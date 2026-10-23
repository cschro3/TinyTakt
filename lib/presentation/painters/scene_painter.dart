import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/catalog.dart';

/// Gemalte Hintergrundwelten (eigene Vektorgrafik). [t] steuert sanfte Bewegung,
/// bei [calm] bleibt alles statisch.
class ScenePainter extends CustomPainter {
  ScenePainter(this.bg, {this.t = 0, this.calm = false});
  final BackgroundSpec bg;
  final double t;
  final bool calm;

  double get _t => calm ? 0 : t;

  Paint _f(Color c) => Paint()..color = c;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bg.top, bg.bottom],
        ).createShader(r),
    );
    switch (bg.scenery) {
      case Scenery.meadow:
        _sun(canvas, size, const Offset(0.82, 0.12));
        _clouds(canvas, size, 3);
        _hills(canvas, size, const [Color(0xFF9BDB6E), Color(0xFF7CC857)]);
        _flowers(canvas, size);
      case Scenery.sky:
        _sun(canvas, size, const Offset(0.2, 0.14));
        _clouds(canvas, size, 6, big: true);
      case Scenery.beach:
        _sun(canvas, size, const Offset(0.8, 0.13));
        _clouds(canvas, size, 2);
        _sea(canvas, size, 0.62, const Color(0xFF3FB6E0));
        _sand(canvas, size);
      case Scenery.forest:
        _clouds(canvas, size, 2);
        _trees(canvas, size);
        _hills(canvas, size, const [Color(0xFF6CC47A), Color(0xFF4EA862)]);
      case Scenery.night:
        _stars(canvas, size, 46);
        _moon(canvas, size);
        _hills(canvas, size, const [Color(0xFF2B3A78), Color(0xFF1F2C62)]);
      case Scenery.space:
        _stars(canvas, size, 70);
        _planetBg(canvas, size);
      case Scenery.underwater:
        _bubbles(canvas, size);
        _seaweed(canvas, size);
        _sand(canvas, size, color: const Color(0xFFE8D5A0));
      case Scenery.winter:
        _hills(canvas, size, const [Color(0xFFFFFFFF), Color(0xFFE6F1FA)]);
        _snow(canvas, size);
      case Scenery.sunset:
        _sun(
          canvas,
          size,
          const Offset(0.5, 0.52),
          r: 0.16,
          col: const Color(0xFFFF6E4A),
        );
        _clouds(canvas, size, 3, tint: const Color(0xFFFFE0D0));
        _hills(canvas, size, const [Color(0xFF6B4A8C), Color(0xFF4C3270)]);
    }
  }

  void _sun(
    Canvas c,
    Size s,
    Offset p, {
    double r = 0.09,
    Color col = const Color(0xFFFFD84D),
  }) {
    final o = Offset(s.width * p.dx, s.height * p.dy);
    final rad = s.shortestSide * r;
    c.drawCircle(o, rad * 1.6, _f(col.withValues(alpha: 0.22)));
    c.drawCircle(o, rad, _f(col));
  }

  void _clouds(
    Canvas c,
    Size s,
    int n, {
    bool big = false,
    Color tint = Colors.white,
  }) {
    for (var i = 0; i < n; i++) {
      final speed = 0.004 + (i % 3) * 0.002;
      final x = ((i * 0.37 + _t * speed) % 1.3 - 0.15) * s.width;
      final y = s.height * (0.08 + (i * 0.11) % 0.4);
      final k = s.shortestSide * (big ? 0.16 : 0.1) * (0.8 + (i % 3) * 0.25);
      final p = _f(tint.withValues(alpha: 0.9));
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: k * 2.4, height: k * 0.9),
        p,
      );
      c.drawCircle(Offset(x - k * 0.4, y - k * 0.3), k * 0.55, p);
      c.drawCircle(Offset(x + k * 0.3, y - k * 0.4), k * 0.7, p);
    }
  }

  void _hills(Canvas c, Size s, List<Color> cols) {
    for (var i = 0; i < cols.length; i++) {
      final base = s.height * (0.72 + i * 0.07);
      final p = Path()..moveTo(0, s.height);
      p.lineTo(0, base);
      p.cubicTo(
        s.width * 0.25,
        base - s.height * (0.12 - i * 0.04),
        s.width * 0.6,
        base + s.height * 0.05,
        s.width,
        base - s.height * (0.07 - i * 0.02),
      );
      p.lineTo(s.width, s.height);
      p.close();
      c.drawPath(p, _f(cols[i]));
    }
  }

  void _flowers(Canvas c, Size s) {
    final cols = [
      const Color(0xFFFF7A9A),
      const Color(0xFFFFD84D),
      const Color(0xFFFFFFFF),
      const Color(0xFFB57BE0),
    ];
    final rnd = math.Random(7);
    for (var i = 0; i < 22; i++) {
      final x = rnd.nextDouble() * s.width;
      final y = s.height * (0.8 + rnd.nextDouble() * 0.18);
      final sway = calm ? 0 : math.sin(_t * 2 + i) * 2;
      c.drawCircle(
        Offset(x + sway, y),
        s.shortestSide * 0.012,
        _f(cols[i % cols.length]),
      );
      c.drawCircle(
        Offset(x + sway, y),
        s.shortestSide * 0.005,
        _f(const Color(0xFFFFE680)),
      );
    }
  }

  void _sea(Canvas c, Size s, double from, Color col) {
    final y = s.height * from;
    final p = Path()..moveTo(0, y);
    for (var i = 0; i <= 8; i++) {
      p.quadraticBezierTo(
        s.width * (i + 0.5) / 8,
        y + (i.isEven ? -1 : 1) * 6 + (calm ? 0 : math.sin(_t + i) * 3),
        s.width * (i + 1) / 8,
        y,
      );
    }
    p.lineTo(s.width, s.height);
    p.lineTo(0, s.height);
    p.close();
    c.drawPath(p, _f(col));
  }

  void _sand(Canvas c, Size s, {Color color = const Color(0xFFF7DE9A)}) {
    final y = s.height * 0.86;
    final p = Path()
      ..moveTo(0, y)
      ..quadraticBezierTo(s.width * 0.5, y - s.height * 0.05, s.width, y)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(p, _f(color));
  }

  void _trees(Canvas c, Size s) {
    final rnd = math.Random(3);
    for (var i = 0; i < 7; i++) {
      final x = s.width * (i / 6.0) + rnd.nextDouble() * 20 - 10;
      final h = s.height * (0.22 + rnd.nextDouble() * 0.12);
      final y = s.height * 0.78;
      c.drawRect(
        Rect.fromLTWH(x - h * 0.05, y - h * 0.4, h * 0.1, h * 0.4),
        _f(const Color(0xFF8A5A2B)),
      );
      for (var k = 0; k < 3; k++) {
        final w = h * (0.34 - k * 0.07);
        final top = y - h * (0.55 + k * 0.25);
        c.drawPath(
          Path()
            ..moveTo(x, top)
            ..lineTo(x + w, top + h * 0.4)
            ..lineTo(x - w, top + h * 0.4)
            ..close(),
          _f(
            Color.lerp(
              const Color(0xFF2F9E5B),
              const Color(0xFF58C27D),
              k / 3,
            )!,
          ),
        );
      }
    }
  }

  void _stars(Canvas c, Size s, int n) {
    final rnd = math.Random(11);
    for (var i = 0; i < n; i++) {
      final x = rnd.nextDouble() * s.width;
      final y = rnd.nextDouble() * s.height * 0.85;
      final tw = calm ? 1.0 : 0.6 + 0.4 * math.sin(_t * 2 + i);
      c.drawCircle(
        Offset(x, y),
        s.shortestSide * (0.002 + rnd.nextDouble() * 0.004),
        _f(Colors.white.withValues(alpha: 0.5 + 0.5 * tw)),
      );
    }
  }

  void _moon(Canvas c, Size s) {
    final o = Offset(s.width * 0.8, s.height * 0.13);
    final r = s.shortestSide * 0.07;
    c.drawCircle(o, r * 1.7, _f(const Color(0x22FFF3B0)));
    c.drawCircle(o, r, _f(const Color(0xFFFFF3B0)));
    c.drawCircle(
      o + Offset(r * 0.35, -r * 0.2),
      r * 0.85,
      _f(const Color(0xFF223070)),
    );
  }

  void _planetBg(Canvas c, Size s) {
    final o = Offset(s.width * 0.82, s.height * 0.16);
    final r = s.shortestSide * 0.09;
    c.drawCircle(o, r, _f(const Color(0xFFE0735C)));
    c.drawCircle(
      o + Offset(-r * 0.3, -r * 0.2),
      r * 0.3,
      _f(const Color(0x33FFFFFF)),
    );
    final o2 = Offset(s.width * 0.12, s.height * 0.78);
    c.drawCircle(o2, r * 0.6, _f(const Color(0xFF5CB8E0)));
    c.drawOval(
      Rect.fromCenter(center: o2, width: r * 2, height: r * 0.4),
      _stroke(const Color(0xFFE6D5FF), 3),
    );
  }

  Paint _stroke(Color col, double w) => Paint()
    ..color = col
    ..style = PaintingStyle.stroke
    ..strokeWidth = w;

  void _bubbles(Canvas c, Size s) {
    final rnd = math.Random(5);
    for (var i = 0; i < 16; i++) {
      final x = rnd.nextDouble() * s.width;
      final y =
          (rnd.nextDouble() -
              (calm ? 0 : _t * 0.03 * (0.5 + rnd.nextDouble()))) %
          1.0 *
          s.height;
      c.drawCircle(
        Offset(x, y),
        s.shortestSide * (0.008 + rnd.nextDouble() * 0.014),
        _stroke(Colors.white.withValues(alpha: 0.6), 1.5),
      );
    }
  }

  void _seaweed(Canvas c, Size s) {
    for (var i = 0; i < 7; i++) {
      final x = s.width * (0.05 + i * 0.15);
      final h = s.height * (0.12 + (i % 3) * 0.05);
      final sw = calm ? 0.0 : math.sin(_t * 1.5 + i) * 8;
      final p = Path()
        ..moveTo(x, s.height * 0.9)
        ..quadraticBezierTo(
          x + sw + 10,
          s.height * 0.9 - h * 0.5,
          x + sw,
          s.height * 0.9 - h,
        );
      c.drawPath(
        p,
        _stroke(const Color(0xFF3FBF7F), 6)..strokeCap = StrokeCap.round,
      );
    }
  }

  void _snow(Canvas c, Size s) {
    final rnd = math.Random(9);
    for (var i = 0; i < 40; i++) {
      final x =
          (rnd.nextDouble() + (calm ? 0 : math.sin(_t * 0.5 + i) * 0.01)) *
          s.width;
      final y =
          (rnd.nextDouble() +
              (calm ? 0 : _t * 0.04 * (0.5 + rnd.nextDouble()))) %
          1.0 *
          s.height;
      c.drawCircle(
        Offset(x, y),
        s.shortestSide * (0.004 + rnd.nextDouble() * 0.006),
        _f(Colors.white),
      );
    }
  }

  @override
  bool shouldRepaint(ScenePainter old) =>
      old.t != t || old.bg != bg || old.calm != calm;
}
