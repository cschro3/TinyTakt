import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../domain/catalog.dart';
import 'stores.dart';

/// Verwaltet die Pro-Berechtigung.
///
/// Es wird kein einfaches Boolean gespeichert. Ein Eintrag besteht aus
/// Produkt, Plattform, Transaktionskennung und Zeitpunkt, abgesichert durch
/// einen HMAC (SHA-256). Der HMAC-Schlüssel liegt im Secure Storage
/// (Keychain / Keystore-gestützt), der Eintrag selbst im normalen Speicher.
/// Dadurch genügt das Bearbeiten der Einstellungsdatei nicht zum Freischalten.
///
/// Grenzen (siehe docs/PURCHASES.md): Ein gerootetes Gerät mit Zugriff auf
/// beide Speicher kann dies umgehen. Maßgeblich bleibt der Store; bei
/// jedem Start wird die Berechtigung gegen den Store abgeglichen.
class EntitlementRepository extends ChangeNotifier {
  EntitlementRepository(
    this._store,
    this._secure, {
    String Function()? platformName,
  }) : _platform = platformName ?? (() => defaultTargetPlatform.name);

  final KeyValueStore _store;
  final SecureStore _secure;
  final String Function() _platform;
  static const _recordKey = 'entitlement.v1';
  static const _macKeyName = 'entitlement.mackey';

  bool _isPro = false;
  bool get isPro => _isPro;

  Future<List<int>> _key() async {
    var k = await _secure.read(_macKeyName);
    if (k == null) {
      final r = Random.secure();
      k = base64Encode(List<int>.generate(32, (_) => r.nextInt(256)));
      await _secure.write(_macKeyName, k);
    }
    return base64Decode(k);
  }

  String _canonical(Map<String, Object?> r) =>
      '${r['product']}|${r['platform']}|${r['txId']}|${r['grantedAtMs']}';

  Future<String> _mac(Map<String, Object?> r) async => base64Encode(
    Hmac(sha256, await _key()).convert(utf8.encode(_canonical(r))).bytes,
  );

  /// Lädt und prüft den gespeicherten Eintrag.
  Future<void> load() async {
    final was = _isPro;
    _isPro = await _validate();
    if (was != _isPro) notifyListeners();
  }

  Future<bool> _validate() async {
    final raw = _store.getString(_recordKey);
    if (raw == null) return false;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['product'] != proProductId) return false;
      if (m['platform'] != _platform()) return false;
      final mac = m['mac'];
      if (mac is! String) return false;
      final expected = await _mac(m);
      return _constantTimeEquals(utf8.encode(mac), utf8.encode(expected));
    } catch (_) {
      return false;
    }
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Schaltet Pro frei, nachdem der Kauf bestätigt wurde.
  Future<void> grant({required String transactionId, int? nowMs}) async {
    final rec = <String, Object?>{
      'product': proProductId,
      'platform': _platform(),
      'txId': transactionId,
      'grantedAtMs': nowMs ?? DateTime.now().toUtc().millisecondsSinceEpoch,
    };
    rec['mac'] = await _mac(rec);
    await _store.setString(_recordKey, jsonEncode(rec));
    if (!_isPro) {
      _isPro = true;
      notifyListeners();
    }
  }

  /// Entzieht Pro (Erstattung/Widerruf laut Store).
  Future<void> revoke() async {
    await _store.remove(_recordKey);
    if (_isPro) {
      _isPro = false;
      notifyListeners();
    }
  }
}
