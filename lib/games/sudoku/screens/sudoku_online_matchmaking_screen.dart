// Online matchmaking screen - see docs/SUDOKU_ARCHITECTURE.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:multigame/games/sudoku/logic/sudoku_generator.dart';
import 'package:multigame/games/sudoku/providers/sudoku_online_provider.dart';
import 'package:multigame/config/service_locator.dart';
import 'package:multigame/services/auth/auth_service.dart';
import 'package:multigame/games/sudoku/services/matchmaking_service.dart';
import 'sudoku_online_game_screen.dart';
import 'package:multigame/games/sudoku/widgets/sudoku_difficulty_card.dart';

const _backgroundDark = Color(0xFF0f1115);
const _surfaceDark = Color(0xFF1a1d24);
const _accentBlue = Color(0xFF3b82f6);

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
  String? _roomCode;
  final TextEditingController _roomCodeController = TextEditingController();

  Future<void> _startMatchmaking() async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _roomCode = null;
    });

    try {
      final authService = getIt<AuthService>();
      final userId = authService.getUserId();
      final displayName = authService.getDisplayName() ?? 'Player';

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final provider = SudokuOnlineProvider(
        matchmakingService: getIt<MatchmakingService>(),
        userId: userId,
        displayName: displayName,
      );

      await provider.createMatch(_difficultyToString(_selectedDifficulty));

      if (!mounted) return;

      final roomCode = provider.currentMatch?.roomCode;

      setState(() {
        _roomCode = roomCode;
      });

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
        _errorMessage = 'Failed to create match: ${e.toString()}';
      });
    }
  }

  Future<void> _joinByRoomCode(String roomCode) async {
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

      if (roomCode.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(roomCode)) {
        throw Exception('Invalid room code format. Must be 6 digits.');
      }

      final provider = SudokuOnlineProvider(
        matchmakingService: getIt<MatchmakingService>(),
        userId: userId,
        displayName: displayName,
      );

      await provider.joinByRoomCode(roomCode);

      if (!mounted) return;

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
        _errorMessage = 'Failed to join match: ${e.toString()}';
      });
    }
  }

  Future<void> _showJoinByCodeDialog() async {
    _roomCodeController.clear();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceDark,
        title: const Text(
          'Join with Code',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the 6-digit room code:',
              style: TextStyle(
                color: Color(0x99FFFFFF),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roomCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3 * 255),
                  letterSpacing: 8,
                ),
                filled: true,
                fillColor: _backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Color(0x99FFFFFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _roomCodeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(context).pop();
                _joinByRoomCode(code);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'JOIN',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyRoomCode() async {
    if (_roomCode != null) {
      await Clipboard.setData(ClipboardData(text: _roomCode!));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room code copied to clipboard!'),
          duration: Duration(seconds: 2),
          backgroundColor: _accentBlue,
        ),
      );
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
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
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
            'WAITING FOR OPPONENT',
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
          if (_roomCode != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: _surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _accentBlue.withValues(alpha: 0.3 * 255),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'ROOM CODE',
                    style: TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _roomCode!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _copyRoomCode,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('COPY CODE'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accentBlue,
                      side: const BorderSide(color: _accentBlue, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Share this code with a friend to play together!',
                style: TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (_roomCode == null) ...[
            const SizedBox(height: 24),
            const Text(
              'Please wait...',
              style: TextStyle(
                color: Color(0x99FFFFFF),
                fontSize: 14,
              ),
            ),
          ],
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
                _roomCode = null;
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
        SudokuDifficultyCard(
          difficulty: SudokuDifficulty.easy,
          name: 'Easy',
          description: '36-40 clues • Perfect for beginners',
          icon: Icons.sentiment_satisfied,
          color: const Color(0xFF4ade80),
          isSelected: _selectedDifficulty == SudokuDifficulty.easy,
          onTap: () => setState(() => _selectedDifficulty = SudokuDifficulty.easy),
        ),
        const SizedBox(height: 12),
        SudokuDifficultyCard(
          difficulty: SudokuDifficulty.medium,
          name: 'Medium',
          description: '30-35 clues • Intermediate challenge',
          icon: Icons.sentiment_neutral,
          color: const Color(0xFFfbbf24),
          isSelected: _selectedDifficulty == SudokuDifficulty.medium,
          onTap: () => setState(() => _selectedDifficulty = SudokuDifficulty.medium),
        ),
        const SizedBox(height: 12),
        SudokuDifficultyCard(
          difficulty: SudokuDifficulty.hard,
          name: 'Hard',
          description: '25-29 clues • Advanced players',
          icon: Icons.sentiment_dissatisfied,
          color: const Color(0xFFfb923c),
          isSelected: _selectedDifficulty == SudokuDifficulty.hard,
          onTap: () => setState(() => _selectedDifficulty = SudokuDifficulty.hard),
        ),
        const SizedBox(height: 12),
        SudokuDifficultyCard(
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
        const SizedBox(height: 32),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: Divider(color: Color(0x33FFFFFF))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0x33FFFFFF))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton(
            onPressed: _showJoinByCodeDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: _accentBlue,
              side: const BorderSide(color: _accentBlue, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'JOIN WITH CODE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
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
