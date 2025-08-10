# 🚀 CI/CD Pipeline Setup Guide

This document describes how to set up a comprehensive CI/CD pipeline for automated Docker image building and publishing for AmneziaWG.

## 📋 Table of Contents

- [Pipeline Overview](#pipeline-overview)
- [Setting up Secrets](#setting-up-secrets)
- [Workflows](#workflows)
- [Creating Releases](#creating-releases)
- [Troubleshooting](#troubleshooting)

## 🔍 Pipeline Overview

The pipeline consists of several workflows:

### 🚀 `release.yml` - Main Release Pipeline
- **Triggers**: Push tags `v*`, manual dispatch
- **Features**:
  - Automated Docker image builds for `linux/amd64` and `linux/arm64`
  - Publishing to Docker Hub and GitHub Container Registry
  - GitHub release creation with automatic changelog
  - Prerelease version support

### 🔄 `ci.yml` - Continuous Integration
- **Triggers**: Push to `main`/`master`/`develop`, Pull Requests
- **Features**:
  - Code and project structure validation
  - Docker image test builds
  - Integration tests
  - Security scanning with Trivy

### 🛠️ `build-dev.yml` - Development Builds
- **Triggers**: Push to `develop`, `feature/*`, `hotfix/*`
- **Features**:
  - Fast builds for testing
  - Development image publishing to GHCR
  - Manual build support

### 🔄 `auto-update.yml` - Automatic Updates
- **Triggers**: Weekly schedule, manual dispatch
- **Features**:
  - Automatic submodule updates
  - Pull Request creation with updates
  - Post-update testing

## 🔐 Setting up Secrets

### 1. GitHub Secrets

Go to your repository → `Settings` → `Secrets and variables` → `Actions` and add:

#### Required secrets for Docker Hub (optional):
```
DOCKERHUB_USERNAME - your Docker Hub username
DOCKERHUB_TOKEN - Docker Hub access token (not password!)
```
> **Note**: Docker Hub publishing is **disabled by default**. Set `DOCKERHUB_ENABLED=true` to enable it.

#### Creating Docker Hub Token:
1. Log in to [Docker Hub](https://hub.docker.com/)
2. Go to `Account Settings` → `Security`
3. Click `New Access Token`
4. Description: `GitHub Actions - AmneziaWG`
5. Permissions: `Read, Write, Delete`
6. Copy token and add to GitHub Secrets

### 2. GitHub Container Registry

GHCR uses the built-in `GITHUB_TOKEN` - no additional setup required.

### 3. Repository Variables (Optional but Recommended)

Go to `Settings` → `Secrets and variables` → `Actions` → `Variables` tab:

```bash
# Customize for your fork
IMAGE_NAME=your-username/your-image-name
DOCKERHUB_ENABLED=false         # Default: false (requires additional setup)
GHCR_ENABLED=true              # Default: true (no additional setup needed)
CREATE_GITHUB_RELEASE=true     # Default: true
SECURITY_SCAN_ENABLED=true     # Default: true
```

### 4. Optional Secrets

```bash
# For notifications (future features)
TELEGRAM_BOT_TOKEN - Telegram bot token
TELEGRAM_CHAT_ID - Telegram chat ID for notifications

# For additional registries
AWS_ACCESS_KEY_ID - for AWS ECR
AWS_SECRET_ACCESS_KEY - for AWS ECR
```

## 🏷️ Creating Releases

### Automatic Release via Tags

1. **Create and push a tag:**
   ```bash
   # Regular release
   git tag v1.0.0
   git push origin v1.0.0
   
   # Prerelease
   git tag v1.0.0-beta
   git push origin v1.0.0-beta
   ```

2. **Automatically triggers:**
   - Docker image builds
   - Registry publishing
   - GitHub release creation

### Manual Release via GitHub UI

1. Go to `Actions` → `Release and Build Docker Images`
2. Click `Run workflow`
3. Enter version (e.g., `v1.0.0`)
4. Select if this is a prerelease
5. Click `Run workflow`

### Using the Release Script

```bash
# Semantic versioning
make release-patch      # 1.0.0 → 1.0.1
make release-minor      # 1.0.0 → 1.1.0
make release-major      # 1.0.0 → 2.0.0
make release-prerelease # 1.0.0 → 1.0.1-rc.1

# Custom version
make release-custom version=1.2.3

# Utilities
make release-current    # Show current version
make release-test      # Test build only
```

### Version Conventions

Uses [Semantic Versioning](https://semver.org/):

```
v1.0.0      - stable release
v1.0.0-rc1  - release candidate
v1.0.0-beta - beta version
v1.0.0-alpha - alpha version
```

## 🐳 Using Images

### From Docker Hub
```bash
# Latest stable version
docker pull asychin/amneziawg-docker:latest

# Specific version
docker pull asychin/amneziawg-docker:1.0.0

# Development version
docker pull asychin/amneziawg-docker:dev-latest
```

### From GitHub Container Registry
```bash
# Latest stable version
docker pull ghcr.io/asychin/amneziawg-docker:latest

# Specific version
docker pull ghcr.io/asychin/amneziawg-docker:1.0.0
```

## 🔧 Workflows

### Workflow Structure

```
.github/workflows/
├── release.yml      # Main release pipeline
├── ci.yml          # Continuous integration
├── build-dev.yml   # Development builds
└── auto-update.yml # Automatic dependency updates
```

### Environment Variables

Workflows use these variables:

```yaml
env:
  REGISTRY_DOCKERHUB: docker.io
  REGISTRY_GHCR: ghcr.io
  IMAGE_NAME: ${{ vars.IMAGE_NAME || 'asychin/amneziawg-docker' }}
  BUILD_PLATFORMS: linux/amd64,linux/arm64
```

### Caching

All workflows use GitHub Actions Cache for:
- Docker layer cache
- Buildx cache
- Go module cache (in submodules)

## 🔧 Customizing for Your Fork

### 1. Quick Setup

Set repository variables:
```bash
IMAGE_NAME=your-username/your-image-name
DOCKERHUB_USERNAME=your-dockerhub-username
```

Add Docker Hub token to secrets:
```bash
DOCKERHUB_TOKEN=your-docker-hub-token
```

### 2. Advanced Configuration

Edit `.github/config/pipeline.yml`:

```yaml
image:
  name: "your-username/your-image-name"

repository:
  owner: "your-username"
  name: "your-repository-name"

registries:
  dockerhub:
    enabled: true
  github:
    enabled: true
```

### 3. Test Your Setup

```bash
# Test release
make release-custom version=0.1.0-test

# Check results in:
# - Docker Hub
# - GitHub Container Registry
# - GitHub Releases
```

## ❗ Troubleshooting

### Build Doesn't Start

**Possible causes:**
- Secrets not configured
- Incorrect tag format
- Missing repository permissions

**Solution:**
1. Check secrets in repository settings
2. Ensure tag starts with `v` (e.g., `v1.0.0`)
3. Verify repository access permissions

### Cannot Publish to Docker Hub

**Errors:**
```
denied: requested access to the resource is denied
authentication required
```

**Solution:**
1. Check `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`
2. Ensure token has `Read, Write, Delete` permissions
3. Verify repository exists in Docker Hub

### Multi-platform Build Issues

**Error:**
```
multiple platforms feature is currently not supported
```

**Solution:**
1. Ensure Docker Buildx is used
2. Check platform settings in workflow
3. For local testing:
   ```bash
   docker buildx create --use
   docker buildx build --platform linux/amd64,linux/arm64 .
   ```

### Test Failures

**Common causes:**
- Insufficient initialization time
- Missing privileges in GitHub Actions
- Network issues

**Solution:**
1. Increase wait times in tests
2. Use simpler tests for CI
3. Check workflow logs

### Large Image Size

**Optimization:**
1. Use multi-stage builds (already implemented)
2. Minimize layer count
3. Remove unnecessary files in the same RUN
4. Use `.dockerignore`

### Slow Builds

**Speed up:**
1. Use caching (already configured)
2. Optimize Dockerfile command order
3. Use parallel builds
4. Consider cached base images

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Docker Buildx](https://docs.docker.com/buildx/)
- [Semantic Versioning](https://semver.org/)
- [Fork Setup Guide](.github/FORK_SETUP.md)

## 🆘 Support

If you encounter issues with pipeline setup:

1. Check [Issues](https://github.com/asychin/amnezia-wg-docker/issues)
2. Create a new issue with detailed problem description
3. Include GitHub Actions logs
4. Specify Docker and OS versions

---

**Setup Complete! 🎉**

After configuring secrets, your pipeline will automatically:
- Build images on tag creation
- Test code on Pull Requests
- Update dependencies weekly
- Publish images to registries