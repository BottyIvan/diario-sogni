import 'package:flutter_test/flutter_test.dart';
import 'package:diario_sogni/whisper_request.dart';

void main() {
  test('recognition detects the language and never requests translation', () {
    final request = whisperRequest(
      audio: '/audio.wav',
      model: '/model.bin',
      vadModel: '/vad.bin',
    );
    expect(request['language'], 'auto');
    expect(request['is_translate'], isFalse);
    expect(request['vad_model'], '/vad.bin');
  });
}
