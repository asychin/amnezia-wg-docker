# AmneziaWG Docker Server
# Docker-реализация от asychin (https://github.com/asychin)
# Основной VPN сервер: AmneziaWG Team (https://github.com/amnezia-vpn)
# Multi-stage сборка для оптимизации размера образа

# ============================================================================
# ЭТАП 1: Сборка amneziawg-go (userspace реализация)
# ============================================================================
FROM golang:1.24-alpine AS awg-builder

# Метаданные образа
LABEL stage="builder"
LABEL description="Building AmneziaWG Go userspace implementation"

# Установка зависимостей для сборки
RUN apk add --no-cache git build-base linux-headers

# Рабочая директория
WORKDIR /build

# Копируем исходники amneziawg-go (сабмодуль)
COPY amneziawg-go/ ./

# Сборка статического бинаря
RUN set -ex && \
    go mod download && \
    go mod verify && \
    CGO_ENABLED=1 GOOS=linux go build \
        -ldflags '-linkmode external -extldflags "-static"' \
        -trimpath \
        -o /usr/local/bin/amneziawg-go \
        .

# Проверка собранного бинаря
RUN /usr/local/bin/amneziawg-go --version

# ============================================================================
# ЭТАП 2: Основной образ на базе Ubuntu
# ============================================================================
FROM ubuntu:22.04

# Метаданные образа
LABEL maintainer="asychin <moloko@skofey.com>"
LABEL description="AmneziaWG VPN Server with DPI bypass capabilities (Docker implementation by asychin)"
LABEL version="1.0.0"
LABEL org.label-schema.name="AmneziaWG Docker Server"
LABEL org.label-schema.description="Ready-to-use AmneziaWG VPN server in Docker with userspace implementation"
LABEL org.label-schema.url="https://github.com/asychin/amnezia-wg-docker"
LABEL org.label-schema.vcs-url="https://github.com/asychin/amnezia-wg-docker"
LABEL org.label-schema.schema-version="1.0"
LABEL docker.author="asychin"
LABEL docker.author.github="https://github.com/asychin"
LABEL docker.author.telegram="https://t.me/BlackSazha"
LABEL amneziawg.original.url="https://github.com/amnezia-vpn"
LABEL amneziawg.original.go="https://github.com/amnezia-vpn/amneziawg-go"
LABEL amneziawg.original.tools="https://github.com/amnezia-vpn/amneziawg-tools"

# Переменные окружения
ENV DEBIAN_FRONTEND=noninteractive \
    AWG_INTERFACE=awg0 \
    AWG_PORT=51820 \
    AWG_NET=10.13.13.0/24 \
    AWG_SERVER_IP=10.13.13.1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    UMASK=077

# Установка системных зависимостей
RUN set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        # Сетевые утилиты
        curl \
        wget \
        iptables \
        iproute2 \
        iputils-ping \
        netcat \
        dnsutils \
        net-tools \
        procps \
        # Система и безопасность
        ca-certificates \
        openresolv \
        # Генерация QR кодов
        qrencode \
        # Утилиты
        nano \
        less \
        # Инструменты сборки (временно для amneziawg-tools)
        build-essential && \
    # Очистка кеша apt
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Копирование и сборка amneziawg-tools из сабмодуля
COPY amneziawg-tools/ /tmp/amneziawg-tools/
RUN set -ex && \
    cd /tmp/amneziawg-tools/src && \
    make && \
    make install PREFIX=/usr && \
    # Проверка установки
    awg --version && \
    # Очистка временных файлов
    cd / && \
    rm -rf /tmp/amneziawg-tools && \
    # Удаление инструментов сборки для уменьшения размера
    apt-get remove -y build-essential && \
    apt-get autoremove -y && \
    apt-get clean

# Копирование собранного amneziawg-go из первого этапа
COPY --from=awg-builder /usr/local/bin/amneziawg-go /usr/local/bin/amneziawg-go

# Создание структуры директорий
RUN set -ex && \
    # Директории для конфигураций
    mkdir -p /etc/amneziawg && \
    mkdir -p /app/config && \
    mkdir -p /app/clients && \
    # Директории для сокетов и PID файлов
    mkdir -p /var/run/amneziawg && \
    mkdir -p /var/log/amneziawg && \
    # Директории для скриптов
    mkdir -p /app/scripts

# Копирование скриптов
COPY scripts/ /app/scripts/

# Установка прав доступа
RUN set -ex && \
    # Исполняемые права для скриптов
    chmod +x /app/scripts/*.sh && \
    # Безопасные права для директорий конфигурации
    chmod 750 /app/config && \
    # БЕЗОПАСНОСТЬ: Строгие права для директории клиентов (приватные ключи)
    chmod 700 /app/clients && \
    chmod 755 /var/run/amneziawg && \
    # Создание символических ссылок для удобства
    ln -sf /app/scripts/healthcheck.sh /usr/local/bin/healthcheck && \
    ln -sf /app/scripts/diagnose.sh /usr/local/bin/diagnose

# Проверка установленных компонентов
RUN set -ex && \
    echo "=== Проверка установленных компонентов ===" && \
    amneziawg-go --version && \
    awg --version && \
    echo "=== Проверка сетевых утилит ===" && \
    which iptables && \
    which ip && \
    which qrencode && \
    echo "=== Все компоненты установлены успешно ==="

# Открытие портов
# 51820/udp - основной порт AmneziaWG
EXPOSE 51820/udp

# Тома для персистентного хранения
VOLUME ["/app/config", "/app/clients"]

# Рабочая директория
WORKDIR /app

# Проверка здоровья контейнера
# Увеличен start-period для корректной инициализации AmneziaWG
# Увеличен timeout для выполнения всех проверок
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=5 \
    CMD /app/scripts/healthcheck.sh || exit 1

# Пользователь (безопасность)
# Пока запускаем от root для работы с iptables и сетевыми интерфейсами
USER root

# Точка входа
ENTRYPOINT ["/app/scripts/entrypoint.sh"]

# Команда по умолчанию (без аргументов - запускаем main() в entrypoint.sh)
CMD []

# ============================================================================
# МЕТАДАННЫЕ ДЛЯ СБОРКИ
# ============================================================================

# Переменные сборки
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

# Метки с информацией о сборке
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.version=$VERSION