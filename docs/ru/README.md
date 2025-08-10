# 🔒 AmneziaWG Docker Server - Полное руководство

<div align="center">

**Готовое к продакшену Docker решение для AmneziaWG VPN сервера с поддержкой обхода DPI**

[![GitHub Release](https://img.shields.io/github/v/release/asychin/amneziawg-docker?style=flat-square&logo=github)](https://github.com/asychin/amneziawg-docker/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/asychin/amneziawg-docker?style=flat-square&logo=docker)](https://hub.docker.com/r/asychin/amneziawg-docker)
[![GitHub Stars](https://img.shields.io/github/stars/asychin/amneziawg-docker?style=flat-square&logo=github)](https://github.com/asychin/amneziawg-docker/stargazers)

<details>
  <summary>🌍 Язык: Русский</summary>
  <p>
    <a href="../en/README.md">🇺🇸 English</a> •
    <a href="../ru/README.md">🇷🇺 Русский</a> •
    <a href="../zh/README.md">🇨🇳 中文</a>
  </p>
</details>

</div>

---

## 🌟 Особенности

- ✅ **AmneziaWG userspace** - работает без модулей ядра
- ✅ **Обход DPI** - маскировка VPN трафика под HTTPS
- ✅ **Docker контейнер** - простое развертывание
- ✅ **Автоопределение IP** - умное определение публичного IP через 8 сервисов
- ✅ **Автоматическая настройка** - iptables, маршрутизация, DNS
- ✅ **QR коды** - для быстрого подключения клиентов
- ✅ **Управление клиентами** - добавление/удаление через Makefile
- ✅ **Мониторинг** - логи и статус соединений

---

## 🚀 Быстрый старт

### 1. Клонирование с сабмодулями

```bash
git clone --recursive https://github.com/asychin/amneziawg-docker.git
cd amneziawg-docker

# Если забыли --recursive:
git submodule update --init --recursive
```

### 2. Запуск сервера

```bash
# Сборка и запуск
make build
make up

# Проверка статуса
make status
```

### 3. Получение клиентской конфигурации

```bash
# Показать QR код для первого клиента
make client-qr client1

# Создать нового клиента
make client-add name=myclient ip=10.13.13.10
```

---

## 📋 Требования

- **Docker** >= 20.10
- **Docker Compose** >= 1.29
- **Linux** хост с поддержкой TUN/TAP
- **Привилегированный режим** или доступ к `/dev/net/tun`

### ⚠️ Важно: TUN устройство

AmneziaWG требует доступ к TUN интерфейсу. Убедитесь что:

1. **TUN модуль загружен:**
   ```bash
   # Проверка модуля
   lsmod | grep tun
   
   # Загрузка если нужно
   sudo modprobe tun
   ```

2. **TUN устройство существует:**
   ```bash
   # Проверка устройства
   ls -la /dev/net/tun
   
   # Создание если нужно
   sudo mkdir -p /dev/net
   sudo mknod /dev/net/tun c 10 200
   sudo chmod 666 /dev/net/tun
   ```

3. **Docker запущен с правильными флагами** (см. секцию развертывания)

### Установка Docker (Ubuntu/Debian)

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
sudo apt install -y docker.io docker-compose

# Добавление пользователя в группу docker
sudo usermod -aG docker $USER
newgrp docker

# Проверка установки
docker --version
docker-compose --version
```

---

## ⚙️ Конфигурация

### Переменные окружения (.env)

Создайте файл `.env` или отредактируйте `env.example`:

```bash
# Основные настройки
AWG_INTERFACE=awg0
AWG_PORT=51820
AWG_NET=10.13.13.0/24
AWG_SERVER_IP=10.13.13.1
AWG_DNS=8.8.8.8,8.8.4.4

# Публичный IP (автоопределение если не указан)
# SERVER_PUBLIC_IP=YOUR_SERVER_IP

# Настройки клиентов
CLIENTS_SUBNET=10.13.13.0/24
ALLOWED_IPS=0.0.0.0/0

# Параметры обфускации AmneziaWG для обхода DPI
AWG_JC=7
AWG_JMIN=50
AWG_JMAX=1000
AWG_S1=86
AWG_S2=574
AWG_H1=1
AWG_H2=2
AWG_H3=3
AWG_H4=4

# Дополнительные настройки
# AWG_DISABLE_IPTABLES=true  # Отключить iptables (для CI/CD или ограниченных окружений)
```

### Настройка параметров обфускации

Параметры обфускации маскируют VPN трафик под обычный HTTPS:

- **Jc** (7) - Интенсивность джиттера
- **Jmin/Jmax** (50/1000) - Минимальный/максимальный размер "мусорных" пакетов
- **S1/S2** (86/574) - Размеры заголовков для маскировки
- **H1-H4** (1/2/3/4) - Хеш-функции для обфускации

---

## 🛠️ Управление

### Makefile команды

```bash
# Основные команды
make build          # Сборка контейнера
make up             # Запуск сервера
make down           # Остановка сервера
make restart        # Перезапуск
make logs           # Просмотр логов
make status         # Статус сервера и соединений

# Управление клиентами
make client-add name=client2 ip=10.13.13.3   # Добавить клиента
make client-rm name=client2                   # Удалить клиента
make client-qr name=client1                   # Показать QR код
make client-list                              # Список клиентов

# Отладка
make shell          # Войти в контейнер
make clean          # Очистка (остановка + удаление данных)
```

### Ручное управление клиентами

```bash
# Войти в контейнер
docker-compose exec amneziawg-server bash

# Добавить клиента
/app/scripts/manage-clients.sh add myclient 10.13.13.5

# Удалить клиента
/app/scripts/manage-clients.sh remove myclient

# Показать статус
awg show awg0
```

### 🚀 Bash Autocomplete

Для удобства работы включен автокомплит make команд:

```bash
# Загрузить в текущей сессии
source amneziawg-autocomplete.bash

# Установить постоянно
echo "source $(pwd)/amneziawg-autocomplete.bash" >> ~/.bashrc
```

**Возможности:**
- 🎯 Автокомплит всех команд `make`
- 👥 Имена клиентов и IP адреса
- 🚀 Быстрые функции: `awg_add_client`, `awg_qr`, `awg_status`

```bash
# Примеры (нажимайте TAB)
make client-add name=<TAB>     # Имена клиентов
make client-qr name=<TAB>      # Существующие клиенты
awg_add_client mobile          # Быстрое добавление
awg_help                       # Справка по автокомплиту
```

---

## 🚀 Развертывание

### Способ 1: Docker Compose (рекомендуется)

```bash
# Быстрый запуск с docker-compose
make build && make up

# Проверка статуса
make status
```

Docker Compose уже настроен с правильными параметрами в `docker-compose.yml`:
- `privileged: true` - полные права контейнера
- `devices: - /dev/net/tun` - доступ к TUN устройству
- `cap_add: [NET_ADMIN, SYS_MODULE]` - сетевые возможности

### Способ 2: Docker run (ручной запуск)

```bash
# Сборка образа
docker build -t amneziawg-server .

# Запуск с необходимыми правами
docker run -d \
  --name amneziawg-server \
  --privileged \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --device=/dev/net/tun \
  --sysctl net.ipv4.ip_forward=1 \
  -p 51820:51820/udp \
  -v $(pwd)/config:/app/config \
  -v $(pwd)/clients:/app/clients \
  -e SERVER_PUBLIC_IP=YOUR_SERVER_IP \
  amneziawg-server
```

### Способ 3: Облачные провайдеры

Для **VPS/VDS** серверов (DigitalOcean, Vultr, Hetzner и др.):

```bash
# Убедитесь что TUN модуль доступен
lsmod | grep tun || sudo modprobe tun

# Создайте TUN устройство если нужно
sudo mkdir -p /dev/net
sudo mknod /dev/net/tun c 10 200
sudo chmod 666 /dev/net/tun

# Запускайте как обычно
make build && make up
```

### ⚠️ Устранение проблем с TUN

Если получаете ошибку `CreateTUN("awg0") failed; /dev/net/tun does not exist`:

1. **Проверьте доступность TUN на хосте:**
   ```bash
   ls -la /dev/net/tun
   cat /dev/net/tun  # должно вернуть "cat: /dev/net/tun: File descriptor in bad state"
   ```

2. **Для Docker без привилегий (не рекомендуется):**
   ```bash
   # Добавьте в docker-compose.yml или docker run:
   --cap-add=NET_ADMIN --device=/dev/net/tun
   ```

3. **Для Podman или других runtime:**
   ```bash
   # Используйте аналогичные флаги с вашим runtime
   podman run --privileged --device=/dev/net/tun ...
   ```

---

## 📱 Подключение клиентов

### Android/iOS (AmneziaVPN)

1. Установите [AmneziaVPN](https://amnezia.org/)
2. Получите QR код: `make client-qr name=client1`
3. Отсканируйте QR код в приложении
4. Подключайтесь!

### Desktop (AmneziaWG клиент)

1. Скачайте конфигурацию:
   ```bash
   docker-compose exec amneziawg-server cat /app/clients/client1.conf > client1.conf
   ```
2. Используйте с совместимым клиентом

### Пример клиентской конфигурации

```ini
[Interface]
PrivateKey = <приватный_ключ_клиента>
Address = 10.13.13.2/32
DNS = 8.8.8.8

[Peer]
PublicKey = <публичный_ключ_сервера>
Endpoint = 203.0.113.123:51820        # Автоматически определенный IP
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25

# Параметры обфускации AmneziaWG
Jc = 7
Jmin = 50
Jmax = 1000
S1 = 86
S2 = 574
H1 = 1
H2 = 2
H3 = 3
H4 = 4
```

---

## 🔧 Архитектура

### Компоненты

```
┌─────────────────────────────────────────┐
│             Docker Container            │
│  ┌─────────────────────────────────────┐ │
│  │         amneziawg-go               │ │  ← Userspace VPN
│  │         (PID процесса)              │ │
│  └─────────────────────────────────────┘ │
│  ┌─────────────────────────────────────┐ │
│  │         amneziawg-tools            │ │  ← Утилиты управления
│  │         (awg, awg-quick)           │ │
│  └─────────────────────────────────────┘ │
│  ┌─────────────────────────────────────┐ │
│  │         iptables rules             │ │  ← NAT и фаервол
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
              │
              │ 51820/UDP
              ▼
        [ Интернет ]
              │
              ▼
     [ VPN клиенты ]
```

### Сетевая схема

```
Клиент (10.13.13.2) ──┐
                       │
Клиент (10.13.13.3) ──┤
                       │    VPN туннель     ┌─ Интернет
                       ├─────────────────────┤
Клиент (10.13.13.4) ──┤                     └─ Сайты/сервисы
                       │
Клиент (10.13.13.5) ──┘
                 
        Сеть VPN: 10.13.13.0/24
        Сервер: 10.13.13.1
        Порт: 51820/UDP
```

---

## 🌐 Автоопределение публичного IP

### Умное определение внешнего IP адреса

Система автоматически определяет публичный IP адрес сервера для создания правильных клиентских конфигураций. Это решает проблему неработающего VPN при развертывании в облаке или за NAT.

### Поддерживаемые сервисы

Автоопределение использует надежные внешние сервисы в порядке приоритета:

1. **https://eth0.me** - быстрый и надежный сервис
2. **https://ipv4.icanhazip.com** - популярный резервный сервис  
3. **https://api.ipify.org** - JSON API для определения IP
4. **https://checkip.amazonaws.com** - официальный сервис AWS
5. **https://ipinfo.io/ip** - детальная геоинформация
6. **https://ifconfig.me/ip** - классический сервис Unix
7. **http://whatismyip.akamai.com** - от CDN провайдера Akamai
8. **http://i.pn** - минималистичный и быстрый

### Настройка

```bash
# В файле .env установите одно из значений:

# 1. Автоопределение (рекомендуется)
SERVER_PUBLIC_IP=auto

# 2. Конкретный IP адрес
SERVER_PUBLIC_IP=203.0.113.123

# 3. Пустое значение = автоопределение
SERVER_PUBLIC_IP=
```

### Процесс определения IP

```bash
# При создании клиента вы увидите в логах:
[INFO] Определяем публичный IP автоматически...
[INFO] Пробуем сервис: https://eth0.me
[INFO] ✅ Публичный IP определён: 203.0.113.123 (через https://eth0.me)
```

### Обработка ошибок

При недоступности всех сервисов система:
- ⚠️ Выводит предупреждение
- 📝 Показывает инструкции по ручной настройке
- 🔧 Устанавливает специальный endpoint для идентификации проблемы

```bash
# В случае сбоя всех сервисов:
[WARN] ⚠️ Не удалось определить публичный IP автоматически!
[WARN] Используем fallback IP. ОБЯЗАТЕЛЬНО укажите правильный IP в .env файле:
[WARN] echo 'SERVER_PUBLIC_IP=ВАШ_ПУБЛИЧНЫЙ_IP' > .env
```

### Валидация IP адресов

Система проверяет полученные IP адреса:
- ✅ Корректность формата IPv4
- ✅ Валидность диапазонов (1-255.0-255.0-255.0-255)
- ✅ Исключение недопустимых адресов

### Производительность

- ⚡ **Таймауты**: 10-15 секунд на сервис
- 🔄 **Попытки**: До 8 различных сервисов
- 💾 **Кеширование**: IP используется для всех клиентов в сессии

---

## 🛡️ Безопасность

### Брандмауэр

Убедитесь, что открыт только нужный порт:

```bash
# UFW (Ubuntu)
sudo ufw allow 51820/udp
sudo ufw enable

# iptables
sudo iptables -A INPUT -p udp --dport 51820 -j ACCEPT
```

### SSL/TLS

AmneziaWG использует надежное шифрование:
- **ChaCha20Poly1305** - симметричное шифрование
- **Curve25519** - обмен ключами
- **BLAKE2s** - хеширование

### Ключи

- Автоматическая генерация криптографически стойких ключей
- Приватные ключи хранятся с правами 600
- Регулярная ротация ключей (рекомендуется)

---

## 🔍 Мониторинг и диагностика

### Просмотр статуса

```bash
# Общий статус
make status

# Детальная информация
docker-compose exec amneziawg-server awg show awg0

# Активные соединения
docker-compose exec amneziawg-server awg show awg0 latest-handshakes
```

### Логи

```bash
# Реальное время
make logs

# Последние 100 строк
docker-compose logs --tail=100 amneziawg-server

# Логи с временными метками
docker-compose logs -t amneziawg-server
```

### Диагностика проблем

```bash
# Проверка процесса
docker-compose exec amneziawg-server ps aux | grep amneziawg

# Проверка интерфейса
docker-compose exec amneziawg-server ip addr show awg0

# Проверка маршрутов
docker-compose exec amneziawg-server ip route

# Проверка iptables
docker-compose exec amneziawg-server iptables -L -n
```

---

## 🚨 Решение проблем

### Контейнер не запускается

```bash
# Проверка образа
docker images | grep amneziawg

# Пересборка
make clean
make build
```

### Клиенты не подключаются

1. **Проверьте брандмауэр:**
   ```bash
   sudo ufw status
   sudo iptables -L INPUT | grep 51820
   ```

2. **Проверьте публичный IP:**
   ```bash
   curl ifconfig.me
   ```

3. **Проверьте порт:**
   ```bash
   sudo netstat -ulnp | grep 51820
   ```

### Нет интернета через VPN

1. **Проверьте IP forwarding:**
   ```bash
   cat /proc/sys/net/ipv4/ip_forward  # должно быть 1
   ```

2. **Проверьте NAT правила:**
   ```bash
   docker-compose exec amneziawg-server iptables -t nat -L
   ```

### DPI блокирует соединение

1. **Измените параметры обфускации:**
   ```bash
   # В .env файле измените:
   AWG_JC=9
   AWG_JMIN=75
   AWG_JMAX=1200
   AWG_S1=96
   AWG_S2=684
   ```

2. **Смените порт:**
   ```bash
   AWG_PORT=443  # HTTPS порт
   # или
   AWG_PORT=53   # DNS порт
   ```

---

## 📚 Дополнительные ресурсы

### Официальная документация

- [AmneziaVPN](https://docs.amnezia.org/)
- [AmneziaWG](https://docs.amnezia.org/ru/documentation/amnezia-wg/)
- [WireGuard](https://www.wireguard.com/)

### Репозитории

- [amneziawg-go](https://github.com/amnezia-vpn/amneziawg-go) - Userspace реализация
- [amneziawg-tools](https://github.com/amnezia-vpn/amneziawg-tools) - Утилиты управления
- [amneziawg-linux-kernel-module](https://github.com/amnezia-vpn/amneziawg-linux-kernel-module) - Модуль ядра

### Сообщество

- [Telegram канал](https://t.me/amnezia_vpn)
- [GitHub Issues](https://github.com/amnezia-vpn/amnezia-client/issues)

---

## 👨‍💻 Автор Docker-реализации

Эта Docker-реализация AmneziaWG создана [@asychin](https://github.com/asychin).

**🔗 Связаться с автором:**
- **GitHub:** [@asychin](https://github.com/asychin)  
- **Telegram:** [@BlackSazha](https://t.me/BlackSazha)
- **Email:** moloko@skofey.com
- **Website:** [cheza.dev](https://cheza.dev)

**⚠️ Важно:**
- Основной VPN сервер AmneziaWG разработан командой [Amnezia VPN](https://github.com/amnezia-vpn)
- Данная реализация содержит только Docker-контейнеризацию и управляющие скрипты
- За вопросами по самому VPN серверу обращайтесь к [оригинальным разработчикам](https://github.com/amnezia-vpn/amneziawg-go)

---

## 🤝 Участие в разработке

### Структура проекта

```
amneziawg-docker/
├── .gitmodules              # Git сабмодули
├── amneziawg-go/           # Сабмодуль: userspace реализация
├── amneziawg-tools/        # Сабмодуль: утилиты управления
├── scripts/                # Скрипты контейнера
│   ├── entrypoint.sh       # Основной скрипт запуска
│   ├── manage-clients.sh   # Управление клиентами
│   ├── post-up.sh         # Скрипт после поднятия интерфейса
│   └── post-down.sh       # Скрипт после опускания интерфейса
├── Dockerfile              # Образ контейнера
├── docker-compose.yml      # Конфигурация сервисов
├── Makefile               # Утилиты управления
├── env.example            # Пример переменных окружения
└── README.md              # Эта документация
```

### Обновление сабмодулей

```bash
# Обновить все сабмодули
git submodule update --remote

# Обновить конкретный сабмодуль
git submodule update --remote amneziawg-go
```

---

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. Смотрите файл LICENSE для деталей.

**Внимание:** Компоненты AmneziaWG могут иметь собственные лицензии:
- amneziawg-go: MIT License
- amneziawg-tools: GPL-2.0 License

---

## ⚠️ Отказ от ответственности

Данное программное обеспечение предоставляется "как есть". Авторы не несут ответственности за любые последствия использования. Пользователи обязаны соблюдать законы своей юрисдикции.

**Помните:** VPN не гарантирует 100% анонимность. Используйте дополнительные меры безопасности.
