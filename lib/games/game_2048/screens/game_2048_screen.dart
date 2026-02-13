import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/game_2048/providers/game_2048_notifier.dart';
import 'package:multigame/widgets/shared/game_result_widget.dart';

class Game2048Page extends ConsumerStatefulWidget {
  const Game2048Page({super.key});

  @override
  ConsumerState<Game2048Page> createState() => _Game2048PageState();
}

class _Game2048PageState extends ConsumerState<Game2048Page>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Overlay entry for the milestone banner
  OverlayEntry? _bannerEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _bannerEntry?.remove();
    _bannerEntry = null;
    _animationController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:  _move('left');  break;
      case LogicalKeyboardKey.arrowRight: _move('right'); break;
      case LogicalKeyboardKey.arrowUp:    _move('up');    break;
      case LogicalKeyboardKey.arrowDown:  _move('down');  break;
    }
    return KeyEventResult.handled;
  }

  void _onHorizontalDrag(DragEndDetails details) {
    if (details.primaryVelocity! > 0) {
      _move('right');
    } else if (details.primaryVelocity! < 0) {
      _move('left');
    }
  }

  void _onVerticalDrag(DragEndDetails details) {
    if (details.primaryVelocity! > 0) {
      _move('down');
    } else if (details.primaryVelocity! < 0) {
      _move('up');
    }
  }

  int _tileFontSize(int value) {
    if (value >= 4096) return 16;
    if (value >= 1024) return 20;
    if (value >= 128)  return 24;
    return 28;
  }

  Widget _buildTile(int value) {
    final tileColor = _getTileColor(value);
    final hasGlow = value >= 8 && value != 0;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(
        scale: value != 0 ? 1.0 - (_animationController.value * 0.1) : 1.0,
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: hasGlow
              ? [
                  BoxShadow(
                    color: tileColor.withValues(alpha: (0.4 * 255)),
                    blurRadius: value >= 512 ? 20 : 12,
                    spreadRadius: value >= 512 ? 2 : 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: value != 0
              ? Text(
                  '$value',
                  style: TextStyle(
                    fontSize: _tileFontSize(value).toDouble(),
                    fontWeight: FontWeight.w800,
                    color: _getTextColor(value),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  void _move(String direction) {
    final prevState = ref.read(game2048Provider);
    final moved = ref.read(game2048Provider.notifier).move(direction);

    if (moved) {
      _animationController.forward(from: 0);

      final newState = ref.read(game2048Provider);

      if (newState.gameOver) {
        _showGameOverDialog(newState);
      } else if (newState.highestMilestoneIndex > prevState.highestMilestoneIndex) {
        _showMilestoneBanner(newState.highestMilestoneIndex);
      }
    }
  }

  void _showMilestoneBanner(int milestoneIndex) {
    _bannerEntry?.remove();
    _bannerEntry = null;

    final tile = Game2048State.milestones[milestoneIndex];
    final label = Game2048State.milestoneLabels[milestoneIndex];

    _bannerEntry = OverlayEntry(
      builder: (context) => _MilestoneBanner(
        tile: tile,
        label: label,
        onDismissed: () {
          _bannerEntry?.remove();
          _bannerEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_bannerEntry!);
  }

  Future<void> _showGameOverDialog(Game2048State state) async {
    final notifier = ref.read(game2048Provider.notifier);
    final isNewBest = state.score >= state.bestScore && state.score > 0;

    await notifier.recordGameCompletion();

    if (!mounted) return;

    final highestTile = notifier.getHighestTile();
    final milestoneLabel = state.currentMilestoneLabel;

    GameResultWidget.show(
      context,
      GameResultConfig(
        isVictory: state.highestMilestoneIndex >= 0,
        title: state.highestMilestoneIndex >= 0 ? 'GAME OVER' : 'GAME OVER',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        icon: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: state.highestMilestoneIndex >= 0
                ? const Color(0xFF19e6a2).withValues(alpha: 0.15)
                : const Color(0xFFff6b6b).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(
            state.highestMilestoneIndex >= 0
                ? Icons.workspace_premium_rounded
                : Icons.heart_broken,
            color: state.highestMilestoneIndex >= 0
                ? const Color(0xFF19e6a2)
                : const Color(0xFFff6b6b),
            size: 48,
          ),
        ),
        subtitle: Column(
          children: [
            // Milestone badge
            if (state.highestMilestoneIndex >= 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF19e6a2).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF19e6a2).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '$milestoneLabel · ${state.currentMilestoneTile}',
                  style: const TextStyle(
                    color: Color(0xFF19e6a2),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            // Score line
            Text(
              'Final Score',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${state.score}',
              style: TextStyle(
                color: state.highestMilestoneIndex >= 0
                    ? const Color(0xFF19e6a2)
                    : const Color(0xFFff6b6b),
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            // New best badge
            if (isNewBest) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFf59e0b).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFf59e0b).withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Color(0xFFf59e0b), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'New Best Score!',
                      style: TextStyle(
                        color: Color(0xFFf59e0b),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Highest tile reached
            const SizedBox(height: 8),
            Text(
              'Highest tile: $highestTile',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
        accentColor: state.highestMilestoneIndex >= 0
            ? const Color(0xFF19e6a2)
            : const Color(0xFFff6b6b),
        stats: const [],
        statsLayout: GameResultStatsLayout.cards,
        primary: GameResultAction(
          label: 'PLAY AGAIN',
          icon: Icons.replay,
          style: GameResultButtonStyle.solid,
          color: state.highestMilestoneIndex >= 0
              ? const Color(0xFF19e6a2)
              : const Color(0xFFff6b6b),
          onTap: () {
            Navigator.pop(context);
            notifier.initializeGame();
          },
        ),
        presentation: GameResultPresentation.dialog,
        animated: false,
        containerBorderRadius: 40,
        containerColor: const Color(0xFF1a1e26),
        contentPadding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 340),
      ),
    );
  }

  void _showSettingsDialog() {
    final notifier = ref.read(game2048Provider.notifier);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1e26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              Icons.settings,
              color: const Color(0xFF19e6a2).withValues(alpha: (0.6 * 255)),
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF19e6a2).withValues(alpha: (0.1 * 255)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              title: const Text(
                'Reset Game',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Start a new game',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: (0.6 * 255)),
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                notifier.initializeGame();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF19e6a2)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTileColor(int value) {
    switch (value) {
      case 0:
        return const Color(0xFF101318).withValues(alpha: (0.4 * 255));
      case 2:
        return const Color(0xFF2d343f);
      case 4:
        return const Color(0xFF3e4a5b);
      case 8:
        return const Color(0xFF19e6a2);
      case 16:
        return const Color(0xFF14b8a6);
      case 32:
        return const Color(0xFF0ea5e9);
      case 64:
        return const Color(0xFF6366f1);
      case 128:
        return const Color(0xFFa855f7);
      case 256:
        return const Color(0xFFec4899);
      case 512:
        return const Color(0xFFf43f5e);
      case 1024:
        return const Color(0xFFf97316);
      case 2048:
        return const Color(0xFFeab308);
      case 4096:
        return const Color(0xFFe11d48);
      case 8192:
        return const Color(0xFF7c3aed);
      default:
        return const Color(0xFF19e6a2);
    }
  }

  Color _getTextColor(int value) {
    if (value == 0) return Colors.transparent;
    if (value <= 4) return Colors.white.withValues(alpha: (0.9 * 255));
    return const Color(0xFF101318);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(game2048Provider);

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _handleKeyEvent(event),
      child: Scaffold(
        backgroundColor: const Color(0xFF101318),
        body: SafeArea(
          child: GestureDetector(
            onHorizontalDragEnd: _onHorizontalDrag,
            onVerticalDragEnd: _onVerticalDrag,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: _showSettingsDialog,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a1e26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const Text(
                        '2048 Game',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Stats Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Level / Next milestone card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a1e26),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: (0.2 * 255)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LEVEL',
                                style: TextStyle(
                                  color: Colors.grey.withValues(alpha: (0.7 * 255)),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.stars,
                                    color: Color(0xFF19e6a2),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      state.highestMilestoneIndex >= 0
                                          ? state.currentMilestoneLabel
                                          : '—',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.nextMilestoneTile != null
                                    ? 'Next: ${state.nextMilestoneTile}'
                                    : 'Max reached!',
                                style: TextStyle(
                                  color: Colors.grey.withValues(alpha: 0.55),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Score card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF19e6a2),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF19e6a2)
                                    .withValues(alpha: (0.2 * 255)),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SCORE',
                                style: TextStyle(
                                  color: const Color(0xFF101318)
                                      .withValues(alpha: (0.6 * 255)),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.bolt,
                                    color: Color(0xFF101318),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${state.score}',
                                      style: const TextStyle(
                                        color: Color(0xFF101318),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Combo bonus hint
                              if (state.lastComboBonus > 0)
                                Text(
                                  '+${state.lastComboBonus} combo!',
                                  style: const TextStyle(
                                    color: Color(0xFF101318),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                Text(
                                  'Best: ${state.bestScore}',
                                  style: TextStyle(
                                    color: const Color(0xFF101318)
                                        .withValues(alpha: 0.55),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Game Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1e26),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: 16,
                          itemBuilder: (context, index) {
                            final value = state.grid[index ~/ 4][index % 4];
                            return _buildTile(value);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                // Footer Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF21242b).withValues(alpha: 0.5 * 255),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05 * 255),
                      ),
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
                            label: 'RESET',
                            onPressed: () =>
                                ref.read(game2048Provider.notifier).initializeGame(),
                            isPrimary: false,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildFooterButton(
                            label: 'MAIN MENU',
                            onPressed: () => Navigator.of(context).popUntil(
                              (route) => route.isFirst,
                            ),
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFF19e6a2) : const Color(0xFF16181d),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              bottom: BorderSide(
                color: isPrimary ? const Color(0xFF0a8a61) : Colors.black,
                width: 4,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isPrimary ? const Color(0xFF101318) : Colors.white,
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

/// Slide-in banner shown when a new milestone is reached mid-game.
/// Auto-dismisses after 2.5 seconds without pausing gameplay.
class _MilestoneBanner extends StatefulWidget {
  final int tile;
  final String label;
  final VoidCallback onDismissed;

  const _MilestoneBanner({
    required this.tile,
    required this.label,
    required this.onDismissed,
  });

  @override
  State<_MilestoneBanner> createState() => _MilestoneBannerState();
}

class _MilestoneBannerState extends State<_MilestoneBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _ctrl.reverse().then((_) => widget.onDismissed());
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1e26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF19e6a2).withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF19e6a2).withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.celebration, color: Color(0xFF19e6a2), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Milestone! ',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${widget.label} · ${widget.tile}',
                    style: const TextStyle(
                      color: Color(0xFF19e6a2),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
