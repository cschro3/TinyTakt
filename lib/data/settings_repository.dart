import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/catalog.dart';
import 'stores.dart';

/// Ein lokales, anonymes Profil (Spitzname statt echtem Namen).
class KidProfile {
  const KidProfile({
    required this.id,
    required this.nickname,
    this.characterId = 'dog',
    this.backgroundId = 'meadow',
    this.style = TimerStyle.circle,
    this.musicId = 'music_calm',
  });
  final String id, nickname, characterId, backgroundId, musicId;
  final TimerStyle style;

  KidProfile copyWith({
    String? nickname,
    String? characterId,
    String? backgroundId,
    TimerStyle? style,
    String? musicId,
  }) => KidProfile(
    id: id,
    nickname: nickname ?? this.nickname,
    characterId: characterId ?? this.characterId,
    backgroundId: backgroundId ?? this.backgroundId,
    style: style ?? this.style,
    musicId: musicId ?? this.musicId,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'nickname': nickname,
    'characterId': characterId,
    'backgroundId': backgroundId,
    'style': style.name,
    'musicId': musicId,
  };

  static KidProfile? fromJson(Object? m) {
    if (m is! Map) return null;
    final id = m['id'];
    final nick = m['nickname'];
    if (id is! String || nick is! String) return null;
    return KidProfile(
      id: id,
      nickname: nick,
      characterId: m['characterId'] is String
          ? m['characterId'] as String
          : 'dog',
      backgroundId: m['backgroundId'] is String
          ? m['backgroundId'] as String
          : 'meadow',
      style: TimerStyle.values.firstWhere(
        (s) => s.name == m['style'],
        orElse: () => TimerStyle.circle,
      ),
      musicId: m['musicId'] is String ? m['musicId'] as String : 'music_calm',
    );
  }
}

/// Vorlage für wiederkehrende Aufgaben (z. B. „Zähneputzen 2 Min.“).
class TimerTemplate {
  const TimerTemplate({
    required this.id,
    required this.name,
    required this.seconds,
    this.characterId,
  });
  final String id, name;
  final int seconds;
  final String? characterId;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'seconds': seconds,
    'characterId': characterId,
  };

  static TimerTemplate? fromJson(Object? m) {
    if (m is! Map) return null;
    final id = m['id'], name = m['name'], sec = m['seconds'];
    if (id is! String || name is! String || sec is! int || sec <= 0)
      return null;
    return TimerTemplate(
      id: id,
      name: name,
      seconds: sec,
      characterId: m['characterId'] as String?,
    );
  }
}

/// Alle Einstellungen, ausschließlich lokal gespeichert.
class SettingsRepository extends ChangeNotifier {
  SettingsRepository(this._store) {
    _load();
  }

  final KeyValueStore _store;
  static const _k = 'settings.v1';
  static const maxProfilesPro = 5;
  static const maxTemplates = 12;

  double musicVolume = 0.6;
  double alarmVolume = 0.8;
  bool muted = false;
  bool countdown321 = false;
  bool speech = false;
  bool calmMode = false;
  bool repeat = false;
  bool keepScreenOn = true;
  bool lockWhileRunning = true;
  bool onboardingDone = false;
  String alarmId = 'alarm_bell';
  int lastSeconds = 300;
  String activeProfileId = 'p1';
  List<KidProfile> profiles = const [KidProfile(id: 'p1', nickname: 'Ich')];
  List<TimerTemplate> templates = const [];
  List<String> customMotifs = const [];

  KidProfile get profile => profiles.firstWhere(
    (p) => p.id == activeProfileId,
    orElse: () => profiles.first,
  );

  void _load() {
    final raw = _store.getString(_k);
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      musicVolume = _d(m['musicVolume'], musicVolume);
      alarmVolume = _d(m['alarmVolume'], alarmVolume);
      muted = m['muted'] == true;
      countdown321 = m['countdown321'] == true;
      speech = m['speech'] == true;
      calmMode = m['calmMode'] == true;
      repeat = m['repeat'] == true;
      keepScreenOn = m['keepScreenOn'] != false;
      lockWhileRunning = m['lockWhileRunning'] != false;
      onboardingDone = m['onboardingDone'] == true;
      alarmId = m['alarmId'] is String ? m['alarmId'] as String : alarmId;
      lastSeconds = m['lastSeconds'] is int && (m['lastSeconds'] as int) > 0
          ? m['lastSeconds'] as int
          : lastSeconds;
      final ps = (m['profiles'] as List?)
          ?.map(KidProfile.fromJson)
          .whereType<KidProfile>()
          .toList();
      if (ps != null && ps.isNotEmpty) profiles = ps;
      activeProfileId = m['activeProfileId'] is String
          ? m['activeProfileId'] as String
          : profiles.first.id;
      templates =
          (m['templates'] as List?)
              ?.map(TimerTemplate.fromJson)
              .whereType<TimerTemplate>()
              .toList() ??
          const [];
      customMotifs =
          (m['customMotifs'] as List?)?.whereType<String>().toList() ??
          const [];
    } catch (_) {
      // Beschädigte Einstellungen: Standardwerte behalten.
    }
  }

  double _d(Object? v, double fallback) =>
      v is num ? v.toDouble().clamp(0.0, 1.0) : fallback;

  Future<void> _save() async {
    notifyListeners();
    await _store.setString(
      _k,
      jsonEncode({
        'musicVolume': musicVolume,
        'alarmVolume': alarmVolume,
        'muted': muted,
        'countdown321': countdown321,
        'speech': speech,
        'calmMode': calmMode,
        'repeat': repeat,
        'keepScreenOn': keepScreenOn,
        'lockWhileRunning': lockWhileRunning,
        'onboardingDone': onboardingDone,
        'alarmId': alarmId,
        'lastSeconds': lastSeconds,
        'activeProfileId': activeProfileId,
        'profiles': profiles.map((p) => p.toJson()).toList(),
        'templates': templates.map((t) => t.toJson()).toList(),
        'customMotifs': customMotifs,
      }),
    );
  }

  Future<void> update(void Function(SettingsRepository s) change) {
    change(this);
    return _save();
  }

  Future<void> updateProfile(KidProfile Function(KidProfile p) change) {
    profiles = [
      for (final p in profiles) p.id == activeProfileId ? change(p) : p,
    ];
    return _save();
  }

  Future<bool> addProfile(String nickname, {required bool isPro}) async {
    if (!isPro && profiles.isNotEmpty) return false;
    if (profiles.length >= maxProfilesPro) return false;
    final id = 'p${DateTime.now().microsecondsSinceEpoch}';
    profiles = [
      ...profiles,
      KidProfile(
        id: id,
        nickname: nickname.trim().isEmpty ? 'Kind' : nickname.trim(),
      ),
    ];
    activeProfileId = id;
    await _save();
    return true;
  }

  Future<void> removeProfile(String id) async {
    if (profiles.length <= 1) return;
    profiles = profiles.where((p) => p.id != id).toList();
    if (activeProfileId == id) activeProfileId = profiles.first.id;
    await _save();
  }

  Future<bool> addTemplate(TimerTemplate t, {required bool isPro}) async {
    if (!isPro || templates.length >= maxTemplates) return false;
    templates = [...templates, t];
    await _save();
    return true;
  }

  Future<void> removeTemplate(String id) async {
    templates = templates.where((t) => t.id != id).toList();
    await _save();
  }
}
