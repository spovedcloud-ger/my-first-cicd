# My First CI/CD Project

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
