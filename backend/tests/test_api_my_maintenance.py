"""Список плановых ТО механика: `GET /act-fact/for-me`.

Главный экран механика в телефоне. Раньше попасть в своё ТО можно было только
через объект и ручной выбор месяца — списка «что мне сделать» не было вовсе.

Механик привязан к ТО через `main_mechanic_id` акта, а тот проставляется из
механика объекта при создании графика.
"""

import datetime
import itertools
import json
import uuid

import pytest

from src.config import settings
from src.core.roles import Role
from src.models import ActFact, Object, PlannedTO, UniversalUser

URL = f"{settings.API_V1_STR}/act-fact/for-me"

_MONTH_COLUMN = {
    1: "january_to_id",
    3: "march_to_id",
    5: "may_to_id",
    12: "december_to_id",
}


def _checklist(steps, number="ТО-1"):
    """Форма, которую пишут оба фронта: список шагов строкой внутри словаря."""
    return json.dumps(
        {"numberTo": number, "stepListTO": json.dumps(steps, ensure_ascii=False)},
        ensure_ascii=False,
    )


@pytest.fixture
def me(as_role):
    return as_role(Role.MECHANIC.value)


@pytest.fixture
def make_object(db_session):
    counter = itertools.count(1)
    prefix = uuid.uuid4().hex[:8]

    def _make(mechanic=None):
        number = next(counter)
        obj = Object(
            name=f"Лифт {number}",
            address=f"ул. Проверочная, {number}",
            factory_number=f"F-{prefix}-{number}",
            registration_number=f"R-{prefix}-{number}",
            mechanic_id=mechanic.id if mechanic else None,
        )
        db_session.add(obj)
        db_session.flush()
        return obj

    return _make


@pytest.fixture
def plan_to(db_session, make_object):
    """Кладёт акт в ячейку графика — так же, как это делает экран прораба."""
    years = itertools.count(2026)

    def _plan(
        mechanic,
        month=5,
        year=None,
        step_list_fact=None,
        finished_at=None,
        obj=None,
    ):
        obj = obj or make_object(mechanic)
        act = ActFact(
            object_id=obj.id,
            main_mechanic_id=mechanic.id if mechanic else None,
            step_list_fact=step_list_fact,
            finished_at=finished_at,
        )
        db_session.add(act)
        db_session.flush()

        # Год уникальный на каждую запись: у `planned_to` уникальность по паре
        # «год + объект», и второй план на тот же объект иначе не заведётся.
        plan_year = str(year if year is not None else next(years))
        plan = PlannedTO(year=plan_year, object_id=obj.id)
        setattr(plan, _MONTH_COLUMN[month], act.id)
        db_session.add(plan)
        db_session.flush()
        return act, plan

    return _plan


def _items(response):
    assert response.status_code == 200, response.text
    return response.json()["data"]


@pytest.mark.integration
def test_shows_my_maintenance_with_the_planned_month(client_with_db, me, plan_to):
    act, _ = plan_to(me, month=3, year=2026)

    item = _items(client_with_db.get(URL))[0]

    assert item["act_id"] == act.id
    assert item["year"] == 2026
    assert item["month"] == 3


@pytest.mark.integration
def test_someone_elses_maintenance_is_not_mine(
    client_with_db, me, plan_to, db_session
):
    other = UniversalUser(
        name="Другой механик",
        email=f"other-{uuid.uuid4().hex[:8]}@test",
        role_id=Role.MECHANIC.value,
        is_active=True,
    )
    db_session.add(other)
    db_session.flush()

    mine, _ = plan_to(me, month=3, year=2026)
    plan_to(other, month=3, year=2027)

    assert [item["act_id"] for item in _items(client_with_db.get(URL))] == [mine.id]


@pytest.mark.integration
def test_counts_steps_instead_of_sending_the_checklist(client_with_db, me, plan_to):
    """В списке нужны два числа, а не строка на сотни килобайт."""
    plan_to(
        me,
        step_list_fact=_checklist(
            [
                {"text": "Выключить вводное устройство", "bool": True},
                {"text": "Осмотр станции управления", "bool": True},
                {"text": "Проверить тормоз", "bool": False},
            ]
        ),
    )

    item = _items(client_with_db.get(URL))[0]

    assert item["steps_total"] == 3
    assert item["steps_done"] == 2
    assert item["title"] == "ТО-1"
    assert "step_list_fact" not in item


@pytest.mark.integration
def test_empty_checklist_is_not_a_crash(client_with_db, me, plan_to):
    """Незаполненный чек-лист — это ноль пунктов, а не пятисотка."""
    plan_to(me, step_list_fact="совсем не список")

    item = _items(client_with_db.get(URL))[0]

    assert (item["steps_total"], item["steps_done"]) == (0, 0)


@pytest.mark.integration
def test_only_open_hides_closed_acts(client_with_db, me, plan_to):
    """Закрытое ТО — то, у которого есть дата окончания."""
    open_act, _ = plan_to(me, month=3, year=2026)
    plan_to(me, month=5, year=2027, finished_at=datetime.datetime(2027, 5, 20))

    got = [item["act_id"] for item in _items(client_with_db.get(URL, params={"only_open": True}))]

    assert got == [open_act.id]


@pytest.mark.integration
def test_filter_by_month_of_the_schedule(client_with_db, me, plan_to):
    wanted, _ = plan_to(me, month=3, year=2026)
    plan_to(me, month=5, year=2026, obj=None)
    plan_to(me, month=3, year=2027)

    got = [
        item["act_id"]
        for item in _items(client_with_db.get(URL, params={"year": 2026, "month": 3}))
    ]

    assert got == [wanted.id]


@pytest.mark.integration
def test_half_of_the_period_is_rejected(client_with_db, me):
    assert client_with_db.get(URL, params={"month": 5}).status_code == 422


@pytest.mark.integration
def test_object_comes_with_the_address(client_with_db, me, plan_to, make_object):
    obj = make_object(me)
    plan_to(me, obj=obj)

    item = _items(client_with_db.get(URL))[0]

    assert item["object"]["id"] == obj.id
    assert item["object"]["address"] == obj.address


@pytest.mark.integration
def test_hand_typed_year_does_not_break_the_list(client_with_db, me, plan_to):
    """Год в графике — строка, набитая руками. «2025 г.» не должен ронять выдачу."""
    plan_to(me, month=3, year="2025 г.")

    assert _items(client_with_db.get(URL))[0]["year"] == 0


@pytest.mark.integration
def test_newest_by_schedule_first(client_with_db, me, plan_to):
    old, _ = plan_to(me, month=1, year=2025)
    fresh, _ = plan_to(me, month=12, year=2026)

    got = [item["act_id"] for item in _items(client_with_db.get(URL))]

    assert got == [fresh.id, old.id]
