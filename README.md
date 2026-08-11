# Lift App (ELS)

Моно-репозиторий **«Единая лифтовая система»**: REST API на FastAPI и фронтенд для сущностей вокруг обслуживания лифтов — организации, объекты, договоры, акты, наряды, справочники, пользователи и роли.

```
backend/     FastAPI: src, alembic, tests, свой pyproject и Dockerfile
frontend/    Flutter-приложение: android, ios, web
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
| Фронт | Flutter, Dart ≥ 3.10.3, flutter_bloc + provider, dio |

### Состояние фронта

Код `frontend/` перенесён из репозитория прежнего подрядчика вместе с историей (`git subtree`). Он **не приведён в порядок**: 71 тысяча строк, экраны продублированы под каждую роль, адрес бэкенда зашит в исходники в двух разных вариантах, слоя работы с API нет. Разбор с цифрами — в `els-vault/knowledge/debugging/аудит фронта на 2026-08-11 - Flutter, 71 тысяча строк.md`, порядок работ — в `els-vault/00-home/план работ - интеграция фронта и рефакторинг.md`. Не считайте текущий вид `frontend/` образцом стиля этого репозитория.

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

## Запуск всего проекта локально

```bash
make up
```

Стек: **postgres** (13), **backend** (`backend/Dockerfile`), **frontend** (веб-сборка Flutter + nginx). Первая сборка тянет образ Flutter (~1 ГБ) и занимает несколько минут.

nginx во фронте — единая точка входа, поэтому наружу смотрит один порт:

| Адрес | Что |
|-------|-----|
| `http://localhost:8080/` | веб-приложение |
| `http://localhost:8080/api/v1/` | API (проксируется на `backend:8000`) |
| `http://localhost:8080/docs` | Swagger бэкенда |
| `localhost:5432` | PostgreSQL (подключаться клиентом БД; порт меняется `DB_HOST_PORT`) |

Один origin на приложение и API — поэтому браузеру не нужен CORS, а фронту достаточно относительного пути `/api/v1`. Порт меняется переменной `WEB_PORT` в `.env`.

### Мобильные сборки (iOS / Android)

В docker их нет и быть не может: Android нужен SDK с эмулятором, iOS собирается только на macOS с Xcode. Кодовая база при этом **одна** — отличается только адрес API:

```bash
cd frontend && flutter run -d <device> --dart-define=API_ORIGIN=http://192.168.1.X:8080
```

Телефон и компьютер должны быть в одной сети; для Android-эмулятора вместо IP машины используется `10.0.2.2`, для iOS-симулятора — `localhost`.

Веб-сборке `API_ORIGIN` задавать не нужно: она берёт адрес из origin страницы, поэтому один и тот же образ работает на `localhost:8080` и на боевом домене. Переопределять стоит только если API вынесен на отдельный хост — см. `frontend/lib/helper/api_config.dart`.

### Переменные сборки фронта

**У Flutter нет рантаймового `.env`**: на телефоне переменных окружения нет, а браузер их не отдаёт. Штатный механизм Dart — константы, подставляемые при компиляции:

```bash
cd frontend && flutter run --dart-define-from-file=env/local.json
```

Скопируйте `frontend/env/example.json` в `frontend/env/local.json` (он в `.gitignore`) — там же описано, что каждая переменная делает. Значения по умолчанию лежат в `frontend/lib/helper/app_config.dart` и `api_config.dart`; в docker те же переменные пробрасываются как build args (см. `infra/docker-compose.yml`).

| Переменная | Назначение |
|------------|------------|
| `API_ORIGIN` | адрес бэкенда; вебу не нужен, нужен телефону |
| `MAP_TILE_URL` | сервер тайлов карты |
| `OSM_USER_AGENT` | User-Agent для OSM и Nominatim: анонимные запросы они блокируют |

**Секретов в клиентском приложении быть не может.** Всё, что попало в сборку, публично: APK распаковывается, JS читается. Ключи внешних сервисов и пароли живут только на бэкенде, приложение обращается к ним через наш API. По этой же причине `flutter_dotenv` тут не используется — он кладёт файл в ассеты, где его видно любому.

Мобильная сборка пока **не собирается** — в нескольких файлах безусловный `import 'dart:html'`, который существует только в вебе. Это отдельный шаг, см. план в `els-vault/00-home/план - запустить проект локально в docker.md`.

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
| `PGADMIN_DEFAULT_EMAIL`, `PGADMIN_DEFAULT_PASSWORD` | Не используются: pgAdmin убран из Compose 2026-08-11, строки можно удалить |

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
