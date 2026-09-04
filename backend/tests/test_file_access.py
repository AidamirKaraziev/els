"""Файлы: путь наружу, токен и доступ к чужому файлу.

До этого `/static/{filename:path}` был открыт вообще без токена и склеивал
путь как `"static/" + filename`. Через него отдавались фото заявок, дефектные
акты и сканы удостоверений — то есть персональные данные без всякой проверки,
а `../` уводил чтение за пределы каталога загрузок.
"""

import datetime
import itertools
import uuid
from pathlib import Path

import pytest

from src.config import settings
from src.core.files import parse_owner, resolve_static_path
from src.core.roles import Role
from src.core.security import create_access_token, create_file_token
from src.models import Company, Division, Object, Order

API = settings.API_V1_STR


# --- разбор пути (без базы и HTTP) ----------------------------------------


@pytest.mark.parametrize(
    "filename",
    [
        "../.env",
        "../../etc/passwd",
        "/etc/passwd",
        "",
    ],
)
def test_path_outside_static_is_refused(filename):
    """Раньше такой путь честно читался и отдавался."""
    assert resolve_static_path(filename) is None


def test_normal_path_resolves_inside_static():
    resolved = resolve_static_path("objects/12/act_pto/file.pdf")

    assert resolved is not None
    assert Path("static").resolve() in resolved.path.parents
    assert resolved.relative == "objects/12/act_pto/file.pdf"


def test_static_root_itself_is_not_a_file():
    assert resolve_static_path(".") is None


def test_owner_is_read_from_the_resolved_path():
    """Строка пути и файл, который будет прочитан, — не одно и то же.

    `objects/1/act_pto/../../../.env` за пределы `static/` не выходит, поэтому
    отказать по корню нельзя. Но по строке он выглядит как файл объекта №1,
    а ведёт на `static/.env`. Владельца поэтому определяем по раскрытому пути.
    """
    resolved = resolve_static_path("objects/1/act_pto/../../../.env")

    assert resolved.relative == ".env"
    assert parse_owner(resolved.relative) is None


@pytest.mark.parametrize(
    "filename, entity, record_id",
    [
        ("objects/12/act_pto/a.pdf", "objects", 12),
        ("order_photo/5/photo/b.jpg", "order_photo", 5),
        ("universal_user/3/identity_card/c.png", "universal_user", 3),
    ],
)
def test_owner_is_read_from_the_path(filename, entity, record_id):
    owner = parse_owner(filename)

    assert (owner.entity, owner.record_id) == (entity, record_id)


@pytest.mark.parametrize(
    "filename",
    ["justafile.png", "objects/abc/act_pto/a.pdf", "objects/12", ""],
)
def test_unknown_path_shape_has_no_owner(filename):
    """Форма пути не та — значит отказ, а не «файл ничей»."""
    assert parse_owner(filename) is None


# --- ручка отдачи файла ----------------------------------------------------


@pytest.fixture
def world(db_session):
    """Лифт своей компании и лифт чужой, с заявками на каждом."""
    prefix = uuid.uuid4().hex[:8]
    counter = itertools.count(1)

    def make_object(**kwargs):
        number = next(counter)
        obj = Object(
            name=f"Лифт {number}",
            factory_number=f"F-{prefix}-{number}",
            registration_number=f"R-{prefix}-{number}",
            **kwargs,
        )
        db_session.add(obj)
        db_session.flush()
        return obj

    division = Division(title=f"Участок {prefix}")
    company_mine = Company(name=f"Моя {prefix}")
    company_other = Company(name=f"Чужая {prefix}")
    db_session.add_all([division, company_mine, company_other])
    db_session.flush()

    own_lift = make_object(division_id=division.id, company_id=company_mine.id)
    other_lift = make_object(division_id=division.id, company_id=company_other.id)

    own_order = Order(
        object_id=own_lift.id,
        creator_id=1,
        created_at=datetime.datetime(2026, 5, 10),
        task_text="своя",
    )
    db_session.add(own_order)
    db_session.flush()

    return {
        "company_mine": company_mine,
        "own_lift": own_lift,
        "other_lift": other_lift,
        "own_order": own_order,
    }


@pytest.fixture
def uploaded_file(tmp_path_factory):
    """Кладёт настоящий файл в `static/` и убирает его за собой."""
    created = []

    def _put(relative_path: str, content: bytes = b"%PDF-1.4 test") -> str:
        target = Path("static") / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)
        created.append(target)
        return relative_path

    yield _put

    for path in created:
        path.unlink(missing_ok=True)


@pytest.mark.integration
def test_file_without_any_token_is_refused(client_with_db, uploaded_file, world):
    """Ровно то, ради чего этап и делался: раньше здесь отдавался файл."""
    path = uploaded_file(f"objects/{world['own_lift'].id}/act_pto/x.pdf")

    response = client_with_db.get(f"{API}/static/{path}")

    assert response.status_code == 401


@pytest.mark.integration
def test_owner_of_the_record_gets_the_file(
    client_with_db, as_role, uploaded_file, world
):
    as_role(Role.CLIENT, company_id=world["company_mine"].id)
    path = uploaded_file(f"objects/{world['own_lift'].id}/act_pto/x.pdf")

    response = client_with_db.get(f"{API}/static/{path}")

    assert response.status_code == 200
    assert response.content == b"%PDF-1.4 test"


@pytest.mark.integration
def test_file_of_a_foreign_record_answers_403(
    client_with_db, as_role, uploaded_file, world
):
    as_role(Role.CLIENT, company_id=world["company_mine"].id)
    path = uploaded_file(f"objects/{world['other_lift'].id}/act_pto/x.pdf")

    response = client_with_db.get(f"{API}/static/{path}")

    assert response.status_code == 403


@pytest.mark.integration
def test_file_laid_outside_the_known_layout_is_refused(
    client_with_db, as_role, uploaded_file
):
    """Файл не по форме `<сущность>/<id>/<вид>/<имя>` не отдаётся никому."""
    as_role(Role.ADMIN)
    path = uploaded_file("strange/place/file.pdf")

    assert client_with_db.get(f"{API}/static/{path}").status_code == 403


@pytest.mark.integration
def test_own_identity_card_is_always_available(client_with_db, as_role, uploaded_file):
    """Механик без назначений всё равно должен видеть своё удостоверение."""
    user = as_role(Role.MECHANIC)
    path = uploaded_file(f"universal_user/{user.id}/identity_card/x.png")

    assert client_with_db.get(f"{API}/static/{path}").status_code == 200


@pytest.mark.integration
def test_missing_file_is_404_not_403(client_with_db, as_role, world):
    as_role(Role.ADMIN)

    response = client_with_db.get(f"{API}/static/objects/1/act_pto/nothing-here.pdf")

    assert response.status_code == 404


# --- короткоживущая ссылка -------------------------------------------------


@pytest.fixture
def real_admin(db_session):
    """Настоящий пользователь в базе, без подмены опознания.

    `as_role` подменяет саму зависимость, которая разбирает токен, — под ней
    проверять токен нечем: он просто не участвует в запросе.
    """
    from src.models import UniversalUser

    user = UniversalUser(
        name="Админ для токенов",
        email=f"token-{uuid.uuid4().hex[:8]}@test",
        role_id=int(Role.ADMIN),
        is_active=True,
    )
    db_session.add(user)
    db_session.flush()
    return user


@pytest.mark.integration
def test_link_opens_the_file_without_a_header(
    client_with_db, real_admin, uploaded_file, world
):
    """Ради этого ссылка и существует: заголовок в `<img src>` не отправить."""
    path = uploaded_file(f"objects/{world['own_lift'].id}/act_pto/x.pdf")

    token = create_file_token(user_id=real_admin.id, path=f"{API}/static/{path}")
    response = client_with_db.get(f"{API}/static/{path}", params={"token": token})

    assert response.status_code == 200


@pytest.mark.integration
def test_link_issued_for_another_file_does_not_work(
    client_with_db, real_admin, uploaded_file, world
):
    """Одна выданная ссылка не должна открывать весь каталог."""
    mine = uploaded_file(f"objects/{world['own_lift'].id}/act_pto/mine.pdf")
    other = uploaded_file(f"objects/{world['other_lift'].id}/act_pto/other.pdf")

    token = create_file_token(user_id=real_admin.id, path=f"{API}/static/{mine}")
    response = client_with_db.get(f"{API}/static/{other}", params={"token": token})

    assert response.status_code == 401


@pytest.mark.integration
def test_access_token_is_not_accepted_in_the_query(
    client_with_db, real_admin, uploaded_file, world
):
    """Иначе боевой токен светился бы в журнале nginx и в истории браузера."""
    path = uploaded_file(f"objects/{world['own_lift'].id}/act_pto/x.pdf")

    access = create_access_token(user_id=real_admin.id)
    response = client_with_db.get(f"{API}/static/{path}", params={"token": access})

    assert response.status_code == 401


@pytest.mark.integration
def test_link_is_not_issued_for_a_foreign_file(
    client_with_db, as_role, uploaded_file, world
):
    as_role(Role.CLIENT, company_id=world["company_mine"].id)
    path = uploaded_file(f"objects/{world['other_lift'].id}/act_pto/x.pdf")

    response = client_with_db.post(f"{API}/files/link", json={"path": path})

    assert response.status_code == 403


@pytest.mark.integration
def test_link_for_own_file_is_ready_to_open(
    client_with_db, as_role, uploaded_file, world
):
    as_role(Role.CLIENT, company_id=world["company_mine"].id)
    path = uploaded_file(f"objects/{world['own_lift'].id}/act_pto/x.pdf")

    body = client_with_db.post(f"{API}/files/link", json={"path": path}).json()["data"]

    assert path in body["url"]
    assert "token=" in body["url"]
    assert body["expires_in"] == settings.FILE_TOKEN_EXPIRE_SECONDS


@pytest.mark.integration
def test_export_link_only_signs_known_exports(client_with_db, as_role):
    """Подписывать произвольный адрес нельзя — иначе это токен ко всему API."""
    as_role(Role.ADMIN)

    ok = client_with_db.post(
        f"{API}/files/export-link",
        json={"export": "breakdowns", "params": {"year": "2026", "month": "5"}},
    )
    bad = client_with_db.post(
        f"{API}/files/export-link", json={"export": "/api/v1/cp/all-users/"}
    )

    assert ok.status_code == 200
    assert bad.status_code == 404


@pytest.mark.integration
def test_export_link_actually_downloads_the_report(client_with_db, real_admin):
    """Кнопка «Скачать» на экране статистики держится ровно на этом."""
    token = create_file_token(
        user_id=real_admin.id, path=f"{API}/statistics/breakdowns/export"
    )
    response = client_with_db.get(
        f"{API}/statistics/breakdowns/export",
        params={"year": 2026, "month": 5, "token": token},
    )

    assert response.status_code == 200
    assert response.content[:4] == b"%PDF"


# --- отдача через nginx ----------------------------------------------------


@pytest.fixture
def x_accel(monkeypatch):
    """Включает отдачу файлов заголовком, как на собранном стеке."""
    monkeypatch.setattr(settings, "X_ACCEL_REDIRECT", True)


@pytest.mark.integration
def test_x_accel_answers_with_a_header_instead_of_bytes(
    client_with_db, as_role, uploaded_file, world, x_accel
):
    as_role(Role.CLIENT, company_id=world["company_mine"].id)
    path = uploaded_file(f"objects/{world['own_lift'].id}/act_pto/x.pdf")

    response = client_with_db.get(f"{API}/static/{path}")

    assert response.status_code == 200
    assert response.content == b""
    assert response.headers["X-Accel-Redirect"] == f"/internal-static/{path}"
    assert response.headers["content-type"] == "application/pdf"


@pytest.mark.integration
def test_x_accel_encodes_cyrillic_names(
    client_with_db, as_role, uploaded_file, world, x_accel
):
    """В заголовок можно положить только latin-1, а имена бывают русскими."""
    as_role(Role.CLIENT, company_id=world["company_mine"].id)
    path = uploaded_file(f"objects/{world['own_lift'].id}/act_pto/акт.pdf")

    response = client_with_db.get(f"{API}/static/{path}")

    assert response.status_code == 200
    header = response.headers["X-Accel-Redirect"]
    assert header.startswith("/internal-static/")
    assert header.endswith("%D0%B0%D0%BA%D1%82.pdf")


@pytest.mark.integration
def test_x_accel_does_not_bypass_the_access_check(
    client_with_db, as_role, uploaded_file, world, x_accel
):
    """Заголовок выдаётся только после проверки: чужой файл — по-прежнему 403."""
    as_role(Role.CLIENT, company_id=world["company_mine"].id)
    path = uploaded_file(f"objects/{world['other_lift'].id}/act_pto/x.pdf")

    response = client_with_db.get(f"{API}/static/{path}")

    assert response.status_code == 403
    assert "X-Accel-Redirect" not in response.headers
