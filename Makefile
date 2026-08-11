.PHONY: up lint format sync vault-check

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
