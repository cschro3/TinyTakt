import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/art/visual/visual_registry.dart';

void main() {
  test('jede Figur-ID löst eindeutig auf', () {
    for (final c in characters) {
      final v = VisualRegistry.character(c.id);
      expect(v.id, c.id);
    }
    expect(characters.length, greaterThanOrEqualTo(81));
  });

  test('jede Welt-ID löst auf, nur Blumenwiese hat Bild-Asset', () {
    for (final b in backgrounds) {
      final w = VisualRegistry.world(b.id);
      expect(w.id, b.id);
      expect(w.hasAsset, b.id == 'meadow');
    }
  });

  test('Mira ist Bild-Asset, andere Rig-Figuren Vektor, Rest Standard', () {
    expect(VisualRegistry.character('nova_mira').tier, AssetTier.premiumAsset);
    expect(VisualRegistry.character('nova_lumi').tier, AssetTier.premiumVector);
    final std = characters.where(
      (c) => VisualRegistry.character(c.id).tier == AssetTier.standardVector,
    );
    expect(std, isNotEmpty);
  });

  test('Story-Szene hängt nur an Welt + Abenteuer, nicht an der Figur', () {
    for (final c in characters) {
      expect(
        VisualRegistry.recipe(
          c.id,
          'meadow',
          TimerStyle.adventure,
        ).fullScreenStory,
        isTrue,
        reason: c.id,
      );
      expect(
        VisualRegistry.recipe(
          c.id,
          'meadow',
          TimerStyle.circle,
        ).fullScreenStory,
        isFalse,
      );
      expect(
        VisualRegistry.recipe(
          c.id,
          'forest',
          TimerStyle.adventure,
        ).fullScreenStory,
        isFalse,
      );
    }
  });

  test('Fallback bei Ladefehler: kein Bildhintergrund, keine Story', () {
    final r = VisualRegistry.recipe(
      'nova_mira',
      'meadow',
      TimerStyle.adventure,
      assetsFailed: true,
    );
    expect(r.fullScreenStory, isFalse);
    expect(r.imageBackdrop, isFalse);
  });

  test(
    'Matrix deckt alle Kombinationen ab, jeder Timer-Stil bleibt wählbar',
    () {
      expect(
        VisualRegistry.matrix().length,
        characters.length * backgrounds.length * TimerStyle.values.length,
      );
      expect(TimerStyle.values.length, 10);
    },
  );
}
