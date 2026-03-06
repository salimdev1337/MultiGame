import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/design_system/ds_colors.dart';

import '../models/playing_card.dart';
import '../models/rummy_game_state.dart';
import '../providers/rummy_notifier.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/rummy_bottom_strip.dart';
import '../widgets/rummy_top_bar.dart';
import '../widgets/rummy_center_area.dart';
import '../widgets/rummy_flying_card.dart';
import '../widgets/rummy_left_sidebar.dart';
import '../widgets/rummy_opponent_slot.dart';
import '../widgets/tunisian_background.dart';
import 'rummy_game_over_screen.dart';
import 'rummy_mode_select_screen.dart';

class RummyGamePage extends ConsumerStatefulWidget {
  const RummyGamePage({super.key});

  @override
  ConsumerState<RummyGamePage> createState() => _RummyGamePageState();
}

class _RummyGamePageState extends ConsumerState<RummyGamePage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
  int _lastRound = -1;

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

  void _launchDealCascade() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final from = _widgetTopLeft(_deckKey);
      if (from == null) {
        return;
      }
      final state = ref.read(rummyProvider);
      final totalCards = state.players
          .where((p) => !p.isEliminated)
          .fold<int>(0, (sum, p) => sum + p.hand.length);

      const dummyCard = PlayingCard(
        id: '_deal',
        suit: suitSpades,
        rank: rankAce,
        isJoker: false,
      );

      final screenSize = MediaQuery.sizeOf(context);
      final targets = <Offset>[
        Offset(screenSize.width / 2, screenSize.height - kCardHeight - 20),
        Offset(screenSize.width / 2, 30),
        Offset(20, screenSize.height / 2),
        Offset(screenSize.width - kCardWidth - 20, screenSize.height / 2),
      ];

      const maxFlyingCards = 12;
      final cards = <FlyingCardData>[];
      var dealIdx = 0;
      outer:
      for (var round = 0; round < kRummyHandSize && dealIdx < totalCards; round++) {
        for (var p = 0; p < state.players.length && dealIdx < totalCards; p++) {
          if (state.players[p].isEliminated) {
            continue;
          }
          if (cards.length >= maxFlyingCards) {
            break outer;
          }
          final target = targets[p % targets.length];
          cards.add(FlyingCardData(
            id: 'deal_${dealIdx}_${DateTime.now().microsecondsSinceEpoch}',
            card: dummyCard,
            from: from,
            to: target,
            faceUp: false,
            duration: const Duration(milliseconds: 200),
            delay: Duration(milliseconds: 40 * dealIdx),
          ));
          dealIdx++;
        }
      }

      _flyingCards.value = [..._flyingCards.value, ...cards];
    });
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
    final (phase, playerCount, roundNumber) = ref.watch(
      rummyProvider.select((s) => (s.phase, s.players.length, s.roundNumber)),
    );

    if (roundNumber != _lastRound && phase == RummyPhase.playing) {
      _lastRound = roundNumber;
      _launchDealCascade();
    }

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
              RepaintBoundary(
                child: Column(
                children: [
                  RummyTopBar(notifier: notifier),
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
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
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
              ),
              RepaintBoundary(
                child: ValueListenableBuilder<List<FlyingCardData>>(
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
              ),
              const Positioned(
                top: 4,
                right: 4,
                child: RepaintBoundary(child: RummyFpsCounter()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

