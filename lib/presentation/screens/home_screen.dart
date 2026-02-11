import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../di/service_locator.dart';
import '../../domain/entities/drug.dart';
import '../../domain/entities/drug_type.dart';
import '../../domain/repositories/drug_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/family_provider.dart';
import '../../data/datasources/local_reminders.dart';
import '../widgets/premium_widgets.dart';
import 'details_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';
import 'family_screen.dart';
import 'search_screen.dart';
import 'nearby_pharmacies_screen.dart';
import 'family_member_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: AppTheme.animNormal,
      vsync: this,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: AppTheme.animNormal,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final familyProvider = Provider.of<FamilyProvider>(context);
    final isEnglish = languageProvider.isEnglish;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? AppTheme.darkSurface : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _HomePage(isEnglish: isEnglish, familyProvider: familyProvider),
            _MedicationsPage(isEnglish: isEnglish),
            const RemindersScreen(),
            FamilyScreen(familyProvider: familyProvider),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(isEnglish, isDark),
      ),
    );
  }

  Widget _buildBottomNav(bool isEnglish, bool isDark) {
    final items = [
      _NavItem(Icons.home_rounded, isEnglish ? 'Home' : 'الرئيسية'),
      _NavItem(Icons.medication_rounded, isEnglish ? 'Medicines' : 'الأدوية'),
      _NavItem(Icons.alarm_rounded, isEnglish ? 'Reminders' : 'التذكيرات'),
      _NavItem(Icons.family_restroom_rounded, isEnglish ? 'Family' : 'العائلة'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        boxShadow: AppTheme.bottomNavShadow,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceS, vertical: AppTheme.spaceS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = _selectedIndex == index;
              return _buildNavItem(index, items[index], isSelected);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item, bool isSelected) {
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? AppTheme.spaceL : AppTheme.spaceM,
          vertical: AppTheme.spaceS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppTheme.animFast,
              child: Icon(
                item.icon,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textHint,
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: AppTheme.animFast,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textHint,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}

/// Home Page Content
class _HomePage extends StatelessWidget {
  final bool isEnglish;
  final FamilyProvider familyProvider;

  const _HomePage({required this.isEnglish, required this.familyProvider});

  @override
  Widget build(BuildContext context) {
    final stats = getIt<ReminderService>().getStatistics();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withOpacity(0.08),
            Theme.of(context).scaffoldBackgroundColor,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(context)),
            
            // Quick Actions Card
            SliverToBoxAdapter(child: _buildQuickActionsCard(context)),
            
            // Statistics Section
            SliverToBoxAdapter(child: _buildStatisticsSection(context, stats)),
            
            // Family Members Section
            if (familyProvider.members.isNotEmpty)
              SliverToBoxAdapter(child: _buildFamilySection(context)),
            
            // Features Grid
            SliverToBoxAdapter(child: _buildFeaturesGrid(context)),
            
            // Low Stock Alerts
            SliverToBoxAdapter(child: _buildLowStockAlerts(context)),
            
            // Bottom Spacing
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Row(
        children: [
          // Logo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DrugDoZer',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEnglish ? 'Your Health Companion' : 'رفيقك الصحي الذكي',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PremiumIconButton(
            icon: Icons.settings_outlined,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            hasShadow: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: AppTheme.spaceL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEnglish ? 'Find Nearby Pharmacies' : 'ابحث عن صيدليات قريبة',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEnglish 
                            ? 'Locate pharmacies and call them directly'
                            : 'حدد موقع الصيدليات واتصل بها مباشرة',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NearbyPharmaciesScreen()),
                ),
                icon: const Icon(Icons.location_on_rounded, size: 20),
                label: Text(isEnglish ? 'Find Pharmacies' : 'البحث عن صيدليات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isEnglish ? 'Overview' : 'نظرة عامة',
            icon: Icons.analytics_outlined,
          ),
          const SizedBox(height: AppTheme.spaceM),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: isEnglish ? 'Active' : 'نشط',
                  value: '${stats['activeReminders']}',
                  icon: Icons.alarm_on_rounded,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: _StatCard(
                  title: isEnglish ? 'Chronic' : 'مزمن',
                  value: '${stats['chronicReminders']}',
                  icon: Icons.repeat_rounded,
                  color: AppTheme.chronicColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: isEnglish ? 'Doses Taken' : 'جرعات',
                  value: '${stats['totalDosesTaken']}',
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.infoColor,
                ),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: _StatCard(
                  title: isEnglish ? 'Low Stock' : 'مخزون منخفض',
                  value: '${stats['lowStockCount']}',
                  icon: Icons.warning_rounded,
                  color: stats['lowStockCount'] > 0 ? AppTheme.warningColor : AppTheme.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFamilySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isEnglish ? 'Family Members' : 'أفراد العائلة',
            icon: Icons.family_restroom_rounded,
            trailingText: isEnglish ? 'View All' : 'عرض الكل',
            onTrailingTap: () {
              // Navigate to family tab
            },
          ),
          const SizedBox(height: AppTheme.spaceS),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceS),
              itemCount: familyProvider.members.length,
              itemBuilder: (context, index) {
                final member = familyProvider.members[index];
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spaceM),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FamilyMemberDetailsScreen(member: member),
                      ),
                    ),
                    child: Column(
                      children: [
                        PremiumAvatar(
                          name: member.name,
                          size: 56,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.8 - (index * 0.1)),
                        ),
                        const SizedBox(height: AppTheme.spaceS),
                        Text(
                          member.name.split(' ').first,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final features = [
      _FeatureItem(
        icon: Icons.search_rounded,
        title: isEnglish ? 'Search Medicines' : 'بحث الأدوية',
        color: AppTheme.infoColor,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
      ),
      _FeatureItem(
        icon: Icons.alarm_add_rounded,
        title: isEnglish ? 'Add Reminder' : 'إضافة تذكير',
        color: AppTheme.successColor,
        onTap: () {
          // Navigate to add reminder
        },
      ),
      _FeatureItem(
        icon: Icons.person_add_rounded,
        title: isEnglish ? 'Add Member' : 'إضافة فرد',
        color: AppTheme.secondaryColor,
        onTap: () {
          // Navigate to add family member
        },
      ),
      _FeatureItem(
        icon: Icons.picture_as_pdf_rounded,
        title: isEnglish ? 'Export Report' : 'تصدير تقرير',
        color: AppTheme.warningColor,
        onTap: () {
          // Export functionality
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isEnglish ? 'Quick Actions' : 'إجراءات سريعة',
            icon: Icons.flash_on_rounded,
          ),
          const SizedBox(height: AppTheme.spaceM),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.85,
              crossAxisSpacing: AppTheme.spaceM,
              mainAxisSpacing: AppTheme.spaceM,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return _FeatureCard(feature: feature);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlerts(BuildContext context) {
    final lowStockReminders = getIt<ReminderService>().lowStockReminders;
    if (lowStockReminders.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isEnglish ? 'Low Stock Alerts' : 'تنبيهات المخزون',
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: AppTheme.spaceM),
          ...lowStockReminders.take(3).map((reminder) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
            child: PremiumCard(
              margin: EdgeInsets.zero,
              border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceM),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: const Icon(Icons.medication_rounded, color: AppTheme.warningColor),
                  ),
                  const SizedBox(width: AppTheme.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.drugName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${isEnglish ? 'Remaining:' : 'المتبقي:'} ${reminder.currentStock}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Refill action
                    },
                    child: Text(isEnglish ? 'Refill' : 'إعادة تعبئة'),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

/// Statistics Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceS),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature Item Data
class _FeatureItem {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  _FeatureItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}

/// Feature Card Widget
class _FeatureCard extends StatelessWidget {
  final _FeatureItem feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: feature.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(feature.icon, color: feature.color, size: 24),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            feature.title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Medications Page Content
class _MedicationsPage extends StatefulWidget {
  final bool isEnglish;

  const _MedicationsPage({required this.isEnglish});

  @override
  State<_MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<_MedicationsPage> {
  final DrugRepository _drugRepository = getIt<DrugRepository>();
  List<Drug> _drugs = [];
  bool _isLoading = true;
  DrugType? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadDrugs();
  }

  Future<void> _loadDrugs() async {
    setState(() => _isLoading = true);
    try {
      _drugs = await _drugRepository.getAllDrugs();
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  List<Drug> get _filteredDrugs {
    if (_selectedType == null) return _drugs;
    return _drugs.where((d) => d.type == _selectedType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEnglish ? 'Medicine Index' : 'فهرس الأدوية',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        '${_drugs.length} ${widget.isEnglish ? 'medicines' : 'دواء'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PremiumIconButton(
                  icon: Icons.search_rounded,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                  hasShadow: true,
                ),
              ],
            ),
          ),
          
          // Type Filter
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
              children: [
                _FilterChip(
                  label: widget.isEnglish ? 'All' : 'الكل',
                  isSelected: _selectedType == null,
                  onTap: () => setState(() => _selectedType = null),
                ),
                ...DrugType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(left: AppTheme.spaceS),
                  child: _FilterChip(
                    label: widget.isEnglish ? type.name : type.arabicName,
                    isSelected: _selectedType == type,
                    onTap: () => setState(() => _selectedType = type),
                  ),
                )),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceM),
          
          // Drug List
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _filteredDrugs.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.medication_outlined,
                        title: widget.isEnglish ? 'No medicines found' : 'لا توجد أدوية',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
                        itemCount: _filteredDrugs.length,
                        itemBuilder: (context, index) {
                          final drug = _filteredDrugs[index];
                          return _DrugCard(
                            drug: drug,
                            isEnglish: widget.isEnglish,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailsScreen(drug: drug),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL, vertical: AppTheme.spaceS),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusRound),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Drug Card Widget
class _DrugCard extends StatelessWidget {
  final Drug drug;
  final bool isEnglish;
  final VoidCallback onTap;

  const _DrugCard({
    required this.drug,
    required this.isEnglish,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: PremiumCard(
        margin: EdgeInsets.zero,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                _getDrugIcon(drug.type),
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEnglish ? drug.englishName : drug.arabicName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEnglish ? drug.type.name : drug.type.arabicName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textHint,
            ),
          ],
        ),
      ),
    );
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
