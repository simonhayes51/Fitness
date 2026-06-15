import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications for rest-timer alerts, workout reminders,
/// streak nudges and goal-achievement celebrations.
///
/// All scheduling is local (no server). FCM push integration lives in
/// [pushIntegrationPoint] for v2.
///
/// On web notifications are silently skipped — the browser Notifications API
/// is a separate integration not yet wired up.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb) return;
    if (_ready) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static const _restChannel = AndroidNotificationDetails(
    'rest_timer',
    'Rest Timers',
    channelDescription: 'Alerts when your rest period is complete',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );

  static const _reminderChannel = AndroidNotificationDetails(
    'reminders',
    'Reminders',
    channelDescription: 'Workout reminders and streak nudges',
    importance: Importance.defaultImportance,
  );

  /// Fire a rest-complete notification [seconds] from now.
  Future<void> scheduleRestComplete(int seconds) async {
    if (kIsWeb || !_ready) return;
    await _plugin.zonedSchedule(
      1001,
      'Rest complete 💥',
      'Time for your next set.',
      tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      const NotificationDetails(android: _restChannel, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelRestTimer() async {
    if (kIsWeb) return;
    await _plugin.cancel(1001);
  }

  /// Schedule a daily workout reminder at [hour]:[minute].
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String title = 'Time to train 🏋️',
    String body = 'Keep your streak alive — log today\'s workout.',
  }) async {
    if (kIsWeb || !_ready) return;
    await _plugin.zonedSchedule(
      2001,
      title,
      body,
      _nextInstanceOf(hour, minute),
      const NotificationDetails(android: _reminderChannel, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showGoalAchieved(String goalTitle) async {
    if (kIsWeb || !_ready) return;
    await _plugin.show(
      3001,
      'Goal achieved! 🎉',
      'You hit "$goalTitle". Outstanding work.',
      const NotificationDetails(android: _reminderChannel, iOS: DarwinNotificationDetails()),
    );
  }

  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    await _plugin.cancel(2001);
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// v2 integration point: register the device's FCM token with your backend
  /// to enable server-driven push (coach messages, social, etc.).
  void pushIntegrationPoint(String? fcmToken) {
    if (kDebugMode) {
      debugPrint('[NotificationService] FCM token ready: $fcmToken');
    }
  }
}
