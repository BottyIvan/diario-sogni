# Diario dei sogni — versione di prova 0.4.2

Il codice è pubblico e gratuito con licenza MIT. Il pacchetto Android gratuito è disponibile nella [Release di prova 0.4.2](https://github.com/SboMusic/diario-sogni/releases/tag/v0.4.2), verificato con audio sintetici e controllo dei percorsi personali. La distribuzione PC autonoma resta da preparare; il launcher incluso usa gli strumenti presenti sul PC di sviluppo.

Per installare su un altro telefono senza USB consulta la [guida Android](docs/installazione-android.md). Le informazioni per conservare la chiave e firmare gli aggiornamenti sono in [firma Android](docs/firma-android.md). Nessuna chiave privata, registrazione o credenziale è inclusa nel repository.

App Flutter per Android e browser. Questa fase implementa registrazione e archivio locali e trascrizione locale Android, con riconoscimento automatico della lingua e servizio per l’elaborazione in background; l’analisi completa si trova nella cartella docs.

## Versione iPhone preliminare

Il progetto iOS è incluso per revisione e prove. Vedi la [guida iPhone](docs/ios-revisione-e-test.md): descrive compilazione su GitHub/macOS, firma e test sul dispositivo. Il supporto Apple non è ancora collaudato su un iPhone reale; il tempo di trascrizione in background è limitato da iOS. Il file non firmato non si installa direttamente come un APK. Le Release iOS sono separate da quelle Android.

## Disponibile

- Registrazione audio locale, pausa, ripresa e salvataggio con data e ora di inizio.
- Archivio cronologico e ascolto, con pausa e avanzamento.
- Modifica del titolo e aggiunta/modifica del testo.
- Trascrizione automatica locale su Android con Whisper small multilingue quantizzato Q5_1 e rilevamento della voce Silero, dopo la disponibilità dei modelli.
- Conservazione del testo automatico originale separato dalle correzioni dell’utente.
- Trascrizione Android che continua fuori dalla schermata dell’app, con notifica temporanea silenziosa e nessun selettore di lingua.
- Ricerca nei titoli e nei testi, senza distinzione tra maiuscole e minuscole.
- Guida nell’app, messaggi di errore e salvataggio ripetibile in caso di errore.
- Nessun account obbligatorio, servizio IA o promemoria.
- Cancellazione confermata di audio, titolo e trascrizioni, anche durante una trascrizione attiva.
- Collegamento facoltativo di una cartella Android o PC e sincronizzazione manuale di audio, testi e cancellazioni.
- Applicazione PC nel browser, con avvio locale e scelta della cartella da Chrome o Edge.

Trascrizione nel browser, riepiloghi e IA esterna **non sono ancora implementati**. Android e browser conservano copie locali separate, sincronizzabili con lo stesso archivio di cartella. Sul PC si può scegliere una cartella sincronizzata da Drive, Dropbox o altri servizi; sul telefono il servizio deve esporre una cartella selezionabile. L’accesso OAuth diretto agli account non è ancora implementato. Il salvataggio nella cartella Drive scelta sul telefono è stato confermato dall’utente.

La [guida dell’archivio condiviso](docs/guida-archivio-condiviso.md) descrive cancellazione, collegamento e utilizzo sul PC. Aprire `Apri diario sul PC.cmd` dalla cartella del progetto per avviare il browser su `http://127.0.0.1:8787/`.

## Formato dell’archivio condiviso

L’app riconosce l’archivio selezionato direttamente tramite il suo nome o file identificativo, altrimenti apre o crea `Diario dei sogni` nel contenitore scelto. `diario-sogni-archive.json` identifica formato e schema. Gli audio sono `audio_<id>.m4a` o `.webm`; ogni modifica ha un file immutabile `sogno_<id>_<revisione>.json`, seguito da una ricevuta `.ready` con SHA-256. Una revisione senza ricevuta non viene importata. Gli audio e i metadati vengono verificati prima del commit. Le revisioni sono timestamp a microsecondi, monotoni per sogno sul singolo dispositivo, seguiti da un suffisso casuale. Non condividere il database Sembast.

`eliminato_<id>.json` prevale su tutte le revisioni: la sincronizzazione rimuove audio e metadati corrispondenti, mantenendo soltanto il segnale di cancellazione. Il database locale conserva un percorso pendente solo fino alla rimozione del file. Le transazioni impediscono a vecchi editor e risultati automatici di ripristinare dati eliminati. Le revisioni precedenti dei sogni attivi restano nella cartella; la fusione assistita dei conflitti è futura. Il prototipo gestisce al massimo 100 MB per audio e legge i file in memoria; non ha cifratura autonoma dei file condivisi.

Android usa Storage Access Framework con accesso persistente al solo albero scelto. Il browser usa File System Access API e ricorda il directory handle in IndexedDB, richiedendo nuovamente il permesso quando necessario. Il trasferimento tra dispositivi è a carico del servizio scelto e può essere successivo alla scrittura locale. La sincronizzazione automatica al ritorno della rete e i connettori OAuth restano da implementare.

## Attivare la trascrizione Android

Dal riepilogo o dalle impostazioni scegliere **Scarica modello locale**. Il download iniziale è circa 191 MB, da Hugging Face, e viene verificato con dimensione e SHA-256. Questo trasferimento riguarda soltanto i modelli, non gli audio. Senza modello si può comunque registrare, ascoltare, salvare e scrivere il testo.

Quando il modello è disponibile, i nuovi audio vengono trascritti automaticamente. Per i precedenti aprire il singolo sogno. La lingua viene riconosciuta dal modello, senza selezioni o etichette di lingua. Non viene richiesta la traduzione dell’audio. Il riconoscimento di parole in altre lingue può comunque contenere errori: le correzioni restano disponibili.

La trascrizione avviene sul telefono anche senza Internet. Dopo aver terminato la registrazione si può salvare, passare a un’altra app o spegnere lo schermo. Il servizio mantiene attivo il motore soltanto durante la coda di elaborazione, con una notifica senza suono né vibrazione; al termine o in caso di errore il servizio si ferma. Android può chiedere il permesso notifiche al primo utilizzo. Non ci sono promemoria né notifiche di completamento.

L’arresto forzato dell’app, un riavvio o la terminazione del processo da parte del sistema possono interrompere il lavoro: l’audio resta salvato e si può riprovare aprendone il dettaglio. La coda non è ancora un pianificatore persistente che riparte automaticamente dopo il riavvio del telefono.

Il testo automatico è incluso nella ricerca e si può correggere. Le correzioni già salvate non vengono sostituite da un risultato automatico arrivato successivamente. Il testo automatico originale è consultabile separatamente. Se il motore fallisce, l’audio resta disponibile e il pulsante **Riprova trascrizione** consente un nuovo tentativo. I modelli non generano riepiloghi o interpretazioni dei sogni.

## Prova sul telefono

1. Aprire **Diario dei sogni**.
2. Toccare **Racconta un sogno** e autorizzare il microfono.
3. Parlare, usare **Pausa/Riprendi** se necessario, quindi **Termina e salva**.
4. Dopo **Termina e salva** si apre il riepilogo del singolo sogno: qui si può ascoltare l’audio, modificare il titolo o aggiungere un testo. L’audio è già conservato localmente.
5. Toccare **Salva sogno** per salvare e tornare alla home. Il pulsante è disponibile anche senza inserire testo; il titolo vuoto viene sostituito dal titolo automatico. In caso di errore si rimane sulla schermata per riprovare.
6. Chiudere e riaprire l’app per verificare la conservazione del sogno.

Se il salvataggio fallisce, mantenere aperta l’app e riprovare. L’indicazione «salvato» compare solo dopo la scrittura nell’archivio.

Cambiare app o bloccare lo schermo mette la registrazione in pausa; riprendere manualmente al ritorno. Registrazione in background e recupero dopo arresto forzato non sono supportati in questa fase. Salvare prima di chiudere. Disinstallazione e cancellazione dei dati eliminano l’archivio locale.

## Struttura

- `lib/dream.dart`: modello e ricerca.
- `lib/dream_repository.dart`: archivio Sembast.
- `lib/storage_native.dart`: database e audio nell’area privata Android.
- `lib/storage_web.dart`: persistenza IndexedDB; audio conservati con i dati, senza collegamenti temporanei.
- `lib/recording_controller.dart`: registrazione e recupero degli errori di salvataggio.
- `lib/transcriber_native.dart`: download verificato e inferenza locale Android.
- `lib/transcription_manager.dart`: coda di elaborazione, stati, errori e applicazione del testo senza sovrascrivere le correzioni.
- `lib/background_guard.dart`: gestione condivisa del servizio durante le elaborazioni accettate.
- `lib/whisper_request.dart`: contratto del motore nativo, con lingua automatica e traduzione disattivata.
- `android/.../TranscriptionService.kt`: servizio, notifica silenziosa e mantenimento temporaneo della CPU.
- `android/.../LocalAudioConverter.kt`: conversione audio legata al contesto dell’applicazione, funzionante anche dopo la chiusura della schermata.
- `lib/main.dart`: interfaccia e ascolto.
- `test/diary_test.dart`: riapertura del database, ricerca, microfono negato e ripetizione del salvataggio.
- `test/transcription_test.dart`: concorrenza tra salvataggio e trascrizione, coda e recupero da errori.
- `lib/transcription_smoke.dart`: ingresso separato per il collaudo sul telefono con audio sintetico; non è la schermata normale dell’app.
- `lib/background_smoke.dart`: collaudo separato con audio sintetico misto e inglese e database dedicato; non modifica l’archivio dell’utente.
- `tools/generate-icons.ps1`: generazione delle icone.

Nel browser l’archivio appartiene all’indirizzo del sito e al profilo del browser. Cancellare i dati del sito elimina l’archivio; evitare la modalità privata. Il microfono richiede HTTPS o localhost. La compilazione web non equivale alla pubblicazione né garantisce ancora l’installazione offline.

Il riconoscimento automatico è stato verificato con audio sintetici separati in italiano e inglese. Nel campione con cambio di voce e di lingua, una frase inglese è stata omessa anche disattivando il rilevamento della voce: la precisione degli audio misti resta da migliorare e verificare con registrazioni reali. Il testo è sempre correggibile.

## Sviluppo

Aprire `diario-sogni.code-workspace` dalla cartella superiore con VS Code. Gli strumenti sono descritti in `ambiente-sviluppo.md`.

```text
flutter pub get
flutter analyze
flutter test
flutter run -d <dispositivo>
flutter build apk --debug
flutter build web
```

Pacchetto Android: `it.diariosogni.diario_sogni`. Android minimo: API 24. L’APK usa la firma di sviluppo e non è pronto per lo store. Il backup automatico Android è disabilitato; nessun backup cloud dell’app è attivo.

## Componenti e modelli

- [whisper_ggml](https://pub.dev/packages/whisper_ggml) 2.8.0, basato su whisper.cpp; conversione audio tramite FFmpeg locale.
- [Modelli Whisper per whisper.cpp](https://huggingface.co/ggerganov/whisper.cpp).
- [Modelli di rilevamento della voce](https://huggingface.co/ggml-org/whisper-vad).

Le integrazioni devono essere mantenute compatibili con le versioni di Flutter/Android. Il componente FFmpeg attuale segnala una futura migrazione del supporto Kotlin; la compilazione corrente riesce. Licenze e distribuzione finale dei componenti vanno documentate prima del rilascio pubblico.

Whisper GGML è fissato alla versione 2.8.0 perché il collegamento diretto usa il relativo contratto nativo. La conversione non usa il canale del plugin legato all’Activity: questo evita il distacco del convertitore quando la schermata Android viene distrutta. La tipologia del servizio è `mediaProcessing` su Android 15 o superiore e `dataSync` per l’elaborazione dei file locali nelle versioni precedenti. Il motore Flutter è conservato oltre la vita della singola Activity, durante il lavoro del servizio.
