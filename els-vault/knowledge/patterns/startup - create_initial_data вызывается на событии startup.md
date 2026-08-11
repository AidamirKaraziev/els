---
tags: [knowledge, patterns, startup]
date: 2026-04-07
---

# Startup - create_initial_data вызывается на событии startup

## Факт
При запуске приложения выполняется инициализация базовых данных через `create_initial_data()` (см. `src/core/db/init_db.py`), вызываемая в `startup`-событии FastAPI в `src/main.py`.

## Риски/следствия
- Старт приложения зависит от доступности БД.
- Повторный запуск может пытаться “досоздавать” базовые записи — важно, чтобы инициализация была идемпотентной.

## Ссылки
- [[архитектура проекта - FastAPI API + CRUD + getters + SQLAlchemy модели]]
- [[база данных - PostgreSQL + SQLAlchemy 1.4 + SessionLocal]]

