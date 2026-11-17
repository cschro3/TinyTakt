import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import 'meadow_path.dart';

double _sstep(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Abbildung Bild → Bildschirm. Breite = Bildschirmbreite; das Mittelband mit dem Weg
/// wird sanft senkrecht gestreckt, damit der Weg auf dem hohen Telefon-Format genug
/// Raum für Mira und den Fortschritt bekommt. Oben und unten ergänzen gespiegelte,
/// weichgezeichnete Streifen den Raum (kein Verzerren der Himmels- und Blumenzonen).
class StoryGeometry {
  StoryGeometry(this.size, {required double pathBottomY}) {
    s = size.width / MeadowPath.imageSize.width;
    final h = MeadowPath.imageSize.height.round();
    final cum = List<double>.filled(h + 1, 0);
    for (var y = 0; y < h; y++) {
      final bump =
          _sstep(400, 490, y.toDouble()) - _sstep(740, 850, y.toDouble());
      final low = 0.32 * _sstep(880, 960, y.toDouble());
      cum[y + 1] = cum[y] + s * (1 + (stretch - 1) * bump + low);
    }
    _cum = cum;
    final y790 = cum[790];
    top0 = math.max(0, pathBottomY - y790);
  }

  static const double stretch = 1.55;
  final Size size;
  late final double s;
  late final double top0;
  late final List<double> _cum;

  double ymap(double yImg) {
    final y = yImg.clamp(0.0, MeadowPath.imageSize.height);
    final i = y.floor();
    final f = y - i;
    final a = _cum[i];
    final b = i + 1 < _cum.length ? _cum[i + 1] : a;
    return top0 + a + (b - a) * f;
  }

  Offset toScreen(Offset img) => Offset(img.dx * s, ymap(img.dy));

  /// Bildschirm-Unterkante des Bildes.
  double get imageBottom => ymap(MeadowPath.imageSize.height);

  /// Maßstab für Figuren an Bildhöhe [yImg] (vorn 1, hinten ~0,48).
  double depthScale(double yImg) =>
      0.48 + 0.52 * ((yImg - 436) / (790 - 436)).clamp(0.0, 1.0);
}

/// Zeichnet die Wiese: Erweiterungsstreifen, Mesh-Bild mit Windwiegen und Lichteffekte.
class MeadowBackdropPainter extends CustomPainter {
  MeadowBackdropPainter({
    required this.image,
    required this.geo,
    required this.t,
    required this.calm,
  });
  final ui.Image image;
  final StoryGeometry geo;
  final double t;
  final bool calm;

  static const _cols = 24;
  static const _rows = 56;
  static Uint16List? _indices;
  static final Map<String, ui.Image> _extImages = {};

  /// Die weichgezeichneten Streifen sind statisch: einmal als Bild rendern (Blur-Layer
  /// würden sonst in jedem Bild neu gerastert). Fallback: Picture, falls nicht unterstützt.
  ui.Image? _extImage(String key, Size size) {
    final hit = _extImages[key];
    if (hit != null) return hit;
    try {
      final rec = ui.PictureRecorder();
      _extension(Canvas(rec), size);
      final pic = rec.endRecording();
      final img = pic.toImageSync(size.width.round(), size.height.round());
      pic.dispose();
      if (_extImages.length > 3) {
        final k = _extImages.keys.first;
        _extImages.remove(k)?.dispose();
      }
      return _extImages[key] = img;
    } catch (_) {
      return null;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = geo.s;
    // Himmelsfarbe als Grundton für die Streifen
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          const [Color(0xFF6FB8F2), Color(0xFF9BD2F5), Color(0xFF6FA83A)],
          const [0, 0.35, 1],
        ),
    );
    final key =
        'story.ext.${size.width.round()}x${size.height.round()}.${geo.top0.round()}';
    final ext = _extImage(key, size);
    if (ext != null) {
      canvas.drawImageRect(
        ext,
        Rect.fromLTWH(0, 0, ext.width.toDouble(), ext.height.toDouble()),
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.low,
      );
    } else {
      canvas.drawPicture(PictureCache.get(key, (c) => _extension(c, size)));
    }
    _drawMesh(canvas, size);
    if (!calm) _fx(canvas, size, s);
    final bt = geo.imageBottom;
    if (bt < size.height) {
      canvas.drawRect(
        Rect.fromLTWH(0, bt - 30, size.width, size.height - bt + 30),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, bt - 30),
            Offset(0, size.height),
            const [Color(0x00205A22), Color(0x66205A22)],
          ),
      );
    }
    // sanfte Vignette gibt Tiefe und hält die Ränder ruhig
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          size.center(Offset.zero),
          size.longestSide * 0.78,
          const [Color(0x00000000), Color(0x2A1A1040)],
          const [0.6, 1],
        ),
    );
  }

  /// Erweiterungsstreifen oben/unten. Sie laufen **unter** die Fade-Zone des Mesh-Bildes weiter
  /// (weichgezeichnete Kopie des Bildrandes), damit der Übergang scharf → unscharf nahtlos ist.
  void _extension(Canvas c, Size size) {
    final s = geo.s;
    const f = 70.0; // Länge der Fade-Zone (siehe _drawMesh)
    final w = MeadowPath.imageSize.width;
    final h = MeadowPath.imageSize.height;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (geo.top0 > 1) {
      final zone = Rect.fromLTWH(0, 0, size.width, geo.top0 + f);
      final srcH = math.min(h * 0.4, math.max(geo.top0, f) / s);
      c.save();
      c.clipRect(zone);
      c.saveLayer(
        zone,
        Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      );
      // gespiegelt oberhalb der Naht
      c.save();
      c.translate(0, geo.top0);
      c.scale(1, -1);
      c.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, w, srcH),
        Rect.fromLTWH(0, 0, size.width, srcH * s),
        paint,
      );
      c.restore();
      // unverändert unterhalb der Naht (unter der Fade-Zone)
      c.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, w, f / s),
        Rect.fromLTWH(0, geo.top0, size.width, f),
        paint,
      );
      c.restore();
      c.restore();
    }
    final bottom = geo.imageBottom;
    if (bottom < size.height - 1) {
      final need = size.height - bottom + 4;
      final k = s * 1.32; // das Unterband ist im Mesh um 1,32 gestreckt
      final zone = Rect.fromLTWH(0, bottom - f, size.width, need + f);
      c.drawRect(
        Rect.fromLTWH(0, bottom - 2, size.width, need + 2),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, bottom),
            Offset(0, bottom + need),
            const [Color(0xFF5E9E34), Color(0xFF3F7F2C)],
          ),
      );
      c.save();
      c.clipRect(zone);
      c.saveLayer(
        zone,
        Paint()
          ..color = const Color(0xB3FFFFFF)
          ..imageFilter = ui.ImageFilter.blur(sigmaX: 11, sigmaY: 11),
      );
      final srcH = math.min(h * 0.5, need / k);
      c.save();
      c.translate(0, bottom);
      c.scale(1, -1);
      c.drawImageRect(
        image,
        Rect.fromLTWH(0, h - srcH, w, srcH),
        Rect.fromLTWH(0, -srcH * k, size.width, srcH * k),
        paint,
      );
      c.restore();
      c.drawImageRect(
        image,
        Rect.fromLTWH(0, h - f / k, w, f / k),
        Rect.fromLTWH(0, bottom - f, size.width, f),
        paint,
      );
      c.restore();
      c.restore();
    }
  }

  /// Mesh-Bild; obere/untere Ränder blenden per Vertex-Alpha aus (kein Offscreen-Layer),
  /// damit die weichgezeichneten Erweiterungsstreifen nahtlos anschließen.
  void _drawMesh(Canvas canvas, Size screen) {
    final s = geo.s;
    final w = MeadowPath.imageSize.width;
    final h = MeadowPath.imageSize.height;
    final nx = _cols + 1, ny = _rows + 1;
    final pos = Float32List(nx * ny * 2);
    final tex = Float32List(nx * ny * 2);
    final colors = Int32List(nx * ny);
    const fade = 70.0;
    final top0 = geo.top0, bottom0 = geo.imageBottom;
    final fadeTop = top0 > 1, fadeBottom = bottom0 < screen.height - 1;
    final amp = calm ? 0.0 : 3.0 * (s / 0.325);
    for (var j = 0; j < ny; j++) {
      final yi = h * j / _rows;
      final sy = geo.ymap(yi);
      final wgt = _sstep(700, h, yi);
      var alpha = 1.0;
      if (fadeTop)
        alpha = math.min(alpha, ((sy - top0) / fade).clamp(0.0, 1.0));
      if (fadeBottom)
        alpha = math.min(alpha, ((bottom0 - sy) / fade).clamp(0.0, 1.0));
      final argb = Color.fromRGBO(255, 255, 255, alpha).toARGB32();
      for (var i = 0; i < nx; i++) {
        final xi = w * i / _cols;
        final dx = amp * wgt * math.sin(t * 1.25 + yi * 0.018 + xi * 0.011);
        final k = (j * nx + i) * 2;
        pos[k] = xi * s + dx;
        pos[k + 1] = sy;
        tex[k] = xi;
        tex[k + 1] = yi;
        colors[j * nx + i] = argb;
      }
    }
    _indices ??= () {
      final idx = Uint16List(_cols * _rows * 6);
      var n = 0;
      for (var j = 0; j < _rows; j++) {
        for (var i = 0; i < _cols; i++) {
          final a = j * (_cols + 1) + i;
          final b = a + 1;
          final c = a + _cols + 1;
          final d = c + 1;
          idx
            ..[n++] = a
            ..[n++] = b
            ..[n++] = c
            ..[n++] = b
            ..[n++] = d
            ..[n++] = c;
        }
      }
      return idx;
    }();
    final verts = ui.Vertices.raw(
      ui.VertexMode.triangles,
      pos,
      textureCoordinates: tex,
      colors: colors,
      indices: _indices!,
    );
    canvas.drawVertices(
      verts,
      BlendMode.modulate,
      Paint()
        ..shader = ui.ImageShader(
          image,
          TileMode.clamp,
          TileMode.clamp,
          Matrix4.identity().storage,
          filterQuality: FilterQuality.medium,
        ),
    );
    verts.dispose();
  }

  void _fx(Canvas canvas, Size size, double s) {
    Offset p(double x, double y) => geo.toScreen(Offset(x, y));
    final plus = BlendMode.plus;
    // Sonnenstrahlen (aus dem Licht hinter dem Baum)
    final origin = p(190, 285);
    for (var i = 0; i < 7; i++) {
      final a = 0.25 + i * 0.17;
      final pulse = 0.65 + 0.35 * math.sin(t * 0.55 + i * 1.3);
      final len = size.height * 0.75;
      final tip = origin + Offset(math.cos(a), math.sin(a)) * len;
      final nrm = Offset(-math.sin(a), math.cos(a));
      final spread = 14.0 + i * 3.0;
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..lineTo(tip.dx + nrm.dx * spread * 3, tip.dy + nrm.dy * spread * 3)
        ..lineTo(tip.dx - nrm.dx * spread * 3, tip.dy - nrm.dy * spread * 3)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..blendMode = plus
          ..shader = ui.Gradient.linear(origin, tip, [
            const Color(0xFFFFF0B0).withValues(alpha: 0.16 * pulse),
            const Color(0x00FFF0B0),
          ]),
      );
    }
    void glowAt(Offset c, double r, Color col, double a) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..blendMode = plus
          ..shader = ui.Gradient.radial(c, r, [
            col.withValues(alpha: a),
            col.withValues(alpha: 0),
          ]),
      );
    }

    // Laterne und Fenster flackern warm
    final flick = 0.8 + 0.2 * math.sin(t * 3.1) * math.sin(t * 1.7 + 1);
    glowAt(p(190, 240), 60 * s, const Color(0xFFFFC857), 0.5 * flick);
    for (final w in [(985.0, 375.0), (1100.0, 380.0), (1030.0, 310.0)]) {
      final f = 0.85 + 0.15 * math.sin(t * 2.3 + w.$1);
      glowAt(p(w.$1, w.$2), 34 * s, const Color(0xFFFFD27A), 0.55 * f);
    }
    // Wasserfunkeln
    final rnd = Rng(11);
    for (var i = 0; i < 12; i++) {
      final bx = 1010 + rnd.next() * 189;
      final by = 740 + rnd.next() * 110;
      final ph = rnd.next() * 6;
      final a = math.sin(t * 2.4 + ph);
      if (a > 0.35)
        sparkleStar(canvas, p(bx, by), 5 * s * a + 1.5, Colors.white);
    }
    // Pollen und Glitzer treiben durchs Bild
    final r2 = Rng(5);
    for (var i = 0; i < 26; i++) {
      final bx = r2.next(),
          by = r2.range(0.18, 0.95),
          sp = r2.range(0.01, 0.03),
          ph = r2.next() * 6;
      final x =
          ((bx + t * sp + math.sin(t * 0.3 + ph) * 0.02) % 1.0) * size.width;
      final y =
          (by + math.sin(t * 0.55 + ph) * 0.02 - ((t * sp * 0.6) % 0.05)) *
          size.height;
      final a = 0.25 + 0.55 * math.sin(t * 1.4 + ph).abs();
      canvas.drawCircle(
        Offset(x, y),
        1.6 + r2.next() * 1.4,
        Paint()
          ..blendMode = plus
          ..color = const Color(0xFFFFF3B0).withValues(alpha: a * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }
  }

  @override
  bool shouldRepaint(MeadowBackdropPainter o) =>
      o.t != t || o.geo != geo || o.image != image || o.calm != calm;
}
