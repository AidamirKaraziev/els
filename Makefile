.PHONY: up lint format sync vault-check test test-db-up test-db-down

sync:
	uv sync --all-groups

up:
	uv run uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload

lint:
	./scripts/lint.sh

format:
	./scripts/format.sh

vault-check:
	python ./scripts/check_windows_safe_filenames.py els-vault

# Отдельная БД под pytest: см. docker-compose.test.yml
test-db-up:
	docker compose --env-file .test.env -f docker-compose.test.yml up -d --wait

test-db-down:
	docker compose --env-file .test.env -f docker-compose.test.yml down

test: test-db-up
	uv run pytest
