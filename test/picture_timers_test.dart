import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/painters/picture_painters.dart';

void main() {
  const picture = [
    TimerStyle.iceCream,
    TimerStyle.candle,
    TimerStyle.plant,
    TimerStyle.pizza,
    TimerStyle.puzzle,
  ];

  test('Alle Bild-Timer sind Pro und haben Namen in beiden Sprachen', () {
    for (final s in picture) {
      expect(s.pro, isTrue);
      expect(s.de, isNotEmpty);
      expect(s.en, isNotEmpty);
    }
    expect(
      TimerStyle.values.where((s) => !s.pro).length,
      3,
      reason: 'drei freie Darstellungen bleiben',
    );
  });

  test('Bild-Timer zeichnen bei jedem Restanteil ohne Fehler (auch außerhalb 0..1)', () {
    for (final s in picture) {
      for (final f in [-0.2, 0.0, 0.01, 0.33, 0.5, 0.99, 1.0, 1.4]) {
        for (final calm in [false, true]) {
          PicturePainter(
            style: s,
            fraction: f,
            t: 1.3,
            calm: calm,
          ).paint(Canvas(PictureRecorder()), const Size(240, 240));
        }
      }
    }
  });

  test('shouldRepaint reagiert auf Restanteil und Stil', () {
    final a = PicturePainter(style: TimerStyle.pizza, fraction: 0.5, t: 0);
    expect(
      a.shouldRepaint(
        PicturePainter(style: TimerStyle.pizza, fraction: 0.4, t: 0),
      ),
      isTrue,
    );
    expect(
      a.shouldRepaint(
        PicturePainter(style: TimerStyle.candle, fraction: 0.5, t: 0),
      ),
      isTrue,
    );
    expect(
      a.shouldRepaint(
        PicturePainter(style: TimerStyle.pizza, fraction: 0.5, t: 0),
      ),
      isFalse,
    );
  });
}
