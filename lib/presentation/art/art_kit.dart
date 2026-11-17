import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Kunst-Toolkit für „Premium Animated Storybook“: organische Silhouetten,
/// Fell-Textur, Licht & Schatten. Alles zeichnet im Einheitsquadrat [-1, 1].
///
/// Aufwendige Teile (Fell, Unschärfe) werden einmal in eine [ui.Picture]
/// aufgenommen und danach nur noch abgespielt ([PictureCache]) – so bleibt das
/// Rendering auf Smartphones flüssig.

/// Deterministischer Zufall (gleiche Figur sieht immer gleich aus).
class Rng {
  Rng(int seed) : _s = (seed * 2654435761) & 0x7fffffff;
  int _s;
  double next() {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return _s / 0x7fffffff;
  }

  double range(double a, double b) => a + (b - a) * next();
}

/// Schattierung mit Farbtemperatur: Licht wärmer, Schatten kühler (wirkt malerischer als reines Aufhellen/Abdunkeln).
Color shade(Color c, double amount, {double hue = 0, double sat = 0}) {
  final h = HSLColor.fromColor(c);
  final warm = amount > 0
      ? -4.0
      : 6.0; // Licht Richtung gelb, Schatten Richtung blau/violett
  return h
      .withLightness((h.lightness + amount).clamp(0.0, 1.0))
      .withHue((h.hue + hue + warm * amount.abs() * 4) % 360)
      .withSaturation((h.saturation + sat).clamp(0.0, 1.0))
      .toColor();
}

/// Weicher Zwischenstand zweier Farben.
Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

/// Glatte, geschlossene Kurve durch Kontrollpunkte (Catmull-Rom → Bézier).
Path smoothClosed(List<Offset> pts, {double tension = 0.5}) {
  final n = pts.length;
  final path = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (var i = 0; i < n; i++) {
    final p0 = pts[(i - 1 + n) % n];
    final p1 = pts[i];
    final p2 = pts[(i + 1) % n];
    final p3 = pts[(i + 2) % n];
    final c1 = p1 + (p2 - p0) * (tension / 3);
    final c2 = p2 - (p3 - p1) * (tension / 3);
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path..close();
}

/// Offene glatte Kurve.
Path smoothOpen(List<Offset> pts, {double tension = 0.5}) {
  final n = pts.length;
  final path = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (var i = 0; i < n - 1; i++) {
    final p0 = pts[math.max(i - 1, 0)];
    final p1 = pts[i];
    final p2 = pts[i + 1];
    final p3 = pts[math.min(i + 2, n - 1)];
    final c1 = p1 + (p2 - p0) * (tension / 3);
    final c2 = p2 - (p3 - p1) * (tension / 3);
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path;
}

/// Ellipse als Path (für Clip und Füllungen).
Path ellipsePath(double cx, double cy, double rx, double ry) => Path()
  ..addOval(
    Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
  );

/// Cache für aufgenommene Bildteile (Einheitskoordinaten, daher auflösungsunabhängig).
class PictureCache {
  static final Map<String, ui.Picture> _m = {};
  static ui.Picture get(String key, void Function(Canvas c) draw) =>
      _m.putIfAbsent(key, () {
        final rec = ui.PictureRecorder();
        draw(Canvas(rec));
        return rec.endRecording();
      });

  static void clear() {
    for (final p in _m.values) {
      p.dispose();
    }
    _m.clear();
  }

  static int get size => _m.length;
}

/// Füllt [path] mit weich modelliertem Volumen:
/// Basisverlauf, Streiflicht oben links, kühler Innenschatten unten rechts, warmer Rückstrahl am Rand.
void fillVolume(
  Canvas c,
  Path path,
  Color base, {
  double light = 0.12,
  double shadow = 0.16,
  double edge = 0.05,
  Offset lightDir = const Offset(-0.35, -0.5),
}) {
  final b = path.getBounds();
  final r = math.max(b.width, b.height);
  c.drawPath(
    path,
    Paint()
      ..shader = ui.Gradient.radial(
        b.center +
            Offset(lightDir.dx * b.width * 0.5, lightDir.dy * b.height * 0.5),
        r * 0.95,
        [shade(base, light), base, shade(base, -shadow)],
        const [0, 0.55, 1],
      ),
  );
  c.save();
  c.clipPath(path);
  // Innenschatten: Kontur nach oben links verschoben und stark unscharf → dunkles Band unten rechts
  c.save();
  c.translate(lightDir.dx * -0.0 - 0.012 * r, -0.02 * r);
  c.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..color = shade(base, -shadow * 1.5, hue: 8).withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.07),
  );
  c.restore();
  // Rückstrahl (warmes Licht von unten) knapp am Rand
  c.save();
  c.translate(0.004 * r, 0.012 * r);
  c.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.03
      ..color = shade(base, edge * 2.4, hue: -6).withValues(alpha: 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.018),
  );
  c.restore();
  c.restore();
}

/// Streiflicht (weicher heller Fleck) innerhalb von [clip].
void softHighlight(
  Canvas c,
  Path clip,
  Offset center,
  double rx,
  double ry, {
  double alpha = 0.22,
  Color color = Colors.white,
  double rot = 0,
}) {
  c.save();
  c.clipPath(clip);
  c.translate(center.dx, center.dy);
  c.rotate(rot);
  c.drawOval(
    Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
    Paint()
      ..color = color.withValues(alpha: alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.min(rx, ry) * 0.55),
  );
  c.restore();
}

/// Weicher Kontaktschatten (z. B. Kinn auf Brust, Ohr am Kopf).
void softShadow(
  Canvas c,
  Path shape, {
  Offset offset = Offset.zero,
  double blur = 0.04,
  Color color = const Color(0x55203050),
  Path? clip,
}) {
  c.save();
  if (clip != null) c.clipPath(clip);
  c.translate(offset.dx, offset.dy);
  c.drawPath(
    shape,
    Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
  );
  c.restore();
}

/// Feine Fellstriche innerhalb von [clip]. [flow] liefert die Strichrichtung (Winkel) je Punkt.
void furTexture(
  Canvas c,
  Path clip, {
  required Color light,
  required Color dark,
  required double Function(Offset p) flow,
  int count = 260,
  double len = 0.075,
  double width = 0.008,
  int seed = 1,
  double alpha = 0.3,
}) {
  final b = clip.getBounds();
  final rnd = Rng(seed);
  c.save();
  c.clipPath(clip);
  final lp = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = width;
  var drawn = 0;
  var guard = 0;
  while (drawn < count && guard < count * 6) {
    guard++;
    final p = Offset(rnd.range(b.left, b.right), rnd.range(b.top, b.bottom));
    if (!clip.contains(p)) continue;
    final a = flow(p) + rnd.range(-0.35, 0.35);
    final l = len * rnd.range(0.6, 1.25);
    final q = p + Offset(math.cos(a), math.sin(a)) * l;
    final mid =
        (p + q) / 2 +
        Offset(-math.sin(a), math.cos(a)) * l * rnd.range(-0.18, 0.18);
    final isLight = rnd.next() > 0.45;
    lp.color = (isLight ? light : dark).withValues(
      alpha: alpha * rnd.range(0.45, 1.0),
    );
    lp.strokeWidth = width * rnd.range(0.7, 1.3);
    c.drawPath(
      Path()
        ..moveTo(p.dx, p.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, q.dx, q.dy),
      lp,
    );
    drawn++;
  }
  c.restore();
}

/// Fellbüschel entlang der Kontur: macht die Silhouette flauschig statt glatt.
/// [outward]: Länge der Büschel nach außen, [skip]: Ausschnitte (z. B. Hals) per Funktion.
void furFringe(
  Canvas c,
  Path outline, {
  required Color color,
  Color? tipColor,
  double spacing = 0.045,
  double outward = 0.055,
  double width = 0.05,
  int seed = 7,
  bool Function(Offset p)? skip,
  double jitter = 0.5,
}) {
  final rnd = Rng(seed);
  for (final m in outline.computeMetrics()) {
    var d = 0.0;
    while (d < m.length) {
      final t = m.getTangentForOffset(d);
      d += spacing * rnd.range(0.7, 1.3);
      if (t == null) continue;
      if (skip != null && skip(t.position)) continue;
      // Außen = Normale, die vom Pfadmittelpunkt wegzeigt
      final normal = Offset(t.vector.dy, -t.vector.dx);
      final center = outline.getBounds().center;
      final out =
          ((t.position - center).dx * normal.dx +
                  (t.position - center).dy * normal.dy) >=
              0
          ? normal
          : -normal;
      final len = outward * rnd.range(0.6, 1.3);
      final w = width * rnd.range(0.7, 1.2);
      final bend = t.vector * (rnd.range(-jitter, jitter) * len);
      final base = t.position;
      final tip = base + out * len + bend;
      final side = t.vector * (w / 2);
      final b0 = base - side;
      final b1 = base + side;
      final bulge = (w * 0.55);
      final nrm = out;
      final tuft = Path()
        ..moveTo(b0.dx, b0.dy)
        ..cubicTo(
          b0.dx + nrm.dx * len * 0.55 - side.dx * (bulge / w) * 0.9,
          b0.dy + nrm.dy * len * 0.55 - side.dy * (bulge / w) * 0.9,
          tip.dx - side.dx * 0.5 - nrm.dx * len * 0.12,
          tip.dy - side.dy * 0.5 - nrm.dy * len * 0.12,
          tip.dx,
          tip.dy,
        )
        ..cubicTo(
          tip.dx + side.dx * 0.5 - nrm.dx * len * 0.12,
          tip.dy + side.dy * 0.5 - nrm.dy * len * 0.12,
          b1.dx + nrm.dx * len * 0.55 + side.dx * (bulge / w) * 0.9,
          b1.dy + nrm.dy * len * 0.55 + side.dy * (bulge / w) * 0.9,
          b1.dx,
          b1.dy,
        )
        ..close();
      c.drawPath(tuft, Paint()..color = color);
      if (tipColor != null) {
        c.drawPath(
          tuft,
          Paint()..shader = ui.Gradient.linear(base, tip, [color, tipColor]),
        );
      }
    }
  }
}

/// Weiche Leuchte (Halo) – für Lumis Ohren, Miras Pfoten usw.
void glow(
  Canvas c,
  Offset center,
  double radius,
  Color color,
  double strength,
) {
  final rect = Rect.fromCircle(center: center, radius: radius);
  c.drawCircle(
    center,
    radius,
    Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          color.withValues(alpha: strength),
          color.withValues(alpha: strength * 0.35),
          color.withValues(alpha: 0),
        ],
        const [0, 0.45, 1],
      ),
  );
  assert(rect.isFinite);
}

/// Kleine glänzende Kugel (Augen-Glanzpunkt, Perlen).
void gloss(Canvas c, Offset p, double r, {double alpha = 0.95}) {
  c.drawCircle(p, r, Paint()..color = Colors.white.withValues(alpha: alpha));
}

double smoothstep(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// 0 → 1 → 0 über [dur] Sekunden ab [start] (z. B. kleine Hüpfer).
double pulse(double t, double start, double dur) {
  final x = (t - start) / dur;
  if (x < 0 || x > 1) return 0;
  return math.sin(x * math.pi);
}

/// Plüschiges Teil in einem Zug: Volumen, Fellstriche, flauschiger Rand.
void plush(
  Canvas c,
  Path shape,
  Color base, {
  Color? light,
  Color? dark,
  double lightAmt = 0.12,
  double shadowAmt = 0.18,
  double Function(Offset p)? flow,
  int fur = 260,
  double furLen = 0.08,
  int seed = 1,
  double fringe = 0.05,
  double fringeSpacing = 0.05,
  double fringeWidth = 0.06,
  Color? fringeColor,
  Color? fringeTip,
  bool Function(Offset p)? skipFringe,
  double furAlpha = 0.3,
}) {
  fillVolume(c, shape, base, light: lightAmt, shadow: shadowAmt);
  if (fur > 0) {
    final ctr = shape.getBounds().center;
    furTexture(
      c,
      shape,
      light: light ?? shade(base, 0.2),
      dark: dark ?? shade(base, -0.2),
      flow: flow ?? (p) => math.atan2(p.dy - ctr.dy, p.dx - ctr.dx),
      count: fur,
      len: furLen,
      seed: seed,
      alpha: furAlpha,
    );
  }
  if (fringe > 0) {
    furFringe(
      c,
      shape,
      color: fringeColor ?? mix(base, light ?? shade(base, 0.2), 0.12),
      tipColor: fringeTip ?? mix(base, light ?? shade(base, 0.2), 0.38),
      outward: fringe,
      spacing: fringeSpacing,
      width: fringeWidth,
      seed: seed + 1,
      skip: skipFringe,
    );
  }
}

/// Kleine Pfoten-Zehen als weiche Linien.
void toeLines(
  Canvas c,
  Offset center,
  double spread,
  Color color, {
  int n = 2,
  double len = 0.05,
}) {
  for (var i = 0; i < n; i++) {
    final x = center.dx + (i - (n - 1) / 2) * spread;
    c.drawLine(
      Offset(x, center.dy),
      Offset(x, center.dy + len),
      Paint()
        ..color = color
        ..strokeWidth = 0.008
        ..strokeCap = StrokeCap.round,
    );
  }
}

/// Vierzackiger Funkelstern (Glanz, Stirnzeichen).
void sparkleStar(Canvas c, Offset p, double r, Color col) {
  final path = Path();
  for (var i = 0; i < 8; i++) {
    final rad = i.isEven ? r : r * 0.28;
    final a = i * math.pi / 4 - math.pi / 2;
    final pt = p + Offset(math.cos(a) * rad, math.sin(a) * rad * 1.15);
    i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
  }
  c.drawPath(path..close(), Paint()..color = col.withValues(alpha: 0.95));
}

/// Gefiederschuppen: Reihen überlappender Halbbögen (Papagei).
void featherScales(
  Canvas c,
  Path clip, {
  required Color base,
  required Color edge,
  double size = 0.07,
  int seed = 1,
  double alpha = 0.55,
}) {
  final b = clip.getBounds();
  final rnd = Rng(seed);
  c.save();
  c.clipPath(clip);
  var row = 0;
  for (var y = b.top; y < b.bottom + size; y += size * 0.62) {
    final off = row.isEven ? 0.0 : size * 0.5;
    for (var x = b.left - size; x < b.right + size; x += size) {
      final p = Offset(x + off, y);
      final path = Path()
        ..moveTo(p.dx - size * 0.5, p.dy)
        ..quadraticBezierTo(p.dx, p.dy + size * 0.95, p.dx + size * 0.5, p.dy);
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.1
          ..color = edge.withValues(alpha: alpha * rnd.range(0.7, 1.0)),
      );
      c.drawPath(
        Path()
          ..moveTo(p.dx - size * 0.4, p.dy + size * 0.12)
          ..quadraticBezierTo(
            p.dx,
            p.dy + size * 0.5,
            p.dx + size * 0.4,
            p.dy + size * 0.12,
          ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.07
          ..color = base.withValues(alpha: 0.35),
      );
    }
    row++;
  }
  c.restore();
}
