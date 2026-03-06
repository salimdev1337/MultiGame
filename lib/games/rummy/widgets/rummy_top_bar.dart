import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../providers/rummy_notifier.dart';

class RummyTopBar extends ConsumerWidget {
  const RummyTopBar({super.key, required this.notifier});
  final RummyNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(rummyProvider.select((s) => (
      roundNumber: s.roundNumber,
      players: s.players,
      currentPlayerIndex: s.currentPlayerIndex,
      meldMinimum: s.meldMinimum,
    )));
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
            onPressed: () {
              notifier.goToIdle();
              context.pop();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Text(
            'Round ${s.roundNumber}',
            style: DSTypography.labelSmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: s.players.asMap().entries.map((e) {
                  final p = e.value;
                  final isCurrent = e.key == s.currentPlayerIndex;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? DSColors.rummyPrimary.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: isCurrent
                          ? Border.all(color: DSColors.rummyAccent, width: 1)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${p.name} ${p.score}',
                          style: DSTypography.labelSmall.copyWith(
                            color: p.isEliminated
                                ? DSColors.textDisabled
                                : isCurrent
                                    ? DSColors.rummyAccent
                                    : Colors.white70,
                            fontSize: 10,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (p.score > 0) ...[
                          const SizedBox(width: 3),
                          RummyScoreChips(score: p.score),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: DSColors.rummyAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: DSColors.rummyAccent.withValues(alpha: 0.5),
                  width: 0.8),
            ),
            child: Text(
              'Min: ${s.meldMinimum}pts',
              style: DSTypography.labelSmall.copyWith(
                color: DSColors.rummyAccent,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RummyScoreChips extends StatelessWidget {
  const RummyScoreChips({super.key, required this.score});
  final int score;

  static const _chipColors = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
  ];

  @override
  Widget build(BuildContext context) {
    final hundreds = score ~/ 100;
    final fifties = (score % 100) ~/ 50;
    final tens = (score % 50) ~/ 10;

    final chips = <Widget>[];
    for (var i = 0; i < hundreds && chips.length < 5; i++) {
      chips.add(_chip(_chipColors[0], 7));
    }
    for (var i = 0; i < fifties && chips.length < 5; i++) {
      chips.add(_chip(_chipColors[1], 6));
    }
    for (var i = 0; i < tens && chips.length < 5; i++) {
      chips.add(_chip(_chipColors[2], 5));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: chips);
  }

  Widget _chip(Color color, double size) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(left: 1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
    );
  }
}

class RummyFpsCounter extends StatefulWidget {
  const RummyFpsCounter({super.key});

  @override
  State<RummyFpsCounter> createState() => _RummyFpsCounterState();
}

class _RummyFpsCounterState extends State<RummyFpsCounter>
    with SingleTickerProviderStateMixin {
  static const _kBufSize = 60;

  late final Ticker _ticker;
  final _frameDurations = List<int>.filled(_kBufSize, 0);
  int _head = 0;
  int _count = 0;
  double _fps = 0;
  Duration _prev = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (_prev != Duration.zero) {
      _frameDurations[_head] = (elapsed - _prev).inMicroseconds;
      _head = (_head + 1) % _kBufSize;
      if (_count < _kBufSize) {
        _count++;
      }
      if (_count >= 5) {
        var sum = 0;
        for (var i = 0; i < _count; i++) {
          sum += _frameDurations[i];
        }
        final fps = 1000000 / (sum / _count);
        if ((fps - _fps).abs() >= 0.5) {
          setState(() => _fps = fps);
        }
      }
    }
    _prev = elapsed;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _fps >= 55
        ? Colors.greenAccent
        : _fps >= 30
            ? Colors.orange
            : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${_fps.toStringAsFixed(0)} FPS',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
