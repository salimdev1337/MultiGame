# API Configuration Guide

## Unsplash API Setup

This app uses the Unsplash API to fetch random images for the puzzle game. To set it up securely:

### 1. Get Your API Key
1. Go to [Unsplash Developers](https://unsplash.com/developers)
2. Register your application
3. Copy your Access Key

### 2. Configure Locally
1. Open the `.env` file in the project root
2. Replace `your_api_key_here` with your actual API key:
   ```
   UNSPLASH_ACCESS_KEY=your_actual_key_here
   ```

### 3. Security Notes
- ✅ The `.env` file is already in `.gitignore` - your key won't be committed
- ✅ Never commit your actual API key to version control
- ✅ Share `.env.example` with your team, not `.env`

### 4. For Production/CI/CD
Use environment variables instead of the `.env` file:

**Windows:**
```powershell
$env:UNSPLASH_ACCESS_KEY="your_key_here"
flutter build windows --dart-define=UNSPLASH_ACCESS_KEY=$env:UNSPLASH_ACCESS_KEY
```

**macOS/Linux:**
```bash
export UNSPLASH_ACCESS_KEY="your_key_here"
flutter build apk --dart-define=UNSPLASH_ACCESS_KEY=$UNSPLASH_ACCESS_KEY
```

### 5. Fallback Images
If no API key is configured, the app will use local fallback images automatically - no errors!

## How It Works
1. App first checks for `--dart-define` environment variable (production)
2. If not found, checks `.env` file (local development)
3. If still not found, uses fallback images

This ensures your API key stays secure while allowing flexible deployment options.
