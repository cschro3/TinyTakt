import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/painters/scene_painter.dart';

/// Rendert Welten im Hochformat (Umgebungsvariable WORLD_IDS, Komma-getrennt).
void main() {
  test('Welten rendern', () async {
    final ids = (Platform.environment['WORLD_IDS'] ?? 'meadow').split(',');
    const w = 390.0, h = 780.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    for (var i = 0; i < ids.length; i++) {
      c.save();
      c.translate(i * w, 0);
      c.clipRect(const Rect.fromLTWH(0, 0, w, h));
      ScenePainter(backgroundById(ids[i]), t: 4.0).paint(c, const Size(w, h));
      c.restore();
    }
    final img = await rec.endRecording().toImage(
      (w * ids.length).toInt(),
      h.toInt(),
    );
    File('build/sheets/worlds.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(
        (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
  });
}
