# Audio: Herkunft, Lizenz, Pegel

**Alle Klänge in `assets/audio/` sind in diesem Projekt selbst synthetisiert** (`tools/generate_audio.py`, Python + NumPy, Ausgabe AAC/m4a über ffmpeg). Es wurden **keine** Samples, Loops, Bibliotheken oder Aufnahmen Dritter verwendet. Die Stücke sind eigene Werke des Projekts; es entstehen keine Lizenzpflichten Dritter, keine Namensnennung ist erforderlich.

| Gruppe | Dateien | Erzeugung |
|---|---|---|
| Musik (13) | `music_*.m4a` | additive Synthese (Sinus/Glocke/Zupf/Harfe/Pad), Hall, eigene Akkordfolgen und Melodien; nahtlose Schleifen |
| Alarme (6) | `alarm_*.m4a` | kurze Glocken-/Marimba-/Harfen-Figuren mit Ausklang |
| Effekte (2) | `sfx_start.m4a` (Start, zwei aufsteigende Glöckchen), `sfx_tick.m4a` (3-2-1-Tropfen) | wie oben |

Neu erzeugen: `python3 tools/generate_audio.py assets/audio [name …]` (benötigt `numpy`, `ffmpeg`).

## Pegel (gemessen mit ffmpeg `volumedetect`)
Spitzen: Musik ≈ −7 dBFS, Alarme ≈ −3 dBFS, Effekte ≈ −4…−5 dBFS; keine Übersteuerung.

## Sicherheit der Lautstärke (in der App)
- Musik und Effekte/Alarme haben **getrennte** Regler (`musicVolume`, `alarmVolume`).
- `AudioService` begrenzt hart: Musik ≤ 0,8, Effekte/Alarme ≤ 0,9 des Systempegels.
- Stumm schaltet Musik, Effekte, Alarm und Sprache ab (Benachrichtigung bleibt); Ruhemodus spielt keine Effekte/Musik.
- Titelwechsel blenden weich über (Crossfade 1,6 s, zwei Player); Stopp/Pause blenden 1,2 s aus.
- Die Systemkategorie respektiert den Stumm-Schalter (iOS „ambient“) und nutzt Ducking (Android).

## Offen
Hörabnahme durch Menschen (Klang, Angenehmheit, Schleifenübergänge, Kindgerechtheit) steht aus – die Synthese wurde nur technisch geprüft.
