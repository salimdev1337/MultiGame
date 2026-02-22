import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../logic/ludo_logic.dart';
import '../logic/ludo_path.dart';
import '../models/ludo_enums.dart';
import '../models/ludo_game_state.dart';
import '../models/ludo_player.dart';
import '../models/ludo_token.dart';
import '../providers/ludo_notifier.dart';
import '../widgets/ludo_board_painter.dart';
import '../widgets/ludo_dice_widget.dart';
import '../widgets/ludo_token_widget.dart';

// ── Dice display (normal + optional magic die) ────────────────────────────

class _DiceDisplay extends StatelessWidget {
  const _DiceDisplay({
    required this.diceValue,
    required this.rolling,
    required this.playerColor,
    required this.magicFace,
    required this.diceMode,
    required this.cellSize,
  });

  final int diceValue;
  final bool rolling;
  final LudoPlayerColor? playerColor;
  final MagicDiceFace? magicFace;
  final LudoDiceMode diceMode;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final dieSize = cellSize * 2.5;
    final normalDie = LudoDiceWidget(
      value: diceValue,
      rolling: rolling,
      playerColor: playerColor,
      size: dieSize,
    );

    if (diceMode != LudoDiceMode.magic || magicFace == null) {
      return normalDie;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        normalDie,
        SizedBox(width: cellSize * 0.4),
        LudoMagicDiceWidget(
          face: magicFace!,
          rolling: rolling,
          size: dieSize,
        ),
      ],
    );
  }
}

// ── Wildcard value picker ──────────────────────────────────────────────────

class _WildcardPicker extends ConsumerWidget {
  const _WildcardPicker({required this.currentPlayer, required this.onRoll});

  final LudoPlayer? currentPlayer;
  final VoidCallback onRoll;

  static Color _playerColor(LudoPlayerColor c) => switch (c) {
        LudoPlayerColor.red    => const Color(0xFFE53935),
        LudoPlayerColor.green  => const Color(0xFF43A047),
        LudoPlayerColor.blue   => const Color(0xFF2979FF),
        LudoPlayerColor.yellow => const Color(0xFFFFD600),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consecutiveSixes = ref.watch(
      ludoProvider.select(
        (s) => s.players.isEmpty ? 0 : s.currentPlayer.consecutiveSixes,
      ),
    );
    final canUse6 = consecutiveSixes < 2;
    final c = currentPlayer != null
        ? _playerColor(currentPlayer!.color)
        : DSColors.ludoPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Wildcard — Pick your dice value',
            style: DSTypography.labelMedium.copyWith(
              color: DSColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final v = i + 1;
              final blocked = v == 6 && !canUse6;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: blocked
                      ? null
                      : () => ref
                            .read(ludoProvider.notifier)
                            .selectWildcardValue(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: blocked
                          ? const Color(0xFF1A1A2E)
                          : c.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: blocked
                            ? const Color(0xFF252545)
                            : c,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$v',
                        style: DSTypography.titleMedium.copyWith(
                          color: blocked ? DSColors.textSecondary : c,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Shared token dot decoration ───────────────────────────────────────────

Widget _tokenDot(Color color) {
  return Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.6),
          blurRadius: 8,
        ),
      ],
    ),
  );
}

class LudoGamePage extends ConsumerWidget {
  const LudoGamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(ludoProvider.select((s) => s.phase));

    return Scaffold(
      backgroundColor: const Color(0xFF090912),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF090912), Color(0xFF14142A)],
          ),
        ),
        child: SafeArea(
          child: switch (phase) {
            LudoPhase.idle => const _LudoModeSelector(),
            _ => const _LudoGameBody(),
          },
        ),
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
  LudoDiceMode _diceMode = LudoDiceMode.classic;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Center(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFFD700),
                  Color(0xFFFF6B6B),
                  Color(0xFFE91E63),
                ],
              ).createShader(bounds),
              child: Text(
                'LUDO',
                style: DSTypography.displayMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tokenDot(const Color(0xFFE53935)),
              const SizedBox(width: 6),
              _tokenDot(const Color(0xFF2979FF)),
              const SizedBox(width: 6),
              _tokenDot(const Color(0xFF43A047)),
              const SizedBox(width: 6),
              _tokenDot(const Color(0xFFFFD600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Race tokens home — roll, capture, and use powerups!',
            style: DSTypography.bodyMedium.copyWith(color: DSColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Bot Difficulty section
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                color: DSColors.ludoPrimary,
              ),
              Text(
                'Bot Difficulty',
                style: DSTypography.labelLarge.copyWith(
                  color: DSColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DifficultyRow(
            selected: _difficulty,
            onChanged: (d) => setState(() => _difficulty = d),
          ),
          const SizedBox(height: 24),

          // Dice Mode section
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                color: DSColors.ludoPrimary,
              ),
              Text(
                'Dice Mode',
                style: DSTypography.labelLarge.copyWith(
                  color: DSColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DiceModeRow(
            selected: _diceMode,
            onChanged: (m) => setState(() => _diceMode = m),
          ),
          const SizedBox(height: 32),

          // Mode buttons
          _ModeButton(
            label: 'Solo vs Bots',
            icon: Icons.smart_toy_rounded,
            color: DSColors.ludoPrimary,
            onTap: () => ref
                .read(ludoProvider.notifier)
                .startSolo(_difficulty, diceMode: _diceMode),
          ),
          const SizedBox(height: 12),
          _ModeButton(
            label: 'Free-for-All (3 Players)',
            icon: Icons.group_rounded,
            color: DSColors.ludoAccent,
            onTap: () => ref
                .read(ludoProvider.notifier)
                .startFreeForAll(playerCount: 3, diceMode: _diceMode),
          ),
          const SizedBox(height: 12),
          _ModeButton(
            label: 'Free-for-All (4 Players)',
            icon: Icons.groups_rounded,
            color: DSColors.ludoAccent,
            onTap: () => ref
                .read(ludoProvider.notifier)
                .startFreeForAll(playerCount: 4, diceMode: _diceMode),
          ),
          const SizedBox(height: 12),
          _ModeButton(
            label: '2v2 Teams',
            icon: Icons.people_alt_rounded,
            color: DSColors.connectFourPrimary,
            onTap: () => ref
                .read(ludoProvider.notifier)
                .startTeamVsTeam(diceMode: _diceMode),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? DSColors.ludoPrimary
                      : const Color(0xFF1A1A30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? DSColors.ludoPrimary
                        : const Color(0xFF252545),
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

class _DiceModeRow extends StatelessWidget {
  const _DiceModeRow({required this.selected, required this.onChanged});

  final LudoDiceMode selected;
  final ValueChanged<LudoDiceMode> onChanged;

  @override
  Widget build(BuildContext context) {
    const magicColor = Color(0xFF9C27B0);
    return Row(
      children: LudoDiceMode.values.map((m) {
        final isActive = m == selected;
        final label = m == LudoDiceMode.classic ? 'Classic Dice' : 'Magic Dice';
        final activeColor =
            m == LudoDiceMode.magic ? magicColor : DSColors.ludoPrimary;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? activeColor : const Color(0xFF1A1A30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive ? activeColor : const Color(0xFF252545),
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
            colors: [
              Color.lerp(color, Colors.white, 0.12)!,
              color,
              Color.lerp(color, Colors.black, 0.20)!,
            ],
            stops: const [0.0, 0.3, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
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
            Expanded(
              child: Text(
                label,
                style: DSTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white60,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Game body ─────────────────────────────────────────────────────────────

class _LudoGameBody extends ConsumerStatefulWidget {
  const _LudoGameBody();

  @override
  ConsumerState<_LudoGameBody> createState() => _LudoGameBodyState();
}

class _LudoGameBodyState extends ConsumerState<_LudoGameBody> {
  bool _is3D = false;
  bool _isDark = true;

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(ludoProvider.select((s) => s.phase));

    if (phase == LudoPhase.won) {
      return const _WonScreen();
    }

    return Stack(
      children: [
        Column(
          children: [
            _LudoAppBar(
              is3D: _is3D,
              onToggle3D: () => setState(() => _is3D = !_is3D),
              isDark: _isDark,
              onToggleDark: () => setState(() => _isDark = !_isDark),
            ),
            Expanded(child: _LudoBoardView(is3D: _is3D, isDark: _isDark)),
          ],
        ),
        const _TurboOvershootListener(),
      ],
    );
  }
}

// ── AppBar ─────────────────────────────────────────────────────────────────

class _LudoAppBar extends ConsumerWidget {
  const _LudoAppBar({
    required this.is3D,
    required this.onToggle3D,
    required this.isDark,
    required this.onToggleDark,
  });

  final bool is3D;
  final VoidCallback onToggle3D;
  final bool isDark;
  final VoidCallback onToggleDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diceMode = ref.watch(ludoProvider.select((s) => s.diceMode));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: DSColors.textPrimary,
                onPressed: () => _confirmExit(context, ref),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ludo',
                      style: DSTypography.titleLarge.copyWith(
                        color: DSColors.ludoPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (diceMode == LudoDiceMode.magic) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'MAGIC',
                          style: DSTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
                color: DSColors.textPrimary,
                tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                onPressed: onToggleDark,
              ),
              IconButton(
                icon: Icon(
                  is3D ? Icons.view_in_ar_rounded : Icons.grid_on_rounded,
                ),
                color: DSColors.textPrimary,
                tooltip: is3D ? '2D View' : '3D View',
                onPressed: onToggle3D,
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                DSColors.ludoPrimary.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmExit(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quit Game?'),
        content: const Text('Your current game will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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

class _LudoBoardView extends ConsumerStatefulWidget {
  const _LudoBoardView({required this.is3D, required this.isDark});

  final bool is3D;
  final bool isDark;

  @override
  ConsumerState<_LudoBoardView> createState() => _LudoBoardViewState();
}

class _LudoBoardViewState extends ConsumerState<_LudoBoardView> {
  bool _showDice = false;
  bool _diceRolling = false;

  // ── Token hop animation ─────────────────────────────────────────────────
  String? _animKey;
  (double, double)? _animCoord;
  List<(double, double)> _animPath = const [];
  int _animStep = 0;
  int _hopTrigger = 0;
  Timer? _animTimer;

  @override
  void dispose() {
    _animTimer?.cancel();
    super.dispose();
  }

  void _onPlayersChanged(
    List<LudoPlayer> prev,
    List<LudoPlayer> next,
  ) {
    for (final prevPlayer in prev) {
      final nextPlayer = next.firstWhere(
        (p) => p.color == prevPlayer.color,
        orElse: () => prevPlayer,
      );
      for (final prevToken in prevPlayer.tokens) {
        final nextToken = nextPlayer.tokens.firstWhere(
          (t) => t.id == prevToken.id,
          orElse: () => prevToken,
        );
        final moved = prevToken.trackPosition != nextToken.trackPosition ||
            prevToken.homeColumnStep != nextToken.homeColumnStep ||
            prevToken.isFinished != nextToken.isFinished;
        final movedToBase = !prevToken.isInBase && nextToken.isInBase;
        if (!moved || movedToBase) {
          continue;
        }
        final mode = ref.read(ludoProvider.select((s) => s.mode));
        final path = computeTokenHopPath(prevToken, nextToken, prevPlayer.color, mode: mode);
        if (path.isEmpty) {
          continue;
        }
        _animTimer?.cancel();
        _animKey = '${prevPlayer.color.name}_${prevToken.id}';
        _animPath = path;
        _animStep = 0;
        _hopTrigger++;
        _animCoord = path[0];
        setState(() {});
        _startHopTimer();
        return;
      }
    }
  }

  void _startHopTimer() {
    _animTimer = Timer.periodic(const Duration(milliseconds: 140), (t) {
      _animStep++;
      if (_animStep >= _animPath.length) {
        t.cancel();
        if (mounted) {
          setState(() {
            _animKey = null;
            _animCoord = null;
            _animPath = const [];
            _animStep = 0;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _animCoord = _animPath[_animStep];
          _hopTrigger++;
        });
      }
    });
  }

  (double dx, double dy) _stackOffset(int idx, int total, double cell) {
    if (total <= 1) {
      return (0.0, 0.0);
    }
    final s = cell * 0.22;
    if (total == 2) {
      return idx == 0 ? (-s, 0.0) : (s, 0.0);
    }
    if (total == 3) {
      final offsets = [(-s, s * 0.5), (s, s * 0.5), (0.0, -s * 0.7)];
      return offsets[idx];
    }
    return (idx % 2 == 0 ? -s : s, idx < 2 ? -s : s);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      ludoProvider.select((s) => s.players),
      (prev, next) {
        if (prev != null && prev != next) {
          _onPlayersChanged(prev, next);
        }
      },
    );

    ref.listen(
      ludoProvider.select((s) => s.diceValue),
      (prev, next) {
        if (next > 0 && next != (prev ?? 0)) {
          setState(() {
            _showDice = true;
            _diceRolling = true;
          });
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) {
              setState(() => _diceRolling = false);
            }
          });
        } else if (next == 0) {
          if (mounted) {
            setState(() => _showDice = false);
          }
        }
      },
    );

    final players = ref.watch(ludoProvider.select((s) => s.players));
    final selectedId = ref.watch(ludoProvider.select((s) => s.selectedTokenId));
    final diceValue = ref.watch(ludoProvider.select((s) => s.diceValue));
    final phase = ref.watch(ludoProvider.select((s) => s.phase));
    final mode = ref.watch(ludoProvider.select((s) => s.mode));
    final activeBombs = ref.watch(ludoProvider.select((s) => s.activeBombs));
    final currentPlayer = ref.watch(
      ludoProvider.select((s) => s.players.isEmpty ? null : s.currentPlayer),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth.clamp(0.0, constraints.maxHeight);
        final cell = boardSize / 15;

        final movable = (phase == LudoPhase.selectingToken && currentPlayer != null)
            ? computeMovableTokenIds(currentPlayer, diceValue, players, mode: mode)
            : <int>[];

        final Map<(double, double), List<({LudoToken token, LudoPlayer player})>>
            groups = {};
        for (final player in players) {
          for (final token in player.tokens) {
            final c = tokenGridCoord(token, player.color);
            final coord = (c.$1.toDouble(), c.$2.toDouble());
            groups.putIfAbsent(coord, () => []).add(
              (token: token, player: player),
            );
          }
        }

        final boardStack = Center(
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(boardSize, boardSize),
                  painter: LudoBoardPainter(isDark: widget.isDark),
                ),
                for (final player in players)
                  for (final token in player.tokens)
                    ..._buildTokenWidgets(
                      token: token,
                      player: player,
                      cell: cell,
                      groups: groups,
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
                for (final bomb in activeBombs)
                  _buildBombWidget(bomb: bomb, cell: cell),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _showDice ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Center(
                        child: _DiceDisplay(
                          diceValue: diceValue > 0 ? diceValue : 1,
                          rolling: _diceRolling,
                          playerColor: ref.watch(
                            ludoProvider.select((s) => s.diceRollerColor),
                          ),
                          magicFace: ref.watch(
                            ludoProvider.select((s) => s.magicDiceFace),
                          ),
                          diceMode: ref.watch(
                            ludoProvider.select((s) => s.diceMode),
                          ),
                          cellSize: cell,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final boardWidget = TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: widget.is3D ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          builder: (context, t, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015 * t)
                ..rotateX(-0.45 * t),
              alignment: Alignment.center,
              child: child,
            );
          },
          child: boardStack,
        );

        return Column(
          children: [
            Expanded(child: boardWidget),
            _LudoHud(
              phase: phase,
              currentPlayer: currentPlayer,
              onRoll: () => ref.read(ludoProvider.notifier).rollDice(),
            ),
          ],
        );
      },
    );
  }

  static Color _bombPlayerColor(LudoPlayerColor c) => switch (c) {
        LudoPlayerColor.red    => const Color(0xFFE53935),
        LudoPlayerColor.green  => const Color(0xFF43A047),
        LudoPlayerColor.blue   => const Color(0xFF2979FF),
        LudoPlayerColor.yellow => const Color(0xFFFFD600),
      };

  Widget _buildBombWidget({
    required LudoBomb bomb,
    required double cell,
  }) {
    final c = kTrackCoords[bomb.trackPosition]!;
    final (double col, double row) = (c.$1.toDouble(), c.$2.toDouble());
    final size = cell * 0.6;
    final left = col * cell + (cell - size) / 2;
    final top  = row * cell + (cell - size) / 2;
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: _BombIndicator(
          color: _bombPlayerColor(bomb.placedBy),
          size: size,
          turnsLeft: bomb.turnsLeft,
        ),
      ),
    );
  }

  List<Widget> _buildTokenWidgets({
    required LudoToken token,
    required LudoPlayer player,
    required double cell,
    required Map<(double, double), List<({LudoToken token, LudoPlayer player})>> groups,
    required bool isSelected,
    required bool isMovable,
    required VoidCallback onTap,
  }) {
    final widgetKey = '${player.color.name}_${token.id}';
    final isAnimating = _animKey == widgetKey;

    final (double, double) coord;
    double dx = 0;
    double dy = 0;

    if (isAnimating && _animCoord != null) {
      coord = _animCoord!;
    } else {
      final c = tokenGridCoord(token, player.color);
      coord = (c.$1.toDouble(), c.$2.toDouble());
      final group = groups[coord];
      if (group != null) {
        final idx = group.indexWhere(
          (e) => e.token.id == token.id && e.player.color == player.color,
        );
        (dx, dy) = _stackOffset(idx < 0 ? 0 : idx, group.length, cell);
      }
    }

    return [
      LudoTokenWidget(
        key: ValueKey(widgetKey),
        token: token,
        cellSize: cell,
        col: coord.$1,
        row: coord.$2,
        isSelected: isSelected,
        isMovable: isMovable,
        subCellOffsetX: dx,
        subCellOffsetY: dy,
        hopTrigger: isAnimating ? _hopTrigger : 0,
        instantMove: isAnimating,
        onTap: onTap,
      ),
    ];
  }
}

// ── Bottom HUD ─────────────────────────────────────────────────────────────

class _LudoHud extends StatelessWidget {
  const _LudoHud({
    required this.phase,
    required this.currentPlayer,
    required this.onRoll,
  });

  final LudoPhase phase;
  final LudoPlayer? currentPlayer;
  final VoidCallback onRoll;

  static Color _playerColor(LudoPlayerColor c) => switch (c) {
        LudoPlayerColor.red    => const Color(0xFFE53935),
        LudoPlayerColor.green  => const Color(0xFF43A047),
        LudoPlayerColor.blue   => const Color(0xFF2979FF),
        LudoPlayerColor.yellow => const Color(0xFFFFD600),
      };

  @override
  Widget build(BuildContext context) {
    if (phase == LudoPhase.rolling && currentPlayer != null && !currentPlayer!.isBot) {
      final c = _playerColor(currentPlayer!.color);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14),
                border: Border(left: BorderSide(color: c, width: 3)),
                boxShadow: [
                  BoxShadow(
                    color: c.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentPlayer!.name,
                        style: DSTypography.labelMedium.copyWith(
                          color: DSColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Your turn',
                        style: DSTypography.labelSmall.copyWith(
                          color: DSColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onRoll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      c,
                      Color.lerp(c, const Color(0xFF000000), 0.25)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.casino_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Roll Dice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (phase == LudoPhase.rolling && currentPlayer != null && currentPlayer!.isBot) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF252545)),
            ),
            child: Text(
              'Bot is thinking...',
              style: DSTypography.bodyMedium.copyWith(
                color: DSColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    if (phase == LudoPhase.selectingToken) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF252545)),
            ),
            child: Text(
              'Tap a highlighted token to move',
              style: DSTypography.bodyMedium.copyWith(
                color: DSColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    if (phase == LudoPhase.selectingWildcard) {
      return _WildcardPicker(currentPlayer: currentPlayer, onRoll: onRoll);
    }

    return const SizedBox(height: 20);
  }
}

// ── Won screen ─────────────────────────────────────────────────────────────

class _WonScreen extends ConsumerWidget {
  const _WonScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(ludoProvider.select((s) => s.players));
    final mode = ref.watch(ludoProvider.select((s) => s.mode));

    final finished = players.where((p) => p.hasWon).toList()
      ..sort((a, b) => a.finishPosition.compareTo(b.finishPosition));

    final winnerName = finished.isNotEmpty ? finished.first.name : 'Someone';

    final title = mode == LudoMode.twoVsTwo
        ? 'Team ${finished.isNotEmpty ? (finished.first.teamIndex == 0 ? "Red & Green" : "Blue & Yellow") : "?"} Wins!'
        : '$winnerName Wins!';

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            DSColors.ludoPrimary.withValues(alpha: 0.10),
            const Color(0xFF0D0D1A),
          ],
          radius: 1.0,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy section
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'WINNER',
                style: DSTypography.labelSmall.copyWith(
                  color: DSColors.ludoPrimary,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFFFD700),
                    Color(0xFFFF6B6B),
                    Color(0xFFFFD700),
                  ],
                ).createShader(bounds),
                child: Text(
                  title,
                  style: DSTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _tokenDot(const Color(0xFFE53935)),
                  const SizedBox(width: 6),
                  _tokenDot(const Color(0xFF2979FF)),
                  const SizedBox(width: 6),
                  _tokenDot(const Color(0xFF43A047)),
                  const SizedBox(width: 6),
                  _tokenDot(const Color(0xFFFFD600)),
                ],
              ),
              const SizedBox(height: 32),

              // Play Again button
              GestureDetector(
                onTap: () {
                  final s = ref.read(ludoProvider);
                  switch (s.mode) {
                    case LudoMode.soloVsBots:
                      ref
                          .read(ludoProvider.notifier)
                          .startSolo(s.difficulty, diceMode: s.diceMode);
                    case LudoMode.freeForAll3:
                      ref
                          .read(ludoProvider.notifier)
                          .startFreeForAll(playerCount: 3, diceMode: s.diceMode);
                    case LudoMode.freeForAll4:
                      ref
                          .read(ludoProvider.notifier)
                          .startFreeForAll(playerCount: 4, diceMode: s.diceMode);
                    case LudoMode.twoVsTwo:
                      ref
                          .read(ludoProvider.notifier)
                          .startTeamVsTeam(diceMode: s.diceMode);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DSColors.ludoPrimary,
                        Color.lerp(
                          DSColors.ludoPrimary,
                          Colors.black,
                          0.20,
                        )!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DSColors.ludoPrimary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.replay_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Play Again',
                        style: DSTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () => ref.read(ludoProvider.notifier).goToIdle(),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Main Menu'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DSColors.ludoPrimary,
                  side: BorderSide(
                    color: DSColors.ludoPrimary.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

// ── Bomb indicator ─────────────────────────────────────────────────────────

class _BombIndicator extends StatefulWidget {
  const _BombIndicator({
    required this.color,
    required this.size,
    required this.turnsLeft,
  });

  final Color color;
  final double size;
  final int turnsLeft;

  @override
  State<_BombIndicator> createState() => _BombIndicatorState();
}

class _BombIndicatorState extends State<_BombIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.25),
          border: Border.all(color: widget.color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.5),
              blurRadius: 6,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.crisis_alert_rounded,
              size: widget.size * 0.55,
              color: widget.color,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: widget.size * 0.38,
                height: widget.size * 0.38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
                child: Center(
                  child: Text(
                    '${widget.turnsLeft}',
                    style: TextStyle(
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Turbo overshoot listener ───────────────────────────────────────────────

/// Watches only [LudoGameState.turboOvershoot] and shows a brief snackbar
/// when turbo causes all tokens to overshoot with no valid move.
class _TurboOvershootListener extends ConsumerWidget {
  const _TurboOvershootListener();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      ludoProvider.select((s) => s.turboOvershoot),
      (_, overshot) {
        if (overshot) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Turbo overshoot — no valid move!'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
    return const SizedBox.shrink();
  }
}
