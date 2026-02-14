import 'package:multigame/utils/secure_logger.dart';

class ApiConfig {
  static const String unsplashBaseUrl = 'https://api.unsplash.com';

  static String? get unsplashAccessKey {
    // Get from dart-define (for production/CI/CD and local development)
    const envKey = String.fromEnvironment('UNSPLASH_ACCESS_KEY');

    // Secure logging - never log the actual key value
    SecureLogger.config(
      'UNSPLASH_ACCESS_KEY',
      envKey.isNotEmpty ? envKey : null,
    );

    if (envKey.isNotEmpty) {
      return envKey;
    }

    SecureLogger.log('Unsplash API key not configured', tag: 'ApiConfig');
    return null;
  }

  static bool get isUnsplashConfigured {
    final key = unsplashAccessKey;
    return validateUnsplashKey(key);
  }

  static bool validateUnsplashKey(String? key) {
    if (key == null || key.isEmpty) return false;

    // Unsplash keys are typically alphanumeric
    final validFormat = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validFormat.hasMatch(key)) {
      SecureLogger.log(
        'Unsplash API key format looks invalid',
        tag: 'ApiConfig',
      );
      return false;
    }

    return true;
  }
}
