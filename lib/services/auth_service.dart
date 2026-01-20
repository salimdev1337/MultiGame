import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service for handling Firebase authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return credential;
    } catch (e) {
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      // Error signing out
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
