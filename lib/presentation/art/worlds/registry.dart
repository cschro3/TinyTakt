import 'meadow_world.dart';
import 'world_kit.dart';
import 'worlds_more.dart';

/// Welten mit Premium-Malerei, nach Katalog-ID (Hintergrund-ID).
final Map<String, WorldArt> premiumWorlds = {
  for (final w in const <WorldArt>[
    MeadowWorld(),
    ForestWorld(),
    NightWorld(),
    SpaceWorld(),
    BeachWorld(),
    SkyWorld(),
    UnderwaterWorld(),
    WinterWorld(),
    SunsetWorld(),
  ])
    w.id: w,
};
