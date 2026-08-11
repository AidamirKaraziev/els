# Единая точка входа монорепо. Все цели запускаются из корня репозитория.
#
# backend/  — FastAPI, свои зависимости (uv) и свои тесты
# frontend/ — появится вместе с кодом фронта
# infra/    — docker compose для всего стека
# els-vault/— база знаний проекта (Obsidian)

.PHONY: help up down logs ps sync dev lint format test test-db-up test-db-down \
        web-build web-logs vault-check release build migrate migrate-status \
        openapi-update prod-deploy prod-ps prod-logs prod-down prod-nginx \
        cert-staging cert-issue cert-renew cert-renew-dry cert-info

# Пути внутри compose-файлов относительны корня, поэтому --project-directory .
COMPOSE := docker compose --project-directory . -f infra/docker-compose.yml
COMPOSE_TEST := docker compose --project-directory . --env-file .test.env -f infra/docker-compose.test.yml
COMPOSE_PROD := docker compose --project-directory . -f infra/docker-compose.prod.yml

help:
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

## --- выкатка ---

# Одна команда на весь цикл: собрать новые образы фронта и бэка, поднять их,
# накатить миграции и убедиться, что после этого система отвечает.
#
# Миграции запускает сам контейнер бэкенда — `prestart.sh` делает
# `alembic upgrade head` до старта uvicorn. Отдельного шага здесь нет
# намеренно: иначе на проде миграции накатывались бы дважды, из Makefile и
# из контейнера. Роль `release` в другом — дождаться результата и не
# отрапортовать успех, если бэкенд не поднялся.
release:  ## собрать фронт и бэк, накатить миграции, дождаться готовности
	@echo "==> Сборка образов"
	$(COMPOSE) build backend frontend
	@echo
	@echo "==> Запуск и миграции (prestart.sh -> alembic upgrade head)"
	@$(COMPOSE) up -d --wait || { \
		echo; \
		echo "!!! Стек не поднялся. Последние строки лога бэкенда:"; \
		echo; \
		$(COMPOSE) logs --tail=60 backend; \
		echo; \
		echo "Чаще всего это упавшая миграция. База не тронута:"; \
		echo "alembic накатывает ревизии по одной в транзакции."; \
		exit 1; \
	}
	@echo
	@echo "==> Накатанная ревизия БД"
	@$(COMPOSE) exec -T backend alembic current
	@echo
	@echo "  Веб:     http://localhost:$${WEB_PORT:-8080}"
	@echo "  API:     http://localhost:$${WEB_PORT:-8080}/api/v1"
	@echo "  Swagger: http://localhost:$${WEB_PORT:-8080}/docs"

build:  ## только пересобрать образы фронта и бэка, не трогая запущенный стек
	$(COMPOSE) build backend frontend

## --- прод (запускать НА СЕРВЕРЕ) ---

# Ничего не собирает: образы приезжают из ghcr.io готовыми, их собрал CI.
# На машине с 1 ГБ памяти собрать фронт всё равно нельзя — dart2js упадёт по OOM.
prod-deploy:  ## на сервере: забрать новые образы, накатить миграции, дождаться
	@echo "==> Скачивание образов"
	$(COMPOSE_PROD) pull
	@echo
	@echo "==> Запуск и миграции (prestart.sh -> alembic upgrade head)"
	@$(COMPOSE_PROD) up -d --wait || { \
		echo; \
		echo "!!! Стек не поднялся. Последние строки лога бэкенда:"; \
		echo; \
		$(COMPOSE_PROD) logs --tail=60 backend; \
		echo; \
		echo "Откатиться на прошлую сборку:"; \
		echo "  IMAGE_TAG=sha-<хеш коммита> make prod-deploy"; \
		exit 1; \
	}
	@echo
	@echo "==> Накатанная ревизия БД"
	@$(COMPOSE_PROD) exec -T backend alembic current
	@echo
	@$(COMPOSE_PROD) images

## --- сертификат Let's Encrypt (запускать НА СЕРВЕРЕ) ---

# Домены и почта. Почта нужна один раз, при первом выпуске: на неё приходит
# предупреждение, если автопродление сломалось и сертификат скоро истечёт.
# Это единственный сигнал о поломке, поэтому адрес обязателен.
CERT_DOMAIN ?= els23.ru
CERT_DOMAIN_WWW ?= www.els23.ru

_CERTBOT_ARGS = certonly --webroot -w /var/www/certbot \
	-d $(CERT_DOMAIN) -d $(CERT_DOMAIN_WWW) \
	--email "$(CERTBOT_EMAIL)" --agree-tos --no-eff-email

_require_email = @if [ -z "$(CERTBOT_EMAIL)" ]; then \
		echo "Нужна почта для Let's Encrypt:"; \
		echo "  CERTBOT_EMAIL=you@example.com make $@"; \
		exit 1; \
	fi

cert-staging:  ## пробный выпуск на тестовом сервере LE (не тратит лимиты)
	$(call _require_email)
	$(COMPOSE_PROD) run --rm certbot $(_CERTBOT_ARGS) --staging
	@echo
	@echo "Проверка прошла. Теперь боевой выпуск: make cert-issue"
	@echo "Тестовый сертификат сначала удалить:"
	@echo "  $(COMPOSE_PROD) run --rm certbot delete --cert-name $(CERT_DOMAIN)"

cert-issue:  ## боевой выпуск сертификата
	$(call _require_email)
	$(COMPOSE_PROD) run --rm certbot $(_CERTBOT_ARGS)
	@$(MAKE) --no-print-directory cert-info

cert-renew:  ## продлить сертификат и перезагрузить nginx (для cron)
	$(COMPOSE_PROD) run --rm certbot renew
	@$(COMPOSE_PROD) exec -T frontend nginx -s reload || true

cert-renew-dry:  ## прогнать продление вхолостую, не дожидаясь трёх месяцев
	$(COMPOSE_PROD) run --rm certbot renew --dry-run

cert-info:  ## что за сертификаты выпущены и до какого числа
	$(COMPOSE_PROD) run --rm certbot certificates

prod-nginx:  ## применить правку конфига nginx на проде
	# Пересоздание, а не `restart`: nginx.conf примонтирован как отдельный
	# файл, docker держит его по inode, а `git pull` записывает файл заново.
	# После перезапуска контейнер видел бы старое содержимое.
	$(COMPOSE_PROD) up -d --force-recreate frontend
	@$(COMPOSE_PROD) exec -T frontend nginx -t

prod-ps:  ## что запущено на проде
	$(COMPOSE_PROD) ps

prod-logs:  ## логи прод-стека
	$(COMPOSE_PROD) logs -f --tail=100

prod-down:  ## погасить прод-стек (данные в volume остаются)
	$(COMPOSE_PROD) down

## --- миграции ---

migrate:  ## накатить миграции отдельно (стек поднимать не обязательно)
	$(COMPOSE) run --rm backend alembic upgrade head

migrate-status:  ## какая ревизия alembic сейчас в базе
	$(COMPOSE) run --rm backend alembic current

## --- стек целиком ---

up:  ## поднять весь стек в docker (веб на http://localhost:8080)
	$(COMPOSE) up -d --build
	@echo
	@echo "  Веб:     http://localhost:$${WEB_PORT:-8080}"
	@echo "  API:     http://localhost:$${WEB_PORT:-8080}/api/v1"
	@echo "  Swagger: http://localhost:$${WEB_PORT:-8080}/docs"

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
