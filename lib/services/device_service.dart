import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

class DeviceService {
  static const _channel = MethodChannel('routine_controller/battery_opt');

  static Future<bool> isBatteryOptimizationEnabled() async {
    try {
      return await _channel.invokeMethod('isBatteryOptimizationEnabled') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } catch (_) {}
  }

  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  static Future<bool> areNotificationsEnabled() async {
    try {
      final plugin = await NotificationService.getAndroidPlugin();
      return await plugin?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> isNotificationChannelBlocked() async {
    try {
      final plugin = await NotificationService.getAndroidPlugin();
      final channels = await plugin?.getNotificationChannels();
      if (channels == null) return false;
      for (final channel in channels) {
        if (channel.id == 'routine_controller_alerts') {
          return channel.importance == Importance.none;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasExactAlarmPermission() async {
    try {
      final plugin = await NotificationService.getAndroidPlugin();
      return await plugin?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> requestExactAlarmPermission() async {
    try {
      final plugin = await NotificationService.getAndroidPlugin();
      await plugin?.requestExactAlarmsPermission();
    } catch (_) {}
  }
}
