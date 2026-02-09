import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'config/firebase_options.dart';
import 'config/service_locator.dart';
import 'package:multigame/games/puzzle/index.dart';
import 'package:multigame/games/game_2048/index.dart';
import 'package:multigame/games/snake/index.dart';
import 'package:multigame/games/sudoku/index.dart';
import 'package:multigame/providers/user_auth_provider.dart';
import 'package:multigame/screens/main_navigation.dart';
import 'package:multigame/services/data/achievement_service.dart';
import 'package:multigame/services/auth/auth_service.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import 'package:multigame/services/storage/nickname_service.dart';
import 'package:multigame/utils/secure_logger.dart';
import 'package:multigame/core/game_initializer.dart';
import 'package:multigame/design_system/design_system.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection container
  await setupServiceLocator();

  // Initialize Sudoku Phase 6 services (settings, sound, haptics)
  await _initializeSudokuPhase6Services();

  // Initialize game registry
  initializeGames();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF21242b),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Note: Crashlytics is initialized in _initializeFirebase() after Firebase.initializeApp()
  // Flutter errors will be caught and reported in the error zone below

  // Run app in an error zone to catch async errors
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stack) {
    // This catches errors that occur outside of Flutter's framework
    SecureLogger.error('Uncaught error in root zone', error: error);
    // Crashlytics will be set up after Firebase initialization
    // For now, just log - Crashlytics reporting will be added in _initializeFirebase
  });
}

/// Initializes Sudoku Phase 6 services (settings, sound, haptics)
Future<void> _initializeSudokuPhase6Services() async {
  try {
    // Initialize settings provider (loads persisted settings)
    final settingsProvider = getIt<SudokuSettingsProvider>();
    await settingsProvider.initialize();

    // Initialize sound service
    final soundService = getIt<SudokuSoundService>();
    await soundService.initialize();

    // Initialize haptic service
    final hapticService = getIt<SudokuHapticService>();
    await hapticService.initialize();

    SecureLogger.log('Sudoku Phase 6 services initialized', tag: 'Sudoku');
  } catch (e) {
    SecureLogger.error('Failed to initialize Sudoku Phase 6 services', error: e);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserAuthProvider(
            authService: getIt<AuthService>(),
            nicknameService: getIt<NicknameService>(),
          ),
        ),
        // Puzzle game providers
        ChangeNotifierProvider(
          create: (_) => PuzzleGameNotifier(
            achievementService: getIt<AchievementService>(),
            statsService: getIt<FirebaseStatsService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PuzzleUIProvider(),
        ),
        // 2048 game providers
        ChangeNotifierProvider(
          create: (_) => Game2048Provider(
            achievementService: getIt<AchievementService>(),
            statsService: getIt<FirebaseStatsService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => Game2048UIProvider(),
        ),
        // Snake game providers
        ChangeNotifierProvider(
          create: (_) => SnakeGameProvider(
            statsService: getIt<FirebaseStatsService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SnakeUIProvider(),
        ),
        // Sudoku game providers (Classic Mode)
        ChangeNotifierProvider(
          create: (_) => SudokuProvider(
            statsService: getIt<FirebaseStatsService>(),
            persistenceService: getIt<SudokuPersistenceService>(),
            sudokuStatsService: getIt<SudokuStatsService>(),
            soundService: getIt<SudokuSoundService>(),
            hapticService: getIt<SudokuHapticService>(),
          ),
        ),
        // Sudoku Rush Mode provider
        ChangeNotifierProvider(
          create: (_) => SudokuRushProvider(
            statsService: getIt<FirebaseStatsService>(),
            persistenceService: getIt<SudokuPersistenceService>(),
            sudokuStatsService: getIt<SudokuStatsService>(),
            soundService: getIt<SudokuSoundService>(),
            hapticService: getIt<SudokuHapticService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SudokuUIProvider(),
        ),
        // Sudoku settings provider (Phase 6 - Polish & UX)
        ChangeNotifierProvider(
          create: (_) => getIt<SudokuSettingsProvider>(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MultiGame',
        theme: DSTheme.buildDarkTheme(),
        home: const FirebaseInitializer(),
      ),
    );
  }
}

/// Widget that initializes Firebase and shows loading screen
class FirebaseInitializer extends StatefulWidget {
  const FirebaseInitializer({super.key});

  @override
  State<FirebaseInitializer> createState() => _FirebaseInitializerState();
}

class _FirebaseInitializerState extends State<FirebaseInitializer> {
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Firebase Crashlytics
      FlutterError.onError = (errorDetails) {
        // Pass Flutter framework errors to Crashlytics
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        SecureLogger.error('Flutter framework error', error: errorDetails.exception);
      };

      // Pass async errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        SecureLogger.error('Platform dispatcher error', error: error);
        return true;
      };

      SecureLogger.log('Crashlytics initialized', tag: 'Crashlytics');

      // Get NicknameService from service locator
      final nicknameService = getIt<NicknameService>();

      // Always sign in to Firebase (needed for Firestore access)
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        SecureLogger.firebase('Signed in anonymously');
      }

      // Check if we have a persistent userId saved
      final savedUserId = await nicknameService.getUserId();

      if (savedUserId != null) {
        // User has played before - keep using their saved persistent ID
        SecureLogger.user('Returning user with saved persistent ID', userId: savedUserId);
      } else {
        // First time user - save current Firebase userId as persistent ID
        final firebaseUserId = FirebaseAuth.instance.currentUser?.uid;
        if (firebaseUserId != null) {
          await nicknameService.saveUserId(firebaseUserId);
          SecureLogger.user('New user - saved persistent ID', userId: firebaseUserId);
        }
      }

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      SecureLogger.error('Firebase initialization failed', error: e, tag: 'Firebase');
      setState(() {
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to initialize app'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = false;
                    _initialized = false;
                  });
                  _initializeFirebase();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              const Text('Loading...'),
            ],
          ),
        ),
      );
    }

    return MainNavigation(key: MainNavigation.navigatorKey);
  }
}
