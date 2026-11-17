import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../art_kit.dart';
import '../rig.dart';

/// Eine handgebaute Premium-Figur mit eigenem Körperbau (kein gemeinsamer Grundkörper).
abstract class PremiumFigure {
  const PremiumFigure();

  /// Eindeutige ID (entspricht der Katalog-ID).
  String get id;
  Personality get personality;

  /// Zeichnet die Figur im Einheitsquadrat [-1,1] mit der gegebenen Pose.
  void paint(Canvas c, Pose pose, double t);

  /// Weicher Bodenschatten – folgt dem Hüpfen (je höher, desto kleiner/blasser).
  void groundShadow(
    Canvas c,
    Pose pose, {
    double width = 1.0,
    double y = 0.96,
  }) {
    final lift = (-pose.bodyDy).clamp(0.0, 0.3);
    final w = width * (1 - lift * 1.2);
    c.drawOval(
      Rect.fromCenter(center: Offset(0, y), width: w, height: 0.13),
      Paint()
        ..color = Color.fromRGBO(30, 40, 70, 0.30 - lift * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.04),
    );
  }

  /// Funkeln bei Freude (dezent, nur kurz sichtbar).
  void sparkles(
    Canvas c,
    Pose pose,
    double t, {
    Color color = const Color(0xFFFFE27A),
    double radius = 0.95,
  }) {
    if (pose.sparkle < 0.02) return;
    for (var i = 0; i < 7; i++) {
      final a = i * 2 * math.pi / 7 + t * 1.2;
      final r = radius * (0.92 + 0.08 * math.sin(t * 4 + i));
      final p = Offset(math.cos(a) * r, math.sin(a) * r * 0.85 - 0.1);
      final s = (0.045 + 0.03 * math.sin(t * 6 + i * 1.7).abs()) * pose.sparkle;
      final path = Path();
      for (var k = 0; k < 8; k++) {
        final rad = k.isEven ? s : s * 0.3;
        final ang = k * math.pi / 4 - math.pi / 2;
        final pt = p + Offset(math.cos(ang) * rad, math.sin(ang) * rad);
        k == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      c.drawPath(
        path,
        Paint()..color = color.withValues(alpha: 0.9 * pose.sparkle),
      );
      glow(c, p, s * 3, color, 0.3 * pose.sparkle);
    }
  }

  /// Gruppe mit Pivot transformieren.
  void group(
    Canvas c,
    Offset pivot, {
    double rot = 0,
    double sx = 1,
    double sy = 1,
    Offset move = Offset.zero,
    required void Function() draw,
  }) {
    c.save();
    c.translate(pivot.dx + move.dx, pivot.dy + move.dy);
    if (rot != 0) c.rotate(rot);
    if (sx != 1 || sy != 1) c.scale(sx, sy);
    c.translate(-pivot.dx, -pivot.dy);
    draw();
    c.restore();
  }
}
