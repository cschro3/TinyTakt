# Premium-Redesign & Character Experience 2.0 – Bericht

Branch `feature/premium-redesign` (Stand vor Redesign: Tag `pre-premium-redesign`). Vergleichsbilder: `docs/redesign/`.

## A. Bestandsaufnahme (Befund vor dem Redesign)
Alle 81 Figuren, 9 Welten und 10 Timer-Stile waren flache Vektorformen; Figuren animierten nur Wippen/Blinzeln; NOVA-Figuren hatten kaum Eigenheiten; Abenteuer-Timer war ein schwebender Weg; kein Abschlussmoment; Auswahlkarten schnitten Namen ab; Widget-Tests mussten wegen höherer Karten auf `hitTestable()` umgestellt werden; Audio ohne Crossfade/Pegelgrenzen. Die fünf vom Auftraggeber erwähnten Screenshots sind im Chat **nicht angekommen** – die Analyse stützt sich auf die eigenen Renderings der Vorgängerversion.

## B–C. Umgesetzt
| Bereich | Ergebnis |
|---|---|
| Figuren | 11 Premium-Figuren neu: NOVA Lumi (Fuchs-/Kaninchenohren, Flausch, blauer Glanz), Zeno (Löwenmähne, Funkeln, Fellbüschel), Mira (Schweif, Herzbrosche, Lila-Glühen), Hund (Schlappohren, Fleck), Katze (Schlitzpupillen, Streifen), Hase (lange Ohren, Blume), Hamster (Backentaschen), Papagei (Federschuppen, Haube), Kuh (Flecken, Hörner, Glocke), Schwein (Rüssel, Ringelschwanz), Schaf (Wollwolke). Identitäten/Namen unverändert. |
| Animation | Wiederverwendbares Rig (`rig.dart`): Atmen, Blinzeln (inkl. Doppelblinzeln), Blick, Ohren/Schwanz, Begrüßung, Freude beim Start, Ermutigung bei 75/50/25 %, Jubel am Ende, Müdigkeit in der Pause; Persönlichkeitsparameter je Figur; Ruhemodus statisch. |
| Welten | Alle 9 neu gemalt mit Tiefenebenen, Dunst, Lichtstrahlen, Partikeln: Blumenwiese, Zauberwald, Sternennacht (Polarlicht, Sternschnuppe), Weltraum (Planeten, Komet, Nebel), Strand (Wellen, Palme), Wolkenhimmel (Ballon), Unterwasser (Lichtstrahlen, Fische, Blasen), Winter (Schnee), Abendrot. |
| Timer-Geschichten | Abenteuer (Diorama mit Weg/Wegpunkten/Häuschen, je Welt getönt), Kreis (leuchtender Bogen, Glanz, Endkappe), Füllstand (zwei Wasserschichten, Blasen, Skala), Regenbogen (glänzende Bänder, Funke an der Spitze, Wolken), Sanduhr (Holzrahmen, rieselnder Sand, Trichter). Jeder Stil: klarer Fortschritt, Abschluss mit Konfetti + Jubel, Neustart-Button. |
| Bild-Timer | Eis, Kerze, Pflanze, Pizza, Puzzle unverändert im Funktionsumfang (Premium-Überarbeitung offen, s. u.). |
| UI/UX | Auswahlkarten (Pastellbühne, Name + Beiname, Schatten, Auswahlzustand), Pro-Hero mit NOVA-Figuren, Seitenübergänge, kompaktes Home-Layout für kleine Telefone (behebt abgeschnittene Minutenleiste auf 360×640), Regler „Effekte & Alarm“. |
| Audio | Crossfade (zwei Player, 1,6 s), getrennte Regler Musik / Effekte+Alarm, harte Pegelgrenzen (0,8/0,9), Start-Effekt + sanfter Countdown-Tick (neu synthetisiert), Stumm-/Ruhemodus ohne Effekte, `AUDIO_LICENSES.md`. |
| Technik | Statische Ebenen als `ui.Picture` gecacht; keine neuen Abhängigkeiten; Einstellungen/Daten unverändert (kein Migrationsbedarf). |

## D. Qualitätssicherung (reale Ergebnisse)
- `flutter analyze`: keine Befunde.
- `flutter test`: **176 Tests grün** (vor dem Redesign-Abschluss 160; +16 neue); neu `test/premium_art_test.dart` (Rig-Logik, jede Figur × jede Emotion rendert sichtbar, Silhouetten paarweise verschieden, jede Welt deckt 100 % auf Phone/Tablet/quer, Abenteuer-Geometrie, klassische Stile zeigen Fortschritt, Konfetti, Bühnen-Regie inkl. Ruhemodus) und Audio-Tests im Timer-Controller (Start-Effekt, Stumm, Ruhemodus).
- Timer-Logik mit Unterbrechungen: bestehende Engine-/Controller-Tests (Pause/Resume, Hintergrund, Neustart, beschädigter Snapshot) unverändert grün.
- Performance (Dart-Aufzeichnungszeit pro Bild, CPU des Build-Containers, **kein** GPU-Rastern): Welten 0,04–0,71 ms, Figuren 0,12–0,35 ms, Diorama 0,29 ms (`test/tools/perf_bench_test.dart`). Echtes Geräte-Profiling steht aus.
- Visuelle Prüfung: Renderings auf 440×956, 360×640, iPad 1032×1376; Vorher/Nachher in `docs/redesign/`.

## Ehrliche Einordnung
- Die Kunst ist **prozedurale Vektorgrafik**, kein handgemalter Illustrationsstil. Sie wirkt deutlich hochwertiger als vorher, erreicht aber nicht die Tiefe einer Studio-Illustration. Asset-Spezifikation für eine Illustratorin/einen Illustrator: `DESIGN_SYSTEM.md` §8.
- Nur die 11 genannten Figuren sind Premium; die übrigen 70 (z. B. Löwe, Panda) haben noch den alten Stil.
- Audio wurde **nicht abgehört** (nur technisch geprüft). iOS-Build, Apple-Music-Swift-Modul und Gerätetests: nicht möglich in dieser Umgebung.
- Offen: Premium-Überarbeitung der fünf Bild-Timer (Eis/Kerze/Pflanze/Pizza/Puzzle), Erfolgs-Fanfare als eigener Effekt (verworfen, würde den Alarm überlagern), Duration-/Musik-Sheet-Feinschliff, Geräte-Screenshots der Stores neu generieren und Web-Preview neu deployen.
