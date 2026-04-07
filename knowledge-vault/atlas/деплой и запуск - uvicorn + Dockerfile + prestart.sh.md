---
tags: [atlas, deploy, run]
date: 2026-04-07
---

# Деплой и запуск - uvicorn + Dockerfile + prestart.sh

## Локальный запуск
- `make up` или `uv run uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload`

## Docker
- Образ собирается из `Dockerfile`
- При старте контейнера запускается `prestart.sh`, который применяет миграции (`alembic upgrade head`)
- Команда контейнера: `uvicorn src.main:app --host 0.0.0.0 --port 8000 ${UVICORN_RELOAD}`

## Связанные темы
- [[Docker Compose - postgres + backend + pgadmin]]
- [[миграции Alembic - версии в alembic versions и импорт моделей из src.models]]

