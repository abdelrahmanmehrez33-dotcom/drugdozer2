import 'package:flutter/material.dart';

class FamilyMember {
  final String id;
  String name;
  int age;
  String relationship;
  List<String> medications;
  List<String> chronicDiseases;
  List<String> allergies;
  String notes;
  DateTime lastUpdated;
  double? weight; // Weight in kg for pediatric dose calculation

  FamilyMember({
    required this.id,
    required this.name,
    required this.age,
    required this.relationship,
    this.medications = const [],
    this.chronicDiseases = const [],
    this.allergies = const [],
    this.notes = '',
    DateTime? lastUpdated,
    this.weight,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
  
  // Getter for backward compatibility
  List<String> get currentMedications => medications;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'relationship': relationship,
      'medications': medications,
      'chronicDiseases': chronicDiseases,
      'allergies': allergies,
      'notes': notes,
      'lastUpdated': lastUpdated.toIso8601String(),
      'weight': weight,
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      relationship: map['relationship'],
      medications: List<String>.from(map['medications']),
      chronicDiseases: List<String>.from(map['chronicDiseases']),
      allergies: List<String>.from(map['allergies']),
      notes: map['notes'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
      weight: map['weight']?.toDouble(),
    );
  }
}