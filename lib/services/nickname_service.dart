import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user nickname
class NicknameService {
  static const String _nicknameKey = 'user_nickname';
  static const String _userIdKey = 'user_id';

  /// Get saved nickname
  Future<String?> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nicknameKey);
  }

  /// Get saved userId
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Save userId
  Future<bool> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_userIdKey, userId);
  }

  /// Check if userId exists
  Future<bool> hasUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userIdKey);
  }

  /// Clear userId
  Future<bool> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_userIdKey);
  }

  /// Save nickname
  Future<bool> saveNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_nicknameKey, nickname);
  }

  /// Check if nickname is set
  Future<bool> hasNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_nicknameKey);
  }

  /// Clear nickname (for testing/reset)
  Future<bool> clearNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_nicknameKey);
  }
}
