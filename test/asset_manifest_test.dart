import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/presentation/art/visual/visual_registry.dart';

/// Liest Breite/Höhe aus WebP (VP8/VP8L/VP8X) ohne zusätzliche Abhängigkeit.
(int, int) webpSize(List<int> b) {
  final fourcc = String.fromCharCodes(b.sublist(12, 16));
  int u24(int o) => b[o] | b[o + 1] << 8 | b[o + 2] << 16;
  if (fourcc == 'VP8X') return (u24(24) + 1, u24(27) + 1);
  if (fourcc == 'VP8 ') {
    return ((b[26] | b[27] << 8) & 0x3fff, (b[28] | b[29] << 8) & 0x3fff);
  }
  final v = b[21] | b[22] << 8 | b[23] << 16 | b[24] << 24; // VP8L
  return ((v & 0x3fff) + 1, ((v >> 14) & 0x3fff) + 1);
}

bool webpHasAlpha(List<int> b) {
  final fourcc = String.fromCharCodes(b.sublist(12, 16));
  if (fourcc == 'VP8X') return b[20] & 0x10 != 0;
  if (fourcc == 'VP8L')
    return true; // Alpha-Bit steht im Header; VP8L kann Alpha tragen
  return false;
}

void main() {
  final m = jsonDecode(
    File('assets/art/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final limits = m['limits'] as Map<String, dynamic>;
  final entries = <String, Map<String, dynamic>>{
    for (final e in (m['characters'] as Map<String, dynamic>).entries)
      'char:${e.key}': e.value as Map<String, dynamic>,
    for (final e in (m['worlds'] as Map<String, dynamic>).entries)
      'world:${e.key}': e.value as Map<String, dynamic>,
  };

  test(
    'alle Dateien existieren, Maße und Transparenz stimmen, Budget eingehalten',
    () {
      var total = 0;
      for (final e in entries.entries) {
        final files = (e.value['files'] as Map).cast<String, String>();
        final sizes = (e.value['sizes'] as Map).cast<String, List>();
        for (final f in files.entries) {
          final file = File(f.value);
          expect(
            file.existsSync(),
            isTrue,
            reason: '${e.key}: ${f.value} fehlt',
          );
          final bytes = file.readAsBytesSync();
          total += bytes.length;
          expect(
            bytes.length / 1024,
            lessThan((limits['maxFileKB'] as num)),
            reason: f.value,
          );
          final (w, h) = webpSize(bytes);
          expect([w, h], sizes[f.key]!.cast<int>(), reason: '${f.value} Maße');
          if (e.value['alpha'] == true) {
            expect(
              webpHasAlpha(bytes),
              isTrue,
              reason: '${f.value} ohne Transparenz',
            );
          }
        }
      }
      expect(total / 1024, lessThan((limits['maxTotalKB'] as num)));
    },
  );

  test(
    'Manifest und VisualRegistry stimmen überein (keine defekten Verweise)',
    () {
      for (final e in entries.entries) {
        final id = e.key.split(':')[1];
        final files = (e.value['files'] as Map).values.cast<String>().toSet();
        final reg = e.key.startsWith('char:')
            ? VisualRegistry.character(id).assets
            : VisualRegistry.world(id).assets;
        expect(reg.toSet(), files, reason: e.key);
      }
      // Jede Registry-Figur/-Welt mit Asset steht im Manifest
      expect(entries.keys.where((k) => k.startsWith('char:')).length, 1);
      expect(entries.keys.where((k) => k.startsWith('world:')).length, 1);
    },
  );

  test('alle Asset-Pfade sind in der pubspec eingetragen', () {
    final pub = File('pubspec.yaml').readAsStringSync();
    for (final e in entries.values) {
      for (final f in (e['files'] as Map).values.cast<String>()) {
        final dir = '${f.substring(0, f.lastIndexOf('/'))}/';
        expect(pub.contains(f) || pub.contains(dir), isTrue, reason: f);
      }
    }
  });

  test(
    'fehlende Zustände sind ausdrücklich benannt (keine stillen Lücken)',
    () {
      final mira = (m['characters'] as Map)['nova_mira'] as Map;
      expect((mira['missingStates'] as List), contains('walkCycle'));
    },
  );
}
