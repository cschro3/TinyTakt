import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import '../face.dart';
import '../rig.dart';
import 'premium_figure.dart';

/// Schaf Wolle: wolkige Lockenwolle (jede Locke einzeln modelliert), dunkles Gesicht,
/// seitlich abstehende Ohren, Woll-Schopf und kleine Beine.
class SheepFigure extends PremiumFigure {
  const SheepFigure();
  @override
  String get id => 'sheep';

  @override
  Personality get personality => const Personality(
    breathRate: 1.4,
    breathDepth: 1.4,
    blinkEvery: 4.0,
    tailRate: 1.8,
    tailAmp: 0.3,
    earTwitch: 1.0,
    curiosity: 0.2,
    bounce: 1.1,
    seed: 12,
  );

  static const wool = Color(0xFFFCF9F3);
  static const woolShadow = Color(0xFFD9CDBD);
  static const faceC = Color(0xFF5D4E5C);
  static const faceLight = Color(0xFF8D7A8B);
  static const _o = Offset(0, -0.02);

  static const _face = FaceStyle(
    eyeGap: 0.22,
    eyeY: -0.08,
    eyeRx: 0.085,
    eyeRy: 0.1,
    iris: Color(0xFF3A2A28),
    irisLight: Color(0xFF8A6A58),
    eyeBase: Color(0xFFFFFFFF),
    sclera: true,
    lid: faceC,
    lashes: true,
    mouthY: 0.26,
    mouthW: 0.07,
    noseY: 0.17,
    noseW: 0.042,
    noseColor: Color(0xFFC8869A),
    blushY: 0.14,
    blushGap: 0.34,
    blushR: 0.065,
    ink: Color(0xFF241C26),
  );

  @override
  void paint(Canvas c, Pose p, double t) {
    c.save();
    c.translate(0, 0.02);
    c.scale(0.74);
    groundShadow(c, p, width: 1.25);
    c.translate(0, p.bodyDy);
    group(
      c,
      const Offset(0, 0.95),
      rot: p.lean,
      sx: 1 + p.squash * 0.4,
      sy: 1 - p.squash * 0.55,
      draw: () {
        // Beine hinter der Wolle
        c.drawPicture(PictureCache.get('sheep.legs', _legs));
        // Wolle atmet sichtbar (Locken bauschen sich)
        final puff = 1 + p.breath * 0.025;
        group(
          c,
          const Offset(0, 0.5),
          sx: puff,
          sy: puff,
          draw: () => c.drawPicture(PictureCache.get('sheep.wool', _woolBody)),
        );
        group(
          c,
          const Offset(0, 0.2),
          rot: p.headTilt * 1.1 + p.lean * 0.5,
          move: Offset(0, p.headDy),
          draw: () {
            _ear(c, p, -1);
            _ear(c, p, 1);
            c.drawPicture(PictureCache.get('sheep.head', _head));
            c.save();
            c.translate(_o.dx, _o.dy);
            drawFace(c, _face, p);
            c.restore();
            c.drawPicture(PictureCache.get('sheep.tuft', _tuft));
          },
        );
      },
    );
    c.restore();
    sparkles(c, p, t, color: const Color(0xFFFFE6A0));
  }

  void _ear(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.earL : p.earR;
    group(
      c,
      Offset(side * 0.38, _o.dy - 0.06),
      rot: (side < 0 ? -rot : rot) * 1.4 + side * 0.04,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('sheep.ear', _earPic));
        c.restore();
      },
    );
  }

  static void _legs(Canvas c) {
    for (final sx in [-1.0, 1.0]) {
      final leg = smoothClosed([
        Offset(sx * 0.14, 0.82),
        Offset(sx * 0.3, 0.82),
        Offset(sx * 0.32, 1.0),
        Offset(sx * 0.3, 1.06),
        Offset(sx * 0.14, 1.06),
        Offset(sx * 0.12, 0.96),
      ], tension: 0.5);
      plush(
        c,
        leg,
        faceC,
        light: faceLight,
        dark: shade(faceC, -0.12),
        fur: 30,
        seed: 95,
        fringe: 0,
        lightAmt: 0.08,
        shadowAmt: 0.12,
        furAlpha: 0.2,
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(sx * 0.23, 1.065),
          width: 0.2,
          height: 0.06,
        ),
        Paint()..color = const Color(0xFF2E2430),
      );
    }
  }

  /// Eine einzelne Wolllocke: Kugel mit Verlauf und eingerollter Spirale.
  static void _curl(Canvas c, Offset ctr, double r, int seed) {
    c.drawCircle(
      ctr,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          ctr + Offset(-r * 0.35, -r * 0.45),
          r * 1.5,
          [Colors.white, wool, woolShadow],
          const [0, 0.5, 1],
        ),
    );
    final rnd = Rng(seed);
    final a0 = rnd.range(0, math.pi * 2);
    final spiral = Path();
    for (var i = 0; i <= 18; i++) {
      final a = a0 + i / 18 * math.pi * 2.6;
      final rr = r * (0.2 + 0.55 * (i / 18));
      final pt = ctr + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? spiral.moveTo(pt.dx, pt.dy) : spiral.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(
      spiral,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.09
        ..strokeCap = StrokeCap.round
        ..color = woolShadow.withValues(alpha: 0.75),
    );
  }

  static void _woolBody(Canvas c) {
    final rnd = Rng(8);
    // von hinten nach vorn: äußerer Ring, dann innere Locken
    final outer = <Offset>[];
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2;
      outer.add(Offset(math.cos(a) * 0.62, 0.48 + math.sin(a) * 0.48));
    }
    for (var i = 0; i < outer.length; i++) {
      _curl(c, outer[i], 0.2 + rnd.range(-0.02, 0.03), i + 1);
    }
    final inner = <Offset>[];
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * math.pi * 2 + 0.3;
      inner.add(Offset(math.cos(a) * 0.38, 0.5 + math.sin(a) * 0.3));
    }
    for (var i = 0; i < inner.length; i++) {
      _curl(c, inner[i], 0.2, i + 40);
    }
    _curl(c, const Offset(0, 0.5), 0.24, 77);
    // weicher Schatten unter dem Kopf
    softShadow(
      c,
      ellipsePath(0, 0.18, 0.4, 0.14),
      offset: const Offset(0, 0.06),
      blur: 0.05,
      color: const Color(0x55705A48),
    );
  }

  static void _earPic(Canvas c) {
    final o = _o;
    final ear = smoothClosed([
      o + const Offset(0.3, -0.12),
      o + const Offset(0.5, -0.2),
      o + const Offset(0.74, -0.14),
      o + const Offset(0.78, 0.0),
      o + const Offset(0.56, 0.08),
      o + const Offset(0.34, 0.04),
    ], tension: 0.55);
    plush(
      c,
      ear,
      faceC,
      light: faceLight,
      dark: shade(faceC, -0.1),
      flow: (p) => 0,
      fur: 30,
      seed: 61,
      fringe: 0,
      lightAmt: 0.08,
      shadowAmt: 0.12,
      furAlpha: 0.2,
    );
    final inner = smoothClosed([
      o + const Offset(0.4, -0.1),
      o + const Offset(0.54, -0.15),
      o + const Offset(0.68, -0.1),
      o + const Offset(0.64, -0.02),
      o + const Offset(0.46, 0.0),
    ], tension: 0.55);
    c.drawPath(
      inner,
      Paint()
        ..shader = ui.Gradient.linear(
          o + const Offset(0.4, -0.05),
          o + const Offset(0.68, -0.05),
          const [Color(0xFFE2A8B8), Color(0xFFC8869A)],
        ),
    );
  }

  static void _head(Canvas c) {
    final o = _o;
    final shape = smoothClosed([
      o + const Offset(0, -0.4),
      o + const Offset(0.22, -0.38),
      o + const Offset(0.38, -0.22),
      o + const Offset(0.4, 0.04),
      o + const Offset(0.32, 0.28),
      o + const Offset(0.16, 0.42),
      o + const Offset(0, 0.45),
      o + const Offset(-0.16, 0.42),
      o + const Offset(-0.32, 0.28),
      o + const Offset(-0.4, 0.04),
      o + const Offset(-0.38, -0.22),
      o + const Offset(-0.22, -0.38),
    ]);
    softShadow(
      c,
      shape,
      offset: const Offset(0, 0.04),
      blur: 0.035,
      color: const Color(0x66302030),
    );
    plush(
      c,
      shape,
      faceC,
      light: faceLight,
      dark: shade(faceC, -0.1),
      fur: 110,
      furLen: 0.05,
      seed: 51,
      fringe: 0,
      lightAmt: 0.1,
      shadowAmt: 0.14,
      furAlpha: 0.25,
    );
    // hellere Schnauzenpartie
    final muzzle = smoothClosed([
      o + const Offset(0, 0.06),
      o + const Offset(0.16, 0.1),
      o + const Offset(0.22, 0.24),
      o + const Offset(0.12, 0.38),
      o + const Offset(0, 0.41),
      o + const Offset(-0.12, 0.38),
      o + const Offset(-0.22, 0.24),
      o + const Offset(-0.16, 0.1),
    ], tension: 0.6);
    c.save();
    c.clipPath(shape);
    plush(
      c,
      muzzle,
      mix(faceC, faceLight, 0.55),
      light: faceLight,
      dark: faceC,
      fur: 40,
      seed: 52,
      fringe: 0,
      lightAmt: 0.06,
      shadowAmt: 0.1,
      furAlpha: 0.2,
    );
    c.restore();
    softHighlight(
      c,
      shape,
      o + const Offset(-0.14, -0.26),
      0.18,
      0.08,
      alpha: 0.3,
      rot: -0.4,
    );
  }

  static void _tuft(Canvas c) {
    // Woll-Schopf auf dem Kopf
    final o = _o;
    final locks = [
      o + const Offset(-0.22, -0.42),
      o + const Offset(-0.07, -0.5),
      o + const Offset(0.1, -0.5),
      o + const Offset(0.24, -0.4),
      o + const Offset(0.0, -0.4),
    ];
    for (var i = 0; i < locks.length; i++) {
      _curl(c, locks[i], 0.15, 120 + i);
    }
  }
}
