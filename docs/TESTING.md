# Tests – was real ausgeführt wurde und was nicht

Alle Angaben hier sind Ergebnisse tatsächlicher Läufe (`flutter test`, siehe `docs/STATUS.md` für die Zahlen des letzten Laufs).

**Automatisiert (Linux, ohne Gerät):**
* Unit: `timer_engine_test` (Zeitberechnung, Start/Stopp/Pause, Ablauf, Wiederholung, Schlaf, Uhr vor/zurück, Zeitzone, Snapshot/Wiederherstellung, korrupte Daten), `timer_controller_test` (Persistenz, Neustart, Ablauf-während-weg, Benachrichtigung planen/stornieren, Alarm/Pro-Fallback, Stumm, Ruhemodus, Countdown), `entitlement_test`, `parental_gate_test`, `purchase_service_test` (Kauf, Abbruch, Pending, Fehler, Restore, Verifikation, Erstattung, Offline, Doppelauslösung, fremdes Produkt).
* Widget: Hauptbildschirm, Schnellauswahl, Zeitrad, Kindermodus-Sperre, Elternsicherung, Free/Pro im Picker, Pro-Screen (online/offline/aktiv), Elternbereich, Englisch, Timer-Ende, Layout ohne Überlauf (iPhone SE, Pixel, iPad hoch/quer, Handy quer; Schrift 1.0/2.0), Mindest-Touchgrößen, Screenreader-Labels, Ruhiger Modus, alle Timer-Arten und alle 46 Figuren rendern.

**Nur auf echten Geräten/Store-Umgebungen prüfbar (NICHT durchgeführt):**
App-Wechsel/Sperrbildschirm/Telefonanruf, Prozess-Kill & Neustart, Geräteneustart (Boot-Receiver), Zustellung der Benachrichtigung (Doze, Energiesparen, Fokus), Audiofokus/Stumm-Schalter, Lautsprecher-Lautstärke, TTS, System-Foto-Picker, VoiceOver/TalkBack, Sandbox-/Lizenztest-Käufe (Kauf, Abbruch, Pending, Restore, Erstattung), iOS-Build, verschiedene OS-Versionen, Performance/Akku, Integrationstests (`integration_test`) auf Gerät.
