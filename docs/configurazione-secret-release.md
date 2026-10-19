# Configurare le secret per le release

Quando pubblichi una GitHub Release, il workflow `Build release artifacts` compila e **firma** Android e iOS, poi allega alla release `DiarioSogni-Android-ARM64.apk` e `DiarioSogni-iOS.ipa`. Se manca anche una sola secret, la build si blocca subito con un messaggio che rimanda a questa pagina.

Le secret si aggiungono in **Settings → Secrets and variables → Actions → New repository secret**. Non scriverle mai nel repository né in chat. Documentazione GitHub: [secret nelle Actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions).

## Android

| Secret | Contenuto |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Keystore `.jks` codificato in base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Password del keystore |
| `ANDROID_KEY_ALIAS` | Alias della chiave (es. `diario-sogni`) |
| `ANDROID_KEY_PASSWORD` | Password della chiave |

Codifica il keystore (macOS): `base64 -i diario-sogni-release.jks | pbcopy`. Su Linux: `base64 -w 0 diario-sogni-release.jks`. Per generare la chiave vedi [firma Android](firma-android.md). Usa sempre la stessa chiave: Android la richiede per gli aggiornamenti.

## iOS

La firma OTA richiede un account Apple Developer a pagamento e un profilo **Ad Hoc**. I dispositivi da installare devono essere registrati nel profilo.

| Secret | Contenuto |
| --- | --- |
| `IOS_CERTIFICATE_P12_BASE64` | Certificato **Apple Distribution** con chiave privata, esportato in `.p12` e codificato in base64 |
| `IOS_CERTIFICATE_PASSWORD` | Password scelta durante l'esportazione del `.p12` |
| `IOS_PROVISIONING_PROFILE_BASE64` | Profilo di provisioning Ad Hoc (`.mobileprovision`) per `it.diariosogni.diario-sogni`, in base64 |

1. Su [developer.apple.com](https://developer.apple.com/account) crea un certificato **Apple Distribution**, scaricalo e installalo nel Portachiavi del Mac.
2. In Accesso Portachiavi esporta certificato e chiave privata in formato `.p12` con una password.
3. Registra gli iPhone (UDID) in **Devices**, crea un **App ID** per `it.diariosogni.diario-sogni` e un profilo **Ad Hoc** che includa certificato e dispositivi. Scaricalo.
4. Codifica i file: `base64 -i certificato.p12 | pbcopy` e `base64 -i profilo.mobileprovision | pbcopy`.

Il Team ID e il nome del profilo sono letti automaticamente dal profilo. Se aggiungi un dispositivo, rigenera il profilo e aggiorna la secret. Il file `.ipa` è firmato per l'installazione OTA sui dispositivi registrati. Il workflow allega alla release anche `manifest.plist`; il portale guide, sviluppato in `website/` e pubblicato con GitHub Pages, include il pulsante **Installa su iPhone** che apre il manifest dell'ultima release. Dall'iPhone aprilo in Safari e tocca il pulsante. L'installazione funziona solo sui dispositivi registrati nel profilo Ad Hoc; se richiesto, abilita lo sviluppatore in Impostazioni → Generali → VPN e gestione dispositivo. Una pre-release non conta come "ultima release".

Riferimenti: [Flutter, distribuzione iOS](https://docs.flutter.dev/deployment/ios), [Apple, profili di provisioning](https://developer.apple.com/help/account/provisioning-profiles/create-an-ad-hoc-provisioning-profile/).
