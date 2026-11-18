# Leistungsmessung

Siehe `docs/PERFORMANCE.md` für Methode, Ergebnisse und Grenzen.

* `measure.js` – Headless-Chromium (Software-WebGL), Bildintervalle, JS-Heap, Ladezeiten, optional CPU-Drosselung.
  **Relativer Vergleich, kein Ersatz für einen echten iPhone-Safari-Test.**
* `flutter test test/tools/story_bench_test.dart --dart-define=BENCH_LABEL=name` – Dart-seitige Kosten
  (Build, Layout, Paint-Aufzeichnung, Compositing) je simulierter App-Sekunde → `build/perf/bench_name.json`.
* `--dart-define=PERF_OFF=rays,fx,vignette,ext,mira,wind,particles` – Ablation einzelner Szenenteile.
* Auf dem Gerät: Staging-Adresse mit `?perf=1` öffnen → Overlay mit Bildrate, p95, Stufe, Texturspeicher,
  Dart-Kosten; Werte stehen auch in `window.__ttPerf`.
