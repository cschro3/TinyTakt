import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app/app.dart';
import 'app/deps.dart';
import 'app/timer_controller.dart';
import 'data/entitlement_repository.dart';
import 'data/motif_repository.dart';
import 'data/parental_gate.dart';
import 'data/settings_repository.dart';
import 'data/stores.dart';
import 'domain/clock.dart';
import 'domain/timer_engine.dart';
import 'platform/audio_service.dart';
import 'platform/notification_service.dart';
import 'platform/purchase_service.dart';

/// Optionale Server-Prüfung der Käufe (--dart-define=PURCHASE_VERIFY_URL=https://…).
const _verifyUrl = String.fromEnvironment('PURCHASE_VERIFY_URL');
const _previewPro = bool.fromEnvironment('PREVIEW_PRO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  FlutterError.onError = (d) {
    FlutterError.presentError(d);
    // Bewusst kein Remote-Crash-Reporting (Datenschutz): nur lokale Logs.
  };

  final prefs = await PrefsStore.open();
  final secure = KeychainStore();
  final settings = SettingsRepository(prefs);
  final entitlements = EntitlementRepository(prefs, secure);
  await entitlements.load();
  final audio = AudioService();
  // Web-Vorschau: keine Systembenachrichtigungen, kein Store.
  final NotificationPort notifications = kIsWeb
      ? NoopNotificationService()
      : LocalNotificationService();
  final timer = TimerController(
    engine: TimerEngine(SystemClock()),
    settings: settings,
    store: prefs,
    audio: audio,
    notifications: notifications,
    languageCode: () => PlatformDispatcher.instance.locale.languageCode,
    isPro: () => entitlements.isPro,
    keepAwake: (on) {
      try {
        on ? WakelockPlus.enable() : WakelockPlus.disable();
      } catch (_) {}
    },
  );
  final purchases = PurchaseService(
    kIsWeb ? _NoStore() : InAppPurchaseGateway(),
    entitlements,
    verifier: _verifyUrl.isEmpty
        ? StoreEvidenceVerifier()
        : ChainVerifier([
            StoreEvidenceVerifier(),
            RemoteVerifier(Uri.parse(_verifyUrl)),
          ]),
  );

  // Nur für die Web-Vorschau (--dart-define=PREVIEW_PRO=true): Pro-Inhalte zum Ausprobieren.
  // Store-Builds setzen diese Option nie; auf Mobilgeräten wird sie ignoriert.
  if (kIsWeb && _previewPro)
    await entitlements.grant(transactionId: 'web-preview');

  final deps = AppDeps(
    settings: settings,
    entitlements: entitlements,
    gate: ParentalGateService(secure),
    purchases: purchases,
    timer: timer,
    motifs: MotifRepository(),
    audio: audio,
  );
  await timer.init();
  runApp(TinyTaktApp(deps: deps));
  // Store-Abgleich nach dem ersten Frame, blockiert den Start nicht (Offline-tauglich).
  purchases.init().catchError(
    (Object e) => debugPrint('Store nicht erreichbar: $e'),
  );
}

/// Web: kein Store vorhanden.
class _NoStore implements StoreGateway {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<ProductDetails?> queryProduct(String id) async => null;
  @override
  Future<bool> buy(ProductDetails p) async => false;
  @override
  Future<void> restore() async {}
  @override
  Future<void> complete(PurchaseDetails p) async {}
  @override
  Future<List<PurchaseDetails>?> queryOwned() async => null;
}
