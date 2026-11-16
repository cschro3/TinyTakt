import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/data/settings_repository.dart';
import 'package:tinytakt/data/stores.dart';
import 'package:tinytakt/domain/session_plan.dart';
import 'package:tinytakt/domain/timer_engine.dart';

import 'helpers.dart';

SessionPlan plan3() => SessionPlan.rounds(
  focusMin: 2,
  pauseMin: 1,
  rounds: 2,
); // 2 + 1 + 2 = 5 min

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionPlan (Rechnung)', () {
    test(
      'rounds: Arbeitsphasen mit Pausen dazwischen, keine Pause am Ende',
      () {
        final p = SessionPlan.rounds(focusMin: 15, pauseMin: 5, rounds: 3);
        expect(p.steps.map((s) => s.kind), [
          StepKind.focus,
          StepKind.pause,
          StepKind.focus,
          StepKind.pause,
          StepKind.focus,
        ]);
        expect(p.totalMs, (15 * 3 + 5 * 2) * 60000);
        expect(p.rounds, 3);
        expect(p.isValid, isTrue);
        expect(p.boundariesMs, [
          15 * 60000,
          20 * 60000,
          35 * 60000,
          40 * 60000,
          55 * 60000,
        ]);
      },
    );

    test('Ohne Pausenzeit entstehen nur Arbeitsphasen', () {
      final p = SessionPlan.rounds(focusMin: 10, pauseMin: 0, rounds: 2);
      expect(p.steps.length, 2);
    });

    test('viewAt: Phase, Restzeit, Runde an den Grenzen', () {
      final p = plan3();
      var v = p.viewAt(0);
      expect(
        (v.index, v.round, v.stepRemainingMs, v.isPause, v.finished),
        (0, 1, 120000, false, false),
      );
      v = p.viewAt(119999);
      expect(v.index, 0);
      v = p.viewAt(120000);
      expect(
        (v.index, v.isPause, v.stepRemainingMs, v.round),
        (1, true, 60000, 1),
      );
      v = p.viewAt(150000);
      expect(v.stepRemainingMs, 30000);
      expect(v.stepFraction, closeTo(0.5, 1e-9));
      v = p.viewAt(180000);
      expect((v.index, v.round, v.isPause), (2, 2, false));
      v = p.viewAt(299999);
      expect(v.finished, isFalse);
      v = p.viewAt(300000);
      expect((v.finished, v.stepRemainingMs), (true, 0));
      expect(p.viewAt(99999999).finished, isTrue);
      expect(p.viewAt(-5).index, 0);
    });

    test('JSON-Roundtrip und ungültige Daten', () {
      final p = plan3();
      final back = SessionPlan.tryFromJson(p.toJson())!;
      expect(back.totalMs, p.totalMs);
      expect(SessionPlan.tryFromJson(null), isNull);
      expect(SessionPlan.tryFromJson({'steps': 'x'}), isNull);
      expect(SessionPlan.tryFromJson({'steps': []}), isNull);
      expect(
        SessionPlan.tryFromJson({
          'steps': [
            {'k': 'focus', 'ms': 5},
          ],
        }),
        isNull,
        reason: 'zu kurz',
      );
      expect(
        SessionPlan.tryFromJson({
          'steps': [
            {'k': 'pause', 'ms': 60000},
          ],
        }),
        isNull,
        reason: 'muss mit Arbeit beginnen',
      );
      expect(
        SessionPlan.tryFromJson({
          'steps': [
            {'k': 'kaputt', 'ms': 60000},
          ],
        }),
        isNull,
      );
      expect(
        SessionPlan(
          List.generate(25, (_) => const PlanStep(StepKind.focus, 60000)),
        ).isValid,
        isFalse,
        reason: 'zu viele Phasen',
      );
    });

    test('Einstellungen speichern und laden den Plan; kaputter Plan wird ignoriert', () async {
      final store = MemoryStore();
      final s = SettingsRepository(store);
      await s.update((x) => x.plan = plan3());
      expect(SettingsRepository(store).plan?.totalMs, 300000);
      await store.setString(
        'settings.v1',
        '{"plan": {"steps": [{"k":"x","ms":1}]}}',
      );
      expect(SettingsRepository(store).plan, isNull);
    });
  });

  group('TimerController mit Plan', () {
    late TestEnv env;
    setUp(() async {
      env = TestEnv();
      await env.init();
    });
    tearDown(() => env.timer.dispose());

    test(
      'setPlan stellt Gesamtdauer ein, Ansicht beginnt in Runde 1',
      () async {
        await env.timer.setPlan(plan3());
        expect(env.timer.engine.totalMs, 300000);
        final v = env.timer.planView!;
        expect((v.index, v.round, v.rounds), (0, 1, 2));
        expect(env.timer.displaySeconds, 120);
        expect(env.timer.displayFraction, 1.0);
      },
    );

    test(
      'Ungültiger Plan und Setzen während des Laufs werden ignoriert',
      () async {
        await env.timer.setPlan(
          const SessionPlan([PlanStep(StepKind.pause, 60000)]),
        );
        expect(env.timer.plan, isNull);
        await env.timer.setPlan(plan3());
        await env.timer.start();
        await env.timer.setPlan(null);
        expect(env.timer.plan, isNotNull);
      },
    );

    test('Start plant eine Benachrichtigung je Phasengrenze', () async {
      await env.timer.setPlan(plan3());
      await env.timer.start();
      final t0 = env.clock.wallMs();
      expect(env.notes.scheduled[4712], t0 + 120000, reason: 'Pause beginnt');
      expect(env.notes.scheduled[4713], t0 + 180000, reason: 'Weiter geht’s');
      expect(env.notes.scheduled[4711], t0 + 300000, reason: 'Ende');
      expect(env.notes.titles[4712], 'Zeit für eine Pause!');
      expect(env.notes.titles[4713], 'Weiter geht’s!');
      expect(env.notes.titles[4711], 'Die Zeit ist um!');
    });

    test(
      'Pause storniert alle, Fortsetzen plant nur noch kommende Grenzen',
      () async {
        await env.timer.setPlan(plan3());
        await env.timer.start();
        env.clock.advance(const Duration(seconds: 130)); // mitten in der Pause
        await env.timer.pause();
        expect(env.notes.scheduled, isEmpty);
        env.clock.advance(
          const Duration(minutes: 10),
        ); // Pause dauert die Uhr nicht
        await env.timer.resume();
        expect(env.notes.scheduled.keys.toSet(), {
          4713,
          4711,
        }, reason: 'Grenze 1 liegt in der Vergangenheit');
        expect(env.notes.scheduled[4711], env.clock.wallMs() + 170000);
        expect(env.timer.planView!.isPause, isTrue);
      },
    );

    test(
      'Phasenwechsel: sanfter Ton, Musik aus in der Pause, wieder an danach',
      () {
        fakeAsync((fa) {
          env.timer.setPlan(plan3());
          fa.flushMicrotasks();
          env.timer.start();
          fa.flushMicrotasks();
          expect(env.audio.log.where((e) => e.startsWith('music:')).length, 1);
          env.clock.advance(const Duration(seconds: 121));
          fa.elapse(const Duration(milliseconds: 300));
          fa.flushMicrotasks();
          expect(env.timer.planView!.isPause, isTrue);
          expect(env.audio.log.where((e) => e.startsWith('alarm:')).length, 1);
          expect(env.audio.log, contains('fade'));
          env.audio.log.clear();
          env.clock.advance(const Duration(seconds: 60));
          fa.elapse(const Duration(milliseconds: 300));
          fa.flushMicrotasks();
          expect(env.timer.planView!.index, 2);
          expect(env.audio.log.where((e) => e.startsWith('alarm:')).length, 1);
          expect(
            env.audio.log.where((e) => e.startsWith('music:')).length,
            1,
            reason: 'Musik startet nach der Pause neu',
          );
        });
      },
    );

    test('Ende des Plans: ein Abschlussalarm, Zustand „Geschafft“', () {
      fakeAsync((fa) {
        env.timer.setPlan(plan3());
        fa.flushMicrotasks();
        env.timer.start();
        fa.flushMicrotasks();
        env.clock.advance(const Duration(minutes: 6));
        fa.elapse(const Duration(milliseconds: 300));
        fa.flushMicrotasks();
        expect(env.timer.status, TimerStatus.finished);
        expect(env.timer.planView!.finished, isTrue);
        expect(env.timer.displaySeconds, 0);
        expect(
          env.audio.log.where((e) => e.startsWith('alarm:')).length,
          1,
          reason: 'kein zusätzlicher Phasenwechsel-Ton am Ende',
        );
      });
    });

    test('Wiederherstellung nach Neustart mitten im Plan (Pause), Musik startet nicht', () async {
      await env.timer.setPlan(plan3());
      await env.timer.start();
      env.clock.advance(const Duration(seconds: 100));
      await env.timer.pause();
      // Prozessende; später weiter – pausierter Zustand bleibt exakt erhalten
      final env2 = TestEnv();
      env2.prefs.data.addAll(env.prefs.data);
      env2.settings
        ..plan = plan3()
        ..appleMusic = null;
      await env2.timer.init();
      expect(env2.timer.status, TimerStatus.paused);
      expect(env2.timer.planView!.index, 0);
      expect(env2.timer.displaySeconds, 20);
      env2.timer.dispose();
    });

    test(
      'Laufender Plan wird nach Neustart in der richtigen Phase fortgesetzt',
      () async {
        await env.timer.setPlan(plan3());
        await env.timer.start();
        final snap = env.timer.engine.snapshot();
        // Prozessende; Neustart 135 s nach dem Start (15 s in der Pause)
        final env2 = TestEnv();
        env2.prefs.data.addAll(env.prefs.data);
        env2.settings.plan = plan3();
        env2.clock.jumpWall(
          Duration(
            milliseconds: snap.anchorWallMs + 135000 - env2.clock.wallMs(),
          ),
        );
        await env2.timer.init();
        expect(env2.timer.status, TimerStatus.running);
        final v = env2.timer.planView!;
        expect((v.index, v.isPause), (1, true));
        expect(v.stepRemainingMs, 45000);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          env2.audio.log.where((e) => e.startsWith('music:')),
          isEmpty,
          reason: 'in der Pause keine Musik',
        );
        env2.timer.dispose();
      },
    );

    test('Einzelzeit ersetzt den Plan; Plan entfernen stellt letzte Einzelzeit wieder her', () async {
      await env.timer.setDuration(const Duration(minutes: 7));
      await env.timer.setPlan(plan3());
      expect(env.timer.plan, isNotNull);
      await env.timer.setDuration(const Duration(minutes: 10));
      expect(env.timer.plan, isNull);
      expect(env.settings.plan, isNull);
      await env.timer.setPlan(plan3());
      await env.timer.setPlan(null);
      expect(env.timer.engine.totalMs, 10 * 60000);
    });

    test('Wiederholen wird bei einem Plan ignoriert', () async {
      await env.settings.update((s) => s.repeat = true);
      await env.timer.setPlan(plan3());
      await env.timer.start();
      expect(env.timer.engine.repeat, isFalse);
    });

    test(
      'Plan passt nicht zur gespeicherten Dauer → wird nicht angewandt',
      () async {
        env.settings.plan = plan3();
        await env.timer.setDuration(const Duration(minutes: 3)); // löscht Plan
        env.settings.plan =
            plan3(); // von außen wieder gesetzt, Engine hat 3 min
        expect(env.timer.plan, isNull);
        expect(env.timer.planView, isNull);
      },
    );
  });
}
