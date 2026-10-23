import 'package:flutter/widgets.dart';

import '../data/entitlement_repository.dart';
import '../data/motif_repository.dart';
import '../data/parental_gate.dart';
import '../data/settings_repository.dart';
import '../platform/audio_service.dart';
import '../platform/purchase_service.dart';
import 'timer_controller.dart';

/// Abhängigkeiten der App (manuelle Dependency Injection, keine Zusatzbibliothek).
class AppDeps {
  AppDeps({
    required this.settings,
    required this.entitlements,
    required this.gate,
    required this.purchases,
    required this.timer,
    required this.motifs,
    required this.audio,
  });

  final SettingsRepository settings;
  final EntitlementRepository entitlements;
  final ParentalGateService gate;
  final PurchaseService purchases;
  final TimerController timer;
  final MotifRepository motifs;
  final AudioPort audio;

  bool get isPro => entitlements.isPro;

  Listenable get all =>
      Listenable.merge([settings, entitlements, purchases, timer]);
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.deps, required super.child});
  final AppDeps deps;

  static AppDeps of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.deps;

  @override
  bool updateShouldNotify(AppScope old) => old.deps != deps;
}
