import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import '../face.dart';
import '../rig.dart';
import 'premium_figure.dart';

/// Lumi, der Ruhige: weiches blaugraues Fell, hohe Ohren mit sanftem Leuchten,
/// leuchtendes Stirnzeichen, ruhige Atmung, langsame Bewegungen.
class LumiFigure extends PremiumFigure {
  const LumiFigure();

  @override
  String get id => 'nova_lumi';

  @override
  Personality get personality => const Personality(
    breathRate: 1.25,
    breathDepth: 1.1,
    blinkEvery: 4.4,
    tailRate: 1.3,
    tailAmp: 0.35,
    earTwitch: 0.25,
    curiosity: 0.1,
    bounce: 0.8,
    glowPulse: 0.22,
    seed: 3,
  );

  // Palette
  static const fur = Color(0xFF7D9DC9);
  static const furDark = Color(0xFF4B6AA2);
  static const furLight = Color(0xFFCFE0F5);
  static const cream = Color(0xFFEAF3FC);
  static const glowColor = Color(0xFF5FA8FF);

  static const _headC = Offset(0, -0.2);

  static const _face = FaceStyle(
    eyeGap: 0.3,
    eyeY: -0.02,
    eyeRx: 0.125,
    eyeRy: 0.16,
    iris: Color(0xFF2E6BFF),
    irisLight: Color(0xFF9AD0FF),
    lid: fur,
    lashes: true,
    mouthY: 0.3,
    mouthW: 0.075,
    noseY: 0.19,
    noseW: 0.05,
    blushY: 0.17,
    blushGap: 0.46,
    blushR: 0.085,
  );

  @override
  void paint(Canvas c, Pose p, double t) {
    c.save();
    c.translate(0, 0.2);
    c.scale(0.76); // passt Ohrspitzen und Schwanz in das Einheitsquadrat
    groundShadow(c, p, width: 1.05);
    final breath = 1 + p.breath * 0.012;
    c.save();
    c.translate(0, p.bodyDy);
    group(
      c,
      const Offset(0, 0.95),
      rot: p.lean,
      sx: 1 + p.squash * 0.35,
      sy: 1 - p.squash * 0.5,
      draw: () {
        // Schwanz hinter dem Körper
        group(
          c,
          const Offset(-0.4, 0.72),
          rot: p.tail * 0.32,
          draw: () {
            c.drawPicture(PictureCache.get('lumi.tail', _tail));
            glow(c, const Offset(-0.78, 0.3), 0.32, glowColor, 0.28 * p.glow);
          },
        );
        group(
          c,
          const Offset(0, 0.95),
          sy: breath,
          draw: () {
            c.drawPicture(PictureCache.get('lumi.body', _body));
          },
        );
        // Arme / Pfoten (Pivot Schulter)
        _arm(c, p, -1);
        _arm(c, p, 1);
        // Kopf
        group(
          c,
          const Offset(0, 0.3),
          rot: p.headTilt + p.lean * 0.5,
          move: Offset(0, p.headDy + p.breath * -0.004),
          draw: () {
            _ear(c, p, -1);
            _ear(c, p, 1);
            c.drawPicture(PictureCache.get('lumi.head', _head));
            // leuchtendes Stirnzeichen
            final gem = _headC + const Offset(0, -0.31);
            glow(c, gem, 0.2, glowColor, 0.5 * p.glow);
            _star(c, gem, 0.045 * (0.9 + 0.15 * p.glow), Colors.white);
            c.save();
            c.translate(_headC.dx, _headC.dy);
            drawFace(c, _face, p);
            c.restore();
          },
        );
      },
    );
    c.restore();
    sparkles(c, p, t, color: const Color(0xFFBFE0FF));
    c.restore();
  }

  void _arm(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.armL : p.armR;
    group(
      c,
      Offset(side * 0.3, 0.38),
      rot: (side < 0 ? -rot : rot) * 1.3,
      draw: () {
        c.save();
        if (side < 0) c.scale(-1, 1);
        c.drawPicture(PictureCache.get('lumi.arm', _armPic));
        c.restore();
      },
    );
  }

  void _ear(Canvas c, Pose p, double side) {
    final rot = side < 0 ? p.earL : p.earR;
    final base = Offset(side * 0.33, _headC.dy - 0.4);
    group(
      c,
      base,
      rot: side * 0.0 + (side < 0 ? -rot : rot),
      draw: () {
        glow(
          c,
          Offset(side * 0.5, _headC.dy - 0.75),
          0.5,
          glowColor,
          0.4 * p.glow,
        );
        c.save();
        if (side < 0) {
          c.translate(0, 0);
          c.scale(-1, 1);
        }
        c.drawPicture(PictureCache.get('lumi.ear', _earPic));
        c.restore();
      },
    );
  }

  void _star(Canvas c, Offset p, double r, Color col) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rad = i.isEven ? r : r * 0.28;
      final a = i * math.pi / 4 - math.pi / 2;
      final pt = p + Offset(math.cos(a) * rad, math.sin(a) * rad * 1.15);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(path..close(), Paint()..color = col.withValues(alpha: 0.95));
  }

  // ----- statische, gecachte Teile -----

  static void _tail(Canvas c) {
    final shape = smoothClosed(const [
      Offset(-0.42, 0.8),
      Offset(-0.62, 0.86),
      Offset(-0.84, 0.7),
      Offset(-0.94, 0.42),
      Offset(-0.86, 0.14),
      Offset(-0.68, 0.06),
      Offset(-0.56, 0.2),
      Offset(-0.6, 0.42),
      Offset(-0.48, 0.6),
    ]);
    fillVolume(c, shape, mix(fur, furLight, 0.12));
    furTexture(
      c,
      shape,
      light: furLight,
      dark: furDark,
      flow: (p) => math.atan2(p.dy - 0.8, p.dx + 0.4) + math.pi,
      count: 150,
      len: 0.09,
      seed: 11,
    );
    furFringe(
      c,
      shape,
      color: mix(fur, furLight, 0.3),
      tipColor: furLight,
      outward: 0.07,
      spacing: 0.05,
      width: 0.06,
      seed: 12,
    );
    // helle Spitze
    final tip = ellipsePath(-0.8, 0.22, 0.12, 0.14);
    softHighlight(
      c,
      shape,
      const Offset(-0.78, 0.2),
      0.14,
      0.16,
      alpha: 0.6,
      color: cream,
    );
    assert(tip.getBounds().isFinite);
  }

  static void _body(Canvas c) {
    final shape = smoothClosed(const [
      Offset(0, 0.1),
      Offset(0.3, 0.12),
      Offset(0.5, 0.32),
      Offset(0.6, 0.6),
      Offset(0.5, 0.86),
      Offset(0.22, 0.97),
      Offset(0, 0.98),
      Offset(-0.22, 0.97),
      Offset(-0.5, 0.86),
      Offset(-0.6, 0.6),
      Offset(-0.5, 0.32),
      Offset(-0.3, 0.12),
    ]);
    fillVolume(c, shape, fur, light: 0.1, shadow: 0.18);
    furTexture(
      c,
      shape,
      light: furLight,
      dark: furDark,
      flow: (p) => math.pi / 2 + (p.dx) * 0.9,
      count: 340,
      len: 0.085,
      seed: 21,
    );
    // heller Bauch
    final belly = smoothClosed(const [
      Offset(0, 0.34),
      Offset(0.2, 0.4),
      Offset(0.3, 0.62),
      Offset(0.22, 0.86),
      Offset(0, 0.93),
      Offset(-0.22, 0.86),
      Offset(-0.3, 0.62),
      Offset(-0.2, 0.4),
    ]);
    c.save();
    c.clipPath(shape);
    fillVolume(c, belly, furLight, light: 0.05, shadow: 0.08);
    furTexture(
      c,
      belly,
      light: Colors.white,
      dark: mix(furLight, fur, 0.4),
      flow: (p) => math.pi / 2 + p.dx * 1.2,
      count: 160,
      len: 0.06,
      seed: 22,
      alpha: 0.5,
    );
    c.restore();
    // Kinnschatten auf die Brust
    softShadow(
      c,
      ellipsePath(0, 0.14, 0.4, 0.12),
      offset: const Offset(0, 0.05),
      blur: 0.05,
      color: const Color(0x663A5588),
      clip: shape,
    );
    // Fußballen
    for (final sx in [-1.0, 1.0]) {
      final foot = smoothClosed([
        Offset(sx * 0.08, 0.93),
        Offset(sx * 0.2, 0.89),
        Offset(sx * 0.36, 0.92),
        Offset(sx * 0.38, 1.0),
        Offset(sx * 0.2, 1.03),
        Offset(sx * 0.07, 1.0),
      ]);
      fillVolume(c, foot, furLight, light: 0.05, shadow: 0.12);
      for (var k = 0; k < 3; k++) {
        c.drawCircle(
          Offset(sx * (0.15 + k * 0.08), 0.995),
          0.012,
          Paint()..color = furDark.withValues(alpha: 0.35),
        );
      }
    }
    furFringe(
      c,
      shape,
      color: mix(fur, furLight, 0.15),
      outward: 0.05,
      spacing: 0.055,
      width: 0.06,
      seed: 23,
      skip: (p) => p.dy < 0.2 || p.dy > 0.92,
    );
  }

  static void _armPic(Canvas c) {
    // linker Arm in Schulter-Koordinaten (Schulter bei (0.3, 0.38)); wird für rechts gespiegelt
    final arm = smoothClosed(const [
      Offset(0.24, 0.34),
      Offset(0.38, 0.36),
      Offset(0.45, 0.52),
      Offset(0.45, 0.7),
      Offset(0.38, 0.78),
      Offset(0.26, 0.76),
      Offset(0.22, 0.6),
    ]);
    fillVolume(c, arm, mix(fur, furLight, 0.1), light: 0.1, shadow: 0.2);
    furTexture(
      c,
      arm,
      light: furLight,
      dark: furDark,
      flow: (p) => math.pi / 2,
      count: 70,
      len: 0.06,
      seed: 31,
    );
    // helle Pfote
    final paw = smoothClosed(const [
      Offset(0.24, 0.68),
      Offset(0.34, 0.65),
      Offset(0.45, 0.68),
      Offset(0.47, 0.78),
      Offset(0.36, 0.84),
      Offset(0.25, 0.8),
    ]);
    fillVolume(c, paw, furLight, light: 0.05, shadow: 0.1);
    for (var k = 0; k < 2; k++) {
      c.drawLine(
        Offset(0.3 + k * 0.09, 0.76),
        Offset(0.3 + k * 0.09, 0.82),
        Paint()
          ..color = furDark.withValues(alpha: 0.3)
          ..strokeWidth = 0.008
          ..strokeCap = StrokeCap.round,
      );
    }
    furFringe(
      c,
      arm,
      color: mix(fur, furLight, 0.2),
      outward: 0.03,
      spacing: 0.05,
      width: 0.04,
      seed: 33,
      skip: (p) => p.dy < 0.4,
    );
  }

  static void _earPic(Canvas c) {
    // rechtes Ohr in Kopfkoordinaten relativ zum Ursprung (0,0); Basis bei (0.33, headY-0.4) – hier relativ zu (0,0) = Kopfmitte.
    final o = _headC;
    final ear = smoothClosed([
      o + const Offset(0.12, -0.4),
      o + const Offset(0.2, -0.62),
      o + const Offset(0.36, -0.9),
      o + const Offset(0.5, -1.18),
      o + const Offset(0.6, -0.9),
      o + const Offset(0.68, -0.58),
      o + const Offset(0.62, -0.28),
      o + const Offset(0.46, -0.2),
    ], tension: 0.45);
    fillVolume(c, ear, fur, light: 0.1, shadow: 0.18);
    furTexture(
      c,
      ear,
      light: furLight,
      dark: furDark,
      flow: (p) => -math.pi / 2 + 0.3,
      count: 70,
      len: 0.07,
      seed: 41,
    );
    // innen: leuchtender Verlauf
    final inner = smoothClosed([
      o + const Offset(0.22, -0.4),
      o + const Offset(0.3, -0.6),
      o + const Offset(0.44, -0.86),
      o + const Offset(0.5, -1.08),
      o + const Offset(0.56, -0.86),
      o + const Offset(0.6, -0.6),
      o + const Offset(0.54, -0.34),
      o + const Offset(0.42, -0.3),
    ], tension: 0.45);
    c.drawPath(
      inner,
      Paint()
        ..shader = ui.Gradient.linear(
          o + const Offset(0.4, -0.3),
          o + const Offset(0.5, -1.1),
          [const Color(0xFFEAF6FF), const Color(0xFF9CD0FF), glowColor],
          const [0, 0.55, 1],
        ),
    );
    furFringe(
      c,
      ear,
      color: mix(fur, furLight, 0.25),
      tipColor: furLight,
      outward: 0.04,
      spacing: 0.05,
      width: 0.045,
      seed: 43,
      skip: (p) => p.dy > o.dy - 0.3,
    );
  }

  static void _head(Canvas c) {
    final o = _headC;
    final shape = smoothClosed([
      o + const Offset(0, -0.56),
      o + const Offset(0.3, -0.52),
      o + const Offset(0.56, -0.36),
      o + const Offset(0.7, -0.06),
      o + const Offset(0.68, 0.2),
      o + const Offset(0.48, 0.4),
      o + const Offset(0.2, 0.48),
      o + const Offset(0, 0.49),
      o + const Offset(-0.2, 0.48),
      o + const Offset(-0.48, 0.4),
      o + const Offset(-0.68, 0.2),
      o + const Offset(-0.7, -0.06),
      o + const Offset(-0.56, -0.36),
      o + const Offset(-0.3, -0.52),
    ]);
    softShadow(
      c,
      shape,
      offset: const Offset(0, 0.045),
      blur: 0.04,
      color: const Color(0x663A5588),
    );
    fillVolume(c, shape, fur, light: 0.12, shadow: 0.2);
    furTexture(
      c,
      shape,
      light: furLight,
      dark: furDark,
      flow: (p) => math.atan2(p.dy - (o.dy + 0.1), p.dx),
      count: 420,
      len: 0.08,
      seed: 51,
    );
    // helle Gesichtsmaske
    final mask = smoothClosed([
      o + const Offset(0, -0.32),
      o + const Offset(0.2, -0.22),
      o + const Offset(0.42, -0.04),
      o + const Offset(0.46, 0.2),
      o + const Offset(0.28, 0.4),
      o + const Offset(0, 0.46),
      o + const Offset(-0.28, 0.4),
      o + const Offset(-0.46, 0.2),
      o + const Offset(-0.42, -0.04),
      o + const Offset(-0.2, -0.22),
    ]);
    c.save();
    c.clipPath(shape);
    fillVolume(c, mask, furLight, light: 0.04, shadow: 0.1);
    furTexture(
      c,
      mask,
      light: Colors.white,
      dark: mix(furLight, fur, 0.5),
      flow: (p) => math.atan2(p.dy - (o.dy + 0.2), p.dx),
      count: 220,
      len: 0.06,
      seed: 52,
      alpha: 0.5,
    );
    furFringe(
      c,
      mask,
      color: furLight,
      outward: 0.03,
      spacing: 0.045,
      width: 0.045,
      seed: 53,
      skip: (p) => p.dy > o.dy + 0.35,
    );
    c.restore();
    softHighlight(
      c,
      shape,
      o + const Offset(-0.25, -0.38),
      0.3,
      0.12,
      alpha: 0.24,
      rot: -0.4,
    );
    // Wangenfluff
    furFringe(
      c,
      shape,
      color: mix(fur, furLight, 0.1),
      tipColor: mix(fur, furLight, 0.38),
      outward: 0.075,
      spacing: 0.04,
      width: 0.07,
      seed: 54,
      skip: (p) =>
          p.dy < o.dy - 0.35 || (p.dy > o.dy + 0.38 && p.dx.abs() < 0.3),
    );
    // Schnurrhaar-Punkte
    for (final sx in [-1.0, 1.0]) {
      for (var k = 0; k < 3; k++) {
        c.drawCircle(
          o + Offset(sx * (0.17 + k * 0.05), 0.26 + k * 0.03),
          0.009,
          Paint()..color = furDark.withValues(alpha: 0.4),
        );
      }
    }
  }
}
