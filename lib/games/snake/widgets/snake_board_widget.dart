import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/snake/providers/snake_notifier.dart';
import 'package:multigame/games/snake/widgets/snake_animations.dart';
import 'package:multigame/games/snake/widgets/snake_board_painter.dart';

/// Renders the snake game board at 60 FPS using a single [CustomPaint].
///
/// A [Ticker] drives a linear interpolation factor [_t] (0.0 → 1.0) between
/// consecutive game ticks, so the snake segments glide smoothly rather than
/// snapping one cell at a time.  The game logic still runs at the original
/// 5–8 Hz tick rate; only the canvas repaint rate increases to 60 FPS.
class SnakeBoardWidget extends ConsumerStatefulWidget {
  const SnakeBoardWidget({super.key});

  @override
  ConsumerState<SnakeBoardWidget> createState() => _SnakeBoardWidgetState();
}

class _SnakeBoardWidgetState extends ConsumerState<SnakeBoardWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  /// Interpolation progress through the current game tick (0.0 = tick just
  /// fired, 1.0 = fully at current position).
  double _t = 1.0;

  /// The [SnakeState.lastTickUs] value of the last observed game tick.
  int _lastTickUs = 0;

  /// Ticker elapsed (ms) captured at the moment the latest game tick landed.
  int _tickerMsAtGameTick = 0;

  /// Running ticker elapsed (ms), updated every frame.
  int _tickerMs = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    _tickerMs = elapsed.inMilliseconds;
    final state = ref.read(snakeProvider);

    if (!state.playing || state.lastTickUs == 0) {
      // Game idle — hold segments at their final position.
      if (_t != 1.0) setState(() => _t = 1.0);
      return;
    }

    // Detect a new game tick by comparing stored timestamp.
    if (state.lastTickUs != _lastTickUs) {
      _lastTickUs = state.lastTickUs;
      _tickerMsAtGameTick = _tickerMs;
    }

    final tickDurationMs = state.tickRate.inMilliseconds.toDouble();
    final elapsed2 = _tickerMs - _tickerMsAtGameTick;
    final newT = (elapsed2 / tickDurationMs).clamp(0.0, 1.0);

    if ((newT - _t).abs() > 0.005) {
      setState(() => _t = newT);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Select only the fields the painter needs — avoids rebuilding on unrelated
    // state changes (score, playing, etc.).
    final board = ref.watch(
      snakeProvider.select(
        (s) => (
          prev: s.previousSnake,
          curr: s.snake,
          food: s.food,
          foodEaten: s.foodEaten,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / SnakeState.gridSize;

        // Pixel-space centre of the food cell — needed by FoodCollectionBurst.
        final foodPx = Offset(
          board.food.dx * cellW + cellW / 2,
          board.food.dy * cellW + cellW / 2,
        );

        return Stack(
          children: [
            // Primary canvas — snake + food drawn at 60 FPS.
            Positioned.fill(
              child: CustomPaint(
                painter: SnakeBoardPainter(
                  previousSnake: board.prev,
                  currentSnake: board.curr,
                  food: board.food,
                  t: _t,
                  gridSize: SnakeState.gridSize,
                ),
              ),
            ),

            // Food particle burst — fires once per food collection.
            FoodCollectionBurst(
              position: foodPx,
              show: board.foodEaten,
              color: const Color(0xFF00C2FF),
            ),
          ],
        );
      },
    );
  }
}
