# Produktionspaket „Mira + Blumenwiese + Abenteuer-Timer“ (Vertical Slice)

**Warum dieses Dokument:** In der Entwicklungsumgebung gibt es kein Bildgenerierungs- oder Illustrationswerkzeug (keine GPU, keine Bild-API, kein Zeichenprogramm außer ImageMagick). Procedural gezeichnete Canvas-Formen erreichen die gewünschte Qualität nicht – das ist hiermit festgehalten. Dieses Paket ist die Vorlage, mit der eine Illustratorin/ein Illustrator **oder** ein Bildgenerator (z. B. mit eigenem API-Schlüssel) das Ergebnis erzeugen kann. Die Integration in Flutter (Abschnitt 6) wird erst nach Lieferung der Dateien umgesetzt.

## 1. Mira – Figurenbeschreibung
„Mira, die Lustige“: flauschiges Fantasiewesen, Mischung aus Eichhörnchen, Fuchs und Plüschtier. Verspielt, neugierig, warmherzig. Körper rundlich-weich, ca. 1,3 Köpfe hoch. Kopf groß, **Fellbüschel** als Krone und an den Wangen, **zwei spitz-runde Ohren** mit Innenfell und Haarbüscheln, **großer buschiger Schweif** (S-Form, Spitze heller), **kleine Pfoten mit rosa Ballen** (Herz-förmig am Brustfleck), **Herz-Brosche** auf der Brust (Markenzeichen, leuchtet sanft).
- **Farben:** Fell Lavendel `#B98CE8` → hell `#E7D3FF`, Schatten `#7C55C9`, Bauch/Brust Creme `#FFF3FA`, Ohr innen Rosa `#FFB5D6`, Augen Violett `#6B3FD1` mit Lichtpunkten, Brosche Pink `#FF6FAE`, Glühen `#D9B8FF`.
- **Stil:** 2,5D-Plüsch-Fantasy wie hochwertiger Kinderfilm/Spielfigur: sichtbare einzelne Haare an Kanten (Rim-Light), weiche Subsurface-Wirkung, Ambient Occlusion zwischen Körperteilen, großes feuchtes Auge mit Iris-Verlauf und 2 Glanzpunkten, kein harter Umriss, keine Vektor-Flächenoptik.
- **Licht:** warmes Sonnenlicht von links oben, kühles Rücklicht (Himmelblau) an der rechten Kontur, weicher Bodenkontakt-Schatten.

## 2. Lieferumfang Mira (Layered PSD/PNG, 2048×2048, transparent, Figur zentriert, Füße bei y=1900)
Teile **getrennt und überlappend ausgemalt** (verdeckte Bereiche fertig malen), Pivot als Notiz je Ebene:
`body`, `chest_fluff`, `head`, `ear_l`, `ear_r`, `tail` (+ `tail_tip`), `arm_l`, `arm_r`, `leg_l`, `leg_r`, `brooch` (+ `brooch_glow`), `cheek_fluff_l/r`, `crown_tufts`.
**Gesicht (Augen/Mund separat, Kopf ohne Gesicht):** `eyes_open`, `eyes_blink_half`, `eyes_closed`, `eyes_happy` (Bogen-Augen), `eyes_wide`, `eyes_wink`; `mouth_smile`, `mouth_grin_open`, `mouth_o`, `mouth_neutral`; `blush`.
**Zustände (jeweils auch als fertiges Gesamtbild-PNG zur Abnahme):** Ruhe (idle), Blinzeln (3 Phasen), Gehen (4-Frame-Zyklus, seitlich/3⁄4 nach rechts-hinten), Freude (Hüpfer: Anlauf, Luft, Landung), Winken, Ermutigung (Nicken), Erfolg/Jubel (Arme hoch, Augen happy, Funken), müde (Pause).

## 3. Blumenwiese – Tiefenebenen (je 1290×2796 @3×, PNG mit Alpha, nach unten nahtlos erweiterbar)
1. `sky` – Verlauf Himmelblau → warmes Gelb am Horizont, weiche Cumulus-Wolken (fotografisch-malerisch), Sonnenstrahlen-Layer separat (`sunrays`, additive).
2. `far_hills` – 2 Hügelreihen im Dunst (atmosphärische Perspektive: blasser, bläulicher), ferne Baumgruppen, Windmühle/Häuschen winzig.
3. `mid_meadow` – satte Hügel mit gemalten Gräsern, Büschen, 3–4 Laubbäume mit Blattmassen und Lichtflecken, Blumeninseln.
4. `path` – **gemalter Pfad** (Erde/Kiesel/Gras-Ränder, Spurrillen, Moos, kleine Steine, Gänseblümchen am Rand), von vorn unten links in S-Kurve zum Häuschen oben rechts, perspektivisch verjüngt, mit Wegpunkt-Plätzen (siehe 4).
5. `foreground_left/right` – große unscharfe Vordergrundpflanzen (Gräser, Mohn, Kornblumen, Margeriten) als Rahmen, leichter Tiefenunschärfe-Look.
6. `fx` – separate Sprites: Schmetterlinge (2 Arten, 3 Flügelstellungen), Bienen, Pollen-Glitzer, Löwenzahnsamen, Lichtflecken, Gras-Wippen-Streifen (für Parallax).
Gesamtlicht: goldene Stunde, weiche Schatten, sanfte Vignette, keine harten Konturen.

## 4. Abenteuer-Timer – grafisches Erscheinungsbild (passt zu Pfad der Wiese)
Kein Vektorstrich. Der Fortschritt ist **der gemalte Pfad selbst**, den Mira entlangläuft:
- `path_done` / `path_todo`: gleicher Pfad in zwei Zuständen (todo: Gras und Tau darüber, schwächer; done: festgetreten, kleine Blumen/Fußspuren hinter Mira).
- **4 Wegpunkte** (25/50/75/100 %): kleine gemalte Objekte am Pfad – Holzschild mit Blume, Brücke, Torbogen aus Blumen, **Ziel: gemütliches Häuschen mit Rauch und Licht im Fenster**; je ein Zustand „offen/erreicht“ (Blumen blühen auf, Laternen an).
- `progress_chip`: dezente Fortschrittsanzeige als gemalter Holz-/Blatt-Streifen (kein Standard-Balken).
- Abschluss: Mira erreicht das Häuschen, Tür öffnet sich, Lichtstrahl, `confetti`-Blütenblätter (gemalt), Jubel-Zustand.

## 5. Abnahmekriterien (zuerst Mira + Wiese + Timer, dann Freigabe)
Auf einem iPhone (390×844 pt @3×) ohne Hinweis erkennbar als hochwertige Kinderfilm-/Spielfigur-Illustration; Fell mit sichtbarer Haarstruktur; mind. 3 klar getrennte Tiefenebenen mit atmosphärischem Dunst; Pfad und Timer wirken wie Teil der Welt; alle 8 Zustände konsistent (gleiche Proportionen, Farben, Lichtrichtung). Dateigröße gesamt ≤ 12 MB (WebP/PNG komprimiert).

## 6. Integrationsvertrag (Flutter, wird nach Lieferung umgesetzt)
```
assets/art/mira/manifest.json
{ "size": 2048, "layers": [ {"id":"body","file":"body.webp","pivot":[x,y],"z":10}, ... ],
  "eyes": {"open":"eyes_open.webp", ...}, "mouths": {...},
  "clips": {"walk":["walk_0.webp",...]} }
assets/art/meadow/{sky,far_hills,mid_meadow,path,foreground_left,foreground_right}.webp, fx/*.webp
assets/art/adventure/{path_done,path_todo,wp_1..4_off|on,house,progress_chip}.webp
```
`SpriteFigure` (ersetzt für `nova_mira` den Painter) lädt Ebenen, animiert per bestehendem Rig (`computePose`: Atmen, Kopfneigen, Ohren, Schweif, Blinzeln, Emotionen); Welt als Parallax-Ebenen mit Wind-Wippen; Abenteuer-Timer legt Mira auf den gemalten Pfad (Pfad-Polylinie als Koordinatenliste im Manifest). Fallback auf die bisherige Darstellung, falls Dateien fehlen. Tests: Manifest-Validierung, Laden aller Ebenen, Rig-Zuordnung, Screenshot auf 3 Geräten.

## 7. Bildgenerator-Prompt (englisch, falls ein Generator genutzt wird)
*Mira character sheet:* "Adorable fluffy fantasy creature named Mira, lavender-purple fur with visible individual hairs and soft rim light, cream chest with a glowing pink heart brooch, large round head with pointed-round ears with pink inner fur and tufts, big glossy violet eyes with two highlights, bushy S-curved tail with lighter tip, tiny paws with pink heart-shaped pads, plush toy meets premium animated children's film, 2.5D, soft subsurface scattering, warm key light from upper left, cool blue rim light, neutral transparent background, front view, full body, 2048px". Danach je Zustand (Pose-Variation, Gesicht getrennt) mit identischer Figur (Referenzbild/Seed).
*Meadow layers:* "Painterly flower meadow, golden hour, layered depth with atmospheric haze, hand-painted children's book illustration, rich foliage, wildflowers, winding dirt path with pebbles and moss leading to a cozy cottage, soft shadows" – je Ebene als einzelne Transparenz-Ebene separat erzeugen/freistellen.
