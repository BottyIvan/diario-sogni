import 'transcriber_port.dart';

TranscriberPort createTranscriber() => _BrowserTranscriber();

class _BrowserTranscriber implements TranscriberPort {
  @override
  bool get supported => false;
  @override
  Future<bool> isReady() async => false;
  @override
  Future<void> download(void Function(double) onProgress) async =>
      throw UnsupportedError('Trascrizione browser non ancora disponibile');
  @override
  Future<String> transcribe(
    String audio,
    void Function(double) onProgress,
  ) async =>
      throw UnsupportedError('Trascrizione browser non ancora disponibile');
}
