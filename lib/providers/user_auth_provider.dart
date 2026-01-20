import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multigame/services/auth_service.dart';
import 'package:multigame/services/nickname_service.dart';

/// Provider for authentication state management
class UserAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NicknameService _nicknameService = NicknameService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _persistentUserId; // Persistent ID from SharedPreferences

  UserAuthProvider() {
    _initializePersistentId();
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      _user = user;
      _error = null;
      notifyListeners();
    });
  }

  /// Initialize persistent user ID from SharedPreferences
  Future<void> _initializePersistentId() async {
    _persistentUserId = await _nicknameService.getUserId();
    notifyListeners();
  }

  /// Current user
  User? get user => _user;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message
  String? get error => _error;

  /// Check if user is signed in
  bool get isSignedIn => _user != null;

  /// Check if user is anonymous
  bool get isAnonymous => _user?.isAnonymous ?? true;

  /// Get user display name
  String get displayName {
    if (_user == null) return 'Guest';
    if (_user!.displayName != null && _user!.displayName!.isNotEmpty) {
      return _user!.displayName!;
    }
    if (_user!.email != null) {
      return _user!.email!.split('@')[0];
    }
    return 'Anonymous';
  }

  /// Get user ID - Uses persistent ID from SharedPreferences
  /// This ensures the same ID is used across app sessions
  String? get userId => _persistentUserId ?? _user?.uid;

  /// Sign in anonymously
  Future<bool> signInAnonymously() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.signInAnonymously();
      _isLoading = false;
      notifyListeners();
      return result != null;
    } catch (e) {
      _error = 'Failed to sign in: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return result != null;
    } catch (e) {
      _error = 'Failed to sign in with Google: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _error = null;
    } catch (e) {
      _error = 'Failed to sign out: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
