import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/presentation/screens/picker_screen.dart';
import 'package:tinytakt/presentation/widgets/preview_cache.dart';

import '../helpers.dart';

/// Bildspeicher des Menü-Caches (RGBA) nach vollständigem Vorwärmen, je Pixeldichte.
void main() {
  for (final dpr in [2.0, 3.0]) {
    testWidgets('Menü-Cache nach Vorwärmen bei dpr $dpr', (t) async {
      PreviewCache.instance.clear();
      setScreen(t, const Size(393, 852), dpr: dpr);
      final env = TestEnv(pro: true);
      await t.runAsync(env.init);
      await t.pumpWidget(wrap(env.deps, const PickerScreen()));
      await t.pump(const Duration(milliseconds: 800));
      var quiet = 0;
      for (var i = 0; i < 800 && quiet < 10; i++) {
        await t.pump(const Duration(milliseconds: 16));
        quiet = PreviewCache.instance.pending.value == 0 ? quiet + 1 : 0;
      }
      // ignore: avoid_print
      print(
        'MEM dpr=$dpr einträge=${PreviewCache.instance.length} MB=${PreviewCache.instance.megabytes.toStringAsFixed(1)}',
      );
      await t.pumpWidget(const SizedBox());
      // ignore: avoid_print
      print(
        'MEM dpr=$dpr nach Schließen MB=${PreviewCache.instance.megabytes.toStringAsFixed(1)} einträge=${PreviewCache.instance.length}',
      );
      env.timer.dispose();
    });
  }
}
