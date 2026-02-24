import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:multigame/widgets/shared/game_result_widget.dart';

import '../models/memory_game_state.dart';
import '../providers/memory_notifier.dart';
import '../widgets/memory_card_grid.dart';
import '../widgets/memory_hud.dart';
import '../widgets/memory_idle_screen.dart';

const _kP1 = Color(0xFF00E5FF);
const _kP2 = Color(0xFFFF1493);
const _kAccent = Color(0xFF7B2FFF);

class MemoryGamePage extends ConsumerStatefulWidget {
  const MemoryGamePage({super.key});

  @override
  ConsumerState<MemoryGamePage> createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends ConsumerState<MemoryGamePage> {
  bool _resultShowing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<MemoryGameState>(memoryProvider, (prev, next) {
      if (next.phase == MemoryGamePhase.won && !_resultShowing) {
        _resultShowing = true;
        _showWinDialog(next);
      }
    });

    final phase = ref.watch(memoryProvider.select((s) => s.phase));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showQuitConfirmation();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF060612),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A1F),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: _showQuitConfirmation,
          ),
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_kP1, _kAccent],
            ).createShader(bounds),
            child: const Text(
              'MEMORY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                fontSize: 18,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            if (phase != MemoryGamePhase.idle)
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
                onPressed: () {
                  _resultShowing = false;
                  ref.read(memoryProvider.notifier).restart();
                },
              ),
          ],
        ),
        body: phase == MemoryGamePhase.idle
            ? const MemoryIdleScreen()
            : const _GameBody(),
      ),
    );
  }

  void _showQuitConfirmation() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1d24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
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
            child: Text(
              'RESUME',
              style: TextStyle(
                color: _kAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(memoryProvider.notifier).reset();
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

  void _showWinDialog(MemoryGameState s) {
    final notifier = ref.read(memoryProvider.notifier);
    final winner = s.winner;

    final title = winner == -1
        ? "IT'S A TIE!"
        : winner == 0
            ? 'P1 WINS!'
            : 'P2 WINS!';

    final iconEmoji = winner == -1 ? '🤝' : '🏆';
    final accentColor = winner == 0
        ? _kP1
        : winner == 1
            ? _kP2
            : _kAccent;

    GameResultWidget.show(
      context,
      GameResultConfig(
        isVictory: winner != -1,
        title: title,
        icon: Text(iconEmoji, style: const TextStyle(fontSize: 52)),
        accentColor: accentColor,
        accentGradient: winner == 0
            ? const [_kP1, Color(0xFF0099AA)]
            : winner == 1
                ? const [_kP2, Color(0xFFAA0055)]
                : const [_kAccent, Color(0xFF4A00E0)],
        stats: [
          GameResultStat('P1 Score', '${s.playerScores[0]}'),
          GameResultStat('P2 Score', '${s.playerScores[1]}'),
          GameResultStat('Moves', '${s.moves}'),
        ],
        statsLayout: GameResultStatsLayout.cards,
        statCardValueFontSize: 24,
        statCardSpacing: 12,
        primary: GameResultAction(
          label: 'Play Again',
          onTap: () {
            Navigator.of(context).pop();
            _resultShowing = false;
            notifier.restart();
          },
        ),
        secondary: GameResultAction(
          label: 'Home',
          onTap: () {
            Navigator.of(context).pop();
            _resultShowing = false;
            notifier.reset();
            context.go(AppRoutes.home);
          },
          style: GameResultButtonStyle.outline,
        ),
        presentation: GameResultPresentation.dialog,
        backdropBlur: true,
        animated: true,
      ),
    ).then((_) => _resultShowing = false);
  }
}

class _GameBody extends ConsumerWidget {
  const _GameBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficulty = ref.watch(memoryProvider.select((s) => s.difficulty));
    return Container(
      color: const Color(0xFF060612),
      child: Column(
        children: [
          const MemoryTwoPlayerHUD(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: MemoryCardGrid(cols: difficulty.cols, rows: difficulty.rows),
            ),
          ),
        ],
      ),
    );
  }
}
