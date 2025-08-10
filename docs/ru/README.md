# 🔒 AmneziaWG Docker Server - Полное руководство

<div align="center">

**Готовое к продакшену Docker решение для AmneziaWG VPN сервера с userspace реализацией и обходом DPI**

[![GitHub Release](https://img.shields.io/github/v/release/asychin/amnezia-wg-docker?style=flat-square&logo=github)](https://github.com/asychin/amnezia-wg-docker/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/asychin/amnezia-wg-docker?style=flat-square&logo=docker)](https://hub.docker.com/r/asychin/amnezia-wg-docker)
[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-asychin%2Famnezia--wg--docker-blue?style=flat-square&logo=docker)](https://ghcr.io/asychin/amnezia-wg-docker)
[![GitHub Stars](https://img.shields.io/github/stars/asychin/amnezia-wg-docker?style=flat-square&logo=github)](https://github.com/asychin/amnezia-wg-docker/stargazers)

> 🍴 **Форкнули репозиторий?** Обновите badges выше, заменив `asychin/amnezia-wg-docker` на `yourusername/amnezia-wg-docker` в файлах документации.

**🌍 Languages: [🇺🇸 English](../../README.md) | [🇨🇳 Chinese](../zh/README.md)**

</div>

---

## 📖 О проекте

Этот проект предоставляет **контейнеризованный AmneziaWG VPN сервер** с userspace реализацией. AmneziaWG - это протокол на основе WireGuard, который добавляет возможности обфускации для обхода DPI (Deep Packet Inspection) систем.

### Ключевые компоненты:
- **amneziawg-go**: Userspace реализация (не требует модулей ядра)
- **amneziawg-tools**: Утилиты конфигурации и управления
- **Docker контейнеризация**: Простое развертывание и управление
- **Makefile автоматизация**: Простые команды для всех операций

---

## 🌟 Особенности

- ✅ **AmneziaWG userspace** - работает без модулей ядра
- ✅ **Обход DPI** - маскировка VPN трафика под HTTPS
- ✅ **Docker контейнер** - простое развертывание с docker-compose
- ✅ **Автоопределение IP** - умное определение публичного IP через несколько сервисов
- ✅ **Автоматическая настройка** - iptables, маршрутизация, DNS
- ✅ **QR коды** - быстрое подключение мобильных клиентов
- ✅ **Управление клиентами** - добавление/удаление через команды Makefile
- ✅ **Мониторинг** - логи в реальном времени и статус соединений
- ✅ **Резервное копирование** - управление конфигурациями
- ✅ **Healthcheck** - встроенный мониторинг сервиса

---

## 🚀 Быстрый старт

### 1. Клонирование и инициализация

```bash
git clone --recursive https://github.com/asychin/amnezia-wg-docker.git
cd amnezia-wg-docker

# Если забыли --recursive:
git submodule update --init --recursive
```

### 2. Сборка и запуск

```bash
# Сборка Docker образа
make build

# Запуск VPN сервера
make up

# Проверка статуса
make status
```

### 3. Добавление клиентов

```bash
# Добавить клиента с автоматическим назначением IP
make client-add name=myphone

# Добавить клиента с конкретным IP
make client-add name=laptop ip=10.13.13.15

# Показать QR код для мобильной настройки
make client-qr name=myphone

# Экспорт конфигурационного файла
make client-config name=laptop > laptop.conf
```

---

## 📋 Доступные команды

| Команда | Описание |
|---------|-----------|
| `make help` | Показать все доступные команды |
| `make build` | Собрать Docker образ |
| `make up` | Запустить VPN сервер |
| `make down` | Остановить VPN сервер |
| `make restart` | Перезапустить VPN сервер |
| `make status` | Показать статус сервера и соединений |
| `make logs` | Просмотр логов в реальном времени |
| `make client-add name=X` | Добавить нового клиента |
| `make client-rm name=X` | Удалить клиента |
| `make client-qr name=X` | Показать QR код клиента |
| `make client-config name=X` | Показать конфигурацию клиента |
| `make client-list` | Список всех клиентов |
| `make backup` | Создать резервную копию конфигурации |
| `make clean` | Полная очистка (остановка + удаление данных) |

---

## 🛠️ Технические детали

### Конфигурация сети
- **VPN сеть**: `10.13.13.0/24`
- **IP сервера**: `10.13.13.1`
- **Порт**: `51820/udp`
- **DNS**: `8.8.8.8, 8.8.4.4`

### Параметры обфускации AmneziaWG
- **Количество мусорных пакетов (Jc)**: 7
- **Мин. размер мусорного пакета (Jmin)**: 50
- **Макс. размер мусорного пакета (Jmax)**: 1000
- **Размер мусора в init пакете**: 86
- **Размер мусора в response пакете**: 574
- **Поля заголовка**: H1=1, H2=2, H3=3, H4=4

### Требования
- Docker с Docker Compose
- Git (для сабмодулей)
- Root привилегии (для настройки сети)

---

## 📚 Документация

Полная документация доступна в этом файле. Для технических деталей см. файлы:
- **🔄 CI/CD Pipeline**: [pipeline.md](pipeline.md)
- **🍴 Fork Setup**: [fork-setup.md](../en/fork-setup.md) (English only)
- **🇺🇸 English version**: [../../README.md](../../README.md)

---

## 🏆 Информация о проекте

<div align="center">

> 💡 **Docker реализация**: [@asychin](https://github.com/asychin) | **Оригинальный VPN сервер**: [AmneziaWG Team](https://github.com/amnezia-vpn)

**🌟 Если проект помог вам, поставьте звезду!**

[![GitHub Stars](https://img.shields.io/github/stars/asychin/amnezia-wg-docker?style=for-the-badge&logo=github)](https://github.com/asychin/amnezia-wg-docker/stargazers)

</div>

---

## 📞 Поддержка

<div align="center">

| Платформа | Ссылка |
|-----------|--------|
| 🐛 **Issues** | [GitHub Issues](https://github.com/asychin/amnezia-wg-docker/issues) |
| 💬 **Обсуждения** | [GitHub Discussions](https://github.com/asychin/amnezia-wg-docker/discussions) |
| 📧 **Контакт** | [Email](mailto:asychin@users.noreply.github.com) |

</div>

---

## 📄 Лицензия

<div align="center">

Этот проект распространяется под лицензией **MIT** - смотрите файл [LICENSE](../../LICENSE) для деталей.

**Copyright © 2024 [asychin](https://github.com/asychin)**

</div>
