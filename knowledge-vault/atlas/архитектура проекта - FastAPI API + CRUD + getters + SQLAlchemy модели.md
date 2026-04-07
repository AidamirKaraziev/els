---
tags: [atlas, architecture]
date: 2026-04-07
---

# Архитектура проекта - FastAPI API + CRUD + getters + SQLAlchemy модели

## Слои
- **HTTP слой**: FastAPI приложение в `src/main.py`, роутеры в `src/api/api_v1/endpoints/`.
- **Схемы**: Pydantic модели запросов/ответов в `src/schemas/`.
- **Доступ к данным**: операции в `src/crud/` (в т.ч. поддиректории `crud/users/`).
- **Модели**: SQLAlchemy модели в `src/models/`.
- **Сборка ответов**: “getters” в `src/getters/` (DTO/агрегации под API-ответы).

## Точки входа/связи
- API подключается через `src/api/api_v1/api.py` и `app.include_router(..., prefix=settings.API_V1_STR)` в `src/main.py`.
- База данных и сессии: [[база данных - PostgreSQL + SQLAlchemy 1.4 + SessionLocal]].
- Конфиг: [[конфигурация - .env через BaseSettings и get_url из DB переменных]].
- Инициализация при старте: [[startup - create_initial_data вызывается на событии startup]].

## Паттерны
- См. [[паттерн API - endpoints to crud to schemas to models]].

