import '../domain/entities/drug.dart';

class DrugInteractionService {
  static final DrugInteractionService _instance = DrugInteractionService._internal();
  factory DrugInteractionService() => _instance;
  DrugInteractionService._internal();

  // Check for interactions between a drug and patient's conditions
  DrugInteractionResult checkInteractions({
    required Drug drug,
    required List<String> chronicDiseases,
    required List<String> allergies,
  }) {
    final List<DrugWarning> warnings = [];

    // Check disease contraindications
    for (final disease in chronicDiseases) {
      final diseaseWarning = _checkDiseaseInteraction(drug, disease);
      if (diseaseWarning != null) {
        warnings.add(diseaseWarning);
      }
    }

    // Check allergy contraindications
    for (final allergy in allergies) {
      final allergyWarning = _checkAllergyInteraction(drug, allergy);
      if (allergyWarning != null) {
        warnings.add(allergyWarning);
      }
    }

    // Determine severity
    WarningLevel overallLevel = WarningLevel.safe;
    if (warnings.any((w) => w.level == WarningLevel.danger)) {
      overallLevel = WarningLevel.danger;
    } else if (warnings.any((w) => w.level == WarningLevel.warning)) {
      overallLevel = WarningLevel.warning;
    } else if (warnings.any((w) => w.level == WarningLevel.caution)) {
      overallLevel = WarningLevel.caution;
    }

    return DrugInteractionResult(
      drug: drug,
      warnings: warnings,
      overallLevel: overallLevel,
    );
  }

  DrugWarning? _checkDiseaseInteraction(Drug drug, String disease) {
    final diseaseLower = disease.toLowerCase();
    final drugNameLower = drug.name.toLowerCase();
    final drugCategoryLower = drug.category.toLowerCase();

    // Kidney Disease Interactions
    if (_containsAny(diseaseLower, ['كلى', 'kidney', 'renal', 'فشل كلوي'])) {
      if (_containsAny(drugNameLower, ['ibuprofen', 'ايبوبروفين', 'nsaid', 'diclofenac', 'ديكلوفيناك', 'naproxen', 'نابروكسين', 'ketoprofen', 'كيتوبروفين'])) {
        return DrugWarning(
          level: WarningLevel.danger,
          titleAr: 'خطر على الكلى',
          titleEn: 'Kidney Risk',
          messageAr: 'هذا الدواء قد يسبب تدهور وظائف الكلى. يجب استشارة الطبيب قبل الاستخدام.',
          messageEn: 'This medication may worsen kidney function. Consult a doctor before use.',
          condition: disease,
        );
      }
      if (_containsAny(drugNameLower, ['metformin', 'ميتفورمين'])) {
        return DrugWarning(
          level: WarningLevel.danger,
          titleAr: 'خطر الحماض اللاكتيكي',
          titleEn: 'Lactic Acidosis Risk',
          messageAr: 'الميتفورمين قد يسبب حماض لاكتيكي في مرضى الكلى. يجب تعديل الجرعة أو استبدال الدواء.',
          messageEn: 'Metformin may cause lactic acidosis in kidney patients. Dose adjustment or alternative needed.',
          condition: disease,
        );
      }
    }

    // Liver Disease Interactions
    if (_containsAny(diseaseLower, ['كبد', 'liver', 'hepatic', 'تليف', 'cirrhosis'])) {
      if (_containsAny(drugNameLower, ['paracetamol', 'باراسيتامول', 'acetaminophen', 'tylenol'])) {
        return DrugWarning(
          level: WarningLevel.warning,
          titleAr: 'تحذير للكبد',
          titleEn: 'Liver Warning',
          messageAr: 'يجب تقليل جرعة الباراسيتامول في مرضى الكبد. الحد الأقصى 2 جرام يومياً.',
          messageEn: 'Reduce paracetamol dose in liver patients. Maximum 2g daily.',
          condition: disease,
        );
      }
      if (_containsAny(drugNameLower, ['statin', 'ستاتين', 'atorvastatin', 'أتورفاستاتين', 'simvastatin', 'سيمفاستاتين'])) {
        return DrugWarning(
          level: WarningLevel.warning,
          titleAr: 'مراقبة وظائف الكبد',
          titleEn: 'Monitor Liver Function',
          messageAr: 'الستاتينات قد تؤثر على الكبد. يجب مراقبة إنزيمات الكبد بانتظام.',
          messageEn: 'Statins may affect liver. Regular liver enzyme monitoring required.',
          condition: disease,
        );
      }
    }

    // Heart Disease / Hypertension Interactions
    if (_containsAny(diseaseLower, ['قلب', 'heart', 'cardiac', 'ضغط', 'hypertension', 'blood pressure'])) {
      if (_containsAny(drugNameLower, ['pseudoephedrine', 'سودوإيفيدرين', 'decongestant', 'مزيل احتقان'])) {
        return DrugWarning(
          level: WarningLevel.danger,
          titleAr: 'خطر على القلب والضغط',
          titleEn: 'Heart & BP Risk',
          messageAr: 'مزيلات الاحتقان ترفع ضغط الدم وتزيد معدل ضربات القلب. تجنب الاستخدام.',
          messageEn: 'Decongestants raise blood pressure and heart rate. Avoid use.',
          condition: disease,
        );
      }
      if (_containsAny(drugNameLower, ['ibuprofen', 'ايبوبروفين', 'nsaid', 'diclofenac', 'ديكلوفيناك'])) {
        return DrugWarning(
          level: WarningLevel.warning,
          titleAr: 'قد يرفع الضغط',
          titleEn: 'May Raise BP',
          messageAr: 'مضادات الالتهاب غير الستيرويدية قد ترفع ضغط الدم وتقلل فعالية أدوية الضغط.',
          messageEn: 'NSAIDs may raise blood pressure and reduce effectiveness of BP medications.',
          condition: disease,
        );
      }
    }

    // Diabetes Interactions
    if (_containsAny(diseaseLower, ['سكر', 'diabetes', 'سكري', 'diabetic'])) {
      if (_containsAny(drugNameLower, ['steroid', 'ستيرويد', 'prednisone', 'بريدنيزون', 'dexamethasone', 'ديكساميثازون', 'cortisone', 'كورتيزون'])) {
        return DrugWarning(
          level: WarningLevel.warning,
          titleAr: 'يرفع السكر',
          titleEn: 'Raises Blood Sugar',
          messageAr: 'الكورتيزون يرفع مستوى السكر في الدم. يجب مراقبة السكر بشكل متكرر.',
          messageEn: 'Corticosteroids raise blood sugar levels. Monitor glucose frequently.',
          condition: disease,
        );
      }
    }

    // Asthma Interactions
    if (_containsAny(diseaseLower, ['ربو', 'asthma', 'تنفس', 'respiratory'])) {
      if (_containsAny(drugNameLower, ['beta blocker', 'بيتا بلوكر', 'propranolol', 'بروبرانولول', 'atenolol', 'أتينولول', 'metoprolol', 'ميتوبرولول'])) {
        return DrugWarning(
          level: WarningLevel.danger,
          titleAr: 'خطر تضيق الشعب الهوائية',
          titleEn: 'Bronchospasm Risk',
          messageAr: 'حاصرات بيتا قد تسبب تضيق الشعب الهوائية في مرضى الربو. تجنب الاستخدام.',
          messageEn: 'Beta blockers may cause bronchospasm in asthma patients. Avoid use.',
          condition: disease,
        );
      }
      if (_containsAny(drugNameLower, ['aspirin', 'أسبرين'])) {
        return DrugWarning(
          level: WarningLevel.caution,
          titleAr: 'احتمال تفاقم الربو',
          titleEn: 'May Worsen Asthma',
          messageAr: 'الأسبرين قد يسبب تفاقم الربو لدى بعض المرضى (حساسية الأسبرين).',
          messageEn: 'Aspirin may worsen asthma in some patients (aspirin-sensitive asthma).',
          condition: disease,
        );
      }
    }

    // Stomach Ulcer Interactions
    if (_containsAny(diseaseLower, ['قرحة', 'ulcer', 'معدة', 'stomach', 'gastric'])) {
      if (_containsAny(drugNameLower, ['ibuprofen', 'ايبوبروفين', 'nsaid', 'aspirin', 'أسبرين', 'diclofenac', 'ديكلوفيناك', 'naproxen', 'نابروكسين'])) {
        return DrugWarning(
          level: WarningLevel.danger,
          titleAr: 'خطر نزيف المعدة',
          titleEn: 'GI Bleeding Risk',
          messageAr: 'مضادات الالتهاب غير الستيرويدية تزيد خطر نزيف المعدة. تجنب الاستخدام أو استخدم مع حماية للمعدة.',
          messageEn: 'NSAIDs increase risk of GI bleeding. Avoid or use with gastric protection.',
          condition: disease,
        );
      }
    }

    // Glaucoma Interactions
    if (_containsAny(diseaseLower, ['جلوكوما', 'glaucoma', 'ضغط العين', 'eye pressure'])) {
      if (_containsAny(drugNameLower, ['antihistamine', 'مضاد هيستامين', 'diphenhydramine', 'ديفينهيدرامين', 'chlorpheniramine', 'كلورفينيرامين'])) {
        return DrugWarning(
          level: WarningLevel.warning,
          titleAr: 'قد يزيد ضغط العين',
          titleEn: 'May Increase Eye Pressure',
          messageAr: 'مضادات الهيستامين قد تزيد ضغط العين في مرضى الجلوكوما.',
          messageEn: 'Antihistamines may increase eye pressure in glaucoma patients.',
          condition: disease,
        );
      }
    }

    // Thyroid Interactions
    if (_containsAny(diseaseLower, ['غدة درقية', 'thyroid', 'درقية'])) {
      if (_containsAny(drugNameLower, ['calcium', 'كالسيوم', 'iron', 'حديد', 'antacid', 'مضاد حموضة'])) {
        return DrugWarning(
          level: WarningLevel.caution,
          titleAr: 'تداخل مع أدوية الغدة',
          titleEn: 'Thyroid Med Interaction',
          messageAr: 'يجب الفصل بين هذا الدواء وأدوية الغدة الدرقية بـ 4 ساعات على الأقل.',
          messageEn: 'Separate this medication from thyroid medications by at least 4 hours.',
          condition: disease,
        );
      }
    }

    // Epilepsy Interactions
    if (_containsAny(diseaseLower, ['صرع', 'epilepsy', 'تشنج', 'seizure'])) {
      if (_containsAny(drugNameLower, ['tramadol', 'ترامادول', 'meperidine', 'ميبيريدين'])) {
        return DrugWarning(
          level: WarningLevel.danger,
          titleAr: 'خطر التشنجات',
          titleEn: 'Seizure Risk',
          messageAr: 'هذا الدواء يخفض عتبة التشنجات وقد يسبب نوبات صرع.',
          messageEn: 'This medication lowers seizure threshold and may cause seizures.',
          condition: disease,
        );
      }
    }

    return null;
  }

  DrugWarning? _checkAllergyInteraction(Drug drug, String allergy) {
    final allergyLower = allergy.toLowerCase();
    final drugNameLower = drug.name.toLowerCase();
    final drugCategoryLower = drug.category.toLowerCase();

    // Penicillin Allergy
    if (_containsAny(allergyLower, ['بنسلين', 'penicillin', 'amoxicillin', 'أموكسيسيلين'])) {
      if (_containsAny(drugNameLower, ['penicillin', 'بنسلين', 'amoxicillin', 'أموكسيسيلين', 'ampicillin', 'أمبيسيلين', 'augmentin', 'أوجمنتين', 'amoxil', 'أموكسيل'])) {
        return DrugWarning(
          level: WarningLevel.danger,
          titleAr: 'حساسية البنسلين',
          titleEn: 'Penicillin Allergy',
          messageAr: 'هذا الدواء من عائلة البنسلين وقد يسبب رد فعل تحسسي خطير. ممنوع الاستخدام!',
          messageEn: 'This medication is a penicillin and may cause severe allergic reaction. DO NOT USE!',
          condition: allergy,
        );
      }
      // Cross-reactivity with cephalosporins
      if (_containsAny(drugNameLower, ['cephalosporin', 'سيفالوسبورين', 'cefuroxime', 'سيفوروكسيم', 'ceftriaxone', 'سيفترياكسون', 'cephalexin', 'سيفالكسين'])) {
        return DrugWarning(
          level: WarningLevel.warning,
          titleAr: 'احتمال تفاعل متصالب',
          titleEn: 'Cross-Reactivity Risk',
          messageAr: 'السيفالوسبورينات قد تسبب تفاعل تحسسي متصالب مع البنسلين (1-10% احتمال).',
          messageEn: 'Cephalosporins may cause cross-reactivity with penicillin allergy (1-10% risk).',
          condition: allergy,
        );
      }
    }

    // Sulfa Allergy
    if (_containsAny(allergyLower, ['سلفا', 'sulfa', 'sulfon', 'سلفون'])) {
      if (_containsAny(drugNameLower, ['sulfamethoxazole', 'سلفاميثوكسازول', 'bactrim', 'باكتريم', 'septrin', 'سبترين', 'sulfa', 'سلفا'])) {
        return DrugWarning(
          level: WarningLevel.danger,
          titleAr: 'حساسية السلفا',
          titleEn: 'Sulfa Allergy',
          messageAr: 'هذا الدواء يحتوي على السلفا وقد يسبب رد فعل تحسسي خطير. ممنوع الاستخدام!',
          messageEn: 'This medication contains sulfa and may cause severe allergic reaction. DO NOT USE!',
          condition: allergy,
        );
      }
    }

    // Aspirin/NSAID Allergy
    if (_containsAny(allergyLower, ['أسبرين', 'aspirin', 'nsaid', 'مسكن'])) {
      if (_containsAny(drugNameLower, ['aspirin', 'أسبرين', 'ibuprofen', 'ايبوبروفين', 'diclofenac', 'ديكلوفيناك', 'naproxen', 'نابروكسين', 'ketoprofen', 'كيتوبروفين'])) {
        return DrugWarning(
          level: WarningLevel.danger,
          titleAr: 'حساسية المسكنات',
          titleEn: 'NSAID Allergy',
          messageAr: 'هذا الدواء من عائلة مضادات الالتهاب غير الستيرويدية وقد يسبب رد فعل تحسسي.',
          messageEn: 'This is an NSAID and may cause allergic reaction in NSAID-sensitive patients.',
          condition: allergy,
        );
      }
    }

    // Codeine/Opioid Allergy
    if (_containsAny(allergyLower, ['كودين', 'codeine', 'opioid', 'أفيون', 'مورفين', 'morphine'])) {
      if (_containsAny(drugNameLower, ['codeine', 'كودين', 'tramadol', 'ترامادول', 'morphine', 'مورفين', 'oxycodone', 'أوكسيكودون'])) {
        return DrugWarning(
          level: WarningLevel.danger,
          titleAr: 'حساسية الأفيونات',
          titleEn: 'Opioid Allergy',
          messageAr: 'هذا الدواء من عائلة الأفيونات وقد يسبب رد فعل تحسسي خطير.',
          messageEn: 'This medication is an opioid and may cause severe allergic reaction.',
          condition: allergy,
        );
      }
    }

    // Iodine Allergy
    if (_containsAny(allergyLower, ['يود', 'iodine'])) {
      if (_containsAny(drugNameLower, ['iodine', 'يود', 'povidone', 'بوفيدون', 'betadine', 'بيتادين'])) {
        return DrugWarning(
          level: WarningLevel.danger,
          titleAr: 'حساسية اليود',
          titleEn: 'Iodine Allergy',
          messageAr: 'هذا المنتج يحتوي على اليود وقد يسبب رد فعل تحسسي.',
          messageEn: 'This product contains iodine and may cause allergic reaction.',
          condition: allergy,
        );
      }
    }

    // Latex Allergy (some medications)
    if (_containsAny(allergyLower, ['لاتكس', 'latex', 'مطاط'])) {
      // Some suppositories and injectable vials have latex
      return DrugWarning(
        level: WarningLevel.caution,
        titleAr: 'تحقق من العبوة',
        titleEn: 'Check Packaging',
        messageAr: 'بعض العبوات الدوائية تحتوي على اللاتكس. تحقق من العبوة قبل الاستخدام.',
        messageEn: 'Some medication packaging contains latex. Check packaging before use.',
        condition: allergy,
      );
    }

    // Egg Allergy (some vaccines)
    if (_containsAny(allergyLower, ['بيض', 'egg'])) {
      if (_containsAny(drugNameLower, ['vaccine', 'لقاح', 'flu', 'انفلونزا'])) {
        return DrugWarning(
          level: WarningLevel.warning,
          titleAr: 'قد يحتوي على بروتين البيض',
          titleEn: 'May Contain Egg Protein',
          messageAr: 'بعض اللقاحات تحتوي على بروتين البيض. استشر الطبيب.',
          messageEn: 'Some vaccines contain egg protein. Consult your doctor.',
          condition: allergy,
        );
      }
    }

    return null;
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}

// Result classes
class DrugInteractionResult {
  final Drug drug;
  final List<DrugWarning> warnings;
  final WarningLevel overallLevel;

  DrugInteractionResult({
    required this.drug,
    required this.warnings,
    required this.overallLevel,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get isDangerous => overallLevel == WarningLevel.danger;
}

class DrugWarning {
  final WarningLevel level;
  final String titleAr;
  final String titleEn;
  final String messageAr;
  final String messageEn;
  final String condition;

  DrugWarning({
    required this.level,
    required this.titleAr,
    required this.titleEn,
    required this.messageAr,
    required this.messageEn,
    required this.condition,
  });

  String getTitle(bool isEnglish) => isEnglish ? titleEn : titleAr;
  String getMessage(bool isEnglish) => isEnglish ? messageEn : messageAr;
}

enum WarningLevel {
  safe,      // Green - No issues
  caution,   // Yellow - Minor concern
  warning,   // Orange - Moderate concern
  danger,    // Red - Severe/Contraindicated
}
