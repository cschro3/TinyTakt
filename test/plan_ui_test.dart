import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/session_plan.dart';
import 'package:tinytakt/domain/timer_engine.dart';
import 'package:tinytakt/presentation/screens/home_screen.dart';

import 'helpers.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<TestEnv> boot(
  WidgetTester t, {
  Size size = const Size(412, 915),
  double scale = 1.0,
  Locale locale = const Locale('de'),
}) async {
  setScreen(t, size);
  final env = TestEnv();
  await t.runAsync(env.init);
  await t.pumpWidget(
    wrap(env.deps, const HomeScreen(), textScale: scale, locale: locale),
  );
  await settle(t);
  return env;
}

Future<void> end(WidgetTester t, TestEnv env) async {
  await env.timer.stop();
  await t.pumpWidget(const SizedBox());
  env.timer.dispose();
}

void main() {
  testWidgets(
    'Zeit-Dialog: Vorlage wählen, Plan übernehmen → Hauptbildschirm zeigt Plan',
    (t) async {
      final env = await boot(t);
      await t.tap(find.bySemanticsLabel('Zeit ändern'));
      await settle(t);
      await t.tap(find.text('Lernen & Pausen'));
      await settle(t);
      expect(find.text('Arbeiten'), findsOneWidget);
      expect(find.text('Runden'), findsOneWidget);
      await t.tap(find.textContaining('Hausaufgaben'));
      await settle(t);
      expect(
        find.textContaining('3 × 15 Min. + 2 × 5 Min. Pause = 55 Min.'),
        findsOneWidget,
      );
      await t.tap(find.text('Plan übernehmen'));
      await settle(t);
      expect(env.timer.plan?.totalMs, 55 * 60000);
      expect(find.text('Lernen & Pausen · 3 Runden'), findsOneWidget);
      expect(find.text('15:00'), findsOneWidget);
      expect(find.byTooltip('Plan entfernen'), findsOneWidget);
      expect(
        find.bySemanticsLabel('10 Minuten'),
        findsNothing,
        reason: 'Schnellwahl ist mit Plan ausgeblendet',
      );
      await end(t, env);
    },
  );

  testWidgets(
    'Stepper ändern Arbeit, Pause und Runden; Grenzen werden eingehalten',
    (t) async {
      final env = await boot(t);
      await t.tap(find.bySemanticsLabel('Zeit ändern'));
      await settle(t);
      await t.tap(find.text('Lernen & Pausen'));
      await settle(t);
      await t.tap(find.byTooltip('Mehr: Runden'));
      await t.pump();
      await t.tap(find.byTooltip('Mehr: Arbeiten'));
      await t.pump();
      await settle(t);
      expect(find.textContaining('4 × 20 Min.'), findsOneWidget);
      for (var i = 0; i < 12; i++) {
        await t.tap(find.byTooltip('Mehr: Runden'), warnIfMissed: false);
        await t.pump();
      }
      await settle(t);
      expect(find.text('8'), findsOneWidget);
      for (var i = 0; i < 12; i++) {
        await t.tap(find.byTooltip('Weniger: Pause'), warnIfMissed: false);
        await t.pump();
      }
      await settle(t);
      expect(find.text('keine'), findsOneWidget);
      await t.tap(find.text('Plan übernehmen'));
      await settle(t);
      expect(
        env.timer.plan!.steps.every((s) => s.kind == StepKind.focus),
        isTrue,
        reason: 'ohne Pausenzeit nur Arbeitsphasen',
      );
      expect(env.timer.plan!.rounds, 8);
      await end(t, env);
    },
  );

  testWidgets(
    'Lauf: Runde 1 von 3 → Pause → Runde 2 (Beschriftung, Leiste, Figur)',
    (t) async {
      final env = await boot(t);
      await env.timer.setPlan(
        SessionPlan.rounds(focusMin: 2, pauseMin: 1, rounds: 3),
      );
      await settle(t);
      await t.tap(find.bySemanticsLabel('Start'));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Runde 1 von 3'), findsOneWidget);
      expect(find.text('02:00'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('Plan: Runde 1 von 3, Arbeitsphase läuft'),
        ),
        findsOneWidget,
      );
      env.clock.advance(const Duration(seconds: 150)); // 30 s in der Pause
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Pause'), findsWidgets);
      expect(find.text('00:30'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Pause läuft')), findsOneWidget);
      env.clock.advance(const Duration(seconds: 45)); // Runde 2, 15 s
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Runde 2 von 3'), findsOneWidget);
      expect(find.text('01:45'), findsOneWidget);
      await end(t, env);
    },
  );

  testWidgets(
    'Angehalten zeigt Phase; Ende zeigt „Geschafft!“ und Plan bleibt für „Noch einmal“',
    (t) async {
      final env = await boot(t);
      await env.timer.setPlan(
        SessionPlan.rounds(focusMin: 1, pauseMin: 1, rounds: 2),
      );
      await settle(t);
      await t.tap(find.bySemanticsLabel('Start'));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.bySemanticsLabel('Pause'));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Angehalten · Runde 1 von 2'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Weiter'));
      await t.pump(const Duration(milliseconds: 400));
      env.clock.advance(const Duration(minutes: 4));
      await t.pump(const Duration(milliseconds: 600));
      expect(env.timer.status, TimerStatus.finished);
      expect(find.text('Geschafft!'), findsWidgets);
      await t.tap(find.bySemanticsLabel('Noch einmal'));
      await t.pump(const Duration(milliseconds: 600));
      expect(env.timer.status, TimerStatus.running);
      expect(find.text('Runde 1 von 2'), findsOneWidget);
      await end(t, env);
    },
  );

  testWidgets(
    'Plan entfernen über das Chip stellt die Schnellwahl wieder her',
    (t) async {
      final env = await boot(t);
      await env.timer.setPlan(
        SessionPlan.rounds(focusMin: 5, pauseMin: 1, rounds: 2),
      );
      await settle(t);
      await t.tap(find.byTooltip('Plan entfernen'));
      await settle(t);
      expect(env.timer.plan, isNull);
      expect(find.bySemanticsLabel('10 Minuten'), findsOneWidget);
      await end(t, env);
    },
  );

  testWidgets('Englisch: Beschriftungen lokalisiert', (t) async {
    final env = await boot(t, locale: const Locale('en'));
    await env.timer.setPlan(
      SessionPlan.rounds(focusMin: 2, pauseMin: 1, rounds: 2),
    );
    await settle(t);
    expect(find.text('Study & breaks · 2 rounds'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Start'));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Round 1 of 2'), findsOneWidget);
    await end(t, env);
  });

  group('Layout mit Plan (8 Runden, größte Schrift)', () {
    final sizes = {
      'iPhone SE': const Size(320, 568),
      'Pixel': const Size(412, 915),
      'iPad quer': const Size(1180, 820),
      'Handy quer': const Size(844, 390),
    };
    for (final e in sizes.entries) {
      testWidgets('Kein Überlauf: ${e.key}', (t) async {
        for (final scale in [1.0, 2.0]) {
          final env = await boot(t, size: e.value, scale: scale);
          await env.timer.setPlan(
            SessionPlan.rounds(focusMin: 15, pauseMin: 5, rounds: 8),
          );
          await settle(t);
          expect(t.takeException(), isNull, reason: '${e.key} @ $scale idle');
          await t.tap(find.bySemanticsLabel('Start'));
          await t.pump(const Duration(milliseconds: 400));
          env.clock.advance(const Duration(minutes: 16)); // in der Pause
          await t.pump(const Duration(milliseconds: 600));
          expect(t.takeException(), isNull, reason: '${e.key} @ $scale Pause');
          await end(t, env);
        }
      });
    }

    testWidgets(
      'Zeit-Dialog ohne Überlauf auf kleinem Gerät mit großer Schrift',
      (t) async {
        final env = await boot(t, size: const Size(320, 568), scale: 2.0);
        await t.tap(find.bySemanticsLabel('Zeit ändern'));
        await settle(t);
        await t.tap(find.text('Lernen & Pausen'));
        await settle(t);
        expect(t.takeException(), isNull);
        await end(t, env);
      },
    );
  });
}
