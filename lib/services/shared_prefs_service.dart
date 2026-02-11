import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../domain/entities/smart_reminder.dart';
import '../domain/entities/drug_type.dart';
import '../domain/entities/family_member.dart';

/// Service for managing persistent storage with caching
class SharedPrefsService {
  static final SharedPrefsService _instance = SharedPrefsService._internal();
  factory SharedPrefsService() => _instance;
  SharedPrefsService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Cache keys
  static const String _remindersKey = 'reminders';
  static const String _familyMembersKey = 'family_members';
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _onboardingKey = 'onboarding_complete';
  static const String _lastSyncKey = 'last_sync';

  /// Initialize shared preferences
  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    debugPrint('SharedPrefsService initialized');
  }

  /// Ensure initialized before operations
  Future<SharedPreferences> get _preferences async {
    if (_prefs == null) await init();
    return _prefs!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REMINDERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save reminders to storage
  Future<void> saveReminders(List<SmartReminder> reminders) async {
    try {
      final prefs = await _preferences;
      final remindersJson = reminders.map((r) => jsonEncode({
        'id': r.id,
        'drugName': r.drugName,
        'type': r.type.name,
        'dosage': r.dosage,
        'timesPerDay': r.timesPerDay.map((t) => {'hour': t.hour, 'minute': t.minute}).toList(),
        'durationDays': r.durationDays,
        'startDate': r.startDate.toIso8601String(),
        'isActive': r.isActive,
        'dosesTaken': r.dosesTaken,
        'isChronic': r.isChronic,
        'currentStock': r.currentStock,
        'lowStockThreshold': r.lowStockThreshold,
        'doseAmount': r.doseAmount,
        'familyMemberId': r.familyMemberId,
        'familyMemberName': r.familyMemberName,
      })).toList();
      await prefs.setStringList(_remindersKey, remindersJson);
      debugPrint('Saved ${reminders.length} reminders');
    } catch (e) {
      debugPrint('Error saving reminders: $e');
      rethrow;
    }
  }

  /// Load reminders from storage
  Future<List<SmartReminder>> loadReminders() async {
    try {
      final prefs = await _preferences;
      final remindersJson = prefs.getStringList(_remindersKey) ?? [];
      return remindersJson.map((json) {
        final data = jsonDecode(json);
        return SmartReminder(
          id: data['id'],
          drugName: data['drugName'],
          type: DrugType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => DrugType.tablet,
          ),
          dosage: data['dosage'],
          timesPerDay: (data['timesPerDay'] as List)
              .map((t) => TimeOfDay(hour: t['hour'], minute: t['minute']))
              .toList(),
          durationDays: data['durationDays'],
          startDate: DateTime.parse(data['startDate']),
          isActive: data['isActive'] ?? true,
          dosesTaken: data['dosesTaken'] ?? 0,
          isChronic: data['isChronic'] ?? false,
          currentStock: data['currentStock'] ?? 0,
          lowStockThreshold: data['lowStockThreshold'] ?? 5,
          doseAmount: (data['doseAmount'] ?? 1.0).toDouble(),
          familyMemberId: data['familyMemberId'],
          familyMemberName: data['familyMemberName'],
        );
      }).toList().cast<SmartReminder>();
    } catch (e) {
      debugPrint('Error loading reminders: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAMILY MEMBERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save family members to storage
  Future<void> saveFamilyMembers(List<FamilyMember> members) async {
    try {
      final prefs = await _preferences;
      final membersJson = members.map((m) => jsonEncode({
        'id': m.id,
        'name': m.name,
        'age': m.age,
        'relationship': m.relationship,
        'medications': m.medications,
        'chronicDiseases': m.chronicDiseases,
        'allergies': m.allergies,
        'notes': m.notes,
        'lastUpdated': m.lastUpdated.toIso8601String(),
        'weight': m.weight,
      })).toList();
      await prefs.setStringList(_familyMembersKey, membersJson);
      debugPrint('Saved ${members.length} family members');
    } catch (e) {
      debugPrint('Error saving family members: $e');
      rethrow;
    }
  }

  /// Load family members from storage
  Future<List<FamilyMember>> loadFamilyMembers() async {
    try {
      final prefs = await _preferences;
      final membersJson = prefs.getStringList(_familyMembersKey) ?? [];
      return membersJson.map((json) {
        final data = jsonDecode(json);
        return FamilyMember(
          id: data['id'],
          name: data['name'],
          age: data['age'],
          relationship: data['relationship'],
          medications: List<String>.from(data['medications'] ?? []),
          chronicDiseases: List<String>.from(data['chronicDiseases'] ?? []),
          allergies: List<String>.from(data['allergies'] ?? []),
          notes: data['notes'] ?? '',
          lastUpdated: DateTime.parse(data['lastUpdated']),
          weight: data['weight']?.toDouble(),
        );
      }).toList().cast<FamilyMember>();
    } catch (e) {
      debugPrint('Error loading family members: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save theme mode (0: system, 1: light, 2: dark)
  Future<void> saveThemeMode(int mode) async {
    final prefs = await _preferences;
    await prefs.setInt(_themeKey, mode);
  }

  /// Load theme mode
  Future<int> loadThemeMode() async {
    final prefs = await _preferences;
    return prefs.getInt(_themeKey) ?? 0;
  }

  /// Save language preference
  Future<void> saveLanguage(bool isEnglish) async {
    final prefs = await _preferences;
    await prefs.setBool(_languageKey, isEnglish);
  }

  /// Load language preference
  Future<bool> loadLanguage() async {
    final prefs = await _preferences;
    return prefs.getBool(_languageKey) ?? false;
  }

  /// Save onboarding completion status
  Future<void> setOnboardingComplete(bool complete) async {
    final prefs = await _preferences;
    await prefs.setBool(_onboardingKey, complete);
  }

  /// Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    final prefs = await _preferences;
    return prefs.getBool(_onboardingKey) ?? false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERIC METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save a string value
  Future<void> setString(String key, String value) async {
    final prefs = await _preferences;
    await prefs.setString(key, value);
  }

  /// Get a string value
  Future<String?> getString(String key) async {
    final prefs = await _preferences;
    return prefs.getString(key);
  }

  /// Save an int value
  Future<void> setInt(String key, int value) async {
    final prefs = await _preferences;
    await prefs.setInt(key, value);
  }

  /// Get an int value
  Future<int?> getInt(String key) async {
    final prefs = await _preferences;
    return prefs.getInt(key);
  }

  /// Save a bool value
  Future<void> setBool(String key, bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(key, value);
  }

  /// Get a bool value
  Future<bool?> getBool(String key) async {
    final prefs = await _preferences;
    return prefs.getBool(key);
  }

  /// Remove a key
  Future<void> remove(String key) async {
    final prefs = await _preferences;
    await prefs.remove(key);
  }

  /// Clear all data
  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.clear();
  }

  /// Update last sync timestamp
  Future<void> updateLastSync() async {
    final prefs = await _preferences;
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSync() async {
    final prefs = await _preferences;
    final timestamp = prefs.getString(_lastSyncKey);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }
}
