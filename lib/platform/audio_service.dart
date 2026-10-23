import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../domain/catalog.dart';

/// Abstraktion für Tests und plattformunabhängige Logik.
abstract class AudioPort {
  Future<void> playMusic(SoundSpec s, double volume);
  Future<void> fadeOutMusic();
  Future<void> setMusicVolume(double v);
  Future<void> playAlarm(SoundSpec s, double volume);
  Future<void> playTick(double volume);
  Future<void> stopAll();
  Future<void> speak(String text, String languageCode);
  Future<void> dispose();
}

/// Lokales Audio ohne Streaming.
///
/// Es wird bewusst **kein** Hintergrund-Audio angefordert: Musik pausiert,
/// wenn die App in den Hintergrund geht; der Timer-Alarm im Hintergrund kommt
/// über die Systembenachrichtigung. iOS nutzt die Kategorie „ambient“
/// (respektiert Stumm-Schalter, mischt sich mit anderen Apps); Android nutzt
/// Audio-Fokus mit Ducking.
class AudioService implements AudioPort {
  AudioService() {
    _music.setAudioContext(_ctx(loop: true));
    _alarm.setAudioContext(_ctx(loop: false));
  }

  final AudioPlayer _music = AudioPlayer(playerId: 'music');
  final AudioPlayer _alarm = AudioPlayer(playerId: 'alarm');
  FlutterTts? _tts;
  Timer? _fade;
  double _musicTarget = 0;

  AudioContext _ctx({required bool loop}) => AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
    android: AudioContextAndroid(
      usageType: loop ? AndroidUsageType.media : AndroidUsageType.alarm,
      contentType: loop
          ? AndroidContentType.music
          : AndroidContentType.sonification,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      stayAwake: false,
    ),
  );

  @override
  Future<void> playMusic(SoundSpec s, double volume) async {
    await _music.stop();
    _fade?.cancel();
    if (s.asset.isEmpty || volume <= 0) return;
    _musicTarget = volume;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(0);
      await _music.play(AssetSource(s.asset));
      _rampTo(volume, const Duration(milliseconds: 1500));
    } catch (e) {
      debugPrint('Musik nicht abspielbar: $e');
    }
  }

  void _rampTo(double target, Duration d, {VoidCallback? done}) {
    _fade?.cancel();
    const step = Duration(milliseconds: 50);
    final steps = (d.inMilliseconds / step.inMilliseconds)
        .clamp(1, 1000)
        .toInt();
    var i = 0;
    double? from;
    _fade = Timer.periodic(step, (t) async {
      from ??= _musicCurrent;
      i++;
      final v = from! + (target - from!) * (i / steps);
      await _music.setVolume(v.clamp(0.0, 1.0));
      _musicCurrent = v;
      if (i >= steps) {
        t.cancel();
        done?.call();
      }
    });
  }

  double _musicCurrent = 0;

  @override
  Future<void> fadeOutMusic() async {
    final c = Completer<void>();
    _rampTo(
      0,
      const Duration(milliseconds: 1200),
      done: () async {
        await _music.stop();
        c.complete();
      },
    );
    await c.future;
  }

  @override
  Future<void> setMusicVolume(double v) async {
    _musicTarget = v;
    _musicCurrent = v;
    await _music.setVolume(v);
  }

  @override
  Future<void> playAlarm(SoundSpec s, double volume) async {
    if (s.asset.isEmpty || volume <= 0) return;
    try {
      await _alarm.setVolume(volume);
      await _alarm.play(AssetSource(s.asset));
    } catch (e) {
      debugPrint('Alarm nicht abspielbar: $e');
    }
  }

  @override
  Future<void> playTick(double volume) async {
    // Kurzer, sanfter Ton für den 3-2-1-Countdown (wiederverwendet das Glöckchen).
    await playAlarm(soundById('alarm_bell'), volume * 0.6);
  }

  @override
  Future<void> stopAll() async {
    _fade?.cancel();
    await _music.stop();
    await _alarm.stop();
    await _tts?.stop();
  }

  @override
  Future<void> speak(String text, String languageCode) async {
    try {
      _tts ??= FlutterTts();
      await _tts!.setLanguage(languageCode == 'de' ? 'de-DE' : 'en-US');
      await _tts!.setSpeechRate(0.42);
      await _tts!.speak(text);
    } catch (e) {
      debugPrint('Sprachausgabe nicht verfügbar: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _fade?.cancel();
    await _music.dispose();
    await _alarm.dispose();
  }

  double get musicTarget => _musicTarget;
}

class SilentAudioService implements AudioPort {
  final List<String> log = [];
  @override
  Future<void> playMusic(SoundSpec s, double volume) async =>
      log.add('music:${s.id}');
  @override
  Future<void> fadeOutMusic() async => log.add('fade');
  @override
  Future<void> setMusicVolume(double v) async {}
  @override
  Future<void> playAlarm(SoundSpec s, double volume) async =>
      log.add('alarm:${s.id}');
  @override
  Future<void> playTick(double volume) async => log.add('tick');
  @override
  Future<void> stopAll() async => log.add('stop');
  @override
  Future<void> speak(String text, String languageCode) async =>
      log.add('speak:$text');
  @override
  Future<void> dispose() async {}
}
