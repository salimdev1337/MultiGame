import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:multigame/games/bomberman/logic/bot_ai.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart'
    show kGridW, kGridH;
import 'package:multigame/games/bomberman/models/game_phase.dart';
import 'package:multigame/games/bomberman/providers/bomberman_notifier.dart';
import 'package:multigame/games/bomberman/ui/bomberman_overlays.dart';
import 'package:multigame/games/bomberman/widgets/bomb_grid_painter.dart';
import 'package:multigame/games/bomberman/widgets/bomberman_hud.dart';

class BombermanGamePage extends ConsumerStatefulWidget {
  const BombermanGamePage({super.key});

  @override
  ConsumerState<BombermanGamePage> createState() => _BombermanGamePageState();
}

class _BombermanGamePageState extends ConsumerState<BombermanGamePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final FocusNode _focusNode;

  // ── FPS counter ────────────────────────────────────────────────────────────
  int _fpsCount = 0;
  int _fps = 0;
  DateTime _fpsResetAt = DateTime.now();
  bool _fpsDisposed = false;

  // ── Keyboard: track every held direction key so simultaneous presses don't
  //   fight each other (e.g. holding RIGHT + pressing UP used to cause jitter
  //   because each key's repeat event overwrote the other every tick).
  final _heldKeys = <LogicalKeyboardKey>{};

  static final _moveKeys = {
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyD,
  };

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _focusNode = FocusNode();

    // Persistent frame callback fires on every actual vsync — most reliable
    // way to count render FPS. Self-updates display once per second.
    WidgetsBinding.instance.addPersistentFrameCallback(_countFrame);
  }

  void _countFrame(Duration _) {
    if (_fpsDisposed) return;
    _fpsCount++;
    final now = DateTime.now();
    if (now.difference(_fpsResetAt).inMilliseconds >= 1000) {
      setState(() {
        _fps = _fpsCount;
        _fpsCount = 0;
        _fpsResetAt = now;
      });
    }
  }

  @override
  void dispose() {
    _fpsDisposed = true;
    _anim.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showQuitConfirmation() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1d24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Text(
          'Quit game?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Your progress will be lost.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'RESUME',
              style: TextStyle(
                color: Color(0xFF00d4ff),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.home);
            },
            child: Text(
              'QUIT',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleKey(KeyEvent event) {
    final k = event.logicalKey;
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (_moveKeys.contains(k)) {
        _heldKeys.add(k);
        _flushKeyInput();
      } else if (k == LogicalKeyboardKey.space ||
          k == LogicalKeyboardKey.keyX) {
        ref.read(bombermanProvider.notifier).pressPlaceBomb();
      }
    } else if (event is KeyUpEvent) {
      _heldKeys.remove(k);
      _flushKeyInput();
    }
  }

  /// Derive a single dx/dy from all currently held direction keys and push it.
  /// Horizontal vs vertical is resolved by the notifier's dominant-axis logic,
  /// so just pass the raw sum — it normalises to ±1 on the winning axis.
  void _flushKeyInput() {
    double dx = 0, dy = 0;
    if (_heldKeys.contains(LogicalKeyboardKey.arrowLeft) ||
        _heldKeys.contains(LogicalKeyboardKey.keyA)) {
      dx -= 1;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.arrowRight) ||
        _heldKeys.contains(LogicalKeyboardKey.keyD)) {
      dx += 1;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.arrowUp) ||
        _heldKeys.contains(LogicalKeyboardKey.keyW)) {
      dy -= 1;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.arrowDown) ||
        _heldKeys.contains(LogicalKeyboardKey.keyS)) {
      dy += 1;
    }
    ref.read(bombermanProvider.notifier).setInput(dx: dx, dy: dy);
  }

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(bombermanProvider.select((s) => s.phase));

    if (phase == GamePhase.lobby) {
      return _buildLobbyScreen();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showQuitConfirmation();
        }
      },
      child: KeyboardListener(
        focusNode: _focusNode..requestFocus(),
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF080b14),
        body: SafeArea(
          child: Column(
            children: [
              // HUD — isolated, selects only stats
              const BombermanHud(),

              // Board
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const aspectRatio = kGridW / kGridH;
                    final boardW = constraints.maxWidth;
                    final boardH = constraints.maxHeight;
                    double w = boardW;
                    double h = boardW / aspectRatio;
                    if (h > boardH) {
                      h = boardH;
                      w = boardH * aspectRatio;
                    }

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Blue glowing border around the game grid
                        Container(
                          width: w,
                          height: h,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF3d5afe),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF3d5afe,
                                ).withValues(alpha: 0.5),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: _AnimatedBoard(animController: _anim),
                        ),
                        // Overlay (countdown, round over, game over)
                        const BombermanOverlay(),
                        // Debug FPS counter
                        Positioned(
                          top: 4,
                          right: 8,
                          child: Text(
                            '$_fps fps',
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(blurRadius: 2)],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Controls — D-pad on all platforms
              _MobileControls(
                onUp: () =>
                    ref.read(bombermanProvider.notifier).setInput(dy: -1),
                onDown: () =>
                    ref.read(bombermanProvider.notifier).setInput(dy: 1),
                onLeft: () =>
                    ref.read(bombermanProvider.notifier).setInput(dx: -1),
                onRight: () =>
                    ref.read(bombermanProvider.notifier).setInput(dx: 1),
                onRelease: () =>
                    ref.read(bombermanProvider.notifier).setInput(),
                onBomb: () =>
                    ref.read(bombermanProvider.notifier).pressPlaceBomb(),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildLobbyScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF111520),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_esports_rounded,
              size: 80,
              color: Color(0xFF00d4ff),
            ),
            const SizedBox(height: 24),
            const Text(
              'BOMBERMAN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Solo vs Bot — choose difficulty',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // Local multiplayer entry point
            GestureDetector(
              onTap: () => context.go(AppRoutes.bombermanLobby),
              child: Container(
                width: 260,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFffd700).withValues(alpha: 0.1),
                  border: Border.all(
                    color: const Color(0xFFffd700).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFffd700),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOCAL MULTIPLAYER',
                            style: TextStyle(
                              color: Color(0xFFffd700),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Host or join a WiFi game',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFFffd700),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Difficulty buttons
            _DifficultyButton(
              label: 'EASY',
              subtitle: 'Bot wanders & rarely bombs',
              color: const Color(0xFF19e6a2),
              onTap: () => ref
                  .read(bombermanProvider.notifier)
                  .startSolo(BotDifficulty.easy),
            ),
            const SizedBox(height: 12),
            _DifficultyButton(
              label: 'MEDIUM',
              subtitle: 'Bot chases and places bombs',
              color: const Color(0xFF00d4ff),
              onTap: () => ref
                  .read(bombermanProvider.notifier)
                  .startSolo(BotDifficulty.medium),
            ),
            const SizedBox(height: 12),
            _DifficultyButton(
              label: 'HARD',
              subtitle: 'Aggressive bot — no mercy',
              color: const Color(0xFFff4757),
              onTap: () => ref
                  .read(bombermanProvider.notifier)
                  .startSolo(BotDifficulty.hard),
            ),

            const SizedBox(height: 32),
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text(
                'Back to Home',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated board widget ───────────────────────────────────────────────────

class _AnimatedBoard extends ConsumerWidget {
  final AnimationController animController;

  const _AnimatedBoard({required this.animController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(bombermanProvider);

    return AnimatedBuilder(
      animation: animController,
      builder: (context2, child) {
        return CustomPaint(
          painter: BombGridPainter(
            gameState: gameState,
            animValue: animController.value,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

// ─── Mobile controls ─────────────────────────────────────────────────────────

class _MobileControls extends StatelessWidget {
  final VoidCallback onUp, onDown, onLeft, onRight, onRelease, onBomb;

  const _MobileControls({
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
    required this.onRelease,
    required this.onBomb,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF080b14),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // D-pad — 4 rounded-square buttons in a cross layout
          SizedBox(
            width: 156,
            height: 156,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 52,
                  child: _Btn(Icons.keyboard_arrow_up_rounded, onUp, onRelease),
                ),
                Positioned(
                  top: 52,
                  left: 0,
                  child: _Btn(Icons.keyboard_arrow_left_rounded, onLeft, onRelease),
                ),
                Positioned(
                  top: 52,
                  left: 52,
                  child: _Btn(Icons.keyboard_arrow_down_rounded, onDown, onRelease),
                ),
                Positioned(
                  top: 52,
                  left: 104,
                  child: _Btn(Icons.keyboard_arrow_right_rounded, onRight, onRelease),
                ),
              ],
            ),
          ),

          // Bomb button — orange gradient circle with flame icon + label
          Listener(
            onPointerDown: (_) => onBomb(),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFff6d00), Color(0xFFbf360c)],
                  radius: 0.85,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFff6d00).withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  Text(
                    'BOMB',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
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
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPress;
  final VoidCallback onRelease;

  const _Btn(this.icon, this.onPress, this.onRelease);

  @override
  Widget build(BuildContext context) {
    // Listener keeps the pointer assigned to this widget from pointerDown to
    // pointerUp regardless of finger movement, so onRelease never fires early
    // due to slight wobble (unlike GestureDetector's onTapCancel).
    return Listener(
      onPointerDown: (_) => onPress(),
      onPointerUp: (_) => onRelease(),
      onPointerCancel: (_) => onRelease(),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1e2e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 30),
      ),
    );
  }
}

// ─── Difficulty button ────────────────────────────────────────────────────────

class _DifficultyButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
          ],
        ),
      ),
    );
  }
}

