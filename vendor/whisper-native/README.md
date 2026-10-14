# Motore nativo riproducibile

Il bridge `main.cpp`, `main.h`, `CMakeLists.txt`, `json/json.hpp` e il sottoinsieme CPU dei sorgenti whisper.cpp provengono dal pacchetto pubblico `whisper_ggml` **2.8.0** su pub.dev. Il bridge è MIT (Copyright 2022 Hrvoje Cukman). Il motore incorporato è whisper.cpp **1.9.1**, CPU soltanto, con le attribuzioni originali conservate nei file e in `whisper.cpp/LICENSE`. Nlohmann JSON e dr_wav conservano i propri avvisi nelle intestazioni originali.

Sono esclusi modelli, esempi audio, back-end GPU e file generati. Il CMake usa gli stessi glob CPU del pacchetto originario e produce `libwhisper.so` con l’ABI `request(char*)`. Gli input e gli output del bridge sono allocati/liberati con malloc/free. Il contratto JSON rimane in `lib/whisper_request.dart`; non cambiare questo ABI senza adeguare e ricollaudare il chiamante Dart.

La compilazione avviene nel progetto Android con NDK 29.0.13113456 e CMake 3.22.1. Nessuna dipendenza FFmpeg è richiesta: conversione e decodifica sono implementate tramite MediaExtractor e MediaCodec Android nel contesto dell’applicazione, utilizzabile in background.

Origini: https://pub.dev/packages/whisper_ggml/versions/2.8.0 e https://github.com/ggml-org/whisper.cpp/tree/v1.9.1. Il sorgente necessario a questa compilazione è incluso nel repository del diario; non viene scaricato un motore precompilato durante la compilazione.
