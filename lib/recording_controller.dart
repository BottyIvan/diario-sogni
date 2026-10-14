import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'dream.dart';

abstract interface class RecorderPort {
  Future<bool> hasPermission();
  Future<void> start(String path);
  Future<void> pause();
  Future<void> resume();
  Future<String?> stop();
  Future<void> dispose();
}

class DeviceRecorder implements RecorderPort {
  final _recorder = AudioRecorder();
  @override
  Future<bool> hasPermission() => _recorder.hasPermission();
  @override
  Future<void> start(String path) => _recorder.start(
    RecordConfig(
      encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
      bitRate: 64000,
      numChannels: 1,
    ),
    path: path,
  );
  @override
  Future<void> pause() => _recorder.pause();
  @override
  Future<void> resume() => _recorder.resume();
  @override
  Future<String?> stop() => _recorder.stop();
  @override
  Future<void> dispose() => _recorder.dispose();
}

enum RecordingStage { idle, recording, paused, saving, retrySave }

class RecordingController extends ChangeNotifier {
  RecordingController({
    required this.recorder,
    required this.createPath,
    required this.persistAudio,
    required this.saveDream,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final RecorderPort recorder;
  final Future<String> Function(String id) createPath;
  final Future<String> Function(String path) persistAudio;
  final Future<void> Function(Dream dream) saveDream;
  final DateTime Function() now;
  final _watch = Stopwatch();
  Timer? _timer;
  DateTime? _startedAt;
  String? _id, _stoppedPath;
  Dream? _pendingDream;
  bool _disposed = false;
  bool busy = false;
  String? error;
  RecordingStage stage = RecordingStage.idle;
  Duration get elapsed => _watch.elapsed;
  bool get active => stage != RecordingStage.idle;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    if (active || busy) return;
    busy = true;
    error = null;
    _notify();
    try {
      if (!await recorder.hasPermission()) {
        error = 'Consenti l’accesso al microfono per registrare il sogno.';
        return;
      }
      _startedAt = now();
      _id = _startedAt!.microsecondsSinceEpoch.toString();
      await recorder.start(await createPath(_id!));
      _watch
        ..reset()
        ..start();
      stage = RecordingStage.recording;
      _timer = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => _notify(),
      );
    } catch (_) {
      error =
          'Non riesco ad avviare il microfono. Controlla i permessi e riprova.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> togglePause() async {
    if (busy ||
        (stage != RecordingStage.recording && stage != RecordingStage.paused)) {
      return;
    }
    busy = true;
    error = null;
    _notify();
    try {
      if (stage == RecordingStage.recording) {
        await recorder.pause();
        _watch.stop();
        stage = RecordingStage.paused;
      } else {
        await recorder.resume();
        _watch.start();
        stage = RecordingStage.recording;
      }
    } catch (_) {
      error = 'Non riesco a cambiare lo stato del microfono. Prova a salvare.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<Dream?> finish() async {
    if (!active || busy) return null;
    final previousStage = stage;
    busy = true;
    error = null;
    stage = RecordingStage.saving;
    _notify();
    try {
      if (_stoppedPath == null) {
        final path = await recorder.stop();
        if (path == null) throw StateError('Registrazione non disponibile');
        _stoppedPath = path;
        _watch.stop();
        _timer?.cancel();
      }
      _pendingDream ??= Dream(
        id: _id!,
        title: defaultTitle(_startedAt!),
        createdAt: _startedAt!,
        durationMs: elapsed.inMilliseconds,
        audio: await persistAudio(_stoppedPath!),
      );
      await saveDream(_pendingDream!);
      final saved = _pendingDream;
      stage = RecordingStage.idle;
      _pendingDream = null;
      _stoppedPath = null;
      _watch.reset();
      return saved;
    } catch (_) {
      stage = _stoppedPath == null ? previousStage : RecordingStage.retrySave;
      error = 'Salvataggio non completato. Mantieni aperta l’app e riprova.';
      return null;
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watch.stop();
    unawaited(recorder.dispose());
    super.dispose();
  }
}
