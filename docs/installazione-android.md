# Installare su un altro telefono senza collegarlo al PC

Il pacchetto Android è un file `.apk`. Il codice scaricato tramite “Source code (zip)” non installa l’app.

Quando è disponibile una Release pubblica, dal telefono apri il repository, vai in Releases, scarica l’allegato APK e aprilo. Se Android richiede il permesso per installare da quel browser, segui la richiesta e poi premi Installa. Non è richiesto il collegamento USB. I messaggi di verifica dipendono dalle impostazioni e dalla versione Android; non disattivare le protezioni del dispositivo per ignorare un blocco.

La prima build firmata è 0.4.1, build 8, per telefoni ARM64 con Android 7.0 o successivo. Il modello di trascrizione, circa 191 MB, viene scaricato separatamente nelle impostazioni. Per ricevere i sogni di un altro dispositivo, collega la stessa cartella cloud e premi Sincronizza. Nessun sogno è incluso nell’APK.

Al momento il download firmato è in una **Release in bozza**, accessibile soltanto al titolare e ai collaboratori autorizzati del repository. Il titolare può aprire Releases dal nuovo telefono dopo essere entrato nel proprio account GitHub e scaricare l’APK della bozza per una prova personale. La disponibilità pubblica richiede prima di completare il controllo descritto in `THIRD_PARTY_NOTICES.md`.

Il telefono su cui è stato installato il prototipo USB usa una firma di sviluppo diversa: non installare sopra quel prototipo il nuovo pacchetto aspettandoti un aggiornamento diretto. Per un eventuale passaggio occorre prima sincronizzare e verificare l’archivio; la disinstallazione cancella la copia locale. La build pubblica è pensata per la prima installazione su altri telefoni. Vedi `docs/firma-android.md` per gli aggiornamenti e il backup della chiave.
