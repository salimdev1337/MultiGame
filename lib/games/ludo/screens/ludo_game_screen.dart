import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../logic/ludo_logic.dart';
import '../logic/ludo_path.dart';
import '../models/ludo_enums.dart';
import '../models/ludo_player.dart';
import '../models/ludo_token.dart';
import '../providers/ludo_notifier.dart';
import '../widgets/ludo_board_painter.dart';
import '../widgets/ludo_token_widget.dart';

class LudoGamePage extends ConsumerWidget {
  const LudoGamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(ludoProvider.select((s) => s.phase));

    return Scaffold(
      backgroundColor: DSColors.surface,
      body: SafeArea(
        child: switch (phase) {
          LudoPhase.idle => const _LudoModeSelector(),
          _ => const _LudoGameBody(),
        },
      ),
    );
  }
}

// ── Mode selector ─────────────────────────────────────────────────────────

class _LudoModeSelector extends ConsumerStatefulWidget {
  const _LudoModeSelector();

  @override
  ConsumerState<_LudoModeSelector> createState() => _LudoModeSelectorState();
}

class _LudoModeSelectorState extends ConsumerState<_LudoModeSelector> {
  LudoDifficulty _difficulty = LudoDifficulty.medium;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Ludo',
            style: DSTypography.displayMedium.copyWith(
              color: DSColors.ludoPrimary,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Race tokens home — roll, capture, and use powerups!',
            style: DSTypography.bodyMedium.copyWith(color: DSColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Difficulty selector (only relevant for solo mode)
          Text(
            'Bot Difficulty',
            style: DSTypography.labelLarge.copyWith(color: DSColors.textPrimary),
          ),
          const SizedBox(height: 8),
          _DifficultyRow(
            selected: _difficulty,
            onChanged: (d) => setState(() => _difficulty = d),
          ),
          const SizedBox(height: 32),

          // Mode buttons
          _ModeButton(
            label: 'Solo vs Bots',
            icon: Icons.smart_toy_rounded,
            color: DSColors.ludoPrimary,
            onTap: () => ref.read(ludoProvider.notifier).startSolo(_difficulty),
          ),
          const SizedBox(height: 12),
          _ModeButton(
            label: 'Free-for-All (3 Players)',
            icon: Icons.group_rounded,
            color: DSColors.ludoAccent,
            onTap: () => ref
                .read(ludoProvider.notifier)
                .startFreeForAll(playerCount: 3),
          ),
          const SizedBox(height: 12),
          _ModeButton(
            label: 'Free-for-All (4 Players)',
            icon: Icons.groups_rounded,
            color: DSColors.ludoAccent,
            onTap: () => ref
                .read(ludoProvider.notifier)
                .startFreeForAll(playerCount: 4),
          ),
          const SizedBox(height: 12),
          _ModeButton(
            label: '2v2 Teams',
            icon: Icons.people_alt_rounded,
            color: DSColors.connectFourPrimary,
            onTap: () =>
                ref.read(ludoProvider.notifier).startTeamVsTeam(),
          ),
        ],
      ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.selected, required this.onChanged});

  final LudoDifficulty selected;
  final ValueChanged<LudoDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: LudoDifficulty.values.map((d) {
        final isActive = d == selected;
        final label = switch (d) {
          LudoDifficulty.easy => 'Easy',
          LudoDifficulty.medium => 'Medium',
          LudoDifficulty.hard => 'Hard',
        };
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(d),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? DSColors.ludoPrimary : DSColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? DSColors.ludoPrimary
                        : DSColors.surfaceHighlight,
                  ),
                ),
                child: Text(
                  label,
                  style: DSTypography.labelMedium.copyWith(
                    color: isActive ? Colors.white : DSColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, Colors.black, 0.2)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: DSTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Game body ─────────────────────────────────────────────────────────────

class _LudoGameBody extends ConsumerWidget {
  const _LudoGameBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(ludoProvider.select((s) => s.phase));

    if (phase == LudoPhase.won) {
      return const _WonScreen();
    }

    return Column(
      children: [
        _LudoAppBar(),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _LudoBoardView()),
              _LudoHud(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── AppBar ─────────────────────────────────────────────────────────────────

class _LudoAppBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: DSColors.textPrimary,
            onPressed: () => _confirmExit(context, ref),
          ),
          Expanded(
            child: Text(
              'Ludo',
              style: DSTypography.titleLarge.copyWith(
                color: DSColors.ludoPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // balance the back button
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quit Game?'),
        content: const Text('Your current game will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quit'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(ludoProvider.notifier).goToIdle();
      }
    });
  }
}

// ── Board ─────────────────────────────────────────────────────────────────

class _LudoBoardView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(ludoProvider.select((s) => s.players));
    final selectedId = ref.watch(ludoProvider.select((s) => s.selectedTokenId));
    final diceValue = ref.watch(ludoProvider.select((s) => s.diceValue));
    final phase = ref.watch(ludoProvider.select((s) => s.phase));
    final currentPlayer = ref.watch(
      ludoProvider.select((s) => s.players.isEmpty ? null : s.currentPlayer),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth.clamp(0.0, constraints.maxHeight);
        final cell = boardSize / 15;

        // Compute movable token IDs for the current player.
        final movable = (phase == LudoPhase.selectingToken && currentPlayer != null)
            ? computeMovableTokenIds(currentPlayer, diceValue, players)
            : <int>[];

        return Center(
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Stack(
              children: [
                // Static board.
                CustomPaint(
                  size: Size(boardSize, boardSize),
                  painter: const LudoBoardPainter(),
                ),
                // Tokens.
                for (final player in players)
                  for (final token in player.tokens)
                    ..._buildTokenWidgets(
                      token: token,
                      player: player,
                      cell: cell,
                      isSelected: selectedId == token.id &&
                          currentPlayer?.color == player.color,
                      isMovable: currentPlayer?.color == player.color &&
                          movable.contains(token.id),
                      onTap: () {
                        if (currentPlayer?.color == player.color) {
                          ref.read(ludoProvider.notifier).selectToken(token.id);
                        }
                      },
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTokenWidgets({
    required LudoToken token,
    required LudoPlayer player,
    required double cell,
    required bool isSelected,
    required bool isMovable,
    required VoidCallback onTap,
  }) {
    final coord = tokenGridCoord(token, player.color);
    return [
      LudoTokenWidget(
        key: ValueKey('${player.color.name}_${token.id}'),
        token: token,
        cellSize: cell,
        col: coord.$1,
        row: coord.$2,
        isSelected: isSelected,
        isMovable: isMovable,
        onTap: onTap,
      ),
    ];
  }
}

// ── HUD ───────────────────────────────────────────────────────────────────

class _LudoHud extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: DSColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CurrentPlayerBadge(),
          const SizedBox(height: 12),
          _DiceArea(),
          const SizedBox(height: 8),
          _PowerupTray(),
        ],
      ),
    );
  }
}

/// Isolated widget — only rebuilds when currentPlayer changes.
class _CurrentPlayerBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(
      ludoProvider.select((s) => s.players.isEmpty ? null : s.currentPlayer),
    );
    if (player == null) {
      return const SizedBox.shrink();
    }
    final colorMap = {
      LudoPlayerColor.red: const Color(0xFFE53935),
      LudoPlayerColor.blue: const Color(0xFF2196F3),
      LudoPlayerColor.green: const Color(0xFF43A047),
      LudoPlayerColor.yellow: const Color(0xFFFFD700),
    };
    final color = colorMap[player.color]!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(backgroundColor: color, radius: 8),
        const SizedBox(width: 8),
        Text(
          player.isBot ? '${player.name} is thinking…' : "${player.name}'s turn",
          style: DSTypography.labelLarge.copyWith(color: DSColors.textPrimary),
        ),
      ],
    );
  }
}

/// Isolated widget — only rebuilds when diceValue + phase change.
class _DiceArea extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dice = ref.watch(ludoProvider.select((s) => s.diceValue));
    final phase = ref.watch(ludoProvider.select((s) => s.phase));
    final isHumanTurn = ref.watch(
      ludoProvider.select(
        (s) => s.players.isNotEmpty && !s.currentPlayer.isBot,
      ),
    );
    final canRoll = phase == LudoPhase.rolling && isHumanTurn;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (dice > 0)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: DSColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DSColors.surfaceHighlight),
            ),
            child: Center(
              child: Text(
                '$dice',
                style: DSTypography.displaySmall.copyWith(
                  color: DSColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        if (dice > 0) const SizedBox(width: 16),
        if (canRoll)
          ElevatedButton.icon(
            onPressed: () => ref.read(ludoProvider.notifier).rollDice(),
            icon: const Icon(Icons.casino_rounded),
            label: const Text('Roll'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DSColors.ludoPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else if (phase == LudoPhase.selectingToken)
          Text(
            'Select a token to move',
            style: DSTypography.labelMedium.copyWith(color: DSColors.textSecondary),
          ),
      ],
    );
  }
}

/// Powerup tray for the current human player.
class _PowerupTray extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(
      ludoProvider.select((s) {
        if (s.players.isEmpty) {
          return null;
        }
        final cp = s.currentPlayer;
        return cp.isBot ? null : cp;
      }),
    );
    if (player == null || player.powerups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      children: player.powerups.map((p) {
        return ActionChip(
          label: Text(_powerupLabel(p)),
          avatar: Icon(_powerupIcon(p), size: 16),
          onPressed: () =>
              ref.read(ludoProvider.notifier).activatePowerup(p),
        );
      }).toList(),
    );
  }

  String _powerupLabel(LudoPowerupType p) {
    switch (p) {
      case LudoPowerupType.shield:
        return 'Shield';
      case LudoPowerupType.doubleStep:
        return '×2 Step';
      case LudoPowerupType.freeze:
        return 'Freeze';
      case LudoPowerupType.recall:
        return 'Recall';
      case LudoPowerupType.luckyRoll:
        return 'Lucky';
    }
  }

  IconData _powerupIcon(LudoPowerupType p) {
    switch (p) {
      case LudoPowerupType.shield:
        return Icons.shield_rounded;
      case LudoPowerupType.doubleStep:
        return Icons.fast_forward_rounded;
      case LudoPowerupType.freeze:
        return Icons.ac_unit_rounded;
      case LudoPowerupType.recall:
        return Icons.undo_rounded;
      case LudoPowerupType.luckyRoll:
        return Icons.star_rounded;
    }
  }
}

// ── Won screen ─────────────────────────────────────────────────────────────

class _WonScreen extends ConsumerWidget {
  const _WonScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(ludoProvider.select((s) => s.players));
    final mode = ref.watch(ludoProvider.select((s) => s.mode));

    // Find winner(s).
    final finished = players.where((p) => p.hasWon).toList()
      ..sort((a, b) => a.finishPosition.compareTo(b.finishPosition));

    final winnerName = finished.isNotEmpty ? finished.first.name : 'Someone';

    final title = mode == LudoMode.twoVsTwo
        ? 'Team ${finished.isNotEmpty ? (finished.first.teamIndex == 0 ? "Red & Green" : "Blue & Yellow") : "?"} Wins!'
        : '$winnerName Wins!';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 72, color: Color(0xFFFFD700)),
            const SizedBox(height: 16),
            Text(
              title,
              style: DSTypography.displaySmall.copyWith(
                color: DSColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                final s = ref.read(ludoProvider);
                switch (s.mode) {
                  case LudoMode.soloVsBots:
                    ref.read(ludoProvider.notifier).startSolo(s.difficulty);
                  case LudoMode.freeForAll3:
                    ref.read(ludoProvider.notifier).startFreeForAll(playerCount: 3);
                  case LudoMode.freeForAll4:
                    ref.read(ludoProvider.notifier).startFreeForAll(playerCount: 4);
                  case LudoMode.twoVsTwo:
                    ref.read(ludoProvider.notifier).startTeamVsTeam();
                }
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Play Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DSColors.ludoPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ref.read(ludoProvider.notifier).goToIdle(),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Main Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
