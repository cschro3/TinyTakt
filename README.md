# TinyTakt – Mein kleiner Zeitheld

Visueller Kinder-Timer (2–8 Jahre) für iOS und Android, gebaut mit Flutter. **Arbeitstitel** – siehe `docs/BRAND.md`.
Kein Backend, keine Werbung, kein Tracking, keine Registrierung. Pro = einmaliger In-App-Kauf `tinytakt_pro_lifetime`.

> Stand und ehrliche Statusübersicht: **`docs/STATUS.md`**. Das Projekt ist ein Release-Candidate-Kandidat, **noch nicht** veröffentlichungsreif (siehe Blocker dort).

## Schnellstart
```bash
flutter pub get
flutter test            # 100+ automatisierte Tests
flutter run             # Gerät/Emulator
ALLOW_DEBUG_SIGNING=1 flutter build apk --release   # nur lokaler Prüf-Build
flutter build appbundle --release                    # Store-Bundle (Signierung: docs/RELEASE.md)
```
Flutter 3.47.7 (stable), Dart 3.13. Android: minSdk laut Flutter, targetSdk 36. iOS: Deployment Target 15.0 (StoreKit 2).

## Struktur
| Pfad | Inhalt |
|---|---|
| `lib/domain` | `TimerEngine` (rein, testbar), `Clock`, Katalog (71 Figuren, 9 Welten, 10 Timer-Arten, Töne) |
| `lib/data` | Einstellungen/Profile/Vorlagen, Entitlements (HMAC), Elternsicherung + PIN, Fotos |
| `lib/platform` | Benachrichtigungen, Audio/TTS, Käufe (Store-Gateway, Verifier) |
| `lib/app` | `TimerController` (Engine + Persistenz + Audio + Benachrichtigung), DI |
| `lib/presentation` | Screens, Widgets, eigene Vektor-Painter für Figuren, Welten, Timer-Darstellungen |
| `tools/` | Audio-Synthese, Store-Bild-Komposition |
| `test/` | Unit-, Widget- und Tool-Tests |
| `docs/` | Architektur, Plattformgrenzen, Käufe, Compliance, Release, Marke, Status |
| `store/` | Store-Texte (DE/EN), Screenshots, Feature Graphic |

Weitere Dokumente: `docs/ARCHITECTURE.md`, `docs/PLATFORM_LIMITS.md`, `docs/PURCHASES.md`, `docs/COMPLIANCE.md`, `docs/DEPENDENCIES.md`, `docs/TESTING.md`, `docs/RELEASE.md`, `docs/BRAND.md`, `docs/ASSETS.md`.
