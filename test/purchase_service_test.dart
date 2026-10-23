import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/platform/purchase_service.dart';

import 'helpers.dart';

Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late TestEnv env;
  setUp(() async {
    env = TestEnv();
    await env.init();
  });

  test('Produkt und Preis kommen vom Store', () async {
    await env.purchases.init();
    expect(env.purchases.state, PurchaseState.ready);
    expect(env.purchases.price, '4,99 €');
  });

  test(
    'Store nicht erreichbar → App bleibt nutzbar, Status unavailable',
    () async {
      env.store.available = false;
      await env.purchases.init();
      expect(env.purchases.state, PurchaseState.unavailable);
      expect(env.entitlements.isPro, isFalse);
    },
  );

  test('Produkt unbekannt → unavailable', () async {
    env.store.product = null;
    await env.purchases.init();
    expect(env.purchases.state, PurchaseState.unavailable);
  });

  test(
    'Kauf: Start, Bestätigung, Freischaltung, Abschluss der Transaktion',
    () async {
      await env.purchases.init();
      await env.purchases.buy();
      expect(env.store.bought, [proProductId]);
      expect(env.purchases.state, PurchaseState.purchasing);
      env.store.emit(PurchaseStatus.purchased);
      await pump();
      expect(env.entitlements.isPro, isTrue);
      expect(env.purchases.state, PurchaseState.owned);
      expect(env.store.completed, hasLength(1));
    },
  );

  test('Doppelte Kaufauslösung wird verhindert', () async {
    await env.purchases.init();
    await env.purchases.buy();
    await env.purchases.buy();
    await env.purchases.buy();
    expect(env.store.bought, hasLength(1));
  });

  test('Kein erneuter Kauf bei vorhandenem Pro', () async {
    await env.entitlements.grant(transactionId: 'x');
    await env.purchases.init();
    await env.purchases.buy();
    expect(env.store.bought, isEmpty);
  });

  test('Abbruch durch Nutzer: kein Pro, wieder bereit', () async {
    await env.purchases.init();
    await env.purchases.buy();
    env.store.emit(PurchaseStatus.canceled);
    await pump();
    expect(env.entitlements.isPro, isFalse);
    expect(env.purchases.state, PurchaseState.ready);
  });

  test(
    'Ausstehender Kauf (Pending): noch kein Pro; später bestätigt → Pro',
    () async {
      await env.purchases.init();
      await env.purchases.buy();
      env.store.emit(PurchaseStatus.pending, pendingComplete: false);
      await pump();
      expect(env.purchases.state, PurchaseState.pending);
      expect(env.entitlements.isPro, isFalse);
      env.store.emit(PurchaseStatus.purchased);
      await pump();
      expect(env.entitlements.isPro, isTrue);
    },
  );

  test('Fehlgeschlagener Kauf: kein Pro, Fehlerstatus, Transaktion wird abgeschlossen', () async {
    await env.purchases.init();
    await env.purchases.buy();
    env.store.emit(PurchaseStatus.error);
    await pump();
    expect(env.entitlements.isPro, isFalse);
    expect(env.purchases.state, PurchaseState.error);
    expect(env.store.completed, hasLength(1));
  });

  test('Nach Fehler ist erneuter Kauf möglich', () async {
    await env.purchases.init();
    await env.purchases.buy();
    env.store.emit(PurchaseStatus.error);
    await pump();
    await env.purchases.buy();
    expect(env.store.bought, hasLength(2));
  });

  test('Wiederherstellung schaltet frei', () async {
    await env.purchases.init();
    await env.purchases.restore();
    expect(env.store.restoreCalls, 1);
    env.store.emit(PurchaseStatus.restored);
    await pump();
    expect(env.entitlements.isPro, isTrue);
  });

  test(
    'Ohne Store-Nachweis keine Freischaltung (Verifikation schlägt fehl)',
    () async {
      await env.purchases.init();
      env.store.emit(PurchaseStatus.purchased, evidence: '');
      await pump();
      expect(env.entitlements.isPro, isFalse);
      expect(env.purchases.state, PurchaseState.error);
      expect(
        env.store.completed,
        isEmpty,
        reason: 'unbestätigte Transaktion nicht abschließen',
      );
    },
  );

  test('Fremdes Produkt wird nicht freigeschaltet', () async {
    await env.purchases.init();
    env.store.emit(PurchaseStatus.purchased, id: 'other_product');
    await pump();
    expect(env.entitlements.isPro, isFalse);
  });

  test(
    'Erstattung: Store meldet Kauf nicht mehr → Pro wird entzogen',
    () async {
      await env.entitlements.grant(transactionId: 'x');
      env.store.owned = [];
      await env.purchases.init();
      expect(env.entitlements.isPro, isFalse);
    },
  );

  test(
    'Store-Abfrage fehlgeschlagen (null) → Pro bleibt (Offline-Toleranz)',
    () async {
      await env.entitlements.grant(transactionId: 'x');
      env.store.owned = null;
      await env.purchases.init();
      expect(env.entitlements.isPro, isTrue);
      expect(env.purchases.state, PurchaseState.owned);
    },
  );

  test('Bereits getätigter Kauf wird beim Start erkannt', () async {
    env.store.owned = [
      PurchaseDetails(
        purchaseID: 'tx9',
        productID: proProductId,
        verificationData: PurchaseVerificationData(
          localVerificationData: 'l',
          serverVerificationData: 's',
          source: 't',
        ),
        transactionDate: '1',
        status: PurchaseStatus.purchased,
      ),
    ];
    await env.purchases.init();
    expect(env.entitlements.isPro, isTrue);
  });

  test(
    'Offline mit gespeichertem Pro: Store nicht verfügbar → bleibt Pro',
    () async {
      await env.entitlements.grant(transactionId: 'x');
      env.store.available = false;
      await env.purchases.init();
      expect(env.entitlements.isPro, isTrue);
      expect(env.purchases.state, PurchaseState.owned);
    },
  );

  test('Serverseitige Ablehnung verhindert Freischaltung', () async {
    final svc = PurchaseService(
      env.store,
      env.entitlements,
      verifier: _Reject(),
    );
    await svc.init();
    env.store.emit(PurchaseStatus.purchased);
    await pump();
    expect(env.entitlements.isPro, isFalse);
    svc.dispose();
  });
}

class _Reject implements PurchaseVerifier {
  @override
  Future<VerifyOutcome> verify(PurchaseDetails p) async =>
      VerifyOutcome.invalid;
}
