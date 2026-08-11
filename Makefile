# Единая точка входа монорепо. Все цели запускаются из корня репозитория.
#
# backend/  — FastAPI, свои зависимости (uv) и свои тесты
# frontend/ — появится вместе с кодом фронта
# infra/    — docker compose для всего стека
# els-vault/— база знаний проекта (Obsidian)

.PHONY: help up down logs ps sync dev lint format test test-db-up test-db-down \
        web-build web-logs vault-check

# Пути внутри compose-файлов относительны корня, поэтому --project-directory .
COMPOSE := docker compose --project-directory . -f infra/docker-compose.yml
COMPOSE_TEST := docker compose --project-directory . --env-file .test.env -f infra/docker-compose.test.yml

help:
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

## --- стек целиком ---

up:  ## поднять весь стек в docker (веб на http://localhost:8080)
	$(COMPOSE) up -d --build
	@echo
	@echo "  Веб:     http://localhost:$${WEB_PORT:-8080}"
	@echo "  API:     http://localhost:$${WEB_PORT:-8080}/api/v1"
	@echo "  Swagger: http://localhost:$${WEB_PORT:-8080}/docs"
	@echo "  pgAdmin: http://localhost:55907"

down:  ## погасить стек
	$(COMPOSE) down

ps:  ## что запущено
	$(COMPOSE) ps

logs:  ## логи стека
	$(COMPOSE) logs -f --tail=100

## --- фронт ---

web-build:  ## пересобрать веб-сборку фронта (первый раз тянет ~1 ГБ образ Flutter)
	$(COMPOSE) build frontend

web-logs:  ## логи nginx с веб-сборкой
	$(COMPOSE) logs -f --tail=100 frontend

## --- бэкенд ---

sync:  ## поставить зависимости бэкенда
	cd backend && uv sync --all-groups

dev:  ## бэкенд локально с автоперезагрузкой
	cd backend && uv run uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload

lint:  ## ruff check + format --check по backend/src
	cd backend && ./scripts/lint.sh

format:  ## автоисправления и форматирование backend/src
	cd backend && ./scripts/format.sh

test: test-db-up  ## тестовая БД + pytest
	cd backend && uv run pytest

test-db-up:  ## только контейнер с тестовой БД
	$(COMPOSE_TEST) up -d --wait

test-db-down:  ## погасить тестовую БД
	$(COMPOSE_TEST) down

openapi-update:  ## пересобрать снимок контракта API (дифф показать в ревью)
	cd backend && UPDATE_OPENAPI_SNAPSHOT=1 uv run pytest tests/test_openapi_contract.py -q

## --- база знаний ---

vault-check:  ## проверить имена файлов vault на Windows-совместимость
	python ./scripts/check_windows_safe_filenames.py els-vault
