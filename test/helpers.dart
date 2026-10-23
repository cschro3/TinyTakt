import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tinytakt/app/deps.dart';
import 'package:tinytakt/app/timer_controller.dart';
import 'package:tinytakt/data/entitlement_repository.dart';
import 'package:tinytakt/data/motif_repository.dart';
import 'package:tinytakt/data/parental_gate.dart';
import 'package:tinytakt/data/settings_repository.dart';
import 'package:tinytakt/data/stores.dart';
import 'package:tinytakt/domain/catalog.dart';
import 'package:tinytakt/domain/clock.dart';
import 'package:tinytakt/domain/timer_engine.dart';
import 'package:tinytakt/platform/audio_service.dart';
import 'package:tinytakt/platform/notification_service.dart';
import 'package:tinytakt/platform/purchase_service.dart';
import 'package:tinytakt/presentation/theme.dart';

class FakeStore implements StoreGateway {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  ProductDetails? product = ProductDetails(
    id: proProductId,
    title: 'TinyTakt Pro',
    description: 'Pro',
    price: '4,99 €',
    rawPrice: 4.99,
    currencyCode: 'EUR',
  );
  List<PurchaseDetails>? owned;
  final bought = <String>[];
  final completed = <PurchaseDetails>[];
  int restoreCalls = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<ProductDetails?> queryProduct(String id) async => product;
  @override
  Future<bool> buy(ProductDetails p) async {
    bought.add(p.id);
    return true;
  }

  @override
  Future<void> restore() async => restoreCalls++;
  @override
  Future<void> complete(PurchaseDetails p) async => completed.add(p);
  @override
  Future<List<PurchaseDetails>?> queryOwned() async => owned;

  void emit(
    PurchaseStatus status, {
    String id = proProductId,
    String evidence = 'token-123',
    bool pendingComplete = true,
  }) {
    final d = PurchaseDetails(
      purchaseID: 'tx-1',
      productID: id,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'l',
        serverVerificationData: evidence,
        source: 'test',
      ),
      transactionDate: '1',
      status: status,
    )..pendingCompletePurchase = pendingComplete;
    controller.add([d]);
  }
}

class TestEnv {
  TestEnv({bool pro = false, this.platform = 'android'}) {
    TestWidgetsFlutterBinding.ensureInitialized();
    entitlements = EntitlementRepository(
      prefs,
      secure,
      platformName: () => platform,
    );
    settings = SettingsRepository(prefs);
    clock = FakeClock();
    audio = SilentAudioService();
    notes = NoopNotificationService();
    timer = TimerController(
      engine: TimerEngine(clock),
      settings: settings,
      store: prefs,
      audio: audio,
      notifications: notes,
      languageCode: () => 'de',
      isPro: () => entitlements.isPro,
    );
    store = FakeStore();
    purchases = PurchaseService(store, entitlements);
    gate = ParentalGateService(
      secure,
      iterations: 10,
      nowMs: () => clock.wallMs(),
    );
    deps = AppDeps(
      settings: settings,
      entitlements: entitlements,
      gate: gate,
      purchases: purchases,
      timer: timer,
      motifs: MotifRepository(),
      audio: audio,
    );
    _pro = pro;
  }

  final String platform;
  final prefs = MemoryStore();
  final secure = MemoryStore();
  late final EntitlementRepository entitlements;
  late final SettingsRepository settings;
  late final FakeClock clock;
  late final SilentAudioService audio;
  late final NoopNotificationService notes;
  late final TimerController timer;
  late final FakeStore store;
  late final PurchaseService purchases;
  late final ParentalGateService gate;
  late final AppDeps deps;
  bool _pro = false;

  Future<void> init() async {
    await timer.init();
    if (_pro) await entitlements.grant(transactionId: 'test');
  }
}

Widget wrap(
  AppDeps deps,
  Widget child, {
  Locale locale = const Locale('de'),
  double textScale = 1.0,
  Size? size,
}) {
  return AppScope(
    deps: deps,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Brand.theme(),
      locale: locale,
      supportedLocales: const [Locale('de'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: c!,
      ),
      home: child,
    ),
  );
}

void setScreen(WidgetTester t, Size logical, {double dpr = 2.0}) {
  t.view.devicePixelRatio = dpr;
  t.view.physicalSize = logical * dpr;
  addTearDown(t.view.reset);
}
