import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/ludo/logic/ludo_logic.dart';
import 'package:multigame/games/ludo/logic/ludo_path.dart';
import 'package:multigame/games/ludo/models/ludo_enums.dart';
import 'package:multigame/games/ludo/models/ludo_game_state.dart';
import 'package:multigame/games/ludo/models/ludo_player.dart';
import 'package:multigame/games/ludo/models/ludo_token.dart';

void main() {
  // ── rollDice ───────────────────────────────────────────────────────────────
  group('rollDice', () {
    test('always returns a value between 1 and 6', () {
      for (int i = 0; i < 200; i++) {
        final v = rollDice();
        expect(v, inInclusiveRange(1, 6));
      }
    });

    test('produces at least 5 distinct values in 200 rolls', () {
      final seen = <int>{};
      for (int i = 0; i < 200; i++) {
        seen.add(rollDice());
      }
      expect(seen.length, greaterThanOrEqualTo(5));
    });
  });

  // ── toRelativePosition / toAbsolutePosition ────────────────────────────────
  group('position conversion', () {
    test('red: start is relative 0', () {
      expect(toRelativePosition(0, LudoPlayerColor.red), 0);
    });

    test('blue: start is relative 0', () {
      expect(toRelativePosition(39, LudoPlayerColor.blue), 0);
    });

    test('green: start is relative 0', () {
      expect(toRelativePosition(13, LudoPlayerColor.green), 0);
    });

    test('yellow: start is relative 0', () {
      expect(toRelativePosition(26, LudoPlayerColor.yellow), 0);
    });

    test('round-trip: abs → rel → abs for all colors', () {
      for (final color in LudoPlayerColor.values) {
        for (int abs = 0; abs < 52; abs++) {
          final rel = toRelativePosition(abs, color);
          final back = toAbsolutePosition(rel, color);
          expect(back, abs, reason: '$color abs=$abs');
        }
      }
    });
  });

  // ── canLaunch ──────────────────────────────────────────────────────────────
  group('canLaunch', () {
    final baseToken = const LudoToken(id: 0, owner: LudoPlayerColor.red);

    test('returns true when token is in base and dice is 6', () {
      expect(canLaunch(baseToken, 6), isTrue);
    });

    test('returns false when dice is not 6', () {
      for (int d = 1; d <= 5; d++) {
        expect(canLaunch(baseToken, d), isFalse);
      }
    });

    test('returns false when token is already on track', () {
      final onTrack = baseToken.copyWith(trackPosition: 0);
      expect(canLaunch(onTrack, 6), isFalse);
    });

    test('returns false when token is finished', () {
      final finished = baseToken.copyWith(isFinished: true);
      expect(canLaunch(finished, 6), isFalse);
    });
  });

  // ── canMoveOnTrack ─────────────────────────────────────────────────────────
  group('canMoveOnTrack', () {
    final players = LudoGameState.buildPlayers(mode: LudoMode.soloVsBots);

    test('returns false for a base token', () {
      final t = const LudoToken(id: 0, owner: LudoPlayerColor.red);
      expect(canMoveOnTrack(t, 3, players), isFalse);
    });

    test('returns false for a finished token', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: -2,
        homeColumnStep: 6,
        isFinished: true,
      );
      expect(canMoveOnTrack(t, 1, players), isFalse);
    });


    test('returns false when move would overshoot home column', () {
      // In home column at step 5 — can only move 1 more step.
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: -2,
        homeColumnStep: 5,
      );
      expect(canMoveOnTrack(t, 2, players), isFalse);
    });

    test('returns true for a valid on-track move', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: 10,
      );
      expect(canMoveOnTrack(t, 3, players), isTrue);
    });
  });

  // ── wouldOvershoot ─────────────────────────────────────────────────────────
  group('wouldOvershoot', () {
    test('in home column: step 5 + 2 overshoots', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: -2,
        homeColumnStep: 5,
      );
      expect(wouldOvershoot(t, 2, LudoPlayerColor.red), isTrue);
    });

    test('in home column: step 5 + 1 does not overshoot', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: -2,
        homeColumnStep: 5,
      );
      expect(wouldOvershoot(t, 1, LudoPlayerColor.red), isFalse);
    });

    test('track token rel 50 + roll 6 does not overshoot (finishes exactly)', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: 50,
      );
      expect(wouldOvershoot(t, 6, LudoPlayerColor.red), isFalse);
    });
  });

  // ── isTrackSafe ────────────────────────────────────────────────────────────
  group('isTrackSafe', () {
    test('all 8 safe squares are safe', () {
      for (final sq in kSafeSquares) {
        expect(isTrackSafe(sq), isTrue, reason: 'square $sq should be safe');
      }
    });

    test('non-safe squares are not safe', () {
      expect(isTrackSafe(1), isFalse);
      expect(isTrackSafe(5), isFalse);
      expect(isTrackSafe(25), isFalse);
    });
  });

  // ── advanceToken ───────────────────────────────────────────────────────────
  group('advanceToken', () {
    test('advances along track', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: 5,
      );
      final result = advanceToken(t, 3, LudoPlayerColor.red);
      expect(result.isOnTrack, isTrue);
      expect(result.trackPosition, 8);
    });

    test('wraps around track (position 50 + 3 = 1)', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.blue,
        trackPosition: 50,
      );
      // Blue start = 39; rel of 50 = (50-39+52)%52 = 11.
      // 11 + 3 = 14 → still on track, abs = (14+39)%52 = 1.
      final result = advanceToken(t, 3, LudoPlayerColor.blue);
      expect(result.isOnTrack, isTrue);
    });

    test('enters home column correctly from rel 50 + roll 1', () {
      // Red's last track square is relative 50 = absolute 50.
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: 50,
      );
      final result = advanceToken(t, 1, LudoPlayerColor.red);
      expect(result.isInHomeColumn, isTrue);
      expect(result.homeColumnStep, 1);
    });

    test('rel 50 + roll 2 → homeColumnStep 2', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: 50,
      );
      final result = advanceToken(t, 2, LudoPlayerColor.red);
      expect(result.isInHomeColumn, isTrue);
      expect(result.homeColumnStep, 2);
    });

    test('rel 50 + roll 6 → isFinished', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: 50,
      );
      final result = advanceToken(t, 6, LudoPlayerColor.red);
      expect(result.isFinished, isTrue);
    });

    test('rel 49 + roll 1 → stays on track at abs 50', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: 49,
      );
      final result = advanceToken(t, 1, LudoPlayerColor.red);
      expect(result.isOnTrack, isTrue);
      expect(result.trackPosition, 50);
    });

    test('rel 49 + roll 2 → homeColumnStep 1', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: 49,
      );
      final result = advanceToken(t, 2, LudoPlayerColor.red);
      expect(result.isInHomeColumn, isTrue);
      expect(result.homeColumnStep, 1);
    });

    test('marks token as finished when it reaches step 6', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: -2,
        homeColumnStep: 5,
      );
      final result = advanceToken(t, 1, LudoPlayerColor.red);
      expect(result.isFinished, isTrue);
    });
  });

  // ── captureTargets ─────────────────────────────────────────────────────────
  group('captureTargets', () {
    LudoPlayer makePlayer(LudoPlayerColor c, int trackPos) {
      return LudoPlayer(
        color: c,
        name: c.name,
        isBot: false,
        tokens: [
          LudoToken(id: 0, owner: c, trackPosition: trackPos),
          LudoToken(id: 1, owner: c),
          LudoToken(id: 2, owner: c),
          LudoToken(id: 3, owner: c),
        ],
      );
    }

    test('returns opponent token at same position', () {
      final all = [
        makePlayer(LudoPlayerColor.red, 5),
        makePlayer(LudoPlayerColor.blue, 5),
      ];
      final targets = captureTargets(5, LudoPlayerColor.red, all, false);
      expect(targets.length, 1);
      expect(targets.first.owner, LudoPlayerColor.blue);
    });

    test('does not return own tokens', () {
      final all = [makePlayer(LudoPlayerColor.red, 5)];
      final targets = captureTargets(5, LudoPlayerColor.red, all, false);
      expect(targets, isEmpty);
    });

    test('does not capture ghost-protected token', () {
      final blue = LudoPlayer(
        color: LudoPlayerColor.blue,
        name: 'Blue',
        isBot: false,
        tokens: [
          const LudoToken(
            id: 0,
            owner: LudoPlayerColor.blue,
            trackPosition: 5,
            ghostTurnsLeft: 2,
          ),
          const LudoToken(id: 1, owner: LudoPlayerColor.blue),
          const LudoToken(id: 2, owner: LudoPlayerColor.blue),
          const LudoToken(id: 3, owner: LudoPlayerColor.blue),
        ],
      );
      final all = [makePlayer(LudoPlayerColor.red, 10), blue];
      final targets = captureTargets(5, LudoPlayerColor.red, all, false);
      expect(targets, isEmpty);
    });

    test('ghost token is never capturable (no bypass)', () {
      final blue = LudoPlayer(
        color: LudoPlayerColor.blue,
        name: 'Blue',
        isBot: false,
        tokens: [
          const LudoToken(
            id: 0,
            owner: LudoPlayerColor.blue,
            trackPosition: 5,
            ghostTurnsLeft: 2,
          ),
          const LudoToken(id: 1, owner: LudoPlayerColor.blue),
          const LudoToken(id: 2, owner: LudoPlayerColor.blue),
          const LudoToken(id: 3, owner: LudoPlayerColor.blue),
        ],
      );
      final all = [makePlayer(LudoPlayerColor.red, 10), blue];
      final targets = captureTargets(5, LudoPlayerColor.red, all, true);
      expect(targets, isEmpty);
    });

    test('cannot capture on safe square (non-recall)', () {
      // Safe square 8.
      final all = [
        makePlayer(LudoPlayerColor.red, 10),
        makePlayer(LudoPlayerColor.blue, 8),
      ];
      final targets = captureTargets(8, LudoPlayerColor.red, all, false);
      expect(targets, isEmpty);
    });
  });

  // ── computeMovableTokenIds ────────────────────────────────────────────────
  group('computeMovableTokenIds', () {
    test('returns empty list when all tokens are in base and dice != 6', () {
      final player = LudoPlayer.initial(
        color: LudoPlayerColor.red,
        name: 'You',
        isBot: false,
      );
      final all = [player];
      expect(computeMovableTokenIds(player, 3, all), isEmpty);
    });

    test('returns base token ids when dice is 6', () {
      final player = LudoPlayer.initial(
        color: LudoPlayerColor.red,
        name: 'You',
        isBot: false,
      );
      final all = [player];
      final ids = computeMovableTokenIds(player, 6, all);
      expect(ids.length, 4); // all 4 base tokens can launch
    });

    test('returns on-track tokens for normal dice', () {
      final player = LudoPlayer(
        color: LudoPlayerColor.red,
        name: 'You',
        isBot: false,
        tokens: [
          const LudoToken(id: 0, owner: LudoPlayerColor.red, trackPosition: 5),
          const LudoToken(id: 1, owner: LudoPlayerColor.red),
          const LudoToken(id: 2, owner: LudoPlayerColor.red),
          const LudoToken(id: 3, owner: LudoPlayerColor.red),
        ],
      );
      final all = [player];
      final ids = computeMovableTokenIds(player, 3, all);
      expect(ids, contains(0));
      expect(ids.length, 1);
    });
  });

  // ── checkWinner ────────────────────────────────────────────────────────────
  group('checkWinner', () {
    LudoPlayer finishedPlayer(LudoPlayerColor c) {
      return LudoPlayer(
        color: c,
        name: c.name,
        isBot: false,
        tokens: List.generate(
          4,
          (i) => LudoToken(
            id: i,
            owner: c,
            trackPosition: -2,
            homeColumnStep: 6,
            isFinished: true,
          ),
        ),
      );
    }

    test('returns the colour whose all 4 tokens are finished', () {
      final players = [
        finishedPlayer(LudoPlayerColor.red),
        LudoPlayer.initial(
          color: LudoPlayerColor.blue,
          name: 'Blue',
          isBot: true,
        ),
      ];
      final state = LudoGameState(
        phase: LudoPhase.rolling,
        mode: LudoMode.soloVsBots,
        players: players,
      );
      expect(checkWinner(state), LudoPlayerColor.red);
    });

    test('returns null when no player has finished', () {
      final players = LudoGameState.buildPlayers(mode: LudoMode.soloVsBots);
      final state = LudoGameState(
        phase: LudoPhase.rolling,
        mode: LudoMode.soloVsBots,
        players: players,
      );
      expect(checkWinner(state), isNull);
    });
  });

  // ── checkTeamWinner ───────────────────────────────────────────────────────
  group('checkTeamWinner', () {
    LudoPlayer finishedTeamPlayer(LudoPlayerColor c, int teamIdx) {
      return LudoPlayer(
        color: c,
        name: c.name,
        isBot: false,
        teamIndex: teamIdx,
        tokens: List.generate(
          4,
          (i) => LudoToken(
            id: i,
            owner: c,
            trackPosition: -2,
            homeColumnStep: 6,
            isFinished: true,
          ),
        ),
      );
    }

    test('returns team 0 when red and green both finish', () {
      final players = [
        finishedTeamPlayer(LudoPlayerColor.red, 0),
        LudoPlayer.initial(
          color: LudoPlayerColor.blue,
          name: 'Blue',
          isBot: false,
        ).copyWith(),
        finishedTeamPlayer(LudoPlayerColor.green, 0),
        LudoPlayer.initial(
          color: LudoPlayerColor.yellow,
          name: 'Yellow',
          isBot: false,
        ),
      ];
      final state = LudoGameState(
        phase: LudoPhase.rolling,
        mode: LudoMode.twoVsTwo,
        players: players,
      );
      expect(checkTeamWinner(state), 0);
    });

    test('returns null when no team has finished', () {
      final players = LudoGameState.buildPlayers(mode: LudoMode.twoVsTwo);
      final state = LudoGameState(
        phase: LudoPhase.rolling,
        mode: LudoMode.twoVsTwo,
        players: players,
      );
      expect(checkTeamWinner(state), isNull);
    });

    test('returns null for non-team mode', () {
      final players = LudoGameState.buildPlayers(mode: LudoMode.soloVsBots);
      final state = LudoGameState(
        phase: LudoPhase.rolling,
        mode: LudoMode.soloVsBots,
        players: players,
      );
      expect(checkTeamWinner(state), isNull);
    });
  });

  // ── stepsToFinish ─────────────────────────────────────────────────────────
  group('stepsToFinish', () {
    test('returns 0 for a finished token', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: -2,
        homeColumnStep: 6,
        isFinished: true,
      );
      expect(stepsToFinish(t), 0);
    });

    test('returns 58 for a base token', () {
      final t = const LudoToken(id: 0, owner: LudoPlayerColor.red);
      expect(stepsToFinish(t), 58);
    });

    test('returns remaining home-column steps for in-column token', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: -2,
        homeColumnStep: 4,
      );
      expect(stepsToFinish(t), 2);
    });
  });

  // ── LudoGameState.buildPlayers ────────────────────────────────────────────
  group('LudoGameState.buildPlayers', () {
    test('soloVsBots: 4 players, red is human, others are bots', () {
      final players = LudoGameState.buildPlayers(mode: LudoMode.soloVsBots);
      expect(players.length, 4);
      final red = players.firstWhere((p) => p.color == LudoPlayerColor.red);
      expect(red.isBot, isFalse);
      for (final p in players.where((p) => p.color != LudoPlayerColor.red)) {
        expect(p.isBot, isTrue);
      }
    });

    test('freeForAll3: 3 players (yellow excluded)', () {
      final players = LudoGameState.buildPlayers(
        mode: LudoMode.freeForAll3,
        excludedColor: LudoPlayerColor.yellow,
      );
      expect(players.length, 3);
      expect(players.every((p) => p.color != LudoPlayerColor.yellow), isTrue);
    });

    test('freeForAll4: 4 players, all human', () {
      final players = LudoGameState.buildPlayers(mode: LudoMode.freeForAll4);
      expect(players.length, 4);
      expect(players.every((p) => !p.isBot), isTrue);
    });

    test('twoVsTwo: red+green on team 0, blue+yellow on team 1', () {
      final players = LudoGameState.buildPlayers(mode: LudoMode.twoVsTwo);
      expect(players.length, 4);
      final redTeam = players
          .firstWhere((p) => p.color == LudoPlayerColor.red)
          .teamIndex;
      final greenTeam = players
          .firstWhere((p) => p.color == LudoPlayerColor.green)
          .teamIndex;
      final blueTeam = players
          .firstWhere((p) => p.color == LudoPlayerColor.blue)
          .teamIndex;
      final yellowTeam = players
          .firstWhere((p) => p.color == LudoPlayerColor.yellow)
          .teamIndex;
      expect(redTeam, 0);
      expect(greenTeam, 0);
      expect(blueTeam, 1);
      expect(yellowTeam, 1);
    });

    test('every player starts with 4 base tokens', () {
      final players = LudoGameState.buildPlayers(mode: LudoMode.soloVsBots);
      for (final p in players) {
        expect(p.tokens.length, 4);
        expect(p.tokens.every((t) => t.isInBase), isTrue);
      }
    });
  });

  // ── same-color stacking — computeMovableTokenIds ──────────────────────────
  group('same-color stacking — computeMovableTokenIds', () {
    LudoPlayer makeRedPlayer(List<LudoToken> tokens) {
      return LudoPlayer(
        color: LudoPlayerColor.red,
        name: 'Red',
        isBot: false,
        tokens: tokens,
      );
    }

    test('token at pos 1 blocked when teammate at pos 3 (non-safe), dice=2', () {
      // Red start = abs 0. Abs 1 = rel 1. Abs 3 = rel 3. Non-safe.
      final token0 = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: 1,
      );
      final token1 = const LudoToken(
        id: 1,
        owner: LudoPlayerColor.red,
        trackPosition: 3,
      );
      final token2 = const LudoToken(id: 2, owner: LudoPlayerColor.red);
      final token3 = const LudoToken(id: 3, owner: LudoPlayerColor.red);
      final player = makeRedPlayer([token0, token1, token2, token3]);
      final ids = computeMovableTokenIds(player, 2, [player]);
      expect(ids, isNot(contains(0))); // token0 would stack at 3 — blocked
      expect(ids, contains(1));        // token1 moves to abs 5, no block
    });

    test('token at pos 1 movable when dice=3 lands at abs 4 (no teammate)', () {
      final token0 = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: 1,
      );
      final token1 = const LudoToken(
        id: 1,
        owner: LudoPlayerColor.red,
        trackPosition: 3,
      );
      final token2 = const LudoToken(id: 2, owner: LudoPlayerColor.red);
      final token3 = const LudoToken(id: 3, owner: LudoPlayerColor.red);
      final player = makeRedPlayer([token0, token1, token2, token3]);
      final ids = computeMovableTokenIds(player, 3, [player]);
      expect(ids, contains(0)); // abs 1+3=4, not occupied
    });

    test('token at pos 1 blocked when teammate at safe square 8 (dice=7)', () {
      // Safe squares do NOT allow same-color stacking — stacking is blocked everywhere.
      final token0 = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: 1,
      );
      final token1 = const LudoToken(
        id: 1,
        owner: LudoPlayerColor.red,
        trackPosition: 8,
      );
      final token2 = const LudoToken(id: 2, owner: LudoPlayerColor.red);
      final token3 = const LudoToken(id: 3, owner: LudoPlayerColor.red);
      final player = makeRedPlayer([token0, token1, token2, token3]);
      final ids = computeMovableTokenIds(player, 7, [player]);
      expect(ids, isNot(contains(0))); // would stack on safe square 8 — blocked
    });

    test('tokens in home column always movable regardless of step overlap', () {
      // Both in home column — _destinationTrackPos returns null, no block check.
      final token0 = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: -2,
        homeColumnStep: 2,
      );
      final token1 = const LudoToken(
        id: 1,
        owner: LudoPlayerColor.red,
        trackPosition: -2,
        homeColumnStep: 3,
      );
      final token2 = const LudoToken(id: 2, owner: LudoPlayerColor.red);
      final token3 = const LudoToken(id: 3, owner: LudoPlayerColor.red);
      final player = makeRedPlayer([token0, token1, token2, token3]);
      final ids = computeMovableTokenIds(player, 1, [player]);
      expect(ids, contains(0)); // home column exempted from stacking rule
    });

    test('launch onto safe start pos allowed even with teammate there', () {
      // Red start = abs 0, which is in kSafeSquares — multiple tokens OK.
      final token0 = const LudoToken(id: 0, owner: LudoPlayerColor.red);
      final token1 = const LudoToken(
        id: 1,
        owner: LudoPlayerColor.red,
        trackPosition: 0, // already at start
      );
      final token2 = const LudoToken(id: 2, owner: LudoPlayerColor.red);
      final token3 = const LudoToken(id: 3, owner: LudoPlayerColor.red);
      final player = makeRedPlayer([token0, token1, token2, token3]);
      final ids = computeMovableTokenIds(player, 6, [player]);
      expect(ids, contains(0)); // canLaunch path — stacking check not applied
    });
  });

  // ── validDiceValues ────────────────────────────────────────────────────────
  group('validDiceValues', () {
    LudoPlayer makeRedPlayer(List<LudoToken> tokens) {
      return LudoPlayer(
        color: LudoPlayerColor.red,
        name: 'Red',
        isBot: false,
        tokens: tokens,
      );
    }

    test('all tokens in base → only dice=6 is valid', () {
      final player = LudoPlayer.initial(
        color: LudoPlayerColor.red,
        name: 'Red',
        isBot: false,
      );
      final valid = validDiceValues(player, [player]);
      expect(valid, equals([6]));
    });

    test('all tokens finished → returns empty', () {
      final player = makeRedPlayer(
        List.generate(
          4,
          (i) => LudoToken(
            id: i,
            owner: LudoPlayerColor.red,
            trackPosition: -2,
            homeColumnStep: 6,
            isFinished: true,
          ),
        ),
      );
      final valid = validDiceValues(player, [player]);
      expect(valid, isEmpty);
    });

    test('one token on track at pos 10 → dice 1-6 all valid', () {
      // Rel pos 10 for Red, no blocking, no overshoot risk for 1-6.
      final player = makeRedPlayer([
        const LudoToken(
          id: 0,
          owner: LudoPlayerColor.red,
          trackPosition: 10,
        ),
        const LudoToken(id: 1, owner: LudoPlayerColor.red),
        const LudoToken(id: 2, owner: LudoPlayerColor.red),
        const LudoToken(id: 3, owner: LudoPlayerColor.red),
      ]);
      final valid = validDiceValues(player, [player]);
      expect(valid, containsAll([1, 2, 3, 4, 5, 6]));
    });

    test('adjacent pawns at pos 1 and 2 → dice=1 excluded, dice=2+ valid', () {
      // token0 at pos 1, token1 at pos 2 (adjacent, non-safe).
      // dice=1: token0 → pos 2 (stacking-blocked) → whole value excluded.
      // dice=2: token0 → pos 3 (free), token1 → pos 4 (free) → valid.
      final player = makeRedPlayer([
        const LudoToken(
          id: 0,
          owner: LudoPlayerColor.red,
          trackPosition: 1,
        ),
        const LudoToken(
          id: 1,
          owner: LudoPlayerColor.red,
          trackPosition: 2,
        ),
        const LudoToken(id: 2, owner: LudoPlayerColor.red),
        const LudoToken(id: 3, owner: LudoPlayerColor.red),
      ]);
      final valid = validDiceValues(player, [player]);
      expect(valid, isNot(contains(1)));
      expect(valid, containsAll([2, 3, 4, 5, 6]));
    });

    test('dice=2 excluded when token 2 squares behind teammate on safe square', () {
      // Red: token0 at abs 6, token1 at abs 8 (safe square).
      // dice=2 would move token0 to 8 (stacking on token1) — must be excluded.
      final player = makeRedPlayer([
        const LudoToken(
          id: 0,
          owner: LudoPlayerColor.red,
          trackPosition: 6,
        ),
        const LudoToken(
          id: 1,
          owner: LudoPlayerColor.red,
          trackPosition: 8,
        ),
        const LudoToken(id: 2, owner: LudoPlayerColor.red),
        const LudoToken(id: 3, owner: LudoPlayerColor.red),
      ]);
      final valid = validDiceValues(player, [player]);
      expect(valid, isNot(contains(2)));
    });
  });

  // ── LudoToken model ───────────────────────────────────────────────────────
  group('LudoToken', () {
    test('isInBase is true by default', () {
      const t = LudoToken(id: 0, owner: LudoPlayerColor.red);
      expect(t.isInBase, isTrue);
      expect(t.isOnTrack, isFalse);
      expect(t.isInHomeColumn, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      const t = LudoToken(id: 2, owner: LudoPlayerColor.blue, trackPosition: 7);
      final t2 = t.copyWith(ghostTurnsLeft: 2);
      expect(t2.id, 2);
      expect(t2.owner, LudoPlayerColor.blue);
      expect(t2.trackPosition, 7);
      expect(t2.ghostTurnsLeft, 2);
    });
  });

  // ── Magic Dice — Turbo ─────────────────────────────────────────────────────
  group('Magic Dice — Turbo', () {
    LudoGameState stateWithPlayers(List<LudoPlayer> players) {
      return LudoGameState(
        phase: LudoPhase.rolling,
        diceMode: LudoDiceMode.magic,
        players: players,
        currentPlayerIndex: 0,
      );
    }

    test('computeMovableTokenIds allows base token launch when normalDice=6 even if effectiveDice=12', () {
      final redPlayer = LudoPlayer(
        color: LudoPlayerColor.red,
        name: 'Red',
        isBot: false,
        tokens: [const LudoToken(id: 0, owner: LudoPlayerColor.red)], // in base
      );
      final movable = computeMovableTokenIds(
        redPlayer,
        12, // effectiveDice (turbo doubled)
        [redPlayer],
        normalDice: 6, // physical roll was 6
      );
      expect(movable, contains(0));
    });

    test('computeMovableTokenIds blocks launch when normalDice!=6 even with turbo', () {
      final redPlayer = LudoPlayer(
        color: LudoPlayerColor.red,
        name: 'Red',
        isBot: false,
        tokens: [const LudoToken(id: 0, owner: LudoPlayerColor.red)], // in base
      );
      final movable = computeMovableTokenIds(
        redPlayer,
        8, // effectiveDice (turbo: 4×2)
        [redPlayer],
        normalDice: 4, // physical roll was 4 — can't launch
      );
      expect(movable, isEmpty);
    });

    test('consecutive sixes increments based on normalDice, not effectiveDice', () {
      final redPlayer = LudoPlayer(
        color: LudoPlayerColor.red,
        name: 'Red',
        isBot: false,
        tokens: [const LudoToken(id: 0, owner: LudoPlayerColor.red, trackPosition: 0)],
      );
      final state = stateWithPlayers([redPlayer]).copyWith(
        diceValue: 12, // effectiveDice after turbo
        magicDiceFace: MagicDiceFace.turbo,
      );
      final result = applyMove(state, 0, normalDice: 6);
      expect(result.players[0].consecutiveSixes, 1);
    });

    test('consecutive sixes does NOT increment when normalDice!=6', () {
      final redPlayer = LudoPlayer(
        color: LudoPlayerColor.red,
        name: 'Red',
        isBot: false,
        tokens: [const LudoToken(id: 0, owner: LudoPlayerColor.red, trackPosition: 0)],
      );
      final state = stateWithPlayers([redPlayer]).copyWith(
        diceValue: 8, // effectiveDice after turbo
        magicDiceFace: MagicDiceFace.turbo,
      );
      final result = applyMove(state, 0, normalDice: 4);
      expect(result.players[0].consecutiveSixes, 0);
    });
  });

  // ── Magic Dice — Ghost ─────────────────────────────────────────────────────
  group('Magic Dice — Ghost', () {
    LudoGameState ghostState(List<LudoPlayer> players) {
      return LudoGameState(
        phase: LudoPhase.selectingToken,
        diceMode: LudoDiceMode.magic,
        magicDiceFace: MagicDiceFace.ghost,
        diceValue: 3,
        players: players,
        currentPlayerIndex: 0,
      );
    }

    test('applyMove with ghost face sets ghostTurnsLeft=3 on moved token', () {
      final redPlayer = LudoPlayer(
        color: LudoPlayerColor.red,
        name: 'Red',
        isBot: false,
        tokens: [const LudoToken(id: 0, owner: LudoPlayerColor.red, trackPosition: 0)],
      );
      final state = ghostState([redPlayer]);
      final result = applyMove(state, 0, normalDice: 3);
      final movedToken = result.players
          .firstWhere((p) => p.color == LudoPlayerColor.red)
          .tokens
          .first;
      expect(movedToken.ghostTurnsLeft, 3);
    });

    test('ghost token defuses an enemy bomb on contact', () {
      final enemyBombPos = 5;
      final redPlayer = LudoPlayer(
        color: LudoPlayerColor.red,
        name: 'Red',
        isBot: false,
        tokens: [
          LudoToken(id: 0, owner: LudoPlayerColor.red, trackPosition: 2, ghostTurnsLeft: 3),
        ],
      );
      final bluePlayer = LudoPlayer(
        color: LudoPlayerColor.blue,
        name: 'Blue',
        isBot: false,
        tokens: [const LudoToken(id: 0, owner: LudoPlayerColor.blue, trackPosition: 10)],
      );
      final bomb = LudoBomb(
        trackPosition: enemyBombPos,
        placedBy: LudoPlayerColor.blue,
        turnsLeft: 8,
      );
      final state = LudoGameState(
        phase: LudoPhase.selectingToken,
        diceMode: LudoDiceMode.magic,
        diceValue: 3, // red moves from 2 → 5, lands on bomb
        players: [redPlayer, bluePlayer],
        currentPlayerIndex: 0,
        activeBombs: [bomb],
      );
      final result = applyMove(state, 0, normalDice: 3);
      final redToken = result.players
          .firstWhere((p) => p.color == LudoPlayerColor.red)
          .tokens
          .first;
      expect(redToken.isInBase, isFalse, reason: 'ghost token should survive');
      expect(result.activeBombs, isEmpty, reason: 'bomb should be defused');
    });
  });

  // ── freeForAll3 — portal mechanic ────────────────────────────────────────
  group('freeForAll3 — portal mechanic', () {
    // Builds a minimal ffa3 state with one on-track token for [color].
    LudoGameState ffa3State({
      required LudoPlayerColor color,
      required int trackPosition,
      required int diceValue,
    }) {
      LudoPlayer makePlayer(LudoPlayerColor c, int pos) {
        return LudoPlayer(
          color: c,
          name: c.name,
          isBot: false,
          tokens: [
            LudoToken(id: 0, owner: c, trackPosition: pos),
            LudoToken(id: 1, owner: c),
            LudoToken(id: 2, owner: c),
            LudoToken(id: 3, owner: c),
          ],
        );
      }

      final players = [
        makePlayer(LudoPlayerColor.red, color == LudoPlayerColor.red ? trackPosition : 5),
        makePlayer(LudoPlayerColor.green, color == LudoPlayerColor.green ? trackPosition : 18),
        makePlayer(LudoPlayerColor.blue, color == LudoPlayerColor.blue ? trackPosition : 44),
      ];
      final idx = players.indexWhere((p) => p.color == color);
      return LudoGameState(
        phase: LudoPhase.selectingToken,
        mode: LudoMode.freeForAll3,
        players: players,
        currentPlayerIndex: idx,
        diceValue: diceValue,
      );
    }

    test('Red at pos 25 + dice 5 → teleports via portal, lands at abs 43', () {
      final state = ffa3State(
        color: LudoPlayerColor.red,
        trackPosition: 25,
        diceValue: 5,
      );
      final result = applyMove(state, 0, normalDice: 5);
      final token = result.players
          .firstWhere((p) => p.color == LudoPlayerColor.red)
          .tokens
          .first;
      expect(token.trackPosition, 43);
      expect(token.isOnTrack, isTrue);
    });

    test('Green at pos 25 + dice 1 → teleports to Blue spawn (abs 39)', () {
      final state = ffa3State(
        color: LudoPlayerColor.green,
        trackPosition: 25,
        diceValue: 1,
      );
      final result = applyMove(state, 0, normalDice: 1);
      final token = result.players
          .firstWhere((p) => p.color == LudoPlayerColor.green)
          .tokens
          .first;
      expect(token.trackPosition, 39);
      expect(token.isOnTrack, isTrue);
    });

    test('Blue at pos 25 + dice 1 → enters home column at step 1', () {
      final state = ffa3State(
        color: LudoPlayerColor.blue,
        trackPosition: 25,
        diceValue: 1,
      );
      final result = applyMove(state, 0, normalDice: 1);
      final token = result.players
          .firstWhere((p) => p.color == LudoPlayerColor.blue)
          .tokens
          .first;
      expect(token.isInHomeColumn, isTrue);
      expect(token.homeColumnStep, 1);
    });

    test('Blue at pos 25 + dice 6 → finishes (home column step 6)', () {
      final state = ffa3State(
        color: LudoPlayerColor.blue,
        trackPosition: 25,
        diceValue: 6,
      );
      final result = applyMove(state, 0, normalDice: 6);
      final token = result.players
          .firstWhere((p) => p.color == LudoPlayerColor.blue)
          .tokens
          .first;
      expect(token.isFinished, isTrue);
    });

    test('Blue at pos 25 is NOT movable with dice 7 (overshoot after portal)', () {
      final player = LudoPlayer(
        color: LudoPlayerColor.blue,
        name: 'Blue',
        isBot: false,
        tokens: [
          const LudoToken(id: 0, owner: LudoPlayerColor.blue, trackPosition: 25),
          const LudoToken(id: 1, owner: LudoPlayerColor.blue),
          const LudoToken(id: 2, owner: LudoPlayerColor.blue),
          const LudoToken(id: 3, owner: LudoPlayerColor.blue),
        ],
      );
      final ids = computeMovableTokenIds(
        player,
        7,
        [player],
        mode: LudoMode.freeForAll3,
      );
      expect(ids, isNot(contains(0)));
    });

    test('Blue at pos 25 IS movable with dice 6 (exact finish, no overshoot)', () {
      final player = LudoPlayer(
        color: LudoPlayerColor.blue,
        name: 'Blue',
        isBot: false,
        tokens: [
          const LudoToken(id: 0, owner: LudoPlayerColor.blue, trackPosition: 25),
          const LudoToken(id: 1, owner: LudoPlayerColor.blue),
          const LudoToken(id: 2, owner: LudoPlayerColor.blue),
          const LudoToken(id: 3, owner: LudoPlayerColor.blue),
        ],
      );
      final ids = computeMovableTokenIds(
        player,
        6,
        [player],
        mode: LudoMode.freeForAll3,
      );
      expect(ids, contains(0));
    });
  });

  // ── Magic Dice — Bomb ──────────────────────────────────────────────────────
  group('Magic Dice — Bomb', () {
    test('own token stepping on own bomb defuses it without dying', () {
      final ownBombPos = 3;
      final redPlayer = LudoPlayer(
        color: LudoPlayerColor.red,
        name: 'Red',
        isBot: false,
        tokens: [
          const LudoToken(id: 0, owner: LudoPlayerColor.red, trackPosition: 0),
        ],
      );
      final bomb = LudoBomb(
        trackPosition: ownBombPos,
        placedBy: LudoPlayerColor.red,
        turnsLeft: 8,
      );
      final state = LudoGameState(
        phase: LudoPhase.selectingToken,
        diceValue: 3, // moves from 0 → 3, lands on own bomb
        players: [redPlayer],
        currentPlayerIndex: 0,
        activeBombs: [bomb],
      );
      final result = applyMove(state, 0, normalDice: 3);
      final redToken = result.players
          .firstWhere((p) => p.color == LudoPlayerColor.red)
          .tokens
          .first;
      expect(redToken.isInBase, isFalse, reason: 'own token should survive own bomb');
      expect(result.activeBombs, isEmpty, reason: 'own bomb should be defused');
    });

    test('enemy token stepping on a bomb is reset to base', () {
      final bombPos = 3;
      final redPlayer = LudoPlayer(
        color: LudoPlayerColor.red,
        name: 'Red',
        isBot: false,
        tokens: [const LudoToken(id: 0, owner: LudoPlayerColor.red, trackPosition: 0)],
      );
      final bomb = LudoBomb(
        trackPosition: bombPos,
        placedBy: LudoPlayerColor.blue, // placed by someone else
        turnsLeft: 8,
      );
      final state = LudoGameState(
        phase: LudoPhase.selectingToken,
        diceValue: 3,
        players: [redPlayer],
        currentPlayerIndex: 0,
        activeBombs: [bomb],
      );
      final result = applyMove(state, 0, normalDice: 3);
      final redToken = result.players
          .firstWhere((p) => p.color == LudoPlayerColor.red)
          .tokens
          .first;
      expect(redToken.isInBase, isTrue, reason: 'enemy bomb should kill token');
      expect(result.activeBombs, isEmpty);
    });
  });

  // ── Magic Dice — skipMagicDiceOnNextRoll ──────────────────────────────────
  group('Magic Dice — skipMagicDiceOnNextRoll', () {
    LudoPlayer makePlayer(LudoPlayerColor color, List<LudoToken> tokens) {
      return LudoPlayer(
        color: color,
        name: color.name,
        isBot: false,
        tokens: tokens,
      );
    }

    test('applyMove with normalDice=6 and extraTurn sets skipMagicDiceOnNextRoll=true', () {
      final red = makePlayer(LudoPlayerColor.red, [
        const LudoToken(id: 0, owner: LudoPlayerColor.red, trackPosition: 5),
        const LudoToken(id: 1, owner: LudoPlayerColor.red),
        const LudoToken(id: 2, owner: LudoPlayerColor.red),
        const LudoToken(id: 3, owner: LudoPlayerColor.red),
      ]);
      final state = LudoGameState(
        phase: LudoPhase.selectingToken,
        diceMode: LudoDiceMode.magic,
        diceValue: 6,
        players: [red],
        currentPlayerIndex: 0,
      );
      // Moving with normalDice=6 grants an extra turn (non-launch 6 rule).
      final result = applyMove(state, 0, normalDice: 6);
      expect(result.skipMagicDiceOnNextRoll, isTrue);
    });

    test('applyMove capture with normalDice!=6 sets skipMagicDiceOnNextRoll=false', () {
      final red = makePlayer(LudoPlayerColor.red, [
        const LudoToken(id: 0, owner: LudoPlayerColor.red, trackPosition: 5),
      ]);
      final blue = makePlayer(LudoPlayerColor.blue, [
        const LudoToken(id: 0, owner: LudoPlayerColor.blue, trackPosition: 8),
      ]);
      final state = LudoGameState(
        phase: LudoPhase.selectingToken,
        diceMode: LudoDiceMode.magic,
        diceValue: 3,
        players: [red, blue],
        currentPlayerIndex: 0,
      );
      // Red moves from 5 to 8 and captures Blue — extra turn but normalDice=3.
      final result = applyMove(state, 0, normalDice: 3);
      expect(result.skipMagicDiceOnNextRoll, isFalse);
    });

    test('applyMove token finishes with normalDice!=6 sets skipMagicDiceOnNextRoll=false', () {
      final red = makePlayer(LudoPlayerColor.red, [
        const LudoToken(
          id: 0,
          owner: LudoPlayerColor.red,
          trackPosition: -2,
          homeColumnStep: 4,
        ),
      ]);
      final state = LudoGameState(
        phase: LudoPhase.selectingToken,
        diceMode: LudoDiceMode.magic,
        diceValue: 2,
        players: [red],
        currentPlayerIndex: 0,
      );
      // Token reaches finish (homeColumnStep 4+2=6) — extra turn but normalDice=2.
      final result = applyMove(state, 0, normalDice: 2);
      expect(result.skipMagicDiceOnNextRoll, isFalse);
    });
  });
}
