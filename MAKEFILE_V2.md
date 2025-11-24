# Makefile - Новые команды для v2.0.0

## 📌 Статус

Основной `Makefile` работает и содержит все команды для управления VPN сервером (v1.x).

Для **v2.0.0** (Веб-интерфейс + PostgreSQL) можно добавить дополнительные команды.

---

## 🎯 Рекомендованные команды для веб-интерфейса и PostgreSQL

### Быстрые команды (без Makefile)

Вместо редактирования Makefile, вы можете использовать прямые Docker команды:

#### **Веб-интерфейс:**
```bash
# Логи веб-интерфейса
docker logs -f amneziawg-web

# Войти в контейнер
docker exec -it amneziawg-web /bin/sh

# Перезапустить
docker compose restart web

# Статус
docker compose ps web

# URL веб-интерфейса
WEB_PORT=$(grep "^WEB_PORT=" .env | cut -d= -f2)
SERVER_IP=$(curl -s https://eth0.me)
echo "http://$SERVER_IP:$WEB_PORT"
```

#### **PostgreSQL:**
```bash
# Логи PostgreSQL
docker logs -f amneziawg-db

# Подключиться к PostgreSQL
PGUSER=$(grep "^POSTGRES_USER=" .env | cut -d= -f2)
PGDB=$(grep "^POSTGRES_DB=" .env | cut -d= -f2)
docker exec -it amneziawg-db psql -U $PGUSER -d $PGDB

# Бэкап PostgreSQL
PGUSER=$(grep "^POSTGRES_USER=" .env | cut -d= -f2)
PGDB=$(grep "^POSTGRES_DB=" .env | cut -d= -f2)
docker exec amneziawg-db pg_dump -U $PGUSER $PGDB > postgres-backup-$(date +%Y%m%d).sql

# Восстановить из бэкапа
cat postgres-backup-20241124.sql | docker exec -i amneziawg-db psql -U $PGUSER -d $PGDB

# Статус
docker compose ps db
docker exec amneziawg-db pg_isready -U $PGUSER
```

#### **Весь стек:**
```bash
# Статус всех сервисов
docker compose ps

# Логи всех сервисов
docker compose logs -f

# Перезапустить весь стек
docker compose down && sleep 2 && docker compose up -d
```

---

## 📝 Bash алиасы (рекомендуется)

Добавьте в `~/.bashrc` для быстрого доступа:

```bash
# AmneziaWG v2.0.0 - Веб-интерфейс и PostgreSQL
alias awg-web-logs='docker logs -f amneziawg-web'
alias awg-web-shell='docker exec -it amneziawg-web /bin/sh'
alias awg-web-restart='docker compose restart web'
alias awg-web-url='WEB_PORT=$(grep "^WEB_PORT=" .env | cut -d= -f2); SERVER_IP=$(curl -s https://eth0.me); echo "http://$SERVER_IP:$WEB_PORT"'

alias awg-db-logs='docker logs -f amneziawg-db'
alias awg-db-shell='docker exec -it amneziawg-db /bin/sh'
alias awg-db-psql='PGUSER=$(grep "^POSTGRES_USER=" .env | cut -d= -f2); PGDB=$(grep "^POSTGRES_DB=" .env | cut -d= -f2); docker exec -it amneziawg-db psql -U $PGUSER -d $PGDB'
alias awg-db-backup='PGUSER=$(grep "^POSTGRES_USER=" .env | cut -d= -f2); PGDB=$(grep "^POSTGRES_DB=" .env | cut -d= -f2); docker exec amneziawg-db pg_dump -U $PGUSER $PGDB > postgres-backup-$(date +%Y%m%d-%H%M%S).sql'

alias awg-stack-status='docker compose ps'
alias awg-stack-logs='docker compose logs -f'
alias awg-stack-restart='docker compose down && sleep 2 && docker compose up -d'
```

После добавления выполните:
```bash
source ~/.bashrc
```

Теперь можно использовать:
```bash
awg-web-url              # Показать URL веб-интерфейса
awg-stack-status         # Статус всех сервисов
awg-db-psql              # Подключиться к PostgreSQL
```

---

## 🛠️ Если хотите добавить в Makefile

Если вы всё-таки хотите добавить команды в `Makefile`, вот готовый фрагмент:

### 1. Обновите переменные (в начале Makefile):

```makefile
# Настройки проекта
SERVICE_NAME := amneziawg-server
WEB_SERVICE := amneziawg-web
DB_SERVICE := amneziawg-db
```

### 2. Добавьте новую секцию (в конец Makefile):

```makefile
# ============================================================================
# ВЕБ-ИНТЕРФЕЙС И POSTGRESQL (v2.0.0+)
# ============================================================================

.PHONY: web-url web-logs db-psql db-backup stack-status

web-url: ## Показать URL веб-интерфейса
	@WEB_PORT=$$(grep "^WEB_PORT=" .env 2>/dev/null | cut -d= -f2 || echo "8080"); \
	SERVER_IP=$$(curl -s https://eth0.me || echo "localhost"); \
	echo "Веб-интерфейс: http://$$SERVER_IP:$$WEB_PORT"

web-logs: ## Логи веб-интерфейса
	@docker logs -f $(WEB_SERVICE)

db-psql: ## Подключиться к PostgreSQL
	@PGUSER=$$(grep "^POSTGRES_USER=" .env 2>/dev/null | cut -d= -f2 || echo "amneziawg"); \
	PGDB=$$(grep "^POSTGRES_DB=" .env 2>/dev/null | cut -d= -f2 || echo "amneziawg"); \
	docker exec -it $(DB_SERVICE) psql -U $$PGUSER -d $$PGDB

db-backup: ## Создать бэкап PostgreSQL
	@PGUSER=$$(grep "^POSTGRES_USER=" .env 2>/dev/null | cut -d= -f2); \
	PGDB=$$(grep "^POSTGRES_DB=" .env 2>/dev/null | cut -d= -f2); \
	docker exec $(DB_SERVICE) pg_dump -U $$PGUSER $$PGDB > postgres-backup-$$(date +%Y%m%d-%H%M%S).sql

stack-status: ## Статус всего стека
	@docker compose ps
```

⚠️ **ВАЖНО:** В Makefile используйте **табы**, а не пробелы перед командами!

---

## 🎯 Итоги

**Существующий Makefile работает** и содержит все команды для управления VPN сервером:
- ✅ `make up` - запуск сервера
- ✅ `make client-add name=john` - добавить клиента
- ✅ `make client-qr name=john` - показать QR код
- ✅ `make logs` - просмотр логов
- ✅ `make status` - статус сервера
- ✅ `make backup` - создать бэкап

**Для v2.0.0 (Веб + PostgreSQL) рекомендуется:**
1. Использовать прямые Docker команды (см. выше)
2. Создать bash алиасы для частых команд
3. Опционально: добавить команды в Makefile вручную

**Самые полезные команды:**
```bash
# Показать URL веб-интерфейса
WEB_PORT=$(grep "^WEB_PORT=" .env | cut -d= -f2)
echo "http://$(curl -s https://eth0.me):$WEB_PORT"

# Статус всех сервисов
docker compose ps

# Подключиться к PostgreSQL
docker exec -it amneziawg-db psql -U amneziawg -d amneziawg

# Бэкап PostgreSQL
docker exec amneziawg-db pg_dump -U amneziawg amneziawg > backup.sql
```

---

**Основной Makefile полностью функционален для VPN управления!** 🎉
