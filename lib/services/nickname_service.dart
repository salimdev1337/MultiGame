import 'package:multigame/repositories/secure_storage_repository.dart';
import 'package:multigame/utils/storage_migrator.dart';

/// Service for managing user nickname and ID using secure encrypted storage
///
/// Data is now stored in encrypted storage instead of plain text SharedPreferences
class NicknameService {
  static const String _nicknameKey = 'user_nickname';
  static const String _userIdKey = 'user_id';

  final SecureStorageRepository _secureStorage;
  final StorageMigrator _migrator;

  bool _migrationChecked = false;

  NicknameService({
    SecureStorageRepository? secureStorage,
  })  : _secureStorage = secureStorage ?? SecureStorageRepository(),
        _migrator = StorageMigrator(secureStorage ?? SecureStorageRepository());

  /// Ensure migration is performed before any operation
  Future<void> _ensureMigration() async {
    if (_migrationChecked) return;

    // Perform migration from SharedPreferences to SecureStorage
    await _migrator.migrateSensitiveData();
    _migrationChecked = true;
  }

  /// Get saved nickname
  Future<String?> getNickname() async {
    await _ensureMigration();
    return await _secureStorage.read(_nicknameKey);
  }

  /// Get saved userId
  Future<String?> getUserId() async {
    await _ensureMigration();
    return await _secureStorage.read(_userIdKey);
  }

  /// Save userId
  Future<bool> saveUserId(String userId) async {
    await _ensureMigration();
    return await _secureStorage.write(_userIdKey, userId);
  }

  /// Check if userId exists
  Future<bool> hasUserId() async {
    await _ensureMigration();
    return await _secureStorage.containsKey(_userIdKey);
  }

  /// Clear userId
  Future<bool> clearUserId() async {
    await _ensureMigration();
    return await _secureStorage.delete(_userIdKey);
  }

  /// Save nickname
  Future<bool> saveNickname(String nickname) async {
    await _ensureMigration();
    return await _secureStorage.write(_nicknameKey, nickname);
  }

  /// Check if nickname is set
  Future<bool> hasNickname() async {
    await _ensureMigration();
    return await _secureStorage.containsKey(_nicknameKey);
  }

  /// Clear nickname (for testing/reset)
  Future<bool> clearNickname() async {
    await _ensureMigration();
    return await _secureStorage.delete(_nicknameKey);
  }
}
