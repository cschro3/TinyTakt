import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import '../face.dart';
import '../rig.dart';
import 'premium_figure.dart';

/// Hund Bruno: treuer Labrador-Mischling mit langen Schlappohren, kräftiger Schnauze,
/// dunklem Augenfleck, rotem Halsband mit Marke und wedelndem Schwanz.
class DogFigure extends PremiumFigure {
  const DogFigure();
  @override
  String get id => 'dog';

  @override
  Personality get personality => const Personality(
    breathRate: 1.8,
    blinkEvery: 3.3,
    tailRate: 6.0,
    tailAmp: 0.9,
    earTwitch: 0.5,
    curiosity: 0.3,
    bounce: 1.3,
    seed: 2,
  );

  static const fur = Color(0xFFD29A5C);
  static const furDark = Color(0xFF8E5B2B);
  static const furLight = Color(0xFFF5E0BC);
  static const earC = Color(0xFF8A5A2E);
  static const _o = Offset(0, -0.12);

  static const _face = FaceStyle(
    eyeGap: 0.26,
    eyeY: -0.04,
    eyeRx: 0.1,
    eyeRy: 0.115,
    iris: Color(0xFF6B4423),
    irisLight: Color(0xFFD9A066),
    lid: fur,
    cat: false,
    noseOval: true,
    noseColor: Color(0xFF2A2430),
    noseY: 0.1,
    noseW: 0.055,
    mouthY: 0.24,
    mouthW: 0.1,
    blushY: 0.12,
    blushGap: 0.42,
    blushR: 0.07,
    blush: Color(0xFFFF9AA2),
  );

  @override
  void paint(Canvas c, Pose p, double t) {
    c.save();
    c.translate(0, 0.14);
    c.scale(0.82);
    groundShadow(c, p, width: 1.0);
    c.translate(0, p.bodyDy);
    group(
      c,
      const Offset(0, 0.95),
      rot: p.lean,
      sx: 1 + p.squash * 0.35,
      sy: 1 - p.squash * 0.5,
      draw: () {
        // wedelnder Schwanz (schnell, mit Schwung)
        group(
          c,
          const Offset(0.4, 0.84),
          rot: -0.5 + p.tail * 0.75,
          draw: () => c.drawPicture(PictureCache.get('dog.tail', _tail)),
        );
        group(
          c,
          const Offset(0, 0.95),
          sy: 1 + p.breath * 0.014,
          draw: () => c.drawPicture(PictureCache.get('dog.body', _body)),
        );
        _arm(c, p, -1);
        _arm(c, p, 1);
        // Halsband
        c.drawPicture(PictureCache.get('dog.collar', _collar));
        group(
          c,
          const Offset(0, 0.3),
          rot: p.headTilt * 1.3 + p.lean * 0.5,
          move: Offset(0, p.headDy),
          draw: () {
            _ear(c, p, -1, t);
            _ear(c, p, 1, t);
            c.drawPicture(PictureCache.get('dog.head', _head));
            c.save();
            c.translate(_o.dx, _o.dy);
            drawFace(c, _face, p);
            // Zunge, wenn der Mund offen/fröhlich ist
            if (p.mouth == MouthShape.open || p.mouth == MouthShape.grin) {
              final lolling = p.mouth == MouthShape.open ? 1.0 : 0.6;
              final tongue = Path()
                ..moveTo(-0.06, 0.26)
                ..quadraticBezierTo(
                  -0.075,
                  0.26 + 0.12 * lolling,
                  0,
                  0.27 + 0.14 * lolling,
                )
                ..quadraticBezierTo(0.075, 0.26 + 0.12 * lolling, 0.06, 0.26)
                ..close();
              c.drawPath(
                tongue,
                Paint()
                  ..shader = ui.Gradient.linear(
                    const Offset(0, 0.26),
                    Offset(0, 0.4),
                    const [Color(0xFFFF8CA0), Color(0xFFE5587A)],
                  ),
              );
              c.drawLine(
                const Offset(0, 0.27),
                Offset(0, 0.25 + 0.1 * lolling),
                Paint()
                  ..color = const Color(0x55A02050)
                  ..strokeWidth = 0.008,
              );
            }
            c.restore();
          },
        );
      },
    );
    c.restore();
    sparkles(c, p, t, color: const Color(0xFFFFD27A));
  }

  void _ear(Canvas c, Pose p, double side, double t) {
    final swing =
        (side < 0 ? p.earL : p.earR) * 0.9 +
        math.sin(t * 2.4 + side) * 0.03 +
        p.headTilt * 0.7 -
        p.bodyDy * side * 1.2;
    group(
      c,
      Offset(side * 0.4, _o.dy - 0.33),
      rot: swing * side,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('dog.ear', _earPic));
        c.restore();
      },
    );
  }

  void _arm(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.armL : p.armR;
    group(
      c,
      Offset(side * 0.26, 0.42),
      rot: (side < 0 ? -rot : rot) * 1.3,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('dog.arm', _armPic));
        c.restore();
      },
    );
  }

  static void _tail(Canvas c) {
    final shape = smoothClosed(const [
      Offset(0.4, 0.9),
      Offset(0.62, 0.92),
      Offset(0.84, 0.82),
      Offset(0.96, 0.62),
      Offset(0.92, 0.5),
      Offset(0.8, 0.62),
      Offset(0.62, 0.74),
      Offset(0.44, 0.78),
    ], tension: 0.6);
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => -0.6,
      fur: 90,
      seed: 71,
      fringe: 0.035,
    );
  }

  static void _body(Canvas c) {
    // Sitzender Körper mit Hinterkeulen
    final shape = smoothClosed(const [
      Offset(0, 0.14),
      Offset(0.28, 0.16),
      Offset(0.46, 0.34),
      Offset(0.58, 0.62),
      Offset(0.52, 0.86),
      Offset(0.26, 0.97),
      Offset(0, 0.98),
      Offset(-0.26, 0.97),
      Offset(-0.52, 0.86),
      Offset(-0.58, 0.62),
      Offset(-0.46, 0.34),
      Offset(-0.28, 0.16),
    ]);
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => math.pi / 2 + p.dx * 0.8,
      fur: 280,
      seed: 81,
      fringe: 0.035,
      skipFringe: (p) => p.dy < 0.24 || p.dy > 0.92,
    );
    // heller Brustlatz
    final chest = smoothClosed(const [
      Offset(0, 0.2),
      Offset(0.2, 0.28),
      Offset(0.26, 0.5),
      Offset(0.18, 0.78),
      Offset(0, 0.86),
      Offset(-0.18, 0.78),
      Offset(-0.26, 0.5),
      Offset(-0.2, 0.28),
    ]);
    c.save();
    c.clipPath(shape);
    plush(
      c,
      chest,
      furLight,
      light: Colors.white,
      dark: mix(furLight, fur, 0.45),
      flow: (p) => math.pi / 2 + p.dx * 1.2,
      fur: 120,
      seed: 82,
      fringe: 0,
      lightAmt: 0.04,
      shadowAmt: 0.08,
    );
    // Hinterkeulen als weiche Wölbung
    for (final sx in [-1.0, 1.0]) {
      final thigh = ellipsePath(sx * 0.4, 0.78, 0.2, 0.2);
      softShadow(
        c,
        thigh,
        offset: const Offset(0, 0.0),
        blur: 0.04,
        color: const Color(0x33703A18),
        clip: shape,
      );
      softHighlight(
        c,
        shape,
        Offset(sx * 0.4 - 0.04, 0.72),
        0.12,
        0.1,
        alpha: 0.18,
      );
    }
    c.restore();
    for (final sx in [-1.0, 1.0]) {
      final foot = smoothClosed([
        Offset(sx * 0.1, 0.94),
        Offset(sx * 0.24, 0.9),
        Offset(sx * 0.4, 0.93),
        Offset(sx * 0.42, 1.01),
        Offset(sx * 0.24, 1.04),
        Offset(sx * 0.09, 1.01),
      ]);
      fillVolume(c, foot, furLight, light: 0.05, shadow: 0.12);
      toeLines(
        c,
        Offset(sx * 0.25, 0.99),
        0.07,
        furDark.withValues(alpha: 0.4),
        n: 3,
        len: 0.035,
      );
    }
  }

  static void _collar(Canvas c) {
    final band = Path()
      ..moveTo(-0.32, 0.18)
      ..quadraticBezierTo(0, 0.34, 0.32, 0.18)
      ..lineTo(0.31, 0.27)
      ..quadraticBezierTo(0, 0.43, -0.31, 0.27)
      ..close();
    c.drawPath(
      band,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0.2),
          const Offset(0, 0.42),
          const [Color(0xFFE5574B), Color(0xFFB92F3C)],
        ),
    );
    c.drawPath(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.008
        ..color = const Color(0x55701820),
    );
    final tag = Offset(0, 0.45);
    c.drawCircle(
      tag,
      0.05,
      Paint()
        ..shader = ui.Gradient.radial(
          tag + const Offset(-0.015, -0.015),
          0.07,
          const [Color(0xFFFFF2A8), Color(0xFFFFC21E), Color(0xFFD9980E)],
          const [0, 0.5, 1],
        ),
    );
    sparkleStar(c, tag + const Offset(-0.012, -0.012), 0.016, Colors.white);
  }

  static void _armPic(Canvas c) {
    final arm = smoothClosed(const [
      Offset(0.18, 0.34),
      Offset(0.32, 0.36),
      Offset(0.38, 0.54),
      Offset(0.38, 0.72),
      Offset(0.31, 0.8),
      Offset(0.2, 0.78),
      Offset(0.16, 0.6),
    ]);
    plush(
      c,
      arm,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => math.pi / 2,
      fur: 60,
      seed: 91,
      fringe: 0.03,
      skipFringe: (p) => p.dy < 0.42,
    );
    final paw = smoothClosed(const [
      Offset(0.17, 0.7),
      Offset(0.27, 0.67),
      Offset(0.38, 0.7),
      Offset(0.4, 0.8),
      Offset(0.3, 0.86),
      Offset(0.19, 0.82),
    ]);
    fillVolume(c, paw, furLight, light: 0.05, shadow: 0.1);
    toeLines(
      c,
      const Offset(0.29, 0.78),
      0.065,
      furDark.withValues(alpha: 0.35),
      n: 3,
      len: 0.045,
    );
  }

  static void _earPic(Canvas c) {
    // lange Schlappohren, die seitlich am Kopf hängen
    final o = _o;
    final ear = smoothClosed([
      o + const Offset(0.22, -0.34),
      o + const Offset(0.48, -0.36),
      o + const Offset(0.66, -0.22),
      o + const Offset(0.7, 0.04),
      o + const Offset(0.64, 0.3),
      o + const Offset(0.5, 0.44),
      o + const Offset(0.38, 0.36),
      o + const Offset(0.38, 0.1),
      o + const Offset(0.3, -0.08),
    ], tension: 0.55);
    softShadow(
      c,
      ear,
      offset: const Offset(0.01, 0.02),
      blur: 0.025,
      color: const Color(0x55401A08),
    );
    plush(
      c,
      ear,
      earC,
      light: shade(earC, 0.25),
      dark: shade(earC, -0.15),
      flow: (p) => math.pi / 2,
      fur: 100,
      seed: 61,
      fringe: 0.03,
      skipFringe: (p) => p.dy < o.dy - 0.2,
    );
    softHighlight(
      c,
      ear,
      o + const Offset(0.52, -0.16),
      0.1,
      0.16,
      alpha: 0.2,
      rot: 0.3,
    );
  }

  static void _head(Canvas c) {
    final o = _o;
    final shape = smoothClosed([
      o + const Offset(0, -0.48),
      o + const Offset(0.3, -0.45),
      o + const Offset(0.5, -0.28),
      o + const Offset(0.56, 0.0),
      o + const Offset(0.5, 0.26),
      o + const Offset(0.34, 0.42),
      o + const Offset(0.12, 0.48),
      o + const Offset(0, 0.49),
      o + const Offset(-0.12, 0.48),
      o + const Offset(-0.34, 0.42),
      o + const Offset(-0.5, 0.26),
      o + const Offset(-0.56, 0.0),
      o + const Offset(-0.5, -0.28),
      o + const Offset(-0.3, -0.45),
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
      fur: 320,
      seed: 51,
      fringe: 0.035,
      fringeSpacing: 0.045,
      skipFringe: (p) => p.dy < o.dy - 0.3 || p.dy > o.dy + 0.38,
    );
    // dunkler Augenfleck (rechts) – Erkennungsmerkmal
    final patch = smoothClosed([
      o + const Offset(0.12, -0.3),
      o + const Offset(0.34, -0.34),
      o + const Offset(0.5, -0.2),
      o + const Offset(0.5, 0.0),
      o + const Offset(0.34, 0.08),
      o + const Offset(0.16, 0.0),
    ], tension: 0.6);
    c.save();
    c.clipPath(shape);
    plush(
      c,
      patch,
      earC,
      light: shade(earC, 0.2),
      dark: shade(earC, -0.1),
      fur: 80,
      seed: 53,
      fringe: 0,
      lightAmt: 0.05,
      shadowAmt: 0.1,
    );
    c.restore();
    // Schnauze: kräftig und hell
    final muzzle = smoothClosed([
      o + const Offset(0, 0.0),
      o + const Offset(0.2, 0.04),
      o + const Offset(0.32, 0.18),
      o + const Offset(0.28, 0.38),
      o + const Offset(0.1, 0.46),
      o + const Offset(0, 0.47),
      o + const Offset(-0.1, 0.46),
      o + const Offset(-0.28, 0.38),
      o + const Offset(-0.32, 0.18),
      o + const Offset(-0.2, 0.04),
    ], tension: 0.6);
    plush(
      c,
      muzzle,
      furLight,
      light: Colors.white,
      dark: mix(furLight, fur, 0.45),
      fur: 110,
      seed: 52,
      fringe: 0,
      lightAmt: 0.05,
      shadowAmt: 0.1,
    );
    // Braue-Punkte
    for (final sx in [-1.0, 1.0]) {
      c.drawCircle(
        o + Offset(sx * 0.24, -0.2),
        0.026,
        Paint()..color = const Color(0xFFE8C48A),
      );
      for (var k = 0; k < 3; k++) {
        c.drawCircle(
          o + Offset(sx * (0.12 + k * 0.045), 0.2 + k * 0.025),
          0.008,
          Paint()..color = furDark.withValues(alpha: 0.5),
        );
      }
    }
    softHighlight(
      c,
      shape,
      o + const Offset(-0.22, -0.32),
      0.24,
      0.09,
      alpha: 0.22,
      rot: -0.4,
    );
  }
}
