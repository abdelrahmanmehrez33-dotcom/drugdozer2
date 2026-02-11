import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/theme_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../di/service_locator.dart';
import '../widgets/premium_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load notification settings from shared preferences
    // For now, using default values
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final isEnglish = languageProvider.isEnglish;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        children: [
          // Header
          Text(
            isEnglish ? 'Settings' : 'الإعدادات',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spaceXXL),

          // Appearance Section
          _buildSectionHeader(
            context,
            icon: Icons.palette_outlined,
            title: isEnglish ? 'Appearance' : 'المظهر',
          ),
          const SizedBox(height: AppTheme.spaceM),
          PremiumCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                // Language
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: isEnglish ? 'Language' : 'اللغة',
                  subtitle: isEnglish ? 'English' : 'العربية',
                  trailing: DropdownButton<String>(
                    value: isEnglish ? 'English' : 'العربية',
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'العربية', child: Text('العربية')),
                      DropdownMenuItem(value: 'English', child: Text('English')),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue == 'English') {
                        languageProvider.switchToEnglish();
                      } else {
                        languageProvider.switchToArabic();
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                
                // Theme
                _SettingsTile(
                  icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  title: isEnglish ? 'Dark Mode' : 'الوضع الداكن',
                  subtitle: isDarkMode 
                      ? (isEnglish ? 'On' : 'مفعل')
                      : (isEnglish ? 'Off' : 'غير مفعل'),
                  trailing: Switch.adaptive(
                    value: isDarkMode,
                    onChanged: (value) => themeProvider.toggleTheme(value),
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceXXL),

          // Notifications Section
          _buildSectionHeader(
            context,
            icon: Icons.notifications_outlined,
            title: isEnglish ? 'Notifications' : 'الإشعارات',
          ),
          const SizedBox(height: AppTheme.spaceM),
          PremiumCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                // Enable Notifications
                _SettingsTile(
                  icon: Icons.notifications_active_rounded,
                  title: isEnglish ? 'Push Notifications' : 'الإشعارات',
                  subtitle: isEnglish 
                      ? 'Receive medication reminders'
                      : 'استلام تذكيرات الأدوية',
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      setState(() => _notificationsEnabled = value);
                      if (value) {
                        await getIt<NotificationService>().requestPermissions();
                      }
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
                const Divider(height: 1),
                
                // Sound
                _SettingsTile(
                  icon: Icons.volume_up_rounded,
                  title: isEnglish ? 'Sound' : 'الصوت',
                  subtitle: isEnglish 
                      ? 'Play sound with notifications'
                      : 'تشغيل صوت مع الإشعارات',
                  trailing: Switch.adaptive(
                    value: _soundEnabled,
                    onChanged: _notificationsEnabled 
                        ? (value) => setState(() => _soundEnabled = value)
                        : null,
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
                const Divider(height: 1),
                
                // Vibration
                _SettingsTile(
                  icon: Icons.vibration_rounded,
                  title: isEnglish ? 'Vibration' : 'الاهتزاز',
                  subtitle: isEnglish 
                      ? 'Vibrate with notifications'
                      : 'اهتزاز مع الإشعارات',
                  trailing: Switch.adaptive(
                    value: _vibrationEnabled,
                    onChanged: _notificationsEnabled 
                        ? (value) => setState(() => _vibrationEnabled = value)
                        : null,
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceXXL),

          // Data Section
          _buildSectionHeader(
            context,
            icon: Icons.storage_outlined,
            title: isEnglish ? 'Data & Storage' : 'البيانات والتخزين',
          ),
          const SizedBox(height: AppTheme.spaceM),
          PremiumCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                // Export Data
                _SettingsTile(
                  icon: Icons.upload_rounded,
                  title: isEnglish ? 'Export Data' : 'تصدير البيانات',
                  subtitle: isEnglish 
                      ? 'Export your data as PDF'
                      : 'تصدير بياناتك كملف PDF',
                  onTap: () => _showExportDialog(context, isEnglish),
                ),
                const Divider(height: 1),
                
                // Clear Cache
                _SettingsTile(
                  icon: Icons.cleaning_services_rounded,
                  title: isEnglish ? 'Clear Cache' : 'مسح الذاكرة المؤقتة',
                  subtitle: isEnglish 
                      ? 'Free up storage space'
                      : 'تحرير مساحة التخزين',
                  onTap: () => _showClearCacheDialog(context, isEnglish),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceXXL),

          // About Section
          _buildSectionHeader(
            context,
            icon: Icons.info_outline,
            title: isEnglish ? 'About' : 'حول التطبيق',
          ),
          const SizedBox(height: AppTheme.spaceM),
          PremiumCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                // Version
                _SettingsTile(
                  icon: Icons.verified_rounded,
                  title: isEnglish ? 'Version' : 'الإصدار',
                  subtitle: '2.0.0',
                ),
                const Divider(height: 1),
                
                // Rate App
                _SettingsTile(
                  icon: Icons.star_rounded,
                  title: isEnglish ? 'Rate App' : 'قيم التطبيق',
                  subtitle: isEnglish 
                      ? 'Share your feedback'
                      : 'شارك رأيك',
                  onTap: () => _launchUrl('https://play.google.com/store'),
                ),
                const Divider(height: 1),
                
                // Privacy Policy
                _SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  title: isEnglish ? 'Privacy Policy' : 'سياسة الخصوصية',
                  subtitle: isEnglish 
                      ? 'Read our privacy policy'
                      : 'اقرأ سياسة الخصوصية',
                  onTap: () => _launchUrl('https://example.com/privacy'),
                ),
                const Divider(height: 1),
                
                // About
                _SettingsTile(
                  icon: Icons.info_rounded,
                  title: isEnglish ? 'About DrugDoZer' : 'عن DrugDoZer',
                  subtitle: isEnglish 
                      ? 'Learn more about the app'
                      : 'اعرف المزيد عن التطبيق',
                  onTap: () => _showAboutDialog(context, isEnglish),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceXXL),

          // App Logo and Copyright
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceL),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
                Text(
                  'DrugDoZer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceS),
                Text(
                  '© 2024 DrugDoZer. All rights reserved.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceXXXL),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: AppTheme.spaceS),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showExportDialog(BuildContext context, bool isEnglish) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Export Data' : 'تصدير البيانات'),
        content: Text(
          isEnglish 
              ? 'Export your reminders and family profiles as a PDF file?'
              : 'تصدير التذكيرات وملفات العائلة كملف PDF؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isEnglish ? 'Cancel' : 'إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEnglish ? 'Data exported successfully!' : 'تم تصدير البيانات بنجاح!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text(isEnglish ? 'Export' : 'تصدير'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, bool isEnglish) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Clear Cache' : 'مسح الذاكرة المؤقتة'),
        content: Text(
          isEnglish 
              ? 'This will clear temporary files. Your data will not be affected.'
              : 'سيتم مسح الملفات المؤقتة. لن تتأثر بياناتك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isEnglish ? 'Cancel' : 'إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEnglish ? 'Cache cleared!' : 'تم مسح الذاكرة المؤقتة!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text(isEnglish ? 'Clear' : 'مسح'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, bool isEnglish) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: AppTheme.spaceL),
            Text(
              'DrugDoZer',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              isEnglish ? 'Version 2.0.0' : 'الإصدار 2.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppTheme.spaceL),
            Text(
              isEnglish 
                  ? 'DrugDoZer is your smart companion for managing medications and doses safely. Track your family\'s health, set reminders, and find nearby pharmacies.'
                  : 'DrugDoZer هو رفيقك الذكي لإدارة الأدوية والجرعات بأمان. تتبع صحة عائلتك، ضع تذكيرات، واعثر على الصيدليات القريبة.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isEnglish ? 'Close' : 'إغلاق'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Settings Tile Widget
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceL,
        vertical: AppTheme.spaceS,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.spaceS),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: trailing ?? (onTap != null 
          ? const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint)
          : null),
      onTap: onTap,
    );
  }
}
