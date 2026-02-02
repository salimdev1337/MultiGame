import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:multigame/games/sudoku/logic/sudoku_generator.dart';
import 'package:multigame/games/sudoku/providers/sudoku_online_provider.dart';
import 'package:multigame/config/service_locator.dart';
import 'package:multigame/services/auth/auth_service.dart';
import 'package:multigame/games/sudoku/services/matchmaking_service.dart';
import 'sudoku_online_game_screen.dart';

// Color constants
const _backgroundDark = Color(0xFF0f1115);
const _surfaceDark = Color(0xFF1a1d24);
const _accentBlue = Color(0xFF3b82f6);

/// Online matchmaking screen for 1v1 Sudoku
class SudokuOnlineMatchmakingScreen extends StatefulWidget {
  const SudokuOnlineMatchmakingScreen({super.key});

  @override
  State<SudokuOnlineMatchmakingScreen> createState() =>
      _SudokuOnlineMatchmakingScreenState();
}

class _SudokuOnlineMatchmakingScreenState
    extends State<SudokuOnlineMatchmakingScreen> {
  SudokuDifficulty _selectedDifficulty = SudokuDifficulty.medium;
  bool _isSearching = false;
  String? _errorMessage;

  Future<void> _startMatchmaking() async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final authService = getIt<AuthService>();
      final userId = authService.getUserId();
      final displayName = authService.getDisplayName() ?? 'Player';

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create provider
      final provider = SudokuOnlineProvider(
        matchmakingService: getIt<MatchmakingService>(),
        userId: userId,
        displayName: displayName,
      );

      // Start matchmaking
      await provider.joinMatch(_difficultyToString(_selectedDifficulty));

      if (!mounted) return;

      // Navigate to game screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: const SudokuOnlineGameScreen(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _errorMessage = 'Failed to find match: ${e.toString()}';
      });
    }
  }

  String _difficultyToString(SudokuDifficulty difficulty) {
    switch (difficulty) {
      case SudokuDifficulty.easy:
        return 'easy';
      case SudokuDifficulty.medium:
        return 'medium';
      case SudokuDifficulty.hard:
        return 'hard';
      case SudokuDifficulty.expert:
        return 'expert';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              'ONLINE 1v1',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                fontSize: 18,
              ),
            ),
            Text(
              'Challenge Other Players',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0x99FFFFFF),
              ),
            ),
          ],
        ),
        backgroundColor: _surfaceDark,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isSearching
            ? _buildSearchingUI()
            : _buildDifficultySelection(),
      ),
    );
  }

  Widget _buildSearchingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              color: _accentBlue,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'FINDING OPPONENT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _difficultyToString(_selectedDifficulty).toUpperCase(),
            style: TextStyle(
              color: _getDifficultyColor(_selectedDifficulty),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Please wait...',
            style: TextStyle(
              color: Color(0x99FFFFFF),
              fontSize: 14,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 32),
          TextButton(
            onPressed: () {
              setState(() {
                _isSearching = false;
                _errorMessage = null;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        const Text(
          'Select Difficulty',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _DifficultyCard(
          difficulty: SudokuDifficulty.easy,
          name: 'Easy',
          description: '36-40 clues • Perfect for beginners',
          icon: Icons.sentiment_satisfied,
          color: const Color(0xFF4ade80),
          isSelected: _selectedDifficulty == SudokuDifficulty.easy,
          onTap: () => setState(() => _selectedDifficulty = SudokuDifficulty.easy),
        ),
        const SizedBox(height: 12),
        _DifficultyCard(
          difficulty: SudokuDifficulty.medium,
          name: 'Medium',
          description: '30-35 clues • Intermediate challenge',
          icon: Icons.sentiment_neutral,
          color: const Color(0xFFfbbf24),
          isSelected: _selectedDifficulty == SudokuDifficulty.medium,
          onTap: () => setState(() => _selectedDifficulty = SudokuDifficulty.medium),
        ),
        const SizedBox(height: 12),
        _DifficultyCard(
          difficulty: SudokuDifficulty.hard,
          name: 'Hard',
          description: '25-29 clues • Advanced players',
          icon: Icons.sentiment_dissatisfied,
          color: const Color(0xFFfb923c),
          isSelected: _selectedDifficulty == SudokuDifficulty.hard,
          onTap: () => setState(() => _selectedDifficulty = SudokuDifficulty.hard),
        ),
        const SizedBox(height: 12),
        _DifficultyCard(
          difficulty: SudokuDifficulty.expert,
          name: 'Expert',
          description: '20-24 clues • For masters only',
          icon: Icons.sentiment_very_dissatisfied,
          color: const Color(0xFFef4444),
          isSelected: _selectedDifficulty == SudokuDifficulty.expert,
          onTap: () => setState(() => _selectedDifficulty = SudokuDifficulty.expert),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: _startMatchmaking,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Text(
              'FIND MATCH',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'You will be matched with another player of similar skill level.',
            style: TextStyle(
              color: Color(0x99FFFFFF),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(SudokuDifficulty difficulty) {
    switch (difficulty) {
      case SudokuDifficulty.easy:
        return const Color(0xFF4ade80);
      case SudokuDifficulty.medium:
        return const Color(0xFFfbbf24);
      case SudokuDifficulty.hard:
        return const Color(0xFFfb923c);
      case SudokuDifficulty.expert:
        return const Color(0xFFef4444);
    }
  }
}

class _DifficultyCard extends StatelessWidget {
  final SudokuDifficulty difficulty;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.difficulty,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3 * 255),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15 * 255),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6 * 255),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
