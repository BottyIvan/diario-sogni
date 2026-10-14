import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'transcriber_port.dart';
import 'whisper_request.dart';
import 'storage_native.dart' as storage;

Map<String, dynamic> invokeWhisper(String requestJson) {
  final input = requestJson.toNativeUtf8();
  Pointer<Utf8>? output;
  try {
    final library = Platform.isIOS
        ? DynamicLibrary.process()
        : DynamicLibrary.open('libwhisper.so');
    final request = library
        .lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>),
          Pointer<Utf8> Function(Pointer<Utf8>)
        >('request');
    output = request(input);
    if (output.address == 0) {
      throw StateError('Risposta del motore non disponibile');
    }
    return jsonDecode(output.toDartString()) as Map<String, dynamic>;
  } finally {
    malloc.free(input);
    if (output != null && output.address != 0) malloc.free(output);
  }
}

TranscriberPort createTranscriber() => LocalWhisperTranscriber();

class LocalWhisperTranscriber implements TranscriberPort {
  static const modelSize = 190085487;
  static const vadSize = 885098;
  static const modelHash =
      'ae85e4a935d7a567bd102fe55afc16bb595bdb618e11b2fc7591bc08120411bb';
  static const vadHash =
      '29940d98d42b91fbd05ce489f3ecf7c72f0a42f027e4875919a28fb4c04ea2cf';
  @override
  bool get supported => Platform.isAndroid || Platform.isIOS;
  Future<String> _vadPath() async =>
      '${(await getApplicationSupportDirectory()).path}/ggml-silero-v5.1.2.bin';
  Future<String> _modelPath() async =>
      '${(await getApplicationSupportDirectory()).path}/ggml-small.bin';
  @override
  Future<bool> isReady() async {
    if (!supported) return false;
    final model = File(await _modelPath());
    final vad = File(await _vadPath());
    return await model.exists() &&
        await model.length() == modelSize &&
        await vad.exists() &&
        await vad.length() == vadSize &&
        await File('${model.path}.verified').exists();
  }

  @override
  Future<void> download(void Function(double) onProgress) async {
    if (!supported) throw UnsupportedError('Richiede Android o iPhone');
    // The wrapper expects this filename; the verified contents are small Q5_1.
    final modelPath = await _modelPath();
    await Directory(File(modelPath).parent.path).create(recursive: true);
    await _downloadVerified(
      Uri.parse(
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small-q5_1.bin',
      ),
      modelPath,
      modelSize,
      modelHash,
      (progress) => onProgress(progress * .99),
    );
    await _downloadVerified(
      Uri.parse(
        'https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v5.1.2.bin',
      ),
      await _vadPath(),
      vadSize,
      vadHash,
      (progress) => onProgress(.99 + progress * .01),
    );
    await File('$modelPath.verified').writeAsString(modelHash, flush: true);
    onProgress(1);
  }

  Future<void> _downloadVerified(
    Uri uri,
    String path,
    int size,
    String checksum,
    void Function(double) progress,
  ) async {
    final destination = File(path);
    if (await destination.exists() &&
        await destination.length() == size &&
        (await sha256.bind(destination.openRead()).first).toString() ==
            checksum) {
      return;
    }
    final partial = File('$path.part');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30);
    IOSink? sink;
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      if (response.statusCode != 200) {
        throw HttpException('Download HTTP ${response.statusCode}');
      }
      sink = partial.openWrite();
      var received = 0;
      await for (final chunk in response.timeout(const Duration(seconds: 60))) {
        received += chunk.length;
        if (received > size) throw StateError('Dimensione modello inattesa');
        sink.add(chunk);
        progress(received / size);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (received != size ||
          (await sha256.bind(partial.openRead()).first).toString() !=
              checksum) {
        throw StateError('Verifica integrità modello fallita');
      }
      if (await destination.exists()) await destination.delete();
      await partial.rename(path);
    } finally {
      await sink?.close();
      client.close(force: true);
      if (await partial.exists()) await partial.delete();
    }
  }

  @override
  Future<String> transcribe(
    String audio,
    void Function(double) onProgress,
  ) async {
    if (!await isReady()) throw StateError('Modello non disponibile');
    audio = await storage.resolveNativeAudio(audio);
    final converted = File('$audio.asr.wav');
    final callback = NativeCallable<Void Function(Int32)>.listener(
      (int value) => onProgress(value / 100),
    );
    try {
      const channel = MethodChannel('it.diariosogni/background');
      await channel.invokeMethod<String>('convertAudio', {
        'input': audio,
        'output': converted.path,
      });
      final request = jsonEncode(
        whisperRequest(
          audio: converted.path,
          model: await _modelPath(),
          vadModel: await _vadPath(),
          progressCallback: callback.nativeFunction.address,
        ),
      );
      final result = await compute(invokeWhisper, request);
      if (result['text'] is! String) {
        throw StateError('Trascrizione non completata');
      }
      return (result['text'] as String).trim();
    } finally {
      callback.close();
      if (await converted.exists()) await converted.delete();
    }
  }
}
