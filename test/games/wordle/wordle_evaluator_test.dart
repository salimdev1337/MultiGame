import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/wordle/logic/wordle_evaluator.dart';
import 'package:multigame/games/wordle/models/wordle_enums.dart';

void main() {
  group('evaluateGuess', () {
    test('all correct', () {
      final result = evaluateGuess('crane', 'crane');
      expect(result, [
        TileState.correct,
        TileState.correct,
        TileState.correct,
        TileState.correct,
        TileState.correct,
      ]);
    });

    test('all absent', () {
      final result = evaluateGuess('zzzzz', 'crane');
      expect(result, everyElement(TileState.absent));
    });

    test('all present (anagram)', () {
      final result = evaluateGuess('nacer', 'crane');
      // n→present, a→present, c→present, e→present, r→present
      expect(result, everyElement(TileState.present));
    });

    test('duplicate letter in guess — only one marked present', () {
      // answer = 'crane' has one 'a' at position 2
      // guess  = 'alarm' has two 'a's at positions 0 and 2
      // Pass 1 (correct): alarm[2]=='crane'[2] → correct; remaining['a'] drops to 0
      // Pass 2 (present): alarm[0]='a', but remaining['a']=0 → absent
      //                   alarm[3]='r', remaining['r']=1 → present
      final result = evaluateGuess('alarm', 'crane');
      expect(result[0], TileState.absent);   // 'a' — the only answer 'a' was consumed by pos 2
      expect(result[1], TileState.absent);   // 'l' — not in crane
      expect(result[2], TileState.correct);  // 'a' — exact match at pos 2
      expect(result[3], TileState.present);  // 'r' — in crane, wrong position
      expect(result[4], TileState.absent);   // 'm' — not in crane
    });

    test('correct takes priority over present for duplicates', () {
      // speed = s(0)p(1)e(2)e(3)d(4),  seedy = s(0)e(1)e(2)d(3)y(4)
      // Pass1: s0==s0→correct, e2==e2→correct; remaining after: p=1, e=1(pos3), d=1
      // Pass2: e1→present (remaining e=1), d3→present (remaining d=1), y4→absent
      final result = evaluateGuess('seedy', 'speed');
      expect(result[0], TileState.correct);  // s at pos 0 — exact match
      expect(result[1], TileState.present);  // e — in speed but wrong position
      expect(result[2], TileState.correct);  // e at pos 2 — exact match
      expect(result[3], TileState.present);  // d — in speed but wrong position
      expect(result[4], TileState.absent);   // y — not in speed
    });

    test('exact match on single repeated letter', () {
      final result = evaluateGuess('aabbb', 'aaxxx');
      // a0==a0→correct, a1==a1→correct, b2!=x2, b3!=x3, b4!=x4
      // remaining: nothing for b
      expect(result[0], TileState.correct);
      expect(result[1], TileState.correct);
      expect(result[2], TileState.absent);
      expect(result[3], TileState.absent);
      expect(result[4], TileState.absent);
    });

    test('result has exactly 5 elements', () {
      final result = evaluateGuess('hello', 'world');
      expect(result.length, 5);
    });
  });

  group('isCorrectGuess', () {
    test('all correct returns true', () {
      expect(
        isCorrectGuess(List.filled(5, TileState.correct)),
        isTrue,
      );
    });

    test('partial correct returns false', () {
      expect(
        isCorrectGuess([
          TileState.correct,
          TileState.absent,
          TileState.correct,
          TileState.correct,
          TileState.correct,
        ]),
        isFalse,
      );
    });
  });

  group('computeKeyboardState', () {
    test('correct beats present beats absent', () {
      final guesses = [
        (
          word: 'crane',
          evaluation: [
            TileState.absent,
            TileState.present,
            TileState.correct,
            TileState.absent,
            TileState.absent,
          ]
        ),
        (
          word: 'crabs',
          evaluation: [
            TileState.correct,
            TileState.correct,
            TileState.absent,
            TileState.absent,
            TileState.absent,
          ]
        ),
      ];

      final keyboard = computeKeyboardState(guesses);

      expect(keyboard['c'], TileState.correct); // correct in guess2 (beats absent in guess1)
      expect(keyboard['r'], TileState.correct); // correct in guess2 (beats present in guess1)
      expect(keyboard['a'], TileState.correct); // correct in guess1 (pos 2 of 'crane')
      expect(keyboard['n'], TileState.absent);
      expect(keyboard['e'], TileState.absent);
      expect(keyboard['b'], TileState.absent);
      expect(keyboard['s'], TileState.absent);
    });

    test('empty guesses returns empty map', () {
      expect(computeKeyboardState([]), isEmpty);
    });

    test('untried letter not in map', () {
      final guesses = [
        (word: 'crane', evaluation: List.filled(5, TileState.absent))
      ];
      final keyboard = computeKeyboardState(guesses);
      expect(keyboard.containsKey('z'), isFalse);
    });
  });
}
