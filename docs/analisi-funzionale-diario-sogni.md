# Diario vocale dei sogni — analisi funzionale e piano di sviluppo

Versione 1.4 — 14 ottobre 2026

Documento di riferimento per la progettazione. I requisiti confermati sono distinti dalle proposte e dalle decisioni tecniche ancora aperte. Non costituisce una verifica di fattibilità dei singoli servizi o modelli.

## 1. Obiettivo

Consentire a una persona di raccontare un sogno a voce, conservarne l’audio, ottenere una trascrizione modificabile e ritrovarlo attraverso la ricerca. Offrire riepiloghi e individuazione di elementi ricorrenti su richiesta.

Android è la prima piattaforma. Un’applicazione accessibile dal browser su PC consentirà anche di registrare, ascoltare, modificare e consultare i sogni. I contenuti saranno condivisi tra i dispositivi dello stesso utente.

## 2. Decisioni confermate

| Area | Requisito |
| --- | --- |
| Registrazione | Disponibile localmente senza Internet; salvataggio con data e ora |
| Titolo | Automatico nel formato «Sogno: martedì 13/10/2026 18:30», modificabile |
| Trascrizione | Automatica per ogni registrazione e modificabile |
| Ricerca | Ricerca nel testo delle trascrizioni, per esempio «coniglio blu» |
| Riepiloghi | Avviati dall’utente; sintesi dei racconti ed elementi ricorrenti |
| Periodi | Ultimi sette giorni, mese e periodo personalizzato |
| PC | Accesso dal browser, inclusa la registrazione |
| Conservazione | Copia locale; archivio condiviso facoltativo scelto e collegato dall’utente su ogni dispositivo |
| Sincronizzazione | Manuale o automatica al ritorno della connessione |
| Elaborazione | Sul dispositivo come modalità predefinita |
| IA esterna | Opzione da progettare per collegare un fornitore e credenziali personali |
| Promemoria | Assenti; nessuna notifica per sollecitare la registrazione |

## 3. Confini della prima versione

La prima versione Android comprende registrazione, archivio, titoli modificabili, trascrizione locale modificabile, ricerca testuale, riepiloghi locali su richiesta e infrastruttura di sincronizzazione. Il completamento multipiattaforma comprende il browser e l’accesso allo stesso archivio.

Proposta di rilascio: realizzare prima il flusso Android locale, quindi sincronizzazione e browser. L’ordine dei rilasci va confermato; non riduce il perimetro funzionale concordato.

Non sono richiesti social network, condivisione pubblica, interpretazioni psicologiche, diagnosi, promemoria o elaborazione cloud obbligatoria.

## 4. Flussi utente

### 4.1 Prima apertura

L’utente può iniziare a registrare senza collegare un servizio di archiviazione. L’app spiega brevemente la conservazione locale e richiede l’accesso al microfono quando serve. Il collegamento dell’archivio condiviso è disponibile nelle impostazioni.

Archivio esterno e assistente IA sono scelte indipendenti, entrambe saltabili nella configurazione iniziale e modificabili successivamente. Senza collegamenti, salvataggio, trascrizione e riepiloghi avvengono sul dispositivo, previa disponibilità dei modelli locali. Senza archivio condiviso, telefono e browser mantengono archivi separati.

| Archivio esterno | IA esterna | Comportamento |
| --- | --- | --- |
| Non collegato | Non collegata | Salvataggio ed elaborazione locali, nessuna sincronizzazione |
| Collegato | Non collegata | Elaborazione locale e sincronizzazione dei contenuti |
| Non collegato | Collegata | Salvataggio locale; invio al servizio IA delle sole operazioni abilitate |
| Collegato | Collegata | Sincronizzazione ed elaborazione esterna per le operazioni abilitate |

Su Android e nel browser l’utente collega lo stesso servizio, account e archivio per ritrovare gli stessi sogni. L’accesso al servizio avviene tramite il flusso di autorizzazione previsto dal fornitore, senza chiedere di salvare la password del cloud nell’app.

Il significato di «stesso account» resta da definire: account dell’app oppure account del servizio di archiviazione. La proposta iniziale è usare l’identità del servizio collegato e un identificativo di archivio condiviso, evitando un account aggiuntivo se tecnicamente possibile.

### 4.2 Registrazione

1. L’utente avvia una registrazione da Android o browser.
2. L’interfaccia mostra durata e stato del microfono; propone pausa, ripresa e termine.
3. Al termine salva l’audio localmente, assegna un identificativo univoco e un titolo nel formato «Sogno: [giorno della settimana] [data] [ora]».
4. Inserisce la trascrizione nella coda locale di elaborazione.
5. L’utente può rinominare il sogno e ascoltarlo subito, anche mentre la trascrizione è in attesa.
6. Il contenuto entra nella coda di sincronizzazione se è stato collegato un archivio.

Il salvataggio non richiede l’inserimento di testo: il pulsante è disponibile da subito. Se il titolo viene svuotato, viene ripristinato il titolo automatico.

Dopo «Termina e salva», l’audio viene conservato e si apre il riepilogo del singolo sogno, con titolo, ascolto e testo modificabile. Il pulsante «Salva sogno» nel riepilogo salva le eventuali modifiche e torna alla home con l’elenco aggiornato. Il riepilogo del singolo sogno è distinto dai riepiloghi settimanali e mensili. Se il salvataggio fallisce, mantiene aperta la schermata e consente di riprovare.

Pausa e ripresa sono una proposta operativa. Gestione di chiamate, chiusura dell’app, blocco schermo e spazio insufficiente richiede prove dedicate. Non mostrare «salvato» prima della conferma del salvataggio locale.

### 4.3 Trascrizione e modifica

Ogni audio salvato genera un’attività di trascrizione. Gli stati sono: in attesa, in elaborazione, completata ed errore. L’utente può riprovare dopo un errore senza registrare di nuovo.

Conservare il testo automatico originale e una versione modificabile. Una nuova elaborazione non deve sovrascrivere silenziosamente le correzioni. Ricerca e riepiloghi usano il testo corrente modificato dall’utente.

La registrazione funziona offline; la prima disponibilità dell’elaborazione locale potrebbe richiedere il download dei modelli. Dopo la disponibilità dei modelli, trascrizione e riepiloghi devono funzionare senza Internet sui dispositivi supportati.

### 4.4 Ricerca

La ricerca include titolo e trascrizione corrente e propone un filtro temporale. I risultati mostrano titolo, data e un estratto pertinente, con accesso all’audio.

Per la prima versione si propone ricerca testuale senza distinzione tra maiuscole e minuscole. Ricerca per sinonimi o significato è un’estensione da valutare, non necessaria per soddisfare l’esempio «coniglio blu».

I sogni privi di trascrizione restano ricercabili per titolo. Un errore di trascrizione non deve far sparire la registrazione dall’archivio.

### 4.5 Riepiloghi

L’utente sceglie il periodo e avvia la generazione. La schermata mostra quali sogni sono inclusi e segnala quelli esclusi per assenza di trascrizione. Se non ci sono testi utilizzabili, spiega il motivo senza produrre un riepilogo vuoto o inventato.

Il risultato contiene una sintesi dei racconti e gli elementi ricorrenti, con collegamenti ai sogni di origine. Le ricorrenze devono indicare in quanti sogni distinti compare l’elemento, distinguendo questo numero dalle ripetizioni nello stesso testo. L’identificazione delle emozioni è descrittiva e deve distinguere emozioni esplicite da inferenze.

Salvare periodo, sogni inclusi, revisioni dei testi, data di generazione e motore utilizzato. Se una trascrizione cambia, indicare che il riepilogo potrebbe essere da aggiornare. La rigenerazione avviene su richiesta.

Proposta: «mese» indica un mese di calendario selezionabile; «ultimi sette giorni» include il giorno corrente e i sei precedenti, secondo il fuso dell’utente. Le regole finali devono essere visibili nell’interfaccia.

## 5. Schermate

| Schermata | Contenuto e azioni principali |
| --- | --- |
| Home | Pulsante registra, sogni recenti, stato sintetico della sincronizzazione |
| Registrazione | Durata, pausa/ripresa proposta, termina e salva |
| Archivio e ricerca | Elenco cronologico, ricerca, filtro temporale |
| Dettaglio sogno | Titolo, date, lettore audio, trascrizione modificabile, stati di elaborazione e sincronizzazione |
| Riepiloghi | Selezione periodo, generazione, risultati e riferimenti ai sogni |
| Impostazioni | Archivio collegato, sincronizzazione, modelli locali, opzione IA esterna, esportazione |

L’assenza di promemoria non impedisce messaggi di stato dentro l’app. Eventuali indicatori di sistema necessari alla registrazione su Android vanno verificati e non devono essere usati per sollecitare l’utente.

## 6. Archivio condiviso e sincronizzazione

L’utente sceglie tra i fornitori effettivamente implementati, con Google Drive e Dropbox previsti tra le opzioni da realizzare. Non promettere compatibilità con qualsiasi cartella cloud. L’ordine tecnico di implementazione sarà definito dopo la verifica delle integrazioni e non impone un unico servizio agli utenti.

La sincronizzazione è bidirezionale per audio, titoli, trascrizioni e riepiloghi salvati. Le credenziali non entrano nella cartella condivisa. La perdita della connessione non blocca registrazione, consultazione dei contenuti già disponibili o modifica locale.

Mostrare stati comprensibili: solo sul dispositivo, in attesa, sincronizzazione in corso, sincronizzato, errore e conflitto. L’utente può avviare una sincronizzazione manuale e riprovare un trasferimento fallito.

Ogni sogno mantiene lo stesso identificativo su tutti i dispositivi. I trasferimenti devono essere ripetibili senza generare duplicati. Non usare la sola data di modifica del dispositivo per scegliere quale versione conservare.

Proposta per i conflitti: unire modifiche a campi indipendenti; quando due dispositivi modificano lo stesso titolo o testo, conservare entrambe le versioni e chiedere all’utente quale utilizzare. Gli audio completati sono trattati come file immutabili.

La sincronizzazione automatica nel browser va garantita quando l’app è aperta e può eseguire attività. Non assumere che una pagina chiusa continui a sincronizzare. Su Android vanno verificate le restrizioni del sistema per le attività in background.

Una cartella sincronizzata non è di per sé un backup storico: un’eliminazione può propagarsi. Cestino, conservazione delle versioni ed esportazione sono proposte da definire per consentire il recupero.

## 7. Dati e formato condiviso

| Entità | Informazioni principali |
| --- | --- |
| Sogno | Identificativo, titolo, data/ora registrazione, fuso originario, revisione, riferimento audio |
| Audio | Formato, durata, dimensione, controllo di integrità |
| Trascrizione | Testo automatico, testo corrente, lingua, revisione, stato, motore |
| Riepilogo | Periodo, sintesi, ricorrenze, riferimenti ai sogni e alle revisioni, motore, data |
| Sincronizzazione | Identificativo archivio, dispositivo, operazioni pendenti, revisioni remote, conflitti |
| Configurazione locale | Preferenze, modelli disponibili, fornitore collegato; credenziali conservate separatamente |

Proposta: salvare audio e metadati in un formato documentato e versionato, con indice ricostruibile. Prevedere migrazioni di schema e riconoscimento delle versioni non supportate.

La data del sogno distinta dalla registrazione è una proposta ancora da confermare. È utile quando il sogno viene ricordato più tardi. Finché non viene approvata, i filtri temporali usano la data di registrazione.

## 8. Elaborazione locale e IA facoltativa

Trascrizione e riepiloghi richiedono componenti distinti: riconoscimento vocale e generazione/analisi del testo. I motori devono essere sostituibili e dichiarare le proprie capacità.

La selezione definitiva dei modelli dipenderà da qualità in italiano, licenza, memoria, dimensione del download, tempo di esecuzione e consumo energetico. La fattibilità su dispositivi di fascia bassa e nei browser non è ancora verificata.

Per il prototipo Android 0.2 è stato integrato Whisper small multilingue Q5_1 tramite whisper.cpp, con rilevamento della voce Silero e conversione audio locale. Il download dei due modelli è circa 191 MB, esplicito e verificato con SHA-256. La validazione iniziale riguarda il OnePlus 9; dispositivi di fascia bassa e browser richiedono prove dedicate. L’eventuale elaborazione nel browser utilizzerà un’integrazione distinta: il motore Flutter nativo non è automaticamente compatibile con il web.

Se un dispositivo non può elaborare localmente un contenuto, conservare l’audio e mostrare il limite. Un possibile percorso, da verificare, è elaborarlo su un altro dispositivo dell’utente attraverso l’archivio condiviso. Non passare automaticamente a servizi esterni.

L’opzione IA esterna deve consentire scelta del fornitore, modello e credenziali personali, con verifica della connessione e indicazione delle operazioni supportate. Non assumere che un abbonamento a un’interfaccia conversazionale includa l’accesso necessario all’integrazione.

L’utente sceglie quali operazioni affidare al servizio esterno. Prima dell’attivazione deve sapere se vengono inviati audio, testo o entrambi. Non inserire chiavi in file di configurazione condivisi; verificare una gestione sicura delle credenziali anche nel browser. Le integrazioni specifiche saranno oggetto di documentazione tecnica aggiornata.

## 9. Privacy, accessibilità e affidabilità

- In modalità locale non inviare audio o trascrizioni a servizi di elaborazione esterni.
- Distinguere elaborazione locale dalla sincronizzazione: collegare un cloud comporta comunque il trasferimento dei contenuti verso quel fornitore.
- Decidere se cifrare i contenuti prima della sincronizzazione e definire il recupero delle chiavi prima di implementare l’archivio condiviso.
- Conservare token e credenziali in meccanismi protetti; non includere contenuti personali o segreti nei log.
- Prevedere esportazione dell’audio e del testo, accessibilità dei controlli, contrasto leggibile e messaggi comprensibili.
- Verificare persistenza dello spazio locale nel browser: la cancellazione dei dati del sito o la modalità privata possono compromettere contenuti non sincronizzati.
- Salvare progressivamente l’audio ove fattibile e verificare recupero dopo interruzioni; avvisare quando lo spazio disponibile è insufficiente.

Cifratura, esportazione e recupero sono requisiti di progettazione proposti; modalità e priorità richiedono una decisione prima del rilascio.

## 10. Architettura proposta

Separare interfacce Android e browser, archivio locale, coda di elaborazione, motori locali, ricerca e motore di sincronizzazione. Ogni fornitore cloud utilizza un connettore dedicato, mantenendo comune il formato dei dati.

Per Android valutare database locale e file audio nell’area applicativa. Nel browser valutare memoria persistente e archiviazione di file compatibili con i browser scelti. Un’app web installabile è una possibilità da verificare per l’uso offline.

Per lo sviluppo è stato scelto Flutter con Dart, utilizzando Visual Studio Code e gli strumenti Android installati separatamente, senza Android Studio. La condivisione del codice tra Android e browser non elimina la necessità di integrazioni specifiche per registrazione, archiviazione ed elaborazione locale.

Non sono ancora definiti browser minimi, versioni Android supportate o eventuali componenti server necessari all’autenticazione. Queste scelte devono seguire le prove di fattibilità, includendo il vincolo di elaborazione locale. L’ambiente installato è descritto in `ambiente-sviluppo.md`.

## 11. Attività di sviluppo

1. Chiudere decisioni aperte e produrre prototipi delle schermate principali.
2. Eseguire prove di trascrizione e riepilogo locale in italiano su Android e browser; misurare prestazioni su dispositivi rappresentativi.
3. Verificare accesso ai fornitori cloud, autenticazione, autorizzazioni, limiti e necessità di componenti server.
4. Definire modello dati, formato condiviso, revisioni, conflitti e migrazioni.
5. Implementare registrazione, salvataggio, lettore e archivio Android.
6. Integrare trascrizione locale, modifica del testo e ricerca.
7. Integrare riepiloghi su richiesta e ricorrenze con riferimenti verificabili.
8. Implementare un primo connettore di sincronizzazione e gestione offline.
9. Implementare browser: registrazione, archivio, modifica, ricerca, riepiloghi e sincronizzazione.
10. Aggiungere gli altri connettori previsti e, se confermata nella prima versione, l’IA esterna facoltativa.
11. Completare recupero, esportazione, protezione credenziali, accessibilità e documentazione utente.
12. Eseguire collaudo multipiattaforma, correggere problemi e preparare distribuzione Android e pubblicazione web.

Nessuna stima di costo o durata è fissata prima delle prove tecniche e della scelta del numero di connettori.

## 12. Criteri di accettazione e collaudo

| Scenario | Risultato atteso |
| --- | --- |
| Registrazione senza rete | Audio salvato e riascoltabile dopo riapertura |
| Modelli locali già disponibili | Trascrizione e riepilogo funzionano senza rete sui dispositivi supportati |
| Modello assente | Audio conservato; spiegazione e procedura per rendere disponibile il modello |
| Titolo rinominato | Persistente dopo riapertura e propagato con la sincronizzazione |
| Trascrizione corretta | Ricerca e nuove sintesi usano il testo aggiornato; audio preservato |
| Due sogni con «coniglio blu» | Entrambi compaiono nei risultati |
| Riepilogo richiesto | Include solo il periodo scelto e riferimenti ai sogni utilizzati |
| Nessuna trascrizione disponibile | Nessun contenuto inventato; indicazione dei testi mancanti |
| Ritorno della rete | Operazioni pendenti riprese nei limiti della piattaforma |
| Sincronizzazione ripetuta | Nessun duplicato |
| Modifiche simultanee allo stesso testo | Nessuna versione persa; conflitto risolvibile |
| Accesso dal browser | Registrazione e consultazione dello stesso archivio dell’utente |
| Errore di trasferimento o accesso revocato | Dati locali disponibili e messaggio con azione di recupero |
| IA esterna disattivata | Nessun contenuto inviato a servizi esterni di elaborazione |
| Promemoria | Nessuna notifica che invita a registrare sogni |

Verificare inoltre interruzioni di registrazione, microfono negato, spazio esaurito, cancellazione dei dati browser, fusi orari, date ai confini dei periodi, file incompleti, aggiornamenti di schema e recupero delle versioni se implementato.

## 13. Decisioni ancora aperte

- Nome dell’app e identità visiva.
- Ordine tecnico di implementazione dei connettori Google Drive e Dropbox e disponibilità nei rilasci.
- Identità condivisa: account dell’app oppure account del servizio collegato.
- Versioni Android, browser e dispositivi minimi supportati.
- Precisione del riconoscimento multilingue, soprattutto nei cambi di lingua nella stessa registrazione.
- Data del sogno separata dalla data di registrazione.
- Cifratura dell’archivio condiviso e recupero delle chiavi.
- Eliminazione, cestino, durata della conservazione e backup storico.
- Gestione degli audio molto lunghi e limiti di spazio.
- IA esterna nel primo rilascio oppure in una versione successiva.
- Ordine di rilascio Android/browser, distribuzione, eventuale modello economico.

Questi punti non annullano le decisioni confermate. Le scelte tecniche saranno documentate dopo la verifica e le scelte di prodotto saranno concordate con l’utente.

## 14. Guida utente da produrre

La guida finale dovrà essere disponibile nell’app e come documento consultabile. Le istruzioni specifiche e le immagini saranno scritte e verificate sulle integrazioni realmente sviluppate.

1. Iniziare senza account esterni: permesso microfono, prima registrazione, disponibilità/download dei modelli, ascolto e modifica della trascrizione.
2. Collegare Google Drive o Dropbox: autorizzazione, selezione/creazione dell’archivio e verifica del collegamento.
3. Aprire l’app sul PC dal browser e collegare lo stesso account e archivio del telefono.
4. Usare sincronizzazione manuale e automatica, comprendere gli stati e risolvere errori o conflitti.
5. Collegare facoltativamente un servizio IA supportato: credenziali richieste, capacità del servizio, eventuali costi del fornitore e contenuti trasmessi.
6. Tornare all’elaborazione locale e scollegare servizi senza perdere i contenuti già salvati localmente.
7. Cercare sogni e generare riepiloghi per il periodo scelto.
8. Gestire esportazione, recupero ed eliminazione secondo le funzioni approvate.

Spiegare esplicitamente che non collegare l’archivio significa rinunciare alla sincronizzazione, mentre non collegare un’IA esterna mantiene l’elaborazione locale. Se il motore locale non è disponibile, conservare la registrazione e indicare come renderlo disponibile, senza attivare automaticamente un servizio esterno.

## 15. Stato del prototipo

La versione 0.4.1 Android implementa registrazione, riepilogo del singolo sogno, salvataggio locale, ascolto, titoli automatici modificabili, ricerca e trascrizione locale dopo la disponibilità del modello. Il testo originale generato è conservato separatamente dalle correzioni. Una coda serializza le elaborazioni e permette di riprovare gli errori senza perdere l’audio. La lingua viene riconosciuta automaticamente, senza selettore e senza traduzione del testo.

Il flusso confermato è: registrazione → riepilogo del singolo sogno → Salva sogno → home. Non è necessario inserire testo per salvare. La trascrizione non blocca il salvataggio e continua mentre si consulta la home, si usa un’altra app o si spegne lo schermo, mediante un servizio Android con notifica temporanea silenziosa. Non vengono introdotti promemoria. Arresto forzato, riavvio del telefono o terminazione del processo interrompono il lavoro; l’audio resta salvato e una registrazione non trascritta viene ripresa quando si riapre il suo dettaglio con il modello disponibile. Non è ancora implementata una coda persistente che riparta automaticamente dopo il riavvio.

Il collaudo ha riconosciuto audio separati in italiano e inglese. Una frase inglese inserita in un audio prevalentemente italiano è stata omessa: l’identificazione automatica della lingua non garantisce la corretta trascrizione di ogni cambio di lingua. La trascrizione resta modificabile. Dettagli e limiti delle prove sono riportati in `diario-sogni/verifiche/esito.md`.

La versione browser permette di collegare una cartella del PC, sincronizzare audio e trascrizioni con il telefono, ascoltare, cercare, modificare ed eliminare i sogni. La versione 0.4 introduce la sincronizzazione manuale tramite cartella: il servizio cloud scelto deve esporla su Android e renderla disponibile sul PC. Il salvataggio nella cartella Drive scelta sul telefono è stato confermato dall’utente. Non sono ancora implementati collegamento OAuth diretto agli account, sincronizzazione automatica al ritorno della rete, trascrizione nel browser, riepiloghi di periodo e IA esterna. La guida operativa è in guida-archivio-condiviso.md.
