# My First CI/CD Project

[![CI Pipeline](https://github.com/spovedcloud-ger/my-first-cicd/actions/workflows/ci.yml/badge.svg)](https://github.com/spovedcloud-ger/my-first-cicd/actions/workflows/ci.yml)
[![Node.js CI](https://img.shields.io/badge/Node.js-24-green)](https://nodejs.org/)
[![Docker](https://img.shields.io/badge/Docker-ready-blue)](https://www.docker.com/)

A simple Node.js app with automated testing pipeline.

## What's Included

- **Express.js** - Simple web server
- **Jest** - Testing framework
- **GitHub Actions** - CI/CD pipeline (runs tests on every push)

## Quick Start

```bash
# Install dependencies
npm install

# Run the app
npm start

# Run tests
npm test
```

## How the CI/CD Works

1. **Push to GitHub** → Triggers the pipeline
2. **GitHub Actions** runs:
   - Checkout code
   - Setup Node.js
   - Install dependencies
   - Run tests
   - Upload coverage report

## Steps to Push to GitHub

```bash
# Navigate to project folder
cd Documents\my-first-cicd

# Initialize git (if not done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit"

# Create GitHub repo and push
git remote add origin https://github.com/YOUR_USERNAME/my-first-cicd.git
git push -u origin main
```

## After Push

Go to your GitHub repo → **Actions** tab to see the pipeline running!

## Creating a Personal Access Token (Classic) on GitHub

A Personal Access Token (PAT) is used to authenticate with GitHub instead of a password.

### Steps to Create a PAT

1. **Go to GitHub Settings**
   - Click your profile picture (top right) → **Settings**
   - Or go directly to: https://github.com/settings/tokens

2. **Navigate to Developer Settings**
   - Scroll down and click **Developer settings** (left sidebar)
   - Then click **Personal access tokens** → **Tokens (classic)**

3. **Generate New Token**
   - Click **Generate new token (classic)**

4. **Configure Your Token**
   - **Note**: Give your token a descriptive name (e.g., "CI/CD Pipeline")
   - **Expiration**: Set an expiration date (recommended: 30-90 days)
   - **Select Scopes**: Check the following boxes:
     - ✅ `repo` - Full control of repositories
     - ✅ `workflow` - Update GitHub Actions workflows
     - ✅ `read:user` - Read user profile data

5. **Generate Token**
   - Click **Generate token**
   - **IMPORTANT**: Copy your token immediately - you won't see it again!

### Using the Token

#### Option 1: Push with Token (as password)
```bash
git remote add origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/my-first-cicd.git
git push -u origin main
```

#### Option 2: Store Credential (recommended)
```bash
git remote set-url origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/my-first-cicd.git
```

Or use Git Credential Manager:
```bash
git config --global credential.helper store
```

#### Option 3: Add to GitHub Secrets (for CI/CD)
1. Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `GITHUB_TOKEN`
4. Value: Paste your PAT
5. Click **Add secret**

Your token is now ready to use for push, pull, or CI/CD operations!

## Git Rebase - Keeping History Clean

Rebase rewrites commit history by moving your commits on top of another branch.

### Basic Rebase (onto main/master)

```bash
# Make sure you're on your feature branch
git checkout feature-branch

# Rebase onto master
git rebase master
```

### Interactive Rebase - Squash & Edit Commits

```bash
# Rebase last 3 commits
git rebase -i HEAD~3
```

In the editor, you'll see:
```
pick abc1234 First commit message
pick def5678 Second commit message
pick ghi9012 Third commit message
```

Change `pick` to:
- `squash` or `s` - Merge into previous commit
- `reword` or `r` - Change commit message
- `edit` or `e` - Stop to amend commit
- `drop` or `d` - Remove commit

Save and close to execute.

### Rebase vs Merge

| Rebase | Merge |
|--------|-------|
| Linear history | Preserves all commits |
| Rewrites history | Creates merge commit |
| Use locally before push | Use for integrating branches |

### Common Rebase Workflow

```bash
# 1. Update master
git checkout master
git pull origin master

# 2. Rebase your feature branch
git checkout feature-branch
git rebase master

# 3. Force push (if already pushed)
git push --force-with-lease
```

⚠️ **Warning:** Never rebase commits that are already pushed to shared branches!

## Git Branching Strategies

### Basic Branch Commands

```bash
# List branches
git branch

# Create new branch
git branch feature-login

# Switch to branch
git checkout feature-login

# Create and switch (shorthand)
git checkout -b feature-login

# Delete branch (local)
git branch -d feature-login

# Delete branch (remote)
git push origin --delete feature-login
```

### Common Branch Types

| Branch | Purpose | Example |
|--------|---------|---------|
| `main` / `master` | Production code | - |
| `develop` / `dev` | Integration branch | - |
| `feature/*` | New features | `feature/user-auth` |
| `bugfix/*` | Bug fixes | `bugfix/login-error` |
| `hotfix/*` | Urgent production fixes | `hotfix/security-patch` |
| `release/*` | Release preparation | `release/v1.0.0` |

### Feature Branch Workflow

```bash
# 1. Start from develop
git checkout develop
git pull origin develop
git checkout -b feature-new-feature

# 2. Work on your feature
# ... make commits ...

# 3. Sync with develop (regularly)
git fetch origin
git rebase origin/develop

# 4. Push and create Pull Request
git push -u origin feature-new-feature
```

### Git Flow (Popular Strategy)

```
main ─────●─────●─────●─────●─────
           \             \
develop ────●───●───●───●───●───●───
              \         \
feature ────────●───●─────
```

**Commands:**
```bash
# Install git-flow
git flow init

# Start feature
git flow feature start login

# Finish feature
git flow feature finish login

# Start hotfix
git flow hotfix start v1.1.0

# Finish hotfix
git flow hotfix finish v1.1.0
```

### Branch Protection Rules

In GitHub → Settings → Branches → Branch protection rules:

1. ✅ Require pull request reviews
2. ✅ Require status checks to pass
3. ✅ Require signed commits (optional)
4. ✅ Require linear history (for main)

This prevents direct pushes to `main` and ensures code review!

## Git Merging

### Basic Merge Commands

```bash
# Merge branch into current branch
git checkout main
git merge feature-branch

# Merge without fast-forward (always creates merge commit)
git merge --no-ff feature-branch

# Squash merge (all commits become one)
git merge --squash feature-branch
git commit -m "Feature complete"
```

### Merge Strategies

| Strategy | Command | Use Case |
|----------|---------|----------|
| Fast-forward | `git merge` | Linear history |
| No-ff | `git merge --no-ff` | Preserve branch history |
| Squash | `git merge --squash` | Clean single commit |
| Rebase + Merge | `git rebase` then `git merge` | Clean linear history |

### Handling Merge Conflicts

```bash
# 1. Start merge
git checkout main
git merge feature-branch

# 2. You'll see conflicts - fix them manually
# Edit the conflicting files, remove <<< === >>> markers

# 3. Mark as resolved
git add .

# 4. Complete merge
git commit
```

**VS Code Conflict Markers:**
```
<<<<<<< HEAD
Your current code
=======
Incoming code from branch
>>>>>>> feature-branch
```

### Merge Pull Request (GitHub)

1. Go to your Pull Request
2. Review changes
3. Click **Merge pull request**
4. Choose merge method:
   - **Merge** - Adds merge commit
   - **Squash and merge** - Single commit (recommended)
   - **Rebase and merge** - Linear history

### Best Practices

```bash
# Always pull latest before merging
git checkout main
git pull origin main
git merge feature-branch

# Delete branch after merge
git branch -d feature-branch
git push origin --delete feature-branch
```

### Merge vs Rebase

| Merge | Rebase |
|-------|--------|
| Preserves full history | Creates linear history |
| Creates merge commit | No extra commits |
| Safe for shared branches | Rewrite history |
| ✅ Use for integrating branches | ✅ Use for local cleanup |

## Getting Hash Key for Developer Settings (Android)

If you're integrating Google Maps or other Google services that require a SHA-1 hash:

### Option 1: Using Command Line

```bash
# Navigate to your keystore location (or debug.keystore default path)
cd C:\Users\YOUR_USERNAME\AppData\Local\Android\Sdk\debug.keystore

# Get SHA-1 hash
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Option 2: Using Gradle

```bash
# Run this in your Android project folder
./gradlew signingReport
```

The output will show:
- SHA-1 certificate fingerprint
- SHA-256 certificate fingerprint
- MD5 certificate fingerprint

### Adding to Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **API Key**
5. Click **Restrict Key** → Select your app's package name and SHA-1

Your API key will be restricted to only work with your app's specific hash!
#   m y - f i r s t - c i c d  
 