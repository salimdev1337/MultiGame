import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling Firebase authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs the user in anonymously via Firebase Auth.
  ///
  /// Returns the [UserCredential] on success, or `null` if sign-in fails
  /// (e.g. network unavailable, Firebase project misconfigured).
  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return credential;
    } catch (e) {
      return null;
    }
  }

  /// Get user ID (for Firestore operations)
  String? getUserId() {
    return currentUser?.uid;
  }

  /// Check if user is anonymous
  bool isAnonymous() {
    return currentUser?.isAnonymous ?? true;
  }

  /// Get user display name
  String? getDisplayName() {
    return currentUser?.displayName;
  }

  /// Get user email
  String? getEmail() {
    return currentUser?.email;
  }
}
