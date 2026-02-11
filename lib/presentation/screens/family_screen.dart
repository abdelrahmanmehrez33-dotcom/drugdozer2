import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/family_provider.dart';
import '../../services/pdf_export_service.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import 'family_member_details_screen.dart';

class FamilyScreen extends StatefulWidget {
  final FamilyProvider familyProvider;
  
  const FamilyScreen({super.key, required this.familyProvider});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isEnglish = languageProvider.isEnglish;
    final members = widget.familyProvider.familyMembers;

    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(context, isEnglish, members.length),
          
          // Content
          Expanded(
            child: members.isEmpty
                ? _buildEmptyState(context, isEnglish)
                : _buildMembersList(context, isEnglish, members),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isEnglish, int memberCount) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnglish ? 'Family Profiles' : 'ملفات العائلة',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '$memberCount ${isEnglish ? 'members' : 'أفراد'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Export PDF Button
          PremiumIconButton(
            icon: Icons.picture_as_pdf_rounded,
            onPressed: () {
              PdfExportService.exportFamilyToPdf(
                widget.familyProvider.familyMembers, 
                'family_file.pdf',
              );
            },
            tooltip: isEnglish ? 'Export to PDF' : 'تصدير PDF',
            hasShadow: true,
          ),
          const SizedBox(width: AppTheme.spaceS),
          // Add Member Button
          ElevatedButton.icon(
            onPressed: () => _showAddMemberDialog(context, isEnglish),
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: Text(isEnglish ? 'Add' : 'إضافة'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceL,
                vertical: AppTheme.spaceM,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isEnglish) {
    return EmptyStateWidget(
      icon: Icons.family_restroom_rounded,
      title: isEnglish ? 'No family members yet' : 'لا يوجد أفراد عائلة بعد',
      subtitle: isEnglish 
          ? 'Add family members to track their medications and health profiles'
          : 'أضف أفراد العائلة لتتبع أدويتهم وملفاتهم الصحية',
      buttonText: isEnglish ? 'Add First Member' : 'إضافة أول فرد',
      onButtonPressed: () => _showAddMemberDialog(context, isEnglish),
    );
  }

  Widget _buildMembersList(BuildContext context, bool isEnglish, List<FamilyMember> members) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _FamilyMemberCard(
          member: member,
          isEnglish: isEnglish,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FamilyMemberDetailsScreen(member: member),
            ),
          ).then((_) => setState(() {})),
          onDelete: () => _showDeleteDialog(context, isEnglish, member),
        );
      },
    );
  }

  void _showAddMemberDialog(BuildContext context, bool isEnglish) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    String selectedRelation = isEnglish ? 'Self' : 'أنا';
    
    final relations = isEnglish 
        ? ['Self', 'Spouse', 'Child', 'Parent', 'Sibling', 'Other']
        : ['أنا', 'زوج/زوجة', 'طفل', 'والد/والدة', 'أخ/أخت', 'آخر'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXXL)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceXL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
                
                // Title
                Text(
                  isEnglish ? 'Add Family Member' : 'إضافة فرد جديد',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.spaceXXL),
                
                // Name Field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: isEnglish ? 'Full Name' : 'الاسم الكامل',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppTheme.spaceL),
                
                // Age Field
                TextField(
                  controller: ageController,
                  decoration: InputDecoration(
                    labelText: isEnglish ? 'Age' : 'العمر',
                    prefixIcon: const Icon(Icons.cake_outlined),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppTheme.spaceL),
                
                // Relation Dropdown
                DropdownButtonFormField<String>(
                  value: selectedRelation,
                  decoration: InputDecoration(
                    labelText: isEnglish ? 'Relationship' : 'صلة القرابة',
                    prefixIcon: const Icon(Icons.family_restroom_outlined),
                  ),
                  items: relations.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r),
                  )).toList(),
                  onChanged: (value) {
                    setSheetState(() => selectedRelation = value!);
                  },
                ),
                const SizedBox(height: AppTheme.spaceXXL),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(isEnglish ? 'Cancel' : 'إلغاء'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceM),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isNotEmpty) {
                            final newMember = FamilyMember(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              name: nameController.text.trim(),
                              age: int.tryParse(ageController.text) ?? 0,
                              relationship: selectedRelation,
                              lastUpdated: DateTime.now(),
                            );
                            widget.familyProvider.addMember(newMember);
                            Navigator.pop(context);
                            setState(() {});
                          }
                        },
                        child: Text(isEnglish ? 'Add Member' : 'إضافة الفرد'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + AppTheme.spaceL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, bool isEnglish, FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Delete Member' : 'حذف الفرد'),
        content: Text(
          isEnglish 
              ? 'Are you sure you want to delete ${member.name}? This will also delete all their reminders.'
              : 'هل أنت متأكد من حذف ${member.name}؟ سيتم حذف جميع تذكيراته أيضاً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isEnglish ? 'Cancel' : 'إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.familyProvider.removeMember(member.id);
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: Text(isEnglish ? 'Delete' : 'حذف'),
          ),
        ],
      ),
    );
  }
}

/// Family Member Card Widget
class _FamilyMemberCard extends StatelessWidget {
  final FamilyMember member;
  final bool isEnglish;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FamilyMemberCard({
    required this.member,
    required this.isEnglish,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: PremiumCard(
        margin: EdgeInsets.zero,
        onTap: onTap,
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                PremiumAvatar(
                  name: member.name,
                  size: 56,
                  backgroundColor: _getRelationColor(member.relationship),
                ),
                const SizedBox(width: AppTheme.spaceL),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          PremiumBadge(
                            text: member.relationship,
                            backgroundColor: _getRelationColor(member.relationship).withOpacity(0.1),
                            textColor: _getRelationColor(member.relationship),
                            isSmall: true,
                          ),
                          const SizedBox(width: AppTheme.spaceS),
                          Text(
                            '${member.age} ${isEnglish ? 'years' : 'سنة'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 20),
                          const SizedBox(width: AppTheme.spaceS),
                          Text(isEnglish ? 'Edit' : 'تعديل'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 20, color: AppTheme.errorColor),
                          const SizedBox(width: AppTheme.spaceS),
                          Text(
                            isEnglish ? 'Delete' : 'حذف',
                            style: const TextStyle(color: AppTheme.errorColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spaceL),
            
            // Health Info Summary
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                children: [
                  _InfoChip(
                    icon: Icons.medical_services_outlined,
                    label: isEnglish ? 'Conditions' : 'أمراض',
                    value: '${member.chronicDiseases.length}',
                    color: AppTheme.chronicColor,
                  ),
                  const SizedBox(width: AppTheme.spaceM),
                  _InfoChip(
                    icon: Icons.warning_amber_rounded,
                    label: isEnglish ? 'Allergies' : 'حساسية',
                    value: '${member.allergies.length}',
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: AppTheme.spaceM),
                  _InfoChip(
                    icon: Icons.medication_rounded,
                    label: isEnglish ? 'Medications' : 'أدوية',
                    value: '${member.currentMedications.length}',
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRelationColor(String relation) {
    switch (relation.toLowerCase()) {
      case 'self':
      case 'أنا':
        return AppTheme.primaryColor;
      case 'spouse':
      case 'زوج/زوجة':
        return AppTheme.secondaryColor;
      case 'child':
      case 'طفل':
        return AppTheme.successColor;
      case 'parent':
      case 'والد/والدة':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondary;
    }
  }
}

/// Info Chip Widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
