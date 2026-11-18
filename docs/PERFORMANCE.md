# Performance der Mira-Szene (Mobile Performance Optimization)

Branch `feature/mira-meadow-slice`. Vergleich: **vorher** = Stand `bf5ea43` (Web-Build 6adbcff, das Staging vor dieser Arbeit), **nachher** = Stand `cdcb997`.
Diagramm: `perf/vergleich.png` · Bildqualität: `perf/qualitaet_vergleich.png` · Rohdaten: `perf/*.json`.

## 0. Was tatsächlich gemessen wurde – und was nicht
**Gemessen wurde nicht auf einem iPhone und nicht in Safari.** Es gab ausschließlich:

| Messung | Umgebung | Aussagekraft |
|---|---|---|
| Bildintervalle, Heap, Ladezeit | Headless-Chromium (Playwright) mit **Software-WebGL (SwiftShader)**, Viewport 393×852, dpr 1/2/3, CanvasKit, lokal ausgelieferte Builds | **Relativer** Vergleich Alt/Neu. Software-WebGL rastert auf der CPU und skaliert mit der Pixelzahl (dpr 1 → 2 → 3 gibt beim Altstand 21 → 6,7 → 2,1 fps); absolute fps sagen **nichts** über ein iPhone-GPU. |
| Dart-Kosten je Bild | `flutter test` (Dart-VM, JIT), echter Home-Screen mit laufendem Timer, 60-Hz-Takt simuliert | Build + Layout + Paint-Aufzeichnung + Compositing, **ohne GPU**. In dart2js/Wasm auf dem Telefon ist es ein Mehrfaches. Nur auf derselben Maschine vergleichbar. |
| Bildqualität | Pixelvergleich im ruhigen Modus (deterministisch) | belastbar |
| Texturspeicher | Rechnung aus Bildgrößen + Wert aus dem Overlay (9,5 MB bei dpr 2) | Schätzung, keine GPU-Messung |

**Ein echter iPhone-Safari-Test steht aus.** Dafür ist ein Mess-Overlay eingebaut (siehe §6), mit dem die Zahlen auf dem Gerät ablesbar sind.

## 1. Reproduktion und Ursachen (Ist-Zustand, Ablation)
Ablation am **unveränderten** Altstand (`PERF_OFF=…`, dpr 2, je 2 Läufe, Mittel):

| Variante | fps | Δ |
|---|---|---|
| alles an (Ist) | 6,5 | – |
| ohne Strahlen | 7,1 | +9 % |
| ohne Effekte (Glühen, Funkeln, Pollen mit Blur-Filter) | 7,7 | +18 % |
| ohne Vignette + Tönung | 9,3 | **+42 %** |
| ohne Erweiterungsstreifen | 7,3 | +12 % |
| ohne Mira | 6,8 | +5 % |
| nur Netz + UI („Boden“) | 14,9 | +127 % |

Befund: Der Altstand zeichnete **jedes Bild** (bis 60/s) alles neu: Himmelsverlauf, Streifenbild, 1 500-Dreieck-Vollbild-Netz mit Vertex-Farben, Tönung, Vignette, 7 additive Strahlen-Dreiecke, 26 Partikel **mit Blur-Filter**, Mira-Netz (841 Vertices mit sin/cos je Vertex), Blur-Schatten – plus Neuaufbau der Szene per `ValueListenableBuilder` und einen Home-Neuaufbau **4× pro Sekunde** (250-ms-Timer-Takt). Dazu ein ständiger 60-Hz-Ticker im Home-Screen und je 4,6 + 6,0 MB Bild-Texturen ohne Anpassung an das Gerät.

Ablation am **neuen** Zwischenstand (volle Stufe) zeigte danach: Hintergrundleben 29,6 fps ohne vs 11,5 mit; davon waren es die **drei Vollbild-Strahlenebenen** (ohne Strahlen 24 fps), Wind 16 %, Glühen/Partikel ≈ 0 %, UI 11 %, Mira 10 %. Das führte zur letzten großen Änderung (ein Strahlenbild nur im sichtbaren Bereich).

## 2. Umgesetzte Maßnahmen (in der Reihenfolge der Aufgabe)
1. **Messen** – Mess-Overlay/Export (`PerfMonitor`, `?perf=1`), Ablationsschalter, Browser-Harness (`tools/perf/`), Dart-Bench (`test/tools/story_bench_test.dart`).
2. **Statische Hintergründe cachen** – Himmelsgrund, Erweiterungsstreifen (Blur), Bild-Netz in Ruhelage, Tönung und Vignette werden **einmal** in ein Bild in Bildschirmauflösung gebacken (`toImageSync`, mit Picture-Fallback). Je Bild nur noch **ein** opaker Bild-Quad (ohne Blending). Je Art bleibt nur das aktuelle Bild im Speicher.
3. **RepaintBoundaries / kein Neuaufbau** – `StoryScene` baut nicht mehr je Bild neu; vier getrennte Ebenen (statisch · Hintergrundleben · Mira · Konfetti) malen über `repaint:`-Listenables. Fortschrittsleiste aktualisiert sich nur bei sichtbarer Änderung (< 1 px). Home baut sich nicht mehr bei jedem Sekundenwechsel neu auf, sondern nur bei strukturellen Timer-Änderungen (Status, Countdown, Plan-Phase, Dauer); nur Zeitanzeige und Plan-Balken hören auf jeden Tick. Der klassische 12-Hz-Hintergrund läuft über einen Timer statt eines 60-Hz-Tickers und gar nicht mehr in der Story-Szene/im ruhigen Modus.
4. **Keine unnötigen Mesh-Neuberechnungen** – Mira: Einfluss-Gewichte je Vertex einmal vorberechnet, Kleinwinkel-Näherung statt sin/cos je Vertex (Abweichung < 0,6 % der Figurhöhe, Test), 24×24 statt 28×28, nur Zellen mit sichtbaren Pixeln (Maske vorberechnet, kein GPU-Rücklesen), Positionspuffer wiederverwendet. Wind: kleines Netz (19×15) nur im Vordergrund mit vorberechneten Phasen, mit der Hintergrund-Rate (≤ 30 Hz) aktualisiert.
5. **Bildgrößen und Texturspeicher** – Asset-Stufen nach Gerät: Mira 512 px (statt 1093) auf Telefonen, Wiese 900 px breit bei dpr·Breite ≤ 900. Kein Mip-Mapping (`FilterQuality.low`). Bilder laden parallel. Download (Telefon, dpr 3): 691 → 489 KB; dpr 2: 691 → 343 KB.
6. **Adaptive Effekte und Stromsparmodus** – `StoryGovernor` (full · reduced · minimal) mit Raten je Zustand (Mira aktiv 60/30/20 Hz, Ruhe 30/20/12 Hz, Hintergrund 30/15/0 Hz), Partikel 26/12/0, Wind nur auf voller Stufe. Er schaltet nur nach Eingewöhnung und nur bei dauerhaft < 70 % der Zielrate herunter (nicht bei Tab im Hintergrund), höchstens zweimal zurück. **Stromsparmodus** (Eltern-Bereich, neue Einstellung, Standard aus) erzwingt „minimal“; der **ruhige Modus** bleibt statisch (4 Hz). Kein Blur-Filter mehr in Partikeln und Schatten; Sonnenstrahlen = **ein** vorgebackenes Bild nur im sichtbaren Bereich; Glüh-Shader gecacht.
7. **Timer-Genauigkeit, Pause, Animationen erhalten** – Die Engine (Ankerzeiten) ist unverändert; nur die UI-Meldungen sind seltener. Tests: Pause friert die Zeit ein, Fortsetzen/Ende/Neustart, Struktur-Meldung bei Start/Pause/Ende, Fortschritt folgt dem Timer (`test/story_test.dart`, `test/story_perf_test.dart`, bestehende Timer-Tests). Live im Chromium geprüft: Start → Pause (Zeit stand 6 s still) → Weiter → Ende.
8. **Staging + Tests** – siehe §5.

## 3. Ergebnisse (alt → neu)
### Browser, Software-WebGL (relativ), dpr 2, Median aus 3 Läufen
| | fps | p50 Intervall | p95 Intervall | JS-Heap |
|---|---|---|---|---|
| vorher | 6,2 | 150 ms | 200 ms | 39 MB |
| nachher, volle Stufe | 17,8 (×2,9) | 50 ms | 67 ms | 22 MB |
| nachher, adaptiv (Standard) | 23,7 (×3,8) | 50 ms | 67 ms | 22 MB |
| nachher, reduziert / minimal* | 26,2 / 28,8 | 33 ms | 50 ms | 22 MB |

\* Stufen-Läufe stammen aus der Messreihe vor der Struktur-/Ladepfad-Änderung (Build davor); Laufzeit-fps unverändert (Stichprobe nach dem Umbau: 25,9 fps adaptiv).

dpr 1 (wenig Pixel): **22,1 → 58,9 fps** (Vsync-Grenze; p95 16,8 ms, nur 0,6 % der Bilder > 33 ms, vorher 73 %).
dpr 3 (Pixelzahl eines iPhone, aber Software-GPU): 2,5 → 9,2 fps (adaptiv), 4× CPU-Drosselung bei dpr 2: 3,2 → 9,0 fps.

### Dart-Kosten (VM, ohne GPU), Median aus 3 Läufen
| | vorher | nachher | |
|---|---|---|---|
| bereit: ms je App-Sekunde | 202 | 72 | −64 % |
| läuft: ms je App-Sekunde | 147 | 70,5 | −52 % |
| läuft: Mittel je Bild | 2,45 ms | 1,17 ms | −52 % |
| läuft: p95 je Bild | 7,45 ms | 2,81 ms | −62 % |
| läuft: langsamstes Bild | 12,6 ms | 8,0 ms | −36 % |
| Asset-Ladezeit (Decode + Netz) | 87–107 ms | 58–68 ms | −35 % |

Der sekündliche Hänger (Home-Neuaufbau beim Sekundenwechsel) fiel von 15–19 ms auf 6–11 ms; vorher gab es ihn zusätzlich 4× pro Sekunde (250-ms-Takt).

### Ladezeit (Software-WebGL, relativ)
Zeit vom Erscheinen des Home-Screens bis Mira sichtbar: **9,3–10,1 s → 2,8 s** (−72 %). Ursache vorher: Die alte, flache Ersatz-Bühne wurde währenddessen gerendert und bremste die Lade-Kette. Jetzt zeigt die Story-Konfiguration beim Laden nur den Himmelsgrund (kein Aufblitzen der alten Mira); scheitert das Laden, bleibt die alte Bühne dauerhaft aktiv. Einmalig im Betrieb: statischer Bake (Software-WebGL: ≈ 0,4 s; auf einer GPU erwartbar deutlich weniger, **nicht gemessen**), Strahlen-Bake ≈ 60 ms.

### Texturspeicher (Schätzung, RGBA, Telefon 393 pt)
| | vorher | nachher |
|---|---|---|
| dpr 2 | ≈ 15,4 MB (Mira 4,6 + Wiese 6,0, mit Mip-Ketten, + Streifenbild) | **9,5 MB** (Overlay-Wert; Mira 1,0 + Wiese 3,4 + gebackene Statik 5,1) |
| dpr 3 | ≈ 15,4 MB | **≈ 18,7 MB** (Mira 1,0 + Wiese 6,0 + gebackene Statik 11,5) |

Ehrlich: Auf **dpr-3-Telefonen steigt** der Texturspeicher um ≈ 3 MB, weil die gebackene Statik in voller Pixelauflösung vorliegt (sonst wäre sie sichtbar weicher). Dafür entfällt ein Großteil der Pixel-Arbeit je Bild. Auf dpr-2-Geräten sinkt er um ≈ 38 %.

## 4. Bildqualität (keine Verschlechterung)
Ruhiger Modus (deterministisch, ohne Animation), 393×852 @3, Pixelvergleich Alt/Neu: **PSNR 45,9 / 47,1 / 48,7 dB** (bereit / läuft / geschafft), mittlere Abweichung 0,3–0,4 von 255; 0,01–0,03 % der Pixel weichen sichtbar ab (Kanten von Mira durch das 512-px-Asset, Schattenverlauf). Differenzbild (×8 verstärkt) praktisch schwarz: `perf/qualitaet_vergleich.png`. Animierte Zustände unterscheiden sich naturgemäß nur in der Phase.
Bewusste kleine Änderungen: Sonnenstrahlen pulsieren als ein Bild (vorher drei unabhängige Phasen), Wind nur auf der vollen Stufe, Partikel/Schatten ohne Blur-Filter (Kernpunkt + Halo statt Weichzeichner).

## 5. Tests und Staging
* `flutter analyze`: keine Befunde. `flutter test`: **209 Tests grün** (vorher 190; neu u. a.: Netz-Näherung vs exakte Formel, Zellmaske passt zum Asset, Asset-Stufen je Gerät, Qualitätsregler, Wiesen-Netz/Wind, Geometrie, Struktur-Meldung, Stromsparmodus-Einstellung inkl. Laden alter Daten, Lade-/Fehlerverhalten, Timer-Meldungen).
* Staging (ohne Login): https://tinytakt-preview-git-feature-mira-meadow-slice-cschro.vercel.app – Version prüfen: `/build.json` oder App → Eltern → Information → „Version & Build“.
* Nichts nach `main` gemergt.

## 6. Messen auf dem iPhone (bitte ausführen)
Staging-Adresse mit **`?perf=1`** öffnen (Onboarding, dann Start drücken): Overlay oben links zeigt Bilder/s (tatsächlich geliefert), p95, Stufe und Takt, Texturspeicher, Zeit bis Szene, Dart-Kosten je Ebene. Zusätzlich `&tier=full` (60 Hz, alle Effekte), `&tier=reduced`, `&tier=minimal` zum Vergleich der Stufen; ohne `tier` entscheidet der Regler. Ein Screenshot des Overlays reicht als Messwert.

## 7. Bekannt / offen
* Echter iPhone-Safari-/GPU-Test steht aus (siehe §0). Der Regler schaltet nur herunter, wenn die gelieferte Rate dauerhaft unter 70 % der Zielrate liegt; auf einem schnellen iPhone bleibt es auf „full“.
* Die klassischen Timer-Stile (`TimerStage`) haben weiterhin einen eigenen Vsync-Ticker und Material-Schatten; nur die Story-Szene wurde optimiert.
* Material-Elevation-Schatten der Bedienelemente kosten im Software-Raster ≈ 11 %; nicht verändert (Optik der Buttons).
* Texturspeicher auf dpr-3-Geräten ≈ +3 MB (siehe §3).
