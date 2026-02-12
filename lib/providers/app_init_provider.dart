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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
    SecureLogger.firebase('Signed in anonymously');
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
