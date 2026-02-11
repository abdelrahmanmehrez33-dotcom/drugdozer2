import 'package:get_it/get_it.dart';
import '../domain/repositories/drug_repository.dart';
import '../data/repositories/drug_repository_impl.dart';
import '../services/notification_service.dart';
import '../services/shared_prefs_service.dart';
import '../services/pdf_export_service.dart';
import '../services/pharmacy_service.dart';
import '../services/drug_interaction_service.dart';
import '../services/background_service.dart';
import '../data/datasources/local_reminders.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Core Services
  getIt.registerLazySingleton<SharedPrefsService>(
    () => SharedPrefsService(),
  );
  
  // Notification Services
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );
  
  getIt.registerLazySingleton<BackgroundService>(
    () => BackgroundService(),
  );
  
  // Data Services
  getIt.registerLazySingleton<ReminderService>(
    () => ReminderService(),
  );
  
  // Repository
  getIt.registerLazySingleton<DrugRepository>(
    () => DrugRepositoryImpl(),
  );
  
  // Feature Services
  getIt.registerLazySingleton<PharmacyService>(
    () => PharmacyService(),
  );
  
  getIt.registerLazySingleton<DrugInteractionService>(
    () => DrugInteractionService(),
  );
  
  getIt.registerLazySingleton<PdfExportService>(
    () => PdfExportService(),
  );
}
