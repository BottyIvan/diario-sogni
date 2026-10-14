import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:diario_sogni/dream.dart';
import 'package:diario_sogni/dream_repository.dart';
import 'package:diario_sogni/main.dart';
import 'package:diario_sogni/recording_controller.dart';

class FakeRecorder implements RecorderPort {
  bool permission = true;
  int starts = 0, stops = 0;
  @override
  Future<bool> hasPermission() async => permission;
  @override
  Future<void> start(String path) async {
    starts++;
  }

  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<String?> stop() async {
    stops++;
    return '/audio/test.m4a';
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets(
    'recording opens its recap and Save returns home without adding text',
    (tester) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('com.ryanheise.just_audio.methods'),
        (_) async => <String, dynamic>{},
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('com.ryanheise.audio_session'),
        (_) async => null,
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.just_audio.methods'),
          null,
        );
        messenger.setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.audio_session'),
          null,
        );
      });
      final db = (await tester.runAsync(
        () => databaseFactoryMemory.openDatabase('recap-test'),
      ))!;
      final repo = DreamRepository(db);
      final controller = RecordingController(
        recorder: FakeRecorder(),
        createPath: (id) async => '/test.m4a',
        persistAudio: (path) async => path,
        saveDream: repo.save,
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: DreamHome(repository: repo, recordingController: controller),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('Racconta un sogno'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() async {
        await tester.tap(find.text('Termina e salva'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.text('Il tuo sogno'), findsOneWidget);
      expect(find.text('Racconta un sogno'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Salva sogno'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(DreamDetail),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('Salva sogno'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.text('Racconta un sogno'), findsOneWidget);
      expect(find.text('Il tuo sogno'), findsNothing);
      final dreams = (await tester.runAsync(repo.load))!;
      expect(dreams, hasLength(1));
      expect(dreams.single.transcript, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(dreams.single.title));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text(dreams.single.title));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Elimina sogno'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect((await tester.runAsync(repo.load))!, hasLength(1));
      await tester.tap(find.byTooltip('Elimina sogno'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Elimina'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Il tuo sogno'), findsNothing);
      expect(find.text('Racconta un sogno'), findsOneWidget);
      expect((await tester.runAsync(repo.load))!, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(db.close);
    },
  );
  test(
    'saved title and text survive database close and reopen without duplicates',
    () async {
      final temp = await Directory.systemTemp.createTemp('dream-test-');
      final path = '${temp.path}/dreams.db';
      var db = await databaseFactoryIo.openDatabase(path);
      final dream = Dream(
        id: 'one',
        title: 'Primo sogno',
        createdAt: DateTime.utc(2026, 10, 13),
        durationMs: 9000,
        audio: '/audio/one.m4a',
      );
      await DreamRepository(db).save(dream);
      await DreamRepository(db).save(
        dream.edited(
          title: 'Coniglio blu',
          transcript: 'Un coniglio BLU attraversava il bosco.',
        ),
      );
      await db.close();
      db = await databaseFactoryIo.openDatabase(path);
      final saved = await DreamRepository(db).load();
      expect(saved, hasLength(1));
      expect(saved.single.title, 'Coniglio blu');
      expect(saved.single.matches('coniglio blu'), isTrue);
      expect(saved.single.matches('coniglio rosso'), isFalse);
      expect(saved.single.audio, dream.audio);
      expect(saved.single.createdAt, dream.createdAt);
      await db.close();
      await temp.delete(recursive: true);
    },
  );

  test(
    'failed persistence can be retried without stopping the microphone twice',
    () async {
      final recorder = FakeRecorder();
      var attempts = 0;
      final controller = RecordingController(
        recorder: recorder,
        createPath: (id) async => '/audio/$id.m4a',
        persistAudio: (path) async => path,
        saveDream: (dream) async {
          if (++attempts == 1) throw StateError('Disk full');
        },
        now: () => DateTime(2026, 10, 13, 8, 30),
      );
      await controller.start();
      await controller.togglePause();
      expect(controller.stage, RecordingStage.paused);
      await controller.togglePause();
      expect(controller.stage, RecordingStage.recording);
      expect(await controller.finish(), isNull);
      expect(controller.stage, RecordingStage.retrySave);
      await controller.start();
      expect(recorder.starts, 1);
      final saved = await controller.finish();
      expect(saved, isNotNull);
      expect(recorder.stops, 1);
      expect(attempts, 2);
      expect(controller.stage, RecordingStage.idle);
      controller.dispose();
    },
  );

  test(
    'denied microphone permission does not create a recording or save a dream',
    () async {
      final recorder = FakeRecorder()..permission = false;
      var saves = 0;
      final controller = RecordingController(
        recorder: recorder,
        createPath: (id) async => id,
        persistAudio: (path) async => path,
        saveDream: (dream) async {
          saves++;
        },
      );
      await controller.start();
      expect(controller.active, isFalse);
      expect(recorder.starts, 0);
      expect(controller.error, isNotNull);
      expect(saves, 0);
      controller.dispose();
    },
  );

  testWidgets('archive and search work at a narrow phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = (await tester.runAsync(
      () => databaseFactoryMemory.openDatabase('widget-test'),
    ))!;
    final repo = DreamRepository(db);
    await tester.runAsync(
      () => repo.save(
        Dream(
          id: 'one',
          title: 'Una notte nel bosco',
          createdAt: DateTime.now(),
          durationMs: 5000,
          audio: '/audio.m4a',
          transcript: 'Ho visto un coniglio blu.',
        ),
      ),
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: DreamHome(repository: repo, recorder: FakeRecorder()),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Una notte nel bosco'), findsOneWidget);
    await tester.tap(find.text('Cerca'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'coniglio blu');
    await tester.pumpAndSettle();
    expect(find.text('Una notte nel bosco'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'gatto rosso');
    await tester.pumpAndSettle();
    expect(find.text('Nessun sogno trovato'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
