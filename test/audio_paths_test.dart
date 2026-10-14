import 'package:flutter_test/flutter_test.dart';
import 'package:diario_sogni/audio_paths.dart';

void main() {
  test('relative audio remains playable after an iOS container relocation', () {
    const oldRoot = '/app/old/Documents';
    const newRoot = '/app/new/Documents';
    final saved = relativeAudioInDocuments(
      '$oldRoot/audio/dream-1.m4a',
      oldRoot,
    );
    expect(saved, 'audio/dream-1.m4a');
    expect(audioPathInDocuments(saved, newRoot), '$newRoot/audio/dream-1.m4a');
    expect(
      audioPathInDocuments('$oldRoot/audio/dream-1.m4a', newRoot),
      '$newRoot/audio/dream-1.m4a',
    );
  });
  test('container relocation rejects traversal and nested paths', () {
    for (final path in [
      'audio/../private.m4a',
      'audio/nested/dream.m4a',
      '/app/old/Documents/audio/../../private.m4a',
    ]) {
      expect(
        () => audioPathInDocuments(path, '/app/new/Documents'),
        throwsFormatException,
      );
    }
  });
}
