import 'package:flutter_test/flutter_test.dart';
import 'package:diario_sogni/background_guard.dart';

void main() {
  test(
    'queued jobs share one service and it stops only after the last job',
    () async {
      var starts = 0, stops = 0;
      final guard = SharedBackgroundGuard(
        start: () async {
          starts++;
        },
        stop: () async {
          stops++;
        },
      );
      await Future.wait([guard.acquire(), guard.acquire()]);
      expect(starts, 1);
      await guard.release();
      expect(stops, 0);
      await guard.release();
      expect(stops, 1);
      await guard.acquire();
      expect(starts, 2);
      await guard.release();
      expect(stops, 2);
    },
  );
  test('a failed service start can be released and retried', () async {
    var starts = 0, stops = 0;
    final guard = SharedBackgroundGuard(
      start: () async {
        starts++;
        if (starts == 1) throw StateError('Service unavailable');
      },
      stop: () async {
        stops++;
      },
    );
    await expectLater(guard.acquire(), throwsStateError);
    await guard.release();
    expect(stops, 0);
    await guard.acquire();
    await guard.release();
    expect(starts, 2);
    expect(stops, 1);
  });
  test(
    'a new job arriving before shutdown keeps the existing service',
    () async {
      var starts = 0, stops = 0;
      final guard = SharedBackgroundGuard(
        start: () async {
          starts++;
        },
        stop: () async {
          stops++;
        },
      );
      await guard.acquire();
      final release = guard.release();
      final acquired = guard.acquire();
      await Future.wait([release, acquired]);
      expect(starts, 1);
      expect(stops, 0);
      await guard.release();
      expect(stops, 1);
    },
  );
}
