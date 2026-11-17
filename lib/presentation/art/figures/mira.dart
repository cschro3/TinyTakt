import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import '../face.dart';
import '../rig.dart';
import 'premium_figure.dart';

/// Mira, die Lustige: rundes, fliederfarbenes Fellwesen mit großen schwingenden Puschel-Ohren,
/// leuchtenden Pfotenballen, Puschelschwanz und einem frechen Zwinkern.
class MiraFigure extends PremiumFigure {
  const MiraFigure();
  @override
  String get id => 'nova_mira';

  @override
  Personality get personality => const Personality(
    breathRate: 2.0,
    blinkEvery: 3.4,
    tailRate: 3.2,
    tailAmp: 0.8,
    earTwitch: 1.0,
    curiosity: 0.4,
    bounce: 1.5,
    glowPulse: 0.18,
    winker: true,
    seed: 9,
  );

  static const fur = Color(0xFFC79DE0);
  static const furDark = Color(0xFF8E5CB8);
  static const furLight = Color(0xFFFBEAF8);
  static const pink = Color(0xFFFF8CC8);
  static const glowColor = Color(0xFFB347FF);
  static const _o = Offset(0, -0.16);

  static const _face = FaceStyle(
    eyeGap: 0.28,
    eyeY: 0.02,
    eyeRx: 0.12,
    eyeRy: 0.15,
    iris: Color(0xFF8E4BE0),
    irisLight: Color(0xFFE0B2FF),
    lid: fur,
    lashes: true,
    mouthY: 0.28,
    mouthW: 0.08,
    noseY: 0.17,
    noseW: 0.045,
    noseColor: Color(0xFFFF7FB0),
    blushY: 0.17,
    blushGap: 0.45,
    blushR: 0.09,
    blush: Color(0xFFFF7FB8),
  );

  @override
  void paint(Canvas c, Pose p, double t) {
    c.save();
    c.translate(0, 0.14);
    c.scale(0.8);
    groundShadow(c, p, width: 1.1);
    c.translate(0, p.bodyDy);
    group(
      c,
      const Offset(0, 0.95),
      rot: p.lean,
      sx: 1 + p.squash * 0.4,
      sy: 1 - p.squash * 0.55,
      draw: () {
        // Puschelschwanz (wackelt schnell)
        group(
          c,
          const Offset(0.4, 0.72),
          rot: p.tail * 0.5,
          draw: () => c.drawPicture(PictureCache.get('mira.tail', _tail)),
        );
        group(
          c,
          const Offset(0, 0.95),
          sy: 1 + p.breath * 0.016,
          draw: () => c.drawPicture(PictureCache.get('mira.body', _body)),
        );
        // Arme mit leuchtenden Pfotenballen
        _arm(c, p, -1);
        _arm(c, p, 1);
        group(
          c,
          const Offset(0, 0.3),
          rot: p.headTilt * 1.2 + p.lean * 0.5,
          move: Offset(0, p.headDy),
          draw: () {
            // große Puschel-Ohren schwingen nach (Verzögerung über Ohrwinkel)
            _puff(c, p, -1, t);
            _puff(c, p, 1, t);
            _ear(c, p, -1);
            _ear(c, p, 1);
            c.drawPicture(PictureCache.get('mira.head', _head));
            c.save();
            c.translate(_o.dx, _o.dy);
            drawFace(c, _face, p);
            c.restore();
          },
        );
      },
    );
    c.restore();
    sparkles(c, p, t, color: const Color(0xFFFFB6E8));
  }

  void _puff(Canvas c, Pose p, double side, double t) {
    final sway =
        (side < 0 ? p.earL : p.earR) * 1.2 +
        math.sin(t * 2.1 + side) * 0.04 +
        p.headTilt * 0.6 +
        p.bodyDy * -0.9 * side;
    group(
      c,
      Offset(side * 0.48, _o.dy - 0.05),
      rot: sway * side,
      draw: () {
        glow(
          c,
          Offset(side * 0.78, _o.dy + 0.02),
          0.5,
          glowColor,
          0.38 * p.glow,
        );
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('mira.puff', _puffPic));
        c.restore();
      },
    );
  }

  void _ear(Canvas c, Pose p, double side) {
    group(
      c,
      Offset(side * 0.3, _o.dy - 0.42),
      rot: (side < 0 ? -p.earL : p.earR) * 0.8,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('mira.ear', _earPic));
        c.restore();
      },
    );
  }

  void _arm(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.armL : p.armR;
    group(
      c,
      Offset(side * 0.3, 0.42),
      rot: (side < 0 ? -rot : rot) * 1.3,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('mira.arm', _armPic));
        c.restore();
        // leuchtender Pfotenballen
        final padC = Offset(side * 0.4, 0.74);
        glow(c, padC, 0.2, glowColor, 0.5 * p.glow);
      },
    );
  }

  static void _tail(Canvas c) {
    final shape = ellipsePath(0.72, 0.58, 0.3, 0.34);
    plush(
      c,
      shape,
      mix(fur, furLight, 0.15),
      light: furLight,
      dark: furDark,
      fur: 180,
      furLen: 0.09,
      seed: 71,
      fringe: 0.085,
      fringeSpacing: 0.04,
      fringeWidth: 0.08,
      fringeTip: furLight,
    );
    softHighlight(
      c,
      shape,
      const Offset(0.62, 0.42),
      0.14,
      0.12,
      alpha: 0.5,
      color: Colors.white,
    );
  }

  static void _body(Canvas c) {
    // rundlich, birnenförmig
    final shape = smoothClosed(const [
      Offset(0, 0.12),
      Offset(0.3, 0.16),
      Offset(0.52, 0.36),
      Offset(0.62, 0.64),
      Offset(0.5, 0.88),
      Offset(0.22, 0.98),
      Offset(0, 0.99),
      Offset(-0.22, 0.98),
      Offset(-0.5, 0.88),
      Offset(-0.62, 0.64),
      Offset(-0.52, 0.36),
      Offset(-0.3, 0.16),
    ]);
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => math.pi / 2 + p.dx * 0.9,
      fur: 340,
      seed: 81,
      fringe: 0.05,
      skipFringe: (p) => p.dy < 0.22 || p.dy > 0.93,
    );
    final belly = smoothClosed(const [
      Offset(0, 0.34),
      Offset(0.22, 0.4),
      Offset(0.34, 0.64),
      Offset(0.24, 0.88),
      Offset(0, 0.95),
      Offset(-0.24, 0.88),
      Offset(-0.34, 0.64),
      Offset(-0.22, 0.4),
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
      fur: 140,
      seed: 82,
      fringe: 0,
      lightAmt: 0.04,
      shadowAmt: 0.08,
    );
    // kleines Herz-Muster auf dem Bauch (Persönlichkeit)
    final heart = Path()
      ..moveTo(0, 0.74)
      ..cubicTo(-0.13, 0.62, -0.12, 0.52, 0, 0.58)
      ..cubicTo(0.12, 0.52, 0.13, 0.62, 0, 0.74)
      ..close();
    c.drawPath(
      heart,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0.55),
          const Offset(0, 0.75),
          [const Color(0xFFFFB0DC), pink],
        ),
    );
    c.restore();
    softShadow(
      c,
      ellipsePath(0, 0.14, 0.42, 0.11),
      offset: const Offset(0, 0.05),
      blur: 0.05,
      color: const Color(0x66583A88),
      clip: shape,
    );
    for (final sx in [-1.0, 1.0]) {
      final foot = smoothClosed([
        Offset(sx * 0.1, 0.94),
        Offset(sx * 0.22, 0.9),
        Offset(sx * 0.38, 0.93),
        Offset(sx * 0.4, 1.01),
        Offset(sx * 0.22, 1.04),
        Offset(sx * 0.09, 1.01),
      ]);
      fillVolume(c, foot, furLight, light: 0.05, shadow: 0.12);
    }
  }

  static void _armPic(Canvas c) {
    final arm = smoothClosed(const [
      Offset(0.26, 0.38),
      Offset(0.4, 0.4),
      Offset(0.48, 0.56),
      Offset(0.48, 0.72),
      Offset(0.4, 0.8),
      Offset(0.28, 0.78),
      Offset(0.24, 0.6),
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
      skipFringe: (p) => p.dy < 0.44,
    );
    final paw = smoothClosed(const [
      Offset(0.27, 0.7),
      Offset(0.37, 0.67),
      Offset(0.48, 0.7),
      Offset(0.5, 0.8),
      Offset(0.4, 0.86),
      Offset(0.28, 0.82),
    ]);
    fillVolume(c, paw, furLight, light: 0.05, shadow: 0.1);
    // Ballen: großer Mittelballen + drei Zehenballen, leuchtend
    final padPaint = Paint()
      ..shader = ui.Gradient.radial(const Offset(0.39, 0.78), 0.06, [
        const Color(0xFFFFD8F4),
        glowColor,
      ]);
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(0.39, 0.79),
        width: 0.07,
        height: 0.055,
      ),
      padPaint,
    );
    for (var i = 0; i < 3; i++) {
      c.drawCircle(Offset(0.33 + i * 0.06, 0.73), 0.015, padPaint);
    }
  }

  static void _earPic(Canvas c) {
    final o = _o;
    final ear = smoothClosed([
      o + const Offset(0.1, -0.4),
      o + const Offset(0.18, -0.58),
      o + const Offset(0.3, -0.82),
      o + const Offset(0.44, -0.62),
      o + const Offset(0.5, -0.4),
      o + const Offset(0.4, -0.26),
    ], tension: 0.55);
    plush(
      c,
      ear,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => -math.pi / 2,
      fur: 50,
      seed: 61,
      fringe: 0.04,
    );
    final inner = smoothClosed([
      o + const Offset(0.2, -0.4),
      o + const Offset(0.26, -0.55),
      o + const Offset(0.31, -0.7),
      o + const Offset(0.4, -0.56),
      o + const Offset(0.42, -0.4),
      o + const Offset(0.34, -0.32),
    ]);
    c.drawPath(
      inner,
      Paint()
        ..shader = ui.Gradient.linear(
          o + const Offset(0.3, -0.3),
          o + const Offset(0.3, -0.7),
          const [Color(0xFFFFC0E6), Color(0xFFFF8CC8)],
        ),
    );
  }

  static void _puffPic(Canvas c) {
    // große weiche Puschel-Ohren seitlich am Kopf
    final shape = smoothClosed([
      _o + const Offset(0.5, -0.2),
      _o + const Offset(0.7, -0.26),
      _o + const Offset(0.9, -0.12),
      _o + const Offset(0.98, 0.12),
      _o + const Offset(0.9, 0.38),
      _o + const Offset(0.7, 0.46),
      _o + const Offset(0.54, 0.34),
      _o + const Offset(0.5, 0.1),
    ], tension: 0.55);
    plush(
      c,
      shape,
      mix(fur, furLight, 0.1),
      light: furLight,
      dark: furDark,
      fur: 160,
      furLen: 0.08,
      seed: 41,
      fringe: 0.09,
      fringeSpacing: 0.04,
      fringeWidth: 0.08,
      fringeTip: furLight,
    );
    final inner = smoothClosed([
      _o + const Offset(0.6, -0.08),
      _o + const Offset(0.76, -0.1),
      _o + const Offset(0.86, 0.06),
      _o + const Offset(0.84, 0.26),
      _o + const Offset(0.72, 0.34),
      _o + const Offset(0.6, 0.22),
    ]);
    c.drawPath(
      inner,
      Paint()
        ..shader = ui.Gradient.radial(
          _o + const Offset(0.74, 0.12),
          0.26,
          [
            const Color(0xFFFFDDF2),
            const Color(0xFFE79BD6),
            const Color(0xFFB766D8),
          ],
          const [0, 0.55, 1],
        ),
    );
  }

  static void _head(Canvas c) {
    final o = _o;
    final shape = smoothClosed([
      o + const Offset(0, -0.52),
      o + const Offset(0.32, -0.48),
      o + const Offset(0.55, -0.3),
      o + const Offset(0.66, 0.0),
      o + const Offset(0.62, 0.26),
      o + const Offset(0.42, 0.42),
      o + const Offset(0.16, 0.48),
      o + const Offset(0, 0.49),
      o + const Offset(-0.16, 0.48),
      o + const Offset(-0.42, 0.42),
      o + const Offset(-0.62, 0.26),
      o + const Offset(-0.66, 0.0),
      o + const Offset(-0.55, -0.3),
      o + const Offset(-0.32, -0.48),
    ]);
    softShadow(
      c,
      shape,
      offset: const Offset(0, 0.045),
      blur: 0.04,
      color: const Color(0x66583A88),
    );
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      fur: 400,
      seed: 51,
      fringe: 0.06,
      fringeSpacing: 0.04,
      fringeWidth: 0.07,
      skipFringe: (p) =>
          p.dy < o.dy - 0.42 || (p.dy > o.dy + 0.42 && p.dx.abs() < 0.3),
    );
    final mask = smoothClosed([
      o + const Offset(0, -0.2),
      o + const Offset(0.22, -0.12),
      o + const Offset(0.42, 0.06),
      o + const Offset(0.44, 0.26),
      o + const Offset(0.26, 0.42),
      o + const Offset(0, 0.46),
      o + const Offset(-0.26, 0.42),
      o + const Offset(-0.44, 0.26),
      o + const Offset(-0.42, 0.06),
      o + const Offset(-0.22, -0.12),
    ]);
    c.save();
    c.clipPath(shape);
    plush(
      c,
      mask,
      furLight,
      light: Colors.white,
      dark: mix(furLight, fur, 0.5),
      fur: 200,
      seed: 52,
      fringe: 0.03,
      lightAmt: 0.04,
      shadowAmt: 0.1,
      skipFringe: (p) => p.dy > o.dy + 0.36,
    );
    c.restore();
    // Haarlocke auf der Stirn
    final curl = Path()
      ..moveTo(o.dx - 0.02, o.dy - 0.5)
      ..cubicTo(
        o.dx - 0.16,
        o.dy - 0.66,
        o.dx + 0.14,
        o.dy - 0.78,
        o.dx + 0.12,
        o.dy - 0.62,
      )
      ..cubicTo(
        o.dx + 0.1,
        o.dy - 0.56,
        o.dx + 0.02,
        o.dy - 0.56,
        o.dx + 0.04,
        o.dy - 0.5,
      )
      ..close();
    fillVolume(c, curl, mix(fur, pink, 0.35), light: 0.1, shadow: 0.12);
    softHighlight(
      c,
      shape,
      o + const Offset(-0.25, -0.36),
      0.28,
      0.1,
      alpha: 0.24,
      rot: -0.4,
    );
    sparkleStar(c, o + const Offset(0.52, -0.34), 0.03, Colors.white);
  }
}
