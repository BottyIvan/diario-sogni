import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'archive_port.dart';
import 'dream.dart';
import 'dream_repository.dart';

typedef AudioImport = Future<String> Function(
  String id,
  String extension,
  Uint8List bytes,
);

class ArchiveManager extends ChangeNotifier {
  ArchiveManager({
    required this.port,
    required this.repository,
    required this.readAudio,
    required this.importAudio,
    required this.deleteAudio,
    required this.audioExtension,
    this.beforeDelete,
  });
  final ArchivePort port;
  final DreamRepository repository;
  final Future<Uint8List> Function(String) readAudio;
  final AudioImport importAudio;
  final Future<void> Function(String) deleteAudio;
  final String Function(String) audioExtension;
  final Future<void> Function(String)? beforeDelete;
  String? folderLabel, error, lastResult;
  bool busy = false;
  static const marker = 'diario-sogni-archive.json';
  static final _recordName = RegExp(
    r'^sogno_([a-zA-Z0-9-]+)_([0-9]{20}-[a-f0-9]+)\.json$',
  );
  static final _deletedName = RegExp(r'^eliminato_([a-zA-Z0-9-]+)\.json$');
  static final _id = RegExp(r'^[a-zA-Z0-9-]+$');
  static final _version = RegExp(r'^[0-9]{20}-[a-f0-9]+$');
  Uint8List _json(Object value) =>
      Uint8List.fromList(utf8.encode(jsonEncode(value)));
  Future<Map<String, dynamic>> _readJson(String name) async {
    final bytes = await port.read(name);
    if (bytes.length > 4 * 1024 * 1024) {
      throw const FormatException('Metadati troppo grandi');
    }
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  Future<void> initialize() async {
    if (!port.supported) return;
    try {
      folderLabel = await port.restore();
    } catch (_) {
      error = 'Ricollega la cartella per accedere all’archivio.';
    }
    notifyListeners();
  }

  Future<void> choose() async {
    if (busy) return;
    // The picker must be called directly from the user's click.
    try {
      final label = await port.choose();
      if (label != null) {
        folderLabel = label;
        error = null;
        lastResult = null;
      }
    } catch (_) {
      error = 'Non riesco a collegare la cartella. Verifica i permessi.';
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (busy) return;
    try {
      await port.disconnect();
      folderLabel = null;
      error = null;
      lastResult = null;
    } catch (_) {
      error = 'Non riesco a scollegare la cartella. Riprova.';
    }
    notifyListeners();
  }

  Future<void> removeDream(String id) async {
    if (busy) throw StateError('Attendi la sincronizzazione');
    await repository.markDeleted(id);
    await beforeDelete?.call(id);
    final path = (await repository.deletions())[id] ?? '';
    await deleteAudio(path);
    await repository.finishDeletion(id);
  }

  Future<void> synchronize() async {
    if (busy || folderLabel == null) return;
    busy = true;
    error = null;
    lastResult = null;
    notifyListeners();
    try {
      final names = await port.list();
      if (names.contains(marker)) {
        final header = await _readJson(marker);
        if (header['format'] != 'diario-sogni' || header['schema'] != 1) {
          throw const FormatException('Formato archivio non supportato');
        }
      } else {
        if (names.any(
          (name) => _recordName.hasMatch(name) || _deletedName.hasMatch(name),
        )) {
          throw const FormatException(
            'Archivio incompleto: manca il file identificativo',
          );
        }
        await port.write(
          marker,
          _json({'format': 'diario-sogni', 'schema': 1}),
        );
      }
      // Always rewrite our tiny deletion markers, repairing an interrupted write.
      for (final id in (await repository.deletions()).keys) {
        if (!_id.hasMatch(id)) {
          throw const FormatException('Identificativo non valido');
        }
        await port.write(
          'eliminato_$id.json',
          _json({'schema': 1, 'id': id, 'deleted': true}),
        );
      }
      // Deletions take precedence over all versions, including offline edits.
      for (final name in names) {
        final match = _deletedName.firstMatch(name);
        if (match == null) continue;
        final header = await _readJson(name);
        if (header['id'] != match[1] ||
            header['deleted'] != true ||
            header['schema'] != 1) {
          throw const FormatException('Eliminazione non valida');
        }
        await repository.markDeleted(match[1]!);
      }
      final deletions = await repository.deletions();
      for (final entry in deletions.entries) {
        if (!_id.hasMatch(entry.key)) {
          throw const FormatException('Identificativo non valido');
        }
        final tombstone = 'eliminato_${entry.key}.json';
        // Commit the marker before removing content, so another device cannot restore it.
        if (!names.contains(tombstone)) {
          await port.write(
            tombstone,
            _json({'schema': 1, 'id': entry.key, 'deleted': true}),
          );
        }
        await beforeDelete?.call(entry.key);
        await deleteAudio(entry.value);
        await repository.finishDeletion(entry.key);
        for (final name in names) {
          if (_recordName.firstMatch(
                    name.replaceFirst(RegExp(r'\.ready$'), '.json'),
                  )?[1] ==
                  entry.key ||
              name == 'audio_${entry.key}.m4a' ||
              name == 'audio_${entry.key}.webm') {
            await port.remove(name);
          }
        }
      }
      final remote = <String, ({String name, String version})>{};
      for (final name in names) {
        final match = _recordName.firstMatch(name);
        if (match == null ||
            deletions.containsKey(match[1]) ||
            !names.contains(name.replaceFirst(RegExp(r'\.json$'), '.ready'))) {
          continue;
        }
        final id = match[1]!, version = match[2]!;
        if (remote[id] == null || version.compareTo(remote[id]!.version) > 0) {
          remote[id] = (name: name, version: version);
        }
      }
      var downloaded = 0, uploaded = 0;
      for (final entry in remote.entries) {
        final existing = await repository.get(entry.key);
        if (existing != null &&
            (await repository.versionFor(existing))
                    .compareTo(entry.value.version) >=
                0) {
          continue;
        }
        final payloadBytes = await port.read(entry.value.name);
        final receipt = await _readJson(
          entry.value.name.replaceFirst(RegExp(r'\.json$'), '.ready'),
        );
        if (payloadBytes.length > 4 * 1024 * 1024 ||
            receipt['sha256'] != sha256.convert(payloadBytes).toString()) {
          throw const FormatException(
            'Metadati incompleti: attendi il cloud e riprova',
          );
        }
        final payload =
            jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;
        if (payload['schema'] != 1 ||
            payload['id'] != entry.key ||
            payload['version'] != entry.value.version) {
          throw const FormatException('Dati sogno non validi');
        }
        final extension = payload['extension'] as String;
        if (!['m4a', 'webm'].contains(extension)) {
          throw const FormatException('Audio non supportato');
        }
        final audioName = 'audio_${entry.key}.$extension';
        final bytes = await port.read(audioName);
        if (bytes.isEmpty ||
            bytes.length > 100 * 1024 * 1024 ||
            sha256.convert(bytes).toString() != payload['audioSha256']) {
          throw const FormatException(
            'Audio incompleto: attendi il cloud e riprova',
          );
        }
        // Validate every field before creating a local file.
        final metadata = Map<String, Object?>.from(payload['dream'] as Map);
        metadata['audio'] = '';
        final validated = Dream.fromMap(entry.key, metadata);
        if (validated.durationMs < 0) {
          throw const FormatException('Durata non valida');
        }
        metadata['audio'] = await importAudio(entry.key, extension, bytes);
        if (await repository.importVersion(
          Dream.fromMap(entry.key, metadata),
          entry.value.version,
        )) {
          downloaded++;
        }
      }
      for (final row in await repository.archiveSnapshot()) {
        final dream = row.dream;
        if (!_id.hasMatch(dream.id) || !_version.hasMatch(row.version)) {
          throw const FormatException('Identificativo non valido');
        }
        final bytes = await readAudio(dream.audio);
        if (bytes.isEmpty || bytes.length > 100 * 1024 * 1024) {
          throw const FormatException('Audio vuoto o oltre 100 MB');
        }
        final extension = audioExtension(dream.audio);
        final audioName = 'audio_${dream.id}.$extension';
        if (!names.contains(audioName) ||
            sha256.convert(await port.read(audioName)).toString() !=
                sha256.convert(bytes).toString()) {
          await port.write(audioName, bytes);
        }
        final metadata = dream.toMap()..remove('audio');
        // Audio is written and verified before the immutable metadata commit.
        if (sha256.convert(await port.read(audioName)).toString() !=
            sha256.convert(bytes).toString()) {
          throw const FormatException('Audio condiviso incompleto');
        }
        final recordName = 'sogno_${dream.id}_${row.version}.json';
        final payloadBytes = _json({
          'schema': 1,
          'id': dream.id,
          'version': row.version,
          'extension': extension,
          'audioSha256': sha256.convert(bytes).toString(),
          'dream': metadata,
        });
        if (remote[dream.id]?.version == row.version) {
          try {
            final saved = await port.read(recordName);
            final receipt = await _readJson(
              recordName.replaceFirst(RegExp(r'\.json$'), '.ready'),
            );
            final checksum = sha256.convert(payloadBytes).toString();
            if (sha256.convert(saved).toString() == checksum &&
                receipt['sha256'] == checksum) {
              continue;
            }
          } catch (_) {
            /* Repair only this device's current immutable version. */
          }
        }
        await port.write(recordName, payloadBytes);
        if (sha256.convert(await port.read(recordName)).toString() !=
            sha256.convert(payloadBytes).toString()) {
          throw const FormatException('Scrittura metadati non completata');
        }
        await port.write(
          recordName.replaceFirst(RegExp(r'\.json$'), '.ready'),
          _json({'sha256': sha256.convert(payloadBytes).toString()}),
        );
        uploaded++;
      }
      lastResult =
          'Cartella aggiornata: $uploaded sogni inviati, $downloaded ricevuti. '
          'Il trasferimento cloud dipende dal servizio scelto.';
    } catch (_) {
      error =
          'Sincronizzazione non completata. I dati locali sono conservati. '
          'Controlla accesso alla cartella, trasferimento cloud e spazio libero, poi riprova.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
