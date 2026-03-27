.PHONY: up lint format

up:
	uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload

lint:
	python3 -m ruff check src
	python3 -m ruff format --check src

format:
	python3 -m ruff check src --fix
	python3 -m ruff format src
