import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/puzzle/providers/puzzle_notifier.dart';
import 'package:multigame/games/puzzle/providers/puzzle_ui_notifier.dart';

class PuzzleTopAppBar extends ConsumerWidget {
  const PuzzleTopAppBar({super.key, required this.onSettingsTap});

  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(puzzleProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16181d).withValues(alpha: 0.8 * 255),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          _buildIconButton(Icons.settings, onSettingsTap),
          const Spacer(),
          Text(
            'LEVEL ${gameState.gridSize * gameState.gridSize}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: const Color(0xFF21242b),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF00d4ff), size: 20),
        ),
      ),
    );
  }
}

class PuzzleStatsSection extends ConsumerWidget {
  const PuzzleStatsSection({
    super.key,
    required this.hintButtonKey,
    required this.onHintTap,
  });

  final GlobalKey hintButtonKey;
  final VoidCallback onHintTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(puzzleProvider);
    return Row(
      children: [
        Expanded(child: _buildStatCard('MOVES', '${gameState.moveCount}')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('TIME', gameState.formatTime())),
        const SizedBox(width: 16),
        GestureDetector(
          key: hintButtonKey,
          onTap: onHintTap,
          child: Container(
            width: 64,
            height: 87,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF21242b),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05 * 255),
              ),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Color(0xFF00d4ff),
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF21242b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05 * 255)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2 * 255),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00d4ff),
            ),
          ),
        ],
      ),
    );
  }
}

class PuzzleFooterControls extends ConsumerWidget {
  const PuzzleFooterControls({
    super.key,
    required this.onReset,
    required this.onPlayAgain,
  });

  final VoidCallback onReset;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(puzzleUIProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF21242b).withValues(alpha: 0.5 * 255),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05 * 255)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3 * 255),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFooterButton(
              label: 'MAIN MENU',
              onPressed: onReset,
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildFooterButton(
              label: 'PLAY AGAIN',
              onPressed: onPlayAgain,
              isPrimary: true,
              isLoading: uiState.isNewImageLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFFff5c00) : const Color(0xFF16181d),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              bottom: BorderSide(
                color: isPrimary ? const Color(0xFF8B3000) : Colors.black,
                width: 4,
              ),
            ),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class PuzzleLoadingScreen extends ConsumerWidget {
  const PuzzleLoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(puzzleProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00d4ff), Color(0xFF00a8cc)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00d4ff).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Loading Puzzle...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00d4ff),
            ),
          ),
          const SizedBox(height: 8),
          const Text('🇹🇳', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Grid: ${gameState.gridSize}×${gameState.gridSize}',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
