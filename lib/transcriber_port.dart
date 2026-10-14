abstract interface class TranscriberPort {
  bool get supported;
  Future<bool> isReady();
  Future<void> download(void Function(double) onProgress);
  Future<String> transcribe(String audio, void Function(double) onProgress);
}
