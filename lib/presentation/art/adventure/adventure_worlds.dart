import 'dart:math' as math;
import 'dart:ui';

import 'adventure_kit.dart';
import 'adventure_spec.dart';

/// Die Abenteuerwelten. Jede hat eigene Landschaft, eigenen Weg, eigene Etappen und ein eigenes Ziel.
/// Programmatisch gemalte Fallbacks – KEINE gelieferten Illustrationen (siehe docs/ASSET_INVENTAR.md).
final Map<String, AdventureWorldSpec> adventureWorlds = {
  for (final w in <AdventureWorldSpec>[
    _space,
    _sunset,
    _night,
    _forest,
    _beach,
    _underwater,
    _winter,
    _sky,
  ])
    w.id: w,
};

const _st = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0];

double _tw(double t, double ph, [double sp = 2]) =>
    0.5 + 0.5 * math.sin(t * sp + ph);

void _orb(
  Canvas c,
  Offset p,
  double s,
  double lit,
  double t,
  Color on,
  Color off, {
  double r = 0.022,
}) {
  final rr = s * r;
  if (lit > 0.01)
    glowDot(
      c,
      p,
      rr * (3.4 + 0.6 * math.sin(t * 3)),
      on.withValues(alpha: 0.5 * lit),
    );
  c.drawCircle(p, rr, fill(Color.lerp(off, on, lit)!));
  c.drawCircle(
    p.translate(-rr * 0.3, -rr * 0.3),
    rr * 0.3,
    fill(const Color(0x88FFFFFF)),
  );
}

void _drift(
  Canvas c,
  AdvFrame f,
  Drifters d,
  double t,
  int count,
  bool calm,
  Color col, {
  double vx = 0,
  double vy = 0,
  double wob = 0.02,
  double rad = 0.006,
  double glowR = 0,
  double yMin = 0,
  double yMax = 1,
}) {
  final n = math.min(count, d.n);
  for (var i = 0; i < n; i++) {
    final tt = calm ? 0.0 : t;
    var x =
        (d.x[i] + vx * d.sp[i] * tt + math.sin(tt * d.sp[i] + d.ph[i]) * wob) %
        1.0;
    var y = (d.y[i] + vy * d.sp[i] * tt) % 1.0;
    if (x < 0) x += 1;
    if (y < 0) y += 1;
    final p = Offset(
      x * f.size.width,
      f.box.top + (yMin + y * (yMax - yMin)) * f.box.height,
    );
    final a = (0.45 + 0.55 * _tw(t, d.ph[i], 1.6 + d.sp[i])) * (calm ? 0.7 : 1);
    if (glowR > 0)
      glowDot(c, p, f.s * glowR * d.sz[i], col.withValues(alpha: 0.55 * a));
    c.drawCircle(p, f.s * rad * d.sz[i], fill(col.withValues(alpha: a)));
  }
}

// ======================= WELTALL =======================
final _spaceStars = Drifters(40, 71);

final AdventureWorldSpec _space = AdventureWorldSpec(
  id: 'space',
  titleDe: 'Reise durchs Weltall',
  titleEn: 'Journey through space',
  goalDe: 'Raumstation',
  goalEn: 'Space station',
  control: const [
    Offset(0.12, 0.86),
    Offset(0.36, 0.80),
    Offset(0.62, 0.72),
    Offset(0.44, 0.58),
    Offset(0.24, 0.44),
    Offset(0.46, 0.32),
    Offset(0.70, 0.24),
    Offset(0.82, 0.16),
  ],
  stations: _st,
  scaleFar: 0.20,
  scaleNear: 0.30,
  pathFar: 0.012,
  pathNear: 0.034,
  pathFill: const Color(0x1FBFE8FF),
  pathEdge: const Color(0x77BFE8FF),
  floating: true,
  bubble: true,
  barColors: const [Color(0xFF3FB8FF), Color(0xFFB97BFF)],
  paintBack: (c, f) {
    skyFill(c, f.size, const [
      Color(0xFF060820),
      Color(0xFF1A1250),
      Color(0xFF3A1F6E),
    ]);
    glowDot(
      c,
      Offset(f.size.width * 0.2, f.size.height * 0.25),
      f.size.width * 0.6,
      const Color(0x443BB0FF),
    );
    glowDot(
      c,
      Offset(f.size.width * 0.8, f.size.height * 0.34),
      f.size.width * 0.55,
      const Color(0x44E040A0),
    );
    glowDot(
      c,
      Offset(f.size.width * 0.35, f.size.height * 0.68),
      f.size.width * 0.5,
      const Color(0x3330D0C0),
    );
    starDots(c, f.size, 170, 7, rMax: 1.7);
    planet(
      c,
      f.p(0.2, 0.2),
      f.s * 0.09,
      const Color(0xFFFFD79A),
      const Color(0xFFD9772E),
      ring: true,
    );
    planet(
      c,
      f.p(0.88, 0.50),
      f.s * 0.06,
      const Color(0xFF8FD8FF),
      const Color(0xFF2A5FC0),
    );
    planet(
      c,
      f.p(0.8, 0.36),
      f.s * 0.028,
      const Color(0xFFEDEDF5),
      const Color(0xFF8A8AA8),
    );
    planet(
      c,
      f.p(1.0, 0.95),
      f.s * 0.16,
      const Color(0xFFFF8A7A),
      const Color(0xFF8A2A5A),
    );
    planet(
      c,
      f.p(0.06, 0.62),
      f.s * 0.035,
      const Color(0xFFB8F0A0),
      const Color(0xFF3A8A5A),
    );
    // Asteroiden
    final r = Rng(5);
    for (var i = 0; i < 9; i++) {
      final p = f.p(r.range(0.05, 0.95), r.range(0.1, 0.95));
      c.drawOval(
        Rect.fromCenter(
          center: p,
          width: f.s * r.range(0.012, 0.03),
          height: f.s * r.range(0.008, 0.02),
        ),
        fill(const Color(0xFF6A6A8A)),
      );
    }
    pathRibbon(c, f, _space, dash: 0.007);
    // Raumstation (Ziel)
    final g = f.p(0.82, 0.16);
    final u = f.s * 0.075;
    c.drawRect(
      Rect.fromCenter(center: g, width: u * 3.6, height: u * 0.28),
      fill(const Color(0xFF6C8AC8)),
    );
    for (final sx in [-1.0, 1.0]) {
      c.drawRect(
        Rect.fromCenter(
          center: g.translate(sx * u * 1.5, 0),
          width: u * 0.9,
          height: u * 1.5,
        ),
        fill(const Color(0xFF2A4AA8)),
      );
      c.drawRect(
        Rect.fromCenter(
          center: g.translate(sx * u * 1.5, 0),
          width: u * 0.9,
          height: u * 1.5,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFF8FB0FF)
          ..strokeWidth = 1,
      );
    }
    c.drawCircle(
      g,
      u * 0.78,
      Paint()
        ..shader = Gradient.radial(g.translate(-u * 0.2, -u * 0.25), u, const [
          Color(0xFFF2F6FF),
          Color(0xFF8A9AC8),
        ]),
    );
    c.drawCircle(g, u * 0.45, fill(const Color(0xFF2A3A7A)));
    c.drawCircle(
      g.translate(-u * 0.12, -u * 0.12),
      u * 0.12,
      fill(const Color(0x88FFFFFF)),
    );
    c.drawLine(
      g.translate(0, -u * 0.78),
      g.translate(0, -u * 1.25),
      Paint()
        ..color = const Color(0xFFCCD8F8)
        ..strokeWidth = 2,
    );
    c.drawCircle(
      g.translate(0, -u * 1.25),
      u * 0.1,
      fill(const Color(0xFFFF6A6A)),
    );
  },
  paintAmbient: (c, f, t, n, calm) {
    _drift(
      c,
      f,
      _spaceStars,
      t,
      14 + n,
      calm,
      const Color(0xFFFFFFFF),
      wob: 0,
      rad: 0.004,
      yMin: -0.2,
      yMax: 1.3,
    );
    if (!calm && n > 0) {
      final ph = (t % 8) / 8; // Sternschnuppe alle 8 s
      if (ph < 0.12) {
        final k = ph / 0.12;
        final a = Offset(
          f.size.width * (0.9 - 0.5 * k),
          f.box.top + f.box.height * (0.05 + 0.25 * k),
        );
        c.drawLine(
          a,
          a + Offset(f.s * 0.14, -f.s * 0.06),
          Paint()
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..shader = Gradient.linear(
              a,
              a + Offset(f.s * 0.14, -f.s * 0.06),
              const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
            ),
        );
      }
    }
  },
  paintStation: (c, p, s, lit, t) {
    final r = s * 0.02;
    c.drawRect(
      Rect.fromCenter(center: p, width: r * 2.4, height: r * 0.7),
      fill(Color.lerp(const Color(0xFF5A6AA0), const Color(0xFFFFE27A), lit)!),
    );
    _orb(
      c,
      p,
      s,
      lit,
      t,
      const Color(0xFFFFE27A),
      const Color(0xFF7A8AC8),
      r: 0.016,
    );
    if (lit > 0.5)
      sparkleStar(c, p.translate(0, -r * 2), r * 1.4, const Color(0xFFFFF4BE));
  },
  paintGoalGlow: (c, p, s, lit, t) {
    if (lit <= 0.01) return;
    glowDot(
      c,
      p,
      s * (0.22 + 0.02 * math.sin(t * 3)),
      const Color(0xAA8FD8FF),
      lit,
    );
    c.drawCircle(
      p,
      s * (0.10 + 0.04 * ((t * 0.8) % 1)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Color.fromRGBO(
          143,
          216,
          255,
          0.7 * lit * (1 - (t * 0.8) % 1),
        ),
    );
  },
);

// ======================= ABENDROT =======================
final _sunEmbers = Drifters(26, 81);

final AdventureWorldSpec _sunset = AdventureWorldSpec(
  id: 'sunset',
  titleDe: 'Abendrot-Wanderung',
  titleEn: 'Sunset hike',
  goalDe: 'Gemütliche Hütte',
  goalEn: 'Cozy cabin',
  control: const [
    Offset(0.10, 0.90),
    Offset(0.50, 0.86),
    Offset(0.78, 0.76),
    Offset(0.46, 0.66),
    Offset(0.22, 0.57),
    Offset(0.50, 0.48),
    Offset(0.78, 0.40),
    Offset(0.72, 0.31),
  ],
  stations: _st,
  scaleFar: 0.18,
  scaleNear: 0.33,
  pathFar: 0.02,
  pathNear: 0.09,
  pathFill: const Color(0xFFFFD58A),
  pathEdge: const Color(0xFFB8743A),
  barColors: const [Color(0xFFFF7A59), Color(0xFFFFC46B)],
  paintBack: (c, f) {
    final w = f.size.width;
    skyFill(
      c,
      f.size,
      const [
        Color(0xFF3E2F7A),
        Color(0xFFB5527A),
        Color(0xFFFF8A5A),
        Color(0xFFFFC46B),
      ],
      const [0, 0.30, 0.52, 0.64],
    );
    final hz = f.box.top + f.box.height * 0.33;
    glowDot(c, Offset(w * 0.28, hz), f.s * 0.7, const Color(0x66FFD27A));
    c.drawCircle(
      Offset(w * 0.28, hz - f.s * 0.02),
      f.s * 0.13,
      Paint()
        ..shader = Gradient.radial(Offset(w * 0.28, hz), f.s * 0.13, const [
          Color(0xFFFFFAD0),
          Color(0xFFFFB84A),
        ]),
    );
    final r = Rng(3);
    for (var i = 0; i < 6; i++) {
      final y = hz - f.s * r.range(0.05, 0.42);
      cloudPuff(
        c,
        Offset(w * r.range(0.05, 0.95), y),
        f.s * r.range(0.35, 0.6),
        Color.fromRGBO(255, 150 + (i * 9), 130, 0.55),
      );
    }
    for (var i = 0; i < 4; i++) {
      final b = Offset(
        w * (0.55 + i * 0.07),
        hz - f.s * (0.30 + 0.03 * (i % 2)),
      );
      final bp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4A2A5A)
        ..strokeCap = StrokeCap.round;
      c.drawPath(
        Path()
          ..moveTo(b.dx - 7, b.dy)
          ..quadraticBezierTo(b.dx - 3, b.dy - 5, b.dx, b.dy)
          ..quadraticBezierTo(b.dx + 3, b.dy - 5, b.dx + 7, b.dy),
        bp,
      );
    }
    ridge(
      c,
      f,
      base: 0.33,
      amp: 0.06,
      freq: 1.2,
      phase: 1,
      top: const Color(0xFF9A5A9A),
      bottom: const Color(0xFF6A3A7A),
    );
    ridge(
      c,
      f,
      base: 0.44,
      amp: 0.07,
      freq: 1.7,
      phase: 2,
      top: const Color(0xFFD0684A),
      bottom: const Color(0xFFA84A44),
    );
    ridge(
      c,
      f,
      base: 0.56,
      amp: 0.06,
      freq: 1.1,
      phase: 0.2,
      top: const Color(0xFFEDAA52),
      bottom: const Color(0xFFC27A3A),
    );
    c.drawRect(
      Rect.fromLTRB(0, f.box.top + f.box.height * 0.80, w, f.size.height),
      Paint()
        ..shader = vGrad(
          Rect.fromLTRB(0, f.box.top + f.box.height * 0.80, w, f.size.height),
          const [Color(0xFFC27A3A), Color(0xFF8A4A30)],
        ),
    );
    final tr = Rng(9);
    for (var i = 0; i < 9; i++) {
      firTree(
        c,
        Offset(
          w * tr.range(0.02, 0.98),
          f.box.top + f.box.height * tr.range(0.40, 0.50),
        ),
        f.s * tr.range(0.07, 0.11),
        const Color(0xFF5A2E5E),
        const Color(0xFF7A3E6A),
      );
    }
    pathRibbon(c, f, _sunset);
    for (final u in const [0.12, 0.33, 0.55, 0.78]) {
      final p = f.at(u);
      lanternPost(
        c,
        p.translate(f.s * 0.07, 0),
        f.s * (0.07 + 0.08 * f.depth(p)),
        const Color(0xFFFFB84A),
      );
    }
    // Hütte
    final g = f.p(0.72, 0.31);
    final u = f.s * 0.06;
    c.drawRect(
      Rect.fromLTWH(g.dx - u, g.dy - u * 1.1, u * 2, u * 1.1),
      Paint()
        ..shader = vGrad(
          Rect.fromLTWH(g.dx - u, g.dy - u * 1.1, u * 2, u * 1.1),
          const [Color(0xFFB07040), Color(0xFF7A4A2A)],
        ),
    );
    c.drawPath(
      Path()
        ..moveTo(g.dx - u * 1.3, g.dy - u * 1.05)
        ..lineTo(g.dx, g.dy - u * 2.1)
        ..lineTo(g.dx + u * 1.3, g.dy - u * 1.05)
        ..close(),
      fill(const Color(0xFF9A2E3A)),
    );
    c.drawRect(
      Rect.fromLTWH(g.dx + u * 0.5, g.dy - u * 2.0, u * 0.3, u * 0.7),
      fill(const Color(0xFF5A3A3A)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(g.dx - u * 0.75, g.dy - u * 0.8, u * 0.6, u * 0.55),
        Radius.circular(u * 0.08),
      ),
      fill(const Color(0xFFFFE08A)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(g.dx + u * 0.15, g.dy - u * 0.75, u * 0.5, u * 0.75),
        Radius.circular(u * 0.2),
      ),
      fill(const Color(0xFF5A3020)),
    );
    glowDot(
      c,
      g.translate(-u * 0.45, -u * 0.5),
      u * 1.3,
      const Color(0x55FFC46B),
    );
  },
  paintAmbient: (c, f, t, n, calm) {
    _drift(
      c,
      f,
      _sunEmbers,
      t,
      6 + n,
      calm,
      const Color(0xFFFFD27A),
      vx: 0.004,
      vy: -0.012,
      wob: 0.03,
      rad: 0.004,
      glowR: 0.016,
      yMin: 0.2,
      yMax: 1.0,
    );
  },
  paintStation: (c, p, s, lit, t) {
    _orb(
      c,
      p.translate(0, -s * 0.03),
      s,
      lit,
      t,
      const Color(0xFFFFC46B),
      const Color(0xFF8A6A5A),
      r: 0.016,
    );
  },
  paintGoalGlow: (c, p, s, lit, t) {
    if (lit <= 0.01) return;
    glowDot(
      c,
      p.translate(0, s * 0.04),
      s * (0.18 + 0.015 * math.sin(t * 4)),
      const Color(0xAAFFC46B),
      lit,
    );
  },
);

// ======================= STERNENNACHT =======================
final _nightFlies = Drifters(20, 91);
final _nightStars = Drifters(26, 92);

final AdventureWorldSpec _night = AdventureWorldSpec(
  id: 'night',
  titleDe: 'Mondpfad zum Sternentor',
  titleEn: 'Moon path to the star gate',
  goalDe: 'Sternentor',
  goalEn: 'Star gate',
  control: const [
    Offset(0.14, 0.88),
    Offset(0.38, 0.82),
    Offset(0.66, 0.76),
    Offset(0.78, 0.62),
    Offset(0.52, 0.54),
    Offset(0.28, 0.46),
    Offset(0.46, 0.36),
    Offset(0.60, 0.27),
  ],
  stations: _st,
  scaleFar: 0.18,
  scaleNear: 0.32,
  pathFar: 0.016,
  pathNear: 0.07,
  pathFill: const Color(0x70D4E4FF),
  pathEdge: const Color(0xCCFFFFFF),
  barColors: const [Color(0xFF6A5AE0), Color(0xFFB8C8FF)],
  paintBack: (c, f) {
    final w = f.size.width;
    skyFill(c, f.size, const [
      Color(0xFF060A24),
      Color(0xFF12205A),
      Color(0xFF2A3A86),
    ]);
    starDots(c, f.size, 150, 11, maxY: 0.6, rMax: 1.8);
    final m = Offset(w * 0.72, f.box.top + f.box.height * 0.13);
    glowDot(c, m, f.s * 0.42, const Color(0x55CFE0FF));
    c.drawCircle(
      m,
      f.s * 0.085,
      Paint()
        ..shader = Gradient.radial(
          m.translate(-f.s * 0.03, -f.s * 0.03),
          f.s * 0.12,
          const [Color(0xFFFFFBE6), Color(0xFFE8E2B8)],
        ),
    );
    for (final cr in const [
      Offset(-0.03, -0.02),
      Offset(0.025, 0.02),
      Offset(0.0, 0.045),
    ]) {
      c.drawCircle(m + cr * f.s, f.s * 0.014, fill(const Color(0x22A09A70)));
    }
    ridge(
      c,
      f,
      base: 0.42,
      amp: 0.08,
      freq: 1.3,
      phase: 0.6,
      top: const Color(0xFF1C2C72),
      bottom: const Color(0xFF101A4A),
    );
    ridge(
      c,
      f,
      base: 0.60,
      amp: 0.05,
      freq: 1.0,
      phase: 2.2,
      top: const Color(0xFF162466),
      bottom: const Color(0xFF0A1236),
    );
    final tr = Rng(13);
    for (var i = 0; i < 14; i++) {
      final y = f.box.top + f.box.height * tr.range(0.5, 0.62);
      firTree(
        c,
        Offset(w * tr.range(0.0, 1.0), y),
        f.s * tr.range(0.08, 0.16),
        const Color(0xFF0A1236),
        const Color(0xFF14204E),
      );
    }
    // winziges Dorf mit Lichtern
    for (var i = 0; i < 4; i++) {
      final p = Offset(w * (0.08 + i * 0.06), f.box.top + f.box.height * 0.58);
      c.drawRect(
        Rect.fromLTWH(p.dx, p.dy, f.s * 0.035, f.s * 0.03),
        fill(const Color(0xFF0A1236)),
      );
      c.drawRect(
        Rect.fromLTWH(
          p.dx + f.s * 0.01,
          p.dy + f.s * 0.008,
          f.s * 0.012,
          f.s * 0.012,
        ),
        fill(const Color(0xFFFFE08A)),
      );
    }
    c.drawRect(
      Rect.fromLTRB(0, f.box.top + f.box.height * 0.80, w, f.size.height),
      fill(const Color(0xFF0A1236)),
    );
    pathRibbon(c, f, _night, dash: 0.006);
    // Sternentor
    final g = f.p(0.60, 0.27);
    final u = f.s * 0.06;
    for (final sx in [-1.0, 1.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: g.translate(sx * u * 1.1, -u * 0.8),
            width: u * 0.6,
            height: u * 1.9,
          ),
          Radius.circular(u * 0.2),
        ),
        Paint()
          ..shader = vGrad(
            Rect.fromCenter(
              center: g.translate(sx * u * 1.1, -u * 0.8),
              width: u * 0.6,
              height: u * 1.9,
            ),
            const [Color(0xFFB8C4F0), Color(0xFF6A78B8)],
          ),
      );
    }
    c.drawArc(
      Rect.fromCenter(
        center: g.translate(0, -u * 1.5),
        width: u * 2.8,
        height: u * 2.2,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.5
        ..color = const Color(0xFF9AA8E0),
    );
    glowDot(c, g.translate(0, -u * 1.0), u * 1.6, const Color(0x33BFD0FF));
    sparkleStar(c, g.translate(0, -u * 1.2), u * 0.55, const Color(0xFFBFD0FF));
  },
  paintAmbient: (c, f, t, n, calm) {
    _drift(
      c,
      f,
      _nightStars,
      t,
      10 + n,
      calm,
      const Color(0xFFFFFFFF),
      wob: 0,
      rad: 0.004,
      yMin: -0.2,
      yMax: 0.6,
    );
    _drift(
      c,
      f,
      _nightFlies,
      t,
      4 + n ~/ 2,
      calm,
      const Color(0xFFFFF0A0),
      vx: 0.003,
      vy: -0.004,
      wob: 0.04,
      rad: 0.004,
      glowR: 0.014,
      yMin: 0.35,
      yMax: 1.0,
    );
    if (!calm && n > 0) {
      final ph = ((t + 3) % 9) / 9;
      if (ph < 0.1) {
        final k = ph / 0.1;
        final a = Offset(
          f.size.width * (0.2 + 0.5 * k),
          f.box.top + f.box.height * (0.04 + 0.2 * k),
        );
        c.drawLine(
          a,
          a - Offset(f.s * 0.12, f.s * 0.05),
          Paint()
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..shader = Gradient.linear(
              a,
              a - Offset(f.s * 0.12, f.s * 0.05),
              const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
            ),
        );
      }
    }
  },
  paintStation: (c, p, s, lit, t) {
    final r = s * 0.026;
    if (lit > 0.01)
      glowDot(c, p, r * 4, Color.fromRGBO(190, 210, 255, 0.5 * lit));
    sparkleStar(
      c,
      p,
      r * (1.0 + 0.5 * lit),
      Color.lerp(const Color(0xFF6A7AB8), const Color(0xFFF4F8FF), lit)!,
    );
  },
  paintGoalGlow: (c, p, s, lit, t) {
    if (lit <= 0.01) return;
    final g = p.translate(0, -s * 0.07);
    glowDot(
      c,
      g,
      s * (0.24 + 0.02 * math.sin(t * 3)),
      const Color(0xAABFD0FF),
      lit,
    );
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + t * 0.4;
      c.drawLine(
        g,
        g + Offset(math.cos(a), math.sin(a)) * s * 0.2,
        Paint()
          ..strokeWidth = 2
          ..color = Color.fromRGBO(220, 232, 255, 0.5 * lit),
      );
    }
  },
);

// ======================= ZAUBERWALD =======================
final _forestFlies = Drifters(30, 101);

void _bigTree(Canvas c, AdvFrame f, double x, double h, {bool mirror = false}) {
  final base = Offset(x, f.box.top + f.box.height * 1.02);
  final w = h * 0.2;
  final trunk = Path()
    ..moveTo(base.dx - w * 0.8, base.dy)
    ..quadraticBezierTo(
      base.dx - w * 0.5,
      base.dy - h * 0.4,
      base.dx - w * 0.4,
      base.dy - h,
    )
    ..lineTo(base.dx + w * 0.4, base.dy - h)
    ..quadraticBezierTo(
      base.dx + w * 0.5,
      base.dy - h * 0.4,
      base.dx + w * 0.8,
      base.dy,
    )
    ..close();
  c.drawPath(
    trunk,
    Paint()
      ..shader = Gradient.linear(
        Offset(base.dx - w, 0),
        Offset(base.dx + w, 0),
        const [Color(0xFF2A1E20), Color(0xFF5A4030), Color(0xFF2A1E20)],
        const [0, 0.5, 1],
      ),
  );
  final top = base.translate(0, -h);
  for (final o in const [
    Offset(-0.12, 0),
    Offset(0.12, 0.02),
    Offset(0, -0.1),
    Offset(-0.22, 0.1),
    Offset(0.24, 0.1),
  ]) {
    c.drawCircle(
      top + Offset(o.dx * h * (mirror ? -1 : 1), o.dy * h),
      h * 0.2,
      fill(const Color(0xFF0F4A3C)),
    );
  }
  c.drawCircle(
    top.translate(-h * 0.04, -h * 0.1),
    h * 0.16,
    fill(const Color(0xFF1A6A4A)),
  );
}

final AdventureWorldSpec _forest = AdventureWorldSpec(
  id: 'forest',
  titleDe: 'Pfad durch den Zauberwald',
  titleEn: 'Path through the enchanted forest',
  goalDe: 'Baumhaus',
  goalEn: 'Tree house',
  control: const [
    Offset(0.50, 0.93),
    Offset(0.30, 0.82),
    Offset(0.62, 0.70),
    Offset(0.38, 0.58),
    Offset(0.62, 0.47),
    Offset(0.44, 0.37),
    Offset(0.52, 0.29),
  ],
  stations: _st,
  scaleFar: 0.15,
  scaleNear: 0.34,
  pathFar: 0.03,
  pathNear: 0.15,
  pathFill: const Color(0xFFC9A66B),
  pathEdge: const Color(0xFF5A4A2E),
  barColors: const [Color(0xFF1FB89A), Color(0xFF8AE6A0)],
  paintBack: (c, f) {
    final w = f.size.width;
    skyFill(c, f.size, const [
      Color(0xFF0E3A3C),
      Color(0xFF1F6A52),
      Color(0xFF2E7A4A),
    ]);
    final r = Rng(21);
    for (var i = 0; i < 16; i++) {
      final x = w * r.range(0, 1);
      c.drawRect(
        Rect.fromLTWH(x, 0, f.s * r.range(0.025, 0.05), f.size.height),
        fill(
          Color.lerp(
            const Color(0xFF0B3A34),
            const Color(0xFF14604A),
            r.next(),
          )!.withValues(alpha: 0.8),
        ),
      );
    }
    // Lichtstrahlen
    for (var i = 0; i < 4; i++) {
      final x0 = w * (0.15 + i * 0.22);
      final p = Path()
        ..moveTo(x0, 0)
        ..lineTo(x0 + f.s * 0.12, 0)
        ..lineTo(x0 + f.s * 0.35, f.box.top + f.box.height * 0.8)
        ..lineTo(x0 + f.s * 0.18, f.box.top + f.box.height * 0.8)
        ..close();
      c.drawPath(
        p,
        Paint()
          ..shader = vGrad(
            Rect.fromLTWH(x0, 0, f.s * 0.4, f.size.height * 0.8),
            const [Color(0x44FFF4B0), Color(0x00FFF4B0)],
          ),
      );
    }
    final gy = f.box.top + f.box.height * 0.30;
    c.drawRect(
      Rect.fromLTRB(0, gy, w, f.size.height),
      Paint()
        ..shader = vGrad(Rect.fromLTRB(0, gy, w, f.size.height), const [
          Color(0xFF2E7A4A),
          Color(0xFF3E9A52),
          Color(0xFF1F6A3A),
        ]),
    );
    ridge(
      c,
      f,
      base: 0.32,
      amp: 0.03,
      freq: 2.0,
      phase: 0.4,
      top: const Color(0xFF1A6A48),
      bottom: const Color(0xFF2E7A4A),
    );
    pathRibbon(c, f, _forest);
    // Trittsteine entlang des Weges
    for (var i = 4; i < f.samples.length - 4; i += 7) {
      final p = f.samples[i];
      c.drawOval(
        Rect.fromCenter(
          center: p.translate(f.s * 0.02, f.s * 0.01),
          width: f.s * (0.02 + 0.04 * f.depth(p)),
          height: f.s * (0.012 + 0.02 * f.depth(p)),
        ),
        fill(const Color(0x66FFFFFF)),
      );
    }
    // Pilze & Farn am Weg
    final mr = Rng(23);
    final caps = [
      const Color(0xFFE8484A),
      const Color(0xFFB868E8),
      const Color(0xFF38C8C8),
    ];
    for (var i = 0; i < 12; i++) {
      final p = f.at(mr.range(0.05, 0.95));
      final side = (i.isEven ? 1 : -1) * f.s * (0.05 + 0.1 * f.depth(p));
      final b = p.translate(side, f.s * 0.01);
      final h = f.s * (0.04 + 0.07 * f.depth(p));
      glowDot(
        c,
        b.translate(0, -h * 0.6),
        h * 1.2,
        caps[i % 3].withValues(alpha: 0.25),
      );
      mushroom(c, b, h, caps[i % 3]);
    }
    _bigTree(c, f, w * 0.03, f.box.height * 0.95);
    _bigTree(c, f, w * 0.97, f.box.height * 0.95, mirror: true);
    _bigTree(c, f, w * 0.20, f.box.height * 0.55);
    _bigTree(c, f, w * 0.82, f.box.height * 0.5, mirror: true);
    // Baumhaus (Ziel)
    final g = f.p(0.52, 0.29);
    final u = f.s * 0.07;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: g.translate(0, -u * 1.2),
          width: u * 1.1,
          height: u * 3.4,
        ),
        Radius.circular(u * 0.3),
      ),
      fill(const Color(0xFF4A3426)),
    );
    c.drawOval(
      Rect.fromCenter(
        center: g.translate(0, -u * 3.0),
        width: u * 3.6,
        height: u * 2.4,
      ),
      fill(const Color(0xFF1A6A48)),
    );
    c.drawRect(
      Rect.fromCenter(
        center: g.translate(0, -u * 1.5),
        width: u * 2.0,
        height: u * 0.18,
      ),
      fill(const Color(0xFF8A5A3A)),
    );
    c.drawRect(
      Rect.fromCenter(
        center: g.translate(0, -u * 2.1),
        width: u * 1.6,
        height: u * 1.1,
      ),
      fill(const Color(0xFFC88A5A)),
    );
    c.drawPath(
      Path()
        ..moveTo(g.dx - u * 1.0, g.dy - u * 2.6)
        ..lineTo(g.dx, g.dy - u * 3.5)
        ..lineTo(g.dx + u * 1.0, g.dy - u * 2.6)
        ..close(),
      fill(const Color(0xFFD0484A)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: g.translate(0, -u * 2.0),
          width: u * 0.5,
          height: u * 0.7,
        ),
        Radius.circular(u * 0.25),
      ),
      fill(const Color(0xFFFFE9A0)),
    );
    for (var i = 0; i < 6; i++) {
      c.drawCircle(
        g.translate(
          -u * 0.9 + i * u * 0.36,
          -u * 1.38 + math.sin(i * 1.7) * u * 0.08,
        ),
        u * 0.07,
        fill(const Color(0xFFFFE27A)),
      );
    }
  },
  paintAmbient: (c, f, t, n, calm) {
    _drift(
      c,
      f,
      _forestFlies,
      t,
      8 + n,
      calm,
      const Color(0xFFD8FF8A),
      vx: 0.004,
      vy: -0.005,
      wob: 0.05,
      rad: 0.004,
      glowR: 0.018,
      yMin: 0.25,
      yMax: 1.0,
    );
  },
  paintStation: (c, p, s, lit, t) {
    final h = s * 0.05;
    final col = Color.lerp(
      const Color(0xFF6A8A7A),
      const Color(0xFF6AF0E0),
      lit,
    )!;
    if (lit > 0.01)
      glowDot(
        c,
        p.translate(0, -h * 0.6),
        h * (2.0 + 0.3 * math.sin(t * 3)),
        Color.fromRGBO(106, 240, 224, 0.55 * lit),
      );
    mushroom(c, p, h, col);
  },
  paintGoalGlow: (c, p, s, lit, t) {
    if (lit <= 0.01) return;
    glowDot(
      c,
      p.translate(0, -s * 0.15),
      s * (0.22 + 0.02 * math.sin(t * 4)),
      const Color(0xAAFFE9A0),
      lit,
    );
  },
);

// ======================= STRAND =======================
final _beachGulls = Drifters(4, 111);
final _beachSparks = Drifters(18, 112);

final AdventureWorldSpec _beach = AdventureWorldSpec(
  id: 'beach',
  titleDe: 'Strandspaziergang',
  titleEn: 'Beach walk',
  goalDe: 'Leuchtturm',
  goalEn: 'Lighthouse',
  control: const [
    Offset(0.10, 0.86),
    Offset(0.36, 0.82),
    Offset(0.58, 0.74),
    Offset(0.38, 0.64),
    Offset(0.60, 0.56),
    Offset(0.76, 0.49),
    Offset(0.80, 0.43),
  ],
  stations: _st,
  scaleFar: 0.20,
  scaleNear: 0.33,
  pathFar: 0.03,
  pathNear: 0.10,
  pathFill: const Color(0xFFFFF3D0),
  pathEdge: const Color(0xFFB88A48),
  barColors: const [Color(0xFF2AB8D0), Color(0xFFFFC46B)],
  paintBack: (c, f) {
    final w = f.size.width;
    skyFill(
      c,
      f.size,
      const [Color(0xFF5CC4F0), Color(0xFFBDE9FA), Color(0xFFFFF4D6)],
      const [0, 0.35, 0.5],
    );
    final hz = f.box.top + f.box.height * 0.34;
    glowDot(
      c,
      Offset(w * 0.8, hz - f.s * 0.28),
      f.s * 0.4,
      const Color(0x66FFF0B0),
    );
    c.drawCircle(
      Offset(w * 0.8, hz - f.s * 0.28),
      f.s * 0.065,
      fill(const Color(0xFFFFF4B0)),
    );
    cloudPuff(
      c,
      Offset(w * 0.2, hz - f.s * 0.25),
      f.s * 0.4,
      const Color(0xCCFFFFFF),
    );
    cloudPuff(
      c,
      Offset(w * 0.55, hz - f.s * 0.15),
      f.s * 0.3,
      const Color(0xAAFFFFFF),
    );
    // Meer
    final shore = f.box.top + f.box.height * 0.52;
    c.drawRect(
      Rect.fromLTRB(0, hz, w, shore),
      Paint()
        ..shader = vGrad(Rect.fromLTRB(0, hz, w, shore), const [
          Color(0xFF1FA0C8),
          Color(0xFF4CD0D8),
          Color(0xFF9AF0E0),
        ]),
    );
    final wr = Rng(31);
    for (var i = 0; i < 16; i++) {
      final y = hz + (shore - hz) * wr.range(0.1, 0.95);
      final x = w * wr.next();
      c.drawLine(
        Offset(x, y),
        Offset(x + f.s * wr.range(0.05, 0.12), y),
        Paint()
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x66FFFFFF),
      );
    }
    // Sand mit Schaumkante
    final sand = Path()..moveTo(0, shore);
    for (var i = 0; i <= 24; i++) {
      sand.lineTo(w * i / 24, shore + math.sin(i * 0.9) * f.s * 0.012);
    }
    sand
      ..lineTo(w, f.size.height)
      ..lineTo(0, f.size.height)
      ..close();
    c.drawPath(
      sand,
      Paint()
        ..shader = vGrad(Rect.fromLTRB(0, shore, w, f.size.height), const [
          Color(0xFFFFEBB8),
          Color(0xFFF0CC88),
          Color(0xFFD9A860),
        ]),
    );
    final foam = Path()..moveTo(0, shore);
    for (var i = 0; i <= 24; i++) {
      foam.lineTo(w * i / 24, shore + math.sin(i * 0.9) * f.s * 0.012);
    }
    c.drawPath(
      foam,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = f.s * 0.012
        ..color = const Color(0xDDFFFFFF),
    );
    // Felsen + Leuchtturm
    final g = f.p(0.80, 0.43);
    final u = f.s * 0.05;
    c.drawOval(
      Rect.fromCenter(
        center: g.translate(0, u * 0.4),
        width: u * 4.4,
        height: u * 1.2,
      ),
      fill(const Color(0xFF7A6A66)),
    );
    c.drawOval(
      Rect.fromCenter(
        center: g.translate(-u * 0.6, u * 0.25),
        width: u * 2.4,
        height: u * 0.9,
      ),
      fill(const Color(0xFF9A8A84)),
    );
    final body = Path()
      ..moveTo(g.dx - u * 0.9, g.dy)
      ..lineTo(g.dx - u * 0.55, g.dy - u * 4.2)
      ..lineTo(g.dx + u * 0.55, g.dy - u * 4.2)
      ..lineTo(g.dx + u * 0.9, g.dy)
      ..close();
    c.save();
    c.clipPath(body);
    c.drawRect(body.getBounds(), fill(const Color(0xFFFFFFFF)));
    for (var i = 0; i < 4; i++) {
      c.drawRect(
        Rect.fromLTWH(
          g.dx - u,
          g.dy - u * (0.2 + i * 1.1) - u * 0.5,
          u * 2,
          u * 0.55,
        ),
        fill(const Color(0xFFE8483A)),
      );
    }
    c.restore();
    c.drawRect(
      Rect.fromCenter(
        center: g.translate(0, -u * 4.5),
        width: u * 1.5,
        height: u * 0.7,
      ),
      fill(const Color(0xFFFFE08A)),
    );
    c.drawRect(
      Rect.fromCenter(
        center: g.translate(0, -u * 4.95),
        width: u * 1.7,
        height: u * 0.2,
      ),
      fill(const Color(0xFF3A3A4A)),
    );
    c.drawPath(
      Path()
        ..moveTo(g.dx - u * 0.75, g.dy - u * 5.0)
        ..lineTo(g.dx, g.dy - u * 5.9)
        ..lineTo(g.dx + u * 0.75, g.dy - u * 5.0)
        ..close(),
      fill(const Color(0xFFE8483A)),
    );
    pathRibbon(c, f, _beach);
    for (var i = 3; i < f.samples.length - 3; i += 8) {
      final p = f.samples[i];
      c.drawOval(
        Rect.fromCenter(
          center: p.translate(f.s * 0.012, 0),
          width: f.s * 0.02,
          height: f.s * 0.011,
        ),
        fill(const Color(0x33805020)),
      );
    }
    // Palmen & Muscheln
    for (final px in const [0.06, 0.94]) {
      final b = Offset(
        w * px,
        f.box.top + f.box.height * (px < 0.5 ? 0.78 : 0.7),
      );
      final lean = px < 0.5 ? 1.0 : -1.0;
      c.drawPath(
        Path()
          ..moveTo(b.dx, b.dy)
          ..quadraticBezierTo(
            b.dx + lean * f.s * 0.05,
            b.dy - f.s * 0.16,
            b.dx + lean * f.s * 0.1,
            b.dy - f.s * 0.3,
          )
          ..lineTo(b.dx + lean * f.s * 0.1 + 6, b.dy - f.s * 0.3)
          ..quadraticBezierTo(
            b.dx + lean * f.s * 0.06 + 6,
            b.dy - f.s * 0.15,
            b.dx + 8,
            b.dy,
          )
          ..close(),
        fill(const Color(0xFF8A5E3A)),
      );
      final top = Offset(b.dx + lean * f.s * 0.1, b.dy - f.s * 0.3);
      for (var i = 0; i < 6; i++) {
        final a = -math.pi / 2 + (i - 2.5) * 0.55;
        c.drawPath(
          Path()
            ..moveTo(top.dx, top.dy)
            ..quadraticBezierTo(
              top.dx + math.cos(a) * f.s * 0.1,
              top.dy + math.sin(a) * f.s * 0.12 - f.s * 0.03,
              top.dx + math.cos(a) * f.s * 0.17,
              top.dy + math.sin(a) * f.s * 0.1 + f.s * 0.07,
            ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = f.s * 0.025
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF2E9A4A),
        );
      }
    }
    final sr = Rng(33);
    for (var i = 0; i < 7; i++) {
      final p = f.p(sr.range(0.05, 0.95), sr.range(0.62, 0.95));
      sparkleStar(
        c,
        p,
        f.s * 0.016,
        i.isEven ? const Color(0xFFFF8A6A) : const Color(0xFFFFB8D0),
      );
    }
  },
  paintAmbient: (c, f, t, n, calm) {
    _drift(
      c,
      f,
      _beachSparks,
      t,
      4 + n ~/ 2,
      calm,
      const Color(0xFFFFFFFF),
      wob: 0,
      rad: 0.004,
      yMin: 0.35,
      yMax: 0.52,
    );
    // Wellenschaum (wandert)
    if (!calm) {
      final shore = f.box.top + f.box.height * 0.52;
      for (var i = 0; i < 3; i++) {
        final k = (t * 0.12 + i / 3) % 1;
        final y = shore - f.s * 0.05 * k;
        c.drawLine(
          Offset(f.size.width * 0.05, y),
          Offset(f.size.width * 0.95, y),
          Paint()
            ..strokeWidth = f.s * 0.006
            ..color = Color.fromRGBO(255, 255, 255, 0.5 * (1 - k)),
        );
      }
      for (var i = 0; i < math.min(3, _beachGulls.n); i++) {
        final x =
            (_beachGulls.x[i] + t * 0.01 * _beachGulls.sp[i]) %
            1.0 *
            f.size.width;
        final y =
            f.box.top +
            f.box.height * (0.08 + 0.12 * _beachGulls.y[i]) +
            math.sin(t + i) * 4;
        final fl = math.sin(t * 5 + i) * 3;
        c.drawPath(
          Path()
            ..moveTo(x - 9, y + fl)
            ..quadraticBezierTo(x - 4, y - 5, x, y)
            ..quadraticBezierTo(x + 4, y - 5, x + 9, y + fl),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF5A6A7A),
        );
      }
    }
  },
  paintStation: (c, p, s, lit, t) {
    final r = s * 0.02;
    c.drawPath(
      Path()
        ..moveTo(p.dx, p.dy)
        ..lineTo(p.dx, p.dy - r * 3),
      Paint()
        ..strokeWidth = 2
        ..color = const Color(0xFF8A5E3A),
    );
    c.drawPath(
      Path()
        ..moveTo(p.dx, p.dy - r * 3)
        ..lineTo(p.dx + r * 2, p.dy - r * 2.3)
        ..lineTo(p.dx, p.dy - r * 1.6)
        ..close(),
      fill(Color.lerp(const Color(0xFFB8A090), const Color(0xFFFF5A4A), lit)!),
    );
    if (lit > 0.5)
      sparkleStar(
        c,
        p.translate(0, -r * 3.6),
        r * 1.1,
        const Color(0xFFFFF4BE),
      );
  },
  paintGoalGlow: (c, p, s, lit, t) {
    if (lit <= 0.01) return;
    final top = p.translate(0, -s * 0.22);
    glowDot(c, top, s * 0.14, const Color(0xAAFFE08A), lit);
    final a = t * 1.2;
    c.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(top.dx + math.cos(a) * s * 0.4, top.dy - s * 0.04)
        ..lineTo(top.dx + math.cos(a) * s * 0.4, top.dy + s * 0.04)
        ..close(),
      fill(Color.fromRGBO(255, 240, 160, 0.4 * lit)),
    );
  },
);

// ======================= UNTERWASSER =======================
final _bubbles = Drifters(26, 121);
final _fish = Drifters(6, 122);

void _coral(Canvas c, Offset b, double h, Color col, int seed) {
  final r = Rng(seed);
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = col
    ..strokeWidth = h * 0.09;
  void branch(Offset o, double ang, double len, int d) {
    final e = o + Offset(math.cos(ang), math.sin(ang)) * len;
    c.drawLine(o, e, p..strokeWidth = h * 0.09 * (1 - d * 0.22));
    if (d < 3) {
      branch(e, ang - r.range(0.3, 0.7), len * 0.7, d + 1);
      branch(e, ang + r.range(0.3, 0.7), len * 0.7, d + 1);
    } else {
      c.drawCircle(e, h * 0.05, fill(mix(col, const Color(0xFFFFFFFF), 0.4)));
    }
  }

  branch(b, -math.pi / 2, h * 0.4, 0);
}

final AdventureWorldSpec _underwater = AdventureWorldSpec(
  id: 'underwater',
  titleDe: 'Tauchgang zum Schatz',
  titleEn: 'Dive to the treasure',
  goalDe: 'Schatztruhe',
  goalEn: 'Treasure chest',
  control: const [
    Offset(0.10, 0.80),
    Offset(0.32, 0.86),
    Offset(0.54, 0.76),
    Offset(0.74, 0.82),
    Offset(0.84, 0.68),
    Offset(0.64, 0.57),
    Offset(0.46, 0.51),
  ],
  stations: _st,
  scaleFar: 0.20,
  scaleNear: 0.30,
  pathFar: 0.03,
  pathNear: 0.09,
  pathFill: const Color(0xFFFFEFC0),
  pathEdge: const Color(0xFFB89868),
  floating: true,
  bubble: true,
  barColors: const [Color(0xFF12A8D0), Color(0xFF8AF0E0)],
  paintBack: (c, f) {
    final w = f.size.width;
    skyFill(c, f.size, const [
      Color(0xFF5ADAEE),
      Color(0xFF1E8AC0),
      Color(0xFF0A3E7A),
    ]);
    for (var i = 0; i < 5; i++) {
      final x0 = w * (0.1 + i * 0.2);
      c.drawPath(
        Path()
          ..moveTo(x0, 0)
          ..lineTo(x0 + f.s * 0.1, 0)
          ..lineTo(x0 + f.s * 0.3, f.size.height * 0.7)
          ..lineTo(x0 + f.s * 0.05, f.size.height * 0.7)
          ..close(),
        Paint()
          ..shader = vGrad(
            Rect.fromLTWH(x0, 0, f.s * 0.3, f.size.height * 0.7),
            const [Color(0x44FFFFFF), Color(0x00FFFFFF)],
          ),
      );
    }
    ridge(
      c,
      f,
      base: 0.40,
      amp: 0.07,
      freq: 1.4,
      phase: 0.3,
      top: const Color(0xFF1A6AA0),
      bottom: const Color(0xFF0E4A82),
      sharp: 0.5,
    );
    ridge(
      c,
      f,
      base: 0.52,
      amp: 0.05,
      freq: 2.1,
      phase: 1.5,
      top: const Color(0xFF1C7AA0),
      bottom: const Color(0xFF0E5A82),
    );
    final fl = f.box.top + f.box.height * 0.58;
    c.drawRect(
      Rect.fromLTRB(0, fl, w, f.size.height),
      Paint()
        ..shader = vGrad(Rect.fromLTRB(0, fl, w, f.size.height), const [
          Color(0xFFD8CC9A),
          Color(0xFFB8A070),
          Color(0xFF8A7A58),
        ]),
    );
    final r = Rng(41);
    final cols = [
      const Color(0xFFFF7A9A),
      const Color(0xFFFFA05A),
      const Color(0xFFB868E8),
      const Color(0xFFFF6A6A),
    ];
    for (var i = 0; i < 9; i++) {
      _coral(
        c,
        Offset(
          w * r.range(0, 1),
          f.box.top + f.box.height * r.range(0.56, 0.7),
        ),
        f.s * r.range(0.12, 0.2),
        cols[i % 4].withValues(alpha: 0.9),
        i + 50,
      );
    }
    pathRibbon(c, f, _underwater);
    for (var i = 4; i < f.samples.length - 4; i += 6) {
      final p = f.samples[i];
      c.drawOval(
        Rect.fromCenter(
          center: p.translate(f.s * 0.03, 0),
          width: f.s * 0.016,
          height: f.s * 0.01,
        ),
        fill(const Color(0x668A6A40)),
      );
    }
    // Seetang
    for (var i = 0; i < 8; i++) {
      final b = Offset(
        w * r.range(0, 1),
        f.box.top + f.box.height * r.range(0.78, 1.0),
      );
      final h = f.s * r.range(0.14, 0.26);
      final path = Path()..moveTo(b.dx, b.dy);
      for (var k = 1; k <= 8; k++) {
        path.lineTo(b.dx + math.sin(k * 0.9 + i) * h * 0.1, b.dy - h * k / 8);
      }
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = f.s * 0.018
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF2E9A5A),
      );
    }
    // Schatztruhe
    final g = f.p(0.46, 0.51);
    final u = f.s * 0.05;
    c.drawOval(
      Rect.fromCenter(
        center: g.translate(0, u * 0.5),
        width: u * 3.2,
        height: u * 0.6,
      ),
      fill(const Color(0x44000000)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(g.dx - u * 1.2, g.dy - u * 1.0, u * 2.4, u * 1.2),
        Radius.circular(u * 0.12),
      ),
      fill(const Color(0xFF8A5A30)),
    );
    c.drawPath(
      Path()
        ..moveTo(g.dx - u * 1.25, g.dy - u * 1.0)
        ..quadraticBezierTo(
          g.dx,
          g.dy - u * 2.2,
          g.dx + u * 1.25,
          g.dy - u * 1.0,
        )
        ..close(),
      fill(const Color(0xFFA06A3A)),
    );
    c.drawRect(
      Rect.fromLTWH(g.dx - u * 1.2, g.dy - u * 1.1, u * 2.4, u * 0.18),
      fill(const Color(0xFFFFC83D)),
    );
    c.drawRect(
      Rect.fromCenter(
        center: g.translate(0, -u * 0.7),
        width: u * 0.35,
        height: u * 0.5,
      ),
      fill(const Color(0xFFFFD86A)),
    );
  },
  paintAmbient: (c, f, t, n, calm) {
    // Blasen steigen auf
    final cnt = math.min(8 + n, _bubbles.n);
    for (var i = 0; i < cnt; i++) {
      final tt = calm ? 0.0 : t;
      final y = (_bubbles.y[i] - tt * 0.05 * _bubbles.sp[i]) % 1.0;
      final x =
          (_bubbles.x[i] +
              math.sin(tt * _bubbles.sp[i] + _bubbles.ph[i]) * 0.02) %
          1.0;
      final p = Offset(x * f.size.width, y * f.size.height);
      final r = f.s * 0.012 * _bubbles.sz[i] * 1.6;
      c.drawCircle(
        p,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xAAFFFFFF),
      );
      c.drawCircle(
        p.translate(-r * 0.3, -r * 0.3),
        r * 0.25,
        fill(const Color(0xCCFFFFFF)),
      );
    }
    if (!calm) {
      for (var i = 0; i < _fish.n; i++) {
        final dir = i.isEven ? 1.0 : -1.0;
        final x =
            ((_fish.x[i] + dir * t * 0.02 * _fish.sp[i]) % 1.0) * f.size.width;
        final y =
            f.box.top +
            f.box.height * (0.15 + 0.35 * _fish.y[i]) +
            math.sin(t + i) * 5;
        final col = [
          const Color(0xFFFFB84A),
          const Color(0xFFFF7A9A),
          const Color(0xFFFFE08A),
        ][i % 3];
        final s = f.s * 0.03 * (0.8 + _fish.sz[i] * 0.5);
        c.save();
        c.translate(x, y);
        c.scale(dir, 1);
        c.drawOval(
          Rect.fromCenter(center: Offset.zero, width: s * 2.2, height: s * 1.2),
          fill(col),
        );
        c.drawPath(
          Path()
            ..moveTo(-s, 0)
            ..lineTo(-s * 1.8, -s * 0.6)
            ..lineTo(-s * 1.8, s * 0.6)
            ..close(),
          fill(col),
        );
        c.drawCircle(
          Offset(s * 0.5, -s * 0.1),
          s * 0.14,
          fill(const Color(0xFF203050)),
        );
        c.restore();
      }
    }
  },
  paintStation: (c, p, s, lit, t) {
    final r = s * 0.022;
    final col = Color.lerp(
      const Color(0xFF9AB8D8),
      const Color(0xFFFFF0F8),
      lit,
    )!;
    if (lit > 0.01)
      glowDot(c, p, r * 3.4, Color.fromRGBO(255, 230, 250, 0.5 * lit));
    c.drawCircle(
      p,
      r,
      Paint()
        ..shader = Gradient.radial(p.translate(-r * 0.3, -r * 0.3), r * 1.3, [
          const Color(0xFFFFFFFF),
          col,
        ]),
    );
    c.drawCircle(
      p.translate(r * 1.4, -r * 1.2),
      r * 0.6,
      fill(col.withValues(alpha: 0.8)),
    );
  },
  paintGoalGlow: (c, p, s, lit, t) {
    if (lit <= 0.01) return;
    glowDot(
      c,
      p.translate(0, -s * 0.03),
      s * (0.2 + 0.02 * math.sin(t * 4)),
      const Color(0xCCFFE27A),
      lit,
    );
  },
);

// ======================= WINTER =======================
final _snow = Drifters(46, 131);

final AdventureWorldSpec _winter = AdventureWorldSpec(
  id: 'winter',
  titleDe: 'Winterwanderung zum Iglu',
  titleEn: 'Winter walk to the igloo',
  goalDe: 'Iglu',
  goalEn: 'Igloo',
  control: const [
    Offset(0.14, 0.90),
    Offset(0.44, 0.84),
    Offset(0.72, 0.75),
    Offset(0.52, 0.64),
    Offset(0.30, 0.54),
    Offset(0.52, 0.44),
    Offset(0.72, 0.36),
  ],
  stations: _st,
  scaleFar: 0.18,
  scaleNear: 0.33,
  pathFar: 0.025,
  pathNear: 0.09,
  pathFill: const Color(0xFFCFDDF0),
  pathEdge: const Color(0xFF7A9AC8),
  barColors: const [Color(0xFF4AA0E8), Color(0xFFB8E0FF)],
  paintBack: (c, f) {
    final w = f.size.width;
    skyFill(c, f.size, const [
      Color(0xFF9CC4EE),
      Color(0xFFDCEAF8),
      Color(0xFFF6FAFF),
    ]);
    glowDot(
      c,
      Offset(w * 0.3, f.box.top + f.box.height * 0.2),
      f.s * 0.4,
      const Color(0x55FFFFFF),
    );
    c.drawCircle(
      Offset(w * 0.3, f.box.top + f.box.height * 0.2),
      f.s * 0.05,
      fill(const Color(0xCCFFFFFF)),
    );
    ridge(
      c,
      f,
      base: 0.36,
      amp: 0.09,
      freq: 1.0,
      phase: 0.8,
      top: const Color(0xFFC4D8F0),
      bottom: const Color(0xFFE0ECF8),
      sharp: 0.6,
    );
    ridge(
      c,
      f,
      base: 0.47,
      amp: 0.06,
      freq: 1.5,
      phase: 2.0,
      top: const Color(0xFFE2EEF9),
      bottom: const Color(0xFFF2F8FD),
    );
    final gy = f.box.top + f.box.height * 0.56;
    c.drawRect(
      Rect.fromLTRB(0, gy, w, f.size.height),
      Paint()
        ..shader = vGrad(Rect.fromLTRB(0, gy, w, f.size.height), const [
          Color(0xFFF6FAFF),
          Color(0xFFDCE8F6),
        ]),
    );
    final r = Rng(51);
    for (var i = 0; i < 16; i++) {
      final y = f.box.top + f.box.height * r.range(0.42, 0.6);
      firTree(
        c,
        Offset(w * r.range(0, 1), y),
        f.s * r.range(0.07, 0.13),
        const Color(0xFF2A5A5E),
        const Color(0xFF3C7A6A),
        snow: true,
      );
    }
    pathRibbon(c, f, _winter);
    for (var i = 3; i < f.samples.length - 3; i += 6) {
      final p = f.samples[i];
      c.drawOval(
        Rect.fromCenter(
          center: p.translate(f.s * 0.012, 0),
          width: f.s * 0.018,
          height: f.s * 0.01,
        ),
        fill(const Color(0x338AA8D0)),
      );
    }
    for (final px in const [0.04, 0.96, 0.9]) {
      firTree(
        c,
        Offset(w * px, f.box.top + f.box.height * (px == 0.9 ? 0.72 : 0.9)),
        f.s * 0.3,
        const Color(0xFF24505A),
        const Color(0xFF3C7A6A),
        snow: true,
      );
    }
    // Iglu
    final g = f.p(0.72, 0.36);
    final u = f.s * 0.07;
    final dome = Rect.fromCenter(center: g, width: u * 3.2, height: u * 3.0);
    c.drawArc(
      dome,
      math.pi,
      math.pi,
      true,
      Paint()
        ..shader = Gradient.radial(
          g.translate(-u * 0.6, -u * 1.0),
          u * 2.2,
          const [Color(0xFFFFFFFF), Color(0xFFC8DAF0)],
        ),
    );
    for (var i = 1; i < 4; i++) {
      c.drawLine(
        g.translate(
          -u * 1.6 * math.cos(i * 0.35),
          -u * 1.5 * math.sin(i * 0.45 + 0.25),
        ),
        g.translate(
          u * 1.6 * math.cos(i * 0.35),
          -u * 1.5 * math.sin(i * 0.45 + 0.25),
        ),
        Paint()
          ..color = const Color(0x558AA8D0)
          ..strokeWidth = 1.4,
      );
    }
    c.drawArc(
      Rect.fromCenter(
        center: g.translate(0, 0),
        width: u * 1.1,
        height: u * 1.5,
      ),
      math.pi,
      math.pi,
      true,
      fill(const Color(0xFF7A4A28)),
    );
    glowDot(c, g.translate(0, -u * 0.3), u * 1.0, const Color(0x44FFB84A));
    c.drawArc(
      Rect.fromCenter(
        center: g.translate(0, 0),
        width: u * 0.7,
        height: u * 1.0,
      ),
      math.pi,
      math.pi,
      true,
      fill(const Color(0xFFFFC66A)),
    );
  },
  paintAmbient: (c, f, t, n, calm) {
    final cnt = math.min(14 + n * 2, _snow.n);
    for (var i = 0; i < cnt; i++) {
      final tt = calm ? 0.0 : t;
      final y = (_snow.y[i] + tt * 0.06 * _snow.sp[i]) % 1.0;
      final x =
          (_snow.x[i] + math.sin(tt * _snow.sp[i] + _snow.ph[i]) * 0.03) % 1.0;
      c.drawCircle(
        Offset(x * f.size.width, y * f.size.height),
        f.s * 0.007 * (0.6 + _snow.sz[i]),
        fill(const Color(0xDDFFFFFF)),
      );
    }
  },
  paintStation: (c, p, s, lit, t) {
    final r = s * 0.026;
    c.drawCircle(p.translate(0, -r * 0.5), r, fill(const Color(0xFFFFFFFF)));
    c.drawCircle(
      p.translate(0, -r * 1.9),
      r * 0.7,
      fill(const Color(0xFFFFFFFF)),
    );
    c.drawCircle(
      p.translate(-r * 0.25, -r * 2.0),
      r * 0.1,
      fill(const Color(0xFF203050)),
    );
    c.drawCircle(
      p.translate(r * 0.25, -r * 2.0),
      r * 0.1,
      fill(const Color(0xFF203050)),
    );
    c.drawPath(
      Path()
        ..moveTo(p.dx, p.dy - r * 1.8)
        ..lineTo(p.dx + r * 0.6, p.dy - r * 1.7)
        ..lineTo(p.dx, p.dy - r * 1.6)
        ..close(),
      fill(const Color(0xFFFF8A3A)),
    );
    final scarf = Color.lerp(
      const Color(0xFF9AB0D0),
      const Color(0xFFE8484A),
      lit,
    )!;
    c.drawRect(
      Rect.fromCenter(
        center: p.translate(0, -r * 1.3),
        width: r * 1.5,
        height: r * 0.3,
      ),
      fill(scarf),
    );
    if (lit > 0.5)
      sparkleStar(
        c,
        p.translate(r * 1.6, -r * 2.8),
        r * 0.6,
        const Color(0xFFFFF4BE),
      );
  },
  paintGoalGlow: (c, p, s, lit, t) {
    if (lit <= 0.01) return;
    glowDot(
      c,
      p.translate(0, -s * 0.02),
      s * (0.18 + 0.015 * math.sin(t * 4)),
      const Color(0xAAFFC66A),
      lit,
    );
  },
);

// ======================= WOLKENHIMMEL =======================
final _skyClouds = Drifters(5, 141);
final _skyBirds = Drifters(3, 142);
final _skySparks = Drifters(16, 143);

final AdventureWorldSpec _sky = AdventureWorldSpec(
  id: 'sky',
  titleDe: 'Über die Wolkenbrücke',
  titleEn: 'Across the cloud bridge',
  goalDe: 'Wolkenschloss',
  goalEn: 'Cloud castle',
  control: const [
    Offset(0.14, 0.88),
    Offset(0.48, 0.82),
    Offset(0.78, 0.70),
    Offset(0.50, 0.60),
    Offset(0.22, 0.48),
    Offset(0.46, 0.37),
    Offset(0.62, 0.28),
  ],
  stations: _st,
  scaleFar: 0.20,
  scaleNear: 0.32,
  pathFar: 0.02,
  pathNear: 0.07,
  pathFill: const Color(0xDDFFFFFF),
  pathEdge: const Color(0xFFFFFFFF),
  floating: false,
  barColors: const [Color(0xFF4AA8F0), Color(0xFFFF9AC8)],
  paintBack: (c, f) {
    final w = f.size.width;
    skyFill(c, f.size, const [
      Color(0xFF3E9CEE),
      Color(0xFF9ED8FA),
      Color(0xFFE8F6FF),
    ]);
    glowDot(
      c,
      Offset(w * 0.8, f.box.top + f.box.height * 0.1),
      f.s * 0.5,
      const Color(0x66FFF4B0),
    );
    c.drawCircle(
      Offset(w * 0.8, f.box.top + f.box.height * 0.1),
      f.s * 0.06,
      fill(const Color(0xFFFFF4B0)),
    );
    // Regenbogen
    final rc = const [
      Color(0xFFFF6A6A),
      Color(0xFFFFA05A),
      Color(0xFFFFE05A),
      Color(0xFF6AD86A),
      Color(0xFF5AB8F0),
      Color(0xFF8A7AE8),
    ];
    final ctr = Offset(w * 0.1, f.box.top + f.box.height * 0.62);
    for (var i = 0; i < rc.length; i++) {
      c.drawArc(
        Rect.fromCircle(center: ctr, radius: f.s * (0.62 - i * 0.028)),
        -math.pi * 0.95,
        math.pi * 0.62,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = f.s * 0.03
          ..color = rc[i].withValues(alpha: 0.7),
      );
    }
    // schwebende Inseln
    for (final o in const [Offset(0.18, 0.2), Offset(0.84, 0.46)]) {
      final p = f.p(o.dx, o.dy);
      final u = f.s * 0.07;
      c.drawPath(
        Path()
          ..moveTo(p.dx - u * 1.3, p.dy)
          ..lineTo(p.dx + u * 1.3, p.dy)
          ..quadraticBezierTo(
            p.dx + u * 0.4,
            p.dy + u * 1.6,
            p.dx,
            p.dy + u * 1.9,
          )
          ..quadraticBezierTo(
            p.dx - u * 0.4,
            p.dy + u * 1.6,
            p.dx - u * 1.3,
            p.dy,
          )
          ..close(),
        fill(const Color(0xFF9A7A5A)),
      );
      c.drawOval(
        Rect.fromCenter(center: p, width: u * 2.7, height: u * 0.55),
        fill(const Color(0xFF6AD86A)),
      );
      roundTree(
        c,
        p.translate(-u * 0.4, 0),
        u * 1.5,
        const Color(0xFF38A85A),
        const Color(0xFF6AD88A),
      );
    }
    for (var i = 0; i < 6; i++) {
      cloudPuff(
        c,
        Offset(
          w * (0.08 + i * 0.18),
          f.box.top + f.box.height * (0.45 + (i % 3) * 0.12),
        ),
        f.s * 0.3,
        const Color(0x99FFFFFF),
      );
    }
    // Wolkenboden
    for (var i = 0; i < 8; i++) {
      cloudPuff(
        c,
        Offset(
          w * (i * 0.15),
          f.box.top + f.box.height * 1.0 + (i % 2) * f.s * 0.03,
        ),
        f.s * 0.5,
        const Color(0xFFFFFFFF),
      );
    }
    pathRibbon(c, f, _sky, dash: 0.01);
    for (var i = 3; i < f.samples.length - 3; i += 6) {
      final p = f.samples[i];
      cloudPuff(
        c,
        p,
        f.s * (0.07 + 0.09 * f.depth(p)),
        const Color(0xFFFFFFFF),
      );
    }
    // Wolkenschloss
    final g = f.p(0.62, 0.28);
    final u = f.s * 0.05;
    cloudPuff(c, g.translate(0, u * 0.3), u * 6, const Color(0xFFFFFFFF));
    for (final tx in const [-1.4, 0.0, 1.4]) {
      final h = tx == 0.0 ? 3.2 : 2.2;
      c.drawRect(
        Rect.fromLTWH(g.dx + tx * u - u * 0.5, g.dy - u * h, u, u * h),
        Paint()
          ..shader = vGrad(
            Rect.fromLTWH(g.dx + tx * u - u * 0.5, g.dy - u * h, u, u * h),
            const [Color(0xFFFFF0F8), Color(0xFFE0C8E8)],
          ),
      );
      c.drawPath(
        Path()
          ..moveTo(g.dx + tx * u - u * 0.65, g.dy - u * h)
          ..lineTo(g.dx + tx * u, g.dy - u * (h + 1.1))
          ..lineTo(g.dx + tx * u + u * 0.65, g.dy - u * h)
          ..close(),
        fill(tx == 0.0 ? const Color(0xFFFF7AA8) : const Color(0xFFB88AE8)),
      );
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: g.translate(0, -u * 0.4),
          width: u * 0.7,
          height: u * 0.9,
        ),
        Radius.circular(u * 0.35),
      ),
      fill(const Color(0xFF8A5AB8)),
    );
    sparkleStar(c, g.translate(0, -u * 4.6), u * 0.5, const Color(0xFFFFD23F));
  },
  paintAmbient: (c, f, t, n, calm) {
    for (var i = 0; i < _skyClouds.n; i++) {
      final x =
          ((_skyClouds.x[i] + (calm ? 0 : t) * 0.006 * _skyClouds.sp[i]) % 1.3 -
              0.15) *
          f.size.width;
      cloudPuff(
        c,
        Offset(x, f.box.top + f.box.height * (0.08 + _skyClouds.y[i] * 0.5)),
        f.s * (0.2 + 0.12 * _skyClouds.sz[i]),
        const Color(0xAAFFFFFF),
      );
    }
    if (!calm) {
      for (var i = 0; i < _skyBirds.n; i++) {
        final x = (_skyBirds.x[i] + t * 0.012) % 1.0 * f.size.width;
        final y =
            f.box.top +
            f.box.height * (0.15 + 0.2 * _skyBirds.y[i]) +
            math.sin(t * 1.5 + i) * 6;
        final fl = math.sin(t * 6 + i) * 3;
        c.drawPath(
          Path()
            ..moveTo(x - 8, y + fl)
            ..quadraticBezierTo(x - 3, y - 5, x, y)
            ..quadraticBezierTo(x + 3, y - 5, x + 8, y + fl),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF5A6A8A),
        );
      }
    }
    _drift(
      c,
      f,
      _skySparks,
      t,
      3 + n ~/ 2,
      calm,
      const Color(0xFFFFF4BE),
      vy: -0.004,
      wob: 0.03,
      rad: 0.004,
      glowR: 0.012,
      yMin: 0.1,
      yMax: 1.0,
    );
  },
  paintStation: (c, p, s, lit, t) {
    final r = s * 0.034;
    const cols = [Color(0xFFFF6A6A), Color(0xFFFFE05A), Color(0xFF5AB8F0)];
    for (var i = 0; i < 3; i++) {
      c.drawArc(
        Rect.fromCircle(
          center: p.translate(0, r * 0.2),
          radius: r * (1.0 - i * 0.22),
        ),
        math.pi,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.22
          ..color = Color.lerp(
            const Color(0xFFD0DCEC),
            cols[i],
            0.25 + 0.75 * lit,
          )!,
      );
    }
    if (lit > 0.5)
      sparkleStar(
        c,
        p.translate(r * 1.2, -r * 1.2),
        r * 0.5,
        const Color(0xFFFFF4BE),
      );
  },
  paintGoalGlow: (c, p, s, lit, t) {
    if (lit <= 0.01) return;
    glowDot(
      c,
      p.translate(0, -s * 0.12),
      s * (0.22 + 0.02 * math.sin(t * 3)),
      const Color(0xAAFFE27A),
      lit,
    );
  },
);
