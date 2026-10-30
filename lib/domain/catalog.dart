import 'dart:ui';

/// Kategorien der Figurenbibliothek.
enum CharacterCategory {
  pets('Haustiere', 'Pets'),
  farm('Bauernhof', 'Farm'),
  jungle('Dschungel', 'Jungle'),
  sea('Meer', 'Sea'),
  dino('Dinos', 'Dinos'),
  fantasy('Fantasie', 'Fantasy'),
  vehicles('Fahrzeuge', 'Vehicles'),
  space('Weltraum', 'Space'),
  nature('Natur', 'Nature'),
  seasonal('Jahreszeiten', 'Seasons');

  const CharacterCategory(this.de, this.en);
  final String de;
  final String en;
}

/// Zeichenart einer Figur (siehe CharacterPainter).
enum Archetype {
  critter,
  bird,
  fish,
  whale,
  octopus,
  turtle,
  crab,
  dino,
  dragon,
  robot,
  monster,
  vehicle,
  rocket,
  ufo,
  moon,
  planet,
  star,
  sun,
  flower,
  tree,
  mushroom,
  snowman,
  pumpkin,
  egg,
  xmasTree,
}

enum EarType { none, round, pointy, long, floppy, tiny, huge }

enum Snout { none, muzzle, pigNose, trunk, beak }

enum Pattern { none, spots, stripes, patch }

class CritterStyle {
  const CritterStyle({
    required this.body,
    required this.belly,
    required this.accent,
    this.ear = EarType.round,
    this.snout = Snout.muzzle,
    this.pattern = Pattern.none,
    this.patternColor = const Color(0xFF5A3A2A),
    this.mane = false,
    this.horn = false,
    this.longNeck = false,
    this.woolly = false,
    this.tail = true,
    this.whiskers = false,
    this.maneColor = const Color(0xFFB5652B),
  });
  final Color body, belly, accent, patternColor, maneColor;
  final EarType ear;
  final Snout snout;
  final Pattern pattern;
  final bool mane, horn, longNeck, woolly, tail, whiskers;
}

class CharacterSpec {
  const CharacterSpec({
    required this.id,
    required this.de,
    required this.en,
    required this.category,
    required this.archetype,
    required this.c1,
    required this.c2,
    this.c3 = const Color(0xFFFFFFFF),
    this.critter,
    this.pro = true,
  });
  final String id, de, en;
  final CharacterCategory category;
  final Archetype archetype;
  final Color c1, c2, c3;
  final CritterStyle? critter;
  final bool pro;
}

const _w = Color(0xFFFFFFFF);

/// 46 eigene Figuren; 9 davon in der Free-Version.
final List<CharacterSpec> characters = [
  // Haustiere
  CharacterSpec(
    id: 'dog',
    de: 'Hund Bruno',
    en: 'Bruno the Dog',
    category: CharacterCategory.pets,
    archetype: Archetype.critter,
    c1: const Color(0xFFD9A066),
    c2: const Color(0xFFF3DDBA),
    pro: false,
    critter: const CritterStyle(
      body: Color(0xFFD9A066),
      belly: Color(0xFFF3DDBA),
      accent: Color(0xFF8A5A2B),
      ear: EarType.floppy,
      pattern: Pattern.patch,
      patternColor: Color(0xFF8A5A2B),
    ),
  ),
  CharacterSpec(
    id: 'cat',
    de: 'Katze Mimi',
    en: 'Mimi the Cat',
    category: CharacterCategory.pets,
    archetype: Archetype.critter,
    c1: const Color(0xFF9AA5B8),
    c2: const Color(0xFFE9EDF3),
    pro: false,
    critter: const CritterStyle(
      body: Color(0xFF9AA5B8),
      belly: Color(0xFFE9EDF3),
      accent: Color(0xFFF4A6B5),
      ear: EarType.pointy,
      snout: Snout.none,
      pattern: Pattern.stripes,
      patternColor: Color(0xFF6F7A8F),
      whiskers: true,
    ),
  ),
  CharacterSpec(
    id: 'bunny',
    de: 'Hase Hoppel',
    en: 'Hoppel the Bunny',
    category: CharacterCategory.pets,
    archetype: Archetype.critter,
    c1: const Color(0xFFF1EDE6),
    c2: _w,
    pro: false,
    critter: const CritterStyle(
      body: Color(0xFFF1EDE6),
      belly: _w,
      accent: Color(0xFFF4A6B5),
      ear: EarType.long,
      snout: Snout.none,
      whiskers: true,
    ),
  ),
  CharacterSpec(
    id: 'hamster',
    de: 'Hamster Krümel',
    en: 'Crumb the Hamster',
    category: CharacterCategory.pets,
    archetype: Archetype.critter,
    c1: const Color(0xFFE8B873),
    c2: const Color(0xFFFFF1D6),
    critter: const CritterStyle(
      body: Color(0xFFE8B873),
      belly: Color(0xFFFFF1D6),
      accent: Color(0xFFF4A6B5),
      ear: EarType.tiny,
      snout: Snout.none,
      pattern: Pattern.patch,
      patternColor: Color(0xFFC98E4A),
    ),
  ),
  CharacterSpec(
    id: 'parrot',
    de: 'Papagei Pip',
    en: 'Pip the Parrot',
    category: CharacterCategory.pets,
    archetype: Archetype.bird,
    c1: const Color(0xFF3FBF7F),
    c2: const Color(0xFFFFD84D),
    c3: const Color(0xFFE85D5D),
  ),
  // Bauernhof
  CharacterSpec(
    id: 'cow',
    de: 'Kuh Frieda',
    en: 'Frieda the Cow',
    category: CharacterCategory.farm,
    archetype: Archetype.critter,
    c1: _w,
    c2: const Color(0xFFF4B6C2),
    critter: const CritterStyle(
      body: _w,
      belly: Color(0xFFF4B6C2),
      accent: Color(0xFF3A3A3A),
      ear: EarType.floppy,
      snout: Snout.pigNose,
      pattern: Pattern.patch,
      patternColor: Color(0xFF3A3A3A),
      horn: true,
    ),
  ),
  CharacterSpec(
    id: 'pig',
    de: 'Schwein Rosa',
    en: 'Rosa the Pig',
    category: CharacterCategory.farm,
    archetype: Archetype.critter,
    c1: const Color(0xFFF7B3C2),
    c2: const Color(0xFFFFD6DE),
    pro: false,
    critter: const CritterStyle(
      body: Color(0xFFF7B3C2),
      belly: Color(0xFFFFD6DE),
      accent: Color(0xFFE88499),
      ear: EarType.pointy,
      snout: Snout.pigNose,
    ),
  ),
  CharacterSpec(
    id: 'sheep',
    de: 'Schaf Wolle',
    en: 'Woolly the Sheep',
    category: CharacterCategory.farm,
    archetype: Archetype.critter,
    c1: const Color(0xFFFAF7F0),
    c2: const Color(0xFFE9DCCB),
    critter: const CritterStyle(
      body: Color(0xFFFAF7F0),
      belly: Color(0xFFE9DCCB),
      accent: Color(0xFFD9C6AE),
      ear: EarType.floppy,
      snout: Snout.none,
      woolly: true,
    ),
  ),
  CharacterSpec(
    id: 'chicken',
    de: 'Huhn Henni',
    en: 'Henny the Hen',
    category: CharacterCategory.farm,
    archetype: Archetype.bird,
    c1: const Color(0xFFFFF4E0),
    c2: const Color(0xFFFF9F43),
    c3: const Color(0xFFE53935),
  ),
  CharacterSpec(
    id: 'horse',
    de: 'Pferd Blitz',
    en: 'Blitz the Horse',
    category: CharacterCategory.farm,
    archetype: Archetype.critter,
    c1: const Color(0xFFB9783F),
    c2: const Color(0xFFD9A874),
    critter: const CritterStyle(
      body: Color(0xFFB9783F),
      belly: Color(0xFFD9A874),
      accent: Color(0xFF6B3F1E),
      ear: EarType.pointy,
      mane: true,
      maneColor: Color(0xFF4A2A12),
    ),
  ),
  // Dschungel
  CharacterSpec(
    id: 'lion',
    de: 'Löwe Leo',
    en: 'Leo the Lion',
    category: CharacterCategory.jungle,
    archetype: Archetype.critter,
    c1: const Color(0xFFF2B84B),
    c2: const Color(0xFFFBE3A6),
    pro: false,
    critter: const CritterStyle(
      body: Color(0xFFF2B84B),
      belly: Color(0xFFFBE3A6),
      accent: Color(0xFF8A4B1F),
      ear: EarType.round,
      mane: true,
      maneColor: Color(0xFFC0702A),
      whiskers: true,
    ),
  ),
  CharacterSpec(
    id: 'elephant',
    de: 'Elefant Ella',
    en: 'Ella the Elephant',
    category: CharacterCategory.jungle,
    archetype: Archetype.critter,
    c1: const Color(0xFF9FB3C8),
    c2: const Color(0xFFD5E0EB),
    critter: const CritterStyle(
      body: Color(0xFF9FB3C8),
      belly: Color(0xFFD5E0EB),
      accent: Color(0xFFF4B6C2),
      ear: EarType.huge,
      snout: Snout.trunk,
    ),
  ),
  CharacterSpec(
    id: 'giraffe',
    de: 'Giraffe Gerda',
    en: 'Gerda the Giraffe',
    category: CharacterCategory.jungle,
    archetype: Archetype.critter,
    c1: const Color(0xFFF6CF5B),
    c2: const Color(0xFFFFF0B8),
    critter: const CritterStyle(
      body: Color(0xFFF6CF5B),
      belly: Color(0xFFFFF0B8),
      accent: Color(0xFF8A5A2B),
      ear: EarType.round,
      pattern: Pattern.spots,
      patternColor: Color(0xFFB9783F),
      longNeck: true,
      horn: true,
    ),
  ),
  CharacterSpec(
    id: 'monkey',
    de: 'Affe Max',
    en: 'Max the Monkey',
    category: CharacterCategory.jungle,
    archetype: Archetype.critter,
    c1: const Color(0xFF9B6B43),
    c2: const Color(0xFFF1D3AE),
    critter: const CritterStyle(
      body: Color(0xFF9B6B43),
      belly: Color(0xFFF1D3AE),
      accent: Color(0xFFF1D3AE),
      ear: EarType.round,
      snout: Snout.none,
    ),
  ),
  CharacterSpec(
    id: 'tiger',
    de: 'Tiger Tara',
    en: 'Tara the Tiger',
    category: CharacterCategory.jungle,
    archetype: Archetype.critter,
    c1: const Color(0xFFF59A3D),
    c2: const Color(0xFFFFF1DC),
    critter: const CritterStyle(
      body: Color(0xFFF59A3D),
      belly: Color(0xFFFFF1DC),
      accent: Color(0xFFF4A6B5),
      ear: EarType.round,
      pattern: Pattern.stripes,
      patternColor: Color(0xFF3B2A20),
      whiskers: true,
    ),
  ),
  // Meer
  CharacterSpec(
    id: 'fish',
    de: 'Fisch Flori',
    en: 'Flori the Fish',
    category: CharacterCategory.sea,
    archetype: Archetype.fish,
    c1: const Color(0xFFFF8A4C),
    c2: const Color(0xFFFFD1A8),
    pro: false,
  ),
  CharacterSpec(
    id: 'whale',
    de: 'Wal Willi',
    en: 'Willi the Whale',
    category: CharacterCategory.sea,
    archetype: Archetype.whale,
    c1: const Color(0xFF5B9BE0),
    c2: const Color(0xFFDDEBFA),
  ),
  CharacterSpec(
    id: 'octopus',
    de: 'Krake Kiki',
    en: 'Kiki the Octopus',
    category: CharacterCategory.sea,
    archetype: Archetype.octopus,
    c1: const Color(0xFFB57BE0),
    c2: const Color(0xFFE6CFF7),
  ),
  CharacterSpec(
    id: 'turtle',
    de: 'Schildkröte Schilli',
    en: 'Shelly the Turtle',
    category: CharacterCategory.sea,
    archetype: Archetype.turtle,
    c1: const Color(0xFF5DBB6A),
    c2: const Color(0xFFA9D98F),
    c3: const Color(0xFF8A6A3B),
  ),
  CharacterSpec(
    id: 'crab',
    de: 'Krabbe Kasimir',
    en: 'Kasimir the Crab',
    category: CharacterCategory.sea,
    archetype: Archetype.crab,
    c1: const Color(0xFFE5574B),
    c2: const Color(0xFFFF9B8F),
  ),
  // Dinos
  CharacterSpec(
    id: 'trex',
    de: 'T-Rex Rexi',
    en: 'Rexi the T-Rex',
    category: CharacterCategory.dino,
    archetype: Archetype.dino,
    c1: const Color(0xFF58B368),
    c2: const Color(0xFFCDE9A8),
    c3: _w,
    pro: false,
  ),
  CharacterSpec(
    id: 'tricera',
    de: 'Triceratops Trixi',
    en: 'Trixi the Triceratops',
    category: CharacterCategory.dino,
    archetype: Archetype.dino,
    c1: const Color(0xFF4FA3C7),
    c2: const Color(0xFFD3ECF5),
    c3: const Color(0xFFF2B84B),
  ),
  CharacterSpec(
    id: 'brachio',
    de: 'Langhals Lotte',
    en: 'Lotte Longneck',
    category: CharacterCategory.dino,
    archetype: Archetype.dino,
    c1: const Color(0xFF9CCB55),
    c2: const Color(0xFFE8F3C4),
    c3: const Color(0xFF5FA03A),
  ),
  CharacterSpec(
    id: 'stego',
    de: 'Stegosaurus Stefan',
    en: 'Stefan the Stegosaurus',
    category: CharacterCategory.dino,
    archetype: Archetype.dino,
    c1: const Color(0xFFE08A4C),
    c2: const Color(0xFFFFE0C2),
    c3: const Color(0xFFE5574B),
  ),
  // Fantasie
  CharacterSpec(
    id: 'dragon',
    de: 'Drache Funki',
    en: 'Funki the Dragon',
    category: CharacterCategory.fantasy,
    archetype: Archetype.dragon,
    c1: const Color(0xFF8E6BD9),
    c2: const Color(0xFFD9CCF5),
    c3: const Color(0xFFFF9F43),
  ),
  CharacterSpec(
    id: 'unicorn',
    de: 'Einhorn Stella',
    en: 'Stella the Unicorn',
    category: CharacterCategory.fantasy,
    archetype: Archetype.critter,
    c1: const Color(0xFFFBF3FF),
    c2: _w,
    critter: const CritterStyle(
      body: Color(0xFFFBF3FF),
      belly: _w,
      accent: Color(0xFFF4A6D0),
      ear: EarType.pointy,
      mane: true,
      maneColor: Color(0xFFB57BE0),
      horn: true,
    ),
  ),
  CharacterSpec(
    id: 'robot',
    de: 'Roboter Robbi',
    en: 'Robbi the Robot',
    category: CharacterCategory.fantasy,
    archetype: Archetype.robot,
    c1: const Color(0xFF8FA8C8),
    c2: const Color(0xFFE3ECF7),
    c3: const Color(0xFFFFB347),
  ),
  CharacterSpec(
    id: 'monster',
    de: 'Monster Mumpel',
    en: 'Mumpel the Monster',
    category: CharacterCategory.fantasy,
    archetype: Archetype.monster,
    c1: const Color(0xFF4FC3B5),
    c2: const Color(0xFFBDEFE8),
    c3: const Color(0xFFFFD84D),
  ),
  // Fahrzeuge
  CharacterSpec(
    id: 'car',
    de: 'Auto Brumm',
    en: 'Brumm the Car',
    category: CharacterCategory.vehicles,
    archetype: Archetype.vehicle,
    c1: const Color(0xFFE5574B),
    c2: const Color(0xFFBFE3F5),
  ),
  CharacterSpec(
    id: 'train',
    de: 'Zug Tschu-Tschu',
    en: 'Choo-Choo the Train',
    category: CharacterCategory.vehicles,
    archetype: Archetype.vehicle,
    c1: const Color(0xFF3F8FD9),
    c2: const Color(0xFFBFE3F5),
  ),
  CharacterSpec(
    id: 'tractor',
    de: 'Traktor Toni',
    en: 'Tony the Tractor',
    category: CharacterCategory.vehicles,
    archetype: Archetype.vehicle,
    c1: const Color(0xFF49A85A),
    c2: const Color(0xFFBFE3F5),
  ),
  CharacterSpec(
    id: 'boat',
    de: 'Boot Plitsch',
    en: 'Splash the Boat',
    category: CharacterCategory.vehicles,
    archetype: Archetype.vehicle,
    c1: const Color(0xFFFFB347),
    c2: const Color(0xFFBFE3F5),
  ),
  CharacterSpec(
    id: 'plane',
    de: 'Flieger Flip',
    en: 'Flip the Plane',
    category: CharacterCategory.vehicles,
    archetype: Archetype.vehicle,
    c1: const Color(0xFF7C6BE0),
    c2: const Color(0xFFBFE3F5),
  ),
  // Weltraum
  CharacterSpec(
    id: 'rocket',
    de: 'Rakete Rollo',
    en: 'Rollo the Rocket',
    category: CharacterCategory.space,
    archetype: Archetype.rocket,
    c1: const Color(0xFFE5574B),
    c2: const Color(0xFFEFF3F8),
    c3: const Color(0xFFFFB347),
    pro: false,
  ),
  CharacterSpec(
    id: 'ufo',
    de: 'Ufo Zuzu',
    en: 'Zuzu the UFO',
    category: CharacterCategory.space,
    archetype: Archetype.ufo,
    c1: const Color(0xFF9AA8C0),
    c2: const Color(0xFF7FE0C4),
    c3: const Color(0xFFFFD84D),
  ),
  CharacterSpec(
    id: 'moon',
    de: 'Mond Mila',
    en: 'Mila the Moon',
    category: CharacterCategory.space,
    archetype: Archetype.moon,
    c1: const Color(0xFFFFE9A8),
    c2: const Color(0xFFF2CF76),
  ),
  CharacterSpec(
    id: 'planet',
    de: 'Planet Saturnia',
    en: 'Saturnia the Planet',
    category: CharacterCategory.space,
    archetype: Archetype.planet,
    c1: const Color(0xFFF2A65A),
    c2: const Color(0xFFFFD9A8),
    c3: const Color(0xFF8E6BD9),
  ),
  CharacterSpec(
    id: 'star',
    de: 'Stern Funkel',
    en: 'Sparkle the Star',
    category: CharacterCategory.space,
    archetype: Archetype.star,
    c1: const Color(0xFFFFD84D),
    c2: const Color(0xFFFFF0A8),
  ),
  // Natur
  CharacterSpec(
    id: 'sun',
    de: 'Sonne Sunny',
    en: 'Sunny the Sun',
    category: CharacterCategory.nature,
    archetype: Archetype.sun,
    c1: const Color(0xFFFFC83D),
    c2: const Color(0xFFFF9F43),
    pro: false,
  ),
  CharacterSpec(
    id: 'flower',
    de: 'Blume Blümchen',
    en: 'Blossom the Flower',
    category: CharacterCategory.nature,
    archetype: Archetype.flower,
    c1: const Color(0xFFF4709B),
    c2: const Color(0xFFFFD84D),
    c3: const Color(0xFF4FA860),
  ),
  CharacterSpec(
    id: 'tree',
    de: 'Baum Eddi',
    en: 'Eddie the Tree',
    category: CharacterCategory.nature,
    archetype: Archetype.tree,
    c1: const Color(0xFF4FA860),
    c2: const Color(0xFF9CD27A),
    c3: const Color(0xFF8A5A2B),
  ),
  CharacterSpec(
    id: 'mushroom',
    de: 'Pilz Poppi',
    en: 'Poppy the Mushroom',
    category: CharacterCategory.nature,
    archetype: Archetype.mushroom,
    c1: const Color(0xFFE5574B),
    c2: const Color(0xFFFFF4E0),
  ),
  // Jahreszeiten
  CharacterSpec(
    id: 'snowman',
    de: 'Schneemann Flocke',
    en: 'Flake the Snowman',
    category: CharacterCategory.seasonal,
    archetype: Archetype.snowman,
    c1: _w,
    c2: const Color(0xFFE5574B),
    c3: const Color(0xFFFF9F43),
  ),
  CharacterSpec(
    id: 'pumpkin',
    de: 'Kürbis Kuno',
    en: 'Kuno the Pumpkin',
    category: CharacterCategory.seasonal,
    archetype: Archetype.pumpkin,
    c1: const Color(0xFFF58A2E),
    c2: const Color(0xFF4FA860),
  ),
  CharacterSpec(
    id: 'egg',
    de: 'Osterei Bunti',
    en: 'Bunti the Egg',
    category: CharacterCategory.seasonal,
    archetype: Archetype.egg,
    c1: const Color(0xFF7FD6C8),
    c2: const Color(0xFFF4709B),
    c3: const Color(0xFFFFD84D),
  ),
  CharacterSpec(
    id: 'xmas',
    de: 'Tannenbaum Tanne',
    en: 'Fir the Christmas Tree',
    category: CharacterCategory.seasonal,
    archetype: Archetype.xmasTree,
    c1: const Color(0xFF2F9E5B),
    c2: const Color(0xFFFFD84D),
    c3: const Color(0xFFE5574B),
  ),
];

CharacterSpec characterById(String id) =>
    characters.firstWhere((c) => c.id == id, orElse: () => characters.first);

/// Hintergründe / Themenwelten.
enum Scenery {
  meadow,
  sky,
  beach,
  forest,
  night,
  space,
  underwater,
  winter,
  sunset,
}

class BackgroundSpec {
  const BackgroundSpec(
    this.id,
    this.de,
    this.en,
    this.scenery,
    this.top,
    this.bottom, {
    this.pro = true,
  });
  final String id, de, en;
  final Scenery scenery;
  final Color top, bottom;
  final bool pro;
}

const List<BackgroundSpec> backgrounds = [
  BackgroundSpec(
    'meadow',
    'Blumenwiese',
    'Flower meadow',
    Scenery.meadow,
    Color(0xFF8FD3F4),
    Color(0xFFB8E986),
    pro: false,
  ),
  BackgroundSpec(
    'sky',
    'Wolkenhimmel',
    'Cloudy sky',
    Scenery.sky,
    Color(0xFF6EC1F5),
    Color(0xFFD9F1FF),
    pro: false,
  ),
  BackgroundSpec(
    'beach',
    'Strand',
    'Beach',
    Scenery.beach,
    Color(0xFF7FD6F2),
    Color(0xFFFFE8A8),
    pro: false,
  ),
  BackgroundSpec(
    'forest',
    'Zauberwald',
    'Magic forest',
    Scenery.forest,
    Color(0xFFA8E0B0),
    Color(0xFF5DB36A),
    pro: false,
  ),
  BackgroundSpec(
    'night',
    'Sternennacht',
    'Starry night',
    Scenery.night,
    Color(0xFF1F2A5C),
    Color(0xFF4A5AA8),
    pro: false,
  ),
  BackgroundSpec(
    'space',
    'Weltraum',
    'Outer space',
    Scenery.space,
    Color(0xFF0E0F2E),
    Color(0xFF3A1F6B),
  ),
  BackgroundSpec(
    'underwater',
    'Unterwasserwelt',
    'Underwater',
    Scenery.underwater,
    Color(0xFF39B8D9),
    Color(0xFF1B5FA0),
  ),
  BackgroundSpec(
    'winter',
    'Winterland',
    'Winter land',
    Scenery.winter,
    Color(0xFFBFDFF5),
    Color(0xFFF4FAFF),
  ),
  BackgroundSpec(
    'sunset',
    'Abendrot',
    'Sunset',
    Scenery.sunset,
    Color(0xFFFF9A76),
    Color(0xFFFFD27F),
  ),
];

BackgroundSpec backgroundById(String id) =>
    backgrounds.firstWhere((b) => b.id == id, orElse: () => backgrounds.first);

/// Darstellungsarten des Timers.
enum TimerStyle {
  circle('Kreis', 'Circle', false),
  adventure('Abenteuer', 'Adventure', false),
  fill('Füllstand', 'Fill level', false),
  rainbow('Regenbogen', 'Rainbow', true),
  hourglass('Sanduhr', 'Hourglass', true);

  const TimerStyle(this.de, this.en, this.pro);
  final String de, en;
  final bool pro;
}

enum SoundKind { music, alarm }

class SoundSpec {
  const SoundSpec(
    this.id,
    this.de,
    this.en,
    this.kind,
    this.asset, {
    this.pro = true,
    this.category,
  });
  final String id, de, en, asset;
  final SoundKind kind;
  final bool pro;
  final String? category;
}

const List<SoundSpec> sounds = [
  SoundSpec(
    'music_none',
    'Keine Musik',
    'No music',
    SoundKind.music,
    '',
    pro: false,
  ),
  SoundSpec(
    'music_calm',
    'Sanfte Wolken',
    'Soft clouds',
    SoundKind.music,
    'audio/music_calm.m4a',
    pro: false,
    category: 'Entspannung',
  ),
  SoundSpec(
    'music_happy',
    'Fröhlicher Hüpfer',
    'Happy hop',
    SoundKind.music,
    'audio/music_happy.m4a',
    pro: false,
    category: 'Fröhlich',
  ),
  SoundSpec(
    'music_nature',
    'Waldspaziergang',
    'Forest walk',
    SoundKind.music,
    'audio/music_nature.m4a',
    category: 'Natur',
  ),
  SoundSpec(
    'music_adventure',
    'Kleine Reise',
    'Little journey',
    SoundKind.music,
    'audio/music_adventure.m4a',
    category: 'Abenteuer',
  ),
  SoundSpec(
    'music_sleep',
    'Gute Nacht',
    'Good night',
    SoundKind.music,
    'audio/music_sleep.m4a',
    category: 'Schlafenszeit',
  ),
  SoundSpec(
    'music_calm2',
    'Sanfter Teich',
    'Gentle pond',
    SoundKind.music,
    'audio/music_calm2.m4a',
    category: 'Entspannung',
  ),
  SoundSpec(
    'music_piano',
    'Klaviertraum',
    'Piano dream',
    SoundKind.music,
    'audio/music_piano_dream.m4a',
    pro: false,
    category: 'Entspannung',
  ),
  SoundSpec(
    'music_ukulele',
    'Sonnenschein-Ukulele',
    'Sunshine ukulele',
    SoundKind.music,
    'audio/music_ukulele.m4a',
    pro: false,
    category: 'Fröhlich',
  ),
  SoundSpec(
    'music_waltz',
    'Spieluhr-Walzer',
    'Music box waltz',
    SoundKind.music,
    'audio/music_waltz.m4a',

    category: 'Schlafenszeit',
  ),
  SoundSpec(
    'music_bossa',
    'Marimba-Bossa',
    'Marimba bossa',
    SoundKind.music,
    'audio/music_bossa.m4a',

    category: 'Fröhlich',
  ),
  SoundSpec(
    'music_rain',
    'Regen und Glöckchen',
    'Rain and bells',
    SoundKind.music,
    'audio/music_rain.m4a',

    category: 'Natur',
  ),
  SoundSpec(
    'music_march',
    'Kleiner Marsch',
    'Little march',
    SoundKind.music,
    'audio/music_march.m4a',

    category: 'Abenteuer',
  ),
  SoundSpec(
    'music_lofi',
    'Ruhige Pause',
    'Quiet break',
    SoundKind.music,
    'audio/music_lofi.m4a',

    category: 'Entspannung',
  ),
  SoundSpec(
    'alarm_bell',
    'Glöckchen',
    'Little bell',
    SoundKind.alarm,
    'audio/alarm_bell.m4a',
    pro: false,
  ),
  SoundSpec(
    'alarm_chime',
    'Windspiel',
    'Wind chime',
    SoundKind.alarm,
    'audio/alarm_chime.m4a',
    pro: false,
  ),
  SoundSpec(
    'alarm_marimba',
    'Marimba',
    'Marimba',
    SoundKind.alarm,
    'audio/alarm_marimba.m4a',
    pro: false,
  ),
  SoundSpec(
    'alarm_harp',
    'Harfe',
    'Harp',
    SoundKind.alarm,
    'audio/alarm_harp.m4a',
  ),
  SoundSpec(
    'alarm_sparkle',
    'Funkeln',
    'Sparkle',
    SoundKind.alarm,
    'audio/alarm_sparkle.m4a',
  ),
  SoundSpec(
    'alarm_music_box',
    'Spieluhr',
    'Music box',
    SoundKind.alarm,
    'audio/alarm_music_box.m4a',
  ),
];

SoundSpec soundById(String id) =>
    sounds.firstWhere((s) => s.id == id, orElse: () => sounds.first);

/// Schnellauswahl in Minuten.
const List<int> quickMinutes = [1, 2, 5, 10, 15, 30];

const String proProductId = 'tinytakt_pro_lifetime';
