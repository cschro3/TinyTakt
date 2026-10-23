import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/app/timer_controller.dart';
import 'package:tinytakt/data/settings_repository.dart';
import 'package:tinytakt/data/stores.dart';
import 'package:tinytakt/domain/clock.dart';
import 'package:tinytakt/domain/timer_engine.dart';
import 'package:tinytakt/platform/audio_service.dart';
import 'package:tinytakt/platform/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryStore store;
  late SettingsRepository settings;
  late FakeClock clock;
  late SilentAudioService audio;
  late NoopNotificationService notes;

  TimerController make({bool pro = false}) {
    return buildTestController(
      settings: settings,
      store: store,
      clock: clock,
      audio: audio,
      notifications: notes,
      pro: pro,
    );
  }

  setUp(() {
    store = MemoryStore();
    settings = SettingsRepository(store);
    clock = FakeClock();
    audio = SilentAudioService();
    notes = NoopNotificationService();
  });

  test('Start plant Benachrichtigung, Pause/Stopp storniert sie', () async {
    final c = make();
    await c.init();
    await c.setDuration(const Duration(minutes: 5));
    await c.start();
    expect(c.status, TimerStatus.running);
    expect(notes.scheduledEndMs, clock.wallMs() + 300000);
    expect(audio.log, contains('music:music_calm'));
    await c.pause();
    expect(notes.scheduledEndMs, isNull);
    await c.resume();
    expect(notes.scheduledEndMs, isNotNull);
    await c.stop();
    expect(c.status, TimerStatus.idle);
    expect(notes.scheduledEndMs, isNull);
    c.dispose();
  });

  test('Laufender Timer wird nach Neustart wiederhergestellt', () async {
    var c = make();
    await c.init();
    await c.setDuration(const Duration(minutes: 10));
    await c.start();
    clock.advance(const Duration(minutes: 2));
    c.dispose();

    // Prozessende + Neustart 3 Minuten später (Wanduhr), neue monotone Uhr
    final clock2 = FakeClock(wall: clock.wallMs() + 180000);
    final c2 = buildTestController(
      settings: SettingsRepository(store),
      store: store,
      clock: clock2,
      audio: audio,
      notifications: notes,
    );
    await c2.init();
    expect(c2.status, TimerStatus.running);
    expect(c2.engine.remainingMs, 5 * 60000);
    c2.dispose();
  });

  test('Ablauf während die App geschlossen war', () async {
    final c = make();
    await c.init();
    await c.setDuration(const Duration(minutes: 1));
    await c.start();
    c.dispose();
    final c2 = buildTestController(
      settings: SettingsRepository(store),
      store: store,
      clock: FakeClock(wall: clock.wallMs() + 3600000),
      audio: audio,
      notifications: notes,
    );
    await c2.init();
    expect(c2.status, TimerStatus.finished);
    expect(c2.finishedWhileAway, isTrue);
    c2.dispose();
  });

  test('Dauer wird gespeichert und beim Start geladen', () async {
    final c = make();
    await c.init();
    await c.setDuration(const Duration(minutes: 15));
    c.dispose();
    final c2 = make();
    await c2.init();
    expect(c2.engine.totalMs, 15 * 60000);
    c2.dispose();
  });

  test('Dauer ist während Lauf gesperrt', () async {
    final c = make();
    await c.init();
    await c.setDuration(const Duration(minutes: 5));
    await c.start();
    await c.setDuration(const Duration(minutes: 30));
    expect(c.engine.totalMs, 5 * 60000);
    c.dispose();
  });

  test('Ende spielt Alarm, stoppt Musik; Pro-Alarm fällt in Free zurück', () {
    fakeAsync((fa) {
      settings.alarmId = 'alarm_harp'; // Pro
      final c = make();
      c.init();
      fa.flushMicrotasks();
      c.setDuration(const Duration(seconds: 3));
      fa.flushMicrotasks();
      c.start();
      fa.flushMicrotasks();
      clock.advance(const Duration(seconds: 4));
      fa.elapse(const Duration(seconds: 1));
      fa.flushMicrotasks();
      expect(c.status, TimerStatus.finished);
      expect(audio.log, contains('alarm:alarm_bell'));
      expect(audio.log, isNot(contains('alarm:alarm_harp')));
      c.dispose();
    });
  });

  test('Stumm: kein Ton, Benachrichtigung bleibt', () async {
    await settings.update((s) => s.muted = true);
    final c = make();
    await c.init();
    await c.setDuration(const Duration(minutes: 1));
    await c.start();
    expect(audio.log.where((e) => e.startsWith('music')), isEmpty);
    expect(notes.scheduledEndMs, isNotNull);
    c.dispose();
  });

  test('Ruhiger Modus: keine Musik', () async {
    await settings.update((s) => s.calmMode = true);
    final c = make();
    await c.init();
    await c.start();
    expect(audio.log.where((e) => e.startsWith('music')), isEmpty);
    c.dispose();
  });

  test('Countdown 3-2-1 startet Timer erst danach', () {
    fakeAsync((fa) {
      settings.countdown321 = true;
      final c = make();
      c.init();
      fa.flushMicrotasks();
      c.start();
      fa.flushMicrotasks();
      expect(c.countdown, 3);
      expect(c.status, TimerStatus.idle);
      fa.elapse(const Duration(seconds: 3));
      fa.flushMicrotasks();
      expect(c.countdown, isNull);
      expect(c.status, TimerStatus.running);
      c.dispose();
    });
  });

  test('Beschädigter Snapshot wird ignoriert', () async {
    await store.setString(TimerController.snapshotKey, '{kaputt');
    final c = make();
    await c.init();
    expect(c.status, TimerStatus.idle);
    c.dispose();
  });
}
