import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import '../face.dart';
import '../rig.dart';
import 'premium_figure.dart';

/// Katze Mimi: schlanke, elegante Tabby-Katze mit spitzen Ohren, grünen Schlitzaugen,
/// Streifen, langem geschwungenem Schwanz und Glöckchen am Halsband.
class CatFigure extends PremiumFigure {
  const CatFigure();
  @override
  String get id => 'cat';

  @override
  Personality get personality => const Personality(
    breathRate: 1.5,
    blinkEvery: 5.2,
    tailRate: 1.4,
    tailAmp: 0.9,
    earTwitch: 1.0,
    curiosity: 0.5,
    bounce: 0.9,
    seed: 4,
  );

  static const fur = Color(0xFF9FA8BA);
  static const furDark = Color(0xFF5A6478);
  static const furLight = Color(0xFFE4E9F2);
  static const pinkIn = Color(0xFFF2A6BA);
  static const _o = Offset(0, -0.14);

  static const _face = FaceStyle(
    eyeGap: 0.25,
    eyeY: -0.02,
    eyeRx: 0.108,
    eyeRy: 0.125,
    iris: Color(0xFF3FA66B),
    irisLight: Color(0xFFD2F5A8),
    lid: fur,
    slit: true,
    lashes: false,
    mouthY: 0.26,
    mouthW: 0.065,
    noseY: 0.16,
    noseW: 0.04,
    noseColor: Color(0xFFF08AA4),
    blushY: 0.15,
    blushGap: 0.4,
    blushR: 0.07,
  );

  @override
  void paint(Canvas c, Pose p, double t) {
    c.save();
    c.translate(0, 0.16);
    c.scale(0.8);
    groundShadow(c, p, width: 0.9);
    c.translate(0, p.bodyDy);
    group(
      c,
      const Offset(0, 0.95),
      rot: p.lean,
      sx: 1 + p.squash * 0.3,
      sy: 1 - p.squash * 0.45,
      draw: () {
        // langer, elegant schwingender Schwanz
        group(
          c,
          const Offset(0.36, 0.86),
          rot: p.tail * 0.5,
          draw: () => c.drawPicture(PictureCache.get('cat.tail', _tail)),
        );
        group(
          c,
          const Offset(0, 0.95),
          sy: 1 + p.breath * 0.012,
          draw: () => c.drawPicture(PictureCache.get('cat.body', _body)),
        );
        _arm(c, p, -1);
        _arm(c, p, 1);
        c.drawPicture(PictureCache.get('cat.collar', _collar));
        group(
          c,
          const Offset(0, 0.3),
          rot: p.headTilt * 1.2 + p.lean * 0.5,
          move: Offset(0, p.headDy),
          draw: () {
            _ear(c, p, -1);
            _ear(c, p, 1);
            c.drawPicture(PictureCache.get('cat.head', _head));
            c.save();
            c.translate(_o.dx, _o.dy);
            drawFace(c, _face, p);
            _whiskers(c, p);
            c.restore();
          },
        );
      },
    );
    c.restore();
    sparkles(c, p, t, color: const Color(0xFFFFD6F0));
  }

  void _whiskers(Canvas c, Pose p) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.008
      ..color = Colors.white.withValues(alpha: 0.9);
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.012
      ..color = furDark.withValues(alpha: 0.25);
    for (final sx in [-1.0, 1.0]) {
      for (var k = 0; k < 3; k++) {
        final y = 0.19 + k * 0.035;
        final path = Path()
          ..moveTo(sx * 0.18, y)
          ..quadraticBezierTo(
            sx * 0.42,
            y - 0.03 + k * 0.03,
            sx * (0.6 + p.look.dx * 0.01),
            y - 0.05 + k * 0.06,
          );
        c.drawPath(path.shift(const Offset(0, 0.006)), shadow);
        c.drawPath(path, paint);
      }
    }
  }

  void _ear(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.earL : p.earR;
    group(
      c,
      Offset(side * 0.34, _o.dy - 0.38),
      rot: (side < 0 ? -rot : rot) * 1.5,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('cat.ear', _earPic));
        c.restore();
      },
    );
  }

  void _arm(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.armL : p.armR;
    group(
      c,
      Offset(side * 0.22, 0.4),
      rot: (side < 0 ? -rot : rot) * 1.3,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('cat.arm', _armPic));
        c.restore();
      },
    );
  }

  static void _stripes(
    Canvas c,
    Path clip,
    List<(Offset, Offset, double)> list,
  ) {
    c.save();
    c.clipPath(clip);
    for (final s in list) {
      final path = Path()
        ..moveTo(s.$1.dx, s.$1.dy)
        ..quadraticBezierTo(
          (s.$1.dx + s.$2.dx) / 2 + s.$3,
          (s.$1.dy + s.$2.dy) / 2,
          s.$2.dx,
          s.$2.dy,
        );
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.05
          ..color = furDark.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.008),
      );
    }
    c.restore();
  }

  static void _tail(Canvas c) {
    // lang, S-förmig nach oben, geringelt
    final shape = smoothClosed(const [
      Offset(0.34, 0.94),
      Offset(0.6, 0.98),
      Offset(0.84, 0.9),
      Offset(0.96, 0.7),
      Offset(0.92, 0.46),
      Offset(0.82, 0.28),
      Offset(0.88, 0.14),
      Offset(0.8, 0.08),
      Offset(0.72, 0.2),
      Offset(0.76, 0.42),
      Offset(0.74, 0.62),
      Offset(0.62, 0.78),
      Offset(0.4, 0.8),
    ], tension: 0.55);
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => -math.pi / 2,
      fur: 120,
      seed: 71,
      fringe: 0.03,
    );
    _stripes(c, shape, [
      (const Offset(0.68, 0.3), const Offset(0.96, 0.34), 0.0),
      (const Offset(0.68, 0.48), const Offset(0.98, 0.5), 0.0),
      (const Offset(0.66, 0.66), const Offset(0.98, 0.68), 0.0),
    ]);
    softHighlight(c, shape, const Offset(0.8, 0.5), 0.05, 0.3, alpha: 0.2);
    final tip = ellipsePath(0.8, 0.12, 0.07, 0.07);
    c.save();
    c.clipPath(shape);
    c.drawPath(tip, Paint()..color = furDark);
    c.restore();
  }

  static void _body(Canvas c) {
    // schlanker, aufrecht sitzender Körper
    final shape = smoothClosed(const [
      Offset(0, 0.12),
      Offset(0.24, 0.14),
      Offset(0.4, 0.32),
      Offset(0.48, 0.6),
      Offset(0.44, 0.86),
      Offset(0.24, 0.97),
      Offset(0, 0.98),
      Offset(-0.24, 0.97),
      Offset(-0.44, 0.86),
      Offset(-0.48, 0.6),
      Offset(-0.4, 0.32),
      Offset(-0.24, 0.14),
    ]);
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => math.pi / 2 + p.dx * 0.5,
      fur: 220,
      seed: 81,
      fringe: 0.025,
      skipFringe: (p) => p.dy < 0.24 || p.dy > 0.93,
    );
    _stripes(c, shape, [
      (const Offset(-0.46, 0.4), const Offset(-0.24, 0.44), 0.0),
      (const Offset(-0.5, 0.58), const Offset(-0.28, 0.6), 0.0),
      (const Offset(-0.46, 0.76), const Offset(-0.26, 0.78), 0.0),
      (const Offset(0.46, 0.4), const Offset(0.24, 0.44), 0.0),
      (const Offset(0.5, 0.58), const Offset(0.28, 0.6), 0.0),
      (const Offset(0.46, 0.76), const Offset(0.26, 0.78), 0.0),
    ]);
    final belly = smoothClosed(const [
      Offset(0, 0.3),
      Offset(0.16, 0.38),
      Offset(0.22, 0.6),
      Offset(0.16, 0.84),
      Offset(0, 0.92),
      Offset(-0.16, 0.84),
      Offset(-0.22, 0.6),
      Offset(-0.16, 0.38),
    ]);
    c.save();
    c.clipPath(shape);
    plush(
      c,
      belly,
      furLight,
      light: Colors.white,
      dark: mix(furLight, fur, 0.4),
      flow: (p) => math.pi / 2,
      fur: 90,
      seed: 82,
      fringe: 0,
      lightAmt: 0.04,
      shadowAmt: 0.08,
    );
    c.restore();
    for (final sx in [-1.0, 1.0]) {
      final foot = smoothClosed([
        Offset(sx * 0.08, 0.94),
        Offset(sx * 0.2, 0.9),
        Offset(sx * 0.34, 0.93),
        Offset(sx * 0.36, 1.01),
        Offset(sx * 0.2, 1.04),
        Offset(sx * 0.07, 1.01),
      ]);
      fillVolume(c, foot, furLight, light: 0.05, shadow: 0.12);
    }
  }

  static void _collar(Canvas c) {
    final band = Path()
      ..moveTo(-0.27, 0.16)
      ..quadraticBezierTo(0, 0.3, 0.27, 0.16)
      ..lineTo(0.26, 0.24)
      ..quadraticBezierTo(0, 0.38, -0.26, 0.24)
      ..close();
    c.drawPath(
      band,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0.18),
          const Offset(0, 0.36),
          const [Color(0xFF6EC1F5), Color(0xFF3F8FD9)],
        ),
    );
    final bell = const Offset(0, 0.39);
    c.drawCircle(
      bell,
      0.045,
      Paint()
        ..shader = ui.Gradient.radial(
          bell + const Offset(-0.014, -0.014),
          0.065,
          const [Color(0xFFFFF2A8), Color(0xFFFFC21E), Color(0xFFD9980E)],
          const [0, 0.5, 1],
        ),
    );
    c.drawLine(
      bell + const Offset(-0.03, 0.005),
      bell + const Offset(0.03, 0.005),
      Paint()
        ..color = const Color(0x66704A08)
        ..strokeWidth = 0.006,
    );
    gloss(c, bell + const Offset(-0.015, -0.015), 0.012, alpha: 0.9);
  }

  static void _armPic(Canvas c) {
    final arm = smoothClosed(const [
      Offset(0.15, 0.34),
      Offset(0.27, 0.36),
      Offset(0.32, 0.54),
      Offset(0.32, 0.72),
      Offset(0.26, 0.8),
      Offset(0.17, 0.78),
      Offset(0.13, 0.6),
    ]);
    plush(
      c,
      arm,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => math.pi / 2,
      fur: 50,
      seed: 91,
      fringe: 0.02,
      skipFringe: (p) => p.dy < 0.42,
    );
    final paw = smoothClosed(const [
      Offset(0.14, 0.7),
      Offset(0.22, 0.67),
      Offset(0.32, 0.7),
      Offset(0.34, 0.8),
      Offset(0.25, 0.86),
      Offset(0.16, 0.82),
    ]);
    fillVolume(c, paw, furLight, light: 0.05, shadow: 0.1);
    toeLines(
      c,
      const Offset(0.24, 0.78),
      0.055,
      furDark.withValues(alpha: 0.35),
      n: 3,
      len: 0.04,
    );
  }

  static void _earPic(Canvas c) {
    final o = _o;
    final ear = smoothClosed([
      o + const Offset(0.1, -0.4),
      o + const Offset(0.2, -0.64),
      o + const Offset(0.36, -0.9),
      o + const Offset(0.52, -0.62),
      o + const Offset(0.58, -0.36),
      o + const Offset(0.44, -0.24),
    ], tension: 0.35);
    plush(
      c,
      ear,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => -math.pi / 2,
      fur: 40,
      seed: 61,
      fringe: 0.025,
    );
    final inner = smoothClosed([
      o + const Offset(0.2, -0.4),
      o + const Offset(0.28, -0.6),
      o + const Offset(0.36, -0.76),
      o + const Offset(0.46, -0.58),
      o + const Offset(0.5, -0.4),
      o + const Offset(0.4, -0.32),
    ], tension: 0.35);
    c.drawPath(
      inner,
      Paint()
        ..shader = ui.Gradient.linear(
          o + const Offset(0.35, -0.3),
          o + const Offset(0.36, -0.76),
          [const Color(0xFFF7B8C8), pinkIn],
        ),
    );
    // feine helle Härchen im Ohr
    for (var i = 0; i < 6; i++) {
      c.drawLine(
        o + Offset(0.3 + i * 0.03, -0.38),
        o + Offset(0.33 + i * 0.025, -0.52 - i * 0.015),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 0.006
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  static void _head(Canvas c) {
    final o = _o;
    // breiter, flacher Katzenkopf mit leichten Wangen
    final shape = smoothClosed([
      o + const Offset(0, -0.46),
      o + const Offset(0.3, -0.44),
      o + const Offset(0.54, -0.28),
      o + const Offset(0.6, -0.04),
      o + const Offset(0.54, 0.2),
      o + const Offset(0.36, 0.38),
      o + const Offset(0.12, 0.44),
      o + const Offset(0, 0.45),
      o + const Offset(-0.12, 0.44),
      o + const Offset(-0.36, 0.38),
      o + const Offset(-0.54, 0.2),
      o + const Offset(-0.6, -0.04),
      o + const Offset(-0.54, -0.28),
      o + const Offset(-0.3, -0.44),
    ]);
    softShadow(
      c,
      shape,
      offset: const Offset(0, 0.04),
      blur: 0.04,
      color: const Color(0x663A4660),
    );
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      fur: 300,
      seed: 51,
      fringe: 0.045,
      fringeSpacing: 0.04,
      skipFringe: (p) => p.dy < o.dy - 0.3 || p.dy > o.dy + 0.4,
    );
    // Stirnstreifen (M-Zeichnung)
    _stripes(c, shape, [
      (o + const Offset(0, -0.46), o + const Offset(0, -0.26), 0.0),
      (o + const Offset(-0.14, -0.44), o + const Offset(-0.1, -0.28), -0.02),
      (o + const Offset(0.14, -0.44), o + const Offset(0.1, -0.28), 0.02),
      (o + const Offset(-0.56, 0.0), o + const Offset(-0.4, 0.04), 0.0),
      (o + const Offset(0.56, 0.0), o + const Offset(0.4, 0.04), 0.0),
    ]);
    final muzzle = smoothClosed([
      o + const Offset(0, 0.04),
      o + const Offset(0.16, 0.08),
      o + const Offset(0.24, 0.22),
      o + const Offset(0.16, 0.38),
      o + const Offset(0, 0.42),
      o + const Offset(-0.16, 0.38),
      o + const Offset(-0.24, 0.22),
      o + const Offset(-0.16, 0.08),
    ], tension: 0.6);
    c.save();
    c.clipPath(shape);
    plush(
      c,
      muzzle,
      furLight,
      light: Colors.white,
      dark: mix(furLight, fur, 0.4),
      fur: 80,
      seed: 52,
      fringe: 0,
      lightAmt: 0.04,
      shadowAmt: 0.08,
    );
    c.restore();
    softHighlight(
      c,
      shape,
      o + const Offset(-0.22, -0.3),
      0.24,
      0.09,
      alpha: 0.22,
      rot: -0.4,
    );
  }
}
