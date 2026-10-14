import 'package:flutter/foundation.dart';

import 'dream.dart';
import 'dream_repository.dart';
import 'transcriber_port.dart';
import 'background_guard.dart';

enum TranscriptionStage { waiting, running, completed, failed }

class TranscriptionManager extends ChangeNotifier {
  TranscriptionManager({
    required this.engine,
    required this.repository,
    BackgroundGuard? background,
  }) : background = background ?? NoBackgroundGuard();
  final TranscriberPort engine;
  final BackgroundGuard background;
  final DreamRepository repository;
  bool ready = false, downloading = false;
  double downloadProgress = 0;
  String? modelError;
  final stages = <String, TranscriptionStage>{};
  final progress = <String, double>{};
  final results = <String, Dream>{};
  Future<void> _queue = Future<void>.value();
  final _jobs = <String, Future<void>>{};
  Future<void> forget(String id) async {
    await (_jobs[id] ?? Future<void>.value());
    stages.remove(id);
    progress.remove(id);
    results.remove(id);
    _notify();
  }

  bool _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    try {
      ready = await engine.isReady();
    } catch (_) {
      modelError = 'Non riesco a verificare il modello locale.';
    }
    _notify();
  }

  Future<bool> download() async {
    if (downloading || !engine.supported) return false;
    downloading = true;
    modelError = null;
    downloadProgress = 0;
    _notify();
    try {
      await engine.download((value) {
        downloadProgress = value;
        _notify();
      });
      ready = await engine.isReady();
      if (!ready) throw StateError('Modello non disponibile');
      return true;
    } catch (_) {
      modelError = 'Download non completato. Controlla connessione e spazio libero, poi riprova.';
      return false;
    } finally {
      downloading = false;
      _notify();
    }
  }

  Future<void> run(Dream dream, {bool retry = false}) async {
    if (!ready || !engine.supported || _disposed) return;
    final state = stages[dream.id];
    if (state == TranscriptionStage.running ||
        state == TranscriptionStage.waiting) {
      return;
    }
    if (!retry &&
        (dream.automaticTranscript != null ||
            state == TranscriptionStage.completed ||
            state == TranscriptionStage.failed)) {
      return;
    }
    stages[dream.id] = TranscriptionStage.waiting;
    _notify();
    // Acquire while the user is still in the app, before waiting for other jobs.
    final protection = background.acquire();
    // Observe any immediate service error while the job waits in the queue.
    final started = protection.then((_) => true, onError: (Object _) => false);
    final job = _queue.then((_) async {
      if (_disposed) {
        await background.release();
        return;
      }
      stages[dream.id] = TranscriptionStage.running;
      progress[dream.id] = 0;
      _notify();
      try {
        if (!await started) {
          throw StateError('Servizio di trascrizione non disponibile');
        }
        final text = await engine.transcribe(dream.audio, (value) {
          progress[dream.id] = value;
          _notify();
        });
        final updated = await repository.applyAutomaticTranscript(
          dream.id,
          text,
        );
        if (updated != null) results[dream.id] = updated;
        stages[dream.id] = TranscriptionStage.completed;
      } catch (_) {
        stages[dream.id] = TranscriptionStage.failed;
      } finally {
        try {
          await background.release();
        } catch (_) {
          /* Audio and result remain saved. */
        }
      }
      _notify();
    });
    _queue = job;
    _jobs[dream.id] = job;
    await job;
    _jobs.remove(dream.id);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
