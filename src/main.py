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

# Set all CORS enabled origins
origins = ["*"]
# if settings.BACKEND_CORS_ORIGINS:
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
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
    await init_db()
    logging.info("Initial data created.")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("src.main:app", host="0.0.0.0", port=8000, reload=True)

# Это очень важно, не удалять!
from .errors import *
