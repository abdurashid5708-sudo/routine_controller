import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ---------------------------------------------------------------------------
  // INIT - call once in main() before runApp()
  // ---------------------------------------------------------------------------
  static Future<void> init() async {
    if (_initialized) return;

    // 1. Load timezone database
    tz_data.initializeTimeZones();

    // 2. Set device local timezone
    final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    // 3. Init notifications plugin
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // User tapped notification - navigation can be handled here later
      },
    );

    // 4. Request Android 13+ notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // 5. Request exact alarm permission (Android 12+)
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();

    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATION DETAILS (reusable)
  // ---------------------------------------------------------------------------
  static NotificationDetails _buildDetails({
    bool urgent = false,
    String channelId = 'routine_controller_alerts',
    String channelName = 'Routine Controller Alerts',
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Time block reminders and penalty alerts',
        importance: urgent ? Importance.max : Importance.high,
        priority: urgent ? Priority.max : Priority.high,
        enableVibration: true,
        playSound: true,
        visibility: urgent
            ? NotificationVisibility.public
            : NotificationVisibility.private,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCHEDULE ESCALATING NOTIFICATIONS
  // Hands off to Android OS - survives app close
  // ---------------------------------------------------------------------------
  static Future<void> scheduleEscalatingNotifications({
    required String missionId,
    required String missionTitle,
    required DateTime startTime,
  }) async {
    await cancelMissionNotifications(missionId);

    final now = DateTime.now();
    final baseId = missionId.hashCode.abs() % 100000;
    final tzStart = tz.TZDateTime.from(startTime, tz.local);
    final tzNow = tz.TZDateTime.now(tz.local);

    // --- 5 min before ---
    final fiveBefore = tzStart.subtract(const Duration(minutes: 5));
    if (fiveBefore.isAfter(tzNow)) {
      await _scheduleOne(
        id: baseId + 1,
        title: '⏳ Starting soon: $missionTitle',
        body: 'Get ready! Your time block starts in 5 minutes.',
        scheduledDate: fiveBefore,
        urgent: false,
      );
    }

    // --- At start time ---
    if (startTime.isAfter(now)) {
      await _scheduleOne(
        id: baseId + 2,
        title: '🔥 START NOW: $missionTitle',
        body: 'Your time block has begun. Tap to mark as started.',
        scheduledDate: tzStart,
        urgent: true,
      );
    }

    // --- 5 min after ---
    final fiveAfter = tzStart.add(const Duration(minutes: 5));
    if (fiveAfter.isAfter(tzNow)) {
      await _scheduleOne(
        id: baseId + 3,
        title: '⚠️ Still waiting: $missionTitle',
        body: 'You haven\'t started yet. Don\'t lose your streak!',
        scheduledDate: fiveAfter,
        urgent: true,
      );
    }

    // --- 15 min after: last warning ---
    final fifteenAfter = tzStart.add(const Duration(minutes: 15));
    if (fifteenAfter.isAfter(tzNow)) {
      await _scheduleOne(
        id: baseId + 4,
        title: '🚨 FINAL WARNING: $missionTitle',
        body: 'Penalty in 15 minutes if you don\'t start. Lock incoming!',
        scheduledDate: fifteenAfter,
        urgent: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // INTERNAL: schedule a single notification
  // ---------------------------------------------------------------------------
  static Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    bool urgent = false,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _buildDetails(urgent: urgent),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: id.toString(),
      );
      debugPrint(
        'Notification scheduled: id=$id title=$title at=$scheduledDate',
      );
    } catch (e) {
      debugPrint('Exact alarm failed (id=$id): $e — falling back to inexact');
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: _buildDetails(urgent: urgent),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: id.toString(),
        );
        debugPrint('Inexact fallback succeeded: id=$id');
      } catch (e2) {
        debugPrint('Inexact fallback also FAILED (id=$id): $e2');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // INSTANT NOTIFICATION - fires immediately
  // Used for penalty lock alerts
  // ---------------------------------------------------------------------------
  static Future<void> showInstant({
    required String title,
    required String body,
    int id = 0,
    bool urgent = true,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _buildDetails(urgent: urgent),
    );
  }

  // ---------------------------------------------------------------------------
  // CANCEL all notifications for a mission (slots 1-4)
  // ---------------------------------------------------------------------------
  static Future<void> cancelMissionNotifications(String missionId) async {
    final baseId = missionId.hashCode.abs() % 100000;
    await _plugin.cancel(id: baseId + 1);
    await _plugin.cancel(id: baseId + 2);
    await _plugin.cancel(id: baseId + 3);
    await _plugin.cancel(id: baseId + 4);
  }

  // ---------------------------------------------------------------------------
  // CANCEL ALL notifications
  // ---------------------------------------------------------------------------
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ---------------------------------------------------------------------------
  // ANDROID PLUGIN — used by DeviceService for channel checks
  // ---------------------------------------------------------------------------
  static Future<AndroidFlutterLocalNotificationsPlugin?>
  getAndroidPlugin() async {
    return _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }
}
