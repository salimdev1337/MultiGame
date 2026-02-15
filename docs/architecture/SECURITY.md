# Security Best Practices

This document outlines security measures and best practices implemented in the MultiGame project.

---

## Table of Contents

1. [Security Overview](#security-overview)
2. [Secure Storage](#secure-storage)
3. [Input Validation](#input-validation)
4. [Logging Guidelines](#logging-guidelines)
5. [API Key Management](#api-key-management)
6. [Firebase Security](#firebase-security)
7. [Security Checklist](#security-checklist)

---

## Security Overview

MultiGame implements industry-standard security practices to protect user data and prevent common vulnerabilities:

- **Encrypted local storage** for sensitive data
- **Input validation** on all user inputs
- **Secure logging** that prevents credential leakage
- **Firestore security rules** to protect database access
- **API key protection** through build-time configuration
- **Template-based configuration** to prevent accidental commits of secrets

---

## Secure Storage

### Implementation

All sensitive user data is stored using **Flutter Secure Storage**, which provides:
- Hardware-backed encryption on Android (KeyStore)
- Keychain encryption on iOS
- Encrypted storage on other platforms

### Usage Pattern

```dart
import 'package:get_it/get_it.dart';
import 'package:puzzle/repositories/secure_storage_repository.dart';

// Get repository from service locator
final secureStorage = GetIt.instance<SecureStorageRepository>();

// Store sensitive data
await secureStorage.write(key: 'user_token', value: token);

// Retrieve sensitive data
final token = await secureStorage.read(key: 'user_token');

// Delete sensitive data
await secureStorage.delete(key: 'user_token');

// Clear all data (e.g., on logout)
await secureStorage.deleteAll();
```

### What to Store Securely

**DO store in secure storage:**
- Authentication tokens
- User credentials
- API keys (if dynamically obtained)
- Encryption keys
- Personal identifiable information (PII)
- OAuth tokens and refresh tokens

**DON'T store in secure storage:**
- Game scores (use Firestore)
- UI preferences (use SharedPreferences)
- Non-sensitive cache data
- Public configuration

### Repository Pattern

The `SecureStorageRepository` (lib/repositories/secure_storage_repository.dart) provides:
- Abstraction over platform-specific storage
- Error handling and fallback mechanisms
- Migration support for legacy data
- Testable interface for unit tests

---

## Input Validation

### Validation Rules

All user inputs must be validated using `InputValidator` (lib/utils/input_validator.dart):

```dart
import 'package:puzzle/utils/input_validator.dart';

// Validate nickname (alphanumeric, 3-20 chars)
final nicknameError = InputValidator.validateNickname(userInput);
if (nicknameError != null) {
  // Show error to user
  showError(nicknameError);
  return;
}

// Validate email (if implementing email auth)
final emailError = InputValidator.validateEmail(email);
if (emailError != null) {
  showError(emailError);
  return;
}
```

### Validation Categories

**1. Nickname Validation**
- Length: 3-20 characters
- Characters: Alphanumeric + spaces, underscores, hyphens
- No special characters to prevent XSS
- No leading/trailing whitespace

**2. Preventing Injection Attacks**
- SQL Injection: N/A (using Firestore, not SQL)
- NoSQL Injection: Validated before Firestore queries
- XSS Prevention: Input sanitization on all user-provided text
- Command Injection: No shell commands with user input

**3. Firestore Query Safety**
```dart
// SAFE: Using parameterized queries
FirebaseFirestore.instance
  .collection('scores')
  .where('userId', isEqualTo: userId)  // Safe: Firebase SDK handles escaping
  .orderBy('score', descending: true);

// UNSAFE: Don't construct queries from raw user input
// Firebase SDK protects against this, but validate anyway
final gameType = InputValidator.sanitize(userInput);
```

### Custom Validation

For game-specific inputs, extend `InputValidator`:

```dart
class InputValidator {
  // Add custom validators as static methods
  static String? validateGridSize(int size) {
    if (size < 3 || size > 5) {
      return 'Grid size must be between 3 and 5';
    }
    return null;
  }

  static String? validateScore(int score) {
    if (score < 0) {
      return 'Score cannot be negative';
    }
    if (score > 999999) {
      return 'Score exceeds maximum value';
    }
    return null;
  }
}
```

---

## Logging Guidelines

### Secure Logging

Use `SecureLogger` (lib/utils/secure_logger.dart) for all logging:

```dart
import 'package:puzzle/utils/secure_logger.dart';

// Safe logging - automatically redacts sensitive data
SecureLogger.info('User logged in', data: {'userId': userId, 'token': token});
// Output: User logged in | userId: abc123 | token: [REDACTED]

SecureLogger.error('API call failed', error: e, stackTrace: stackTrace);

SecureLogger.debug('Game state', data: {'score': 1000, 'apiKey': key});
// Output: ... apiKey: [REDACTED]
```

### What Gets Redacted

The `SecureLogger` automatically redacts:
- API keys (keys containing 'key', 'apikey', 'api_key')
- Tokens (keys containing 'token', 'jwt', 'bearer')
- Passwords (keys containing 'password', 'pwd', 'pass')
- Secrets (keys containing 'secret', 'private')
- Credentials (keys containing 'credential', 'auth')

### Logging Levels

```dart
// Development only (stripped in release builds)
SecureLogger.debug('Detailed game state', data: gameState);

// General information
SecureLogger.info('Game started', data: {'gameType': 'puzzle'});

// Warnings (potential issues)
SecureLogger.warning('API fallback used', data: {'reason': 'timeout'});

// Errors (actionable issues)
SecureLogger.error('Failed to save score', error: e);
```

### Production Logging

In release builds:
- `debug()` logs are completely removed
- `info()`, `warning()`, `error()` are sanitized
- Stack traces are preserved but sanitized
- Consider integrating with crash reporting (Firebase Crashlytics)

---

## API Key Management

### Build-Time Configuration

API keys are provided at build time using `--dart-define`:

```bash
# Development
flutter run --dart-define=UNSPLASH_ACCESS_KEY=your_dev_key

# Production
flutter build apk --release --dart-define=UNSPLASH_ACCESS_KEY=your_prod_key
```

### Access Pattern

```dart
// lib/config/api_config.dart
class ApiConfig {
  // Accessed at compile time, not stored in code
  static const String unsplashKey = String.fromEnvironment(
    'UNSPLASH_ACCESS_KEY',
    defaultValue: '', // Empty string = fallback mode
  );

  static bool get hasUnsplashKey => unsplashKey.isNotEmpty;
}

// Usage in services
if (ApiConfig.hasUnsplashKey) {
  // Use real API
} else {
  // Use fallback/local assets
}
```

### CI/CD Secrets

For GitHub Actions, store secrets in repository settings:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add secrets:
   - `UNSPLASH_ACCESS_KEY`
   - Any other API keys

3. Reference in workflows:
```yaml
- name: Build with API keys
  run: flutter build apk --release --dart-define=UNSPLASH_ACCESS_KEY=${{ secrets.UNSPLASH_ACCESS_KEY }}
```

### What NOT to Do

**❌ DON'T:**
- Commit API keys in code
- Store keys in `lib/config/api_config.dart` directly
- Use environment variables without sanitization
- Log API keys (even in debug mode)
- Store keys in SharedPreferences
- Include keys in error messages

**✅ DO:**
- Use `--dart-define` for build-time configuration
- Store in CI/CD secrets for automated builds
- Use template files (e.g., `config.template.dart`)
- Provide fallback behavior when keys are missing
- Document key requirements in README

---

## Firebase Security

### Firestore Security Rules

**Location:** `firestore.rules`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // User scores collection
    match /user_scores/{userId} {
      // Users can read their own scores
      allow read: if request.auth != null && request.auth.uid == userId;

      // Users can write their own scores
      allow create, update: if request.auth != null
                            && request.auth.uid == userId
                            && validateScoreData(request.resource.data);

      // No one can delete scores (data retention)
      allow delete: if false;
    }

    // Leaderboard collection (read-only for clients)
    match /leaderboard/{document} {
      allow read: if request.auth != null;
      allow write: if false; // Only server can write
    }

    // Validation functions
    function validateScoreData(data) {
      return data.keys().hasAll(['score', 'displayName', 'timestamp', 'gameType'])
          && data.score is int
          && data.score >= 0
          && data.displayName is string
          && data.displayName.size() >= 3
          && data.displayName.size() <= 20
          && data.gameType in ['puzzle', '2048', 'snake', 'infinite_runner'];
    }
  }
}
```

### Deploy Security Rules

```bash
# Install Firebase CLI (one-time setup)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in project
firebase init firestore

# Deploy rules
firebase deploy --only firestore:rules

# Test rules
firebase emulators:start --only firestore
```

### Authentication Security

**Anonymous Auth:**
```dart
// Automatically sign in anonymously on app start
Future<void> _signInAnonymously() async {
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      SecureLogger.info('Anonymous sign-in successful');
    }
  } catch (e) {
    SecureLogger.error('Anonymous sign-in failed', error: e);
  }
}
```

**Security Considerations:**
- Anonymous users can be ephemeral (lost on app reinstall)
- Use persistent user ID (stored securely) to maintain identity
- Convert anonymous users to permanent accounts via linking

### Firebase Options Security

**Template File:** `lib/config/firebase_options.dart.template`

```dart
// This is a template - actual values are generated by flutterfire configure
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Generated by: flutterfire configure
    // DO NOT commit actual firebase_options.dart to version control
    throw UnsupportedError('firebase_options.dart not configured');
  }
}
```

**Setup:**
1. Add `firebase_options.dart` to `.gitignore`
2. Run `flutterfire configure` to generate actual file
3. Keep template committed for reference
4. Document setup in `docs/FIREBASE_SETUP_GUIDE.md`

---

## Security Checklist

### Pre-Commit Checklist

Before committing code, verify:

- [ ] No API keys or secrets in code
- [ ] All user inputs are validated
- [ ] Sensitive data uses SecureStorageRepository
- [ ] All logs use SecureLogger
- [ ] No credentials in log messages
- [ ] firebase_options.dart not committed
- [ ] .env files (if any) are in .gitignore
- [ ] No TODO comments containing sensitive info

### Pre-Release Checklist

Before releasing to production:

- [ ] Firestore security rules deployed
- [ ] All API keys configured in CI/CD
- [ ] firebase_options.dart generated for production
- [ ] Test secure storage encryption
- [ ] Verify no debug logs in production
- [ ] Test authentication flows
- [ ] Verify input validation on all forms
- [ ] Run security audit: `flutter analyze`
- [ ] Check for hardcoded secrets: `git grep -i "apikey\|secret\|password"`
- [ ] Review Firebase Console security settings

### Regular Security Maintenance

Perform regularly (monthly/quarterly):

- [ ] Update dependencies: `flutter pub upgrade`
- [ ] Check for security advisories: `flutter pub audit`
- [ ] Review Firebase Auth usage logs
- [ ] Audit Firestore security rules
- [ ] Rotate API keys (if compromised)
- [ ] Review app permissions (AndroidManifest.xml, Info.plist)
- [ ] Test for common vulnerabilities (OWASP Mobile Top 10)

---

## Vulnerability Response

### Reporting Security Issues

If you discover a security vulnerability:

1. **DO NOT** open a public GitHub issue
2. Email security concerns to: [your-email@example.com]
3. Include:
   - Vulnerability description
   - Steps to reproduce
   - Potential impact
   - Suggested fix (optional)

### Response Process

1. **Acknowledgment** within 48 hours
2. **Assessment** within 7 days
3. **Fix** based on severity:
   - Critical: 1-3 days
   - High: 7-14 days
   - Medium: 14-30 days
4. **Disclosure** after fix is deployed

---

## Additional Resources

- [OWASP Mobile Security Testing Guide](https://owasp.org/www-project-mobile-security-testing-guide/)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [Firebase Security Documentation](https://firebase.google.com/docs/rules)
- [Dart Security Guidelines](https://dart.dev/guides/libraries/secure-coding)

---

## Questions?

For security-related questions or concerns:
- Review this document and related documentation
- Check [docs/ARCHITECTURE.md](ARCHITECTURE.md) for implementation details
- Contact the development team for clarification
