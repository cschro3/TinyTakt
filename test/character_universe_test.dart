import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/data/settings_repository.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/domain/character_profiles.dart';
import 'package:tinytakt/domain/timer_engine.dart';
import 'package:tinytakt/presentation/art/adventure/adventure_gear.dart';
import 'package:tinytakt/presentation/art/adventure/adventure_scene.dart';
import 'package:tinytakt/presentation/art/rig.dart' show Emotion;
import 'package:tinytakt/presentation/art/story/art_images.dart';
import 'package:tinytakt/presentation/art/visual/character_visual_painter.dart';
import 'package:tinytakt/presentation/screens/home_screen.dart';
import 'package:tinytakt/presentation/screens/picker_screen.dart';
import 'package:tinytakt/presentation/widgets/character_sheet.dart';

import 'helpers.dart';

void main() {
  group('Charakteruniversum (Daten)', () {
    test('jede Figur hat ein vollständiges zweisprachiges Profil', () {
      for (final c in characters) {
        final p = profileOf(c.id);
        expect(p, isNotNull, reason: c.id);
        for (final t in [
          p!.traitDe,
          p.traitEn,
          p.abilityDe,
          p.abilityEn,
          p.storyDe,
          p.storyEn,
        ]) {
          expect(t.trim().length, greaterThan(3), reason: c.id);
        }
        expect(p.storyDe, isNot(p.storyEn), reason: '${c.id}: DE/EN identisch');
        expect(
          p.storyDe.length,
          lessThan(90),
          reason: '${c.id}: Geschichte zu lang für die Karte',
        );
      }
      expect(
        characterProfiles.length,
        characters.length,
        reason: 'kein Profil ohne Figur',
      );
    });

    test('alle 14 Gruppen sind belegt', () {
      final used = {for (final p in characterProfiles.values) p.group};
      expect(used, containsAll(CharacterGroup.values));
      for (final g in CharacterGroup.values) {
        expect(g.de, isNotEmpty);
        expect(g.en, isNotEmpty);
      }
    });
  });

  group('Abenteuer-Ausrüstung', () {
    test('jede Welt hat Ausrüstung, nur Figuren mit Kopf tragen sie', () {
      for (final b in backgrounds) {
        expect(adventureGear.containsKey(b.id), isTrue, reason: b.id);
        final g = adventureGear[b.id]!;
        expect(g.nameDe, isNotEmpty);
        expect(g.itemsEn, isNotEmpty);
        expect(g.front != null || g.back != null, isTrue);
      }
      expect(gearFits(characters.firstWhere((c) => c.id == 'dog')), isTrue);
      expect(
        gearFits(characters.firstWhere((c) => c.id == 'nova_mira')),
        isTrue,
      );
      expect(gearFits(characters.firstWhere((c) => c.id == 'car')), isFalse);
      expect(gearFits(characters.firstWhere((c) => c.id == 'planet')), isFalse);
    });

    test('Ausrüstung zeichnet für jede Figur in jeder Welt fehlerfrei', () {
      for (final c in characters) {
        for (final w in adventureGear.keys) {
          final rec = PictureRecorder();
          CharacterVisualPainter(
            c,
            gearWorld: w,
            shadow: false,
          ).paint(Canvas(rec), const Size(120, 120));
          rec.endRecording().dispose();
        }
      }
    });
  });

  group('Figurenbewegung', () {
    FigureMotion m({
      double u = 0.5,
      double t = 1,
      bool running = true,
      bool finished = false,
      bool calm = false,
      Emotion emotion = Emotion.calm,
      double emotionT = 5,
      Map<int, double> passed = const {},
      bool goalRight = true,
    }) => FigureMotion.compute(
      u: u,
      t: t,
      running: running,
      finished: finished,
      calm: calm,
      emotion: emotion,
      emotionT: emotionT,
      passedAt: passed,
      side: 100,
      goalRight: goalRight,
    );

    test('Etappe erreicht: kurzer Hüpfer, danach wieder normal', () {
      final base = m(running: false, passed: const {}).lift;
      final hop = m(running: false, t: 10.45, passed: const {1: 10.0}).lift;
      expect(hop, lessThan(base - 10));
      expect(m(running: false, t: 12.0, passed: const {1: 10.0}).lift, base);
    });

    test('Kurz vor dem Ziel federt die Figur lebhafter als davor', () {
      var far = 0.0, near = 0.0;
      for (var i = 0; i < 100; i++) {
        far = far < -m(u: 0.5, t: i * 0.02).lift
            ? -m(u: 0.5, t: i * 0.02).lift
            : far;
        near = near < -m(u: 0.95, t: i * 0.02).lift
            ? -m(u: 0.95, t: i * 0.02).lift
            : near;
      }
      expect(near, greaterThan(far));
    });

    test('Am Ziel weicht die Figur seitlich aus und verdeckt es nicht', () {
      expect(m(u: 0.5).dx, 0);
      expect(m(u: 1.0, goalRight: true).dx, lessThan(-40));
      expect(m(u: 1.0, goalRight: false).dx, greaterThan(40));
    });

    test('Jubeln am Ende, Pause ohne Hüpfen, ruhiger Modus ohne Bewegung', () {
      expect(
        m(finished: true, running: false, emotionT: 0.3, u: 1).lift,
        lessThan(-5),
      );
      expect(m(running: false, emotion: Emotion.sleepy).lift, 0);
      final c = m(
        calm: true,
        passed: const {1: 0.9},
        t: 1.0,
        finished: true,
        emotionT: 0.3,
      );
      expect(c.lift, 0);
      expect(c.rot, 0);
    });

    test('Begrüßung/Start: leichtes Winken klingt ab', () {
      expect(
        m(emotion: Emotion.greet, emotionT: 0.2, t: 1.0).rot.abs(),
        greaterThan(0),
      );
      expect(m(emotion: Emotion.greet, emotionT: 2.5, t: 1.0).rot, 0);
    });
  });

  group('Favoriten & Galerie', () {
    test(
      'Favoriten werden gespeichert, geladen und tolerant gelesen',
      () async {
        final env = TestEnv();
        await env.settings.toggleFavorite('dog');
        await env.settings.toggleFavorite('nova_mira');
        expect(env.settings.favorites, ['dog', 'nova_mira']);
        await env.settings.toggleFavorite('dog');
        expect(env.settings.isFavorite('dog'), isFalse);
        final reload = SettingsRepository(env.prefs);
        expect(reload.favorites, ['nova_mira']);
        env.timer.dispose();
      },
    );

    testWidgets(
      'Stern zeigt Favoriten-Bereich, Info öffnet Steckbrief, Wählen setzt die Figur',
      (t) async {
        setScreen(t, const Size(393, 852), dpr: 1);
        await t.runAsync(ArtImages.instance.ensureLoaded);
        final env = TestEnv(pro: true);
        await t.runAsync(env.init);
        await t.pumpWidget(wrap(env.deps, const PickerScreen()));
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 50));
        }
        expect(find.text('Meine Favoriten'), findsNothing);
        await t.tap(
          find.bySemanticsLabel('Zu Favoriten').first,
          warnIfMissed: false,
        );
        await t.pump(const Duration(milliseconds: 300));
        expect(env.settings.favorites, isNotEmpty);
        expect(find.text('Meine Favoriten'), findsOneWidget);
        await t.tap(find.byIcon(Icons.info_outline_rounded).first);
        for (var i = 0; i < 10; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(CharacterSheet), findsOneWidget);
        expect(
          find.textContaining('Persönlichkeit', findRichText: true),
          findsWidgets,
        );
        expect(find.text('Abenteuer-Ausrüstung'), findsOneWidget);
        await t.tap(find.text('Diese Figur wählen'));
        for (var i = 0; i < 12; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(CharacterSheet), findsNothing);
        expect(env.settings.profile.characterId, env.settings.favorites.first);
        await t.pumpWidget(const SizedBox());
        env.timer.dispose();
      },
    );

    testWidgets(
      'Gesperrte Figur: Steckbrief sichtbar, Wählen öffnet Pro statt zu wählen',
      (t) async {
        setScreen(t, const Size(393, 852), dpr: 1);
        final env = TestEnv(pro: false);
        await t.runAsync(env.init);
        final before = env.settings.profile.characterId;
        final lion = characters.firstWhere((c) => c.pro && gearFits(c));
        expect(lion.pro, isTrue);
        await t.pumpWidget(
          wrap(
            env.deps,
            Scaffold(
              body: Builder(
                builder: (c) => TextButton(
                  onPressed: () => showCharacterSheet(c, lion),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('open'));
        for (var i = 0; i < 10; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('Mit Pro freischalten'), findsOneWidget);
        await t.tap(find.text('Mit Pro freischalten'));
        await t.pump(const Duration(milliseconds: 400));
        expect(
          env.settings.profile.characterId,
          before,
          reason: 'Pro-Figur darf nicht ohne Pro gewählt werden',
        );
        await t.pumpWidget(const SizedBox());
        env.timer.dispose();
      },
    );
  });

  testWidgets('Abenteuer mit Ausrüstung: Timerlauf und Abschluss ohne Fehler', (
    t,
  ) async {
    setScreen(t, const Size(393, 852), dpr: 1);
    await t.runAsync(ArtImages.instance.ensureLoaded);
    final env = TestEnv(pro: true);
    await t.runAsync(env.init);
    await env.settings.updateProfile(
      (p) => p.copyWith(
        characterId: 'bear',
        backgroundId: 'space',
        style: TimerStyle.adventure,
      ),
    );
    await env.timer.setDuration(const Duration(minutes: 10));
    await t.pumpWidget(wrap(env.deps, const HomeScreen()));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(AdventureScene), findsOneWidget);
    await env.timer.start();
    for (var s = 0; s < 6; s++) {
      env.clock.advance(const Duration(minutes: 2));
      for (var i = 0; i < 8; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }
    expect(env.timer.status, TimerStatus.finished);
    await env.timer.stop();
    await t.pumpWidget(const SizedBox());
    env.timer.dispose();
  });
}
