import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:multigame/repositories/secure_storage_repository.dart';

// Mock implementation of FlutterSecureStorage for testing
class MockFlutterSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

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

  @override
  Future<bool> isCupertinoProtectedDataAvailable() async => true;

  @override
  void registerListener({
    required String key,
    required void Function(String value) listener,
  }) {}

  @override
  void unregisterAllListeners() {}

  @override
  void unregisterAllListenersForKey({required String key}) {}

  @override
  void unregisterListener({
    required String key,
    required void Function(String value) listener,
  }) {}

  // Stub methods for completeness
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  // Helper method for testing
  void clear() {
    _storage.clear();
  }
}

void main() {
  late SecureStorageRepository repository;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    repository = SecureStorageRepository(storage: mockStorage);
  });

  tearDown(() {
    mockStorage.clear();
  });

  group('SecureStorageRepository - read', () {
    test('reads existing value from storage', () async {
      await mockStorage.write(key: 'test_key', value: 'test_value');

      final result = await repository.read('test_key');

      expect(result, 'test_value');
    });

    test('returns null for non-existent key', () async {
      final result = await repository.read('nonexistent_key');

      expect(result, isNull);
    });

    test('reads empty string value', () async {
      await mockStorage.write(key: 'empty_key', value: '');

      final result = await repository.read('empty_key');

      expect(result, '');
    });

    test('reads value with special characters', () async {
      await mockStorage.write(
        key: 'special_key',
        value: 'Value with émojis 🔥 and symbols: @#\$%',
      );

      final result = await repository.read('special_key');

      expect(result, 'Value with émojis 🔥 and symbols: @#\$%');
    });

    test('reads very long values', () async {
      final longValue = 'x' * 10000;
      await mockStorage.write(key: 'long_key', value: longValue);

      final result = await repository.read('long_key');

      expect(result, longValue);
    });
  });

  group('SecureStorageRepository - write', () {
    test('writes value to storage successfully', () async {
      final result = await repository.write('test_key', 'test_value');

      expect(result, true);

      final readValue = await mockStorage.read(key: 'test_key');
      expect(readValue, 'test_value');
    });

    test('writes empty string', () async {
      final result = await repository.write('empty_key', '');

      expect(result, true);
      expect(await mockStorage.read(key: 'empty_key'), '');
    });

    test('overwrites existing value', () async {
      await repository.write('key', 'old_value');
      final result = await repository.write('key', 'new_value');

      expect(result, true);
      expect(await mockStorage.read(key: 'key'), 'new_value');
    });

    test('writes value with special characters', () async {
      final result = await repository.write(
        'special',
        'Émojis 🚀 and symbols: !@#\$%^&*()',
      );

      expect(result, true);
      expect(
        await mockStorage.read(key: 'special'),
        'Émojis 🚀 and symbols: !@#\$%^&*()',
      );
    });

    test('writes very long value', () async {
      final longValue = 'y' * 10000;
      final result = await repository.write('long', longValue);

      expect(result, true);
      expect(await mockStorage.read(key: 'long'), longValue);
    });

    test('writes multiple different keys', () async {
      await repository.write('key1', 'value1');
      await repository.write('key2', 'value2');
      await repository.write('key3', 'value3');

      expect(await mockStorage.read(key: 'key1'), 'value1');
      expect(await mockStorage.read(key: 'key2'), 'value2');
      expect(await mockStorage.read(key: 'key3'), 'value3');
    });

    test('writes user_id correctly', () async {
      final result = await repository.write('user_id', 'uid_abc123');

      expect(result, true);
      expect(await mockStorage.read(key: 'user_id'), 'uid_abc123');
    });

    test('writes user_nickname correctly', () async {
      final result = await repository.write('user_nickname', 'CoolPlayer');

      expect(result, true);
      expect(await mockStorage.read(key: 'user_nickname'), 'CoolPlayer');
    });
  });

  group('SecureStorageRepository - delete', () {
    test('deletes existing value', () async {
      await repository.write('test_key', 'test_value');

      final result = await repository.delete('test_key');

      expect(result, true);
      expect(await mockStorage.read(key: 'test_key'), isNull);
    });

    test('delete non-existent key succeeds', () async {
      final result = await repository.delete('nonexistent');

      expect(result, true);
    });

    test('deletes multiple keys independently', () async {
      await repository.write('key1', 'value1');
      await repository.write('key2', 'value2');
      await repository.write('key3', 'value3');

      await repository.delete('key2');

      expect(await mockStorage.read(key: 'key1'), 'value1');
      expect(await mockStorage.read(key: 'key2'), isNull);
      expect(await mockStorage.read(key: 'key3'), 'value3');
    });

    test('delete allows re-writing same key', () async {
      await repository.write('key', 'value1');
      await repository.delete('key');
      await repository.write('key', 'value2');

      expect(await mockStorage.read(key: 'key'), 'value2');
    });
  });

  group('SecureStorageRepository - containsKey', () {
    test('returns true for existing key', () async {
      await repository.write('test_key', 'test_value');

      final result = await repository.containsKey('test_key');

      expect(result, true);
    });

    test('returns false for non-existent key', () async {
      final result = await repository.containsKey('nonexistent');

      expect(result, false);
    });

    test('returns false for deleted key', () async {
      await repository.write('key', 'value');
      await repository.delete('key');

      final result = await repository.containsKey('key');

      expect(result, false);
    });

    test('returns true for empty string value', () async {
      await repository.write('empty', '');

      final result = await repository.containsKey('empty');

      expect(result, true);
    });
  });

  group('SecureStorageRepository - readAll', () {
    test('returns empty map when storage is empty', () async {
      final result = await repository.readAll();

      expect(result, isEmpty);
    });

    test('returns all stored values', () async {
      await repository.write('key1', 'value1');
      await repository.write('key2', 'value2');
      await repository.write('key3', 'value3');

      final result = await repository.readAll();

      expect(result.length, 3);
      expect(result['key1'], 'value1');
      expect(result['key2'], 'value2');
      expect(result['key3'], 'value3');
    });

    test('returns map after some deletions', () async {
      await repository.write('key1', 'value1');
      await repository.write('key2', 'value2');
      await repository.write('key3', 'value3');
      await repository.delete('key2');

      final result = await repository.readAll();

      expect(result.length, 2);
      expect(result['key1'], 'value1');
      expect(result['key3'], 'value3');
      expect(result.containsKey('key2'), false);
    });

    test('returns copy of storage (not reference)', () async {
      await repository.write('key', 'value');

      final result1 = await repository.readAll();
      final result2 = await repository.readAll();

      expect(identical(result1, result2), false);
    });
  });

  group('SecureStorageRepository - deleteAll', () {
    test('deletes all values from storage', () async {
      await repository.write('key1', 'value1');
      await repository.write('key2', 'value2');
      await repository.write('key3', 'value3');

      final result = await repository.deleteAll();

      expect(result, true);

      final allData = await repository.readAll();
      expect(allData, isEmpty);
    });

    test('deleteAll on empty storage succeeds', () async {
      final result = await repository.deleteAll();

      expect(result, true);
    });

    test('allows writing after deleteAll', () async {
      await repository.write('key1', 'value1');
      await repository.deleteAll();
      await repository.write('key2', 'value2');

      final allData = await repository.readAll();
      expect(allData.length, 1);
      expect(allData['key2'], 'value2');
    });

    test('deleteAll removes all keys individually', () async {
      await repository.write('user_id', 'uid_123');
      await repository.write('user_nickname', 'Player1');
      await repository.write('api_token', 'token_abc');

      await repository.deleteAll();

      expect(await repository.containsKey('user_id'), false);
      expect(await repository.containsKey('user_nickname'), false);
      expect(await repository.containsKey('api_token'), false);
    });
  });

  group('SecureStorageRepository - Integration scenarios', () {
    test('write, read, delete workflow', () async {
      // Write
      await repository.write('test_key', 'test_value');
      expect(await repository.containsKey('test_key'), true);

      // Read
      final readValue = await repository.read('test_key');
      expect(readValue, 'test_value');

      // Delete
      await repository.delete('test_key');
      expect(await repository.containsKey('test_key'), false);
      expect(await repository.read('test_key'), isNull);
    });

    test('stores sensitive user data correctly', () async {
      await repository.write('user_id', 'firebase_uid_abc123');
      await repository.write('user_nickname', 'SecretPlayer');
      await repository.write('auth_token', 'bearer_token_xyz789');

      expect(await repository.read('user_id'), 'firebase_uid_abc123');
      expect(await repository.read('user_nickname'), 'SecretPlayer');
      expect(await repository.read('auth_token'), 'bearer_token_xyz789');
    });

    test('handles multiple writes and reads', () async {
      for (int i = 0; i < 10; i++) {
        await repository.write('key_$i', 'value_$i');
      }

      for (int i = 0; i < 10; i++) {
        final value = await repository.read('key_$i');
        expect(value, 'value_$i');
      }

      final allData = await repository.readAll();
      expect(allData.length, 10);
    });

    test('preserves data isolation between keys', () async {
      await repository.write('user_id', 'uid_123');
      await repository.write('user_id_backup', 'uid_456');

      // Deleting one should not affect the other
      await repository.delete('user_id');

      expect(await repository.read('user_id'), isNull);
      expect(await repository.read('user_id_backup'), 'uid_456');
    });

    test('handles rapid write/delete operations', () async {
      await repository.write('key', 'value1');
      await repository.delete('key');
      await repository.write('key', 'value2');
      await repository.delete('key');
      await repository.write('key', 'value3');

      expect(await repository.read('key'), 'value3');
    });

    test('stores and retrieves UTF-8 strings correctly', () async {
      await repository.write('chinese', '你好世界');
      await repository.write('arabic', 'مرحبا بالعالم');
      await repository.write('russian', 'Привет мир');
      await repository.write('emoji', '🌍🚀💻🎮');

      expect(await repository.read('chinese'), '你好世界');
      expect(await repository.read('arabic'), 'مرحبا بالعالم');
      expect(await repository.read('russian'), 'Привет мир');
      expect(await repository.read('emoji'), '🌍🚀💻🎮');
    });
  });
}
