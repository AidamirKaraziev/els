---
tags: [knowledge, integrations, docker]
date: 2026-04-07
---

# Docker Compose - postgres + backend + pgadmin

## Сервисы
- `postgres`: PostgreSQL 13, хранит данные в `postgres_data`
- `backend`: FastAPI приложение (сборка из `Dockerfile`)
- `pgadmin`: dpage/pgadmin4, для администрирования БД

## Важные детали
- `backend` ждёт healthcheck `postgres` (через `depends_on: condition: service_healthy`)
- В `backend` пробрасывается `UVICORN_RELOAD` для режима разработки

## Ссылки
- [[деплой и запуск - uvicorn + Dockerfile + prestart.sh]]
- [[конфигурация - .env через BaseSettings и get_url из DB переменных]]

