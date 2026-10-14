import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:diario_sogni/storage_native.dart';

void main() {
  test(
    'removes audio and transcription/import files, including leftover sidecars',
    () async {
      final temporary = await Directory.systemTemp.createTemp('dream-delete-');
      addTearDown(() => temporary.delete(recursive: true));
      final path = '${temporary.path}${Platform.pathSeparator}one.m4a';
      for (final name in [path, '$path.asr.wav', '$path.import']) {
        await File(name).writeAsBytes([1, 2, 3]);
      }
      await deleteAudioFromFolder(path, temporary);
      expect(await temporary.list().toList(), isEmpty);
      await File('$path.asr.wav').writeAsBytes([4]);
      await deleteAudioFromFolder(path, temporary);
      expect(await temporary.list().toList(), isEmpty);
    },
  );
  test('refuses deletion outside the managed audio folder', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'dream-delete-scope-',
    );
    addTearDown(() => temporary.delete(recursive: true));
    final audio = await Directory(
      '${temporary.path}${Platform.pathSeparator}audio',
    ).create();
    final outside = File('${temporary.path}${Platform.pathSeparator}keep.m4a');
    await outside.writeAsBytes([9]);
    await expectLater(
      deleteAudioFromFolder(outside.path, audio),
      throwsStateError,
    );
    expect(await outside.readAsBytes(), [9]);
  });
}
