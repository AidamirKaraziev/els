---
tags: [home, index]
date: 2026-04-07
---

# Lift App (ELS) — карта знаний

Этот vault — долгосрочная память проекта. Заметки называются **утверждениями**, а не категориями, и связываются wiki-ссылками `[[...]]`.

## Быстрый старт
- [[текущие приоритеты]]
- [[шпаргалка - как работать с Cursor и графом знаний]]
- [[архитектура проекта - FastAPI API + CRUD + getters + SQLAlchemy модели]]
- [[миграции Alembic - версии в alembic versions и импорт моделей из src.models]]
- [[Docker Compose - postgres + backend + pgadmin]]

## Атлас (стабильные знания)
- [[архитектура проекта - FastAPI API + CRUD + getters + SQLAlchemy модели]]
- [[база данных - PostgreSQL + SQLAlchemy 1.4 + SessionLocal]]
- [[деплой и запуск - uvicorn + Dockerfile + prestart.sh]]
- [[конфигурация - .env через BaseSettings и get_url из DB переменных]]
- [[аутентификация - JWT через python-jose + пароли через bcrypt/passlib]]

## Интеграции / внешние системы
- (пока нет выделенных интеграций, кроме PostgreSQL/pgAdmin/Docker)

## Решения
- [[пакетный менеджер - uv sync и фиксированный uv.lock]]
- [[pdf - генерация дефектной ведомости через reportlab]]

## Дебаг и известные проблемы
- [[модель defective_acts - TODO по структуре и связям]]

## Сессии
- [[2026-04-07 - дефектные акты и генерация pdf]]

## Паттерны кода
- [[паттерн API - endpoints to crud to schemas to models]]
- [[startup - create_initial_data вызывается на событии startup]]

