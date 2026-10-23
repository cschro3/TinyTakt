import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../data/entitlement_repository.dart';
import '../domain/catalog.dart';

/// Dünne Schicht über dem Store (Google Play Billing / StoreKit 2).
abstract class StoreGateway {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetails?> queryProduct(String id);
  Future<bool> buy(ProductDetails p);
  Future<void> restore();
  Future<void> complete(PurchaseDetails p);

  /// Autoritative Liste der Käufe (nur Android). `null` = unbekannt/Fehler → nichts ändern.
  Future<List<PurchaseDetails>?> queryOwned();
}

class InAppPurchaseGateway implements StoreGateway {
  InAppPurchaseGateway([InAppPurchase? iap])
    : _iap = iap ?? InAppPurchase.instance;
  final InAppPurchase _iap;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;
  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<ProductDetails?> queryProduct(String id) async {
    final r = await _iap.queryProductDetails({id});
    if (r.error != null || r.productDetails.isEmpty) return null;
    return r.productDetails.first;
  }

  @override
  Future<bool> buy(ProductDetails p) =>
      _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: p));
  @override
  Future<void> restore() => _iap.restorePurchases();
  @override
  Future<void> complete(PurchaseDetails p) => _iap.completePurchase(p);

  @override
  Future<List<PurchaseDetails>?> queryOwned() async {
    if (!Platform.isAndroid) return null;
    final add = _iap
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final r = await add.queryPastPurchases();
    if (r.error != null) return null;
    return r.pastPurchases;
  }
}

enum VerifyOutcome { valid, invalid }

/// Prüft eine vom Store gemeldete Transaktion.
abstract class PurchaseVerifier {
  Future<VerifyOutcome> verify(PurchaseDetails p);
}

/// Lokale Prüfung: richtiges Produkt, Status „gekauft/wiederhergestellt“ und
/// vorhandene, vom Store signierte Nachweisdaten (StoreKit-2-JWS bzw. Play-Purchase-Token).
class StoreEvidenceVerifier implements PurchaseVerifier {
  @override
  Future<VerifyOutcome> verify(PurchaseDetails p) async {
    final ok =
        p.productID == proProductId &&
        (p.status == PurchaseStatus.purchased ||
            p.status == PurchaseStatus.restored) &&
        p.verificationData.serverVerificationData.isNotEmpty;
    return ok ? VerifyOutcome.valid : VerifyOutcome.invalid;
  }
}

/// Optionale serverseitige Prüfung (nur wenn eine URL konfiguriert ist).
/// Sendet ausschließlich Produkt-ID, Plattform und den Store-Nachweis – keine Geräte-/Kinderdaten.
/// Ist der Dienst nicht erreichbar, gilt die lokale Prüfung (Offline-Strategie);
/// eine ausdrückliche Ablehnung („invalid“) verhindert die Freischaltung.
class RemoteVerifier implements PurchaseVerifier {
  RemoteVerifier(this.endpoint, {HttpClient? client})
    : _client = client ?? HttpClient();
  final Uri endpoint;
  final HttpClient _client;

  @override
  Future<VerifyOutcome> verify(PurchaseDetails p) async {
    try {
      final req = await _client
          .postUrl(endpoint)
          .timeout(const Duration(seconds: 8));
      req.headers.contentType = ContentType.json;
      req.write(
        jsonEncode({
          'productId': p.productID,
          'platform': defaultTargetPlatform.name,
          'evidence': p.verificationData.serverVerificationData,
        }),
      );
      final resp = await req.close().timeout(const Duration(seconds: 8));
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode == 200 && (jsonDecode(body) as Map)['valid'] == true)
        return VerifyOutcome.valid;
      if (resp.statusCode == 200 ||
          resp.statusCode == 400 ||
          resp.statusCode == 403)
        return VerifyOutcome.invalid;
      return VerifyOutcome
          .valid; // Serverfehler → lokale Store-Bestätigung gilt
    } catch (_) {
      return VerifyOutcome.valid; // offline → lokale Store-Bestätigung gilt
    }
  }
}

class ChainVerifier implements PurchaseVerifier {
  ChainVerifier(this.verifiers);
  final List<PurchaseVerifier> verifiers;
  @override
  Future<VerifyOutcome> verify(PurchaseDetails p) async {
    for (final v in verifiers) {
      if (await v.verify(p) == VerifyOutcome.invalid)
        return VerifyOutcome.invalid;
    }
    return VerifyOutcome.valid;
  }
}

enum PurchaseState {
  loading,
  unavailable,
  ready,
  purchasing,
  pending,
  restoring,
  owned,
  error,
}

/// Kauflogik für das einmalige Pro-Upgrade (`tinytakt_pro_lifetime`).
class PurchaseService extends ChangeNotifier {
  PurchaseService(
    this._gateway,
    this._entitlements, {
    PurchaseVerifier? verifier,
  }) : _verifier = verifier ?? StoreEvidenceVerifier();

  final StoreGateway _gateway;
  final EntitlementRepository _entitlements;
  final PurchaseVerifier _verifier;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;

  PurchaseState state = PurchaseState.loading;
  String? errorMessage;

  /// Vom Store gelieferter, lokalisierter Preis (nie hartcodiert).
  String? get price => _product?.price;
  bool get isPro => _entitlements.isPro;

  Future<void> init() async {
    _sub ??= _gateway.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        _set(PurchaseState.error, e.toString());
      },
    );
    await refresh();
  }

  /// Lädt Produktdaten und gleicht die Berechtigung mit dem Store ab.
  Future<void> refresh() async {
    try {
      if (!await _gateway.isAvailable()) {
        _set(
          _entitlements.isPro ? PurchaseState.owned : PurchaseState.unavailable,
        );
        return;
      }
      _product = await _gateway.queryProduct(proProductId);
      final owned = await _gateway.queryOwned();
      if (owned != null) {
        final mine = owned.where(
          (p) =>
              p.productID == proProductId &&
              (p.status == PurchaseStatus.purchased ||
                  p.status == PurchaseStatus.restored),
        );
        if (mine.isEmpty) {
          if (_entitlements.isPro)
            await _entitlements.revoke(); // erstattet/zurückgegeben
        } else {
          await _handle(mine.first);
        }
      }
      _set(
        _entitlements.isPro
            ? PurchaseState.owned
            : (_product == null
                  ? PurchaseState.unavailable
                  : PurchaseState.ready),
      );
    } catch (e) {
      _set(
        _entitlements.isPro ? PurchaseState.owned : PurchaseState.error,
        e.toString(),
      );
    }
  }

  /// Startet den Kauf. Doppelte Auslösung und Kauf bei vorhandenem Pro werden verhindert.
  Future<void> buy() async {
    if (_entitlements.isPro ||
        state == PurchaseState.purchasing ||
        state == PurchaseState.pending)
      return;
    final p = _product;
    if (p == null) {
      _set(PurchaseState.unavailable);
      return;
    }
    _set(PurchaseState.purchasing);
    try {
      final started = await _gateway.buy(p);
      if (!started) _set(PurchaseState.ready);
    } catch (e) {
      _set(PurchaseState.error, e.toString());
    }
  }

  Future<void> restore() async {
    if (state == PurchaseState.restoring || state == PurchaseState.purchasing)
      return;
    _set(PurchaseState.restoring);
    try {
      await _gateway.restore();
      // Ergebnis kommt über den Stream; ohne Treffer zurück auf „bereit“.
      Timer(const Duration(seconds: 6), () {
        if (state == PurchaseState.restoring) {
          _set(_entitlements.isPro ? PurchaseState.owned : PurchaseState.ready);
        }
      });
    } catch (e) {
      _set(PurchaseState.error, e.toString());
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.productID != proProductId) {
        if (p.pendingCompletePurchase) await _gateway.complete(p);
        continue;
      }
      await _handle(p);
    }
  }

  Future<void> _handle(PurchaseDetails p) async {
    switch (p.status) {
      case PurchaseStatus.pending:
        _set(PurchaseState.pending);
      case PurchaseStatus.canceled:
        _set(_entitlements.isPro ? PurchaseState.owned : PurchaseState.ready);
      case PurchaseStatus.error:
        if (p.pendingCompletePurchase) await _gateway.complete(p);
        _set(
          _entitlements.isPro ? PurchaseState.owned : PurchaseState.error,
          p.error?.message,
        );
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final outcome = await _verifier.verify(p);
        if (outcome == VerifyOutcome.valid) {
          if (!_entitlements.isPro) {
            await _entitlements.grant(
              transactionId:
                  p.purchaseID ??
                  p.verificationData.serverVerificationData.hashCode.toString(),
            );
          }
          if (p.pendingCompletePurchase) await _gateway.complete(p);
          _set(PurchaseState.owned);
        } else {
          _set(PurchaseState.error, 'verification_failed');
        }
    }
  }

  void _set(PurchaseState s, [String? err]) {
    state = s;
    errorMessage = err;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
