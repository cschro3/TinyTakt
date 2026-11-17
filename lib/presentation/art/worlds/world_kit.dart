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
    stops,
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
