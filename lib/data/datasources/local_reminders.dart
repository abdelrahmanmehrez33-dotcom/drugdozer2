import 'dart:io';
import '../../domain/entities/smart_reminder.dart';
import '../../services/shared_prefs_service.dart';
import '../../services/notification_service.dart';
import '../../services/background_service.dart';
import '../../di/service_locator.dart';

/// Global list of active reminders
List<SmartReminder> smartReminders = [];

/// Service for managing medication reminders
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final SharedPrefsService _prefsService = SharedPrefsService();
  bool _isLoaded = false;

  /// Load reminders from persistent storage
  Future<void> loadReminders() async {
    smartReminders = await _prefsService.loadReminders();
    _isLoaded = true;
  }

  /// Ensure reminders are loaded
  Future<void> ensureLoaded() async {
    if (!_isLoaded) {
      await loadReminders();
    }
  }

  /// Save reminders to persistent storage
  Future<void> saveReminders() async {
    await _prefsService.saveReminders(smartReminders);
  }

  /// Add a new reminder with notification scheduling
  Future<void> addReminder(SmartReminder reminder, {bool isEnglish = false}) async {
    smartReminders.add(reminder);
    await saveReminders();
    
    // Schedule notifications
    await _scheduleReminderNotifications(reminder, isEnglish: isEnglish);
  }

  /// Update an existing reminder
  Future<void> updateReminder(SmartReminder reminder, {bool isEnglish = false}) async {
    final index = smartReminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      // Cancel old notifications
      await _cancelReminderNotifications(smartReminders[index]);
      
      // Update reminder
      smartReminders[index] = reminder;
      await saveReminders();
      
      // Schedule new notifications
      if (reminder.isActive) {
        await _scheduleReminderNotifications(reminder, isEnglish: isEnglish);
      }
    }
  }

  /// Remove a reminder
  Future<void> removeReminder(String id) async {
    final reminder = smartReminders.firstWhere(
      (r) => r.id == id,
      orElse: () => throw Exception('Reminder not found'),
    );
    
    // Cancel notifications
    await _cancelReminderNotifications(reminder);
    
    // Remove from list
    smartReminders.removeWhere((r) => r.id == id);
    await saveReminders();
  }

  /// Toggle reminder active state
  Future<void> toggleReminderActive(String id, {bool isEnglish = false}) async {
    final index = smartReminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      smartReminders[index].isActive = !smartReminders[index].isActive;
      await saveReminders();
      
      if (smartReminders[index].isActive) {
        await _scheduleReminderNotifications(smartReminders[index], isEnglish: isEnglish);
      } else {
        await _cancelReminderNotifications(smartReminders[index]);
      }
    }
  }

  /// Record a dose taken and update stock
  Future<void> takeDose(String id, {bool isEnglish = false}) async {
    final index = smartReminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final reminder = smartReminders[index];
      reminder.dosesTaken++;
      
      // Deduct from stock
      if (reminder.currentStock > 0) {
        reminder.currentStock = (reminder.currentStock - reminder.doseAmount).toInt();
        if (reminder.currentStock < 0) reminder.currentStock = 0;
        
        // Check for low stock alert
        if (reminder.isLowStock && reminder.currentStock > 0) {
          await getIt<NotificationService>().showStockAlert(
            id: reminder.id.hashCode + 999,
            drugName: reminder.drugName,
            remainingStock: reminder.currentStock,
            isEnglish: isEnglish,
          );
        }
      }
      
      await saveReminders();
    }
  }

  /// Refill stock for a reminder
  Future<void> refillStock(String id, int amount) async {
    final index = smartReminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      smartReminders[index].currentStock += amount;
      await saveReminders();
    }
  }

  /// Get reminders for a specific family member
  List<SmartReminder> getRemindersForMember(String memberId) {
    return smartReminders.where((r) => r.familyMemberId == memberId).toList();
  }

  /// Get active reminders only
  List<SmartReminder> get activeReminders {
    return smartReminders.where((r) => r.isActive).toList();
  }

  /// Get reminders with low stock
  List<SmartReminder> get lowStockReminders {
    return smartReminders.where((r) => r.isLowStock && r.isActive).toList();
  }

  /// Schedule notifications for a reminder
  Future<void> _scheduleReminderNotifications(SmartReminder reminder, {bool isEnglish = false}) async {
    // Schedule using NotificationService
    await getIt<NotificationService>().scheduleFromReminder(reminder, isEnglish: isEnglish);
    
    // Also schedule using BackgroundService for reliability (Android only)
    if (Platform.isAndroid) {
      await getIt<BackgroundService>().scheduleReminderAlarm(reminder);
    }
  }

  /// Cancel notifications for a reminder
  Future<void> _cancelReminderNotifications(SmartReminder reminder) async {
    await getIt<NotificationService>().cancelReminderNotifications(reminder);
    
    if (Platform.isAndroid) {
      await getIt<BackgroundService>().cancelReminderAlarms(reminder);
    }
  }

  /// Reschedule all active reminders (called after app restart)
  Future<void> rescheduleAllReminders({bool isEnglish = false}) async {
    for (final reminder in smartReminders) {
      if (reminder.isActive) {
        await _scheduleReminderNotifications(reminder, isEnglish: isEnglish);
      }
    }
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalReminders': smartReminders.length,
      'activeReminders': activeReminders.length,
      'chronicReminders': smartReminders.where((r) => r.isChronic).length,
      'lowStockCount': lowStockReminders.length,
      'totalDosesTaken': smartReminders.fold<int>(0, (sum, r) => sum + r.dosesTaken),
    };
  }
}
