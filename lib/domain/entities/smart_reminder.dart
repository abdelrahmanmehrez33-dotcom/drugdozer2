import 'package:flutter/material.dart';
import 'drug_type.dart';

class SmartReminder {
  final String id;
  final String drugName;
  final DrugType type;
  final String dosage;
  final List<TimeOfDay> timesPerDay;
  final int? durationDays; // Nullable for chronic diseases
  final DateTime startDate;
  bool isActive;
  int dosesTaken;
  
  // New fields for chronic disease and stock management
  final bool isChronic;
  int currentStock; // Total units (tablets, ml, etc.)
  final int lowStockThreshold; // Alert when stock reaches this level
  final double doseAmount; // Amount taken per dose (e.g., 1 tablet, 5ml)

  // Link to family member
  final String? familyMemberId;
  final String? familyMemberName;

  SmartReminder({
    required this.id,
    required this.drugName,
    required this.type,
    required this.dosage,
    required this.timesPerDay,
    this.durationDays,
    required this.startDate,
    this.isActive = true,
    this.dosesTaken = 0,
    this.isChronic = false,
    this.currentStock = 0,
    this.lowStockThreshold = 5,
    this.doseAmount = 1.0,
    this.familyMemberId,
    this.familyMemberName,
  });

  bool get isLowStock => currentStock <= lowStockThreshold;
  
  // Getters for backward compatibility
  List<TimeOfDay> get times => timesPerDay;
  DateTime? get endDate => isChronic ? null : (durationDays != null ? startDate.add(Duration(days: durationDays!)) : null);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drugName': drugName,
      'type': type.index,
      'dosage': dosage,
      'timesPerDay': timesPerDay.map((t) => {'hour': t.hour, 'minute': t.minute}).toList(),
      'durationDays': durationDays,
      'startDate': startDate.toIso8601String(),
      'isActive': isActive,
      'dosesTaken': dosesTaken,
      'isChronic': isChronic,
      'currentStock': currentStock,
      'lowStockThreshold': lowStockThreshold,
      'doseAmount': doseAmount,
      'familyMemberId': familyMemberId,
      'familyMemberName': familyMemberName,
    };
  }

  factory SmartReminder.fromMap(Map<String, dynamic> map) {
    return SmartReminder(
      id: map['id'],
      drugName: map['drugName'],
      type: DrugType.values[map['type']],
      dosage: map['dosage'],
      timesPerDay: (map['timesPerDay'] as List).map((t) => TimeOfDay(hour: t['hour'], minute: t['minute'])).toList(),
      durationDays: map['durationDays'],
      startDate: DateTime.parse(map['startDate']),
      isActive: map['isActive'],
      dosesTaken: map['dosesTaken'],
      isChronic: map['isChronic'] ?? false,
      currentStock: map['currentStock'] ?? 0,
      lowStockThreshold: map['lowStockThreshold'] ?? 5,
      doseAmount: (map['doseAmount'] ?? 1.0).toDouble(),
      familyMemberId: map['familyMemberId'],
      familyMemberName: map['familyMemberName'],
    );
  }
}
