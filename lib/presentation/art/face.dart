import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'art_kit.dart';
import 'rig.dart';

/// Gesichts-System: Augen (offen, glücklich, schläfrig, staunend, zwinkernd), Mund, Nase, Wangen.
class FaceStyle {
  const FaceStyle({
    this.eyeGap = 0.26,
    this.eyeY = -0.1,
    this.eyeRx = 0.115,
    this.eyeRy = 0.14,
    this.iris = const Color(0xFF3F6FB5),
    this.irisLight = const Color(0xFF7FB4FF),
    this.eyeBase = const Color(0xFF241C3A),
    this.lid = const Color(0xFF7C9CC8),
    this.lashes = false,
    this.sclera = false,
    this.mouthY = 0.18,
    this.mouthW = 0.075,
    this.cat = true,
    this.noseColor = const Color(0xFFE88A9C),
    this.noseW = 0.045,
    this.noseY = 0.1,
    this.blush = const Color(0xFFFF8FA8),
    this.blushY = 0.13,
    this.blushGap = 0.4,
    this.blushR = 0.075,
    this.ink = const Color(0xFF2B2440),
    this.irisScale = 0.84,
  });

  final double eyeGap,
      eyeY,
      eyeRx,
      eyeRy,
      mouthY,
      mouthW,
      noseW,
      noseY,
      blushY,
      blushGap,
      blushR,
      irisScale;
  final Color iris, irisLight, eyeBase, lid, noseColor, blush, ink;
  final bool lashes, sclera, cat;
}

/// Zeichnet das Gesicht an der aktuellen Koordinatenursprung-Position (Kopfmitte).
void drawFace(Canvas c, FaceStyle s, Pose p, {double scale = 1}) {
  c.save();
  c.scale(scale);
  _blush(c, s, p);
  _eye(c, s, p, -1);
  _eye(c, s, p, 1);
  _nose(c, s);
  _mouth(c, s, p);
  c.restore();
}

void _blush(Canvas c, FaceStyle s, Pose p) {
  for (final sx in [-1.0, 1.0]) {
    final center = Offset(sx * s.blushGap, s.blushY);
    final r = s.blushR * (1 + p.cheek * 0.25);
    c.drawOval(
      Rect.fromCenter(center: center, width: r * 2.4, height: r * 1.5),
      Paint()
        ..shader = ui.Gradient.radial(center, r * 1.3, [
          s.blush.withValues(alpha: 0.55),
          s.blush.withValues(alpha: 0),
        ]),
    );
  }
}

void _eye(Canvas c, FaceStyle s, Pose p, double side) {
  final cx = side * s.eyeGap;
  final cy = s.eyeY;
  var mode = p.eyes;
  if (mode == EyeMode.wink && side < 0)
    mode = EyeMode.open; // links bleibt offen, rechts zwinkert
  if (mode == EyeMode.wink && side > 0) mode = EyeMode.happy;
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = s.ink
    ..strokeWidth = s.eyeRx * 0.34;

  if (mode == EyeMode.happy) {
    // „Lachbogen“ mit kleinem Lidschatten
    final path = Path()
      ..moveTo(cx - s.eyeRx * 1.0, cy + s.eyeRy * 0.25)
      ..quadraticBezierTo(
        cx,
        cy - s.eyeRy * 1.05,
        cx + s.eyeRx * 1.0,
        cy + s.eyeRy * 0.25,
      );
    c.drawPath(path, stroke);
    if (s.lashes) {
      c.drawLine(
        Offset(cx + side * s.eyeRx * 0.95, cy + s.eyeRy * 0.15),
        Offset(cx + side * s.eyeRx * 1.35, cy - s.eyeRy * 0.05),
        stroke..strokeWidth = s.eyeRx * 0.2,
      );
    }
    return;
  }
  var open = 1 - p.blink;
  var sleepyLid = 0.0;
  var scale = 1.0;
  if (mode == EyeMode.sleepy) {
    sleepyLid = 0.5;
    open = math.min(open, 0.85);
  }
  if (mode == EyeMode.wide) scale = 1.12;
  if (open < 0.12) {
    final path = Path()
      ..moveTo(cx - s.eyeRx, cy)
      ..quadraticBezierTo(cx, cy + s.eyeRy * 0.55, cx + s.eyeRx, cy);
    c.drawPath(path, stroke);
    if (s.lashes) {
      c.drawLine(
        Offset(cx + side * s.eyeRx * 0.95, cy),
        Offset(cx + side * s.eyeRx * 1.35, cy - s.eyeRy * 0.2),
        stroke..strokeWidth = s.eyeRx * 0.2,
      );
    }
    return;
  }
  c.save();
  c.translate(cx, cy);
  c.scale(scale, scale * open);
  final rx = s.eyeRx, ry = s.eyeRy;
  final eyeRect = Rect.fromCenter(
    center: Offset.zero,
    width: rx * 2,
    height: ry * 2,
  );
  if (s.sclera) {
    c.drawOval(
      eyeRect.inflate(rx * 0.08),
      Paint()..color = const Color(0xFFFDFBFF),
    );
    c.drawOval(
      eyeRect.inflate(rx * 0.08),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rx * 0.1
        ..color = s.ink.withValues(alpha: 0.85),
    );
  } else {
    c.drawOval(eyeRect, Paint()..color = s.eyeBase);
  }
  // Iris wandert mit dem Blick
  final look = p.look;
  final off = Offset(look.dx * rx * 0.18, look.dy * ry * 0.12);
  final ir = Rect.fromCenter(
    center: off + Offset(0, ry * 0.04),
    width: rx * 2 * s.irisScale,
    height: ry * 2 * s.irisScale,
  );
  c.save();
  c.clipPath(Path()..addOval(eyeRect));
  c.drawOval(
    ir,
    Paint()
      ..shader = ui.Gradient.radial(
        ir.center + Offset(0, ry * 0.45),
        ry * 1.15,
        [s.irisLight, s.iris, shade(s.iris, -0.18)],
        const [0, 0.55, 1],
      ),
  );
  // dunkler Irisrand + Pupille
  c.drawOval(
    ir,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rx * 0.1
      ..color = shade(s.iris, -0.3).withValues(alpha: 0.8),
  );
  final pupilR = (mode == EyeMode.wide ? 0.34 : 0.4);
  c.drawOval(
    Rect.fromCenter(
      center: ir.center,
      width: rx * 2 * s.irisScale * pupilR * 1.1,
      height: ry * 2 * s.irisScale * pupilR * 1.25,
    ),
    Paint()..color = const Color(0xFF110C20),
  );
  // Glanzlichter: groß oben rechts, klein unten links, Funken
  gloss(c, off + Offset(rx * 0.34, -ry * 0.38), rx * 0.34);
  gloss(c, off + Offset(-rx * 0.3, ry * 0.42), rx * 0.15, alpha: 0.85);
  gloss(c, off + Offset(rx * 0.1, ry * 0.12), rx * 0.07, alpha: 0.7);
  // Lidschatten oben für Tiefe
  c.drawOval(
    eyeRect.shift(Offset(0, -ry * 1.1)).inflate(rx * 0.1),
    Paint()
      ..color = const Color(0x66000010)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, ry * 0.25),
  );
  if (sleepyLid > 0) {
    // schwere Lider: oben abgedeckt, Lidkante leicht durchhängend
    final lidPath = Path()
      ..moveTo(-rx * 1.3, -ry * 1.3)
      ..lineTo(rx * 1.3, -ry * 1.3)
      ..lineTo(rx * 1.3, -ry * 0.1)
      ..quadraticBezierTo(0, ry * 0.42, -rx * 1.3, -ry * 0.1)
      ..close();
    c.drawPath(lidPath, Paint()..color = s.lid);
    c.drawPath(
      Path()
        ..moveTo(-rx * 1.05, -ry * 0.07)
        ..quadraticBezierTo(0, ry * 0.36, rx * 1.05, -ry * 0.07),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = rx * 0.2
        ..color = s.ink,
    );
  }
  c.restore();
  if (s.lashes) {
    c.drawLine(
      Offset(side * rx * 0.95, -ry * 0.2),
      Offset(side * rx * 1.4, -ry * 0.55),
      Paint()
        ..color = s.ink
        ..strokeWidth = rx * 0.2
        ..strokeCap = StrokeCap.round,
    );
  }
  c.restore();
}

void _nose(Canvas c, FaceStyle s) {
  final w = s.noseW;
  final path = Path()
    ..moveTo(-w, s.noseY - w * 0.35)
    ..quadraticBezierTo(0, s.noseY - w * 0.8, w, s.noseY - w * 0.35)
    ..quadraticBezierTo(w * 0.7, s.noseY + w * 0.55, 0, s.noseY + w * 0.8)
    ..quadraticBezierTo(-w * 0.7, s.noseY + w * 0.55, -w, s.noseY - w * 0.35)
    ..close();
  c.drawPath(
    path,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, s.noseY - w),
        Offset(0, s.noseY + w),
        [shade(s.noseColor, 0.12), s.noseColor, shade(s.noseColor, -0.12)],
        const [0, 0.5, 1],
      ),
  );
  gloss(c, Offset(-w * 0.3, s.noseY - w * 0.2), w * 0.2, alpha: 0.7);
}

void _mouth(Canvas c, FaceStyle s, Pose p) {
  final y = s.mouthY;
  final w = s.mouthW;
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = w * 0.26
    ..color = s.ink;
  // senkrechter Strich Nase → Mund
  if (s.cat) {
    c.drawLine(
      Offset(0, s.noseY + s.noseW * 0.85),
      Offset(0, y - w * 0.15),
      line..strokeWidth = w * 0.2,
    );
  }
  line.strokeWidth = w * 0.26;
  switch (p.mouth) {
    case MouthShape.smile:
      if (s.cat) {
        final path = Path()
          ..moveTo(-w, y - w * 0.1)
          ..quadraticBezierTo(-w * 0.55, y + w * 0.75, 0, y)
          ..quadraticBezierTo(w * 0.55, y + w * 0.75, w, y - w * 0.1);
        c.drawPath(path, line);
      } else {
        final path = Path()
          ..moveTo(-w, y)
          ..quadraticBezierTo(0, y + w * 1.1, w, y);
        c.drawPath(path, line);
      }
    case MouthShape.grin:
      final path = Path()
        ..moveTo(-w * 1.15, y - w * 0.15)
        ..quadraticBezierTo(0, y + w * 1.6, w * 1.15, y - w * 0.15);
      c.drawPath(path, line);
    case MouthShape.open:
      final path = Path()
        ..moveTo(-w * 1.2, y - w * 0.2)
        ..quadraticBezierTo(0, y + w * 2.7, w * 1.2, y - w * 0.2)
        ..close();
      c.drawPath(path, Paint()..color = const Color(0xFF7A2A44));
      c.save();
      c.clipPath(path);
      c.drawOval(
        Rect.fromCenter(
          center: Offset(0, y + w * 1.3),
          width: w * 1.7,
          height: w * 1.1,
        ),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, y + w * 0.8),
            Offset(0, y + w * 1.9),
            [const Color(0xFFFF8CA0), const Color(0xFFE5587A)],
          ),
      );
      c.restore();
      c.drawPath(path, line..strokeWidth = w * 0.2);
    case MouthShape.o:
      c.drawOval(
        Rect.fromCenter(
          center: Offset(0, y + w * 0.4),
          width: w * 0.9,
          height: w * 1.1,
        ),
        Paint()..color = const Color(0xFF7A2A44),
      );
    case MouthShape.neutral:
      c.drawLine(
        Offset(-w * 0.6, y + w * 0.1),
        Offset(w * 0.6, y + w * 0.1),
        line,
      );
    case MouthShape.sleepy:
      final path = Path()
        ..moveTo(-w * 0.55, y + w * 0.1)
        ..quadraticBezierTo(0, y + w * 0.5, w * 0.55, y + w * 0.1);
      c.drawPath(path, line..strokeWidth = w * 0.22);
  }
}
