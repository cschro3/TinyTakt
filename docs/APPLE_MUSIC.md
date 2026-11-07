# Apple-Music-Baustein (optional, nur iPhone/iPad)

**Status: Dart-Teil und Oberfläche getestet (Linux, mit Test-Double). Der Swift-Teil wurde in dieser Umgebung NICHT kompiliert und NICHT auf einem Gerät ausgeführt** (kein macOS/Xcode). Die verwendeten MusicKit-Namen stammen aus dem Wissensstand, nicht aus einem Build – beim ersten `flutter build ios` auf dem Mac sind kleine Compilerkorrekturen möglich (siehe unten).

## Was er kann
Eltern (hinter der Elternsicherung) → Elternbereich → „Apple Music“: verbinden (iOS-Erlaubnisdialog), Titel suchen, anhören, wählen. Der gewählte Titel wird als „Timer-Musik“ des Profils gesetzt und läuft während des Timers (Einzeltitel in Wiederholung). Kinder sehen den Titel nur als Eintrag unter „Musik“ und können nicht suchen.
Verhalten: Pause/Stopp/Ende/Stumm/Hintergrund halten Apple Music an (kein Hintergrund-Audio, siehe PLATFORM_LIMITS). Ist Apple Music nicht verfügbar (Android, Web, keine Erlaubnis, kein Abo, Fehler), spielt stattdessen die eingebaute Musik – der Timer läuft immer weiter. Nicht jugendfreie Titel werden in Suche und Wiedergabe herausgefiltert (`contentRating == .explicit`; abhängig von Apples Metadaten, nicht perfekt).

## Dateien
* Dart: `lib/platform/apple_music_service.dart` (Schnittstelle, MethodChannel `app.tinytakt/apple_music`, Test-Double), `lib/presentation/screens/apple_music_screen.dart` (Suche), Abschnitt in `parent_screen.dart`, Eintrag in `picker_screen.dart`, Steuerung in `app/timer_controller.dart` (inkl. Schutz gegen verspäteten Start nach Stopp).
* iOS: `ios/Runner/AppleMusicPlugin.swift`, Registrierung in `AppDelegate.swift`, `NSAppleMusicUsageDescription` in `Info.plist`, Projekteintrag in `project.pbxproj`.

## Was SIE einrichten müssen
1. **Developer-Portal:** Certificates, Identifiers & Profiles → Identifiers → App-ID `app.tinytakt.kids` (oder final) → *App Services* → **MusicKit** aktivieren. Ohne das schlagen Suche und Wiedergabe fehl (Fehlercode in der App: „Die Suche hat nicht geklappt“).
2. **Xcode:** Projekt öffnen, Team/Signierung setzen, bauen. `AppleMusicPlugin.swift` ist bereits im Target `Runner`. Deployment Target ist 15.0 (MusicKit-Minimum).
3. **Test nur auf echtem iPhone** mit aktivem Apple-Music-Abo (Simulator ist für Wiedergabe nicht zuverlässig). Testfälle: Erlaubnis erteilen / ablehnen / später in den iOS-Einstellungen ändern; Abo vorhanden / nicht vorhanden; Suche mit und ohne Treffer; Flugmodus während Suche/Wiedergabe; Titel anhören → wählen → Timer starten; Pause/Fortsetzen/Stopp; Timer-Ende; App in den Hintergrund; Anruf; Stumm-Schalter; Titel ist explizit (darf nicht erscheinen).
4. **Mögliche Compilerkorrekturen** in `AppleMusicPlugin.swift` (am ehesten): `engineBridge.pluginRegistry.registrar(forPlugin:)` (Optional), `MusicSubscription.current` (async throws), `ApplicationMusicPlayer.Queue(for:)`, `player.state.repeatMode`, `MusicItemID(_:)`.

## Store/Compliance (offen, bitte prüfen)
* **Apple Kids Category / Guideline 1.3:** Dienst von Apple selbst, hinter Elternsicherung, keine Links, kein Tracking durch uns – ob der Reviewer die optionale Anbindung in der Kids-Kategorie akzeptiert, ist **ungeklärt**; in den Review Notes erklären (siehe `store/review_notes.md`) und ggf. Funktion für die Einreichung per Build-Schalter ausblenden.
* **App Privacy:** Wir erheben keine Daten; ob die MusicKit-Nutzung eine Angabe erfordert, bitte bei Apple prüfen und die Datenschutzinformation (Abschnitt „Apple Music“) rechtlich prüfen lassen.
* **Google Play:** nicht betroffen (Funktion nur iOS), Data-safety unverändert.
* Lizenz/Rechte: Es wird nichts heruntergeladen oder gespeichert; Wiedergabe nur über Apples Player.
