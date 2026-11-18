import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/presentation/painters/character_painter.dart';
import 'package:tinytakt/presentation/painters/scene_painter.dart';
import 'package:tinytakt/presentation/screens/picker_screen.dart';
import 'package:tinytakt/presentation/widgets/preview_cache.dart';

import 'helpers.dart';

Future<ui.Image> direct(
  void Function(Canvas, Size) draw,
  Size s,
  double dpr,
) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec)..scale(dpr);
  draw(c, s);
  return rec.endRecording().toImage(
    (s.width * dpr).ceil(),
    (s.height * dpr).ceil(),
  );
}

double psnr(ByteData a, ByteData b) {
  var se = 0.0;
  final n = a.lengthInBytes;
  for (var i = 0; i < n; i++) {
    final d = a.getUint8(i) - b.getUint8(i);
    se += d * d;
  }
  final mse = se / n;
  return mse == 0 ? 99 : 10 * math.log(255 * 255 / mse) / math.ln10;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreviewCache', () {
    setUp(() => PreviewCache.instance.clear());

    test(
      'backt einmal, liefert danach dieselbe Instanz (kein erneutes Zeichnen)',
      () {
        var draws = 0;
        void draw(Canvas c, Size s) {
          draws++;
          c.drawRect(Offset.zero & s, Paint()..color = Colors.red);
        }

        const s = Size(100, 80);
        final a = PreviewCache.instance.get('t1', s, 3, draw);
        final b = PreviewCache.instance.get('t1', s, 3, draw);
        expect(a, isNotNull);
        expect(identical(a, b), isTrue);
        expect(draws, 1);
        expect(
          (a!.width, a.height),
          (300, 240),
        ); // logische Größe × Pixeldichte
        // andere Größe/Pixeldichte = eigener Eintrag
        PreviewCache.instance.get('t1', const Size(96, 80), 3, draw);
        PreviewCache.instance.get('t1', s, 2, draw);
        expect(draws, 3);
      },
    );

    test(
      'Rand vergrößert das Bild, Inhalt bleibt an derselben Stelle',
      () async {
        void draw(Canvas c, Size s) =>
            c.drawRect(Offset.zero & s, Paint()..color = Colors.blue);
        final img = PreviewCache.instance.get(
          't2',
          const Size(50, 40),
          2,
          draw,
          margin: const Offset(10, 10),
        )!;
        expect((img.width, img.height), (140, 120));
        final px = (await img.toByteData())!;
        int a(int x, int y) => px.getUint8((y * img.width + x) * 4 + 3);
        expect(a(5, 5), 0); // im Rand transparent
        expect(a(70, 60), 255); // Mitte gefüllt
      },
    );

    test(
      'LRU: begrenzt Einträge und Speicher, Kacheln behalten gültige Klone',
      () {
        const big = Size(1000, 1000); // ≈ 3,8 MB je Bild bei dpr 1
        ui.Image? clone;
        for (var i = 0; i < 40; i++) {
          final img = PreviewCache.instance.get(
            'big$i',
            big,
            1,
            (c, s) => c.drawRect(Offset.zero & s, Paint()),
          );
          if (i == 0) clone = img!.clone();
        }
        expect(
          PreviewCache.instance.megabytes,
          lessThanOrEqualTo(PreviewCache.maxMegabytes + 2),
        );
        expect(PreviewCache.instance.length, lessThan(40));
        expect(
          clone!.width,
          1000,
        ); // Original evtl. entsorgt, Klon bleibt nutzbar
        clone.dispose();
        final before = PreviewCache.instance.megabytes;
        PreviewCache.instance.trim(5);
        expect(PreviewCache.instance.megabytes, lessThan(before));
        expect(
          PreviewCache.instance.length,
          8,
        ); // behält mindestens die 8 jüngsten
      },
    );

    testWidgets('Vorwärmen stoppt am Speicher-Budget und verdrängt nichts', (
      t,
    ) async {
      PreviewCache.instance.clear();
      for (var i = 0; i < 14; i++) {
        PreviewCache.instance.get(
          'fill$i',
          const Size(1000, 1000),
          1,
          (c, s) => c.drawRect(Offset.zero & s, Paint()),
        );
      }
      expect(
        PreviewCache.instance.megabytes,
        greaterThan(PreviewCache.warmBudgetMegabytes),
      );
      final before = PreviewCache.instance.length;
      var draws = 0;
      for (var i = 0; i < 3; i++) {
        PreviewCache.instance.enqueue(
          'warm$i',
          const Size(40, 40),
          1,
          (c, s) => draws++,
        );
      }
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(draws, 0, reason: 'über dem Budget wird nicht mehr vorgewärmt');
      expect(PreviewCache.instance.pending.value, 0);
      expect(PreviewCache.instance.length, before);
    });

    testWidgets('Vorwärmen backt nur bei Ruhe und höchstens eines je Frame', (
      t,
    ) async {
      var draws = 0;
      void draw(Canvas c, Size s) => draws++;
      for (var i = 0; i < 4; i++) {
        PreviewCache.instance.enqueue('w$i', const Size(40, 40), 1, draw);
      }
      expect(PreviewCache.instance.pending.value, 4);
      // kurz nach einer Berührung wird nicht gebacken
      final g = await t.startGesture(const Offset(5, 5));
      await g.up();
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(draws, 0);
      expect(PreviewCache.instance.pending.value, 4);
      // nach 700 ms Ruhe (echte Zeit): ein Bild je Frame
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 800)),
      );
      await t.pump(
        const Duration(milliseconds: 16),
      ); // schaltet auf Rückprüfung
      await t.pump(const Duration(milliseconds: 400));
      await t.pump(const Duration(milliseconds: 16));
      expect(draws, greaterThan(0));
      expect(draws, lessThanOrEqualTo(2)); // nicht alle auf einmal
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(draws, 4);
      expect(PreviewCache.instance.pending.value, 0);
    });
  });

  group('Optik: gebacken = direkt gezeichnet', () {
    setUp(() => PreviewCache.instance.clear());

    testWidgets('Figuren, Welten und Timer-Stile (≥ 45 dB PSNR)', (t) async {
      const s = Size(105, 85);
      const dpr = 3.0;
      await t.runAsync(() async {
        final cases = <String, void Function(Canvas, Size)>{
          for (final id in ['dog', 'nova_lumi', 'nova_mira', 'cat'])
            'char:$id': (c, sz) =>
                CharacterPainter(characterById(id), shadow: false).paint(c, sz),
          for (final b in backgrounds.take(4))
            'world:${b.id}': (c, sz) =>
                ScenePainter(b, calm: true).paint(c, sz),
        };
        for (final e in cases.entries) {
          final baked = PreviewCache.instance.get(e.key, s, dpr, e.value)!;
          final ref = await direct(e.value, s, dpr);
          final p = psnr(
            (await baked.toByteData())!,
            (await ref.toByteData())!,
          );
          expect(p, greaterThan(45), reason: '${e.key}: $p dB');
        }
      });
    });
  });

  group('Auswahlmenü', () {
    testWidgets(
      'Kacheln zeigen gebackene Bilder; Auswahl backt nur die betroffene Kachel neu',
      (t) async {
        PreviewCache.instance.clear();
        setScreen(t, const Size(393, 852), dpr: 3);
        final env = TestEnv(pro: true);
        await t.runAsync(env.init);
        await t.pumpWidget(wrap(env.deps, const PickerScreen()));
        for (var i = 0; i < 10; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        expect(find.byType(RawImage), findsWidgets);
        expect(PreviewCache.instance.bakes, greaterThan(5));
        // Hintergrund-Backen (Größe im gewählten Zustand) erst auslaufen lassen
        for (
          var i = 0;
          i < 200 && PreviewCache.instance.pending.value > 0;
          i++
        ) {
          await t.pump(const Duration(milliseconds: 16));
        }
        final bakes0 = PreviewCache.instance.bakes;
        // Auswahl einer anderen Figur: Rahmen der zwei betroffenen Kacheln + deren Figur in neuer Größe
        await t.tap(find.text('Katze Mimi'));
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        final delta = PreviewCache.instance.bakes - bakes0;
        expect(
          delta,
          lessThanOrEqualTo(3),
          reason: 'nur die betroffenen Kacheln',
        );
        expect(env.settings.profile.characterId, 'cat');
        // zurückwählen: alles aus dem Cache
        final b1 = PreviewCache.instance.bakes;
        await t.tap(find.text('Hund Bruno'));
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        expect(PreviewCache.instance.bakes, b1);
        await t.pumpWidget(const SizedBox());
        env.timer.dispose();
      },
    );

    testWidgets('Antippen backt nichts mehr, wenn das Menü kurz in Ruhe war', (
      t,
    ) async {
      PreviewCache.instance.clear();
      setScreen(t, const Size(393, 852), dpr: 1);
      final env = TestEnv(pro: true);
      await t.runAsync(env.init);
      await t.pumpWidget(wrap(env.deps, const PickerScreen()));
      // Ruhe: sichtbare Kacheln und ihre „gewählt“-Größe werden im Hintergrund fertig gebacken
      var quiet = 0;
      for (var i = 0; i < 300 && quiet < 8; i++) {
        await t.pump(const Duration(milliseconds: 16));
        quiet = PreviewCache.instance.pending.value == 0 ? quiet + 1 : 0;
      }
      expect(PreviewCache.instance.pending.value, 0);
      final before = PreviewCache.instance.bakes;
      await t.tap(find.text('Katze Mimi'));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(env.settings.profile.characterId, 'cat');
      expect(
        PreviewCache.instance.bakes,
        before,
        reason: 'Tippen zeichnet nichts neu',
      );
      await t.tap(find.text('Hund Bruno'));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(PreviewCache.instance.bakes, before);
      await t.pumpWidget(const SizedBox());
      env.timer.dispose();
    });

    testWidgets(
      'Vorwärmen backt alle Figuren, Welten, Stile – Durchscrollen backt danach nichts mehr',
      (t) async {
        PreviewCache.instance.clear();
        final b0 = PreviewCache.instance.bakes;
        setScreen(t, const Size(393, 852), dpr: 1);
        final env = TestEnv(pro: true);
        await t.runAsync(env.init);
        await t.pumpWidget(wrap(env.deps, const PickerScreen()));
        for (var i = 0; i < 10; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        expect(
          PreviewCache.instance.bakes - b0,
          lessThan(40),
        ); // zuerst nur, was zu sehen ist
        // 700 ms Wartezeit, dann ein Bild je Frame bis die Warteschlange leer ist
        await t.pump(const Duration(milliseconds: 800));
        for (var i = 0; i < 500; i++) {
          await t.pump(const Duration(milliseconds: 16));
          if (i > 5 && PreviewCache.instance.pending.value == 0) break;
        }
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        expect(PreviewCache.instance.pending.value, 0);
        expect(
          PreviewCache.instance.bakes - b0,
          greaterThanOrEqualTo(
            characters.length + backgrounds.length + TimerStyle.values.length,
          ),
        );
        final after = PreviewCache.instance.bakes;
        final list = find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axis == Axis.vertical,
            )
            .first;
        for (var k = 0; k < 8; k++) {
          await t.drag(list, const Offset(0, -900));
          for (var i = 0; i < 12; i++) {
            await t.pump(const Duration(milliseconds: 16));
          }
        }
        expect(
          PreviewCache.instance.bakes,
          after,
          reason: 'alles schon im Cache',
        );
        await t.pumpWidget(const SizedBox());
        env.timer.dispose();
      },
    );

    testWidgets(
      'Tabs bleiben erhalten: Scrollposition überlebt den Tab-Wechsel',
      (t) async {
        setScreen(t, const Size(393, 852), dpr: 2);
        final env = TestEnv(pro: true);
        await t.runAsync(env.init);
        await t.pumpWidget(wrap(env.deps, const PickerScreen()));
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        final sc = find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axis == Axis.vertical,
            )
            .first;
        await t.drag(sc, const Offset(0, -900));
        for (var i = 0; i < 40; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        double offset() => t
            .state<ScrollableState>(
              find
                  .byWidgetPredicate(
                    (w) => w is Scrollable && w.axis == Axis.vertical,
                  )
                  .first,
            )
            .position
            .pixels;
        final before = offset();
        expect(before, greaterThan(300));
        await t.tap(find.widgetWithText(Tab, 'Welt'));
        for (var i = 0; i < 40; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        await t.tap(find.widgetWithText(Tab, 'Figur'));
        for (var i = 0; i < 40; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        expect(offset(), closeTo(before, 1));
        await t.pumpWidget(const SizedBox());
        env.timer.dispose();
      },
    );

    testWidgets('Timer-Meldungen bauen das Menü nicht neu auf', (t) async {
      setScreen(t, const Size(393, 852), dpr: 2);
      final env = TestEnv(pro: true);
      await t.runAsync(env.init);
      await t.pumpWidget(wrap(env.deps, const PickerScreen()));
      for (var i = 0; i < 40; i++) {
        await t.pump(
          const Duration(milliseconds: 16),
        ); // Animationen auslaufen lassen
      }
      expect(t.binding.hasScheduledFrame, isFalse);
      // ignore: invalid_use_of_protected_member
      env.timer.notifyListeners();
      expect(
        t.binding.hasScheduledFrame,
        isFalse,
        reason: 'Menü hört nicht mehr auf den Timer',
      );
      // Einstellungen dagegen aktualisieren die Auswahl
      await env.settings.updateProfile((p) => p.copyWith(characterId: 'cat'));
      expect(t.binding.hasScheduledFrame, isTrue);
      await t.pumpWidget(const SizedBox());
      env.timer.dispose();
    });

    testWidgets(
      'alle vier Tabs lassen sich öffnen, gesperrte Einträge bleiben erkennbar',
      (t) async {
        setScreen(t, const Size(393, 852), dpr: 2);
        final env = TestEnv(pro: false);
        await t.runAsync(env.init);
        await t.pumpWidget(wrap(env.deps, const PickerScreen()));
        for (final n in ['Figur', 'Welt', 'Zeit', 'Musik']) {
          await t.tap(find.widgetWithText(Tab, n));
          for (var i = 0; i < 30; i++) {
            await t.pump(const Duration(milliseconds: 16));
          }
          expect(find.byIcon(Icons.lock_rounded), findsWidgets, reason: n);
        }
        await t.pumpWidget(const SizedBox());
        env.timer.dispose();
      },
    );
  });
}
