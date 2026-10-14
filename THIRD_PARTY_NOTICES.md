# Componenti di terze parti

La licenza MIT del progetto riguarda il codice di Diario dei sogni. I componenti esterni mantengono le loro licenze e attribuzioni. `pubspec.lock` documenta le versioni effettivamente risolte.

I pacchetti Flutter e Dart hanno avvisi raccolti dal sistema di licenze Flutter nell’asset `NOTICES.Z` dell’APK. I testi aggiuntivi per il motore nativo sono nella cartella `licenses` del repository.

| Componente | Versione usata | Licenza e sorgenti |
| --- | --- | --- |
| whisper_ggml | 2.8.0 | MIT; [pub.dev](https://pub.dev/packages/whisper_ggml/versions/2.8.0), [repository](https://github.com/sk3llo/whisper_ggml) |
| whisper.cpp | 1.9.1, incluso in whisper_ggml | MIT; [sorgenti upstream](https://github.com/ggml-org/whisper.cpp/tree/v1.9.1); testo incluso in `licenses/whisper.cpp-MIT.txt` |
| ffmpeg_kit_flutter_new_min | 2.1.0 | LGPL-3.0; [pacchetto con sorgenti Flutter](https://pub.dev/packages/ffmpeg_kit_flutter_new_min/versions/2.1.0), [repository del plugin](https://github.com/sk3llo/ffmpeg_kit_flutter) |
| com.antonkarpenko:ffmpeg-kit-min | 1.0.3 | LGPL-3.0 secondo il POM Maven; dichiarato FFmpeg 7.1.1 Min; [metadati del pacchetto](https://central.sonatype.com/artifact/com.antonkarpenko/ffmpeg-kit-min/1.0.3) |

La distribuzione binaria pubblica resta sospesa finché non è verificata la disponibilità dei sorgenti corrispondenti al componente nativo `ffmpeg-kit-min:1.0.3`. Il POM indica `https://github.com/sk3llo/ffmpeg-kit-flutter`, che durante il controllo del 14 ottobre 2026 ha restituito 404. Il repository del plugin Flutter è disponibile ma non è stato confermato come fonte completa e corrispondente delle librerie native precompilate. Non presentare sorgenti di una versione diversa come quelli del binario distribuito.

La Release preparata è una bozza per il titolare del repository. Per renderla pubblica occorre ottenere e fornire i sorgenti corrispondenti con le informazioni di ricompilazione, oppure sostituire questo componente con una soluzione distribuibile e ricollaudarla. Non è stato contattato il manutentore del componente.

La LGPL non rende a pagamento il progetto. Sono obblighi di distribuzione distinti dal prezzo. Per i requisiti vedi [LGPL-3.0](https://www.gnu.org/licenses/lgpl-3.0.html). Le informazioni per compilare e installare una propria versione dell’app sono in `docs/firma-android.md`; la chiave privata del progetto non viene distribuita.

I modelli Whisper e Silero vengono scaricati separatamente dall’app; non sono inclusi nell’APK o nel repository. Collegamenti, dimensioni e checksum sono in `lib/transcriber_native.dart`.
