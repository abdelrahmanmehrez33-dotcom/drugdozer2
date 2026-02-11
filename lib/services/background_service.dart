import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../domain/entities/smart_reminder.dart';

/// Background service for handling medication reminders
/// Works even when app is killed or device is restarted
class BackgroundService {
  static const String _isolateName = 'drugdozer_background_isolate';
  static const String _activeRemindersKey = 'active_reminders_for_background';
  static const String _reminderAlarmPrefix = 'reminder_alarm_';

  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  bool _isInitialized = false;
  final ReceivePort _receivePort = ReceivePort();

  /// Initialize the background service
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize Android Alarm Manager
    await AndroidAlarmManager.initialize();

    // Register the port for communication with background isolate
    IsolateNameServer.registerPortWithName(
      _receivePort.sendPort,
      _isolateName,
    );

    // Listen for messages from background
    _receivePort.listen((message) {
      debugPrint('Background message received: $message');
    });

    _isInitialized = true;
    debugPrint('BackgroundService initialized');
  }

  /// Schedule a background alarm for a reminder
  Future<void> scheduleReminderAlarm(SmartReminder reminder) async {
    // Save reminder data for background access
    await _saveReminderForBackground(reminder);

    // Schedule alarms for each time
    for (int i = 0; i < reminder.times.length; i++) {
      final time = reminder.times[i];
      final alarmId = _generateAlarmId(reminder.id, i);

      final now = DateTime.now();
      var scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      if (reminder.isChronic) {
        // For chronic reminders, schedule repeating daily alarm
        await AndroidAlarmManager.periodic(
          const Duration(days: 1),
          alarmId,
          _backgroundCallback,
          startAt: scheduledTime,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
      } else {
        // For non-chronic, schedule one-time alarm
        if (reminder.endDate == null || scheduledTime.isBefore(reminder.endDate!)) {
          await AndroidAlarmManager.oneShotAt(
            scheduledTime,
            alarmId,
            _backgroundCallback,
            exact: true,
            wakeup: true,
            rescheduleOnReboot: true,
          );
        }
      }

      debugPrint('Scheduled background alarm $alarmId for $scheduledTime');
    }
  }

  /// Cancel all alarms for a reminder
  Future<void> cancelReminderAlarms(SmartReminder reminder) async {
    for (int i = 0; i < reminder.times.length; i++) {
      final alarmId = _generateAlarmId(reminder.id, i);
      await AndroidAlarmManager.cancel(alarmId);
    }
    await _removeReminderFromBackground(reminder.id);
  }

  /// Generate unique alarm ID from reminder ID and time index
  int _generateAlarmId(String reminderId, int timeIndex) {
    return (reminderId.hashCode + timeIndex).abs() % 2147483647;
  }

  /// Save reminder data for background isolate access
  Future<void> _saveReminderForBackground(SmartReminder reminder) async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString(_activeRemindersKey);
    Map<String, dynamic> reminders = {};

    if (remindersJson != null) {
      reminders = json.decode(remindersJson) as Map<String, dynamic>;
    }

    reminders[reminder.id] = reminder.toMap();
    await prefs.setString(_activeRemindersKey, json.encode(reminders));
  }

  /// Remove reminder from background storage
  Future<void> _removeReminderFromBackground(String reminderId) async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString(_activeRemindersKey);

    if (remindersJson != null) {
      final reminders = json.decode(remindersJson) as Map<String, dynamic>;
      reminders.remove(reminderId);
      await prefs.setString(_activeRemindersKey, json.encode(reminders));
    }
  }

  /// Static callback for background execution
  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback() async {
    debugPrint('Background alarm triggered');

    // Show notification from background
    await _showBackgroundNotification();

    // Send message to main isolate if available
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(_isolateName);
    sendPort?.send('alarm_triggered');
  }

  /// Show notification from background isolate
  static Future<void> _showBackgroundNotification() async {
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    // Reverted for v17 API
    await notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification response in background: ${response.payload}');
      },
    );

    // Get the current reminder that needs notification
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString(_activeRemindersKey);

    if (remindersJson != null) {
      final reminders = json.decode(remindersJson) as Map<String, dynamic>;
      final now = DateTime.now();
      final currentHour = now.hour;
      final currentMinute = now.minute;

      // Find reminder matching current time
      for (final entry in reminders.entries) {
        try {
          final reminder = SmartReminder.fromMap(entry.value as Map<String, dynamic>);

          for (final time in reminder.times) {
            if (time.hour == currentHour &&
                (time.minute == currentMinute || time.minute == currentMinute - 1)) {
              // Show notification for this reminder
              const androidDetails = AndroidNotificationDetails(
                'medication_reminders',
                'Medication Reminders',
                channelDescription: 'Notifications for medication dose reminders',
                importance: Importance.max,
                priority: Priority.max,
                playSound: true,
                enableVibration: true,
                fullScreenIntent: true,
                category: AndroidNotificationCategory.alarm,
              );

              const notificationDetails = NotificationDetails(android: androidDetails);

              await notifications.show(
                reminder.id.hashCode,
                '💊 ${reminder.drugName}',
                'حان موعد جرعتك: ${reminder.dosage}',
                notificationDetails,
                payload: reminder.id,
              );

              debugPrint('Background notification shown for ${reminder.drugName}');
              break;
            }
          }
        } catch (e) {
          debugPrint('Error processing reminder: $e');
        }
      }
    }
  }

  /// Reschedule all reminders (called after device restart)
  Future<void> rescheduleAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString(_activeRemindersKey);

    if (remindersJson != null) {
      final reminders = json.decode(remindersJson) as Map<String, dynamic>;

      for (final entry in reminders.entries) {
        try {
          final reminder = SmartReminder.fromMap(entry.value as Map<String, dynamic>);
          if (reminder.isActive) {
            await scheduleReminderAlarm(reminder);
          }
        } catch (e) {
          debugPrint('Error rescheduling reminder: $e');
        }
      }
    }
  }

  /// Dispose resources
  void dispose() {
    IsolateNameServer.removePortNameMapping(_isolateName);
    _receivePort.close();
  }
}
