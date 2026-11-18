import '../../../app/perf_monitor.dart';

/// Qualitätsstufe der Story-Szene. Höhere Stufen = weniger Hintergrundbewegung und weniger Bilder.
enum StoryTier { full, reduced, minimal }

/// Lenkt Bildrate und Effekte nach Gerät, Zustand und gemessener Leistung.
///
/// * [full]: Mira bis 60 Hz, Hintergrund 30 Hz, alle Effekte.
/// * [reduced]: Mira 30 Hz, Hintergrund 15 Hz, weniger Partikel.
/// * [minimal]: 20/12 Hz, kein Wind, keine Partikel, Strahlen statisch (Stromsparmodus).
///
/// Der Regler schaltet nur herunter, wenn die tatsächlich gelieferte Bildrate dauerhaft unter
/// 70 % des Zielwerts liegt, und nur nach einer Eingewöhnung (Shader, Bake). Zurück nach oben
/// höchstens zweimal, nach 12 s stabiler Leistung. Die Timer-Logik ist davon unberührt.
class StoryGovernor {
  StoryGovernor({StoryTier start = StoryTier.full, double Function()? fpsProbe})
    : tier = start,
      _fps = fpsProbe ?? (() => PerfMonitor.instance.achievedFps(seconds: 2));

  final double Function() _fps;

  StoryTier tier;
  bool forceMinimal = false;

  /// Feste Stufe (Messungen): der Regler wertet dann nichts mehr aus.
  bool locked = false;
  int _bad = 0, _good = 0, _upgradesLeft = 2;
  double _lastEval = 0, _lastChange = 0;

  StoryTier get effective => forceMinimal ? StoryTier.minimal : tier;

  /// Szenenrate (Hz) je Stufe und Zustand.
  static int sceneHz(StoryTier t, {required bool active}) => switch (t) {
    StoryTier.full => active ? 60 : 30,
    StoryTier.reduced => active ? 30 : 20,
    StoryTier.minimal => active ? 20 : 12,
  };

  /// Rate, mit der der Hintergrund (Wind, Strahlen, Partikel) neu gezeichnet wird; 0 = statisch.
  static int ambientHz(StoryTier t) => switch (t) {
    StoryTier.full => 30,
    StoryTier.reduced => 15,
    StoryTier.minimal => 0,
  };

  static int particles(StoryTier t) => switch (t) {
    StoryTier.full => 26,
    StoryTier.reduced => 12,
    StoryTier.minimal => 0,
  };

  /// Wind-Netz im Vordergrund nur auf der vollen Stufe.
  static bool wind(StoryTier t) => t == StoryTier.full;

  /// Einmal pro Sekunde aufrufen. [t] = Szenenzeit in s, [targetHz] = aktuell angeforderte Rate.
  /// Gibt true zurück, wenn die Stufe gewechselt hat.
  bool evaluate(double t, int targetHz, {required bool visible}) {
    if (t - _lastEval < 1) return false;
    _lastEval = t;
    if (locked || forceMinimal || !visible || t < 4 || t - _lastChange < 3)
      return false;
    final fps = _fps();
    if (fps <= 0.1)
      return false; // keine Frames (z. B. Tab im Hintergrund) – nicht bewerten
    if (fps < targetHz * 0.7) {
      _bad++;
      _good = 0;
      if (_bad >= 2 && tier != StoryTier.minimal) {
        tier = StoryTier.values[tier.index + 1];
        _bad = 0;
        _lastChange = t;
        return true;
      }
    } else if (fps >= targetHz * 0.92) {
      _good++;
      _bad = 0;
      if (_good >= 12 && tier != StoryTier.full && _upgradesLeft > 0) {
        tier = StoryTier.values[tier.index - 1];
        _upgradesLeft--;
        _good = 0;
        _lastChange = t;
        return true;
      }
    } else {
      _bad = 0;
      _good = 0;
    }
    return false;
  }
}
