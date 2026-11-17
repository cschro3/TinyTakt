import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import '../face.dart';
import '../rig.dart';
import 'premium_figure.dart';

/// Schwein Rosa: großer runder Kopf, Schnauzenscheibe mit Nüstern (schnuppert),
/// nach vorn geklappte Ohren, kleine Hufe und ein Ringelschwänzchen.
class PigFigure extends PremiumFigure {
  const PigFigure();
  @override
  String get id => 'pig';

  @override
  Personality get personality => const Personality(
    breathRate: 2.0,
    breathDepth: 1.1,
    blinkEvery: 3.2,
    tailRate: 3.0,
    tailAmp: 0.6,
    earTwitch: 0.9,
    curiosity: 0.5,
    bounce: 1.3,
    seed: 11,
  );

  static const fur = Color(0xFFF7AEC2);
  static const furDark = Color(0xFFD7708E);
  static const furLight = Color(0xFFFFDDE6);
  static const snoutC = Color(0xFFF08CAB);
  static const _o = Offset(0, -0.06);

  static const _face = FaceStyle(
    eyeGap: 0.31,
    eyeY: -0.14,
    eyeRx: 0.085,
    eyeRy: 0.105,
    iris: Color(0xFF4A2A3A),
    irisLight: Color(0xFFB87088),
    lid: fur,
    lashes: true,
    showNose: false,
    mouthY: 0.4,
    mouthW: 0.09,
    cat: false,
    blushY: 0.04,
    blushGap: 0.5,
    blushR: 0.095,
    blush: Color(0xFFFF6F9A),
  );

  @override
  void paint(Canvas c, Pose p, double t) {
    c.save();
    c.translate(0, 0.14);
    c.scale(0.82);
    groundShadow(c, p, width: 1.1);
    c.translate(0, p.bodyDy);
    group(
      c,
      const Offset(0, 0.95),
      rot: p.lean,
      sx: 1 + p.squash * 0.4,
      sy: 1 - p.squash * 0.55,
      draw: () {
        // Ringelschwänzchen wackelt
        group(
          c,
          const Offset(0.5, 0.74),
          rot: p.tail * 0.4,
          draw: () => c.drawPicture(PictureCache.get('pig.tail', _tail)),
        );
        group(
          c,
          const Offset(0, 0.95),
          sy: 1 + p.breath * 0.016,
          draw: () => c.drawPicture(PictureCache.get('pig.body', _body)),
        );
        _arm(c, p, -1);
        _arm(c, p, 1);
        group(
          c,
          const Offset(0, 0.32),
          rot: p.headTilt * 1.2 + p.lean * 0.5,
          move: Offset(0, p.headDy),
          draw: () {
            c.drawPicture(PictureCache.get('pig.head', _head));
            _ear(c, p, -1, t);
            _ear(c, p, 1, t);
            c.save();
            c.translate(_o.dx, _o.dy);
            drawFace(c, _face, p);
            // Schnauze: Nüstern weiten sich beim Schnuppern
            final sniff =
                1 +
                math.max(0.0, math.sin(t * 3.0)) * 0.12 +
                (p.eyes == EyeMode.wide ? 0.15 : 0);
            c.drawPicture(PictureCache.get('pig.snout', _snout));
            for (final sx in [-1.0, 1.0]) {
              c.drawOval(
                Rect.fromCenter(
                  center: Offset(sx * 0.07, 0.24),
                  width: 0.062 * sniff,
                  height: 0.092 * sniff,
                ),
                Paint()..color = const Color(0xFF8E3A58),
              );
              c.drawOval(
                Rect.fromCenter(
                  center: Offset(sx * 0.07 - 0.008, 0.225),
                  width: 0.03 * sniff,
                  height: 0.03 * sniff,
                ),
                Paint()..color = const Color(0x44FFFFFF),
              );
            }
            c.restore();
          },
        );
      },
    );
    c.restore();
    sparkles(c, p, t, color: const Color(0xFFFFB6D0));
  }

  void _ear(Canvas c, Pose p, double side, double t) {
    final rot =
        (side < 0 ? p.earL : p.earR) * 1.2 + math.sin(t * 2 + side) * 0.02;
    group(
      c,
      Offset(side * 0.4, _o.dy - 0.4),
      rot: (side < 0 ? -rot : rot),
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('pig.ear', _earPic));
        c.restore();
      },
    );
  }

  void _arm(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.armL : p.armR;
    group(
      c,
      Offset(side * 0.3, 0.5),
      rot: (side < 0 ? -rot : rot) * 1.2,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('pig.arm', _armPic));
        c.restore();
      },
    );
  }

  static void _tail(Canvas c) {
    final spiral = Path();
    for (var i = 0; i <= 40; i++) {
      final a = i / 40 * math.pi * 4.2;
      final r = 0.03 + 0.1 * (i / 40);
      final pt = Offset(
        0.66 + math.cos(a) * r * 1.1,
        0.7 - i / 40 * 0.04 + math.sin(a) * r,
      );
      i == 0 ? spiral.moveTo(pt.dx, pt.dy) : spiral.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(
      spiral,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.05
        ..strokeCap = StrokeCap.round
        ..color = furDark,
    );
    c.drawPath(
      spiral,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.03
        ..strokeCap = StrokeCap.round
        ..color = fur,
    );
  }

  static void _body(Canvas c) {
    final shape = smoothClosed(const [
      Offset(0, 0.2),
      Offset(0.32, 0.22),
      Offset(0.52, 0.4),
      Offset(0.6, 0.66),
      Offset(0.5, 0.9),
      Offset(0.24, 0.99),
      Offset(0, 1.0),
      Offset(-0.24, 0.99),
      Offset(-0.5, 0.9),
      Offset(-0.6, 0.66),
      Offset(-0.52, 0.4),
      Offset(-0.32, 0.22),
    ]);
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => math.pi / 2,
      fur: 80,
      furLen: 0.05,
      seed: 81,
      fringe: 0,
      furAlpha: 0.2,
      lightAmt: 0.1,
      shadowAmt: 0.16,
    );
    softHighlight(
      c,
      shape,
      const Offset(-0.22, 0.45),
      0.2,
      0.3,
      alpha: 0.28,
      rot: 0.3,
    );
    softShadow(
      c,
      ellipsePath(0, 0.22, 0.42, 0.1),
      offset: const Offset(0, 0.05),
      blur: 0.05,
      color: const Color(0x66903050),
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
      fillVolume(c, hoof, const Color(0xFFD7708E), light: 0.08, shadow: 0.14);
      c.drawLine(
        Offset(sx * 0.26, 0.98),
        Offset(sx * 0.26, 1.06),
        Paint()
          ..color = const Color(0x55702040)
          ..strokeWidth = 0.01,
      );
    }
  }

  static void _armPic(Canvas c) {
    final arm = smoothClosed(const [
      Offset(0.2, 0.44),
      Offset(0.34, 0.46),
      Offset(0.4, 0.62),
      Offset(0.4, 0.78),
      Offset(0.32, 0.86),
      Offset(0.22, 0.84),
      Offset(0.18, 0.66),
    ]);
    plush(
      c,
      arm,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => math.pi / 2,
      fur: 20,
      seed: 91,
      fringe: 0,
      furAlpha: 0.2,
      lightAmt: 0.08,
      shadowAmt: 0.14,
    );
    final hoof = smoothClosed(const [
      Offset(0.19, 0.8),
      Offset(0.3, 0.77),
      Offset(0.4, 0.8),
      Offset(0.41, 0.88),
      Offset(0.3, 0.91),
      Offset(0.2, 0.88),
    ]);
    fillVolume(c, hoof, const Color(0xFFD7708E), light: 0.08, shadow: 0.14);
  }

  static void _earPic(Canvas c) {
    final o = _o;
    // dreieckige, nach vorn geklappte Ohren
    final ear = smoothClosed([
      o + const Offset(0.1, -0.44),
      o + const Offset(0.3, -0.62),
      o + const Offset(0.58, -0.62),
      o + const Offset(0.66, -0.4),
      o + const Offset(0.5, -0.24),
      o + const Offset(0.28, -0.3),
    ], tension: 0.4);
    plush(
      c,
      ear,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => -math.pi / 4,
      fur: 30,
      seed: 61,
      fringe: 0,
      furAlpha: 0.2,
      lightAmt: 0.08,
      shadowAmt: 0.14,
    );
    final inner = smoothClosed([
      o + const Offset(0.24, -0.44),
      o + const Offset(0.38, -0.54),
      o + const Offset(0.54, -0.52),
      o + const Offset(0.56, -0.4),
      o + const Offset(0.44, -0.32),
    ], tension: 0.4);
    c.drawPath(
      inner,
      Paint()
        ..shader = ui.Gradient.linear(
          o + const Offset(0.3, -0.34),
          o + const Offset(0.54, -0.54),
          const [Color(0xFFFFB8CC), Color(0xFFF08CAB)],
        ),
    );
    c.drawPath(
      smoothOpen([
        o + const Offset(0.24, -0.46),
        o + const Offset(0.42, -0.5),
        o + const Offset(0.56, -0.46),
      ]),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.008
        ..color = const Color(0x55902050),
    );
  }

  static void _head(Canvas c) {
    final o = _o;
    final shape = smoothClosed([
      o + const Offset(0, -0.5),
      o + const Offset(0.34, -0.47),
      o + const Offset(0.56, -0.28),
      o + const Offset(0.66, 0.02),
      o + const Offset(0.62, 0.3),
      o + const Offset(0.44, 0.48),
      o + const Offset(0.18, 0.55),
      o + const Offset(0, 0.56),
      o + const Offset(-0.18, 0.55),
      o + const Offset(-0.44, 0.48),
      o + const Offset(-0.62, 0.3),
      o + const Offset(-0.66, 0.02),
      o + const Offset(-0.56, -0.28),
      o + const Offset(-0.34, -0.47),
    ]);
    softShadow(
      c,
      shape,
      offset: const Offset(0, 0.045),
      blur: 0.04,
      color: const Color(0x66903050),
    );
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      fur: 100,
      furLen: 0.05,
      seed: 51,
      fringe: 0,
      furAlpha: 0.2,
      lightAmt: 0.12,
      shadowAmt: 0.16,
    );
    softHighlight(
      c,
      shape,
      o + const Offset(-0.24, -0.32),
      0.3,
      0.12,
      alpha: 0.4,
      rot: -0.4,
    );
    // Härchen auf der Stirn
    for (var i = 0; i < 4; i++) {
      c.drawLine(
        o + Offset(-0.06 + i * 0.04, -0.44),
        o + Offset(-0.07 + i * 0.045, -0.5),
        Paint()
          ..color = furDark.withValues(alpha: 0.5)
          ..strokeWidth = 0.008
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  static void _snout(Canvas c) {
    final r = Rect.fromCenter(
      center: const Offset(0, 0.22),
      width: 0.5,
      height: 0.34,
    );
    final shape = Path()..addOval(r);
    softShadow(
      c,
      shape,
      offset: const Offset(0, 0.02),
      blur: 0.02,
      color: const Color(0x55902050),
    );
    c.drawOval(
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(-0.08, 0.14),
          0.4,
          const [Color(0xFFFFC6D6), snoutC, Color(0xFFD9708E)],
          const [0, 0.55, 1],
        ),
    );
    c.drawOval(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.012
        ..color = const Color(0x44A03060),
    );
  }
}
