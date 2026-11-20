import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/art/adventure/adventure_worlds.dart';
import 'package:tinytakt/presentation/art/visual/visual_registry.dart';

/// Erzeugt docs/ASSET_INVENTAR.md aus der Registry (Bestandsmatrix, Stand des Codes).
void main() {
  test('Inventar schreiben', () {
    final tiers = <AssetTier, List<String>>{};
    for (final c in characters) {
      tiers
          .putIfAbsent(VisualRegistry.character(c.id).tier, () => [])
          .add(c.id);
    }
    final b = StringBuffer()
      ..writeln(
        '# Asset-Inventar (automatisch aus der VisualRegistry erzeugt)\n',
      )
      ..writeln(
        'Einstufung ehrlich: **Premium-Asset** = echte Bilddatei; **Premium-Vektor** = aufgewertete',
      )
      ..writeln(
        'programmatische Figur (KEINE Illustration); **Standard-Vektor** = alte Grundgrafik.\n',
      )
      ..writeln('## Figuren (${characters.length})\n')
      ..writeln('| Stufe | Anzahl | IDs |')
      ..writeln('|---|---|---|');
    for (final t in AssetTier.values) {
      final l = tiers[t] ?? [];
      b.writeln(
        '| ${t.name} | ${l.length} | ${l.length > 14 ? '${l.take(14).join(', ')}, …' : l.join(', ')} |',
      );
    }
    b
      ..writeln('\n## Welten (${backgrounds.length})\n')
      ..writeln('| ID | Name | Stufe | Renderer | Story-Weg | Pro |')
      ..writeln('|---|---|---|---|---|---|');
    for (final w in backgrounds) {
      final v = VisualRegistry.world(w.id);
      b.writeln(
        '| ${w.id} | ${w.de} | ${v.hasAsset ? 'premiumAsset' : 'Fallback (prozedural)'} | ${v.renderer.name} | ${v.storyRoute
            ? 'ja (gemaltes Bild)'
            : adventureWorlds[w.id] != null
            ? 'ja (eigene Szene, programmatisch)'
            : 'nein'} | ${w.pro ? 'ja' : 'nein'} |',
      );
    }
    final m = VisualRegistry.matrix();
    final story = m.where((r) => r.fullScreenStory).length;
    final img = m.where((r) => r.imageBackdrop).length;
    b
      ..writeln('\n## Kombinationsmatrix Figur × Welt × Timer-Stil\n')
      ..writeln('- Kombinationen gesamt: ${m.length}')
      ..writeln('- mit gemaltem Vollbild-Abenteuer (Story-Szene): $story')
      ..writeln('- mit Bild-Hintergrund (Wiese): $img')
      ..writeln(
        '- Figur als Bild-Asset (Mira) in: ${m.where((r) => r.character.hasAsset).length} Kombinationen, Mesh-Renderer in allen Welten und Stilen',
      )
      ..writeln(
        '- alle übrigen: dokumentierter Fallback (Vektor-Figur / prozedurale Welt)',
      );
    File('docs/ASSET_INVENTAR.md').writeAsStringSync(b.toString());
  });
}
