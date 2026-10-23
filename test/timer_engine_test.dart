import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/clock.dart';
import 'package:tinytakt/domain/timer_engine.dart';

void main() {
  late FakeClock clock;
  late TimerEngine e;
  setUp(() {
    clock = FakeClock();
    e = TimerEngine(clock);
  });

  test('Startzustand und Dauer setzen', () {
    expect(e.status, TimerStatus.idle);
    e.setDuration(const Duration(minutes: 5));
    expect(e.remainingMs, 300000);
    expect(e.fractionRemaining, 1.0);
    expect(() => e.setDuration(Duration.zero), throwsArgumentError);
    expect(() => e.start(), returnsNormally);
  });

  test('Start ohne Dauer wirft', () {
    expect(() => e.start(), throwsStateError);
  });

  test('Zeitberechnung und Sekundenanzeige (aufgerundet)', () {
    e.start(const Duration(seconds: 10));
    clock.advance(const Duration(milliseconds: 2500));
    expect(e.remainingMs, 7500);
    expect(e.displaySeconds, 8);
    expect(e.fractionRemaining, closeTo(0.75, 1e-9));
  });

  test('Pause hält die Zeit an, Fortsetzen läuft weiter', () {
    e.start(const Duration(seconds: 10));
    clock.advance(const Duration(seconds: 3));
    e.pause();
    expect(e.status, TimerStatus.paused);
    clock.advance(const Duration(minutes: 5));
    expect(e.remainingMs, 7000);
    e.resume();
    clock.advance(const Duration(seconds: 2));
    expect(e.remainingMs, 5000);
  });

  test('Stopp und Zurücksetzen stellen volle Dauer her', () {
    e.start(const Duration(seconds: 10));
    clock.advance(const Duration(seconds: 4));
    e.stop();
    expect(e.status, TimerStatus.idle);
    expect(e.remainingMs, 10000);
    e.start();
    clock.advance(const Duration(seconds: 1));
    e.reset();
    expect(e.remainingMs, 10000);
  });

  test('Automatisches Beenden genau einmal', () {
    e.start(const Duration(seconds: 2));
    clock.advance(const Duration(seconds: 1));
    expect(e.tick(), isFalse);
    clock.advance(const Duration(seconds: 1));
    expect(e.tick(), isTrue);
    expect(e.status, TimerStatus.finished);
    expect(e.remainingMs, 0);
    expect(e.tick(), isFalse);
    expect(e.completedRuns, 1);
  });

  test('Wiederholen startet neuen Lauf', () {
    e.repeat = true;
    e.start(const Duration(seconds: 2));
    clock.advance(const Duration(seconds: 2));
    expect(e.tick(), isTrue);
    expect(e.status, TimerStatus.running);
    expect(e.remainingMs, 2000);
    expect(e.completedRuns, 1);
  });

  test('Gerätschlaf: Wanduhr zählt, monotone Uhr steht', () {
    e.start(const Duration(minutes: 10));
    clock.sleep(const Duration(minutes: 4));
    expect(e.remainingMs, 6 * 60 * 1000);
  });

  test('Systemzeit zurückgestellt: Timer bleibt korrekt', () {
    e.start(const Duration(minutes: 10));
    clock.advance(const Duration(minutes: 1));
    clock.jumpWall(const Duration(hours: -5));
    clock.advance(const Duration(minutes: 1));
    expect(e.remainingMs, 8 * 60 * 1000);
  });

  test('Systemzeit vorgestellt verkürzt (dokumentiertes Verhalten)', () {
    e.start(const Duration(minutes: 10));
    clock.jumpWall(const Duration(minutes: 3));
    expect(e.remainingMs, 7 * 60 * 1000);
  });

  test('Zeitzonenwechsel (UTC-Epoche bleibt gleich) hat keinen Einfluss', () {
    e.start(const Duration(minutes: 10));
    clock.advance(const Duration(minutes: 2));
    // Zeitzone wechselt: Epoche unverändert -> keine Auswirkung
    expect(e.remainingMs, 8 * 60 * 1000);
  });

  test('Snapshot-Roundtrip und Wiederherstellung (laufend)', () {
    e.start(const Duration(minutes: 10));
    clock.advance(const Duration(minutes: 2));
    final raw = e.snapshot().encode();

    // Neustart: neue Engine, neue monotone Uhr, Wanduhr 3 Minuten später
    final clock2 = FakeClock(wall: clock.wallMs() + 180000, mono: 0);
    final e2 = TimerEngine(clock2);
    final expired = e2.restore(TimerSnapshot.tryDecode(raw)!);
    expect(expired, isFalse);
    expect(e2.status, TimerStatus.running);
    // Anker liegt beim Start: 2 min + 3 min Wanduhr seit Anker vergangen.
    expect(e2.remainingMs, 5 * 60000);
  });

  test('Wiederherstellung nach Ablauf meldet Ende', () {
    e.start(const Duration(minutes: 1));
    final snap = e.snapshot();
    final e2 = TimerEngine(FakeClock(wall: clock.wallMs() + 120000));
    expect(e2.restore(snap), isTrue);
    expect(e2.status, TimerStatus.finished);
  });

  test('Wiederherstellung bei zurückgestellter Uhr zieht nichts ab', () {
    e.start(const Duration(minutes: 1));
    final snap = e.snapshot();
    final e2 = TimerEngine(FakeClock(wall: clock.wallMs() - 100000));
    e2.restore(snap);
    expect(e2.remainingMs, 60000);
  });

  test('Wiederherstellung: pausiert bleibt pausiert', () {
    e.start(const Duration(minutes: 1));
    clock.advance(const Duration(seconds: 20));
    e.pause();
    final e2 = TimerEngine(FakeClock(wall: clock.wallMs() + 99999999));
    e2.restore(e.snapshot());
    expect(e2.status, TimerStatus.paused);
    expect(e2.remainingMs, 40000);
  });

  test('Korrupte Snapshots werden abgelehnt', () {
    expect(TimerSnapshot.tryDecode(null), isNull);
    expect(TimerSnapshot.tryDecode('kaputt'), isNull);
    expect(TimerSnapshot.tryDecode('{"status":"running"}'), isNull);
    expect(
      TimerSnapshot.tryDecode(
        '{"status":"running","totalMs":10,"remainingAtAnchorMs":99,"anchorWallMs":1}',
      ),
      isNull,
    );
    expect(
      TimerSnapshot.tryDecode(
        '{"status":"bogus","totalMs":10,"remainingAtAnchorMs":1,"anchorWallMs":1}',
      ),
      isNull,
    );
  });

  test('Doppeltes Start/Pause/Resume ist idempotent', () {
    e.start(const Duration(seconds: 10));
    clock.advance(const Duration(seconds: 1));
    e.start();
    expect(e.remainingMs, 9000);
    e.pause();
    e.pause();
    e.resume();
    e.resume();
    clock.advance(const Duration(seconds: 1));
    expect(e.remainingMs, 8000);
  });

  test('Pause nach Ablauf beendet Timer', () {
    e.start(const Duration(seconds: 1));
    clock.advance(const Duration(seconds: 5));
    e.pause();
    expect(e.status, TimerStatus.finished);
  });

  test('endWallMs nur im Lauf', () {
    expect(e.endWallMs, isNull);
    e.start(const Duration(seconds: 30));
    expect(e.endWallMs, clock.wallMs() + 30000);
  });
}
