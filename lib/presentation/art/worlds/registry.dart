import 'meadow_world.dart';
import 'world_kit.dart';

/// Welten mit Premium-Malerei, nach Katalog-ID (Hintergrund-ID).
final Map<String, WorldArt> premiumWorlds = {
  for (final w in const <WorldArt>[MeadowWorld()]) w.id: w,
};
