// Device-only probe: synthesized speech, separate database, no user recordings.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

import 'background_platform.dart' as background;
import 'dream.dart';
import 'dream_repository.dart';
import 'transcriber_native.dart';
import 'transcription_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: _BackgroundProbe()));
}

class _BackgroundProbe extends StatefulWidget {
  const _BackgroundProbe();
  @override
  State<_BackgroundProbe> createState() => _BackgroundProbeState();
}

class _BackgroundProbeState extends State<_BackgroundProbe> {
  String status = 'Preparazione prova con audio sintetici…';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  Future<void> _run() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final db = await databaseFactoryIo.openDatabase(
        '${directory.path}/background-probe.db',
      );
      final repo = DreamRepository(db);
      final manager = TranscriptionManager(
        engine: LocalWhisperTranscriber(),
        repository: repo,
        background: background.createBackgroundGuard(),
      );
      await manager.initialize();
      if (!manager.ready) throw StateError('Modello non disponibile');
      final mixed = Dream(
        id: 'probe-mixed',
        title: 'Audio sintetico misto',
        createdAt: DateTime.now(),
        durationMs: 20000,
        audio: '${directory.path}/test-mixed.wav',
      );
      final english = Dream(
        id: 'probe-english',
        title: 'Audio sintetico inglese',
        createdAt: DateTime.now(),
        durationMs: 20000,
        audio: '${directory.path}/test-english.wav',
      );
      await repo.save(mixed);
      await repo.save(english);
      final watch = Stopwatch()..start();
      final jobs = [
        manager.run(mixed, retry: true),
        manager.run(english, retry: true),
      ];
      debugPrint('BACKGROUND_ASR_TEST_STARTED');
      if (mounted) {
        setState(() {
          status = 'Trascrizione in corso. La prova continua anche fuori da questa schermata.';
        });
      }
      await Future.wait(jobs);
      watch.stop();
      final mixedResult = (await repo.get(mixed.id))!;
      final englishResult = (await repo.get(english.id))!;
      final wasBackground =
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed;
      final passed =
          manager.stages[mixed.id] == TranscriptionStage.completed &&
          manager.stages[english.id] == TranscriptionStage.completed &&
          mixedResult.automaticTranscript!.toLowerCase().contains(
            'coniglio blu',
          ) &&
          mixedResult.automaticTranscript!.toLowerCase().contains(
            'good morning',
          ) &&
          englishResult.automaticTranscript!.toLowerCase().contains(
            'blue rabbit',
          ) &&
          wasBackground;
      final report = {
        'passed': passed,
        'backgroundAtCompletion': wasBackground,
        'elapsedMs': watch.elapsedMilliseconds,
        'mixed': mixedResult.automaticTranscript,
        'english': englishResult.automaticTranscript,
        'mixedStage': manager.stages[mixed.id]?.name,
        'englishStage': manager.stages[english.id]?.name,
      };
      await File('${directory.path}/background-probe-report.json')
          .writeAsString(jsonEncode(report), flush: true);
      debugPrint(
        '${passed ? 'BACKGROUND_ASR_TEST_PASS' : 'BACKGROUND_ASR_TEST_FAIL'} ${jsonEncode(report)}',
      );
      if (mounted) {
        setState(() {
          status = jsonEncode(report);
        });
      }
      manager.dispose();
      await db.close();
    } catch (error) {
      debugPrint('BACKGROUND_ASR_TEST_ERROR: $error');
      if (mounted) {
        setState(() {
          status = 'Errore collaudo: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Prova trascrizione in background')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: SelectableText(status),
    ),
  );
}
