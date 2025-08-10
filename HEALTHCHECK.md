# Мониторинг и диагностика AmneziaWG

## Обзор

Система мониторинга AmneziaWG Docker Server включает расширенные хелсчеки и инструменты диагностики для обеспечения стабильной работы VPN сервера.

## Возможности хелсчека

### Проверки
- ✅ **Процесс amneziawg-go** - проверка работоспособности основного процесса
- ✅ **Сетевой интерфейс** - существование и активность интерфейса
- ✅ **Порт прослушивания** - проверка через netstat, ss и lsof
- ✅ **Конфигурация AmneziaWG** - доступность через awg команды
- ⚠️ **DNS** - проверка связности (не критическая)
- ✅ **Файловая система** - доступность директорий конфигурации
- ⚠️ **IP адрес** - назначение IP на интерфейсе (не критическая)
- ⚠️ **iptables** - наличие NAT правил (не критическая)

### Настройки таймингов

**Dockerfile (по умолчанию):**
- Интервал: 30 секунд
- Таймаут: 15 секунд
- Период запуска: 60 секунд (время на инициализацию)
- Попытки: 5

**docker-compose.yml (переопределяет Dockerfile):**
- Можно настроить через переменные окружения
- Более гибкие настройки для разных сред

## Использование

### Ручная проверка хелсчека
```bash
# Внутри контейнера
/app/scripts/healthcheck.sh

# Или через символическую ссылку
healthcheck

# С подробным выводом
HEALTHCHECK_VERBOSE=true /app/scripts/healthcheck.sh
```

### Из хоста Docker
```bash
# Выполнить хелсчек
docker exec amneziawg-server /app/scripts/healthcheck.sh

# Посмотреть статус хелсчека
docker ps

# Посмотреть подробную информацию о хелсчеке
docker inspect amneziawg-server | grep -A 10 Health
```

### Диагностика проблем
```bash
# Полная диагностика системы
docker exec amneziawg-server /app/scripts/diagnose.sh

# Или через символическую ссылку
docker exec amneziawg-server diagnose

# Сохранить диагностику в файл
docker exec amneziawg-server diagnose > amneziawg-diagnostic.log
```

## Настройка переменных окружения

### В .env файле
```bash
# Таймаут для проверок (секунды)
HEALTHCHECK_TIMEOUT=5

# Подробное логирование
HEALTHCHECK_VERBOSE=false
```

### В docker-compose.yml
```yaml
environment:
  - HEALTHCHECK_TIMEOUT=10
  - HEALTHCHECK_VERBOSE=true
```

## Интерпретация результатов

### Успешный хелсчек
```
[HEALTHCHECK] 14:23:15 ✅ Процесс amneziawg-go работает (PID: 1234)
[HEALTHCHECK] 14:23:15 ✅ Интерфейс awg0 существует
[HEALTHCHECK] 14:23:15 ✅ Интерфейс awg0 активен
[HEALTHCHECK] 14:23:15 ✅ Порт 51820 прослушивается (netstat)
[HEALTHCHECK] 14:23:15 ✅ AmneziaWG конфигурация доступна
[HEALTHCHECK] 14:23:15 ⚠️  DNS работает (google.com) (предупреждение)
[HEALTHCHECK] 14:23:15 ✅ Директории конфигурации доступны
[HEALTHCHECK] 14:23:15 ✅ IP адрес назначен на awg0
[HEALTHCHECK] 14:23:15 ✅ iptables правила существуют
[HEALTHCHECK] 14:23:15 Проверок выполнено: 9/9
[HEALTHCHECK] 14:23:15 ✅ Все критические проверки пройдены успешно
```

### Проблемы с хелсчеком
```
[HEALTHCHECK ERROR] 14:23:15 ❌ Процесс amneziawg-go не отвечает (PID: 1234)
[HEALTHCHECK ERROR] 14:23:15 ❌ Интерфейс awg0 не найден
[HEALTHCHECK ERROR] 14:23:15 ❌ Обнаружены критические проблемы в работе сервера
```

## Типичные проблемы и решения

### 1. Процесс amneziawg-go не работает
```bash
# Перезапуск контейнера
docker restart amneziawg-server

# Проверка логов
docker logs amneziawg-server
```

### 2. Интерфейс не создается
- Проверьте права контейнера (privileged: true, NET_ADMIN)
- Убедитесь что `/dev/net/tun` доступен
- Проверьте конфигурационный файл

### 3. Порт не прослушивается
- Проверьте переменную `AWG_PORT`
- Убедитесь что порт не занят другим процессом
- Проверьте файрволл хоста

### 4. DNS проблемы (не критично)
- Проверьте `/etc/resolv.conf` в контейнере
- Убедитесь в доступности внешней сети

## Мониторинг в production

### Интеграция с Docker Swarm
```yaml
deploy:
  restart_policy:
    condition: on-failure
    delay: 5s
    max_attempts: 3
```

### Интеграция с внешними системами мониторинга
```bash
# Prometheus/Grafana
curl -f http://localhost/health || exit 1

# Zabbix
docker exec amneziawg-server healthcheck > /dev/null
echo $?
```

### Алерты
Настройте алерты на:
- Статус хелсчека контейнера
- Логи с ошибками healthcheck
- Метрики ресурсов контейнера

## Отладка

### Включение подробного логирования
```bash
export HEALTHCHECK_VERBOSE=true
```

### Пошаговая диагностика
1. Запустите полную диагностику: `diagnose`
2. Проверьте логи контейнера: `docker logs amneziawg-server`
3. Проверьте логи хоста: `journalctl -u docker`
4. Проверьте сетевые интерфейсы: `ip link show`
5. Проверьте процессы: `ps aux | grep amnezia`

### Временное отключение хелсчека
```yaml
# В docker-compose.yml
healthcheck:
  disable: true
```
