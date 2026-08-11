#!/usr/bin/env bash
set -euo pipefail
set -x

uv run ruff check src --fix
uv run ruff format src
