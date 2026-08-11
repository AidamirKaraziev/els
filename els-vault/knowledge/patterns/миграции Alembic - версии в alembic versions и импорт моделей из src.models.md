---
tags: [knowledge, patterns, migrations]
date: 2026-04-07
---

# Миграции Alembic - версии в alembic/versions и импорт моделей из src.models

## Факт
Миграции лежат в `alembic/versions/`, конфигурация — `alembic.ini`. Окружение Alembic обычно импортирует модели из `src.models.*`, чтобы автогенерация видела метаданные.

## Рабочий цикл
- Применить миграции: `uv run alembic upgrade head`
- Создать миграцию: `uv run alembic revision --autogenerate -m "описание"`

## Связанные темы
- [[база данных - PostgreSQL + SQLAlchemy 1.4 + SessionLocal]]
- [[деплой и запуск - uvicorn + Dockerfile + prestart.sh]]

