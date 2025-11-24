# PostgreSQL в Docker для AmneziaWG v2.0.0

## 🐳 Автоматический запуск PostgreSQL в Docker

PostgreSQL **автоматически запускается** при старте проекта через `docker-compose up -d`. Все настройки подтягиваются из файла `.env`.

---

## 📦 Что настроено автоматически

### 1. **Docker контейнер**
```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: amneziawg-db
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-amneziawg}
      POSTGRES_USER: ${POSTGRES_USER:-amneziawg}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-change_this_password_to_secure_one}
    volumes:
      - postgres-data:/var/lib/postgresql/data
```

### 2. **Подключение из .env файла**
Все креды и настройки читаются из `.env`:
```bash
# Основные настройки
POSTGRES_DB=amneziawg
POSTGRES_USER=amneziawg
POSTGRES_PASSWORD=your_secure_password_here

# Производительность (опционально)
PG_SHARED_BUFFERS=256MB
PG_MAX_CONNECTIONS=100
PG_WORK_MEM=4MB
```

### 3. **Docker Volume для данных**
Все данные PostgreSQL хранятся в Docker volume `postgres-data`:
- ✅ Данные сохраняются при перезапуске контейнера
- ✅ Данные сохраняются при обновлении версии
- ✅ Бэкап делается через `docker run --rm -v postgres-data:/data alpine tar czf /backup.tar.gz /data`

---

## 🚀 Быстрый старт

### 1. Настройка кредов
Скопируйте `env.example` в `.env` и измените пароль:
```bash
cp env.example .env
nano .env  # Измените POSTGRES_PASSWORD!
```

### 2. Запуск PostgreSQL
```bash
# Запустить все сервисы (включая PostgreSQL)
docker-compose up -d

# Проверить статус
docker-compose ps

# Посмотреть логи PostgreSQL
docker-compose logs postgres
```

### 3. Проверка подключения
```bash
# Проверить что PostgreSQL работает
docker-compose exec postgres pg_isready -U amneziawg

# Подключиться к базе данных
docker-compose exec postgres psql -U amneziawg -d amneziawg
```

---

## ⚙️ Переменные окружения в .env

### Основные (обязательные)

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `POSTGRES_DB` | Имя базы данных | `amneziawg` |
| `POSTGRES_USER` | Пользователь БД | `amneziawg` |
| `POSTGRES_PASSWORD` | **Пароль БД (ИЗМЕНИТЬ!)** | `change_this_password_to_secure_one` |

### Производительность (опциональные)

| Переменная | Описание | По умолчанию | Рекомендации |
|------------|----------|--------------|--------------|
| `PG_SHARED_BUFFERS` | Память для кэша | `128MB` | 25% RAM (1GB→256MB) |
| `PG_MAX_CONNECTIONS` | Макс. подключений | `100` | Зависит от нагрузки |
| `PG_WORK_MEM` | Память на операцию | `4MB` | Для сортировки/хеша |
| `PG_EFFECTIVE_CACHE_SIZE` | Оценка кэша ОС | `512MB` | 50-75% RAM |
| `PG_RANDOM_PAGE_COST` | Стоимость чтения | `1.1` | SSD: 1.1, HDD: 4.0 |
| `PG_EFFECTIVE_IO_CONCURRENCY` | Параллельный I/O | `200` | SSD: 200, HDD: 2 |
| `PG_MAX_WAL_SIZE` | Макс. размер WAL | `4GB` | Для больших операций |
| `PG_SHM_SIZE` | Shared memory | `128MB` | Должен быть ≥ shared_buffers |

---

## 📊 Оптимизация под разные сервера

### Для малого VPS (1GB RAM)
```bash
PG_SHARED_BUFFERS=256MB
PG_EFFECTIVE_CACHE_SIZE=512MB
PG_MAX_CONNECTIONS=50
PG_WORK_MEM=2MB
PG_SHM_SIZE=256MB
```

### Для среднего VPS (2GB RAM)
```bash
PG_SHARED_BUFFERS=512MB
PG_EFFECTIVE_CACHE_SIZE=1GB
PG_MAX_CONNECTIONS=100
PG_WORK_MEM=4MB
PG_SHM_SIZE=512MB
```

### Для мощного VPS (4GB+ RAM)
```bash
PG_SHARED_BUFFERS=1GB
PG_EFFECTIVE_CACHE_SIZE=3GB
PG_MAX_CONNECTIONS=200
PG_WORK_MEM=8MB
PG_MAX_WAL_SIZE=8GB
PG_SHM_SIZE=1GB
```

---

## 🔧 Управление базой данных

### Подключение к PostgreSQL
```bash
# Через Docker контейнер
docker-compose exec postgres psql -U amneziawg -d amneziawg

# Через локальный psql (если установлен)
psql -h localhost -p 5432 -U amneziawg -d amneziawg
```

### Просмотр таблиц
```sql
-- Список всех таблиц
\dt

-- Описание таблицы vpn_clients
\d vpn_clients

-- Посмотреть всех клиентов
SELECT * FROM vpn_clients;

-- Подсчет клиентов
SELECT COUNT(*) FROM vpn_clients;
```

### Бэкап и восстановление

#### Бэкап базы данных
```bash
# Создать SQL дамп
docker-compose exec postgres pg_dump -U amneziawg amneziawg > backup.sql

# Создать бэкап Docker volume
docker run --rm \
  -v amneziawg_postgres-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-backup-$(date +%Y%m%d).tar.gz /data
```

#### Восстановление из бэкапа
```bash
# Восстановить из SQL дампа
cat backup.sql | docker-compose exec -T postgres psql -U amneziawg amneziawg

# Восстановить Docker volume
docker run --rm \
  -v amneziawg_postgres-data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/postgres-backup-20241124.tar.gz -C /
```

---

## 🔍 Мониторинг и диагностика

### Проверка статуса
```bash
# Healthcheck
docker-compose exec postgres pg_isready -U amneziawg

# Проверка подключений
docker-compose exec postgres psql -U amneziawg -d amneziawg -c \
  "SELECT count(*) FROM pg_stat_activity;"

# Размер базы данных
docker-compose exec postgres psql -U amneziawg -d amneziawg -c \
  "SELECT pg_size_pretty(pg_database_size('amneziawg'));"
```

### Просмотр логов
```bash
# Логи PostgreSQL
docker-compose logs -f postgres

# Последние 100 строк
docker-compose logs --tail 100 postgres
```

### Производительность
```sql
-- Медленные запросы
SELECT pid, now() - pg_stat_activity.query_start AS duration, query 
FROM pg_stat_activity 
WHERE state = 'active' 
ORDER BY duration DESC;

-- Статистика таблиц
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Индексы
SELECT schemaname, tablename, indexname, 
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_indexes 
WHERE schemaname = 'public';
```

---

## 🛠️ Миграции схемы базы данных

Проект использует **Drizzle ORM** для работы с базой данных.

### Применить изменения схемы
```bash
# Push schema changes (автоматически создаст таблицы)
npm run db:push

# Принудительный push (если есть конфликты)
npm run db:push -- --force
```

### Файлы схемы
```
shared/schema.ts     - Описание схемы Drizzle ORM
server/storage.ts    - Операции с базой данных
```

---

## 🔐 Безопасность

### 1. Изменить пароль по умолчанию
```bash
# В .env файле
POSTGRES_PASSWORD=$(openssl rand -base64 32)
```

### 2. Ограничить доступ к порту
PostgreSQL не должен быть доступен извне! В `docker-compose.yml` НЕТ маппинга порта 5432 на хост.

Если нужен внешний доступ (не рекомендуется):
```yaml
ports:
  - "127.0.0.1:5432:5432"  # Только локально!
```

### 3. Использовать scram-sha-256
```bash
# В .env
POSTGRES_HOST_AUTH_METHOD=scram-sha-256
```

---

## 🆘 Решение проблем

### PostgreSQL не запускается
```bash
# Проверить логи
docker-compose logs postgres

# Проверить что порт не занят
sudo lsof -i :5432

# Пересоздать контейнер
docker-compose down
docker-compose up -d postgres
```

### Ошибка подключения к БД
```bash
# Проверить что контейнер работает
docker-compose ps

# Проверить healthcheck
docker inspect amneziawg-db | grep Health

# Проверить креды в .env
cat .env | grep POSTGRES
```

### Очистить все данные
```bash
# ⚠️ УДАЛИТ ВСЕ ДАННЫЕ!
docker-compose down -v
docker volume rm amneziawg_postgres-data
docker-compose up -d
```

---

## 📚 Полезные команды

```bash
# Перезапустить только PostgreSQL
docker-compose restart postgres

# Остановить PostgreSQL
docker-compose stop postgres

# Запустить PostgreSQL
docker-compose start postgres

# Посмотреть статус
docker-compose ps postgres

# Зайти в контейнер
docker-compose exec postgres sh

# Посмотреть конфигурацию PostgreSQL
docker-compose exec postgres cat /var/lib/postgresql/data/postgresql.conf
```

---

## 🎯 Итоги

✅ **PostgreSQL запускается автоматически** через `docker-compose up -d`  
✅ **Все креды подтягиваются из .env** файла  
✅ **Данные сохраняются** в Docker volume `postgres-data`  
✅ **Настройки производительности** легко меняются через .env  
✅ **Healthcheck и мониторинг** встроены в docker-compose  
✅ **Миграции** управляются через Drizzle ORM  

Никакой ручной настройки не требуется! 🚀
