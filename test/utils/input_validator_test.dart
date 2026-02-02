import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/utils/input_validator.dart';

void main() {
  group('InputValidator - validateNickname', () {
    test('accepts valid nickname with letters and numbers', () {
      final result = InputValidator.validateNickname('Player123');
      expect(result.isValid, true);
      expect(result.value, 'Player123');
      expect(result.error, null);
    });

    test('accepts nickname with spaces', () {
      final result = InputValidator.validateNickname('Cool Player');
      expect(result.isValid, true);
      expect(result.value, 'Cool Player');
    });

    test('accepts nickname with hyphens and underscores', () {
      final result = InputValidator.validateNickname('Player_123-Pro');
      expect(result.isValid, true);
    });

    test('accepts minimum length nickname (2 chars)', () {
      final result = InputValidator.validateNickname('AB');
      expect(result.isValid, true);
    });

    test('accepts maximum length nickname (20 chars)', () {
      final result = InputValidator.validateNickname('A' * 20);
      expect(result.isValid, true);
    });

    test('rejects nickname that is too short (1 char)', () {
      final result = InputValidator.validateNickname('A');
      expect(result.isValid, false);
      expect(result.error, contains('2 and 20 characters'));
    });

    test('rejects nickname that is too long (21 chars)', () {
      final result = InputValidator.validateNickname('A' * 21);
      expect(result.isValid, false);
      expect(result.error, contains('2 and 20 characters'));
    });

    test('rejects nickname with leading whitespace', () {
      final result = InputValidator.validateNickname(' Player');
      expect(result.isValid, false);
      expect(result.error, contains('leading or trailing whitespace'));
    });

    test('rejects nickname with trailing whitespace', () {
      final result = InputValidator.validateNickname('Player ');
      expect(result.isValid, false);
      expect(result.error, contains('leading or trailing whitespace'));
    });

    test('rejects nickname with consecutive spaces', () {
      final result = InputValidator.validateNickname('Cool  Player');
      expect(result.isValid, false);
      expect(result.error, contains('consecutive spaces'));
    });

    test('rejects nickname with special characters', () {
      final result = InputValidator.validateNickname('Player@123');
      expect(result.isValid, false);
      expect(result.error, contains('alphanumeric'));
    });

    test('rejects nickname with emoji', () {
      final result = InputValidator.validateNickname('Player😀');
      expect(result.isValid, false);
    });

    test('rejects empty nickname', () {
      final result = InputValidator.validateNickname('');
      expect(result.isValid, false);
      expect(result.error, contains('empty'));
    });
  });

  group('InputValidator - sanitizeForFirestore', () {
    test('trims leading and trailing whitespace', () {
      final result = InputValidator.sanitizeForFirestore('  Player  ');
      expect(result, 'Player');
    });

    test('collapses multiple spaces to single space', () {
      final result = InputValidator.sanitizeForFirestore('Cool   Player   Name');
      expect(result, 'Cool Player Name');
    });

    test('removes control characters', () {
      final result = InputValidator.sanitizeForFirestore('Player\x00\x01\x1F');
      expect(result, 'Player');
    });

    test('removes HTML tags', () {
      final result = InputValidator.sanitizeForFirestore('<script>alert("XSS")</script>Player');
      expect(result, 'Player');
    });

    test('handles complex HTML', () {
      final result = InputValidator.sanitizeForFirestore('<div class="test">Player<span>123</span></div>');
      expect(result, 'Player123');
    });

    test('handles empty string', () {
      final result = InputValidator.sanitizeForFirestore('');
      expect(result, '');
    });

    test('handles string with only whitespace', () {
      final result = InputValidator.sanitizeForFirestore('   ');
      expect(result, '');
    });
  });

  group('InputValidator - validateScore', () {
    test('accepts valid score within default range', () {
      final result = InputValidator.validateScore(500);
      expect(result.isValid, true);
      expect(result.value, 500);
    });

    test('accepts minimum score (0)', () {
      final result = InputValidator.validateScore(0);
      expect(result.isValid, true);
    });

    test('accepts maximum score (100000)', () {
      final result = InputValidator.validateScore(100000);
      expect(result.isValid, true);
    });

    test('accepts custom min value', () {
      final result = InputValidator.validateScore(50, min: 50);
      expect(result.isValid, true);
    });

    test('accepts custom max value', () {
      final result = InputValidator.validateScore(200, max: 200);
      expect(result.isValid, true);
    });

    test('rejects negative score', () {
      final result = InputValidator.validateScore(-10);
      expect(result.isValid, false);
      expect(result.error, contains('between 0 and 100000'));
    });

    test('rejects score above maximum', () {
      final result = InputValidator.validateScore(100001);
      expect(result.isValid, false);
      expect(result.error, contains('between 0 and 100000'));
    });

    test('rejects score below custom minimum', () {
      final result = InputValidator.validateScore(49, min: 50);
      expect(result.isValid, false);
      expect(result.error, contains('between 50'));
    });

    test('rejects score above custom maximum', () {
      final result = InputValidator.validateScore(201, max: 200);
      expect(result.isValid, false);
      expect(result.error, contains('maximum'));
    });
  });

  group('InputValidator - validateGameType', () {
    test('accepts valid game type: puzzle', () {
      final result = InputValidator.validateGameType('puzzle');
      expect(result.isValid, true);
      expect(result.value, 'puzzle');
    });

    test('accepts valid game type: 2048', () {
      final result = InputValidator.validateGameType('2048');
      expect(result.isValid, true);
    });

    test('accepts valid game type: snake', () {
      final result = InputValidator.validateGameType('snake');
      expect(result.isValid, true);
    });

    test('accepts valid game type: infinite_runner', () {
      final result = InputValidator.validateGameType('infinite_runner');
      expect(result.isValid, true);
    });

    test('rejects invalid game type', () {
      final result = InputValidator.validateGameType('tetris');
      expect(result.isValid, false);
      expect(result.error, contains('Valid game types'));
    });

    test('rejects empty game type', () {
      final result = InputValidator.validateGameType('');
      expect(result.isValid, false);
      expect(result.error, contains('Invalid'));
    });

    test('is case sensitive', () {
      final result = InputValidator.validateGameType('PUZZLE');
      expect(result.isValid, false);
    });
  });

  group('InputValidator - containsDangerousChars', () {
    test('detects script tag', () {
      expect(InputValidator.containsDangerousChars('<script>'), true);
    });

    test('detects javascript protocol', () {
      expect(InputValidator.containsDangerousChars('javascript:alert(1)'), true);
    });

    test('detects SQL injection attempt', () {
      expect(InputValidator.containsDangerousChars("' OR '1'='1"), true);
    });

    test('detects SQL comment', () {
      expect(InputValidator.containsDangerousChars('admin--'), true);
    });

    test('detects SQL UNION', () {
      expect(InputValidator.containsDangerousChars('UNION SELECT'), true);
    });

    test('allows safe alphanumeric string', () {
      expect(InputValidator.containsDangerousChars('Player123'), false);
    });

    test('allows safe string with spaces and hyphens', () {
      expect(InputValidator.containsDangerousChars('Cool-Player 123'), false);
    });

    test('returns false for empty string', () {
      expect(InputValidator.containsDangerousChars(''), false);
    });

    test('detects onclick attribute', () {
      expect(InputValidator.containsDangerousChars('onclick='), true);
    });

    test('detects onerror attribute', () {
      expect(InputValidator.containsDangerousChars('onerror='), true);
    });
  });

  group('ValidationResult', () {
    test('success creates valid result', () {
      final result = ValidationResult.success('test_value');
      expect(result.isValid, true);
      expect(result.value, 'test_value');
      expect(result.error, null);
    });

    test('error creates invalid result', () {
      final result = ValidationResult.error('test error message');
      expect(result.isValid, false);
      expect(result.value, null);
      expect(result.error, 'test error message');
    });

    test('success can hold different types', () {
      final intResult = ValidationResult.success(123);
      expect(intResult.value, 123);

      final boolResult = ValidationResult.success(true);
      expect(boolResult.value, true);
    });
  });
}
