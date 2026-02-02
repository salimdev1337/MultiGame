import 'package:flutter/material.dart';
import 'difficulty_selection_screen.dart';
import 'sudoku_online_matchmaking_screen.dart';

// Color constants
const _backgroundDark = Color(0xFF0f1115);
const _surfaceDark = Color(0xFF1a1d24);
const _primaryCyan = Color(0xFF00d4ff);
const _dangerRed = Color(0xFFef4444);
const _accentBlue = Color(0xFF3b82f6);

/// Mode selection screen for Sudoku.
///
/// Allows players to choose between:
/// - Classic Mode: Solve at your own pace
/// - Rush Mode: 5-minute countdown with penalties
/// - Online 1v1: Compete against other players in real-time
class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        title: const Text(
          'SELECT MODE',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: _surfaceDark,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Classic Mode Card
              _ModeCard(
                title: 'CLASSIC MODE',
                description: 'Take your time and solve the puzzle at your own pace',
                icon: Icons.timelapse,
                color: _primaryCyan,
                features: const [
                  'No time limit',
                  'Track your solve time',
                  'Hints available',
                  'Perfect for learning',
                ],
                onTap: () => _selectMode(context, GameMode.classic),
              ),
              const SizedBox(height: 20),
              // Rush Mode Card
              _ModeCard(
                title: 'RUSH MODE',
                description: 'Race against the clock! 5 minutes to solve',
                icon: Icons.flash_on,
                color: _dangerRed,
                features: const [
                  '5-minute countdown',
                  '-10 seconds per mistake',
                  'Time bonus scoring',
                  'High-intensity challenge',
                ],
                onTap: () => _selectMode(context, GameMode.rush),
              ),
              const SizedBox(height: 20),
              // Online 1v1 Mode Card
              _ModeCard(
                title: 'ONLINE 1v1',
                description: 'Compete against other players in real-time',
                icon: Icons.people,
                color: _accentBlue,
                features: const [
                  'Real-time multiplayer',
                  'First to solve wins',
                  'Matchmaking system',
                  'Compete globally',
                ],
                onTap: () => _selectOnlineMode(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigates to difficulty selection with the selected mode
  void _selectMode(BuildContext context, GameMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DifficultySelectionScreen(mode: mode),
      ),
    );
  }

  /// Navigates to online matchmaking screen
  void _selectOnlineMode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SudokuOnlineMatchmakingScreen(),
      ),
    );
  }
}

/// Individual mode selection card
class _ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.5 * 255),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2 * 255),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15 * 255),
                      borderRadius: BorderRadius.circular(16),
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
                          title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6 * 255),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Features list
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: color.withValues(alpha: 0.7 * 255),
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8 * 255),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              // Play button
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15 * 255),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PLAY',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: color,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Game mode enum
enum GameMode {
  classic,
  rush,
}
