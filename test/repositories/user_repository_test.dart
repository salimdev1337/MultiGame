import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/repositories/user_repository.dart';
import 'package:multigame/repositories/secure_storage_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void clear() {
    _storage.clear();
  }
}

void main() {
  late UserRepository repository;
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageRepository secureStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureStorage = SecureStorageRepository(storage: mockStorage);
    repository = SecureUserRepository(secureStorage: secureStorage);
  });

  tearDown(() {
    mockStorage.clear();
  });

  group('UserRepository - getUserId', () {
    test('returns null when no user ID is stored', () async {
      final result = await repository.getUserId();
      expect(result, isNull);
    });

    test('returns stored user ID', () async {
      await repository.saveUserId('user_123');

      final result = await repository.getUserId();
      expect(result, 'user_123');
    });

    test('returns updated user ID after change', () async {
      await repository.saveUserId('user_old');
      await repository.saveUserId('user_new');

      final result = await repository.getUserId();
      expect(result, 'user_new');
    });
  });

  group('UserRepository - saveUserId', () {
    test('saves user ID successfully', () async {
      final result = await repository.saveUserId('user_abc123');

      expect(result, true);
      expect(await repository.getUserId(), 'user_abc123');
    });

    test('overwrites existing user ID', () async {
      await repository.saveUserId('user_old');
      final result = await repository.saveUserId('user_new');

      expect(result, true);
      expect(await repository.getUserId(), 'user_new');
    });

    test('saves Firebase UID format', () async {
      final firebaseUid = 'Xy8fKp3qR2T5wN9vM1bZ4cA6';
      final result = await repository.saveUserId(firebaseUid);

      expect(result, true);
      expect(await repository.getUserId(), firebaseUid);
    });

    test('saves user ID with special characters', () async {
      final result = await repository.saveUserId('user_id-with_dashes-123');

      expect(result, true);
      expect(await repository.getUserId(), 'user_id-with_dashes-123');
    });
  });

  group('UserRepository - hasUserId', () {
    test('returns false when no user ID is stored', () async {
      final result = await repository.hasUserId();
      expect(result, false);
    });

    test('returns true when user ID is stored', () async {
      await repository.saveUserId('user_456');

      final result = await repository.hasUserId();
      expect(result, true);
    });

    test('returns false after user ID is cleared', () async {
      await repository.saveUserId('user_789');
      await repository.clearUserId();

      final result = await repository.hasUserId();
      expect(result, false);
    });
  });

  group('UserRepository - clearUserId', () {
    test('clears existing user ID', () async {
      await repository.saveUserId('user_to_delete');

      final result = await repository.clearUserId();

      expect(result, true);
      expect(await repository.getUserId(), isNull);
      expect(await repository.hasUserId(), false);
    });

    test('succeeds when no user ID exists', () async {
      final result = await repository.clearUserId();
      expect(result, true);
    });

    test('allows saving new user ID after clear', () async {
      await repository.saveUserId('user_old');
      await repository.clearUserId();
      await repository.saveUserId('user_new');

      expect(await repository.getUserId(), 'user_new');
    });
  });

  group('UserRepository - getDisplayName', () {
    test('returns null when no display name is stored', () async {
      final result = await repository.getDisplayName();
      expect(result, isNull);
    });

    test('returns stored display name', () async {
      await repository.saveDisplayName('CoolPlayer');

      final result = await repository.getDisplayName();
      expect(result, 'CoolPlayer');
    });

    test('returns updated display name after change', () async {
      await repository.saveDisplayName('OldName');
      await repository.saveDisplayName('NewName');

      final result = await repository.getDisplayName();
      expect(result, 'NewName');
    });
  });

  group('UserRepository - saveDisplayName', () {
    test('saves display name successfully', () async {
      final result = await repository.saveDisplayName('Player123');

      expect(result, true);
      expect(await repository.getDisplayName(), 'Player123');
    });

    test('overwrites existing display name', () async {
      await repository.saveDisplayName('OldName');
      final result = await repository.saveDisplayName('NewName');

      expect(result, true);
      expect(await repository.getDisplayName(), 'NewName');
    });

    test('saves display name with spaces', () async {
      final result = await repository.saveDisplayName('Cool Player');

      expect(result, true);
      expect(await repository.getDisplayName(), 'Cool Player');
    });

    test('saves display name with special characters', () async {
      final result = await repository.saveDisplayName('Player_123-Pro');

      expect(result, true);
      expect(await repository.getDisplayName(), 'Player_123-Pro');
    });

    test('saves display name with Unicode characters', () async {
      final result = await repository.saveDisplayName('Игрок');

      expect(result, true);
      expect(await repository.getDisplayName(), 'Игрок');
    });
  });

  group('UserRepository - hasDisplayName', () {
    test('returns false when no display name is stored', () async {
      final result = await repository.hasDisplayName();
      expect(result, false);
    });

    test('returns true when display name is stored', () async {
      await repository.saveDisplayName('TestPlayer');

      final result = await repository.hasDisplayName();
      expect(result, true);
    });

    test('returns false after display name is cleared', () async {
      await repository.saveDisplayName('TempName');
      await repository.clearDisplayName();

      final result = await repository.hasDisplayName();
      expect(result, false);
    });
  });

  group('UserRepository - clearDisplayName', () {
    test('clears existing display name', () async {
      await repository.saveDisplayName('NameToDelete');

      final result = await repository.clearDisplayName();

      expect(result, true);
      expect(await repository.getDisplayName(), isNull);
      expect(await repository.hasDisplayName(), false);
    });

    test('succeeds when no display name exists', () async {
      final result = await repository.clearDisplayName();
      expect(result, true);
    });

    test('allows saving new display name after clear', () async {
      await repository.saveDisplayName('OldName');
      await repository.clearDisplayName();
      await repository.saveDisplayName('NewName');

      expect(await repository.getDisplayName(), 'NewName');
    });
  });

  group('UserRepository - clearAll', () {
    test('clears both user ID and display name', () async {
      await repository.saveUserId('user_123');
      await repository.saveDisplayName('Player123');

      final result = await repository.clearAll();

      expect(result, true);
      expect(await repository.getUserId(), isNull);
      expect(await repository.getDisplayName(), isNull);
    });

    test('succeeds when only user ID exists', () async {
      await repository.saveUserId('user_456');

      final result = await repository.clearAll();

      expect(result, true);
      expect(await repository.hasUserId(), false);
    });

    test('succeeds when only display name exists', () async {
      await repository.saveDisplayName('PlayerName');

      final result = await repository.clearAll();

      expect(result, true);
      expect(await repository.hasDisplayName(), false);
    });

    test('succeeds when nothing is stored', () async {
      final result = await repository.clearAll();
      expect(result, true);
    });

    test('allows saving new data after clearAll', () async {
      await repository.saveUserId('user_old');
      await repository.saveDisplayName('OldName');
      await repository.clearAll();

      await repository.saveUserId('user_new');
      await repository.saveDisplayName('NewName');

      expect(await repository.getUserId(), 'user_new');
      expect(await repository.getDisplayName(), 'NewName');
    });
  });

  group('UserRepository - Integration scenarios', () {
    test('stores and retrieves complete user profile', () async {
      await repository.saveUserId('firebase_uid_abc123');
      await repository.saveDisplayName('AwesomePlayer');

      expect(await repository.getUserId(), 'firebase_uid_abc123');
      expect(await repository.getDisplayName(), 'AwesomePlayer');
      expect(await repository.hasUserId(), true);
      expect(await repository.hasDisplayName(), true);
    });

    test('clears user ID without affecting display name', () async {
      await repository.saveUserId('user_123');
      await repository.saveDisplayName('Player123');

      await repository.clearUserId();

      expect(await repository.getUserId(), isNull);
      expect(await repository.getDisplayName(), 'Player123');
    });

    test('clears display name without affecting user ID', () async {
      await repository.saveUserId('user_456');
      await repository.saveDisplayName('Player456');

      await repository.clearDisplayName();

      expect(await repository.getUserId(), 'user_456');
      expect(await repository.getDisplayName(), isNull);
    });

    test('handles multiple updates to user data', () async {
      // Initial save
      await repository.saveUserId('user_1');
      await repository.saveDisplayName('Name1');

      // First update
      await repository.saveUserId('user_2');
      await repository.saveDisplayName('Name2');

      // Second update
      await repository.saveUserId('user_3');
      await repository.saveDisplayName('Name3');

      expect(await repository.getUserId(), 'user_3');
      expect(await repository.getDisplayName(), 'Name3');
    });

    test('handles rapid save and clear operations', () async {
      await repository.saveUserId('user_1');
      await repository.clearUserId();
      await repository.saveUserId('user_2');
      await repository.clearUserId();
      await repository.saveUserId('user_3');

      expect(await repository.getUserId(), 'user_3');
    });

    test('preserves data isolation between user ID and display name', () async {
      await repository.saveUserId('uid_abc');
      await repository.saveDisplayName(
        'uid_abc',
      ); // Same value but different keys

      await repository.clearUserId();

      expect(await repository.getUserId(), isNull);
      expect(
        await repository.getDisplayName(),
        'uid_abc',
      ); // Should still exist
    });

    test('handles empty strings correctly', () async {
      // Repository should handle empty strings if validation allows them
      await repository.saveUserId('');
      await repository.saveDisplayName('');

      expect(await repository.getUserId(), '');
      expect(await repository.getDisplayName(), '');
      expect(await repository.hasUserId(), true);
      expect(await repository.hasDisplayName(), true);
    });

    test('workflow: new user registration and profile update', () async {
      // 1. New anonymous user
      expect(await repository.hasUserId(), false);
      expect(await repository.hasDisplayName(), false);

      // 2. Save anonymous user ID
      await repository.saveUserId('anonymous_user_123');
      expect(await repository.hasUserId(), true);

      // 3. User sets nickname later
      await repository.saveDisplayName('NewPlayer');
      expect(await repository.hasDisplayName(), true);

      // 4. User updates nickname
      await repository.saveDisplayName('ProPlayer');
      expect(await repository.getDisplayName(), 'ProPlayer');

      // 5. User logs out
      await repository.clearAll();
      expect(await repository.hasUserId(), false);
      expect(await repository.hasDisplayName(), false);
    });
  });
}
