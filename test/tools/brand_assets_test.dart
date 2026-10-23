import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/presentation/painters/hero_painter.dart';

Future<void> _png(String path, int px, void Function(Canvas, Size) draw) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  draw(c, Size(px.toDouble(), px.toDouble()));
  final img = await rec.endRecording().toImage(px, px);
  final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!;
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes.buffer.asUint8List());
}

/// Erzeugt Marken-Quellbilder (Icon, Adaptive-Vordergrund, Splash-Figur) aus dem Code des Helden.
void main() {
  test('Markenbilder erzeugen', () async {
    await _png('assets/brand/icon_1024.png', 1024, (c, s) {
      HeroPainter(
        t: 0.3,
        withBackground: true,
        waving: false,
        scale: 0.78,
      ).paint(c, s);
    });
    // Adaptive-Icon-Vordergrund: Figur auf 62 % verkleinert (Safe-Zone), transparent
    await _png('assets/brand/icon_foreground.png', 1024, (c, s) {
      c.translate(s.width * 0.19, s.height * 0.19);
      HeroPainter(
        t: 0.3,
        waving: false,
        scale: 0.95,
      ).paint(c, Size(s.width * 0.62, s.height * 0.62));
    });
    await _png('assets/brand/splash_hero.png', 768, (c, s) {
      HeroPainter(t: 0.3, waving: false).paint(c, s);
    });
    expect(File('assets/brand/icon_1024.png').existsSync(), isTrue);
  });
}
