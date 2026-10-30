import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/painters/picture_painters.dart';

/// Alle Bild-Timer bei 100 %, 66 %, 33 %, 5 %, 0 % Restzeit (Sichtprüfung + Fehlerfreiheit).
void main() {
  test('Bild-Timer rendern', () async {
    final styles = [
      TimerStyle.iceCream,
      TimerStyle.candle,
      TimerStyle.plant,
      TimerStyle.pizza,
      TimerStyle.puzzle,
    ];
    const fr = [1.0, 0.66, 0.33, 0.05, 0.0];
    const cell = 220.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(
      Rect.fromLTWH(0, 0, cell * fr.length, cell * styles.length),
      Paint()..color = const Color(0xFFCDEBFF),
    );
    for (var r = 0; r < styles.length; r++) {
      for (var k = 0; k < fr.length; k++) {
        c.save();
        c.translate(k * cell, r * cell);
        PicturePainter(
          style: styles[r],
          fraction: fr[k],
          t: 0.7,
        ).paint(c, const Size(cell, cell));
        c.restore();
      }
    }
    final img = await rec.endRecording().toImage(
      (cell * fr.length).toInt(),
      (cell * styles.length).toInt(),
    );
    File('build/sheets/pictures.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(
        (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
  });
}
