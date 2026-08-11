---
tags: [atlas, auth]
date: 2026-04-07
---

# Аутентификация - JWT через python-jose + пароли через bcrypt/passlib

## Что ожидается по README
- JWT-токены для авторизации (`python-jose`)
- Хеширование паролей (`bcrypt` / `passlib`)

## Где искать в коде
- `src/core/security.py` — обычно утилиты для токенов/паролей
- `src/api/api_v1/endpoints/_login.py` — эндпоинты логина (если подключены в `api.py`)
- `src/schemas/token.py` — схемы токенов

## Связанные темы
- [[архитектура проекта - FastAPI API + CRUD + getters + SQLAlchemy модели]]

