---
tags: [atlas, deploy, run]
date: 2026-08-19
---

# Деплой и запуск - uvicorn + Dockerfile + prestart.sh

## Локальный запуск
- `make up` — весь стек в docker: postgres, backend, nginx с веб-сборкой
  фронта. Веб и API на `http://localhost:8080`, наружу торчит только nginx.
- `make dev` — только бэкенд локально с автоперезагрузкой
  (`uv run uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload`),
  база при этом нужна своя.

## Docker
- Образ собирается из `Dockerfile`
- При старте контейнера запускается `prestart.sh`, который применяет миграции (`alembic upgrade head`)
- Команда контейнера: `uvicorn src.main:app --host 0.0.0.0 --port 8000 ${UVICORN_RELOAD}`

## Связанные темы
- [[Docker Compose - postgres + backend + фронт с nginx]]
- [[миграции Alembic - версии в alembic versions и импорт моделей из src.models]]

