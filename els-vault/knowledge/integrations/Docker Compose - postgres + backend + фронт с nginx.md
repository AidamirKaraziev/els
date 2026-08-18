---
tags: [knowledge, integrations, docker]
date: 2026-08-11
---

# Docker Compose - postgres + backend + фронт с nginx

Compose-файлов два, и они решают разные задачи.

## Дев-стек: `infra/docker-compose.yml`

Собирает образы из исходников. Поднимается через `make up` или `make release`.

- `postgres`: PostgreSQL 13, данные в томе `postgres_data`, порт наружу
  на `localhost:5432` (меняется `DB_HOST_PORT`)
- `backend`: FastAPI, сборка из `backend/Dockerfile`, наружу не публикуется
- `frontend`: веб-сборка Flutter внутри образа плюс nginx — единая точка
  входа: `/` отдаёт приложение, `/api/v1/` проксируется на `backend:8000`

`pgadmin` был в стеке до 2026-08-11 и убран: 173 МБ памяти и 528 МБ образа
ради веб-морды к базе. Базу смотрим клиентом на `localhost:5432`, а дев-стек
держим ближе к прод-стеку.

## Прод-стек: `infra/docker-compose.prod.yml`

Ничего не собирает — образы приезжают из ghcr.io, их собрал CI
(`.github/workflows/release.yml`). Поднимается через `make prod-deploy`.

Отличия продиктованы сервером на 1 ГБ памяти: нет pgAdmin, postgres привязан
к `127.0.0.1` и настроен на 50 соединений вместо ста, у сервисов
`restart: unless-stopped`, `UVICORN_RELOAD` принудительно пустой.

Собирать фронт на таком сервере нельзя в принципе: `flutter build web
--release` требует несколько гигабайт RAM и образ Flutter SDK на 3.76 ГБ.

## Важные детали

- `backend` ждёт healthcheck `postgres` через `depends_on: condition:
  service_healthy`
- у `backend` свой healthcheck на `/api/v1/openapi.json`. Без него
  `docker compose up -d` рапортует успех, даже если контейнер упал на
  миграции: команда лишь просит docker его запустить
- миграции накатывает сам контейнер — `prestart.sh` делает
  `alembic upgrade head` до старта uvicorn. Отдельного шага в Makefile нет
  намеренно, иначе на проде они шли бы дважды
- `infra/nginx/` монтируется каталогом, а не вшит в образ: правка проксирования
  не требует пересборки
- пути внутри compose-файлов относительны корня монорепо, поэтому нужен
  `--project-directory .`
- том `static_data` хранит фотографии заявок и сгенерированные PDF. Растёт
  линейно и сам не чистится

## Ссылки
- [[деплой и запуск - uvicorn + Dockerfile + prestart.sh]]
- [[конфигурация - .env через BaseSettings и свойство DB_URL]]
- [[монорепозиторий - код в одном репо, но связь только через REST]]
