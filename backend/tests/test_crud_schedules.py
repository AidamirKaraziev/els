"""Лента графиков ТО: состояния клеток, поиск и фильтр состояния.

Тесты бьют по живой БД: вся логика здесь — SQL. Разворот двенадцати колонок
графика через `UNION ALL`, `CASE` с концом планового месяца, `EXISTS` по
клеткам года и `ilike` с экранированием. Мок проверил бы сам себя.

«Сейчас» задано явно (`schedule_year(..., now=...)`), а не берётся из
`datetime.now()`: от него зависит граница между «просрочено» и «месяц ещё
идёт», и иначе набор проходящих тестов зависел бы от дня прогона.
"""

import datetime
import itertools
import uuid

import pytest

from src.core.access import AccessScope, ScopeKind
from src.crud.crud_schedules import crud_schedules, schedule_year
from src.crud.crud_statistics import _PLANNED_MONTH_COLUMN
from src.getters.schedules import get_schedule_rows
from src.models import (
    ActBase,
    ActFact,
    Division,
    FactoryModel,
    Object,
    PlannedTO,
    UniversalUser,
)
from src.schemas.reports import MaintenanceStatus
from src.schemas.schedules import ScheduleState
from tests.scopes import ALL_SCOPE

#: id из `create_initial_data` (см. `src/core/db/init_db.py`).
TYPE_ACT_TO_1 = 1
TYPE_ACT_TO_6 = 6
TYPE_OBJECT_LIFT = 1
TYPE_OBJECT_ESCALATOR = 4

#: Сейчас — 20 августа 2026. Значит месяцы по июль включительно уже прошли.
NOW = datetime.datetime(2026, 8, 20, 12, 0)

YEAR = 2026


@pytest.fixture
def period():
    return schedule_year(YEAR, now=NOW)


@pytest.fixture
def make_object(db_session):
    counter = itertools.count(1)
    prefix = uuid.uuid4().hex[:8]

    def _make(**kwargs):
        number = next(counter)
        obj = Object(
            name=kwargs.pop("name", f"Лифт {number}"),
            factory_number=kwargs.pop("factory_number", f"F-{prefix}-{number}"),
            registration_number=f"R-{prefix}-{number}",
            **kwargs,
        )
        db_session.add(obj)
        db_session.flush()
        return obj

    return _make


@pytest.fixture
def plan_to(db_session):
    """Строка графика на год: `{номер месяца: finished_at}`.

    `None` означает «акт заведён, но не закрыт». Одной строкой на год, а не
    вызовом на каждый месяц: в `planned_to` висит
    `UniqueConstraint("year", "object_id")`.
    """

    def _make(obj, *, months=None, type_act_id=None, year=YEAR):
        act_base_id = None
        if type_act_id is not None:
            act_base = ActBase(type_act_id=type_act_id)
            db_session.add(act_base)
            db_session.flush()
            act_base_id = act_base.id

        columns = {}
        for month, finished_at in (months or {}).items():
            act = ActFact(
                object_id=obj.id, finished_at=finished_at, act_base_id=act_base_id
            )
            db_session.add(act)
            db_session.flush()
            columns[_PLANNED_MONTH_COLUMN[month].key] = act.id

        planned = PlannedTO(year=str(year), object_id=obj.id, **columns)
        db_session.add(planned)
        db_session.flush()
        return planned

    return _make


def _row(db_session, period, object_id=None, **kwargs):
    """Одна собранная строка ленты — то же, что увидит фронт."""
    rows, _ = crud_schedules.rows(
        db=db_session, scope=ALL_SCOPE, period=period, object_id=object_id, **kwargs
    )
    cells = crud_schedules.cells(
        db=db_session,
        scope=ALL_SCOPE,
        period=period,
        object_ids=[row.object_id for row in rows],
        object_id=object_id,
    )
    return get_schedule_rows(rows=rows, cells=cells, year=YEAR, now=period.now)


def _ids(db_session, period, **kwargs):
    rows, _ = crud_schedules.rows(
        db=db_session, scope=ALL_SCOPE, period=period, **kwargs
    )
    return {row.object_id for row in rows}


class TestCellStatus:
    """Пять состояний клетки. Ради них раздел и делается."""

    @pytest.mark.integration
    def test_five_states_of_one_year(
        self, db_session, make_object, plan_to, period
    ):
        obj = make_object()
        plan_to(
            obj,
            months={
                # Закрыт внутри своего месяца — выполнено.
                3: datetime.datetime(2026, 3, 20),
                # Закрыт в мае, а планировался на апрель — с опозданием.
                4: datetime.datetime(2026, 5, 2),
                # Не закрыт, месяц кончился — просрочка.
                5: None,
                # Не закрыт, месяц ещё идёт (сейчас 20 августа).
                8: None,
            },
        )

        cells = {cell.month: cell for cell in _row(db_session, period, obj.id)[0].cells}

        assert cells[3].status is MaintenanceStatus.DONE
        assert cells[4].status is MaintenanceStatus.LATE
        assert cells[5].status is MaintenanceStatus.OVERDUE
        assert cells[8].status is MaintenanceStatus.PENDING
        # Месяц, на который ТО не назначали. Это не долг: клетка пустая.
        assert cells[1].status is MaintenanceStatus.NONE
        assert cells[1].act_id is None

    @pytest.mark.integration
    def test_twelve_cells_always(self, db_session, make_object, plan_to, period):
        # Строк в ответе двенадцать даже у объекта с одним назначенным ТО:
        # иначе колонки разъехались бы между строками.
        obj = make_object()
        plan_to(obj, months={3: None})

        row = _row(db_session, period, obj.id)[0]

        assert [cell.month for cell in row.cells] == list(range(1, 13))

    @pytest.mark.integration
    def test_object_without_schedule_stays_in_feed(
        self, db_session, make_object, period
    ):
        # График на год не заводили вовсе. Объект из ленты не пропадает —
        # пустой график это тоже ответ, и он виден двенадцатью пустыми
        # клетками.
        obj = make_object()

        row = _row(db_session, period, obj.id)[0]

        assert len(row.cells) == 12
        assert all(cell.status is MaintenanceStatus.NONE for cell in row.cells)

    @pytest.mark.integration
    def test_cell_carries_act_and_kind(
        self, db_session, make_object, plan_to, period
    ):
        # Клик по клетке открывает работу, поэтому в ней обязаны быть и id
        # акта, и вид ТО.
        obj = make_object()
        plan_to(obj, months={3: None}, type_act_id=TYPE_ACT_TO_6)

        cell = _row(db_session, period, obj.id)[0].cells[2]

        assert cell.act_id is not None
        assert cell.to_name == "ТО 6"

    @pytest.mark.integration
    def test_other_year_is_not_shown(
        self, db_session, make_object, plan_to, period
    ):
        # График 2025 года в ленту 2026-го попадать не должен.
        obj = make_object()
        plan_to(obj, months={3: None}, year=2025)

        row = _row(db_session, period, obj.id)[0]

        assert all(cell.status is MaintenanceStatus.NONE for cell in row.cells)


class TestSearch:
    """Одна строка поиска на все таблицы сразу."""

    @pytest.mark.integration
    def test_finds_by_type_act(self, db_session, make_object, plan_to, period):
        # «ТО 6» — это вид акта, а не поле объекта. Человек ищет одной
        # строкой и не обязан знать, где что лежит.
        with_to6 = make_object()
        plan_to(with_to6, months={3: None}, type_act_id=TYPE_ACT_TO_6)
        with_to1 = make_object()
        plan_to(with_to1, months={3: None}, type_act_id=TYPE_ACT_TO_1)

        found = _ids(db_session, period, search="ТО 6")

        assert with_to6.id in found
        assert with_to1.id not in found

    @pytest.mark.integration
    def test_finds_by_address_and_division(
        self, db_session, make_object, period
    ):
        division = Division(title=f"Участок {uuid.uuid4().hex[:6]}")
        db_session.add(division)
        db_session.flush()
        by_address = make_object(address=f"ул. {uuid.uuid4().hex[:6]}")
        by_division = make_object(division_id=division.id)

        assert by_address.id in _ids(db_session, period, search=by_address.address)
        assert by_division.id in _ids(db_session, period, search=division.title)

    @pytest.mark.integration
    def test_percent_is_escaped(self, db_session, make_object, period):
        # `%` в `LIKE` значит «что угодно». Без экранирования одинокий
        # процент снял бы отбор целиком и вернул всю базу.
        obj = make_object(name=f"Склад 50% {uuid.uuid4().hex[:6]}")
        make_object()

        # Найден ровно тот, у кого процент в названии, а не вся база.
        assert _ids(db_session, period, search="%") == {obj.id}
        assert _ids(db_session, period, search="50%") == {obj.id}

    @pytest.mark.integration
    def test_search_and_filter_add_up(self, db_session, make_object, period):
        # Ищем внутри выбранного фильтра, а не вместо него.
        division = Division(title=f"Участок {uuid.uuid4().hex[:6]}")
        other = Division(title=f"Участок {uuid.uuid4().hex[:6]}")
        db_session.add_all([division, other])
        db_session.flush()

        mark = uuid.uuid4().hex[:8]
        mine = make_object(name=f"Спортмастер {mark}", division_id=division.id)
        theirs = make_object(name=f"Спортмастер {mark}", division_id=other.id)

        found = _ids(
            db_session, period, search=mark, division_id=division.id
        )

        assert found == {mine.id}
        assert theirs.id not in found


class TestFilters:
    """Фильтры выпадающих списков: точное значение, а не вхождение."""

    @pytest.mark.integration
    def test_type_object_filter(self, db_session, make_object, period):
        lift_model = FactoryModel(
            type_object_id=TYPE_OBJECT_LIFT,
            factory=f"З-{uuid.uuid4().hex[:6]}",
            model="М",
        )
        escalator_model = FactoryModel(
            type_object_id=TYPE_OBJECT_ESCALATOR,
            factory=f"З-{uuid.uuid4().hex[:6]}",
            model="М",
        )
        db_session.add_all([lift_model, escalator_model])
        db_session.flush()

        lift = make_object(factory_model_id=lift_model.id)
        escalator = make_object(factory_model_id=escalator_model.id)

        found = _ids(db_session, period, type_object_id=TYPE_OBJECT_ESCALATOR)

        assert escalator.id in found
        assert lift.id not in found

    @pytest.mark.integration
    def test_name_and_factory_number_match_exactly(
        self, db_session, make_object, period
    ):
        # Значения выпадающих списков сравниваются целиком: «Лифт 1» не
        # обязан приводить с собой «Лифт 12».
        mark = uuid.uuid4().hex[:8]
        exact = make_object(name=f"Лифт {mark}")
        longer = make_object(name=f"Лифт {mark} второй")

        found = _ids(db_session, period, name=exact.name)

        assert found == {exact.id}
        assert longer.id not in found
        assert _ids(
            db_session, period, factory_number=exact.factory_number
        ) == {exact.id}


class TestScheduleState:
    """«Где болит» — состояние всей годовой ленты."""

    @pytest.fixture
    def zoo(self, make_object, plan_to):
        """По объекту на каждое состояние ленты."""
        overdue = make_object()
        plan_to(overdue, months={5: None})

        late = make_object()
        plan_to(late, months={4: datetime.datetime(2026, 5, 2)})

        pending = make_object()
        plan_to(pending, months={8: None})

        done = make_object()
        plan_to(done, months={3: datetime.datetime(2026, 3, 20)})

        empty = make_object()

        return {
            "overdue": overdue,
            "late": late,
            "pending": pending,
            "done": done,
            "empty": empty,
        }

    @pytest.mark.integration
    def test_has_overdue(self, db_session, zoo, period):
        found = _ids(db_session, period, schedule_state=ScheduleState.HAS_OVERDUE)

        assert zoo["overdue"].id in found
        assert zoo["done"].id not in found
        assert zoo["pending"].id not in found

    @pytest.mark.integration
    def test_has_late(self, db_session, zoo, period):
        found = _ids(db_session, period, schedule_state=ScheduleState.HAS_LATE)

        assert zoo["late"].id in found
        assert zoo["done"].id not in found

    @pytest.mark.integration
    def test_has_pending_is_not_overdue(self, db_session, zoo, period):
        # «Есть незакрытые» — про месяц, который ещё идёт. Просрочка
        # спрашивается отдельным значением фильтра, иначе первого числа
        # каждого месяца оба фильтра показывали бы одно и то же.
        found = _ids(db_session, period, schedule_state=ScheduleState.HAS_PENDING)

        assert zoo["pending"].id in found
        assert zoo["overdue"].id not in found

    @pytest.mark.integration
    def test_all_done_counts_late_and_ignores_future(
        self, db_session, zoo, period
    ):
        # Зелёные и жёлтые без красных: опоздание — это сделанная работа, а
        # ещё не наступивший месяц чистоту не портит.
        found = _ids(db_session, period, schedule_state=ScheduleState.ALL_DONE)

        assert zoo["done"].id in found
        assert zoo["late"].id in found
        assert zoo["pending"].id in found
        assert zoo["overdue"].id not in found

    @pytest.mark.integration
    def test_state_and_search_live_in_one_query(
        self, db_session, make_object, plan_to, period
    ):
        # Поиск по виду ТО и фильтр состояния — два `EXISTS` по клеткам года
        # в одном запросе. Разъехаться им нельзя даже по имени подзапроса:
        # столкновение имён уронило бы весь запрос, а не одну строку.
        clean = make_object()
        plan_to(
            clean,
            months={3: datetime.datetime(2026, 3, 20)},
            type_act_id=TYPE_ACT_TO_6,
        )
        dirty = make_object()
        plan_to(dirty, months={5: None}, type_act_id=TYPE_ACT_TO_6)

        found = _ids(
            db_session,
            period,
            search="ТО 6",
            schedule_state=ScheduleState.ALL_DONE,
        )

        assert found == {clean.id}

    @pytest.mark.integration
    def test_all_done_skips_object_without_schedule(
        self, db_session, zoo, period
    ):
        # Объекту, которому график не ставили, «всё выполнено» неправда:
        # винить его не в чем, но и хвалить не за что.
        found = _ids(db_session, period, schedule_state=ScheduleState.ALL_DONE)

        assert zoo["empty"].id not in found


class TestScope:
    """Область видимости — граница, а не фильтр."""

    @pytest.mark.integration
    def test_foreman_does_not_see_other_division(
        self, db_session, make_object, plan_to, period
    ):
        mine = Division(title=f"Мой {uuid.uuid4().hex[:6]}")
        theirs = Division(title=f"Чужой {uuid.uuid4().hex[:6]}")
        db_session.add_all([mine, theirs])
        db_session.flush()

        my_object = make_object(division_id=mine.id)
        their_object = make_object(division_id=theirs.id)
        plan_to(their_object, months={3: None})

        foreman_scope = AccessScope(
            kind=ScopeKind.DIVISIONS,
            user_id=0,
            division_ids=frozenset({mine.id}),
            company_id=None,
        )

        rows, _ = crud_schedules.rows(
            db=db_session,
            scope=foreman_scope,
            period=period,
            # Чужой объект спрошен напрямую — и всё равно не приходит.
            object_id=their_object.id,
        )
        cells = crud_schedules.cells(
            db=db_session,
            scope=foreman_scope,
            period=period,
            object_ids=[their_object.id],
        )

        assert rows == []
        assert cells == []
        assert my_object.id not in {row.object_id for row in rows}


class TestRowFields:
    """Поля строки: их читает карточка объекта на экране."""

    @pytest.mark.integration
    def test_row_carries_division_type_and_foreman(
        self, db_session, make_object, period
    ):
        division = Division(title=f"Участок {uuid.uuid4().hex[:6]}")
        model = FactoryModel(
            type_object_id=TYPE_OBJECT_ESCALATOR,
            factory=f"З-{uuid.uuid4().hex[:6]}",
            model="М",
        )
        foreman = UniversalUser(
            name=f"Прораб {uuid.uuid4().hex[:6]}",
            email=f"{uuid.uuid4().hex[:12]}@example.com",
            hashed_password="x",
            is_active=True,
        )
        db_session.add_all([division, model, foreman])
        db_session.flush()

        obj = make_object(
            division_id=division.id,
            factory_model_id=model.id,
            foreman_id=foreman.id,
            address="ул. Ленина, 1",
        )

        row = _row(db_session, period, obj.id)[0]

        assert row.division == division.title
        assert row.type_name == "Эскалатор"
        assert row.foreman == foreman.name
        assert row.address == "ул. Ленина, 1"
        assert row.year == YEAR
