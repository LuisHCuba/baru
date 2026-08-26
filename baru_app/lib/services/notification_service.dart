import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notificações locais: relatório da noite (21h) e "senti sua falta".
class BaruNotifications {
  BaruNotifications._();

  static final BaruNotifications instance = BaruNotifications._();

  static const _eveningId = 1001;
  static const _missedId = 1002;
  static const _trialId = 1003;
  static const _lastMissedKey = 'baru_last_missed_notify';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb || _ready) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'baru_reminders',
              'Lembretes Baru',
              description: 'Relatório da noite e mensagens do pet',
              importance: Importance.defaultImportance,
            ),
          );
    }

    _ready = true;
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  Future<bool> ensurePermission() async {
    if (kIsWeb) return false;
    if (await hasPermission()) return true;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      if (granted == true) return true;
    }

    final result = await Permission.notification.request();
    return result.isGranted || result.isLimited;
  }

  Future<void> syncSchedules({
    required bool evening,
    required bool missed,
    required String eveningTitle,
    required String eveningBody,
    required String missedTitle,
    required String missedBody,
    required int daysAway,
    required bool trialActive,
    required DateTime? trialEndsAt,
    required String trialTitle,
    required String trialBody,
  }) async {
    if (kIsWeb || !_ready) return;

    await _syncTrialReminder(
      ativo: trialActive,
      fim: trialEndsAt,
      title: trialTitle,
      body: trialBody,
    );

    if (evening && await hasPermission()) {
      await _scheduleEvening(eveningTitle, eveningBody);
    } else {
      await _plugin.cancel(id: _eveningId);
    }

    if (!missed || !await hasPermission()) {
      await _plugin.cancel(id: _missedId);
      return;
    }

    if (daysAway >= 2) {
      await _maybeShowMissed(missedTitle, missedBody);
    }
  }

  /// Aviso 24h antes do fim do teste — o contrato de produto §9 e a copy do
  /// paywall prometem esse recado.
  Future<void> _syncTrialReminder({
    required bool ativo,
    required DateTime? fim,
    required String title,
    required String body,
  }) async {
    if (!ativo || fim == null || !await hasPermission()) {
      await _plugin.cancel(id: _trialId);
      return;
    }

    final quando = tz.TZDateTime.from(
      fim.subtract(const Duration(hours: 24)),
      tz.local,
    );
    if (!quando.isAfter(tz.TZDateTime.now(tz.local))) {
      // As 24h já passaram: avisar agora seria avisar tarde.
      await _plugin.cancel(id: _trialId);
      return;
    }

    await _plugin.zonedSchedule(
      id: _trialId,
      title: title,
      body: body,
      scheduledDate: quando,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'baru_reminders',
          'Lembretes Baru',
          channelDescription: 'Fim do teste',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _scheduleEvening(String title, String body) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _eveningId,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'baru_reminders',
          'Lembretes Baru',
          channelDescription: 'Relatório da noite',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _maybeShowMissed(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    if (prefs.getString(_lastMissedKey) == today) return;

    await _plugin.show(
      id: _missedId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'baru_reminders',
          'Lembretes Baru',
          channelDescription: 'Senti sua falta',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    await prefs.setString(_lastMissedKey, today);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
