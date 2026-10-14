// Separate entry point for an on-device test with synthesized speech only.
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'transcriber_native.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: _SmokePage()));
}

class _SmokePage extends StatefulWidget {
  const _SmokePage();
  @override
  State<_SmokePage> createState() => _SmokePageState();
}

class _SmokePageState extends State<_SmokePage> {
  String status = 'Verifica della trascrizione locale…';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      final engine = LocalWhisperTranscriber();
      await engine.download((_) {});
      final directory = await getApplicationSupportDirectory();
      final watch = Stopwatch()..start();
      final text = await engine.transcribe(
        '${directory.path}/test-italiano.wav',
        (_) {},
      );
      watch.stop();
      final passed = text.toLowerCase().contains('coniglio blu');
      final output =
          '${passed ? 'LOCAL_ASR_TEST_PASS' : 'LOCAL_ASR_TEST_FAIL'}\n'
          '${watch.elapsedMilliseconds} ms\n$text';
      debugPrint(output);
      if (mounted) {
        setState(() {
          status = output;
        });
      }
    } catch (error) {
      debugPrint('LOCAL_ASR_TEST_ERROR: $error');
      if (mounted) {
        setState(() {
          status = 'LOCAL_ASR_TEST_ERROR: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verifica audio sintetico')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: SelectableText(status),
    ),
  );
}
