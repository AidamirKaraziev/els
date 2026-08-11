FROM python:3.8-slim-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

COPY . /app

ENV PATH="/app/.venv/bin:$PATH"

COPY prestart.sh /prestart.sh
RUN chmod +x /prestart.sh

CMD ["sh", "-c", "/prestart.sh && uvicorn src.main:app --host 0.0.0.0 --port 8000 ${UVICORN_RELOAD}"]
