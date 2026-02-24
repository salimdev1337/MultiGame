import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/memory_notifier.dart';

const _kP1 = Color(0xFF00E5FF);
const _kP2 = Color(0xFFFF1493);

class MemoryTwoPlayerHUD extends ConsumerWidget {
  const MemoryTwoPlayerHUD({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(memoryProvider.select((s) => (
          currentPlayer: s.currentPlayer,
          playerScores: s.playerScores,
          playerMatches: s.playerMatches,
          playerStreaks: s.playerStreaks,
          moves: s.moves,
        )));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1F),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: MemoryPlayerPanel(
              playerIndex: 0,
              score: s.playerScores[0],
              matches: s.playerMatches[0],
              streak: s.playerStreaks[0],
              isActive: s.currentPlayer == 0,
              alignRight: false,
            ),
          ),
          MemoryMovesColumn(moves: s.moves),
          Expanded(
            child: MemoryPlayerPanel(
              playerIndex: 1,
              score: s.playerScores[1],
              matches: s.playerMatches[1],
              streak: s.playerStreaks[1],
              isActive: s.currentPlayer == 1,
              alignRight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class MemoryPlayerPanel extends StatelessWidget {
  const MemoryPlayerPanel({
    super.key,
    required this.playerIndex,
    required this.score,
    required this.matches,
    required this.streak,
    required this.isActive,
    required this.alignRight,
  });

  final int playerIndex;
  final int score;
  final int matches;
  final int streak;
  final bool isActive;
  final bool alignRight;

  Color get _color => playerIndex == 0 ? _kP1 : _kP2;
  String get _label => playerIndex == 0 ? 'P1' : 'P2';

  @override
  Widget build(BuildContext context) {
    final multiplier = (streak + 1).clamp(1, 4);
    final crossAxis =
        alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignRight ? TextAlign.right : TextAlign.left;
    final color = _color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.35)
              : Colors.transparent,
          width: 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: crossAxis,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: alignRight
                ? [
                    if (isActive)
                      MemoryActiveDot(color: color),
                    if (isActive) const SizedBox(width: 5),
                    Text(
                      _label,
                      style: TextStyle(
                        color: isActive ? color : Colors.white30,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ]
                : [
                    Text(
                      _label,
                      style: TextStyle(
                        color: isActive ? color : Colors.white30,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    if (isActive) const SizedBox(width: 5),
                    if (isActive)
                      MemoryActiveDot(color: color),
                  ],
          ),
          const SizedBox(height: 3),
          Text(
            '$score',
            textAlign: textAlign,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white38,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$matches pairs  ×$multiplier',
            textAlign: textAlign,
            style: TextStyle(
              color: isActive
                  ? color.withValues(alpha: 0.8)
                  : Colors.white24,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class MemoryActiveDot extends StatefulWidget {
  const MemoryActiveDot({super.key, required this.color});
  final Color color;

  @override
  State<MemoryActiveDot> createState() => _MemoryActiveDotState();
}

class _MemoryActiveDotState extends State<MemoryActiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.5 + 0.5 * _anim.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.6 * _anim.value),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class MemoryMovesColumn extends StatelessWidget {
  const MemoryMovesColumn({super.key, required this.moves});
  final int moves;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MOVES',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 8,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$moves',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
