/// Nur für Leistungsmessungen: einzelne Szenenteile per `--dart-define=PERF_OFF=rays,fx,...`
/// abschalten (Ablation). Ohne Angabe ist alles an; Release-Builds für Nutzer setzen das nie.
/// Schlüssel: rays, fx, vignette, ext, mira, ui, wind
const String _off = String.fromEnvironment('PERF_OFF');
final Set<String> _offSet = _off.isEmpty ? const {} : _off.split(',').toSet();

bool perfOff(String key) => _offSet.contains(key);
