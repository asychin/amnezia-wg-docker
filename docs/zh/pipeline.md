# 🚀 CI/CD 流水线 - AmneziaWG Docker Server

用于自动构建、测试和发布 AmneziaWG Docker Server 镜像的综合性 CI/CD 流水线。

**🌍 Languages: [🇺🇸 English](../en/pipeline.md) | [🇷🇺 Russian](../ru/pipeline.md)**

---

## 🌟 流水线功能

### ⚙️ 自动化
- **🏷️ 发布**: 推送标签时自动创建发布
- **🐳 Docker**: 多平台镜像构建 (AMD64, ARM64)
- **📦 发布**: 自动发布到 Docker Hub 和 GitHub Container Registry
- **🧪 测试**: 每个 PR 的综合测试
- **🔄 更新**: 每周自动依赖更新
- **📝 变更日志**: 自动生成发布变更日志

### 🏗️ 可用镜像

```bash
# GitHub Container Registry - 默认 (无需设置)
docker pull ghcr.io/asychin/amnezia-wg-docker:latest
docker pull ghcr.io/asychin/amnezia-wg-docker:1.0.0

# Docker Hub - 可选 (需要 DOCKERHUB_ENABLED=true + secrets)
docker pull asychin/amnezia-wg-docker:latest
docker pull asychin/amnezia-wg-docker:1.0.0

# 开发构建
docker pull ghcr.io/asychin/amnezia-wg-docker:dev-latest
docker pull ghcr.io/asychin/amnezia-wg-docker:dev-main-abc1234
```

## 📋 工作流程

### 1. 🚀 发布流水线 (`release.yml`)
**触发器:** 推送标签 `v*`，手动调度

**功能:**
- 多平台 Docker 镜像构建
- 发布到 Docker Hub 和 GHCR
- 创建 GitHub 发布和变更日志
- 自动预发布版本检测

### 2. 🔄 持续集成 (`ci.yml`)
**触发器:** 推送到主分支，Pull Request

**检查:**
- 代码和项目结构验证
- Docker 镜像测试构建
- 集成测试
- Trivy 安全扫描

### 3. 🛠️ 开发构建 (`build-dev.yml`)
**触发器:** 推送到 `develop`、`feature/*`、`hotfix/*`

**功能:**
- 用于测试的快速构建
- 开发镜像发布到 GHCR
- 手动构建支持

### 4. 🔄 自动更新 (`auto-update.yml`)
**触发器:** 每周计划，手动调度

**功能:**
- 自动子模块更新
- 创建更新的 Pull Request
- 更新后测试

## 🔐 设置密钥

### 1. GitHub 密钥

前往您的仓库 → `Settings` → `Secrets and variables` → `Actions` → `Secrets` 标签:

```bash
# Docker Hub 发布所需 (如果 DOCKERHUB_ENABLED=true)
DOCKERHUB_USERNAME=your-dockerhub-username
DOCKERHUB_TOKEN=your-dockerhub-access-token

# 可选: 用于通知
TELEGRAM_BOT_TOKEN=your-telegram-bot-token
TELEGRAM_CHAT_ID=your-telegram-chat-id
```

### 2. 仓库变量

前往您的仓库 → `Settings` → `Secrets and variables` → `Actions` → `Variables` 标签:

```bash
# 控制流水线功能
IMAGE_NAME=your-username/your-image-name        # 您的 Docker 镜像名称
DOCKERHUB_ENABLED=false                         # 启用 Docker Hub 发布
GHCR_ENABLED=true                              # 启用 GitHub Container Registry
CREATE_GITHUB_RELEASE=true                     # 创建 GitHub 发布
SECURITY_SCAN_ENABLED=true                     # 启用 Trivy 安全扫描
```

## 🛠️ 创建发布

### 自动发布创建

1. **创建并推送标签:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **流水线自动:**
   - 构建多平台 Docker 镜像
   - 发布到 Docker Hub 和/或 GHCR
   - 创建 GitHub 发布和变更日志
   - 运行安全扫描

### 手动发布创建

1. 前往您的仓库 → `Actions`
2. 选择 `Release Pipeline` 工作流程
3. 点击 `Run workflow`
4. 输入标签版本 (例如 `v1.0.0`)
5. 运行工作流程

### 版本命名

- **发布版本:** `v1.0.0`, `v1.2.3`
- **预发布版本:** `v1.0.0-rc1`, `v1.0.0-beta1`
- **开发构建:** `dev-main-abc1234`, `dev-develop-xyz789`

## 🐳 Docker 镜像标签

### 生产镜像

```bash
# 最新稳定发布
docker pull ghcr.io/asychin/amnezia-wg-docker:latest
docker pull asychin/amnezia-wg-docker:latest

# 特定版本
docker pull ghcr.io/asychin/amnezia-wg-docker:1.0.0
docker pull asychin/amnezia-wg-docker:1.0.0

# 最新预发布
docker pull ghcr.io/asychin/amnezia-wg-docker:1.0.0-rc1
```

### 开发镜像

```bash
# 最新开发构建
docker pull ghcr.io/asychin/amnezia-wg-docker:dev-latest

# 特定提交构建
docker pull ghcr.io/asychin/amnezia-wg-docker:dev-main-abc1234
```

## 🔧 流水线配置

### 自定义构建

编辑 `.github/workflows/release.yml` 进行自定义:

```yaml
# 平台目标
platforms: linux/amd64,linux/arm64

# Docker 注册表
registries:
  - ghcr.io
  - docker.io  # 如果 DOCKERHUB_ENABLED=true

# 构建参数
build-args: |
  BUILD_DATE=${{ steps.date.outputs.date }}
  VCS_REF=${{ github.sha }}
  VERSION=${{ steps.version.outputs.version }}
```

### 环境变量

使用仓库变量控制流水线行为:

| 变量 | 默认值 | 描述 |
|------|--------|------|
| `IMAGE_NAME` | `your-username/amneziawg-docker` | Docker 镜像名称 |
| `DOCKERHUB_ENABLED` | `false` | 启用 Docker Hub 发布 |
| `GHCR_ENABLED` | `true` | 启用 GitHub Container Registry |
| `CREATE_GITHUB_RELEASE` | `true` | 创建 GitHub 发布 |
| `SECURITY_SCAN_ENABLED` | `true` | 启用 Trivy 安全扫描 |

## 🔍 监控流水线

### GitHub Actions 仪表板

1. 前往您的仓库 → `Actions`
2. 查看工作流程运行及其状态
3. 检查日志以获取详细信息
4. 如果可用，下载构件

### 构建状态徽章

添加到您的 README.md:

```markdown
[![CI](https://github.com/your-username/amneziawg-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/your-username/amneziawg-docker/actions/workflows/ci.yml)
[![Release](https://github.com/your-username/amneziawg-docker/actions/workflows/release.yml/badge.svg)](https://github.com/your-username/amneziawg-docker/actions/workflows/release.yml)
```

## 🚨 故障排除

### 常见问题

1. **Docker 构建失败:**
   - 检查 Dockerfile 语法
   - 验证构建上下文
   - 查看 Actions 中的错误日志

2. **发布失败:**
   - 验证仓库密钥
   - 检查令牌权限
   - 确保 DOCKERHUB_ENABLED 设置正确

3. **发布创建失败:**
   - 检查标签是否已存在
   - 验证令牌权限
   - 查看变更日志生成

### 调试技巧

1. **启用调试日志:**
   ```yaml
   env:
     ACTIONS_STEP_DEBUG: true
   ```

2. **检查运行器环境:**
   ```yaml
   - name: Debug Info
     run: |
       echo "Runner OS: $RUNNER_OS"
       echo "GitHub Event: $GITHUB_EVENT_NAME"
       echo "GitHub Ref: $GITHUB_REF"
   ```

3. **验证密钥:**
   ```yaml
   - name: Check Secrets
     run: |
       echo "Docker Hub enabled: ${{ vars.DOCKERHUB_ENABLED }}"
       echo "Has Docker token: ${{ secrets.DOCKERHUB_TOKEN != '' }}"
   ```

## 📚 额外资源

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Trivy 安全扫描器](https://github.com/aquasecurity/trivy-action)

---

## 🔗 相关文档

- [🍴 分叉设置指南](fork-setup.md) - 为您的分叉设置流水线
- [🏗️ 开发设置](development.md) - 本地开发环境
- [🐛 故障排除](troubleshooting.md) - 常见问题和解决方案