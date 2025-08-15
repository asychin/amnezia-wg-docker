# AmneziaWG Web Interface

Веб-интерфейс для управления AmneziaWG VPN сервером, построенный на React + TypeScript + Chakra UI v3.

## Структура проекта

```
web/
├── frontend/                 # React приложение
│   ├── src/
│   │   ├── components/       # React компоненты
│   │   ├── pages/           # Страницы
│   │   ├── services/        # API сервисы
│   │   ├── hooks/           # Кастомные хуки
│   │   ├── types/           # TypeScript типы
│   │   └── utils/           # Утилиты
│   ├── package.json
│   └── tsconfig.json
├── backend/                  # Go API сервер
│   ├── cmd/
│   ├── internal/
│   ├── go.mod
│   └── go.sum
└── docker-compose.web.yml    # Дополнительная конфигурация для веб-интерфейса
```

## Стек технологий

- **Frontend**: React 18 + TypeScript + Vite
- **UI Library**: Chakra UI v3 с Charts
- **Backend**: Go с Gin фреймворком
- **Containerization**: Docker

## Функциональность

1. **Dashboard** - мониторинг статуса сервера и подключений
2. **Client Management** - управление клиентами (добавление, удаление, QR коды)
3. **Server Settings** - настройка параметров сервера
4. **Logs** - просмотр логов в реальном времени
5. **Statistics** - графики использования и статистика
