# STATUS – Stand 2026-10-23

## Real ausgeführt
* `flutter analyze`: ohne Befunde (Lint `curly_braces_in_flow_control_structures` bewusst aus).
* `flutter test`: **96 Tests bestanden** (Engine 19, Controller 10, Entitlement 8, Elternsicherung 9, Käufe 18, Widget/Layout/A11y 29, Tools 3).
* Android: `flutter build apk --release` (59 MB, alle ABIs, **mit Debug-Schlüssel signiert – nur Prüf-Build**) und `flutter build appbundle --release` (57,7 MB, **unsigniert**) erfolgreich. targetSdk 36, Berechtigungen: POST_NOTIFICATIONS, USE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED, VIBRATE, BILLING, INTERNET, ACCESS_NETWORK_STATE.

## NICHT ausgeführt / nicht möglich in dieser Umgebung
* **iOS-Build** (kein macOS/Xcode). Projekt ist konfiguriert (Bundle-ID, Privacy Manifest, Info.plist, Icons, Splash), CI-Job auf macOS-Runner vorbereitet – **unverifiziert**.
* Jegliche Gerätetests, Sandbox-/Lizenztest-Käufe, Hintergrund-/Benachrichtigungs-Zustellung, Audio-Hörabnahme, VoiceOver/TalkBack, Integrationstests auf Gerät.
* Store-Konsolen, Markenregister, Domain-/Namensprüfung, aktuelle Richtlinientexte im Volltext.

## Blocker für eine Veröffentlichung
1. iOS-Build/Signierung/TestFlight nicht gelaufen.
2. Käufe nicht gegen Sandbox/Play-Lizenztest geprüft; iOS-Erstattungserkennung nicht verifiziert; kein Server-Verifier (optional).
3. Hintergrund-Timer-Benachrichtigung nur per Code/Manifest-Prüfung, nicht auf Gerät belegt; Exact-Alarm-Deklaration in Play ungeklärt.
4. Illustrations-/Animations- und Audio-Abnahme durch Menschen (docs/ASSETS.md).
5. Betreiberdaten, öffentliche Datenschutz-URL, Impressum, Support, Händlerangaben fehlen (Platzhalter).
6. Marken-/Namensprüfung, finale Bundle-ID, Preisbestätigung.
7. Google-Play: ggf. 12 Tester × 14 Tage (Kontotyp prüfen); Families-/Data-safety-Formulare ausfüllen.
8. Referenz-Screenshots des Auftraggebers lagen nicht vor.
9. Keystore/Upload-Key fehlen (nie im Repo).
