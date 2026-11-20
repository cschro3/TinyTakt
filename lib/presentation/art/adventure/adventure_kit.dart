import 'dart:math' as math;
import 'dart:ui';

import '../art_kit.dart' show Rng, mix;
import 'adventure_spec.dart';

export '../art_kit.dart' show Rng, mix, sparkleStar;

/// Gemeinsamer Zeichen-Baukasten der Abenteuerwelten (alles statisch → wird einmal gebacken).

Paint fill(Color c) => Paint()..color = c;

Shader vGrad(Rect r, List<Color> cols, [List<double>? stops]) =>
    Gradient.linear(
      r.topCenter,
      r.bottomCenter,
      cols,
      stops ?? [for (var i = 0; i < cols.length; i++) i / (cols.length - 1)],
    );

/// Vollflächiger Himmelsverlauf.
void skyFill(Canvas c, Size s, List<Color> cols, [List<double>? stops]) {
  c.drawRect(
    Offset.zero & s,
    Paint()..shader = vGrad(Offset.zero & s, cols, stops),
  );
}

/// Weiches Leuchten (radial).
void glowDot(Canvas c, Offset p, double r, Color col, [double a = 1]) {
  c.drawCircle(
    p,
    r,
    Paint()
      ..shader = Gradient.radial(p, r, [
        col.withValues(alpha: col.a * a),
        col.withValues(alpha: 0),
      ]),
  );
}

/// Hügel-/Berg-Silhouette über die ganze Bildschirmbreite. [base]/[amp] relativ zum Feld.
void ridge(
  Canvas c,
  AdvFrame f, {
  required double base,
  required double amp,
  required double freq,
  required double phase,
  required Color top,
  required Color bottom,
  double sharp = 0, // 0 = sanfte Hügel, 1 = spitze Berge
}) {
  final w = f.size.width;
  final y0 = f.box.top + base * f.box.height;
  final a = amp * f.box.height;
  final path = Path()..moveTo(-4, f.size.height + 4);
  const n = 48;
  for (var i = 0; i <= n; i++) {
    final x = -4 + (w + 8) * i / n;
    final u = x / w * freq * math.pi * 2 + phase;
    var v =
        math.sin(u) * 0.55 +
        math.sin(u * 2.3 + 1.1) * 0.3 +
        math.sin(u * 4.1) * 0.15;
    if (sharp > 0)
      v =
          (1 - sharp) * v +
          sharp * (1 - 2 * (math.asin(math.sin(u)).abs() / (math.pi / 2)));
    path.lineTo(x, y0 - v * a);
  }
  path
    ..lineTo(w + 4, f.size.height + 4)
    ..close();
  c.drawPath(
    path,
    Paint()
      ..shader = vGrad(Rect.fromLTRB(0, y0 - a, w, f.size.height), [
        top,
        bottom,
      ]),
  );
}

/// Weg als perspektivisches Band entlang der Wegpunkte (hinten schmaler).
void pathRibbon(Canvas c, AdvFrame f, AdventureWorldSpec w, {double dash = 0}) {
  final left = <Offset>[], right = <Offset>[];
  final pts = f.samples;
  for (var i = 0; i < pts.length; i++) {
    final a = pts[math.max(i - 1, 0)], b = pts[math.min(i + 1, pts.length - 1)];
    final d = b - a;
    final len = d.distance == 0 ? 1 : d.distance;
    final nrm = Offset(-d.dy / len, d.dx / len);
    final wd =
        (w.pathFar + (w.pathNear - w.pathFar) * f.depth(pts[i])) * f.s * 0.5;
    left.add(pts[i] + nrm * wd);
    right.add(pts[i] - nrm * wd);
  }
  final path = Path()..moveTo(left.first.dx, left.first.dy);
  for (final p in left.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  for (final p in right.reversed) {
    path.lineTo(p.dx, p.dy);
  }
  path.close();
  c.drawPath(path, fill(w.pathFill));
  final edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = f.s * 0.012
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = w.pathEdge;
  for (final side in [left, right]) {
    final e = Path()..moveTo(side.first.dx, side.first.dy);
    for (final p in side.skip(1)) {
      e.lineTo(p.dx, p.dy);
    }
    c.drawPath(e, edge);
  }
  if (dash > 0) {
    // Mittellinie aus Punkten (Sternenspur, Wolkentritte …)
    for (var i = 2; i < pts.length - 2; i += 3) {
      final r = f.s * dash * (0.5 + 0.5 * f.depth(pts[i]));
      c.drawCircle(pts[i], r, fill(w.pathEdge));
    }
  }
}

// ---- Bäume & Pflanzen ----

void firTree(
  Canvas c,
  Offset base,
  double h,
  Color dark,
  Color light, {
  bool snow = false,
}) {
  final w = h * 0.52;
  c.drawRect(
    Rect.fromLTWH(base.dx - w * 0.07, base.dy - h * 0.12, w * 0.14, h * 0.14),
    fill(const Color(0xFF5A3A28)),
  );
  for (var i = 0; i < 3; i++) {
    final y = base.dy - h * (0.08 + i * 0.27);
    final ww = w * (1 - i * 0.28);
    final tier = Path()
      ..moveTo(base.dx - ww / 2, y)
      ..lineTo(base.dx, y - h * 0.42)
      ..lineTo(base.dx + ww / 2, y)
      ..close();
    c.drawPath(
      tier,
      Paint()
        ..shader = Gradient.linear(
          Offset(base.dx - ww / 2, y),
          Offset(base.dx + ww / 2, y),
          [dark, light],
        ),
    );
    if (snow) {
      final cap = Path()
        ..moveTo(base.dx - ww * 0.30, y - h * 0.16)
        ..lineTo(base.dx, y - h * 0.42)
        ..lineTo(base.dx + ww * 0.30, y - h * 0.16)
        ..quadraticBezierTo(
          base.dx + ww * 0.1,
          y - h * 0.09,
          base.dx,
          y - h * 0.15,
        )
        ..quadraticBezierTo(
          base.dx - ww * 0.12,
          y - h * 0.08,
          base.dx - ww * 0.30,
          y - h * 0.16,
        );
      c.drawPath(cap, fill(const Color(0xFFF4FAFF)));
    }
  }
}

void roundTree(
  Canvas c,
  Offset base,
  double h,
  Color crown,
  Color crownLight, {
  Color trunk = const Color(0xFF6A4630),
}) {
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(base.dx - h * 0.05, base.dy - h * 0.45, h * 0.10, h * 0.46),
      Radius.circular(h * 0.04),
    ),
    fill(trunk),
  );
  final r = h * 0.30;
  final ctr = base.translate(0, -h * 0.66);
  c.drawCircle(
    ctr,
    r,
    Paint()
      ..shader = Gradient.radial(ctr.translate(-r * 0.3, -r * 0.35), r * 1.4, [
        crownLight,
        crown,
      ]),
  );
  c.drawCircle(ctr.translate(-r * 0.7, r * 0.25), r * 0.62, fill(crown));
  c.drawCircle(ctr.translate(r * 0.72, r * 0.2), r * 0.6, fill(crown));
}

void mushroom(
  Canvas c,
  Offset base,
  double h,
  Color cap, {
  Color dots = const Color(0xFFFFFFFF),
}) {
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(base.dx - h * 0.11, base.dy - h * 0.55, h * 0.22, h * 0.55),
      Radius.circular(h * 0.08),
    ),
    fill(const Color(0xFFF6EEDC)),
  );
  final r = Rect.fromCenter(
    center: base.translate(0, -h * 0.58),
    width: h * 0.95,
    height: h * 0.7,
  );
  c.drawArc(
    r,
    math.pi,
    math.pi,
    true,
    Paint()
      ..shader = Gradient.radial(
        r.center.translate(-h * 0.15, -h * 0.2),
        h * 0.7,
        [mix(cap, const Color(0xFFFFFFFF), 0.3), cap],
      ),
  );
  c.drawCircle(r.center.translate(-h * 0.2, -h * 0.12), h * 0.07, fill(dots));
  c.drawCircle(r.center.translate(h * 0.18, -h * 0.2), h * 0.055, fill(dots));
  c.drawCircle(r.center.translate(h * 0.02, -h * 0.05), h * 0.05, fill(dots));
}

void cloudPuff(Canvas c, Offset p, double w, Color col, {double alpha = 1}) {
  final paint = fill(col.withValues(alpha: col.a * alpha));
  c.drawOval(Rect.fromCenter(center: p, width: w, height: w * 0.32), paint);
  c.drawCircle(p.translate(-w * 0.18, -w * 0.08), w * 0.17, paint);
  c.drawCircle(p.translate(w * 0.05, -w * 0.15), w * 0.22, paint);
  c.drawCircle(p.translate(w * 0.27, -w * 0.05), w * 0.15, paint);
}

void planet(
  Canvas c,
  Offset p,
  double r,
  Color a,
  Color b, {
  bool ring = false,
  Color? ringColor,
}) {
  if (ring) {
    final rc = ringColor ?? const Color(0xAAFFE9B0);
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(-0.35);
    c.drawArc(
      Rect.fromCenter(center: Offset.zero, width: r * 3.3, height: r * 0.9),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.16
        ..color = rc,
    );
    c.restore();
  }
  c.drawCircle(
    p,
    r,
    Paint()
      ..shader = Gradient.radial(p.translate(-r * 0.35, -r * 0.4), r * 1.5, [
        a,
        b,
      ]),
  );
  c.drawCircle(
    p,
    r,
    Paint()
      ..shader = Gradient.radial(p.translate(r * 0.45, r * 0.4), r * 1.1, [
        const Color(0x00000000),
        const Color(0x66000020),
      ]),
  );
  if (ring) {
    final rc = ringColor ?? const Color(0xAAFFE9B0);
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(-0.35);
    c.clipRect(Rect.fromLTWH(-r * 2, 0, r * 4, r * 2));
    c.drawArc(
      Rect.fromCenter(center: Offset.zero, width: r * 3.3, height: r * 0.9),
      0,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.16
        ..color = rc,
    );
    c.restore();
  }
}

void starDots(
  Canvas c,
  Size size,
  int n,
  int seed, {
  double minY = 0,
  double maxY = 1,
  Color col = const Color(0xFFFFFFFF),
  double rMax = 1.6,
}) {
  final rnd = Rng(seed);
  final big = Paint()..color = col.withValues(alpha: 0.9);
  final small = Paint()..color = col.withValues(alpha: 0.55);
  for (var i = 0; i < n; i++) {
    final p = Offset(
      rnd.next() * size.width,
      (minY + rnd.next() * (maxY - minY)) * size.height,
    );
    final r = rnd.range(0.4, rMax);
    c.drawCircle(p, r, r > rMax * 0.7 ? big : small);
  }
}

void lanternPost(
  Canvas c,
  Offset base,
  double h,
  Color glowCol, {
  bool lit = true,
}) {
  c.drawRect(
    Rect.fromLTWH(base.dx - h * 0.025, base.dy - h, h * 0.05, h),
    fill(const Color(0xFF3B2A2A)),
  );
  final head = Rect.fromCenter(
    center: base.translate(0, -h),
    width: h * 0.2,
    height: h * 0.26,
  );
  if (lit) glowDot(c, head.center, h * 0.55, glowCol.withValues(alpha: 0.55));
  c.drawRRect(
    RRect.fromRectAndRadius(head, Radius.circular(h * 0.05)),
    fill(lit ? const Color(0xFFFFE9A8) : const Color(0xFF8A7A6A)),
  );
  c.drawRect(
    Rect.fromCenter(center: head.topCenter, width: h * 0.26, height: h * 0.04),
    fill(const Color(0xFF3B2A2A)),
  );
}

/// Wiederkehrende, deterministische Teilchen (Position aus Zeit) – für Ambient-Ebenen.
class Drifters {
  Drifters(int n, int seed) : x = [], y = [], sp = [], ph = [], sz = [] {
    final r = Rng(seed);
    for (var i = 0; i < n; i++) {
      x.add(r.next());
      y.add(r.next());
      sp.add(r.range(0.4, 1.0));
      ph.add(r.range(0, 6.28));
      sz.add(r.range(0.5, 1.0));
    }
  }
  final List<double> x, y, sp, ph, sz;
  int get n => x.length;
}
