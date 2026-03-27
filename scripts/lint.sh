#!/usr/bin/env bash
set -euo pipefail
set -x

python3 -m ruff check src
python3 -m ruff format --check src
