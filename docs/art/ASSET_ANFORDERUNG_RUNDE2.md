# Zusätzliche Grafiken für Mira + Blumenwiese (Anforderung Runde 2, zu erstellen mit ChatGPT)

Ziel: aus dem Prototyp (Standbild + Mesh-Bewegung) wird eine echte Animation mit Zuständen und Tiefe. **Alles als PNG mit echtem Alpha-Kanal** (kein Schachbrett im Bild!), sRGB.
Prüfung nach dem Export (kostenlos, lokal): Bild in einen Bildbetrachter mit farbigem Hintergrund legen – bleibt ein Schachbrett sichtbar, ist es eingebrannt und muss neu erzeugt werden. Ich prüfe jede Lieferung zusätzlich automatisch.

## A. Mira – Zustandsbilder (höchste Priorität)
**Gemeinsame Regeln:** Leinwand **1400×1400 px**, Mira gleich groß und an **derselben Stelle** wie im Referenzbild (Füße unten bei y≈1330, horizontal mittig), transparenter Hintergrund, identische Farben/Licht/Proportionen. Arbeitsweise in ChatGPT: das freigestellte Referenzbild (`mira_prototype.webp` als PNG) hochladen und je Datei **bearbeiten lassen**, nicht neu würfeln.
Prompt-Vorlage: *„Verändere dieses Bild nur wie folgt: <Änderung>. Alles andere (Fell, Farben, Licht, Pose, Position, Größe) bleibt pixelgenau gleich. Transparenter Hintergrund (echter Alpha-Kanal), kein Schatten, kein Boden, kein Schachbrett.“*

| Datei | Änderung |
|---|---|
| `mira_idle_open.png` | beide Augen offen, freundliches Lächeln (Ruhe-Basis) |
| `mira_blink_half.png` / `mira_blink_closed.png` | Augen halb geschlossen / ganz geschlossen (Blinzeln, 3 Phasen mit idle) |
| `mira_joy.png` | Augen als fröhliche Bögen (^ ^), Mund weit offen, Pfoten leicht angehoben |
| `mira_cheer_finish.png` | Jubel: beide Vorderpfoten hoch, Augen fröhlich, Mund offen, Funkeln um die Antennen |
| `mira_sleepy.png` | Augen halb geschlossen, kleines Lächeln, Kopf leicht geneigt (Pause) |
| `mira_walk_a.png`, `mira_walk_b.png` | Hüpf-/Laufposen **leicht nach rechts oben schauend (¾-Ansicht)**: a = Abstoßen (Körper gestaucht), b = Flugphase (Pfoten gestreckt) |
**Optional (für noch weichere Bewegung):** `mira_ear_l.png`, `mira_ear_r.png`, `mira_tail.png` als einzelne Teile (jeweils auf 1400×1400, an Originalposition, Verdecktes ergänzt) + `mira_body_no_ears_tail.png`.

## B. Blumenwiese – Ebenen (deckungsgleich zum Konzeptbild)
**Gemeinsame Regeln:** jede Ebene als Vollbild **1199×1312 px**, exakt dieselbe Perspektive/Kamera wie `blumenwiese_concept.png` (damit der Weg und die Sternsteine passen), Alpha wo die Ebene endet. Prompt-Vorlage: *„Teile dieses Bild in Ebenen. Gib nur die Ebene <Name> zurück, alles andere transparent, ergänze verdeckte Bereiche malerisch im gleichen Stil.“*

| Datei | Inhalt |
|---|---|
| `meadow_sky.png` | Himmel, Wolken, Sonne, Berge, ferner See (ohne Hügel) |
| `meadow_far.png` | ferne Hügel und Bäume (hinter dem Weg) |
| `meadow_mid_path.png` | Hügel mit Weg, **ohne Sternsteine, ohne Haus** |
| `meadow_stones_on.png` / `meadow_stones_off.png` | die 7 Sternsteine an Originalposition: leuchtend bzw. gedämpft (zeigt erreicht/offen) |
| `meadow_house_closed.png` / `meadow_house_open.png` | Häuschen mit Fahne: Tür zu / Tür offen, Fenster hell |
| `meadow_tree_lantern.png` | Baum mit Laterne und Blättern oben links (Überhang, Alpha) |
| `meadow_foreground_left.png`, `meadow_foreground_right.png` | Vordergrund-Blumen/Gräser/Pilz/Steine als Rahmen |
| `fx_butterfly_a_1..3.png`, `fx_butterfly_b_1..3.png` | je ein Schmetterling in 3 Flügelstellungen, 256×256, Alpha |
| `fx_sunrays.png` | Lichtstrahlen als helles Overlay auf Schwarz (additiv) |

## C. Reihenfolge / Abnahme
1. A (Mira-Zustände) → ich baue Blinzeln, Laufzyklus, Jubel-Pose, Müdigkeit ein.
2. B (Ebenen) → ich ersetze das Einzelbild durch echten Parallax mit Wind je Ebene.
3. Erst nach deiner visuellen Freigabe auf dem iPhone werden Lumi, Zeno, weitere Figuren und Welten nach dem gleichen Verfahren umgesetzt.
Dateien bitte in einen Ordner `assets_neu/mira/` und `assets_neu/meadow/` legen und mir als ZIP geben.
