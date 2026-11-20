# Offene Illustrations-Assets für die Abenteuerwelten (Stand 4.0)

Alle acht neuen Abenteuer sind **programmatisch gemalte Fallbacks** (Flutter-Canvas, `lib/presentation/art/adventure/`).
Sie haben eigene Wege, Ziele, Etappen und Ambiente – sind aber **keine Illustrationen** im Stil von Mira/Blumenwiese.
Für Premium-Qualität je Welt (gleiches Format wie `assets/art/meadow`, siehe `assets/art/manifest.json`):

| Welt | Hintergrund-Datei (WebP, 1199×1312, ohne Figur) | Ziel-Objekt (PNG/WebP, transparent) | Weg-Daten |
|---|---|---|---|
| space | `space_prototype.webp` – Nebel, Planeten, Sternenfeld, Flugroute frei | `space_goal.webp` Raumstation (1024²) | Route als Punktliste (wie `MeadowPath`) |
| sunset | `sunset_prototype.webp` – goldene Hügel, große Sonne, Laternenpfad | `sunset_goal.webp` Hütte mit Licht | dito |
| night | `night_prototype.webp` – Mond, Sterne, Hügel, silbriger Mondpfad | `night_goal.webp` Sternentor | dito |
| forest | `forest_prototype.webp` – Riesenbäume, Lichtstrahlen, Pilze, Waldweg | `forest_goal.webp` Baumhaus | dito |
| beach | `beach_prototype.webp` – Meer, Dünen, Palmen, Pfad | `beach_goal.webp` Leuchtturm | dito |
| underwater | `underwater_prototype.webp` – Korallen, Lichtstrahlen, Sandweg | `underwater_goal.webp` Schatztruhe/Muschel | dito |
| winter | `winter_prototype.webp` – Schneehügel, Tannen, Pfad | `winter_goal.webp` Iglu | dito |
| sky | `sky_prototype.webp` – Wolkenbrücke, Regenbogen, Inseln | `sky_goal.webp` Wolkenschloss | dito |

Je Welt zusätzlich gewünscht: Phone-Variante (≈900 px breit, ≤ 260 KB), getrennte Ebenen (Himmel / Mitte / Vordergrund) für Parallaxe, Ambiente-Sprites (Sterne, Fische, Schneeflocken …).
Einbau: Eintrag in `assets/art/manifest.json` + `VisualRegistry` (`_bitmapWorlds`) + `Path`-Datei – die Szene `StoryScene` (Bild-Story) nimmt die Welt dann statt `AdventureScene`.

Weiterhin offen (siehe 3.0): Mira-Zustände (Blinzeln, Laufzyklus, Jubel), Illustrationen für 80 Figuren.
