import logging

from fastapi import FastAPI
from starlette.middleware.cors import CORSMiddleware

from src.api.api_v1.api import api_router
from src.config import settings
from src.core.db.init_db import create_initial_data
from src.session import SessionLocal

app = FastAPI(
    title=settings.PROJECT_NAME, openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Список доменов задаётся переменной BACKEND_CORS_ORIGINS в .env, например:
#   BACKEND_CORS_ORIGINS=https://els.example.ru,https://admin.els.example.ru
# Годится и JSON: ["https://els.example.ru"]. Обе формы разбирает
# `Config.parse_env_var` в config.py — форма через запятую до него не
# работала вовсе и однажды уронила прод на старте.
#
# Переменная существовала в конфиге и раньше, но не читалась: здесь был
# зашитый `["*"]`. Пустое значение сохраняет прежнее поведение, чтобы прод
# не отвалился при обновлении, — но в проде её нужно заполнить.
#
# `allow_credentials=True` вместе с `*` браузеры игнорируют: спецификация
# запрещает такую комбинацию. Поэтому пока список пуст, credentials выключены —
# так поведение честно совпадает с тем, что реально делает браузер.
origins = settings.BACKEND_CORS_ORIGINS or ["*"]
allow_credentials = bool(settings.BACKEND_CORS_ORIGINS)

if not settings.BACKEND_CORS_ORIGINS:
    logging.warning(
        "BACKEND_CORS_ORIGINS не задан: API открыт для любого домена. "
        "Задайте список доменов в .env."
    )

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)


# Функция для создания начальных данных
async def init_db() -> None:
    db = SessionLocal()
    try:
        create_initial_data()
    finally:
        db.close()


# Событие, которое будет выполняться при запуске приложения
@app.on_event("startup")
async def startup_event() -> None:
    logging.info("Starting application...")
    if settings.MODE != "TEST":
        await init_db()
        logging.info("Initial data created.")
    else:
        logging.info("TEST mode: skipping initial data creation.")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("src.main:app", host="0.0.0.0", port=8000, reload=True)

# Это очень важно, не удалять!
from src.errors import *
