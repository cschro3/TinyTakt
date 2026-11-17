import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/presentation/art/figures/registry.dart';
import 'package:tinytakt/presentation/art/rig.dart';
import 'package:tinytakt/presentation/art/timers/adventure.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/art/worlds/registry.dart';

/// Misst die reine Aufzeichnungszeit (Dart-Seite) pro Bild: Welt + Figur + Timer-Diorama.
/// Kein GPU-Rastern – ein Richtwert für den Dart-Anteil, kein Ersatz für Geräte-Profiling.
void main() {
  test('Aufzeichnungszeit pro Bild', () {
    const size = Size(390, 844);
    const frames = 300;
    final lines = <String>[];
    double worstWorld = 0;
    for (final w in premiumWorlds.values) {
      w.paint(Canvas(ui.PictureRecorder()), size, 0, false); // Cache wärmen
      final sw = Stopwatch()..start();
      for (var i = 0; i < frames; i++) {
        final rec = ui.PictureRecorder();
        w.paint(Canvas(rec), size, i / 60, false);
        rec.endRecording();
      }
      final ms = sw.elapsedMicroseconds / 1000 / frames;
      worstWorld = ms > worstWorld ? ms : worstWorld;
      lines.add('Welt ${w.id}: ${ms.toStringAsFixed(3)} ms/Bild');
    }
    double worstFig = 0;
    for (final f in premiumFigures.values) {
      final sw = Stopwatch()..start();
      for (var i = 0; i < frames; i++) {
        final rec = ui.PictureRecorder();
        final c = Canvas(rec);
        c.scale(150);
        f.paint(
          c,
          computePose(f.personality, Emotion.celebrate, i / 60, i / 60),
          i / 60,
        );
        rec.endRecording();
      }
      final ms = sw.elapsedMicroseconds / 1000 / frames;
      worstFig = ms > worstFig ? ms : worstFig;
      lines.add('Figur ${f.id}: ${ms.toStringAsFixed(3)} ms/Bild');
    }
    final sw = Stopwatch()..start();
    for (var i = 0; i < frames; i++) {
      final rec = ui.PictureRecorder();
      AdventurePainter(
        fraction: 0.5,
        t: i / 60,
        calm: false,
        theme: AdventureTheme.forScenery(Scenery.meadow),
      ).paint(Canvas(rec), const Size(360, 360));
      rec.endRecording();
    }
    final adv = sw.elapsedMicroseconds / 1000 / frames;
    lines.add('Abenteuer-Diorama: ${adv.toStringAsFixed(3)} ms/Bild');
    // ignore: avoid_print
    print(lines.join('\n'));
    // Budget: Dart-Anteil deutlich unter einem 16,7-ms-Bild
    expect(worstWorld + worstFig + adv, lessThan(8.0));
  });
}
