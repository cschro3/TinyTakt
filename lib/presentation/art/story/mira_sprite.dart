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
  static const cols = 28;
  static const rows = 28;

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

  static Uint16List? _idx;
  static Uint16List get indices => _idx ??= () {
    final idx = Uint16List(cols * rows * 6);
    var n = 0;
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final a = j * (cols + 1) + i, b = a + 1, c = a + cols + 1, d = c + 1;
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
    ui.Image image,
    Offset feet,
    double height,
    Pose pose,
    double t, {
    bool calm = false,
    double lean = 0,
  }) {
    final aspect = image.width / image.height;
    final w = height * aspect;
    final nx = cols + 1, ny = rows + 1;
    final pos = Float32List(nx * ny * 2);
    final tex = Float32List(nx * ny * 2);
    // Hüpfen/Stauchen der ganzen Figur
    final hop =
        -pose.bodyDy * 0.5 * height; // bodyDy ist negativ beim Hochspringen
    final sq = pose.squash;
    final sx = 1 + sq * 0.10, sy = 1 - sq * 0.12;
    final cl = math.cos(lean + pose.lean), sl = math.sin(lean + pose.lean);
    for (var j = 0; j < ny; j++) {
      for (var i = 0; i < nx; i++) {
        final u = i / cols, v = j / rows;
        final q = deform(Offset(u, v), pose, t, calm: calm);
        // lokale Pixel relativ zu den Füßen
        var x = (q.dx - 0.5) * w * sx;
        var y = (q.dy - feetV) * height * sy;
        final rx = x * cl - y * sl, ry = x * sl + y * cl;
        final k = (j * nx + i) * 2;
        pos[k] = feet.dx + rx;
        pos[k + 1] = feet.dy + ry + hop;
        tex[k] = u * image.width;
        tex[k + 1] = v * image.height;
      }
    }
    final verts = ui.Vertices.raw(
      ui.VertexMode.triangles,
      pos,
      textureCoordinates: tex,
      indices: indices,
    );
    canvas.drawVertices(
      verts,
      BlendMode.srcOver,
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

  /// Weicher Bodenschatten; schrumpft beim Hüpfen.
  static void shadow(Canvas canvas, Offset feet, double width, double hopFrac) {
    final k = 1 - hopFrac.clamp(0.0, 1.0) * 0.35;
    final r = Rect.fromCenter(
      center: feet.translate(0, width * 0.015),
      width: width * 0.62 * k,
      height: width * 0.13 * k,
    );
    canvas.drawOval(
      r,
      Paint()
        ..color = const Color(0x55102008).withValues(alpha: 0.33 * k)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.03),
    );
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
