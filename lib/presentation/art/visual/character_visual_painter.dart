import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/catalog.dart';
import '../../painters/character_painter.dart';
import '../adventure/adventure_gear.dart';
import '../figures/registry.dart';
import '../rig.dart';
import '../story/art_images.dart';
import '../story/mira_sprite.dart';
import 'visual_registry.dart';

/// Gemeinsamer Figuren-Renderer für ALLE Ansichten (Auswahlkarte, Startbildschirm, Timer-Bühne,
/// Avatar, Erfolg). Wählt anhand der [VisualRegistry] das Premium-Asset, sonst den dokumentierten
/// Vektor-Fallback. Eine Figur sieht dadurch überall gleich aus.
/// Verschiebung der vorderen Ausrüstung nach unten (Anteil der Figurenhöhe).
const double headOffset = 0.085;

class CharacterVisualPainter extends CustomPainter {
  CharacterVisualPainter(
    this.spec, {
    this.t = 0,
    this.mood = Mood.idle,
    this.calm = false,
    this.shadow = true,
    this.emotion,
    this.emotionT = 0,
    this.gearWorld,
  }) : _fallback = CharacterPainter(
         spec,
         t: t,
         mood: mood,
         calm: calm,
         shadow: shadow,
         emotion: emotion,
         emotionT: emotionT,
       );

  final CharacterSpec spec;
  final double t;
  final Mood mood;
  final bool calm;
  final bool shadow;
  final Emotion? emotion;
  final double emotionT;

  /// Welt-ID für die Abenteuer-Ausrüstung (null = keine). Sitzt nur auf Figuren mit Kopf.
  final String? gearWorld;
  final CharacterPainter _fallback;

  /// Bild-Figur steht zum Zeichnen bereit?
  static bool bitmapReady(String id) =>
      VisualRegistry.character(id).renderer == FigureRenderer.bitmapMesh &&
      ArtImages.instance.miraMesh != null;

  Emotion get _emotion =>
      emotion ??
      switch (mood) {
        Mood.sleepy => Emotion.sleepy,
        Mood.happy => Emotion.celebrate,
        _ => Emotion.calm,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final gear = gearWorld == null || !gearFits(spec)
        ? null
        : gearForWorld(gearWorld!);
    if (gear == null) {
      _paintFigure(canvas, size);
      return;
    }
    final side = math.min(size.width, size.height);
    final origin = Offset((size.width - side) / 2, (size.height - side) / 2);
    void layer(void Function(Canvas, double)? f, {double dy = 0}) {
      if (f == null) return;
      canvas.save();
      canvas.translate(origin.dx, origin.dy + dy * side);
      f(canvas, side);
      canvas.restore();
    }

    layer(gear.back);
    _paintFigure(canvas, size);
    // Kopfteile sitzen ~8,5 % tiefer als im Gear-Entwurf (Gesichtsmitte der Figuren)
    layer(gear.front, dy: headOffset);
  }

  void _paintFigure(Canvas canvas, Size size) {
    final visual = VisualRegistry.character(spec.id);
    if (visual.renderer != FigureRenderer.bitmapMesh) {
      _fallback.paint(canvas, size);
      return;
    }
    final mesh = ArtImages.instance.miraMesh;
    if (mesh == null) {
      // Bilder laden noch (oder Laden gescheitert): bei Fehlschlag Vektor-Fallback,
      // sonst bewusst leer – die Ansicht blendet die Figur ein, sobald sie bereit ist.
      if (ArtImages.instance.failed) _fallback.paint(canvas, size);
      return;
    }
    final side = math.min(size.width, size.height);
    final origin = Offset((size.width - side) / 2, (size.height - side) / 2);
    final h = side * 0.9;
    final feet = origin + Offset(side / 2, side * 0.95);
    final pose = computePose(
      premiumFigures[spec.id]!.personality,
      _emotion,
      t,
      emotionT,
      calm: calm,
    );
    if (shadow) MiraMesh.shadow(canvas, feet, h * 0.9, 0);
    MiraMesh.paint(canvas, mesh, feet, h, pose, t, calm: calm);
    if (!calm && mood == Mood.happy) {
      MiraMesh.sparkles(
        canvas,
        feet.translate(0, -h * 0.55),
        h * 0.55,
        pose.sparkle,
        t,
      );
    }
  }

  @override
  bool shouldRepaint(CharacterVisualPainter o) =>
      o.t != t ||
      o.mood != mood ||
      o.spec != spec ||
      o.calm != calm ||
      o.emotion != emotion ||
      o.emotionT != emotionT ||
      o.gearWorld != gearWorld ||
      o.shadow != shadow;
}
