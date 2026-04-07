---
tags: [knowledge, debugging, models]
date: 2026-04-07
---

# Модель defective_acts - TODO по структуре и связям

## Наблюдение
Файл `src/models/defective_acts.py` содержит TODO и “пустые” места, что сигнализирует о незавершённой модели или не до конца понятных требованиях к структуре.

## Текущее состояние (по коду)
- Таблица: `defective_acts`
- Связи: `objects`, `acts_bases`, `statuses`, два FK на `universal_users` (прораб и главный механик)
- Поля времени: `created_at`, `started_at`, `finished_at`
- `step_list_fact` хранится строкой (возможно сериализованный список шагов)

## Что прояснить перед доработкой
- Является ли `step_list_fact` JSON/строкой/отдельной таблицей?
- Нужны ли дополнительные связи (например, “факты по механикам”) — в коде есть удалённая строка relationship.
- Правила удаления: сейчас многие FK `ondelete="SET NULL"`, у `status_id` — `CASCADE`.

## Связанные заметки
- [[база данных - PostgreSQL + SQLAlchemy 1.4 + SessionLocal]]
- [[миграции Alembic - версии в alembic versions и импорт моделей из src.models]]

