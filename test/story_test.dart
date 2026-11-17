import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/domain/timer_engine.dart';
import 'package:tinytakt/presentation/art/rig.dart';
import 'package:tinytakt/presentation/art/story/art_images.dart';
import 'package:tinytakt/presentation/art/story/meadow_path.dart';
import 'package:tinytakt/presentation/art/story/meadow_story.dart';
import 'package:tinytakt/presentation/art/story/mira_sprite.dart';
import 'package:tinytakt/presentation/art/story/story_scene.dart';
import 'package:tinytakt/presentation/screens/home_screen.dart';

import 'helpers.dart';

Future<ui.Image> decodeFile(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

Future<void> pumpFor(WidgetTester t, double seconds) async {
  for (var i = 0; i < (seconds * 10).round(); i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mira-Asset (echtes Alpha)', () {
    testWidgets('transparenter Hintergrund, kein eingebranntes Schachbrett', (
      t,
    ) async {
      await t.runAsync(() async {
        final img = await decodeFile(ArtImages.miraAsset);
        final data = (await img.toByteData())!;
        final w = img.width, h = img.height;
        int a(int x, int y) => data.getUint8((y * w + x) * 4 + 3);
        // Ecken sind wirklich durchsichtig
        for (final p in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]) {
          expect(a(p.$1, p.$2), 0, reason: 'Ecke ${p.$1},${p.$2}');
        }
        var transparent = 0, opaque = 0, neutralBright = 0;
        for (var i = 0; i < w * h; i++) {
          final r = data.getUint8(i * 4),
              g = data.getUint8(i * 4 + 1),
              b = data.getUint8(i * 4 + 2),
              al = data.getUint8(i * 4 + 3);
          if (al == 0) transparent++;
          if (al > 240) {
            opaque++;
            final chroma =
                [r, g, b].reduce((x, y) => x > y ? x : y) -
                [r, g, b].reduce((x, y) => x < y ? x : y);
            if (chroma <= 3 && r > 225) neutralBright++;
          }
        }
        expect(transparent / (w * h), inInclusiveRange(0.15, 0.6));
        expect(opaque / (w * h), greaterThan(0.3));
        // Fell-Glanzlichter sind neutral hell, aber klein; ein Schachbrett wären Blöcke.
        expect(neutralBright / opaque, lessThan(0.01));
        const blk = 12;
        var blocks = 0;
        for (var by = 0; by + blk <= h; by += blk) {
          for (var bx = 0; bx + blk <= w; bx += blk) {
            var all = true;
            for (var y = by; y < by + blk && all; y++) {
              for (var x = bx; x < bx + blk; x++) {
                final i = (y * w + x) * 4;
                final r = data.getUint8(i),
                    g = data.getUint8(i + 1),
                    b = data.getUint8(i + 2);
                final ch =
                    [r, g, b].reduce((p, q) => p > q ? p : q) -
                    [r, g, b].reduce((p, q) => p < q ? p : q);
                if (!(data.getUint8(i + 3) > 240 && ch <= 5 && r > 215)) {
                  all = false;
                  break;
                }
              }
            }
            if (all) blocks++;
          }
        }
        // Erlaubt: der große Augenglanzpunkt (1 Block); ein Schachbrett hätte Dutzende.
        expect(
          blocks,
          lessThanOrEqualTo(2),
          reason: 'zusammenhängende neutral-weiße Blöcke = Schachbrettreste',
        );
      });
    });

    testWidgets('Wiese lädt in Referenzgröße', (t) async {
      await t.runAsync(() async {
        final img = await decodeFile(ArtImages.meadowAsset);
        expect(
          Size(img.width.toDouble(), img.height.toDouble()),
          MeadowPath.imageSize,
        );
      });
    });
  });

  group('Weg und Geometrie', () {
    test('Weg läuft vom Start zur Haustür, Etappen liegen auf dem Weg', () {
      final p = MeadowPath.instance;
      expect(p.at(0), MeadowPath.control.first);
      expect((p.at(1) - MeadowPath.control.last).distance, lessThan(1));
      var prev = -1.0;
      for (final u in p.stationU) {
        expect(u, greaterThanOrEqualTo(prev));
        expect(u, inInclusiveRange(0.0, 1.0));
        prev = u;
      }
      for (var i = 0; i < MeadowPath.stones.length; i++) {
        final onPath = p.at(p.stationU[i]);
        expect(
          (onPath - MeadowPath.stones[i]).distance,
          lessThan(
            i == 0 ? 130 : 40,
          ), // Startstein liegt links neben dem Startpunkt
          reason: 'Stein $i',
        );
      }
      // Bogenlänge strikt gleichmäßig steigend → Fortschritt springt nie
      for (var i = 1; i < p.arc.length; i++) {
        expect(p.arc[i], greaterThanOrEqualTo(p.arc[i - 1]));
      }
    });

    test('Abbildung Bild→Bildschirm ist monoton und bleibt im Bild', () {
      for (final size in const [
        Size(360, 640),
        Size(393, 852),
        Size(430, 932),
      ]) {
        final g = StoryGeometry(size, pathBottomY: size.height * 0.52);
        var prev = -1.0;
        for (var y = 0.0; y <= 1312; y += 8) {
          final sy = g.ymap(y);
          expect(sy, greaterThan(prev));
          prev = sy;
        }
        for (final st in MeadowPath.stones) {
          final sp = g.toScreen(st);
          expect(sp.dx, inInclusiveRange(0, size.width));
          expect(sp.dy, inInclusiveRange(0, size.height));
        }
        expect(g.depthScale(436), closeTo(0.48, 1e-9));
        expect(g.depthScale(790), closeTo(1.0, 1e-9));
      }
    });
  });

  group('Mesh-Verformung', () {
    test('neutrale Pose lässt das Bild unverändert', () {
      final pose = Pose();
      for (final p in const [
        Offset(0.1, 0.1),
        Offset(0.5, 0.5),
        Offset(0.9, 0.9),
      ]) {
        final q = MiraMesh.deform(p, pose, 0, calm: true);
        expect((q - p).distance, lessThan(1e-9));
      }
    });

    test('Ohren und Schweif bewegen sich, Füße bleiben stehen', () {
      final pose = Pose()
        ..earL = 0.3
        ..earR = 0.3
        ..tail = 1;
      final ear = MiraMesh.deform(
        const Offset(0.12, 0.35),
        pose,
        0,
        calm: true,
      );
      final tail = MiraMesh.deform(
        const Offset(0.93, 0.78),
        pose,
        0,
        calm: true,
      );
      final foot = MiraMesh.deform(
        const Offset(0.35, 0.97),
        pose,
        0,
        calm: true,
      );
      expect((ear - const Offset(0.12, 0.35)).distance, greaterThan(0.01));
      expect((tail - const Offset(0.93, 0.78)).distance, greaterThan(0.01));
      expect((foot - const Offset(0.35, 0.97)).distance, lessThan(0.002));
    });

    test('alle Posen liefern endliche Verformungen', () {
      for (final e in Emotion.values) {
        for (var i = 0; i < 60; i++) {
          final pose = computePose(const Personality(), e, i * 0.1, i * 0.07);
          for (var u = 0.0; u <= 1; u += 0.1) {
            for (var v = 0.0; v <= 1; v += 0.1) {
              final q = MiraMesh.deform(Offset(u, v), pose, i * 0.1);
              expect(q.dx.isFinite && q.dy.isFinite, isTrue);
            }
          }
        }
      }
    });
  });

  group('Integration im Home-Bildschirm', () {
    Future<TestEnv> boot(
      WidgetTester t, {
      String character = 'nova_mira',
    }) async {
      setScreen(t, const Size(393, 852), dpr: 1);
      await t.runAsync(ArtImages.instance.ensureLoaded);
      final env = TestEnv(pro: true);
      await t.runAsync(env.init);
      await env.settings.updateProfile(
        (p) => p.copyWith(
          characterId: character,
          backgroundId: 'meadow',
          style: TimerStyle.adventure,
        ),
      );
      await env.timer.setDuration(const Duration(minutes: 10));
      await t.pumpWidget(wrap(env.deps, const HomeScreen()));
      await pumpFor(t, 0.5);
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

    testWidgets(
      'Mira + Wiese + Abenteuer zeigt Szene und Flutter-Fortschritt',
      (t) async {
        final env = await boot(t);
        expect(find.byType(StoryScene), findsOneWidget);
        expect(find.byType(StoryProgressBar), findsOneWidget);
        expect(find.text('10:00'), findsOneWidget); // Zeit bleibt echter Text
        expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
        await done(t, env);
      },
    );

    testWidgets(
      'Fortschritt steuert den Weg; Pause friert ein; Stopp setzt zurück',
      (t) async {
        final env = await boot(t);
        expect(progress(t), 0);
        await env.timer.start();
        await env.timer
            .start(); // zweiter Aufruf ist wirkungslos (läuft bereits)
        await pumpFor(t, 4); // 3-2-1-Countdown ist standardmäßig aus
        env.clock.advance(const Duration(minutes: 4));
        await pumpFor(t, 0.5);
        expect(progress(t), closeTo(0.4, 0.05));
        await env.timer.pause();
        await pumpFor(t, 0.3);
        final frozen = progress(t);
        env.clock.advance(const Duration(minutes: 3));
        await pumpFor(t, 0.5);
        expect(progress(t), closeTo(frozen, 1e-9));
        await env.timer.resume();
        env.clock.advance(const Duration(minutes: 6));
        await pumpFor(t, 1);
        expect(env.timer.status, TimerStatus.finished);
        expect(progress(t), closeTo(1.0, 1e-9));
        await env.timer.stop();
        await pumpFor(t, 0.5);
        expect(progress(t), 0);
        await done(t, env);
      },
    );

    testWidgets('andere Figur nutzt weiterhin die bisherige Bühne', (t) async {
      final env = await boot(t, character: 'dog');
      expect(find.byType(StoryScene), findsNothing);
      expect(find.byType(StoryProgressBar), findsNothing);
      await done(t, env);
    });

    testWidgets('ohne geladene Bilder: sauberer Fallback', (t) async {
      setScreen(t, const Size(393, 852), dpr: 1);
      final saved = (ArtImages.instance.mira, ArtImages.instance.meadow);
      ArtImages.instance.setForTest(mira: null, meadow: null);
      final env = TestEnv(pro: true);
      await t.runAsync(env.init);
      await env.settings.updateProfile(
        (p) => p.copyWith(
          characterId: 'nova_mira',
          backgroundId: 'meadow',
          style: TimerStyle.adventure,
        ),
      );
      await t.pumpWidget(wrap(env.deps, const HomeScreen()));
      await pumpFor(t, 0.3);
      expect(find.byType(StoryScene), findsNothing);
      expect(find.text('05:00'), findsOneWidget);
      ArtImages.instance.setForTest(mira: saved.$1, meadow: saved.$2);
      await done(t, env);
    });
  });
}
