"""
Загружает переменные из `.test.env` до импорта `src.config` / приложения.

Так Settings() один раз получает строку подключения к тестовой БД, а не значения из `.env`.
"""

from pathlib import Path

import pytest
from dotenv import load_dotenv

from src.config import settings

_BACKEND_ROOT = Path(__file__).resolve().parent.parent
_REPO_ROOT = _BACKEND_ROOT.parent

# `.test.env` может лежать и в корне монорепо, и рядом с бэкендом — забираем оба,
# корневой перебивает. Файла может не быть вовсе: тогда переменные задаются
# в окружении / CI (см. `backend/.test.env.example`).
for _env_file in (_BACKEND_ROOT / ".test.env", _REPO_ROOT / ".test.env"):
    load_dotenv(_env_file, override=True)


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
def migrated_test_db():
    """
    1) Прогоняет alembic миграции в ТЕСТОВУЮ БД.
    2) Заполняет справочники через create_initial_data().

    Использует текущую инфраструктуру:
    - Alembic берёт URL из `src/config.settings` (см. `alembic/env.py`)
    - Сидинг через `src/core/db/init_db.py:create_initial_data`
    """
    _assert_test_env_is_safe()

    from sqlalchemy import text
    from sqlalchemy.exc import OperationalError

    from src.session import engine

    # Если БД недоступна — просто скипаем интеграционные тесты, не падая на коллекции.
    try:
        with engine.connect() as conn:  # noqa: F841
            pass
    except OperationalError as exc:
        pytest.skip(f"Test database is not available: {exc}")

    # 1) Полная очистка тестовой БД (только public schema).
    # Это быстрее и надёжнее, чем пытаться удалять таблицы по одной.
    # После тестов базу НЕ трогаем, чтобы можно было посмотреть состояние.
    with engine.begin() as conn:
        conn.execute(text("DROP SCHEMA IF EXISTS public CASCADE"))
        conn.execute(text("CREATE SCHEMA public"))
        conn.execute(text("GRANT ALL ON SCHEMA public TO public"))

    from alembic import command
    from alembic.config import Config

    alembic_cfg = Config(str(_BACKEND_ROOT / "alembic.ini"))
    # Важно: `alembic/env.py` сам подставит `settings.DB_URL` в конфиг.
    command.upgrade(alembic_cfg, "head")

    from src.core.db.init_db import create_initial_data

    # 2) Наполнение тестовой БД начальными данными.
    create_initial_data()

    # После сидинга с "ручными id" нужно поднять sequences,
    # иначе следующий INSERT может попытаться снова выдать id=1/2/...
    from src.session import engine as _engine

    # Таблицы, которые сидятся "ручными id" и/или требуют корректного nextval().
    # Названия берём из `__tablename__` моделей.
    tables_to_fix_sequences = [
        "locations",
        "fault_category",
        "reason_fault",
        "roles",
        "statuses",
        "type_objects",
        "types_contracts",
        "types_acts",
        "cost_types",
    ]

    with _engine.begin() as conn:
        for table in tables_to_fix_sequences:
            # pg_get_serial_sequence возвращает NULL, если у колонки нет sequence.
            seq = conn.execute(
                text("SELECT pg_get_serial_sequence(:table, 'id')"),
                {"table": table},
            ).scalar()
            if not seq:
                continue

            # Имя таблицы нельзя передать параметром, но список выше — константа
            # в этом же файле, так что подстановка безопасна.
            max_id = conn.execute(
                text(f"SELECT COALESCE(MAX(id), 1) FROM {table}")  # noqa: S608
            ).scalar()
            conn.execute(
                text("SELECT setval(:seq, :value, true)"),
                {"seq": seq, "value": max_id},
            )
    return True


@pytest.fixture(scope="session")
def app():
    _assert_test_env_is_safe()
    from src.main import app as fastapi_app

    return fastapi_app


@pytest.fixture
def db_session(migrated_test_db):
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
        # Откат внешней транзакции стирает всё, что тест успел закоммитить внутри
        # savepoint'а. Каждый следующий тест видит ровно то состояние, которое
        # оставила сессионная фикстура: миграции + справочники, без чужих данных.
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
