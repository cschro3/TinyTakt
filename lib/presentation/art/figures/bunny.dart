import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import '../face.dart';
import '../rig.dart';
import 'premium_figure.dart';

/// Hase Hoppel: sehr lange Ohren (eins knickt leicht), rundes Wollknäuel-Fell, große Hinterfüße,
/// kleine Schneidezähne und eine Möhre im Arm.
class BunnyFigure extends PremiumFigure {
  const BunnyFigure();
  @override
  String get id => 'bunny';

  @override
  Personality get personality => const Personality(
    breathRate: 2.4,
    blinkEvery: 3.0,
    tailRate: 2.0,
    tailAmp: 0.3,
    earTwitch: 1.4,
    curiosity: 0.6,
    bounce: 1.7,
    seed: 6,
  );

  static const fur = Color(0xFFF2EBE3);
  static const furDark = Color(0xFFB8AB9E);
  static const furLight = Color(0xFFFFFFFF);
  static const pink = Color(0xFFF6A8C0);
  static const _o = Offset(0, -0.02);

  static const _face = FaceStyle(
    eyeGap: 0.24,
    eyeY: -0.04,
    eyeRx: 0.1,
    eyeRy: 0.125,
    iris: Color(0xFF8A4B5C),
    irisLight: Color(0xFFE8A0B0),
    lid: fur,
    lashes: true,
    mouthY: 0.27,
    mouthW: 0.055,
    noseY: 0.17,
    noseW: 0.04,
    noseColor: pink,
    blushY: 0.15,
    blushGap: 0.4,
    blushR: 0.075,
  );

  @override
  void paint(Canvas c, Pose p, double t) {
    c.save();
    c.translate(0, 0.28);
    c.scale(0.68);
    groundShadow(c, p, width: 1.0);
    c.translate(0, p.bodyDy);
    group(
      c,
      const Offset(0, 0.95),
      rot: p.lean,
      sx: 1 + p.squash * 0.4,
      sy: 1 - p.squash * 0.55,
      draw: () {
        group(
          c,
          const Offset(0, 0.95),
          sy: 1 + p.breath * 0.016,
          draw: () => c.drawPicture(PictureCache.get('bunny.body', _body)),
        );
        // Wollschwänzchen
        group(
          c,
          const Offset(0.5, 0.82),
          rot: p.tail * 0.3,
          draw: () {
            final shape = ellipsePath(0.58, 0.8, 0.13, 0.12);
            plush(
              c,
              shape,
              furLight,
              light: furLight,
              dark: furDark,
              fur: 0,
              fringe: 0.05,
              fringeSpacing: 0.04,
              fringeWidth: 0.07,
              lightAmt: 0.02,
            );
          },
        );
        c.drawPicture(PictureCache.get('bunny.feet', _feet));
        _arm(c, p, -1);
        _arm(c, p, 1);
        // Möhre im Arm (liegt vor dem Bauch)
        c.drawPicture(PictureCache.get('bunny.carrot', _carrot));
        group(
          c,
          const Offset(0, 0.3),
          rot: p.headTilt * 1.2 + p.lean * 0.5,
          move: Offset(0, p.headDy),
          draw: () {
            _ear(c, p, -1, t);
            _ear(c, p, 1, t);
            c.drawPicture(PictureCache.get('bunny.head', _head));
            c.save();
            c.translate(_o.dx, _o.dy);
            drawFace(c, _face, p);
            // Schneidezähne
            final wide = p.mouth == MouthShape.open ? 0.02 : 0.0;
            for (final sx in [-1.0, 1.0]) {
              final r = RRect.fromRectAndRadius(
                Rect.fromLTWH(sx > 0 ? 0.003 : -0.043, 0.3 + wide, 0.04, 0.05),
                const Radius.circular(0.012),
              );
              c.drawRRect(r, Paint()..color = Colors.white);
              c.drawRRect(
                r,
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 0.005
                  ..color = const Color(0x55704050),
              );
            }
            c.restore();
          },
        );
      },
    );
    c.restore();
    sparkles(c, p, t, color: const Color(0xFFFFD6EC));
  }

  void _ear(Canvas c, Pose p, double side, double t) {
    final rot =
        (side < 0 ? p.earL : p.earR) * 1.6 +
        math.sin(t * 1.1 + side * 2) * 0.03;
    group(
      c,
      Offset(side * 0.26, _o.dy - 0.46),
      rot: (side < 0 ? -rot : rot) + side * 0.06,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(
          PictureCache.get(
            side < 0 ? 'bunny.earL' : 'bunny.earR',
            side < 0 ? _earBent : _earPic,
          ),
        );
        c.restore();
      },
    );
  }

  void _arm(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.armL : p.armR;
    group(
      c,
      Offset(side * 0.26, 0.5),
      rot: (side < 0 ? -rot : rot) * 1.3,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('bunny.arm', _armPic));
        c.restore();
      },
    );
  }

  static void _body(Canvas c) {
    final shape = smoothClosed(const [
      Offset(0, 0.2),
      Offset(0.28, 0.22),
      Offset(0.48, 0.4),
      Offset(0.58, 0.64),
      Offset(0.5, 0.88),
      Offset(0.24, 0.98),
      Offset(0, 0.99),
      Offset(-0.24, 0.98),
      Offset(-0.5, 0.88),
      Offset(-0.58, 0.64),
      Offset(-0.48, 0.4),
      Offset(-0.28, 0.22),
    ]);
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => math.pi / 2 + p.dx * 0.8,
      fur: 260,
      seed: 81,
      fringe: 0.05,
      fringeSpacing: 0.04,
      fringeWidth: 0.07,
      skipFringe: (p) => p.dy < 0.3 || p.dy > 0.93,
    );
    final belly = smoothClosed(const [
      Offset(0, 0.38),
      Offset(0.2, 0.44),
      Offset(0.3, 0.64),
      Offset(0.22, 0.88),
      Offset(0, 0.95),
      Offset(-0.22, 0.88),
      Offset(-0.3, 0.64),
      Offset(-0.2, 0.44),
    ]);
    c.save();
    c.clipPath(shape);
    plush(
      c,
      belly,
      furLight,
      light: Colors.white,
      dark: mix(furLight, fur, 0.5),
      flow: (p) => math.pi / 2,
      fur: 100,
      seed: 82,
      fringe: 0,
      lightAmt: 0.02,
      shadowAmt: 0.05,
    );
    c.restore();
    softShadow(
      c,
      ellipsePath(0, 0.22, 0.4, 0.1),
      offset: const Offset(0, 0.05),
      blur: 0.05,
      color: const Color(0x55705A4A),
      clip: shape,
    );
  }

  static void _feet(Canvas c) {
    // große Hasenfüße, vorn sichtbar
    for (final sx in [-1.0, 1.0]) {
      final foot = smoothClosed([
        Offset(sx * 0.1, 0.9),
        Offset(sx * 0.3, 0.86),
        Offset(sx * 0.52, 0.92),
        Offset(sx * 0.56, 1.02),
        Offset(sx * 0.3, 1.07),
        Offset(sx * 0.1, 1.03),
      ], tension: 0.6);
      plush(
        c,
        foot,
        fur,
        light: furLight,
        dark: furDark,
        fur: 40,
        seed: 95,
        fringe: 0.025,
        lightAmt: 0.06,
        shadowAmt: 0.12,
      );
      final pad = Offset(sx * 0.32, 1.0);
      c.drawOval(
        Rect.fromCenter(center: pad, width: 0.16, height: 0.07),
        Paint()..color = pink.withValues(alpha: 0.85),
      );
      for (var k = 0; k < 3; k++) {
        c.drawCircle(
          Offset(sx * (0.2 + k * 0.1), 0.93),
          0.016,
          Paint()..color = pink.withValues(alpha: 0.85),
        );
      }
    }
  }

  static void _carrot(Canvas c) {
    c.save();
    c.translate(0.02, 0.62);
    c.rotate(0.35);
    final body = Path()
      ..moveTo(-0.07, -0.16)
      ..quadraticBezierTo(-0.1, 0.05, 0.0, 0.26)
      ..quadraticBezierTo(0.1, 0.05, 0.07, -0.16)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-0.1, 0),
          const Offset(0.1, 0),
          const [Color(0xFFFFB066), Color(0xFFFF8A2E), Color(0xFFE56A12)],
          const [0, 0.5, 1],
        ),
    );
    for (var i = 0; i < 4; i++) {
      c.drawLine(
        Offset(-0.05, -0.09 + i * 0.07),
        Offset(0.02, -0.07 + i * 0.07),
        Paint()
          ..color = const Color(0x55A04A08)
          ..strokeWidth = 0.008
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final a in [-0.4, 0.0, 0.4]) {
      c.save();
      c.translate(0, -0.16);
      c.rotate(a);
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(-0.04, -0.1, 0, -0.2)
          ..quadraticBezierTo(0.04, -0.1, 0, 0)
          ..close(),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            const Offset(0, -0.2),
            const [Color(0xFF3FA650), Color(0xFF7DD65A)],
          ),
      );
      c.restore();
    }
    c.restore();
  }

  static void _armPic(Canvas c) {
    final arm = smoothClosed(const [
      Offset(0.12, 0.44),
      Offset(0.26, 0.46),
      Offset(0.32, 0.62),
      Offset(0.3, 0.76),
      Offset(0.22, 0.82),
      Offset(0.12, 0.78),
      Offset(0.1, 0.6),
    ]);
    plush(
      c,
      arm,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => math.pi / 2,
      fur: 40,
      seed: 91,
      fringe: 0.025,
      skipFringe: (p) => p.dy < 0.5,
      lightAmt: 0.06,
    );
  }

  static void _earPic(Canvas c) => _earShape(c, bend: 0.0);
  static void _earBent(Canvas c) => _earShape(c, bend: 1.0);

  static void _earShape(Canvas c, {required double bend}) {
    final o = _o;
    // sehr lange, schmale Ohren; [bend] knickt die Spitze
    final tipX = 0.46 + 0.18 * bend, tipY = -1.55 + 0.38 * bend;
    final ear = smoothClosed([
      o + const Offset(0.1, -0.46),
      o + const Offset(0.16, -0.8),
      o + Offset(0.28 + 0.04 * bend, -1.15 + 0.1 * bend),
      o + Offset(tipX, tipY),
      o + Offset(tipX + 0.12, tipY + 0.14),
      o + Offset(0.5 + 0.04 * bend, -1.1 + 0.1 * bend),
      o + const Offset(0.5, -0.7),
      o + const Offset(0.42, -0.42),
      o + const Offset(0.26, -0.36),
    ], tension: 0.55);
    plush(
      c,
      ear,
      fur,
      light: furLight,
      dark: furDark,
      flow: (p) => -math.pi / 2,
      fur: 80,
      seed: 61 + bend.toInt(),
      fringe: 0.03,
      lightAmt: 0.06,
    );
    final inner = smoothClosed([
      o + const Offset(0.2, -0.5),
      o + const Offset(0.24, -0.8),
      o + Offset(0.34 + 0.03 * bend, -1.12 + 0.1 * bend),
      o + Offset(tipX - 0.02, tipY + 0.1),
      o + Offset(0.46 + 0.03 * bend, -1.08 + 0.1 * bend),
      o + const Offset(0.44, -0.74),
      o + const Offset(0.38, -0.46),
      o + const Offset(0.28, -0.42),
    ], tension: 0.55);
    c.drawPath(
      inner,
      Paint()
        ..shader = ui.Gradient.linear(
          o + const Offset(0.3, -0.4),
          o + Offset(0.4, tipY),
          const [Color(0xFFF8B8CC), Color(0xFFF6A0BC), Color(0xFFFAD0DC)],
          const [0, 0.5, 1],
        ),
    );
  }

  static void _head(Canvas c) {
    final o = _o;
    final shape = smoothClosed([
      o + const Offset(0, -0.46),
      o + const Offset(0.3, -0.43),
      o + const Offset(0.5, -0.26),
      o + const Offset(0.58, 0.02),
      o + const Offset(0.52, 0.26),
      o + const Offset(0.34, 0.4),
      o + const Offset(0.12, 0.45),
      o + const Offset(0, 0.46),
      o + const Offset(-0.12, 0.45),
      o + const Offset(-0.34, 0.4),
      o + const Offset(-0.52, 0.26),
      o + const Offset(-0.58, 0.02),
      o + const Offset(-0.5, -0.26),
      o + const Offset(-0.3, -0.43),
    ]);
    softShadow(
      c,
      shape,
      offset: const Offset(0, 0.04),
      blur: 0.04,
      color: const Color(0x55705A4A),
    );
    plush(
      c,
      shape,
      fur,
      light: furLight,
      dark: furDark,
      fur: 320,
      seed: 51,
      fringe: 0.06,
      fringeSpacing: 0.04,
      fringeWidth: 0.07,
      skipFringe: (p) =>
          p.dy < o.dy - 0.35 || (p.dy > o.dy + 0.4 && p.dx.abs() < 0.3),
      lightAmt: 0.06,
    );
    final muzzle = smoothClosed([
      o + const Offset(0, 0.06),
      o + const Offset(0.16, 0.1),
      o + const Offset(0.24, 0.24),
      o + const Offset(0.14, 0.4),
      o + const Offset(0, 0.43),
      o + const Offset(-0.14, 0.4),
      o + const Offset(-0.24, 0.24),
      o + const Offset(-0.16, 0.1),
    ], tension: 0.6);
    c.save();
    c.clipPath(shape);
    plush(
      c,
      muzzle,
      furLight,
      light: Colors.white,
      dark: mix(furLight, fur, 0.4),
      fur: 60,
      seed: 52,
      fringe: 0,
      lightAmt: 0.02,
      shadowAmt: 0.06,
    );
    c.restore();
    softHighlight(
      c,
      shape,
      o + const Offset(-0.22, -0.3),
      0.24,
      0.09,
      alpha: 0.35,
      rot: -0.4,
    );
    for (final sx in [-1.0, 1.0]) {
      for (var k = 0; k < 3; k++) {
        c.drawCircle(
          o + Offset(sx * (0.12 + k * 0.045), 0.24 + k * 0.025),
          0.008,
          Paint()..color = furDark.withValues(alpha: 0.45),
        );
      }
    }
  }
}
