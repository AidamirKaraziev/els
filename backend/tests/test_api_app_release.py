"""Раздача APK механикам: `/app/release`, `/app/link`, `/app/download`.

Проверяется не «ручка отвечает 200», а три вещи, каждая из которых уже была
источником дыры в этом проекте:

* **без входа файл не отдаётся** — ради этого раздачу и завели под логином;
* **манифест не может увести чтение за пределы каталога** — поле `file`
  пишет человек, и опечатка вида `../../.env` не должна работать;
* **ссылка привязана к своему адресу** — токен на скачивание приложения не
  открывает ничего другого.
"""

import json

import pytest

from src.config import settings
from src.core import app_release as release_module
from src.core.roles import Role

RELEASE_URL = f"{settings.API_V1_STR}/app/release"
LINK_URL = f"{settings.API_V1_STR}/app/link"
DOWNLOAD_URL = f"{settings.API_V1_STR}/app/download"

APK_BYTES = b"PK\x03\x04 not really an apk, but the bytes travel the same way"


@pytest.fixture
def release_dir(tmp_path, monkeypatch):
    """Подменяет каталог со сборкой на временный.

    Настоящий `static/app/` трогать нельзя: тесты гоняются и на машине
    разработчика, где рядом лежат живые загрузки.
    """
    directory = tmp_path / "app"
    directory.mkdir()
    monkeypatch.setattr(release_module, "RELEASE_DIR", directory)
    return directory


@pytest.fixture
def published(release_dir):
    """Выложенная сборка: файл и манифест рядом."""
    (release_dir / "els-1.0.0.apk").write_bytes(APK_BYTES)
    (release_dir / "release.json").write_text(
        json.dumps(
            {
                "versionName": "1.0.0",
                "versionCode": 1,
                "file": "els-1.0.0.apk",
                "sha256": "9f3c",
                "publishedAt": "2026-09-07",
                "notes": "Первая сборка",
            }
        ),
        encoding="utf-8",
    )
    return release_dir


def test_release_requires_login(client_with_db, published):
    """Без токена — отказ, а не сведения о сборке."""
    assert client_with_db.get(RELEASE_URL).status_code == 401


def test_download_requires_login(client_with_db, published):
    assert client_with_db.get(DOWNLOAD_URL).status_code == 401


def test_release_tells_what_is_published(client_with_db, as_role, published):
    as_role(Role.MECHANIC)

    response = client_with_db.get(RELEASE_URL)

    assert response.status_code == 200
    data = response.json()["data"]
    assert data["version_name"] == "1.0.0"
    assert data["version_code"] == 1
    assert data["size"] == len(APK_BYTES)
    assert data["notes"] == "Первая сборка"


def test_release_is_404_until_apk_is_uploaded(client_with_db, as_role, release_dir):
    """До первого выката это нормальное состояние, а не поломка."""
    as_role(Role.MECHANIC)

    assert client_with_db.get(RELEASE_URL).status_code == 404


def test_manifest_without_its_file_is_not_published(
    client_with_db, as_role, release_dir
):
    """Выкат оборвался на полпути: манифест лёг, APK — нет."""
    (release_dir / "release.json").write_text(
        json.dumps({"versionName": "1.0.0", "versionCode": 1, "file": "els-1.0.0.apk"}),
        encoding="utf-8",
    )
    as_role(Role.MECHANIC)

    assert client_with_db.get(RELEASE_URL).status_code == 404


def test_broken_manifest_does_not_crash(client_with_db, as_role, release_dir):
    (release_dir / "release.json").write_text("{ это не json", encoding="utf-8")
    as_role(Role.MECHANIC)

    assert client_with_db.get(RELEASE_URL).status_code == 404


@pytest.mark.parametrize(
    "file_name",
    [
        "../../.env",
        "/etc/passwd",
        "..",
        "",
    ],
)
def test_manifest_cannot_point_outside_the_directory(
    client_with_db, as_role, release_dir, file_name
):
    """Поле `file` пишет человек — путь в нём не должен работать."""
    (release_dir / "release.json").write_text(
        json.dumps({"versionName": "1.0.0", "versionCode": 1, "file": file_name}),
        encoding="utf-8",
    )
    as_role(Role.MECHANIC)

    assert client_with_db.get(RELEASE_URL).status_code == 404
    assert client_with_db.get(DOWNLOAD_URL).status_code == 404


def test_download_gives_the_file(client_with_db, as_role, published):
    as_role(Role.MECHANIC)

    response = client_with_db.get(DOWNLOAD_URL)

    assert response.status_code == 200
    assert response.content == APK_BYTES
    assert response.headers["content-type"] == "application/vnd.android.package-archive"
    # Иначе телефон сохранит файл как «download» без расширения и не
    # предложит его поставить.
    assert "els-1.0.0.apk" in response.headers["content-disposition"]


def test_link_opens_the_download(client_with_db, as_role, published):
    """Ссылка из `/app/link` работает без заголовка `Authorization`."""
    from src.api import deps

    user = as_role(Role.MECHANIC)

    link = client_with_db.post(LINK_URL).json()["data"]
    assert link["expires_in"] == settings.FILE_TOKEN_EXPIRE_SECONDS
    token = link["url"].split("token=")[1]

    # Снимаем подмену опознания по ссылке: проверяем именно токен, а не
    # фикстуру, которая иначе пустила бы кого угодно.
    client_with_db.app.dependency_overrides.pop(deps.get_link_requester, None)

    response = client_with_db.get(DOWNLOAD_URL, params={"token": token})

    assert response.status_code == 200
    assert response.content == APK_BYTES
    assert user is not None


def test_token_does_not_open_other_paths(client_with_db, as_role, published):
    """Утёкшая ссылка открывает APK, а не остальное API."""
    from src.api import deps

    as_role(Role.MECHANIC)
    token = client_with_db.post(LINK_URL).json()["data"]["url"].split("token=")[1]

    client_with_db.app.dependency_overrides.pop(deps.get_link_requester, None)

    other = client_with_db.get(
        f"{settings.API_V1_STR}/static/objects/1/act_pto/whatever.pdf",
        params={"token": token},
    )
    assert other.status_code == 401


def test_link_is_not_issued_when_nothing_is_published(
    client_with_db, as_role, release_dir
):
    """Иначе человек получил бы ссылку, которая через минуту молча умрёт."""
    as_role(Role.MECHANIC)

    assert client_with_db.post(LINK_URL).status_code == 404
