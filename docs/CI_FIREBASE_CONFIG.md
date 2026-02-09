# CI/CD Firebase Configuration

## Problem

The `lib/config/firebase_options.dart` file contains Firebase API keys and secrets, so it's correctly gitignored for security. However, this causes CI/CD builds to fail because the file is missing.

## Solution

We use a **template file** approach:

1. **Template File**: `lib/config/firebase_options.dart.template` contains dummy Firebase configuration values that allow the app to compile without real secrets.

2. **CI Setup**: All CI/CD workflows copy the template to the real location before building:
   ```bash
   cp lib/config/firebase_options.dart.template lib/config/firebase_options.dart
   ```

3. **Security**: Real Firebase keys remain out of version control and are only used in local development or production builds with proper secrets management.

## Updated Workflows

All workflows now include the Firebase config setup step:

- ✅ `.github/workflows/ci.yml` - Test & Analyze
- ✅ `.github/workflows/build.yml` - Multi-platform builds (Android, Windows, Web)
- ✅ `.github/workflows/deploy-web.yml` - GitHub Pages deployment
- ✅ `.github/workflows/release.yml` - Release automation

## Local Development Setup

For local development with real Firebase:

1. **Run FlutterFire CLI** (recommended):
   ```bash
   flutterfire configure
   ```

2. **Or manually create** `lib/config/firebase_options.dart` with your Firebase project keys from the Firebase Console.

3. **Never commit** `firebase_options.dart` - it's already in `.gitignore`

## How It Works

### CI Environment
```
Template (committed) → Copy during CI → Build succeeds ✅
  firebase_options.dart.template
        ↓
  firebase_options.dart (generated)
        ↓
  CI builds with dummy config
```

### Local Development
```
Real config (gitignored) → Build with real Firebase ✅
  flutterfire configure
        ↓
  firebase_options.dart (with real keys)
        ↓
  Local builds with production Firebase
```

## Template Contents

The template file includes:
- Valid Dart code that compiles
- Placeholder values for all platforms (Web, Android, iOS, macOS, Windows)
- Clear documentation on how to set up real Firebase
- All required Firebase configuration fields

## Security Best Practices

✅ **DO:**
- Use the template for CI/CD builds
- Keep `firebase_options.dart` in `.gitignore`
- Use environment-specific Firebase projects (dev, staging, prod)
- Rotate Firebase keys if accidentally committed

❌ **DON'T:**
- Commit real `firebase_options.dart` to git
- Use production Firebase keys in CI/CD
- Share Firebase keys in public repositories
- Hardcode API keys in source code

## Troubleshooting

### Build fails with "DefaultFirebaseOptions not found"
**Solution**: Ensure the template file exists and the copy step runs before `flutter pub get`

### Firebase initialization fails in CI
**Expected**: The template uses dummy values, so Firebase features won't work in CI builds. This is intentional for security.

### Need to test Firebase features in CI?
**Solution**: Use GitHub Secrets to inject real Firebase config only for specific test workflows (advanced, not recommended for public repos)

## References

- [FIREBASE_SETUP_GUIDE.md](FIREBASE_SETUP_GUIDE.md) - Full Firebase setup instructions
- [SECURITY.md](SECURITY.md) - Security best practices
- [.gitignore](../.gitignore) - See line 114 for Firebase exclusions
