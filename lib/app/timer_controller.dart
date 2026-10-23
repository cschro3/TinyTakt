import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/settings_repository.dart';
import '../data/stores.dart';
import '../domain/catalog.dart';
import '../domain/clock.dart';
import '../domain/timer_engine.dart';
import '../platform/audio_service.dart';
import '../platform/notification_service.dart';

/// Verbindet die reine [TimerEngine] mit Persistenz, Audio und Benachrichtigungen.
/// Enthält keine UI und keine Animation.
class TimerController extends ChangeNotifier with WidgetsBindingObserver {
  TimerController({
    required this.engine,
    required this.settings,
    required this.store,
    required this.audio,
    required this.notifications,
    required this.languageCode,
    void Function(bool on)? keepAwake,
    this.isPro = _no,
  }) : _keepAwake = keepAwake ?? ((_) {});

  static bool _no() => false;

  final TimerEngine engine;
  final SettingsRepository settings;
  final KeyValueStore store;
  final AudioPort audio;
  final NotificationPort notifications;
  final String Function() languageCode;
  final bool Function() isPro;
  final void Function(bool) _keepAwake;

  static const snapshotKey = 'timer.snapshot';

  Timer? _poll;
  int? countdown; // 3,2,1 vor dem Start
  Timer? _countdownTimer;
  bool _disposed = false;

  /// Wird gesetzt, wenn der Timer ablief, während die App nicht lief.
  bool finishedWhileAway = false;

  TimerStatus get status => engine.status;
  bool get isCountingDown => countdown != null;
  bool get isRunning => engine.status == TimerStatus.running;

  SoundSpec get _music {
    final s = soundById(settings.profile.musicId);
    return (s.pro && !isPro()) ? soundById('music_calm') : s;
  }

  SoundSpec get _alarm {
    final s = soundById(settings.alarmId);
    return (s.pro && !isPro()) ? soundById('alarm_bell') : s;
  }

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    engine.repeat = settings.repeat;
    final snap = TimerSnapshot.tryDecode(store.getString(snapshotKey));
    if (snap != null) {
      final expired = engine.restore(snap);
      if (expired) {
        finishedWhileAway = true;
        await _persist();
      } else if (engine.status == TimerStatus.running) {
        _startPolling();
        _keepAwake(settings.keepScreenOn);
        _startMusic();
        await _scheduleNotification();
      }
    } else {
      engine.setDuration(Duration(seconds: settings.lastSeconds));
    }
    notifyListeners();
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    if (engine.tick()) {
      _onFinished();
    }
    notifyListeners();
  }

  Future<void> _persist() =>
      store.setString(snapshotKey, engine.snapshot().encode());

  Future<void> setDuration(Duration d) async {
    if (isRunning || engine.status == TimerStatus.paused || isCountingDown)
      return;
    engine.setDuration(d);
    finishedWhileAway = false;
    await settings.update((s) => s.lastSeconds = d.inSeconds);
    await _persist();
    notifyListeners();
  }

  Future<void> start() async {
    if (isRunning || isCountingDown) return;
    finishedWhileAway = false;
    if (engine.status == TimerStatus.paused) return resume();
    if (engine.status == TimerStatus.finished) {
      engine.setDuration(Duration(milliseconds: engine.totalMs));
    }
    if (settings.countdown321 && !settings.muted) {
      countdown = 3;
      notifyListeners();
      await audio.playTick(settings.alarmVolume);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
        final c = (countdown ?? 1) - 1;
        if (c <= 0) {
          t.cancel();
          countdown = null;
          await _begin();
        } else {
          countdown = c;
          await audio.playTick(settings.alarmVolume);
          notifyListeners();
        }
      });
      return;
    }
    await _begin();
  }

  Future<void> _begin() async {
    engine.repeat = settings.repeat;
    engine.start();
    _startPolling();
    _keepAwake(settings.keepScreenOn);
    await _persist();
    _startMusic();
    await _scheduleNotification();
    notifyListeners();
  }

  Future<void> pause() async {
    if (!isRunning) return;
    engine.pause();
    _poll?.cancel();
    _keepAwake(false);
    await audio.fadeOutMusic();
    await notifications.cancel();
    await _persist();
    notifyListeners();
  }

  Future<void> resume() async {
    if (engine.status != TimerStatus.paused) return;
    engine.resume();
    _startPolling();
    _keepAwake(settings.keepScreenOn);
    _startMusic();
    await _scheduleNotification();
    await _persist();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (isCountingDown) return cancelCountdown();
    if (isRunning) return pause();
    return start();
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    countdown = null;
    notifyListeners();
  }

  /// Stoppt und stellt die volle Dauer wieder her.
  Future<void> stop() async {
    cancelCountdown();
    engine.stop();
    _poll?.cancel();
    _keepAwake(false);
    finishedWhileAway = false;
    await audio.stopAll();
    await notifications.cancel();
    await _persist();
    notifyListeners();
  }

  Future<void> applySettings() async {
    engine.repeat = settings.repeat;
    if (isRunning) {
      await audio.setMusicVolume(settings.muted ? 0 : settings.musicVolume);
    }
    notifyListeners();
  }

  Future<void> changeMusic() async {
    if (isRunning) await _startMusic();
  }

  Future<void> _startMusic() async {
    if (settings.muted || settings.calmMode) return;
    await audio.playMusic(_music, settings.musicVolume);
  }

  Future<void> _scheduleNotification() async {
    final end = engine.endWallMs;
    if (end == null) return;
    final de = languageCode() == 'de';
    await notifications.scheduleEnd(
      endWallMs: end,
      title: de ? 'Die Zeit ist um!' : 'Time is up!',
      body: de
          ? 'Gut gemacht – dein Timer ist fertig.'
          : 'Well done – your timer is finished.',
    );
  }

  Future<void> _onFinished() async {
    await notifications.cancel();
    _keepAwake(
      engine.status == TimerStatus.running ? settings.keepScreenOn : false,
    );
    if (engine.status != TimerStatus.running) _poll?.cancel();
    await _persist();
    if (!settings.muted) {
      await audio.fadeOutMusic();
      await audio.playAlarm(_alarm, settings.alarmVolume);
      if (settings.speech) {
        await audio.speak(
          languageCode() == 'de'
              ? 'Die Zeit ist um! Gut gemacht!'
              : 'Time is up! Well done!',
          languageCode(),
        );
      }
    }
    if (engine.status == TimerStatus.running) {
      await _scheduleNotification();
      await _startMusic();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (isRunning) {
          _tick(); // Zeit anhand der gespeicherten Zeitbasis neu berechnen
          if (isRunning) _startMusic();
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Kein Hintergrund-Audio: Musik stoppt. Der Timer läuft zeitbasiert weiter,
        // das Ende meldet die geplante Benachrichtigung.
        if (state != AppLifecycleState.inactive) {
          audio.stopAll();
          if (isRunning) _persist();
        }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}

TimerController buildTestController({
  required SettingsRepository settings,
  required KeyValueStore store,
  required Clock clock,
  AudioPort? audio,
  NotificationPort? notifications,
  bool pro = false,
}) => TimerController(
  engine: TimerEngine(clock),
  settings: settings,
  store: store,
  audio: audio ?? SilentAudioService(),
  notifications: notifications ?? NoopNotificationService(),
  languageCode: () => 'de',
  isPro: () => pro,
);
