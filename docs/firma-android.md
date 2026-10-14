# Firma delle versioni Android

Le compilazioni debug usano il certificato di sviluppo; le release usano una chiave dedicata. `android/key.properties` e i keystore sono esclusi da Git. Per una release senza configurazione, la compilazione si interrompe invece di usare automaticamente il certificato debug.

Su questo PC la chiave della pubblicazione è in `.private/signing/diario-sogni-release.jks`. Conserva privatamente una copia di quel file e di `android/key.properties`, in un luogo protetto separato dal PC. Servono per firmare gli aggiornamenti; non allegarli alle Releases e non caricarli nel repository. Non rigenerare la chiave per ogni versione.

Per compilare una propria copia, genera la tua chiave con il `keytool` del JDK e crea `android/key.properties` con questa struttura:

```properties
storeFile=../.private/signing/diario-sogni-release.jks
storePassword=PASSWORD_PRIVATA
keyPassword=PASSWORD_PRIVATA
keyAlias=diario-sogni
```

`storeFile` è relativo alla cartella `android`. Le password nell’esempio sono segnaposto. Per le istruzioni di generazione consulta la [guida Flutter alla firma Android](https://docs.flutter.dev/deployment/android#sign-the-app).

La build distribuita è prodotta con `flutter build apk --release --target-platform android-arm64`, verificata tramite `apksigner verify --print-certs` e accompagnata da un checksum SHA-256. Android minimo: API 24, cioè Android 7.0. La prima distribuzione riguarda telefoni ARM64; l’elenco di librerie presenti nell’APK non implica che Flutter supporti tutte le architetture elencate dai componenti nativi.

Il vecchio prototipo installato tramite USB è firmato con il certificato debug. Il nuovo APK pubblico non può aggiornarlo direttamente, perché Android richiede la stessa firma. Il telefono di sviluppo non viene disinstallato o aggiornato automaticamente. Prima di un eventuale passaggio, sincronizza e verifica l’archivio cloud; la disinstallazione elimina i dati locali. Sui telefoni nuovi si installa direttamente il pacchetto pubblico. Le release successive devono mantenere la chiave della pubblicazione.

Per ricompilare con modifiche ai componenti nativi o alle librerie LGPL puoi utilizzare una tua chiave e installare la tua copia: non è richiesta né distribuita la chiave privata del progetto. La copia firmata con la tua chiave deve essere installata come app separata, oppure dopo avere preservato i dati e rimosso una versione con firma diversa.
