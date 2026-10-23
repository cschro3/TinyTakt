import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/data/parental_gate.dart';
import 'package:tinytakt/data/stores.dart';

void main() {
  late MemoryStore secure;
  late int now;
  late ParentalGateService g;
  setUp(() {
    secure = MemoryStore();
    now = 1000000;
    g = ParentalGateService(
      secure,
      random: Random(1),
      nowMs: () => now,
      iterations: 10,
    );
  });

  test('Aufgabe: Zahlen als Wörter, Antwort korrekt', () async {
    final c = g.newChallenge();
    expect(
      c.promptDe(),
      matches(RegExp(r'^Wie viel ist [a-zäöüß]+ plus [a-zäöüß]+\?$')),
    );
    expect(c.promptDe(), isNot(contains(RegExp(r'\d'))));
    expect(await g.checkAnswer(c, c.answer), GateResult.ok);
  });

  test(
    'Falsche Antwort, dann Sperre nach 3 Fehlversuchen, Sperre läuft ab',
    () async {
      final c = g.newChallenge();
      expect(await g.checkAnswer(c, -1), GateResult.wrong);
      expect(await g.checkAnswer(c, null), GateResult.wrong);
      expect(await g.checkAnswer(c, 0), GateResult.lockedOut);
      expect(await g.lockedForMs(), 30000);
      expect(
        await g.checkAnswer(c, c.answer),
        GateResult.lockedOut,
        reason: 'auch richtige Antwort während Sperre abgewiesen',
      );
      now += 31000;
      expect(await g.lockedForMs(), 0);
      expect(await g.checkAnswer(c, c.answer), GateResult.ok);
    },
  );

  test('Sperrzeit steigt bei weiteren Fehlversuchen', () async {
    final c = g.newChallenge();
    for (var i = 0; i < 3; i++) {
      await g.checkAnswer(c, -1);
    }
    now += 31000;
    await g.checkAnswer(c, -1);
    expect(await g.lockedForMs(), 60000);
  });

  test('PIN: setzen, prüfen, nie im Klartext gespeichert', () async {
    expect(await g.hasPin(), isFalse);
    await g.setPin('4711');
    expect(await g.hasPin(), isTrue);
    expect(secure.data.values.any((v) => v.contains('4711')), isFalse);
    expect(await g.checkPin('4711'), GateResult.ok);
    expect(await g.checkPin('0000'), GateResult.wrong);
  });

  test(
    'PIN-Hash ist gesalzen (gleicher PIN → unterschiedlicher Speicherwert)',
    () async {
      await g.setPin('1234');
      final a = secure.data['gate.pin'];
      await g.setPin('1234');
      expect(secure.data['gate.pin'], isNot(a));
    },
  );

  test('Ungültige PIN-Formate werden abgelehnt', () async {
    for (final bad in ['', '123', '1234567', 'abcd', '12 4']) {
      expect(() => g.setPin(bad), throwsArgumentError, reason: bad);
    }
  });

  test('PIN-Fehlversuche führen zur Sperre', () async {
    await g.setPin('4711');
    await g.checkPin('1');
    await g.checkPin('2');
    expect(await g.checkPin('3'), GateResult.lockedOut);
    expect(await g.checkPin('4711'), GateResult.lockedOut);
  });

  test(
    'Wiederherstellung: 3 Aufgaben + Wartezeit, erst dann PIN entfernt',
    () async {
      await g.setPin('4711');
      g.startRecovery();
      expect(g.recordRecoverySolved(), isFalse);
      expect(g.recordRecoverySolved(), isFalse);
      expect(await g.completeRecovery(), isFalse);
      expect(g.recordRecoverySolved(), isTrue);
      expect(await g.completeRecovery(), isFalse, reason: 'Wartezeit läuft');
      expect(g.recoveryRemainingMs(), 60000);
      now += 61000;
      expect(await g.completeRecovery(), isTrue);
      expect(await g.hasPin(), isFalse);
    },
  );

  test('Kein PIN gesetzt: Aufgaben variieren', () {
    final seen = <int>{};
    for (var i = 0; i < 40; i++) {
      seen.add(g.newChallenge().answer);
    }
    expect(seen.length, greaterThan(5));
  });
}
