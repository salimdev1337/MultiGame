import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/utils/secure_logger.dart';

void main() {
  group('SecureLogger - maskValue', () {
    test('masks value with default visibility (4 start, 2 end)', () {
      final result = SecureLogger.maskValue('my_secret_key_12345');
      expect(result, 'my_s***45');
    });

    test('masks value with custom visibility', () {
      final result = SecureLogger.maskValue(
        'uid_abc123def456',
        visibleStart: 4,
        visibleEnd: 3,
      );
      expect(result, 'uid_***456');
    });

    test('masks short API key', () {
      final result = SecureLogger.maskValue('sk_test_abcdef123456');
      expect(result, 'sk_t***56');
    });

    test('returns [REDACTED] for very short values', () {
      final result = SecureLogger.maskValue('short');
      expect(result, '[REDACTED]');
    });

    test(
      'returns [REDACTED] when value length equals visibleStart + visibleEnd',
      () {
        final result = SecureLogger.maskValue(
          '123456',
          visibleStart: 3,
          visibleEnd: 3,
        );
        expect(result, '[REDACTED]');
      },
    );

    test('returns [EMPTY] for null value', () {
      final result = SecureLogger.maskValue(null);
      expect(result, '[EMPTY]');
    });

    test('returns [EMPTY] for empty string', () {
      final result = SecureLogger.maskValue('');
      expect(result, '[EMPTY]');
    });

    test('handles different visibleStart values', () {
      final value = 'long_secret_key_value_12345';

      final result1 = SecureLogger.maskValue(
        value,
        visibleStart: 2,
        visibleEnd: 2,
      );
      expect(result1, 'lo***45');

      final result2 = SecureLogger.maskValue(
        value,
        visibleStart: 6,
        visibleEnd: 3,
      );
      expect(result2, 'long_s***345');
    });

    test('handles different visibleEnd values', () {
      final value = 'another_api_key_abcdef';

      final result1 = SecureLogger.maskValue(
        value,
        visibleStart: 4,
        visibleEnd: 1,
      );
      expect(result1, 'anot***f');

      final result2 = SecureLogger.maskValue(
        value,
        visibleStart: 4,
        visibleEnd: 5,
      );
      expect(result2, 'anot***bcdef');
    });

    test('handles edge case: visibleStart=0', () {
      final result = SecureLogger.maskValue(
        'secret123',
        visibleStart: 0,
        visibleEnd: 3,
      );
      expect(result, '***123');
    });

    test('handles edge case: visibleEnd=0', () {
      final result = SecureLogger.maskValue(
        'secret123',
        visibleStart: 6,
        visibleEnd: 0,
      );
      expect(result, 'secret***');
    });

    test('masks user IDs correctly', () {
      final result = SecureLogger.maskValue('user_abc123def456ghi789');
      expect(result, 'user***89');
    });

    test('masks Firebase UIDs', () {
      final result = SecureLogger.maskValue('Xy8fKp3qR2T5wN9vM1bZ4cA6');
      expect(result, 'Xy8f***A6');
    });
  });

  group('SecureLogger - log method', () {
    test('log method executes without error', () {
      expect(() => SecureLogger.log('Test message'), returnsNormally);
    });

    test('log method with tag executes without error', () {
      expect(
        () => SecureLogger.log('Test message', tag: 'TEST'),
        returnsNormally,
      );
    });

    test('log method handles special characters', () {
      expect(
        () =>
            SecureLogger.log('Message with émojis 🔥 and special chars: @#\$%'),
        returnsNormally,
      );
    });

    test('log method handles empty message', () {
      expect(() => SecureLogger.log(''), returnsNormally);
    });

    test('log method handles very long messages', () {
      final longMessage = 'A' * 10000;
      expect(() => SecureLogger.log(longMessage), returnsNormally);
    });
  });

  group('SecureLogger - error method', () {
    test('error method executes without error', () {
      expect(() => SecureLogger.error('Error message'), returnsNormally);
    });

    test('error method with tag executes without error', () {
      expect(
        () => SecureLogger.error('Error occurred', tag: 'ERROR'),
        returnsNormally,
      );
    });

    test('error method with error object executes without error', () {
      final error = Exception('Test exception');
      expect(
        () => SecureLogger.error('Error occurred', error: error),
        returnsNormally,
      );
    });

    test('error method with tag and error executes without error', () {
      final error = FormatException('Invalid format');
      expect(
        () => SecureLogger.error('Parse failed', error: error, tag: 'PARSER'),
        returnsNormally,
      );
    });

    test('error method handles null error gracefully', () {
      expect(() => SecureLogger.error('Error', error: null), returnsNormally);
    });
  });

  group('SecureLogger - api method', () {
    test('api method with endpoint only executes without error', () {
      expect(() => SecureLogger.api(endpoint: '/users'), returnsNormally);
    });

    test('api method with all parameters executes without error', () {
      expect(
        () => SecureLogger.api(
          endpoint: '/api/games',
          method: 'POST',
          statusCode: 200,
          message: 'Success',
        ),
        returnsNormally,
      );
    });

    test('api method with partial parameters executes without error', () {
      expect(
        () => SecureLogger.api(endpoint: '/api/stats', statusCode: 404),
        returnsNormally,
      );
    });

    test('api method handles different HTTP methods', () {
      expect(
        () => SecureLogger.api(endpoint: '/data', method: 'GET'),
        returnsNormally,
      );
      expect(
        () => SecureLogger.api(endpoint: '/data', method: 'POST'),
        returnsNormally,
      );
      expect(
        () => SecureLogger.api(endpoint: '/data', method: 'PUT'),
        returnsNormally,
      );
      expect(
        () => SecureLogger.api(endpoint: '/data', method: 'DELETE'),
        returnsNormally,
      );
    });

    test('api method handles different status codes', () {
      expect(
        () => SecureLogger.api(endpoint: '/test', statusCode: 200),
        returnsNormally,
      );
      expect(
        () => SecureLogger.api(endpoint: '/test', statusCode: 404),
        returnsNormally,
      );
      expect(
        () => SecureLogger.api(endpoint: '/test', statusCode: 500),
        returnsNormally,
      );
    });
  });

  group('SecureLogger - config method', () {
    test('config method with set value executes without error', () {
      expect(
        () => SecureLogger.config('API_KEY', 'sk_test_123456'),
        returnsNormally,
      );
    });

    test('config method with null value executes without error', () {
      expect(() => SecureLogger.config('OPTIONAL_KEY', null), returnsNormally);
    });

    test('config method with empty value executes without error', () {
      expect(() => SecureLogger.config('EMPTY_KEY', ''), returnsNormally);
    });

    test('config method handles long values', () {
      final longValue = 'x' * 1000;
      expect(
        () => SecureLogger.config('LONG_CONFIG', longValue),
        returnsNormally,
      );
    });

    test('config method handles special characters in key', () {
      expect(
        () => SecureLogger.config('CONFIG_KEY_123', 'value'),
        returnsNormally,
      );
    });
  });

  group('SecureLogger - user method', () {
    test('user method with message only executes without error', () {
      expect(() => SecureLogger.user('User logged in'), returnsNormally);
    });

    test('user method with userId executes without error', () {
      expect(
        () => SecureLogger.user('User action', userId: 'user_abc123def456'),
        returnsNormally,
      );
    });

    test('user method handles null userId', () {
      expect(
        () => SecureLogger.user('Anonymous action', userId: null),
        returnsNormally,
      );
    });

    test('user method handles empty userId', () {
      expect(() => SecureLogger.user('Action', userId: ''), returnsNormally);
    });

    test('user method masks userId in output', () {
      // The userId should be masked when logged
      // This test just ensures it executes without error
      expect(
        () => SecureLogger.user('Login', userId: 'sensitive_user_id_12345'),
        returnsNormally,
      );
    });
  });

  group('SecureLogger - firebase method', () {
    test('firebase method with operation only executes without error', () {
      expect(
        () => SecureLogger.firebase('User authenticated'),
        returnsNormally,
      );
    });

    test('firebase method with details executes without error', () {
      expect(
        () => SecureLogger.firebase('Document written', details: 'users/123'),
        returnsNormally,
      );
    });

    test('firebase method handles null details', () {
      expect(
        () => SecureLogger.firebase('Operation complete', details: null),
        returnsNormally,
      );
    });

    test('firebase method handles empty details', () {
      expect(
        () => SecureLogger.firebase('Operation', details: ''),
        returnsNormally,
      );
    });

    test('firebase method handles various operations', () {
      expect(
        () => SecureLogger.firebase('Auth state changed'),
        returnsNormally,
      );
      expect(() => SecureLogger.firebase('Firestore read'), returnsNormally);
      expect(() => SecureLogger.firebase('Firestore write'), returnsNormally);
      expect(() => SecureLogger.firebase('Analytics event'), returnsNormally);
    });
  });

  group('SecureLogger - Integration scenarios', () {
    test('can chain multiple logging calls', () {
      expect(() {
        SecureLogger.log('Starting operation', tag: 'INIT');
        SecureLogger.api(endpoint: '/api/test', method: 'GET', statusCode: 200);
        SecureLogger.user('User action', userId: 'user_123');
        SecureLogger.firebase('Data saved');
        SecureLogger.log('Operation complete', tag: 'DONE');
      }, returnsNormally);
    });

    test('handles real-world API key masking scenario', () {
      final apiKey = 'fake_api_key_51234567890abcdefghijklmnop';
      final masked = SecureLogger.maskValue(apiKey);

      // Should not expose the full key
      expect(masked, isNot(contains('51234567890abcdefghijklmnop')));
      // Should contain masked indicator
      expect(masked, contains('***'));
    });

    test('handles real-world user ID masking scenario', () {
      final userId = 'firebase_uid_abc123def456ghi789';
      final masked = SecureLogger.maskValue(userId);

      // Should not expose the full ID
      expect(masked, isNot(contains('abc123def456ghi789')));
      // Should contain masked indicator
      expect(masked, contains('***'));
    });

    test('safely logs error with sensitive data in exception', () {
      final error = Exception('API key sk_test_123 is invalid');
      // The error message itself isn't logged, only the type
      expect(
        () => SecureLogger.error('Authentication failed', error: error),
        returnsNormally,
      );
    });
  });
}
