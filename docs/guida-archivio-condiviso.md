# Usare il diario sul telefono e sul PC

Versione 0.4.1 — 14 ottobre 2026

## Cancellare un sogno

Apri il sogno e premi il cestino in alto. La richiesta di conferma indica cosa verrà eliminato. Premi **Elimina** per cancellare audio, titolo, testo corretto e trascrizione originale, oppure **Annulla** per conservarli. Dopo la cancellazione torni alla home e il sogno scompare anche dalla ricerca.

Se è in corso la trascrizione, l’app attende la fine dell’elaborazione prima di rimuovere il file. Il risultato arrivato dopo la richiesta non ripristina il sogno.

Quando usi una cartella condivisa, premi **Sincronizza** sul dispositivo che ha eliminato il sogno, attendi il trasferimento del servizio cloud, poi sincronizza l’altro dispositivo. La cancellazione si applica anche lì. Un dispositivo offline conserva la propria copia fino alla prossima sincronizzazione.

Questa versione non ha cestino né ripristino. Il servizio cloud può mantenere autonomamente cestino, versioni precedenti o copie di backup: la cancellazione nell’app non svuota il cestino dell’account cloud. Rimane un piccolo segnale di eliminazione contenente soltanto l’identificativo, per impedire che una copia offline faccia riapparire il sogno.

## Collegare il telefono

1. Apri **Impostazioni → Collega cartella**.
2. Nel selettore Android scegli una cartella che possa contenere l’archivio. Può essere locale o resa disponibile da un servizio cloud. Concedi l’accesso alla cartella scelta.
3. Puoi scegliere direttamente **Diario dei sogni** oppure la cartella che la contiene. L’app riconosce l’archivio esistente; se scegli un contenitore nuovo, crea al suo interno **Diario dei sogni**.
4. Premi **Sincronizza**. Un messaggio indica quanti sogni sono stati inviati e ricevuti.
5. Attendi che il servizio cloud finisca di trasferire i file prima di sincronizzare dal PC.

Le registrazioni nuove e le modifiche vengono prima salvate sul dispositivo. In questa versione il trasferimento dell’app è manuale: dopo aver registrato o modificato un sogno, premi nuovamente **Sincronizza**. Senza connessione puoi continuare a registrare e riprovare il trasferimento più tardi. Non vengono inviati audio a servizi di IA.

Un’app cloud installata non garantisce che Android consenta l’accesso alle sue cartelle: dipende dal suo fornitore di documenti. Se il servizio non appare o non permette la selezione, il collegamento diretto con account non è ancora implementato. In alternativa il servizio può trasferire una cartella locale. Non inserire password o credenziali nei file dell’archivio.

## Aprire il diario sul PC

Se Google Drive per desktop non è installato, usa il [programma ufficiale e la guida Google](https://support.google.com/a/users/answer/13022292?hl=it). Dopo l’installazione apri **Google Drive**, premi **Accedi** e completa personalmente l’accesso allo stesso account del telefono. Per il diario serve la cartella che hai già creato nel cloud; non è necessario aggiungere cartelle del PC al backup. Attendi che in Esplora file compaia **Google Drive**, quindi cerca al suo interno il contenitore dell’archivio. Puoi scegliere direttamente **Diario dei sogni** o il suo contenitore: dalla versione 0.4.1 vengono riconosciuti entrambi.

Su questo PC apri **Apri diario sul PC.cmd**, nella cartella del progetto. Il collegamento avvia il diario in Edge, oppure nel browser predefinito se Edge non è disponibile. L’indirizzo è **http://127.0.0.1:8787/**. Il servizio è accessibile solo da questo PC.

1. Usa Chrome o Edge. Apri **Impostazioni → Collega cartella**.
2. Scegli in Esplora file la cartella **Diario dei sogni** sincronizzata dal telefono, oppure quella che la contiene. Per Google Drive o Dropbox deve essere disponibile sul PC tramite il relativo programma di sincronizzazione; un indirizzo del sito cloud non è un percorso di cartella.
3. Consenti al browser la lettura e scrittura della cartella. Il selettore sostituisce l’inserimento manuale del percorso, per rispettare i permessi del browser.
4. Premi **Sincronizza**. I sogni ricevuti vengono copiati nell’archivio locale del browser.
5. In **Sogni** apri una registrazione per ascoltarla o modificarne titolo e testo. In **Cerca** usa le parole della trascrizione, per esempio “coniglio blu”.

Il browser può richiedere nuovamente il permesso dopo la riapertura. Il collegamento alla cartella viene ricordato nello stesso profilo e allo stesso indirizzo. Cancellare i dati del sito elimina la copia locale e il collegamento: puoi ricollegare la cartella e ricevere di nuovo i sogni ancora presenti nell’archivio condiviso. Evita la modalità privata. La trascrizione locale del browser non è ancora disponibile; le trascrizioni ricevute dal telefono si possono consultare, cercare e modificare.

La versione per PC è un’app browser servita localmente, non un programma Windows nativo e non un sito pubblicato. Il collegamento di avvio usa il Python già disponibile nell’ambiente di questo PC; la distribuzione autonoma su altri PC richiede ancora una confezione dedicata o un sito HTTPS.

## Cambiare o scollegare cartella

**Scollega** interrompe l’accesso ma conserva la copia locale. **Cambia cartella** seleziona un nuovo contenitore: alla successiva sincronizzazione i sogni locali vengono inviati a quel contenitore e quelli presenti lì vengono ricevuti. Non trasferisce né elimina automaticamente il vecchio archivio. Cambiare account o contenitore non è una fusione anonima: i dati dell’archivio locale verranno copiati nella nuova destinazione che scegli.

## Se il trasferimento non riesce

Controlla connessione, permessi e spazio libero, verifica che la cartella sia disponibile e attendi il trasferimento del servizio cloud. Poi riprova **Sincronizza**. L’app controlla l’integrità degli audio e importa il sogno soltanto se i file sono completi. Non eliminare manualmente i file identificativi dell’archivio.

Limite attuale: 100 MB per audio. La sincronizzazione legge gli audio in memoria e non è ancora ottimizzata per archivi molto grandi. Usa orari corretti su entrambi i dispositivi: se modifichi lo stesso sogno offline su entrambi, prevale la versione con revisione più recente; le precedenti rimangono come file nell’archivio finché il sogno non viene eliminato. La fusione manuale dei conflitti è un’attività futura.

## Come viene conservato l’archivio

La sottocartella **Diario dei sogni** contiene un file che identifica il formato, gli audio originali, i file dei sogni con titolo, data e trascrizioni, e ricevute di integrità. Non viene condiviso il database del dispositivo, che non è adatto a essere scritto contemporaneamente da telefono e browser.

I file condivisi non sono cifrati dall’app: sono leggibili da chi ha accesso alla cartella e dal servizio di archiviazione scelto. La cifratura autonoma dell’archivio resta da sviluppare. Collegare una cartella non comporta l’apertura di un account dell’app né un collegamento con ChatGPT o altri assistenti.

Il selettore Android usa lo [Storage Access Framework](https://developer.android.com/training/data-storage/shared/documents-files), che permette l’accesso alle cartelle esposte dai fornitori di documenti. Sul PC l’accesso usa la [File System Access API](https://developer.chrome.com/docs/capabilities/web-apis/file-system-access), con scelta e permessi del browser.
