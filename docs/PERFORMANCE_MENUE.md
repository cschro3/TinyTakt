# Performance des Auswahlmenüs (Figur · Welt · Zeit · Musik)

Branch `feature/mira-meadow-slice`. Vergleich: **vorher** = Stand `47bb1ab`, **nachher** = Stand `c6fdba1`.
Diagramm: `perf/menue_vergleich.png` · Rohdaten: `perf/picker_*_roh.json`. Timer-Szene, Mira, Animationen wurden **nicht** angefasst.

## 0. Was gemessen wurde – und was nicht
**Nicht auf einem iPhone, nicht in Safari.** Gemessen wurde in Headless-Chromium mit **Software-WebGL** (CPU-Rasterung, Viewport 393×852, dpr 2, CanvasKit; Skript `tools/perf/picker_measure.js`: Menü öffnen, Leerlauf, 3× Hoch-/Runterscrollen per Touch-Geste, 8 Tab-Wechsel, Kachel antippen; je Phase die Bildintervalle). Das ist ein **relativer** Vergleich: Software-WebGL rastert langsam und skaliert mit Pixelzahl und Zeichenaufwand, das iPhone-GPU ist um Größenordnungen schneller. Absolute fps und Millisekunden sagen nichts über das iPhone; die Verhältnisse und das Verschwinden der Hänger sind aussagekräftig.
Zusätzlich: Dart-VM-Test (`test/tools/picker_bench_test.dart`) – **hier nicht aussagekräftig**, siehe §4.
Bildparität: Pixelvergleich aller vier Tabs (Free + Pro, mit Scroll-Zustand).

## 1. Ursachen (Ist-Zustand)
* Alle 81 Figuren (Fell, Verläufe, Blur, Teilbilder) wurden als **volle Vektorgrafik in jedem Frame** gerastert; ebenso 9 Welten und 10 Timer-Stile.
* Jede Kachel: **Blur-Schatten** (8/16 px), **antialiasierter Clip** (Material `Clip.antiAlias`), bei gesperrten Einträgen ein **`Opacity`-Layer** (Offscreen-Puffer je Kachel und Frame).
* **Tab-Wechsel**: `TabBarView` baute die Seite jedes Mal neu auf und zeichnete alles neu (kein Keep-Alive) → Hänger von 0,9–1,3 s, Scrollposition ging verloren.
* Alle vier Tabs hörten auf `d.all` (inkl. **Timer**) und bauten bei jeder Meldung alle Kacheln neu; `characters.where(...).toList()` lief **je Kachel**.
* Antippen einer Figur: Neuaufbau und Neuzeichnen aller sichtbaren Kacheln (≈ 1 s Stillstand).

## 2. Umsetzung (`lib/presentation/screens/picker_screen.dart`, neu `widgets/preview_cache.dart`)
1. **Gebackene Vorschauen**: Jede Figur, Welt und jeder Timer-Stil wird **einmal** mit demselben Painter, in derselben Größe und Pixeldichte in ein Bild gerendert (`toImageSync`, LRU-Cache) und danach nur noch als Bild gezeichnet. Gesperrte Einträge werden per Bild-Alpha gedimmt (kein `Opacity`-Layer); die gerundeten Welt-Ecken sind mitgebacken (kein Clip je Frame). Fällt `toImageSync` aus, wird wie bisher direkt gezeichnet.
2. **Gebackener Kachel-Rahmen** (Blur-Schatten, weiße Karte, Rand) statt je Frame zu zeichnen; Material ohne Clip, Splash bleibt über `InkWell(borderRadius)` gerundet.
3. **Tab-Seiten bleiben am Leben** (`AutomaticKeepAliveClientMixin`): kein Neuaufbau beim Zurückwechseln, Scrollposition bleibt.
4. **Engerer Listener**: Menü hört nur auf Einstellungen und Berechtigungen (`settings`, `entitlements`), nicht mehr auf den Timer; Kategorien einmal berechnet.
5. **Vorwärmen bei Ruhe**: 0,7 s nach dem Öffnen werden Welten, Timer-Stile und alle Figuren **unsichtbar** gelayoutet und je **ein Bild pro Frame** gebacken – nur wenn die letzten 700 ms keine Zeigerereignisse kamen (Scrollen/Tippen werden nie unterbrochen), höchstens bis 48 MB. Zusätzlich wird bei Figuren die Größe im „gewählten“ Zustand (Rand 4 px dicker) vorab gebacken, damit das Antippen nichts mehr zeichnet.
6. **Speicher**: Cache-Limit 64 MB (LRU); beim Schließen des Menüs werden offene Aufträge verworfen und auf 14 MB gekürzt.

## 3. Ergebnisse (alt → neu), Browser, Software-WebGL, dpr 2, Median aus 3 Läufen
### Menü war schon einige Sekunden offen (Vorwärmen fertig)
| Phase | Bilder/s | Intervall p95 | längster Hänger |
|---|---|---|---|
| Leerlauf | 60 → 60 | 17 → 17 ms | 17 → 17 ms |
| Runterscrollen | 25,8 → 28,2 | 117 → 67 ms | 825 → 117 ms |
| Hochscrollen | 16,2 → 31,0 | 133 → 67 ms | 950 → 83 ms |
| Tab-Wechsel (8×) | **8,2 → 47,8** | 916 → 50 ms | 2175 → 133 ms |
| Kachel antippen | **1,1 → 35,5** | 900 → 67 ms | 900 → 83 ms |

Längster Hänger je Tab-Wechsel (Welt, Zeit, Musik, Figur, Welt, Figur, Zeit, Figur): **933 / 1166 / 233 / 875 / 900 / 941 / 908 / 1300 ms → 117 / 133 / 117 / 67 / 67 / 67 / 67 / 67 ms** (Mittel 907 → 88 ms).

### Sofort nach dem Öffnen (Vorwärmen läuft noch)
Tab-Wechsel 8,1 → 42,4 fps, Antippen 1,1 → 35,5 fps (längster Hänger 950 → 100 ms), Hochscrollen 16,9 → 29,6 fps, Tab-Wechsel-Hänger Mittel 890 → 92 ms. Runterscrollen 23,6 → 21,3 fps (p95 133 → 183 ms; die noch nicht vorgewärmten Kacheln werden einmal gebacken), längster Hänger 917 → 417 ms.
**Nachteil:** Im Leerlauf direkt nach dem Öffnen sinkt die Bildrate **im Software-Raster von 43 auf 9 fps**, solange das Vorwärmen läuft (≈ 3 s, je Backen ≈ 50–250 ms CPU im Software-Raster, Spitzen bis 1,2 s). Auf einem echten GPU-Gerät ist das Backen deutlich billiger (nicht gemessen); Bedienung setzt das Vorwärmen aus.

### Wenig Pixel (dpr 1)
Tab-Wechsel 14,9 → 56,5 fps (Hänger 2125 → 100 ms), Antippen 2,2 → 55,6 fps, Hochscrollen 23,6 → 56,1 fps, Runterscrollen 32,2 → 40,4 fps.

## 4. Dart-VM-Bench (nicht aussagekräftig)
`picker_bench_test.dart` zeigt für das neue Menü höhere Werte (Öffnen 1161 → 1584 ms, Antippen 99 → 258 ms, Tab-Wechsel −11 %). Grund: Der Test misst nur Build/Layout/Aufzeichnung **ohne GPU-Rasterung** – dort fällt der Gewinn gar nicht an –, während `toImageSync` im Test-Engine real **auf der CPU rastert** und so die einmaligen Backkosten (und das Vorwärmen, das im simulierten Zeitraum läuft) als Mehrkosten sichtbar macht. Er ist hier daher nur als Warnhinweis zu lesen: Die Kosten des ersten Backens (Dart-Aufzeichnung der Painter + Textur-Erzeugung) fallen **einmalig** an und sind auf dem iPhone mit Safari zu prüfen (Overlay `?perf=1`: Zeilen `bake:char`, `bake:world`, `bake:style`, `bake:chrome`).

## 5. Bildqualität
Pixelvergleich alt/neu je Tab (393×852 @3, Free und Pro): Musik **exakt gleich**, Figur 37,5–41,6 dB, Zeit 37,2–38,1 dB, Welt 33,6–34,6 dB PSNR; nur 0,3–0,9 % der Pixel weichen sichtbar ab (> 24/255). Die Differenz sind **1-Pixel-Kanten** (Anti-Aliasing der gerundeten Ecken, Sub-Pixel-Skalierung der Bitmaps bei gebrochenen Kachelgrößen), keine Inhaltsunterschiede. Bewusst bleibt alles gleich: Farben, Schatten, Rand, Auswahlzustand, gedimmte Schlösser, `AnimatedScale` (0,985 → 1,0).
Ein Fund beim Vergleich: Einige Painter (Adventure-Diorama, Schatten) zeichnen **über ihre Box hinaus**; die gebackenen Bilder haben deshalb einen Rand (Figuren 4, Stile 10 px), damit nichts abgeschnitten wird.

## 6. Speicher
Bildspeicher des Menü-Caches nach vollem Vorwärmen (RGBA, Test `test/tools/picker_mem_test.dart`): **dpr 2: 36,5 MB (130 Bilder)**, **dpr 3: begrenzt auf ≈ 48 MB (71 Bilder, Vorwärm-Budget)**; sichtbare Bilder dürfen bis 64 MB wachsen. Weiter hinten liegende Figuren werden bei Bedarf einmal gebacken. Ohne Budget bräuchte dpr 3 ≈ 80 MB. Beim Schließen: Kürzung auf ≈ 14 MB. Zusätzlich liegt die Timer-Szene (≈ 19 MB Texturen bei dpr 3) im Hintergrund.

## 7. Tests
`flutter analyze` ohne Befunde; `flutter test`: **225 Tests** grün (neu `test/picker_perf_test.dart`, 12 Tests: Cache-Verhalten (einmal backen, Rand, LRU/MB-Limit, Klone), Vorwärmen nur bei Ruhe/je Frame/Budget, **Pixel-Gleichheit gebacken = direkt (≥ 45 dB)**, Kachel-Bilder, Antippen backt nichts mehr, Keep-Alive/Scrollposition, Menü ignoriert Timer-Meldungen, alle Tabs und Schlösser).

## 8. Auf dem iPhone prüfen
Staging mit **`?perf=1`** öffnen, Timer-Szene laden, oben links das Menü öffnen und durch die Tabs wischen/tippen. Das Overlay (oben links, auf der Timer-Seite darunter) zeigt Bilder/s; die Backkosten stehen in den Dart-Zeilen (`bake:char` usw., Millisekunden). Bitte Screenshot der Zahlen.

## 9. Bekannt / offen
* Echter iPhone-Safari-Test steht aus (siehe §0).
* Direkt nach dem Öffnen läuft ca. 3 s (Software-Raster) bzw. kurz (GPU) das Vorwärmen im Hintergrund; es wartet auf Ruhe, kann aber einen einzelnen Frame kosten (längstes einzelnes Backen: Welt/Stil).
* Antippen der **ersten** Welt/des ersten Stils (nur 9 + 10 Stück): die „gewählt“-Größe wird dort nicht vorgebacken (spart Hintergrundarbeit); das erste Antippen backt dort einmal.
* Die klassischen Timer-Stile und die Timer-Szene sind unverändert.
