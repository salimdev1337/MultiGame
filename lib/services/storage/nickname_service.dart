import 'package:multigame/repositories/user_repository.dart';
import 'package:multigame/repositories/secure_storage_repository.dart';
import 'package:multigame/utils/storage_migrator.dart';

/// Service for managing user nickname and ID using secure encrypted storage
///
/// Data is now stored in encrypted storage instead of plain text SharedPreferences.
/// This service now uses UserRepository for data persistence.
class NicknameService {
  final UserRepository _userRepository;
  final StorageMigrator _migrator;

  bool _migrationChecked = false;

  NicknameService({UserRepository? userRepository, StorageMigrator? migrator})
    : _userRepository = userRepository ?? SecureUserRepository(),
      _migrator = migrator ?? StorageMigrator(SecureStorageRepository());

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
    return await _userRepository.getDisplayName();
  }

  /// Get saved userId
  Future<String?> getUserId() async {
    await _ensureMigration();
    return await _userRepository.getUserId();
  }

  /// Save userId
  Future<bool> saveUserId(String userId) async {
    await _ensureMigration();
    return await _userRepository.saveUserId(userId);
  }

  /// Check if userId exists
  Future<bool> hasUserId() async {
    await _ensureMigration();
    return await _userRepository.hasUserId();
  }

  /// Clear userId
  Future<bool> clearUserId() async {
    await _ensureMigration();
    return await _userRepository.clearUserId();
  }

  /// Save nickname
  Future<bool> saveNickname(String nickname) async {
    await _ensureMigration();
    return await _userRepository.saveDisplayName(nickname);
  }

  /// Check if nickname is set
  Future<bool> hasNickname() async {
    await _ensureMigration();
    return await _userRepository.hasDisplayName();
  }

  /// Clear nickname (for testing/reset)
  Future<bool> clearNickname() async {
    await _ensureMigration();
    return await _userRepository.clearDisplayName();
  }
}
