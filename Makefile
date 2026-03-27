.PHONY: up lint format sync

sync:
	uv sync --all-groups

up:
	uv run uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload

lint:
	./scripts/lint.sh

format:
	./scripts/format.sh
