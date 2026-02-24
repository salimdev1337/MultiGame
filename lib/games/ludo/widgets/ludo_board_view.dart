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
import 'ludo_board_painter.dart';
import 'ludo_bomb_indicator.dart';
import 'ludo_dice_widget.dart';
import 'ludo_hud.dart';
import 'ludo_token_widget.dart';

class LudoDiceDisplay extends StatelessWidget {
  const LudoDiceDisplay({
    super.key,
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

class LudoBoardView extends ConsumerStatefulWidget {
  const LudoBoardView({super.key, required this.is3D, required this.isDark});

  final bool is3D;
  final bool isDark;

  @override
  ConsumerState<LudoBoardView> createState() => _LudoBoardViewState();
}

class _LudoBoardViewState extends ConsumerState<LudoBoardView> {
  bool _showDice = false;
  bool _diceRolling = false;

  String? _animKey;
  final _animCoordNotifier = ValueNotifier<(double, double)?>(null);
  List<(double, double)> _animPath = const [];
  int _animStep = 0;
  Timer? _animTimer;

  @override
  void dispose() {
    _animTimer?.cancel();
    _animCoordNotifier.dispose();
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
        // Mount the fresh widget at the token's current (pre-move) position so
        // the first arc travels FROM here TO path[0], not a bounce in place.
        final oldCoord = tokenGridCoord(prevToken, prevPlayer.color);
        _animCoordNotifier.value = (oldCoord.$1.toDouble(), oldCoord.$2.toDouble());
        setState(() {});
        // After the widget mounts at oldCoord, update to path[0] — the position
        // change triggers didUpdateWidget → hop arc fires automatically.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _animCoordNotifier.value = path[0];
          }
        });
        _startHopTimer();
        return;
      }
    }
  }

  void _startHopTimer() {
    _animTimer = Timer.periodic(const Duration(milliseconds: 290), (t) {
      _animStep++;
      if (_animStep >= _animPath.length) {
        t.cancel();
        _animCoordNotifier.value = null;
        if (mounted) {
          setState(() {
            _animKey = null;
            _animPath = const [];
            _animStep = 0;
          });
        }
        return;
      }
      _animCoordNotifier.value = _animPath[_animStep];
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

  static Color _bombPlayerColor(LudoPlayerColor c) => switch (c) {
        LudoPlayerColor.red    => DSColors.ludoPlayerRed,
        LudoPlayerColor.green  => DSColors.ludoPlayerGreen,
        LudoPlayerColor.blue   => DSColors.ludoPlayerBlue,
        LudoPlayerColor.yellow => DSColors.ludoPlayerYellow,
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
        child: LudoBombIndicator(
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

    if (isAnimating) {
      final c = tokenGridCoord(token, player.color);
      final staticCoord = (c.$1.toDouble(), c.$2.toDouble());
      return [
        ValueListenableBuilder<(double, double)?>(
          valueListenable: _animCoordNotifier,
          builder: (_, animCoord, child) {
            final coord = animCoord ?? staticCoord;
            return LudoTokenWidget(
              key: ValueKey('${widgetKey}_anim'),
              token: token,
              cellSize: cell,
              col: coord.$1,
              row: coord.$2,
              isSelected: isSelected,
              isMovable: false,
              subCellOffsetX: 0,
              subCellOffsetY: 0,
              hopOnMove: true,
              onTap: onTap,
            );
          },
        ),
      ];
    }

    final c = tokenGridCoord(token, player.color);
    final coord = (c.$1.toDouble(), c.$2.toDouble());
    double dx = 0;
    double dy = 0;
    final group = groups[coord];
    if (group != null) {
      final idx = group.indexWhere(
        (e) => e.token.id == token.id && e.player.color == player.color,
      );
      (dx, dy) = _stackOffset(idx < 0 ? 0 : idx, group.length, cell);
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
        onTap: onTap,
      ),
    ];
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
    final normalDiceValue = ref.watch(ludoProvider.select((s) => s.normalDiceValue));
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
            ? computeMovableTokenIds(
                currentPlayer,
                diceValue,
                players,
                mode: mode,
                normalDice: normalDiceValue > 0 ? normalDiceValue : null,
              )
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
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(boardSize, boardSize),
                    painter: LudoBoardPainter(isDark: widget.isDark),
                  ),
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
                        child: LudoDiceDisplay(
                          diceValue: normalDiceValue > 0
                              ? normalDiceValue
                              : (diceValue > 0 ? diceValue : 1),
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
            LudoHud(
              phase: phase,
              currentPlayer: currentPlayer,
              onRoll: () => ref.read(ludoProvider.notifier).rollDice(),
            ),
          ],
        );
      },
    );
  }
}
