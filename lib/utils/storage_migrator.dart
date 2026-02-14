import 'package:shared_preferences/shared_preferences.dart';
import 'package:multigame/repositories/secure_storage_repository.dart';
import 'package:multigame/utils/secure_logger.dart';

/// Utility for migrating data from SharedPreferences to SecureStorage
///
/// This preserves existing user data when transitioning to encrypted storage
class StorageMigrator {
  final SecureStorageRepository _secureStorage;

  StorageMigrator(this._secureStorage);

  /// Migrate a single key from SharedPreferences to SecureStorage
  Future<bool> migrateKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if value exists in SharedPreferences
      if (!prefs.containsKey(key)) {
        return false; // Nothing to migrate
      }

      final value = prefs.getString(key);
      if (value == null) {
        return false; // No value to migrate
      }

      // Check if already migrated to secure storage
      if (await _secureStorage.containsKey(key)) {
        SecureLogger.log('Key already migrated: $key', tag: 'Migration');
        // Clean up old SharedPreferences entry
        await prefs.remove(key);
        return true;
      }

      // Write to secure storage
      final success = await _secureStorage.write(key, value);

      if (success) {
        // Remove from SharedPreferences after successful migration
        await prefs.remove(key);
        SecureLogger.log('Successfully migrated key: $key', tag: 'Migration');
        return true;
      } else {
        SecureLogger.error('Failed to migrate key: $key', tag: 'Migration');
        return false;
      }
    } catch (e) {
      SecureLogger.error(
        'Error migrating key: $key',
        error: e,
        tag: 'Migration',
      );
      return false;
    }
  }

  /// Migrate multiple keys from SharedPreferences to SecureStorage
  Future<Map<String, bool>> migrateKeys(List<String> keys) async {
    final results = <String, bool>{};

    for (final key in keys) {
      results[key] = await migrateKey(key);
    }

    return results;
  }

  /// Migrate all sensitive user data
  ///
  /// This includes user IDs, nicknames, and other private information.
  /// Achievement data and game stats remain in SharedPreferences for now
  /// as they are less sensitive.
  Future<bool> migrateSensitiveData() async {
    SecureLogger.log('Starting sensitive data migration', tag: 'Migration');

    final keysToMigrate = [
      'user_id',
      'user_nickname',
      // Add other sensitive keys here as needed
    ];

    // Check if any keys exist in SharedPreferences before migration
    final prefs = await SharedPreferences.getInstance();
    final keysExist = keysToMigrate.any((key) => prefs.containsKey(key));

    final results = await migrateKeys(keysToMigrate);

    final successCount = results.values.where((success) => success).length;
    final totalCount = results.length;

    SecureLogger.log(
      'Migration complete: $successCount/$totalCount keys migrated',
      tag: 'Migration',
    );

    // Return true if:
    // - At least one key was successfully migrated, OR
    // - No keys existed in SharedPreferences (nothing to migrate)
    return successCount > 0 || !keysExist;
  }

  /// Check if migration has been completed
  Future<bool> isMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();

    final sensitiveKeys = ['user_id', 'user_nickname'];

    // Check if any sensitive keys still exist in SharedPreferences
    for (final key in sensitiveKeys) {
      if (prefs.containsKey(key)) {
        return false; // Migration not complete
      }
    }

    return true; // All sensitive keys have been migrated
  }

  /// Mark migration as complete (for testing purposes)
  Future<void> markMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('migration_complete', true);
    SecureLogger.log('Migration marked as complete', tag: 'Migration');
  }
}
