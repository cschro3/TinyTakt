import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/art/celebration.dart';
import 'package:tinytakt/presentation/art/figures/registry.dart';
import 'package:tinytakt/presentation/art/rig.dart';
import 'package:tinytakt/presentation/art/worlds/registry.dart';
import 'package:tinytakt/presentation/painters/timer_painters.dart';
import 'package:tinytakt/presentation/widgets/timer_stage.dart';

import 'helpers.dart';

Future<ui.Image> render(void Function(Canvas c, Size s) draw, Size size) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  draw(c, size);
  return rec.endRecording().toImage(size.width.round(), size.height.round());
}

/// Anteil Pixel mit Grün-Überhang (Wasser/Teal-Bogen).
Future<double> tealShare(ui.Image img) async {
  final data = (await img.toByteData())!;
  var n = 0;
  for (var i = 0; i < data.lengthInBytes; i += 4) {
    if (data.getUint8(i + 1) > data.getUint8(i) + 60 &&
        data.getUint8(i + 3) > 200) {
      n++;
    }
  }
  return n / (img.width * img.height);
}

Future<double> coverage(ui.Image img) async {
  final data = (await img.toByteData())!;
  var opaque = 0;
  for (var i = 3; i < data.lengthInBytes; i += 4) {
    if (data.getUint8(i) > 8) opaque++;
  }
  return opaque / (img.width * img.height);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Rig und Animation', () {
    const p = Personality();
    test('ruhiger Modus liefert eine statische Pose', () {
      final a = computePose(p, Emotion.celebrate, 1.0, 0.5, calm: true);
      final b = computePose(p, Emotion.celebrate, 7.3, 3.1, calm: true);
      expect(a.bodyDy, b.bodyDy);
      expect(a.breath, b.breath);
      expect(a.sparkle, 0);
    });

    test('Atmung schwingt, Blinzeln tritt auf', () {
      final breaths = {
        for (var i = 0; i < 40; i++)
          computePose(p, Emotion.calm, i * 0.1, 99).breath.toStringAsFixed(3),
      };
      expect(breaths.length, greaterThan(10));
      var blinked = false;
      for (var i = 0; i < 2000; i++) {
        if (computePose(p, Emotion.calm, i * 0.01, 99).blink > 0.5) {
          blinked = true;
          break;
        }
      }
      expect(blinked, isTrue);
    });

    test('Feiern hüpft und beruhigt sich wieder', () {
      var maxHop = 0.0;
      for (var i = 0; i < 100; i++) {
        maxHop = math.max(
          maxHop,
          computePose(
            p,
            Emotion.celebrate,
            10 + i * 0.03,
            i * 0.03,
          ).bodyDy.abs(),
        );
      }
      expect(maxHop, greaterThan(0.01));
      // nach dem Jubel bleibt nur ein sanftes Weiterhüpfen (≤ 35 % der Spitze)
      var late = 0.0;
      for (var i = 0; i < 100; i++) {
        late = math.max(
          late,
          computePose(
            p,
            Emotion.celebrate,
            30 + i * 0.03,
            9 + i * 0.03,
          ).bodyDy.abs(),
        );
      }
      expect(late, lessThan(maxHop * 0.35));
      expect(late, greaterThan(0));
    });

    test('alle Posen sind endlich (jede Emotion, viele Zeitpunkte)', () {
      for (final e in Emotion.values) {
        for (var i = 0; i < 300; i++) {
          final q = computePose(p, e, i * 0.07, i * 0.05);
          for (final v in [
            q.breath, q.blink, q.look.dx, q.look.dy, q.headTilt, q.headDy, //
            q.bodyDy, q.squash, q.lean, q.earL, q.earR, q.tail, q.armL, q.armR,
            q.cheek, q.glow, q.sparkle,
          ]) {
            expect(v.isFinite, isTrue, reason: '$e @ $i');
          }
        }
      }
    });
  });

  group('Premium-Figuren', () {
    const ids = [
      'nova_lumi', 'nova_zeno', 'nova_mira', 'dog', 'cat', 'bunny', //
      'hamster', 'parrot', 'cow', 'pig', 'sheep',
    ];
    test('alle angeforderten Figuren sind registriert und im Katalog', () {
      expect(premiumFigures.keys.toSet(), containsAll(ids));
      for (final id in ids) {
        expect(characters.any((c) => c.id == id), isTrue, reason: id);
      }
    });

    testWidgets('jede Figur × jede Emotion zeichnet sichtbar und ohne Fehler', (
      t,
    ) async {
      await t.runAsync(() async {
        for (final id in ids) {
          final fig = premiumFigures[id]!;
          for (final e in Emotion.values) {
            final pose = computePose(fig.personality, e, 1.3, 0.8);
            final img = await render((c, s) {
              c.translate(s.width / 2, s.height / 2);
              c.scale(s.width / 2);
              fig.paint(c, pose, 1.3);
            }, const Size(160, 160));
            final cov = await coverage(img);
            expect(cov, greaterThan(0.12), reason: '$id/$e zu leer ($cov)');
            expect(cov, lessThan(0.95), reason: '$id/$e füllt alles ($cov)');
          }
        }
      });
    });

    testWidgets('Figuren sind visuell unterscheidbar (Silhouetten)', (t) async {
      await t.runAsync(() async {
        final sil = <String, List<bool>>{};
        for (final id in ids) {
          final fig = premiumFigures[id]!;
          final img = await render((c, s) {
            c.translate(s.width / 2, s.height / 2);
            c.scale(s.width / 2);
            fig.paint(c, computePose(fig.personality, Emotion.calm, 0, 0), 0);
          }, const Size(48, 48));
          final d = (await img.toByteData())!;
          sil[id] = [
            for (var i = 3; i < d.lengthInBytes; i += 4) d.getUint8(i) > 128,
          ];
        }
        for (var i = 0; i < ids.length; i++) {
          for (var j = i + 1; j < ids.length; j++) {
            final a = sil[ids[i]]!, b = sil[ids[j]]!;
            var diff = 0;
            for (var k = 0; k < a.length; k++) {
              if (a[k] != b[k]) diff++;
            }
            expect(
              diff / a.length,
              greaterThan(0.02),
              reason: '${ids[i]} ≈ ${ids[j]}',
            );
          }
        }
      });
    });
  });

  group('Welten', () {
    test('alle neun Welten haben Premium-Malerei und sind im Katalog', () {
      for (final b in backgrounds) {
        expect(premiumWorlds.containsKey(b.id), isTrue, reason: b.id);
      }
    });

    testWidgets('jede Welt deckt die Fläche voll ab (Phone, Tablet, quer)', (
      t,
    ) async {
      await t.runAsync(() async {
        for (final w in premiumWorlds.values) {
          for (final size in const [
            Size(360, 640),
            Size(430, 932),
            Size(1024, 768),
          ]) {
            for (final calm in [false, true]) {
              final img = await render(
                (c, s) => w.paint(c, s, 3.7, calm),
                size,
              );
              final cov = await coverage(img);
              expect(cov, greaterThan(0.99), reason: '${w.id} $size');
            }
          }
        }
      });
    });
  });

  group('Abenteuer-Timer', () {
    test('Weg steigt monoton zum Ziel, Maßstab nimmt ab, bleibt im Bild', () {
      const size = Size(400, 400);
      const tr = AdventureTrack(size);
      var prev = tr.at(0);
      for (var i = 1; i <= 100; i++) {
        final u = i / 100;
        final p = tr.at(u);
        expect(p.dy, lessThan(prev.dy + 1e-6));
        expect(p.dx, inInclusiveRange(0, size.width));
        expect(p.dy, inInclusiveRange(0, size.height));
        expect(tr.scaleAt(u), lessThanOrEqualTo(tr.scaleAt(u - 0.01)));
        prev = p;
      }
    });

    testWidgets('jede Szenerie und jeder Fortschritt zeichnet ohne Fehler', (
      t,
    ) async {
      await t.runAsync(() async {
        for (final sc in Scenery.values) {
          for (final f in [1.0, 0.5, 0.0]) {
            final img = await render(
              (c, s) => AdventurePainter(
                fraction: f,
                t: 2,
                calm: false,
                theme: AdventureTheme.forScenery(sc),
              ).paint(c, s),
              const Size(300, 300),
            );
            expect(await coverage(img), greaterThan(0.3), reason: '$sc $f');
          }
        }
      });
    });
  });

  group('Klassische Timer-Stile', () {
    testWidgets('Ring, Glas, Regenbogen, Sanduhr: Fortschritt ist sichtbar', (
      t,
    ) async {
      await t.runAsync(() async {
        const s = Size(300, 300);
        Future<double> cov(CustomPainter p) async =>
            coverage(await render((c, sz) => p.paint(c, sz), s));
        final ringFull = await cov(
          RingPainter(fraction: 1, color: Colors.teal),
        );
        final ringHalf = await cov(
          RingPainter(fraction: 0.5, color: Colors.teal),
        );
        expect(ringFull, isNot(closeTo(ringHalf, 1e-9)));
        Future<double> water(double f) async => tealShare(
          await render(
            (c, sz) => FillPainter(
              fraction: f,
              t: 0,
              color: const Color(0xFF2FC4A8),
            ).paint(c, sz),
            s,
          ),
        );
        final fillFull = await water(1);
        final fillLow = await water(0.1);
        expect(fillFull, greaterThan(fillLow));
        final rbFull = await cov(RainbowPainter(fraction: 1));
        final rbLow = await cov(RainbowPainter(fraction: 0.2));
        expect(rbFull, greaterThan(rbLow));
        final hgStart = await cov(HourglassPainter(fraction: 1, t: 0));
        final hgEnd = await cov(HourglassPainter(fraction: 0.0, t: 0));
        expect(
          hgStart,
          closeTo(hgEnd, 0.1),
        ); // gleiche Silhouette, anderer Sand
      });
    });
  });

  group('Feier und Regie', () {
    testWidgets('Konfetti verblasst nach der Dauer', (t) async {
      await t.runAsync(() async {
        final during = await coverage(
          await render(
            (c, s) => CelebrationPainter(et: 0.8).paint(c, s),
            const Size(200, 200),
          ),
        );
        final after = await coverage(
          await render(
            (c, s) =>
                CelebrationPainter(et: CelebrationPainter.duration + 0.5)
                    .paint(c, s),
            const Size(200, 200),
          ),
        );
        expect(during, greaterThan(0.005));
        expect(after, lessThan(during));
      });
    });

    testWidgets('Bühne zeigt beim Ende die Feier, im ruhigen Modus nicht', (
      t,
    ) async {
      for (final calm in [false, true]) {
        setScreen(t, const Size(390, 844), dpr: 1);
        final env = TestEnv(pro: true);
        await t.runAsync(env.init);
        await env.timer.setDuration(const Duration(minutes: 1));
        await env.timer.start();
        await t.pumpWidget(
          wrap(
            env.deps,
            Scaffold(
              body: TimerStage(
                engine: env.timer.engine,
                style: TimerStyle.adventure,
                motif: Motif.character(characterById('nova_lumi')),
                calm: calm,
              ),
            ),
          ),
        );
        for (var i = 0; i < 5; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        env.clock.advance(const Duration(minutes: 1, seconds: 1));
        env.timer.engine.tick();
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        final celebrating = find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is CelebrationPainter,
        );
        expect(
          celebrating,
          calm ? findsNothing : findsOneWidget,
          reason: 'calm=$calm',
        );
        await t.pumpWidget(const SizedBox());
        env.timer.dispose();
      }
    });
  });
}
