import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/screens/home_screen.dart';
import 'package:tinytakt/presentation/screens/parent_screen.dart';
import 'package:tinytakt/presentation/screens/picker_screen.dart';
import 'package:tinytakt/presentation/screens/pro_screen.dart';

import '../helpers.dart';
import 'screenshot_support.dart';

/// Rendert Store-Screenshots aus der echten UI (flutter test, kein Gerät).
/// Ausgabe: build/shots/LOCALE/DEVICE/NAME.png
void main() {
  final devices = {
    'iphone_6_9': (const Size(440, 956), 3.0),
    'ipad_13': (const Size(1032, 1376), 2.0),
    'android_phone': (const Size(360, 640), 3.0),
  };
  for (final d in devices.entries) {
    testWidgets('Screenshots ${d.key}', (t) async {
      await t.runAsync(loadFonts);
      Future<void> shot(
        String name,
        Widget home, {
        bool pro = false,
        Future<void> Function(TestEnv)? prep,
        String loc = 'de',
      }) async {
        setScreen(t, d.value.$1, dpr: d.value.$2);
        final env = TestEnv(pro: pro);
        await t.runAsync(env.init);
        await t.runAsync(env.purchases.init);
        if (prep != null) await prep(env);
        final key = GlobalKey();
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: wrap(env.deps, home, locale: Locale(loc)),
          ),
        );
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 150));
        }
        await savePng(
          t,
          key,
          'build/shots/$loc/${d.key}/$name.png',
          pixelRatio: d.value.$2,
        );
        await env.timer.stop();
        await t.pumpWidget(const SizedBox());
      }

      for (final loc in ['de', 'en']) {
        await shot('1_timer', const HomeScreen(), loc: loc);
        await shot(
          '2_adventure',
          const HomeScreen(),
          loc: loc,
          pro: true,
          prep: (e) async {
            await e.settings.updateProfile(
              (p) => p.copyWith(
                characterId: 'lion',
                style: TimerStyle.adventure,
                backgroundId: 'forest',
              ),
            );
            await e.timer.setDuration(const Duration(minutes: 10));
            await e.timer.start();
            e.clock.advance(const Duration(minutes: 4));
          },
        );
        await shot(
          '3_fill',
          const HomeScreen(),
          loc: loc,
          pro: true,
          prep: (e) async {
            await e.settings.updateProfile(
              (p) => p.copyWith(
                characterId: 'whale',
                style: TimerStyle.fill,
                backgroundId: 'underwater',
              ),
            );
            await e.timer.setDuration(const Duration(minutes: 5));
            await e.timer.start();
            e.clock.advance(const Duration(minutes: 2));
          },
        );
        await shot(
          '4_space',
          const HomeScreen(),
          loc: loc,
          pro: true,
          prep: (e) async {
            await e.settings.updateProfile(
              (p) => p.copyWith(
                characterId: 'rocket',
                style: TimerStyle.rainbow,
                backgroundId: 'night',
              ),
            );
            await e.timer.setDuration(const Duration(minutes: 15));
            await e.timer.start();
            e.clock.advance(const Duration(minutes: 5));
          },
        );
        await shot('5_characters', const PickerScreen(), loc: loc);
        await shot('6_parents', const ParentScreen(), loc: loc);
        await shot('7_pro', const ProScreen(), loc: loc);
      }
    });
  }
}
