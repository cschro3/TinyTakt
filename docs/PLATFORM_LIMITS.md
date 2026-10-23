# Zeitmodell, Hintergrund und Plattformgrenzen

## Strategie
1. Im Vordergrund: Anzeige aus Anker-Modell (siehe ARCHITECTURE.md), 250-ms-Polling nur zur Aktualisierung.
2. Hintergrund/gesperrter Bildschirm: Der Timer „läuft“ rechnerisch weiter (Zeitbasis). Das Ende meldet eine **vom Betriebssystem zugestellte lokale Benachrichtigung** (Android: AlarmManager, iOS: UNUserNotificationCenter), geplant bei Start/Fortsetzen, storniert bei Pause/Stopp.
3. Prozessende/Neustart: Snapshot wird beim Start wiederhergestellt; Wanduhr-Differenz wird abgezogen; abgelaufen → Zustand „Geschafft“ (`finishedWhileAway`).
4. Systemzeit: zurückgestellt → monotone Uhr gewinnt (im Prozess); Zeitzone ändert UTC-Epoche nicht; **vorgestellte Uhr verkürzt den Timer** (nicht von Schlaf unterscheidbar). Nach Geräteneustart gibt es nur die Wanduhr; liegt der Anker in der Zukunft, wird nichts abgezogen.

## Ausdrücklich NICHT garantiert
* Keine sekundengenaue Hintergrundausführung, keine garantierte Alarmzustellung. Energiesparmodus, Doze, Nicht stören/Fokus, deaktivierte Benachrichtigungen, App-Standby-Buckets und Hersteller-Akkuoptimierung (Xiaomi, Huawei …) können Benachrichtigungen verzögern oder unterdrücken.
* Android 12+: exakte Alarme erfordern `USE_EXACT_ALARM` (Timer-Kernfunktion; **in der Play Console zu deklarieren**, Ablehnung möglich → Fallback `inexactAllowWhileIdle` ist implementiert, wenn exakt nicht erlaubt ist). Android 13+: `POST_NOTIFICATIONS` Laufzeitberechtigung (Anfrage hinter Elternsicherung im Onboarding).
* iOS: lokale Benachrichtigung mit `timeSensitive`-Stufe (kann durch Fokus-Modi unterdrückt werden; Entitlement „Time Sensitive Notifications“ ggf. in Xcode aktivieren).
* Alarmton im Hintergrund = Benachrichtigungston des Systems (Standardton), nicht die App-Alarmmelodie. Die Melodie spielt nur bei geöffneter App.
* Audio: keine Hintergrund-Audio-Fähigkeit (kein `UIBackgroundModes audio`, kein Foreground-Service). Musik stoppt beim Verlassen der App. iOS-Kategorie `ambient` (respektiert Stumm-Schalter, mischt mit anderen), Android Audiofokus mit Ducking. Telefonanrufe: Audiofokus/Unterbrechungen werden vom Audio-Plugin gemäß Plattform behandelt – **nur auf Geräten prüfbar**.
* Loop-Nahtlosigkeit der AAC-Musik ist nicht garantiert (Encoder-Priming; evtl. winziger Spalt).
