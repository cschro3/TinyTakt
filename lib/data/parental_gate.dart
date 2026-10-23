import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'stores.dart';

/// Eine Elternsicherungs-Aufgabe: Rechenaufgabe mit ausgeschriebenen Zahlwörtern.
/// Kinder im Vorschulalter können weder die Zahlwörter lesen noch addieren.
class GateChallenge {
  const GateChallenge(this.a, this.b);
  final int a, b;
  int get answer => a + b;

  String promptDe() => 'Wie viel ist ${_de(a)} plus ${_de(b)}?';
  String promptEn() => 'What is ${_en(a)} plus ${_en(b)}?';

  static const _deWords = {
    7: 'sieben',
    8: 'acht',
    9: 'neun',
    11: 'elf',
    12: 'zwölf',
    13: 'dreizehn',
    14: 'vierzehn',
    15: 'fünfzehn',
    16: 'sechzehn',
    17: 'siebzehn',
    18: 'achtzehn',
    19: 'neunzehn',
  };
  static const _enWords = {
    7: 'seven',
    8: 'eight',
    9: 'nine',
    11: 'eleven',
    12: 'twelve',
    13: 'thirteen',
    14: 'fourteen',
    15: 'fifteen',
    16: 'sixteen',
    17: 'seventeen',
    18: 'eighteen',
    19: 'nineteen',
  };
  static String _de(int n) => _deWords[n]!;
  static String _en(int n) => _enWords[n]!;
  static List<int> get pool => _deWords.keys.toList();
}

enum GateResult { ok, wrong, lockedOut }

/// Elternsicherung: Rechenaufgabe oder optionaler PIN.
///
/// * Die Aufgabe ist eine Kinderbarriere, keine Sicherheitsgrenze gegen Erwachsene.
/// * Der PIN wird nur als PBKDF2-HMAC-SHA256-Hash mit zufälligem Salt im
///   Secure Storage gehalten, nie im Klartext und nicht hartcodiert.
/// * Falsche Eingaben führen zu steigenden Sperrzeiten.
/// * Vergessener PIN: Wiederherstellung über drei aufeinanderfolgende
///   Aufgaben und 60 Sekunden Wartezeit (siehe [startRecovery]/[completeRecovery]).
class ParentalGateService {
  ParentalGateService(
    this._secure, {
    Random? random,
    int Function()? nowMs,
    this.iterations = 20000,
  }) : _random = random ?? Random.secure(),
       _now = nowMs ?? (() => DateTime.now().toUtc().millisecondsSinceEpoch);

  final SecureStore _secure;
  final Random _random;
  final int Function() _now;
  final int iterations;

  static const _pinKey = 'gate.pin';
  static const _failKey = 'gate.fails';
  static const _lockKey = 'gate.lockUntil';
  static const recoveryWaitMs = 60 * 1000;
  static const recoveryChallenges = 3;

  int _recoverySolved = 0;
  int? _recoveryStartedMs;

  GateChallenge newChallenge() {
    final pool = GateChallenge.pool;
    return GateChallenge(
      pool[_random.nextInt(pool.length)],
      pool[_random.nextInt(pool.length)],
    );
  }

  Future<bool> hasPin() async => (await _secure.read(_pinKey)) != null;

  Future<int> lockedForMs() async {
    final until = int.tryParse(await _secure.read(_lockKey) ?? '') ?? 0;
    final rest = until - _now();
    return rest > 0 ? rest : 0;
  }

  Future<GateResult> checkAnswer(GateChallenge c, int? answer) async {
    if (await lockedForMs() > 0) return GateResult.lockedOut;
    if (answer != null && answer == c.answer) {
      await _clearFails();
      return GateResult.ok;
    }
    return _fail();
  }

  Future<GateResult> checkPin(String pin) async {
    if (await lockedForMs() > 0) return GateResult.lockedOut;
    final stored = await _secure.read(_pinKey);
    if (stored == null) return GateResult.ok;
    final parts = stored.split(r'$');
    if (parts.length != 3) return _fail();
    final salt = base64Decode(parts[1]);
    final expected = base64Decode(parts[2]);
    final actual = _pbkdf2(
      utf8.encode(pin),
      salt,
      int.parse(parts[0]),
      expected.length,
    );
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected[i] ^ actual[i];
    }
    if (diff == 0) {
      await _clearFails();
      return GateResult.ok;
    }
    return _fail();
  }

  Future<GateResult> _fail() async {
    final fails = (int.tryParse(await _secure.read(_failKey) ?? '') ?? 0) + 1;
    await _secure.write(_failKey, '$fails');
    if (fails >= 3) {
      // 30 s, 60 s, 120 s … max. 15 min
      final secs = min(30 * pow(2, fails - 3).toInt(), 900);
      await _secure.write(_lockKey, '${_now() + secs * 1000}');
      return GateResult.lockedOut;
    }
    return GateResult.wrong;
  }

  Future<void> _clearFails() async {
    await _secure.delete(_failKey);
    await _secure.delete(_lockKey);
  }

  static bool isValidPinFormat(String pin) =>
      RegExp(r'^\d{4,6}$').hasMatch(pin);

  Future<void> setPin(String pin) async {
    if (!isValidPinFormat(pin))
      throw ArgumentError('PIN muss 4–6 Ziffern haben');
    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final hash = _pbkdf2(utf8.encode(pin), salt, iterations, 32);
    await _secure.write(
      _pinKey,
      '$iterations\$${base64Encode(salt)}\$${base64Encode(hash)}',
    );
    await _clearFails();
  }

  Future<void> removePin() async {
    await _secure.delete(_pinKey);
    await _clearFails();
  }

  // --- Wiederherstellung bei vergessenem PIN ---
  void startRecovery() {
    _recoverySolved = 0;
    _recoveryStartedMs = null;
  }

  int get recoverySolved => _recoverySolved;

  /// Meldet eine gelöste Wiederherstellungs-Aufgabe. Gibt true zurück, sobald
  /// alle Aufgaben gelöst sind; danach läuft die Wartezeit.
  bool recordRecoverySolved() {
    _recoverySolved++;
    if (_recoverySolved >= recoveryChallenges) {
      _recoveryStartedMs = _now();
      return true;
    }
    return false;
  }

  int recoveryRemainingMs() {
    final s = _recoveryStartedMs;
    if (s == null) return recoveryWaitMs;
    final r = recoveryWaitMs - (_now() - s);
    return r > 0 ? r : 0;
  }

  /// Entfernt den PIN, wenn alle Aufgaben gelöst und die Wartezeit abgelaufen ist.
  Future<bool> completeRecovery() async {
    if (_recoveryStartedMs == null || recoveryRemainingMs() > 0) return false;
    await removePin();
    _recoveryStartedMs = null;
    _recoverySolved = 0;
    return true;
  }

  static List<int> _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int length,
  ) {
    final hmac = Hmac(sha256, password);
    final out = <int>[];
    var block = 1;
    while (out.length < length) {
      var u = hmac.convert([
        ...salt,
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ]).bytes;
      final t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.addAll(t);
      block++;
    }
    return out.sublist(0, length);
  }
}
