import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/painters/character_painter.dart';

/// Rendert alle Figuren in ein PNG (Sichtprüfung). Schreibt nach build/sheets.
void main() {
  test('Figurenblatt rendern', () async {
    const cols = 8;
    const cell = 200.0;
    final rows = (characters.length / cols).ceil();
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cols * cell, rows * cell),
      Paint()..color = const Color(0xFFCDEBFF),
    );
    for (var i = 0; i < characters.length; i++) {
      canvas.save();
      canvas.translate((i % cols) * cell, (i ~/ cols) * cell);
      canvas.clipRect(const Rect.fromLTWH(0, 0, cell, cell));
      final mood = [Mood.idle, Mood.active, Mood.happy, Mood.sleepy][i % 4];
      CharacterPainter(
        characters[i],
        t: 1.3,
        mood: mood,
      ).paint(canvas, const Size(cell, cell));
      canvas.restore();
    }
    final img = await rec.endRecording().toImage(
      (cols * cell).toInt(),
      (rows * cell).toInt(),
    );
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!;
    Directory('build/sheets').createSync(recursive: true);
    File('build/sheets/characters.png')
        .writeAsBytesSync(bytes.buffer.asUint8List());
    expect(characters.length, greaterThanOrEqualTo(40));
  });
}
