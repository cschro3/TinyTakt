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

## Staging und Verifikation (tatsächlich ausgeführt)
- **Branch:** `feature/mira-meadow-slice` (Basis `feature/premium-redesign`), nichts nach `main` gemergt.
- **Staging-Link (ohne Login):** https://tinytakt-preview-git-feature-mira-meadow-slice-cschro.vercel.app – baut Vercel automatisch bei jedem Push des Branches.
- **Version prüfen:** `…/build.json` (SHA, Branch, Zeit) und in der App unter Eltern → Information → „Version & Build“. Die SHA ist die des Basis-Commits der Web-Dateien (`tools/build_web.sh`).
- **Ausgelieferte Dateien verifiziert:** `mira_prototype.webp` (299 664 B, `image/webp`), `meadow_prototype.webp` (407 480 B), `main.dart.js` (3,83 MB), `build.json` mit der erwarteten SHA.
- **Echter Browserlauf** (Chromium, 393×852 @2, iPhone-Maße, CanvasKit/WebGL-Software): Onboarding → Start-Bildschirm mit vorgewählter Mira + Wiese → 1-Minuten-Timer → Start → Pause (Zeit stand >6 s still) → Fortsetzen → Ende („Geschafft!“, Mira am Häuschen). Bilder: `staging_chromium_*.png`. Kein Safari/iPhone-Test möglich.
- **PWA-Cache:** `--pwa-strategy=none` (leerer Service Worker, kein Cache); ein alter, auf dem iPhone installierter Worker wird beim nächsten Laden ersetzt. Falls die Home-Bildschirm-App noch „alt“ zeigt: App schließen und neu öffnen, notfalls Verknüpfung löschen und neu anlegen.
- **Ursache des „flachen“ Eindrucks:** Die Haupt-URL `tinytakt-preview.vercel.app` baut von `main`; dort liegt der Stand vor dem Redesign (Commit `4bce4d6`). Das Staging-Preview ist nur über die Branch-URL erreichbar.
- **Bildrate:** im Headless-Browser ohne GPU (Software-WebGL) 6,3 Bilder/s neu vs. 2,0 am Vorgänger-Stand – nur als relativer Vergleich brauchbar, **keine Aussage über iPhone-Leistung**. Maßnahmen: Erweiterungsstreifen als Bild gecacht, Rand-Fade per Vertex-Alpha (kein Vollbild-Layer), ca. 2 600 Dreiecke je Bild.
- **Bekannt, nicht neu:** In beiden Ständen meldet der Headless-Browser einmal `PAGEERROR: Error` ohne Text (vermutlich Wake-Lock-API im Headless-Modus); die App läuft davon unbeeinflusst weiter.
