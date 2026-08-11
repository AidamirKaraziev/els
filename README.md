# Lift App (ELS)

Моно-репозиторий **«Единая лифтовая система»**: REST API на FastAPI и фронтенд для сущностей вокруг обслуживания лифтов — организации, объекты, договоры, акты, наряды, справочники, пользователи и роли.

```
backend/     FastAPI: src, alembic, tests, свой pyproject и Dockerfile
frontend/    клиентское приложение (появится вместе с кодом фронта)
infra/       docker compose для стека и для тестовой БД
els-vault/   база знаний проекта (Obsidian)
docs/        схема БД и прочая документация
scripts/     инструменты репозитория (проверка имён файлов vault)
```

Части независимы: у каждой свои зависимости, свой линт и свои тесты, общение — только по REST через `/api/v1`. Импортов друг в друга нет.

| Компонент | Версия / заметка |
|-----------|------------------|
| Python | 3.11 локально (`backend/.python-version`), 3.8 в образе |
| Web | FastAPI 0.95, Uvicorn, Starlette |
| БД | PostgreSQL, SQLAlchemy 1.4, Alembic |
| Auth | JWT (python-jose), bcrypt / passlib |
| Пакетный менеджер | [uv](https://github.com/astral-sh/uv) |
| Линт / формат | Ruff |

## Требования

- [uv](https://docs.astral.sh/uv/), Docker
- Файл `.env` в корне репозитория (см. раздел «Конфигурация»)

Все команды запускаются **из корня репозитория** через `Makefile`. `make help` покажет список.

## Быстрый старт (локально)

1. Скопируйте пример окружения и заполните значения (шаблоны: `backend/envs/.env.local`, `backend/envs/.env.docker` — **не коммитьте секреты**). `.env` кладите в корень репозитория; рядом с бэкендом он тоже подхватится.

2. Установите зависимости бэкенда:

   ```bash
   make sync
   ```

3. Примените миграции:

   ```bash
   cd backend && uv run alembic upgrade head
   ```

4. Запуск бэкенда с автоперезагрузкой:

   ```bash
   make dev
   ```

- Документация OpenAPI: `http://localhost:8000/docs`  
- Альтернатива: `http://localhost:8000/redoc`  
- Префикс API: `/api/v1` (см. `settings.API_V1_STR` в `backend/src/config.py`)

При старте вызывается `create_initial_data()` (`backend/src/core/db/init_db.py`) — инициализация базовых данных.

## Docker Compose

Стек: **postgres** (13), **backend** (сборка из `backend/Dockerfile`), **pgadmin**.

```bash
make up
```

- Backend: `8000:8000`
- PostgreSQL: `5432:5432`
- pgAdmin: `55907:80`

Compose живёт в `infra/`, но пути внутри него относительны корня репозитория, поэтому вызывать его нужно с `--project-directory .` — `make up` и `make down` это уже делают:

```bash
docker compose --project-directory . -f infra/docker-compose.yml up -d --build
```

Перед стартом контейнера `prestart.sh` выполняет `alembic upgrade head`. Для hot-reload в контейнере задайте в `.env` переменную `UVICORN_RELOAD` (например `--reload`); для production оставьте пустой строкой.

## Конфигурация

Приложение читает переменные из **`.env`** (`python-dotenv` + pydantic `BaseSettings`).

### Обязательные для подключения к БД

Параметры формируют URL `postgresql://…` в `settings.DB_URL` (`backend/src/config.py`):

| Переменная | Назначение |
|------------|------------|
| `DB_USER` | Пользователь PostgreSQL |
| `DB_PASS` | Пароль. **Именно `DB_PASS`** — шаблоны в `backend/envs/` называют его `DB_PASSWORD`, приложение такое имя не читает; compose понимает оба |
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

Переменная `SQLALCHEMY_DATABASE_URI` в примерах `backend/envs/` не подменяет `DB_URL` — для приложения критичны `DB_*`.

## Миграции (Alembic)

```bash
cd backend && uv run alembic upgrade head
```

Новая ревизия: `cd backend && uv run alembic revision --autogenerate -m "описание"`.

Скрипты: каталог `backend/alembic/versions`, конфиг `backend/alembic.ini`, `backend/alembic/env.py` импортирует модели из `src.models.*`.

## Разработка

| Команда | Действие |
|---------|----------|
| `make help` | список целей |
| `make sync` | зависимости бэкенда (`uv sync --all-groups`) |
| `make dev` | бэкенд локально с автоперезагрузкой |
| `make up` / `make down` / `make logs` | весь стек в docker |
| `make lint` | `ruff check` + `ruff format --check` для `backend/src` |
| `make format` | автоисправления Ruff и форматирование |
| `make test` | поднимает тестовую БД и гоняет `pytest` |
| `make test-db-up` / `make test-db-down` | только контейнер с тестовой БД |
| `make vault-check` | имена файлов `els-vault/` на Windows-совместимость |

Настройки Ruff: `backend/pyproject.toml` (`[tool.ruff]`). CI: `.github/workflows/backend.yml` — линт, тесты и проверка vault отдельными джобами.

## Тесты

```bash
make test
```

1. Скопируйте `backend/.test.env.example` в `.test.env` в корне репозитория — там **отдельная** база только под pytest.
2. `make test-db-up` поднимает `infra/docker-compose.test.yml`: PostgreSQL на своём порту, данные в tmpfs (исчезают вместе с контейнером).
3. Сессионная фикстура `migrated_test_db` пересоздаёт схему `public`, накатывает Alembic до `head` и заполняет справочники через `create_initial_data()`.
4. Фикстура `db_session` даёт сессию внутри SAVEPOINT и откатывает её после каждого теста — тесты не видят данных друг друга. За этим следит `TestDbSessionIsolation` в `backend/tests/test_crud_location.py`.

Перед прогоном `conftest.py` проверяет `MODE=TEST` и слово `test` в `DB_NAME` — предохранитель от запуска по боевой базе, потому что фикстура делает `DROP SCHEMA public`.

## Структура репозитория (логика)

```
backend/
  src/
    main.py            # FastAPI app, CORS, startup / init_db
    config.py          # Настройки и DB_URL
    session.py         # Engine, SessionLocal, Base
    api/api_v1/        # Роутеры endpoints
    models/            # SQLAlchemy-модели
    schemas/           # Pydantic-схемы
    crud/              # Доступ к данным
    core/              # security, db/init, roles, response
    getters/           # Сборка DTO для ответов
  alembic/             # Миграции
  tests/               # pytest
  static/              # Загруженные фото и сгенерированные PDF (не в git)
  envs/                # Примеры .env (не единственный источник секретов в проде)
  scripts/             # lint.sh, format.sh, test.sh
infra/                 # docker-compose.yml, docker-compose.test.yml
els-vault/             # База знаний (Obsidian)
docs/                  # Схема БД
readme_file/            # Скриншоты интерфейса
scripts/               # Инструменты репозитория (vault-check)
```

Модули `act_fact_of_mechanic`, `verif_code` и часть роутеров (`_login`, `_users`) в дереве есть, но **не подключены** в `backend/src/api/api_v1/api.py` — актуальный набор эндпоинтов смотрите в этом файле и в `/docs`.

## Версионирование

Версия пакета: `0.1.0` в `backend/pyproject.toml` (`name = "lift-app"`).
