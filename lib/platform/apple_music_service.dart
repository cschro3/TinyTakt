import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reservierte Musik-ID im Profil: „Titel aus Apple Music“.
const String appleMusicSoundId = 'apple_music';

enum AppleMusicAuth {
  unsupported,
  notDetermined,
  denied,
  restricted,
  authorized,
}

/// Ein ausgewählter Titel aus dem Apple-Music-Katalog (nur Verweis, keine Audiodaten).
class AppleMusicTrack {
  const AppleMusicTrack({
    required this.id,
    required this.title,
    required this.artist,
  });
  final String id, title, artist;

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'artist': artist};

  static AppleMusicTrack? fromJson(Object? m) {
    if (m is! Map) return null;
    final id = m['id'], title = m['title'], artist = m['artist'];
    if (id is! String || id.isEmpty || title is! String) return null;
    return AppleMusicTrack(
      id: id,
      title: title,
      artist: artist is String ? artist : '',
    );
  }
}

class AppleMusicException implements Exception {
  AppleMusicException(this.code, [this.message]);
  final String code;
  final String? message;
  @override
  String toString() =>
      'AppleMusicException($code${message == null ? '' : ': $message'})';
}

/// Optionale Apple-Music-Anbindung (nur iOS/iPadOS über MusicKit).
///
/// Datenschutz: Katalogsuche und Wiedergabe laufen über Apple; TinyTakt
/// speichert nur Titel-ID, Titel und Künstler als lokale Auswahl. Alle
/// Aufrufe zum Suchen/Verbinden liegen hinter der Elternsicherung.
abstract class AppleMusicPort {
  bool get isSupported;
  Future<AppleMusicAuth> authorizationStatus();
  Future<AppleMusicAuth> requestAuthorization();

  /// true, wenn ein aktives Apple-Music-Abo Katalogtitel abspielen kann.
  Future<bool> canPlay();

  /// Sucht Titel; nicht jugendfreie (explizite) Titel werden nativ herausgefiltert.
  Future<List<AppleMusicTrack>> search(String query);
  Future<void> play(String trackId);
  Future<void> pause();
  Future<void> stop();
}

class MethodChannelAppleMusic implements AppleMusicPort {
  MethodChannelAppleMusic({MethodChannel? channel, bool? supported})
    : _ch = channel ?? const MethodChannel('app.tinytakt/apple_music'),
      _supported =
          supported ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  final MethodChannel _ch;
  final bool _supported;

  @override
  bool get isSupported => _supported;

  static AppleMusicAuth _auth(Object? v) => switch (v) {
    'authorized' => AppleMusicAuth.authorized,
    'denied' => AppleMusicAuth.denied,
    'restricted' => AppleMusicAuth.restricted,
    'notDetermined' => AppleMusicAuth.notDetermined,
    _ => AppleMusicAuth.unsupported,
  };

  Future<T?> _call<T>(String method, [Object? args]) async {
    if (!_supported) throw AppleMusicException('unsupported');
    try {
      return await _ch.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw AppleMusicException(e.code, e.message);
    } on MissingPluginException {
      throw AppleMusicException('unsupported');
    }
  }

  @override
  Future<AppleMusicAuth> authorizationStatus() async {
    if (!_supported) return AppleMusicAuth.unsupported;
    try {
      return _auth(await _call<String>('authorizationStatus'));
    } on AppleMusicException {
      return AppleMusicAuth.unsupported;
    }
  }

  @override
  Future<AppleMusicAuth> requestAuthorization() async =>
      _auth(await _call<String>('requestAuthorization'));

  @override
  Future<bool> canPlay() async {
    try {
      return await _call<bool>('canPlay') ?? false;
    } on AppleMusicException {
      return false;
    }
  }

  @override
  Future<List<AppleMusicTrack>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final raw = await _call<List<Object?>>('search', {'query': q});
    return (raw ?? const [])
        .map(AppleMusicTrack.fromJson)
        .whereType<AppleMusicTrack>()
        .toList();
  }

  @override
  Future<void> play(String trackId) => _call<void>('play', {'id': trackId});
  @override
  Future<void> pause() async {
    try {
      await _call<void>('pause');
    } on AppleMusicException {
      // Nichts zu pausieren.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _call<void>('stop');
    } on AppleMusicException {
      // Nichts zu stoppen.
    }
  }
}

/// Android, Web und alle Plattformen ohne MusicKit.
class UnavailableAppleMusic implements AppleMusicPort {
  @override
  bool get isSupported => false;
  @override
  Future<AppleMusicAuth> authorizationStatus() async =>
      AppleMusicAuth.unsupported;
  @override
  Future<AppleMusicAuth> requestAuthorization() async =>
      AppleMusicAuth.unsupported;
  @override
  Future<bool> canPlay() async => false;
  @override
  Future<List<AppleMusicTrack>> search(String query) async => const [];
  @override
  Future<void> play(String trackId) async =>
      throw AppleMusicException('unsupported');
  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
}

/// Testdouble.
class FakeAppleMusic implements AppleMusicPort {
  FakeAppleMusic({
    this.supported = true,
    this.auth = AppleMusicAuth.authorized,
    this.subscribed = true,
    this.catalog = const [
      AppleMusicTrack(id: 'a1', title: 'Sonnenlied', artist: 'Ensemble Eins'),
      AppleMusicTrack(id: 'a2', title: 'Mondschein', artist: 'Ensemble Zwei'),
    ],
  });
  bool supported;
  AppleMusicAuth auth;
  bool subscribed;
  List<AppleMusicTrack> catalog;
  final List<String> log = [];
  bool failPlay = false;
  Duration authDelay = Duration.zero;
  Duration playDelay = Duration.zero;

  @override
  bool get isSupported => supported;
  @override
  Future<AppleMusicAuth> authorizationStatus() async {
    if (authDelay > Duration.zero) await Future<void>.delayed(authDelay);
    return supported ? auth : AppleMusicAuth.unsupported;
  }

  @override
  Future<AppleMusicAuth> requestAuthorization() async {
    log.add('request');
    if (auth == AppleMusicAuth.notDetermined) auth = AppleMusicAuth.authorized;
    return auth;
  }

  @override
  Future<bool> canPlay() async => subscribed;
  @override
  Future<List<AppleMusicTrack>> search(String query) async {
    log.add('search:$query');
    final q = query.toLowerCase();
    return catalog
        .where(
          (t) =>
              t.title.toLowerCase().contains(q) ||
              t.artist.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<void> play(String trackId) async {
    if (failPlay) throw AppleMusicException('not_authorized');
    log.add('play:$trackId');
    if (playDelay > Duration.zero) await Future<void>.delayed(playDelay);
  }

  @override
  Future<void> pause() async => log.add('pause');
  @override
  Future<void> stop() async => log.add('stop');
}
