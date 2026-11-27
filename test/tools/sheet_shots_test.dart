import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/art/story/art_images.dart';
import 'package:tinytakt/presentation/screens/picker_screen.dart';
import 'package:tinytakt/presentation/widgets/character_sheet.dart';

import '../helpers.dart';
import 'screenshot_support.dart';

/// Screenshots der Galerie und der Charakterkarte → build/sheet/*.png
void main() {
  testWidgets('Charakterkarte', (t) async {
    await t.runAsync(loadFonts);
    await t.runAsync(
      () => ArtImages.instance.ensureLoaded(cssWidth: 393, dpr: 3),
    );
    for (final shot in const [
      ('nova_mira', 'meadow'),
      ('dog', 'space'),
      ('owl', 'forest'),
      ('trex', 'underwater'),
    ]) {
      setScreen(t, const Size(393, 852), dpr: 3);
      final env = TestEnv(pro: true);
      await t.runAsync(env.init);
      await env.settings.updateProfile(
        (p) => p.copyWith(backgroundId: shot.$2),
      );
      final key = GlobalKey();
      final spec = characters.firstWhere((c) => c.id == shot.$1);
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: wrap(
            env.deps,
            Scaffold(
              body: Builder(
                builder: (c) => TextButton(
                  onPressed: () => showCharacterSheet(c, spec),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      for (var i = 0; i < 40; i++) {
        await t.pump(const Duration(milliseconds: 66));
      }
      await savePng(
        t,
        key,
        'build/sheet/${shot.$1}_${shot.$2}.png',
        pixelRatio: 3,
      );
      await t.pumpWidget(const SizedBox());
      env.timer.dispose();
    }
  });

  testWidgets('Galerie mit Favoriten', (t) async {
    await t.runAsync(loadFonts);
    await t.runAsync(
      () => ArtImages.instance.ensureLoaded(cssWidth: 393, dpr: 3),
    );
    setScreen(t, const Size(393, 852), dpr: 3);
    final env = TestEnv(pro: true);
    await t.runAsync(env.init);
    await env.settings.toggleFavorite('nova_mira');
    await env.settings.toggleFavorite('dog');
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(key: key, child: wrap(env.deps, const PickerScreen())),
    );
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    await savePng(t, key, 'build/sheet/gallery.png', pixelRatio: 3);
    await t.pumpWidget(const SizedBox());
    env.timer.dispose();
  });
}
