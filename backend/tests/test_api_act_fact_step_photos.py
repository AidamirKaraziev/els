"""Фотографии шагов ТО: отдельная таблица вместо байтов внутри чек-листа.

Раньше мобильное приложение клало снимок массивом байтов прямо в текстовое
поле `acts_fact.step_list_fact`. Строка акта разрасталась до сотен килобайт,
список ТО не открывался с телефона, а сослаться на снимок было нечем.

Теперь снимок — строка отдельной таблицы: файл на диске, в базе путь, привязка
к номеру шага из канонического чек-листа.
"""

import io
import json
import shutil
import uuid
from pathlib import Path

import pytest

from src.config import settings
from src.core.roles import Role
from src.models import ActFact, ActFactStepPhoto, Object
from src.services.checklist import to_canonical

PNG = b"\x89PNG\r\n\x1a\n" + b"0" * 32


def _checklist(*titles):
    """Чек-лист в канонической форме — той, в какой акт и лежит в базе."""
    return to_canonical(
        json.dumps(
            {
                "numberTo": "ТО-1",
                "stepListTO": json.dumps(
                    [{"text": title, "bool": False} for title in titles],
                    ensure_ascii=False,
                ),
            },
            ensure_ascii=False,
        )
    )


@pytest.fixture
def me(as_role):
    return as_role(Role.MECHANIC.value)


@pytest.fixture
def act(db_session, me):
    """ТО, назначенное на механика: он привязан к акту через `main_mechanic_id`."""
    suffix = uuid.uuid4().hex[:8]
    obj = Object(
        name="Лифт со снимками",
        factory_number=f"F-{suffix}",
        registration_number=f"R-{suffix}",
        mechanic_id=me.id,
    )
    db_session.add(obj)
    db_session.flush()

    act_fact = ActFact(
        object_id=obj.id,
        main_mechanic_id=me.id,
        step_list_fact=_checklist("Осмотр станции", "Проверить тормоз"),
    )
    db_session.add(act_fact)
    db_session.flush()
    return act_fact


@pytest.fixture
def uploaded_files():
    """Убирает за тестом каталоги, которые ручка создаёт на диске."""
    created = []
    yield created
    for folder in created:
        shutil.rmtree(folder, ignore_errors=True)


def _upload(client, act_id, step_id, uploaded_files, content=PNG):
    uploaded_files.append(Path("static") / "act_fact_step_photo" / str(act_id))
    return client.post(
        f"{settings.API_V1_STR}/act-fact/{act_id}/step/{step_id}/photo/",
        files={"file": ("шаг.png", io.BytesIO(content), "image/png")},
    )


def _photos(client, act_id, **params):
    return client.get(
        f"{settings.API_V1_STR}/act-fact/{act_id}/photos/", params=params
    )


@pytest.mark.integration
def test_photo_of_a_step_is_saved_and_listed(
    client_with_db, act, uploaded_files
):
    response = _upload(client_with_db, act.id, 1, uploaded_files)

    assert response.status_code == 200, response.text
    saved = response.json()["data"]
    assert saved["act_fact_id"] == act.id
    assert saved["step_id"] == 1

    listed = _photos(client_with_db, act.id).json()["data"]
    assert [photo["id"] for photo in listed] == [saved["id"]]


@pytest.mark.integration
def test_file_lands_on_disk_and_the_base_keeps_only_the_path(
    client_with_db, act, db_session, uploaded_files
):
    """В базе относительный путь: адрес сервера меняется, а снимки нет."""
    _upload(client_with_db, act.id, 1, uploaded_files)

    photo = (
        db_session.query(ActFactStepPhoto)
        .filter(ActFactStepPhoto.act_fact_id == act.id)
        .one()
    )
    assert photo.photo.startswith(f"act_fact_step_photo/{act.id}/photo/")
    assert (Path("static") / photo.photo).read_bytes() == PNG


@pytest.mark.integration
def test_link_goes_out_with_the_host_and_not_the_bare_path(
    client_with_db, act, uploaded_files
):
    photo = _upload(client_with_db, act.id, 1, uploaded_files).json()["data"]["photo"]

    assert f"{settings.API_V1_STR}/static/act_fact_step_photo/" in photo


@pytest.mark.integration
def test_photos_of_one_step_can_be_asked_for_separately(
    client_with_db, act, uploaded_files
):
    """Экран шага не должен выкачивать фотографии всего регламента."""
    _upload(client_with_db, act.id, 1, uploaded_files)
    second = _upload(client_with_db, act.id, 2, uploaded_files).json()["data"]

    listed = _photos(client_with_db, act.id, step_id=2).json()["data"]

    assert [photo["id"] for photo in listed] == [second["id"]]


@pytest.mark.integration
def test_step_outside_the_checklist_is_refused(client_with_db, act, uploaded_files):
    """Снимок без пункта регламента негде показать и нечем найти."""
    response = _upload(client_with_db, act.id, 99, uploaded_files)

    assert response.status_code == 404, response.text


@pytest.mark.integration
def test_upload_without_a_file_says_so(client_with_db, act):
    response = client_with_db.post(
        f"{settings.API_V1_STR}/act-fact/{act.id}/step/1/photo/"
    )

    assert response.status_code >= 400


@pytest.mark.integration
def test_someone_elses_act_is_not_available(
    client_with_db, act, db_session, as_role, uploaded_files
):
    """Область видимости: чужое ТО механик не видит и снимок к нему не приложит."""
    stranger = as_role(Role.MECHANIC.value)
    assert stranger.id != act.main_mechanic_id

    assert _upload(client_with_db, act.id, 1, uploaded_files).status_code >= 400
    assert _photos(client_with_db, act.id).status_code >= 400


@pytest.mark.integration
def test_deleting_removes_the_row_but_keeps_the_file(
    client_with_db, act, db_session, uploaded_files
):
    """Файл на диске остаётся — так же, как у фотографий заявок."""
    saved = _upload(client_with_db, act.id, 1, uploaded_files).json()["data"]
    on_disk = Path("static") / db_session.query(ActFactStepPhoto).get(saved["id"]).photo

    response = client_with_db.delete(
        f"{settings.API_V1_STR}/act-fact-photo/{saved['id']}/"
    )

    assert response.status_code == 200, response.text
    assert _photos(client_with_db, act.id).json()["data"] == []
    assert on_disk.exists()


@pytest.mark.integration
def test_stranger_cannot_delete_a_photo_of_someone_elses_act(
    client_with_db, act, as_role, uploaded_files
):
    saved = _upload(client_with_db, act.id, 1, uploaded_files).json()["data"]
    as_role(Role.MECHANIC.value)

    response = client_with_db.delete(
        f"{settings.API_V1_STR}/act-fact-photo/{saved['id']}/"
    )

    assert response.status_code >= 400


@pytest.mark.integration
def test_client_cannot_upload_at_all(client_with_db, act, as_role, uploaded_files):
    as_role(Role.CLIENT.value)

    assert _upload(client_with_db, act.id, 1, uploaded_files).status_code == 403


@pytest.mark.integration
def test_foreman_of_the_act_sees_the_photos(
    client_with_db, act, db_session, as_role, uploaded_files
):
    _upload(client_with_db, act.id, 1, uploaded_files)

    foreman = as_role(Role.FOREMAN.value)
    act.foreman_id = foreman.id
    db_session.flush()

    listed = _photos(client_with_db, act.id)

    assert listed.status_code == 200, listed.text
    assert len(listed.json()["data"]) == 1


@pytest.mark.integration
def test_photo_survives_the_mechanic_marking_the_step(
    client_with_db, act, db_session, uploaded_files
):
    """Отметка шага не должна ни перенумеровать пункты, ни отвязать снимок."""
    saved = _upload(client_with_db, act.id, 2, uploaded_files).json()["data"]

    checklist = client_with_db.get(
        f"{settings.API_V1_STR}/act-fact/{act.id}/"
    ).json()["data"]["checklist"]
    checklist["steps"][1]["done"] = True

    response = client_with_db.put(
        f"{settings.API_V1_STR}/act-fact/{act.id}/", json={"checklist": checklist}
    )
    assert response.status_code == 200, response.text

    assert response.json()["data"]["checklist"]["steps"][1] == {
        "id": 2,
        "title": "Проверить тормоз",
        "done": True,
        "comment": None,
    }
    listed = _photos(client_with_db, act.id, step_id=2).json()["data"]
    assert [photo["id"] for photo in listed] == [saved["id"]]


@pytest.mark.integration
def test_photos_of_a_missing_act_are_not_a_blank_list(client_with_db, me):
    """Пустой список означал бы «снимков нет», а акта нет вовсе."""
    assert _photos(client_with_db, 10**7).status_code == 404
