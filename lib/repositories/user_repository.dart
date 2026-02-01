import 'package:multigame/repositories/secure_storage_repository.dart';

/// Abstract interface for user data persistence
///
/// This repository handles user profile data including userId and displayName.
/// Implementations should handle both secure storage and any necessary migrations.
abstract class UserRepository {
  /// Get the stored user ID
  Future<String?> getUserId();

  /// Save user ID
  Future<bool> saveUserId(String userId);

  /// Check if user ID exists
  Future<bool> hasUserId();

  /// Clear user ID
  Future<bool> clearUserId();

  /// Get the stored display name/nickname
  Future<String?> getDisplayName();

  /// Save display name/nickname
  Future<bool> saveDisplayName(String displayName);

  /// Check if display name exists
  Future<bool> hasDisplayName();

  /// Clear display name
  Future<bool> clearDisplayName();

  /// Clear all user data
  Future<bool> clearAll();
}

/// Implementation of UserRepository using SecureStorageRepository
///
/// Stores user data in encrypted storage for security.
class SecureUserRepository implements UserRepository {
  static const String _userIdKey = 'user_id';
  static const String _displayNameKey = 'user_nickname';

  final SecureStorageRepository _secureStorage;

  SecureUserRepository({
    SecureStorageRepository? secureStorage,
  }) : _secureStorage = secureStorage ?? SecureStorageRepository();

  @override
  Future<String?> getUserId() async {
    return await _secureStorage.read(_userIdKey);
  }

  @override
  Future<bool> saveUserId(String userId) async {
    return await _secureStorage.write(_userIdKey, userId);
  }

  @override
  Future<bool> hasUserId() async {
    return await _secureStorage.containsKey(_userIdKey);
  }

  @override
  Future<bool> clearUserId() async {
    return await _secureStorage.delete(_userIdKey);
  }

  @override
  Future<String?> getDisplayName() async {
    return await _secureStorage.read(_displayNameKey);
  }

  @override
  Future<bool> saveDisplayName(String displayName) async {
    return await _secureStorage.write(_displayNameKey, displayName);
  }

  @override
  Future<bool> hasDisplayName() async {
    return await _secureStorage.containsKey(_displayNameKey);
  }

  @override
  Future<bool> clearDisplayName() async {
    return await _secureStorage.delete(_displayNameKey);
  }

  @override
  Future<bool> clearAll() async {
    final userIdResult = await clearUserId();
    final displayNameResult = await clearDisplayName();
    return userIdResult && displayNameResult;
  }
}