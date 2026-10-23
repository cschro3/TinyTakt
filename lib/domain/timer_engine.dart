import 'dart:convert';

import 'clock.dart';

enum TimerStatus { idle, running, paused, finished }

/// Persistierbarer Zustand der Engine.
class TimerSnapshot {
  const TimerSnapshot({
    required this.status,
    required this.totalMs,
    required this.remainingAtAnchorMs,
    required this.anchorWallMs,
    this.repeat = false,
  });

  final TimerStatus status;
  final int totalMs;
  final int remainingAtAnchorMs;
  final int anchorWallMs;
  final bool repeat;

  Map<String, Object?> toJson() => {
    'v': 1,
    'status': status.name,
    'totalMs': totalMs,
    'remainingAtAnchorMs': remainingAtAnchorMs,
    'anchorWallMs': anchorWallMs,
    'repeat': repeat,
  };

  String encode() => jsonEncode(toJson());

  static TimerSnapshot? tryDecode(String? raw) {
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      final status = TimerStatus.values.firstWhere(
        (s) => s.name == m['status'],
      );
      final total = m['totalMs'];
      final rem = m['remainingAtAnchorMs'];
      final anchor = m['anchorWallMs'];
      if (total is! int || rem is! int || anchor is! int) return null;
      if (total <= 0 || rem < 0 || rem > total) return null;
      return TimerSnapshot(
        status: status,
        totalMs: total,
        remainingAtAnchorMs: rem,
        anchorWallMs: anchor,
        repeat: m['repeat'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Zentrale, UI-unabhängige Timer-Engine.
///
/// Zeitmodell: Die Engine speichert nur einen *Anker* (verbleibende Zeit zum
/// Zeitpunkt des Ankers, Wand- und monotone Uhr). Die verbleibende Zeit wird
/// bei jeder Abfrage neu berechnet – es werden keine Ticks gezählt.
///
/// Vergangene Zeit seit dem Anker = max(monotone Differenz, Wanduhr-Differenz ≥ 0):
///  * Systemzeit wird zurückgestellt → monotone Differenz gewinnt, Timer bleibt korrekt.
///  * Gerät schläft / Prozess pausiert (monotone Uhr steht) → Wanduhr gewinnt.
///  * Systemzeit wird vorgestellt → Timer verkürzt sich um den Sprung
///    (nicht unterscheidbar von Schlaf; dokumentierte Einschränkung).
///  * Zeitzonenwechsel ändert die UTC-Epoche nicht → kein Einfluss.
class TimerEngine {
  TimerEngine(this._clock);

  final Clock _clock;

  TimerStatus _status = TimerStatus.idle;
  int _totalMs = 0;
  int _remainingAtAnchorMs = 0;
  int _anchorWall = 0;
  int _anchorMono = 0;
  bool repeat = false;
  int _completedRuns = 0;

  TimerStatus get status => _status;
  int get totalMs => _totalMs;

  /// Anzahl abgeschlossener Läufe seit Erzeugung (für Wiederholung/Ereignisse).
  int get completedRuns => _completedRuns;

  int get remainingMs {
    switch (_status) {
      case TimerStatus.idle:
        return _totalMs;
      case TimerStatus.paused:
        return _remainingAtAnchorMs;
      case TimerStatus.finished:
        return 0;
      case TimerStatus.running:
        final r = _remainingAtAnchorMs - _elapsedSinceAnchor();
        return r < 0 ? 0 : r;
    }
  }

  /// Anteil verbleibender Zeit, 1.0 = voll, 0.0 = abgelaufen.
  double get fractionRemaining =>
      _totalMs <= 0 ? 0 : (remainingMs / _totalMs).clamp(0.0, 1.0);

  /// Angezeigte Sekunden (aufgerundet, damit „0“ erst bei Ablauf erscheint).
  int get displaySeconds => (remainingMs + 999) ~/ 1000;

  int _elapsedSinceAnchor() {
    final mono = _clock.monoMs() - _anchorMono;
    final wall = _clock.wallMs() - _anchorWall;
    final m = mono < 0 ? 0 : mono;
    final w = wall < 0 ? 0 : wall;
    return m > w ? m : w;
  }

  void _anchor(int remaining) {
    _remainingAtAnchorMs = remaining;
    _anchorWall = _clock.wallMs();
    _anchorMono = _clock.monoMs();
  }

  /// Setzt die Dauer im Leerlauf (bzw. nach Ende/Stopp).
  void setDuration(Duration d) {
    if (d.inMilliseconds <= 0) throw ArgumentError('Dauer muss > 0 sein');
    _status = TimerStatus.idle;
    _totalMs = d.inMilliseconds;
    _remainingAtAnchorMs = _totalMs;
  }

  void start([Duration? duration]) {
    if (duration != null) setDuration(duration);
    if (_totalMs <= 0) throw StateError('Keine Dauer gesetzt');
    if (_status == TimerStatus.running) return;
    _status = TimerStatus.running;
    _anchor(_totalMs);
  }

  void pause() {
    if (_status != TimerStatus.running) return;
    final r = remainingMs;
    if (r <= 0) {
      _finish();
      return;
    }
    _status = TimerStatus.paused;
    _remainingAtAnchorMs = r;
  }

  void resume() {
    if (_status != TimerStatus.paused) return;
    _status = TimerStatus.running;
    _anchor(_remainingAtAnchorMs);
  }

  /// Bricht ab und kehrt mit voller Dauer in den Leerlauf zurück.
  void stop() {
    if (_totalMs == 0) return;
    _status = TimerStatus.idle;
    _remainingAtAnchorMs = _totalMs;
  }

  void reset() => stop();

  /// Prüft auf Ablauf. Gibt true zurück, wenn der Timer gerade abgelaufen ist.
  /// Bei [repeat] startet sofort ein neuer Lauf.
  bool tick() {
    if (_status != TimerStatus.running) return false;
    if (remainingMs > 0) return false;
    _finish();
    return true;
  }

  void _finish() {
    _completedRuns++;
    if (repeat) {
      _status = TimerStatus.running;
      _anchor(_totalMs);
    } else {
      _status = TimerStatus.finished;
      _remainingAtAnchorMs = 0;
    }
  }

  /// Zeitpunkt (UTC-Epoche ms) des Ablaufs, falls laufend – für Benachrichtigungen.
  int? get endWallMs =>
      _status == TimerStatus.running ? _clock.wallMs() + remainingMs : null;

  TimerSnapshot snapshot() => TimerSnapshot(
    status: _status,
    totalMs: _totalMs,
    remainingAtAnchorMs: _remainingAtAnchorMs,
    anchorWallMs: _anchorWall,
    repeat: repeat,
  );

  /// Stellt einen gespeicherten Zustand wieder her (App-Neustart/Prozessende).
  ///
  /// Nach Neustart steht nur die Wanduhr zur Verfügung. Läuft der Timer, wird
  /// die Wanduhr-Differenz abgezogen; liegt der Anker in der Zukunft
  /// (Uhr zurückgestellt oder Gerät neu gestartet mit abweichender Zeit),
  /// wird nichts abgezogen. Rückgabe: true, wenn der Timer währenddessen ablief.
  bool restore(TimerSnapshot s) {
    _totalMs = s.totalMs;
    repeat = s.repeat;
    switch (s.status) {
      case TimerStatus.idle:
        _status = TimerStatus.idle;
        _remainingAtAnchorMs = _totalMs;
        return false;
      case TimerStatus.paused:
        _status = TimerStatus.paused;
        _remainingAtAnchorMs = s.remainingAtAnchorMs;
        return false;
      case TimerStatus.finished:
        _status = TimerStatus.finished;
        _remainingAtAnchorMs = 0;
        return false;
      case TimerStatus.running:
        final gone = _clock.wallMs() - s.anchorWallMs;
        var rem = s.remainingAtAnchorMs - (gone < 0 ? 0 : gone);
        if (rem > 0) {
          _status = TimerStatus.running;
          _anchor(rem);
          return false;
        }
        // Währenddessen abgelaufen. Wiederholung wird bewusst nicht
        // nachgeholt – der Timer endet, damit nichts unbemerkt weiterläuft.
        _completedRuns++;
        _status = TimerStatus.finished;
        _remainingAtAnchorMs = 0;
        return true;
    }
  }
}
