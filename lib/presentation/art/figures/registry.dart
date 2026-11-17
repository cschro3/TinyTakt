import 'lumi.dart';
import 'premium_figure.dart';

/// Alle Figuren mit Premium-Rig, nach Katalog-ID.
final Map<String, PremiumFigure> premiumFigures = {
  for (final f in const <PremiumFigure>[LumiFigure()]) f.id: f,
};
