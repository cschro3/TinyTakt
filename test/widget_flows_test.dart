import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/domain/timer_engine.dart';
import 'package:tinytakt/presentation/screens/home_screen.dart';
import 'package:tinytakt/presentation/screens/parent_screen.dart';
import 'package:tinytakt/presentation/screens/picker_screen.dart';
import 'package:tinytakt/presentation/screens/pro_screen.dart';

import 'helpers.dart';

Future<TestEnv> boot(
  WidgetTester t, {
  bool pro = false,
  Size size = const Size(412, 915),
  double textScale = 1.0,
  Locale locale = const Locale('de'),
  Widget? home,
}) async {
  setScreen(t, size);
  final env = TestEnv(pro: pro);
  await t.runAsync(env.init);
  await t.pumpWidget(
    wrap(
      env.deps,
      home ?? const HomeScreen(),
      textScale: textScale,
      locale: locale,
    ),
  );
  await t.pump(const Duration(milliseconds: 100));
  return env;
}

/// Die Oberfläche hat Dauer-Animationen; pumpAndSettle würde nie enden.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

final _vertical = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axis == Axis.vertical,
);

Future<void> dispose(WidgetTester t, TestEnv env) async {
  await env.timer.stop();
  await t.pumpWidget(const SizedBox());
  env.timer.dispose();
}

void main() {
  testWidgets('Hauptbildschirm zeigt Dauer, Start startet, Pause pausiert', (
    t,
  ) async {
    final env = await boot(t);
    expect(find.text('05:00'), findsOneWidget);
    expect(find.bySemanticsLabel('Start'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Start'));
    await t.pump(const Duration(milliseconds: 300));
    expect(env.timer.status, TimerStatus.running);
    expect(find.bySemanticsLabel('Pause'), findsOneWidget);
    expect(env.notes.scheduledEndMs, isNotNull);
    await t.tap(find.bySemanticsLabel('Pause'));
    await t.pump(const Duration(milliseconds: 300));
    expect(env.timer.status, TimerStatus.paused);
    expect(find.bySemanticsLabel('Weiter'), findsOneWidget);
    await dispose(t, env);
  });

  testWidgets('Schnellauswahl ändert Dauer', (t) async {
    final env = await boot(t);
    await t.tap(find.bySemanticsLabel('10 Minuten'));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('10:00'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('30 Minuten'));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('30:00'), findsOneWidget);
    await dispose(t, env);
  });

  testWidgets('Zeiteinstellung per Radsteuerung (Stunden/Minuten/Sekunden)', (
    t,
  ) async {
    final env = await boot(t);
    await t.tap(find.bySemanticsLabel('Zeit ändern'));
    await settle(t);
    expect(find.text('Wie lange?'), findsOneWidget);
    expect(find.text('Std.'), findsOneWidget);
    expect(find.text('Min.'), findsOneWidget);
    expect(find.text('Sek.'), findsOneWidget);
    await t.tap(find.text('Fertig'));
    await settle(t);
    expect(env.timer.engine.totalMs, 300000);
    await dispose(t, env);
  });

  testWidgets(
    'Kindermodus: laufender Timer verbirgt Einstellungen, Stopp braucht Elternsicherung',
    (t) async {
      final env = await boot(t);
      expect(find.bySemanticsLabel('Bereich für Eltern'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Start'));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.bySemanticsLabel('Bereich für Eltern'), findsNothing);
      expect(find.bySemanticsLabel('Figur und Welt wählen'), findsNothing);
      expect(find.bySemanticsLabel('Zeit ändern'), findsNothing);
      await t.tap(find.bySemanticsLabel('Timer beenden (Erwachsene)'));
      await settle(t);
      expect(find.text('Nur für Erwachsene'), findsOneWidget);
      expect(
        env.timer.status,
        TimerStatus.running,
        reason: 'ohne Gate kein Stopp',
      );
      await t.tap(find.text('Abbrechen'));
      await settle(t);
      expect(env.timer.status, TimerStatus.running);
      await dispose(t, env);
    },
  );

  testWidgets('Sperre abschaltbar: Einstellungen bleiben sichtbar', (t) async {
    final env = await boot(t);
    await env.settings.update((s) => s.lockWhileRunning = false);
    await t.tap(find.bySemanticsLabel('Start'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('Bereich für Eltern'), findsOneWidget);
    await dispose(t, env);
  });

  testWidgets(
    'Elternsicherung: falsche Antwort wird abgelehnt, richtige öffnet Elternbereich',
    (t) async {
      final env = await boot(t);
      await t.tap(find.bySemanticsLabel('Bereich für Eltern'));
      await settle(t);
      expect(find.textContaining('Wie viel ist'), findsOneWidget);
      await t.enterText(find.byType(TextField), '1');
      await t.tap(find.text('OK'));
      await settle(t);
      expect(
        find.text('Leider falsch. Bitte noch einmal versuchen.'),
        findsOneWidget,
      );
      expect(find.byType(ParentScreen), findsNothing);
      // Aufgabe wurde neu gestellt: Antwort aus dem Text berechnen
      final txt = (t.widget(find.textContaining('Wie viel ist')) as Text).data!;
      await t.enterText(find.byType(TextField), '${_solve(txt)}');
      await t.tap(find.text('OK'));
      await settle(t);
      expect(find.byType(ParentScreen), findsOneWidget);
      expect(find.text('Für Eltern'), findsOneWidget);
      await dispose(t, env);
    },
  );

  testWidgets(
    'Free: Pro-Inhalte sind gesperrt; Tippen öffnet nur die Elternsicherung, keinen Kauf',
    (t) async {
      final env = await boot(t, home: const PickerScreen());
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
      expect(find.text('Hund Bruno'), findsOneWidget);
      // Kein Kaufbutton im Kinderbereich
      expect(find.textContaining('4,99'), findsNothing);
      expect(find.textContaining('freischalten'), findsNothing);
      await t.scrollUntilVisible(
        find.text('Drache Funki'),
        300,
        scrollable: _vertical.first,
      );
      await t.tap(find.text('Drache Funki'));
      await settle(t);
      expect(find.text('Nur für Erwachsene'), findsOneWidget);
      expect(find.byType(ProScreen), findsNothing);
      expect(env.settings.profile.characterId, 'dog');
      await t.tap(find.text('Abbrechen'));
      await settle(t);
      await dispose(t, env);
    },
  );

  testWidgets('Free: mindestens 8 Figuren und 5 Welten frei', (t) async {
    expect(characters.where((c) => !c.pro).length, greaterThanOrEqualTo(8));
    expect(backgrounds.where((b) => !b.pro).length, greaterThanOrEqualTo(5));
    expect(characters.length, greaterThanOrEqualTo(40));
    expect(
      sounds.where((s) => s.kind == SoundKind.alarm && !s.pro).length,
      greaterThanOrEqualTo(2),
    );
  });

  testWidgets('Free: freie Figur wählbar', (t) async {
    final env = await boot(t, home: const PickerScreen());
    await t.tap(find.text('Katze Mimi'));
    await t.pump();
    expect(env.settings.profile.characterId, 'cat');
    await dispose(t, env);
  });

  testWidgets('Pro: keine Sperrsymbole, Pro-Figur wählbar', (t) async {
    final env = await boot(t, pro: true, home: const PickerScreen());
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    await t.scrollUntilVisible(
      find.text('Drache Funki'),
      300,
      scrollable: _vertical.first,
    );
    await t.tap(find.text('Drache Funki'));
    await t.pump();
    expect(env.settings.profile.characterId, 'dragon');
    await dispose(t, env);
  });

  testWidgets('Pro-Figur fällt nach Entzug von Pro auf freie Figur zurück', (
    t,
  ) async {
    final env = await boot(t, pro: true);
    await env.settings.updateProfile(
      (p) => p.copyWith(
        characterId: 'dragon',
        style: TimerStyle.rainbow,
        backgroundId: 'space',
      ),
    );
    expect(effectiveCharacter(env.deps).id, 'dragon');
    await env.entitlements.revoke();
    expect(effectiveCharacter(env.deps).id, 'dog');
    expect(effectiveStyle(env.deps), TimerStyle.circle);
    expect(effectiveBackground(env.deps).id, 'meadow');
    await dispose(t, env);
  });

  testWidgets(
    'Pro-Bildschirm: Preis vom Store, Kauf auslösen, Wiederherstellen',
    (t) async {
      final env = await boot(t, home: const ProScreen());
      await t.runAsync(env.purchases.init);
      await t.pump();
      expect(find.text('Pro freischalten – 4,99 €'), findsOneWidget);
      expect(find.textContaining('Kein Abo'), findsWidgets);
      await t.tap(find.text('Pro freischalten – 4,99 €'));
      await t.pump();
      expect(env.store.bought, [proProductId]);
      await t.tap(find.text('Kauf wiederherstellen'), warnIfMissed: false);
      await dispose(t, env);
    },
  );

  testWidgets(
    'Pro-Bildschirm: Store offline zeigt verständlichen Hinweis, kein Absturz',
    (t) async {
      setScreen(t, const Size(412, 915));
      final env = TestEnv();
      env.store.available = false;
      await t.runAsync(env.init);
      await t.pumpWidget(wrap(env.deps, const ProScreen()));
      await t.runAsync(env.purchases.init);
      await t.pump();
      expect(find.textContaining('nicht erreichbar'), findsOneWidget);
      expect(t.takeException(), isNull);
      await dispose(t, env);
    },
  );

  testWidgets('Pro aktiv: Bestätigung statt Kaufbutton', (t) async {
    final env = await boot(t, pro: true, home: const ProScreen());
    expect(find.textContaining('Pro ist freigeschaltet'), findsOneWidget);
    expect(find.textContaining('freischalten –'), findsNothing);
    await dispose(t, env);
  });

  testWidgets('Elternbereich: Profil hinzufügen ist Pro-Funktion', (t) async {
    final env = await boot(t, home: const ParentScreen());
    await t.scrollUntilVisible(
      find.text('Profil hinzufügen'),
      300,
      scrollable: _vertical.first,
    );
    expect(env.settings.profiles.length, 1);
    expect(await env.settings.addProfile('Mia', isPro: false), isFalse);
    expect(await env.settings.addProfile('Mia', isPro: true), isTrue);
    expect(env.settings.profiles.length, 2);
    await dispose(t, env);
  });

  testWidgets('Elternbereich: Einstellungen schalten und persistieren', (
    t,
  ) async {
    final env = await boot(t, home: const ParentScreen());
    await t.tap(find.text('Timer wiederholen'));
    await t.pump();
    expect(env.settings.repeat, isTrue);
    await t.tap(find.text('Ruhiger Modus'));
    await t.pump();
    expect(env.settings.calmMode, isTrue);
    expect(env.prefs.data['settings.v1'], contains('"calmMode":true'));
    await dispose(t, env);
  });

  testWidgets('Englisch: Texte werden lokalisiert', (t) async {
    final env = await boot(t, locale: const Locale('en'));
    expect(find.bySemanticsLabel('Start'), findsOneWidget);
    expect(find.bySemanticsLabel('Parents area'), findsOneWidget);
    expect(find.bySemanticsLabel('5 minutes'), findsOneWidget);
    await dispose(t, env);
  });

  testWidgets('Timer-Ende zeigt „Geschafft!“ und Erneut/Fertig', (t) async {
    final env = await boot(t);
    await env.timer.setDuration(const Duration(seconds: 2));
    await t.tap(find.bySemanticsLabel('Start'));
    await t.pump(const Duration(milliseconds: 300));
    env.clock.advance(const Duration(seconds: 3));
    await t.pump(const Duration(milliseconds: 500));
    expect(env.timer.status, TimerStatus.finished);
    expect(find.textContaining('Geschafft'), findsWidgets);
    expect(find.bySemanticsLabel('Noch einmal'), findsOneWidget);
    expect(env.audio.log.any((e) => e.startsWith('alarm:')), isTrue);
    await t.tap(find.bySemanticsLabel('Fertig'));
    await t.pump(const Duration(milliseconds: 300));
    expect(env.timer.status, TimerStatus.idle);
    await dispose(t, env);
  });

  group('Barrierefreiheit & Layout', () {
    final sizes = {
      'iPhone SE': const Size(320, 568),
      'Pixel': const Size(412, 915),
      'iPad Hochformat': const Size(820, 1180),
      'iPad Querformat': const Size(1180, 820),
      'Handy quer': const Size(844, 390),
    };
    for (final e in sizes.entries) {
      testWidgets('Kein Überlauf: ${e.key}, Schrift 1.0 und 2.0', (t) async {
        for (final scale in [1.0, 2.0]) {
          final env = await boot(t, size: e.value, textScale: scale);
          expect(t.takeException(), isNull, reason: '${e.key} @ $scale idle');
          await t.tap(find.bySemanticsLabel('Start'));
          await t.pump(const Duration(milliseconds: 400));
          expect(
            t.takeException(),
            isNull,
            reason: '${e.key} @ $scale running',
          );
          await dispose(t, env);
        }
      });
    }

    testWidgets('Bedienflächen mindestens 48×48 dp', (t) async {
      final env = await boot(t, size: const Size(360, 640));
      for (final label in [
        'Start',
        'Zeit ändern',
        'Bereich für Eltern',
        'Figur und Welt wählen',
        'Ton ausschalten',
      ]) {
        final r = t.getRect(find.bySemanticsLabel(label));
        expect(r.width, greaterThanOrEqualTo(48), reason: label);
        expect(r.height, greaterThanOrEqualTo(48), reason: label);
      }
      expect(
        t.getRect(find.bySemanticsLabel('Start')).width,
        greaterThanOrEqualTo(96),
        reason: 'Start-Button groß',
      );
      await dispose(t, env);
    });

    testWidgets(
      'Screenreader: Zeit wird als Satz angesagt, Buttons haben Rollen',
      (t) async {
        final h = t.ensureSemantics();
        final env = await boot(t);
        expect(find.bySemanticsLabel('Bereit 5 Minuten'), findsOneWidget);
        expect(
          t
              .getSemantics(find.bySemanticsLabel('Start'))
              .flagsCollection
              .isButton,
          isTrue,
        );
        h.dispose();
        await dispose(t, env);
      },
    );

    testWidgets('Ruhiger Modus rendert ohne Fehler', (t) async {
      final env = await boot(t);
      await env.settings.update((s) => s.calmMode = true);
      await t.tap(find.bySemanticsLabel('Start'));
      await t.pump(const Duration(milliseconds: 500));
      expect(t.takeException(), isNull);
      expect(env.audio.log.where((e) => e.startsWith('music')), isEmpty);
      await dispose(t, env);
    });

    testWidgets(
      'Alle Timer-Darstellungen und alle Figuren rendern fehlerfrei',
      (t) async {
        final env = await boot(t, pro: true);
        for (final s in TimerStyle.values) {
          await env.settings.updateProfile((p) => p.copyWith(style: s));
          await t.pump(const Duration(milliseconds: 100));
          expect(t.takeException(), isNull, reason: s.name);
        }
        await env.timer.start();
        for (final s in TimerStyle.values) {
          await env.settings.updateProfile((p) => p.copyWith(style: s));
          env.clock.advance(const Duration(seconds: 30));
          await t.pump(const Duration(milliseconds: 300));
          expect(t.takeException(), isNull, reason: 'running ${s.name}');
        }
        for (final c in characters) {
          await env.settings.updateProfile(
            (p) => p.copyWith(characterId: c.id),
          );
          await t.pump(const Duration(milliseconds: 50));
          expect(t.takeException(), isNull, reason: c.id);
        }
        await dispose(t, env);
      },
    );
  });
}

int _solve(String prompt) {
  const words = {
    'sieben': 7,
    'acht': 8,
    'neun': 9,
    'elf': 11,
    'zwölf': 12,
    'dreizehn': 13,
    'vierzehn': 14,
    'fünfzehn': 15,
    'sechzehn': 16,
    'siebzehn': 17,
    'achtzehn': 18,
    'neunzehn': 19,
  };
  final m = RegExp(r'ist (\S+) plus (\S+)\?').firstMatch(prompt)!;
  return words[m.group(1)]! + words[m.group(2)]!;
}
