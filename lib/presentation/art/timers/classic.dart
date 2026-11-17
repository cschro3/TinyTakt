import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import '../worlds/world_kit.dart' show drawCloud;

/// A. Kreis-Timer: weiche Scheibe, leuchtender Bogen mit Kappe, ruhige Marken.
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
    final w = size.shortestSide * 0.07;
    final r = size.shortestSide / 2 - w * 0.9;
    final rect = Rect.fromCircle(center: c, radius: r);
    // Scheibe mit weichem Schatten
    canvas.drawCircle(
      c + Offset(0, size.shortestSide * 0.012),
      r + w * 0.9,
      Paint()
        ..color = const Color(0x2A2A1A6A)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.5),
    );
    canvas.drawCircle(
      c,
      r + w * 0.9,
      Paint()
        ..shader = ui.Gradient.radial(c - Offset(0, r * 0.4), r * 1.9, const [
          Color(0xFFFFFFFF),
          Color(0xFFF0EBFF),
        ]),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFFE6E0F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w,
    );
    if (ticks) {
      for (var i = 0; i < 12; i++) {
        final a = -math.pi / 2 + i * math.pi / 6;
        final long = i % 3 == 0;
        final d = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(
          c + d * (r - w / 2 - 6),
          c + d * (r - w / 2 - (long ? 20 : 12)),
          Paint()
            ..color = const Color(0xFFA29BC4)
            ..strokeWidth = long ? 4 : 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    if (fraction > 0) {
      final sweep = 2 * math.pi * fraction.clamp(0.0, 1.0);
      final grad = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [
          shade(color, 0.08),
          color,
          Color.lerp(color, const Color(0xFFFFC83D), 0.4)!,
          shade(color, 0.08),
        ],
        stops: const [0, 0.4, 0.8, 1],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 1.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.45),
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..shader = grad
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round,
      );
      // Glanzkante auf dem Bogen
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - w * 0.2),
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.22
          ..strokeCap = StrokeCap.round,
      );
      final a = -math.pi / 2 + sweep;
      final cap = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(cap, w * 0.3, Paint()..color = Colors.white);
      canvas.drawCircle(cap, w * 0.14, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(RingPainter o) =>
      o.fraction != fraction || o.color != color;
}

/// Geometrie des Glases (Wasserlinie, Figur-Position).
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

/// C. Füllstand: Glas mit zwei Wasserschichten, Blasen, Glanz und Skala.
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
      topLeft: const Radius.circular(22),
      topRight: const Radius.circular(22),
    );
    canvas.drawRRect(
      rr.shift(Offset(0, size.height * 0.012)),
      Paint()
        ..color = const Color(0x262A1A6A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = ui.Gradient.linear(g.glass.topLeft, g.glass.bottomRight, [
          Colors.white.withValues(alpha: 0.7),
          Colors.white.withValues(alpha: 0.4),
        ]),
    );
    final y = g.surfaceY(fraction);
    canvas.save();
    canvas.clipRRect(rr);
    Path waveAt(double yy, double amp, double ph, double f) {
      final p = Path()..moveTo(g.glass.left, yy);
      for (var i = 0; i <= 32; i++) {
        final x = g.glass.left + g.glass.width * i / 32;
        p.lineTo(
          x,
          yy + (calm ? 0 : math.sin(t * 1.9 * f + i * 0.45 + ph) * amp),
        );
      }
      return p
        ..lineTo(g.glass.right, g.glass.bottom)
        ..lineTo(g.glass.left, g.glass.bottom)
        ..close();
    }

    canvas.drawPath(
      waveAt(y - 3, 5, 1.6, 0.8),
      Paint()..color = shade(color, 0.14).withValues(alpha: 0.7),
    );
    final body = waveAt(y, 4, 0, 1);
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, y),
          Offset(0, g.glass.bottom),
          [shade(color, 0.06), color, shade(color, -0.12)],
          const [0, 0.5, 1],
        ),
    );
    // Lichtkante an der Oberfläche
    final edge = Path();
    for (var i = 0; i <= 32; i++) {
      final x = g.glass.left + g.glass.width * i / 32;
      final yy = y + (calm ? 0 : math.sin(t * 1.9 + i * 0.45) * 4);
      i == 0 ? edge.moveTo(x, yy) : edge.lineTo(x, yy);
    }
    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.6),
    );
    if (!calm) {
      final rnd = Rng(2);
      for (var i = 0; i < 9; i++) {
        final bx = g.glass.left + g.glass.width * (0.12 + rnd.next() * 0.76);
        final k = (t * 0.1 * (0.6 + rnd.next()) + rnd.next()) % 1.0;
        final by = g.glass.bottom - k * (g.glass.bottom - y);
        final br = 3 + rnd.next() * 4;
        canvas.drawCircle(
          Offset(bx + math.sin(t + i) * 4, by),
          br,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        canvas.drawCircle(
          Offset(bx + math.sin(t + i) * 4 - br * 0.3, by - br * 0.3),
          br * 0.25,
          Paint()..color = Colors.white.withValues(alpha: 0.8),
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
    canvas.drawRRect(
      rr.deflate(5),
      Paint()
        ..color = const Color(0x22403090)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Skala (Viertel): Zeit nicht nur über Farbe lesbar
    for (var i = 1; i < 4; i++) {
      final ly =
          g.glass.bottom -
          g.glass.height * 0.04 -
          g.glass.height * 0.88 * i / 4;
      canvas.drawLine(
        Offset(g.glass.right - 24, ly),
        Offset(g.glass.right - 3, ly),
        Paint()
          ..color = const Color(0xFF8E87B2)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
    // Glanzstreifen
    final hl = Path()
      ..moveTo(g.glass.left + 16, g.glass.top + 30)
      ..quadraticBezierTo(
        g.glass.left + 11,
        g.glass.top + g.glass.height * 0.25,
        g.glass.left + 18,
        g.glass.top + g.glass.height * 0.42,
      );
    canvas.drawPath(
      hl,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(FillPainter o) =>
      o.fraction != fraction || o.t != t || o.color != color;
}

/// D. Regenbogen (Pro): sieben glänzende Bögen, die nacheinander verschwinden.
class RainbowPainter extends CustomPainter {
  RainbowPainter({required this.fraction, this.t = 0});
  final double fraction, t;
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
    for (var i = 0; i < colors.length; i++) {
      final r = outer - i * bandW;
      final bandFraction = (fraction * colors.length - (colors.length - 1 - i))
          .clamp(0.0, 1.0);
      final rect = Rect.fromCircle(center: c, radius: r - bandW / 2);
      canvas.drawArc(
        rect,
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = bandW - 1,
      );
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
        // Glanzlicht
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r - bandW * 0.78),
          math.pi,
          math.pi * bandFraction,
          false,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = bandW * 0.22,
        );
        if (bandFraction < 1 && bandFraction > 0.02) {
          final a = math.pi + math.pi * bandFraction;
          final p = c + Offset(math.cos(a), math.sin(a)) * (r - bandW / 2);
          sparkleStar(
            canvas,
            p,
            bandW * (0.5 + 0.15 * math.sin(t * 6)),
            Colors.white,
          );
        }
      }
    }
    // Wolkenpolster am Fuß
    for (final sx in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(c.dx + sx * outer * 0.9, c.dy + size.width * 0.02);
      canvas.scale(sx, 1);
      canvas.drawPicture(
        PictureCache.get(
          'rainbow.cloud.${size.width.round()}',
          (cc) => drawCloud(cc, size.width * 0.3),
        ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(RainbowPainter o) => o.fraction != fraction || o.t != t;
}

/// E. Sanduhr (Pro): Holzrahmen, Glas, rieselnder Sand.
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
    final top = size.height * 0.07,
        bottom = size.height * 0.93,
        mid = size.height / 2;
    final w = size.width * 0.33;
    final glass = Path()
      ..moveTo(cx - w, top)
      ..lineTo(cx + w, top)
      ..cubicTo(cx + w, mid - size.height * 0.1, cx + 9, mid - 26, cx + 9, mid)
      ..cubicTo(
        cx + 9,
        mid + 26,
        cx + w,
        mid + size.height * 0.1,
        cx + w,
        bottom,
      )
      ..lineTo(cx - w, bottom)
      ..cubicTo(cx - w, mid + size.height * 0.1, cx - 9, mid + 26, cx - 9, mid)
      ..cubicTo(cx - 9, mid - 26, cx - w, mid - size.height * 0.1, cx - w, top)
      ..close();
    canvas.drawPath(
      glass.shift(const Offset(0, 8)),
      Paint()
        ..color = const Color(0x262A1A6A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      glass,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.save();
    canvas.clipPath(glass);
    const sandA = Color(0xFFF8CF6A), sandB = Color(0xFFE5A23A);
    final sandPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, bottom), const [
        sandA,
        sandB,
      ]);
    // oben: Oberfläche sinkt, in der Mitte trichterförmig
    final upH = (mid - top) * fraction;
    final surf = mid - upH;
    final dip = fraction > 0.01 ? 14.0 * math.min(1, fraction * 4) : 0.0;
    final upper = Path()
      ..moveTo(cx - w - 4, surf)
      ..quadraticBezierTo(cx, surf + dip * 2, cx + w + 4, surf)
      ..lineTo(cx + w + 4, mid + 2)
      ..lineTo(cx - w - 4, mid + 2)
      ..close();
    canvas.drawPath(upper, sandPaint);
    // unten: Haufen
    final lowH = (bottom - mid) * 0.9 * (1 - fraction);
    final pile = Path()
      ..moveTo(cx - w - 4, bottom)
      ..lineTo(cx - w - 4, bottom - lowH * 0.3)
      ..quadraticBezierTo(
        cx,
        bottom - lowH * 1.5,
        cx + w + 4,
        bottom - lowH * 0.3,
      )
      ..lineTo(cx + w + 4, bottom)
      ..close();
    canvas.drawPath(pile, sandPaint);
    if (fraction > 0.01 && fraction < 0.99) {
      final tip = bottom - lowH * 0.95;
      canvas.drawLine(
        Offset(cx, mid - 2),
        Offset(cx, tip),
        Paint()
          ..color = sandA
          ..strokeWidth = 3.2,
      );
      if (!calm) {
        final rnd = Rng(4);
        for (var i = 0; i < 7; i++) {
          final k = (t * 1.4 + rnd.next()) % 1.0;
          canvas.drawCircle(
            Offset(cx + (rnd.next() - 0.5) * 6, mid + k * (tip - mid)),
            1.8,
            Paint()..color = sandB,
          );
        }
      }
    }
    canvas.restore();
    // Glasglanz
    canvas.drawPath(
      Path()
        ..moveTo(cx - w + 14, top + 30)
        ..cubicTo(
          cx - w + 6,
          top + size.height * 0.12,
          cx - w + 10,
          mid - 60,
          cx - 22,
          mid - 18,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      glass,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round,
    );
    // Holzrahmen: Platten oben/unten und zwei Stützen
    for (final x in [cx - w - 8, cx + w + 8]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x - 5, top, x + 5, bottom),
          const Radius.circular(5),
        ),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(x - 5, 0),
            Offset(x + 5, 0),
            const [Color(0xFFB07A44), Color(0xFF8A5A2B)],
          ),
      );
    }
    for (final y in [top, bottom]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, y), width: w * 2.7, height: 22),
        const Radius.circular(11),
      );
      canvas.drawRRect(
        r,
        Paint()
          ..shader = ui.Gradient.linear(
            r.outerRect.topCenter,
            r.outerRect.bottomCenter,
            const [Color(0xFFC48A52), Color(0xFF8A5A2B)],
          ),
      );
      canvas.drawLine(
        Offset(cx - w * 1.2, y - 5),
        Offset(cx + w * 1.2, y - 5),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(HourglassPainter o) => o.fraction != fraction || o.t != t;
}
