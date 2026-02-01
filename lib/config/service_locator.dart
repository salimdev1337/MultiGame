import 'package:get_it/get_it.dart';
import 'package:multigame/repositories/secure_storage_repository.dart';
import 'package:multigame/services/achievement_service.dart';
import 'package:multigame/services/auth_service.dart';
import 'package:multigame/services/firebase_stats_service.dart';
import 'package:multigame/services/nickname_service.dart';
import 'package:multigame/services/unsplash_service.dart';
import 'package:multigame/utils/storage_migrator.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Setup and register all services with the service locator
///
/// This should be called once at app startup before runApp()
/// Services are registered as lazy singletons - they are created only when first accessed
Future<void> setupServiceLocator() async {
  // Register repositories (bottom level - no dependencies)
  getIt.registerLazySingleton<SecureStorageRepository>(
    () => SecureStorageRepository(),
  );

  // Register storage utilities
  getIt.registerLazySingleton<StorageMigrator>(
    () => StorageMigrator(getIt<SecureStorageRepository>()),
  );

  // Register independent services (no dependencies on other services)
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(),
  );

  getIt.registerLazySingleton<FirebaseStatsService>(
    () => FirebaseStatsService(),
  );

  getIt.registerLazySingleton<AchievementService>(
    () => AchievementService(),
  );

  getIt.registerLazySingleton<UnsplashService>(
    () => UnsplashService(),
  );

  // Register services with dependencies
  getIt.registerLazySingleton<NicknameService>(
    () => NicknameService(
      secureStorage: getIt<SecureStorageRepository>(),
    ),
  );

  // Note: ImagePuzzleGenerator is NOT registered as a singleton because
  // it has mutable state (gridSize) and needs to be created per-game instance.
  // Instead, providers will create instances and inject UnsplashService.
}

/// Reset the service locator (useful for testing)
Future<void> resetServiceLocator() async {
  await getIt.reset();
}
