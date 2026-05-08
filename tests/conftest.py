"""
Загружает переменные из `.test.env` до импорта `src.config` / приложения.

Так Settings() один раз получает строку подключения к тестовой БД, а не значения из `.env`.
"""

from pathlib import Path

import pytest
from dotenv import load_dotenv

from src.config import settings

_REPO_ROOT = Path(__file__).resolve().parent.parent
# Файла может не быть локально — тогда задаёте переменные в окружении / CI (см. .test.env.example).
load_dotenv(_REPO_ROOT / ".test.env", override=True)


def _assert_test_env_is_safe() -> None:
    # Минимальный предохранитель от случайного запуска тестов на боевой БД.
    if settings.MODE != "TEST":
        raise RuntimeError(
            "Refusing to run tests because MODE != TEST. "
            "Create `.test.env` (see `.test.env.example`) or set env vars in CI."
        )
    if "test" not in settings.DB_NAME.lower():
        raise RuntimeError(
            "Refusing to run tests because DB_NAME doesn't look like a test DB. "
            "Use a dedicated database (e.g. lift_test)."
        )


@pytest.fixture(scope="session")
def app():
    _assert_test_env_is_safe()
    from src.main import app as fastapi_app

    return fastapi_app


@pytest.fixture
def db_session():
    """
    Изолированная сессия БД на тест.

    В проекте CRUD делает `commit()` внутри методов, поэтому используем
    nested transaction (SAVEPOINT), чтобы любые commit'ы откатывались в конце теста.
    """
    from sqlalchemy import event

    from src.session import SessionLocal, engine

    _assert_test_env_is_safe()

    from sqlalchemy.exc import OperationalError

    try:
        connection = engine.connect()
    except OperationalError as exc:
        pytest.skip(f"Test database is not available: {exc}")
    transaction = connection.begin()
    session = SessionLocal(bind=connection)

    session.begin_nested()

    @event.listens_for(session, "after_transaction_end")
    def _restart_savepoint(sess, trans):  # noqa: ANN001
        if trans.nested and not trans._parent.nested:
            sess.begin_nested()

    try:
        yield session
    finally:
        session.close()
        transaction.rollback()
        connection.close()


@pytest.fixture
def client(app):
    from starlette.testclient import TestClient

    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def client_with_db(app, db_session):
    from starlette.testclient import TestClient

    from src.api import deps

    def _override_get_db():
        yield db_session

    app.dependency_overrides[deps.get_db] = _override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.pop(deps.get_db, None)
