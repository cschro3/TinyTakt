import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/presentation/art/story/art_images.dart';
import 'package:tinytakt/presentation/screens/picker_screen.dart';

import '../helpers.dart';
import 'screenshot_support.dart';

/// Rendert alle vier Tabs des Auswahlmenüs (Free mit Schlössern, Pro) für Bildvergleiche.
/// Ausgabe: `build/picker/OUT/pro_oder_free_TAB[_scroll].png` (OUT aus PICKER_OUT).
void main() {
  testWidgets('Auswahlmenü: Bilder', (t) async {
    const out = String.fromEnvironment('PICKER_OUT', defaultValue: 'lokal');
    await t.runAsync(loadFonts);
    await t.runAsync(
      () => ArtImages.instance.ensureLoaded(cssWidth: 393, dpr: 3),
    );
    for (final pro in [false, true]) {
      setScreen(t, const Size(393, 852), dpr: 3);
      final env = TestEnv(pro: pro);
      await t.runAsync(env.init);
      final key = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(key: key, child: wrap(env.deps, const PickerScreen())),
      );
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      final names = ['Figur', 'Welt', 'Zeit', 'Musik'];
      for (final n in names) {
        await t.tap(find.widgetWithText(Tab, n));
        for (var i = 0; i < 40; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        final p = '${pro ? 'pro' : 'free'}_$n';
        await savePng(t, key, 'build/picker/$out/$p.png', pixelRatio: 3);
        if (n == 'Figur') {
          await t.drag(find.byType(Scrollable).first, const Offset(0, -1500));
          for (var i = 0; i < 40; i++) {
            await t.pump(const Duration(milliseconds: 16));
          }
          await savePng(
            t,
            key,
            'build/picker/$out/${p}_scroll.png',
            pixelRatio: 3,
          );
          await t.drag(find.byType(Scrollable).first, const Offset(0, 1500));
          for (var i = 0; i < 40; i++) {
            await t.pump(const Duration(milliseconds: 16));
          }
        }
      }
      await t.pumpWidget(const SizedBox());
      env.timer.dispose();
    }
  });
}
