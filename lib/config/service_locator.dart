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
import 'package:multigame/games/sudoku/services/sudoku_persistence_service.dart';
import 'package:multigame/games/sudoku/services/sudoku_stats_service.dart';
import 'package:multigame/games/sudoku/services/matchmaking_service.dart';
import 'package:multigame/games/sudoku/services/sudoku_sound_service.dart';
import 'package:multigame/games/sudoku/services/sudoku_haptic_service.dart';
import 'package:multigame/games/sudoku/providers/sudoku_settings_provider.dart';
import 'package:multigame/services/feedback/haptic_feedback_service.dart';
import 'package:multigame/services/feedback/sound_service.dart';
import 'package:multigame/services/onboarding/onboarding_service.dart';
import 'package:multigame/services/accessibility/accessibility_service.dart';
import 'package:multigame/services/themes/theme_service.dart';
import 'package:multigame/services/performance/image_cache_service.dart';
import 'package:multigame/services/performance/battery_saver_service.dart';

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
    () => SecureUserRepository(secureStorage: getIt<SecureStorageRepository>()),
  );

  // Stats repository for Firebase statistics and leaderboards
  getIt.registerLazySingleton<StatsRepository>(() => FirebaseStatsRepository());

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

  getIt.registerLazySingleton<AuthService>(() => AuthService());

  getIt.registerLazySingleton<FirebaseStatsService>(
    () => FirebaseStatsService(statsRepository: getIt<StatsRepository>()),
  );

  getIt.registerLazySingleton<AchievementService>(
    () => AchievementService(repository: getIt<AchievementRepository>()),
  );

  getIt.registerLazySingleton<UnsplashService>(() => UnsplashService());

  getIt.registerLazySingleton<NicknameService>(
    () => NicknameService(
      userRepository: getIt<UserRepository>(),
      migrator: getIt<StorageMigrator>(),
    ),
  );

  // Sudoku game services
  getIt.registerLazySingleton<SudokuPersistenceService>(
    () => SudokuPersistenceService(storage: getIt<SecureStorageRepository>()),
  );

  getIt.registerLazySingleton<SudokuStatsService>(
    () => SudokuStatsService(storage: getIt<SecureStorageRepository>()),
  );

  getIt.registerLazySingleton<MatchmakingService>(() => MatchmakingService());

  // Sudoku settings and feedback services (Phase 6)
  getIt.registerLazySingleton<SudokuSettingsProvider>(
    () => SudokuSettingsProvider(),
  );

  getIt.registerLazySingleton<SudokuSoundService>(
    () => SudokuSoundService(settings: getIt<SudokuSettingsProvider>()),
  );

  getIt.registerLazySingleton<SudokuHapticService>(
    () => SudokuHapticService(settings: getIt<SudokuSettingsProvider>()),
  );

  // ========== App-Wide Feedback Services (Phase 6) ==========
  // These provide haptic and sound feedback across the entire app

  getIt.registerLazySingleton<HapticFeedbackService>(
    () => HapticFeedbackService(),
  );

  getIt.registerLazySingleton<SoundService>(() => SoundService());

  // ========== Onboarding Service (Phase 7) ==========
  // Tracks onboarding completion and tutorial states

  getIt.registerLazySingleton<OnboardingService>(() => OnboardingService());

  // ========== Accessibility Service (Phase 8) ==========
  // Persists and retrieves accessibility settings

  getIt.registerLazySingleton<AccessibilityService>(
    () => AccessibilityService(storage: getIt<SecureStorageRepository>()),
  );

  // ========== Theme Service (Phase 8) ==========

  getIt.registerLazySingleton<ThemeService>(
    () => ThemeService(storage: getIt<SecureStorageRepository>()),
  );

  // ========== Performance Services (Phase 8) ==========

  getIt.registerLazySingleton<ImageCacheService>(() => ImageCacheService());

  getIt.registerLazySingleton<BatterySaverService>(
    () => BatterySaverService(storage: getIt<SecureStorageRepository>()),
  );

  // ========== App-Wide Feedback Services (Phase 6) ==========
  // These provide haptic and sound feedback across the entire app

  getIt.registerLazySingleton<HapticFeedbackService>(
    () => HapticFeedbackService(),
  );

  getIt.registerLazySingleton<SoundService>(
    () => SoundService(),
  );

  // ========== Onboarding Service (Phase 7) ==========
  // Tracks onboarding completion and tutorial states

  getIt.registerLazySingleton<OnboardingService>(
    () => OnboardingService(),
  );

  // ========== Accessibility Service (Phase 8) ==========
  // Persists and retrieves accessibility settings

  getIt.registerLazySingleton<AccessibilityService>(
    () => AccessibilityService(
      storage: getIt<SecureStorageRepository>(),
    ),
  );

  // ========== Theme Service (Phase 8) ==========

  getIt.registerLazySingleton<ThemeService>(
    () => ThemeService(
      storage: getIt<SecureStorageRepository>(),
    ),
  );

  // ========== Performance Services (Phase 8) ==========

  getIt.registerLazySingleton<ImageCacheService>(
    () => ImageCacheService(),
  );

  getIt.registerLazySingleton<BatterySaverService>(
    () => BatterySaverService(
      storage: getIt<SecureStorageRepository>(),
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
