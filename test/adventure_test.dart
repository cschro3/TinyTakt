import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/domain/timer_engine.dart';
import 'package:tinytakt/presentation/art/adventure/adventure_scene.dart';
import 'package:tinytakt/presentation/art/adventure/adventure_spec.dart';
import 'package:tinytakt/presentation/art/adventure/adventure_worlds.dart';
import 'package:tinytakt/presentation/art/story/art_images.dart';
import 'package:tinytakt/presentation/art/visual/figure_frames.dart';
import 'package:tinytakt/presentation/painters/character_painter.dart'
    show Mood;
import 'package:tinytakt/presentation/art/story/story_scene.dart';
import 'package:tinytakt/presentation/art/visual/visual_registry.dart';
import 'package:tinytakt/presentation/screens/home_screen.dart';

import 'helpers.dart';

Future<void> pumpFor(WidgetTester t, double seconds) async {
  for (var i = 0; i < (seconds * 10).round(); i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  figureFrameTests();
  group('Adventure-Framework (Daten)', () {
    test('jede Welt außer der Wiese hat ein eigenes Abenteuer; IDs passen zum Katalog', () {
      for (final b in backgrounds) {
        if (b.id == 'meadow') {
          expect(adventureWorlds.containsKey('meadow'), isFalse);
          expect(VisualRegistry.world('meadow').storyRoute, isTrue);
        } else {
          expect(adventureWorlds[b.id], isNotNull, reason: b.id);
          expect(adventureWorlds[b.id]!.id, b.id);
        }
      }
    });

    test('Wege sind eigenständig (keine zwei Welten mit gleicher Route) und plausibel', () {
      final seen = <String>{};
      for (final w in adventureWorlds.values) {
        expect(w.control.length, greaterThanOrEqualTo(6), reason: w.id);
        expect(
          seen.add(w.control.map((o) => '${o.dx},${o.dy}').join(';')),
          isTrue,
          reason: '${w.id} Route doppelt',
        );
        for (final o in w.control) {
          expect(o.dx, inInclusiveRange(0.0, 1.0));
          expect(o.dy, inInclusiveRange(0.0, 1.0));
        }
        expect(w.stations.first, 0);
        expect(w.stations.last, 1);
        for (var i = 1; i < w.stations.length; i++) {
          expect(w.stations[i], greaterThan(w.stations[i - 1]));
        }
        expect(w.goalDe, isNotEmpty);
        expect(w.goalEn, isNotEmpty);
        expect(w.scaleFar, lessThan(w.scaleNear));
      }
      expect(adventureWorlds.length, 8);
    });

    test(
      'Weggeometrie: Start/Ziel exakt, Fortschritt monoton, kein Springen',
      () {
        for (final w in adventureWorlds.values) {
          final f = AdvFrame(
            const Size(393, 852),
            const Rect.fromLTWH(10, 100, 373, 373),
            w.control,
          );
          expect(
            (f.at(0) - f.p(w.control.first.dx, w.control.first.dy)).distance,
            lessThan(0.01),
          );
          expect(
            (f.at(1) - f.p(w.control.last.dx, w.control.last.dy)).distance,
            lessThan(0.01),
          );
          var prev = f.at(0);
          var travelled = 0.0;
          for (var i = 1; i <= 200; i++) {
            final p = f.at(i / 200);
            final step = (p - prev).distance;
            expect(
              step,
              lessThan(f.s * 0.08),
              reason: '${w.id}: Sprung bei $i',
            );
            travelled += step;
            prev = p;
          }
          expect(
            travelled,
            greaterThan(f.s * 0.8),
            reason: '${w.id} Weg zu kurz',
          );
          // Außerhalb 0…1 wird begrenzt
          expect(f.at(-1), f.at(0));
          expect(f.at(2), f.at(1));
        }
      },
    );

    test(
      'Registry: Abenteuer-Szene für alle Figuren in allen Welten außer Wiese',
      () {
        for (final c in characters) {
          for (final b in backgrounds) {
            final r = VisualRegistry.recipe(c.id, b.id, TimerStyle.adventure);
            if (b.id == 'meadow') {
              expect(r.fullScreenStory, isTrue);
              expect(r.adventureWorld, isNull);
            } else {
              expect(r.adventureWorld?.id, b.id, reason: '${c.id}/${b.id}');
              expect(r.fullScreenStory, isFalse);
            }
            expect(
              VisualRegistry.recipe(
                c.id,
                b.id,
                TimerStyle.circle,
              ).adventureWorld,
              isNull,
              reason: 'nur Abenteuer-Stil nutzt die Szene',
            );
          }
        }
      },
    );
  });

  group('Adventure im Home-Bildschirm', () {
    Future<TestEnv> boot(
      WidgetTester t, {
      required String character,
      required String world,
      TimerStyle style = TimerStyle.adventure,
    }) async {
      setScreen(t, const Size(393, 852), dpr: 1);
      await t.runAsync(ArtImages.instance.ensureLoaded);
      final env = TestEnv(pro: true);
      await t.runAsync(env.init);
      await env.settings.updateProfile(
        (p) => p.copyWith(
          characterId: character,
          backgroundId: world,
          style: style,
        ),
      );
      await env.timer.setDuration(const Duration(minutes: 10));
      await t.pumpWidget(wrap(env.deps, const HomeScreen()));
      await pumpFor(t, 0.6);
      return env;
    }

    Future<void> done(WidgetTester t, TestEnv env) async {
      await env.timer.stop();
      await t.pumpWidget(const SizedBox());
      env.timer.dispose();
    }

    double progress(WidgetTester t) {
      final bar = t.widget<StoryProgressBar>(find.byType(StoryProgressBar));
      return (bar.progress as ValueNotifier<double>).value;
    }

    for (final w in adventureWorlds.keys) {
      for (final ch in const ['dog', 'nova_mira', 'lion']) {
        testWidgets(
          '$ch + $w: eigene Abenteuerszene, Fortschritt, Pause, Abschluss',
          (t) async {
            final env = await boot(t, character: ch, world: w);
            expect(find.byType(AdventureScene), findsOneWidget);
            expect(find.byType(StoryScene), findsNothing);
            expect(find.byType(StoryProgressBar), findsOneWidget);
            expect(find.text('10:00'), findsOneWidget);
            expect(progress(t), 0);
            await env.timer.start();
            await pumpFor(t, 0.5);
            env.clock.advance(const Duration(minutes: 5));
            await pumpFor(t, 0.5);
            expect(progress(t), closeTo(0.5, 0.05));
            await env.timer.pause();
            await pumpFor(t, 0.3);
            final frozen = progress(t);
            env.clock.advance(const Duration(minutes: 2));
            await pumpFor(t, 0.5);
            expect(
              progress(t),
              closeTo(frozen, 1e-9),
              reason: 'Pause: kein Springen',
            );
            await env.timer.resume();
            await pumpFor(t, 0.3);
            expect(
              progress(t),
              closeTo(frozen, 0.02),
              reason: 'Fortsetzen: gleiche Position',
            );
            env.clock.advance(const Duration(minutes: 6));
            await pumpFor(t, 1.2);
            expect(env.timer.status, TimerStatus.finished);
            expect(progress(t), closeTo(1.0, 1e-9));
            await pumpFor(t, 1.0); // Jubel läuft ohne Fehler
            await env.timer.stop();
            await pumpFor(t, 0.4);
            expect(progress(t), 0, reason: 'Neustart: zurück am Anfang');
            await done(t, env);
          },
        );
      }
    }

    testWidgets(
      'Figur wechseln ändert die Welt nicht, Welt wechseln ändert die Figur nicht',
      (t) async {
        final env = await boot(t, character: 'dog', world: 'space');
        final sceneA = t.widget<AdventureScene>(find.byType(AdventureScene));
        expect(sceneA.world.id, 'space');
        expect(sceneA.spec!.id, 'dog');
        await env.settings.updateProfile((p) => p.copyWith(characterId: 'cat'));
        await pumpFor(t, 0.4);
        final sceneB = t.widget<AdventureScene>(find.byType(AdventureScene));
        expect(sceneB.world.id, 'space');
        expect(sceneB.spec!.id, 'cat');
        await env.settings.updateProfile(
          (p) => p.copyWith(backgroundId: 'forest'),
        );
        await pumpFor(t, 0.4);
        final sceneC = t.widget<AdventureScene>(find.byType(AdventureScene));
        expect(sceneC.world.id, 'forest');
        expect(sceneC.spec!.id, 'cat');
        await done(t, env);
      },
    );

    testWidgets(
      'Wiese bleibt die gemalte Story-Szene, andere Stile nutzen keine Abenteuerszene',
      (t) async {
        var env = await boot(t, character: 'bunny', world: 'meadow');
        expect(find.byType(StoryScene), findsOneWidget);
        expect(find.byType(AdventureScene), findsNothing);
        await done(t, env);
        env = await boot(
          t,
          character: 'bunny',
          world: 'night',
          style: TimerStyle.circle,
        );
        expect(find.byType(AdventureScene), findsNothing);
        expect(find.byType(StoryScene), findsNothing);
        expect(find.text('10:00'), findsOneWidget);
        await done(t, env);
      },
    );

    testWidgets('Ruhiger Modus: Abenteuerszene rendert ohne Fehler', (t) async {
      setScreen(t, const Size(393, 852), dpr: 1);
      final env = TestEnv(pro: true);
      await t.runAsync(env.init);
      await env.settings.update((x) => x.calmMode = true);
      await env.settings.updateProfile(
        (p) => p.copyWith(
          characterId: 'pig',
          backgroundId: 'underwater',
          style: TimerStyle.adventure,
        ),
      );
      await t.pumpWidget(wrap(env.deps, const HomeScreen()));
      await pumpFor(t, 0.8);
      expect(find.byType(AdventureScene), findsOneWidget);
      await done(t, env);
    });
  });
}

// ---- gebackene Figuren-Frames ----
void figureFrameTests() {
  group('FigureFrames (Leistung)', () {
    test('backt höchstens einen Frame je Aufruf, spielt danach nur Bilder und bleibt im Speicherlimit', () {
      final ff = FigureFrames.instance..clear();
      final spec = characters.firstWhere((c) => c.id == 'dog');
      final rec = PictureRecorder();
      final canvas = Canvas(rec);
      const rect = Rect.fromLTWH(0, 0, 120, 120);
      final b0 = ff.bakes;
      expect(
        ff.paint(
          canvas,
          spec,
          rect,
          t: 0,
          mood: Mood.active,
          calm: false,
          dpr: 2,
        ),
        isTrue,
      );
      expect(ff.bakes - b0, 1);
      // gleiche Zeit nochmal → kein weiteres Backen
      ff.paint(
        canvas,
        spec,
        rect,
        t: 0.01,
        mood: Mood.active,
        calm: false,
        dpr: 2,
      );
      expect(ff.bakes - b0, 1);
      // eine ganze Schleife: höchstens frameCount Frames
      for (var i = 0; i < 100; i++) {
        ff.paint(
          canvas,
          spec,
          rect,
          t: i * 0.05,
          mood: Mood.active,
          calm: false,
          dpr: 2,
        );
      }
      expect(ff.bakes - b0, FigureFrames.frameCount);
      final steady = ff.bakes;
      for (var i = 0; i < 100; i++) {
        ff.paint(
          canvas,
          spec,
          rect,
          t: i * 0.033,
          mood: Mood.active,
          calm: false,
          dpr: 2,
        );
      }
      expect(ff.bakes, steady, reason: 'danach nur noch Bilder');
      // viele Figuren: Speicher bleibt begrenzt
      for (final c in characters.take(40)) {
        for (final m in [Mood.idle, Mood.active, Mood.happy]) {
          for (var i = 0; i < FigureFrames.frameCount; i++) {
            ff.paint(canvas, c, rect, t: i * 0.2, mood: m, calm: false, dpr: 3);
          }
        }
      }
      expect(ff.bytes, lessThanOrEqualTo(FigureFrames.maxBytes + 4 * 1048576));
      ff.clear();
    });
  });
}
