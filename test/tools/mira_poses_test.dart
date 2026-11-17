import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/presentation/art/figures/registry.dart';
import 'package:tinytakt/presentation/art/rig.dart';
import 'package:tinytakt/presentation/art/story/art_images.dart';
import 'package:tinytakt/presentation/art/story/mira_sprite.dart';

import 'screenshot_support.dart';

/// Mira groß in mehreren Zuständen (Mesh-Verformung prüfen). Ausgabe: build/sheets/mira_poses.png
void main() {
  testWidgets('Mira Posen', (t) async {
    await t.runAsync(ArtImages.instance.ensureLoaded);
    final img = ArtImages.instance.mira!;
    final key = GlobalKey();
    t.view.physicalSize = const Size(2000, 520);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final cases = <(String, Emotion, double, double)>[
      ('ruhe', Emotion.calm, 0.0, 0),
      ('ohren', Emotion.calm, 3.4, 0),
      ('gruss', Emotion.greet, 5.1, 0.9),
      ('freude', Emotion.cheer, 1.0, 0.45),
      ('jubel', Emotion.celebrate, 2.2, 0.57),
      ('muede', Emotion.sleepy, 4.0, 1.0),
    ];
    final p = premiumFigures['nova_mira']!.personality;
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: CustomPaint(
            size: const Size(2000, 520),
            painter: _P(
              img,
              [for (final c in cases) computePose(p, c.$2, c.$3, c.$4)],
              [for (final c in cases) c.$3],
            ),
          ),
        ),
      ),
    );
    await savePng(t, key, 'build/sheets/mira_poses.png', pixelRatio: 1);
  });
}

class _P extends CustomPainter {
  _P(this.img, this.poses, this.ts);
  final ui.Image img;
  final List<Pose> poses;
  final List<double> ts;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF8FCB6A));
    final w = s.width / poses.length;
    for (var i = 0; i < poses.length; i++) {
      final feet = Offset(w * (i + 0.5), s.height - 40);
      MiraMesh.shadow(c, feet, 300, 0);
      MiraMesh.paint(c, img, feet, 400, poses[i], ts[i]);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
