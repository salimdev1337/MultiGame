# CI/CD Learning Guide for Puzzle App 🚀

Welcome! This guide will help you understand the CI/CD setup for your Flutter puzzle game.

## 📚 Table of Contents
1. [What is CI/CD?](#what-is-cicd)
2. [Your Workflows Explained](#your-workflows-explained)
3. [How to Use](#how-to-use)
4. [Learning Exercises](#learning-exercises)
5. [Troubleshooting](#troubleshooting)

---

## What is CI/CD?

### Continuous Integration (CI)
Automatically test and validate your code every time you push changes.

**Benefits:**
- ✅ Catch bugs before they reach users
- ✅ Ensure code quality
- ✅ Run tests on every commit
- ✅ Check code formatting and style

### Continuous Delivery/Deployment (CD)
Automatically build and deploy your app to users.

**Benefits:**
- 🚀 Deploy with one command
- 🚀 No manual building for each platform
- 🚀 Consistent release process
- 🚀 Faster time to market

---

## Your Workflows Explained

### 1. CI Workflow (`ci.yml`)
**Trigger:** Runs on every push and pull request  
**Purpose:** Test and analyze code quality

**What it does:**
```
Code pushed → Install Flutter → Get dependencies → 
Check formatting → Analyze code → Run tests → 
Generate coverage report
```

**Files checked:**
- Code formatting (Dart format)
- Code quality (Flutter analyze)
- Unit tests (Flutter test)
- Code coverage

**Learn more:** Open `.github/workflows/ci.yml` - every step has detailed comments!

---

### 2. Build Workflow (`build.yml`)
**Trigger:** Runs on push to main branch  
**Purpose:** Build app for all platforms

**What it does:**
```
Main branch updated → Build Android APK → 
Build Windows executable → Build Web version → 
Upload artifacts (downloadable builds)
```

**Platforms built:**
- 🤖 Android (APK + App Bundle)
- 🪟 Windows (Executable)
- 🌐 Web (HTML/JavaScript)

**Download builds:** Go to Actions tab → Select workflow run → Download artifacts

---

### 3. Web Deployment (`deploy-web.yml`)
**Trigger:** Runs on push to main branch  
**Purpose:** Deploy web version to GitHub Pages

**What it does:**
```
Main branch updated → Build web version → 
Deploy to GitHub Pages → 
Your game is live at yourusername.github.io/puzzle
```

**Setup required:**
1. Go to repo Settings → Pages
2. Source: Select "GitHub Actions"
3. Save
4. Done! Future pushes auto-deploy

**Your game URL:** `https://yourusername.github.io/puzzle`

---

### 4. Release Workflow (`release.yml`)
**Trigger:** Runs when you push a version tag (e.g., v1.0.0)  
**Purpose:** Create GitHub release with downloads

**What it does:**
```
Tag pushed → Build all platforms → 
Create GitHub Release → Upload APK, Windows ZIP → 
Generate changelog
```

**How to create a release:**
```bash
# 1. Update version in pubspec.yaml
version: 1.0.0+1

# 2. Commit the change
git add pubspec.yaml
git commit -m "Release v1.0.0"

# 3. Create and push tag
git tag v1.0.0
git push origin v1.0.0

# 4. Wait! GitHub Actions will:
#    - Build Android APK
#    - Build Windows ZIP
#    - Create release with downloads
#    - Generate changelog automatically
```

---

## How to Use

### Daily Development Workflow

1. **Write code** on your feature branch
```bash
git checkout -b feature/new-game
# Make changes...
git add .
git commit -m "Add memory card game"
git push origin feature/new-game
```

2. **Create pull request**
- CI workflow runs automatically
- Check if tests pass (green checkmark ✅)
- Fix any issues if tests fail (red X ❌)

3. **Merge to main**
```bash
git checkout main
git pull
git merge feature/new-game
git push
```

4. **Automatic actions:**
- ✅ CI tests run again
- 🔨 Build workflow creates all platform builds
- 🌐 Web version deploys automatically
- 🎮 Game is live online!

### Creating a Release

When ready to release a new version:

```bash
# 1. Update version
# Edit pubspec.yaml: version: 1.2.0+3

# 2. Commit
git add pubspec.yaml
git commit -m "Bump version to 1.2.0"
git push

# 3. Create release tag
git tag v1.2.0
git push origin v1.2.0

# 4. Wait 5-10 minutes
# Check: github.com/youruser/puzzle/releases
# Your release will have:
# - puzzle-android.apk
# - puzzle-windows.zip
# - Automatic changelog
```

---

## Learning Exercises

### Exercise 1: Watch CI in Action
1. Make a small change to any file
2. Commit and push to GitHub
3. Go to Actions tab
4. Watch the CI workflow run live
5. Click on each step to see output

**Questions to answer:**
- How long did the workflow take?
- Which step took the longest?
- What would happen if a test failed?

---

### Exercise 2: Download Your Build
1. Push changes to main branch
2. Wait for build workflow to complete
3. Go to Actions → Build workflow → Latest run
4. Scroll down to "Artifacts"
5. Download the Android APK
6. Install it on your phone!

**Try this:**
- Share the APK with a friend
- Test it on a different device
- Compare with local debug build

---

### Exercise 3: Deploy Your Game Online
1. Enable GitHub Pages (Settings → Pages → GitHub Actions)
2. Push to main branch
3. Wait for deploy-web workflow
4. Visit `yourusername.github.io/puzzle`
5. Share the link with friends!

**Experiment:**
- Change the game title
- Push the change
- Watch automatic deployment
- Refresh your game URL - it's updated!

---

### Exercise 4: Create Your First Release
1. Update `pubspec.yaml` version to 1.0.0
2. Commit: `git commit -m "Release v1.0.0"`
3. Tag: `git tag v1.0.0`
4. Push: `git push origin v1.0.0`
5. Go to Releases tab
6. See your automated release!

**Success criteria:**
- Release appears in Releases tab
- Android APK is downloadable
- Windows ZIP is downloadable
- Changelog is generated

---

## Understanding YAML Syntax

Workflows are written in YAML. Here's a quick guide:

```yaml
# Comments start with #

name: My Workflow  # Workflow name

on:  # When to run
  push:  # On push events
    branches: [main]  # Only main branch

jobs:  # Tasks to run
  build:  # Job name
    runs-on: ubuntu-latest  # Which OS
    steps:  # Individual steps
      - name: Step name  # What it does
        run: echo "Hello"  # Command to run
```

---

## Viewing Workflow Results

### In GitHub:
1. Go to your repository
2. Click "Actions" tab
3. See all workflow runs
4. Click any run to see details
5. Click any step to see output

### Status Badges:
Add to your README.md:
```markdown
![CI](https://github.com/username/puzzle/actions/workflows/ci.yml/badge.svg)
```

Shows real-time status: ![Passing](https://img.shields.io/badge/build-passing-brightgreen)

---

## Common Issues & Solutions

### Issue: CI workflow fails on formatting
**Error:** `dart format --set-exit-if-changed` fails

**Solution:**
```bash
# Format all files locally
dart format .

# Commit formatted code
git add .
git commit -m "Format code"
git push
```

---

### Issue: Tests fail in CI but pass locally
**Possible causes:**
- Network calls in tests (use mocks)
- File system access
- Time-dependent tests

**Solution:**
- Check test output in Actions tab
- Run `flutter test` locally
- Look for environment-specific issues

---

### Issue: Web deployment shows 404
**Solution:**
1. Check base-href in build command matches repo name
2. Verify GitHub Pages is enabled
3. Wait 2-3 minutes for DNS propagation
4. Check Pages settings: `Settings → Pages`

---

### Issue: Release creation fails
**Error:** Permission denied

**Solution:**
1. Go to `Settings → Actions → General`
2. Under "Workflow permissions"
3. Select "Read and write permissions"
4. Save changes

---

## Advanced Topics

### Secrets Management
Store sensitive data (API keys, signing keys):

1. Go to `Settings → Secrets and variables → Actions`
2. Click "New repository secret"
3. Use in workflow: `${{ secrets.SECRET_NAME }}`

Example:
```yaml
- name: Sign APK
  env:
    SIGNING_KEY: ${{ secrets.ANDROID_SIGNING_KEY }}
  run: ./sign-apk.sh
```

---

### Matrix Builds
Test on multiple Flutter versions:

```yaml
strategy:
  matrix:
    flutter-version: ['3.24.0', '3.27.1']
steps:
  - uses: subosito/flutter-action@v2
    with:
      flutter-version: ${{ matrix.flutter-version }}
```

---

### Caching
Speed up workflows by caching dependencies:

```yaml
- name: Cache Flutter dependencies
  uses: actions/cache@v3
  with:
    path: |
      ~/.pub-cache
      build
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
```

---

## Next Steps

### Week 1 Goals:
- ✅ Understand what each workflow does
- ✅ Watch CI run on your commits
- ✅ Download a build artifact
- ✅ Deploy web version

### Week 2 Goals:
- ✅ Create your first release
- ✅ Customize workflows
- ✅ Add status badges to README
- ✅ Set up branch protection rules

### Week 3 Goals:
- ✅ Add Android app signing
- ✅ Set up Play Store deployment
- ✅ Create deployment environments
- ✅ Add manual approval steps

### Week 4 Goals:
- ✅ Implement semantic versioning
- ✅ Automate changelog generation
- ✅ Set up notifications
- ✅ Create custom actions

---

## Resources

### Official Documentation:
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Flutter CI/CD Guide](https://docs.flutter.dev/deployment/cd)
- [GitHub Pages](https://pages.github.com/)

### Useful Actions:
- [Flutter Action](https://github.com/marketplace/actions/flutter-action)
- [Upload Artifact](https://github.com/marketplace/actions/upload-a-build-artifact)
- [Create Release](https://github.com/marketplace/actions/create-a-release)

### Video Tutorials:
- GitHub Actions Tutorial (YouTube)
- Flutter CI/CD with GitHub Actions
- Automated Testing Best Practices

---

## Questions?

**Common questions:**

**Q: How much does GitHub Actions cost?**  
A: Free for public repos! 2,000 minutes/month for private repos.

**Q: Can I run workflows locally?**  
A: Yes! Use [act](https://github.com/nektos/act) to run workflows locally.

**Q: How do I debug a failing workflow?**  
A: Check the Actions tab, click the run, click the failing step, read the logs.

**Q: Can I deploy to Play Store automatically?**  
A: Yes! Add secrets for signing keys and use fastlane or gradle-play-publisher.

---

## Celebrate Your Progress! 🎉

You now have:
- ✅ Automated testing
- ✅ Multi-platform builds
- ✅ Web deployment
- ✅ Release automation

This is professional-grade DevOps! Companies pay big money for this expertise.

**Keep learning, keep building!** 🚀

---

*Last updated: 2026-01-16*
