---
tags: [knowledge, patterns]
date: 2026-04-07
---

# Паттерн API - endpoints to crud to schemas to models

## Поток данных
- `endpoints/*.py`: принимает запрос, валидирует через `schemas`, вызывает CRUD.
- `crud/*.py`: реализует операции с БД и бизнес-логику на уровне доступа к данным.
- `models/*.py`: ORM-структура таблиц и отношений.
- `getters/*.py`: формирование DTO/ответов под нужды API (когда ответ не 1-в-1 модель).

## Ссылки
- [[архитектура проекта - FastAPI API + CRUD + getters + SQLAlchemy модели]]

