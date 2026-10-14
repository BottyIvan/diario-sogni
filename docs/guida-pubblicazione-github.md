# Pubblicare il diario e installarlo su altri telefoni

## Primo passo: creare il repository

Accedi al tuo account su GitHub. Premi **+ → New repository**, inserisci **diario-sogni** come nome e scegli **Public** per permettere a tutti di leggere il codice e scaricare i pacchetti. Lascia disattivata l’aggiunta iniziale di README, .gitignore e licenza: prepareremo questi file dal progetto locale. Premi **Create repository** e copia l’indirizzo della pagina del repository.

L’app da caricare è nella cartella locale `diario-sogni`. Non caricare la cartella `sources`, gli audio personali, i modelli scaricati o le chiavi di firma. Il file .gitignore esclude i principali file generati, audio di collaudo e credenziali locali.

## Secondo passo: caricare il codice

Una volta noto l’indirizzo del repository, colleghiamo il progetto locale con Git. Se GitHub richiede accesso, l’autenticazione deve essere completata personalmente dal titolare dell’account. Non condividere password o codici di accesso nella chat.

Il caricamento avviene tramite Git, non trascinando tutta la cartella nel sito: Git rispetta il .gitignore, conserva le versioni e permette di pubblicare gli aggiornamenti. Prima del primo invio verifichiamo l’elenco dei file inclusi.

## Terzo passo: pubblicare una versione scaricabile

Nel repository apri **Releases → Draft a new release**. Associa una versione al codice, scegli un titolo e descrivi quali funzioni sono disponibili. Allega il file APK preparato per quella versione, quindi pubblica la release. Un repository pubblico permette agli utenti di scaricare il pacchetto senza accedere al tuo account.

Il file **Source code (zip)** contiene il codice: non installa l’app. Il file con estensione **.apk** è il pacchetto Android. La versione PC autonoma avrà un pacchetto separato, da preparare: il launcher attuale usa gli strumenti disponibili su questo PC.

Prima del rilascio pubblico occorre preparare una build Android release con firma stabile, conservare privatamente la chiave e documentare licenze e dispositivi supportati. L’APK disponibile oggi è una build di prova 0.4.1, preparata per telefoni ARM64 con Android 7.0 o successivo. Non presentarlo come versione definitiva per tutti i telefoni. Cambiare firma impedisce l’aggiornamento diretto di un’app già installata con una firma diversa: le prove attuali e il passaggio alla firma definitiva vanno gestiti senza perdere l’archivio.

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
