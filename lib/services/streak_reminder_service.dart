import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'game_storage.dart';

/// Daily local notification to remind the user to play and keep their streak (этап 2a).
class StreakReminderService {
  StreakReminderService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _notificationId = 9001;
  static const String _channelId = 'streak_reminder';
  static const String _channelName = 'Streak reminder';
  static const String _channelDescription = 'Daily reminder to play Sudoku';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(
          android: android, iOS: darwin, macOS: darwin),
    );
    _initialized = true;
  }

  /// Android 13+ / iOS: request permission. Returns true if granted or not applicable.
  static Future<bool> requestNotificationPermission() async {
    await init();
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final r =
          await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return r ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final mac = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      final r =
          await mac?.requestPermissions(alert: true, badge: true, sound: true);
      return r ?? false;
    }
    return true;
  }

  static Future<void> cancelReminder() async {
    await init();
    await _plugin.cancel(_notificationId);
  }

  /// Schedules daily notification at [hour]:[minute] local time. [body] must be non-empty.
  static Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await init();
    await cancelReminder();

    final scheduled = _nextInstanceOf(hour, minute);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
        android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

    await _plugin.zonedSchedule(
      _notificationId,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Reads GameStorage and schedules or cancels.
  static Future<void> applyFromStorage({
    required String defaultTitle,
    required String defaultBody,
  }) async {
    await init();
    if (!GameStorage.loadReminderEnabled()) {
      await cancelReminder();
      return;
    }
    final time = GameStorage.loadReminderTime();
    final parts = time.split(':');
    final h = int.tryParse(parts[0].trim())?.clamp(0, 23) ?? 19;
    final m =
        int.tryParse(parts.length > 1 ? parts[1].trim() : '0')?.clamp(0, 59) ??
            0;
    var text = GameStorage.loadReminderText().trim();
    if (text.isEmpty) text = defaultBody;
    await scheduleDaily(hour: h, minute: m, title: defaultTitle, body: text);
  }
}
