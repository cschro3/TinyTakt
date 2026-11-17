import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import '../face.dart';
import '../rig.dart';
import 'premium_figure.dart';

/// Hamster Krümel: kugelrund, kein sichtbarer Hals, dicke Backen (pusten sich auf),
/// winzige Ohren, Perlenaugen und ein Sonnenblumenkern in den Pfötchen.
class HamsterFigure extends PremiumFigure {
  const HamsterFigure();
  @override
  String get id => 'hamster';

  @override
  Personality get personality => const Personality(
    breathRate: 2.8,
    breathDepth: 1.2,
    blinkEvery: 3.4,
    tailRate: 1.0,
    tailAmp: 0.1,
    earTwitch: 1.2,
    curiosity: 0.7,
    bounce: 1.2,
    seed: 7,
  );

  static const fur = Color(0xFFE9B76B);
  static const furDark = Color(0xFFB07A32);
  static const furLight = Color(0xFFFFF0D2);
  static const patch = Color(0xFFC98A44);
  static const pink = Color(0xFFF6A8B4);

  static const _face = FaceStyle(
    eyeGap: 0.27,
    eyeY: -0.16,
    eyeRx: 0.098,
    eyeRy: 0.118,
    iris: Color(0xFF3A2418),
    irisLight: Color(0xFF8A5A3A),
    eyeBase: Color(0xFF1A1220),
    lid: fur,
    mouthY: 0.12,
    mouthW: 0.06,
    noseY: 0.04,
    noseW: 0.04,
    noseColor: pink,
    blushY: -0.02,
    blushGap: 0.5,
    blushR: 0.1,
    blush: Color(0xFFFF9AA2),
  );

  @override
  void paint(Canvas c, Pose p, double t) {
    c.save();
    c.translate(0, 0.18);
    c.scale(0.82);
    groundShadow(c, p, width: 1.1);
    c.translate(0, p.bodyDy);
    group(
      c,
      const Offset(0, 0.95),
      rot: p.lean,
      sx: 1 + p.squash * 0.45,
      sy: 1 - p.squash * 0.6,
      draw: () {
        // kleine Ohren sitzen hinter dem Körper und ragen oben über den Rand
        for (final sx in [-1.0, 1.0]) {
          final rot = sx < 0 ? p.earL : p.earR;
          group(
            c,
            Offset(sx * 0.46, -0.46),
            rot: (sx < 0 ? -rot : rot) * 1.4,
            draw: () {
              c.save();
              if (sx < 0) c.scale(-1, 1);
              c.drawPicture(PictureCache.get('hamster.ear', _earPic));
              c.restore();
            },
          );
        }
        final puff = 1 + p.breath * 0.014 + (p.eyes == EyeMode.wide ? 0.02 : 0);
        group(
          c,
          const Offset(0, 0.95),
          sx: puff,
          sy: puff,
          draw: () => c.drawPicture(PictureCache.get('hamster.body', _body)),
        );
        // Backen pusten sich bei Freude auf
        final cheek =
            1 +
            p.cheek * 0.1 +
            (p.mouth == MouthShape.open || p.mouth == MouthShape.grin
                ? 0.05
                : 0);
        for (final sx in [-1.0, 1.0]) {
          group(
            c,
            Offset(sx * 0.5, 0.14),
            sx: cheek,
            sy: cheek,
            draw: () {
              c.save();
              if (sx < 0) c.scale(-1, 1);
              c.drawPicture(PictureCache.get('hamster.cheek', _cheekPic));
              c.restore();
            },
          );
        }
        c.drawPicture(PictureCache.get('hamster.face', _faceBase));
        c.save();
        group(
          c,
          const Offset(0, 0),
          rot: p.headTilt * 0.6,
          draw: () {
            drawFace(c, _face, p);
            _whiskers(c);
            // Schneidezähnchen bei Freude
            if (p.mouth == MouthShape.open || p.mouth == MouthShape.grin) {
              final r = RRect.fromRectAndRadius(
                const Rect.fromLTWH(-0.025, 0.145, 0.05, 0.04),
                const Radius.circular(0.01),
              );
              c.drawRRect(r, Paint()..color = Colors.white);
            }
          },
        );
        c.restore();
        // Pfötchen mit Kern
        _arm(c, p, -1);
        _arm(c, p, 1);
        c.drawPicture(PictureCache.get('hamster.seed', _seed));
      },
    );
    c.restore();
    sparkles(c, p, t, color: const Color(0xFFFFE6A0));
  }

  void _whiskers(Canvas c) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.007
      ..color = Colors.white.withValues(alpha: 0.9);
    for (final sx in [-1.0, 1.0]) {
      for (var k = 0; k < 3; k++) {
        c.drawPath(
          Path()
            ..moveTo(sx * 0.14, 0.06 + k * 0.03)
            ..quadraticBezierTo(
              sx * 0.34,
              0.02 + k * 0.05,
              sx * 0.52,
              0.0 + k * 0.08,
            ),
          paint,
        );
      }
    }
  }

  void _arm(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.armL : p.armR;
    group(
      c,
      Offset(side * 0.2, 0.45),
      rot: (side < 0 ? -rot : rot) * 1.1,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('hamster.arm', _armPic));
        c.restore();
      },
    );
  }

  static void _body(Canvas c) {
    // kugeliger Körper (Kopf und Körper verschmolzen)
    final shape = smoothClosed(const [
      Offset(0, -0.58),
      Offset(0.34, -0.54),
      Offset(0.58, -0.32),
      Offset(0.7, 0.04),
      Offset(0.7, 0.44),
      Offset(0.56, 0.8),
      Offset(0.28, 0.97),
      Offset(0, 1.0),
      Offset(-0.28, 0.97),
      Offset(-0.56, 0.8),
      Offset(-0.7, 0.44),
      Offset(-0.7, 0.04),
      Offset(-0.58, -0.32),
      Offset(-0.34, -0.54),
    ]);
    softShadow(
      c,
      shape,
      offset: const Offset(0, 0.04),
      blur: 0.04,
      color: const Color(0x66704A18),
    );
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => math.atan2(p.dy + 0.1, p.dx),
      fur: 460,
      furLen: 0.075,
      seed: 81,
      fringe: 0.055,
      fringeSpacing: 0.04,
      fringeWidth: 0.07,
      skipFringe: (p) => p.dy > 0.93,
    );
    // dunkle Rückenzeichnung (Haube) und heller Bauch
    final cap = smoothClosed(const [
      Offset(-0.3, -0.5),
      Offset(-0.12, -0.58),
      Offset(0.12, -0.58),
      Offset(0.3, -0.5),
      Offset(0.22, -0.34),
      Offset(0.0, -0.4),
      Offset(-0.22, -0.34),
    ], tension: 0.6);
    c.save();
    c.clipPath(shape);
    plush(
      c,
      cap,
      patch,
      light: shade(patch, 0.2),
      dark: shade(patch, -0.1),
      fur: 120,
      seed: 82,
      fringe: 0,
      lightAmt: 0.04,
      shadowAmt: 0.08,
    );
    final belly = smoothClosed(const [
      Offset(0, 0.28),
      Offset(0.34, 0.38),
      Offset(0.44, 0.66),
      Offset(0.26, 0.92),
      Offset(0, 0.98),
      Offset(-0.26, 0.92),
      Offset(-0.44, 0.66),
      Offset(-0.34, 0.38),
    ]);
    plush(
      c,
      belly,
      furLight,
      light: Colors.white,
      dark: mix(furLight, fur, 0.45),
      flow: (p) => math.pi / 2,
      fur: 140,
      seed: 83,
      fringe: 0,
      lightAmt: 0.03,
      shadowAmt: 0.07,
    );
    c.restore();
    // Füßchen
    for (final sx in [-1.0, 1.0]) {
      final foot = smoothClosed([
        Offset(sx * 0.1, 0.94),
        Offset(sx * 0.24, 0.9),
        Offset(sx * 0.4, 0.94),
        Offset(sx * 0.42, 1.02),
        Offset(sx * 0.24, 1.05),
        Offset(sx * 0.09, 1.02),
      ]);
      fillVolume(c, foot, pink, light: 0.06, shadow: 0.12);
    }
  }

  static void _cheekPic(Canvas c) {
    final shape = ellipsePath(0.5, 0.14, 0.24, 0.22);
    c.save();
    plush(
      c,
      shape,
      mix(fur, furLight, 0.3),
      light: furLight,
      dark: furDark,
      fur: 80,
      seed: 85,
      fringe: 0.05,
      fringeSpacing: 0.04,
      fringeWidth: 0.07,
      lightAmt: 0.06,
      shadowAmt: 0.1,
      fringeTip: furLight,
    );
    c.restore();
  }

  static void _earPic(Canvas c) {
    final ear = ellipsePath(0.46, -0.56, 0.13, 0.15);
    plush(
      c,
      ear,
      fur,
      light: furLight,
      dark: furDark,
      fur: 20,
      seed: 61,
      fringe: 0.02,
    );
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(0.06, -0.05),
        width: 0.12,
        height: 0.14,
      ),
      Paint()
        ..shader = ui.Gradient.radial(const Offset(0.06, -0.05), 0.09, const [
          Color(0xFFFFC8D2),
          pink,
        ]),
    );
  }

  static void _faceBase(Canvas c) {
    // helle Schnauzenpartie
    final muzzle = smoothClosed(const [
      Offset(0, -0.02),
      Offset(0.2, 0.0),
      Offset(0.34, 0.12),
      Offset(0.3, 0.3),
      Offset(0.12, 0.38),
      Offset(0, 0.4),
      Offset(-0.12, 0.38),
      Offset(-0.3, 0.3),
      Offset(-0.34, 0.12),
      Offset(-0.2, 0.0),
    ], tension: 0.6);
    plush(
      c,
      muzzle,
      furLight,
      light: Colors.white,
      dark: mix(furLight, fur, 0.4),
      fur: 90,
      seed: 52,
      fringe: 0.02,
      lightAmt: 0.03,
      shadowAmt: 0.07,
      skipFringe: (p) => p.dy < 0.1,
    );
    softHighlight(
      c,
      ellipsePath(0, -0.2, 0.6, 0.4),
      const Offset(-0.25, -0.42),
      0.26,
      0.09,
      alpha: 0.3,
      rot: -0.4,
    );
  }

  static void _armPic(Canvas c) {
    final arm = smoothClosed(const [
      Offset(0.1, 0.46),
      Offset(0.22, 0.48),
      Offset(0.28, 0.6),
      Offset(0.26, 0.72),
      Offset(0.18, 0.76),
      Offset(0.1, 0.7),
    ]);
    plush(
      c,
      arm,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => math.pi / 2,
      fur: 30,
      seed: 91,
      fringe: 0.02,
      skipFringe: (p) => p.dy < 0.54,
    );
    final paw = ellipsePath(0.19, 0.7, 0.09, 0.07);
    fillVolume(c, paw, pink, light: 0.06, shadow: 0.1);
  }

  static void _seed(Canvas c) {
    c.save();
    c.translate(0.0, 0.62);
    c.rotate(-0.3);
    final r = Rect.fromCenter(center: Offset.zero, width: 0.16, height: 0.3);
    final seed = Path()..addOval(r);
    c.drawPath(
      seed,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-0.08, 0),
          const Offset(0.08, 0),
          const [
            Color(0xFF6A5A4A),
            Color(0xFFE9E1D6),
            Color(0xFFF7F2EA),
            Color(0xFF3A3028),
          ],
          const [0, 0.3, 0.6, 1],
        ),
    );
    c.save();
    c.clipPath(seed);
    for (final x in [-0.05, 0.0, 0.05]) {
      c.drawLine(
        Offset(x, -0.15),
        Offset(x * 0.8, 0.15),
        Paint()
          ..color = const Color(0x55302018)
          ..strokeWidth = 0.01,
      );
    }
    c.restore();
    c.restore();
  }
}
