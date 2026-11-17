import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import 'world_kit.dart';

/// Blumenwiese: Morgensonne, drei Hügelebenen mit Tiefenstaffelung, Bäume, Blumen
/// in verschiedenen Größen, Gräser, langsame Wolken, Schmetterlinge, Pollen.
class MeadowWorld extends WorldArt {
  const MeadowWorld();
  @override
  String get id => 'meadow';

  // Hügelparameter (baseY in Bildhöhe)
  static const _far = (base: 0.56, amp: 0.025, phase: 0.6, freq: 0.9);
  static const _mid = (base: 0.64, amp: 0.035, phase: 2.0, freq: 1.2);
  static const _near = (base: 0.76, amp: 0.045, phase: 4.1, freq: 0.8);

  @override
  void paint(Canvas c, Size s, double t, bool calm) {
    // 1) Himmel + Sonne + ferne Hügel (statisch)
    c.drawPicture(layer('back', s, _back));
    // 2) Wolken (langsam)
    _clouds(c, s, calm ? 0 : t);
    // 3) Sonnenstrahlen (sehr dezent)
    _rays(c, s, calm ? 0 : t);
    // 4) Mittel- und Vordergrund mit Bäumen, Blumen, Gras (statisch)
    c.drawPicture(layer('front', s, _front));
    // 5) Leben: Schmetterlinge, Pollen, wiegende Vordergrundblumen
    if (!calm) {
      _butterflies(c, s, t);
      _pollen(c, s, t);
    }
    _swayFlowers(c, s, calm ? 0 : t);
    // 6) weiche Randabdunklung unten für Lesbarkeit der Bedienelemente
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, s.height * 0.72),
          Offset(0, s.height),
          const [Color(0x00205A28), Color(0x33205A28)],
        ),
    );
  }

  static void _back(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(
      r,
      vgrad(
        r,
        const [
          Color(0xFF6EC0F0),
          Color(0xFFA7DDF6),
          Color(0xFFDDF1E8),
          Color(0xFFFFF0CC),
        ],
        const [0, 0.35, 0.62, 0.8],
      ),
    );
    // Sonne mit Hof
    final sun = Offset(s.width * 0.8, s.height * 0.15);
    final sr = s.shortestSide * 0.075;
    glow(c, sun, s.shortestSide * 0.42, const Color(0xFFFFE9A0), 0.55);
    c.drawCircle(sun, sr * 1.5, Paint()..color = const Color(0x44FFF3C0));
    c.drawCircle(
      sun,
      sr,
      Paint()
        ..shader = ui.Gradient.radial(
          sun + Offset(-sr * 0.3, -sr * 0.3),
          sr * 1.4,
          const [Color(0xFFFFFBE0), Color(0xFFFFE066), Color(0xFFFFC83D)],
          const [0, 0.5, 1],
        ),
    );
    // ferne Hügel (Luftperspektive: bläulich, weich)
    final far = hillPath(
      s,
      _far.base,
      _far.amp,
      phase: _far.phase,
      freq: _far.freq,
    );
    c.drawPath(
      far,
      vgrad(Rect.fromLTWH(0, s.height * 0.5, s.width, s.height * 0.3), const [
        Color(0xFFB4DDC0),
        Color(0xFFA2D3B0),
      ]),
    );
    // winzige Wäldchen und Windmühle in der Ferne
    final rnd = Rng(9);
    for (var i = 0; i < 9; i++) {
      final x = rnd.range(0.04, 0.96);
      final y =
          hillY(x, _far.base, _far.amp, phase: _far.phase, freq: _far.freq) *
              s.height +
          2;
      c.save();
      c.translate(x * s.width, y);
      drawRoundTree(
        c,
        s.shortestSide * rnd.range(0.05, 0.075),
        leaf: const Color(0xFF8CC6A0),
        seed: i + 40,
      );
      c.restore();
    }
    final mx = 0.22;
    final my =
        hillY(mx, _far.base, _far.amp, phase: _far.phase, freq: _far.freq) *
            s.height +
        3;
    c.save();
    c.translate(mx * s.width, my);
    final u = s.shortestSide * 0.06;
    final body = Path()
      ..moveTo(-u * 0.38, 0)
      ..lineTo(-u * 0.22, -u * 1.1)
      ..lineTo(u * 0.22, -u * 1.1)
      ..lineTo(u * 0.38, 0)
      ..close();
    c.drawPath(body, Paint()..color = const Color(0xFFF3E8D4));
    c.drawPath(
      Path()
        ..moveTo(-u * 0.3, -u * 1.1)
        ..lineTo(0, -u * 1.55)
        ..lineTo(u * 0.3, -u * 1.1)
        ..close(),
      Paint()..color = const Color(0xFFC96A4A),
    );
    c.restore();
    // Mittelhügel
    final mid = hillPath(
      s,
      _mid.base,
      _mid.amp,
      phase: _mid.phase,
      freq: _mid.freq,
    );
    c.drawPath(
      mid,
      vgrad(Rect.fromLTWH(0, s.height * 0.55, s.width, s.height * 0.3), const [
        Color(0xFF9ED88A),
        Color(0xFF86C877),
      ]),
    );
    // Dunst am Horizont
    c.drawRect(
      Rect.fromLTWH(0, s.height * 0.48, s.width, s.height * 0.2),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, s.height * 0.48),
          Offset(0, s.height * 0.68),
          const [Color(0x00FFFFFF), Color(0x33FFFFFF), Color(0x00FFFFFF)],
          const [0, 0.5, 1],
        ),
    );
  }

  static void _front(Canvas c, Size s) {
    final rnd = Rng(21);
    // Bäume und Büsche auf dem Mittelhügel
    for (var i = 0; i < 6; i++) {
      final x = 0.08 + i * 0.17 + rnd.range(-0.04, 0.04);
      final y =
          hillY(x, _mid.base, _mid.amp, phase: _mid.phase, freq: _mid.freq) *
              s.height +
          3;
      c.save();
      c.translate(x * s.width, y);
      if (i % 3 == 1) {
        drawBush(c, s.shortestSide * 0.1, leaf: const Color(0xFF5FB35C));
      } else {
        drawRoundTree(
          c,
          s.shortestSide * rnd.range(0.13, 0.18),
          leaf: i.isEven ? const Color(0xFF58AE5A) : const Color(0xFF6BBB5E),
          seed: i + 70,
        );
      }
      c.restore();
    }
    // Vordergrundwiese
    final near = hillPath(
      s,
      _near.base,
      _near.amp,
      phase: _near.phase,
      freq: _near.freq,
    );
    c.drawPath(
      near,
      vgrad(
        Rect.fromLTWH(0, s.height * 0.68, s.width, s.height * 0.32),
        const [Color(0xFF7ACB5E), Color(0xFF5DB04F), Color(0xFF46933F)],
        const [0, 0.5, 1],
      ),
    );
    // Lichtflecken auf der Wiese
    c.save();
    c.clipPath(near);
    for (var i = 0; i < 6; i++) {
      final ctr = Offset(
        rnd.range(0.1, 0.9) * s.width,
        rnd.range(0.74, 0.95) * s.height,
      );
      c.drawOval(
        Rect.fromCenter(
          center: ctr,
          width: s.width * rnd.range(0.2, 0.4),
          height: s.height * 0.03,
        ),
        Paint()..color = const Color(0x1FFFF7B0),
      );
    }
    c.restore();
    drawGrassFringe(
      c,
      s,
      (x) =>
          hillY(x, _near.base, _near.amp, phase: _near.phase, freq: _near.freq),
      a: const Color(0xFF8ADB66),
      b: const Color(0xFF4FA94A),
      count: 320,
      maxH: 0.028,
      seed: 5,
    );
    // Blumen: nach Tiefe sortiert (hinten klein, vorne groß)
    final items = <(double, double, FlowerKind, double, int)>[];
    for (var i = 0; i < 70; i++) {
      final depth = math.pow(rnd.next(), 0.8).toDouble(); // 0 hinten … 1 vorn
      final y = _near.base + 0.03 + depth * 0.2;
      final x = rnd.next();
      items.add((
        x,
        y,
        FlowerKind.values[rnd.next() < 0.18 ? 5 : (rnd.next() * 5).floor()],
        0.4 + depth * 1.0,
        i,
      ));
    }
    items.sort((a, b) => a.$2.compareTo(b.$2));
    for (final f in items) {
      c.save();
      c.translate(f.$1 * s.width, f.$2 * s.height);
      drawFlower(
        c,
        f.$3,
        s.shortestSide * 0.012 * f.$4 * 1.6,
        lean: (rnd.next() - 0.5) * 0.25,
        seed: f.$5,
      );
      c.restore();
    }
  }

  static const _cloudSpecs = <(double, double, double, double)>[
    (0.2, 0.12, 0.34, 0.012),
    (0.62, 0.08, 0.26, 0.008),
    (0.9, 0.24, 0.22, 0.015),
    (0.4, 0.28, 0.18, 0.01),
  ];

  void _clouds(Canvas c, Size s, double t) {
    for (var i = 0; i < _cloudSpecs.length; i++) {
      final sp = _cloudSpecs[i];
      final w = s.shortestSide * sp.$3 * 1.1;
      final x = ((sp.$1 + t * sp.$4 * 0.12) % 1.3 - 0.15) * s.width;
      c.save();
      c.translate(x, sp.$2 * s.height);
      c.drawPicture(
        PictureCache.get(
          'world.meadow.cloud$i.${w.round()}',
          (cc) => drawCloud(cc, w),
        ),
      );
      c.restore();
    }
  }

  void _rays(Canvas c, Size s, double t) {
    final sun = Offset(s.width * 0.8, s.height * 0.15);
    c.save();
    c.translate(sun.dx, sun.dy);
    c.rotate(t * 0.02);
    for (var i = 0; i < 9; i++) {
      c.rotate(2 * math.pi / 9);
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(-s.shortestSide * 0.05, s.height * 0.75)
        ..lineTo(s.shortestSide * 0.05, s.height * 0.75)
        ..close();
      c.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(0, s.height * 0.75),
            const [Color(0x22FFF3B0), Color(0x00FFF3B0)],
          ),
      );
    }
    c.restore();
  }

  void _butterflies(Canvas c, Size s, double t) {
    const cols = [
      (Color(0xFFFF9F43), Color(0xFFFFF0C8)),
      (Color(0xFFFFFFFF), Color(0xFFF4A6C0)),
      (Color(0xFF7BA6FF), Color(0xFFE8F0FF)),
    ];
    for (var i = 0; i < 3; i++) {
      final ph = i * 2.1;
      final x = (0.2 + i * 0.3 + math.sin(t * 0.21 + ph) * 0.14) * s.width;
      final y =
          (0.6 + math.sin(t * 0.33 + ph * 1.3) * 0.06 + i * 0.03) * s.height;
      c.save();
      c.translate(x, y);
      c.rotate(math.cos(t * 0.21 + ph) * 0.35);
      drawButterfly(
        c,
        s.shortestSide * 0.028,
        math.sin(t * 14 + ph),
        cols[i].$1,
        cols[i].$2,
      );
      c.restore();
    }
  }

  void _pollen(Canvas c, Size s, double t) {
    final rnd = Rng(77);
    for (var i = 0; i < 22; i++) {
      final bx = rnd.next(),
          by = rnd.range(0.35, 0.9),
          sp = rnd.range(0.01, 0.03),
          ph = rnd.next() * 6;
      final x = ((bx + t * sp) % 1.0) * s.width;
      final y = (by + math.sin(t * 0.6 + ph) * 0.02) * s.height;
      final a = 0.35 + 0.35 * math.sin(t * 1.4 + ph);
      glow(
        c,
        Offset(x, y),
        s.shortestSide * 0.012,
        const Color(0xFFFFF4B0),
        a.clamp(0.1, 0.7),
      );
    }
  }

  void _swayFlowers(Canvas c, Size s, double t) {
    const kinds = [
      FlowerKind.poppy,
      FlowerKind.daisy,
      FlowerKind.cornflower,
      FlowerKind.tulip,
      FlowerKind.buttercup,
    ];
    final rnd = Rng(5);
    for (var i = 0; i < 5; i++) {
      final x = i < 3
          ? 0.04 + i * 0.07 + rnd.next() * 0.02
          : 0.8 + (i - 3) * 0.1;
      final y = 0.99 - (i % 2) * 0.02;
      c.save();
      c.translate(x * s.width, y * s.height);
      drawFlower(
        c,
        kinds[i],
        s.shortestSide * 0.03,
        lean: math.sin(t * 0.9 + i) * 0.08 + (i < 3 ? 0.05 : -0.05),
        seed: 90 + i,
      );
      c.restore();
    }
  }
}
