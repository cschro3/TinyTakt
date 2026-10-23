import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/data/entitlement_repository.dart';
import 'package:tinytakt/data/stores.dart';

void main() {
  late MemoryStore prefs, secure;
  setUp(() {
    prefs = MemoryStore();
    secure = MemoryStore();
  });

  test('Ohne Eintrag kein Pro', () async {
    final e = EntitlementRepository(
      prefs,
      secure,
      platformName: () => 'android',
    );
    await e.load();
    expect(e.isPro, isFalse);
  });

  test('Grant wird gespeichert und nach Neustart geladen', () async {
    final e = EntitlementRepository(
      prefs,
      secure,
      platformName: () => 'android',
    );
    await e.grant(transactionId: 'tx1');
    expect(e.isPro, isTrue);
    final e2 = EntitlementRepository(
      prefs,
      secure,
      platformName: () => 'android',
    );
    await e2.load();
    expect(e2.isPro, isTrue);
  });

  test(
    'Manipulierter Eintrag (Transaktions-ID geändert) wird abgelehnt',
    () async {
      final e = EntitlementRepository(
        prefs,
        secure,
        platformName: () => 'android',
      );
      await e.grant(transactionId: 'tx1');
      final raw = prefs.data['entitlement.v1']!.replaceAll('tx1', 'tx2');
      prefs.data['entitlement.v1'] = raw;
      final e2 = EntitlementRepository(
        prefs,
        secure,
        platformName: () => 'android',
      );
      await e2.load();
      expect(e2.isPro, isFalse);
    },
  );

  test('Selbst gebauter Eintrag ohne gültigen MAC wird abgelehnt', () async {
    prefs.data['entitlement.v1'] = '{"product":"tinytakt_pro_lifetime","platform":"android","txId":"x","grantedAtMs":1,"mac":"AAAA"}';
    final e = EntitlementRepository(
      prefs,
      secure,
      platformName: () => 'android',
    );
    await e.load();
    expect(e.isPro, isFalse);
  });

  test('Einfaches Boolean-Flag schaltet nichts frei', () async {
    prefs.data['pro'] = 'true';
    prefs.data['isPro'] = 'true';
    prefs.data['entitlement.v1'] = 'true';
    final e = EntitlementRepository(
      prefs,
      secure,
      platformName: () => 'android',
    );
    await e.load();
    expect(e.isPro, isFalse);
  });

  test('Eintrag einer anderen Plattform gilt nicht', () async {
    final a = EntitlementRepository(
      prefs,
      secure,
      platformName: () => 'android',
    );
    await a.grant(transactionId: 'tx1');
    final i = EntitlementRepository(prefs, secure, platformName: () => 'iOS');
    await i.load();
    expect(i.isPro, isFalse);
  });

  test(
    'Ohne Schlüssel im Secure Storage (z. B. kopierte Prefs) kein Pro',
    () async {
      final e = EntitlementRepository(
        prefs,
        secure,
        platformName: () => 'android',
      );
      await e.grant(transactionId: 'tx1');
      final other = EntitlementRepository(
        prefs,
        MemoryStore(),
        platformName: () => 'android',
      );
      await other.load();
      expect(other.isPro, isFalse);
    },
  );

  test('Revoke entzieht Pro und benachrichtigt', () async {
    final e = EntitlementRepository(
      prefs,
      secure,
      platformName: () => 'android',
    );
    var n = 0;
    e.addListener(() => n++);
    await e.grant(transactionId: 'tx1');
    await e.revoke();
    expect(e.isPro, isFalse);
    expect(n, 2);
    final e2 = EntitlementRepository(
      prefs,
      secure,
      platformName: () => 'android',
    );
    await e2.load();
    expect(e2.isPro, isFalse);
  });
}
