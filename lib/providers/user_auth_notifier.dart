import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/auth/auth_service.dart';
import 'package:multigame/services/storage/nickname_service.dart';

class UserAuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final String? persistentUserId;

  const UserAuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.persistentUserId,
  });

  bool get isSignedIn => user != null;
  bool get isAnonymous => user?.isAnonymous ?? true;

  String get displayName {
    if (user == null) return 'Guest';
    if (user!.displayName != null && user!.displayName!.isNotEmpty) {
      return user!.displayName!;
    }
    if (user!.email != null) return user!.email!.split('@')[0];
    return 'Anonymous';
  }

  String? get userId => persistentUserId ?? user?.uid;

  UserAuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    String? persistentUserId,
    bool clearError = false,
  }) {
    return UserAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      persistentUserId: persistentUserId ?? this.persistentUserId,
    );
  }
}

class UserAuthNotifier extends Notifier<UserAuthState> {
  late AuthService _authService;
  late NicknameService _nicknameService;

  @override
  UserAuthState build() {
    _authService = ref.read(authServiceProvider);
    _nicknameService = ref.read(nicknameServiceProvider);

    // Listen to Firebase auth state changes
    final sub = _authService.authStateChanges.listen((user) {
      state = state.copyWith(user: user, clearError: true);
    });
    ref.onDispose(sub.cancel);

    // Load persistent user ID async
    _loadPersistentId();

    return const UserAuthState();
  }

  Future<void> _loadPersistentId() async {
    final id = await _nicknameService.getUserId();
    state = state.copyWith(persistentUserId: id);
  }

  Future<bool> signInAnonymously() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.signInAnonymously();
      state = state.copyWith(isLoading: false);
      return result != null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to sign in: $e');
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final userAuthProvider = NotifierProvider<UserAuthNotifier, UserAuthState>(
  UserAuthNotifier.new,
);
