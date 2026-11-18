import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../app/perf_flags.dart';
import '../../../app/perf_monitor.dart';
import '../art_kit.dart';
import 'meadow_path.dart';
import 'story_quality.dart';

double _sstep(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Abbildung Bild → Bildschirm. Breite = Bildschirmbreite; das Mittelband mit dem Weg
/// wird sanft senkrecht gestreckt, damit der Weg auf dem hohen Telefon-Format genug
/// Raum für Mira und den Fortschritt bekommt. Oben und unten ergänzen gespiegelte,
/// weichgezeichnete Streifen den Raum (kein Verzerren der Himmels- und Blumenzonen).
class StoryGeometry {
  StoryGeometry(this.size, {required this.pathBottomY}) {
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
    top0 = math.max(0, pathBottomY - cum[790]);
  }

  static const double stretch = 1.55;
  final Size size;
  final double pathBottomY;
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

  @override
  bool operator ==(Object other) =>
      other is StoryGeometry &&
      other.size == size &&
      (other.pathBottomY - pathBottomY).abs() < 0.5;

  @override
  int get hashCode => Object.hash(size, pathBottomY.round());
}

/// Netz über einen Bildbereich der Wiese (Positionen ändern sich nur durch den Wind).
class BackdropMesh {
  BackdropMesh({
    required this.geo,
    required this.screen,
    required this.src,
    required this.texScale,
    required this.yStart,
    required this.yEnd,
    required this.rows,
    required this.cols,
    this.topFadeFromY,
    this.topFadePx = 0,
  }) {
    final nx = cols + 1, ny = rows + 1;
    final n = nx * ny;
    _x = Float32List(n);
    _wgt = Float32List(n);
    _ph = Float32List(n);
    pos = Float32List(n * 2);
    tex = Float32List(n * 2);
    colors = Int32List(n);
    final w = MeadowPath.imageSize.width;
    final bottom0 = geo.imageBottom;
    final fadeBottom = bottom0 < screen.height - 1;
    final top0 = geo.top0;
    final sy0 = topFadeFromY == null ? top0 : geo.ymap(topFadeFromY!);
    for (var j = 0; j < ny; j++) {
      final yi = yStart + (yEnd - yStart) * j / rows;
      final sy = geo.ymap(yi);
      var alpha = 1.0;
      if (topFadePx > 0)
        alpha = math.min(alpha, ((sy - sy0) / topFadePx).clamp(0.0, 1.0));
      if (fadeBottom)
        alpha = math.min(alpha, ((bottom0 - sy) / 70).clamp(0.0, 1.0));
      final argb = Color.fromRGBO(255, 255, 255, alpha).toARGB32();
      final wg = _sstep(700, MeadowPath.imageSize.height, yi);
      for (var i = 0; i < nx; i++) {
        final xi = w * i / cols;
        final k = j * nx + i;
        _x[k] = xi * geo.s;
        _wgt[k] = wg;
        _ph[k] = yi * 0.018 + xi * 0.011;
        pos[k * 2 + 1] = sy;
        tex[k * 2] = xi * texScale;
        tex[k * 2 + 1] = yi * texScale;
        colors[k] = argb;
      }
    }
    final idx = Uint16List(cols * rows * 6);
    var q = 0;
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final a = j * nx + i, b = a + 1, c = a + nx, d = c + 1;
        idx
          ..[q++] = a
          ..[q++] = b
          ..[q++] = c
          ..[q++] = b
          ..[q++] = d
          ..[q++] = c;
      }
    }
    indices = idx;
    paint = Paint()
      ..shader = ui.ImageShader(
        src,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
        filterQuality: FilterQuality.low,
      );
  }

  final StoryGeometry geo;
  final Size screen;
  final ui.Image src;
  final double texScale, yStart, yEnd;
  final double? topFadeFromY;
  final double topFadePx;
  final int rows, cols;
  late final Float32List _x, _wgt, _ph, pos, tex;
  late final Int32List colors;
  late final Uint16List indices;
  late final Paint paint;

  /// Zeichnet das Netz; [amp] = Windausschlag in px (0 = Ruhelage).
  void draw(Canvas canvas, double t, double amp) {
    final n = _x.length;
    if (amp == 0) {
      for (var k = 0; k < n; k++) {
        pos[k * 2] = _x[k];
      }
    } else {
      final tt = t * 1.25;
      for (var k = 0; k < n; k++) {
        pos[k * 2] = _x[k] + amp * _wgt[k] * math.sin(tt + _ph[k]);
      }
    }
    final v = ui.Vertices.raw(
      ui.VertexMode.triangles,
      pos,
      textureCoordinates: tex,
      colors: colors,
      indices: indices,
    );
    canvas.drawVertices(v, BlendMode.modulate, paint);
    v.dispose();
  }
}

/// Gebackene (einmal gerenderte) Bilder der Wiese; Fallback auf Picture, falls nicht unterstützt.
class BackdropCache {
  static final Map<String, ui.Image> _images = {};
  static final Map<String, ui.Picture> _pictures = {};
  static double bakedMB = 0;

  static ui.Image? _bake(
    String key,
    Size size,
    double scale,
    void Function(Canvas) draw,
  ) {
    final hit = _images[key];
    if (hit != null) return hit;
    try {
      final sw = Stopwatch()..start();
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.scale(scale);
      draw(c);
      final pic = rec.endRecording();
      final img = pic.toImageSync(
        (size.width * scale).round(),
        (size.height * scale).round(),
      );
      pic.dispose();
      // je Art nur das aktuelle Bild behalten (Drehen/Größenänderung gibt den alten Speicher frei)
      final kind = key.split('|').first;
      for (final k
          in _images.keys.where((k) => k.startsWith('$kind|')).toList()) {
        _images.remove(k)?.dispose();
      }
      _images[key] = img;
      bakedMB = _images.values.fold<double>(
        0,
        (a, i) => a + i.width * i.height * 4 / 1048576,
      );
      PerfMonitor.instance.cost(
        'bake:${key.split('|').first}',
        sw.elapsedMicroseconds,
      );
      return img;
    } catch (_) {
      return null;
    }
  }

  /// Statische Wiese (Himmel, Streifen, Mesh, Tönung, Vignette) in Bildschirmauflösung.
  static ui.Image? staticImage(
    ui.Image src,
    double texScale,
    StoryGeometry geo,
    Size size,
    double scale,
  ) => _bake(
    'static|${size.width.round()}x${size.height.round()}|${geo.top0.round()}|${geo.imageBottom.round()}|${scale.toStringAsFixed(2)}|${identityHashCode(src)}',
    size,
    scale,
    (c) => paintStatic(c, src, texScale, geo, size),
  );

  static ui.Picture staticPicture(
    ui.Image src,
    double texScale,
    StoryGeometry geo,
    Size size,
  ) {
    final key =
        'staticpic|${size.width.round()}x${size.height.round()}|${geo.top0.round()}|${identityHashCode(src)}';
    return _pictures.putIfAbsent(key, () {
      final rec = ui.PictureRecorder();
      paintStatic(Canvas(rec), src, texScale, geo, size);
      return rec.endRecording();
    });
  }

  /// Sonnenstrahlen als **ein** Bild nur im Bereich, in dem sie sichtbar sind (halbe Auflösung).
  /// Früher: drei Vollbild-Ebenen – der größte Einzelposten der Bildzeit (siehe docs/PERFORMANCE.md).
  static ui.Image? raysImage(StoryGeometry geo, Size size) {
    final r = raysRect(geo, size);
    if (r.isEmpty) return null;
    return _bake(
      'rays|${size.width.round()}x${size.height.round()}|${geo.top0.round()}|${r.left.round()},${r.top.round()},${r.width.round()},${r.height.round()}',
      Size(r.width, r.height),
      0.5,
      (c) {
        c.translate(-r.left, -r.top);
        paintRays(c, geo, size);
      },
    );
  }
}

/// Alles Statische der Wiese: Grundton, Erweiterungsstreifen, Bild-Netz in Ruhelage, Tönung, Vignette.
void paintStatic(
  Canvas canvas,
  ui.Image src,
  double k,
  StoryGeometry geo,
  Size size,
) {
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
  if (!perfOff('ext')) _paintExtension(canvas, src, k, geo, size);
  BackdropMesh(
    geo: geo,
    screen: size,
    src: src,
    texScale: k,
    yStart: 0,
    yEnd: MeadowPath.imageSize.height,
    rows: 56,
    cols: 24,
    topFadeFromY: 0,
    topFadePx: geo.top0 > 1 ? 70 : 0,
  ).draw(canvas, 0, 0);
  if (perfOff('vignette')) return;
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

/// Erweiterungsstreifen oben/unten. Sie laufen **unter** die Fade-Zone des Netzes weiter
/// (weichgezeichnete Kopie des Bildrandes), damit der Übergang scharf → unscharf nahtlos ist.
void _paintExtension(
  Canvas c,
  ui.Image src,
  double k,
  StoryGeometry geo,
  Size size,
) {
  final s = geo.s;
  const f = 70.0;
  final w = MeadowPath.imageSize.width;
  final h = MeadowPath.imageSize.height;
  final paint = Paint()..filterQuality = FilterQuality.medium;
  Rect srcRect(double x, double y, double ww, double hh) =>
      Rect.fromLTWH(x * k, y * k, ww * k, hh * k);
  if (geo.top0 > 1) {
    final zone = Rect.fromLTWH(0, 0, size.width, geo.top0 + f);
    final srcH = math.min(h * 0.4, math.max(geo.top0, f) / s);
    c.save();
    c.clipRect(zone);
    c.saveLayer(
      zone,
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
    );
    c.save();
    c.translate(0, geo.top0);
    c.scale(1, -1);
    c.drawImageRect(
      src,
      srcRect(0, 0, w, srcH),
      Rect.fromLTWH(0, 0, size.width, srcH * s),
      paint,
    );
    c.restore();
    c.drawImageRect(
      src,
      srcRect(0, 0, w, f / s),
      Rect.fromLTWH(0, geo.top0, size.width, f),
      paint,
    );
    c.restore();
    c.restore();
  }
  final bottom = geo.imageBottom;
  if (bottom < size.height - 1) {
    final need = size.height - bottom + 4;
    final kk = s * 1.32; // das Unterband ist im Netz um 1,32 gestreckt
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
    final srcH = math.min(h * 0.5, need / kk);
    c.save();
    c.translate(0, bottom);
    c.scale(1, -1);
    c.drawImageRect(
      src,
      srcRect(0, h - srcH, w, srcH),
      Rect.fromLTWH(0, -srcH * kk, size.width, srcH * kk),
      paint,
    );
    c.restore();
    c.drawImageRect(
      src,
      srcRect(0, h - f / kk, w, f / kk),
      Rect.fromLTWH(0, bottom - f, size.width, f),
      paint,
    );
    c.restore();
    c.restore();
  }
}

const _rayOrigin = Offset(
  190,
  285,
); // Lichtquelle hinter dem Baum (Bildkoordinaten)

/// Ausdehnung der Strahlen auf dem Bildschirm (bis 85 % der Länge, danach unsichtbar).
Rect raysRect(StoryGeometry geo, Size size) {
  final origin = geo.toScreen(_rayOrigin);
  var r = Rect.fromPoints(origin, origin);
  for (var i = 0; i < 7; i++) {
    final a = 0.25 + i * 0.17;
    final len = size.height * 0.75 * 0.85;
    final tip = origin + Offset(math.cos(a), math.sin(a)) * len;
    final nrm = Offset(-math.sin(a), math.cos(a));
    final spread = (14.0 + i * 3.0) * 3 * 0.85;
    r = r.expandToInclude(
      Rect.fromPoints(tip + nrm * spread, tip - nrm * spread),
    );
  }
  return r.inflate(4).intersect(Offset.zero & size);
}

/// Alle sieben Strahlen bei voller Stärke.
void paintRays(Canvas canvas, StoryGeometry geo, Size size) {
  final origin = geo.toScreen(_rayOrigin);
  for (var i = 0; i < 7; i++) {
    final a = 0.25 + i * 0.17;
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
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.linear(origin, tip, const [
          Color(0x29FFF0B0),
          Color(0x00FFF0B0),
        ]),
    );
  }
}

/// Dynamischer Teil der Wiese: Wind (kleines Netz unten), Strahlen, Glühen, Funkeln, Pollen.
class MeadowAmbient {
  MeadowAmbient({
    required this.geo,
    required this.size,
    required this.src,
    required this.texScale,
  }) {
    wind = BackdropMesh(
      geo: geo,
      screen: size,
      src: src,
      texScale: texScale,
      yStart: 700,
      yEnd: MeadowPath.imageSize.height,
      rows: 14,
      cols: 18,
      topFadeFromY: 700,
      topFadePx: 24,
    );
    final r = Rng(5);
    for (var i = 0; i < _n; i++) {
      _bx[i] = r.next();
      _by[i] = r.range(0.18, 0.95);
      _sp[i] = r.range(0.01, 0.03);
      _ph[i] = r.next() * 6;
      _sz[i] = r.next();
    }
    final w = Rng(11);
    for (var i = 0; i < 12; i++) {
      _wx[i] = 1010 + w.next() * 189;
      _wy[i] = 740 + w.next() * 110;
      _wp[i] = w.next() * 6;
    }
  }

  final StoryGeometry geo;
  final Size size;
  final ui.Image src;
  final double texScale;
  late final BackdropMesh wind;
  ui.Image? _rays;
  bool _raysTried = false;
  late final Rect _raysRect = raysRect(geo, size);

  static const _n = 26;
  final _bx = Float64List(_n),
      _by = Float64List(_n),
      _sp = Float64List(_n),
      _ph = Float64List(_n),
      _sz = Float64List(_n);
  final _wx = Float64List(12), _wy = Float64List(12), _wp = Float64List(12);
  static final Map<int, ui.Shader> _glowShaders = {};

  /// Weiches additives Glühen (Verlaufs-Shader je Größe/Farbe gecacht, Stärke über Paint-Alpha).
  static void paintGlow(
    Canvas canvas,
    Offset c,
    double r,
    Color col,
    double a,
  ) {
    final key = Object.hash(r.round(), col.toARGB32());
    final sh = _glowShaders.putIfAbsent(
      key,
      () => ui.Gradient.radial(Offset.zero, r, [
        col.withValues(alpha: 1),
        col.withValues(alpha: 0),
      ]),
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = sh
        ..color = Color.fromRGBO(255, 255, 255, a.clamp(0.0, 1.0)),
    );
    canvas.restore();
  }

  void paint(
    Canvas canvas,
    double t, {
    required StoryTier tier,
    required bool calm,
  }) {
    if (calm) return; // ruhiger Modus: statische Wiese
    final s = geo.s;
    Offset p(double x, double y) => geo.toScreen(Offset(x, y));
    // Wind: nur das kleine Netz im Vordergrund bewegt sich
    if (StoryGovernor.wind(tier) && !perfOff('wind')) {
      wind.draw(canvas, t, 3.0 * (s / 0.325));
    }
    // Sonnenstrahlen: ein vorgebackenes Bild nur im sichtbaren Bereich, sanft pulsierend
    if (!perfOff('rays')) {
      if (!_raysTried) {
        _raysTried = true;
        _rays = BackdropCache.raysImage(geo, size);
      }
      final pulse = tier == StoryTier.minimal
          ? 0.8
          : (0.65 + 0.35 * math.sin(t * 0.55)) *
                (0.92 + 0.08 * math.sin(t * 1.7 + 1));
      final img = _rays;
      if (img != null) {
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          _raysRect,
          Paint()
            ..blendMode = BlendMode.plus
            ..filterQuality = FilterQuality.low
            ..color = Color.fromRGBO(255, 255, 255, pulse),
        );
      } else {
        canvas.saveLayer(
          _raysRect,
          Paint()..color = Color.fromRGBO(255, 255, 255, pulse),
        );
        paintRays(canvas, geo, size);
        canvas.restore();
      }
    }
    if (perfOff('fx')) return;
    // Laterne und Fenster flackern warm
    final flick = 0.8 + 0.2 * math.sin(t * 3.1) * math.sin(t * 1.7 + 1);
    paintGlow(
      canvas,
      p(190, 240),
      60 * s,
      const Color(0xFFFFC857),
      0.5 * flick,
    );
    const windows = [(985.0, 375.0), (1100.0, 380.0), (1030.0, 310.0)];
    for (final w in windows) {
      paintGlow(
        canvas,
        p(w.$1, w.$2),
        34 * s,
        const Color(0xFFFFD27A),
        0.55 * (0.85 + 0.15 * math.sin(t * 2.3 + w.$1)),
      );
    }
    // Wasserfunkeln
    for (var i = 0; i < 12; i++) {
      final a = math.sin(t * 2.4 + _wp[i]);
      if (a > 0.35)
        sparkleStar(canvas, p(_wx[i], _wy[i]), 5 * s * a + 1.5, Colors.white);
    }
    // Pollen und Glitzer: ein Zug je Helligkeitsstufe, kein Blur-Filter
    final count = math.min(_n, StoryGovernor.particles(tier));
    if (count > 0 && !perfOff('particles')) {
      final bins = [<double>[], <double>[], <double>[]];
      for (var i = 0; i < count; i++) {
        final x =
            ((_bx[i] + t * _sp[i] + math.sin(t * 0.3 + _ph[i]) * 0.02) % 1.0) *
            size.width;
        final y =
            (_by[i] +
                math.sin(t * 0.55 + _ph[i]) * 0.02 -
                ((t * _sp[i] * 0.6) % 0.05)) *
            size.height;
        final a = 0.25 + 0.55 * math.sin(t * 1.4 + _ph[i]).abs();
        bins[a < 0.45 ? 0 : (a < 0.65 ? 1 : 2)].addAll([x, y]);
      }
      const alphas = [0.3, 0.5, 0.7];
      for (var b = 0; b < 3; b++) {
        if (bins[b].isEmpty) continue;
        final pts = Float32List.fromList(bins[b]);
        canvas.drawRawPoints(
          ui.PointMode.points,
          pts,
          Paint()
            ..blendMode = BlendMode.plus
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 6.5
            ..color = const Color(0xFFFFF3B0)
                .withValues(alpha: alphas[b] * 0.28),
        );
        canvas.drawRawPoints(
          ui.PointMode.points,
          pts,
          Paint()
            ..blendMode = BlendMode.plus
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 3
            ..color = const Color(0xFFFFF3B0).withValues(alpha: alphas[b]),
        );
      }
    }
  }
}
