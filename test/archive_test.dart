import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:diario_sogni/archive_manager.dart';
import 'package:diario_sogni/archive_port.dart';
import 'package:diario_sogni/dream.dart';
import 'package:diario_sogni/dream_repository.dart';
import 'package:diario_sogni/transcriber_port.dart';
import 'package:diario_sogni/transcription_manager.dart';

class MemoryFolder implements ArchivePort {
  final files = <String, Uint8List>{};
  String? failWrite;
  @override
  bool get supported => true;
  @override
  Future<String?> restore() async => 'Prova';
  @override
  Future<String?> choose() async => 'Prova';
  @override
  Future<void> disconnect() async {}
  @override
  Future<List<String>> list() async => files.keys.toList();
  @override
  Future<Uint8List> read(String name) async => files[name]!;
  @override
  Future<void> write(String name, Uint8List bytes) async {
    if (name.startsWith(failWrite ?? '\u0000')) {
      throw StateError('Transfer interrupted');
    }
    files[name] = Uint8List.fromList(bytes);
  }

  @override
  Future<void> remove(String name) async {
    files.remove(name);
  }
}

class LocalFiles {
  final files = <String, Uint8List>{};
  Future<Uint8List> read(String name) async => files[name]!;
  Future<String> import(String id, String extension, Uint8List bytes) async {
    final name = '/audio/$id.$extension';
    files[name] = Uint8List.fromList(bytes);
    return name;
  }

  Future<void> remove(String name) async {
    files.remove(name);
  }
}

class DeferredEngine implements TranscriberPort {
  final started = Completer<void>(), result = Completer<String>();
  @override
  bool get supported => true;
  @override
  Future<bool> isReady() async => true;
  @override
  Future<void> download(void Function(double) onProgress) async {}
  @override
  Future<String> transcribe(String audio, void Function(double) onProgress) {
    started.complete();
    return result.future;
  }
}

Dream sample() => Dream(
  id: 'one',
  title: 'Coniglio blu',
  createdAt: DateTime.utc(2026, 10, 14),
  durationMs: 1000,
  audio: '/audio/one.m4a',
  transcript: 'Ho sognato un coniglio blu',
  automaticTranscript: 'Ho sognato un coniglio blu',
);
ArchiveManager manager(
  DreamRepository repo,
  MemoryFolder folder,
  LocalFiles files, {
  Future<void> Function(String)? beforeDelete,
}) => ArchiveManager(
  port: folder,
  repository: repo,
  readAudio: files.read,
  importAudio: files.import,
  deleteAudio: files.remove,
  audioExtension: (_) => 'm4a',
  beforeDelete: beforeDelete,
);

void main() {
  test('two devices share audio, searchable text and edits without duplicating dreams', () async {
    final aDb = await databaseFactoryMemory.openDatabase('archive-a');
    final bDb = await databaseFactoryMemory.openDatabase('archive-b');
    addTearDown(() async {
      await aDb.close();
      await bDb.close();
    });
    final a = DreamRepository(aDb), b = DreamRepository(bDb);
    final folder = MemoryFolder(), aFiles = LocalFiles(), bFiles = LocalFiles();
    aFiles.files[sample().audio] = Uint8List.fromList([1, 2, 3]);
    await a.save(sample());
    final ma = manager(a, folder, aFiles), mb = manager(b, folder, bFiles);
    await ma.initialize();
    await mb.initialize();
    await ma.synchronize();
    await mb.synchronize();
    expect(ma.error, isNull);
    expect(mb.error, isNull);
    expect((await b.load()).single.matches('coniglio blu'), isTrue);
    expect(bFiles.files[(await b.get('one'))!.audio], [1, 2, 3]);
    await b.save(
      (await b.get('one'))!.edited(
        title: 'Nuovo titolo',
        transcript: 'Coniglio blu e casa rossa',
      ),
    );
    await mb.synchronize();
    await ma.synchronize();
    await ma.synchronize();
    expect((await a.load()).single.title, 'Nuovo titolo');
    expect((await a.load()).single.transcript, 'Coniglio blu e casa rossa');
    expect(
      (await a.load()).single.automaticTranscript,
      sample().automaticTranscript,
    );
  });
  test('offline deletion removes cloud audio and all text versions and wins over stale edits', () async {
    final aDb = await databaseFactoryMemory.openDatabase('delete-a');
    final bDb = await databaseFactoryMemory.openDatabase('delete-b');
    addTearDown(() async {
      await aDb.close();
      await bDb.close();
    });
    final a = DreamRepository(aDb), b = DreamRepository(bDb);
    final folder = MemoryFolder(), aFiles = LocalFiles(), bFiles = LocalFiles();
    aFiles.files[sample().audio] = Uint8List.fromList([1, 2, 3]);
    await a.save(sample());
    final ma = manager(a, folder, aFiles), mb = manager(b, folder, bFiles);
    await ma.initialize();
    await mb.initialize();
    await ma.synchronize();
    await mb.synchronize();
    await ma.removeDream('one');
    expect(await a.get('one'), isNull);
    expect(aFiles.files, isEmpty);
    await b.save(
      (await b.get('one'))!
          .edited(title: 'Modifica offline', transcript: 'Non ripristinare'),
    );
    await ma.synchronize();
    await mb.synchronize();
    expect(await b.load(), isEmpty);
    expect(bFiles.files, isEmpty);
    expect(folder.files.keys.toSet(), {
      ArchiveManager.marker,
      'eliminato_one.json',
    });
    expect(await a.deletions(), {'one': ''});
    expect(await b.deletions(), {'one': ''});
    await expectLater(b.save(sample()), throwsStateError);
    expect(await b.applyAutomaticTranscript('one', 'late result'), isNull);
  });
  test('failed audio transfer commits no dream metadata and retry imports one complete dream', () async {
    final aDb = await databaseFactoryMemory.openDatabase('failure-a');
    final bDb = await databaseFactoryMemory.openDatabase('failure-b');
    addTearDown(() async {
      await aDb.close();
      await bDb.close();
    });
    final a = DreamRepository(aDb), b = DreamRepository(bDb);
    final folder = MemoryFolder()..failWrite = 'audio_';
    final aFiles = LocalFiles(), bFiles = LocalFiles();
    aFiles.files[sample().audio] = Uint8List.fromList([1, 2, 3]);
    await a.save(sample());
    final ma = manager(a, folder, aFiles), mb = manager(b, folder, bFiles);
    await ma.initialize();
    await mb.initialize();
    await ma.synchronize();
    expect(ma.error, isNotNull);
    expect(await a.load(), hasLength(1));
    expect(
      folder.files.keys.where((name) => name.startsWith('sogno_')),
      isEmpty,
    );
    folder.failWrite = null;
    await ma.synchronize();
    folder.files['audio_one.m4a'] = Uint8List.fromList([9]);
    await mb.synchronize();
    expect(mb.error, isNotNull);
    expect(await b.load(), isEmpty);
    folder.files['audio_one.m4a'] = Uint8List.fromList([1, 2, 3]);
    await mb.synchronize();
    expect(mb.error, isNull);
    expect(await b.load(), hasLength(1));
  });
  test('deletion waits for active transcription and late results cannot restore text', () async {
    final db = await databaseFactoryMemory.openDatabase('delete-running');
    addTearDown(db.close);
    final repo = DreamRepository(db),
        files = LocalFiles(),
        engine = DeferredEngine();
    final dream = Dream(
      id: 'one',
      title: 'Audio',
      createdAt: DateTime.now(),
      durationMs: 1000,
      audio: '/audio/one.m4a',
    );
    files.files[dream.audio] = Uint8List.fromList([1]);
    await repo.save(dream);
    final transcription = TranscriptionManager(
      engine: engine,
      repository: repo,
    );
    await transcription.initialize();
    final job = transcription.run(dream);
    await engine.started.future;
    final deletionMarked = Completer<void>();
    final archive = manager(
      repo,
      MemoryFolder(),
      files,
      beforeDelete: (id) async {
        deletionMarked.complete();
        await transcription.forget(id);
      },
    );
    final deletion = archive.removeDream(dream.id);
    await deletionMarked.future;
    expect(await repo.get(dream.id), isNull);
    expect(files.files, isNotEmpty);
    engine.result.complete('Risultato arrivato tardi');
    await job;
    await deletion;
    expect(files.files, isEmpty);
    expect(transcription.results, isEmpty);
    expect(await repo.load(), isEmpty);
  });
}
