// Online game screen - see docs/SUDOKU_ARCHITECTURE.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/providers/services_providers.dart';
import '../providers/sudoku_online_provider.dart';
import '../models/connection_state.dart' as sudoku;
import '../widgets/sudoku_grid.dart';
import '../widgets/number_pad.dart';
import '../widgets/control_buttons.dart';
import 'sudoku_online_result_screen.dart';

const _backgroundDark = Color(0xFF0f1115);
const _surfaceDark = Color(0xFF1a1d24);
const _accentBlue = Color(0xFF3b82f6);
const _accentGreen = Color(0xFF4ade80);

class SudokuOnlineGameScreen extends ConsumerStatefulWidget {
  const SudokuOnlineGameScreen({super.key});

  @override
  ConsumerState<SudokuOnlineGameScreen> createState() =>
      _SudokuOnlineGameScreenState();
}

class _SudokuOnlineGameScreenState
    extends ConsumerState<SudokuOnlineGameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sudokuOnlineProvider).addListener(_checkCompletion);
    });
  }

  void _checkCompletion() {
    final provider = ref.read(sudokuOnlineProvider);
    if (provider.isCompleted && mounted) {
      provider.removeListener(_checkCompletion);

      // The current ProviderScope already has the override — navigate inside it
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProviderScope(
            overrides: [sudokuOnlineProvider.overrideWith((ref) => provider)],
            child: const SudokuOnlineResultScreen(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    ref.read(sudokuOnlineProvider).removeListener(_checkCompletion);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(sudokuOnlineProvider);

    return Scaffold(
      backgroundColor: _backgroundDark,
      body: SafeArea(
        child: provider.board == null
            ? _buildWaitingUI(provider)
            : LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      _buildHeader(context, provider),
                      _buildOpponentBar(provider),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: SudokuGrid(
                            board: provider.board!,
                            selectedRow: provider.selectedRow,
                            selectedCol: provider.selectedCol,
                            onCellTap: provider.selectCell,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ControlButtons(
                        notesMode: provider.notesMode,
                        canUndo: provider.canUndo,
                        canErase:
                            provider.selectedRow != null &&
                            provider.selectedCol != null,
                        hintsRemaining: provider.hintsRemaining,
                        onUndo: provider.canUndo
                            ? () => provider.undo()
                            : () {},
                        onErase:
                            provider.selectedRow != null &&
                                provider.selectedCol != null
                            ? () => provider.clearCell()
                            : () {},
                        onToggleNotes: provider.toggleNotesMode,
                        onHint: provider.canUseHint
                            ? () => _useHint(context, provider)
                            : () {},
                      ),
                      const SizedBox(height: 8),
                      NumberPad(
                        board: provider.board!,
                        onNumberTap: (number) => provider.placeNumber(number),
                        useCompactMode: constraints.maxHeight < 700,
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SudokuOnlineProvider provider) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _showLeaveDialog(context, provider),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ONLINE 1v1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildConnectionDot(provider.connectionState),
                  ],
                ),
                Text(
                  _formatTime(provider.elapsedSeconds),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6 * 255),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildOpponentBar(SudokuOnlineProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: provider.opponentCompleted
              ? _accentGreen
              : _accentBlue.withValues(alpha: 0.3 * 255),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            provider.opponentCompleted ? Icons.check_circle : Icons.person,
            color: provider.opponentCompleted ? _accentGreen : _accentBlue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildConnectionDot(provider.opponentConnectionState),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.opponentName ?? 'Waiting for opponent...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (provider.hasOpponent)
                  Row(
                    children: [
                      Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.red.withValues(alpha: 0.8 * 255),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.opponentMistakes}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6 * 255),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.lightbulb_outline,
                        size: 14,
                        color: Colors.amber.withValues(alpha: 0.8 * 255),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.opponentHintsUsed}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6 * 255),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        provider.opponentCompleted
                            ? 'Completed!'
                            : '${provider.opponentProgress ?? 0}/81',
                        style: TextStyle(
                          color: provider.opponentCompleted
                              ? _accentGreen
                              : Colors.white.withValues(alpha: 0.6 * 255),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Waiting...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4 * 255),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (provider.hasOpponent && !provider.opponentCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accentBlue.withValues(alpha: 0.15 * 255),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${((provider.opponentProgress ?? 0) / 81 * 100).round()}%',
                style: const TextStyle(
                  color: _accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWaitingUI(SudokuOnlineProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _accentBlue),
          const SizedBox(height: 24),
          Text(
            provider.isWaiting ? 'WAITING FOR OPPONENT' : 'LOADING GAME',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            provider.isWaiting
                ? 'Please wait while we find you an opponent...'
                : 'Setting up the game...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6 * 255),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await provider.leaveMatch();
              navigator.pop();
            },
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLeaveDialog(
    BuildContext context,
    SudokuOnlineProvider provider,
  ) async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceDark,
        title: const Text(
          'Leave Match?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to leave? This will count as a forfeit.',
          style: TextStyle(color: Color(0x99FFFFFF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('STAY'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('LEAVE'),
          ),
        ],
      ),
    );

    if (shouldLeave == true && context.mounted) {
      await provider.leaveMatch();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildConnectionDot(sudoku.ConnectionState state) {
    final Color dotColor;
    final String tooltip;

    switch (state) {
      case sudoku.ConnectionState.online:
        dotColor = _accentGreen;
        tooltip = 'Online';
        break;
      case sudoku.ConnectionState.offline:
        dotColor = Colors.red;
        tooltip = 'Offline';
        break;
      case sudoku.ConnectionState.reconnecting:
        dotColor = Colors.orange;
        tooltip = 'Reconnecting';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: dotColor.withValues(alpha: 0.5 * 255),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useHint(
    BuildContext context,
    SudokuOnlineProvider provider,
  ) async {
    try {
      await provider.useHint();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
