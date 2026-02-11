import 'package:flutter/material.dart';
import '../../services/shared_prefs_service.dart';
import '../../domain/entities/family_member.dart';

export '../../domain/entities/family_member.dart';

class FamilyProvider extends ChangeNotifier {
  List<FamilyMember> _familyMembers = [];
  final SharedPrefsService _prefsService = SharedPrefsService();

  List<FamilyMember> get familyMembers => _familyMembers;
  
  // Alias for backward compatibility
  List<FamilyMember> get members => _familyMembers;

  FamilyProvider() {
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    _familyMembers = await _prefsService.loadFamilyMembers();
    notifyListeners();
  }

  Future<void> addMember(FamilyMember member) async {
    _familyMembers.add(member);
    await _prefsService.saveFamilyMembers(_familyMembers);
    notifyListeners();
  }

  Future<void> updateMember(FamilyMember member) async {
    final index = _familyMembers.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _familyMembers[index] = member;
      await _prefsService.saveFamilyMembers(_familyMembers);
      notifyListeners();
    }
  }

  Future<void> removeMember(String id) async {
    _familyMembers.removeWhere((m) => m.id == id);
    await _prefsService.saveFamilyMembers(_familyMembers);
    notifyListeners();
  }

  Future<void> addChronicDisease(String memberId, String disease) async {
    final index = _familyMembers.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      _familyMembers[index].chronicDiseases.add(disease);
      _familyMembers[index].lastUpdated = DateTime.now();
      await _prefsService.saveFamilyMembers(_familyMembers);
      notifyListeners();
    }
  }

  Future<void> removeChronicDisease(String memberId, String disease) async {
    final index = _familyMembers.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      _familyMembers[index].chronicDiseases.remove(disease);
      _familyMembers[index].lastUpdated = DateTime.now();
      await _prefsService.saveFamilyMembers(_familyMembers);
      notifyListeners();
    }
  }

  Future<void> addAllergy(String memberId, String allergy) async {
    final index = _familyMembers.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      _familyMembers[index].allergies.add(allergy);
      _familyMembers[index].lastUpdated = DateTime.now();
      await _prefsService.saveFamilyMembers(_familyMembers);
      notifyListeners();
    }
  }

  Future<void> removeAllergy(String memberId, String allergy) async {
    final index = _familyMembers.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      _familyMembers[index].allergies.remove(allergy);
      _familyMembers[index].lastUpdated = DateTime.now();
      await _prefsService.saveFamilyMembers(_familyMembers);
      notifyListeners();
    }
  }

  Future<void> addMedication(String memberId, String medication) async {
    final index = _familyMembers.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      _familyMembers[index].medications.add(medication);
      _familyMembers[index].lastUpdated = DateTime.now();
      await _prefsService.saveFamilyMembers(_familyMembers);
      notifyListeners();
    }
  }

  Future<void> removeMedication(String memberId, String medication) async {
    final index = _familyMembers.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      _familyMembers[index].medications.remove(medication);
      _familyMembers[index].lastUpdated = DateTime.now();
      await _prefsService.saveFamilyMembers(_familyMembers);
      notifyListeners();
    }
  }

  Future<void> updateNotes(String memberId, String notes) async {
    final index = _familyMembers.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      _familyMembers[index].notes = notes;
      _familyMembers[index].lastUpdated = DateTime.now();
      await _prefsService.saveFamilyMembers(_familyMembers);
      notifyListeners();
    }
  }
}
