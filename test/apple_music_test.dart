import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/data/settings_repository.dart';
import 'package:tinytakt/data/stores.dart';
import 'package:tinytakt/domain/timer_engine.dart';
import 'package:tinytakt/platform/apple_music_service.dart';
import 'package:tinytakt/presentation/screens/apple_music_screen.dart';
import 'package:tinytakt/presentation/screens/parent_screen.dart';
import 'package:tinytakt/presentation/screens/picker_screen.dart';

import 'helpers.dart';

const _track = AppleMusicTrack(
  id: 'a1',
  title: 'Sonnenlied',
  artist: 'Ensemble Eins',
);

Future<void> music() => Future<void>.delayed(const Duration(milliseconds: 30));

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

final _vertical = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axis == Axis.vertical,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelAppleMusic (Kanal-Übersetzung)', () {
    const channel = MethodChannel('test/apple_music');
    final calls = <MethodCall>[];

    void mock(Future<Object?> Function(MethodCall) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (c) {
            calls.add(c);
            return handler(c);
          });
    }

    setUp(calls.clear);
    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    test('Status-Zeichenketten werden übersetzt', () async {
      final am = MethodChannelAppleMusic(channel: channel, supported: true);
      for (final e in {
        'authorized': AppleMusicAuth.authorized,
        'denied': AppleMusicAuth.denied,
        'restricted': AppleMusicAuth.restricted,
        'notDetermined': AppleMusicAuth.notDetermined,
        'unbekannt': AppleMusicAuth.unsupported,
      }.entries) {
        mock((_) async => e.key);
        expect(await am.authorizationStatus(), e.value, reason: e.key);
      }
    });

    test('Nicht unterstützt: kein Kanalaufruf, Status unsupported, Suche leer, Play wirft', () async {
      final am = MethodChannelAppleMusic(channel: channel, supported: false);
      mock((_) async => 'authorized');
      expect(am.isSupported, isFalse);
      expect(await am.authorizationStatus(), AppleMusicAuth.unsupported);
      expect(await am.canPlay(), isFalse);
      await expectLater(am.play('x'), throwsA(isA<AppleMusicException>()));
      await expectLater(
        am.requestAuthorization(),
        throwsA(isA<AppleMusicException>()),
      );
      expect(calls, isEmpty);
    });

    test('Suche: Ergebnisse gelesen, ungültige Einträge ignoriert, leere Anfrage ohne Aufruf', () async {
      final am = MethodChannelAppleMusic(channel: channel, supported: true);
      mock(
        (c) async => [
          {'id': '1', 'title': 'Lied', 'artist': 'A'},
          {'id': '', 'title': 'ohne Id', 'artist': 'B'},
          {'title': 'ohne Id'},
          'kaputt',
          {'id': '2', 'title': 'Zwei'},
        ],
      );
      final r = await am.search('  lied ');
      expect(r.map((t) => t.id), ['1', '2']);
      expect(r.last.artist, '');
      expect(calls.single.method, 'search');
      expect((calls.single.arguments as Map)['query'], 'lied');
      calls.clear();
      expect(await am.search('   '), isEmpty);
      expect(calls, isEmpty);
    });

    test('Plattformfehler werden zu AppleMusicException', () async {
      final am = MethodChannelAppleMusic(channel: channel, supported: true);
      mock(
        (_) async =>
            throw PlatformException(code: 'not_authorized', message: 'nein'),
      );
      await expectLater(
        am.play('1'),
        throwsA(
          isA<AppleMusicException>().having(
            (e) => e.code,
            'code',
            'not_authorized',
          ),
        ),
      );
      await expectLater(am.search('x'), throwsA(isA<AppleMusicException>()));
      expect(await am.canPlay(), isFalse);
      await am.pause();
      await am.stop();
    });

    test('Fehlendes Plugin (z. B. Simulator ohne Kanal) wird als unsupported behandelt', () async {
      final am = MethodChannelAppleMusic(
        channel: const MethodChannel('test/gibts_nicht'),
        supported: true,
      );
      expect(await am.authorizationStatus(), AppleMusicAuth.unsupported);
      await expectLater(
        am.play('1'),
        throwsA(
          isA<AppleMusicException>().having(
            (e) => e.code,
            'code',
            'unsupported',
          ),
        ),
      );
    });

    test('Play übergibt die Titel-ID', () async {
      final am = MethodChannelAppleMusic(channel: channel, supported: true);
      mock((_) async => null);
      await am.play('abc');
      expect(calls.single.method, 'play');
      expect((calls.single.arguments as Map)['id'], 'abc');
    });
  });

  group('AppleMusicTrack / Einstellungen', () {
    test('JSON-Roundtrip und ungültige Daten', () {
      expect(AppleMusicTrack.fromJson(_track.toJson())!.title, 'Sonnenlied');
      expect(AppleMusicTrack.fromJson(null), isNull);
      expect(AppleMusicTrack.fromJson({'id': '', 'title': 'x'}), isNull);
      expect(AppleMusicTrack.fromJson({'id': '1'}), isNull);
    });

    test('Ausgewählter Titel wird gespeichert und geladen', () async {
      final store = MemoryStore();
      final s = SettingsRepository(store);
      await s.update((x) => x.appleMusic = _track);
      await s.updateProfile((p) => p.copyWith(musicId: appleMusicSoundId));
      final s2 = SettingsRepository(store);
      expect(s2.appleMusic?.id, 'a1');
      expect(s2.profile.musicId, appleMusicSoundId);
    });

    test('Beschädigte Titelauswahl wird ignoriert', () async {
      final store = MemoryStore();
      await store.setString('settings.v1', '{"appleMusic": {"id": 5}}');
      expect(SettingsRepository(store).appleMusic, isNull);
    });
  });

  group('TimerController mit Apple Music', () {
    late TestEnv env;

    Future<void> prepare({FakeAppleMusic? am}) async {
      env = TestEnv();
      if (am != null) {
        env.appleMusic
          ..supported = am.supported
          ..auth = am.auth;
      }
      await env.init();
      await env.settings.update((s) => s.appleMusic = _track);
      await env.settings.updateProfile(
        (p) => p.copyWith(musicId: appleMusicSoundId),
      );
    }

    tearDown(() => env.timer.dispose());

    test('Spielt den gewählten Titel statt der eingebauten Musik', () async {
      await prepare();
      await env.timer.start();
      await music();
      expect(env.appleMusic.log, contains('play:a1'));
      expect(env.audio.log.where((e) => e.startsWith('music:')), isEmpty);
    });

    test('Pause, Stopp und Ende halten Apple Music an', () async {
      await prepare();
      await env.timer.setDuration(const Duration(seconds: 5));
      await env.timer.start();
      await music();
      await env.timer.pause();
      expect(env.appleMusic.log.last, 'pause');
      env.appleMusic.log.clear();
      await env.timer.resume();
      await music();
      expect(env.appleMusic.log, contains('play:a1'));
      env.clock.advance(const Duration(seconds: 6));
      env.timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(env.timer.status, TimerStatus.finished);
      expect(env.appleMusic.log, contains('pause'));
      expect(env.audio.log.any((e) => e.startsWith('alarm:')), isTrue);
    });

    test('Race 1: Stopp, während die Berechtigung noch geprüft wird → es wird gar nicht gespielt', () async {
      await prepare();
      env.appleMusic.authDelay = const Duration(milliseconds: 40);
      await env.timer.start();
      await env.timer.stop();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(env.appleMusic.log.where((e) => e.startsWith('play')), isEmpty);
    });

    test('Race 2: Stopp, während der Titel gerade startet → er wird sofort wieder angehalten', () async {
      await prepare();
      env.appleMusic.playDelay = const Duration(milliseconds: 40);
      await env.timer.start();
      await Future<void>.delayed(
        const Duration(milliseconds: 10),
      ); // play läuft bereits
      expect(env.appleMusic.log, contains('play:a1'));
      await env.timer.stop();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(env.appleMusic.log.last, 'pause');
    });

    test('Stopp pausiert Apple Music', () async {
      await prepare();
      await env.timer.start();
      await music();
      env.appleMusic.log.clear();
      await env.timer.stop();
      expect(env.appleMusic.log, contains('pause'));
    });

    test('Hintergrund pausiert Apple Music (kein Hintergrund-Audio)', () async {
      await prepare();
      await env.timer.start();
      await music();
      env.appleMusic.log.clear();
      env.timer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(env.appleMusic.log, contains('pause'));
    });

    test(
      'Nicht erlaubt: eingebaute Musik als Ersatz, kein Apple-Aufruf',
      () async {
        await prepare(am: FakeAppleMusic(auth: AppleMusicAuth.denied));
        await env.timer.start();
        await music();
        expect(env.appleMusic.log.where((e) => e.startsWith('play')), isEmpty);
        expect(env.audio.log, contains('music:music_calm'));
      },
    );

    test(
      'Nicht unterstützt (Android/Web): eingebaute Musik als Ersatz',
      () async {
        await prepare(am: FakeAppleMusic(supported: false));
        await env.timer.start();
        await music();
        expect(env.audio.log, contains('music:music_calm'));
      },
    );

    test(
      'Wiedergabe schlägt fehl (z. B. kein Abo): eingebaute Musik als Ersatz',
      () async {
        await prepare();
        env.appleMusic.failPlay = true;
        await env.timer.start();
        await music();
        expect(env.audio.log, contains('music:music_calm'));
        expect(
          env.timer.status,
          TimerStatus.running,
          reason: 'Timer läuft trotzdem',
        );
      },
    );

    test('Stumm und Ruhiger Modus: keine Wiedergabe', () async {
      await prepare();
      await env.settings.update((s) => s.muted = true);
      await env.timer.start();
      await music();
      expect(env.appleMusic.log.where((e) => e.startsWith('play')), isEmpty);
    });

    test('Stumm schalten während des Laufs pausiert Apple Music', () async {
      await prepare();
      await env.timer.start();
      await music();
      env.appleMusic.log.clear();
      await env.settings.update((s) => s.muted = true);
      await env.timer.applySettings();
      expect(env.appleMusic.log, contains('pause'));
    });

    test('Wechsel zu eingebauter Musik pausiert Apple Music', () async {
      await prepare();
      await env.timer.start();
      await music();
      env.appleMusic.log.clear();
      await env.settings.updateProfile(
        (p) => p.copyWith(musicId: 'music_happy'),
      );
      await env.timer.changeMusic();
      expect(env.appleMusic.log, contains('pause'));
      expect(env.audio.log, contains('music:music_happy'));
    });

    test('Ohne gewählten Titel: eingebaute Musik', () async {
      await prepare();
      await env.settings.update((s) => s.appleMusic = null);
      await env.timer.start();
      await music();
      expect(env.appleMusic.log.where((e) => e.startsWith('play')), isEmpty);
      expect(env.audio.log, contains('music:music_calm'));
    });
  });

  group('Oberfläche', () {
    testWidgets('Elternbereich: nicht unterstützt → nur Hinweis', (t) async {
      setScreen(t, const Size(412, 915));
      final env = TestEnv();
      env.appleMusic.supported = false;
      await t.runAsync(env.init);
      await t.pumpWidget(wrap(env.deps, const ParentScreen()));
      await settle(t);
      await t.scrollUntilVisible(
        find.text('Nur auf iPhone und iPad verfügbar'),
        300,
        scrollable: _vertical.first,
      );
      expect(find.text('Nur auf iPhone und iPad verfügbar'), findsOneWidget);
      expect(find.text('Titel suchen'), findsNothing);
      await t.pumpWidget(const SizedBox());
      env.timer.dispose();
    });

    testWidgets(
      'Elternbereich: nicht verbunden → Verbinden fragt die Erlaubnis an',
      (t) async {
        setScreen(t, const Size(412, 915));
        final env = TestEnv();
        env.appleMusic.auth = AppleMusicAuth.notDetermined;
        await t.runAsync(env.init);
        await t.pumpWidget(wrap(env.deps, const ParentScreen()));
        await settle(t);
        await t.scrollUntilVisible(
          find.text('Mit Apple Music verbinden'),
          300,
          scrollable: _vertical.first,
        );
        await t.tap(find.text('Mit Apple Music verbinden'));
        await settle(t);
        expect(env.appleMusic.log, contains('request'));
        expect(find.text('Titel suchen'), findsOneWidget);
        await t.pumpWidget(const SizedBox());
        env.timer.dispose();
      },
    );

    testWidgets(
      'Elternbereich: Zugriff verweigert und kein Abo zeigen verständliche Hinweise',
      (t) async {
        setScreen(t, const Size(412, 915));
        var env = TestEnv();
        env.appleMusic.auth = AppleMusicAuth.denied;
        await t.runAsync(env.init);
        await t.pumpWidget(wrap(env.deps, const ParentScreen()));
        await settle(t);
        await t.scrollUntilVisible(
          find.text('Zugriff nicht erlaubt'),
          300,
          scrollable: _vertical.first,
        );
        expect(find.text('Zugriff nicht erlaubt'), findsOneWidget);
        await t.pumpWidget(const SizedBox());
        env.timer.dispose();

        env = TestEnv();
        env.appleMusic.subscribed = false;
        await t.runAsync(env.init);
        await t.pumpWidget(wrap(env.deps, const ParentScreen()));
        await settle(t);
        await t.scrollUntilVisible(
          find.text('Kein aktives Apple-Music-Abo gefunden'),
          300,
          scrollable: _vertical.first,
        );
        expect(
          find.text('Kein aktives Apple-Music-Abo gefunden'),
          findsOneWidget,
        );
        expect(find.text('Titel suchen'), findsNothing);
        await t.pumpWidget(const SizedBox());
        env.timer.dispose();
      },
    );

    testWidgets(
      'Suche: Titel finden, anhören, wählen → als Timer-Musik gesetzt',
      (t) async {
        setScreen(t, const Size(412, 915));
        final env = TestEnv();
        await t.runAsync(env.init);
        await t.pumpWidget(wrap(env.deps, const AppleMusicSearchScreen()));
        await t.enterText(find.byType(TextField), 'sonne');
        await t.testTextInput.receiveAction(TextInputAction.search);
        await settle(t);
        expect(find.text('Sonnenlied'), findsOneWidget);
        expect(find.text('Mondschein'), findsNothing);
        await t.tap(find.byTooltip('Anhören'));
        await settle(t);
        expect(env.appleMusic.log, contains('play:a1'));
        await t.tap(find.text('Wählen'));
        await settle(t);
        expect(env.settings.appleMusic?.id, 'a1');
        expect(env.settings.profile.musicId, appleMusicSoundId);
        expect(
          env.appleMusic.log,
          contains('stop'),
          reason: 'Vorschau wird vor dem Wählen gestoppt',
        );
        await t.pumpWidget(const SizedBox());
        env.timer.dispose();
      },
    );

    testWidgets('Suche ohne Treffer und mit Fehler zeigt Hinweise', (t) async {
      setScreen(t, const Size(412, 915));
      final env = TestEnv();
      await t.runAsync(env.init);
      await t.pumpWidget(wrap(env.deps, const AppleMusicSearchScreen()));
      await t.enterText(find.byType(TextField), 'zzz');
      await t.testTextInput.receiveAction(TextInputAction.search);
      await settle(t);
      expect(find.text('Nichts gefunden.'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      env.timer.dispose();
    });

    testWidgets(
      'Kinder-Musikauswahl: Apple-Eintrag nur wenn unterstützt und von Eltern gewählt',
      (t) async {
        setScreen(t, const Size(412, 915));
        var env = TestEnv();
        await t.runAsync(env.init);
        await t.pumpWidget(wrap(env.deps, const PickerScreen()));
        await t.tap(find.text('Musik'));
        await settle(t);
        expect(find.textContaining('Apple Music ·'), findsNothing);
        await env.settings.update((s) => s.appleMusic = _track);
        await settle(t);
        expect(
          find.textContaining('Apple Music · Ensemble Eins'),
          findsOneWidget,
        );
        await t.tap(find.text('Sonnenlied'));
        await settle(t);
        expect(env.settings.profile.musicId, appleMusicSoundId);
        await t.pumpWidget(const SizedBox());
        env.timer.dispose();

        env = TestEnv();
        env.appleMusic.supported = false;
        await t.runAsync(env.init);
        await env.settings.update((s) => s.appleMusic = _track);
        await t.pumpWidget(wrap(env.deps, const PickerScreen()));
        await t.tap(find.text('Musik'));
        await settle(t);
        expect(
          find.textContaining('Apple Music ·'),
          findsNothing,
          reason: 'auf Android/Web nicht anbieten',
        );
        await t.pumpWidget(const SizedBox());
        env.timer.dispose();
      },
    );
  });
}
