import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/domain/character_profiles.dart';
import 'package:tinytakt/presentation/art/adventure/adventure_gear.dart';
import 'package:tinytakt/presentation/art/visual/visual_registry.dart';

/// Erzeugt docs/CHARACTER_STATUS.md – ehrlicher Fertigstellungsstand aller Figuren.
void main() {
  test('Figuren-Status schreiben', () {
    final b = StringBuffer()
      ..writeln(
        '# Figuren-Status (automatisch aus Registry und Profilen erzeugt)\n',
      )
      ..writeln(
        'Spalten: **Stufe** = tatsächlicher Grafikstand (`premiumAsset` = echte Bilddatei, `premiumVector` = aufgewertete',
      )
      ..writeln(
        'programmatische Figur, `standardVector` = einfache Grundgrafik). **Profil** = Gruppe/Persönlichkeit/Fähigkeit/Geschichte',
      )
      ..writeln(
        'vorhanden. **Ausrüstung** = trägt die automatische Abenteuer-Ausrüstung. **Offen** = fehlende Produktions-Assets.\n',
      );
    final tiers = <AssetTier, int>{};
    for (final c in characters) {
      final t = VisualRegistry.character(c.id).tier;
      tiers[t] = (tiers[t] ?? 0) + 1;
    }
    b.writeln(
      'Zusammenfassung: ${characters.length} Figuren – ${tiers[AssetTier.premiumAsset] ?? 0} mit echtem Bild-Asset, '
      '${tiers[AssetTier.premiumVector] ?? 0} aufgewertete Vektorfigur, ${tiers[AssetTier.standardVector] ?? 0} einfache Vektorfigur. '
      'Profile: ${characters.where((c) => profileOf(c.id) != null).length}/${characters.length}. '
      'Mit Ausrüstung: ${characters.where(gearFits).length}.\n',
    );
    b.writeln(
      '| ID | Name | Gruppe | Stufe | Profil | Ausrüstung | Offen (Produktion) |',
    );
    b.writeln('|---|---|---|---|---|---|---|');
    for (final c in characters) {
      final v = VisualRegistry.character(c.id);
      final p = profileOf(c.id);
      final open = v.tier == AssetTier.premiumAsset
          ? 'Zustände (Blinzeln, Laufzyklus, Jubel), Avatar-Kopf'
          : 'Design-Sheet, Porträt, Ganzkörper, Zustände, Ausrüstungs-Varianten';
      b.writeln(
        '| ${c.id} | ${c.de} | ${p?.group.de ?? '–'} | ${v.tier.name} | ${p != null ? 'ja' : 'nein'} | ${gearFits(c) ? 'ja (programmatisch)' : 'nein (kein Kopf)'} | $open |',
      );
    }
    File('docs/CHARACTER_STATUS.md').writeAsStringSync(b.toString());
  });
}
