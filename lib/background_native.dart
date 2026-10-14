import 'dart:io';

import 'package:flutter/services.dart';

import 'background_guard.dart';

BackgroundGuard createBackgroundGuard() {
  if (!Platform.isAndroid) return NoBackgroundGuard();
  const channel = MethodChannel('it.diariosogni/background');
  return SharedBackgroundGuard(
    start: () => channel.invokeMethod<void>('startTranscription'),
    stop: () => channel.invokeMethod<void>('stopTranscription'),
  );
}
