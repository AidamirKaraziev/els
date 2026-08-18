---
tags: [atlas, database]
date: 2026-08-19
---

# База данных - PostgreSQL + SQLAlchemy 1.4 + SessionLocal

## Что используется
- PostgreSQL (локально или через Docker Compose)
- SQLAlchemy **1.4.48** (закреплена в `backend/pyproject.toml`)
- Alembic (миграции) — см. [[миграции Alembic - версии в alembic versions и импорт моделей из src.models]]

## Где смотреть в коде
- `src/session.py`: `engine` из `settings.DB_URL` с `pool_pre_ping`,
  `SessionLocal` (**`autoflush=False`** — про грабли с этим см. план
  механика), `Base = declarative_base()`. Сверено 2026-08-19.
- `src/models/`: таблицы/отношения ORM.
- `alembic/`: миграции и окружение Alembic.

## Связанные темы
- [[конфигурация - .env через BaseSettings и свойство DB_URL]]
- [[Docker Compose - postgres + backend + фронт с nginx]]

