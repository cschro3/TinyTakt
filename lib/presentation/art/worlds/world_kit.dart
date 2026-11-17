import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';

/// Eine gemalte Welt. Statische Ebenen werden je Bildschirmgröße einmal aufgenommen
/// (Picture), nur bewegte Details (Wolken, Schmetterlinge, Lichtpunkte) werden pro Bild gezeichnet.
abstract class WorldArt {
  const WorldArt();
  String get id;
  void paint(Canvas c, Size size, double t, bool calm);

  /// Statische Ebene für diese Größe (gecacht).
  ui.Picture layer(
    String name,
    Size size,
    void Function(Canvas c, Size s) draw,
  ) => PictureCache.get(
    'world.$id.$name.${(size.width / 8).round()}x${(size.height / 8).round()}',
    (c) => draw(c, size),
  );
}

/// Hügellinie: Summe weicher Sinuswellen, als glatte Fläche bis zum unteren Rand.
Path hillPath(
  Size s,
  double baseY,
  double amp, {
  double phase = 0,
  double freq = 1.0,
  double tilt = 0,
  double detail = 0.35,
}) {
  final pts = <Offset>[];
  const n = 28;
  for (var i = 0; i <= n; i++) {
    final x = i / n;
    final y =
        baseY +
        math.sin(x * math.pi * 2 * freq + phase) * amp +
        math.sin(x * math.pi * 5 * freq + phase * 1.7) * amp * detail +
        tilt * (x - 0.5);
    pts.add(Offset(x * s.width, y * s.height));
  }
  final path = smoothOpen(pts, tension: 0.9);
  path
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();
  return path;
}

/// y der Hügellinie bei x (0..1) – damit Bäume und Blumen auf der Kante stehen.
double hillY(
  double x,
  double baseY,
  double amp, {
  double phase = 0,
  double freq = 1.0,
  double tilt = 0,
  double detail = 0.35,
}) =>
    baseY +
    math.sin(x * math.pi * 2 * freq + phase) * amp +
    math.sin(x * math.pi * 5 * freq + phase * 1.7) * amp * detail +
    tilt * (x - 0.5);

/// Vertikaler Farbverlauf über [rect].
Paint vgrad(Rect rect, List<Color> colors, [List<double>? stops]) => Paint()
  ..shader = ui.Gradient.linear(
    rect.topCenter,
    rect.bottomCenter,
    colors,
    stops ??
        (colors.length == 2
            ? null
            : [
                for (var i = 0; i < colors.length; i++) i / (colors.length - 1),
              ]),
  );

/// Weiche Wolke aus überlappenden Kugeln mit Licht oben und kühlem Schatten unten.
void drawCloud(
  Canvas c,
  double w, {
  Color top = Colors.white,
  Color bottom = const Color(0xFFD7E6F6),
}) {
  final blobs = <(double, double, double)>[
    (-0.34, 0.06, 0.2),
    (-0.12, -0.08, 0.27),
    (0.14, -0.04, 0.24),
    (0.34, 0.06, 0.19),
    (0.0, 0.1, 0.25),
  ];
  for (final b in blobs) {
    final r = b.$3 * w;
    final ctr = Offset(b.$1 * w, b.$2 * w);
    c.drawCircle(
      ctr,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          ctr + Offset(-r * 0.25, -r * 0.45),
          r * 1.5,
          [top, mix(top, bottom, 0.6), bottom],
          const [0, 0.55, 1],
        ),
    );
  }
}

/// Baum mit gerundeter Krone (mehrere Lichtschichten) und Stamm.
void drawRoundTree(
  Canvas c,
  double h, {
  required Color leaf,
  Color trunk = const Color(0xFF8A5A33),
  int seed = 1,
}) {
  final rnd = Rng(seed);
  // Stamm
  final tw = h * 0.1;
  final trunkPath = Path()
    ..moveTo(-tw, 0)
    ..lineTo(-tw * 0.7, -h * 0.5)
    ..lineTo(tw * 0.7, -h * 0.5)
    ..lineTo(tw, 0)
    ..close();
  c.drawPath(
    trunkPath,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(-tw, 0),
        Offset(tw, 0),
        [shade(trunk, 0.1), trunk, shade(trunk, -0.14)],
        const [0, 0.5, 1],
      ),
  );
  // Krone
  final crown = Offset(0, -h * 0.72);
  final r = h * 0.38;
  final lobes = [
    Offset(-r * 0.55, r * 0.15),
    Offset(r * 0.55, r * 0.2),
    Offset(0, -r * 0.45),
    Offset(-r * 0.35, -r * 0.2),
    Offset(r * 0.4, -r * 0.15),
  ];
  for (final l in lobes) {
    final ctr = crown + l;
    final rr = r * (0.62 + 0.1 * rnd.next());
    c.drawCircle(
      ctr,
      rr,
      Paint()
        ..shader = ui.Gradient.radial(
          ctr + Offset(-rr * 0.35, -rr * 0.45),
          rr * 1.5,
          [shade(leaf, 0.14), leaf, shade(leaf, -0.14)],
          const [0, 0.5, 1],
        ),
    );
  }
  // Lichtflecken
  for (var i = 0; i < 6; i++) {
    final p =
        crown +
        Offset(rnd.range(-r * 0.7, r * 0.5), rnd.range(-r * 0.9, r * 0.1));
    c.drawCircle(
      p,
      r * rnd.range(0.06, 0.12),
      Paint()..color = shade(leaf, 0.2).withValues(alpha: 0.55),
    );
  }
}

/// Busch.
void drawBush(Canvas c, double w, {required Color leaf}) {
  for (final b in <(double, double, double)>[
    (-0.28, 0, 0.26),
    (0.0, -0.08, 0.3),
    (0.28, 0, 0.25),
  ]) {
    final ctr = Offset(b.$1 * w, b.$2 * w);
    final r = b.$3 * w;
    c.drawCircle(
      ctr,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          ctr + Offset(-r * 0.3, -r * 0.5),
          r * 1.4,
          [shade(leaf, 0.12), leaf, shade(leaf, -0.14)],
          const [0, 0.5, 1],
        ),
    );
  }
}

/// Fünf Blumenarten als Sprites; [s] = Blütengröße, Ursprung = Fußpunkt.
enum FlowerKind { daisy, tulip, poppy, cornflower, buttercup, lavender }

void drawFlower(
  Canvas c,
  FlowerKind kind,
  double s, {
  double lean = 0,
  int seed = 1,
  Color stem = const Color(0xFF3F9A4A),
}) {
  final rnd = Rng(seed);
  final h = s * (kind == FlowerKind.lavender ? 3.8 : 3.0 + rnd.next());
  final top = Offset(lean * h, -h);
  final stemPath = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(lean * h * 0.2, -h * 0.5, top.dx, top.dy);
  c.drawPath(
    stemPath,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.16
      ..strokeCap = StrokeCap.round
      ..color = stem,
  );
  // Blätter
  for (final sd in [-1.0, 1.0]) {
    final ly = -h * (0.25 + rnd.next() * 0.15);
    final leaf = Path()
      ..moveTo(0, ly)
      ..quadraticBezierTo(
        sd * s * 0.9,
        ly - s * 0.6,
        sd * s * 1.5,
        ly - s * 0.1,
      )
      ..quadraticBezierTo(sd * s * 0.7, ly + s * 0.05, 0, ly);
    c.drawPath(
      leaf,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, ly), Offset(sd * s * 1.5, ly), [
          shade(stem, 0.1),
          shade(stem, -0.08),
        ]),
    );
  }
  c.save();
  c.translate(top.dx, top.dy);
  switch (kind) {
    case FlowerKind.daisy:
      for (var i = 0; i < 10; i++) {
        final a = i * 2 * math.pi / 10;
        c.save();
        c.rotate(a);
        c.drawOval(
          Rect.fromCenter(
            center: Offset(0, -s * 0.62),
            width: s * 0.42,
            height: s * 0.82,
          ),
          Paint()
            ..shader = ui.Gradient.linear(Offset(0, -s * 0.2), Offset(0, -s), [
              const Color(0xFFF1EEFA),
              Colors.white,
            ]),
        );
        c.restore();
      }
      c.drawCircle(
        Offset.zero,
        s * 0.32,
        Paint()
          ..shader = ui.Gradient.radial(const Offset(-2, -2), s * 0.4, [
            const Color(0xFFFFE680),
            const Color(0xFFF2B01E),
          ]),
      );
    case FlowerKind.tulip:
      final cup = Path()
        ..moveTo(-s * 0.55, -s * 0.2)
        ..quadraticBezierTo(-s * 0.6, s * 0.5, 0, s * 0.55)
        ..quadraticBezierTo(s * 0.6, s * 0.5, s * 0.55, -s * 0.2)
        ..lineTo(s * 0.28, -s * 0.75)
        ..lineTo(0, -s * 0.3)
        ..lineTo(-s * 0.28, -s * 0.75)
        ..close();
      c.drawPath(
        cup,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(-s * 0.5, 0),
            Offset(s * 0.5, 0),
            [
              const Color(0xFFFF7BA5),
              const Color(0xFFE8457C),
              const Color(0xFFB92A5F),
            ],
            const [0, 0.5, 1],
          ),
      );
    case FlowerKind.poppy:
      for (var i = 0; i < 5; i++) {
        c.save();
        c.rotate(i * 2 * math.pi / 5 + 0.3);
        c.drawOval(
          Rect.fromCenter(
            center: Offset(0, -s * 0.45),
            width: s * 0.95,
            height: s * 0.95,
          ),
          Paint()
            ..shader = ui.Gradient.radial(Offset(0, -s * 0.3), s * 0.7, [
              const Color(0xFFFF7A5F),
              const Color(0xFFE23A2E),
            ]),
        );
        c.restore();
      }
      c.drawCircle(
        Offset.zero,
        s * 0.2,
        Paint()..color = const Color(0xFF3A2430),
      );
    case FlowerKind.cornflower:
      for (var i = 0; i < 8; i++) {
        c.save();
        c.rotate(i * 2 * math.pi / 8);
        final p = Path()
          ..moveTo(0, 0)
          ..lineTo(-s * 0.16, -s * 0.8)
          ..lineTo(0, -s * 0.66)
          ..lineTo(s * 0.16, -s * 0.8)
          ..close();
        c.drawPath(
          p,
          Paint()
            ..color = i.isEven
                ? const Color(0xFF5B8CF0)
                : const Color(0xFF7BA6FF),
        );
        c.restore();
      }
      c.drawCircle(
        Offset.zero,
        s * 0.2,
        Paint()..color = const Color(0xFF3A4FA8),
      );
    case FlowerKind.buttercup:
      for (var i = 0; i < 5; i++) {
        c.save();
        c.rotate(i * 2 * math.pi / 5);
        c.drawCircle(
          Offset(0, -s * 0.38),
          s * 0.38,
          Paint()
            ..shader = ui.Gradient.radial(Offset(-2, -s * 0.5), s * 0.6, [
              const Color(0xFFFFF08A),
              const Color(0xFFFFC21E),
            ]),
        );
        c.restore();
      }
      c.drawCircle(
        Offset.zero,
        s * 0.18,
        Paint()..color = const Color(0xFFE59A12),
      );
    case FlowerKind.lavender:
      for (var i = 0; i < 7; i++) {
        final y = -i * s * 0.26 + s * 0.3;
        for (final sd in [-1.0, 1.0]) {
          c.drawOval(
            Rect.fromCenter(
              center: Offset(sd * s * 0.14, y),
              width: s * 0.28,
              height: s * 0.3,
            ),
            Paint()
              ..color = (i.isEven
                  ? const Color(0xFF9B7BE0)
                  : const Color(0xFFB59AF2)),
          );
        }
      }
  }
  c.restore();
}

/// Gräser entlang einer Hügelkante.
void drawGrassFringe(
  Canvas c,
  Size s,
  double Function(double x) edgeY, {
  required Color a,
  required Color b,
  int count = 260,
  double maxH = 0.03,
  int seed = 3,
}) {
  final rnd = Rng(seed);
  for (var i = 0; i < count; i++) {
    final x = rnd.next();
    final y = edgeY(x) * s.height + rnd.range(-2, 6);
    final h = s.height * maxH * rnd.range(0.4, 1.0);
    final lean = rnd.range(-0.5, 0.5) * h;
    final bx = x * s.width;
    final blade = Path()
      ..moveTo(bx - h * 0.09, y)
      ..quadraticBezierTo(bx + lean * 0.4, y - h * 0.6, bx + lean, y - h)
      ..quadraticBezierTo(
        bx + lean * 0.6 + h * 0.05,
        y - h * 0.5,
        bx + h * 0.09,
        y,
      )
      ..close();
    c.drawPath(blade, Paint()..color = mix(a, b, rnd.next()));
  }
}

/// Schmetterling (Flügel schlagen über [flap] −1..1).
void drawButterfly(Canvas c, double size, double flap, Color wing, Color spot) {
  final w = 0.35 + 0.65 * flap.abs();
  c.save();
  for (final sd in [-1.0, 1.0]) {
    c.save();
    c.scale(sd * w, 1);
    final up = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size * 0.9, -size * 1.1, size * 1.05, -size * 0.2)
      ..quadraticBezierTo(size * 0.7, size * 0.1, 0, size * 0.05)
      ..close();
    final lo = Path()
      ..moveTo(0, size * 0.05)
      ..quadraticBezierTo(size * 0.8, size * 0.1, size * 0.6, size * 0.6)
      ..quadraticBezierTo(size * 0.2, size * 0.7, 0, size * 0.2)
      ..close();
    c.drawPath(
      up,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(size, -size * 0.5), [
          shade(wing, 0.1),
          wing,
        ]),
    );
    c.drawPath(lo, Paint()..color = shade(wing, -0.05));
    c.drawCircle(
      Offset(size * 0.62, -size * 0.32),
      size * 0.16,
      Paint()..color = spot,
    );
    c.restore();
  }
  c.drawOval(
    Rect.fromCenter(
      center: Offset(0, size * 0.1),
      width: size * 0.14,
      height: size * 0.75,
    ),
    Paint()..color = const Color(0xFF3A2A40),
  );
  c.restore();
}

/// Kiefer; mit [snow] bekommt jede Etage eine Schneehaube.
void drawPine(
  Canvas c,
  double h, {
  required Color leaf,
  Color? snow,
  int seed = 1,
}) {
  final rnd = Rng(seed);
  c.drawRect(
    Rect.fromLTWH(-h * 0.035, -h * 0.16, h * 0.07, h * 0.16),
    Paint()..color = const Color(0xFF6E4A2C),
  );
  const tiers = 4;
  for (var i = 0; i < tiers; i++) {
    final y0 = -h * (0.12 + i * 0.2);
    final w = h * (0.34 - i * 0.065) * (1 + rnd.next() * 0.06);
    final top = y0 - h * 0.3;
    final tri = Path()
      ..moveTo(0, top)
      ..quadraticBezierTo(w * 0.55, y0 - h * 0.12, w, y0)
      ..quadraticBezierTo(0, y0 + h * 0.04, -w, y0)
      ..quadraticBezierTo(-w * 0.55, y0 - h * 0.12, 0, top)
      ..close();
    c.drawPath(
      tri,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-w, y0),
          Offset(w, y0),
          [shade(leaf, 0.12), leaf, shade(leaf, -0.14)],
          const [0, 0.5, 1],
        ),
    );
    if (snow != null) {
      final cap = Path()
        ..moveTo(0, top)
        ..quadraticBezierTo(w * 0.28, top + h * 0.1, w * 0.52, y0 - h * 0.1)
        ..quadraticBezierTo(w * 0.2, y0 - h * 0.05, 0, y0 - h * 0.12)
        ..quadraticBezierTo(-w * 0.2, y0 - h * 0.05, -w * 0.52, y0 - h * 0.1)
        ..quadraticBezierTo(-w * 0.28, top + h * 0.1, 0, top)
        ..close();
      c.drawPath(cap, Paint()..color = snow);
    }
  }
}

/// Palme mit geschwungenem Stamm und Wedeln.
void drawPalm(Canvas c, double h, {double lean = 0.18, double sway = 0}) {
  final trunk = Path()
    ..moveTo(-h * 0.03, 0)
    ..quadraticBezierTo(h * lean * 0.5, -h * 0.5, h * lean, -h)
    ..lineTo(h * lean + h * 0.03, -h)
    ..quadraticBezierTo(h * lean * 0.5 + h * 0.05, -h * 0.5, h * 0.03, 0)
    ..close();
  c.drawPath(
    trunk,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(-h * 0.05, 0),
        Offset(h * 0.2, 0),
        const [Color(0xFFB88A5A), Color(0xFF9A6C3E), Color(0xFF7A5230)],
        const [0, 0.5, 1],
      ),
  );
  for (var i = 1; i < 9; i++) {
    final y = -h * i / 9;
    final x = h * lean * math.pow(i / 9, 1.4);
    c.drawLine(
      Offset(x - h * 0.03, y),
      Offset(x + h * 0.03, y + h * 0.012),
      Paint()
        ..color = const Color(0x44402810)
        ..strokeWidth = h * 0.012,
    );
  }
  c.save();
  c.translate(h * lean, -h);
  for (var i = 0; i < 7; i++) {
    final a = -math.pi * 0.95 + i * math.pi * 0.9 / 6 + sway;
    c.save();
    c.rotate(a + math.pi / 2);
    final len = h * (0.5 + 0.06 * (i % 2));
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * 0.1, -len * 0.5, len * 0.12, -len)
      ..quadraticBezierTo(-len * 0.03, -len * 0.52, 0, 0)
      ..close();
    c.drawPath(
      leaf,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, -len), const [
          Color(0xFF2F9A50),
          Color(0xFF6CCB6A),
        ]),
    );
    c.restore();
  }
  c.drawCircle(
    const Offset(-6, 6),
    h * 0.03,
    Paint()..color = const Color(0xFF6A4A2A),
  );
  c.drawCircle(
    const Offset(6, 8),
    h * 0.03,
    Paint()..color = const Color(0xFF6A4A2A),
  );
  c.restore();
}

/// Sternenhimmel (deterministisch); Größe und Helligkeit variieren.
void starfield(
  Canvas c,
  Size s, {
  int count = 80,
  int seed = 1,
  double yMax = 0.85,
  double maxR = 0.004,
  Color color = Colors.white,
}) {
  final rnd = Rng(seed);
  for (var i = 0; i < count; i++) {
    final p = Offset(rnd.next() * s.width, rnd.next() * s.height * yMax);
    final r = s.shortestSide * (maxR * 0.35 + maxR * rnd.next());
    c.drawCircle(
      p,
      r,
      Paint()..color = color.withValues(alpha: 0.4 + 0.6 * rnd.next()),
    );
    if (rnd.next() > 0.85) glow(c, p, r * 5, color, 0.35);
  }
}

/// Mond mit Hof, Kratern und Schattierung.
void drawMoon(Canvas c, Offset ctr, double r) {
  glow(c, ctr, r * 3.2, const Color(0xFFFFF0B8), 0.5);
  c.drawCircle(
    ctr,
    r,
    Paint()
      ..shader = ui.Gradient.radial(
        ctr + Offset(-r * 0.3, -r * 0.3),
        r * 1.6,
        const [Color(0xFFFFFBE6), Color(0xFFFFEFB0), Color(0xFFE8D48A)],
        const [0, 0.55, 1],
      ),
  );
  for (final k in <(double, double, double)>[
    (-0.3, -0.2, 0.2),
    (0.3, 0.1, 0.15),
    (-0.1, 0.4, 0.12),
    (0.35, -0.4, 0.1),
  ]) {
    final p = ctr + Offset(k.$1 * r, k.$2 * r);
    c.drawCircle(p, k.$3 * r, Paint()..color = const Color(0x22A89050));
    c.drawCircle(
      p + Offset(-k.$3 * r * 0.15, -k.$3 * r * 0.15),
      k.$3 * r * 0.75,
      Paint()..color = const Color(0x18FFFFFF),
    );
  }
}

/// Planet mit Verlauf, Bändern und optionalem Ring.
void drawPlanet(
  Canvas c,
  Offset ctr,
  double r,
  Color a,
  Color b, {
  bool ring = false,
  double tilt = -0.35,
  List<double> bands = const [],
}) {
  c.save();
  c.translate(ctr.dx, ctr.dy);
  c.rotate(tilt);
  if (ring) {
    c.drawArc(
      Rect.fromCenter(center: Offset.zero, width: r * 3.4, height: r * 0.95),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.22
        ..color = const Color(0xFFE6D5FF).withValues(alpha: 0.85),
    );
  }
  final sphere = Rect.fromCircle(center: Offset.zero, radius: r);
  c.drawCircle(
    Offset.zero,
    r,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(-r * 0.35, -r * 0.4),
        r * 1.7,
        [shade(a, 0.12), a, b],
        const [0, 0.5, 1],
      ),
  );
  c.save();
  c.clipPath(Path()..addOval(sphere));
  for (final y in bands) {
    c.drawRect(
      Rect.fromLTWH(-r, y * r - r * 0.06, r * 2, r * 0.12),
      Paint()..color = shade(a, -0.12).withValues(alpha: 0.45),
    );
  }
  // Terminator: Schatten auf der Nachtseite
  c.drawCircle(
    Offset(r * 0.45, r * 0.4),
    r * 1.15,
    Paint()
      ..color = const Color(0x55100830)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.25),
  );
  c.restore();
  if (ring) {
    c.drawArc(
      Rect.fromCenter(center: Offset.zero, width: r * 3.4, height: r * 0.95),
      0,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.22
        ..color = const Color(0xFFF4EAFF).withValues(alpha: 0.9),
    );
  }
  c.restore();
}

/// Diagonale, sanft schimmernde Lichtstrahlen.
void lightShafts(
  Canvas c,
  Size s,
  double t, {
  required Color color,
  int count = 6,
  double angle = 0.35,
  double alpha = 0.16,
  double seed = 0,
}) {
  for (var i = 0; i < count; i++) {
    final x =
        s.width * (0.08 + i * (0.9 / count)) +
        math.sin(t * 0.2 + i + seed) * s.width * 0.02;
    final w = s.width * (0.05 + 0.03 * ((i * 7) % 3));
    final a = alpha * (0.6 + 0.4 * math.sin(t * 0.5 + i * 1.7 + seed));
    final path = Path()
      ..moveTo(x, 0)
      ..lineTo(x + w, 0)
      ..lineTo(x + w - s.height * angle, s.height * 0.8)
      ..lineTo(x - s.height * angle, s.height * 0.8)
      ..close();
    c.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(x, 0),
          Offset(x - s.height * angle, s.height * 0.8),
          [color.withValues(alpha: a), color.withValues(alpha: 0)],
        ),
    );
  }
}
