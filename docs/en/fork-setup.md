# 🔧 Fork Setup Guide

This guide helps you set up the CI/CD pipeline when forking this repository for your own projects.

**🌍 Languages: [🇺🇸 English](../en/fork-setup.md) | [🇷🇺 Русский](../ru/fork-setup.md) | [🇨🇳 中文](../zh/fork-setup.md)**

---

## 🚀 Quick Setup (5 minutes)

### 1. Fork Configuration

After forking the repository, you need to configure a few variables to make the pipeline work with your accounts.

#### Repository Variables (Recommended)

Go to your forked repository → `Settings` → `Secrets and variables` → `Actions` → `Variables` tab:

```bash
# Required: Your Docker image name
IMAGE_NAME=your-username/your-image-name

# Optional: Control pipeline features
DOCKERHUB_ENABLED=false         # Enable Docker Hub publishing (disabled by default)
GHCR_ENABLED=true              # Enable GitHub Container Registry (enabled by default)
CREATE_GITHUB_RELEASE=true     # Create GitHub releases
SECURITY_SCAN_ENABLED=true     # Enable Trivy security scans
```

#### Repository Secrets

Go to your forked repository → `Settings` → `Secrets and variables` → `Actions` → `Secrets` tab:

```bash
# Required for Docker Hub (if DOCKERHUB_ENABLED=true)
DOCKERHUB_USERNAME=your-dockerhub-username
DOCKERHUB_TOKEN=your-dockerhub-access-token

# Optional: For notifications (future features)
TELEGRAM_BOT_TOKEN=your-telegram-bot-token
TELEGRAM_CHAT_ID=your-telegram-chat-id
```

### 2. Create Docker Hub Access Token

1. Log in to [Docker Hub](https://hub.docker.com/)
2. Go to `Account Settings` → `Security`
3. Click `New Access Token`
4. Name: `GitHub Actions - Your Project`
5. Permissions: `Read, Write, Delete`
6. Copy the token and add it to GitHub Secrets

### 3. Update Configuration Files

#### Update Image Name in Makefile

Edit `Makefile` and update the image name:

```makefile
# Change this line to your image name
IMAGE_NAME ?= your-username/your-image-name
```

#### Update Docker Compose (Optional)

If you want to use your custom image in `docker-compose.yml`:

```yaml
services:
  amneziawg-server:
    image: your-username/your-image-name:latest
    # ... rest of configuration
```

### 4. Test Your Setup

1. **Create a test release:**
   ```bash
   git tag v0.1.0-test
   git push origin v0.1.0-test
   ```

2. **Check pipeline execution:**
   - Go to your repository → `Actions`
   - Verify that the release workflow runs
   - Check that images are published to your registries

3. **Clean up test release:**
   ```bash
   # Delete local tag
   git tag -d v0.1.0-test
   
   # Delete remote tag
   git push origin --delete v0.1.0-test
   ```

---

## 🎛️ Advanced Configuration

### Custom Workflow Behavior

#### Disable Docker Hub Publishing

If you only want to use GitHub Container Registry:

```bash
# Repository Variables
DOCKERHUB_ENABLED=false
GHCR_ENABLED=true
```

#### Enable Docker Hub Publishing

To publish to both registries:

```bash
# Repository Variables
DOCKERHUB_ENABLED=true
GHCR_ENABLED=true

# Repository Secrets (required)
DOCKERHUB_USERNAME=your-username
DOCKERHUB_TOKEN=your-access-token
```

#### Customize Image Names

You can use different image names for different registries:

```bash
# Repository Variables
IMAGE_NAME=your-username/custom-amneziawg
DOCKERHUB_IMAGE_NAME=your-username/amneziawg-docker
GHCR_IMAGE_NAME=your-username/amneziawg-server
```

### Multi-Platform Builds

The pipeline builds for multiple architectures by default:
- `linux/amd64` (Intel/AMD 64-bit)
- `linux/arm64` (ARM 64-bit, e.g., Apple M1, Raspberry Pi)

To customize supported platforms, edit `.github/workflows/release.yml`:

```yaml
platforms: linux/amd64,linux/arm64,linux/arm/v7
```

### Security Scanning

Trivy security scanning is enabled by default. To configure:

```bash
# Repository Variables
SECURITY_SCAN_ENABLED=true        # Enable/disable scanning
TRIVY_SEVERITY=HIGH,CRITICAL      # Scan severity levels
```

---

## 🔧 Customization Options

### Branch Protection

Set up branch protection for your main branch:

1. Go to `Settings` → `Branches`
2. Add rule for `main` or `master`
3. Enable:
   - Require status checks to pass
   - Require up-to-date branches
   - Include administrators

### Workflow Permissions

Ensure proper permissions for GitHub Actions:

1. Go to `Settings` → `Actions` → `General`
2. Set `Workflow permissions` to:
   - **Read and write permissions**
   - **Allow GitHub Actions to create and approve pull requests**

### Custom Build Arguments

Add custom build arguments to your builds by editing `.github/workflows/release.yml`:

```yaml
build-args: |
  BUILD_DATE=${{ steps.date.outputs.date }}
  VCS_REF=${{ github.sha }}
  VERSION=${{ steps.version.outputs.version }}
  CUSTOM_ARG=custom-value
```

### Environment-Specific Configurations

Create different configurations for different environments:

```bash
# Development
IMAGE_NAME=your-username/amneziawg-dev
SECURITY_SCAN_ENABLED=false

# Production
IMAGE_NAME=your-username/amneziawg-prod
SECURITY_SCAN_ENABLED=true
```

---

## 📝 Best Practices

### 1. Repository Naming

Use descriptive repository names:
- `amneziawg-docker` ✅
- `my-vpn-server` ✅
- `docker-amneziawg` ✅
- `repo1` ❌

### 2. Tagging Strategy

Follow semantic versioning:
- Major releases: `v1.0.0`, `v2.0.0`
- Minor releases: `v1.1.0`, `v1.2.0`
- Patch releases: `v1.0.1`, `v1.0.2`
- Pre-releases: `v1.0.0-rc1`, `v1.0.0-beta1`

### 3. Documentation Updates

Keep documentation in sync with your changes:
- Update README.md with your image names
- Modify examples to use your registry
- Add your contact information

### 4. Testing

Always test your pipeline:
- Create test tags first
- Verify image functionality
- Check all enabled registries

---

## 🚨 Common Issues

### Pipeline Fails

1. **Check secrets:**
   ```bash
   # Verify required secrets are set
   echo ${{ secrets.DOCKERHUB_TOKEN }}
   ```

2. **Validate variables:**
   ```bash
   # Check repository variables
   echo ${{ vars.IMAGE_NAME }}
   echo ${{ vars.DOCKERHUB_ENABLED }}
   ```

3. **Review permissions:**
   - Ensure Actions have write permissions
   - Check if organization restrictions apply

### Docker Push Fails

1. **Token permissions:**
   - Docker Hub token needs `Read, Write, Delete`
   - GitHub token needs `packages:write`

2. **Image name format:**
   ```bash
   # Correct formats
   username/image-name
   registry.com/username/image-name
   
   # Incorrect formats
   USERNAME/IMAGE-NAME  # Uppercase not allowed
   image-name           # Missing username
   ```

### Build Failures

1. **Platform issues:**
   - Some packages may not support all platforms
   - Consider removing problematic platforms

2. **Build context:**
   - Ensure all required files are in repository
   - Check .dockerignore file

---

## 🔗 Related Documentation

- [🚀 CI/CD Pipeline](pipeline.md) - Complete pipeline documentation
- [🏗️ Development Setup](development.md) - Local development environment
- [🐛 Troubleshooting](troubleshooting.md) - Common issues and solutions

---

## 💬 Getting Help

If you encounter issues:

1. **Check existing issues:** [GitHub Issues](https://github.com/asychin/amneziawg-docker/issues)
2. **Create new issue:** Include your configuration and error logs
3. **Join discussions:** [GitHub Discussions](https://github.com/asychin/amneziawg-docker/discussions)