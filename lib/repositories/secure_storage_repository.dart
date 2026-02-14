import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:multigame/utils/secure_logger.dart';

/// Repository for securely storing sensitive data using encrypted storage
///
/// This replaces SharedPreferences for sensitive data like user IDs,
/// authentication tokens, and other private information.
class SecureStorageRepository {
  final FlutterSecureStorage _storage;

  SecureStorageRepository({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  /// Read a value from secure storage
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      SecureLogger.error(
        'Failed to read from secure storage',
        error: e,
        tag: 'SecureStorage',
      );
      return null;
    }
  }

  /// Write a value to secure storage
  Future<bool> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return true;
    } catch (e) {
      SecureLogger.error(
        'Failed to write to secure storage',
        error: e,
        tag: 'SecureStorage',
      );
      return false;
    }
  }

  /// Delete a value from secure storage
  Future<bool> delete(String key) async {
    try {
      await _storage.delete(key: key);
      return true;
    } catch (e) {
      SecureLogger.error(
        'Failed to delete from secure storage',
        error: e,
        tag: 'SecureStorage',
      );
      return false;
    }
  }

  /// Check if a key exists in secure storage
  Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      SecureLogger.error(
        'Failed to check key in secure storage',
        error: e,
        tag: 'SecureStorage',
      );
      return false;
    }
  }

  /// Read all keys from secure storage
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      SecureLogger.error(
        'Failed to read all from secure storage',
        error: e,
        tag: 'SecureStorage',
      );
      return {};
    }
  }

  /// Delete all values from secure storage
  Future<bool> deleteAll() async {
    try {
      await _storage.deleteAll();
      return true;
    } catch (e) {
      SecureLogger.error(
        'Failed to delete all from secure storage',
        error: e,
        tag: 'SecureStorage',
      );
      return false;
    }
  }
}
