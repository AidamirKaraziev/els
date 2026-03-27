#!/usr/bin/env bash
set -euo pipefail
set -x

python3 -m ruff check src --fix
python3 -m ruff format src
