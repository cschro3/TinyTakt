import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/art/story/art_images.dart';
import 'package:tinytakt/presentation/screens/home_screen.dart';

import '../helpers.dart';

/// Dart-seitige Frame-Kosten der Story-Szene (Build + Layout + Paint-Aufzeichnung + Compositing,
/// **ohne** GPU-Rasterung): Wandzeit je simulierter App-Sekunde bei 60-Hz-Takt.
/// Ausgabe: `build/perf/bench_LABEL.json` (LABEL aus BENCH_LABEL). Vergleichswerte nur auf derselben Maschine gültig.
void main() {
  testWidgets('Story-Szene: Dart-Kosten', (t) async {
    const label = String.fromEnvironment('BENCH_LABEL', defaultValue: 'lokal');
    setScreen(t, const Size(393, 852), dpr: 3);
    final loadSw = Stopwatch()..start();
    await t.runAsync(
      () => ArtImages.instance.ensureLoaded(cssWidth: 393, dpr: 3),
    );
    loadSw.stop();
    final env = TestEnv(pro: true);
    await t.runAsync(env.init);
    await env.settings.updateProfile(
      (p) => p.copyWith(
        characterId: 'nova_mira',
        backgroundId: 'meadow',
        style: TimerStyle.adventure,
      ),
    );
    await env.timer.setDuration(const Duration(minutes: 5));
    await t.pumpWidget(wrap(env.deps, const HomeScreen()));
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }

    Future<Map<String, num>> run(String name, int frames) async {
      final times = <double>[];
      final total = Stopwatch()..start();
      for (var i = 0; i < frames; i++) {
        final sw = Stopwatch()..start();
        await t.pump(const Duration(microseconds: 16667));
        times.add(sw.elapsedMicroseconds / 1000);
        // Timer-Takt: alle 250 ms (wie im Betrieb)
        if (i % 15 == 0) env.clock.advance(const Duration(milliseconds: 250));
      }
      total.stop();
      final slow = [for (var i = 0; i < times.length; i++) (i, times[i])]
        ..sort((a, b) => b.$2.compareTo(a.$2));
      // ignore: avoid_print
      print(
        'BENCH $label/$name langsamste Bilder (Index, ms): ${slow.take(4).map((e) => '${e.$1}:${e.$2.toStringAsFixed(1)}').join(', ')}',
      );
      times.sort();
      double q(double p) => times[(p * (times.length - 1)).round()];
      final secs = frames / 60;
      final r = {
        'msPerAppSecond': double.parse(
          (total.elapsedMilliseconds / secs).toStringAsFixed(1),
        ),
        'meanMsPerFrame': double.parse(
          (times.reduce((a, b) => a + b) / times.length).toStringAsFixed(2),
        ),
        'p95MsPerFrame': double.parse(q(0.95).toStringAsFixed(2)),
        'maxMsPerFrame': double.parse(times.last.toStringAsFixed(2)),
      };
      // ignore: avoid_print
      print('BENCH $label/$name $r');
      return r;
    }

    final idle = await run('bereit', 240);
    await env.timer.start();
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    final running = await run('laeuft', 360);
    final out = {
      'label': label,
      'assetLadezeitMs': loadSw.elapsedMilliseconds,
      'bereit': idle,
      'laeuft': running,
    };
    Directory('build/perf').createSync(recursive: true);
    File('build/perf/bench_$label.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
    await env.timer.stop();
    await t.pumpWidget(const SizedBox());
    env.timer.dispose();
  });
}
