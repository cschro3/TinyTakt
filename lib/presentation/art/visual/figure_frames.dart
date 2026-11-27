import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../domain/catalog.dart' show CharacterSpec;
import '../../painters/character_painter.dart' show Mood;
import 'character_visual_painter.dart';

/// Gebackene Animations-Frames für Vektor-Figuren (Leistung).
///
/// Eine Vektor-Figur live zu zeichnen kostet pro Bild viel (Fell, Verläufe). Sie bewegt sich im
/// Abenteuer aber nur leicht (Atmen, Wippen, Blinzeln) – deshalb werden je Figur und Stimmung
/// [frameCount] Frames einer [period]-Sekunden-Schleife einmal in Bilder gebacken (höchstens ein
/// Frame pro Aufruf) und danach nur noch als Bild gezeichnet. Weg, Hüpfen, Skalierung und Schatten
/// laufen weiterhin pro Bild live über Canvas-Transformationen.
///
/// Grenze: Es gibt nur die Stimmungen Ruhe/Aktiv/Freude/Müde (keine einmaligen Gesten wie
/// Begrüßung oder Ermutigung) – dokumentiert in docs/V4_BERICHT.md.
class FigureFrames {
  FigureFrames._();
  static final FigureFrames instance = FigureFrames._();

  static const frameCount = 10;
  static const period = 2.0;
  static const maxBytes = 28 * 1048576;

  final Map<String, List<ui.Image?>> _groups = {};
  final List<String> _lru = [];
  int _bytes = 0;
  int bakes = 0;

  void clear() {
    for (final g in _groups.values) {
      for (final i in g) {
        i?.dispose();
      }
    }
    _groups.clear();
    _lru.clear();
    _bytes = 0;
  }

  int get bytes => _bytes;
  int get groups => _groups.length;

  /// Zeichnet die Figur als gebackenes Bild in das Quadrat [rect]. Gibt false zurück, wenn noch
  /// gar kein Frame existiert und auch keiner gebacken werden konnte.
  bool paint(
    Canvas canvas,
    CharacterSpec spec,
    Rect rect, {
    required double t,
    required Mood mood,
    required bool calm,
    required double dpr,
    String? gearWorld,
  }) {
    final px = (((rect.width * dpr).clamp(96.0, 320.0)) / 32).ceil() * 32;
    final key =
        '${spec.id}|${mood.name}|${calm ? 'c' : 'a'}|$px|${gearWorld ?? ''}';
    final group = _groups.putIfAbsent(
      key,
      () => List<ui.Image?>.filled(calm ? 1 : frameCount, null),
    );
    _lru
      ..remove(key)
      ..add(key);
    final n = group.length;
    final idx = n == 1 ? 0 : (((t % period) / period) * n).floor() % n;
    var img = group[idx];
    if (img == null) {
      img = _bake(spec, mood, calm, px, idx, n, gearWorld);
      if (img != null) {
        group[idx] = img;
        _bytes += img.width * img.height * 4;
        _evict(key);
      } else {
        for (var k = 1; k < n && img == null; k++) {
          img = group[(idx + k) % n];
        }
      }
    }
    if (img == null) return false;
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      rect,
      Paint()..filterQuality = FilterQuality.medium,
    );
    return true;
  }

  ui.Image? _bake(
    CharacterSpec spec,
    Mood mood,
    bool calm,
    int px,
    int idx,
    int n,
    String? gearWorld,
  ) {
    try {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final k = px / 100.0;
      c.scale(k);
      CharacterVisualPainter(
        spec,
        t: calm ? 0 : idx / n * period,
        mood: mood,
        calm: calm,
        shadow: false,
        gearWorld: gearWorld,
      ).paint(c, const Size(100, 100));
      final pic = rec.endRecording();
      final img = pic.toImageSync(px, px);
      pic.dispose();
      bakes++;
      return img;
    } catch (_) {
      return null;
    }
  }

  void _evict(String keep) {
    while (_bytes > maxBytes && _lru.length > 1) {
      final victim = _lru.firstWhere((k) => k != keep, orElse: () => keep);
      if (victim == keep) break;
      _lru.remove(victim);
      final g = _groups.remove(victim);
      if (g == null) continue;
      for (final i in g) {
        if (i != null) {
          _bytes -= i.width * i.height * 4;
          i.dispose();
        }
      }
    }
  }
}
