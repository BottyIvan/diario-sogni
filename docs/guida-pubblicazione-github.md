# Pubblicare il diario e installarlo su altri telefoni

## Primo passo: creare il repository

Accedi al tuo account su GitHub. Premi **+ → New repository**, inserisci **diario-sogni** come nome e scegli **Public** per permettere a tutti di leggere il codice e scaricare i pacchetti. Lascia disattivata l’aggiunta iniziale di README, .gitignore e licenza: prepareremo questi file dal progetto locale. Premi **Create repository** e copia l’indirizzo della pagina del repository.

L’app da caricare è nella cartella locale `diario-sogni`. Non caricare la cartella `sources`, gli audio personali, i modelli scaricati o le chiavi di firma. Il file .gitignore esclude i principali file generati, audio di collaudo e credenziali locali.

## Secondo passo: caricare il codice

Una volta noto l’indirizzo del repository, colleghiamo il progetto locale con Git. Se GitHub richiede accesso, l’autenticazione deve essere completata personalmente dal titolare dell’account. Non condividere password o codici di accesso nella chat.

Il caricamento avviene tramite Git, non trascinando tutta la cartella nel sito: Git rispetta il .gitignore, conserva le versioni e permette di pubblicare gli aggiornamenti. Prima del primo invio verifichiamo l’elenco dei file inclusi.

## Terzo passo: pubblicare una versione

Prima di creare una release, aggiorna il numero di versione in `pubspec.yaml` e invia la modifica sul repository. Nel repository apri **Releases → Draft a new release**, scegli il tag che identifica quel commit, un titolo e descrivi quali funzioni sono disponibili. Alla pubblicazione della release, GitHub Actions compila Android e iOS e allega automaticamente i due artefatti; il numero di build viene assegnato dal workflow. Il workflow si avvia quando la release viene pubblicata, non quando è ancora una bozza; richiede che le Actions siano abilitate nel repository.

Gli allegati firmati sono `DiarioSogni-Android-ARM64.apk` e `DiarioSogni-iOS.ipa` (Ad Hoc, per i dispositivi registrati nel profilo). La compilazione Android è limitata ai telefoni ARM64. Se mancano le secret di firma nel repository, la build si blocca prima di compilare e indica la guida: [configurare le secret di release](configurazione-secret-release.md). Il file **Source code (zip)** contiene invece i sorgenti. La versione PC autonoma avrà un pacchetto separato, da preparare: il launcher attuale usa gli strumenti disponibili su questo PC.

## Installazione su un altro telefono, senza cavo

1. Dal telefono apri la pagina GitHub del progetto e vai in **Releases**.
2. Scarica l’allegato **.apk**.
3. Apri il file scaricato. Se Android lo richiede, autorizza il browser o il gestore file a installare da quella fonte.
4. Premi **Installa** e poi **Apri**.
5. Consenti il microfono quando richiesto. Il modello di trascrizione si scarica separatamente dalle impostazioni dell’app.
6. Per ricevere i sogni esistenti, collega la stessa cartella cloud e premi **Sincronizza**. Se non colleghi una cartella, il nuovo telefono conserva un archivio locale indipendente.

I permessi e i messaggi di verifica dipendono dalla versione Android e dalle impostazioni del telefono. GitHub distribuisce il file ma non installa l’app automaticamente. Non è necessario collegare il telefono al PC. Non serve pubblicare l’app sul Play Store per questo percorso.

Per una prova privata prima della pubblicazione puoi trasferire sul telefono l’APK già preparato nella cartella locale `distribuzione/prove`. Questa copia non contiene le registrazioni presenti sul primo telefono.

## Aggiornamenti successivi

Pubblicheremo una nuova release e un nuovo APK, con numero di versione superiore e la stessa firma. L’utente scaricherà e installerà l’aggiornamento sopra la versione precedente. Gli aggiornamenti automatici dall’interno dell’app non sono ancora implementati.

Riferimenti: [gestione delle Releases GitHub](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository), [compilazione e firma Android con Flutter](https://docs.flutter.dev/deployment/android), [distribuzione Android al di fuori del Play Store](https://developer.android.com/distribute/marketing-tools/alternative-distribution).

## Pubblicare il portale guide con GitHub Pages

Il portale è realizzato con Docusaurus nella cartella `website/`; le guide in Markdown restano in `docs/`. Il menu laterale si aggiorna da `website/sidebars.js` e la pagina iniziale è in `website/src/pages/index.js`.

Per vedere il sito sul proprio PC servono Node.js 20 o successivo. Dal terminale, nella cartella del progetto, esegui:

```sh
cd website
npm ci
npm start
```

Il sito si apre all’indirizzo indicato nel terminale. Per pubblicarlo, il workflow `.github/workflows/gh-pages.yml` installa le dipendenze, genera il sito e lo carica automaticamente a ogni push sul branch `main`. Per la prima pubblicazione:

1. Apri **Settings → Pages** nel repository GitHub.
2. In **Build and deployment**, scegli **GitHub Actions**.
3. Invia le modifiche sul branch `main` e controlla il workflow **Deploy to GitHub Pages** nella sezione Actions.
4. Attendi il completamento della pubblicazione: l’indirizzo del sito compare nella stessa sezione **Pages**.

Le modifiche alle guide Markdown o al portale vengono pubblicate automaticamente dopo il push sul branch `main`.
