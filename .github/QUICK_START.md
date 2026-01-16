# Quick Start: Using CI/CD

## 🎯 Your First Steps

### 1. Push to GitHub (5 minutes)

```bash
# Add all new workflow files
git add .github/

# Commit
git commit -m "Add CI/CD workflows"

# Push to GitHub
git push origin main
```

**What happens:**
- ✅ CI workflow runs tests automatically
- 🔨 Build workflow creates APK, Windows, Web builds
- 🌐 Web version deploys to GitHub Pages (if enabled)

### 2. Enable GitHub Pages (2 minutes)

1. Go to your repo on GitHub
2. Click **Settings** → **Pages**
3. Under "Source", select **GitHub Actions**
4. Click **Save**

Done! Your game will be live at: `https://yourusername.github.io/puzzle`

### 3. Watch Your First CI Run (Right Now!)

1. Go to GitHub → Your repo → **Actions** tab
2. See your workflows running in real-time
3. Click any workflow to see detailed logs
4. Watch tests pass ✅

## 📊 Understanding the Actions Tab

```
Actions Tab
├── Workflows (left sidebar)
│   ├── CI - Test & Analyze
│   ├── Build - Multi-Platform
│   ├── Deploy Web to GitHub Pages
│   └── Release - Create GitHub Release
│
└── All workflows (main area)
    └── Each run shows:
        ├── Status (✅ Success, ❌ Failed, 🟡 In Progress)
        ├── Commit message
        ├── Who triggered it
        ├── How long it took
        └── Downloadable artifacts
```

## 🎓 Learning Exercises

### Exercise 1: Trigger CI Manually
1. Go to Actions → CI - Test & Analyze
2. Click "Run workflow" button
3. Select branch: main
4. Click "Run workflow"
5. Watch it run!

### Exercise 2: Download Your First Build
1. Wait for "Build - Multi-Platform" to complete
2. Go to that workflow run
3. Scroll to bottom → Artifacts section
4. Download `android-apk`
5. Install on your phone!

### Exercise 3: Create Your First Release
```bash
# Update version in pubspec.yaml to 1.0.0

git add pubspec.yaml
git commit -m "Release v1.0.0"
git tag v1.0.0
git push origin v1.0.0
```

Then:
1. Go to Actions tab
2. Watch "Release" workflow run
3. Go to "Releases" tab
4. See your automated release with downloads!

## 🐛 Troubleshooting

### Tests Fail in CI?

**Check the logs:**
1. Actions tab → Failed workflow
2. Click the failed job
3. Click the failed step
4. Read the error message

**Common fixes:**
```bash
# Run tests locally first
flutter test

# Fix any issues, then push again
git add .
git commit -m "Fix tests"
git push
```

### Web Deploy Shows 404?

**Solution:**
1. Check that GitHub Pages is enabled
2. Wait 2-3 minutes for deployment
3. Verify the URL matches your repo name
4. Check Actions → Deploy Web → Success?

## 📈 What to Check Daily

1. **Actions Tab**: Are all workflows passing? ✅
2. **Pull Requests**: Do they have green checks? ✅
3. **Releases**: Is latest version available? ✅

## 🎉 Success Checklist

After pushing to GitHub, you should have:

- [ ] CI workflow runs and passes
- [ ] Build artifacts are created
- [ ] Web version deploys successfully
- [ ] Tests run automatically
- [ ] Status badges show "passing"

## 📚 Next Steps

1. Read the full [CI/CD Learning Guide](CI_CD_GUIDE.md)
2. Customize workflows for your needs
3. Add Android signing for Play Store
4. Set up branch protection rules
5. Configure notifications

## 🚀 Pro Tips

**Tip 1:** Add this to your workflow:
```yaml
- name: Notify on Discord
  if: failure()
  run: # Send Discord webhook
```

**Tip 2:** Use `act` to test workflows locally:
```bash
brew install act  # or choco install act on Windows
act -l  # List workflows
act push  # Simulate a push event
```

**Tip 3:** Cache dependencies to speed up builds:
```yaml
- uses: actions/cache@v3
  with:
    path: ~/.pub-cache
    key: ${{ runner.os }}-pub-${{ hashFiles('pubspec.lock') }}
```

## ❓ Questions?

**Where are my build artifacts?**
→ Actions tab → Latest build run → Scroll to Artifacts section

**How do I deploy to Play Store?**
→ Add Fastlane and signing keys (see advanced guide)

**Can I run this on my own server?**
→ Yes! Use self-hosted runners

**Is this free?**
→ Yes! GitHub Actions is free for public repos

---

**Ready to learn more?** Open [CI_CD_GUIDE.md](CI_CD_GUIDE.md) for the complete guide!
