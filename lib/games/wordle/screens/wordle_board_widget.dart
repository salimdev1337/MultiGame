import 'package:flutter/material.dart';

import '../models/wordle_enums.dart';
import '../models/wordle_game_state.dart';
import '../models/wordle_round_state.dart';

/// 6×5 Wordle tile grid for one player's board.
class WordleBoardWidget extends StatelessWidget {
  const WordleBoardWidget({
    super.key,
    required this.round,
    required this.currentInput,
    required this.shake,
  });

  final WordlePlayerRound round;
  final String currentInput;

  /// When true the active row plays a shake animation.
  final bool shake;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(kWordleMaxGuesses, (row) {
        if (row < round.guesses.length) {
          // Submitted row — animate tiles
          return _SubmittedRow(
            key: ValueKey('row-$row-${round.guesses[row].word}'),
            guess: round.guesses[row],
            rowIndex: row,
          );
        } else if (row == round.guesses.length && !round.isFinished) {
          // Active input row
          return _ActiveRow(
            input: currentInput,
            shake: shake,
          );
        } else {
          // Empty future row
          return _EmptyRow();
        }
      }),
    );
  }
}

// ── Submitted row ─────────────────────────────────────────────────────────────

class _SubmittedRow extends StatefulWidget {
  const _SubmittedRow({
    super.key,
    required this.guess,
    required this.rowIndex,
  });

  final WordleGuess guess;
  final int rowIndex;

  @override
  State<_SubmittedRow> createState() => _SubmittedRowState();
}

class _SubmittedRowState extends State<_SubmittedRow>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _flips;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      kWordleWordLength,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    _flips = _controllers
        .map((c) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    // Stagger tile flips by 80 ms per column
    for (var i = 0; i < kWordleWordLength; i++) {
      Future.delayed(Duration(milliseconds: 80 * i), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(kWordleWordLength, (i) {
          return AnimatedBuilder(
            animation: _flips[i],
            builder: (context, _) {
              final t = _flips[i].value;
              // First half: face-down (blank) → second half: face-up (coloured)
              final showFront = t >= 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX((showFront ? (t - 0.5) : (0.5 - t)) * 3.14159),
                child: _Tile(
                  letter: widget.guess.word[i].toUpperCase(),
                  state: showFront
                      ? widget.guess.evaluation[i]
                      : TileState.empty,
                  submitted: showFront,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ── Active input row ──────────────────────────────────────────────────────────

class _ActiveRow extends StatefulWidget {
  const _ActiveRow({required this.input, required this.shake});

  final String input;
  final bool shake;

  @override
  State<_ActiveRow> createState() => _ActiveRowState();
}

class _ActiveRowState extends State<_ActiveRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_ActiveRow old) {
    super.didUpdateWidget(old);
    if (widget.shake && !old.shake) {
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) =>
          Transform.translate(offset: Offset(_shakeAnim.value, 0), child: child),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(kWordleWordLength, (i) {
            final letter = i < widget.input.length ? widget.input[i] : '';
            return _Tile(
              letter: letter,
              state: TileState.empty,
              submitted: false,
            );
          }),
        ),
      ),
    );
  }
}

// ── Empty row ─────────────────────────────────────────────────────────────────

class _EmptyRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          kWordleWordLength,
          (_) => const _Tile(letter: '', state: TileState.empty, submitted: false),
        ),
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  const _Tile({
    required this.letter,
    required this.state,
    required this.submitted,
  });

  final String letter;
  final TileState state;
  final bool submitted;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        border: submitted ? null : Border.all(color: _borderColor, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }

  Color get _bgColor {
    switch (state) {
      case TileState.correct:
        return const Color(0xFF538D4E);
      case TileState.present:
        return const Color(0xFFB59F3B);
      case TileState.absent:
        return const Color(0xFF3A3A3C);
      case TileState.empty:
        return Colors.transparent;
    }
  }

  Color get _borderColor =>
      letter.isEmpty ? const Color(0xFF3A3A3C) : const Color(0xFF565758);
}
