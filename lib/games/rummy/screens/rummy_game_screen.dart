import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/playing_card.dart';
import '../models/rummy_game_state.dart';
import '../providers/rummy_notifier.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/rummy_bottom_strip.dart';
import '../widgets/rummy_center_area.dart';
import '../widgets/rummy_flying_card.dart';
import '../widgets/rummy_left_sidebar.dart';
import '../widgets/rummy_opponent_slot.dart';
import '../widgets/tunisian_background.dart';
import 'rummy_game_over_screen.dart';
import 'rummy_mode_select_screen.dart';

class RummyGamePage extends ConsumerWidget {
  const RummyGamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(rummyProvider.select((s) => s.phase));
    if (phase == RummyPhase.idle) {
      return const RummyModeSelectScreen();
    }
    return const _GameScreen();
  }
}

class _GameScreen extends ConsumerStatefulWidget {
  const _GameScreen();

  @override
  ConsumerState<_GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<_GameScreen> {
  final _flyingCards = ValueNotifier<List<FlyingCardData>>([]);
  final _deckKey = GlobalKey();
  final _discardKey = GlobalKey();
  final _handKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _flyingCards.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _removeFlyingCard(String id) {
    final current = List<FlyingCardData>.from(_flyingCards.value);
    current.removeWhere((c) => c.id == id);
    _flyingCards.value = current;
  }

  Offset? _widgetTopLeft(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero);
  }

  Offset? _widgetCenter(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final tl = box.localToGlobal(Offset.zero);
    return Offset(
      tl.dx + box.size.width / 2 - kCardWidth / 2,
      tl.dy + box.size.height / 2 - kCardHeight / 2,
    );
  }

  void _launchFlyCard(PlayingCard card,
      {required Offset from, required Offset to, bool faceUp = true}) {
    final id = '${card.id}_${DateTime.now().microsecondsSinceEpoch}';
    final current = List<FlyingCardData>.from(_flyingCards.value);
    current.add(FlyingCardData(
      id: id,
      card: card,
      from: from,
      to: to,
      faceUp: faceUp,
      duration: const Duration(milliseconds: 320),
    ));
    _flyingCards.value = current;
  }

  void _onDrawFromDeck(RummyNotifier notifier) {
    final state = ref.read(rummyProvider);
    if (state.drawPile.isNotEmpty) {
      final from = _widgetTopLeft(_deckKey);
      final to = _widgetCenter(_handKey);
      if (from != null && to != null) {
        _launchFlyCard(state.drawPile.last, from: from, to: to, faceUp: false);
      }
    }
    notifier.drawFromDeck();
  }

  void _onDrawFromDiscard(RummyNotifier notifier) {
    final state = ref.read(rummyProvider);
    final card = state.topDiscard;
    if (card != null) {
      final from = _widgetTopLeft(_discardKey);
      final to = _widgetCenter(_handKey);
      if (from != null && to != null) {
        _launchFlyCard(card, from: from, to: to);
      }
    }
    notifier.drawFromDiscard();
  }

  void _onDropOnDiscard(PlayingCard card, RummyNotifier notifier) {
    final from = _widgetCenter(_handKey);
    final to = _widgetTopLeft(_discardKey);
    if (from != null && to != null) {
      _launchFlyCard(card, from: from, to: to);
    }
    notifier.discard(card);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(rummyProvider.notifier);
    final (phase, playerCount) = ref.watch(
      rummyProvider.select((s) => (s.phase, s.players.length)),
    );

    if (phase == RummyPhase.gameOver) {
      final state = ref.read(rummyProvider);
      return RummyGameOverScreen(state: state, notifier: notifier);
    }

    return Scaffold(
      backgroundColor: DSColors.rummyFelt,
      body: TunisianBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _TopBar(notifier: notifier),
                  Expanded(
                    child: Row(
                      children: [
                        RummyLeftSidebar(
                          notifier: notifier,
                          deckWidgetKey: _deckKey,
                          discardWidgetKey: _discardKey,
                          onDrawFromDeck: () => _onDrawFromDeck(notifier),
                          onDrawFromDiscard: () =>
                              _onDrawFromDiscard(notifier),
                          onCardDroppedOnDiscard: (card) =>
                              _onDropOnDiscard(card, notifier),
                        ),
                        Expanded(
                          child: RummyCenterArea(notifier: notifier),
                        ),
                        if (playerCount > 3)
                          SizedBox(
                            width: 70,
                            child: Center(
                              child: RummyOpponentSlot(
                                playerIdx: 3,
                                horizontal: false,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  RummyBottomStrip(
                    notifier: notifier,
                    handContainerKey: _handKey,
                  ),
                ],
              ),
              ValueListenableBuilder<List<FlyingCardData>>(
                valueListenable: _flyingCards,
                builder: (_, cards, _) {
                  return Stack(
                    children: cards.map((data) {
                      return RummyFlyingCard(
                        key: ValueKey(data.id),
                        data: data,
                        onComplete: () => _removeFlyingCard(data.id),
                      );
                    }).toList(),
                  );
                },
              ),
              const Positioned(top: 4, right: 4, child: _FpsCounter()),
            ],
          ),
        ),
      ),
    );
  }
}

class _FpsCounter extends StatefulWidget {
  const _FpsCounter();

  @override
  State<_FpsCounter> createState() => _FpsCounterState();
}

class _FpsCounterState extends State<_FpsCounter>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _frameDurations = <int>[];
  double _fps = 0;
  Duration _prev = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (_prev != Duration.zero) {
      _frameDurations.add((elapsed - _prev).inMicroseconds);
      if (_frameDurations.length > 60) {
        _frameDurations.removeAt(0);
      }
      if (_frameDurations.length >= 5) {
        final avg =
            _frameDurations.reduce((a, b) => a + b) / _frameDurations.length;
        final fps = 1000000 / avg;
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

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.notifier});
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? DSColors.rummyPrimary.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: isCurrent
                          ? Border.all(color: DSColors.rummyAccent, width: 1)
                          : null,
                    ),
                    child: Text(
                      '${p.name} ${p.score}',
                      style: DSTypography.labelSmall.copyWith(
                        color: p.isEliminated
                            ? DSColors.textDisabled
                            : isCurrent
                                ? DSColors.rummyAccent
                                : Colors.white70,
                        fontSize: 10,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
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
                  color: DSColors.rummyAccent.withValues(alpha: 0.5), width: 0.8),
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
