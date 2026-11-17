import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/art/rig.dart';
import 'package:tinytakt/presentation/painters/character_painter.dart';

/// Rendert Premium-Figuren groß in allen Gefühlen (Sichtprüfung der Gestaltung).
/// Umgebungsvariable PREMIUM_IDS (Komma-getrennt) wählt die Figuren, Standard: nova_lumi.
void main() {
  test('Premium-Figuren: Gefühle', () async {
    final ids = (Platform.environment['PREMIUM_IDS'] ?? 'nova_lumi').split(',');
    final states = <(String, Emotion, double, double)>[
      ('ruhig', Emotion.calm, 1.2, 0),
      ('begrüßt', Emotion.greet, 3.0, 0.5),
      ('Start-Freude', Emotion.cheer, 3.0, 0.3),
      ('ermutigt', Emotion.encourage, 3.0, 0.6),
      ('jubelt', Emotion.celebrate, 3.0, 0.5),
      ('müde', Emotion.sleepy, 3.0, 0),
    ];
    const cell = 420.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final w = cell * states.length, h = cell * ids.length;
    c.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), const [
          Color(0xFFBFE6FF),
          Color(0xFFCFF0B8),
        ]),
    );
    for (var r = 0; r < ids.length; r++) {
      for (var k = 0; k < states.length; k++) {
        c.save();
        c.translate(k * cell, r * cell);
        c.clipRect(const Rect.fromLTWH(0, 0, cell, cell));
        final st = states[k];
        CharacterPainter(
          characterById(ids[r]),
          t: st.$3,
          emotion: st.$2,
          emotionT: st.$4,
        ).paint(c, const Size(cell, cell));
        c.restore();
      }
    }
    final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
    File('build/sheets/premium.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(
        (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
  });
}
