import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import '../face.dart';
import '../rig.dart';
import 'premium_figure.dart';

/// Papagei Pip: aufrecht auf einem Ast, gebogener Schnabel, bunte Federhaube,
/// Gefiederschuppen, lange Schwanzfedern und Flügel, die beim Jubeln ausschlagen.
class ParrotFigure extends PremiumFigure {
  const ParrotFigure();
  @override
  String get id => 'parrot';

  @override
  Personality get personality => const Personality(
    breathRate: 2.2,
    blinkEvery: 3.0,
    tailRate: 1.6,
    tailAmp: 0.25,
    earTwitch: 1.0,
    curiosity: 0.9,
    bounce: 1.1,
    seed: 8,
  );

  static const green = Color(0xFF3DBE6C);
  static const greenDark = Color(0xFF1C8A4C);
  static const greenLight = Color(0xFF9CEB8A);
  static const yellow = Color(0xFFFFD84D);
  static const red = Color(0xFFE5574B);
  static const blue = Color(0xFF3F8FD9);
  static const beak = Color(0xFFFF9F43);
  static const _o = Offset(0, -0.3);

  static const _face = FaceStyle(
    eyeGap: 0.27,
    eyeY: -0.06,
    eyeRx: 0.075,
    eyeRy: 0.09,
    iris: Color(0xFF3A2418),
    irisLight: Color(0xFFA06A3A),
    eyeBase: Color(0xFF1A1220),
    lid: green,
    showNose: false,
    showMouth: false,
    eyeRing: Color(0xFFFFF6E8),
    blushY: 0.1,
    blushGap: 0.44,
    blushR: 0.07,
    blush: Color(0xFFFF7A6A),
  );

  @override
  void paint(Canvas c, Pose p, double t) {
    c.save();
    c.translate(0, 0.14);
    c.scale(0.8);
    groundShadow(c, p, width: 0.9, y: 1.0);
    // Ast
    c.drawPicture(PictureCache.get('parrot.branch', _branch));
    c.translate(0, p.bodyDy);
    group(
      c,
      const Offset(0, 0.92),
      rot: p.lean,
      sx: 1 + p.squash * 0.35,
      sy: 1 - p.squash * 0.5,
      draw: () {
        // Schwanzfedern
        group(
          c,
          const Offset(0, 0.8),
          rot: p.tail * 0.1,
          draw: () => c.drawPicture(PictureCache.get('parrot.tail', _tail)),
        );
        group(
          c,
          const Offset(0, 0.92),
          sy: 1 + p.breath * 0.014,
          draw: () => c.drawPicture(PictureCache.get('parrot.body', _body)),
        );
        c.drawPicture(PictureCache.get('parrot.feet', _feet));
        _wing(c, p, -1);
        _wing(c, p, 1);
        group(
          c,
          const Offset(0, 0.2),
          rot: p.headTilt * 1.4 + p.lean * 0.5,
          move: Offset(p.look.dx * 0.01, p.headDy),
          draw: () {
            // Haube (Federn stellen sich bei Freude auf)
            final lift =
                (p.eyes == EyeMode.wide || p.mouth == MouthShape.open
                    ? 0.12
                    : 0.0) +
                p.earL * 0.5;
            for (var i = 0; i < 3; i++) {
              group(
                c,
                _o + const Offset(0, -0.4),
                rot: (i - 1) * (0.32 + lift),
                draw: () {
                  c.drawPicture(PictureCache.get('parrot.crest', _crest));
                },
              );
            }
            c.drawPicture(PictureCache.get('parrot.head', _head));
            c.save();
            c.translate(_o.dx, _o.dy);
            drawFace(c, _face, p);
            c.restore();
            _beak(c, p);
          },
        );
      },
    );
    c.restore();
    sparkles(c, p, t, color: const Color(0xFFFFE27A));
  }

  /// Gebogener Schnabel; Unterschnabel öffnet sich beim Sprechen/Jubeln.
  void _beak(Canvas c, Pose p) {
    final open = switch (p.mouth) {
      MouthShape.open => 0.07,
      MouthShape.grin => 0.035,
      MouthShape.o => 0.05,
      _ => 0.0,
    };
    final o = _o;
    // Unterschnabel
    final lower = Path()
      ..moveTo(o.dx - 0.1, o.dy + 0.12 + open * 0.2)
      ..quadraticBezierTo(
        o.dx,
        o.dy + 0.3 + open,
        o.dx + 0.1,
        o.dy + 0.12 + open * 0.2,
      )
      ..quadraticBezierTo(
        o.dx,
        o.dy + 0.2 + open * 0.6,
        o.dx - 0.1,
        o.dy + 0.12 + open * 0.2,
      )
      ..close();
    c.drawPath(
      lower,
      Paint()
        ..shader = ui.Gradient.linear(
          o + const Offset(0, 0.12),
          o + const Offset(0, 0.3),
          [shade(beak, -0.02), shade(beak, -0.16)],
        ),
    );
    if (open > 0) {
      c.drawPath(
        Path()
          ..moveTo(o.dx - 0.08, o.dy + 0.15)
          ..quadraticBezierTo(
            o.dx,
            o.dy + 0.22 + open,
            o.dx + 0.08,
            o.dy + 0.15,
          )
          ..close(),
        Paint()..color = const Color(0xFF7A2A44),
      );
    }
    // Oberschnabel: kräftig gebogen
    final upper = Path()
      ..moveTo(o.dx - 0.16, o.dy + 0.0)
      ..cubicTo(
        o.dx - 0.16,
        o.dy + 0.2 - open * 0.3,
        o.dx - 0.04,
        o.dy + 0.34 - open * 0.3,
        o.dx,
        o.dy + 0.34 - open * 0.3,
      )
      ..cubicTo(
        o.dx + 0.04,
        o.dy + 0.34 - open * 0.3,
        o.dx + 0.16,
        o.dy + 0.2 - open * 0.3,
        o.dx + 0.16,
        o.dy + 0.0,
      )
      ..cubicTo(
        o.dx + 0.1,
        o.dy - 0.08,
        o.dx - 0.1,
        o.dy - 0.08,
        o.dx - 0.16,
        o.dy + 0.0,
      )
      ..close();
    c.drawPath(
      upper,
      Paint()
        ..shader = ui.Gradient.linear(
          o + const Offset(-0.16, -0.05),
          o + const Offset(0.16, 0.3),
          const [Color(0xFFFFD08A), beak, Color(0xFFE5791A)],
          const [0, 0.5, 1],
        ),
    );
    c.drawPath(
      upper,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.008
        ..color = const Color(0x55803A08),
    );
    for (final sx in [-1.0, 1.0]) {
      c.drawOval(
        Rect.fromCenter(
          center: o + Offset(sx * 0.045, 0.045),
          width: 0.035,
          height: 0.022,
        ),
        Paint()..color = const Color(0x77603008),
      );
    }
    gloss(c, o + const Offset(-0.07, 0.04), 0.018, alpha: 0.75);
  }

  void _wing(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.armL : p.armR;
    group(
      c,
      Offset(side * 0.42, 0.22),
      rot: (side < 0 ? -rot : rot) * 0.9,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('parrot.wing', _wingPic));
        c.restore();
      },
    );
  }

  static void _branch(Canvas c) {
    final wood = const Color(0xFF8A5A33);
    final branch = Path()
      ..moveTo(-0.95, 1.0)
      ..quadraticBezierTo(0, 0.93, 0.95, 1.02)
      ..lineTo(0.95, 1.1)
      ..quadraticBezierTo(0, 1.03, -0.95, 1.1)
      ..close();
    c.drawPath(
      branch,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0.95),
          const Offset(0, 1.1),
          [shade(wood, 0.1), wood, shade(wood, -0.15)],
          const [0, 0.5, 1],
        ),
    );
    for (final x in [-0.5, 0.2, 0.7]) {
      c.drawLine(
        Offset(x, 1.0),
        Offset(x + 0.08, 1.07),
        Paint()
          ..color = const Color(0x44301808)
          ..strokeWidth = 0.01
          ..strokeCap = StrokeCap.round,
      );
    }
    // Blatt
    final leaf = Path()
      ..moveTo(0.7, 1.0)
      ..quadraticBezierTo(0.85, 0.86, 1.0, 0.92)
      ..quadraticBezierTo(0.92, 1.02, 0.7, 1.0)
      ..close();
    c.drawPath(
      leaf,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0.7, 1.0),
          const Offset(1.0, 0.9),
          const [Color(0xFF3FA650), Color(0xFF7DD65A)],
        ),
    );
  }

  static void _tail(Canvas c) {
    final cols = [
      blue,
      const Color(0xFF2F6FC9),
      red,
      blue,
      const Color(0xFF58A8F0),
    ];
    for (var i = 0; i < 5; i++) {
      c.save();
      c.translate(0, 0.8);
      c.rotate((i - 2) * 0.12);
      final f = Path()
        ..moveTo(-0.05, 0)
        ..quadraticBezierTo(-0.1, 0.22, -0.04, 0.42 + (i == 2 ? 0.08 : 0))
        ..quadraticBezierTo(
          0,
          0.46 + (i == 2 ? 0.08 : 0),
          0.04,
          0.42 + (i == 2 ? 0.08 : 0),
        )
        ..quadraticBezierTo(0.1, 0.22, 0.05, 0)
        ..close();
      c.drawPath(
        f,
        Paint()
          ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 0.45), [
            cols[i],
            shade(cols[i], -0.15),
          ]),
      );
      c.drawLine(
        Offset.zero,
        const Offset(0, 0.4),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..strokeWidth = 0.008,
      );
      c.restore();
    }
  }

  static void _body(Canvas c) {
    final shape = smoothClosed(const [
      Offset(0, 0.08),
      Offset(0.3, 0.12),
      Offset(0.48, 0.32),
      Offset(0.52, 0.58),
      Offset(0.4, 0.82),
      Offset(0.18, 0.94),
      Offset(0, 0.95),
      Offset(-0.18, 0.94),
      Offset(-0.4, 0.82),
      Offset(-0.52, 0.58),
      Offset(-0.48, 0.32),
      Offset(-0.3, 0.12),
    ]);
    fillVolume(c, shape, green, light: 0.1, shadow: 0.2);
    featherScales(
      c,
      shape,
      base: greenLight,
      edge: greenDark,
      size: 0.075,
      seed: 3,
      alpha: 0.5,
    );
    // gelber Bauch/Brust mit Federn
    final chest = smoothClosed(const [
      Offset(0, 0.26),
      Offset(0.22, 0.34),
      Offset(0.3, 0.58),
      Offset(0.2, 0.84),
      Offset(0, 0.92),
      Offset(-0.2, 0.84),
      Offset(-0.3, 0.58),
      Offset(-0.22, 0.34),
    ]);
    c.save();
    c.clipPath(shape);
    fillVolume(c, chest, yellow, light: 0.08, shadow: 0.12);
    featherScales(
      c,
      chest,
      base: Colors.white,
      edge: const Color(0xFFD9A81E),
      size: 0.06,
      seed: 4,
      alpha: 0.45,
    );
    c.restore();
    softShadow(
      c,
      ellipsePath(0, 0.1, 0.34, 0.1),
      offset: const Offset(0, 0.05),
      blur: 0.05,
      color: const Color(0x66104A28),
      clip: shape,
    );
  }

  static void _feet(Canvas c) {
    for (final sx in [-1.0, 1.0]) {
      final toes = Path()
        ..moveTo(sx * 0.12, 0.92)
        ..lineTo(sx * 0.12, 0.99)
        ..moveTo(sx * 0.2, 0.92)
        ..lineTo(sx * 0.24, 0.99)
        ..moveTo(sx * 0.04, 0.92)
        ..lineTo(sx * 0.0, 0.99);
      c.drawPath(
        toes,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.035
          ..color = const Color(0xFFE5A24A),
      );
      c.drawPath(
        toes,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.012
          ..color = const Color(0xFFFFD08A),
      );
      c.drawCircle(
        Offset(sx * 0.14, 0.9),
        0.04,
        Paint()..color = const Color(0xFFF2B060),
      );
    }
  }

  static void _wingPic(Canvas c) {
    final shape = smoothClosed(const [
      Offset(0.38, 0.2),
      Offset(0.52, 0.28),
      Offset(0.6, 0.5),
      Offset(0.58, 0.76),
      Offset(0.5, 0.92),
      Offset(0.42, 0.86),
      Offset(0.4, 0.6),
      Offset(0.34, 0.36),
    ], tension: 0.55);
    fillVolume(c, shape, greenDark, light: 0.08, shadow: 0.14);
    featherScales(
      c,
      shape,
      base: green,
      edge: const Color(0xFF0E5A30),
      size: 0.07,
      seed: 5,
      alpha: 0.5,
    );
    // Schwungfedern mit blauer Spitze
    c.save();
    c.clipPath(shape);
    final tip = Path()..addRect(const Rect.fromLTWH(0.3, 0.72, 0.4, 0.3));
    c.drawPath(
      tip,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0.72),
          const Offset(0, 0.95),
          [blue.withValues(alpha: 0.0), blue.withValues(alpha: 0.85)],
        ),
    );
    c.restore();
  }

  static void _crest(Canvas c) {
    final o = _o + const Offset(0, -0.42);
    final f = Path()
      ..moveTo(o.dx - 0.05, o.dy)
      ..quadraticBezierTo(o.dx - 0.09, o.dy - 0.16, o.dx, o.dy - 0.3)
      ..quadraticBezierTo(o.dx + 0.09, o.dy - 0.16, o.dx + 0.05, o.dy)
      ..close();
    c.drawPath(
      f,
      Paint()
        ..shader = ui.Gradient.linear(
          o,
          o + const Offset(0, -0.3),
          const [red, Color(0xFFFF9F43), yellow],
          const [0, 0.6, 1],
        ),
    );
  }

  static void _head(Canvas c) {
    final o = _o;
    final shape = smoothClosed([
      o + const Offset(0, -0.46),
      o + const Offset(0.3, -0.43),
      o + const Offset(0.5, -0.24),
      o + const Offset(0.54, 0.04),
      o + const Offset(0.44, 0.28),
      o + const Offset(0.22, 0.4),
      o + const Offset(0, 0.43),
      o + const Offset(-0.22, 0.4),
      o + const Offset(-0.44, 0.28),
      o + const Offset(-0.54, 0.04),
      o + const Offset(-0.5, -0.24),
      o + const Offset(-0.3, -0.43),
    ]);
    softShadow(
      c,
      shape,
      offset: const Offset(0, 0.04),
      blur: 0.04,
      color: const Color(0x66104A28),
    );
    fillVolume(c, shape, green, light: 0.12, shadow: 0.2);
    featherScales(
      c,
      shape,
      base: greenLight,
      edge: greenDark,
      size: 0.06,
      seed: 6,
      alpha: 0.45,
    );
    // helle Wangenpartie
    for (final sx in [-1.0, 1.0]) {
      final cheek = ellipsePath(sx * 0.28, 0.12, 0.2, 0.22);
      c.save();
      c.clipPath(shape);
      fillVolume(c, cheek, yellow, light: 0.08, shadow: 0.1);
      featherScales(
        c,
        cheek,
        base: Colors.white,
        edge: const Color(0xFFD9A81E),
        size: 0.05,
        seed: 7,
        alpha: 0.4,
      );
      c.restore();
    }
    // rote Stirn
    final forehead = smoothClosed([
      o + const Offset(-0.3, -0.38),
      o + const Offset(0, -0.46),
      o + const Offset(0.3, -0.38),
      o + const Offset(0.16, -0.22),
      o + const Offset(-0.16, -0.22),
    ], tension: 0.6);
    c.save();
    c.clipPath(shape);
    fillVolume(c, forehead, red, light: 0.1, shadow: 0.14);
    c.restore();
    softHighlight(
      c,
      shape,
      o + const Offset(-0.22, -0.3),
      0.24,
      0.09,
      alpha: 0.28,
      rot: -0.4,
    );
  }
}
