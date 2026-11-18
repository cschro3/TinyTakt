import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art_kit.dart';
import '../rig.dart';

double _sstep(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Verformung des echten Mira-Bildes per Mesh (keine neu gezeichneten Formen).
/// Alle Koordinaten sind normiert auf das freigestellte Bild (u,v ∈ [0,1]).
///
/// Aus einem einzelnen Standbild entstehen so weiche Zweitbewegungen: Atmen, Kopfneigen,
/// Ohrenwackeln, Schweifschwung, Antennenwippen. Für echte Zustandswechsel (Blinzeln,
/// Laufzyklus, Jubelpose) werden zusätzliche Bildebenen gebraucht – siehe
/// `docs/art/ASSET_ANFORDERUNG_RUNDE2.md`.
class MiraMesh {
  static const cols = MiraMeshData.cols;
  static const rows = MiraMeshData.rows;

  // Drehpunkte und Einflusszonen (aus dem Konzeptbild abgelesen)
  static const _neck = Offset(0.527, 0.58);
  static const _earLPivot = Offset(0.29, 0.43);
  static const _earRPivot = Offset(0.755, 0.43);
  static const _earLCenter = Offset(0.15, 0.41);
  static const _earRCenter = Offset(0.87, 0.41);
  static const _tailPivot = Offset(0.77, 0.86);
  static const _tailCenter = Offset(0.88, 0.80);
  static const _antLRoot = Offset(0.43, 0.19);
  static const _antRRoot = Offset(0.61, 0.15);

  static const double feetV = 0.985; // Standlinie der Pfoten im Bild

  static Offset _rot(Offset p, Offset pivot, double a) {
    final c = math.cos(a), s = math.sin(a);
    final d = p - pivot;
    return Offset(
      pivot.dx + d.dx * c - d.dy * s,
      pivot.dy + d.dx * s + d.dy * c,
    );
  }

  static double _ellipseW(Offset p, Offset c, double rx, double ry) {
    final dx = (p.dx - c.dx) / rx, dy = (p.dy - c.dy) / ry;
    final d = math.sqrt(dx * dx + dy * dy);
    return 1 - _sstep(0.7, 1.2, d);
  }

  /// Verformte Position eines Bildpunkts (u,v) in Bild-Einheiten.
  static Offset deform(Offset p, Pose pose, double t, {bool calm = false}) {
    var d = Offset.zero;
    void add(Offset pivot, double angle, double w) {
      if (w <= 0 || angle == 0) return;
      d += _rot(p, pivot, angle * w) - p;
    }

    // Kopf mit Ohren neigt sich um den Hals
    add(_neck, pose.headTilt, 1 - _sstep(0.5, 0.66, p.dy));
    // Ohren wackeln (links/rechts entgegengesetzt, damit sie nach außen schlagen)
    add(_earLPivot, pose.earL * 0.9, _ellipseW(p, _earLCenter, 0.17, 0.28));
    add(_earRPivot, -pose.earR * 0.9, _ellipseW(p, _earRCenter, 0.17, 0.28));
    // Schweif schwingt
    add(_tailPivot, pose.tail * 0.16, _ellipseW(p, _tailCenter, 0.16, 0.24));
    // Antennen wippen mit eigener Phase (nur im bewegten Modus)
    if (!calm) {
      final top = 1 - _sstep(0.06, 0.24, p.dy);
      if (p.dx < 0.52) {
        add(
          _antLRoot,
          math.sin(t * 2.7) * 0.09,
          top * (1 - _sstep(0.42, 0.52, p.dx)),
        );
      } else {
        add(
          _antRRoot,
          math.sin(t * 2.3 + 1.4) * 0.09,
          top * _sstep(0.52, 0.62, p.dx),
        );
      }
    }
    var q = p + d;
    // Atmen: leichtes Dehnen des Oberkörpers um die Standlinie
    final b = pose.breath;
    q = Offset(
      0.5 + (q.dx - 0.5) * (1 + 0.006 * b * _sstep(0.45, 0.8, q.dy)),
      feetV + (q.dy - feetV) * (1 + 0.013 * b),
    );
    return q;
  }

  /// Zeichnet Mira: Füße bei [feet], Bildhöhe [height] in Pixeln.
  static void paint(
    Canvas canvas,
    MiraMeshData data,
    Offset feet,
    double height,
    Pose pose,
    double t, {
    bool calm = false,
    double lean = 0,
  }) {
    final verts = ui.Vertices.raw(
      ui.VertexMode.triangles,
      MiraFastMesh.fill(data, feet, height, pose, t, calm: calm, lean: lean),
      textureCoordinates: data.tex,
      indices: data.indices,
    );
    canvas.drawVertices(verts, BlendMode.srcOver, data.paint);
    verts.dispose();
  }

  static ui.Shader? _shadowShader;

  /// Weicher Bodenschatten (Verlaufs-Oval statt Blur-Filter); schrumpft beim Hüpfen.
  static void shadow(Canvas canvas, Offset feet, double width, double hopFrac) {
    final k = 1 - hopFrac.clamp(0.0, 1.0) * 0.35;
    final sh = _shadowShader ??= ui.Gradient.radial(
      Offset.zero,
      1,
      const [Color(0x8A102008), Color(0x4A102008), Color(0x00102008)],
      const [0, 0.55, 1],
    );
    canvas.save();
    canvas.translate(feet.dx, feet.dy + width * 0.015);
    canvas.scale(width * 0.36 * k, width * 0.08 * k);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = sh
        ..color = Color.fromRGBO(255, 255, 255, 0.9 * k),
    );
    canvas.restore();
  }

  /// Freudenfunken um Mira.
  static void sparkles(
    Canvas canvas,
    Offset center,
    double radius,
    double amount,
    double t,
  ) {
    if (amount < 0.05) return;
    for (var i = 0; i < 9; i++) {
      final a = i * 0.7 + t * 0.9;
      final r = radius * (0.75 + 0.25 * math.sin(t * 2 + i));
      final p = center + Offset(math.cos(a) * r * 1.1, math.sin(a) * r * 0.8);
      final f = (math.sin(t * 5 + i * 1.7) * 0.5 + 0.5) * amount;
      sparkleStar(
        canvas,
        p,
        radius * 0.07 * (0.5 + f),
        const Color(0xFFFFF0A0),
      );
    }
  }
}

/// Netz-Daten zu einem Mira-Bild: Texturkoordinaten, nur aktive Zellen (keine Dreiecke über
/// vollständig transparenten Flächen), wiederverwendeter Positionspuffer.
class MiraMeshData {
  static const cols = 24;
  static const rows = 24;
  static const vertexCount = (cols + 1) * (rows + 1);

  MiraMeshData(this.image, {Uint8List? rgba}) {
    tex = Float32List(vertexCount * 2);
    for (var j = 0; j <= rows; j++) {
      for (var i = 0; i <= cols; i++) {
        final k = (j * (cols + 1) + i) * 2;
        tex[k] = image.width * i / cols;
        tex[k + 1] = image.height * j / rows;
      }
    }
    final active = List<bool>.filled(cols * rows, true);
    if (rgba != null) {
      for (var cy = 0; cy < rows; cy++) {
        for (var cx = 0; cx < cols; cx++) {
          final x0 = cx * image.width ~/ cols,
              x1 = (cx + 1) * image.width ~/ cols;
          final y0 = cy * image.height ~/ rows,
              y1 = (cy + 1) * image.height ~/ rows;
          var any = false;
          // jedes Pixel prüfen (auch feine Härchen); ein Pixel Rand wegen der Filterung
          for (
            var y = math.max(y0 - 1, 0);
            y < math.min(y1 + 1, image.height) && !any;
            y++
          ) {
            for (
              var x = math.max(x0 - 1, 0);
              x < math.min(x1 + 1, image.width);
              x++
            ) {
              if (rgba[(y * image.width + x) * 4 + 3] > 0) {
                any = true;
                break;
              }
            }
          }
          active[cy * cols + cx] = any;
        }
      }
    }
    final idx = <int>[];
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        if (!active[j * cols + i]) continue;
        final a = j * (cols + 1) + i, b = a + 1, c = a + cols + 1, d = c + 1;
        idx.addAll([a, b, c, b, d, c]);
      }
    }
    indices = Uint16List.fromList(idx);
    paint = Paint()
      ..shader = ui.ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
        filterQuality: FilterQuality.low,
      );
  }

  final ui.Image image;
  late final Float32List tex;
  late final Uint16List indices;
  late final Paint paint;
  final Float32List pos = Float32List(vertexCount * 2);

  /// Anteil gezeichneter Dreiecke gegenüber dem vollen Gitter.
  double get activeShare => indices.length / (cols * rows * 6);
}

/// Schnelle Verformung: Einfluss-Gewichte je Vertex einmal berechnet, je Bild nur noch
/// Multiplikationen (Kleinwinkel-Näherung statt sin/cos je Vertex; Abweichung < 0,002 Bildbreiten).
class MiraFastMesh {
  static late final Float32List _u, _v;
  static late final Float32List _wHead,
      _wEarL,
      _wEarR,
      _wTail,
      _wAntL,
      _wAntR,
      _wBreath;
  static bool _ready = false;

  static void _init() {
    if (_ready) return;
    const n = MiraMeshData.vertexCount;
    _u = Float32List(n);
    _v = Float32List(n);
    _wHead = Float32List(n);
    _wEarL = Float32List(n);
    _wEarR = Float32List(n);
    _wTail = Float32List(n);
    _wAntL = Float32List(n);
    _wAntR = Float32List(n);
    _wBreath = Float32List(n);
    for (var j = 0; j <= MiraMeshData.rows; j++) {
      for (var i = 0; i <= MiraMeshData.cols; i++) {
        final k = j * (MiraMeshData.cols + 1) + i;
        final u = i / MiraMeshData.cols, v = j / MiraMeshData.rows;
        _u[k] = u;
        _v[k] = v;
        final p = Offset(u, v);
        _wHead[k] = 1 - _sstep(0.5, 0.66, v);
        _wEarL[k] = MiraMesh._ellipseW(p, MiraMesh._earLCenter, 0.17, 0.28);
        _wEarR[k] = MiraMesh._ellipseW(p, MiraMesh._earRCenter, 0.17, 0.28);
        _wTail[k] = MiraMesh._ellipseW(p, MiraMesh._tailCenter, 0.16, 0.24);
        final top = 1 - _sstep(0.06, 0.24, v);
        _wAntL[k] = u < 0.52 ? top * (1 - _sstep(0.42, 0.52, u)) : 0;
        _wAntR[k] = u >= 0.52 ? top * _sstep(0.52, 0.62, u) : 0;
        _wBreath[k] = _sstep(0.45, 0.8, v);
      }
    }
    _ready = true;
  }

  static double _dx = 0, _dy = 0;

  static void _acc(double u, double v, Offset pivot, double a) {
    final s = a - a * a * a / 6;
    final c1 = -a * a / 2 + a * a * a * a / 24; // cos(a) - 1
    final rx = u - pivot.dx, ry = v - pivot.dy;
    _dx += c1 * rx - s * ry;
    _dy += s * rx + c1 * ry;
  }

  /// Füllt [MiraMeshData.pos] mit Bildschirmkoordinaten und gibt ihn zurück.
  static Float32List fill(
    MiraMeshData data,
    Offset feet,
    double height,
    Pose pose,
    double t, {
    bool calm = false,
    double lean = 0,
  }) {
    _init();
    final pos = data.pos;
    final width = height * data.image.width / data.image.height;
    final ht = pose.headTilt,
        el = pose.earL * 0.9,
        er = -pose.earR * 0.9,
        tl = pose.tail * 0.16;
    final antL = calm ? 0.0 : math.sin(t * 2.7) * 0.09;
    final antR = calm ? 0.0 : math.sin(t * 2.3 + 1.4) * 0.09;
    final b = pose.breath;
    final bx = 0.006 * b, by = 1 + 0.013 * b;
    final sx = 1 + pose.squash * 0.10, sy = 1 - pose.squash * 0.12;
    final ang = lean + pose.lean;
    final cl = math.cos(ang), sl = math.sin(ang);
    final hop = pose.bodyDy * 0.5 * height;
    const feetV = MiraMesh.feetV;
    for (var k = 0; k < MiraMeshData.vertexCount; k++) {
      final u = _u[k], v = _v[k];
      _dx = 0;
      _dy = 0;
      var w = _wHead[k];
      if (w > 0 && ht != 0) _acc(u, v, MiraMesh._neck, ht * w);
      w = _wEarL[k];
      if (w > 0 && el != 0) _acc(u, v, MiraMesh._earLPivot, el * w);
      w = _wEarR[k];
      if (w > 0 && er != 0) _acc(u, v, MiraMesh._earRPivot, er * w);
      w = _wTail[k];
      if (w > 0 && tl != 0) _acc(u, v, MiraMesh._tailPivot, tl * w);
      w = _wAntL[k];
      if (w > 0 && antL != 0) _acc(u, v, MiraMesh._antLRoot, antL * w);
      w = _wAntR[k];
      if (w > 0 && antR != 0) _acc(u, v, MiraMesh._antRRoot, antR * w);
      var qx = u + _dx, qy = v + _dy;
      qx = 0.5 + (qx - 0.5) * (1 + bx * _wBreath[k]);
      qy = feetV + (qy - feetV) * by;
      final x = (qx - 0.5) * width * sx;
      final y = (qy - feetV) * height * sy;
      pos[k * 2] = feet.dx + x * cl - y * sl;
      pos[k * 2 + 1] = feet.dy + x * sl + y * cl + hop;
    }
    return pos;
  }
}
