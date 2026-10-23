# Architektur

Schichten: Presentation → App (Controller) → Domain ← Data/Platform. Keine Zusatzbibliothek für State/DI (`ChangeNotifier`, `InheritedWidget`).

* **TimerEngine** (`lib/domain/timer_engine.dart`): rein, ohne UI/Plattform. Zustand = Anker (Restzeit zum Ankerzeitpunkt, Wand- und monotone Uhr). Restzeit wird bei jeder Abfrage berechnet, **keine Tick-Zählung**. Verstrichen = `max(monotonDelta, wandDelta≥0)`. Zustand ist als `TimerSnapshot` (JSON) persistierbar und wiederherstellbar.
* **TimerController**: verbindet Engine, Persistenz (Snapshot nach jedem Übergang), `AudioPort`, `NotificationPort`, Wakelock, App-Lifecycle. Pollt nur während des Laufs (250 ms) zur Anzeige.
* **TimerStage** + Painter: reine Darstellung (Kreis, Abenteuer, Füllstand, Regenbogen*, Sanduhr*; *Pro). Alle lesen nur `fractionRemaining` aus der Engine. Animationszeit (Ticker) ist getrennt von der Timerlogik.
* **Kindermodus / Elternbereich**: Kinder sehen keine Kauf-Buttons, keine Links. Gesperrte Inhalte, Elternbereich, Stopp bei aktiver Sperre und jeder Kauf laufen über `requireParent()` (Rechenaufgabe mit Zahlwörtern oder optionaler PIN; Sperrzeiten; PIN als PBKDF2-Hash im Secure Storage; Wiederherstellung über 3 Aufgaben + 60 s).
* **Entitlements**: HMAC-gesicherter Eintrag, Schlüssel im Secure Storage, plattformgebunden. Siehe `PURCHASES.md`.
* **Free/Pro-Trennung** zentral über `effectiveCharacter/Background/Style` und `isPro`-Prüfungen (Fallback auf freie Inhalte bei Entzug).
* **Lokalisierung**: de/en über `context.tr(de, en)`; Systemsprache, Fallback Englisch.
