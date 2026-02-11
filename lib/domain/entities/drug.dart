import 'drug_type.dart';

class Drug {
  final String id;
  final String arabicName;
  final String englishName;
  final String category;
  final DrugType type;
  final double concentrationMg;
  final double concentrationMl;
  final double minDosePerKg;
  final double maxDosePerKg;
  final double maxDailyDoseMg; // الحد الأقصى للاستخدام الآمن يومياً
  final String description;
  final String dosage;
  final String sideEffects;
  final String contraindications;
  final String? fixedDose;
  final List<String> warningDiseases; // الأمراض التي يتعارض معها الدواء
  final List<String> warningAllergies; // الحساسية التي يتعارض معها الدواء

  const Drug({
    required this.id,
    required this.arabicName,
    required this.englishName,
    required this.category,
    required this.type,
    this.concentrationMg = 0,
    this.concentrationMl = 0,
    this.minDosePerKg = 0,
    this.maxDosePerKg = 0,
    this.maxDailyDoseMg = 0,
    required this.description,
    required this.dosage,
    required this.sideEffects,
    required this.contraindications,
    this.fixedDose,
    this.warningDiseases = const [],
    this.warningAllergies = const [],
  });
  
  // Getters for backward compatibility
  String get name => englishName;
  double get maxDailyDose => maxDailyDoseMg;
}
