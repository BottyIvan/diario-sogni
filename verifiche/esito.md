# Verifiche del prototipo — 14 ottobre 2026

## Riconoscimento della cartella 0.4.1

- Corretto il caso segnalato dall’utente: selezionando direttamente “Diario dei sogni”, la versione precedente apriva o creava un’altra cartella con lo stesso nome al suo interno. Il resolver browser e Android ora riconosce l’archivio diretto, per nome o file identificativo, e continua ad accettare il contenitore.
- Cinque test Node superati sul resolver effettivamente caricato dal browser: archivio diretto, archivio rinominato con file identificativo, contenitore, archivio con sottocartella accidentale e permesso negato senza creazione di cartelle.
- Analisi statica senza problemi; compilazioni web e Android riuscite; aggiornamento 0.4.1 installato sul telefono. UI browser verificata con etichetta 0.4.1 e istruzioni aggiornate. Verifica dei sogni reali sul PC richiesta all’utente dopo il ricaricamento.
- La prima compilazione Android è stata interrotta da esaurimento della memoria della JVM. Limite Gradle ridotto da 8 a 2 GB e concorrenza limitata a due worker; compilazione successiva riuscita. Questo modifica soltanto l’ambiente di compilazione.

## Cancellazione e archivio di cartella 0.4.0

- Tutti i 19 test superati: trasferimento tra due database con audio e testo ricercabile, modifiche senza duplicati, cancellazione offline prevalente sulle modifiche obsolete, rimozione delle versioni condivise e dell’audio, protezione dai risultati di trascrizione tardivi, recupero da trasferimento fallito e rifiuto di audio con hash errato. Due prove aggiuntive su file reali temporanei verificano la rimozione dei file intermedi anche quando l’originale manca e il rifiuto di cancellazione fuori dalla cartella audio gestita.
- Il test del flusso completo comprende registrazione → dettaglio → salvataggio senza testo → home → riapertura → annullamento della cancellazione → cancellazione confermata → home senza il sogno.
- Analisi statica senza problemi. Compilazioni Android e web riuscite; versione normale 0.4.0 installata sul OnePlus senza cancellare dati o modelli. Interfaccia browser finale verificata con etichetta 0.4.0 e pulsante Collega cartella.
- L’utente ha collegato la cartella Drive dal selettore Android e ha confermato che, dopo Sincronizza, i file sono nella cartella scelta. Questa è una conferma d’uso dell’utente, non una lettura degli audio da parte dell’agente.
- Interfaccia browser aperta su http://127.0.0.1:8787/: home e impostazioni visualizzate, pulsante Collega cartella presente. Il collegamento alla cartella reale sul PC è effettuato dall’utente con i permessi del browser; non dichiarare concluso il collaudo reale tra telefono e PC prima della sua conferma.
- Non sono stati eliminati sogni dell’utente durante lo sviluppo. Le prove di cancellazione usano database e file simulati separati.
- Limiti: sincronizzazione manuale, cartella cloud disponibile tramite fornitore Android o client PC, niente OAuth diretto; niente cifratura dei file condivisi, fusione assistita dei conflitti o trasferimenti oltre 100 MB per audio. Cestino/versioni del fornitore cloud restano sotto il controllo del servizio.

## Trascrizione in background e lingua automatica 0.3.0

- Analisi statica senza problemi e 13 test automatici superati, compresi gestione condivisa del servizio, ripetizione dopo un errore di avvio e lingua automatica senza traduzione.
- Corretto il distacco del convertitore audio quando Android distrugge la schermata: la conversione ora usa il contesto dell’applicazione, insieme al motore Flutter conservato e al servizio temporaneo.
- Prova sul OnePlus 9 con due audio sintetici in coda, database separato e nessun accesso alle registrazioni dell’utente. Pagina Android avviata senza permanenza nella cronologia, passaggio alla home e spegnimento dello schermo dopo l’avvio del servizio. Entrambe le trascrizioni completate; stato dell’app fuori primo piano alla fine. Durata complessiva 67.293 secondi nella prova diagnostica senza VAD.
- Servizio osservato in primo piano, con notifica priva di suono e vibrazione e protezione temporanea della CPU. La prova non garantisce il comportamento di ogni versione Android o delle impostazioni energetiche di ogni produttore.
- Audio inglese riconosciuto correttamente nella sua lingua, includendo «blue rabbit». Nell’audio misto sono state riconosciute le parti italiane, incluso «coniglio blu», ma è stata omessa la frase inglese intermedia. Il controllo completo di qualità del campione misto NON è passato. Il limite si presenta sia con VAD sia senza VAD; la versione normale mantiene VAD. Non dichiarare supporto perfetto dei cambi di lingua.
- Arresto forzato, riavvio e terminazione del processo non sono coperti da una coda persistente. L’audio resta conservato e si può riprovare aprendo il dettaglio.
- La schermata di collaudo è un ingresso separato; al termine si reinstalla l’app normale con `lib/main.dart`, conservando archivio e modelli locali.

## Trascrizione locale 0.2.0

- Analisi statica superata; nove test automatici passati, includendo applicazione del testo automatico, conservazione di correzioni e titolo durante le elaborazioni, salvataggio da una schermata precedente alla trascrizione, coda serializzata e ripetizione dopo errore.
- Collaudo sul OnePlus 9 con audio italiano sintetizzato sul PC da Microsoft Elsa Desktop, senza acquisire nuove registrazioni dal microfono e senza inviare registrazioni dell’utente a servizi esterni.
- Modello base: trascrizione in 4.264 secondi, ma parola «coniglio» riconosciuta come «con ilio». Esito del controllo di qualità negativo.
- Modello small multilingue Q5_1: trascrizione in 11.148 secondi; frase riconosciuta «Ho sognato un coniglio blu che correva in un bosco. Poi ho visto una casa rossa vicino al mare.». Controllo di qualità superato. Il modello small è stato scelto per questa versione.
- Modelli small Q5_1 e Silero verificati con SHA-256 e installati nella cartella privata del prototipo sul telefono. Per una nuova installazione è previsto un download esplicito di circa 191 MB.
- Le misure riguardano un solo audio sintetico e non rappresentano una garanzia di precisione o velocità per tutte le registrazioni.
- Trascrizione nel browser, elaborazione garantita in background e riepiloghi di periodo non ancora implementati.

## Aggiornamento 0.1.3

Ripristinato il flusso registrazione → riepilogo del singolo sogno → Salva sogno → home. Aggiunto un test dell’intero percorso con testo vuoto e verifica che l’archivio contenga un solo sogno. Tutti e cinque i test automatici sono passati. Il titolo automatico e il salvataggio senza testo introdotti nella versione 0.1.1 sono mantenuti.

- Analisi statica Flutter: superata, nessun problema.
- Quattro test automatici superati: persistenza dopo chiusura e riapertura del database senza duplicati; ripetizione di un salvataggio fallito senza fermare il microfono due volte; microfono negato; ricerca in titolo/testo e layout a 360 pixel.
- Compilazione APK debug: riuscita.
- Compilazione web: riuscita. Pubblicazione e collaudo del microfono nel browser non eseguiti.
- Installazione sul OnePlus 9 LE2113 via USB: riuscita.
- Avvio dell’attività Android: confermato.
- Controllo dei log del processo: nessun errore Flutter rilevato nei log esaminati.
- Ispezione della schermata: dettaglio sogno con durata di circa sei secondi e campi di testo, senza overflow visibile. Non è stato registrato audio automaticamente per il collaudo.
- Ascolto sul telefono, pausa/ripresa reale, ritorno da blocco schermo e persistenza sul telefono dopo arresto/riavvio restano da verificare nell’uso reale.

Trascrizione automatica, riepiloghi, esportazione e sincronizzazione non fanno parte di questa prima implementazione. Non considerare questo esito come collaudo della versione completa descritta nell’analisi.

## Verifica della distribuzione 0.4.2 — 14 ottobre 2026

- Il convertitore usa Android MediaExtractor/MediaCodec; nessuna libreria FFmpeg è presente nel nuovo APK. Il motore Whisper viene compilato dai sorgenti CPU inclusi nel repository.
- App di prova con identificativo separato sul OnePlus: archivio e audio dell'app dell'utente non modificati.
- Due audio WAV sintetici completati in 54.279 secondi, con schermo spento e servizio poi arrestato.
- Seconda prova con contenuti AAC/M4A e Opus/WebM sintetici: entrambe le trascrizioni completate in background in 53.736 secondi, inglese incluso. La breve frase inglese nell'audio misto resta omessa: il controllo di qualità misto continua a essere negativo, distinto dal corretto completamento del convertitore e del servizio.
- APK release ARM64 firmato con chiave dedicata SboMusic. Controllo tools/audit_release.py: nessun percorso personale Windows/macOS/Linux rilevato e nessuna libreria FFmpeg. Licenze native incluse come asset; simboli e chiave esclusi da Git.
- Il prototipo USB esistente resta installato con la firma di sviluppo. La nuova firma pubblica serve per installazioni su altri telefoni e non può aggiornare direttamente il prototipo.
