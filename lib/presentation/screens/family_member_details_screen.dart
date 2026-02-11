import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/providers/family_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/constants/medical_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/pdf_export_service.dart';

class FamilyMemberDetailsScreen extends StatefulWidget {
  final FamilyMember member;
  
  const FamilyMemberDetailsScreen({super.key, required this.member});

  @override
  State<FamilyMemberDetailsScreen> createState() => _FamilyMemberDetailsScreenState();
}

class _FamilyMemberDetailsScreenState extends State<FamilyMemberDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final familyProvider = Provider.of<FamilyProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isEnglish = languageProvider.isEnglish;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.member.name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Share/Export Button for individual member
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: isEnglish ? 'Share Report' : 'مشاركة التقرير',
            onPressed: () => _showExportOptions(context, isEnglish),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              _showEditMemberDialog(context, widget.member, familyProvider, isEnglish);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Profile Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                    ),
                    child: Center(
                      child: Text(
                        widget.member.name.isNotEmpty ? widget.member.name.substring(0, 1).toUpperCase() : '?',
                        style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.member.name,
                          style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.member.relationship} • ${widget.member.age} ${isEnglish ? 'years' : 'سنة'}',
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            
            // Chronic Diseases Section
            _buildPremiumSection(
              title: isEnglish ? 'Chronic Diseases' : 'الأمراض المزمنة',
              icon: Icons.medical_services_rounded,
              color: AppTheme.errorColor,
              items: widget.member.chronicDiseases,
              onAdd: () => _showMedicalSelectionDialog(context, widget.member.id, familyProvider, 'disease', isEnglish),
              onDelete: (item) {
                familyProvider.removeChronicDisease(widget.member.id, item);
                setState(() {});
              },
              isEnglish: isEnglish,
            ),
            
            const SizedBox(height: 16),
            
            // Allergies Section
            _buildPremiumSection(
              title: isEnglish ? 'Allergies' : 'الحساسيات',
              icon: Icons.warning_rounded,
              color: AppTheme.warningColor,
              items: widget.member.allergies,
              onAdd: () => _showMedicalSelectionDialog(context, widget.member.id, familyProvider, 'allergy', isEnglish),
              onDelete: (item) {
                familyProvider.removeAllergy(widget.member.id, item);
                setState(() {});
              },
              isEnglish: isEnglish,
            ),
            
            const SizedBox(height: 16),
            
            // Current Medications Section
            _buildPremiumSection(
              title: isEnglish ? 'Current Medications' : 'الأدوية الحالية',
              icon: Icons.medication_rounded,
              color: AppTheme.infoColor,
              items: widget.member.medications,
              onAdd: () => _showAddItemDialog(context, widget.member.id, familyProvider, 'medication', isEnglish),
              onDelete: (item) {
                familyProvider.removeMedication(widget.member.id, item);
                setState(() {});
              },
              isEnglish: isEnglish,
            ),
            
            const SizedBox(height: 16),
            
            // Notes Section
            _buildNotesSection(familyProvider, isEnglish),
            
            const SizedBox(height: 24),
            
            // Export Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showExportOptions(context, isEnglish),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: Text(
                  isEnglish ? 'Export Medical Report (PDF)' : 'تصدير التقرير الطبي (PDF)',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
    required VoidCallback onAdd,
    required Function(String) onDelete,
    required bool isEnglish,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.add_rounded, color: color),
                  onPressed: onAdd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isEnglish ? 'None recorded' : 'لا يوجد سجلات',
                    style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => onDelete(item),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(FamilyProvider familyProvider, bool isEnglish) {
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
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.note_rounded, color: AppTheme.secondaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                isEnglish ? 'Notes' : 'ملاحظات إضافية',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showEditNotesDialog(context, widget.member, familyProvider, isEnglish),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.member.notes.isEmpty 
                        ? (isEnglish ? 'Tap to add notes...' : 'اضغط لإضافة ملاحظات...')
                        : widget.member.notes,
                      style: TextStyle(
                        color: widget.member.notes.isEmpty ? Colors.grey[400] : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.edit_rounded, color: Colors.grey[400], size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context, bool isEnglish) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isEnglish ? 'Export Options' : 'خيارات التصدير',
              style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isEnglish 
                  ? 'Export ${widget.member.name}\'s medical report'
                  : 'تصدير التقرير الطبي لـ ${widget.member.name}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildExportOption(
              icon: Icons.share_rounded,
              title: isEnglish ? 'Share PDF Report' : 'مشاركة تقرير PDF',
              subtitle: isEnglish ? 'Send via WhatsApp, Email, etc.' : 'إرسال عبر واتساب، البريد، إلخ',
              color: AppTheme.primaryColor,
              onTap: () async {
                Navigator.pop(context);
                _showLoadingDialog(context, isEnglish);
                try {
                  // Convert to FamilyMember entity
                  final memberEntity = _convertToFamilyMemberEntity();
                  await PdfExportService().shareMemberReport(
                    member: memberEntity,
                    isEnglish: isEnglish,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEnglish ? 'Error exporting report' : 'خطأ في تصدير التقرير')),
                  );
                }
                if (mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              icon: Icons.print_rounded,
              title: isEnglish ? 'Print Report' : 'طباعة التقرير',
              subtitle: isEnglish ? 'Print directly to printer' : 'طباعة مباشرة',
              color: AppTheme.secondaryColor,
              onTap: () async {
                Navigator.pop(context);
                _showLoadingDialog(context, isEnglish);
                try {
                  final memberEntity = _convertToFamilyMemberEntity();
                  await PdfExportService().printMemberReport(
                    member: memberEntity,
                    isEnglish: isEnglish,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEnglish ? 'Error printing report' : 'خطأ في طباعة التقرير')),
                  );
                }
                if (mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context, bool isEnglish) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(isEnglish ? 'Generating report...' : 'جاري إنشاء التقرير...'),
          ],
        ),
      ),
    );
  }

  // Convert provider FamilyMember to entity FamilyMember
  dynamic _convertToFamilyMemberEntity() {
    // Import the entity class and create instance
    return FamilyMemberEntity(
      id: widget.member.id,
      name: widget.member.name,
      relationship: widget.member.relationship,
      age: widget.member.age,
      weight: null,
      chronicDiseases: widget.member.chronicDiseases,
      allergies: widget.member.allergies,
      currentMedications: widget.member.medications,
      notes: widget.member.notes.isEmpty ? null : widget.member.notes,
    );
  }

  void _showMedicalSelectionDialog(BuildContext context, String memberId, FamilyProvider provider, String type, bool isEnglish) {
    final List<String> options = type == 'disease' ? MedicalConstants.chronicDiseases : MedicalConstants.commonAllergies;
    final String title = type == 'disease' 
        ? (isEnglish ? 'Select Chronic Disease' : 'اختر المرض المزمن')
        : (isEnglish ? 'Select Allergy' : 'اختر الحساسية');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length + 1,
            itemBuilder: (context, index) {
              if (index == options.length) {
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: AppTheme.primaryColor),
                  ),
                  title: Text(isEnglish ? 'Add Custom...' : 'إضافة مخصص...', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddItemDialog(context, memberId, provider, type, isEnglish);
                  },
                );
              }
              return ListTile(
                title: Text(options[index]),
                onTap: () {
                  if (type == 'disease') provider.addChronicDisease(memberId, options[index]);
                  if (type == 'allergy') provider.addAllergy(memberId, options[index]);
                  Navigator.pop(context);
                  setState(() {});
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEditMemberDialog(BuildContext context, FamilyMember member, FamilyProvider provider, bool isEnglish) {
    final nameController = TextEditingController(text: member.name);
    final ageController = TextEditingController(text: member.age.toString());
    final relController = TextEditingController(text: member.relationship);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEnglish ? 'Edit Member' : 'تعديل البيانات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: isEnglish ? 'Name' : 'الاسم', prefixIcon: const Icon(Icons.person_outline))),
            const SizedBox(height: 12),
            TextField(controller: ageController, decoration: InputDecoration(labelText: isEnglish ? 'Age' : 'العمر', prefixIcon: const Icon(Icons.cake_outlined)), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: relController, decoration: InputDecoration(labelText: isEnglish ? 'Relationship' : 'صلة القرابة', prefixIcon: const Icon(Icons.family_restroom))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isEnglish ? 'Cancel' : 'إلغاء')),
          ElevatedButton(
            onPressed: () {
              member.name = nameController.text;
              member.age = int.tryParse(ageController.text) ?? member.age;
              member.relationship = relController.text;
              provider.updateMember(member);
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: Text(isEnglish ? 'Save' : 'حفظ'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, String memberId, FamilyProvider provider, String type, bool isEnglish) {
    final controller = TextEditingController();
    String title = '';
    if (type == 'disease') title = isEnglish ? 'Add Chronic Disease' : 'إضافة مرض مزمن';
    if (type == 'allergy') title = isEnglish ? 'Add Allergy' : 'إضافة حساسية';
    if (type == 'medication') title = isEnglish ? 'Add Medication' : 'إضافة دواء';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller, 
          decoration: InputDecoration(
            hintText: isEnglish ? 'Enter name...' : 'أدخل الاسم...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isEnglish ? 'Cancel' : 'إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                if (type == 'disease') provider.addChronicDisease(memberId, controller.text);
                if (type == 'allergy') provider.addAllergy(memberId, controller.text);
                if (type == 'medication') provider.addMedication(memberId, controller.text);
                Navigator.pop(context);
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: Text(isEnglish ? 'Add' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditNotesDialog(BuildContext context, FamilyMember member, FamilyProvider provider, bool isEnglish) {
    final controller = TextEditingController(text: member.notes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEnglish ? 'Edit Notes' : 'تعديل الملاحظات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
            hintText: isEnglish ? 'Enter notes...' : 'أدخل الملاحظات...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isEnglish ? 'Cancel' : 'إلغاء')),
          ElevatedButton(
            onPressed: () {
              provider.updateNotes(member.id, controller.text);
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: Text(isEnglish ? 'Save' : 'حفظ'),
          ),
        ],
      ),
    );
  }
}

// Entity class for PDF export
class FamilyMemberEntity {
  final String id;
  final String name;
  final String relationship;
  final int? age;
  final double? weight;
  final List<String> chronicDiseases;
  final List<String> allergies;
  final List<String> currentMedications;
  final String? notes;

  FamilyMemberEntity({
    required this.id,
    required this.name,
    required this.relationship,
    this.age,
    this.weight,
    required this.chronicDiseases,
    required this.allergies,
    required this.currentMedications,
    this.notes,
  });
}
