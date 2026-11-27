import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/art/adventure/adventure_gear.dart';
import 'package:tinytakt/presentation/art/story/art_images.dart';
import 'package:tinytakt/presentation/art/visual/character_visual_painter.dart';

import '../helpers.dart';
import 'screenshot_support.dart';

/// Kontaktbogen: Ausrüstung je Welt auf verschiedenen Figuren → build/gear/sheet.png
void main() {
  testWidgets('Ausrüstungs-Kontaktbogen', (t) async {
    await t.runAsync(loadFonts);
    await t.runAsync(
      () => ArtImages.instance.ensureLoaded(cssWidth: 393, dpr: 3),
    );
    const ids = [
      'dog',
      'bunny',
      'cat',
      'bear',
      'lion',
      'penguin',
      'trex',
      'dragon',
      'robot',
      'owl',
      'nova_mira',
      'nova_lumi',
      'turtle',
      'frog',
    ];
    final worlds = adventureGear.keys.toList();
    setScreen(t, const Size(14 * 90.0, 9 * 110.0), dpr: 1);
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            color: const Color(0xFFE8ECF8),
            child: Column(
              children: [
                for (final w in worlds)
                  SizedBox(
                    height: 110,
                    child: Row(
                      children: [
                        for (final id in ids)
                          SizedBox(
                            width: 90,
                            height: 110,
                            child: CustomPaint(
                              painter: CharacterVisualPainter(
                                characters.firstWhere((c) => c.id == id),
                                gearWorld: w,
                                shadow: false,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 200));
    await savePng(t, key, 'build/gear/sheet.png', pixelRatio: 2);
  });
}
