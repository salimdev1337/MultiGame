import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:multigame/models/game_model.dart';
import 'package:multigame/providers/user_auth_provider.dart';
import 'package:multigame/providers/game_2048_provider.dart';
import 'package:multigame/providers/snake_game_provider.dart';
import 'package:multigame/providers/puzzle_game_provider.dart';
import 'package:multigame/services/storage/nickname_service.dart';
import 'package:multigame/widgets/nickname_dialog.dart';
import 'package:multigame/screens/home_page.dart';
import 'package:multigame/screens/profile_screen.dart';
import 'package:multigame/screens/puzzle.dart';
import 'package:multigame/screens/game_2048_page.dart';
import 'package:multigame/screens/snake_game_page.dart';
import 'package:multigame/screens/infinite_runner_page.dart';
import 'package:multigame/screens/leaderboard_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  static final GlobalKey navigatorKey = GlobalKey();

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  GameModel? _selectedGame;
  final NicknameService _nicknameService = NicknameService();
  String? _userNickname;

  @override
  void initState() {
    super.initState();
    // Initialize user info in game providers after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUser();
    });
  }

  Future<void> _initializeUser() async {
    // Load saved nickname
    _userNickname = await _nicknameService.getNickname();

    // If no nickname, prompt user
    if (_userNickname == null && mounted) {
      _userNickname = await showNicknameDialog(context, isFirstTime: true);
      if (_userNickname != null) {
        await _nicknameService.saveNickname(_userNickname!);
      }
    }

    // Update game providers with user info
    _updateGameProvidersUserInfo();
  }

  void _updateGameProvidersUserInfo() {
    final authProvider = context.read<UserAuthProvider>();
    if (authProvider.userId != null) {
      // Use nickname instead of displayName
      final displayName = _userNickname ?? authProvider.displayName;

      context.read<Game2048Provider>().setUserInfo(
        authProvider.userId,
        displayName,
      );
      context.read<SnakeGameProvider>().setUserInfo(
        authProvider.userId,
        displayName,
      );
      context.read<PuzzleGameNotifier>().setUserInfo(
        authProvider.userId,
        displayName,
      );
      debugPrint('User info updated: ${authProvider.userId} - $displayName');
    } else {
      debugPrint('User info is null, waiting for auth...');
      // Retry after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _updateGameProvidersUserInfo();
      });
    }
  }

  void _onGameSelected(GameModel game) {
    if (game.id == 'image_puzzle' ||
        game.id == '2048' ||
        game.id == 'snake_game' ||
        game.id == 'infinite_runner') {
      setState(() {
        _selectedGame = game;
        _currentIndex = 1;
      });
    }
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return HomePage(onGameSelected: _onGameSelected);
      case 1:
        if (_selectedGame?.id == 'image_puzzle') {
          return const PuzzlePage();
        } else if (_selectedGame?.id == '2048') {
          return const Game2048Page();
        } else if (_selectedGame?.id == 'snake_game') {
          return const SnakeGamePage();
        } else if (_selectedGame?.id == 'infinite_runner') {
          return const InfiniteRunnerPage();
        } else {
          return _buildNoGameSelectedView();
        }
      case 2:
        return const LeaderboardScreen();
      case 3:
        return ProfilePage();
      default:
        return HomePage(onGameSelected: _onGameSelected);
    }
  }

  Widget _buildNoGameSelectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.games_outlined,
            size: 80,
            color: Colors.grey.withValues(alpha: (0.5 * 255)),
          ),
          const SizedBox(height: 24),
          Text(
            'No Game Selected',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: (0.7 * 255)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Go to Home and select a game to play',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.withValues(alpha: (0.6 * 255)),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _currentIndex = 0;
              });
            },
            icon: const Icon(Icons.home),
            label: const Text('Go to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hide bottom navigation bar when playing infinite runner
    final hideBottomNav =
        _currentIndex == 1 && _selectedGame?.id == 'infinite_runner';

    return Scaffold(
      body: _getCurrentPage(),
      bottomNavigationBar: hideBottomNav
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: (0.3 * 255)),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: Icons.games_rounded,
                        label: 'Game',
                        index: 1,
                      ),
                      _buildNavItem(
                        icon: Icons.emoji_events_rounded,
                        label: 'Leaderboard',
                        index: 2,
                      ),
                      _buildNavItem(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        index: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔵 Top indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            width: isSelected ? 24 : 0,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha((0.1 * 255).toInt())
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
