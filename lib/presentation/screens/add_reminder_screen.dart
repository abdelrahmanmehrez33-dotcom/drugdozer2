import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../di/service_locator.dart';
import '../../domain/entities/drug_type.dart';
import '../../domain/entities/smart_reminder.dart';
import '../../domain/entities/drug.dart';
import '../../data/datasources/local_reminders.dart';
import '../../services/notification_service.dart';
import '../../services/drug_interaction_service.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/family_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/repositories/drug_repository.dart';

class AddReminderScreen extends StatefulWidget {
  final String? initialDrugName;
  final String? initialDrugType;
  
  const AddReminderScreen({
    super.key,
    this.initialDrugName,
    this.initialDrugType,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _stockController;
  late TextEditingController _thresholdController;
  late TextEditingController _doseAmountController;
  late TextEditingController _weightController;
  
  late DrugType _selectedType;
  int _durationDays = 7;
  bool _isChronic = false;
  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
  
  FamilyMember? _selectedMember;
  Drug? _selectedDrug;
  DrugInteractionResult? _interactionResult;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialDrugName);
    _dosageController = TextEditingController();
    _stockController = TextEditingController(text: '0');
    _thresholdController = TextEditingController(text: '5');
    _doseAmountController = TextEditingController(text: '1');
    _weightController = TextEditingController();
    
    _selectedType = widget.initialDrugType != null 
        ? DrugType.values.firstWhere((e) => e.name == widget.initialDrugType, orElse: () => DrugType.tablet)
        : DrugType.tablet;

    if (widget.initialDrugName != null) {
      _loadDrugInfo(widget.initialDrugName!);
    }
  }

  void _loadDrugInfo(String name) async {
    final repo = getIt<DrugRepository>();
    final drugs = await repo.searchDrugs(name);
    if (drugs.isNotEmpty) {
      setState(() {
        _selectedDrug = drugs.first;
        _checkInteractions();
      });
    }
  }

  void _checkInteractions() {
    if (_selectedDrug == null || _selectedMember == null) {
      setState(() => _interactionResult = null);
      return;
    }

    final result = DrugInteractionService().checkInteractions(
      drug: _selectedDrug!,
      chronicDiseases: _selectedMember!.chronicDiseases,
      allergies: _selectedMember!.allergies,
    );

    setState(() => _interactionResult = result);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final familyProvider = Provider.of<FamilyProvider>(context);
    final isEnglish = languageProvider.isEnglish;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          isEnglish ? 'Add Reminder' : 'إضافة تذكير',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Family Member Selection Card
            _buildPremiumCard(
              title: isEnglish ? 'Patient' : 'المريض',
              icon: Icons.person_rounded,
              child: DropdownButtonFormField<FamilyMember>(
                value: _selectedMember,
                decoration: InputDecoration(
                  hintText: isEnglish ? 'Select family member' : 'اختر فرد العائلة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: familyProvider.familyMembers.map((m) => DropdownMenuItem(
                  value: m, 
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(m.name[0], style: const TextStyle(color: AppTheme.primaryColor)),
                      ),
                      const SizedBox(width: 12),
                      Text(m.name),
                      if (m.age < 12) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.infoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isEnglish ? 'Child' : 'طفل',
                            style: const TextStyle(fontSize: 10, color: AppTheme.infoColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                )).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedMember = v;
                    _checkInteractions();
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Medicine Name Card
            _buildPremiumCard(
              title: isEnglish ? 'Medicine' : 'الدواء',
              icon: Icons.medication_rounded,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: isEnglish ? 'Enter medicine name' : 'أدخل اسم الدواء',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (v) => _loadDrugInfo(v),
                    validator: (v) => v!.isEmpty ? (isEnglish ? 'Required' : 'مطلوب') : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<DrugType>(
                    value: _selectedType,
                    items: DrugType.values.map((t) => DropdownMenuItem(
                      value: t, 
                      child: Row(
                        children: [
                          Icon(_getDrugTypeIcon(t), size: 20, color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Text(isEnglish ? t.name : t.arabicName),
                        ],
                      ),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedType = v!),
                    decoration: InputDecoration(
                      labelText: isEnglish ? 'Type' : 'النوع',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
            ),
            
            // Interaction Warnings
            if (_interactionResult != null && _interactionResult!.hasWarnings) ...[
              const SizedBox(height: 16),
              _buildInteractionWarningsCard(isEnglish),
            ],

            const SizedBox(height: 16),

            // Pediatric Dose Calculator
            if (_selectedMember != null && _selectedMember!.age < 12) ...[
              _buildPediatricCalculatorCard(isEnglish),
              const SizedBox(height: 16),
            ],

            // Dosage Card
            _buildPremiumCard(
              title: isEnglish ? 'Dosage' : 'الجرعة',
              icon: Icons.local_pharmacy_rounded,
              child: Column(
                children: [
                  TextFormField(
                    controller: _dosageController,
                    decoration: InputDecoration(
                      hintText: isEnglish ? 'e.g., 1 tablet, 5ml' : 'مثال: قرص واحد، 5 مل',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (v) => v!.isEmpty ? (isEnglish ? 'Required' : 'مطلوب') : null,
                  ),
                  const SizedBox(height: 16),
                  // Safe dose limit warning
                  if (_selectedDrug != null && _selectedDrug!.maxDailyDose > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.infoColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEnglish 
                                  ? 'Max daily dose: ${_selectedDrug!.maxDailyDose}mg'
                                  : 'الحد الأقصى اليومي: ${_selectedDrug!.maxDailyDose} ملجم',
                              style: const TextStyle(color: AppTheme.infoColor, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Chronic Disease Toggle
            _buildPremiumCard(
              title: isEnglish ? 'Duration' : 'المدة',
              icon: Icons.calendar_month_rounded,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _isChronic ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isChronic ? AppTheme.primaryColor : Colors.grey[300]!,
                      ),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        isEnglish ? 'Chronic Disease (Continuous)' : 'مرض مزمن (مستمر دائماً)',
                        style: TextStyle(
                          fontWeight: _isChronic ? FontWeight.bold : FontWeight.normal,
                          color: _isChronic ? AppTheme.primaryColor : AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        isEnglish ? 'Reminder will never expire' : 'التذكير لن ينتهي أبداً',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      value: _isChronic,
                      onChanged: (v) => setState(() => _isChronic = v),
                      activeColor: AppTheme.primaryColor,
                    ),
                  ),
                  if (!_isChronic) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _durationDays.toString(),
                      decoration: InputDecoration(
                        labelText: isEnglish ? 'Duration (Days)' : 'المدة (بالأيام)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                        suffixText: isEnglish ? 'days' : 'يوم',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _durationDays = int.tryParse(v) ?? 7,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stock Management Card
            _buildPremiumCard(
              title: isEnglish ? 'Stock Management' : 'إدارة المخزون',
              icon: Icons.inventory_2_rounded,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          decoration: InputDecoration(
                            labelText: isEnglish ? 'Current Stock' : 'المخزون الحالي',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _thresholdController,
                          decoration: InputDecoration(
                            labelText: isEnglish ? 'Alert at' : 'تنبيه عند',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _doseAmountController,
                    decoration: InputDecoration(
                      labelText: isEnglish ? 'Amount per dose' : 'الكمية المستهلكة في كل جرعة',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Times Card
            _buildPremiumCard(
              title: isEnglish ? 'Reminder Times' : 'أوقات التذكير',
              icon: Icons.access_time_rounded,
              child: Column(
                children: [
                  ..._selectedTimes.asMap().entries.map((entry) {
                    int idx = entry.key;
                    TimeOfDay time = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.alarm, color: AppTheme.primaryColor),
                        ),
                        title: Text(
                          time.format(context),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                          onPressed: _selectedTimes.length > 1 
                              ? () => setState(() => _selectedTimes.removeAt(idx))
                              : null,
                        ),
                        onTap: () async {
                          TimeOfDay? picked = await showTimePicker(context: context, initialTime: time);
                          if (picked != null) setState(() => _selectedTimes[idx] = picked);
                        },
                      ),
                    );
                  }),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _selectedTimes.add(const TimeOfDay(hour: 12, minute: 0))),
                    icon: const Icon(Icons.add),
                    label: Text(isEnglish ? 'Add Time' : 'إضافة وقت'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: ElevatedButton(
                onPressed: () => _saveReminder(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded),
                    const SizedBox(width: 12),
                    Text(
                      isEnglish ? 'Save Reminder' : 'حفظ التذكير',
                      style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInteractionWarningsCard(bool isEnglish) {
    final result = _interactionResult!;
    Color bgColor;
    Color borderColor;
    IconData icon;

    switch (result.overallLevel) {
      case WarningLevel.danger:
        bgColor = AppTheme.errorColor.withOpacity(0.1);
        borderColor = AppTheme.errorColor;
        icon = Icons.dangerous_rounded;
        break;
      case WarningLevel.warning:
        bgColor = AppTheme.warningColor.withOpacity(0.1);
        borderColor = AppTheme.warningColor;
        icon = Icons.warning_rounded;
        break;
      case WarningLevel.caution:
        bgColor = Colors.yellow.withOpacity(0.1);
        borderColor = Colors.orange;
        icon = Icons.info_rounded;
        break;
      default:
        bgColor = Colors.grey[100]!;
        borderColor = Colors.grey;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEnglish ? 'Medical Warnings' : 'تحذيرات طبية',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...result.warnings.map((warning) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getWarningColor(warning.level).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        warning.getTitle(isEnglish),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getWarningColor(warning.level),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '(${warning.condition})',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  warning.getMessage(isEnglish),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          )),
          if (result.isDangerous)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEnglish 
                          ? 'CAUTION: Consult a doctor before using this medication!'
                          : 'تنبيه: استشر الطبيب قبل استخدام هذا الدواء!',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPediatricCalculatorCard(bool isEnglish) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.infoColor.withOpacity(0.1), AppTheme.infoColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.child_care_rounded, color: AppTheme.infoColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                isEnglish ? 'Pediatric Dose Calculator' : 'حاسبة جرعة الأطفال',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    labelText: isEnglish ? 'Weight (kg)' : 'الوزن (كجم)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_selectedDrug != null && _weightController.text.isNotEmpty) {
                    double weight = double.tryParse(_weightController.text) ?? 0;
                    double dose = weight * _selectedDrug!.minDosePerKg;
                    _dosageController.text = '${dose.toStringAsFixed(1)} mg';
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.infoColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEnglish ? 'Calculate' : 'احسب'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEnglish 
                        ? 'For educational purposes only. The doctor is responsible for calculating doses.'
                        : 'لأغراض تعليمية فقط. الطبيب هو المختص بحساب الجرعات.',
                    style: const TextStyle(fontSize: 11, color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getWarningColor(WarningLevel level) {
    switch (level) {
      case WarningLevel.danger:
        return AppTheme.errorColor;
      case WarningLevel.warning:
        return AppTheme.warningColor;
      case WarningLevel.caution:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getDrugTypeIcon(DrugType type) {
    switch (type) {
      case DrugType.tablet:
        return Icons.medication_rounded;
      case DrugType.syrup:
        return Icons.local_drink_rounded;
      case DrugType.injection:
        return Icons.vaccines_rounded;
      case DrugType.cream:
        return Icons.spa_rounded;
      case DrugType.drops:
        return Icons.water_drop_rounded;
      case DrugType.spray:
        return Icons.air_rounded;
      default:
        return Icons.medication_rounded;
    }
  }

  void _saveReminder(BuildContext context) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isEnglish = languageProvider.isEnglish;

    if (_formKey.currentState!.validate()) {
      // Show confirmation if there are dangerous interactions
      if (_interactionResult != null && _interactionResult!.isDangerous) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.warning_rounded, color: AppTheme.errorColor),
                const SizedBox(width: 12),
                Text(isEnglish ? 'Warning' : 'تحذير'),
              ],
            ),
            content: Text(
              isEnglish 
                  ? 'This medication has serious interactions with the patient\'s conditions. Are you sure you want to continue?'
                  : 'هذا الدواء له تعارضات خطيرة مع حالة المريض. هل أنت متأكد من المتابعة؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isEnglish ? 'Cancel' : 'إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                child: Text(isEnglish ? 'Continue Anyway' : 'متابعة على أي حال'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }

      final reminder = SmartReminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        drugName: _nameController.text,
        type: _selectedType,
        dosage: _dosageController.text,
        timesPerDay: _selectedTimes,
        durationDays: _isChronic ? null : _durationDays,
        startDate: DateTime.now(),
        isChronic: _isChronic,
        currentStock: int.tryParse(_stockController.text) ?? 0,
        lowStockThreshold: int.tryParse(_thresholdController.text) ?? 5,
        doseAmount: double.tryParse(_doseAmountController.text) ?? 1.0,
        familyMemberId: _selectedMember?.id,
        familyMemberName: _selectedMember?.name,
      );
      
      getIt<ReminderService>().addReminder(reminder);
      
      // Add to family member's medication list automatically
      if (_selectedMember != null) {
        Provider.of<FamilyProvider>(context, listen: false).addMedication(_selectedMember!.id, _nameController.text);
      }
      
      // Schedule notifications
      for (var time in _selectedTimes) {
        final now = DateTime.now();
        var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));
        
        await getIt<NotificationService>().scheduleNotification(
          id: reminder.id.hashCode + _selectedTimes.indexOf(time),
          title: isEnglish ? 'Dose Reminder: ${_nameController.text}' : 'تذكير بجرعة: ${_nameController.text}',
          body: isEnglish 
              ? 'Time to take your ${_dosageController.text} (${_selectedMember?.name ?? ""})' 
              : 'حان وقت تناول ${_dosageController.text} (${_selectedMember?.name ?? ""})',
          scheduledDate: scheduledDate,
        );
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(isEnglish ? 'Reminder saved successfully!' : 'تم حفظ التذكير بنجاح!'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pop(context);
    }
  }
}
