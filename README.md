# Lift App (ELS)

Backend **«Единая лифтовая система»**: REST API на FastAPI для сущностей вокруг обслуживания лифтов — организации, объекты, договоры, акты, наряды, справочники, пользователи и роли.

| Компонент | Версия / заметка |
|-----------|------------------|
| Python | ≥ 3.8 (`pyproject.toml`) |
| Web | FastAPI 0.95, Uvicorn, Starlette |
| БД | PostgreSQL, SQLAlchemy 1.4, Alembic |
| Auth | JWT (python-jose), bcrypt / passlib |
| Пакетный менеджер | [uv](https://github.com/astral-sh/uv) |
| Линт / формат | Ruff |

## Требования

- [uv](https://docs.astral.sh/uv/)
- PostgreSQL 13+ (локально или через Docker)
- Файл `.env` в корне репозитория (см. раздел «Конфигурация»)

## Быстрый старт (локально)

1. Скопируйте пример окружения и заполните значения (в репозитории есть `envs/.env.local`, `envs/.env.docker` — используйте как шаблон, **не коммитьте секреты**).

2. Установите зависимости:

   ```bash
   make sync
   ```

3. Поднимите PostgreSQL и примените миграции:

   ```bash
   uv run alembic upgrade head
   ```

4. Запуск приложения с автоперезагрузкой:

   ```bash
   make up
   ```

   Или: `uv run uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload`

- Документация OpenAPI: `http://localhost:8000/docs`  
- Альтернатива: `http://localhost:8000/redoc`  
- Префикс API: `/api/v1` (см. `settings.API_V1_STR` в `src/config.py`)

При старте вызывается `create_initial_data()` (`src/core/db/init_db.py`) — инициализация базовых данных.

## Docker Compose

Стек: **postgres** (13), **backend** (сборка из `Dockerfile`), **pgadmin**.

```bash
docker compose up --build
```

- Backend: `8000:8000`
- PostgreSQL: `5432:5432`
- pgAdmin: `55907:80`

Перед стартом контейнера `prestart.sh` выполняет `alembic upgrade head`. Для hot-reload в контейнере задайте в `.env` переменную `UVICORN_RELOAD` (например `--reload`); для production оставьте пустой строкой.

В `docker-compose.yml` для backend смонтирован текущий каталог в `/app` — код на хосте виден внутри контейнера.

## Конфигурация

Приложение читает переменные из **`.env`** (`python-dotenv` + pydantic `BaseSettings`).

### Обязательные для подключения к БД

Параметры формируют URL `postgresql://…` в `get_url()` (`src/config.py`):

| Переменная | Назначение |
|------------|------------|
| `DB_USER` | Пользователь PostgreSQL |
| `DB_PASSWORD` | Пароль |
| `DB_HOST` | Хост (`postgres` в Compose, `localhost` локально) |
| `DB_PORT` | Порт (часто `5432`) |
| `DB_NAME` | Имя базы |

### Часто используемые опциональные

| Переменная | Назначение |
|------------|------------|
| `APP_PORT` | Порт приложения (по умолчанию `8000`; для Uvicorn в образе порт фиксирован в `CMD`) |
| `SECRET_KEY` | Секрет подписи JWT; **задайте в production**, иначе при отсутствии в окружении возможно нестабильное поведение из‑за дефолта |
| `PROJECT_NAME` | Имя проекта в OpenAPI и письмах |
| `SERVER_HOST`, `SERVER_NAME` | Метаданные сервера |
| `BACKEND_CORS_ORIGINS` | CORS (в `main.py` сейчас разрешён `*`; настройка в конфиге может использоваться при доработке) |
| `FIRST_SUPERUSER`, `FIRST_SUPERUSER_PASSWORD` | Учётные данные начального суперпользователя (см. `init_db`) |
| `SMTP_*`, `EMAILS_FROM_EMAIL` | SMTP; `EMAILS_ENABLED` вычисляется при наличии хоста, порта и email отправителя |
| `SENTRY_DSN` | Опционально Sentry |
| `PGADMIN_DEFAULT_EMAIL`, `PGADMIN_DEFAULT_PASSWORD` | Только для сервиса pgAdmin в Compose |

Переменная `SQLALCHEMY_DATABASE_URI` в примерах `envs/` не подменяет `get_url()` — для приложения критичны `DB_*`.

## Миграции (Alembic)

```bash
uv run alembic upgrade head
uv run alembic revision --autogenerate -m "описание"
```

Скрипты: каталог `alembic/versions`, конфиг `alembic.ini`, `alembic/env.py` импортирует модели из `src.models.*`.

## Разработка

| Команда | Действие |
|---------|----------|
| `make sync` | `uv sync --all-groups` (runtime + dev) |
| `make lint` | `ruff check` + `ruff format --check` для `src/` |
| `make format` | автоисправления Ruff и форматирование |
| `make test` | поднимает тестовую БД и гоняет `pytest` |
| `make test-db-up` / `make test-db-down` | только контейнер с тестовой БД |

Настройки Ruff: `pyproject.toml` (`[tool.ruff]`).

## Тесты

```bash
make test
```

1. Скопируйте `.test.env.example` в `.test.env` — там **отдельная** база только под pytest.
2. `make test-db-up` поднимает `docker-compose.test.yml`: PostgreSQL на своём порту, данные в tmpfs (исчезают вместе с контейнером).
3. Сессионная фикстура `migrated_test_db` пересоздаёт схему `public`, накатывает Alembic до `head` и заполняет справочники через `create_initial_data()`.
4. Фикстура `db_session` даёт сессию внутри SAVEPOINT и откатывает её после каждого теста — тесты не видят данных друг друга. За этим следит `TestDbSessionIsolation` в `tests/test_crud_location.py`.

Перед прогоном `conftest.py` проверяет `MODE=TEST` и слово `test` в `DB_NAME` — предохранитель от запуска по боевой базе, потому что фикстура делает `DROP SCHEMA public`.

## Структура репозитория (логика)

```
src/
  main.py              # FastAPI app, CORS, startup / init_db
  config.py            # Настройки и get_url()
  session.py           # Engine, SessionLocal, Base
  api/api_v1/          # Роутеры endpoints
  models/              # SQLAlchemy-модели
  schemas/             # Pydantic-схемы
  crud/                # Доступ к данным
  core/                # security, db/init, roles, response
  getters/             # Сборка DTO для ответов
alembic/               # Миграции
envs/                  # Примеры .env (не для продакшена как единственный источник секретов)
```

Модули `act_fact_of_mechanic`, `verif_code` и часть роутеров (`_login`, `_users`) в дереве есть, но **не подключены** в `src/api/api_v1/api.py` — актуальный набор эндпоинтов смотрите в этом файле и в `/docs`.

## Версионирование

Версия пакета: `0.1.0` в `pyproject.toml` (`name = "lift-app"`).
