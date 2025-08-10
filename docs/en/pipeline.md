# 🚀 CI/CD Pipeline - AmneziaWG Docker Server

Comprehensive CI/CD pipeline for automated building, testing, and publishing of AmneziaWG Docker Server images.

**🌍 Languages: [🇷🇺 Russian](../ru/pipeline.md) | [🇨🇳 Chinese](../zh/pipeline.md)**

---

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
docker pull ghcr.io/asychin/amnezia-wg-docker:latest
docker pull ghcr.io/asychin/amnezia-wg-docker:1.0.0

# Docker Hub - Optional (requires DOCKERHUB_ENABLED=true + secrets)
docker pull asychin/amnezia-wg-docker:latest
docker pull asychin/amnezia-wg-docker:1.0.0

# Development builds
docker pull ghcr.io/asychin/amnezia-wg-docker:dev-latest
docker pull ghcr.io/asychin/amnezia-wg-docker:dev-main-abc1234
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

### 3. 🛠️ Development Builds (`build-dev.yml`)
**Triggers:** Push to `develop`, `feature/*`, `hotfix/*`

**Features:**
- Fast builds for testing
- Development image publishing to GHCR
- Manual build support

### 4. 🔄 Automatic Updates (`auto-update.yml`)
**Triggers:** Weekly schedule, manual dispatch

**Features:**
- Automatic submodule updates
- Pull Request creation with updates
- Post-update testing

## 🔐 Setting up Secrets

### 1. GitHub Secrets

Go to your repository → `Settings` → `Secrets and variables` → `Actions` → `Secrets` tab:

```bash
# Required for Docker Hub publishing (if DOCKERHUB_ENABLED=true)
DOCKERHUB_USERNAME=your-dockerhub-username
DOCKERHUB_TOKEN=your-dockerhub-access-token

# Optional: For notifications
TELEGRAM_BOT_TOKEN=your-telegram-bot-token
TELEGRAM_CHAT_ID=your-telegram-chat-id
```

### 2. Repository Variables

Go to your repository → `Settings` → `Secrets and variables` → `Actions` → `Variables` tab:

```bash
# Control pipeline features
IMAGE_NAME=your-username/your-image-name        # Your Docker image name
DOCKERHUB_ENABLED=false                         # Enable Docker Hub publishing
GHCR_ENABLED=true                              # Enable GitHub Container Registry
CREATE_GITHUB_RELEASE=true                     # Create GitHub releases
SECURITY_SCAN_ENABLED=true                     # Enable Trivy security scans
```

## 🛠️ Creating Releases

### Automatic Release Creation

1. **Create and push a tag:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Pipeline automatically:**
   - Builds multi-platform Docker images
   - Publishes to Docker Hub and/or GHCR
   - Creates GitHub release with changelog
   - Runs security scans

### Manual Release Creation

1. Go to your repository → `Actions`
2. Select `Release Pipeline` workflow
3. Click `Run workflow`
4. Enter tag version (e.g., `v1.0.0`)
5. Run workflow

### Version Naming

- **Release versions:** `v1.0.0`, `v1.2.3`
- **Pre-release versions:** `v1.0.0-rc1`, `v1.0.0-beta1`
- **Development builds:** `dev-main-abc1234`, `dev-develop-xyz789`

## 🐳 Docker Image Tags

### Production Images

```bash
# Latest stable release
docker pull ghcr.io/asychin/amnezia-wg-docker:latest
docker pull asychin/amnezia-wg-docker:latest

# Specific version
docker pull ghcr.io/asychin/amnezia-wg-docker:1.0.0
docker pull asychin/amnezia-wg-docker:1.0.0

# Latest pre-release
docker pull ghcr.io/asychin/amnezia-wg-docker:1.0.0-rc1
```

### Development Images

```bash
# Latest development build
docker pull ghcr.io/asychin/amnezia-wg-docker:dev-latest

# Specific commit build
docker pull ghcr.io/asychin/amnezia-wg-docker:dev-main-abc1234
```

## 🔧 Pipeline Configuration

### Customizing Builds

Edit `.github/workflows/release.yml` to customize:

```yaml
# Platform targets
platforms: linux/amd64,linux/arm64

# Docker registries
registries:
  - ghcr.io
  - docker.io  # if DOCKERHUB_ENABLED=true

# Build arguments
build-args: |
  BUILD_DATE=${{ steps.date.outputs.date }}
  VCS_REF=${{ github.sha }}
  VERSION=${{ steps.version.outputs.version }}
```

### Environment Variables

Control pipeline behavior with repository variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `IMAGE_NAME` | `your-username/amneziawg-docker` | Docker image name |
| `DOCKERHUB_ENABLED` | `false` | Enable Docker Hub publishing |
| `GHCR_ENABLED` | `true` | Enable GitHub Container Registry |
| `CREATE_GITHUB_RELEASE` | `true` | Create GitHub releases |
| `SECURITY_SCAN_ENABLED` | `true` | Enable Trivy security scans |

## 🔍 Monitoring Pipeline

### GitHub Actions Dashboard

1. Go to your repository → `Actions`
2. View workflow runs and their status
3. Check logs for detailed information
4. Download artifacts if available

### Build Status Badges

Add to your README.md:

```markdown
[![CI](https://github.com/your-username/amneziawg-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/your-username/amneziawg-docker/actions/workflows/ci.yml)
[![Release](https://github.com/your-username/amneziawg-docker/actions/workflows/release.yml/badge.svg)](https://github.com/your-username/amneziawg-docker/actions/workflows/release.yml)
```

## 🚨 Troubleshooting

### Common Issues

1. **Docker build fails:**
   - Check Dockerfile syntax
   - Verify build context
   - Review error logs in Actions

2. **Publishing fails:**
   - Verify repository secrets
   - Check token permissions
   - Ensure DOCKERHUB_ENABLED is set correctly

3. **Release creation fails:**
   - Check if tag already exists
   - Verify token permissions
   - Review changelog generation

### Debug Tips

1. **Enable debug logging:**
   ```yaml
   env:
     ACTIONS_STEP_DEBUG: true
   ```

2. **Check runner environment:**
   ```yaml
   - name: Debug Info
     run: |
       echo "Runner OS: $RUNNER_OS"
       echo "GitHub Event: $GITHUB_EVENT_NAME"
       echo "GitHub Ref: $GITHUB_REF"
   ```

3. **Validate secrets:**
   ```yaml
   - name: Check Secrets
     run: |
       echo "Docker Hub enabled: ${{ vars.DOCKERHUB_ENABLED }}"
       echo "Has Docker token: ${{ secrets.DOCKERHUB_TOKEN != '' }}"
   ```

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Trivy Security Scanner](https://github.com/aquasecurity/trivy-action)

---

## 🔗 Related Documentation

- [🍴 Fork Setup Guide](fork-setup.md) - Set up pipeline for your fork