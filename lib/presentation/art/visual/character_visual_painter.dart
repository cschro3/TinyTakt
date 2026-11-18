import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/catalog.dart';
import '../../painters/character_painter.dart';
import '../figures/registry.dart';
import '../rig.dart';
import '../story/art_images.dart';
import '../story/mira_sprite.dart';
import 'visual_registry.dart';

/// Gemeinsamer Figuren-Renderer für ALLE Ansichten (Auswahlkarte, Startbildschirm, Timer-Bühne,
/// Avatar, Erfolg). Wählt anhand der [VisualRegistry] das Premium-Asset, sonst den dokumentierten
/// Vektor-Fallback. Eine Figur sieht dadurch überall gleich aus.
class CharacterVisualPainter extends CustomPainter {
  CharacterVisualPainter(
    this.spec, {
    this.t = 0,
    this.mood = Mood.idle,
    this.calm = false,
    this.shadow = true,
    this.emotion,
    this.emotionT = 0,
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
      o.shadow != shadow;
}
