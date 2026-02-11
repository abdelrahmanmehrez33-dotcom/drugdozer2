import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'di/service_locator.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/family_provider.dart';
import 'data/datasources/local_reminders.dart';
import 'presentation/screens/welcome_screen.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Initialize Service Locator
  await setupServiceLocator();
  
  // Initialize Notifications
  await getIt<NotificationService>().init();
  
  // Initialize Background Service (Android only)
  if (Platform.isAndroid) {
    await getIt<BackgroundService>().init();
  }
  
  // Load initial data
  await getIt<ReminderService>().loadReminders();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
      ],
      child: const DrugDoZerApp(),
    ),
  );
}

class DrugDoZerApp extends StatefulWidget {
  const DrugDoZerApp({super.key});

  @override
  State<DrugDoZerApp> createState() => _DrugDoZerAppState();
}

class _DrugDoZerAppState extends State<DrugDoZerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupNotificationListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes to foreground
      getIt<ReminderService>().loadReminders();
    }
  }

  void _setupNotificationListener() {
    getIt<NotificationService>().selectNotificationStream.listen((payload) {
      if (payload != null) {
        // Handle notification tap - navigate to reminders screen
        debugPrint('Notification payload received: $payload');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DrugDoZer',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      locale: languageProvider.isEnglish ? const Locale('en') : const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: languageProvider.isEnglish 
              ? TextDirection.ltr 
              : TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child!,
          ),
        );
      },
      home: const WelcomeScreen(),
    );
  }
}
