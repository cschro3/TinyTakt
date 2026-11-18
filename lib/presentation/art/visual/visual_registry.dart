import '../../../domain/catalog.dart';
import '../figures/registry.dart';

/// Wie hochwertig ist die Darstellung einer Figur/Welt tatsächlich? (ehrliche Einstufung)
enum AssetTier {
  /// Echtes Illustrations-Asset (Bilddatei) ist vorhanden und wird verwendet.
  premiumAsset,

  /// Aufgewertete programmatische Vektorfigur/-welt (Rig, Verläufe) – KEINE Illustration.
  premiumVector,

  /// Alte Standardgrafik (einfache Vektorformen).
  standardVector,
}

/// Womit eine Figur gezeichnet wird.
enum FigureRenderer { bitmapMesh, vectorRig, vectorStandard }

/// Womit eine Welt gezeichnet wird.
enum WorldRenderer { bitmapStory, procedural }

/// Visuelle Identität einer Figur – gilt in allen Ansichten.
class CharacterVisual {
  const CharacterVisual(
    this.id,
    this.tier,
    this.renderer, {
    this.assets = const [],
  });
  final String id;
  final AssetTier tier;
  final FigureRenderer renderer;

  /// Dateien, die für die Premium-Darstellung nötig sind (leer = keine).
  final List<String> assets;
  bool get hasAsset => assets.isNotEmpty;
}

/// Visuelle Identität einer Welt – gilt in allen Ansichten.
class WorldVisual {
  const WorldVisual(
    this.id,
    this.tier,
    this.renderer, {
    this.assets = const [],
    this.storyRoute = false,
  });
  final String id;
  final AssetTier tier;
  final WorldRenderer renderer;
  final List<String> assets;

  /// Es gibt einen gemalten Abenteuer-Weg (Vollbild-Story-Szene) für diese Welt.
  final bool storyRoute;
  bool get hasAsset => assets.isNotEmpty;
}

/// Ergebnis der Auflösung Figur × Welt × Timer-Stil.
class SceneRecipe {
  const SceneRecipe({
    required this.character,
    required this.world,
    required this.style,
    required this.fullScreenStory,
    required this.imageBackdrop,
  });
  final CharacterVisual character;
  final WorldVisual world;
  final TimerStyle style;

  /// Vollbild-Story-Szene (gemalter Weg, Wind, Licht) statt klassischer Bühne.
  final bool fullScreenStory;

  /// Hintergrund ist ein echtes Bild (auch für klassische Timer-Stile).
  final bool imageBackdrop;

  /// Welche Bilddateien diese Szene braucht.
  List<String> get requiredAssets => [
    if (character.renderer == FigureRenderer.bitmapMesh) ...character.assets,
    if (imageBackdrop) ...world.assets,
  ];
}

/// Zentrale Zuordnung: Jede Figur/Welt hat genau EINE visuelle Identität; alle Ansichten fragen
/// diese Registry statt eigene Sonderfälle zu prüfen. Neue Premium-Assets werden hier (bzw. im
/// Manifest `assets/art/manifest.json`) eingetragen – kein Screen muss angepasst werden.
class VisualRegistry {
  VisualRegistry._();

  static const _miraAssets = [
    'assets/art/mira/mira_512.webp',
    'assets/art/mira/mira_prototype.webp',
  ];
  static const _meadowAssets = [
    'assets/art/meadow/meadow_900.webp',
    'assets/art/meadow/meadow_prototype.webp',
  ];

  /// Figuren mit Bild-Asset.
  static const _bitmapCharacters = <String, List<String>>{
    'nova_mira': _miraAssets,
  };

  /// Welten mit Bild-Asset (+ gemaltem Abenteuer-Weg).
  static const _bitmapWorlds = <String, List<String>>{'meadow': _meadowAssets};

  static CharacterVisual character(String id) {
    final a = _bitmapCharacters[id];
    if (a != null) {
      return CharacterVisual(
        id,
        AssetTier.premiumAsset,
        FigureRenderer.bitmapMesh,
        assets: a,
      );
    }
    if (premiumFigures.containsKey(id)) {
      return CharacterVisual(
        id,
        AssetTier.premiumVector,
        FigureRenderer.vectorRig,
      );
    }
    return CharacterVisual(
      id,
      AssetTier.standardVector,
      FigureRenderer.vectorStandard,
    );
  }

  static WorldVisual world(String id) {
    final a = _bitmapWorlds[id];
    if (a != null) {
      return WorldVisual(
        id,
        AssetTier.premiumAsset,
        WorldRenderer.bitmapStory,
        assets: a,
        storyRoute: true,
      );
    }
    return WorldVisual(id, AssetTier.premiumVector, WorldRenderer.procedural);
  }

  /// Löst die Szene auf. [assetsReady]/[assetsFailed] beschreiben den Ladezustand der Bilder:
  /// scheitert das Laden, greift der dokumentierte Fallback (Vektor), sonst nie.
  static SceneRecipe recipe(
    String characterId,
    String worldId,
    TimerStyle style, {
    bool assetsFailed = false,
  }) {
    final c = character(characterId);
    final w = world(worldId);
    final image = w.renderer == WorldRenderer.bitmapStory && !assetsFailed;
    return SceneRecipe(
      character: c,
      world: w,
      style: style,
      fullScreenStory: image && w.storyRoute && style == TimerStyle.adventure,
      imageBackdrop: image,
    );
  }

  /// Alle Kombinationen für Inventar und Tests.
  static List<SceneRecipe> matrix() => [
    for (final c in characters)
      for (final b in backgrounds)
        for (final s in TimerStyle.values) recipe(c.id, b.id, s),
  ];
}
