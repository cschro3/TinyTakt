# Abhängigkeiten – Datenschutz-Prüfung (erste Sichtung)

| Paket | Zweck | Netzwerk/Daten | Bewertung |
|---|---|---|---|
| in_app_purchase (+android, +storekit) | Käufe | Kommunikation mit Apple/Google (nötig) | Offizielles Flutter-Paket; Billing-Lib ergänzt `BILLING`, `INTERNET`, `ACCESS_NETWORK_STATE` |
| flutter_local_notifications, timezone | Timer-Ende | lokal | Keine Daten nach außen |
| flutter_secure_storage | PIN-Hash, HMAC-Schlüssel | lokal | Keychain/Keystore |
| shared_preferences, path_provider, path | Einstellungen, Dateien | lokal | – |
| audioplayers | Audio (lokale Assets) | nur lokale Assets (kein Streaming genutzt) | `INTERNET` kommt zusätzlich von Billing; keine URLs im Code |
| flutter_tts | optionale Sprachausgabe | System-TTS (Gerät) | Engine kann je nach Gerät Netz nutzen (System-Einstellung) – bewusst optional, standardmäßig aus |
| image_picker | Foto-Auswahl | lokal, System-Picker | Keine Medienberechtigungen (im Manifest entfernt) |
| wakelock_plus | Bildschirm an | lokal | – |
| crypto | HMAC/PBKDF2 | lokal | – |
| (dev) flutter_launcher_icons, flutter_native_splash, fake_async | Build/Test | nicht in der App | – |

`scripts/check_privacy_deps.sh` (CI) bricht bei Werbe-/Tracking-/Standort-/Kamera-Paketen ab. **Offen:** manuelle Prüfung der transitiven Abhängigkeiten pro Release (`flutter pub deps`), OSV-Scan läuft in CI (nicht blockierend). `flutter_tts` nutzt noch das alte Kotlin-Gradle-Plugin (Build-Warnung; Plugin beobachten).
