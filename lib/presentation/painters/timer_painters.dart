import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Reine Darstellung: nimmt den Restanteil (1 → 0) entgegen, kennt keine Zeitlogik.

/// A. Kreis-Timer: Fortschrittsring leert sich im Uhrzeigersinn, dazu Strichmarken.
class RingPainter extends CustomPainter {
  RingPainter({
    required this.fraction,
    required this.color,
    this.track = const Color(0x33FFFFFF),
    this.ticks = true,
  });
  final double fraction;
  final Color color, track;
  final bool ticks;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final w = size.shortestSide * 0.075;
    final r = size.shortestSide / 2 - w / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r + w / 2 + 6,
      Paint()..color = Colors.white.withValues(alpha: 0.82),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFFE9E4F5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w,
    );
    if (ticks) {
      for (var i = 0; i < 12; i++) {
        final a = -math.pi / 2 + i * math.pi / 6;
        final long = i % 3 == 0;
        final p1 = c + Offset(math.cos(a), math.sin(a)) * (r - w / 2 - 4);
        final p2 =
            c +
            Offset(math.cos(a), math.sin(a)) * (r - w / 2 - (long ? 18 : 10));
        canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = const Color(0xFF9A93B8)
            ..strokeWidth = long ? 4 : 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    if (fraction > 0) {
      final sweep = 2 * math.pi * fraction.clamp(0.0, 1.0);
      final paint = Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: 2 * math.pi,
          colors: [
            color,
            Color.lerp(color, const Color(0xFFFFC83D), 0.45)!,
            color,
          ],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round;
      // Ring beginnt oben und schrumpft gegen den Uhrzeigersinn zum Startpunkt hin.
      canvas.drawArc(rect, -math.pi / 2, sweep, false, paint);
      // Endkappe mit Punkt
      final a = -math.pi / 2 + sweep;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r,
        w * 0.22,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(RingPainter o) =>
      o.fraction != fraction || o.color != color;
}

/// B. Abenteuer-Timer: Weg durch die Landschaft. Liefert die Position der Figur.
class AdventureTrack {
  const AdventureTrack(this.size);
  final Size size;

  Offset at(double progress) {
    final x = size.width * (0.12 + 0.76 * progress);
    final y =
        size.height *
        (0.62 - 0.12 * math.sin(progress * math.pi * 2) - 0.06 * progress);
    return Offset(x, y);
  }
}

class AdventurePainter extends CustomPainter {
  AdventurePainter({
    required this.fraction,
    required this.t,
    this.calm = false,
  });
  final double fraction;
  final double t;
  final bool calm;

  @override
  void paint(Canvas canvas, Size size) {
    final track = AdventureTrack(size);
    final progress = 1 - fraction;
    // Weg
    final path = Path()..moveTo(track.at(0).dx, track.at(0).dy);
    for (var i = 1; i <= 60; i++) {
      final p = track.at(i / 60);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF2DDB0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height * 0.1
        ..strokeCap = StrokeCap.round,
    );
    // Gestrichelte Mitte
    for (var i = 0; i < 24; i++) {
      final p = track.at(i / 24 + 0.01);
      canvas.drawCircle(
        p,
        size.height * 0.008,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
    // Restweg-Markierungen (Fußspuren hinter der Figur)
    for (var i = 0; i < 12; i++) {
      final f = i / 12;
      if (f < progress - 0.04) {
        canvas.drawCircle(
          track.at(f) + Offset(0, size.height * 0.045),
          size.height * 0.012,
          Paint()..color = const Color(0x33000000),
        );
      }
    }
    // Ziel: Fahne
    final goal = track.at(1);
    final pole = Paint()
      ..color = const Color(0xFF6B4423)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      goal + Offset(0, size.height * 0.03),
      goal + Offset(0, -size.height * 0.2),
      pole,
    );
    final wave = calm ? 0.0 : math.sin(t * 4) * 4;
    canvas.drawPath(
      Path()
        ..moveTo(goal.dx, goal.dy - size.height * 0.2)
        ..lineTo(
          goal.dx + size.height * 0.13,
          goal.dy - size.height * 0.165 + wave,
        )
        ..lineTo(goal.dx, goal.dy - size.height * 0.13)
        ..close(),
      Paint()..color = const Color(0xFFE5574B),
    );
    // Start-Markierung
    canvas.drawCircle(
      track.at(0) + Offset(0, size.height * 0.045),
      size.height * 0.02,
      Paint()..color = const Color(0xFF3FBF7F),
    );
    // Fortschrittsband unten (zusätzlich zur Position, nicht nur Farbe)
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.9,
        size.width * 0.76,
        size.height * 0.035,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      barRect,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.12,
          size.height * 0.9,
          size.width * 0.76 * progress.clamp(0.0, 1.0),
          size.height * 0.035,
        ),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF2FC4A8),
    );
  }

  @override
  bool shouldRepaint(AdventurePainter o) => o.fraction != fraction || o.t != t;
}

/// C. Füllstand-Timer: Glas, das sich leert. Gibt die Wasserlinie zurück.
class FillGeometry {
  const FillGeometry(this.size);
  final Size size;
  Rect get glass => Rect.fromCenter(
    center: size.center(Offset.zero),
    width: size.width * 0.74,
    height: size.height * 0.92,
  );
  double surfaceY(double fraction) =>
      glass.bottom -
      glass.height * 0.04 -
      (glass.height * 0.88) * fraction.clamp(0.0, 1.0);
}

class FillPainter extends CustomPainter {
  FillPainter({
    required this.fraction,
    required this.t,
    required this.color,
    this.calm = false,
  });
  final double fraction, t;
  final Color color;
  final bool calm;

  @override
  void paint(Canvas canvas, Size size) {
    final g = FillGeometry(size);
    final rr = RRect.fromRectAndCorners(
      g.glass,
      bottomLeft: Radius.circular(size.width * 0.18),
      bottomRight: Radius.circular(size.width * 0.18),
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
    );
    canvas.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: 0.55));
    final y = g.surfaceY(fraction);
    canvas.save();
    canvas.clipRRect(rr);
    final wave = Path()..moveTo(g.glass.left, y);
    for (var i = 0; i <= 24; i++) {
      final x = g.glass.left + g.glass.width * i / 24;
      wave.lineTo(x, y + (calm ? 0 : math.sin(t * 2.2 + i * 0.5) * 4));
    }
    wave
      ..lineTo(g.glass.right, g.glass.bottom)
      ..lineTo(g.glass.left, g.glass.bottom)
      ..close();
    canvas.drawPath(
      wave,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.85), color],
        ).createShader(g.glass),
    );
    // Blasen
    if (!calm) {
      final rnd = math.Random(2);
      for (var i = 0; i < 8; i++) {
        final bx =
            g.glass.left + g.glass.width * (0.15 + rnd.nextDouble() * 0.7);
        final by =
            g.glass.bottom -
            ((t * 0.12 * (0.6 + rnd.nextDouble()) + rnd.nextDouble()) % 1.0) *
                (g.glass.bottom - y);
        canvas.drawCircle(
          Offset(bx, by),
          3 + rnd.nextDouble() * 4,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
    canvas.restore();
    canvas.drawRRect(
      rr,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    // Skala (Viertel) – Zeit nicht nur über Farbe lesbar
    for (var i = 1; i < 4; i++) {
      final ly =
          g.glass.bottom -
          g.glass.height * 0.04 -
          g.glass.height * 0.88 * i / 4;
      canvas.drawLine(
        Offset(g.glass.right - 22, ly),
        Offset(g.glass.right, ly),
        Paint()
          ..color = const Color(0xFF9A93B8)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
    // Glanz
    canvas.drawLine(
      Offset(g.glass.left + 14, g.glass.top + 26),
      Offset(g.glass.left + 14, g.glass.top + g.glass.height * 0.4),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(FillPainter o) =>
      o.fraction != fraction || o.t != t || o.color != color;
}

/// D. Regenbogen (Pro): sieben Bögen, die nacheinander verschwinden.
class RainbowPainter extends CustomPainter {
  RainbowPainter({required this.fraction});
  final double fraction;
  static const colors = [
    Color(0xFFE5574B),
    Color(0xFFFF9F43),
    Color(0xFFFFD84D),
    Color(0xFF58B368),
    Color(0xFF3F8FD9),
    Color(0xFF5B4FC9),
    Color(0xFFB57BE0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.78);
    final bandW = size.width * 0.055;
    final outer = size.width * 0.46;
    canvas.drawCircle(
      c,
      outer + 4,
      Paint()..color = Colors.white.withValues(alpha: 0.0),
    );
    for (var i = 0; i < colors.length; i++) {
      final r = outer - i * bandW;
      // Jedes Band entspricht 1/7 der Zeit; die Außenbänder verschwinden zuerst.
      final bandFraction = (fraction * colors.length - (colors.length - 1 - i))
          .clamp(0.0, 1.0);
      final rect = Rect.fromCircle(center: c, radius: r - bandW / 2);
      final track = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = bandW;
      canvas.drawArc(rect, math.pi, math.pi, false, track);
      if (bandFraction > 0) {
        canvas.drawArc(
          rect,
          math.pi,
          math.pi * bandFraction,
          false,
          Paint()
            ..color = colors[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = bandW
            ..strokeCap = StrokeCap.butt,
        );
      }
    }
    // Wolken am Fuß
    final cp = Paint()..color = Colors.white;
    for (final sx in [-1.0, 1.0]) {
      final o = Offset(c.dx + sx * outer * 0.92, c.dy);
      canvas.drawOval(
        Rect.fromCenter(
          center: o,
          width: size.width * 0.26,
          height: size.width * 0.12,
        ),
        cp,
      );
      canvas.drawCircle(
        o + Offset(-sx * size.width * 0.04, -size.width * 0.04),
        size.width * 0.06,
        cp,
      );
    }
  }

  @override
  bool shouldRepaint(RainbowPainter o) => o.fraction != fraction;
}

/// E. Sanduhr (Pro).
class HourglassPainter extends CustomPainter {
  HourglassPainter({
    required this.fraction,
    required this.t,
    this.calm = false,
  });
  final double fraction, t;
  final bool calm;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final top = size.height * 0.05,
        bottom = size.height * 0.95,
        mid = size.height / 2;
    final w = size.width * 0.34;
    final glass = Path()
      ..moveTo(cx - w, top)
      ..lineTo(cx + w, top)
      ..quadraticBezierTo(cx + w, mid - 20, cx + 10, mid)
      ..quadraticBezierTo(cx + w, mid + 20, cx + w, bottom)
      ..lineTo(cx - w, bottom)
      ..quadraticBezierTo(cx - w, mid + 20, cx - 10, mid)
      ..quadraticBezierTo(cx - w, mid - 20, cx - w, top)
      ..close();
    canvas.drawPath(
      glass,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.save();
    canvas.clipPath(glass);
    const sand = Color(0xFFF2B84B);
    // oben: Sand schrumpft
    final upH = (mid - top) * fraction;
    canvas.drawRect(
      Rect.fromLTRB(cx - w, mid - upH, cx + w, mid),
      Paint()..color = sand,
    );
    // unten: Sand wächst
    final lowH = (bottom - mid) * (1 - fraction);
    final pile = Path()
      ..moveTo(cx - w, bottom)
      ..lineTo(cx - w, bottom - lowH * 0.35)
      ..quadraticBezierTo(
        cx,
        bottom - lowH * 1.25,
        cx + w,
        bottom - lowH * 0.35,
      )
      ..lineTo(cx + w, bottom)
      ..close();
    canvas.drawPath(pile, Paint()..color = sand);
    if (fraction > 0.01 && fraction < 0.99) {
      canvas.drawLine(
        Offset(cx, mid - 4),
        Offset(cx, bottom - lowH),
        Paint()
          ..color = sand
          ..strokeWidth = 3,
      );
    }
    canvas.restore();
    canvas.drawPath(
      glass,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round,
    );
    for (final y in [top, bottom]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, y), width: w * 2.5, height: 18),
          const Radius.circular(9),
        ),
        Paint()..color = const Color(0xFF8A5A2B),
      );
    }
  }

  @override
  bool shouldRepaint(HourglassPainter o) => o.fraction != fraction || o.t != t;
}
