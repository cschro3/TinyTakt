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
  Future<void> playSfx(Sfx sfx, double volume);
  Future<void> stopAll();
  Future<void> speak(String text, String languageCode);
  Future<void> dispose();
}

/// Kurze Effekt-Klänge (nicht wählbar; getrennt von der Musik regelbar).
enum Sfx {
  start('audio/sfx_start.m4a'),
  tick('audio/sfx_tick.m4a');

  const Sfx(this.asset);
  final String asset;
}

/// Lokales Audio ohne Streaming.
///
/// Es wird bewusst **kein** Hintergrund-Audio angefordert: Musik pausiert,
/// wenn die App in den Hintergrund geht; der Timer-Alarm im Hintergrund kommt
/// über die Systembenachrichtigung. iOS nutzt die Kategorie „ambient“
/// (respektiert Stumm-Schalter, mischt sich mit anderen Apps); Android nutzt
/// Audio-Fokus mit Ducking.
///
/// Zwei Musik-Player erlauben weiche Übergänge (Crossfade) beim Titelwechsel.
/// Alle Pegel werden über [maxMusic]/[maxEffects] begrenzt (Kinderohren).
class AudioService implements AudioPort {
  AudioService() {
    for (final p in _musicPlayers) {
      p.setAudioContext(_ctx(loop: true));
    }
    _alarm.setAudioContext(_ctx(loop: false));
    _sfx.setAudioContext(_ctx(loop: false));
  }

  /// Obergrenzen, damit auch ein voll aufgedrehter Regler nie unangenehm laut ist.
  static const double maxMusic = 0.8;
  static const double maxEffects = 0.9;

  final List<AudioPlayer> _musicPlayers = [
    AudioPlayer(playerId: 'music_a'),
    AudioPlayer(playerId: 'music_b'),
  ];
  int _active = 0;
  final AudioPlayer _alarm = AudioPlayer(playerId: 'alarm');
  final AudioPlayer _sfx = AudioPlayer(playerId: 'sfx');
  FlutterTts? _tts;
  Timer? _fade;
  double _musicTarget = 0;
  double _musicCurrent = 0;
  double _outgoingCurrent = 0;

  AudioPlayer get _music => _musicPlayers[_active];
  AudioPlayer get _other => _musicPlayers[1 - _active];

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

  double _m(double v) => (v * maxMusic).clamp(0.0, maxMusic);
  double _e(double v) => (v * maxEffects).clamp(0.0, maxEffects);

  @override
  Future<void> playMusic(SoundSpec s, double volume) async {
    _fade?.cancel();
    if (s.asset.isEmpty || volume <= 0) {
      await _music.stop();
      await _other.stop();
      return;
    }
    // Crossfade: der bisherige Titel blendet aus, der neue gleichzeitig ein.
    final outgoing = _music;
    _outgoingCurrent = _musicCurrent;
    _active = 1 - _active;
    final incoming = _music;
    _musicTarget = volume;
    _musicCurrent = 0;
    try {
      await incoming.stop();
      await incoming.setReleaseMode(ReleaseMode.loop);
      await incoming.setVolume(0);
      await incoming.play(AssetSource(s.asset));
      _crossfade(
        outgoing,
        incoming,
        volume,
        const Duration(milliseconds: 1600),
      );
    } catch (e) {
      debugPrint('Musik nicht abspielbar: $e');
    }
  }

  void _crossfade(AudioPlayer out, AudioPlayer inn, double target, Duration d) {
    const step = Duration(milliseconds: 50);
    final steps = (d.inMilliseconds / step.inMilliseconds)
        .clamp(1, 1000)
        .toInt();
    final from = _outgoingCurrent;
    var i = 0;
    _fade = Timer.periodic(step, (t) async {
      i++;
      final k = (i / steps).clamp(0.0, 1.0);
      _musicCurrent = target * k;
      _outgoingCurrent = from * (1 - k);
      await inn.setVolume(_m(_musicCurrent));
      await out.setVolume(_m(_outgoingCurrent));
      if (i >= steps) {
        t.cancel();
        await out.stop();
        _outgoingCurrent = 0;
      }
    });
  }

  void _rampTo(double target, Duration d, {VoidCallback? done}) {
    _fade?.cancel();
    const step = Duration(milliseconds: 50);
    final steps = (d.inMilliseconds / step.inMilliseconds)
        .clamp(1, 1000)
        .toInt();
    var i = 0;
    final from = _musicCurrent;
    _fade = Timer.periodic(step, (t) async {
      i++;
      final v = from + (target - from) * (i / steps);
      _musicCurrent = v;
      await _music.setVolume(_m(v));
      if (i >= steps) {
        t.cancel();
        done?.call();
      }
    });
  }

  @override
  Future<void> fadeOutMusic() async {
    final c = Completer<void>();
    _rampTo(
      0,
      const Duration(milliseconds: 1200),
      done: () async {
        await _music.stop();
        await _other.stop();
        c.complete();
      },
    );
    await c.future;
  }

  @override
  Future<void> setMusicVolume(double v) async {
    _fade?.cancel();
    _musicTarget = v;
    _musicCurrent = v;
    await _music.setVolume(_m(v));
    if (v <= 0) await _other.stop();
  }

  @override
  Future<void> playAlarm(SoundSpec s, double volume) async {
    if (s.asset.isEmpty || volume <= 0) return;
    try {
      await _alarm.setVolume(_e(volume));
      await _alarm.play(AssetSource(s.asset));
    } catch (e) {
      debugPrint('Alarm nicht abspielbar: $e');
    }
  }

  @override
  Future<void> playSfx(Sfx sfx, double volume) async {
    if (volume <= 0) return;
    try {
      await _sfx.setVolume(_e(volume));
      await _sfx.play(AssetSource(sfx.asset));
    } catch (e) {
      debugPrint('Effekt nicht abspielbar: $e');
    }
  }

  @override
  Future<void> playTick(double volume) => playSfx(Sfx.tick, volume);

  @override
  Future<void> stopAll() async {
    _fade?.cancel();
    for (final p in _musicPlayers) {
      await p.stop();
    }
    _musicCurrent = 0;
    await _alarm.stop();
    await _sfx.stop();
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
    for (final p in _musicPlayers) {
      await p.dispose();
    }
    await _alarm.dispose();
    await _sfx.dispose();
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
  Future<void> playSfx(Sfx sfx, double volume) async =>
      log.add('sfx:${sfx.name}');
  @override
  Future<void> stopAll() async => log.add('stop');
  @override
  Future<void> speak(String text, String languageCode) async =>
      log.add('speak:$text');
  @override
  Future<void> dispose() async {}
}
