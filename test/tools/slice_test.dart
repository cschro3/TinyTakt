import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/screens/home_screen.dart';

import '../helpers.dart';
import 'screenshot_support.dart';

/// Vorzeige-Beispiel: NOVA-Figur + Blumenwiese + Abenteuer-Timer + Abschluss.
/// Umgebungsvariablen: SLICE_CHAR (Standard nova_lumi), SLICE_WORLD (meadow), SLICE_STYLE (adventure).
void main() {
  testWidgets('Vorzeige-Beispiel', (t) async {
    await t.runAsync(loadFonts);
    const size = Size(390, 844);
    setScreen(t, size, dpr: 2.0);
    final env = TestEnv(pro: true);
    await t.runAsync(env.init);
    final charId = const String.fromEnvironment(
      'SLICE_CHAR',
      defaultValue: 'nova_lumi',
    );
    final world = const String.fromEnvironment(
      'SLICE_WORLD',
      defaultValue: 'meadow',
    );
    final style = TimerStyle.values.firstWhere(
      (s) =>
          s.name ==
          const String.fromEnvironment(
            'SLICE_STYLE',
            defaultValue: 'adventure',
          ),
    );
    await env.settings.updateProfile(
      (p) => p.copyWith(characterId: charId, backgroundId: world, style: style),
    );
    await env.timer.setDuration(const Duration(minutes: 10));
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(key: key, child: wrap(env.deps, const HomeScreen())),
    );
    Future<void> run(double seconds) async {
      for (var i = 0; i < (seconds * 10).round(); i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    await run(1.4);
    await savePng(t, key, 'build/slice/1_idle.png', pixelRatio: 2);
    await env.timer.start();
    await run(0.6);
    await savePng(t, key, 'build/slice/2_cheer.png', pixelRatio: 2);
    env.clock.advance(const Duration(minutes: 4));
    await run(3.2);
    await savePng(t, key, 'build/slice/3_running40.png', pixelRatio: 2);
    env.clock.advance(const Duration(minutes: 5, seconds: 20));
    await run(1.2);
    await savePng(t, key, 'build/slice/4_near_goal.png', pixelRatio: 2);
    env.clock.advance(const Duration(seconds: 40));
    await run(1.0);
    await savePng(t, key, 'build/slice/5_finish.png', pixelRatio: 2);
    await env.timer.stop();
    await t.pumpWidget(const SizedBox());
    env.timer.dispose();
  });
}
