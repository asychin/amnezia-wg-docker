# 🚀 CI/CD Пайплайн - AmneziaWG Docker Server

Комплексный CI/CD пайплайн для автоматизированной сборки, тестирования и публикации образов AmneziaWG Docker Server.

<details>
  <summary>🌍 Язык: Русский</summary>
  <p>
    <a href="../en/pipeline.md">🇺🇸 English</a> •
    <a href="../ru/pipeline.md">🇷🇺 Русский</a> •
    <a href="../zh/pipeline.md">🇨🇳 中文</a>
  </p>
</details>

---

## 🌟 Возможности пайплайна

### ⚙️ Автоматизация
- **🏷️ Релизы**: Автоматическое создание релизов при push тегов
- **🐳 Docker**: Мультиплатформенная сборка образов (AMD64, ARM64)
- **📦 Публикация**: Автоматическая публикация в Docker Hub и GitHub Container Registry
- **🧪 Тестирование**: Комплексное тестирование при каждом PR
- **🔄 Обновления**: Еженедельные автоматические обновления зависимостей
- **📝 Changelog**: Автоматическая генерация списка изменений для релизов

### 🏗️ Доступные образы

```bash
# GitHub Container Registry - По умолчанию (настройка не требуется)
docker pull ghcr.io/asychin/amneziawg-docker:latest
docker pull ghcr.io/asychin/amneziawg-docker:1.0.0

# Docker Hub - Опционально (требует DOCKERHUB_ENABLED=true + секреты)
docker pull asychin/amneziawg-docker:latest
docker pull asychin/amneziawg-docker:1.0.0

# Сборки для разработки
docker pull ghcr.io/asychin/amneziawg-docker:dev-latest
docker pull ghcr.io/asychin/amneziawg-docker:dev-main-abc1234
```

## 📋 Рабочие процессы

### 1. 🚀 Пайплайн релизов (`release.yml`)
**Триггеры:** Push тегов `v*`, ручной запуск

**Возможности:**
- Мультиплатформенная сборка Docker образов
- Публикация в Docker Hub и GHCR
- Создание GitHub релизов с changelog
- Автоматическое определение pre-release версий

### 2. 🔄 Непрерывная интеграция (`ci.yml`)
**Триггеры:** Push в основные ветки, Pull Request'ы

**Проверки:**
- Валидация кода и структуры проекта
- Тестовые сборки Docker образов
- Интеграционные тесты
- Сканирование безопасности с Trivy

### 3. 🛠️ Сборки для разработки (`build-dev.yml`)
**Триггеры:** Push в `develop`, `feature/*`, `hotfix/*`

**Возможности:**
- Быстрые сборки для тестирования
- Публикация образов разработки в GHCR
- Поддержка ручного запуска

### 4. 🔄 Автоматические обновления (`auto-update.yml`)
**Триггеры:** Еженедельное расписание, ручной запуск

**Возможности:**
- Автоматическое обновление субмодулей
- Создание Pull Request'ов с обновлениями
- Тестирование после обновлений

## 🔐 Настройка секретов

### 1. GitHub секреты

Перейдите в репозиторий → `Settings` → `Secrets and variables` → `Actions` → вкладка `Secrets`:

```bash
# Необходимо для публикации в Docker Hub (если DOCKERHUB_ENABLED=true)
DOCKERHUB_USERNAME=your-dockerhub-username
DOCKERHUB_TOKEN=your-dockerhub-access-token

# Опционально: Для уведомлений
TELEGRAM_BOT_TOKEN=your-telegram-bot-token
TELEGRAM_CHAT_ID=your-telegram-chat-id
```

### 2. Переменные репозитория

Перейдите в репозиторий → `Settings` → `Secrets and variables` → `Actions` → вкладка `Variables`:

```bash
# Контроль возможностей пайплайна
IMAGE_NAME=your-username/your-image-name        # Имя Docker образа
DOCKERHUB_ENABLED=false                         # Включить публикацию в Docker Hub
GHCR_ENABLED=true                              # Включить GitHub Container Registry
CREATE_GITHUB_RELEASE=true                     # Создавать GitHub релизы
SECURITY_SCAN_ENABLED=true                     # Включить сканирование безопасности Trivy
```

## 🛠️ Создание релизов

### Автоматическое создание релизов

1. **Создайте и отправьте тег:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Пайплайн автоматически:**
   - Собирает мультиплатформенные Docker образы
   - Публикует в Docker Hub и/или GHCR
   - Создает GitHub релиз с changelog
   - Запускает сканирование безопасности

### Ручное создание релизов

1. Перейдите в репозиторий → `Actions`
2. Выберите workflow `Release Pipeline`
3. Нажмите `Run workflow`
4. Введите версию тега (например, `v1.0.0`)
5. Запустите workflow

### Именование версий

- **Релизные версии:** `v1.0.0`, `v1.2.3`
- **Pre-release версии:** `v1.0.0-rc1`, `v1.0.0-beta1`
- **Сборки разработки:** `dev-main-abc1234`, `dev-develop-xyz789`

## 🐳 Теги Docker образов

### Продакшн образы

```bash
# Последний стабильный релиз
docker pull ghcr.io/asychin/amneziawg-docker:latest
docker pull asychin/amneziawg-docker:latest

# Конкретная версия
docker pull ghcr.io/asychin/amneziawg-docker:1.0.0
docker pull asychin/amneziawg-docker:1.0.0

# Последний pre-release
docker pull ghcr.io/asychin/amneziawg-docker:1.0.0-rc1
```

### Образы для разработки

```bash
# Последняя сборка разработки
docker pull ghcr.io/asychin/amneziawg-docker:dev-latest

# Сборка конкретного коммита
docker pull ghcr.io/asychin/amneziawg-docker:dev-main-abc1234
```

## 🔧 Конфигурация пайплайна

### Настройка сборок

Отредактируйте `.github/workflows/release.yml` для настройки:

```yaml
# Целевые платформы
platforms: linux/amd64,linux/arm64

# Docker реестры
registries:
  - ghcr.io
  - docker.io  # если DOCKERHUB_ENABLED=true

# Аргументы сборки
build-args: |
  BUILD_DATE=${{ steps.date.outputs.date }}
  VCS_REF=${{ github.sha }}
  VERSION=${{ steps.version.outputs.version }}
```

### Переменные окружения

Управляйте поведением пайплайна с помощью переменных репозитория:

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `IMAGE_NAME` | `your-username/amneziawg-docker` | Имя Docker образа |
| `DOCKERHUB_ENABLED` | `false` | Включить публикацию в Docker Hub |
| `GHCR_ENABLED` | `true` | Включить GitHub Container Registry |
| `CREATE_GITHUB_RELEASE` | `true` | Создавать GitHub релизы |
| `SECURITY_SCAN_ENABLED` | `true` | Включить сканирование безопасности Trivy |

## 🔍 Мониторинг пайплайна

### Панель GitHub Actions

1. Перейдите в репозиторий → `Actions`
2. Просматривайте запуски workflow и их статус
3. Проверяйте логи для подробной информации
4. Скачивайте артефакты если доступны

### Значки статуса сборки

Добавьте в ваш README.md:

```markdown
[![CI](https://github.com/your-username/amneziawg-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/your-username/amneziawg-docker/actions/workflows/ci.yml)
[![Release](https://github.com/your-username/amneziawg-docker/actions/workflows/release.yml/badge.svg)](https://github.com/your-username/amneziawg-docker/actions/workflows/release.yml)
```

## 🚨 Решение проблем

### Распространенные проблемы

1. **Сбой сборки Docker:**
   - Проверьте синтаксис Dockerfile
   - Проверьте контекст сборки
   - Просмотрите логи ошибок в Actions

2. **Сбой публикации:**
   - Проверьте секреты репозитория
   - Проверьте права токена
   - Убедитесь что DOCKERHUB_ENABLED установлен правильно

3. **Сбой создания релиза:**
   - Проверьте существует ли тег уже
   - Проверьте права токена
   - Просмотрите генерацию changelog

### Советы по отладке

1. **Включите отладочное логирование:**
   ```yaml
   env:
     ACTIONS_STEP_DEBUG: true
   ```

2. **Проверьте окружение runner'а:**
   ```yaml
   - name: Debug Info
     run: |
       echo "Runner OS: $RUNNER_OS"
       echo "GitHub Event: $GITHUB_EVENT_NAME"
       echo "GitHub Ref: $GITHUB_REF"
   ```

3. **Валидируйте секреты:**
   ```yaml
   - name: Check Secrets
     run: |
       echo "Docker Hub enabled: ${{ vars.DOCKERHUB_ENABLED }}"
       echo "Has Docker token: ${{ secrets.DOCKERHUB_TOKEN != '' }}"
   ```

## 📚 Дополнительные ресурсы

- [Документация GitHub Actions](https://docs.github.com/en/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Сканер безопасности Trivy](https://github.com/aquasecurity/trivy-action)

---

## 🔗 Связанная документация

- [🍴 Руководство по настройке форка](fork-setup.md) - Настройка пайплайна для вашего форка
- [🏗️ Настройка разработки](development.md) - Локальная среда разработки
- [🐛 Устранение неполадок](troubleshooting.md) - Распространенные проблемы и решения