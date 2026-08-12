from pathlib import Path
from typing import Any, Dict, List, Optional, Union

from pydantic import (
    AnyHttpUrl,
    BaseSettings,
    EmailStr,
    HttpUrl,
    root_validator,
    validator,
)

# `.env` ищем по абсолютному пути, а не относительно текущего каталога: в монорепо
# приложение запускают и из корня, и из `backend/`, и из контейнера. Оба варианта
# размещения файла рабочие, корневой перебивает бэкендовый.
_BACKEND_DIR = Path(__file__).resolve().parent.parent
_REPO_ROOT = _BACKEND_DIR.parent
_ENV_FILES = (_BACKEND_DIR / ".env", _REPO_ROOT / ".env")


class Settings(BaseSettings):
    MODE: str

    API_V1_STR: str = "/api/v1"
    APP_PORT: str = "8000"

    # Обязателен, дефолта нет намеренно. Раньше здесь стоял
    # `secrets.token_urlsafe(32)`: без переменной в `.env` ключ получался новый
    # на каждый рестарт процесса, все токены протухали молча, а в нескольких
    # воркерах uvicorn ключи были ещё и разные у каждого.
    SECRET_KEY: str

    DB_HOST: str
    DB_PORT: int
    DB_USER: str
    DB_PASS: str
    DB_NAME: str

    @property
    def DB_URL(self):
        return f"postgresql://{self.DB_USER}:{self.DB_PASS}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

    # Access живёт минутами: отозвать его нечем, поэтому единственная защита —
    # короткий срок. Долгую сессию держит refresh-токен, он лежит в базе и
    # гасится по требованию.
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Требований к составу пароля нет: длина защищает лучше, чем обязательная
    # цифра, а механику вводить пароль с телефона в машинном отделении.
    PASSWORD_MIN_LENGTH: int = 8

    # Защита от перебора. Состояние — в самой таблице пользователей, Redis в
    # проекте нет.
    LOGIN_MAX_FAILED_ATTEMPTS: int = 5
    LOGIN_LOCKOUT_MINUTES: int = 15

    SERVER_NAME: str = "default_server_name"
    SERVER_HOST: AnyHttpUrl = "http://localhost"
    BACKEND_CORS_ORIGINS: List = []

    @validator("BACKEND_CORS_ORIGINS", pre=True)
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> Union[List[str], str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)

    PROJECT_NAME: str = "ELS 🔥"
    SENTRY_DSN: Optional[HttpUrl] = None

    @validator("SENTRY_DSN", pre=True)
    def sentry_dsn_can_be_blank(cls, v: Optional[str]) -> Optional[str]:
        if v is None or len(v) == 0:
            return None
        return v

    SMTP_TLS: bool = True
    SMTP_PORT: Optional[int] = None
    SMTP_HOST: Optional[str] = None
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    EMAILS_FROM_EMAIL: Optional[EmailStr] = None
    EMAILS_FROM_NAME: Optional[str] = None

    @root_validator(pre=True)
    def set_email_from_name(cls, values: Dict[str, Any]) -> Dict[str, Any]:
        if "EMAILS_FROM_NAME" not in values or values["EMAILS_FROM_NAME"] is None:
            values["EMAILS_FROM_NAME"] = values.get("PROJECT_NAME", "ELS")
        return values

    EMAIL_RESET_TOKEN_EXPIRE_HOURS: int = 48
    EMAIL_TEMPLATES_DIR: str = "/app/app/email-templates/build"
    EMAILS_ENABLED: bool = False

    @validator("EMAILS_ENABLED", pre=True)
    def get_emails_enabled(cls, v: bool, values: Dict[str, Any]) -> bool:
        return bool(
            values.get("SMTP_HOST")
            and values.get("SMTP_PORT")
            and values.get("EMAILS_FROM_EMAIL")
        )

    EMAIL_TEST_USER: EmailStr = "test@example.com"  # type: ignore
    FIRST_SUPERUSER: EmailStr = "users@example.com"
    FIRST_SUPERUSER_PASSWORD: str = "supersecretpassword"
    USERS_OPEN_REGISTRATION: bool = False

    class Config:
        case_sensitive = True
        env_file = _ENV_FILES

        @classmethod
        def parse_env_var(cls, field_name: str, raw_val: str) -> Any:
            """Разбор переменных окружения для полей-контейнеров.

            Нужен из-за порядка работы pydantic 1.x: значения полей сложных
            типов (`List`, `Dict`) он сначала разбирает как JSON и только
            потом отдаёт валидаторам. Поэтому `assemble_cors_origins` выше,
            хоть и объявлен с `pre=True`, до переменной окружения не
            доходит — до него всё падает с
            `SettingsError: error parsing env var`.

            Из-за этого форма через запятую никогда не работала, хотя именно
            она была написана в README и в комментарии `main.py`. Прод лёг
            ровно на ней.

            Здесь принимаем обе: и JSON `["https://a","https://b"]`, и
            человеческую `https://a,https://b`.
            """
            if field_name == "BACKEND_CORS_ORIGINS":
                value = raw_val.strip()
                if not value:
                    return []
                if not value.startswith("["):
                    return [item.strip() for item in value.split(",") if item.strip()]
            return cls.json_loads(raw_val)


# Инициализация настроек
settings = Settings()
