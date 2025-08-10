# 🔧 Fork Setup Guide

This guide helps you set up the CI/CD pipeline when forking this repository for your own projects.

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

#### Option A: Use Environment Variables (Recommended)

Just set the `IMAGE_NAME` variable in GitHub repository settings. The workflows will automatically use your repository owner and image name.

> **Note**: Docker Hub is **disabled by default**. Only GHCR will be used unless you explicitly enable Docker Hub.

#### Option B: Edit Configuration File

Edit `.github/config/pipeline.yml`:

```yaml
# Change these values
image:
  name: "your-username/your-image-name"

repository:
  owner: "your-username"
  name: "your-repository-name"
```

### 4. Test Your Setup

1. **Create a test release:**
   ```bash
   make release-patch
   ```

2. **Or trigger manually:**
   - Go to `Actions` → `Release and Build Docker Images`
   - Click `Run workflow`
   - Enter version: `v0.1.0`
   - Click `Run workflow`

3. **Check results:**
   - Docker images in your Docker Hub/GHCR
   - GitHub release created
   - All checks passed

## 📋 Detailed Configuration

### Docker Registry Settings

The pipeline supports multiple registries. Configure them in `.github/config/pipeline.yml`:

```yaml
registries:
  dockerhub:
    enabled: true  # Set to false to disable
    registry: "docker.io"
    username_secret: "DOCKERHUB_USERNAME"
    token_secret: "DOCKERHUB_TOKEN"
  
  github:
    enabled: true  # GitHub Container Registry
    registry: "ghcr.io"
  
  # Add custom registries
  aws_ecr:
    enabled: false
    registry: "123456789.dkr.ecr.us-west-2.amazonaws.com"
    username_secret: "AWS_ACCESS_KEY_ID"
    token_secret: "AWS_SECRET_ACCESS_KEY"
```

### Image Configuration

```yaml
image:
  # Your image name (namespace/repository)
  name: "your-username/your-project"
  
  # Build platforms
  platforms:
    release: "linux/amd64,linux/arm64"
    development: "linux/amd64"
  
  # Tagging strategy
  tags:
    latest_on_release: true    # Add 'latest' tag for releases
    include_version: true      # Add version tags
    development_prefix: "dev"  # Prefix for dev builds
```

### Workflow Control

```yaml
workflows:
  release:
    create_github_release: true    # Create GitHub releases
    generate_changelog: true       # Auto-generate changelog
    run_security_scan: true       # Run Trivy security scan
    platforms: "linux/amd64,linux/arm64"
  
  ci:
    run_on_pr: true               # Run CI on Pull Requests
    run_security_scan: true       # Security scanning in CI
    run_integration_tests: true   # Integration tests
    hadolint_enabled: true        # Dockerfile linting
  
  development:
    auto_push_dev_images: true    # Auto-push dev images
    platforms: "linux/amd64"     # Faster dev builds
  
  auto_update:
    schedule_enabled: true        # Weekly dependency updates
    create_pr: true              # Auto-create PR for updates
    update_submodules: true      # Update git submodules
```

## 🔐 Security Best Practices

### 1. Use Repository Variables for Non-Sensitive Data

```bash
# Repository Variables (public in repository settings)
IMAGE_NAME=your-username/your-image
DOCKERHUB_ENABLED=true
```

### 2. Use Secrets for Sensitive Data

```bash
# Repository Secrets (encrypted)
DOCKERHUB_USERNAME=your-username
DOCKERHUB_TOKEN=dckr_pat_1234567890abcdef
```

### 3. Token Permissions

- **Docker Hub Token**: Read, Write, Delete permissions
- **GitHub Token**: Automatically provided, no setup needed
- **Custom Registry Tokens**: Minimal required permissions only

### 4. Security Scanning

The pipeline includes Trivy security scanning. Configure severity levels:

```yaml
security:
  trivy:
    enabled: true
    fail_on_high: false      # Don't fail on HIGH severity
    fail_on_critical: true   # Fail on CRITICAL severity
```

## 🌍 Multi-Registry Publishing

You can publish to multiple registries simultaneously:

```yaml
registries:
  dockerhub:
    enabled: true
    registry: "docker.io"
  
  github:
    enabled: true
    registry: "ghcr.io"
  
  aws_ecr:
    enabled: true
    registry: "123456789.dkr.ecr.region.amazonaws.com"
    username_secret: "AWS_ACCESS_KEY_ID"
    token_secret: "AWS_SECRET_ACCESS_KEY"
  
  custom:
    enabled: true
    registry: "registry.your-company.com"
    username_secret: "REGISTRY_USERNAME"
    token_secret: "REGISTRY_TOKEN"
```

Add corresponding secrets for each enabled registry.

## 🏷️ Customizing Release Process

### Semantic Versioning

The pipeline supports semantic versioning with these commands:

```bash
# Automated versioning
make release-patch      # 1.0.0 → 1.0.1
make release-minor      # 1.0.0 → 1.1.0
make release-major      # 1.0.0 → 2.0.0
make release-prerelease # 1.0.0 → 1.0.1-rc.1

# Custom version
make release-custom version=1.2.3
```

### Release Script Customization

Edit `.github/scripts/release.sh` to modify:
- Version increment logic
- Changelog generation
- Tag creation process
- Validation steps

### GitHub Release Customization

Modify the changelog template in `.github/workflows/release.yml`:

```bash
FULL_CHANGELOG="## 🚀 Your Project ${VERSION#v}

### 🔥 What's New:
$CHANGELOG

### 🐳 Docker Images:
- \`docker.io/your-username/your-image:${VERSION#v}\`
- \`ghcr.io/your-username/your-image:${VERSION#v}\`

### 🚀 Quick Start:
\`\`\`bash
docker run -d your-username/your-image:${VERSION#v}
\`\`\`"
```

## 🔄 Customizing CI/CD Triggers

### Push Triggers

```yaml
on:
  push:
    branches: [ main, master, develop ]  # Add your branches
    paths-ignore:
      - '**.md'
      - 'docs/**'
      - 'your-ignore-pattern/**'
```

### Schedule Triggers

```yaml
on:
  schedule:
    - cron: '0 2 * * 1'  # Weekly on Monday
    - cron: '0 0 * * *'  # Daily builds
```

### Manual Triggers

```yaml
on:
  workflow_dispatch:
    inputs:
      custom_input:
        description: 'Your custom input'
        required: false
        default: 'default-value'
```

## 🧪 Testing Your Fork

### 1. Local Testing

```bash
# Clone your fork
git clone --recursive https://github.com/your-username/your-fork.git
cd your-fork

# Test build
make build
make up
make test
```

### 2. Pipeline Testing

```bash
# Test release process
make release-test

# Create test release
make release-custom version=0.1.0-test
```

### 3. Verify Results

- Check Docker Hub for your images
- Verify GitHub Container Registry
- Confirm GitHub releases are created
- Review CI/CD logs for issues

## 🆘 Troubleshooting

### Common Issues

1. **Image name conflicts**: Make sure `IMAGE_NAME` is unique
2. **Docker Hub permissions**: Verify token has correct permissions
3. **Registry authentication**: Check username/token pairs
4. **Workflow permissions**: Ensure repository has Actions enabled

### Debug Commands

```bash
# Check current configuration
cat .github/config/pipeline.yml

# Test local build
docker build -t test-image .

# Check image
docker run --rm test-image amneziawg-go --version
```

### Getting Help

1. Check [GitHub Actions logs](https://github.com/your-username/your-fork/actions)
2. Review [original repository issues](https://github.com/asychin/amnezia-wg-docker/issues)
3. Create an issue in your fork with detailed logs

---

## ✅ Quick Checklist

- [ ] Set `IMAGE_NAME` repository variable
- [ ] Add Docker Hub secrets (if using Docker Hub)
- [ ] Test with `make release-custom version=0.1.0-test`
- [ ] Verify images appear in your registries
- [ ] Check GitHub releases are created
- [ ] Customize configuration as needed

**Your fork is ready! 🎉**

The pipeline will now automatically build and publish Docker images when you create releases, run comprehensive tests on PRs, and keep your dependencies up to date.
