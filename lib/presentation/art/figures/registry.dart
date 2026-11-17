import 'bunny.dart';
import 'cat.dart';
import 'cow.dart';
import 'dog.dart';
import 'hamster.dart';
import 'lumi.dart';
import 'mira.dart';
import 'parrot.dart';
import 'pig.dart';
import 'premium_figure.dart';
import 'sheep.dart';
import 'zeno.dart';

/// Alle Figuren mit Premium-Rig, nach Katalog-ID.
final Map<String, PremiumFigure> premiumFigures = {
  for (final f in const <PremiumFigure>[
    LumiFigure(),
    ZenoFigure(),
    MiraFigure(),
    DogFigure(),
    CatFigure(),
    BunnyFigure(),
    HamsterFigure(),
    ParrotFigure(),
    CowFigure(),
    PigFigure(),
    SheepFigure(),
  ])
    f.id: f,
};
