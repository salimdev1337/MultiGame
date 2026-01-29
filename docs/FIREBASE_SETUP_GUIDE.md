# 🔥 Firebase Setup Guide - Step by Step

Follow these steps carefully. We'll do this together!

---

## ✅ Step 1: Install FlutterFire CLI (COMPLETE THIS FIRST)

The FlutterFire CLI helps configure Firebase for your Flutter app automatically.

### Windows PowerShell Commands:

```powershell
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Verify installation
flutterfire --version
```

**Expected Output:** Should show version like `1.x.x`

**Troubleshooting:**
- If you get "command not found", add Dart global packages to PATH:
  - Path: `C:\Users\YourUsername\AppData\Local\Pub\Cache\bin`
  - Or run: `flutter pub global run flutterfire_cli:flutterfire`

---

## ✅ Step 2: Create Firebase Project (Do this in browser)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. **Project Name**: Enter `puzzle-game` (or your preferred name)
4. **Google Analytics**: 
   - You can **disable** it for now (simplifies setup)
   - Or enable it (optional for tracking)
5. Click **"Create project"**
6. Wait for project creation (takes ~30 seconds)
7. Click **"Continue"** when done

**🎯 Checkpoint:** You should now see your Firebase project dashboard

---

## ✅ Step 3: Enable Authentication

1. In Firebase Console, click **"Authentication"** in left sidebar
2. Click **"Get started"**
3. Go to **"Sign-in method"** tab
4. Enable **"Anonymous"** provider:
   - Click on "Anonymous"
   - Toggle "Enable"
   - Click "Save"
5. Enable **"Google"** provider (optional but recommended):
   - Click on "Google"
   - Toggle "Enable"
   - Enter project support email
   - Click "Save"

**🎯 Checkpoint:** You should see "Anonymous" and "Google" as enabled

---

## ✅ Step 4: Create Firestore Database

1. In Firebase Console, click **"Firestore Database"** in left sidebar
2. Click **"Create database"**
3. **Security rules**: Select **"Start in test mode"** (we'll secure it later)
4. **Location**: Choose closest region (e.g., `us-central1` for US, `europe-west1` for Europe)
5. Click **"Enable"**
6. Wait for database creation (~30 seconds)

**🎯 Checkpoint:** You should see empty Firestore database with "Start collection" button

---

## ✅ Step 5: Connect Firebase to Flutter App

**Run this command in your project directory:**

```powershell
# Make sure you're in the project folder
cd C:\Users\salim\OneDrive\Bureau\bootcamp\flutter\puzzle

# Configure Firebase for all platforms
flutterfire configure
```

### What this command does:
1. Prompts you to select your Firebase project
2. Asks which platforms to configure (Android, iOS, Web, Windows)
3. Creates `firebase_options.dart` file automatically
4. Updates platform-specific configuration files

### Follow the prompts:
```
? Select a Firebase project to configure your Flutter application with
  > puzzle-game (or your project name)

? Which platforms should your configuration support?
  > ✓ android
  > ✓ ios
  > ✓ web
  > ✓ windows
```

**🎯 Checkpoint:** 
- File created: `lib/firebase_options.dart`
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

---

## ✅ Step 6: Install Dependencies

```powershell
flutter pub get
```

**🎯 Checkpoint:** Should show "Got dependencies!"

---

## ✅ Step 7: Initialize Firebase in App

I'll create the initialization code for you now...

---

## ⏸️ STOP HERE

Once you complete Steps 1-6, let me know and I'll help you with:
- Step 7: Code implementation
- Step 8: Authentication setup
- Step 9: Database integration
- Step 10: Testing

**Current Status:**
- [ ] Step 1: FlutterFire CLI installed
- [ ] Step 2: Firebase project created
- [ ] Step 3: Authentication enabled
- [ ] Step 4: Firestore created
- [ ] Step 5: Firebase configured
- [ ] Step 6: Dependencies installed

---

## 🆘 Common Issues & Solutions

### Issue 1: FlutterFire command not found
**Solution:**
```powershell
# Run directly without adding to PATH
flutter pub global run flutterfire_cli:flutterfire configure
```

### Issue 2: "Firebase project not found"
**Solution:**
- Make sure you're logged into Google account
- Run: `firebase login` (if you have Firebase CLI)
- Or select project manually in flutterfire configure

### Issue 3: Permission denied
**Solution:**
- Run PowerShell as Administrator
- Or use `flutter pub global run flutterfire_cli:flutterfire configure`

### Issue 4: Package conflicts
**Solution:**
```powershell
flutter clean
flutter pub get
```

---

## 📝 Notes

- Keep Firebase Console open in browser
- Don't close terminal during setup
- If stuck, take screenshot and share the error
- We'll test everything before moving to next step

**Ready to start? Begin with Step 1!** 🚀
