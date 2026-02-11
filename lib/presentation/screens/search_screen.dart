import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../di/service_locator.dart';
import '../../domain/entities/drug.dart';
import '../../domain/entities/drug_type.dart';
import '../../domain/repositories/drug_repository.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import 'details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final DrugRepository _drugRepository = getIt<DrugRepository>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<Drug> _allDrugs = [];
  List<Drug> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.animNormal,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadAllDrugs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllDrugs() async {
    setState(() => _isLoading = true);
    try {
      _allDrugs = await _drugRepository.getAllDrugs();
      _searchResults = _allDrugs;
      _animationController.forward();
    } catch (e) {
      debugPrint('Error loading drugs: $e');
    }
    setState(() => _isLoading = false);
  }

  void _filterResults() {
    String query = _searchController.text.toLowerCase().trim();
    setState(() {
      _searchResults = _allDrugs.where((drug) {
        bool matchesQuery = query.isEmpty ||
            drug.englishName.toLowerCase().contains(query) || 
            drug.arabicName.contains(query);
        bool matchesCategory = _selectedCategory == 'All' || 
            _selectedCategory == 'الكل' || 
            drug.category == _selectedCategory;
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  void _addToRecentSearches(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 5) {
          _recentSearches = _recentSearches.sublist(0, 5);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isEnglish = languageProvider.isEnglish;

    // Get unique categories
    List<String> categories = [isEnglish ? 'All' : 'الكل'];
    categories.addAll(_allDrugs.map((d) => d.category).toSet().toList());

    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(context, isEnglish),
          
          // Search Bar
          _buildSearchBar(context, isEnglish),
          
          // Categories
          _buildCategories(categories),
          
          // Results Count
          if (!_isLoading && _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceL,
                vertical: AppTheme.spaceS,
              ),
              child: Row(
                children: [
                  Text(
                    '${_searchResults.length} ${isEnglish ? 'results' : 'نتيجة'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          
          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _searchResults.isEmpty
                    ? _buildEmptyState(isEnglish)
                    : _buildResultsList(isEnglish),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isEnglish) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnglish ? 'Medicine Library' : 'مكتبة الأدوية',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '${_allDrugs.length} ${isEnglish ? 'medicines available' : 'دواء متوفر'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Stats Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceM,
              vertical: AppTheme.spaceS,
            ),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.medication_rounded, color: Colors.white, size: 18),
                const SizedBox(width: AppTheme.spaceS),
                Text(
                  '${_allDrugs.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isEnglish) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardShadow,
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: isEnglish ? 'Search medicines...' : 'ابحث عن الأدوية...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppTheme.textHint),
                    onPressed: () {
                      _searchController.clear();
                      _filterResults();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceL,
              vertical: AppTheme.spaceL,
            ),
          ),
          onChanged: (_) => _filterResults(),
          onSubmitted: (query) => _addToRecentSearches(query),
          textInputAction: TextInputAction.search,
        ),
      ),
    );
  }

  Widget _buildCategories(List<String> categories) {
    return Container(
      height: 56,
      margin: const EdgeInsets.only(top: AppTheme.spaceM),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spaceS),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                  _filterResults();
                });
              },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primaryColor.withOpacity(0.15),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceM,
                vertical: AppTheme.spaceS,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceXL),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              boxShadow: AppTheme.cardShadow,
            ),
            child: const CircularProgressIndicator(),
          ),
          const SizedBox(height: AppTheme.spaceXL),
          Text(
            'Loading medicines...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isEnglish) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: isEnglish ? 'No results found' : 'لا توجد نتائج',
      subtitle: isEnglish 
          ? 'Try a different search term or category'
          : 'جرب مصطلح بحث أو فئة مختلفة',
    );
  }

  Widget _buildResultsList(bool isEnglish) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final drug = _searchResults[index];
          return _DrugCard(
            drug: drug,
            isEnglish: isEnglish,
            onTap: () {
              _addToRecentSearches(_searchController.text);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailsScreen(drug: drug),
                ),
              );
            },
          );
        },
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
            // Drug Icon
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient.scale(0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                _getDrugIcon(drug.type),
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spaceL),
            
            // Drug Info
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      PremiumBadge(
                        text: drug.category,
                        backgroundColor: AppTheme.surfaceColor,
                        textColor: AppTheme.textSecondary,
                        isSmall: true,
                      ),
                      const SizedBox(width: AppTheme.spaceS),
                      Text(
                        isEnglish ? drug.type.name : drug.type.arabicName,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Arrow
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
      case DrugType.syrup:
        return Icons.local_drink_rounded;
      case DrugType.tablet:
        return Icons.medication_rounded;
      case DrugType.cream:
        return Icons.spa_rounded;
      case DrugType.spray:
        return Icons.air_rounded;
      case DrugType.drops:
        return Icons.water_drop_rounded;
      case DrugType.injection:
        return Icons.vaccines_rounded;
    }
  }
}

/// Extension for gradient scaling
extension GradientExtension on LinearGradient {
  LinearGradient scale(double factor) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((c) => c.withOpacity(c.opacity * factor)).toList(),
      stops: stops,
    );
  }
}
