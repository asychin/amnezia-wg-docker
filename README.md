# AmneziaWG Docker Server

Контейнеризированный VPN-сервер с обходом DPI. Основан на протоколе AmneziaWG v2 для обфускации трафика.

## Возможности

- Установка за одну минуту с автоматической настройкой
- Обход DPI через обфускацию трафика (AmneziaWG v2 — S1/S2/S3/S4)
- Userspace режим (не требуются модули ядра)
- QR-код и vpn:// URI для мобильных клиентов
- Автоматические бэкапы с sidecar-сервисом
- Встроенный healthcheck и мониторинг

## Быстрый старт

```bash
# Клонирование с сабмодулями
git clone --recursive https://github.com/asychin/amnezia-wg-docker.git
cd amnezia-wg-docker

# Запуск сервера
make up

# Добавить клиента (автоматически показывает QR + vpn:// URI)
make client-add john

# Показать QR-код для мобильного
make client-qr john

# Показать vpn:// URI для импорта в AmneziaVPN
make client-vpnurl john
```

Если забыли `--recursive` при клонировании:
```bash
git submodule update --init --recursive
```

## Требования

- Docker 20.10+
- Docker Compose 2.0+
- Git

## Команды

### Основные

| Команда | Описание |
|---------|----------|
| `make up` | Запустить VPN-сервер |
| `make down` | Остановить сервер |
| `make restart` | Перезапустить сервер |
| `make reload` | Перезагрузить конфигурацию (без перезапуска) |
| `make status` | Показать статус сервера |
| `make logs` | Просмотр логов |
| `make build` | Собрать Docker-образ (с кешем) |
| `make rebuild` | Пересобрать Docker-образ (без кеша) |

### Управление клиентами

| Команда | Описание |
|---------|----------|
| `make client-add john` | Добавить клиента |
| `make client-add john 10.13.13.5` | Добавить клиента с конкретным IP |
| `make client-rm john` | Удалить клиента |
| `make client-qr john` | Показать QR-код |
| `make client-config john` | Показать конфигурацию |
| `make client-vpnurl john` | Показать vpn:// URI |
| `make client-list` | Список всех клиентов |

### Бэкапы

| Команда | Описание |
|---------|----------|
| `make backup` | Создать бэкап вручную |
| `make restore file=backups/file.tar.gz` | Восстановить из бэкапа |
| `make backup-cleanup` | Удалить старые бэкапы |
| `make backup-verify file=backups/file.tar.gz` | Проверить целостность бэкапа |

### Утилиты

| Команда | Описание |
|---------|----------|
| `make shell` | Войти в контейнер |
| `make debug` | Показать диагностику |
| `make test` | Проверить связность сервера |
| `make clean` | Полная очистка (удаляет все данные) |
| `make version` | Показать версию |

## Конфигурация

Скопируйте `.env.example` в `.env` и настройте. Основные параметры:

| Переменная | По умолчанию | Описание |
|------------|-------------|----------|
| `AWG_PORT` | 51820 | UDP порт (443 или 53 для маскировки под HTTPS/DNS) |
| `AWG_NET` | 10.13.13.0/24 | VPN сеть |
| `AWG_DNS` | 8.8.8.8,8.8.4.4 | DNS серверы для клиентов |
| `SERVER_PUBLIC_IP` | auto | Публичный IP сервера (автоопределение) |

### Параметры обфускации (AmneziaWG v2)

Генерируются автоматически при первом `make init`:

| Переменная | Диапазон | Описание |
|------------|---------|----------|
| `AWG_JC` | 4-12 | Количество мусорных пакетов |
| `AWG_JMIN` | 8-50 | Мин. размер мусорного пакета |
| `AWG_JMAX` | 80-250 | Макс. размер мусорного пакета |
| `AWG_S1` | 15-150 | Размер мусорных данных в init-пакетах |
| `AWG_S2` | 15-150 | Размер мусорных данных в response-пакетах |
| `AWG_S3` | 0-1216 | Размер мусорных данных в cookie-пакетах **(v2 NEW)** |
| `AWG_S4` | 0-32 | Размер мусорных данных в data-пакетах **(v2 NEW)** |
| `AWG_H1-H4` | 5-2147483647 | Magic header values (уникальные 32-bit целые) |

Ограничение: `S1 + 56 != S2` (гарантирует разные размеры пакетов).

## Автоматические бэкапы

Bэкапы запускаются автоматически как sidecar-контейнер в docker-compose:

```bash
# Ручной бэкап
make backup

# Восстановление
make restore file=backups/amneziawg-20240101-120000.tar.gz
```

Настройки в `.env`:
- `BACKUP_INTERVAL` — Интервал бэкапов (по умолчанию: 24h)
- `BACKUP_KEEP` — Количество хранимых бэкапов (по умолчанию: 10)

## Подключение мобильных устройств

1. Установите AmneziaVPN ([Android](https://play.google.com/store/apps/details?id=org.amnezia.vpn) / [iOS](https://apps.apple.com/app/amneziavpn/id1600529900))
2. **Способ 1 (QR-код):** `make client-qr <name>` → отсканируйте QR-код
3. **Способ 2 (vpn:// URI):** `make client-vpnurl <name>` → скопируйте строку и вставьте в приложение
4. Подключитесь

## Структура файлов

```
amnezia-wg-docker/
├── config/           # Конфигурация сервера
├── clients/          # Конфигурации клиентов
├── backups/          # Архивы бэкапов
├── scripts/          # Рабочие скрипты
│   ├── common.sh     # Общая библиотека (логирование, валидация, IP-детекция)
│   ├── entrypoint.sh # Точка входа контейнера
│   ├── manage-clients.sh # Управление клиентами
│   ├── generate-vpn-uri.sh # Генерация vpn:// URI
│   ├── backup.sh     # Автоматические бэкапы
│   ├── healthcheck.sh # Проверка здоровья
│   └── diagnose.sh   # Диагностика
├── amneziawg-go/     # Go-реализация (сабмодуль)
└── amneziawg-tools/  # CLI-утилиты (сабмодуль)
```

## Решение проблем

Проверка статуса сервера:
```bash
make status
make debug
make test
```

Просмотр логов:
```bash
make logs
```

Частые проблемы:
- Порт занят: измените `AWG_PORT` в `.env`
- Сабмодули отсутствуют: выполните `git submodule update --init --recursive`
- Контейнер не запускается: проверьте `make debug`

## Документация

- [Руководство по безопасности](SECURITY.md)
- [Руководство по миграции](MIGRATION.md)
- [CI/CD Pipeline](PIPELINE.md)

## Лицензия

MIT License — см. [LICENSE](LICENSE)

## Авторы

- [AmneziaVPN Team](https://github.com/amnezia-vpn) — Оригинальный протокол AmneziaWG
- Docker-реализация от [@asychin](https://github.com/asychin)
