# Componenti di terze parti

La licenza MIT del progetto riguarda il codice di Diario dei sogni. I componenti esterni mantengono le proprie licenze e attribuzioni. pubspec.lock documenta le versioni Flutter e Dart, i cui avvisi sono raccolti nell'asset Flutter NOTICES.Z.

La versione Android 0.4.2 decodifica gli audio mediante MediaExtractor e MediaCodec. Il progetto iOS preliminare usa AVFoundation. Non includono FFmpeg, FFmpeg Kit o il plugin Flutter whisper_ggml. Il motore CPU viene compilato dai sorgenti presenti in vendor/whisper-native, con le attribuzioni originali conservate: CMake per Android, DreamNative.podspec per Apple.

| Componente | Provenienza | Licenza |
| --- | --- | --- |
| Bridge nativo whisper_ggml | Sorgenti del pacchetto 2.8.0; dettagli in vendor/whisper-native/README.md | MIT, Copyright 2022 Hrvoje Cukman |
| whisper.cpp e ggml CPU | Versione 1.9.1 incorporata nel pacchetto originario | MIT; testo in licenses/whisper.cpp-MIT.txt |
| Nlohmann JSON | Intestazione 3.11.2, con avvisi originali | MIT, Copyright 2013–2022 Niels Lohmann |
| dr_wav | Intestazione incorporata nel motore | MIT No Attribution, Copyright 2020 David Reid |

I testi delle licenze native sono nella cartella licenses, inclusa anche come asset nell'app. La distribuzione allega inoltre un archivio delle licenze. I sorgenti necessari a ricompilare il motore sono inclusi nel repository; per compilazione e firma vedi docs/firma-android.md.

I modelli Whisper e Silero vengono scaricati separatamente e non sono inclusi nell'APK o nel repository. Collegamenti, dimensioni e checksum sono in lib/transcriber_native.dart.
