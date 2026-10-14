abstract interface class BackgroundGuard {
  Future<void> acquire();
  Future<void> release();
}

class NoBackgroundGuard implements BackgroundGuard {
  @override
  Future<void> acquire() async {}
  @override
  Future<void> release() async {}
}

// Keep a single foreground service alive for all accepted, queued jobs.
class SharedBackgroundGuard implements BackgroundGuard {
  SharedBackgroundGuard({required this.start, required this.stop});
  final Future<void> Function() start, stop;
  int _users = 0;
  bool _started = false;
  Future<void> _operations = Future<void>.value();
  Future<void> _serialize(Future<void> Function() operation) {
    final next = _operations.then((_) => operation());
    _operations = next.catchError((Object _) {});
    return next;
  }

  @override
  Future<void> acquire() {
    _users++;
    return _serialize(() async {
      if (!_started) {
        await start();
        _started = true;
      }
    });
  }

  @override
  Future<void> release() {
    if (_users == 0) return Future<void>.value();
    _users--;
    return _serialize(() async {
      if (_users == 0 && _started) {
        await stop();
        _started = false;
      }
    });
  }
}
