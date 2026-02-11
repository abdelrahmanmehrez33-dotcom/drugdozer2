import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/smart_reminder.dart';

/// Custom Time class since flutter_local_notifications removed it in some versions
class NotificationTime {
  final int hour;
  final int minute;
  final int second;

  const NotificationTime(this.hour, this.minute, [this.second = 0]);
}

/// Callback for handling notification taps in background
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('Background notification tapped: ${response.payload}');
}

/// Production-ready notification service for medication reminders
/// Handles scheduling, background execution, and device restart scenarios
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  StreamController<String?>? _selectNotificationStream;

  // Notification channel IDs
  static const String _medicationChannelId = 'medication_reminders';
  static const String _medicationChannelName = 'Medication Reminders';
  static const String _medicationChannelDesc = 'Notifications for medication dose reminders';

  static const String _stockAlertChannelId = 'stock_alerts';
  static const String _stockAlertChannelName = 'Stock Alerts';
  static const String _stockAlertChannelDesc = 'Notifications for low medication stock';

  static const String _urgentChannelId = 'urgent_reminders';
  static const String _urgentChannelName = 'Urgent Reminders';
  static const String _urgentChannelDesc = 'Critical medication reminders';

  // Keys for SharedPreferences
  static const String _pendingRemindersKey = 'pending_reminders';

  Stream<String?> get selectNotificationStream =>
      _selectNotificationStream?.stream ?? const Stream.empty();

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();
    
    // Try to get local timezone, fallback to UTC
    try {
      final String timeZoneName = await _getLocalTimeZone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Could not set local timezone: $e');
    }

    _selectNotificationStream = StreamController<String?>.broadcast();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'medication_category',
          actions: [
            DarwinNotificationAction.plain(
              'take_dose',
              'Mark as Taken ✓',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              'snooze',
              'Snooze 10 min',
            ),
          ],
          options: {
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          },
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _createNotificationChannels();
    await _requestPermissions();
    await _reschedulePendingReminders();

    _isInitialized = true;
    debugPrint('NotificationService initialized successfully');
  }

  Future<String> _getLocalTimeZone() async {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      for (final location in tz.timeZoneDatabase.locations.values) {
        final tzOffset = location.currentTimeZone.offset;
        if (tzOffset == offset.inMilliseconds) {
          return location.name;
        }
      }
      final hours = offset.inHours;
      if (hours == 3) return 'Asia/Riyadh';
      if (hours == 2) return 'Africa/Cairo';
      if (hours == 4) return 'Asia/Dubai';
      return 'UTC';
    } catch (e) {
      return 'UTC';
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _medicationChannelId,
          _medicationChannelName,
          description: _medicationChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF00897B),
          showBadge: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _stockAlertChannelId,
          _stockAlertChannelName,
          description: _stockAlertChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _urgentChannelId,
          _urgentChannelName,
          description: _urgentChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFFFF5252),
        ),
      );
    }
  }

  Future<bool> _requestPermissions() async {
    bool granted = true;
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final notificationPermission = await androidPlugin.requestNotificationsPermission();
        final exactAlarmPermission = await androidPlugin.requestExactAlarmsPermission();
        granted = (notificationPermission ?? false) && (exactAlarmPermission ?? false);
      }
    }
    if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        ) ?? false;
      }
    }
    return granted;
  }

  void _onNotificationTapped(NotificationResponse response) {
    _selectNotificationStream?.add(response.payload);
    if (response.actionId == 'take_dose') {
      _handleTakeDoseAction(response.payload);
    } else if (response.actionId == 'snooze') {
      _handleSnoozeAction(response.payload);
    }
  }

  void _handleTakeDoseAction(String? payload) {
    debugPrint('Dose taken for reminder: $payload');
  }

  void _handleSnoozeAction(String? payload) {
    if (payload != null) {
      final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
      scheduleMedicationReminder(
        id: payload.hashCode + 10000,
        title: '⏰ Snoozed Reminder',
        body: 'Time to take your medication!',
        scheduledTime: snoozeTime,
        payload: payload,
      );
    }
  }

  Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool isUrgent = false,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      isUrgent ? _urgentChannelId : _medicationChannelId,
      isUrgent ? _urgentChannelName : _medicationChannelName,
      channelDescription: isUrgent ? _urgentChannelDesc : _medicationChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: isUrgent ? const Color(0xFFFF5252) : const Color(0xFF00897B),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: [
        const AndroidNotificationAction('take_dose', 'Mark as Taken ✓'),
        const AndroidNotificationAction('snooze', 'Snooze 10 min'),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'medication_category',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required NotificationTime time,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _medicationChannelId,
      _medicationChannelName,
      channelDescription: _medicationChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: [const AndroidNotificationAction('take_dose', 'Mark as Taken ✓')],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'medication_category',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  // Fixed method signature to match local_reminders.dart call
  Future<void> showStockAlert({
    required int id,
    required String drugName,
    required int remainingStock,
    bool isEnglish = true,
    String? payload,
  }) async {
    final title = isEnglish ? '⚠️ Low Stock Alert' : '⚠️ تنبيه انخفاض المخزون';
    final body = isEnglish 
        ? 'Your stock for $drugName is running low ($remainingStock remaining)'
        : 'مخزون $drugName منخفض (بقي $remainingStock)';

    const androidDetails = AndroidNotificationDetails(
      _stockAlertChannelId,
      _stockAlertChannelName,
      channelDescription: _stockAlertChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notifications.show(id, title, body, notificationDetails, payload: payload);
  }

  // Fixed method signature to match local_reminders.dart call (added isEnglish)
  Future<void> scheduleFromReminder(SmartReminder reminder, {bool isEnglish = true}) async {
    final title = isEnglish ? '💊 Medication Time' : '💊 موعد الدواء';
    final body = isEnglish 
        ? 'Time to take your ${reminder.drugName} (${reminder.dosage})'
        : 'حان موعد تناول ${reminder.drugName} (${reminder.dosage})';

    for (int i = 0; i < reminder.times.length; i++) {
      final time = reminder.times[i];
      final notificationId = reminder.id.hashCode + i;
      final nTime = NotificationTime(time.hour, time.minute);

      if (reminder.isChronic) {
        await scheduleDailyReminder(
          id: notificationId,
          title: title,
          body: reminder.familyMemberName != null ? '$body (${reminder.familyMemberName})' : body,
          time: nTime,
          payload: reminder.id,
        );
      } else {
        final now = DateTime.now();
        var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));
        if (reminder.endDate == null || scheduledDate.isBefore(reminder.endDate!)) {
          await scheduleMedicationReminder(
            id: notificationId,
            title: title,
            body: reminder.familyMemberName != null ? '$body (${reminder.familyMemberName})' : body,
            scheduledTime: scheduledDate,
            payload: reminder.id,
          );
        }
      }
    }
    await _savePendingReminder(reminder);
  }

  Future<void> _savePendingReminder(SmartReminder reminder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getString(_pendingRemindersKey);
      Map<String, dynamic> pending = pendingJson != null ? json.decode(pendingJson) : {};
      pending[reminder.id] = reminder.toMap();
      await prefs.setString(_pendingRemindersKey, json.encode(pending));
    } catch (e) {
      debugPrint('Error saving pending reminder: $e');
    }
  }

  Future<void> _reschedulePendingReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getString(_pendingRemindersKey);
      if (pendingJson != null) {
        final pending = json.decode(pendingJson) as Map<String, dynamic>;
        for (final entry in pending.entries) {
          final reminder = SmartReminder.fromMap(entry.value as Map<String, dynamic>);
          if (reminder.isActive) await scheduleFromReminder(reminder);
        }
      }
    } catch (e) {
      debugPrint('Error rescheduling pending reminders: $e');
    }
  }

  Future<void> cancelNotification(int id) async => await _notifications.cancel(id);

  Future<void> cancelReminderNotifications(SmartReminder reminder) async {
    for (int i = 0; i < reminder.times.length; i++) {
      await cancelNotification(reminder.id.hashCode + i);
    }
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString(_pendingRemindersKey);
    if (pendingJson != null) {
      final pending = json.decode(pendingJson) as Map<String, dynamic>;
      pending.remove(reminder.id);
      await prefs.setString(_pendingRemindersKey, json.encode(pending));
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingRemindersKey);
  }

  Future<bool> requestPermissions() async => await _requestPermissions();

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await scheduleMedicationReminder(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledDate,
      payload: payload,
    );
  }
}
