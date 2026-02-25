import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:go_router/go_router.dart';
import 'config/service_locator.dart';
import 'config/app_router.dart';
import 'package:multigame/providers/app_init_provider.dart';
import 'package:multigame/games/sudoku/index.dart';
import 'package:multigame/utils/secure_logger.dart';
import 'package:multigame/core/game_initializer.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/services/feedback/haptic_feedback_service.dart';
import 'package:multigame/services/feedback/sound_service.dart';
import 'package:multigame/services/ads/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupServiceLocator();
  await _initializeSudokuServices();
  await _initializeAppServices();
  initializeGames();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF21242b),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initializeSudokuServices() async {
  try {
    final settingsProvider = getIt<SudokuSettingsProvider>();
    await settingsProvider.initialize();
    final soundService = getIt<SudokuSoundService>();
    await soundService.initialize();
    final hapticService = getIt<SudokuHapticService>();
    await hapticService.initialize();
    SecureLogger.log('Sudoku services initialized', tag: 'Sudoku');
  } catch (e) {
    SecureLogger.error('Failed to initialize Sudoku services', error: e);
  }
}

Future<void> _initializeAppServices() async {
  try {
    final hapticService = getIt<HapticFeedbackService>();
    await hapticService.initialize();
    final soundService = getIt<SoundService>();
    await soundService.initialize();
    SecureLogger.log('App-wide services initialized', tag: 'Phase6');
  } catch (e) {
    SecureLogger.error('Failed to initialize app-wide services', error: e);
  }
  try {
    await getIt<AdService>().initialize();
  } catch (e) {
    SecureLogger.error('Failed to initialize AdMob', error: e);
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  // Router is created once and kept stable — recreating it on every
  // rebuild resets navigation state and breaks the splash → home flow
  // for returning users (ref.listen in _SplashScreen never fires).
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildAppRouter(ref);
  }

  @override
  Widget build(BuildContext context) {
    // Once Firebase initialises, wire up Crashlytics for Flutter errors.
    ref.listen(appInitProvider, (_, next) {
      next.whenData((_) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
      });
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MultiGame',
      theme: DSTheme.buildDarkTheme(),
      routerConfig: _router,
    );
  }
}
