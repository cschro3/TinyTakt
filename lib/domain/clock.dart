/// Zeitquelle für die Timer-Engine.
///
/// [wallMs] ist die UTC-Systemzeit (Millisekunden seit Epoche, unabhängig von
/// der Zeitzone). [monoMs] ist eine monotone Uhr, die durch Änderungen der
/// Systemzeit nicht beeinflusst wird, aber im Gerätesschlaf stehen bleiben kann.
abstract class Clock {
  int wallMs();
  int monoMs();
}

class SystemClock implements Clock {
  SystemClock() {
    _watch.start();
  }
  final Stopwatch _watch = Stopwatch();

  @override
  int wallMs() => DateTime.now().toUtc().millisecondsSinceEpoch;

  @override
  int monoMs() => _watch.elapsedMilliseconds;
}

/// Testuhr mit getrennt steuerbarer Wand- und monotoner Uhr.
class FakeClock implements Clock {
  FakeClock({int wall = 1700000000000, int mono = 0}) {
    _wall = wall;
    _mono = mono;
  }
  late int _wall;
  late int _mono;

  @override
  int wallMs() => _wall;

  @override
  int monoMs() => _mono;

  /// Normale Zeitspanne: beide Uhren laufen gleich.
  void advance(Duration d) {
    _wall += d.inMilliseconds;
    _mono += d.inMilliseconds;
  }

  /// Gerät schläft: Wanduhr läuft weiter, monotone Uhr steht.
  void sleep(Duration d) => _wall += d.inMilliseconds;

  /// Benutzer/Netz verstellt die Systemzeit (positiv = vor, negativ = zurück).
  void jumpWall(Duration d) => _wall += d.inMilliseconds;
}
