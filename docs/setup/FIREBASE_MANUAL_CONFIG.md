# 🔧 Manual Firebase Configuration

Since the automatic configuration had PATH issues, let's configure manually. It's simple!

## 📋 Step-by-Step Guide

### 1️⃣ Get Your Firebase Config Values

Go to Firebase Console: https://console.firebase.google.com/

#### For **Web** Configuration:
1. In your Firebase project, click ⚙️ (gear icon) → **Project settings**
2. Scroll down to **"Your apps"** section
3. If you don't see a web app, click **"Add app"** → Web icon (`</>`)
4. Give it a nickname (e.g., "Puzzle Web")
5. Click **"Register app"**
6. You'll see a config object like this:

```javascript
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "puzzle-game-xxxxx.firebaseapp.com",
  projectId: "puzzle-game-xxxxx",
  storageBucket: "puzzle-game-xxxxx.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123456"
};
```

**Copy these values!**

#### For **Android** Configuration:
1. In **Project settings**, scroll to **"Your apps"**
2. Click **"Add app"** → Android icon 🤖
3. **Android package name**: `com.example.multigame` (must match your app)
4. Click **"Register app"**
5. **Download** `google-services.json`
6. **Move** it to: `android/app/google-services.json`

#### For **iOS** Configuration (optional):
1. Click **"Add app"** → iOS icon 🍎
2. **iOS bundle ID**: `com.example.multigame`
3. Click **"Register app"**
4. **Download** `GoogleService-Info.plist`
5. **Move** it to: `ios/Runner/GoogleService-Info.plist`

---

### 2️⃣ Update `lib/firebase_options.dart`

I've created the file. Now you need to replace the placeholder values:

**Open:** `lib/firebase_options.dart`

**Replace these placeholders with your values from Step 1:**

```dart
// For Web and Windows (use web config):
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',           // ← Replace with apiKey from web config
  appId: 'YOUR_WEB_APP_ID',             // ← Replace with appId
  messagingSenderId: 'YOUR_SENDER_ID',  // ← Replace with messagingSenderId
  projectId: 'YOUR_PROJECT_ID',         // ← Replace with projectId
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',  // ← Replace YOUR_PROJECT_ID
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',   // ← Replace YOUR_PROJECT_ID
);

// For Android (use values from google-services.json or Firebase Console):
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',       // ← Usually starts with "AIza"
  appId: 'YOUR_ANDROID_APP_ID',         // ← Usually like "1:xxx:android:xxx"
  messagingSenderId: 'YOUR_SENDER_ID',  // ← Same as web
  projectId: 'YOUR_PROJECT_ID',         // ← Same as web
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);
```

**Windows uses the same config as Web, so copy web values to windows section too.**

---

### 3️⃣ Verify Android Configuration Files

Make sure you have these files:

**File:** `android/build.gradle`

Add this at the bottom (if not already there):
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

**File:** `android/app/build.gradle`

Add this at the very bottom (after everything):
```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## ✅ Once You've Updated the Values...

**Tell me and I'll help you:**
1. Initialize Firebase in your app
2. Set up Authentication service
3. Create Firestore service
4. Test the connection

---

## 🆘 Need Help Finding Values?

**Can't find your config?**
- Go to: https://console.firebase.google.com/
- Select your project
- Click ⚙️ → Project settings
- Scroll to "Your apps" section
- Click on the web app you created
- You'll see all the config values

**Screenshot where you see them and I can guide you!**
