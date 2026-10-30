import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';

void main() {
  test('Alle Klang-Assets im Katalog existieren und IDs sind eindeutig', () {
    final ids = <String>{};
    for (final s in sounds) {
      expect(ids.add(s.id), isTrue, reason: 'doppelte ID ${s.id}');
      if (s.asset.isNotEmpty)
        expect(File('assets/${s.asset}').existsSync(), isTrue, reason: s.asset);
    }
  });

  test('Free enthält genug Musik und Alarme, Pro erweitert', () {
    final music = sounds.where((s) => s.kind == SoundKind.music);
    expect(
      music.where((s) => !s.pro && s.asset.isNotEmpty).length,
      greaterThanOrEqualTo(2),
    );
    expect(music.where((s) => s.pro).length, greaterThanOrEqualTo(5));
    expect(music.length, greaterThanOrEqualTo(13));
  });
}
