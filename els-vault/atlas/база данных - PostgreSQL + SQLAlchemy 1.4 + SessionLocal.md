---
tags: [atlas, database]
date: 2026-04-07
---

# База данных - PostgreSQL + SQLAlchemy 1.4 + SessionLocal

## Что используется
- PostgreSQL (локально или через Docker Compose)
- SQLAlchemy 1.4 (ORM)
- Alembic (миграции) — см. [[миграции Alembic - версии в alembic versions и импорт моделей из src.models]]

## Где смотреть в коде
- `src/session.py`: обычно содержит engine, `SessionLocal`, `Base`.
- `src/models/`: таблицы/отношения ORM.
- `alembic/`: миграции и окружение Alembic.

## Связанные темы
- [[конфигурация - .env через BaseSettings и get_url из DB переменных]]
- [[Docker Compose - postgres + backend + pgadmin]]

