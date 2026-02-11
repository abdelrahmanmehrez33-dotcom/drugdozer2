import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/drug_type.dart';
import '../../domain/entities/smart_reminder.dart';
import '../../data/datasources/local_reminders.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../di/service_locator.dart';
import '../widgets/premium_widgets.dart';
import 'add_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isEnglish = languageProvider.isEnglish;
    final reminders = smartReminders;
    
    final activeReminders = reminders.where((r) => r.isActive).toList();
    final chronicReminders = reminders.where((r) => r.isChronic).toList();
    final lowStockReminders = reminders.where((r) => r.isLowStock).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isEnglish, reminders.length),
            
            // Tab Bar
            _buildTabBar(context, isEnglish, activeReminders.length, chronicReminders.length, lowStockReminders.length),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRemindersList(context, isEnglish, activeReminders, 'active'),
                  _buildRemindersList(context, isEnglish, chronicReminders, 'chronic'),
                  _buildRemindersList(context, isEnglish, lowStockReminders, 'lowStock'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddReminder(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(isEnglish ? 'Add Reminder' : 'إضافة تذكير'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isEnglish, int totalCount) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnglish ? 'Dose Reminders' : 'تذكيرات الجرعات',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '$totalCount ${isEnglish ? 'reminders set' : 'تذكير مضاف'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PremiumIconButton(
            icon: Icons.notifications_active_rounded,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            iconColor: AppTheme.primaryColor,
            hasShadow: false,
            onPressed: () {
              // Show notification settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, bool isEnglish, int activeCount, int chronicCount, int lowStockCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: [
          Tab(text: '${isEnglish ? 'Active' : 'نشط'} ($activeCount)'),
          Tab(text: '${isEnglish ? 'Chronic' : 'مزمن'} ($chronicCount)'),
          Tab(text: '${isEnglish ? 'Low Stock' : 'منخفض'} ($lowStockCount)'),
        ],
      ),
    );
  }

  Widget _buildRemindersList(BuildContext context, bool isEnglish, List<SmartReminder> reminders, String type) {
    if (reminders.isEmpty) {
      return EmptyStateWidget(
        icon: _getEmptyIcon(type),
        title: _getEmptyTitle(isEnglish, type),
        subtitle: _getEmptySubtitle(isEnglish, type),
        buttonText: type == 'active' ? (isEnglish ? 'Add Reminder' : 'إضافة تذكير') : null,
        onButtonPressed: type == 'active' ? () => _navigateToAddReminder(context) : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return _ReminderCard(
          reminder: reminder,
          isEnglish: isEnglish,
          onTakeDose: () => _takeDose(reminder.id, isEnglish),
          onDelete: () => _deleteReminder(reminder.id),
          onToggle: () => _toggleReminder(reminder.id, isEnglish),
          onRefill: () => _showRefillDialog(context, reminder, isEnglish),
        );
      },
    );
  }

  IconData _getEmptyIcon(String type) {
    switch (type) {
      case 'active':
        return Icons.alarm_off_rounded;
      case 'chronic':
        return Icons.repeat_rounded;
      case 'lowStock':
        return Icons.inventory_2_outlined;
      default:
        return Icons.notifications_off_rounded;
    }
  }

  String _getEmptyTitle(bool isEnglish, String type) {
    switch (type) {
      case 'active':
        return isEnglish ? 'No active reminders' : 'لا توجد تذكيرات نشطة';
      case 'chronic':
        return isEnglish ? 'No chronic medications' : 'لا توجد أدوية مزمنة';
      case 'lowStock':
        return isEnglish ? 'All stocked up!' : 'المخزون كافٍ!';
      default:
        return '';
    }
  }

  String _getEmptySubtitle(bool isEnglish, String type) {
    switch (type) {
      case 'active':
        return isEnglish ? 'Add a reminder to get started' : 'أضف تذكيراً للبدء';
      case 'chronic':
        return isEnglish ? 'Chronic medications will appear here' : 'ستظهر الأدوية المزمنة هنا';
      case 'lowStock':
        return isEnglish ? 'No medications running low' : 'لا توجد أدوية منخفضة المخزون';
      default:
        return '';
    }
  }

  void _navigateToAddReminder(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddReminderScreen()),
    ).then((_) => setState(() {}));
  }

  Future<void> _takeDose(String id, bool isEnglish) async {
    await getIt<ReminderService>().takeDose(id, isEnglish: isEnglish);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEnglish ? 'Dose recorded!' : 'تم تسجيل الجرعة!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteReminder(String id) async {
    await getIt<ReminderService>().removeReminder(id);
    setState(() {});
  }

  Future<void> _toggleReminder(String id, bool isEnglish) async {
    await getIt<ReminderService>().toggleReminderActive(id, isEnglish: isEnglish);
    setState(() {});
  }

  void _showRefillDialog(BuildContext context, SmartReminder reminder, bool isEnglish) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Refill Stock' : 'إعادة تعبئة المخزون'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isEnglish ? 'Current stock:' : 'المخزون الحالي:'} ${reminder.currentStock}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spaceL),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isEnglish ? 'Amount to add' : 'الكمية المضافة',
                hintText: isEnglish ? 'e.g., 30' : 'مثال: 30',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isEnglish ? 'Cancel' : 'إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                await getIt<ReminderService>().refillStock(reminder.id, amount);
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: Text(isEnglish ? 'Refill' : 'تعبئة'),
          ),
        ],
      ),
    );
  }
}

/// Premium Reminder Card Widget
class _ReminderCard extends StatelessWidget {
  final SmartReminder reminder;
  final bool isEnglish;
  final VoidCallback onTakeDose;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback onRefill;

  const _ReminderCard({
    required this.reminder,
    required this.isEnglish,
    required this.onTakeDose,
    required this.onDelete,
    required this.onToggle,
    required this.onRefill,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: PremiumCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Drug Icon
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spaceM),
                        decoration: BoxDecoration(
                          color: _getTypeColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Icon(
                          _getDrugIcon(reminder.type),
                          color: _getTypeColor(),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                      
                      // Name and Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reminder.drugName,
                                    style: Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (reminder.isChronic)
                                  PremiumBadge(
                                    text: isEnglish ? 'Chronic' : 'مزمن',
                                    backgroundColor: AppTheme.chronicColor.withOpacity(0.1),
                                    textColor: AppTheme.chronicColor,
                                    isSmall: true,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${reminder.dosage} • ${reminder.timesPerDay.length} ${isEnglish ? 'times daily' : 'مرات يومياً'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (reminder.familyMemberName != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 14, color: AppTheme.textHint),
                                  const SizedBox(width: 4),
                                  Text(
                                    reminder.familyMemberName!,
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Active Toggle
                      Switch(
                        value: reminder.isActive,
                        onChanged: (_) => onToggle(),
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spaceM),
                  
                  // Times Row
                  Wrap(
                    spacing: AppTheme.spaceS,
                    runSpacing: AppTheme.spaceS,
                    children: reminder.timesPerDay.map((time) {
                      final hour = time.hour;
                      final minute = time.minute.toString().padLeft(2, '0');
                      final period = hour >= 12 ? (isEnglish ? 'PM' : 'م') : (isEnglish ? 'AM' : 'ص');
                      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceM,
                          vertical: AppTheme.spaceS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '$displayHour:$minute $period',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            // Stock and Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL, vertical: AppTheme.spaceM),
              decoration: BoxDecoration(
                color: reminder.isLowStock 
                    ? AppTheme.warningColor.withOpacity(0.05) 
                    : AppTheme.surfaceColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radiusLarge),
                ),
              ),
              child: Row(
                children: [
                  // Stock Info
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: reminder.isLowStock ? AppTheme.warningColor : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.spaceS),
                        Text(
                          '${isEnglish ? 'Stock:' : 'المخزون:'} ${reminder.currentStock}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: reminder.isLowStock ? AppTheme.warningColor : AppTheme.textSecondary,
                            fontWeight: reminder.isLowStock ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (reminder.isLowStock) ...[
                          const SizedBox(width: AppTheme.spaceS),
                          GestureDetector(
                            onTap: onRefill,
                            child: Text(
                              isEnglish ? 'Refill' : 'تعبئة',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Action Buttons
                  Row(
                    children: [
                      // Take Dose Button
                      SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: reminder.isActive ? onTakeDose : null,
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: Text(isEnglish ? 'Take' : 'أخذ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceS),
                      
                      // Delete Button
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: AppTheme.errorColor,
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor() {
    if (reminder.isLowStock) return AppTheme.warningColor;
    if (reminder.isChronic) return AppTheme.chronicColor;
    return AppTheme.primaryColor;
  }

  IconData _getDrugIcon(DrugType type) {
    switch (type) {
      case DrugType.tablet:
        return Icons.medication_rounded;
      case DrugType.syrup:
        return Icons.water_drop_rounded;
      case DrugType.cream:
        return Icons.spa_rounded;
      case DrugType.spray:
        return Icons.air_rounded;
      case DrugType.drops:
        return Icons.opacity_rounded;
      case DrugType.injection:
        return Icons.vaccines_rounded;
    }
  }
}
