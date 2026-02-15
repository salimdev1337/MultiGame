# GitHub Pages Setup Instructions

This guide will help you publish the Privacy Policy and Terms of Service using GitHub Pages.

## Quick Setup (2 minutes)

### Method 1: Using GitHub Actions (Automated)

1. **Go to your GitHub repository settings**
   - Navigate to: `https://github.com/YOUR_USERNAME/MultiGame/settings/pages`

2. **Configure Source**
   - Under "Build and deployment"
   - Source: Select **GitHub Actions**

3. **Push this commit**
   ```bash
   git add .
   git commit -m "feat: add privacy policy and terms of service"
   git push
   ```

4. **Wait for deployment** (1-2 minutes)
   - Go to Actions tab to see the deployment progress
   - Once complete, your pages will be available at:
     - Privacy Policy: `https://YOUR_USERNAME.github.io/MultiGame/index.html`
     - Terms of Service: `https://YOUR_USERNAME.github.io/MultiGame/terms.html`

### Method 2: Using docs/ folder (Manual)

If GitHub Actions is not available:

1. **Go to repository settings**
   - Navigate to: `https://github.com/YOUR_USERNAME/MultiGame/settings/pages`

2. **Configure Source**
   - Under "Build and deployment"
   - Source: Select **Deploy from a branch**
   - Branch: Select **master** (or main)
   - Folder: Select **/docs**

3. **Save settings**

4. **Wait for deployment** (1-2 minutes)
   - Your pages will be available at:
     - Privacy Policy: `https://YOUR_USERNAME.github.io/MultiGame/index.html`
     - Terms of Service: `https://YOUR_USERNAME.github.io/MultiGame/terms.html`

## Verify Deployment

1. Open your browser and visit:
   - `https://YOUR_USERNAME.github.io/MultiGame/index.html`

2. You should see the Privacy Policy page with navigation links

3. Click "Terms of Service" to verify the second page works

## Update App Links

After confirming the pages are live, update the URLs in:

**File:** `lib/screens/profile_screen.dart`

```dart
_buildLegalButton(
  context,
  icon: Icons.privacy_tip_outlined,
  label: 'Privacy Policy',
  url: 'https://YOUR_USERNAME.github.io/MultiGame/index.html', // ← Update this
),
```

## Custom Domain (Optional)

If you have a custom domain:

1. Add a `CNAME` file to `docs/` folder with your domain
2. Configure DNS settings in your domain registrar
3. Update the URLs in the app to use your custom domain

## Troubleshooting

### Pages not showing up?

1. Check Actions tab for deployment errors
2. Ensure GitHub Pages is enabled in repository settings
3. Verify the repository is public (Pages requires public repo for free tier)
4. Wait 5-10 minutes for DNS propagation

### 404 Error?

1. Check the branch name is correct (master vs main)
2. Ensure docs/ folder exists in the branch
3. Verify index.html and terms.html exist in docs/

### Still having issues?

1. Check repository visibility (Settings → General → Danger Zone)
2. Verify GitHub Pages permissions (Settings → Actions → General → Workflow permissions)
3. Re-run the GitHub Actions workflow manually

---

**Done!** Your legal pages are now live and accessible from the app.
