# Release-Anleitung (manuelle Schritte des Auftraggebers)

Es wurde **nichts** veröffentlicht oder bei einem Store eingereicht.

## Vorab
1. Marke/Name/Bundle-ID final klären (`docs/BRAND.md`), IDs ggf. in `android/app/build.gradle.kts`, `AndroidManifest`, `MainActivity` (Package), `ios/Runner.xcodeproj` ändern.
2. Betreiberdaten eintragen (`legal_screen.dart`, `lib/app/info.dart`, Store-Texte), Datenschutzerklärung als öffentliche URL hosten, Support-E-Mail.
3. Preis bestätigen (4,99 € vorläufig). Illustrations-/Audio-Abnahme (`docs/ASSETS.md`).
4. Richtlinien aktuell lesen (Apple Guidelines 1.3/5.1.4/3.1.1, Google Families, Data safety, Exact Alarm).

## Android
1. Play-Entwicklerkonto; **neue persönliche Konten (nach 13.11.2023) brauchen einen geschlossenen Test mit mindestens 12 Testern über 14 zusammenhängende Tage, bevor Produktionszugang beantragt werden kann** (Organisationskonten laut Drittquellen ausgenommen – im eigenen Konto prüfen: Play Console → Dashboard).
2. Upload-Keystore erzeugen (`keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`), `android/key.properties` (nicht committen) bzw. CI-Secrets `ANDROID_KEYSTORE_B64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`. Play App Signing aktivieren.
3. `flutter build appbundle --release --build-number=N`; AAB im Track „Intern“ → „Geschlossen“ hochladen.
4. App-Inhalte: Zielgruppe/Families, Datenschutz-URL, Data safety, Inhaltseinstufung, Exact-Alarm-Deklaration, Anzeigen = nein, In-App-Produkt `tinytakt_pro_lifetime`, Lizenztester.
5. Store-Eintrag: Texte `store/listing_*.md`, Screenshots `store/screenshots/<loc>/<gerät>`, Feature Graphic `store/feature_graphic_*.png`.

## iOS (benötigt macOS/Xcode – hier nicht verfügbar)
1. Apple Developer Programm, App-ID `app.tinytakt.kids` (oder final), App in App Store Connect anlegen, Kids Category, Altersband, App Privacy „Data Not Collected“, IAP `tinytakt_pro_lifetime`, Sandbox-Tester.
2. Xcode: Team/Signierung setzen, Capability „In-App Purchase“; `flutter build ipa --release`; Upload via Transporter/Fastlane (`fastlane ios beta`, Secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`).
3. TestFlight-Plan: interne Tester → Test: Timer im Hintergrund/gesperrt, Benachrichtigung, Kauf/Restore (Sandbox), VoiceOver, iPad Quer.
4. Review Notes: siehe `store/review_notes.md`.

## Danach
Geräte-Testmatrix (`docs/TESTING.md`, Abschnitt „nur auf Geräten“), Produktionsfreigabe nur nach ausdrücklicher Entscheidung.
