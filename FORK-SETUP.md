# 🍴 Fork Setup Guide

This guide explains how to properly set up your fork of this repository to work with your own GitHub username and Docker repositories.

## 🚀 Quick Setup

After forking the repository, run the setup script to automatically update all documentation with your repository information:

```bash
git clone --recursive https://github.com/YOUR_USERNAME/amnezia-wg-docker.git
cd amnezia-wg-docker
./scripts/setup-repo.sh
```

## 🛠️ What the Script Does

The setup script (`scripts/setup-repo.sh`) automatically:

1. **Detects your repository information** from git remote
2. **Updates all documentation files** with your username/repository
3. **Fixes all badges** to point to your repository
4. **Updates Docker image references** to your Docker Hub account
5. **Fixes all GitHub links** (issues, discussions, releases, etc.)

## 📋 Files Updated

The script processes these files:
- `README.md` - Main repository readme
- `docs/en/README.md` - English documentation
- `docs/ru/README.md` - Russian documentation  
- `docs/zh/README.md` - Chinese documentation
- `docs/*/pipeline.md` - CI/CD pipeline documentation
- `docs/en/fork-setup.md` - Fork setup guide

## ⚙️ Environment Variables

You can customize the setup by setting environment variables before running the script:

```bash
# Custom Docker repository (default: same as GitHub repo)
export DOCKER_REPOSITORY="yourdockerhub/custom-name"

# Custom maintainer email (default: yourname@users.noreply.github.com)
export MAINTAINER_EMAIL="your.email@example.com"

./scripts/setup-repo.sh
```

## 🔧 Manual Setup (Alternative)

If you prefer manual setup, update these placeholders in all documentation:

- `{{GITHUB_REPOSITORY}}` → `yourusername/amnezia-wg-docker`
- `{{GITHUB_OWNER}}` → `yourusername`
- `{{DOCKER_REPOSITORY}}` → `yourusername/amnezia-wg-docker`
- `{{MAINTAINER_EMAIL}}` → `your.email@example.com`

## ✅ Verification

After running the setup script, verify that:

1. **Badges work**: Check that all badges in README.md show your repository data
2. **Links work**: Click on issues/discussions links to verify they point to your repo
3. **Docker references**: Search for any remaining `asychin/` references

```bash
# Check for any remaining original references
grep -r "asychin/" docs/ README.md || echo "✅ All references updated!"
```

## 🔄 Re-running the Script

The script is idempotent - you can safely run it multiple times. This is useful if:
- You change your Docker repository name
- You want to update the maintainer email
- New documentation files are added

## 🆘 Need Help?

If you encounter issues with the setup script:

1. Make sure you're in the repository root directory
2. Verify git remote is properly configured: `git remote -v`
3. Check that the script is executable: `chmod +x scripts/setup-repo.sh`
4. Run with verbose output to debug issues

---

**Note**: This setup is only needed once after forking. The script automatically detects your repository information and updates all references accordingly.