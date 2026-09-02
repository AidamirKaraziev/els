"""Годовой график по программе: предпросмотр и создание.

Предпросмотр ничего не пишет в базу — это заготовка, которую человек ещё
утверждает. Поэтому здесь же проверяется, что после запроса не появилось ни
строки `planned_to`, ни акта.

Создание пишет по тем же клеткам: акт заводится только в свободный месяц,
занятый не трогается вовсе — на этом держится идемпотентность.

Данные заводятся годами, а не относительно сегодняшнего дня: предпросмотру
всё равно, какое сегодня число, — он про план, а не про исполнение.
"""

import itertools
import json
import uuid

import pytest

from src.config import settings
from src.core.roles import ADMIN, CLIENT_ID, DISPATCHER, FOREMAN, MECHANIC
from src.crud.crud_statistics import _PLANNED_MONTH_COLUMN
from src.models import (
    ActBase,
    ActFact,
    FactoryModel,
    MaintenanceProgram,
    MaintenanceProgramItem,
    Object,
    PlannedTO,
)
from src.services.checklist import parse_checklist

URL = f"{settings.API_V1_STR}/planned-to/preview/"

#: id из `create_initial_data` (см. `src/core/db/init_db.py`): id вида ТО
#: равен периодичности в месяцах.
TO_1, TO_3, TO_6, TO_12 = 1, 3, 6, 12

#: Стандартный цикл: позиция получает наибольшую периодичность, на которую
#: делится. ТО12 в нём один, поэтому сдвиг по такому году опознаётся
#: однозначно.
FULL_CYCLE = [TO_1, TO_1, TO_3, TO_1, TO_1, TO_6, TO_1, TO_1, TO_3, TO_1, TO_1, TO_12]

YEAR = 2026


def cycle_month(position_type_acts, anchor_month):
    """Разложить цикл на календарные месяцы при заданном якоре."""
    return {
        month: position_type_acts[(month - anchor_month) % 12] for month in range(1, 13)
    }


@pytest.fixture
def make_model(db_session):
    counter = itertools.count(1)
    prefix = uuid.uuid4().hex[:8]

    def _make(*, act_bases=(TO_1, TO_3, TO_6, TO_12), program=FULL_CYCLE):
        number = next(counter)
        model = FactoryModel(factory=f"Завод {prefix}", model=f"М-{prefix}-{number}")
        db_session.add(model)
        db_session.flush()

        for type_act_id in act_bases:
            db_session.add(ActBase(factory_model_id=model.id, type_act_id=type_act_id))

        if program is not None:
            saved = MaintenanceProgram(factory_model_id=model.id, name="Стандартная")
            saved.items = [
                MaintenanceProgramItem(position=position, type_act_id=type_act_id)
                for position, type_act_id in enumerate(program, start=1)
            ]
            db_session.add(saved)

        db_session.flush()
        return model

    return _make


@pytest.fixture
def make_object(db_session):
    counter = itertools.count(1)
    prefix = uuid.uuid4().hex[:8]

    def _make(**kwargs):
        number = next(counter)
        obj = Object(
            name=kwargs.pop("name", f"Лифт {number}"),
            factory_number=f"F-{prefix}-{number}",
            registration_number=f"R-{prefix}-{number}",
            **kwargs,
        )
        db_session.add(obj)
        db_session.flush()
        return obj

    return _make


@pytest.fixture
def plan_year(db_session):
    """Завести график объекта за год: месяц → вид ТО."""

    def _make(obj, *, year, months):
        columns = {}
        for month, type_act_id in months.items():
            # Шаблон на пару «модель + вид ТО» в базе один: `acts_bases`
            # уникальна по ним, и заводить второй нельзя.
            act_base = (
                db_session.query(ActBase)
                .filter(
                    ActBase.factory_model_id == obj.factory_model_id,
                    ActBase.type_act_id == type_act_id,
                )
                .first()
            )
            if act_base is None:
                act_base = ActBase(
                    factory_model_id=obj.factory_model_id, type_act_id=type_act_id
                )
                db_session.add(act_base)
                db_session.flush()

            act = ActFact(object_id=obj.id, act_base_id=act_base.id)
            db_session.add(act)
            db_session.flush()
            columns[_PLANNED_MONTH_COLUMN[month].key] = act.id

        planned = PlannedTO(year=str(year), object_id=obj.id, **columns)
        db_session.add(planned)
        db_session.flush()
        return planned

    return _make


def _data(response):
    assert response.status_code == 200, response.text
    return response.json()["data"]


def _cells(response):
    return {cell["month"]: cell for cell in _data(response)["cells"]}


def _url(obj, *, year=YEAR, anchor_month=None):
    query = f"?object_id={obj.id}&year={year}"
    if anchor_month is not None:
        query += f"&anchor_month={anchor_month}"
    return URL + query


class TestAccess:
    """Право то же, что у остальных чтений графика; границу держит область."""

    @pytest.mark.integration
    @pytest.mark.parametrize(
        "role",
        [ADMIN, FOREMAN, DISPATCHER],
        ids=["админ", "прораб", "диспетчер"],
    )
    def test_roles_with_planned_to_read_are_allowed(
        self, client_with_db, as_role, make_model, make_object, role
    ):
        obj = make_object(factory_model_id=make_model().id)
        as_role(role)

        response = client_with_db.get(_url(obj, anchor_month=1))

        assert response.status_code == 200, response.text

    @pytest.mark.integration
    def test_client_is_denied(self, client_with_db, as_role, make_model, make_object):
        # Клиент график ТО не ведёт и не смотрит: права у роли нет.
        obj = make_object(factory_model_id=make_model().id)
        as_role(CLIENT_ID)

        assert client_with_db.get(_url(obj, anchor_month=1)).status_code == 403

    @pytest.mark.integration
    def test_anonymous_is_denied(self, client_with_db, make_model, make_object):
        obj = make_object(factory_model_id=make_model().id)

        assert client_with_db.get(_url(obj, anchor_month=1)).status_code == 401

    @pytest.mark.integration
    def test_mechanic_sees_his_own_object(
        self, client_with_db, as_role, make_model, make_object
    ):
        user = as_role(MECHANIC)
        obj = make_object(factory_model_id=make_model().id, mechanic_id=user.id)

        assert client_with_db.get(_url(obj, anchor_month=1)).status_code == 200

    @pytest.mark.integration
    def test_foreign_object_is_403_not_404(
        self, client_with_db, as_role, make_model, make_object
    ):
        # Чужая запись — 403: 404 на неё выглядел бы как пропавшие данные.
        as_role(MECHANIC)
        obj = make_object(factory_model_id=make_model().id)

        assert client_with_db.get(_url(obj, anchor_month=1)).status_code == 403

    @pytest.mark.integration
    def test_missing_object_is_404(self, client_with_db, as_role):
        as_role(ADMIN)

        response = client_with_db.get(f"{URL}?object_id=99999999&year={YEAR}")

        assert response.status_code == 404


class TestPreviewShape:
    """Форма ответа: двенадцать клеток, позиция цикла и вид ТО."""

    @pytest.mark.integration
    def test_twelve_cells_by_anchor(
        self, client_with_db, as_role, make_model, make_object
    ):
        obj = make_object(factory_model_id=make_model().id)
        as_role(ADMIN)

        response = client_with_db.get(_url(obj, anchor_month=3))
        data = _data(response)
        cells = {cell["month"]: cell for cell in data["cells"]}

        assert len(data["cells"]) == 12
        assert data["anchor_month"] == 3
        assert data["object_id"] == obj.id
        assert data["year"] == YEAR
        # Первая позиция цикла приходится на якорь, дальше по кругу.
        assert cells[3]["position"] == 1
        assert cells[2]["position"] == 12
        assert cells[2]["type_act_id"] == TO_12
        assert cells[2]["type_act_name"] == "ТО 12"
        assert all(cell["occupied"] is False for cell in data["cells"])
        assert all(cell["template_missing"] is False for cell in data["cells"])

    @pytest.mark.integration
    def test_missing_template_is_marked(
        self, client_with_db, as_role, make_model, make_object
    ):
        # Шаблоны только на ТО1 и ТО12, а программа просит ещё ТО3 и ТО6.
        model = make_model(act_bases=(TO_1, TO_12))
        obj = make_object(factory_model_id=model.id)
        as_role(ADMIN)

        cells = _cells(client_with_db.get(_url(obj, anchor_month=1)))

        assert cells[12]["template_missing"] is False
        assert cells[6]["type_act_id"] == TO_6
        assert cells[6]["template_missing"] is True
        assert cells[3]["template_missing"] is True

    @pytest.mark.integration
    def test_occupied_months_are_marked(
        self, client_with_db, as_role, make_model, make_object, plan_year
    ):
        obj = make_object(factory_model_id=make_model().id)
        # Полгода уже расставлено, вторая половина пуста.
        plan_year(
            obj,
            year=YEAR,
            months={month: TO_1 for month in range(1, 7)},
        )
        as_role(ADMIN)

        cells = _cells(client_with_db.get(_url(obj, anchor_month=1)))

        assert [month for month in range(1, 13) if cells[month]["occupied"]] == list(
            range(1, 7)
        )


class TestAnchor:
    """Якорь: продолжение цикла через границу года."""

    @pytest.mark.integration
    def test_cycle_continues_across_the_year_boundary(
        self, client_with_db, as_role, make_model, make_object, plan_year
    ):
        obj = make_object(factory_model_id=make_model().id)
        # Прошлый год расставлен со сдвигом: цикл начался в марте.
        previous = cycle_month(FULL_CYCLE, anchor_month=3)
        plan_year(obj, year=YEAR - 1, months=previous)
        as_role(ADMIN)

        response = client_with_db.get(_url(obj))
        data = _data(response)
        cells = {cell["month"]: cell for cell in data["cells"]}

        assert data["anchor_month"] == 3
        # Раскладка нового года повторяет прошлогоднюю: цикл не разорвался.
        assert {month: cell["type_act_id"] for month, cell in cells.items()} == previous

    @pytest.mark.integration
    def test_half_planned_previous_year_is_enough(
        self, client_with_db, as_role, make_model, make_object, plan_year
    ):
        obj = make_object(factory_model_id=make_model().id)
        previous = cycle_month(FULL_CYCLE, anchor_month=5)
        plan_year(
            obj,
            year=YEAR - 1,
            months={
                month: type_act_id
                for month, type_act_id in previous.items()
                if month <= 6
            },
        )
        as_role(ADMIN)

        # ТО12 попало в первую половину года — сдвиг опознаётся по нему.
        assert _data(client_with_db.get(_url(obj)))["anchor_month"] == 5

    @pytest.mark.integration
    def test_explicit_anchor_ignores_the_previous_year(
        self, client_with_db, as_role, make_model, make_object, plan_year
    ):
        obj = make_object(factory_model_id=make_model().id)
        plan_year(obj, year=YEAR - 1, months=cycle_month(FULL_CYCLE, anchor_month=3))
        as_role(ADMIN)

        assert _data(client_with_db.get(_url(obj, anchor_month=7)))["anchor_month"] == 7

    @pytest.mark.integration
    def test_without_previous_year_anchor_is_required(
        self, client_with_db, as_role, make_model, make_object
    ):
        obj = make_object(factory_model_id=make_model().id)
        as_role(ADMIN)

        response = client_with_db.get(_url(obj))

        assert response.status_code == 422, response.text
        assert "anchor_month" in response.text

    @pytest.mark.integration
    def test_ambiguous_previous_year_is_422(
        self, client_with_db, as_role, make_model, make_object, plan_year
    ):
        # Один месяц с ТО1: в программе ТО1 стоит на восьми позициях, и
        # сдвигов, которые подходят, тоже восемь.
        obj = make_object(factory_model_id=make_model().id)
        plan_year(obj, year=YEAR - 1, months={4: TO_1})
        as_role(ADMIN)

        assert client_with_db.get(_url(obj)).status_code == 422

    @pytest.mark.integration
    def test_anchor_is_taken_from_the_year_itself(
        self, client_with_db, as_role, make_model, make_object, plan_year
    ):
        # Год уже расставлен с марта: повторный заход в мастер обязан
        # показать его же цикл, а не начать заново с января.
        obj = make_object(factory_model_id=make_model().id)
        planned = cycle_month(FULL_CYCLE, anchor_month=3)
        plan_year(obj, year=YEAR, months=planned)
        as_role(ADMIN)

        data = _data(client_with_db.get(_url(obj)))
        cells = {cell["month"]: cell["type_act_id"] for cell in data["cells"]}

        assert data["anchor_month"] == 3
        assert cells == planned

    @pytest.mark.integration
    def test_the_year_itself_wins_over_the_previous_one(
        self, client_with_db, as_role, make_model, make_object, plan_year
    ):
        # Прошлый год расставлен по одному сдвигу, этот — по другому.
        # Продолжать надо тот, что уже лежит в запрошенном году.
        obj = make_object(factory_model_id=make_model().id)
        plan_year(obj, year=YEAR - 1, months=cycle_month(FULL_CYCLE, anchor_month=3))
        plan_year(obj, year=YEAR, months=cycle_month(FULL_CYCLE, anchor_month=7))
        as_role(ADMIN)

        assert _data(client_with_db.get(_url(obj)))["anchor_month"] == 7

    @pytest.mark.integration
    def test_ambiguous_year_falls_back_to_the_previous_one(
        self, client_with_db, as_role, make_model, make_object, plan_year
    ):
        # В этом году один месяц с ТО1 — по нему сдвиг не опознать. Тогда
        # смотрим прошлый год, как и раньше.
        obj = make_object(factory_model_id=make_model().id)
        plan_year(obj, year=YEAR - 1, months=cycle_month(FULL_CYCLE, anchor_month=5))
        plan_year(obj, year=YEAR, months={4: TO_1})
        as_role(ADMIN)

        assert _data(client_with_db.get(_url(obj)))["anchor_month"] == 5

    @pytest.mark.integration
    def test_previous_year_off_program_is_422(
        self, client_with_db, as_role, make_model, make_object, plan_year
    ):
        # Год расставлен не по этой программе: ни один сдвиг не сходится.
        obj = make_object(factory_model_id=make_model().id)
        plan_year(obj, year=YEAR - 1, months={month: TO_1 for month in range(1, 13)})
        as_role(ADMIN)

        assert client_with_db.get(_url(obj)).status_code == 422


class TestMissingProgram:
    """Без программы раскладывать нечего."""

    @pytest.mark.integration
    def test_model_without_program_is_404(
        self, client_with_db, as_role, make_model, make_object
    ):
        obj = make_object(factory_model_id=make_model(program=None).id)
        as_role(ADMIN)

        response = client_with_db.get(_url(obj, anchor_month=1))

        assert response.status_code == 404, response.text

    @pytest.mark.integration
    def test_object_without_model_is_404(self, client_with_db, as_role, make_object):
        obj = make_object()
        as_role(ADMIN)

        assert client_with_db.get(_url(obj, anchor_month=1)).status_code == 404


class TestWritesNothing:
    """Предпросмотр — чтение. В базе после него не должно измениться ничего."""

    @pytest.mark.integration
    def test_nothing_is_written(
        self, client_with_db, as_role, db_session, make_model, make_object
    ):
        obj = make_object(factory_model_id=make_model().id)
        as_role(ADMIN)
        before = (
            db_session.query(PlannedTO).count(),
            db_session.query(ActFact).count(),
        )

        assert client_with_db.get(_url(obj, anchor_month=1)).status_code == 200

        assert (
            db_session.query(PlannedTO).count(),
            db_session.query(ActFact).count(),
        ) == before


GENERATE_URL = f"{settings.API_V1_STR}/planned-to/generate/"


def _payload(obj, *, year=YEAR, anchor_month=1):
    body = {"object_id": obj.id, "year": year}
    if anchor_month is not None:
        body["anchor_month"] = anchor_month
    return body


def _acts_of(db_session, obj):
    return db_session.query(ActFact).filter(ActFact.object_id == obj.id).all()


def _months_of(planned):
    """Месяц → id акта по колонкам графика."""
    return {
        month: getattr(planned, column.key)
        for month, column in _PLANNED_MONTH_COLUMN.items()
        if getattr(planned, column.key) is not None
    }


class TestGenerateAccess:
    """Право на запись графика: админ и прораб, остальным закрыто."""

    @pytest.mark.integration
    def test_admin_is_allowed(self, client_with_db, as_role, make_model, make_object):
        obj = make_object(factory_model_id=make_model().id)
        as_role(ADMIN)

        response = client_with_db.post(GENERATE_URL, json=_payload(obj))

        assert response.status_code == 200, response.text

    @pytest.mark.integration
    @pytest.mark.parametrize(
        "role",
        [DISPATCHER, MECHANIC, CLIENT_ID],
        ids=["диспетчер", "механик", "клиент"],
    )
    def test_roles_without_write_are_denied(
        self, client_with_db, as_role, make_model, make_object, role
    ):
        # Читать график диспетчер может, расставлять его — нет.
        obj = make_object(factory_model_id=make_model().id)
        as_role(role)

        assert client_with_db.post(GENERATE_URL, json=_payload(obj)).status_code == 403

    @pytest.mark.integration
    def test_anonymous_is_denied(self, client_with_db, make_model, make_object):
        obj = make_object(factory_model_id=make_model().id)

        assert client_with_db.post(GENERATE_URL, json=_payload(obj)).status_code == 401

    @pytest.mark.integration
    def test_foreign_object_is_403_not_404(
        self, client_with_db, as_role, make_model, make_object
    ):
        # У прораба область на запись — свои участки, чужой лифт даёт 403.
        as_role(FOREMAN)
        obj = make_object(factory_model_id=make_model().id)

        assert client_with_db.post(GENERATE_URL, json=_payload(obj)).status_code == 403

    @pytest.mark.integration
    def test_missing_object_is_404(self, client_with_db, as_role):
        as_role(ADMIN)

        response = client_with_db.post(
            GENERATE_URL, json={"object_id": 99999999, "year": YEAR, "anchor_month": 1}
        )

        assert response.status_code == 404


class TestGenerateWrites:
    """Что легло в базу: двенадцать актов и заполненный график года."""

    @pytest.mark.integration
    def test_year_is_created_by_program(
        self, client_with_db, as_role, db_session, make_model, make_object
    ):
        obj = make_object(factory_model_id=make_model().id)
        as_role(ADMIN)

        data = _data(
            client_with_db.post(GENERATE_URL, json=_payload(obj, anchor_month=3))
        )

        assert data["anchor_month"] == 3
        assert data["skipped"] == []
        assert [cell["month"] for cell in data["created"]] == list(range(1, 13))

        planned = (
            db_session.query(PlannedTO)
            .filter(PlannedTO.id == data["planned_to_id"])
            .one()
        )
        assert planned.object_id == obj.id
        assert planned.year == str(YEAR)
        assert sorted(_months_of(planned)) == list(range(1, 13))
        assert len(_acts_of(db_session, obj)) == 12

    @pytest.mark.integration
    def test_cells_match_preview(
        self, client_with_db, as_role, make_model, make_object
    ):
        # Раскладка одна на две ручки: создание не считает год заново.
        obj = make_object(factory_model_id=make_model().id)
        as_role(ADMIN)

        preview = _cells(client_with_db.get(_url(obj, anchor_month=5)))
        created = _data(
            client_with_db.post(GENERATE_URL, json=_payload(obj, anchor_month=5))
        )

        for cell in created["created"]:
            assert cell["position"] == preview[cell["month"]]["position"]
            assert cell["type_act_id"] == preview[cell["month"]]["type_act_id"]
            assert cell["type_act_name"] == preview[cell["month"]]["type_act_name"]

    @pytest.mark.integration
    def test_created_act_is_filled(
        self, client_with_db, as_role, db_session, make_model, make_object
    ):
        model = make_model()
        obj = make_object(factory_model_id=model.id)
        as_role(ADMIN)

        data = _data(client_with_db.post(GENERATE_URL, json=_payload(obj)))
        january = next(cell for cell in data["created"] if cell["month"] == 1)
        act = (
            db_session.query(ActFact).filter(ActFact.id == january["act_fact_id"]).one()
        )

        assert act.object_id == obj.id
        assert act.status_id == 1
        assert act.act_base.factory_model_id == model.id
        assert act.act_base.type_act_id == january["type_act_id"]

    @pytest.mark.integration
    def test_checklist_is_canonical(
        self, client_with_db, as_role, db_session, make_model, make_object
    ):
        # Шаблон лежит в форме `steplist_tamplate.json`; в акт он должен
        # попасть уже канонической формой, с названием вида ТО.
        model = make_model()
        act_base = (
            db_session.query(ActBase)
            .filter(ActBase.factory_model_id == model.id, ActBase.type_act_id == TO_1)
            .one()
        )
        act_base.step_list = json.dumps(
            [{"step_name": "Осмотреть кабину", "substeps": []}], ensure_ascii=False
        )
        db_session.flush()
        obj = make_object(factory_model_id=model.id)
        as_role(ADMIN)

        data = _data(client_with_db.post(GENERATE_URL, json=_payload(obj)))
        january = next(cell for cell in data["created"] if cell["month"] == 1)
        act = (
            db_session.query(ActFact).filter(ActFact.id == january["act_fact_id"]).one()
        )
        checklist = parse_checklist(act.step_list_fact)

        assert json.loads(act.step_list_fact)["steps"][0]["title"] == "Осмотреть кабину"
        assert checklist.title == "ТО 1"
        assert [step.id for step in checklist.steps] == [1]


class TestGenerateSkipsOccupied:
    """Занятый месяц не трогается — ни акт, ни ячейка."""

    @pytest.mark.integration
    def test_occupied_months_are_skipped(
        self, client_with_db, as_role, db_session, make_model, make_object, plan_year
    ):
        obj = make_object(factory_model_id=make_model().id)
        planned = plan_year(obj, year=YEAR, months={2: TO_1, 7: TO_1})
        before = _months_of(planned)
        as_role(ADMIN)

        data = _data(client_with_db.post(GENERATE_URL, json=_payload(obj)))

        assert data["skipped"] == [2, 7]
        assert [cell["month"] for cell in data["created"]] == [
            1,
            3,
            4,
            5,
            6,
            8,
            9,
            10,
            11,
            12,
        ]
        assert data["planned_to_id"] == planned.id
        after = _months_of(planned)
        assert after[2] == before[2] and after[7] == before[7]
        # Два акта были, десять добавилось.
        assert len(_acts_of(db_session, obj)) == 12

    @pytest.mark.integration
    def test_second_call_adds_nothing(
        self, client_with_db, as_role, db_session, make_model, make_object
    ):
        obj = make_object(factory_model_id=make_model().id)
        as_role(ADMIN)

        first = _data(client_with_db.post(GENERATE_URL, json=_payload(obj)))
        acts_after_first = {act.id for act in _acts_of(db_session, obj)}

        second = _data(client_with_db.post(GENERATE_URL, json=_payload(obj)))

        assert second["created"] == []
        assert second["skipped"] == list(range(1, 13))
        assert second["planned_to_id"] == first["planned_to_id"]
        assert {act.id for act in _acts_of(db_session, obj)} == acts_after_first


class TestGenerateResponsibles:
    """Прораб и механик берутся из карточки объекта и могут быть пустыми."""

    @pytest.mark.integration
    def test_taken_from_object(
        self, client_with_db, as_role, db_session, make_model, make_object
    ):
        mechanic = as_role(MECHANIC)
        foreman = as_role(FOREMAN)
        obj = make_object(
            factory_model_id=make_model().id,
            foreman_id=foreman.id,
            mechanic_id=mechanic.id,
        )
        as_role(ADMIN)

        data = _data(client_with_db.post(GENERATE_URL, json=_payload(obj)))
        act = (
            db_session.query(ActFact)
            .filter(ActFact.id == data["created"][0]["act_fact_id"])
            .one()
        )

        assert act.foreman_id == foreman.id
        assert act.main_mechanic_id == mechanic.id

    @pytest.mark.integration
    def test_empty_object_gives_empty_act(
        self, client_with_db, as_role, db_session, make_model, make_object
    ):
        # Незаполненная карточка объекта графику не помеха: проставить
        # ответственных можно и потом.
        obj = make_object(factory_model_id=make_model().id)
        as_role(ADMIN)

        data = _data(client_with_db.post(GENERATE_URL, json=_payload(obj)))
        act = (
            db_session.query(ActFact)
            .filter(ActFact.id == data["created"][0]["act_fact_id"])
            .one()
        )

        assert act.foreman_id is None
        assert act.main_mechanic_id is None


class TestGenerateRefuses:
    """Отказы: нет шаблона, нет программы, не восстановился якорь."""

    @pytest.mark.integration
    def test_missing_template_is_422_and_writes_nothing(
        self, client_with_db, as_role, db_session, make_model, make_object
    ):
        # Шаблоны только на ТО1 и ТО12, а программа просит ещё ТО3 и ТО6.
        obj = make_object(factory_model_id=make_model(act_bases=(TO_1, TO_12)).id)
        as_role(ADMIN)

        response = client_with_db.post(GENERATE_URL, json=_payload(obj))

        assert response.status_code == 422, response.text
        assert _acts_of(db_session, obj) == []
        assert (
            db_session.query(PlannedTO).filter(PlannedTO.object_id == obj.id).count()
            == 0
        )

    @pytest.mark.integration
    def test_missing_program_is_404(
        self, client_with_db, as_role, make_model, make_object
    ):
        obj = make_object(factory_model_id=make_model(program=None).id)
        as_role(ADMIN)

        assert client_with_db.post(GENERATE_URL, json=_payload(obj)).status_code == 404

    @pytest.mark.integration
    def test_anchor_is_taken_from_previous_year(
        self, client_with_db, as_role, make_model, make_object, plan_year
    ):
        obj = make_object(factory_model_id=make_model().id)
        # Прошлый год расставлен с якорём 4 — цикл продолжается без разрыва.
        plan_year(obj, year=YEAR - 1, months=cycle_month(FULL_CYCLE, 4))
        as_role(ADMIN)

        data = _data(
            client_with_db.post(GENERATE_URL, json=_payload(obj, anchor_month=None))
        )

        assert data["anchor_month"] == 4

    @pytest.mark.integration
    def test_without_anchor_and_without_previous_year_is_422(
        self, client_with_db, as_role, db_session, make_model, make_object
    ):
        obj = make_object(factory_model_id=make_model().id)
        as_role(ADMIN)

        response = client_with_db.post(
            GENERATE_URL, json=_payload(obj, anchor_month=None)
        )

        assert response.status_code == 422, response.text
        assert _acts_of(db_session, obj) == []
