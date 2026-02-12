/// Riverpod providers that expose GetIt-registered services.
///
/// This is the bridge layer: services stay in GetIt (they have no Flutter
/// lifecycle) but are accessible as Riverpod providers so game notifiers can
/// declare them as dependencies — making mocking trivial in tests.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/config/service_locator.dart';
import 'package:multigame/services/auth/auth_service.dart';
import 'package:multigame/services/data/achievement_service.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import 'package:multigame/services/storage/nickname_service.dart';
import 'package:multigame/services/feedback/haptic_feedback_service.dart';
import 'package:multigame/services/feedback/sound_service.dart';
import 'package:multigame/games/sudoku/services/sudoku_persistence_service.dart';
import 'package:multigame/games/sudoku/services/sudoku_stats_service.dart';
import 'package:multigame/games/sudoku/services/sudoku_sound_service.dart';
import 'package:multigame/games/sudoku/services/sudoku_haptic_service.dart';
import 'package:multigame/games/sudoku/services/matchmaking_service.dart';
import 'package:multigame/services/game/unsplash_service.dart';
import 'package:multigame/services/accessibility/accessibility_service.dart';
import 'package:multigame/providers/accessibility_provider.dart';
import 'package:multigame/services/themes/theme_service.dart';
import 'package:multigame/providers/theme_provider.dart';

final authServiceProvider =
    Provider<AuthService>((_) => getIt<AuthService>());

final firebaseStatsServiceProvider =
    Provider<FirebaseStatsService>((_) => getIt<FirebaseStatsService>());

final achievementServiceProvider =
    Provider<AchievementService>((_) => getIt<AchievementService>());

final nicknameServiceProvider =
    Provider<NicknameService>((_) => getIt<NicknameService>());

final hapticFeedbackServiceProvider =
    Provider<HapticFeedbackService>((_) => getIt<HapticFeedbackService>());

final soundServiceProvider =
    Provider<SoundService>((_) => getIt<SoundService>());

final sudokuPersistenceServiceProvider =
    Provider<SudokuPersistenceService>((_) => getIt<SudokuPersistenceService>());

final sudokuStatsServiceProvider =
    Provider<SudokuStatsService>((_) => getIt<SudokuStatsService>());

final sudokuSoundServiceProvider =
    Provider<SudokuSoundService>((_) => getIt<SudokuSoundService>());

final sudokuHapticServiceProvider =
    Provider<SudokuHapticService>((_) => getIt<SudokuHapticService>());

final matchmakingServiceProvider =
    Provider<MatchmakingService>((_) => getIt<MatchmakingService>());

final unsplashServiceProvider =
    Provider<UnsplashService>((_) => getIt<UnsplashService>());

final accessibilityServiceProvider =
    Provider<AccessibilityService>((_) => getIt<AccessibilityService>());

final accessibilityProvider =
    ChangeNotifierProvider<AccessibilityProvider>((ref) {
  final service = ref.watch(accessibilityServiceProvider);
  return AccessibilityProvider(service: service)..loadSettings();
});

final themeServiceProvider =
    Provider<ThemeService>((_) => getIt<ThemeService>());

final themeProvider = ChangeNotifierProvider<ThemeProvider>((ref) {
  final service = ref.watch(themeServiceProvider);
  return ThemeProvider(service: service)..loadTheme();
});
