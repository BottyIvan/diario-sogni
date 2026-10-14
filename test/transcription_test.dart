import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:diario_sogni/dream.dart';
import 'package:diario_sogni/dream_repository.dart';
import 'package:diario_sogni/transcriber_port.dart';
import 'package:diario_sogni/transcription_manager.dart';

class FakeTranscriber implements TranscriberPort {
  final gate = Completer<void>();
  int calls = 0, concurrent = 0, maxConcurrent = 0;
  bool fail = false;
  @override
  bool get supported => true;
  @override
  Future<bool> isReady() async => true;
  @override
  Future<void> download(void Function(double) onProgress) async {}
  @override
  Future<String> transcribe(
    String audio,
    void Function(double) onProgress,
  ) async {
    calls++;
    concurrent++;
    if (concurrent > maxConcurrent) maxConcurrent = concurrent;
    try {
      await gate.future;
      if (fail) throw StateError('Engine failure');
      return 'Ho sognato un coniglio blu.';
    } finally {
      concurrent--;
    }
  }
}

Dream sample(String id) => Dream(
  id: id,
  title: 'Sogno iniziale',
  createdAt: DateTime(2026, 10, 13),
  durationMs: 6000,
  audio: '$id.m4a',
);

void main() {
  test('saving an older editor snapshot preserves a completed automatic transcript', () async {
    final db = await databaseFactoryMemory.openDatabase('older-editor');
    final repo = DreamRepository(db);
    final original = sample('one');
    await repo.save(original);
    await repo.applyAutomaticTranscript('one', 'Un coniglio blu.');
    await repo.save(
      original.edited(title: 'Nome nuovo', transcript: 'Testo corretto.'),
    );
    final saved = (await repo.get('one'))!;
    expect(saved.title, 'Nome nuovo');
    expect(saved.transcript, 'Testo corretto.');
    expect(saved.automaticTranscript, 'Un coniglio blu.');
    await db.close();
  });
  test('late automatic result preserves title and manual text saved while transcribing', () async {
    final db = await databaseFactoryMemory.openDatabase('transcript-race');
    final repo = DreamRepository(db);
    final original = sample('one');
    await repo.save(original);
    final engine = FakeTranscriber();
    final manager = TranscriptionManager(engine: engine, repository: repo);
    await manager.initialize();
    final job = manager.run(original);
    await repo.save(
      original.edited(
        title: 'Titolo scelto',
        transcript: 'Ho corretto il colore: coniglio rosso.',
      ),
    );
    engine.gate.complete();
    await job;
    final saved = (await repo.get('one'))!;
    expect(saved.title, 'Titolo scelto');
    expect(saved.transcript, 'Ho corretto il colore: coniglio rosso.');
    expect(saved.automaticTranscript, 'Ho sognato un coniglio blu.');
    expect(saved.transcriptEdited, isTrue);
    manager.dispose();
    await db.close();
  });

  test('automatic text is searchable and inference jobs are serialized and deduplicated', () async {
    final db = await databaseFactoryMemory.openDatabase('transcript-queue');
    final repo = DreamRepository(db);
    final one = sample('one'), two = sample('two');
    await repo.save(one);
    await repo.save(two);
    final engine = FakeTranscriber();
    final manager = TranscriptionManager(engine: engine, repository: repo);
    await manager.initialize();
    final first = manager.run(one);
    final duplicate = manager.run(one);
    final second = manager.run(two);
    engine.gate.complete();
    await Future.wait([first, duplicate, second]);
    expect(engine.calls, 2);
    expect(engine.maxConcurrent, 1);
    expect(
      (await repo.load()).where((dream) => dream.matches('coniglio blu')),
      hasLength(2),
    );
    manager.dispose();
    await db.close();
  });

  test('inference failure keeps the audio and can be retried', () async {
    final db = await databaseFactoryMemory.openDatabase('transcript-retry');
    final repo = DreamRepository(db);
    final dream = sample('one');
    await repo.save(dream);
    final engine = FakeTranscriber()..fail = true;
    engine.gate.complete();
    final manager = TranscriptionManager(engine: engine, repository: repo);
    await manager.initialize();
    await manager.run(dream);
    expect(manager.stages[dream.id], TranscriptionStage.failed);
    expect((await repo.get(dream.id))!.audio, dream.audio);
    engine.fail = false;
    await manager.run(dream, retry: true);
    expect(manager.stages[dream.id], TranscriptionStage.completed);
    manager.dispose();
    await db.close();
  });
}
