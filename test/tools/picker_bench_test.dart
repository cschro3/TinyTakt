import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/presentation/screens/picker_screen.dart';

import '../helpers.dart';

/// Dart-seitige Kosten des Auswahlmenüs (Build + Layout + Paint-Aufzeichnung, **ohne GPU**):
/// Öffnen, Scrollen, Tab-Wechsel, Antippen. Ausgabe: `build/perf/picker_LABEL.json` (LABEL aus PICKER_LABEL).
/// Nur auf derselben Maschine vergleichbar.
void main() {
  testWidgets('Auswahlmenü: Dart-Kosten', (t) async {
    const label = String.fromEnvironment('PICKER_LABEL', defaultValue: 'lokal');
    setScreen(t, const Size(393, 852), dpr: 3);
    final env = TestEnv(pro: true);
    await t.runAsync(env.init);
    final res = <String, Object>{};
    Future<double> timed(Future<void> Function() f) async {
      final sw = Stopwatch()..start();
      await f();
      return sw.elapsedMicroseconds / 1000;
    }

    Future<void> frames(int n) async {
      for (var i = 0; i < n; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
    }

    // 1) Öffnen (erster Aufbau + erste Bilder)
    res['oeffnen_ms'] = await timed(() async {
      await t.pumpWidget(wrap(env.deps, const PickerScreen()));
      await frames(8);
    });
    // 2) Scrollen: viele Bilder, jeweils pump je Frame
    final scrollFrames = <double>[];
    final list = find.byType(Scrollable).first;
    for (var k = 0; k < 4; k++) {
      final g = await t.startGesture(const Offset(196, 500));
      for (var i = 0; i < 12; i++) {
        await g.moveBy(const Offset(0, -45));
        scrollFrames.add(
          await timed(() => t.pump(const Duration(milliseconds: 16))),
        );
      }
      await g.up();
      for (var i = 0; i < 20; i++) {
        scrollFrames.add(
          await timed(() => t.pump(const Duration(milliseconds: 16))),
        );
      }
    }
    scrollFrames.sort();
    double q(List<double> l, double p) => l[((l.length - 1) * p).round()];
    res['scroll_mean_ms'] = double.parse(
      (scrollFrames.reduce((a, b) => a + b) / scrollFrames.length)
          .toStringAsFixed(2),
    );
    res['scroll_p95_ms'] = double.parse(
      q(scrollFrames, .95).toStringAsFixed(2),
    );
    res['scroll_max_ms'] = double.parse(scrollFrames.last.toStringAsFixed(2));
    await t.fling(list, const Offset(0, 3000), 3000);
    await frames(30);

    // 3) Tab-Wechsel (antippen, 400 ms Übergang)
    final tabNames = [
      'Welt',
      'Zeit',
      'Musik',
      'Figur',
      'Welt',
      'Figur',
      'Zeit',
      'Figur',
    ];
    final tabCosts = <double>[];
    for (final n in tabNames) {
      tabCosts.add(
        await timed(() async {
          await t.tap(find.widgetWithText(Tab, n));
          for (var i = 0; i < 30; i++) {
            await t.pump(const Duration(milliseconds: 16));
          }
        }),
      );
    }
    res['tabs_gesamt_ms_je_wechsel'] = double.parse(
      (tabCosts.reduce((a, b) => a + b) / tabCosts.length).toStringAsFixed(1),
    );
    res['tabs_einzeln_ms'] = tabCosts
        .map((e) => double.parse(e.toStringAsFixed(1)))
        .toList();
    // 4) Kachel antippen (Auswahl wechselt, Menü baut neu)
    res['antippen_ms'] = await timed(() async {
      await t.tap(find.text('Katze Mimi'));
      await frames(14);
    });
    // 5) Rest-Frames im Leerlauf
    res['leerlauf_ms_je_frame'] = double.parse(
      ((await timed(() => frames(60))) / 60).toStringAsFixed(3),
    );
    // ignore: avoid_print
    print('PICKER $label ${jsonEncode(res)}');
    File('build/perf/picker_$label.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(res));
    await t.pumpWidget(const SizedBox());
    env.timer.dispose();
  });
}
