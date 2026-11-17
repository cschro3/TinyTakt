import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../domain/catalog.dart';
import '../art_kit.dart';
import '../worlds/world_kit.dart';

/// Abenteuer-Weg in 2,5D: Der Pfad schlängelt sich vom Vordergrund (unten links) in die Ferne
/// (oben rechts), wird dabei schmaler, Figuren werden kleiner. Wegmarken bei 25/50/75 %,
/// Startbogen unten, gemütliches Häuschen als Ziel.
class AdventureTrack {
  const AdventureTrack(this.size);
  final Size size;

  double get s => math.min(size.width, size.height);
  Offset get origin => Offset((size.width - s) / 2, (size.height - s) / 2);

  /// Normierte Koordinaten (0..1 im Stage-Quadrat) → Bildschirm.
  Offset n(double x, double y) => origin + Offset(x * s, y * s);

  /// Oberkante des Hügels bei x (0..1), normiert.
  static double ridge(double x) =>
      0.52 - 0.2 * math.pow(math.sin(math.pi * x.clamp(0, 1)), 0.85);

  /// Punkt auf der Wegmitte, [u] = 0 (Start unten links) … 1 (Ziel am Häuschen oben rechts).
  Offset at(double u) {
    final x =
        0.2 +
        0.6 * u +
        0.085 * math.sin(u * math.pi * 2.3 + 0.5) * (1 - 0.35 * u);
    final y = 0.9 - 0.47 * u - 0.015 * math.sin(u * math.pi * 2.3 + 0.5);
    return n(x, y);
  }

  /// Tiefenmaßstab: vorn 1.0, hinten ~0.55.
  double scaleAt(double u) => 1 - 0.45 * u;

  double widthAt(double u) => s * 0.14 * scaleAt(u);
}

/// Farbwelt des Dioramas passend zur gewählten Welt.
class AdventureTheme {
  const AdventureTheme({
    required this.hillTop,
    required this.hillBottom,
    required this.rim,
    required this.pathNear,
    required this.pathFar,
    required this.leafA,
    required this.leafB,
    this.blades = const [Color(0xFF8ADB66), Color(0xFF4FA94A)],
    this.flowers = true,
  });
  final Color hillTop, hillBottom, rim, pathNear, pathFar, leafA, leafB;
  final List<Color> blades;
  final bool flowers;

  static const meadow = AdventureTheme(
    hillTop: Color(0xFF86D36A),
    hillBottom: Color(0xFF4FA24B),
    rim: Color(0xFFB4EE8A),
    pathNear: Color(0xFFE9C58E),
    pathFar: Color(0xFFF6E3BC),
    leafA: Color(0xFF58AE5A),
    leafB: Color(0xFF6BBB5E),
  );
  static const night = AdventureTheme(
    hillTop: Color(0xFF3A6E8E),
    hillBottom: Color(0xFF244A68),
    rim: Color(0xFF6FA6C4),
    pathNear: Color(0xFF8DA6C8),
    pathFar: Color(0xFFB4C8E4),
    leafA: Color(0xFF2F6A7E),
    leafB: Color(0xFF3E7F8F),
    blades: [Color(0xFF5FA2B8), Color(0xFF2F6A7E)],
    flowers: false,
  );
  static const space = AdventureTheme(
    hillTop: Color(0xFF8A7BC8),
    hillBottom: Color(0xFF584A98),
    rim: Color(0xFFB9A8F0),
    pathNear: Color(0xFFC9B8F0),
    pathFar: Color(0xFFE6DCFA),
    leafA: Color(0xFF6A5AB0),
    leafB: Color(0xFF8070C8),
    blades: [Color(0xFFA898E4), Color(0xFF6A5AB0)],
    flowers: false,
  );
  static const beach = AdventureTheme(
    hillTop: Color(0xFFF7E3A6),
    hillBottom: Color(0xFFE5C37A),
    rim: Color(0xFFFFF2C8),
    pathNear: Color(0xFFD9B070),
    pathFar: Color(0xFFF2D9A0),
    leafA: Color(0xFF4FAE7A),
    leafB: Color(0xFF6CC28C),
    blades: [Color(0xFF9ED88A), Color(0xFF5FB070)],
  );
  static const forest = AdventureTheme(
    hillTop: Color(0xFF5FB070),
    hillBottom: Color(0xFF357A4E),
    rim: Color(0xFF9EE0A0),
    pathNear: Color(0xFFD8B987),
    pathFar: Color(0xFFEAD6AE),
    leafA: Color(0xFF2F8A52),
    leafB: Color(0xFF3FA062),
  );
  static const winter = AdventureTheme(
    hillTop: Color(0xFFFFFFFF),
    hillBottom: Color(0xFFD4E6F6),
    rim: Color(0xFFFFFFFF),
    pathNear: Color(0xFFBCD2EA),
    pathFar: Color(0xFFDCEAF8),
    leafA: Color(0xFF3E8E6E),
    leafB: Color(0xFF52A482),
    blades: [Color(0xFFEAF4FF), Color(0xFFC4DAF0)],
    flowers: false,
  );
  static const sunset = AdventureTheme(
    hillTop: Color(0xFFB27AA8),
    hillBottom: Color(0xFF7A4E88),
    rim: Color(0xFFEBA5B4),
    pathNear: Color(0xFFF2C0A0),
    pathFar: Color(0xFFFFE0C4),
    leafA: Color(0xFF6A4E8A),
    leafB: Color(0xFF8A62A0),
    blades: [Color(0xFFD08AA8), Color(0xFF8A5A90)],
  );
  static const underwater = AdventureTheme(
    hillTop: Color(0xFFEBD9A0),
    hillBottom: Color(0xFFC9AE6E),
    rim: Color(0xFFFFF0C0),
    pathNear: Color(0xFFD9C080),
    pathFar: Color(0xFFF2E3B4),
    leafA: Color(0xFF2FA880),
    leafB: Color(0xFF45C09A),
    blades: [Color(0xFF58C8A0), Color(0xFF2F9A78)],
    flowers: false,
  );

  static AdventureTheme forScenery(Scenery s) => switch (s) {
    Scenery.meadow || Scenery.sky => meadow,
    Scenery.night => night,
    Scenery.space => space,
    Scenery.beach => beach,
    Scenery.forest => forest,
    Scenery.winter => winter,
    Scenery.sunset => sunset,
    Scenery.underwater => underwater,
  };
}

class AdventurePainter extends CustomPainter {
  AdventurePainter({
    required this.fraction,
    required this.t,
    this.calm = false,
    this.theme = AdventureTheme.meadow,
  });
  final AdventureTheme theme;
  final double fraction;
  final double t;
  final bool calm;

  static const checkpoints = [0.25, 0.5, 0.75];

  @override
  void paint(Canvas canvas, Size size) {
    final track = AdventureTrack(size);
    final u = (1 - fraction).clamp(0.0, 1.0);
    canvas.drawPicture(
      PictureCache.get(
        'adv.scene.${theme.hillTop.toARGB32()}.${size.width.round()}x${size.height.round()}',
        (c) => _staticPath(c, size, track, theme),
      ),
    );
    _footprints(canvas, track, u);
    // Wegmarken und Ziel (Zustand ändert sich mit dem Fortschritt)
    for (var i = 0; i < checkpoints.length; i++) {
      _signpost(
        canvas,
        track,
        checkpoints[i],
        reached: u >= checkpoints[i],
        i: i,
      );
    }
    _house(canvas, track, glowing: u > 0.88, reached: u >= 0.999);
    _progressBar(canvas, size, u);
  }

  // ---- statisch ----
  /// Märchen-Diorama: schwebender Hügel mit Lichtkante, Bäumchen und Grasbüscheln.
  static Path _hill(Canvas c, AdventureTrack tr, AdventureTheme th) {
    final pts = <Offset>[
      for (var i = 0; i <= 26; i++)
        tr.n(
          -0.04 + 1.08 * i / 26,
          AdventureTrack.ridge((-0.04 + 1.08 * i / 26).clamp(0.0, 1.0)),
        ),
    ];
    final ridgeLine = smoothOpen(pts, tension: 0.9);
    final hill = smoothOpen(pts, tension: 0.9)
      ..lineTo(tr.n(1.04, 0.95).dx, tr.n(1.04, 0.95).dy)
      ..quadraticBezierTo(
        tr.n(1.04, 1.04).dx,
        tr.n(1.04, 1.04).dy,
        tr.n(0.92, 1.04).dx,
        tr.n(0.92, 1.04).dy,
      )
      ..lineTo(tr.n(0.08, 1.04).dx, tr.n(0.08, 1.04).dy)
      ..quadraticBezierTo(
        tr.n(-0.04, 1.04).dx,
        tr.n(-0.04, 1.04).dy,
        tr.n(-0.04, 0.95).dx,
        tr.n(-0.04, 0.95).dy,
      )
      ..close();
    // Schatten unter dem schwebenden Hügel
    c.drawOval(
      Rect.fromCenter(
        center: tr.n(0.5, 1.06),
        width: tr.s * 0.95,
        height: tr.s * 0.07,
      ),
      Paint()
        ..color = const Color(0x33203050)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, tr.s * 0.02),
    );
    // Körper
    final b = hill.getBounds();
    c.drawPath(
      hill,
      Paint()
        ..shader = ui.Gradient.linear(
          b.topCenter,
          b.bottomCenter,
          [th.hillTop, mix(th.hillTop, th.hillBottom, 0.55), th.hillBottom],
          const [0, 0.5, 1],
        ),
    );
    c.save();
    c.clipPath(hill);
    // weiche Lichtflecken und Unterkante
    for (var i = 0; i < 5; i++) {
      c.drawOval(
        Rect.fromCenter(
          center: tr.n(0.2 + i * 0.16, 0.62 + (i % 2) * 0.16),
          width: tr.s * 0.34,
          height: tr.s * 0.05,
        ),
        Paint()..color = th.rim.withValues(alpha: 0.12),
      );
    }
    c.drawRect(
      Rect.fromLTWH(b.left, b.bottom - tr.s * 0.12, b.width, tr.s * 0.12),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, b.bottom - tr.s * 0.12),
          Offset(0, b.bottom),
          [const Color(0x00000000), const Color(0x33102030)],
        ),
    );
    // Lichtkante entlang des Kamms
    c.drawPath(
      ridgeLine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tr.s * 0.028
        ..color = th.rim.withValues(alpha: 0.75)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, tr.s * 0.012),
    );
    c.restore();
    // Bäumchen auf dem Kamm (hinten klein)
    final rnd = Rng(61);
    for (final x in const [0.07, 0.17, 0.3, 0.44, 0.58]) {
      final y = AdventureTrack.ridge(x) + 0.012;
      c.save();
      final pos = tr.n(x, y);
      c.translate(pos.dx, pos.dy);
      drawRoundTree(
        c,
        tr.s * rnd.range(0.1, 0.14),
        leaf: x < 0.3 ? th.leafA : th.leafB,
        seed: (x * 100).round(),
      );
      c.restore();
    }
    // Gräser auf dem Kamm
    for (var i = 0; i < 140; i++) {
      final x = rnd.next();
      final base = tr.n(x, AdventureTrack.ridge(x) + 0.006);
      final h = tr.s * 0.022 * rnd.range(0.5, 1.0);
      final lean = rnd.range(-0.4, 0.4) * h;
      c.drawPath(
        Path()
          ..moveTo(base.dx - h * 0.1, base.dy)
          ..quadraticBezierTo(
            base.dx + lean * 0.4,
            base.dy - h * 0.6,
            base.dx + lean,
            base.dy - h,
          )
          ..quadraticBezierTo(
            base.dx + lean * 0.6 + h * 0.06,
            base.dy - h * 0.5,
            base.dx + h * 0.1,
            base.dy,
          )
          ..close(),
        Paint()..color = Color.lerp(th.blades[0], th.blades[1], rnd.next())!,
      );
    }
    // Büsche an den vorderen Ecken
    for (final bx in const [(0.06, 0.88), (0.95, 0.86)]) {
      final pos = tr.n(bx.$1, bx.$2);
      c.save();
      c.translate(pos.dx, pos.dy);
      drawBush(c, tr.s * 0.1, leaf: th.leafA);
      c.restore();
    }
    return hill;
  }

  static void _staticPath(
    Canvas c,
    Size size,
    AdventureTrack tr,
    AdventureTheme th,
  ) {
    final hillClip = _hill(c, tr, th);
    c.save();
    c.clipPath(hillClip);
    const n = 80;
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final u =
          -0.16 +
          1.16 * i / n; // beginnt außerhalb des Hügels (sauberer Anschnitt)
      final p = tr.at(u);
      final q = tr.at(math.min(1, u + 0.01));
      final d = (q - p);
      final len = d.distance == 0 ? 1.0 : d.distance;
      final nrm = Offset(-d.dy / len, d.dx / len);
      final w = tr.widthAt(u) / 2;
      left.add(p + nrm * w);
      right.add(p - nrm * w);
    }
    final strip = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left) {
      strip.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      strip.lineTo(p.dx, p.dy);
    }
    strip.close();
    // weicher Schatten/Kontakt zum Gras
    c.drawPath(
      strip,
      Paint()
        ..color = const Color(0x33306030)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // Sandweg mit Verlauf (vorn wärmer, hinten heller/ferner)
    c.drawPath(
      strip,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height * 0.9),
          Offset(0, size.height * 0.25),
          const [Color(0xFFE9C58E), Color(0xFFF3DDB0), Color(0xFFF7E6C4)],
          const [0, 0.6, 1],
        ),
    );
    // Kanten: leicht dunkler, wie festgetretene Erde
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0x55A8763A);
    c.drawPath(strip, edge);
    // Fahrspuren / Mitte
    final center = smoothOpen([for (var i = 0; i <= 24; i++) tr.at(i / 24)]);
    c.drawPath(
      center,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tr.s * 0.012
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x22A8763A),
    );
    // Kiesel
    final rnd = Rng(31);
    for (var i = 0; i < 70; i++) {
      final u = rnd.next();
      final p = tr.at(u);
      final w = tr.widthAt(u);
      final o = Offset(rnd.range(-0.42, 0.42) * w, rnd.range(-0.1, 0.1) * w);
      final r = tr.s * 0.006 * tr.scaleAt(u) * rnd.range(0.6, 1.4);
      c.drawOval(
        Rect.fromCenter(center: p + o, width: r * 2.2, height: r * 1.5),
        Paint()
          ..color = Color.lerp(
            const Color(0xFFD7C09A),
            const Color(0xFFB59B73),
            rnd.next(),
          )!.withValues(alpha: 0.8),
      );
    }
    // Gräser und Blümchen am Wegrand
    for (var i = 0; i < 90; i++) {
      final u = rnd.next();
      final side = rnd.next() < 0.5 ? -1.0 : 1.0;
      final p = tr.at(u);
      final q = tr.at(math.min(1, u + 0.01));
      final d = q - p;
      final len = d.distance == 0 ? 1.0 : d.distance;
      final nrm = Offset(-d.dy / len, d.dx / len);
      final base =
          p + nrm * side * (tr.widthAt(u) * 0.55 + rnd.range(0, tr.s * 0.03));
      final sc = tr.scaleAt(u);
      final h = tr.s * 0.03 * sc * rnd.range(0.6, 1.3);
      // Grashalme
      for (var k = 0; k < 3; k++) {
        final dx = (k - 1) * h * 0.22;
        c.drawPath(
          Path()
            ..moveTo(base.dx + dx - h * 0.06, base.dy)
            ..quadraticBezierTo(
              base.dx + dx + h * 0.05 * side,
              base.dy - h * 0.6,
              base.dx + dx + h * 0.2 * (k - 1),
              base.dy - h,
            )
            ..quadraticBezierTo(
              base.dx + dx + h * 0.08,
              base.dy - h * 0.5,
              base.dx + dx + h * 0.06,
              base.dy,
            )
            ..close(),
          Paint()
            ..color = Color.lerp(
              const Color(0xFF6CC05A),
              const Color(0xFF3F9A48),
              rnd.next(),
            )!,
        );
      }
      if (th.flowers && rnd.next() < 0.45) {
        final col = [
          const Color(0xFFFF7BA5),
          const Color(0xFFFFE066),
          Colors.white,
          const Color(0xFF8CB4FF),
        ][rnd.next() < 0.5 ? (rnd.next() * 4).floor() : 2];
        c.drawCircle(
          base + Offset(h * 0.3 * side, -h * 1.1),
          tr.s * 0.007 * sc * 1.4,
          Paint()..color = col,
        );
        c.drawCircle(
          base + Offset(h * 0.3 * side, -h * 1.1),
          tr.s * 0.0028 * sc * 1.4,
          Paint()..color = const Color(0xFFFFC21E),
        );
      }
    }
    // Startbogen (Holz) unten links
    final p0 = tr.at(0.05);
    final sc0 = tr.scaleAt(0.05);
    final w0 = tr.widthAt(0.05) * 0.62;
    final h0 = tr.s * 0.15 * sc0;
    final wood = const Color(0xFF9A6A3E);
    for (final sd in [-1.0, 1.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            p0.dx + sd * w0 - tr.s * 0.012,
            p0.dy - h0,
            tr.s * 0.024,
            h0,
          ),
          const Radius.circular(3),
        ),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(p0.dx + sd * w0 - 6, 0),
            Offset(p0.dx + sd * w0 + 6, 0),
            [shade(wood, 0.1), wood, shade(wood, -0.12)],
            const [0, 0.5, 1],
          ),
      );
    }
    final banner = Path()
      ..moveTo(p0.dx - w0 - 4, p0.dy - h0 - 2)
      ..quadraticBezierTo(
        p0.dx,
        p0.dy - h0 * 1.12,
        p0.dx + w0 + 4,
        p0.dy - h0 - 2,
      )
      ..lineTo(p0.dx + w0 + 4, p0.dy - h0 * 0.78)
      ..quadraticBezierTo(
        p0.dx,
        p0.dy - h0 * 0.88,
        p0.dx - w0 - 4,
        p0.dy - h0 * 0.78,
      )
      ..close();
    c.drawPath(
      banner,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(p0.dx - w0, 0),
          Offset(p0.dx + w0, 0),
          const [Color(0xFF3FC4A8), Color(0xFF2FA88E)],
        ),
    );
    for (var i = 0; i < 5; i++) {
      c.drawCircle(
        Offset(
          p0.dx - w0 * 0.7 + i * w0 * 0.35,
          p0.dy - h0 * 0.93 + (i == 2 ? -h0 * 0.045 : 0),
        ),
        tr.s * 0.007,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }
    c.restore();
  }

  void _footprints(Canvas c, AdventureTrack tr, double u) {
    final steps = (u * 38).floor();
    for (var i = 0; i < steps; i++) {
      final k = i / 38;
      if (k > u - 0.025) break;
      final p = tr.at(k);
      final q = tr.at(math.min(1, k + 0.01));
      final d = q - p;
      final len = d.distance == 0 ? 1.0 : d.distance;
      final nrm = Offset(-d.dy / len, d.dx / len);
      final side = i.isEven ? 1.0 : -1.0;
      final sc = tr.scaleAt(k);
      final age = ((u - k) * 3).clamp(0.0, 1.0);
      c.drawOval(
        Rect.fromCenter(
          center:
              p + nrm * side * tr.s * 0.012 * sc + Offset(0, tr.s * 0.02 * sc),
          width: tr.s * 0.016 * sc,
          height: tr.s * 0.011 * sc,
        ),
        Paint()
          ..color = const Color(0xFF9A7240)
              .withValues(alpha: 0.32 * (1 - age * 0.6)),
      );
    }
  }

  void _signpost(
    Canvas c,
    AdventureTrack tr,
    double u, {
    required bool reached,
    required int i,
  }) {
    final p = tr.at(u);
    final sc = tr.scaleAt(u);
    final off = tr.widthAt(u) * 0.78;
    final base = p + Offset(off, tr.s * 0.012 * sc);
    final h = tr.s * 0.12 * sc;
    final pole = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = tr.s * 0.012 * sc
      ..color = const Color(0xFF8A5A33);
    c.drawLine(base, base + Offset(0, -h), pole);
    // Fähnchen: ungeleuchtet = grau & unten, erreicht = golden & oben, wehend
    final wave = calm ? 0.0 : math.sin(t * 5 + i) * h * 0.04;
    final fy = reached ? -h * 0.96 : -h * 0.55;
    final fw = tr.s * 0.06 * sc;
    final flag = Path()
      ..moveTo(base.dx, base.dy + fy)
      ..quadraticBezierTo(
        base.dx + fw * 0.5,
        base.dy + fy - fw * 0.15 + wave,
        base.dx + fw,
        base.dy + fy + fw * 0.2 + wave,
      )
      ..quadraticBezierTo(
        base.dx + fw * 0.5,
        base.dy + fy + fw * 0.45 + wave,
        base.dx,
        base.dy + fy + fw * 0.5,
      )
      ..close();
    c.drawPath(
      flag,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(base.dx, 0),
          Offset(base.dx + fw, 0),
          reached
              ? const [Color(0xFFFFD84D), Color(0xFFFFA726)]
              : const [Color(0xFFB8B4C8), Color(0xFF9A96AE)],
        ),
    );
    if (reached) {
      // kleines Sternchen als Bestätigung (Form, nicht nur Farbe)
      final star = Path();
      final sc2 = base + Offset(fw * 0.4, fy + fw * 0.22);
      for (var k = 0; k < 10; k++) {
        final r = (k.isEven ? 1.0 : 0.42) * fw * 0.16;
        final a = -math.pi / 2 + k * math.pi / 5;
        final pt = sc2 + Offset(math.cos(a) * r, math.sin(a) * r);
        k == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
      }
      c.drawPath(star..close(), Paint()..color = Colors.white);
    }
  }

  void _house(
    Canvas c,
    AdventureTrack tr, {
    required bool glowing,
    required bool reached,
  }) {
    final p = tr.at(1);
    final sc = tr.scaleAt(1) * 1.15;
    final u = tr.s * 0.13 * sc;
    c.save();
    c.translate(p.dx + tr.widthAt(1) * 0.3, p.dy);
    // Bodenschatten
    c.drawOval(
      Rect.fromCenter(
        center: Offset(0, u * 0.05),
        width: u * 2.3,
        height: u * 0.35,
      ),
      Paint()..color = const Color(0x33204020),
    );
    // Hauskörper
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(-u, -u * 0.95, u * 2, u * 0.95),
      Radius.circular(u * 0.06),
    );
    c.drawRRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-u, 0),
          Offset(u, 0),
          const [Color(0xFFFFF3DC), Color(0xFFF6E2BC), Color(0xFFE5C99B)],
          const [0, 0.55, 1],
        ),
    );
    // Dach
    final roof = Path()
      ..moveTo(-u * 1.18, -u * 0.9)
      ..lineTo(0, -u * 1.75)
      ..lineTo(u * 1.18, -u * 0.9)
      ..close();
    c.drawPath(
      roof,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, -u * 1.75),
          Offset(0, -u * 0.9),
          const [Color(0xFFE5674F), Color(0xFFC24A3A)],
        ),
    );
    c.drawPath(
      roof,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.05
        ..color = const Color(0x33803020),
    );
    // Schornstein + Rauch
    c.drawRect(
      Rect.fromLTWH(u * 0.5, -u * 1.75, u * 0.26, u * 0.6),
      Paint()..color = const Color(0xFFB5543F),
    );
    if (!calm) {
      for (var i = 0; i < 3; i++) {
        final k = ((t * 0.5) + i / 3) % 1;
        c.drawCircle(
          Offset(
            u * 0.63 + math.sin(k * 5 + i) * u * 0.1,
            -u * 1.85 - k * u * 0.9,
          ),
          u * (0.1 + k * 0.14),
          Paint()..color = Colors.white.withValues(alpha: 0.5 * (1 - k)),
        );
      }
    }
    // Tür und Fenster
    c.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(-u * 0.2, -u * 0.58, u * 0.4, u * 0.58),
        topLeft: Radius.circular(u * 0.2),
        topRight: Radius.circular(u * 0.2),
      ),
      Paint()..color = const Color(0xFF8A5A33),
    );
    c.drawCircle(
      Offset(u * 0.1, -u * 0.28),
      u * 0.025,
      Paint()..color = const Color(0xFFFFD84D),
    );
    for (final sd in [-1.0, 1.0]) {
      final win = Rect.fromCenter(
        center: Offset(sd * u * 0.62, -u * 0.5),
        width: u * 0.34,
        height: u * 0.34,
      );
      if (glowing) glow(c, win.center, u * 0.5, const Color(0xFFFFE08A), 0.55);
      c.drawRRect(
        RRect.fromRectAndRadius(win, Radius.circular(u * 0.05)),
        Paint()
          ..color = glowing ? const Color(0xFFFFE9A8) : const Color(0xFFA8CCE8),
      );
      c.drawLine(
        win.centerLeft,
        win.centerRight,
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..strokeWidth = u * 0.03,
      );
      c.drawLine(
        win.topCenter,
        win.bottomCenter,
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..strokeWidth = u * 0.03,
      );
    }
    // Fähnchen auf dem Dach: erreicht → weht
    c.drawLine(
      Offset(0, -u * 1.75),
      Offset(0, -u * 2.1),
      Paint()
        ..color = const Color(0xFF8A5A33)
        ..strokeWidth = u * 0.04,
    );
    final wv = calm ? 0.0 : math.sin(t * 5) * u * 0.05;
    c.drawPath(
      Path()
        ..moveTo(0, -u * 2.1)
        ..quadraticBezierTo(u * 0.25, -u * 2.12 + wv, u * 0.45, -u * 2.0 + wv)
        ..quadraticBezierTo(u * 0.25, -u * 1.9 + wv, 0, -u * 1.9)
        ..close(),
      Paint()
        ..color = reached ? const Color(0xFFFFD84D) : const Color(0xFFE5574B),
    );
    c.restore();
  }

  void _progressBar(Canvas c, Size size, double u) {
    final w = size.shortestSide * 0.72;
    final x0 = (size.width - w) / 2;
    final y = size.height - size.shortestSide * 0.045;
    final h = size.shortestSide * 0.032;
    final r = Radius.circular(h);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x0 - 3, y - 3, w + 6, h + 6), r),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x0, y, w, h), r),
      Paint()..color = const Color(0x33203060),
    );
    final fw = math.max(h, w * u);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x0, y, fw, h), r),
      Paint()
        ..shader = ui.Gradient.linear(Offset(x0, 0), Offset(x0 + w, 0), const [
          Color(0xFF3FD0B0),
          Color(0xFFFFC83D),
        ]),
    );
    // Wegmarken auch auf der Leiste (Form, nicht nur Farbe)
    for (final cp in checkpoints) {
      final cx = x0 + w * cp;
      c.drawCircle(
        Offset(cx, y + h / 2),
        h * 0.28,
        Paint()..color = u >= cp ? Colors.white : const Color(0x66FFFFFF),
      );
    }
    c.drawCircle(
      Offset(x0 + fw - h * 0.5, y + h / 2),
      h * 0.62,
      Paint()..color = Colors.white,
    );
    c.drawCircle(
      Offset(x0 + fw - h * 0.5, y + h / 2),
      h * 0.38,
      Paint()..color = const Color(0xFFFFC83D),
    );
  }

  @override
  bool shouldRepaint(AdventurePainter o) =>
      o.fraction != fraction || o.t != t || o.calm != calm;
}
