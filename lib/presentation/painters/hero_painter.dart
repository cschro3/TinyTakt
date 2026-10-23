import 'dart:math' as math;

import 'package:flutter/material.dart';

/// „Takti“ – der kleine Zeitheld der App (eigene Figur, auch Basis des App-Icons).
class HeroPainter extends CustomPainter {
  HeroPainter({
    this.t = 0,
    this.withBackground = false,
    this.waving = true,
    this.scale = 0.9,
  });
  final double t;
  final bool withBackground;
  final bool waving;
  final double scale;

  static const body = Color(0xFF2FC4A8);
  static const bodyDark = Color(0xFF1FA48B);
  static const ring = Color(0xFFFFC83D);
  static const ink = Color(0xFF2B2440);

  @override
  void paint(Canvas canvas, Size size) {
    if (withBackground) {
      final r = Offset.zero & size;
      canvas.drawRect(
        r,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5B4FC9), Color(0xFF3B2F7F)],
          ).createShader(r),
      );
    }
    final s = size.shortestSide / 2;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(s * scale);
    canvas.translate(0, 0.04);
    final bob = math.sin(t * 2) * 0.02;
    canvas.translate(0, bob);

    Paint f(Color c) => Paint()..color = c;
    // Schatten
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0.88), width: 1.1, height: 0.12),
      f(const Color(0x33000000)),
    );
    // Antennen
    for (final sx in [-1.0, 1.0]) {
      final sw = math.sin(t * 3 + sx) * 0.03;
      canvas.drawLine(
        Offset(sx * 0.22, -0.62),
        Offset(sx * 0.34 + sw, -0.92),
        Paint()
          ..color = bodyDark
          ..strokeWidth = 0.05
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(Offset(sx * 0.34 + sw, -0.95), 0.085, f(ring));
    }
    // Füße
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-0.25, 0.8),
        width: 0.34,
        height: 0.17,
      ),
      f(bodyDark),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0.25, 0.8),
        width: 0.34,
        height: 0.17,
      ),
      f(bodyDark),
    );
    // Arme
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-0.78, 0.2),
        width: 0.22,
        height: 0.4,
      ),
      f(bodyDark),
    );
    canvas.save();
    canvas.translate(0.74, 0.0);
    canvas.rotate(waving ? -0.5 + math.sin(t * 5) * 0.25 : -0.2);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0.15), width: 0.22, height: 0.42),
      f(bodyDark),
    );
    canvas.restore();
    // Körper
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0.1), width: 1.5, height: 1.45),
      f(body),
    );
    // Uhr-Bauch
    const c = Offset(0, 0.47);
    canvas.drawCircle(c, 0.34, f(Colors.white));
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: 0.275),
      -math.pi / 2,
      math.pi * 1.5,
      false,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.09
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      c,
      c + const Offset(0, -0.17),
      Paint()
        ..color = ink
        ..strokeWidth = 0.04
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      c,
      c + const Offset(0.1, 0.025),
      Paint()
        ..color = ink
        ..strokeWidth = 0.04
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, 0.035, f(ink));
    // Gesicht
    for (final sx in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(sx * 0.26, -0.22),
          width: 0.2,
          height: 0.25,
        ),
        f(Colors.white),
      );
      canvas.drawCircle(Offset(sx * 0.26 + 0.02, -0.21), 0.075, f(ink));
      canvas.drawCircle(
        Offset(sx * 0.26 + 0.05, -0.25),
        0.026,
        f(Colors.white),
      );
      canvas.drawCircle(
        Offset(sx * 0.46, -0.04),
        0.07,
        f(const Color(0xFFFF9BB0)),
      );
    }
    final smile = Path()
      ..moveTo(-0.15, -0.03)
      ..quadraticBezierTo(0, 0.12, 0.15, -0.03);
    canvas.drawPath(
      smile,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.05
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(HeroPainter o) => o.t != t;
}
