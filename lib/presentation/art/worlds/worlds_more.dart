import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import 'world_kit.dart';

// Gemeinsame Hilfen ---------------------------------------------------------

void _bg(Canvas c, Size s, List<Color> colors, [List<double>? stops]) {
  final r = Offset.zero & s;
  c.drawRect(r, vgrad(r, colors, stops));
}

/// Hügelband in [color] (mit leichtem Verlauf nach unten).
void _hills(
  Canvas c,
  Size s,
  double base,
  double amp,
  Color top,
  Color bottom, {
  double phase = 0,
  double freq = 1,
  double detail = 0.35,
}) {
  final p = hillPath(s, base, amp, phase: phase, freq: freq, detail: detail);
  c.drawPath(
    p,
    vgrad(Rect.fromLTWH(0, (base - amp) * s.height, s.width, s.height), [
      top,
      bottom,
    ]),
  );
}

void _motes(
  Canvas c,
  Size s,
  double t, {
  required Color color,
  int count = 18,
  int seed = 3,
  double yMin = 0.3,
  double yMax = 0.9,
  double size = 0.012,
}) {
  final rnd = Rng(seed);
  for (var i = 0; i < count; i++) {
    final bx = rnd.next(),
        by = rnd.range(yMin, yMax),
        sp = rnd.range(0.008, 0.025),
        ph = rnd.next() * 6;
    final x =
        ((bx + math.sin(t * 0.2 + ph) * 0.03 + t * sp * 0.2) % 1.0) * s.width;
    final y = (by + math.sin(t * 0.5 + ph) * 0.025) * s.height;
    final a = 0.3 + 0.5 * math.sin(t * 1.3 + ph).abs();
    glow(c, Offset(x, y), s.shortestSide * size, color, a.clamp(0.1, 0.8));
  }
}

void _cloudsDrift(
  Canvas c,
  Size s,
  double t,
  List<(double, double, double, double)> specs,
  String key, {
  Color top = Colors.white,
  Color bottom = const Color(0xFFD7E6F6),
}) {
  for (var i = 0; i < specs.length; i++) {
    final sp = specs[i];
    final w = s.shortestSide * sp.$3;
    final x = ((sp.$1 + t * sp.$4 * 0.1) % 1.4 - 0.2) * s.width;
    c.save();
    c.translate(x, sp.$2 * s.height);
    c.drawPicture(
      PictureCache.get(
        'world.$key.cloud$i.${w.round()}',
        (cc) => drawCloud(cc, w, top: top, bottom: bottom),
      ),
    );
    c.restore();
  }
}

// Zauberwald -----------------------------------------------------------------

class ForestWorld extends WorldArt {
  const ForestWorld();
  @override
  String get id => 'forest';

  @override
  void paint(Canvas c, Size s, double t, bool calm) {
    c.drawPicture(layer('back', s, _back));
    if (!calm)
      lightShafts(
        c,
        s,
        t,
        color: const Color(0xFFFFF3B0),
        count: 6,
        alpha: 0.2,
      );
    c.drawPicture(layer('front', s, _front));
    if (!calm)
      _motes(
        c,
        s,
        t,
        color: const Color(0xFFE8FF9A),
        count: 24,
        seed: 5,
        yMin: 0.3,
        yMax: 0.85,
      );
  }

  static void _back(Canvas c, Size s) {
    _bg(
      c,
      s,
      const [
        Color(0xFFD7F2C0),
        Color(0xFF9AD9A0),
        Color(0xFF5FB27A),
        Color(0xFF2F7A52),
      ],
      const [0, 0.3, 0.62, 1],
    );
    glow(
      c,
      Offset(s.width * 0.5, s.height * 0.08),
      s.shortestSide * 0.8,
      const Color(0xFFFFF6C0),
      0.55,
    );
    final rnd = Rng(4);
    // drei Baumreihen in die Tiefe: hinten hell/bläulich, vorn dunkel
    for (var layer = 0; layer < 3; layer++) {
      final base = 0.52 + layer * 0.07;
      final col = [
        const Color(0xFF8EC9A0),
        const Color(0xFF5FAE82),
        const Color(0xFF3B8E62),
      ][layer];
      for (var i = 0; i < 9 + layer * 2; i++) {
        final x = (i + rnd.next() * 0.6) / (9 + layer * 2 - 0.4);
        c.save();
        c.translate(x * s.width, (base + rnd.range(-0.01, 0.015)) * s.height);
        drawPine(
          c,
          s.shortestSide * (0.28 + layer * 0.09 + rnd.range(0, 0.05)),
          leaf: col,
          seed: i + layer * 20,
        );
        c.restore();
      }
      c.drawRect(
        Rect.fromLTWH(0, (base) * s.height, s.width, s.height * 0.04),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, base * s.height),
            Offset(0, (base + 0.05) * s.height),
            [
              col.withValues(alpha: 0.0),
              shade(col, -0.05).withValues(alpha: 0.5),
            ],
          ),
      );
    }
    // Dunst
    c.drawRect(
      Rect.fromLTWH(0, s.height * 0.4, s.width, s.height * 0.25),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, s.height * 0.4),
          Offset(0, s.height * 0.65),
          const [Color(0x00FFFFFF), Color(0x44E8FFE0), Color(0x00FFFFFF)],
          const [0, 0.5, 1],
        ),
    );
  }

  static void _front(Canvas c, Size s) {
    final ground = hillPath(s, 0.76, 0.03, phase: 1.2, freq: 1.1);
    c.drawPath(
      ground,
      vgrad(
        Rect.fromLTWH(0, s.height * 0.7, s.width, s.height * 0.3),
        const [Color(0xFF5DB36E), Color(0xFF3E9558), Color(0xFF2C7545)],
        const [0, 0.5, 1],
      ),
    );
    drawGrassFringe(
      c,
      s,
      (x) => hillY(x, 0.76, 0.03, phase: 1.2, freq: 1.1),
      a: const Color(0xFF7FDB7A),
      b: const Color(0xFF2F8A4C),
      count: 300,
      maxH: 0.03,
      seed: 8,
    );
    final rnd = Rng(14);
    // Farne und Pilze am Boden
    for (var i = 0; i < 9; i++) {
      final x = rnd.next();
      final y = 0.8 + rnd.next() * 0.18;
      c.save();
      c.translate(x * s.width, y * s.height);
      if (i % 3 == 0) {
        _mushroom(c, s.shortestSide * rnd.range(0.035, 0.06));
      } else {
        _fern(c, s.shortestSide * rnd.range(0.06, 0.1), i);
      }
      c.restore();
    }
    // große Stämme am Rand rahmen die Szene
    for (final side in [-1.0, 1.0]) {
      final x = side < 0 ? 0.0 : s.width;
      final w = s.width * 0.14;
      final trunk = Path()
        ..moveTo(x - side * 0, 0)
        ..lineTo(x - side * w * 1.1, 0)
        ..quadraticBezierTo(
          x - side * w * 0.95,
          s.height * 0.5,
          x - side * w * 1.25,
          s.height,
        )
        ..lineTo(x, s.height)
        ..close();
      c.drawPath(
        trunk,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(x, 0),
            Offset(x - side * w * 1.2, 0),
            const [Color(0xFF3E2A1C), Color(0xFF6A4630), Color(0xFF86603E)],
            const [0, 0.55, 1],
          ),
      );
      for (var i = 0; i < 10; i++) {
        final y = rnd.next() * s.height;
        c.drawLine(
          Offset(x - side * w * rnd.range(0.2, 0.9), y),
          Offset(x - side * w * rnd.range(0.3, 1.0), y + s.height * 0.05),
          Paint()
            ..color = const Color(0x33201008)
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  static void _mushroom(Canvas c, double r) {
    c.drawPath(
      Path()
        ..moveTo(-r * 0.22, 0)
        ..quadraticBezierTo(-r * 0.2, -r * 0.7, -r * 0.3, -r * 0.8)
        ..lineTo(r * 0.3, -r * 0.8)
        ..quadraticBezierTo(r * 0.2, -r * 0.7, r * 0.22, 0)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-r * 0.3, 0),
          Offset(r * 0.3, 0),
          const [Color(0xFFFFF6E4), Color(0xFFF1E2C6)],
        ),
    );
    final cap = Path()
      ..moveTo(-r, -r * 0.75)
      ..quadraticBezierTo(0, -r * 1.9, r, -r * 0.75)
      ..quadraticBezierTo(0, -r * 0.55, -r, -r * 0.75)
      ..close();
    c.drawPath(
      cap,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(-r * 0.3, -r * 1.3),
          r * 1.6,
          const [Color(0xFFFF7A5F), Color(0xFFE5483A), Color(0xFFB8302E)],
          const [0, 0.5, 1],
        ),
    );
    for (final p in <(double, double, double)>[
      (-0.4, -1.0, 0.12),
      (0.1, -1.3, 0.14),
      (0.45, -0.95, 0.1),
    ]) {
      c.drawCircle(
        Offset(p.$1 * r, p.$2 * r),
        p.$3 * r,
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
    }
  }

  static void _fern(Canvas c, double h, int seed) {
    for (var i = -3; i <= 3; i++) {
      c.save();
      c.rotate(i * 0.3);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(h * 0.1, -h * 0.5, h * 0.05 * i, -h);
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.05
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(
            const Color(0xFF2F8A4C),
            const Color(0xFF7FDB7A),
            (i + 3) / 6,
          )!,
      );
      c.restore();
    }
  }
}

// Sternennacht ---------------------------------------------------------------

class NightWorld extends WorldArt {
  const NightWorld();
  @override
  String get id => 'night';

  @override
  void paint(Canvas c, Size s, double t, bool calm) {
    c.drawPicture(layer('back', s, _back));
    if (!calm) {
      // funkelnde Sterne (wenige, pulsierend)
      final rnd = Rng(31);
      for (var i = 0; i < 26; i++) {
        final p = Offset(rnd.next() * s.width, rnd.next() * s.height * 0.62);
        final a = 0.35 + 0.65 * math.sin(t * rnd.range(0.8, 2.2) + i).abs();
        glow(c, p, s.shortestSide * 0.012, Colors.white, a);
      }
      // Sternschnuppe alle ~14 s
      final k = (t % 14.0 - 9.0) / 0.9;
      if (k > 0 && k < 1) {
        final p = Offset(
          s.width * (0.9 - 0.5 * k),
          s.height * (0.08 + 0.22 * k),
        );
        c.drawLine(
          p,
          p + Offset(s.width * 0.14, -s.height * 0.05),
          Paint()
            ..shader = ui.Gradient.linear(
              p,
              p + Offset(s.width * 0.14, -s.height * 0.05),
              [
                Colors.white.withValues(alpha: 0.9 * (1 - k)),
                Colors.white.withValues(alpha: 0),
              ],
            )
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    c.drawPicture(layer('front', s, _front));
    if (!calm) {
      _motes(
        c,
        s,
        t,
        color: const Color(0xFFD8FF8A),
        count: 16,
        seed: 9,
        yMin: 0.62,
        yMax: 0.95,
        size: 0.014,
      );
      // Rauch aus dem Schornstein
      final chim = Offset(s.width * 0.215, s.height * 0.57);
      for (var i = 0; i < 4; i++) {
        final k = ((t * 0.35) + i / 4) % 1;
        c.drawCircle(
          chim + Offset(math.sin(k * 4 + i) * 6 + k * 14, -k * s.height * 0.07),
          s.shortestSide * (0.008 + 0.014 * k),
          Paint()..color = Colors.white.withValues(alpha: 0.3 * (1 - k)),
        );
      }
    }
  }

  static void _back(Canvas c, Size s) {
    _bg(
      c,
      s,
      const [
        Color(0xFF0B1038),
        Color(0xFF1C2A70),
        Color(0xFF3C4C9E),
        Color(0xFF6A78C0),
      ],
      const [0, 0.4, 0.75, 1],
    );
    // zarte Polarlicht-Schleier
    for (var i = 0; i < 3; i++) {
      final path = Path()..moveTo(0, s.height * (0.2 + i * 0.05));
      for (var k = 0; k <= 10; k++) {
        path.lineTo(
          s.width * k / 10,
          s.height * (0.2 + i * 0.05 + 0.04 * math.sin(k * 0.9 + i * 1.7)),
        );
      }
      path.lineTo(s.width, s.height * 0.05);
      path.lineTo(0, s.height * 0.05);
      path.close();
      c.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, s.height * 0.05),
            Offset(0, s.height * 0.3),
            [
              const Color(0x00000000),
              [
                const Color(0x3347E0B0),
                const Color(0x336E7BFF),
                const Color(0x33B070F0),
              ][i],
            ],
          ),
      );
    }
    starfield(c, s, count: 90, seed: 2, yMax: 0.68, maxR: 0.005);
    drawMoon(c, Offset(s.width * 0.78, s.height * 0.15), s.shortestSide * 0.07);
  }

  static void _front(Canvas c, Size s) {
    _hills(
      c,
      s,
      0.62,
      0.03,
      const Color(0xFF28397E),
      const Color(0xFF1C2A66),
      phase: 0.5,
    );
    _hills(
      c,
      s,
      0.72,
      0.035,
      const Color(0xFF1F2E6E),
      const Color(0xFF16215A),
      phase: 2.2,
      freq: 1.2,
    );
    final rnd = Rng(12);
    for (var i = 0; i < 8; i++) {
      final x = rnd.range(0.35, 0.98);
      final y = hillY(x, 0.72, 0.035, phase: 2.2, freq: 1.2) * s.height + 2;
      c.save();
      c.translate(x * s.width, y);
      drawPine(
        c,
        s.shortestSide * rnd.range(0.1, 0.18),
        leaf: const Color(0xFF14204F),
        seed: i,
      );
      c.restore();
    }
    // gemütliches Häuschen mit leuchtendem Fenster
    final hx = s.width * 0.2;
    final hy = hillY(0.2, 0.72, 0.035, phase: 2.2, freq: 1.2) * s.height + 3;
    c.save();
    c.translate(hx, hy);
    final u = s.shortestSide * 0.07;
    c.drawRect(
      Rect.fromLTWH(-u, -u * 1.0, u * 2, u),
      Paint()..color = const Color(0xFF2A3470),
    );
    c.drawPath(
      Path()
        ..moveTo(-u * 1.2, -u)
        ..lineTo(0, -u * 1.8)
        ..lineTo(u * 1.2, -u)
        ..close(),
      Paint()..color = const Color(0xFF1A2358),
    );
    c.drawRect(
      Rect.fromLTWH(u * 0.5, -u * 1.9, u * 0.26, u * 0.7),
      Paint()..color = const Color(0xFF1A2358),
    );
    glow(c, Offset(-u * 0.3, -u * 0.55), u * 1.1, const Color(0xFFFFD27A), 0.7);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-u * 0.3, -u * 0.55),
          width: u * 0.5,
          height: u * 0.5,
        ),
        Radius.circular(u * 0.06),
      ),
      Paint()..color = const Color(0xFFFFE8A8),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(u * 0.5, -u * 0.35),
          width: u * 0.34,
          height: u * 0.7,
        ),
        Radius.circular(u * 0.17),
      ),
      Paint()..color = const Color(0xFF111A4A),
    );
    c.restore();
    _hills(
      c,
      s,
      0.84,
      0.03,
      const Color(0xFF16215A),
      const Color(0xFF0E1640),
      phase: 4,
      freq: 0.9,
    );
  }
}

// Weltraum -------------------------------------------------------------------

class SpaceWorld extends WorldArt {
  const SpaceWorld();
  @override
  String get id => 'space';

  @override
  void paint(Canvas c, Size s, double t, bool calm) {
    c.drawPicture(layer('back', s, _back));
    if (!calm) {
      final rnd = Rng(77);
      for (var i = 0; i < 30; i++) {
        final p = Offset(rnd.next() * s.width, rnd.next() * s.height);
        final a = 0.3 + 0.7 * math.sin(t * rnd.range(0.7, 2.0) + i).abs();
        glow(c, p, s.shortestSide * 0.012, Colors.white, a);
      }
      // Komet
      final k = (t % 18.0 - 12.0) / 1.6;
      if (k > 0 && k < 1) {
        final p = Offset(
          s.width * (1.05 - 1.2 * k),
          s.height * (0.12 + 0.45 * k),
        );
        final tail = Offset(s.width * 0.28, -s.height * 0.13);
        c.drawLine(
          p,
          p + tail,
          Paint()
            ..shader = ui.Gradient.linear(p, p + tail, const [
              Color(0xCCBFE0FF),
              Color(0x00BFE0FF),
            ])
            ..strokeWidth = s.shortestSide * 0.012
            ..strokeCap = StrokeCap.round,
        );
        glow(c, p, s.shortestSide * 0.03, Colors.white, 0.9);
      }
    }
    c.drawPicture(layer('planets', s, _planets));
  }

  static void _back(Canvas c, Size s) {
    _bg(
      c,
      s,
      const [
        Color(0xFF070824),
        Color(0xFF160C3E),
        Color(0xFF2A1560),
        Color(0xFF3C1E78),
      ],
      const [0, 0.4, 0.75, 1],
    );
    // Nebel
    for (final n in <(double, double, double, Color)>[
      (0.2, 0.25, 0.55, Color(0xFF7A3FC8)),
      (0.85, 0.5, 0.5, Color(0xFF2FA8C8)),
      (0.45, 0.8, 0.6, Color(0xFFC8408A)),
      (0.7, 0.12, 0.35, Color(0xFF4F5FE0)),
    ]) {
      glow(
        c,
        Offset(s.width * n.$1, s.height * n.$2),
        s.shortestSide * n.$3,
        n.$4,
        0.32,
      );
    }
    starfield(c, s, count: 160, seed: 5, yMax: 1.0, maxR: 0.005);
    // feine Umlaufbahn
    c.drawArc(
      Rect.fromCenter(
        center: Offset(s.width * 0.72, s.height * 0.2),
        width: s.width * 1.1,
        height: s.height * 0.18,
      ),
      0.2,
      2.8,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0x33FFFFFF),
    );
  }

  static void _planets(Canvas c, Size s) {
    final m = s.shortestSide;
    drawPlanet(
      c,
      Offset(s.width * 0.78, s.height * 0.2),
      m * 0.1,
      const Color(0xFFF2A65A),
      const Color(0xFFB8602E),
      ring: true,
      bands: const [-0.4, 0.0, 0.35, 0.6],
    );
    drawPlanet(
      c,
      Offset(s.width * 0.14, s.height * 0.62),
      m * 0.05,
      const Color(0xFF5CB8F0),
      const Color(0xFF2A6AB8),
      bands: const [-0.2, 0.3],
    );
    drawPlanet(
      c,
      Offset(s.width * 0.98, s.height * 0.95),
      m * 0.24,
      const Color(0xFFE0735C),
      const Color(0xFF8A2E4A),
      bands: const [-0.5, -0.1, 0.4],
    );
    drawPlanet(
      c,
      Offset(s.width * 0.3, s.height * 0.12),
      m * 0.028,
      const Color(0xFFD8E0F0),
      const Color(0xFF7A86A8),
    );
  }
}

// Strand ---------------------------------------------------------------------

class BeachWorld extends WorldArt {
  const BeachWorld();
  @override
  String get id => 'beach';

  @override
  void paint(Canvas c, Size s, double t, bool calm) {
    c.drawPicture(layer('back', s, _back));
    _sea(c, s, calm ? 0 : t);
    c.drawPicture(layer('sand', s, _sand));
    final sway = calm ? 0.0 : math.sin(t * 1.4) * 0.05;
    c.save();
    c.translate(s.width * 0.12, s.height * 0.84);
    drawPalm(c, s.height * 0.42, lean: 0.2, sway: sway);
    c.restore();
    if (!calm) {
      for (var i = 0; i < 3; i++) {
        final x = ((0.2 + i * 0.3 + t * 0.012) % 1.2 - 0.1) * s.width;
        final y = (0.16 + i * 0.07 + math.sin(t * 0.8 + i) * 0.01) * s.height;
        final flap = math.sin(t * 5 + i) * 4;
        c.drawPath(
          Path()
            ..moveTo(x - 10, y + flap)
            ..quadraticBezierTo(x - 4, y - 6, x, y)
            ..quadraticBezierTo(x + 4, y - 6, x + 10, y + flap),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round
            ..color = Colors.white,
        );
      }
    }
  }

  static void _back(Canvas c, Size s) {
    _bg(
      c,
      s,
      const [Color(0xFF63C8F2), Color(0xFFA8E4F8), Color(0xFFE6F8FF)],
      const [0, 0.5, 1],
    );
    final sun = Offset(s.width * 0.8, s.height * 0.14);
    glow(c, sun, s.shortestSide * 0.4, const Color(0xFFFFEBA0), 0.55);
    c.drawCircle(
      sun,
      s.shortestSide * 0.07,
      Paint()
        ..shader = ui.Gradient.radial(
          sun,
          s.shortestSide * 0.09,
          const [Color(0xFFFFFBE0), Color(0xFFFFE066), Color(0xFFFFC83D)],
          const [0, 0.55, 1],
        ),
    );
    for (final cl in <(double, double, double)>[
      (0.2, 0.13, 0.22),
      (0.55, 0.22, 0.18),
      (0.45, 0.08, 0.16),
    ]) {
      c.save();
      c.translate(s.width * cl.$1, s.height * cl.$2);
      drawCloud(c, s.shortestSide * cl.$3);
      c.restore();
    }
    // Horizont
    final horizon = Rect.fromLTWH(0, s.height * 0.44, s.width, s.height * 0.3);
    c.drawRect(
      horizon,
      vgrad(horizon, const [
        Color(0xFF5CC8D8),
        Color(0xFF2FA8C8),
        Color(0xFF1E86B8),
      ]),
    );
  }

  static void _sea(Canvas c, Size s, double t) {
    // drei Wellenbänder, die sanft schwingen; Schaumkämme als helle Linien
    for (var layer = 0; layer < 3; layer++) {
      final y0 = s.height * (0.5 + layer * 0.065);
      final path = Path()..moveTo(0, y0);
      for (var i = 0; i <= 24; i++) {
        final x = s.width * i / 24;
        path.lineTo(
          x,
          y0 +
              math.sin(i * 0.8 + t * (0.9 + layer * 0.3) + layer) *
                  s.height *
                  0.006 *
                  (1 + layer),
        );
      }
      path.lineTo(s.width, s.height);
      path.lineTo(0, s.height);
      path.close();
      final cols = [
        const Color(0xFF3FB4D6),
        const Color(0xFF2FA0CC),
        const Color(0xFF2490C0),
      ][layer];
      c.drawPath(path, Paint()..color = cols.withValues(alpha: 0.9));
      final foam = Path();
      for (var i = 0; i <= 24; i++) {
        final x = s.width * i / 24;
        final y =
            y0 +
            math.sin(i * 0.8 + t * (0.9 + layer * 0.3) + layer) *
                s.height *
                0.006 *
                (1 + layer);
        i == 0 ? foam.moveTo(x, y) : foam.lineTo(x, y);
      }
      c.drawPath(
        foam,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = Colors.white.withValues(alpha: 0.55),
      );
    }
    // Glitzern
    final rnd = Rng(15);
    for (var i = 0; i < 18; i++) {
      final p = Offset(rnd.next() * s.width, s.height * rnd.range(0.47, 0.7));
      final a = math.sin(t * 2 + i).abs() * 0.7;
      c.drawLine(
        p,
        p + Offset(s.width * 0.03, 0),
        Paint()
          ..color = Colors.white.withValues(alpha: a)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  static void _sand(Canvas c, Size s) {
    final sand = hillPath(s, 0.76, 0.025, phase: 0.8, freq: 0.8);
    // nasser Rand
    c.drawPath(
      sand.shift(const Offset(0, -6)),
      Paint()..color = const Color(0xFFC8A870).withValues(alpha: 0.55),
    );
    c.drawPath(
      sand,
      vgrad(
        Rect.fromLTWH(0, s.height * 0.72, s.width, s.height * 0.28),
        const [Color(0xFFFFEDB4), Color(0xFFF7DA94), Color(0xFFE8C078)],
        const [0, 0.5, 1],
      ),
    );
    final rnd = Rng(16);
    for (var i = 0; i < 40; i++) {
      c.drawCircle(
        Offset(rnd.next() * s.width, s.height * rnd.range(0.78, 0.99)),
        rnd.range(1, 2.4),
        Paint()..color = const Color(0x33A8803A),
      );
    }
    // Muschel und Seestern
    c.save();
    c.translate(s.width * 0.72, s.height * 0.9);
    c.drawPath(
      Path()
        ..moveTo(-14, 6)
        ..quadraticBezierTo(0, -22, 14, 6)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -14),
          const Offset(0, 6),
          const [Color(0xFFFFE0E8), Color(0xFFF4A8B8)],
        ),
    );
    for (var i = -2; i <= 2; i++) {
      c.drawLine(
        Offset(i * 3, 5),
        Offset(i * 4.5, -10),
        Paint()
          ..color = const Color(0x55B05070)
          ..strokeWidth = 1.2,
      );
    }
    c.restore();
    c.save();
    c.translate(s.width * 0.4, s.height * 0.95);
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 16.0 : 6.5;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    c.drawPath(
      star..close(),
      Paint()
        ..shader = ui.Gradient.radial(const Offset(-3, -3), 20, const [
          Color(0xFFFFA070),
          Color(0xFFE5603A),
        ]),
    );
    c.restore();
  }
}

// Wolkenhimmel ---------------------------------------------------------------

class SkyWorld extends WorldArt {
  const SkyWorld();
  @override
  String get id => 'sky';

  static const _far = <(double, double, double, double)>[
    (0.1, 0.1, 0.3, 0.6),
    (0.7, 0.14, 0.34, 0.5),
    (0.4, 0.32, 0.26, 0.7),
    (0.95, 0.4, 0.3, 0.45),
  ];
  static const _near = <(double, double, double, double)>[
    (0.3, 0.2, 0.46, 1.0),
    (0.85, 0.28, 0.5, 0.9),
    (0.0, 0.5, 0.44, 1.1),
  ];

  @override
  void paint(Canvas c, Size s, double t, bool calm) {
    c.drawPicture(layer('back', s, _back));
    _cloudsDrift(
      c,
      s,
      calm ? 0 : t,
      _far,
      'sky.far',
      bottom: const Color(0xFFE2EEFA),
    );
    // Heißluftballon schaukelt sanft
    final bob = calm ? 0.0 : math.sin(t * 0.8) * 6;
    c.save();
    c.translate(s.width * 0.72, s.height * 0.3 + bob);
    c.rotate(calm ? 0 : math.sin(t * 0.6) * 0.03);
    _balloon(c, s.shortestSide * 0.1);
    c.restore();
    _cloudsDrift(c, s, calm ? 0 : t, _near, 'sky.near');
    if (!calm) {
      for (var i = 0; i < 3; i++) {
        final x = ((0.1 + i * 0.35 + t * 0.015) % 1.2 - 0.1) * s.width;
        final y = (0.5 + i * 0.05 + math.sin(t + i) * 0.01) * s.height;
        final flap = math.sin(t * 6 + i) * 3;
        c.drawPath(
          Path()
            ..moveTo(x - 9, y + flap)
            ..quadraticBezierTo(x - 3, y - 5, x, y)
            ..quadraticBezierTo(x + 3, y - 5, x + 9, y + flap),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF3A4A78),
        );
      }
    }
    c.drawPicture(layer('front', s, _front));
  }

  static void _back(Canvas c, Size s) {
    _bg(
      c,
      s,
      const [
        Color(0xFF3FA8F2),
        Color(0xFF7CC8F8),
        Color(0xFFBDE6FF),
        Color(0xFFFFF4DC),
      ],
      const [0, 0.4, 0.75, 1],
    );
    final sun = Offset(s.width * 0.2, s.height * 0.1);
    glow(c, sun, s.shortestSide * 0.5, const Color(0xFFFFF4C0), 0.6);
    c.drawCircle(
      sun,
      s.shortestSide * 0.06,
      Paint()..color = const Color(0xFFFFF8D8),
    );
  }

  static void _front(Canvas c, Size s) {
    // Wolkenmeer unten als Boden der Szene
    for (var i = 0; i < 9; i++) {
      c.save();
      c.translate(s.width * (i / 8.0), s.height * (0.9 + (i % 2) * 0.03));
      drawCloud(
        c,
        s.shortestSide * (0.4 + (i % 3) * 0.06),
        top: Colors.white,
        bottom: const Color(0xFFD0E4F8),
      );
      c.restore();
    }
  }

  static void _balloon(Canvas c, double r) {
    final env = Path()
      ..moveTo(0, -r * 1.3)
      ..cubicTo(r * 1.15, -r * 1.3, r * 1.1, r * 0.5, r * 0.3, r * 0.75)
      ..lineTo(-r * 0.3, r * 0.75)
      ..cubicTo(-r * 1.1, r * 0.5, -r * 1.15, -r * 1.3, 0, -r * 1.3)
      ..close();
    c.drawPath(
      env,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-r, 0),
          Offset(r, 0),
          const [
            Color(0xFFFF7A5F),
            Color(0xFFFFC83D),
            Color(0xFFFF7A5F),
            Color(0xFFE5483A),
          ],
          const [0, 0.35, 0.65, 1],
        ),
    );
    for (final x in [-0.5, 0.0, 0.5]) {
      c.drawPath(
        Path()
          ..moveTo(x * r * 0.4, -r * 1.28)
          ..quadraticBezierTo(x * r * 1.2, -r * 0.2, x * r * 0.3, r * 0.74),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0x33801810),
      );
    }
    c.drawLine(
      Offset(-r * 0.25, r * 0.75),
      Offset(-r * 0.2, r * 1.05),
      Paint()
        ..color = const Color(0xFF6A4A2A)
        ..strokeWidth = 1.6,
    );
    c.drawLine(
      Offset(r * 0.25, r * 0.75),
      Offset(r * 0.2, r * 1.05),
      Paint()
        ..color = const Color(0xFF6A4A2A)
        ..strokeWidth = 1.6,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-r * 0.24, r * 1.05, r * 0.48, r * 0.3),
        Radius.circular(r * 0.06),
      ),
      Paint()..color = const Color(0xFF9A6A3E),
    );
    softHighlight(
      c,
      env,
      Offset(-r * 0.4, -r * 0.6),
      r * 0.3,
      r * 0.5,
      alpha: 0.35,
    );
  }
}

// Unterwasserwelt ------------------------------------------------------------

class UnderwaterWorld extends WorldArt {
  const UnderwaterWorld();
  @override
  String get id => 'underwater';

  @override
  void paint(Canvas c, Size s, double t, bool calm) {
    c.drawPicture(layer('back', s, _back));
    if (!calm) {
      lightShafts(
        c,
        s,
        t,
        color: const Color(0xFFCFF8FF),
        count: 7,
        angle: 0.18,
        alpha: 0.22,
      );
      _caustics(c, s, t);
    }
    c.drawPicture(layer('front', s, _front));
    _seaweed(c, s, calm ? 0 : t);
    if (!calm) {
      _fish(c, s, t);
      _bubbles(c, s, t);
    }
  }

  static void _back(Canvas c, Size s) {
    _bg(
      c,
      s,
      const [
        Color(0xFF3ED0E0),
        Color(0xFF1E92D0),
        Color(0xFF145AA8),
        Color(0xFF0C3A80),
      ],
      const [0, 0.35, 0.7, 1],
    );
    // ferne Felsen/Korallen (blau verdunstet)
    final rnd = Rng(18);
    for (var i = 0; i < 6; i++) {
      final x = rnd.next() * s.width;
      final h = s.height * rnd.range(0.08, 0.18);
      c.drawPath(
        Path()
          ..moveTo(x - h * 0.5, s.height * 0.78)
          ..quadraticBezierTo(
            x - h * 0.2,
            s.height * 0.78 - h,
            x,
            s.height * 0.78 - h * 1.1,
          )
          ..quadraticBezierTo(
            x + h * 0.3,
            s.height * 0.78 - h * 0.8,
            x + h * 0.55,
            s.height * 0.78,
          )
          ..close(),
        Paint()..color = const Color(0xFF1E5CA8).withValues(alpha: 0.6),
      );
    }
  }

  static void _caustics(Canvas c, Size s, double t) {
    for (var i = 0; i < 6; i++) {
      final y = s.height * (0.04 + i * 0.05);
      final path = Path();
      for (var k = 0; k <= 30; k++) {
        final x = s.width * k / 30;
        final yy =
            y +
            math.sin(k * 0.7 + t * (0.8 + i * 0.1) + i * 2) * s.height * 0.012;
        k == 0 ? path.moveTo(x, yy) : path.lineTo(x, yy);
      }
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = Colors.white.withValues(alpha: 0.12 * (1 - i / 7)),
      );
    }
  }

  static void _front(Canvas c, Size s) {
    final sand = hillPath(s, 0.86, 0.02, phase: 1.0);
    c.drawPath(
      sand,
      vgrad(Rect.fromLTWH(0, s.height * 0.82, s.width, s.height * 0.18), const [
        Color(0xFFF2DFA8),
        Color(0xFFD9BE7E),
        Color(0xFFB89C60),
      ]),
    );
    // Sandwellen
    for (var i = 0; i < 5; i++) {
      c.drawPath(
        Path()
          ..moveTo(0, s.height * (0.9 + i * 0.02))
          ..quadraticBezierTo(
            s.width * 0.5,
            s.height * (0.88 + i * 0.02),
            s.width,
            s.height * (0.9 + i * 0.02),
          ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0x22806030),
      );
    }
    final rnd = Rng(19);
    // Korallen: verzweigt, rosa/orange
    for (var i = 0; i < 6; i++) {
      final x = (0.08 + i * 0.17 + rnd.range(-0.03, 0.03)) * s.width;
      c.save();
      c.translate(x, s.height * 0.9);
      _coral(
        c,
        s.shortestSide * rnd.range(0.1, 0.18),
        [
          const Color(0xFFFF8CA8),
          const Color(0xFFFF9A5A),
          const Color(0xFFC888F0),
        ][i % 3],
        i,
      );
      c.restore();
    }
  }

  static void _coral(Canvas c, double h, Color col, int seed) {
    void branch(Offset from, double ang, double len, int depth) {
      final to = from + Offset(math.sin(ang) * len, -math.cos(ang) * len);
      c.drawLine(
        from,
        to,
        Paint()
          ..color = shade(col, -0.03 * depth)
          ..strokeWidth = h * 0.09 * (1 - depth * 0.18)
          ..strokeCap = StrokeCap.round,
      );
      if (depth < 3) {
        branch(to, ang - 0.5, len * 0.7, depth + 1);
        branch(to, ang + 0.5, len * 0.7, depth + 1);
      } else {
        c.drawCircle(to, h * 0.05, Paint()..color = shade(col, 0.12));
      }
    }

    branch(Offset.zero, 0, h * 0.5, 0);
  }

  static void _seaweed(Canvas c, Size s, double t) {
    for (var i = 0; i < 8; i++) {
      final x = s.width * (0.04 + i * 0.13);
      final h = s.height * (0.13 + (i % 3) * 0.05);
      final sw = math.sin(t * 1.3 + i) * s.width * 0.02;
      final path = Path()
        ..moveTo(x - 4, s.height * 0.92)
        ..quadraticBezierTo(
          x + sw,
          s.height * 0.92 - h * 0.55,
          x + sw * 1.6,
          s.height * 0.92 - h,
        )
        ..quadraticBezierTo(
          x + sw * 0.8 + 6,
          s.height * 0.92 - h * 0.5,
          x + 4,
          s.height * 0.92,
        )
        ..close();
      c.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(x, s.height * 0.92),
            Offset(x, s.height * 0.92 - h),
            const [Color(0xFF1F9A6A), Color(0xFF58E0A0)],
          ),
      );
    }
  }

  static void _fish(Canvas c, Size s, double t) {
    const cols = [Color(0xFFFF9F43), Color(0xFFFFD84D), Color(0xFFFF7BA5)];
    for (var i = 0; i < 3; i++) {
      final dir = i.isEven ? 1.0 : -1.0;
      final x = ((0.1 + i * 0.33 + t * 0.02 * dir) % 1.3 - 0.15) * s.width;
      final y = s.height * (0.3 + i * 0.12) + math.sin(t * 1.2 + i) * 8;
      c.save();
      c.translate(x, y);
      c.scale(dir, 1);
      final w = s.shortestSide * 0.045;
      final tail = math.sin(t * 8 + i) * w * 0.25;
      c.drawPath(
        Path()
          ..moveTo(-w * 0.9, 0)
          ..lineTo(-w * 1.5, -w * 0.5 + tail)
          ..lineTo(-w * 1.5, w * 0.5 + tail)
          ..close(),
        Paint()..color = shade(cols[i], -0.08),
      );
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: w * 2, height: w * 1.2),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, -w * 0.6),
            Offset(0, w * 0.6),
            [shade(cols[i], 0.1), cols[i], shade(cols[i], -0.12)],
            const [0, 0.5, 1],
          ),
      );
      c.drawCircle(
        Offset(w * 0.5, -w * 0.12),
        w * 0.14,
        Paint()..color = const Color(0xFF1A1A30),
      );
      c.drawCircle(
        Offset(w * 0.54, -w * 0.16),
        w * 0.05,
        Paint()..color = Colors.white,
      );
      c.restore();
    }
  }

  static void _bubbles(Canvas c, Size s, double t) {
    final rnd = Rng(20);
    for (var i = 0; i < 16; i++) {
      final bx = rnd.next(),
          sp = rnd.range(0.03, 0.08),
          ph = rnd.next() * 6,
          r = s.shortestSide * rnd.range(0.006, 0.016);
      final y = (1.0 - ((t * sp + ph) % 1.0)) * s.height;
      final x = (bx + math.sin(t * 0.8 + ph) * 0.02) * s.width;
      c.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.white.withValues(alpha: 0.6),
      );
      c.drawCircle(
        Offset(x - r * 0.3, y - r * 0.3),
        r * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }
  }
}

// Winterland -----------------------------------------------------------------

class WinterWorld extends WorldArt {
  const WinterWorld();
  @override
  String get id => 'winter';

  @override
  void paint(Canvas c, Size s, double t, bool calm) {
    c.drawPicture(layer('back', s, _back));
    c.drawPicture(layer('front', s, _front));
    if (!calm) {
      final chim = Offset(s.width * 0.8, s.height * 0.6);
      for (var i = 0; i < 4; i++) {
        final k = ((t * 0.3) + i / 4) % 1;
        c.drawCircle(
          chim + Offset(math.sin(k * 4 + i) * 6, -k * s.height * 0.08),
          s.shortestSide * (0.008 + 0.014 * k),
          Paint()..color = Colors.white.withValues(alpha: 0.55 * (1 - k)),
        );
      }
      _snow(c, s, t);
      // Glitzern im Schnee
      final rnd = Rng(24);
      for (var i = 0; i < 14; i++) {
        final p = Offset(
          rnd.next() * s.width,
          s.height * rnd.range(0.66, 0.98),
        );
        final a = (math.sin(t * 2.2 + i * 1.3)).clamp(0.0, 1.0);
        if (a > 0.1)
          sparkleStar(c, p, s.shortestSide * 0.012 * a, Colors.white);
      }
    }
  }

  static void _snow(Canvas c, Size s, double t) {
    final rnd = Rng(23);
    for (var i = 0; i < 70; i++) {
      final layer = i % 2;
      final sp = rnd.range(0.04, 0.09) * (1 + layer * 0.7);
      final bx = rnd.next(), ph = rnd.next() * 6;
      final y = ((t * sp + ph) % 1.0) * s.height;
      final x = (bx + math.sin(t * 0.7 + ph) * 0.02 * (1 + layer)) * s.width;
      final r =
          s.shortestSide * (layer == 0 ? 0.004 : 0.007) * rnd.range(0.7, 1.3);
      c.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: layer == 0 ? 0.7 : 0.95),
      );
    }
  }

  static void _back(Canvas c, Size s) {
    _bg(
      c,
      s,
      const [Color(0xFF9AC4EC), Color(0xFFCFE6F8), Color(0xFFF4FAFF)],
      const [0, 0.55, 1],
    );
    final sun = Offset(s.width * 0.25, s.height * 0.16);
    glow(c, sun, s.shortestSide * 0.4, const Color(0xFFFFF8E0), 0.55);
    c.drawCircle(
      sun,
      s.shortestSide * 0.05,
      Paint()..color = const Color(0xFFFFFDF0),
    );
    _hills(
      c,
      s,
      0.54,
      0.03,
      const Color(0xFFE6F0FA),
      const Color(0xFFD0E2F4),
      phase: 0.5,
    );
    final rnd = Rng(25);
    for (var i = 0; i < 10; i++) {
      final x = rnd.range(0.02, 0.98);
      final y = hillY(x, 0.54, 0.03, phase: 0.5) * s.height + 2;
      c.save();
      c.translate(x * s.width, y);
      drawPine(
        c,
        s.shortestSide * rnd.range(0.1, 0.16),
        leaf: const Color(0xFF6AA8A8),
        snow: Colors.white,
        seed: i,
      );
      c.restore();
    }
  }

  static void _front(Canvas c, Size s) {
    _hills(
      c,
      s,
      0.66,
      0.04,
      const Color(0xFFF4F9FF),
      const Color(0xFFDCEAF8),
      phase: 2.0,
      freq: 1.1,
    );
    final rnd = Rng(26);
    // Häuschen mit Schneedach
    final hx = 0.8;
    final hy = hillY(hx, 0.66, 0.04, phase: 2.0, freq: 1.1) * s.height + 4;
    c.save();
    c.translate(hx * s.width, hy);
    final u = s.shortestSide * 0.08;
    c.drawRect(
      Rect.fromLTWH(-u, -u * 1.0, u * 2, u),
      Paint()
        ..shader = ui.Gradient.linear(Offset(-u, 0), Offset(u, 0), const [
          Color(0xFFD9A06A),
          Color(0xFFB87848),
        ]),
    );
    c.drawPath(
      Path()
        ..moveTo(-u * 1.25, -u)
        ..lineTo(0, -u * 1.9)
        ..lineTo(u * 1.25, -u)
        ..close(),
      Paint()..color = const Color(0xFFC25A4A),
    );
    c.drawPath(
      Path()
        ..moveTo(-u * 1.28, -u * 0.98)
        ..lineTo(0, -u * 1.95)
        ..lineTo(u * 1.28, -u * 0.98)
        ..quadraticBezierTo(u * 0.6, -u * 1.15, 0, -u * 1.5)
        ..quadraticBezierTo(-u * 0.6, -u * 1.15, -u * 1.28, -u * 0.98)
        ..close(),
      Paint()..color = Colors.white,
    );
    c.drawRect(
      Rect.fromLTWH(u * 0.55, -u * 2.0, u * 0.3, u * 0.7),
      Paint()..color = const Color(0xFF9A4A3A),
    );
    glow(c, Offset(-u * 0.35, -u * 0.5), u * 1.0, const Color(0xFFFFD27A), 0.6);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-u * 0.35, -u * 0.5),
          width: u * 0.5,
          height: u * 0.5,
        ),
        Radius.circular(u * 0.06),
      ),
      Paint()..color = const Color(0xFFFFE8A8),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(u * 0.5, -u * 0.35),
          width: u * 0.36,
          height: u * 0.7,
        ),
        Radius.circular(u * 0.18),
      ),
      Paint()..color = const Color(0xFF7A4A2A),
    );
    c.restore();
    for (var i = 0; i < 5; i++) {
      final x = rnd.range(0.04, 0.6);
      final y = hillY(x, 0.66, 0.04, phase: 2.0, freq: 1.1) * s.height + 3;
      c.save();
      c.translate(x * s.width, y);
      drawPine(
        c,
        s.shortestSide * rnd.range(0.15, 0.24),
        leaf: const Color(0xFF4A9490),
        snow: Colors.white,
        seed: i + 30,
      );
      c.restore();
    }
    _hills(
      c,
      s,
      0.84,
      0.035,
      const Color(0xFFFFFFFF),
      const Color(0xFFD4E4F6),
      phase: 4,
      freq: 0.9,
    );
  }
}

// Abendrot -------------------------------------------------------------------

class SunsetWorld extends WorldArt {
  const SunsetWorld();
  @override
  String get id => 'sunset';

  static const _clouds = <(double, double, double, double)>[
    (0.15, 0.2, 0.34, 0.7),
    (0.65, 0.12, 0.3, 0.5),
    (0.9, 0.3, 0.26, 0.8),
    (0.4, 0.34, 0.24, 0.6),
  ];

  @override
  void paint(Canvas c, Size s, double t, bool calm) {
    c.drawPicture(layer('back', s, _back));
    _cloudsDrift(
      c,
      s,
      calm ? 0 : t,
      _clouds,
      'sunset',
      top: const Color(0xFFFFE0D0),
      bottom: const Color(0xFFE88AA0),
    );
    c.drawPicture(layer('front', s, _front));
    if (!calm) {
      for (var i = 0; i < 4; i++) {
        final x = ((0.1 + i * 0.12 + t * 0.012) % 1.2 - 0.1) * s.width;
        final y = (0.3 + i * 0.03 + math.sin(t + i) * 0.008) * s.height;
        final flap = math.sin(t * 5 + i) * 3.5;
        c.drawPath(
          Path()
            ..moveTo(x - 9, y + flap)
            ..quadraticBezierTo(x - 3, y - 5, x, y)
            ..quadraticBezierTo(x + 3, y - 5, x + 9, y + flap),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF3A2858),
        );
      }
    }
  }

  static void _back(Canvas c, Size s) {
    _bg(
      c,
      s,
      const [
        Color(0xFF3A2F7A),
        Color(0xFF8A4A92),
        Color(0xFFE5688A),
        Color(0xFFFF9A6A),
        Color(0xFFFFD27F),
      ],
      const [0, 0.25, 0.5, 0.72, 0.88],
    );
    starfield(c, s, count: 40, seed: 3, yMax: 0.3, maxR: 0.004);
    final sun = Offset(s.width * 0.5, s.height * 0.6);
    glow(c, sun, s.shortestSide * 0.9, const Color(0xFFFFC27A), 0.65);
    c.drawCircle(
      sun,
      s.shortestSide * 0.16,
      Paint()
        ..shader = ui.Gradient.radial(
          sun,
          s.shortestSide * 0.18,
          const [Color(0xFFFFFBE0), Color(0xFFFFE066), Color(0xFFFF9A4A)],
          const [0, 0.55, 1],
        ),
    );
    _hills(
      c,
      s,
      0.64,
      0.025,
      const Color(0xFF9A5A92),
      const Color(0xFF7A4284),
      phase: 0.5,
    );
  }

  static void _front(Canvas c, Size s) {
    _hills(
      c,
      s,
      0.72,
      0.03,
      const Color(0xFF6A3A82),
      const Color(0xFF512E70),
      phase: 2.2,
      freq: 1.2,
    );
    final rnd = Rng(28);
    for (var i = 0; i < 9; i++) {
      final x = rnd.range(0.02, 0.98);
      final y = hillY(x, 0.72, 0.03, phase: 2.2, freq: 1.2) * s.height + 2;
      c.save();
      c.translate(x * s.width, y);
      drawPine(
        c,
        s.shortestSide * rnd.range(0.1, 0.18),
        leaf: const Color(0xFF3A2058),
        seed: i,
      );
      c.restore();
    }
    _hills(
      c,
      s,
      0.82,
      0.035,
      const Color(0xFF4A2868),
      const Color(0xFF331A52),
      phase: 4,
      freq: 0.9,
    );
    for (var i = 0; i < 6; i++) {
      final x = rnd.range(0.02, 0.98);
      final y = hillY(x, 0.82, 0.035, phase: 4, freq: 0.9) * s.height + 2;
      c.save();
      c.translate(x * s.width, y);
      drawPine(
        c,
        s.shortestSide * rnd.range(0.14, 0.24),
        leaf: const Color(0xFF2A1646),
        seed: i + 20,
      );
      c.restore();
    }
  }
}
