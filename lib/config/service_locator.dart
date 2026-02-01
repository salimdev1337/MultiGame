import 'package:get_it/get_it.dart';
import 'package:multigame/repositories/secure_storage_repository.dart';
import 'package:multigame/repositories/user_repository.dart';
import 'package:multigame/repositories/stats_repository.dart';
import 'package:multigame/repositories/achievement_repository.dart';
import 'package:multigame/services/data/achievement_service.dart';
import 'package:multigame/services/auth/auth_service.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import 'package:multigame/services/storage/nickname_service.dart';
import 'package:multigame/services/game/unsplash_service.dart';
import 'package:multigame/utils/storage_migrator.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Setup and register all services with the service locator
///
/// This should be called once at app startup before runApp()
/// Services are registered as lazy singletons - they are created only when first accessed
Future<void> setupServiceLocator() async {
  // ========== Register Repositories (Data Layer) ==========
  // These are the lowest level - handle data persistence

  // Secure storage repository for encrypted data
  getIt.registerLazySingleton<SecureStorageRepository>(
    () => SecureStorageRepository(),
  );

  // User repository for user profile data (uses SecureStorageRepository)
  getIt.registerLazySingleton<UserRepository>(
    () => SecureUserRepository(
      secureStorage: getIt<SecureStorageRepository>(),
    ),
  );

  // Stats repository for Firebase statistics and leaderboards
  getIt.registerLazySingleton<StatsRepository>(
    () => FirebaseStatsRepository(),
  );

  // Achievement repository for local achievements and stats
  getIt.registerLazySingleton<AchievementRepository>(
    () => SharedPrefsAchievementRepository(),
  );

  // ========== Register Utilities ==========

  getIt.registerLazySingleton<StorageMigrator>(
    () => StorageMigrator(getIt<SecureStorageRepository>()),
  );

  // ========== Register Services (Business Logic Layer) ==========
  // These use repositories for data persistence

  getIt.registerLazySingleton<AuthService>(
    () => AuthService(),
  );

  getIt.registerLazySingleton<FirebaseStatsService>(
    () => FirebaseStatsService(
      statsRepository: getIt<StatsRepository>(),
    ),
  );

  getIt.registerLazySingleton<AchievementService>(
    () => AchievementService(
      repository: getIt<AchievementRepository>(),
    ),
  );

  getIt.registerLazySingleton<UnsplashService>(
    () => UnsplashService(),
  );

  getIt.registerLazySingleton<NicknameService>(
    () => NicknameService(
      userRepository: getIt<UserRepository>(),
      migrator: getIt<StorageMigrator>(),
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
