import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multigame/utils/storage_migrator.dart';
import 'package:multigame/repositories/secure_storage_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Mock implementation of FlutterSecureStorage for testing
class MockFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_storage);
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    }
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage.containsKey(key);
  }
}

void main() {
  late StorageMigrator migrator;
  late SecureStorageRepository secureStorage;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockStorage = MockFlutterSecureStorage();
    secureStorage = SecureStorageRepository(storage: mockStorage);
    migrator = StorageMigrator(secureStorage);
  });

  group('StorageMigrator - migrateKey', () {
    test('migrates key from SharedPreferences to SecureStorage', () async {
      // Setup: Add data to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('test_key', 'test_value');

      // Migrate
      final result = await migrator.migrateKey('test_key');

      // Verify migration succeeded
      expect(result, true);

      // Verify value is in SecureStorage
      final secureValue = await secureStorage.read('test_key');
      expect(secureValue, 'test_value');

      // Verify value is removed from SharedPreferences
      expect(prefs.containsKey('test_key'), false);
    });

    test(
      'returns false when key does not exist in SharedPreferences',
      () async {
        final result = await migrator.migrateKey('nonexistent_key');
        expect(result, false);
      },
    );

    test('returns false when key has null value', () async {
      final prefs = await SharedPreferences.getInstance();
      // Set then remove to simulate null value scenario
      await prefs.setString('null_key', 'temp');
      await prefs.remove('null_key');

      final result = await migrator.migrateKey('null_key');
      expect(result, false);
    });

    test('handles already migrated key', () async {
      // Setup: Add to both storages
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('existing_key', 'old_value');
      await secureStorage.write('existing_key', 'migrated_value');

      // Migrate
      final result = await migrator.migrateKey('existing_key');

      // Should return true and clean up SharedPreferences
      expect(result, true);
      expect(prefs.containsKey('existing_key'), false);

      // SecureStorage should still have its value
      final secureValue = await secureStorage.read('existing_key');
      expect(secureValue, 'migrated_value');
    });

    test('migrates user_id correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', 'user_abc123');

      final result = await migrator.migrateKey('user_id');

      expect(result, true);
      expect(await secureStorage.read('user_id'), 'user_abc123');
      expect(prefs.containsKey('user_id'), false);
    });

    test('migrates user_nickname correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_nickname', 'CoolPlayer');

      final result = await migrator.migrateKey('user_nickname');

      expect(result, true);
      expect(await secureStorage.read('user_nickname'), 'CoolPlayer');
      expect(prefs.containsKey('user_nickname'), false);
    });

    test('handles special characters in values', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'special_key',
        'Value with émojis 🔥 and symbols: @#\$%',
      );

      final result = await migrator.migrateKey('special_key');

      expect(result, true);
      expect(
        await secureStorage.read('special_key'),
        'Value with émojis 🔥 and symbols: @#\$%',
      );
    });

    test('handles empty string values', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('empty_key', '');

      final result = await migrator.migrateKey('empty_key');

      expect(result, true);
      expect(await secureStorage.read('empty_key'), '');
    });

    test('handles very long values', () async {
      final prefs = await SharedPreferences.getInstance();
      final longValue = 'x' * 10000;
      await prefs.setString('long_key', longValue);

      final result = await migrator.migrateKey('long_key');

      expect(result, true);
      expect(await secureStorage.read('long_key'), longValue);
    });
  });

  group('StorageMigrator - migrateKeys', () {
    test('migrates multiple keys successfully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('key1', 'value1');
      await prefs.setString('key2', 'value2');
      await prefs.setString('key3', 'value3');

      final results = await migrator.migrateKeys(['key1', 'key2', 'key3']);

      expect(results['key1'], true);
      expect(results['key2'], true);
      expect(results['key3'], true);

      // Verify all are in SecureStorage
      expect(await secureStorage.read('key1'), 'value1');
      expect(await secureStorage.read('key2'), 'value2');
      expect(await secureStorage.read('key3'), 'value3');

      // Verify all removed from SharedPreferences
      expect(prefs.containsKey('key1'), false);
      expect(prefs.containsKey('key2'), false);
      expect(prefs.containsKey('key3'), false);
    });

    test('handles mix of existing and non-existing keys', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('exists1', 'value1');
      await prefs.setString('exists2', 'value2');

      final results = await migrator.migrateKeys([
        'exists1',
        'nonexistent',
        'exists2',
      ]);

      expect(results['exists1'], true);
      expect(results['nonexistent'], false);
      expect(results['exists2'], true);
    });

    test('handles empty key list', () async {
      final results = await migrator.migrateKeys([]);
      expect(results, isEmpty);
    });

    test('handles single key in list', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('single', 'value');

      final results = await migrator.migrateKeys(['single']);

      expect(results.length, 1);
      expect(results['single'], true);
    });

    test('migrates keys in order', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('first', '1');
      await prefs.setString('second', '2');
      await prefs.setString('third', '3');

      final results = await migrator.migrateKeys(['first', 'second', 'third']);

      // Results should maintain order
      final keys = results.keys.toList();
      expect(keys[0], 'first');
      expect(keys[1], 'second');
      expect(keys[2], 'third');
    });
  });

  group('StorageMigrator - migrateSensitiveData', () {
    test('migrates user_id and user_nickname', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', 'uid_123');
      await prefs.setString('user_nickname', 'Player1');

      final result = await migrator.migrateSensitiveData();

      expect(result, true);
      expect(await secureStorage.read('user_id'), 'uid_123');
      expect(await secureStorage.read('user_nickname'), 'Player1');
      expect(prefs.containsKey('user_id'), false);
      expect(prefs.containsKey('user_nickname'), false);
    });

    test('returns true when only user_id exists', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', 'uid_456');

      final result = await migrator.migrateSensitiveData();

      expect(result, true);
      expect(await secureStorage.read('user_id'), 'uid_456');
    });

    test('returns true when only user_nickname exists', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_nickname', 'Player2');

      final result = await migrator.migrateSensitiveData();

      expect(result, true);
      expect(await secureStorage.read('user_nickname'), 'Player2');
    });

    test('returns true when no sensitive data exists', () async {
      // No data to migrate
      final result = await migrator.migrateSensitiveData();
      expect(result, true);
    });

    test('does not affect other SharedPreferences data', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', 'uid_789');
      await prefs.setString('achievement_data', 'some_achievement');
      await prefs.setInt('high_score', 1000);
      await prefs.setBool('sound_enabled', true);

      await migrator.migrateSensitiveData();

      // Sensitive data migrated
      expect(prefs.containsKey('user_id'), false);

      // Other data remains
      expect(prefs.getString('achievement_data'), 'some_achievement');
      expect(prefs.getInt('high_score'), 1000);
      expect(prefs.getBool('sound_enabled'), true);
    });

    test('handles already migrated data', () async {
      // Pre-migrate data
      await secureStorage.write('user_id', 'existing_uid');
      await secureStorage.write('user_nickname', 'existing_name');

      final result = await migrator.migrateSensitiveData();

      // Should still return true
      expect(result, true);

      // Data should remain in SecureStorage
      expect(await secureStorage.read('user_id'), 'existing_uid');
      expect(await secureStorage.read('user_nickname'), 'existing_name');
    });
  });

  group('StorageMigrator - isMigrationComplete', () {
    test(
      'returns false when sensitive keys exist in SharedPreferences',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', 'uid_123');

        final result = await migrator.isMigrationComplete();
        expect(result, false);
      },
    );

    test(
      'returns false when user_nickname exists in SharedPreferences',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_nickname', 'Player1');

        final result = await migrator.isMigrationComplete();
        expect(result, false);
      },
    );

    test('returns false when both sensitive keys exist', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', 'uid_456');
      await prefs.setString('user_nickname', 'Player2');

      final result = await migrator.isMigrationComplete();
      expect(result, false);
    });

    test('returns true when no sensitive keys in SharedPreferences', () async {
      final result = await migrator.isMigrationComplete();
      expect(result, true);
    });

    test('returns true after successful migration', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', 'uid_789');
      await prefs.setString('user_nickname', 'Player3');

      // Before migration
      expect(await migrator.isMigrationComplete(), false);

      // Migrate
      await migrator.migrateSensitiveData();

      // After migration
      expect(await migrator.isMigrationComplete(), true);
    });

    test('ignores non-sensitive keys in SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('achievement_data', 'data');
      await prefs.setInt('high_score', 500);

      // Should be complete since no sensitive keys exist
      final result = await migrator.isMigrationComplete();
      expect(result, true);
    });
  });

  group('StorageMigrator - markMigrationComplete', () {
    test('marks migration as complete', () async {
      await migrator.markMigrationComplete();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('migration_complete'), true);
    });

    test('can mark as complete multiple times', () async {
      await migrator.markMigrationComplete();
      await migrator.markMigrationComplete();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('migration_complete'), true);
    });

    test('sets flag even when no migration needed', () async {
      // No data to migrate
      await migrator.markMigrationComplete();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('migration_complete'), true);
    });
  });

  group('StorageMigrator - Integration scenarios', () {
    test('full migration workflow', () async {
      final prefs = await SharedPreferences.getInstance();

      // 1. Initial state: data in SharedPreferences
      await prefs.setString('user_id', 'initial_uid');
      await prefs.setString('user_nickname', 'InitialPlayer');
      expect(await migrator.isMigrationComplete(), false);

      // 2. Perform migration
      final migrateResult = await migrator.migrateSensitiveData();
      expect(migrateResult, true);

      // 3. Check migration complete
      expect(await migrator.isMigrationComplete(), true);

      // 4. Verify data in SecureStorage
      expect(await secureStorage.read('user_id'), 'initial_uid');
      expect(await secureStorage.read('user_nickname'), 'InitialPlayer');

      // 5. Mark as complete
      await migrator.markMigrationComplete();
      expect(prefs.getBool('migration_complete'), true);
    });

    test('handles repeated migration attempts safely', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', 'uid_repeat');

      // First migration
      final result1 = await migrator.migrateSensitiveData();
      expect(result1, true);

      // Second migration (should be idempotent)
      final result2 = await migrator.migrateSensitiveData();
      expect(result2, true);

      // Data should still be correct
      expect(await secureStorage.read('user_id'), 'uid_repeat');
      expect(await migrator.isMigrationComplete(), true);
    });

    test('preserves data integrity during migration', () async {
      final prefs = await SharedPreferences.getInstance();

      // Setup complex data
      final userId = 'user_abc123def456';
      final nickname = 'Player With Spaces';
      await prefs.setString('user_id', userId);
      await prefs.setString('user_nickname', nickname);
      await prefs.setInt('score', 9999);

      // Migrate
      await migrator.migrateSensitiveData();

      // Verify exact values preserved
      expect(await secureStorage.read('user_id'), userId);
      expect(await secureStorage.read('user_nickname'), nickname);

      // Non-sensitive data still in SharedPreferences
      expect(prefs.getInt('score'), 9999);
    });

    test('handles migration with special characters', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', 'uid-with-dashes_and_underscores');
      await prefs.setString('user_nickname', 'Player-123_Pro');

      await migrator.migrateSensitiveData();

      expect(
        await secureStorage.read('user_id'),
        'uid-with-dashes_and_underscores',
      );
      expect(await secureStorage.read('user_nickname'), 'Player-123_Pro');
      expect(await migrator.isMigrationComplete(), true);
    });
  });
}
