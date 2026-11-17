import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import '../face.dart';
import '../rig.dart';
import 'premium_figure.dart';

/// Kuh Frieda: breite rosa Schnauze, waagerechte Ohren, kleine Hörner, Stirnlocke,
/// große Flecken, Glocke am Halsband und ein Schwanz mit Quaste.
class CowFigure extends PremiumFigure {
  const CowFigure();
  @override
  String get id => 'cow';

  @override
  Personality get personality => const Personality(
    breathRate: 1.2,
    breathDepth: 1.2,
    blinkEvery: 4.6,
    tailRate: 1.8,
    tailAmp: 0.8,
    earTwitch: 1.1,
    curiosity: 0.2,
    bounce: 0.8,
    seed: 10,
  );

  static const white = Color(0xFFFBF8F4);
  static const shadowW = Color(0xFFCFC9D4);
  static const black = Color(0xFF3A3644);
  static const pinkM = Color(0xFFF6B3C2);
  static const _o = Offset(0, -0.12);

  static const _face = FaceStyle(
    eyeGap: 0.3,
    eyeY: -0.07,
    eyeRx: 0.095,
    eyeRy: 0.115,
    iris: Color(0xFF6B4A32),
    irisLight: Color(0xFFD9A878),
    lid: white,
    lashes: true,
    showNose: false,
    mouthY: 0.4,
    mouthW: 0.1,
    cat: false,
    blushY: 0.1,
    blushGap: 0.48,
    blushR: 0.08,
  );

  @override
  void paint(Canvas c, Pose p, double t) {
    c.save();
    c.translate(0, 0.12);
    c.scale(0.75);
    groundShadow(c, p, width: 1.2);
    c.translate(0, p.bodyDy);
    group(
      c,
      const Offset(0, 0.95),
      rot: p.lean,
      sx: 1 + p.squash * 0.3,
      sy: 1 - p.squash * 0.45,
      draw: () {
        group(
          c,
          const Offset(0.5, 0.45),
          rot: p.tail * 0.5,
          draw: () => c.drawPicture(PictureCache.get('cow.tail', _tail)),
        );
        group(
          c,
          const Offset(0, 0.95),
          sy: 1 + p.breath * 0.014,
          draw: () => c.drawPicture(PictureCache.get('cow.body', _body)),
        );
        _arm(c, p, -1);
        _arm(c, p, 1);
        // Halsband mit Glocke (schwingt leicht)
        c.drawPicture(PictureCache.get('cow.collar', _collar));
        group(
          c,
          const Offset(0, 0.3),
          rot: p.headTilt * 1.1 + p.lean * 0.5,
          move: Offset(0, p.headDy),
          draw: () {
            _ear(c, p, -1);
            _ear(c, p, 1);
            c.drawPicture(PictureCache.get('cow.horns', _horns));
            c.drawPicture(PictureCache.get('cow.head', _head));
            c.save();
            c.translate(_o.dx, _o.dy);
            // Wiederkäuen: Schnauze bewegt sich minimal
            final chew = (p.mouth == MouthShape.smile
                ? math.sin(t * 3.0) * 0.006
                : 0.0);
            c.translate(0, chew);
            drawFace(c, _face, p);
            c.restore();
          },
        );
      },
    );
    c.restore();
    sparkles(c, p, t, color: const Color(0xFFFFD6E8));
  }

  void _ear(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.earL : p.earR;
    group(
      c,
      Offset(side * 0.5, _o.dy - 0.22),
      rot: (side < 0 ? -rot : rot) * 1.4 + side * 0.04,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('cow.ear', _earPic));
        c.restore();
      },
    );
  }

  void _arm(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.armL : p.armR;
    group(
      c,
      Offset(side * 0.3, 0.46),
      rot: (side < 0 ? -rot : rot) * 1.2,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('cow.arm', _armPic));
        c.restore();
      },
    );
  }

  static void _patch(Canvas c, Path clip, Path blob) {
    c.save();
    c.clipPath(clip);
    plush(
      c,
      blob,
      black,
      light: shade(black, 0.15),
      dark: shade(black, -0.08),
      fur: 70,
      seed: 33,
      fringe: 0,
      lightAmt: 0.05,
      shadowAmt: 0.08,
      furAlpha: 0.22,
    );
    c.restore();
  }

  static void _tail(Canvas c) {
    final rope = Path()
      ..moveTo(0.56, 0.5)
      ..quadraticBezierTo(0.9, 0.5, 0.92, 0.78)
      ..quadraticBezierTo(0.93, 0.9, 0.9, 0.95);
    c.drawPath(
      rope,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.05
        ..strokeCap = StrokeCap.round
        ..color = shadowW,
    );
    c.drawPath(
      rope,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.03
        ..strokeCap = StrokeCap.round
        ..color = white,
    );
    final tuft = smoothClosed(const [
      Offset(0.86, 0.92),
      Offset(0.92, 0.88),
      Offset(0.99, 0.95),
      Offset(0.96, 1.06),
      Offset(0.88, 1.06),
    ], tension: 0.6);
    plush(
      c,
      tuft,
      black,
      fur: 30,
      seed: 41,
      fringe: 0.04,
      lightAmt: 0.06,
      shadowAmt: 0.1,
      light: shade(black, 0.2),
    );
  }

  static void _body(Canvas c) {
    final shape = smoothClosed(const [
      Offset(0, 0.16),
      Offset(0.34, 0.18),
      Offset(0.56, 0.36),
      Offset(0.66, 0.64),
      Offset(0.58, 0.88),
      Offset(0.28, 0.98),
      Offset(0, 0.99),
      Offset(-0.28, 0.98),
      Offset(-0.58, 0.88),
      Offset(-0.66, 0.64),
      Offset(-0.56, 0.36),
      Offset(-0.34, 0.18),
    ]);
    plush(
      c,
      shape,
      white,
      light: Colors.white,
      dark: shadowW,
      flow: (p) => math.pi / 2 + p.dx * 0.6,
      fur: 200,
      seed: 81,
      fringe: 0.02,
      furAlpha: 0.22,
      lightAmt: 0.05,
      shadowAmt: 0.14,
      skipFringe: (p) => p.dy < 0.3,
    );
    _patch(
      c,
      shape,
      smoothClosed(const [
        Offset(-0.7, 0.3),
        Offset(-0.34, 0.28),
        Offset(-0.2, 0.46),
        Offset(-0.3, 0.66),
        Offset(-0.62, 0.74),
        Offset(-0.74, 0.5),
      ], tension: 0.6),
    );
    _patch(
      c,
      shape,
      smoothClosed(const [
        Offset(0.74, 0.62),
        Offset(0.4, 0.6),
        Offset(0.28, 0.78),
        Offset(0.4, 0.96),
        Offset(0.74, 1.0),
      ], tension: 0.6),
    );
    _patch(
      c,
      shape,
      smoothClosed(const [
        Offset(0.1, 0.2),
        Offset(0.34, 0.22),
        Offset(0.4, 0.4),
        Offset(0.22, 0.48),
        Offset(0.06, 0.36),
      ], tension: 0.6),
    );
    softShadow(
      c,
      ellipsePath(0, 0.17, 0.44, 0.1),
      offset: const Offset(0, 0.05),
      blur: 0.05,
      color: const Color(0x55402E58),
      clip: shape,
    );
    for (final sx in [-1.0, 1.0]) {
      final hoof = smoothClosed([
        Offset(sx * 0.1, 0.96),
        Offset(sx * 0.26, 0.93),
        Offset(sx * 0.42, 0.96),
        Offset(sx * 0.43, 1.04),
        Offset(sx * 0.26, 1.07),
        Offset(sx * 0.09, 1.04),
      ]);
      fillVolume(c, hoof, const Color(0xFF5A5262), light: 0.08, shadow: 0.12);
    }
  }

  static void _collar(Canvas c) {
    final band = Path()
      ..moveTo(-0.34, 0.2)
      ..quadraticBezierTo(0, 0.38, 0.34, 0.2)
      ..lineTo(0.33, 0.29)
      ..quadraticBezierTo(0, 0.47, -0.33, 0.29)
      ..close();
    c.drawPath(
      band,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0.2),
          const Offset(0, 0.46),
          const [Color(0xFFE5574B), Color(0xFFB92F3C)],
        ),
    );
    final bell = const Offset(0, 0.5);
    c.drawPath(
      Path()
        ..moveTo(bell.dx - 0.07, bell.dy + 0.05)
        ..quadraticBezierTo(
          bell.dx - 0.07,
          bell.dy - 0.08,
          bell.dx,
          bell.dy - 0.08,
        )
        ..quadraticBezierTo(
          bell.dx + 0.07,
          bell.dy - 0.08,
          bell.dx + 0.07,
          bell.dy + 0.05,
        )
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          bell + const Offset(-0.07, 0),
          bell + const Offset(0.07, 0),
          const [Color(0xFFFFF2A8), Color(0xFFFFC21E), Color(0xFFD9980E)],
          const [0, 0.5, 1],
        ),
    );
    c.drawCircle(
      bell + const Offset(0, 0.06),
      0.017,
      Paint()..color = const Color(0xFF7A5A08),
    );
    gloss(c, bell + const Offset(-0.03, -0.03), 0.015, alpha: 0.85);
  }

  static void _armPic(Canvas c) {
    final arm = smoothClosed(const [
      Offset(0.2, 0.4),
      Offset(0.36, 0.42),
      Offset(0.42, 0.58),
      Offset(0.42, 0.76),
      Offset(0.34, 0.86),
      Offset(0.22, 0.84),
      Offset(0.18, 0.64),
    ]);
    plush(
      c,
      arm,
      white,
      light: Colors.white,
      dark: shadowW,
      flow: (p) => math.pi / 2,
      fur: 40,
      seed: 91,
      fringe: 0,
      furAlpha: 0.2,
      lightAmt: 0.05,
      shadowAmt: 0.12,
    );
    final hoof = smoothClosed(const [
      Offset(0.19, 0.8),
      Offset(0.3, 0.77),
      Offset(0.42, 0.8),
      Offset(0.43, 0.9),
      Offset(0.3, 0.93),
      Offset(0.2, 0.9),
    ]);
    fillVolume(c, hoof, const Color(0xFF5A5262), light: 0.08, shadow: 0.12);
  }

  static void _horns(Canvas c) {
    final o = _o;
    for (final sx in [-1.0, 1.0]) {
      final h = Path()
        ..moveTo(o.dx + sx * 0.26, o.dy - 0.42)
        ..quadraticBezierTo(
          o.dx + sx * 0.3,
          o.dy - 0.6,
          o.dx + sx * 0.44,
          o.dy - 0.66,
        )
        ..quadraticBezierTo(
          o.dx + sx * 0.4,
          o.dy - 0.54,
          o.dx + sx * 0.38,
          o.dy - 0.42,
        )
        ..close();
      c.drawPath(
        h,
        Paint()
          ..shader = ui.Gradient.linear(
            o + Offset(sx * 0.3, -0.42),
            o + Offset(sx * 0.44, -0.66),
            const [Color(0xFFF1E3C4), Color(0xFFFFF6E0)],
          ),
      );
      c.drawPath(
        h,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.008
          ..color = const Color(0x55906A30),
      );
    }
  }

  static void _earPic(Canvas c) {
    final o = _o;
    final ear = smoothClosed([
      o + const Offset(0.46, -0.3),
      o + const Offset(0.7, -0.38),
      o + const Offset(0.94, -0.3),
      o + const Offset(0.98, -0.18),
      o + const Offset(0.72, -0.08),
      o + const Offset(0.5, -0.12),
    ], tension: 0.55);
    plush(
      c,
      ear,
      white,
      light: Colors.white,
      dark: shadowW,
      flow: (p) => 0,
      fur: 40,
      seed: 61,
      fringe: 0.025,
      furAlpha: 0.2,
      lightAmt: 0.05,
      shadowAmt: 0.12,
    );
    final inner = smoothClosed([
      o + const Offset(0.56, -0.28),
      o + const Offset(0.74, -0.33),
      o + const Offset(0.88, -0.27),
      o + const Offset(0.86, -0.19),
      o + const Offset(0.72, -0.14),
      o + const Offset(0.58, -0.17),
    ], tension: 0.55);
    c.drawPath(
      inner,
      Paint()
        ..shader = ui.Gradient.linear(
          o + const Offset(0.56, -0.2),
          o + const Offset(0.88, -0.2),
          const [Color(0xFFF9C4D2), Color(0xFFF08CAB)],
        ),
    );
    // schwarzer Ohrrand rechts als Zeichnung
    c.save();
    c.clipPath(ear);
    c.drawCircle(o + const Offset(0.92, -0.2), 0.1, Paint()..color = black);
    c.restore();
  }

  static void _head(Canvas c) {
    final o = _o;
    final shape = smoothClosed([
      o + const Offset(0, -0.46),
      o + const Offset(0.3, -0.45),
      o + const Offset(0.5, -0.34),
      o + const Offset(0.56, -0.08),
      o + const Offset(0.54, 0.22),
      o + const Offset(0.44, 0.42),
      o + const Offset(0.2, 0.5),
      o + const Offset(0, 0.51),
      o + const Offset(-0.2, 0.5),
      o + const Offset(-0.44, 0.42),
      o + const Offset(-0.54, 0.22),
      o + const Offset(-0.56, -0.08),
      o + const Offset(-0.5, -0.34),
      o + const Offset(-0.3, -0.45),
    ]);
    softShadow(
      c,
      shape,
      offset: const Offset(0, 0.04),
      blur: 0.04,
      color: const Color(0x55402E58),
    );
    plush(
      c,
      shape,
      white,
      light: Colors.white,
      dark: shadowW,
      fur: 200,
      seed: 51,
      fringe: 0.02,
      furAlpha: 0.2,
      lightAmt: 0.06,
      shadowAmt: 0.14,
      skipFringe: (p) => p.dy < o.dy - 0.3 || p.dy > o.dy + 0.38,
    );
    // Fleck um das linke Auge und über der Stirn
    _patch(
      c,
      shape,
      smoothClosed([
        o + const Offset(-0.62, -0.24),
        o + const Offset(-0.26, -0.3),
        o + const Offset(-0.18, -0.04),
        o + const Offset(-0.4, 0.1),
        o + const Offset(-0.62, 0.0),
      ], tension: 0.6),
    );
    // breite rosa Schnauze mit Nüstern
    final muzzle = smoothClosed([
      o + const Offset(0, 0.12),
      o + const Offset(0.3, 0.14),
      o + const Offset(0.4, 0.3),
      o + const Offset(0.3, 0.46),
      o + const Offset(0, 0.5),
      o + const Offset(-0.3, 0.46),
      o + const Offset(-0.4, 0.3),
      o + const Offset(-0.3, 0.14),
    ], tension: 0.6);
    c.save();
    c.clipPath(shape);
    plush(
      c,
      muzzle,
      pinkM,
      light: const Color(0xFFFFDCE4),
      dark: const Color(0xFFD9788F),
      fur: 0,
      fringe: 0,
      lightAmt: 0.06,
      shadowAmt: 0.1,
    );
    for (final sx in [-1.0, 1.0]) {
      c.drawOval(
        Rect.fromCenter(
          center: o + Offset(sx * 0.14, 0.26),
          width: 0.1,
          height: 0.06,
        ),
        Paint()..color = const Color(0xFFB85A78),
      );
      c.drawOval(
        Rect.fromCenter(
          center: o + Offset(sx * 0.14 - 0.01, 0.255),
          width: 0.06,
          height: 0.025,
        ),
        Paint()..color = const Color(0x66FFFFFF),
      );
    }
    c.restore();
    // Stirnlocke
    final curl = smoothClosed([
      o + const Offset(-0.14, -0.44),
      o + const Offset(0, -0.58),
      o + const Offset(0.16, -0.44),
      o + const Offset(0.1, -0.36),
      o + const Offset(-0.1, -0.36),
    ], tension: 0.6);
    plush(
      c,
      curl,
      black,
      light: shade(black, 0.18),
      fur: 30,
      seed: 55,
      fringe: 0.03,
      lightAmt: 0.06,
      shadowAmt: 0.1,
    );
    softHighlight(
      c,
      shape,
      o + const Offset(-0.22, -0.3),
      0.24,
      0.09,
      alpha: 0.35,
      rot: -0.4,
    );
  }
}
