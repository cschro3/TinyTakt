import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import '../face.dart';
import '../rig.dart';
import 'premium_figure.dart';

/// Zeno, der Neugierige: kompakter, sandfarbener Fuchs-Löwen-Mix mit wuscheliger Mähne,
/// neugierig geneigtem Kopf, wachen Augen mit Brauen, aufgerichtetem Ringelschwanz.
class ZenoFigure extends PremiumFigure {
  const ZenoFigure();
  @override
  String get id => 'nova_zeno';

  @override
  Personality get personality => const Personality(
    breathRate: 1.9,
    blinkEvery: 3.1,
    tailRate: 2.6,
    tailAmp: 0.6,
    earTwitch: 0.9,
    curiosity: 1.0,
    bounce: 1.1,
    seed: 5,
  );

  static const fur = Color(0xFFD28C50);
  static const furDark = Color(0xFF9A5A2A);
  static const furLight = Color(0xFFF7DDB4);
  static const mane = Color(0xFFB8672E);
  static const maneLight = Color(0xFFE29A56);
  static const _o = Offset(0, -0.12); // Kopfmitte

  static const _face = FaceStyle(
    eyeGap: 0.27,
    eyeY: 0.0,
    eyeRx: 0.12,
    eyeRy: 0.15,
    iris: Color(0xFFE8741E),
    irisLight: Color(0xFFFFC46A),
    lid: fur,
    mouthY: 0.27,
    mouthW: 0.07,
    noseY: 0.16,
    noseW: 0.052,
    noseColor: Color(0xFFD9707A),
    blushY: 0.16,
    blushGap: 0.43,
    blushR: 0.08,
  );

  @override
  void paint(Canvas c, Pose p, double t) {
    c.save();
    c.translate(0, 0.17);
    c.scale(0.8);
    groundShadow(c, p, width: 0.95);
    c.translate(0, p.bodyDy);
    group(
      c,
      const Offset(0, 0.95),
      rot: p.lean,
      sx: 1 + p.squash * 0.35,
      sy: 1 - p.squash * 0.5,
      draw: () {
        // aufgerichteter Ringelschwanz hinter dem Körper
        group(
          c,
          const Offset(0.42, 0.78),
          rot: p.tail * 0.35,
          draw: () => c.drawPicture(PictureCache.get('zeno.tail', _tail)),
        );
        group(
          c,
          const Offset(0, 0.95),
          sy: 1 + p.breath * 0.014,
          draw: () => c.drawPicture(PictureCache.get('zeno.body', _body)),
        );
        _arm(c, p, -1);
        _arm(c, p, 1);
        // Kopf mit Mähne: neugierige Neigung
        group(
          c,
          const Offset(0, 0.3),
          rot: p.headTilt * 1.6 + p.lean * 0.5,
          move: Offset(p.look.dx * 0.01, p.headDy),
          draw: () {
            c.drawPicture(PictureCache.get('zeno.mane', _mane));
            _ear(c, p, -1);
            _ear(c, p, 1);
            c.drawPicture(PictureCache.get('zeno.head', _head));
            c.save();
            c.translate(_o.dx, _o.dy);
            drawFace(c, _face, p);
            _brows(c, p);
            c.restore();
          },
        );
      },
    );
    c.restore();
    sparkles(c, p, t, color: const Color(0xFFFFD27A));
  }

  /// Ausdrucksstarke Brauen: heben sich bei Neugier und Freude.
  void _brows(Canvas c, Pose p) {
    final up =
        (p.eyes == EyeMode.wide ? 0.04 : 0.0) +
        (p.look.dy < 0 ? 0.015 : 0) +
        math.max(0, -p.look.dx * 0.0);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.024
      ..color = furDark;
    for (final sx in [-1.0, 1.0]) {
      final x = sx * 0.27;
      final tilt = sx > 0 ? -p.look.dx * 0.01 : p.look.dx * 0.01;
      c.drawPath(
        Path()
          ..moveTo(x - 0.1, -0.17 - up + tilt * 2)
          ..quadraticBezierTo(
            x,
            -0.24 - up - 0.02 * (sx > 0 ? 1 : 0),
            x + 0.1,
            -0.17 - up - tilt * 2,
          ),
        paint,
      );
    }
  }

  void _arm(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.armL : p.armR;
    group(
      c,
      Offset(side * 0.28, 0.4),
      rot: (side < 0 ? -rot : rot) * 1.3,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('zeno.arm', _armPic));
        c.restore();
      },
    );
  }

  void _ear(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.earL : p.earR;
    group(
      c,
      Offset(side * 0.36, _o.dy - 0.4),
      rot: (side < 0 ? -rot : rot) * 1.4,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('zeno.ear', _earPic));
        c.restore();
      },
    );
  }

  static void _tail(Canvas c) {
    // Ringelschwanz: geschwungener Körper, dunkle Ringe, buschige Spitze
    final shape = smoothClosed(const [
      Offset(0.42, 0.9),
      Offset(0.66, 0.92),
      Offset(0.84, 0.76),
      Offset(0.9, 0.5),
      Offset(0.84, 0.22),
      Offset(0.7, 0.04),
      Offset(0.6, 0.12),
      Offset(0.7, 0.3),
      Offset(0.7, 0.52),
      Offset(0.6, 0.7),
      Offset(0.45, 0.76),
    ], tension: 0.55);
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => -math.pi / 2,
      fur: 140,
      seed: 71,
      fringe: 0.045,
    );
    c.save();
    c.clipPath(shape);
    for (var i = 0; i < 4; i++) {
      final y = 0.7 - i * 0.17;
      c.drawPath(
        Path()
          ..moveTo(0.4, y + 0.04)
          ..quadraticBezierTo(0.78, y - 0.06, 1.0, y + 0.02),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.045
          ..color = furDark.withValues(alpha: 0.45),
      );
    }
    c.restore();
    final tip = smoothClosed(const [
      Offset(0.58, 0.14),
      Offset(0.66, 0.02),
      Offset(0.76, 0.06),
      Offset(0.74, 0.18),
      Offset(0.66, 0.26),
    ]);
    plush(c, tip, maneLight, fur: 40, seed: 72, fringe: 0.05, light: furLight);
  }

  static void _body(Canvas c) {
    final shape = smoothClosed(const [
      Offset(0, 0.14),
      Offset(0.27, 0.16),
      Offset(0.45, 0.34),
      Offset(0.52, 0.6),
      Offset(0.42, 0.86),
      Offset(0.2, 0.97),
      Offset(0, 0.98),
      Offset(-0.2, 0.97),
      Offset(-0.42, 0.86),
      Offset(-0.52, 0.6),
      Offset(-0.45, 0.34),
      Offset(-0.27, 0.16),
    ]);
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => math.pi / 2 + p.dx * 0.8,
      fur: 300,
      seed: 81,
      fringe: 0.045,
      skipFringe: (p) => p.dy < 0.22 || p.dy > 0.92,
    );
    // heller Bauch mit Fellrichtung
    final belly = smoothClosed(const [
      Offset(0, 0.36),
      Offset(0.18, 0.42),
      Offset(0.27, 0.62),
      Offset(0.2, 0.86),
      Offset(0, 0.93),
      Offset(-0.2, 0.86),
      Offset(-0.27, 0.62),
      Offset(-0.18, 0.42),
    ]);
    c.save();
    c.clipPath(shape);
    plush(
      c,
      belly,
      furLight,
      light: Colors.white,
      dark: mix(furLight, fur, 0.5),
      flow: (p) => math.pi / 2 + p.dx * 1.2,
      fur: 120,
      seed: 82,
      fringe: 0,
      lightAmt: 0.04,
      shadowAmt: 0.08,
    );
    c.restore();
    softShadow(
      c,
      ellipsePath(0, 0.15, 0.36, 0.1),
      offset: const Offset(0, 0.05),
      blur: 0.05,
      color: const Color(0x66703A18),
      clip: shape,
    );
    for (final sx in [-1.0, 1.0]) {
      final foot = smoothClosed([
        Offset(sx * 0.08, 0.93),
        Offset(sx * 0.2, 0.89),
        Offset(sx * 0.34, 0.92),
        Offset(sx * 0.36, 1.0),
        Offset(sx * 0.2, 1.03),
        Offset(sx * 0.07, 1.0),
      ]);
      fillVolume(c, foot, furLight, light: 0.05, shadow: 0.12);
    }
  }

  static void _armPic(Canvas c) {
    final arm = smoothClosed(const [
      Offset(0.22, 0.36),
      Offset(0.36, 0.38),
      Offset(0.42, 0.54),
      Offset(0.42, 0.7),
      Offset(0.35, 0.78),
      Offset(0.24, 0.76),
      Offset(0.2, 0.6),
    ]);
    plush(
      c,
      arm,
      mix(fur, furLight, 0.1),
      light: furLight,
      dark: furDark,
      flow: (p) => math.pi / 2,
      fur: 60,
      seed: 91,
      fringe: 0.03,
      skipFringe: (p) => p.dy < 0.42,
    );
    final paw = smoothClosed(const [
      Offset(0.22, 0.69),
      Offset(0.31, 0.66),
      Offset(0.42, 0.69),
      Offset(0.44, 0.79),
      Offset(0.34, 0.85),
      Offset(0.23, 0.8),
    ]);
    fillVolume(c, paw, furLight, light: 0.05, shadow: 0.1);
    toeLines(
      c,
      const Offset(0.33, 0.77),
      0.08,
      furDark.withValues(alpha: 0.35),
    );
  }

  static void _earPic(Canvas c) {
    final o = _o;
    final ear = smoothClosed([
      o + const Offset(0.18, -0.4),
      o + const Offset(0.28, -0.56),
      o + const Offset(0.42, -0.62),
      o + const Offset(0.58, -0.5),
      o + const Offset(0.6, -0.3),
      o + const Offset(0.5, -0.18),
    ], tension: 0.6);
    plush(
      c,
      ear,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => -math.pi / 2,
      fur: 50,
      seed: 61,
      fringe: 0.035,
    );
    final inner = smoothClosed([
      o + const Offset(0.28, -0.4),
      o + const Offset(0.36, -0.5),
      o + const Offset(0.46, -0.52),
      o + const Offset(0.54, -0.42),
      o + const Offset(0.52, -0.3),
      o + const Offset(0.42, -0.26),
    ]);
    fillVolume(c, inner, const Color(0xFFF2B496), light: 0.06, shadow: 0.1);
    // Ohrbüschel
    final tuft = smoothClosed([
      o + const Offset(0.43, -0.58),
      o + const Offset(0.48, -0.7),
      o + const Offset(0.56, -0.62),
      o + const Offset(0.52, -0.5),
    ], tension: 0.7);
    plush(
      c,
      tuft,
      maneLight,
      light: furLight,
      fur: 0,
      fringe: 0.03,
      lightAmt: 0.08,
      shadowAmt: 0.1,
    );
  }

  static void _mane(Canvas c) {
    // wuschelige Mähne: viele weiche Büschel hinter dem Kopf
    final rnd = Rng(123);
    for (var layer = 0; layer < 2; layer++) {
      final n = layer == 0 ? 15 : 12;
      for (var i = 0; i < n; i++) {
        final a =
            math.pi * 0.95 +
            (i + 0.5) * (math.pi * 1.1 / n) +
            (layer == 1 ? 0.1 : 0);
        final r0 = 0.5;
        final r1 = (layer == 0 ? 0.88 : 0.74) + rnd.range(-0.05, 0.07);
        final base =
            _o + Offset(math.cos(a) * r0, math.sin(a) * r0 * 0.9 + 0.1);
        final tip =
            _o + Offset(math.cos(a) * r1, math.sin(a) * r1 * 0.95 + 0.1);
        final side =
            Offset(-math.sin(a), math.cos(a)) * (layer == 0 ? 0.11 : 0.09);
        final path = Path()
          ..moveTo(base.dx + side.dx, base.dy + side.dy)
          ..cubicTo(
            base.dx + side.dx * 1.6 + (tip.dx - base.dx) * 0.5,
            base.dy + side.dy * 1.6 + (tip.dy - base.dy) * 0.5,
            tip.dx + side.dx * 0.5,
            tip.dy + side.dy * 0.5,
            tip.dx,
            tip.dy,
          )
          ..cubicTo(
            tip.dx - side.dx * 0.5,
            tip.dy - side.dy * 0.5,
            base.dx - side.dx * 1.6 + (tip.dx - base.dx) * 0.5,
            base.dy - side.dy * 1.6 + (tip.dy - base.dy) * 0.5,
            base.dx - side.dx,
            base.dy - side.dy,
          )
          ..close();
        c.drawPath(
          path,
          Paint()
            ..shader = ui.Gradient.linear(base, tip, [
              layer == 0 ? mane : maneLight,
              layer == 0 ? shade(mane, 0.12) : shade(maneLight, 0.12),
            ]),
        );
        c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.006
            ..color = shade(mane, -0.16).withValues(alpha: 0.4),
        );
      }
    }
  }

  static void _head(Canvas c) {
    final o = _o;
    final shape = smoothClosed([
      o + const Offset(0, -0.52),
      o + const Offset(0.3, -0.48),
      o + const Offset(0.52, -0.3),
      o + const Offset(0.62, 0.0),
      o + const Offset(0.58, 0.26),
      o + const Offset(0.38, 0.42),
      o + const Offset(0.14, 0.48),
      o + const Offset(0, 0.49),
      o + const Offset(-0.14, 0.48),
      o + const Offset(-0.38, 0.42),
      o + const Offset(-0.58, 0.26),
      o + const Offset(-0.62, 0.0),
      o + const Offset(-0.52, -0.3),
      o + const Offset(-0.3, -0.48),
    ]);
    softShadow(
      c,
      shape,
      offset: const Offset(0, 0.04),
      blur: 0.04,
      color: const Color(0x66703A18),
    );
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      fur: 380,
      seed: 51,
      fringe: 0.065,
      fringeSpacing: 0.04,
      fringeWidth: 0.07,
      skipFringe: (p) =>
          p.dy < o.dy - 0.4 || (p.dy > o.dy + 0.42 && p.dx.abs() < 0.3),
    );
    // helle Schnauzenpartie
    final muzzle = smoothClosed([
      o + const Offset(0, 0.0),
      o + const Offset(0.2, 0.08),
      o + const Offset(0.36, 0.24),
      o + const Offset(0.24, 0.42),
      o + const Offset(0, 0.46),
      o + const Offset(-0.24, 0.42),
      o + const Offset(-0.36, 0.24),
      o + const Offset(-0.2, 0.08),
    ]);
    c.save();
    c.clipPath(shape);
    plush(
      c,
      muzzle,
      furLight,
      light: Colors.white,
      dark: mix(furLight, fur, 0.5),
      fur: 160,
      seed: 52,
      fringe: 0.03,
      lightAmt: 0.04,
      shadowAmt: 0.1,
      skipFringe: (p) => p.dy < o.dy + 0.1,
    );
    c.restore();
    // Stirnschopf
    for (var i = -2; i <= 2; i++) {
      final base = o + Offset(i * 0.085, -0.46);
      final tip =
          o + Offset(i * 0.12 + (i == 0 ? 0 : i * 0.02), -0.7 + i.abs() * 0.05);
      final path = Path()
        ..moveTo(base.dx - 0.05, base.dy)
        ..quadraticBezierTo(
          (base.dx + tip.dx) / 2 - 0.04,
          (base.dy + tip.dy) / 2,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          (base.dx + tip.dx) / 2 + 0.05,
          (base.dy + tip.dy) / 2,
          base.dx + 0.05,
          base.dy,
        )
        ..close();
      c.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(base, tip, [
            fur,
            shade(maneLight, 0.1),
          ]),
      );
    }
    softHighlight(
      c,
      shape,
      o + const Offset(-0.24, -0.32),
      0.26,
      0.1,
      alpha: 0.22,
      rot: -0.4,
    );
    for (final sx in [-1.0, 1.0]) {
      for (var k = 0; k < 3; k++) {
        c.drawCircle(
          o + Offset(sx * (0.16 + k * 0.05), 0.25 + k * 0.03),
          0.009,
          Paint()..color = furDark.withValues(alpha: 0.4),
        );
      }
    }
  }
}
