---
tags: [atlas, architecture]
date: 2026-08-19
---

# Архитектура проекта - FastAPI API + CRUD + getters + SQLAlchemy модели

## Слои
- **HTTP слой**: FastAPI приложение в `src/main.py`, роутеры в `src/api/api_v1/endpoints/`.
- **Схемы**: Pydantic модели запросов/ответов в `src/schemas/`.
- **Доступ к данным**: операции в `src/crud/` (в т.ч. поддиректории `crud/users/`).
- **Модели**: SQLAlchemy модели в `src/models/`.
- **Сборка ответов**: “getters” в `src/getters/` (DTO/агрегации под API-ответы).
- **Правила предметной области**: `src/services/` — то, что нельзя держать
  ни в ручке, ни в CRUD, потому что читают это несколько мест сразу. Сейчас
  там разбор чек-листа (`checklist.py`), деление работ на виды
  (`work_kind.py`), балл сотрудника (`employee_score.py`), доступ к файлам
  (`file_access.py`), генерация PDF и Excel, почта. Слой появился после
  апреля и в прежней редакции этой заметки отсутствовал.
- **Мелкие утилиты**: `src/utils/` — страницы (`pagination.py`) и метки
  времени (`time_stamp.py`, там же `utc_to_timestamp`).

## Точки входа/связи
- API подключается через `src/api/api_v1/api.py` и `app.include_router(..., prefix=settings.API_V1_STR)` в `src/main.py`.
- База данных и сессии: [[база данных - PostgreSQL + SQLAlchemy 1.4 + SessionLocal]].
- Конфиг: [[конфигурация - .env через BaseSettings и свойство DB_URL]].
- Инициализация при старте: [[startup - create_initial_data вызывается на событии startup]].

## Паттерны
- См. [[паттерн API - endpoints to crud to schemas to models]].
- Права и область видимости навешиваются в `src/api/deps.py`, а сама область
  считается один раз и применяется фильтром:
  [[область видимости считается один раз и применяется фильтром]].

Сверено с кодом 2026-08-19.

