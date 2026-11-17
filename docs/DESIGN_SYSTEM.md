# TinyTakt – Kreativrichtung & Design-System („Animated Storybook“)

Ziel: Der Timer fühlt sich an wie ein kleines, lebendiges Bilderbuch – warm, weich, ruhig, nie hektisch.

## 1. Prinzipien
1. **Weiche Volumen statt flacher Formen.** Jede Figur und jedes Objekt hat Verlauf, Innenschatten und Rücklicht (`fillVolume`).
2. **Tiefe durch Schichten.** Welten bestehen aus 3–5 Ebenen (Himmel, Ferne, Mitte, Vordergrund) mit Dunst dazwischen; Bewegung nur in einzelnen Details.
3. **Ruhe vor Effekt.** Partikel sind klein, langsam und selten; nie über der Figur oder dem Timer. Im *ruhigen Modus* steht alles still (≈ 4 Bilder/s, statische Pose).
4. **Zeit ist immer lesbar.** Fortschritt steckt in Form und Zahl, nie nur in Farbe (Ring-Marken, Glas-Skala, Wegpunkte, Segmente).
5. **Charakter vor Dekoration.** Jede Figur hat eigene Silhouette, Fell-/Federstruktur, Augenform und Bewegungsmuster.

## 2. Farben (siehe `lib/presentation/theme.dart`, Klasse `Brand`)
| Token | Wert | Verwendung |
|---|---|---|
| indigo / indigoDark | `#3B2F7F` / `#241B57` | Primär, Text auf hell, Auswahlrahmen |
| coral | `#FF7A59` | Hauptaktion (Start/Pause) |
| sun | `#FFC83D` | Akzent, Sperr-Symbol |
| mint | `#2FC4A8` | Fortschritt (>50 %), Schalter an |
| sky | `#6EC1F5` | Pause im Lernplan |
| cream | `#FFF8EC` | Hintergrund Erwachsenen-/Listenscreens |
| ink | `#2B2440` | Text |
Fortschrittsfarbe: >50 % mint, >20 % amber `#FFB02E`, sonst coral `#FF7A59`; Pause blau.

## 3. Typografie
Nunito (gebündelt). Zeit-Anzeige 900er Schnitt, groß; Titel w900 22 px; Karten-Name w900 14 px, Beiname w700 11,5 px; Fließtext ≥ 14 px. Skaliert mit der Systemschrift.

## 4. Abstände, Radien, Schatten
Raster 4/8/12/16/24 px. Karten Radius 24, Pillen/Buttons 24–28, Bühne 12 px Innenrand. Schatten: weich, indigo-getönt (`#3B2F7F` mit 8–28 % Deckkraft, Blur 8–16). Mindest-Touchfläche 48×48 dp (Schnellwahl 52×48, große Buttons 76+).

## 5. Bewegung
- Seitenwechsel: Fade-Forwards (Android) / Cupertino (iOS).
- Auswahl: Karte skaliert 0,985 → 1,0 in 180 ms, Rahmen 3,5 px + Schatten.
- Figur-Emotionen: calm, greet (Winken, 2,4 s), cheer (Doppelhopser beim Start, 1,8 s), encourage (Nicken bei 75/50/25 %, 2,2 s), celebrate (Jubelhopser, klingt nach ≈ 4 s auf ein sanftes Weiterhüpfen ab), sleepy (Pause).
- Konfetti 3,4 s, danach ausgeblendet; im ruhigen Modus entfällt es.

## 6. Technische Bausteine (`lib/presentation/art/`)
| Datei | Zweck |
|---|---|
| `art_kit.dart` | Catmull-Rom-Silhouetten, `fillVolume`, `furTexture`, `furFringe`, `plush()`, `featherScales`, Glanz/Glühen, `PictureCache` |
| `rig.dart` | `Pose`, `Personality`, `Emotion`, `computePose(...)` – gesamte Animationslogik (rein, testbar) |
| `face.dart` | Gesichtssystem: Augen (glänzend, Schlitzpupillen, Lider), Nase, Mund, Wangen |
| `figures/` | 11 Premium-Figuren (NOVA Lumi/Zeno/Mira, Hund, Katze, Hase, Hamster, Papagei, Kuh, Schwein, Schaf) als gecachte Teile mit Pivot-Animation |
| `worlds/` | 9 Welten (`WorldArt`): statische Ebenen als `ui.Picture` je Bildschirmgröße gecacht, nur bewegte Details pro Bild |
| `timers/adventure.dart` | Abenteuer-Diorama (Hügel, Weg, Wegpunkte, Häuschen) je Szenerie getönt |
| `timers/classic.dart` | Kreis, Füllstand, Regenbogen, Sanduhr |
| `celebration.dart` | Konfetti, Ring, Sterne zum Abschluss |

Regie: `TimerStage._direct` leitet aus Timer-Zustand und Fortschritt die Emotion ab (keine Zeitlogik im UI).

## 7. Barrierefreiheit
Reduzierte Bewegung = „Ruhiger Modus“ (statische Pose, keine Partikel/Konfetti, wenige Bilder/s). Semantik-Labels auf allen Karten/Buttons (gesprochene Dauer). Zeit zusätzlich als Zahl. Kontrast: Text/Zahlen dunkel auf weißen Pillen.

## 8. Asset-Spezifikation für professionelle Illustration (falls gewünscht)
Die gesamte Kunst ist **prozedurale Vektorgrafik (CustomPainter)** – bewusst: kleine App, beliebig skalierbar, keine Fremdrechte. Sie erreicht nicht die Detailtiefe handgemalter Illustration. Für einen weiteren Qualitätssprung:
- **Figuren (je Figur, 11 Premium + optional die übrigen 70):** Layered SVG oder Lottie/Rive, Quadrat 1024², Teile getrennt benannt (`body`, `head`, `ear_l/r`, `arm_l/r`, `tail`, `eye_l/r` + Lid, `mouth_open/smile/grin/o`, `cheek`), Pivots als Marker; 6 Gesichtszustände (neutral, glücklich, Freude, erstaunt, schläfrig, zwinkern). Palette siehe Abschnitt 2, weiche Schattierung, kein harter Umriss.
- **Welten (9):** je 4–5 Ebenen als SVG/WebP @3× (Himmel, Fern, Mitte, Vorn, Details), 1290×2796 und 2048×2732, nahtlos nach unten verlängerbar; Parallax-Ebenen mit Alpha.
- **Timer-Objekte:** Glas, Sanduhr, Regenbogen, Diorama-Elemente als getrennte SVG-Ebenen.
- **Audio:** Hörabnahme/Neuaufnahme – siehe `AUDIO_LICENSES.md`.
Lieferformat/Lizenz: eigene Werke mit übertragenen Nutzungsrechten, keine Stock-Elemente ohne Rechte.
