import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/config/firebase_options.dart';
import 'package:multigame/config/service_locator.dart';
import 'package:multigame/services/storage/nickname_service.dart';
import 'package:multigame/utils/secure_logger.dart';

final appInitProvider = FutureProvider<void>((ref) async {
  // Initialize Firebase with a 10-second timeout to prevent infinite loading
  // on slow networks or when Firebase services are unreachable.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
  } on Exception catch (e) {
    // TimeoutException, FirebaseException, or network error — continue offline
    SecureLogger.error('Firebase init failed — proceeding offline', error: e);
    return;
  }

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    SecureLogger.error(
      'Flutter framework error',
      error: errorDetails.exception,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    SecureLogger.error('Platform dispatcher error', error: error);
    return true;
  };

  SecureLogger.log('Crashlytics initialized', tag: 'Crashlytics');

  final nicknameService = getIt<NicknameService>();

  // Anonymous auth with a 8-second timeout
  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance
          .signInAnonymously()
          .timeout(const Duration(seconds: 8));
      SecureLogger.firebase('Signed in anonymously');
    } catch (e) {
      SecureLogger.error('Anonymous auth failed — continuing as guest', error: e);
    }
  }

  final savedUserId = await nicknameService.getUserId();
  if (savedUserId != null) {
    SecureLogger.user(
      'Returning user with saved persistent ID',
      userId: savedUserId,
    );
  } else {
    final firebaseUserId = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUserId != null) {
      await nicknameService.saveUserId(firebaseUserId);
      SecureLogger.user(
        'New user - saved persistent ID',
        userId: firebaseUserId,
      );
    }
  }
});
