import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:multigame/utils/navigation_utils.dart';
import 'package:multigame/widgets/shared/game_result_widget.dart';

import '../logic/wordle_evaluator.dart';
import '../models/wordle_enums.dart';
import '../models/wordle_game_state.dart';
import '../providers/wordle_notifier.dart';
import 'wordle_board_widget.dart';
import 'wordle_keyboard_widget.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBg     = Color(0xFF0D1117);
const _kCard   = Color(0xFF161B22);
const _kBorder = Color(0xFF30363D);
const _kCyan   = Color(0xFF58A6FF);
const _kGreen  = Color(0xFF3FB950);

class WordleGamePage extends ConsumerStatefulWidget {
  const WordleGamePage({super.key});

  @override
  ConsumerState<WordleGamePage> createState() => _WordleGamePageState();
}

class _WordleGamePageState extends ConsumerState<WordleGamePage> {
  bool _resultShowing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<WordleGameState>(wordleProvider, (prev, next) {
      if (next.phase == WordlePhase.matchEnd && !_resultShowing) {
        _resultShowing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showResultDialog(next);
          }
        });
      }
    });

    final phase = ref.watch(wordleProvider.select((s) => s.phase));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmQuit();
        }
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(phase),
        body: phase == WordlePhase.idle
            ? const _IdleScreen()
            : const _GameBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(WordlePhase phase) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: BoxDecoration(
          color: _kBg,
          border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white70, size: 18),
                  onPressed: phase == WordlePhase.idle
                      ? () => NavigationUtils.goHome(context)
                      : _confirmQuit,
                ),
                // Round pill (only in game)
                if (phase != WordlePhase.idle)
                  _RoundPill(),
                const Spacer(),
                // WORD CLASH gradient title
                _GradientText(
                  'WORD CLASH',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                // Placeholder to balance layout
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmQuit() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _kBorder),
        ),
        title: const Text('Quit game?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Your progress will be lost.',
            style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Stay', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              NavigationUtils.goHome(context);
            },
            child: const Text('Quit', style: TextStyle(color: _kCyan)),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(WordleGameState s) {
    final notifier = ref.read(wordleProvider.notifier);
    final iWon = s.matchWinnerId == s.myPlayerId;
    final isDraw = s.matchWinnerId == null;

    final title = isDraw ? "IT'S A TIE!" : iWon ? 'VICTORY!' : 'DEFEAT';

    GameResultWidget.show(
      context,
      GameResultConfig(
        isVictory: iWon,
        title: title,
        icon: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: iWon
                ? const [_kCyan, _kGreen]
                : isDraw
                    ? [Colors.amber.shade300, Colors.amber.shade600]
                    : [Colors.red.shade400, Colors.red.shade700],
          ).createShader(bounds),
          child: Icon(
            iWon
                ? Icons.emoji_events_rounded
                : isDraw
                    ? Icons.handshake_rounded
                    : Icons.sentiment_dissatisfied_rounded,
            size: 60,
            color: Colors.white,
          ),
        ),
        accentColor: iWon ? _kGreen : isDraw ? Colors.amber : Colors.red,
        accentGradient: iWon
            ? const [_kCyan, _kGreen]
            : isDraw
                ? [Colors.amber.shade300, Colors.amber.shade600]
                : [Colors.red.shade400, Colors.red.shade700],
        stats: [
          GameResultStat('Your Score', '${s.myScore} / $kWordleRounds'),
          if (!s.isSolo)
            GameResultStat('Opponent', '${s.opponentScore} / $kWordleRounds'),
          GameResultStat('Rounds Played', '${s.roundIndex + 1}'),
        ],
        statsLayout: GameResultStatsLayout.cards,
        statCardValueFontSize: 26,
        statCardSpacing: 10,
        primary: GameResultAction(
          label: 'Play Again',
          onTap: () {
            Navigator.of(context).pop();
            _resultShowing = false;
            notifier.startSolo();
          },
        ),
        secondary: GameResultAction(
          label: 'Home',
          onTap: () {
            Navigator.of(context).pop();
            _resultShowing = false;
            NavigationUtils.goHome(context);
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

// ── Round pill ────────────────────────────────────────────────────────────────

class _RoundPill extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roundIndex =
        ref.watch(wordleProvider.select((s) => s.roundIndex));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Text(
        'ROUND ${roundIndex + 1}/$kWordleRounds',
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── Idle screen ───────────────────────────────────────────────────────────────

class _IdleScreen extends ConsumerWidget {
  const _IdleScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(wordleProvider.notifier);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GradientText(
              'WORD\nCLASH',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '5 ROUNDS · FIRST TO 3 WINS',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 11,
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 56),
            _ActionButton(
              label: 'SOLO',
              subtitle: 'Solve 5 words on your own',
              gradient: const [Color(0xFF0099CC), _kCyan],
              icon: Icons.person,
              onTap: notifier.startSolo,
            ),
            const SizedBox(height: 14),
            _ActionButton(
              label: 'MULTIPLAYER',
              subtitle: 'Challenge a friend over WiFi',
              gradient: const [Color(0xFF6B21A8), Color(0xFF8B5CF6)],
              icon: Icons.people_alt_rounded,
              onTap: () => context.go(AppRoutes.wordleLobby),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final List<Color> gradient;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Game body ─────────────────────────────────────────────────────────────────

class _GameBody extends ConsumerWidget {
  const _GameBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(wordleProvider.select((s) => s.phase));
    final isSolo = ref.watch(wordleProvider.select((s) => s.isSolo));

    return Stack(
      children: [
        Column(
          children: [
            const _ScoreBar(),
            if (!isSolo) const _OpponentIndicator(),
            const Expanded(child: _BoardArea()),
            const _KeyboardArea(),
            const SizedBox(height: 8),
          ],
        ),
        if (phase == WordlePhase.countdown) const _CountdownOverlay(),
        if (phase == WordlePhase.roundEnd) const _RoundEndOverlay(),
      ],
    );
  }
}

// ── Score bar ─────────────────────────────────────────────────────────────────

class _ScoreBar extends ConsumerWidget {
  const _ScoreBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(wordleProvider.select(
      (s) => (
        myScore: s.myScore,
        opponentScore: s.opponentScore,
        isSolo: s.isSolo,
        opponentName: s.opponentName,
      ),
    ));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ScorePill(
            label: 'YOU',
            score: s.myScore,
            color: _kGreen,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorder),
            ),
            child: Text(
              s.isSolo ? 'SOLO MODE' : 'VS',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          if (!s.isSolo)
            _ScorePill(
              label: s.opponentName ?? 'OPPONENT',
              score: s.opponentScore,
              color: _kCyan,
            )
          else
            const SizedBox(width: 64),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$score',
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label.length > 8 ? '${label.substring(0, 8)}…' : label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ── Opponent indicator ────────────────────────────────────────────────────────

class _OpponentIndicator extends ConsumerWidget {
  const _OpponentIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempts =
        ref.watch(wordleProvider.select((s) => s.opponentAttemptsUsed ?? 0));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Text(
            'OPP  ',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          ...List.generate(kWordleMaxGuesses, (i) {
            return Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: i < attempts
                    ? _kCyan.withValues(alpha: 0.6)
                    : Colors.transparent,
                border: Border.all(
                  color: i < attempts ? _kCyan : _kBorder,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Board area ────────────────────────────────────────────────────────────────

class _BoardArea extends ConsumerWidget {
  const _BoardArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(wordleProvider.select((s) => (
          myRound: s.myRound,
          currentInput: s.currentInput,
          invalidWordMessage: s.invalidWordMessage,
        )));

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (s.invalidWordMessage != null)
            AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 150),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  s.invalidWordMessage!,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          WordleBoardWidget(
            round: s.myRound,
            currentInput: s.currentInput,
            shake: s.invalidWordMessage != null,
          ),
        ],
      ),
    );
  }
}

// ── Keyboard area ─────────────────────────────────────────────────────────────

class _KeyboardArea extends ConsumerWidget {
  const _KeyboardArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guesses = ref.watch(wordleProvider.select(
      (s) => s.myRound.guesses
          .map((g) => (word: g.word, evaluation: g.evaluation))
          .toList(),
    ));

    final letterStates = computeKeyboardState(guesses);
    final notifier = ref.read(wordleProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: WordleKeyboard(
        letterStates: letterStates,
        onKey: notifier.typeKey,
        onEnter: notifier.submitGuess,
        onDelete: notifier.deleteLast,
      ),
    );
  }
}

// ── Countdown overlay ─────────────────────────────────────────────────────────

class _CountdownOverlay extends ConsumerWidget {
  const _CountdownOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value =
        ref.watch(wordleProvider.select((s) => s.countdownValue ?? 3));
    return Container(
      color: _kBg.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_kCyan, _kGreen],
              ).createShader(bounds),
              child: Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'GET READY',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 13,
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Round end overlay ─────────────────────────────────────────────────────────

class _RoundEndOverlay extends ConsumerWidget {
  const _RoundEndOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(wordleProvider.select((s) => (
          revealedWord: s.revealedWord ?? '',
          roundWinnerId: s.roundWinnerId,
          roundIndex: s.roundIndex,
          myPlayerId: s.myPlayerId,
          isSolo: s.isSolo,
          myRound: s.myRound,
          myScore: s.myScore,
          opponentScore: s.opponentScore,
          opponentName: s.opponentName,
        )));

    final iWon = s.roundWinnerId == s.myPlayerId;
    final isDraw = s.roundWinnerId == null;

    String winnerLabel;
    if (s.isSolo) {
      winnerLabel = s.myRound.isSolved
          ? 'Solved in ${s.myRound.attemptsUsed}!'
          : 'Better luck next time';
    } else if (isDraw) {
      winnerLabel = 'No winner this round';
    } else {
      winnerLabel = iWon ? 'You won!' : '${s.opponentName ?? "Opponent"} won';
    }

    return Container(
      color: _kBg.withValues(alpha: 0.97),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: _kGreen.withValues(alpha: 0.6)),
                ),
                child: Text(
                  'ROUND ${s.roundIndex + 1} COMPLETE',
                  style: const TextStyle(
                    color: _kGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // "The word was"
              const Text(
                'THE WORD WAS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Word tiles (all green, decorative)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: s.revealedWord.toUpperCase().split('').map((ch) {
                  return Container(
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF538D4E),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF538D4E).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        ch,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Winner banner
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isDraw || s.isSolo) ...[
                    Icon(
                      s.isSolo
                          ? (s.myRound.isSolved
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded)
                          : Icons.emoji_events_rounded,
                      color: (iWon || (s.isSolo && s.myRound.isSolved))
                          ? _kGreen
                          : Colors.white38,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    winnerLabel,
                    style: TextStyle(
                      color: (iWon || (s.isSolo && s.myRound.isSolved))
                          ? Colors.white
                          : Colors.white54,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              if (!s.isSolo) ...[
                const SizedBox(height: 20),
                // Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundScoreChip(score: s.myScore, label: 'YOU', color: _kGreen),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '—',
                        style: TextStyle(color: Colors.white24, fontSize: 20),
                      ),
                    ),
                    _RoundScoreChip(
                      score: s.opponentScore,
                      label: s.opponentName ?? 'OPP',
                      color: _kCyan,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundScoreChip extends StatelessWidget {
  const _RoundScoreChip({
    required this.score,
    required this.label,
    required this.color,
  });

  final int score;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$score',
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label.length > 6 ? '${label.substring(0, 6)}…' : label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── _GradientText ─────────────────────────────────────────────────────────────

class _GradientText extends StatelessWidget {
  const _GradientText(
    this.text, {
    required this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [_kCyan, _kGreen],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}
