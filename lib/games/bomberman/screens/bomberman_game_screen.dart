import 'package:flutter/foundation.dart';
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

    return KeyboardListener(
      focusNode: _focusNode..requestFocus(),
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF111520),
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
                        SizedBox(
                          width: w,
                          height: h,
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

              // Controls — joystick on mobile/web, D-pad on desktop
              if (kIsWeb ||
                  defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS)
                _JoystickControls(
                  onMove: (dx, dy) => ref
                      .read(bombermanProvider.notifier)
                      .setInput(dx: dx, dy: dy),
                  onRelease: () =>
                      ref.read(bombermanProvider.notifier).setInput(),
                  onBomb: () =>
                      ref.read(bombermanProvider.notifier).pressPlaceBomb(),
                )
              else
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
      color: const Color(0xFF0d1018),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // D-pad
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 52,
                  child: _Btn(Icons.keyboard_arrow_up, onUp, onRelease),
                ),
                Positioned(
                  top: 52,
                  left: 0,
                  child: _Btn(Icons.keyboard_arrow_left, onLeft, onRelease),
                ),
                Positioned(
                  top: 52,
                  left: 52,
                  child: _Btn(Icons.keyboard_arrow_down, onDown, onRelease),
                ),
                Positioned(
                  top: 52,
                  left: 104,
                  child: _Btn(Icons.keyboard_arrow_right, onRight, onRelease),
                ),
              ],
            ),
          ),

          // Bomb button
          GestureDetector(
            onTap: onBomb,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFff4500).withValues(alpha: 0.15),
                border: Border.all(
                  color: const Color(0xFFff4500).withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.circle,
                color: Color(0xFFff4500),
                size: 32,
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
      onPointerCancel: (_) => onRelease(), // only fires on system interrupts
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
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

// ─── Joystick controls (mobile + web) ────────────────────────────────────────

const _kJoystickOuterR = 72.0;
const _kJoystickInnerR = 28.0;

class _JoystickControls extends StatelessWidget {
  final void Function(double dx, double dy) onMove;
  final VoidCallback onRelease;
  final VoidCallback onBomb;

  const _JoystickControls({
    required this.onMove,
    required this.onRelease,
    required this.onBomb,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0d1018),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Joystick(onMove: onMove, onRelease: onRelease),
          _XBombButton(onBomb: onBomb),
        ],
      ),
    );
  }
}

// ─── Analog joystick ──────────────────────────────────────────────────────────

class _Joystick extends StatefulWidget {
  final void Function(double dx, double dy) onMove;
  final VoidCallback onRelease;

  const _Joystick({required this.onMove, required this.onRelease});

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  Offset _thumb =
      Offset.zero; // pixel offset from centre, clamped to outer radius

  void _update(Offset localPos) {
    const centre = Offset(_kJoystickOuterR, _kJoystickOuterR);
    final delta = localPos - centre;
    final dist = delta.distance;
    final clamped = dist <= _kJoystickOuterR
        ? delta
        : delta / dist * _kJoystickOuterR;
    setState(() => _thumb = clamped);
    widget.onMove(_thumb.dx / _kJoystickOuterR, _thumb.dy / _kJoystickOuterR);
  }

  void _release() {
    setState(() => _thumb = Offset.zero);
    widget.onRelease();
  }

  @override
  Widget build(BuildContext context) {
    const size = _kJoystickOuterR * 2;
    return GestureDetector(
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _release(),
      onPanCancel: _release,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _JoystickPainter(thumb: _thumb)),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset thumb;
  const _JoystickPainter({required this.thumb});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);

    // Outer ring background
    canvas.drawCircle(
      centre,
      _kJoystickOuterR,
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );
    // Outer ring border
    canvas.drawCircle(
      centre,
      _kJoystickOuterR,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Thumb fill
    canvas.drawCircle(
      centre + thumb,
      _kJoystickInnerR,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    // Thumb border (cyan accent)
    canvas.drawCircle(
      centre + thumb,
      _kJoystickInnerR,
      Paint()
        ..color = const Color(0xFF00d4ff).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_JoystickPainter old) => old.thumb != thumb;
}

// ─── X bomb button ────────────────────────────────────────────────────────────

class _XBombButton extends StatelessWidget {
  final VoidCallback onBomb;
  const _XBombButton({required this.onBomb});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onBomb(),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFff4500).withValues(alpha: 0.15),
          border: Border.all(
            color: const Color(0xFFff4500).withValues(alpha: 0.55),
            width: 2,
          ),
        ),
        child: const Center(
          child: Text(
            'X',
            style: TextStyle(
              color: Color(0xFFff4500),
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
