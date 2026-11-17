# Prototyp-Assets (Mira + Blumenwiese) – Herkunft, Technik, Grenzen

**Status: visueller Prototyp, keine fertigen Produktionsassets.** Eingebunden wird die vom Auftraggeber gelieferte Designrichtung (`tinytakt_visual_pack`, mit ChatGPT erzeugt).

## Was eingebunden ist
| Datei | Herkunft | Verarbeitung |
|---|---|---|
| `assets/art/mira/mira_prototype.webp` (RGBA, 1097×1093, 0,3 MB) | `mira_character_concept.png` (RGB, **eingebranntes Schachbrett**) | **Freigestellt** mit `tools/matte_mira.py`: Hintergrund per Chroma-Flood-Fill vom Rand erkannt, Trimap, Closed-Form-Matting (PyMatting), Vordergrundfarbe vom Schachbrett befreit. Ergebnis hat **echtes Alpha** (Ecken Alpha 0, ~32 % transparent). Prüfung: Test `test/story_test.dart` + `docs/art/mira_alpha_pruefung.png` (dunkel/grün/hell hinterlegt). |
| `assets/art/meadow/meadow_prototype.webp` (RGB, 1199×1312, 0,4 MB) | `blumenwiese_concept.png` | unverändert (verlustbehaftet nach WebP). **Keine Ebenen** – ein zusammengesetztes Bild. |

## Grenzen (ehrlich)
- Der Freistellungs-Schnitt ist ein **Prototyp**: Haar-Ränder sind sehr gut, aber nicht von Hand retuschiert; feine Härchen sind nur so gut wie die Vorlage. Für Produktion bitte ebenenfertige Neu-Exporte (siehe `ASSET_ANFORDERUNG_RUNDE2.md`).
- Mira ist **ein Standbild** (sitzend, zwinkernd). Bewegung entsteht durch **Mesh-Verformung des echten Bildes** (`MiraMesh`): Atmen, Kopfneigen, Ohrenwackeln, Schweifschwung, Antennenwippen, Hüpfen/Stauchen. Es gibt **kein Blinzeln, keinen Laufzyklus, keine Jubel-/Müde-Pose** – dafür fehlen Bildebenen.
- Die Wiese hat **keine Tiefenebenen**. Umgebungsleben: Wind-Wiegen des Vordergrunds (Mesh), Sonnenstrahlen, Laternen-/Fensterglühen, Wasserfunkeln, Pollen. Echter Parallax ist erst mit getrennten Ebenen möglich. Das Bild wird für das hohe Telefon-Format im Mittelband sanft gestreckt, oben/unten durch gespiegelte, weichgezeichnete Streifen ergänzt.
- Der Weg (`MeadowPath`) wurde von Hand aus dem Bild abgelesen; die Sternsteine sind die sieben Etappen.
- **Keine Aussage „Studioqualität“**, solange keine professionell erstellten Ebenen eingebunden sind.

## Technik
`ArtImages` lädt beide WebP; `StoryScene` zeichnet Hintergrund-Mesh (24×56, Wind), Lichteffekte, Mira (28×28-Mesh) und Etappen-Effekte; `StoryStage` meldet den Layout-Bereich und zeigt die **Flutter-Fortschrittsleiste** (`StoryProgressBar`) und den 3-2-1-Countdown. Zeit, Pause, Stopp, Buttons und Musik bleiben die bisherigen Flutter-Komponenten. Aktiv nur bei **Mira + Blumenwiese + Abenteuer**; ohne geladene Bilder greift die bisherige Bühne.
Performance: ca. 2 600 Dreiecke je Bild, kein Shader-Wechsel; im ruhigen Modus ca. 4 Bilder/s.
