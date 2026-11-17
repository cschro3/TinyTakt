
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/painters/picture_painters.dart';

import 'screenshot_support.dart';

/// Rendert ein Bild-Timer-Motiv in mehreren Fortschrittsstufen (Zeile): PICTURE_STYLE (Standard iceCream).
void main() {
  testWidgets('Bild-Timer Stufen', (t) async {
    const name = String.fromEnvironment(
      'PICTURE_STYLE',
      defaultValue: 'iceCream',
    );
    final style = TimerStyle.values.firstWhere((s) => s.name == name);
    final key = GlobalKey();
    t.view.physicalSize = const Size(1400, 300);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    const fr = [1.0, 0.85, 0.6, 0.4, 0.2, 0.0];
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: Container(
            color: const Color(0xFFBFE6F8),
            width: 220.0 * 6,
            height: 220,
            child: Row(
              children: [
                for (final f in fr)
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CustomPaint(
                      painter: PicturePainter(
                        style: style,
                        fraction: f,
                        t: 0.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await savePng(t, key, 'build/sheets/pic_$name.png', pixelRatio: 1.5);
  });
}
