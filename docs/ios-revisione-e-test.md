# iPhone: revisione del codice e prove

Questa è una versione iOS preliminare dello stesso progetto Flutter. La Release iOS contiene i sorgenti, non un'app firmata installabile con un tocco. La Release Android rimane separata e utilizzabile.

## Stato verificato

Il [controllo macOS/Xcode](https://github.com/SboMusic/diario-sogni/actions/runs/38584268550) ha superato analisi, 21 test Dart, 4 test nativi, compilazione simulatore e compilazione iPhone senza firma. Minimo iOS 15. Le prove reali sul telefono elencate sotto restano necessarie: i test nativi non eseguono la trascrizione con il modello né verificano un servizio cloud.

## Scaricare dal proprio PC

Aprire https://github.com/SboMusic/diario-sogni e scegliere Code → Download ZIP, oppure scaricare Source code (zip) dalla Release iOS. Estrarre la cartella e aprirla con VS Code. Questi passaggi funzionano anche su Windows: servono per leggere e modificare i file, non per installare l'app su iPhone.

I file specifici sono `ios/Runner`, `ios/Native/DreamPlatform.swift`, `ios/Podfile`, `DreamNative.podspec` e `.github/workflows/ios-check.yml`. Il codice comune è in `lib`; i sorgenti Whisper CPU sono in `vendor/whisper-native`. Nessuna credenziale Apple, chiave privata, modello o registrazione personale è inclusa.

## Funzioni preparate

| Funzione | Implementazione iOS |
| --- | --- |
| Registrazione, pausa/ripresa e ascolto | Plugin Flutter record e just_audio; registrazione AAC/M4A |
| Titolo automatico e data/ora | Codice comune, con flusso registrazione → riepilogo → Salva → home |
| Archivio locale e ricerca | Sembast nella cartella privata, ricerca in titolo e testo |
| Modifica di titolo e trascrizione | Codice comune, conservazione del testo automatico originale |
| Cancellazione | Rimozione di audio e testi, segnale di cancellazione nell'archivio condiviso |
| Trascrizione locale | Whisper small multilingue Q5_1 e Silero; download verificato di circa 191 MB |
| Conversione audio | AVFoundation, WAV mono a 16 kHz per il motore |
| Cartella condivisa | Selezione tramite File, autorizzazione persistente con bookmark, accesso coordinato ai file |
| Sincronizzazione | Manuale, stesso formato di Android e PC, checksum e ricevute prima dell'importazione |
| Background | Richiesta del tempo aggiuntivo concesso da iOS; durata limitata e nessuna garanzia su audio lunghi |

Riepiloghi settimanali/mensili, assistenti IA esterni, connettori OAuth e sincronizzazione automatica non sono ancora disponibili neppure nella versione Android: non sono stati aggiunti soltanto per iOS.

La versione Apple usa i formati decodificabili da AVFoundation. Gli audio M4A di Android e iPhone sono il percorso previsto. Gli audio WebM/Opus registrati dal browser possono essere importati nell'archivio, ma ascolto e trascrizione su iPhone richiedono ancora un decoder compatibile: non è garantito il loro supporto.

## Build automatica e verifica gratuita sul Mac di GitHub

Alla pubblicazione di una GitHub Release, il workflow `Build release artifacts` compila Android e iOS firmati e allega `DiarioSogni-iOS.ipa` e l'APK alla release. L'IPA è Ad Hoc: si installa via OTA solo sui dispositivi registrati nel profilo di provisioning. Servono le secret descritte in [configurare le secret di release](configurazione-secret-release.md); senza di esse la build si blocca. Il risultato non include credenziali Apple, certificati o simboli privati.

Nel repository scegliere Actions → Verifica iPhone per le verifiche. Il controllo usa un runner macOS standard per repository pubblico, senza certificati e senza account sviluppatore Apple. Esegue analisi Dart, test comuni, compilazione per simulatore, prove native del convertitore e compilazione iPhone senza firma.

Il risultato `iOS-compilazione-non-firmata` serve come controllo di compilazione. Il file `DiarioSogni-iOS-NON-FIRMATO.zip` contiene Runner.app senza firma: non è un installer e non si installa direttamente aprendolo su iPhone. I simboli privati non vengono allegati. Controllare che il workflow sia verde: l'esistenza dei sorgenti o dell'archivio non dimostra che tutte le prove siano passate.

## Compilare e provare su iPhone

Serve un ambiente macOS con Xcode, locale o remoto; avere solo un iPhone e un PC Windows non sostituisce Xcode. Installare Flutter 3.47.7 e CocoaPods, poi dal progetto:

```sh
flutter pub get
flutter analyze
flutter test
flutter build ios --simulator --debug
open ios/Runner.xcworkspace
```

In Xcode selezionare Runner → Signing & Capabilities, scegliere il proprio team Apple e, se necessario, un identificativo app personale. Non modificare la firma Android. Collegare il proprio iPhone, abilitare le opzioni sviluppatore richieste da Apple e avviare Runner. L'account Apple e i certificati si configurano privatamente sul Mac: non caricarli su GitHub.

Un account Apple gratuito consente prove personali con firma di breve durata (7 giorni), che va rinnovata. TestFlight e App Store richiedono il programma sviluppatori a pagamento. Un file IPA allegato a GitHub non elimina questi requisiti. Prima di scegliere App Store va verificata anche l'identità pubblica del venditore: il nome SboMusic nel codice non garantisce che Apple mostri soltanto quel nome.

## Prove sul telefono da comunicare

Usare inizialmente sogni di prova e una cartella separata, evitando di eliminare contenuti reali durante i test.

1. Negare il microfono: mostrare l'errore senza creare un sogno. Poi autorizzarlo e registrare un audio breve.
2. Verificare pausa/ripresa, titolo con giorno/data/ora, ascolto e Salva senza testo. Salva deve tornare alla home.
3. Riavviare l'app: audio e titolo devono restare. Modificare titolo e testo; cercare una parola presente nella trascrizione.
4. Scaricare il modello, poi disattivare Internet. Registrare una frase italiana e una inglese; attendere la trascrizione con l'app aperta. Correggere il testo e verificare che una trascrizione successiva non sovrascriva la correzione.
5. Provare un audio più lungo, passare alla home dell'iPhone e poi tornare. Annotare se iOS sospende il lavoro; se il sistema termina il processo, l'audio deve restare salvato e la trascrizione deve essere riprovabile dal dettaglio. Non è previsto il riavvio automatico dopo arresto forzato.
6. Attivare il servizio scelto nell'app File. Collegare una cartella di prova contenente l'archivio condiviso o il suo contenitore, premere Sincronizza e verificare gli stessi sogni su Android/PC. I servizi che non consentono la selezione di una cartella non sono utilizzabili con questo metodo.
7. Chiudere e riaprire l'app: verificare il recupero del collegamento. Provare temporaneamente senza rete e poi risincronizzare.
8. Cancellare un sogno di prova, sincronizzare gli altri dispositivi e verificare che spariscano audio e testi senza ricomparire.

Per ogni problema riportare modello di iPhone, versione iOS, versione del progetto o commit, passaggi, risultato atteso e risultato effettivo. Evitare di allegare audio personali, percorsi identificativi, credenziali o screenshot del proprio account.

## Fonti

- Flutter iOS: https://docs.flutter.dev/deployment/ios
- Tempo in background Apple: https://developer.apple.com/documentation/uikit/extending-your-app-s-background-execution-time
- Cartelle Apple: https://developer.apple.com/documentation/uikit/providing-access-to-directories
- Account e limiti Apple: https://developer.apple.com/help/account/basics/about-your-developer-account
- Runner GitHub: https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job
