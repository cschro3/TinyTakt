import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../domain/catalog.dart';
import '../../painters/scene_painter.dart';
import '../adventure/adventure_spec.dart';
import '../adventure/adventure_worlds.dart';
import '../story/art_images.dart';
import 'visual_registry.dart';

/// Gemeinsamer Welt-Renderer für Vorschaukarte, Startbildschirm und alle klassischen Timer-Stile.
/// Welten mit Bild-Asset (Blumenwiese) zeigen überall dasselbe Bild; die übrigen Welten nutzen
/// den dokumentierten prozeduralen Fallback ([ScenePainter]).
class WorldVisualPainter extends CustomPainter {
  WorldVisualPainter(
    this.bg, {
    this.t = 0,
    this.calm = false,
    this.focusY = 0.55,
    this.screen = false,
  });

  /// Vollbild (Startbildschirm): Weg-Feld wie in der Abenteuerszene; sonst Vorschaukarte.
  final bool screen;
  final BackgroundSpec bg;
  final double t;
  final bool calm;

  /// Welcher Höhenanteil des Bildes bei Beschnitt (cover) im Fokus bleibt (0 oben … 1 unten).
  final double focusY;

  /// Bild-Welt steht zum Zeichnen bereit?
  static bool bitmapReady(String id) =>
      VisualRegistry.world(id).renderer == WorldRenderer.bitmapStory &&
      ArtImages.instance.meadow != null;

  @override
  void paint(Canvas canvas, Size size) {
    if (bitmapReady(bg.id)) {
      _cover(canvas, size, ArtImages.instance.meadow!);
      return;
    }
    final spec = adventureWorlds[bg.id];
    if (spec != null) {
      final side = screen
          ? math.min(size.width, size.height * 0.55)
          : math.min(size.width, size.height);
      final bottom = screen ? size.height * 0.53 : size.height;
      final box = Rect.fromLTWH(
        (size.width - side) / 2,
        bottom - side,
        side,
        side,
      );
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      spec.paintBack(canvas, AdvFrame(size, box, spec.control));
      canvas.restore();
      return;
    }
    ScenePainter(bg, t: t, calm: calm).paint(canvas, size);
  }

  void _cover(Canvas canvas, Size size, ui.Image img) {
    final iw = img.width.toDouble(), ih = img.height.toDouble();
    final k = size.width / iw > size.height / ih
        ? size.width / iw
        : size.height / ih;
    final vw = size.width / k, vh = size.height / k;
    final left = ((iw - vw) / 2).clamp(0.0, double.infinity);
    final top = (((ih - vh) * focusY).clamp(
      -1e9,
      1e9,
    )).clamp(0.0, double.infinity);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(left, top, vw.clamp(0.0, iw), vh.clamp(0.0, ih)),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(WorldVisualPainter o) =>
      o.bg != bg ||
      o.t != t ||
      o.calm != calm ||
      o.focusY != focusY ||
      o.screen != screen;
}
