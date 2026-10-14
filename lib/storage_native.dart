import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

import 'audio_paths.dart';

Directory? _documents;
Future<Directory> _documentsFolder() async =>
    _documents ??= await getApplicationDocumentsDirectory();

Future<String> resolveNativeAudio(String audio) async {
  if (!Platform.isIOS) return audio;
  return audioPathInDocuments(audio, (await _documentsFolder()).path);
}

String _playbackPath(String audio) {
  if (!Platform.isIOS) return audio;
  final folder = _documents;
  if (folder == null) throw StateError('Archivio non ancora aperto');
  return audioPathInDocuments(audio, folder.path);
}

Future<Database> openDreamDatabase() async {
  final directory = await _documentsFolder();
  return databaseFactoryIo.openDatabase(
    '${directory.path}/dreams.db',
    version: 1,
  );
}

Future<String> recordingPath(String id) async {
  final directory = await _documentsFolder();
  final audio = Directory('${directory.path}/audio');
  await audio.create(recursive: true);
  return '${audio.path}/$id.m4a';
}

Future<String> persistAudio(String path) async {
  final file = File(path);
  if (!await file.exists() || await file.length() == 0) {
    throw StateError('Audio non disponibile');
  }
  return Platform.isIOS
      ? relativeAudioInDocuments(path, (await _documentsFolder()).path)
      : path;
}

String playbackUrl(String audio) => Uri.file(_playbackPath(audio)).toString();

Future<Uint8List> readAudio(String audio) async =>
    File(await resolveNativeAudio(audio)).readAsBytes();
String audioExtension(String audio) =>
    audio.toLowerCase().endsWith('.webm') ? 'webm' : 'm4a';
Future<String> importAudio(String id, String extension, Uint8List bytes) async {
  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id) ||
      !['m4a', 'webm'].contains(extension)) {
    throw FormatException('Nome audio non valido');
  }
  final directory = await _documentsFolder();
  final folder = Directory('${directory.path}/audio');
  await folder.create(recursive: true);
  final file = File('${folder.path}/$id.$extension');
  final temporary = File('${file.path}.import');
  await temporary.writeAsBytes(bytes, flush: true);
  await temporary.rename(file.path);
  return Platform.isIOS
      ? relativeAudioInDocuments(file.path, directory.path)
      : file.path;
}

Future<void> deleteAudio(String audio) async {
  if (audio.isEmpty) return;
  audio = await resolveNativeAudio(audio);
  if (!(await Future.wait(
    [
      audio,
      '$audio.asr.wav',
      '$audio.import',
    ].map((path) => File(path).exists()),
  )).any((exists) => exists)) {
    return;
  }
  final directory = await getApplicationDocumentsDirectory();
  final folder = Directory('${directory.path}/audio');
  await deleteAudioFromFolder(audio, folder);
}

Future<void> deleteAudioFromFolder(String audio, Directory folder) async {
  final files = <File>[];
  for (final path in [audio, '$audio.asr.wav', '$audio.import']) {
    final file = File(path);
    if (await file.exists()) files.add(file);
  }
  if (files.isEmpty) return;
  final resolvedFolder = await folder.resolveSymbolicLinks();
  // Validate all resolved paths before removing any file.
  for (final file in files) {
    final resolvedFile = await file.resolveSymbolicLinks();
    if (!resolvedFile.startsWith('$resolvedFolder${Platform.pathSeparator}')) {
      throw StateError('Audio fuori dall’archivio dell’app');
    }
  }
  for (final file in files) {
    await file.delete();
  }
}
