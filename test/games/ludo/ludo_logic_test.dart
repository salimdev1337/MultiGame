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
      expect(toRelativePosition(26, LudoPlayerColor.blue), 0);
    });

    test('green: start is relative 0', () {
      expect(toRelativePosition(39, LudoPlayerColor.green), 0);
    });

    test('yellow: start is relative 0', () {
      expect(toRelativePosition(13, LudoPlayerColor.yellow), 0);
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

    test('returns false for a frozen token', () {
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: 5,
        isFrozen: true,
      );
      expect(canMoveOnTrack(t, 3, players), isFalse);
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
      // Blue start = 26; rel of 50 = (50-26+52)%52 = 24.
      // 24 + 3 = 27 → still on track, abs = (27+26)%52 = 1.
      final result = advanceToken(t, 3, LudoPlayerColor.blue);
      expect(result.isOnTrack, isTrue);
    });

    test('enters home column correctly', () {
      // Red's last track square before home column is at relative 51 = absolute 51.
      final t = const LudoToken(
        id: 0,
        owner: LudoPlayerColor.red,
        trackPosition: 51,
      );
      // 1 step enters home column step 1.
      final result = advanceToken(t, 1, LudoPlayerColor.red);
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

    test('does not capture shielded token (non-recall)', () {
      final blue = LudoPlayer(
        color: LudoPlayerColor.blue,
        name: 'Blue',
        isBot: false,
        tokens: [
          const LudoToken(
            id: 0,
            owner: LudoPlayerColor.blue,
            trackPosition: 5,
            shieldTurnsLeft: 2,
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

    test('capture bypasses shield when recall powerup', () {
      final blue = LudoPlayer(
        color: LudoPlayerColor.blue,
        name: 'Blue',
        isBot: false,
        tokens: [
          const LudoToken(
            id: 0,
            owner: LudoPlayerColor.blue,
            trackPosition: 5,
            shieldTurnsLeft: 2,
          ),
          const LudoToken(id: 1, owner: LudoPlayerColor.blue),
          const LudoToken(id: 2, owner: LudoPlayerColor.blue),
          const LudoToken(id: 3, owner: LudoPlayerColor.blue),
        ],
      );
      final all = [makePlayer(LudoPlayerColor.red, 10), blue];
      final targets = captureTargets(5, LudoPlayerColor.red, all, true);
      expect(targets.length, 1);
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
      expect(players.first.color, LudoPlayerColor.red);
      expect(players.first.isBot, isFalse);
      for (final p in players.skip(1)) {
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
      final t2 = t.copyWith(shieldTurnsLeft: 2);
      expect(t2.id, 2);
      expect(t2.owner, LudoPlayerColor.blue);
      expect(t2.trackPosition, 7);
      expect(t2.shieldTurnsLeft, 2);
    });
  });
}
