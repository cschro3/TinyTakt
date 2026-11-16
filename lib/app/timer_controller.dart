import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/settings_repository.dart';
import '../data/stores.dart';
import '../domain/catalog.dart';
import '../domain/clock.dart';
import '../domain/session_plan.dart';
import '../domain/timer_engine.dart';
import '../platform/apple_music_service.dart';
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
    this.appleMusic,
  }) : _keepAwake = keepAwake ?? ((_) {});

  static bool _no() => false;

  final TimerEngine engine;
  final SettingsRepository settings;
  final KeyValueStore store;
  final AudioPort audio;
  final AppleMusicPort? appleMusic;
  bool _appleActive = false;
  int _musicGen =
      0; // verwirft Musikstarts, die durch Pause/Stopp überholt wurden
  final NotificationPort notifications;
  final String Function() languageCode;
  final bool Function() isPro;
  final void Function(bool) _keepAwake;

  static const snapshotKey = 'timer.snapshot';

  Timer? _poll;
  int? countdown; // 3,2,1 vor dem Start
  Timer? _countdownTimer;
  bool _disposed = false;
  int? _lastStep; // Phase im Lern-/Spielplan, für Phasenwechsel-Erkennung

  /// Wird gesetzt, wenn der Timer ablief, während die App nicht lief.
  bool finishedWhileAway = false;

  TimerStatus get status => engine.status;
  bool get isCountingDown => countdown != null;
  bool get isRunning => engine.status == TimerStatus.running;

  /// Aktiver Lern-/Spielplan (nur wenn er zur Engine-Dauer passt).
  SessionPlan? get plan {
    final p = settings.plan;
    return (p != null && p.totalMs == engine.totalMs) ? p : null;
  }

  /// Position im Plan bzw. null ohne Plan.
  PlanView? get planView {
    final p = plan;
    if (p == null) return null;
    final elapsed = engine.status == TimerStatus.finished
        ? p.totalMs
        : engine.totalMs - engine.remainingMs;
    return p.viewAt(elapsed);
  }

  /// Anteil der aktuellen Phase (bzw. der ganzen Zeit ohne Plan), 1 → 0.
  double get displayFraction {
    if (engine.status == TimerStatus.finished) return 0;
    final v = planView;
    return v == null ? engine.fractionRemaining : v.stepFraction;
  }

  /// Angezeigte Sekunden der aktuellen Phase (bzw. der ganzen Zeit ohne Plan).
  int get displaySeconds {
    if (engine.status == TimerStatus.finished) return 0;
    final v = planView;
    return v == null
        ? engine.displaySeconds
        : (v.stepRemainingMs + 999) ~/ 1000;
  }

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
    final snap = TimerSnapshot.tryDecode(store.getString(snapshotKey));
    if (snap != null) {
      final expired = engine.restore(snap);
      engine.repeat = settings.repeat && plan == null;
      _lastStep = planView?.index;
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
      final p = settings.plan;
      engine.setDuration(
        p != null
            ? Duration(milliseconds: p.totalMs)
            : Duration(seconds: settings.lastSeconds),
      );
    }
    engine.repeat = settings.repeat && plan == null;
    notifyListeners();
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    if (engine.tick()) {
      _onFinished();
    } else {
      _checkStepChange();
    }
    notifyListeners();
  }

  /// Phasenwechsel im Lern-/Spielplan: sanfter Ton, Musik passend zur Phase.
  void _checkStepChange() {
    final v = planView;
    if (v == null || !isRunning) return;
    final last = _lastStep;
    _lastStep = v.index;
    if (last == null || last == v.index) return;
    _onStepChanged(v);
  }

  Future<void> _onStepChanged(PlanView v) async {
    if (settings.muted) return;
    await audio.playAlarm(_alarm, settings.alarmVolume * 0.8);
    if (settings.speech) {
      final de = languageCode() == 'de';
      await audio.speak(
        v.isPause
            ? (de ? 'Pause! Ruh dich aus.' : 'Break time! Rest a little.')
            : (de ? 'Weiter geht’s!' : 'Let’s go on!'),
        languageCode(),
      );
    }
    if (v.isPause) {
      await audio.fadeOutMusic();
      await _pauseAppleMusic();
    } else {
      await _startMusic();
    }
  }

  /// Lern-/Spielplan setzen (nur im Leerlauf) oder mit `null` entfernen.
  Future<void> setPlan(SessionPlan? p) async {
    if (isRunning || engine.status == TimerStatus.paused || isCountingDown)
      return;
    if (p != null && !p.isValid) return;
    settings.plan = p;
    engine.setDuration(
      p != null
          ? Duration(milliseconds: p.totalMs)
          : Duration(seconds: settings.lastSeconds),
    );
    engine.repeat = settings.repeat && plan == null;
    finishedWhileAway = false;
    _lastStep = null;
    await settings.update((_) {});
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() =>
      store.setString(snapshotKey, engine.snapshot().encode());

  Future<void> setDuration(Duration d) async {
    if (isRunning || engine.status == TimerStatus.paused || isCountingDown)
      return;
    engine.setDuration(d);
    finishedWhileAway = false;
    _lastStep = null;
    await settings.update((s) {
      s.lastSeconds = d.inSeconds;
      s.plan = null; // eine Einzelzeit ersetzt den Plan
    });
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
    engine.repeat = settings.repeat && plan == null;
    engine.start();
    _lastStep = planView?.index;
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
    await _pauseAppleMusic();
    await notifications.cancel();
    await _persist();
    notifyListeners();
  }

  Future<void> resume() async {
    if (engine.status != TimerStatus.paused) return;
    engine.resume();
    _lastStep = planView?.index;
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
    await _pauseAppleMusic();
    await notifications.cancel();
    await _persist();
    notifyListeners();
  }

  Future<void> applySettings() async {
    engine.repeat = settings.repeat && plan == null;
    if (isRunning) {
      await audio.setMusicVolume(settings.muted ? 0 : settings.musicVolume);
      if (settings.muted || settings.calmMode) await _pauseAppleMusic();
    }
    notifyListeners();
  }

  Future<void> changeMusic() async {
    if (isRunning) await _startMusic();
  }

  Future<void> _startMusic() async {
    if (settings.muted || settings.calmMode) return;
    if (planView?.isPause ?? false) return; // Pausenphase: Ruhe
    final gen = ++_musicGen;
    if (settings.profile.musicId == appleMusicSoundId) {
      final track = settings.appleMusic;
      final am = appleMusic;
      if (track != null && am != null && am.isSupported) {
        try {
          if (await am.authorizationStatus() == AppleMusicAuth.authorized) {
            if (gen != _musicGen || !isRunning)
              return; // inzwischen pausiert/gestoppt
            await audio.stopAll();
            await am.play(track.id);
            if (gen != _musicGen || !isRunning) {
              await am.pause(); // Start wurde währenddessen überholt
              return;
            }
            _appleActive = true;
            return;
          }
        } on AppleMusicException {
          // Abo fehlt/Wiedergabe nicht möglich: auf eingebaute Musik ausweichen.
        }
      }
      if (gen != _musicGen || !isRunning) return;
      await audio.playMusic(soundById('music_calm'), settings.musicVolume);
      return;
    }
    await _pauseAppleMusic();
    await audio.playMusic(_music, settings.musicVolume);
  }

  /// Apple-Music-Wiedergabe anhalten (Pause, Stopp, Ende, Hintergrund, Stumm).
  Future<void> _pauseAppleMusic() async {
    _musicGen++;
    if (!_appleActive) return;
    _appleActive = false;
    try {
      await appleMusic?.pause();
    } on AppleMusicException {
      // ignorieren
    }
  }

  Future<void> _scheduleNotification() async {
    final end = engine.endWallMs;
    if (end == null) return;
    final de = languageCode() == 'de';
    final p = plan;
    if (p != null) {
      // Jede noch kommende Phasengrenze bekommt eine eigene Benachrichtigung.
      final b = p.boundariesMs;
      final elapsed = engine.totalMs - engine.remainingMs;
      for (var i = 0; i < b.length - 1; i++) {
        if (b[i] <= elapsed) continue;
        final next = p.steps[i + 1];
        final isPause = next.kind == StepKind.pause;
        await notifications.scheduleAt(
          id: 4711 + 1 + i,
          endWallMs: end - (engine.totalMs - b[i]),
          title: isPause
              ? (de ? 'Zeit für eine Pause!' : 'Time for a break!')
              : (de ? 'Weiter geht’s!' : 'Let’s go on!'),
          body: isPause
              ? (de
                    ? 'Gut gemacht – ruh dich kurz aus.'
                    : 'Well done – rest for a moment.')
              : (de ? 'Die Pause ist vorbei.' : 'The break is over.'),
        );
      }
    }
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
      await _pauseAppleMusic();
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
          _pauseAppleMusic();
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
