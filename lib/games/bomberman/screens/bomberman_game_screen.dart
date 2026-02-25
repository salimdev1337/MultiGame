import 'dart:math' show cos, sin, pi;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:multigame/games/bomberman/logic/bot_ai.dart';
import 'package:multigame/utils/navigation_utils.dart';
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
              NavigationUtils.goHome(context);
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
                        // Return button — top-left corner of board
                        Positioned(
                          top: 6,
                          left: 6,
                          child: _ReturnButton(onTap: _showQuitConfirmation),
                        ),
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

              // Controls — analog stick on mobile/web, keyboard hint on desktop
              if (_useTouchControls(context))
                _TouchControls(
                  onInput: (dx, dy) =>
                      ref.read(bombermanProvider.notifier).setInput(dx: dx, dy: dy),
                  onRelease: () =>
                      ref.read(bombermanProvider.notifier).setInput(),
                  onBomb: () =>
                      ref.read(bombermanProvider.notifier).pressPlaceBomb(),
                )
              else
                const _DesktopHint(),
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
              onPressed: () => NavigationUtils.goHome(context),
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

// ─── Platform helper ──────────────────────────────────────────────────────────

bool _useTouchControls(BuildContext context) {
  if (kIsWeb) {
    return true;
  }
  final p = Theme.of(context).platform;
  return p == TargetPlatform.android || p == TargetPlatform.iOS;
}

// ─── Touch controls (mobile + web) ───────────────────────────────────────────

class _TouchControls extends StatelessWidget {
  final void Function(double dx, double dy) onInput;
  final VoidCallback onRelease;
  final VoidCallback onBomb;

  const _TouchControls({
    required this.onInput,
    required this.onRelease,
    required this.onBomb,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF070910),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Analog joystick ───────────────────────────────────────────────
          _AnalogStick(onInput: onInput, onRelease: onRelease),

          // ── BOMB button ───────────────────────────────────────────────────
          _BombBtn(onBomb: onBomb),
        ],
      ),
    );
  }
}

// ─── Analog joystick ──────────────────────────────────────────────────────────

class _AnalogStick extends StatefulWidget {
  final void Function(double dx, double dy) onInput;
  final VoidCallback onRelease;

  const _AnalogStick({required this.onInput, required this.onRelease});

  @override
  State<_AnalogStick> createState() => _AnalogStickState();
}

class _AnalogStickState extends State<_AnalogStick> {
  // Knob offset from the stick centre (canvas coords, clamped to base radius)
  Offset _knob = Offset.zero;

  static const double _baseR = 58.0; // outer ring radius
  static const double _knobR = 24.0; // draggable thumb radius
  static const double _size = (_baseR + _knobR) * 2;

  Offset get _centre => const Offset(_size / 2, _size / 2);

  void _update(Offset localPos) {
    final delta = localPos - _centre;
    final dist = delta.distance;
    final clamped = dist > _baseR ? delta / dist * _baseR : delta;
    setState(() => _knob = clamped);
    widget.onInput(
      (clamped.dx / _baseR).clamp(-1.0, 1.0),
      (clamped.dy / _baseR).clamp(-1.0, 1.0),
    );
  }

  void _reset() {
    setState(() => _knob = Offset.zero);
    widget.onRelease();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: SizedBox(
        width: _size,
        height: _size,
        child: CustomPaint(
          painter: _JoystickPainter(knob: _knob, baseR: _baseR, knobR: _knobR),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset knob;
  final double baseR;
  final double knobR;

  const _JoystickPainter({
    required this.knob,
    required this.baseR,
    required this.knobR,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final active = knob != Offset.zero;

    // ── Outer ring ────────────────────────────────────────────────────────
    canvas.drawCircle(
      c,
      baseR,
      Paint()..color = const Color(0x1AFFFFFF), // fill — very subtle
    );
    canvas.drawCircle(
      c,
      baseR,
      Paint()
        ..color = active
            ? const Color(0x66FFFFFF)
            : const Color(0x33FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── Cardinal tick marks (subtle orientation guides) ───────────────────
    const tickLen = 6.0;
    final tickPaint = Paint()
      ..color = const Color(0x26FFFFFF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final angle in [0.0, pi / 2, pi, 3 * pi / 2]) {
      final outer = c + Offset(baseR * cos(angle), baseR * sin(angle));
      final inner = c + Offset((baseR - tickLen) * cos(angle), (baseR - tickLen) * sin(angle));
      canvas.drawLine(inner, outer, tickPaint);
    }

    // ── Knob shadow ───────────────────────────────────────────────────────
    canvas.drawCircle(
      c + knob + const Offset(0, 2),
      knobR,
      Paint()..color = const Color(0x33000000),
    );

    // ── Knob body ─────────────────────────────────────────────────────────
    canvas.drawCircle(
      c + knob,
      knobR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            active ? const Color(0xFF475569) : const Color(0xFF334155),
            const Color(0xFF1e293b),
          ],
          stops: const [0.0, 1.0],
        ).createShader(
          Rect.fromCircle(center: c + knob, radius: knobR),
        ),
    );

    // Knob rim highlight
    canvas.drawCircle(
      c + knob,
      knobR,
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner dot
    canvas.drawCircle(
      c + knob,
      knobR * 0.28,
      Paint()..color = const Color(0x80FFFFFF),
    );
  }

  @override
  bool shouldRepaint(_JoystickPainter old) => old.knob != knob;
}

// ─── Bomb button (stateful for press feedback) ────────────────────────────────

class _BombBtn extends StatefulWidget {
  final VoidCallback onBomb;

  const _BombBtn({required this.onBomb});

  @override
  State<_BombBtn> createState() => _BombBtnState();
}

class _BombBtnState extends State<_BombBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        setState(() => _pressed = true);
        widget.onBomb();
      },
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed ? const Color(0xFF991b1b) : const Color(0xFFdc2626),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFdc2626).withValues(alpha: _pressed ? 0.3 : 0.55),
              blurRadius: _pressed ? 8 : 16,
              spreadRadius: _pressed ? 0 : 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'BOMB',
            style: TextStyle(
              color: Colors.white.withValues(alpha: _pressed ? 0.75 : 1.0),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Desktop keyboard hint ────────────────────────────────────────────────────

class _DesktopHint extends StatelessWidget {
  const _DesktopHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF070910),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 24,
        children: [
          _KeyHint(keys: const ['W', 'A', 'S', 'D'], label: 'Move'),
          _KeyHint(keys: const ['↑', '↓', '←', '→'], label: 'Move'),
          _KeyHint(keys: const ['Space', 'X'], label: 'Bomb'),
        ],
      ),
    );
  }
}

class _KeyHint extends StatelessWidget {
  final List<String> keys;
  final String label;

  const _KeyHint({required this.keys, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        ...keys.map(
          (k) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1e293b),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Text(
              k,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ─── Return button ────────────────────────────────────────────────────────────

class _ReturnButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ReturnButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xCC070910),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white70,
          size: 16,
        ),
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

