import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/service_locator.dart';
import 'package:multigame/games/sudoku/logic/sudoku_generator.dart';
import 'package:multigame/providers/app_init_provider.dart';
import 'package:multigame/screens/onboarding/welcome_splash_screen.dart';
import 'package:multigame/screens/onboarding/onboarding_tutorial_screen.dart';
import 'package:multigame/screens/home_page_premium.dart';
import 'package:multigame/screens/profile_screen.dart';
import 'package:multigame/screens/leaderboard_screen_premium.dart';
import 'package:multigame/screens/shell_scaffold.dart';
import 'package:multigame/games/puzzle/screens/puzzle_screen.dart';
import 'package:multigame/games/game_2048/screens/game_2048_screen.dart';
import 'package:multigame/games/snake/screens/snake_game_screen.dart';
import 'package:multigame/games/infinite_runner/screens/infinite_runner_screen.dart';
import 'package:multigame/games/memory/screens/memory_game_screen.dart';
import 'package:multigame/games/bomberman/screens/bomberman_game_screen.dart';
import 'package:multigame/games/bomberman/screens/bomberman_lobby_screen.dart';
import 'package:multigame/games/sudoku/screens/modern_mode_difficulty_screen.dart';
import 'package:multigame/games/sudoku/screens/sudoku_classic_screen.dart';
import 'package:multigame/games/sudoku/screens/sudoku_rush_screen.dart';
import 'package:multigame/games/sudoku/screens/sudoku_online_matchmaking_screen.dart';
import 'package:multigame/services/onboarding/onboarding_service.dart';

/// Route path constants — single source of truth for all routes.
abstract class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const leaderboard = '/leaderboard';
  static const profile = '/profile';
  static const play = '/play';

  static String game(String gameId) => '/play/$gameId';
  static String sudokuMode(String mode) => '/play/sudoku/$mode';
  static const bombermanLobby = '/play/bomberman/lobby';
}

GoRouter buildAppRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final appAsync = ref.read(appInitProvider);

      if (appAsync.isLoading) return AppRoutes.splash;
      if (appAsync.hasError) return AppRoutes.splash;

      final path = state.uri.toString();
      final onboardingService = getIt<OnboardingService>();
      final hasOnboarded = await onboardingService.hasCompletedOnboarding();

      if (!hasOnboarded) {
        if (kIsWeb) {
          await onboardingService.completeOnboarding();
          return AppRoutes.home;
        }
        return path == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      if (path == AppRoutes.splash || path == AppRoutes.onboarding) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const _SplashScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const _OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ShellScaffold(navigationShell: shell),
        branches: [
          // Tab 0 — Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => HomePagePremium(
                  onGameSelected: (game) => context.goToGame(game.id),
                ),
              ),
            ],
          ),
          // Tab 1 — Play
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.play,
                builder: (_, _) => const _GameSelectionPrompt(),
                routes: [
                  GoRoute(
                    path: '2048',
                    builder: (_, _) => const Game2048Page(),
                  ),
                  GoRoute(
                    path: 'snake_game',
                    builder: (_, _) => const SnakeGamePage(),
                  ),
                  GoRoute(
                    path: 'image_puzzle',
                    builder: (_, _) => const PuzzlePage(),
                  ),
                  GoRoute(
                    path: 'infinite_runner',
                    builder: (_, _) => const InfiniteRunnerPage(),
                  ),
                  GoRoute(
                    path: 'memory_game',
                    builder: (_, _) => const MemoryGamePage(),
                  ),
                  GoRoute(
                    path: 'bomberman',
                    builder: (_, _) => const BombermanGamePage(),
                    routes: [
                      GoRoute(
                        path: 'lobby',
                        builder: (_, _) => const BombermanLobbyPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'sudoku',
                    builder: (_, _) => const ModernModeDifficultyScreen(),
                    routes: [
                      GoRoute(
                        path: 'classic',
                        builder: (_, state) => SudokuClassicScreen(
                          difficulty: _parseDifficulty(state.extra),
                        ),
                      ),
                      GoRoute(
                        path: 'rush',
                        builder: (_, state) => SudokuRushScreen(
                          difficulty: _parseDifficulty(state.extra),
                        ),
                      ),
                      GoRoute(
                        path: 'online',
                        builder: (_, _) =>
                            const SudokuOnlineMatchmakingScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Tab 2 — Leaderboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.leaderboard,
                builder: (_, _) => const LeaderboardScreenPremium(),
              ),
            ],
          ),
          // Tab 3 — Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

SudokuDifficulty _parseDifficulty(Object? extra) {
  if (extra is SudokuDifficulty) return extra;
  return SudokuDifficulty.easy;
}

class _SplashScreen extends ConsumerWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-trigger the router redirect when Firebase init completes.
    // Without this, GoRouter's redirect never fires automatically and the
    // app stays stuck on the splash screen forever.
    ref.listen<AsyncValue<void>>(appInitProvider, (_, next) {
      if (!next.isLoading) {
        context.go(AppRoutes.splash);
      }
    });

    final appAsync = ref.watch(appInitProvider);

    // Fallback: if the provider was already done when this widget first
    // built (e.g., very fast init on returning users), the listener above
    // never fires. Navigate immediately via postFrameCallback.
    if (!appAsync.isLoading && !appAsync.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.splash);
      });
    }

    if (appAsync.hasError) {
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
                onPressed: () => ref.refresh(appInitProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show the polished animated splash while Firebase initializes
    return WelcomeSplashScreen(onComplete: () {});
  }
}

class _OnboardingScreen extends ConsumerStatefulWidget {
  const _OnboardingScreen();

  @override
  ConsumerState<_OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<_OnboardingScreen> {
  _OnboardingStep _step = _OnboardingStep.splash;

  void _onSplashComplete() => setState(() => _step = _OnboardingStep.tutorial);

  Future<void> _onTutorialComplete() async {
    await getIt<OnboardingService>().completeOnboarding();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case _OnboardingStep.splash:
        return WelcomeSplashScreen(onComplete: _onSplashComplete);
      case _OnboardingStep.tutorial:
        return OnboardingTutorialScreen(onComplete: _onTutorialComplete);
    }
  }
}

enum _OnboardingStep { splash, tutorial }

class _GameSelectionPrompt extends StatelessWidget {
  const _GameSelectionPrompt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.games_outlined,
              size: 80,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Game Selected',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Go to Home and select a game to play'),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.home),
              label: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
