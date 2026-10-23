import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schnittstelle für Timer-Ende-Benachrichtigungen.
abstract class NotificationPort {
  Future<void> init();

  /// Fragt die Benachrichtigungserlaubnis an (nur nach Elterninteraktion aufrufen).
  Future<bool> requestPermission();
  Future<bool> hasPermission();

  /// Plant eine Benachrichtigung zum Ablaufzeitpunkt (UTC-Epoche ms).
  Future<void> scheduleEnd({
    required int endWallMs,
    required String title,
    required String body,
  });
  Future<void> cancel();
}

/// Offiziell unterstützte Mechanismen:
///  * Android: AlarmManager (exakt, falls erlaubt, sonst inexakt) → Benachrichtigung.
///  * iOS: UNUserNotificationCenter mit zeitbasiertem Trigger.
/// Zustellung ist vom Betriebssystem abhängig (Energiesparmodus, Fokus/Nicht-Stören,
/// entzogene Berechtigung) und wird nicht garantiert.
class LocalNotificationService implements NotificationPort {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _p = plugin ?? FlutterLocalNotificationsPlugin();
  final FlutterLocalNotificationsPlugin _p;
  static const _id = 4711;
  static const _channelId = 'timer_end';
  bool _inited = false;

  @override
  Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    await _p.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_timer'),
        // Berechtigung wird bewusst nicht beim Start angefragt.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _inited = true;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    if (Platform.isAndroid) {
      final a = _p
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await a?.requestNotificationsPermission() ?? false;
    }
    if (Platform.isIOS) {
      final i = _p
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await i?.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  @override
  Future<bool> hasPermission() async {
    await init();
    if (Platform.isAndroid) {
      final a = _p
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await a?.areNotificationsEnabled() ?? false;
    }
    if (Platform.isIOS) {
      final i = _p
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final o = await i?.checkPermissions();
      return o?.isEnabled ?? false;
    }
    return false;
  }

  @override
  Future<void> scheduleEnd({
    required int endWallMs,
    required String title,
    required String body,
  }) async {
    await init();
    if (endWallMs <= DateTime.now().toUtc().millisecondsSinceEpoch) return;
    var mode = AndroidScheduleMode.inexactAllowWhileIdle;
    if (Platform.isAndroid) {
      final a = _p
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (await a?.canScheduleExactNotifications() ?? false)
        mode = AndroidScheduleMode.exactAllowWhileIdle;
    }
    await _p.zonedSchedule(
      id: _id,
      scheduledDate: tz.TZDateTime.fromMillisecondsSinceEpoch(
        tz.UTC,
        endWallMs,
      ),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Timer-Ende',
          channelDescription: 'Meldet, wenn der Timer abgelaufen ist.',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: mode,
      title: title,
      body: body,
    );
  }

  @override
  Future<void> cancel() async {
    await init();
    await _p.cancel(id: _id);
  }
}

class NoopNotificationService implements NotificationPort {
  final List<String> log = [];
  int? scheduledEndMs;
  bool granted = true;
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => granted;
  @override
  Future<bool> hasPermission() async => granted;
  @override
  Future<void> scheduleEnd({
    required int endWallMs,
    required String title,
    required String body,
  }) async {
    scheduledEndMs = endWallMs;
    log.add('schedule');
  }

  @override
  Future<void> cancel() async {
    scheduledEndMs = null;
    log.add('cancel');
  }
}
