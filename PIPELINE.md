# 🚀 CI/CD Pipeline - AmneziaWG Docker Server

Comprehensive CI/CD pipeline for automated building, testing, and publishing of AmneziaWG Docker Server images.

## 🌟 Pipeline Features

### ⚙️ Automation
- **🏷️ Releases**: Automatic release creation on tag push
- **🐳 Docker**: Multi-platform image builds (AMD64, ARM64)  
- **📦 Publishing**: Automatic publishing to Docker Hub and GitHub Container Registry
- **🧪 Testing**: Comprehensive testing on every PR
- **🔄 Updates**: Weekly automatic dependency updates
- **📝 Changelog**: Automatic changelog generation for releases

### 🏗️ Available Images

```bash
# GitHub Container Registry - Default (no setup required)
docker pull ghcr.io/asychin/amneziawg-docker:latest
docker pull ghcr.io/asychin/amneziawg-docker:1.0.0

# Docker Hub - Optional (requires DOCKERHUB_ENABLED=true + secrets)
docker pull asychin/amneziawg-docker:latest
docker pull asychin/amneziawg-docker:1.0.0

# Development builds
docker pull ghcr.io/asychin/amneziawg-docker:dev-latest
docker pull ghcr.io/asychin/amneziawg-docker:dev-main-abc1234
```

## 📋 Workflows

### 1. 🚀 Release Pipeline (`release.yml`)
**Triggers:** Push tags `v*`, manual dispatch

**Features:**
- Multi-platform Docker image builds
- Publishing to Docker Hub and GHCR
- GitHub release creation with changelog
- Automatic prerelease version detection

### 2. 🔄 Continuous Integration (`ci.yml`)  
**Triggers:** Push to main branches, Pull Requests

**Checks:**
- Code and project structure validation
- Docker image test builds
- Integration tests
- Security scanning with Trivy

### 3. 🛠️ Development Build (`build-dev.yml`)
**Triggers:** Push to `develop`, `feature/*`, `hotfix/*`

**Features:**
- Fast builds for testing
- Development image publishing to GHCR
- Manual build support

### 4. 🔄 Auto Update (`auto-update.yml`)
**Triggers:** Weekly schedule, manual dispatch

**Functions:**
- Automatic submodule updates
- Pull Request creation with updates
- Post-update testing

## 🏷️ Creating Releases

### Via Makefile (Recommended)

```bash
# Patch release (1.0.0 → 1.0.1)
make release-patch

# Minor release (1.0.0 → 1.1.0)  
make release-minor

# Major release (1.0.0 → 2.0.0)
make release-major

# Prerelease (1.0.0 → 1.0.1-rc.1)
make release-prerelease

# Custom version
make release-custom version=1.2.3

# Show current version
make release-current

# Test release build
make release-test
```

### Via Script Directly

```bash
# Using the script
./.github/scripts/release.sh patch
./.github/scripts/release.sh minor
./.github/scripts/release.sh major
./.github/scripts/release.sh prerelease
./.github/scripts/release.sh 1.2.3

# Additional options
./.github/scripts/release.sh --help
./.github/scripts/release.sh --current
./.github/scripts/release.sh --test
./.github/scripts/release.sh --dry-run patch
```

### Via GitHub UI

1. Go to `Actions` → `Release and Build Docker Images`
2. Click `Run workflow`
3. Enter version (e.g., `v1.0.0`)
4. Select if this is a prerelease
5. Click `Run workflow`

## 📊 Semantic Versioning

Uses [Semantic Versioning](https://semver.org/):

- `v1.0.0` - stable release
- `v1.0.0-rc1` - release candidate
- `v1.0.0-beta` - beta version  
- `v1.0.0-alpha` - alpha version

### Automatic Prerelease Detection

Versions containing `alpha`, `beta`, `rc`, `dev` are automatically marked as prerelease.

## 🔐 Required Secrets

For full pipeline functionality, configure these secrets in GitHub:

```bash
# Required for Docker Hub (if DOCKERHUB_ENABLED=true)
DOCKERHUB_USERNAME=your_dockerhub_username
DOCKERHUB_TOKEN=your_dockerhub_access_token

# Optional for notifications (future features)
TELEGRAM_BOT_TOKEN=your_telegram_bot_token
TELEGRAM_CHAT_ID=your_telegram_chat_id
```

## 🏗️ Multi-platform Builds

All release images are built for:
- `linux/amd64` (Intel/AMD 64-bit)
- `linux/arm64` (ARM 64-bit, including Apple Silicon)

Development images are built only for `linux/amd64` for speed.

## 📈 Monitoring and Logs

### Build Tracking
- [GitHub Actions](https://github.com/asychin/amnezia-wg-docker/actions)
- [GHCR Package](https://github.com/asychin/amnezia-wg-docker/pkgs/container/amneziawg-docker)
- [GitHub Packages](https://github.com/asychin/amnezia-wg-docker/pkgs/container/amneziawg-docker)

### Useful Commands

```bash
# Check latest releases
curl -s https://api.github.com/repos/asychin/amnezia-wg-docker/releases/latest | jq -r .tag_name

# Check available Docker Hub tags
curl -s https://registry.hub.docker.com/v2/repositories/asychin/amneziawg-docker/tags/ | jq -r '.results[].name'

# Local image check
docker run --rm asychin/amneziawg-docker:latest amneziawg-go --version
```

## 🔧 Pipeline Customization

### Changing Registries

To add additional registries, edit variables in workflows:

```yaml
env:
  REGISTRY_DOCKERHUB: docker.io
  REGISTRY_GHCR: ghcr.io
  REGISTRY_CUSTOM: your-registry.com
  IMAGE_NAME: asychin/amneziawg-docker
```

### Changing Build Platforms

```yaml
env:
  BUILD_PLATFORMS: linux/amd64,linux/arm64,linux/arm/v7
```

### Custom Triggers

Add additional triggers in workflows:

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # Daily builds
  workflow_dispatch:
    inputs:
      custom_option:
        description: 'Custom option'
        required: false
```

## 🔧 Fork Configuration

### For Repository Forks

When forking this repository, configure these repository variables:

```bash
# In GitHub repository settings → Variables
IMAGE_NAME=your-username/your-image-name
DOCKERHUB_ENABLED=true
GHCR_ENABLED=true
```

### Detailed Fork Setup

See the comprehensive [Fork Setup Guide](.github/FORK_SETUP.md) for detailed instructions on:
- Setting up your own Docker registries
- Customizing the pipeline configuration
- Testing your fork
- Troubleshooting common issues

## 📚 Additional Resources

- [Complete Setup Guide](.github/PIPELINE_SETUP.md)
- [Fork Setup Guide](.github/FORK_SETUP.md)
- [Issue Templates](.github/ISSUE_TEMPLATE/)
- [Pull Request Template](.github/pull_request_template.md)
- [Release Script](.github/scripts/release.sh)

## 🆘 Troubleshooting

### Common Issues

1. **Build doesn't start** - check secrets and tag format
2. **Cannot publish to Docker Hub** - verify access token
3. **Multi-platform build fails** - ensure Buildx is used
4. **Tests fail** - increase timeouts, check privileges

### Getting Help

- Create an [Issue](https://github.com/asychin/amnezia-wg-docker/issues/new/choose)
- Check [GitHub Actions logs](https://github.com/asychin/amnezia-wg-docker/actions)
- Review [Setup Documentation](.github/PIPELINE_SETUP.md)

---

**Pipeline Ready for Use! 🚀**

After configuring secrets, create your first release with `make release-patch` or via GitHub UI.