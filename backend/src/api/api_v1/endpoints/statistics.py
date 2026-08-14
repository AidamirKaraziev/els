"""Статистика для главной страницы.

Здесь все четыре виджета: топ поломок, выполнение графика ТО, просроченные ТО
и топ сотрудников. Период и фильтры у них общие, запрос у каждого свой.
"""

import datetime
import logging
from io import BytesIO
from typing import List, NamedTuple
from urllib.parse import quote

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse

from src.api import deps
from src.core.permissions import Permission, permissions_for
from src.core.response import SingleEntityResponse
from src.core.roles import ADMIN, FIELD_ROLES, FOREMAN
from src.crud.crud_statistics import crud_statistics, month_period, previous_month
from src.getters.statistics import (
    get_breakdowns_report,
    get_overdue_maintenance_report,
    get_schedule_execution_report,
    get_top_employees_report,
)
from src.schemas.statistics import (
    BreakdownsReport,
    OverdueMaintenanceReport,
    ScheduleExecutionReport,
    TopEmployeesReport,
)
from src.services.breakdowns_pdf import build_breakdowns_pdf
from src.services.employee_score import (
    MIN_WORKS_FOR_RANKING,
    REPEAT_WINDOW_DAYS,
    score_employees,
    score_foremen,
)

router = APIRouter()


@router.get(
    "/statistics/breakdowns",
    response_model=SingleEntityResponse[BreakdownsReport],
    name="breakdowns_statistics",
    summary="Топ поломок за месяц",
    description=(
        "Объекты с наибольшим числом поломок за выбранный месяц, свод по "
        "категориям тяжести и время реакции.\n\n"
        "Поломкой считается заявка, созданная в этом месяце, если её категория "
        "помечена как поломка. Плановые ТО, ПТО, капремонт и ложные вызовы "
        "не учитываются. Заявка без категории учитывается.\n\n"
        "Сортировка: по числу заявок, при равенстве выше объект с более "
        "тяжёлым событием."
    ),
    tags=["Статистика"],
)
def get_breakdowns_statistics(
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.STATISTICS_READ)),
    year: int = Query(..., ge=1990, le=2100, title="Год отчёта"),
    month: int = Query(..., ge=1, le=12, title="Месяц отчёта (1–12)"),
    limit: int = Query(
        5,
        ge=1,
        le=200,
        title="Сколько объектов вернуть",
        description="Карточке на главной хватает пяти, экран подробностей просит больше.",
    ),
    offset: int = Query(0, ge=0, title="Сколько объектов пропустить"),
    division_id: int = Query(None, title="Только объекты этого участка"),
    organization_id: int = Query(None, title="Только объекты этой организации"),
    company_id: int = Query(None, title="Только объекты этой компании"),
    with_previous: bool = Query(
        False,
        title="Добавить сравнение с предыдущим месяцем",
        description="Стоит денег ещё одного запроса, поэтому по умолчанию выключено.",
    ),
    scope=Depends(deps.get_read_scope),
):
    # Временной проверки роли здесь больше нет: клиент пускается в статистику,
    # потому что сводка теперь режется по его компании тем же фильтром, что и
    # списки. Цифры у клиента, прораба и админа будут разными — так и надо.
    return SingleEntityResponse(
        data=_collect_report(
            session=session,
            scope=scope,
            year=year,
            month=month,
            limit=limit,
            offset=offset,
            division_id=division_id,
            organization_id=organization_id,
            company_id=company_id,
            with_previous=with_previous,
        )
    )


@router.get(
    "/statistics/breakdowns/export",
    name="breakdowns_statistics_export",
    summary="Топ поломок за месяц — выгрузка в PDF",
    description=(
        "Тот же отчёт, что и `/statistics/breakdowns`, но файлом.\n\n"
        "Выгружаются все объекты периода, а не первая страница: отчёт печатают "
        "и отправляют заказчику целиком. Сравнение с прошлым месяцем включено "
        "всегда — в бумажном отчёте колонка динамики самая ценная.\n\n"
        "Принимает и заголовок `Authorization`, и короткоживущий `?token=` из "
        "`POST /api/v1/files/export-link` — по нему кнопку «Скачать» можно "
        "сделать обычной ссылкой в новой вкладке."
    ),
    response_class=StreamingResponse,
    tags=["Статистика"],
)
def export_breakdowns_statistics(
    session=Depends(deps.get_db),
    # Не `require(...)`, а `get_link_requester`: файл открывают в новой
    # вкладке, где заголовок `Authorization` не отправить. Право проверяется
    # ниже вручную — зависимость умеет только опознать человека.
    current_user=Depends(deps.get_link_requester),
    year: int = Query(..., ge=1990, le=2100, title="Год отчёта"),
    month: int = Query(..., ge=1, le=12, title="Месяц отчёта (1–12)"),
    division_id: int = Query(None, title="Только объекты этого участка"),
    organization_id: int = Query(None, title="Только объекты этой организации"),
    company_id: int = Query(None, title="Только объекты этой компании"),
    scope=Depends(deps.get_link_scope),
):
    if Permission.STATISTICS_READ not in permissions_for(current_user.role_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Недостаточно прав для этого действия",
        )

    report = _collect_report(
        session=session,
        scope=scope,
        year=year,
        month=month,
        # Без ограничения: в файл идёт весь период.
        limit=None,
        offset=0,
        division_id=division_id,
        organization_id=organization_id,
        company_id=company_id,
        with_previous=True,
    )

    content = build_breakdowns_pdf(report)
    filename = f"breakdowns-{year}-{month:02d}.pdf"

    return StreamingResponse(
        BytesIO(content),
        media_type="application/pdf",
        headers={
            # ASCII-имя для старых клиентов и полное — по RFC 5987. Кириллицу
            # в обычный `filename` класть нельзя: заголовок ходит в latin-1.
            "Content-Disposition": (
                f'attachment; filename="{filename}"; '
                f"filename*=UTF-8''{quote(f'топ-поломок-{year}-{month:02d}.pdf')}"
            ),
            "Content-Length": str(len(content)),
        },
    )


@router.get(
    "/statistics/schedule-execution",
    response_model=SingleEntityResponse[ScheduleExecutionReport],
    name="schedule_execution_statistics",
    summary="Выполнение графика ТО за месяц",
    description=(
        "Доля выполненных ТО за месяц в разрезе участков.\n\n"
        "**План** — заполненные ячейки месяца в графике на этот год. "
        "Отдельного признака «в этом месяце ТО положено» в базе нет: на экране "
        "графика нажатие на месяц сразу создаёт акт, поэтому заведение акта и "
        "есть планирование. Объект, которому ТО на месяц не завели, в план не "
        "попадает — так учитывается разная периодичность обслуживания.\n\n"
        "**Факт** — у акта заполнен `finished_at`. Месяц берётся из ячейки "
        "плана, а не из даты закрытия: ТО за март, закрытое второго апреля, "
        "остаётся выполнением марта и попадает в `completed_late_count`.\n\n"
        "Сортировка: от худшего процента к лучшему."
    ),
    tags=["Статистика"],
)
def get_schedule_execution_statistics(
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.STATISTICS_READ)),
    year: int = Query(..., ge=1990, le=2100, title="Год отчёта"),
    month: int = Query(..., ge=1, le=12, title="Месяц отчёта (1–12)"),
    division_id: int = Query(None, title="Только объекты этого участка"),
    organization_id: int = Query(None, title="Только объекты этой организации"),
    company_id: int = Query(None, title="Только объекты этой компании"),
    scope=Depends(deps.get_read_scope),
):
    period = month_period(year, month)
    rows = crud_statistics.schedule_execution_by_division(
        db=session,
        period=period,
        scope=scope,
        division_id=division_id,
        organization_id=organization_id,
        company_id=company_id,
    )
    # Имена прорабов — вторым запросом и только по участкам из выдачи. В
    # унаследованной ручке запрос уходил на каждый участок отдельно.
    foremen = crud_statistics.foremen_by_division(
        db=session,
        division_ids=[row.division_id for row in rows if row.division_id is not None],
    )
    return SingleEntityResponse(
        data=get_schedule_execution_report(period=period, rows=rows, foremen=foremen)
    )


@router.get(
    "/statistics/overdue-maintenance",
    response_model=SingleEntityResponse[OverdueMaintenanceReport],
    name="overdue_maintenance_statistics",
    summary="Просроченные ТО на сегодня",
    description=(
        "ТО, заведённые в графике, чей плановый месяц уже закончился, а акт "
        "так и не закрыт (`finished_at` пуст).\n\n"
        "Месяца в параметрах нет намеренно: просрочка — это состояние на "
        "сегодня, а не срез периода. Смотрим два года, текущий и предыдущий, "
        "иначе первого января долги обнулялись бы сами собой.\n\n"
        "Строка — одно ТО, то есть пара «объект и плановый месяц». Объект с "
        "тремя пропущенными месяцами придёт тремя строками.\n\n"
        "Сортировка: самые старые сверху. `total_count` считается по всей "
        "выдаче, а не по обрезанному `limit` списку."
    ),
    tags=["Статистика"],
)
def get_overdue_maintenance_statistics(
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.STATISTICS_READ)),
    limit: int = Query(
        5,
        ge=1,
        le=200,
        title="Сколько ТО вернуть",
        description="Карточке на главной хватает пяти.",
    ),
    offset: int = Query(0, ge=0, title="Сколько ТО пропустить"),
    division_id: int = Query(None, title="Только объекты этого участка"),
    organization_id: int = Query(None, title="Только объекты этой организации"),
    company_id: int = Query(None, title="Только объекты этой компании"),
    scope=Depends(deps.get_read_scope),
):
    today = datetime.date.today()
    reference = month_period(today.year, today.month)
    filters = {
        "division_id": division_id,
        "organization_id": organization_id,
        "company_id": company_id,
    }

    rows = crud_statistics.overdue_maintenance(
        db=session,
        reference=reference,
        scope=scope,
        limit=limit,
        offset=offset,
        **filters,
    )
    total_count, objects_affected = crud_statistics.count_overdue_maintenance(
        db=session, reference=reference, scope=scope, **filters
    )

    return SingleEntityResponse(
        data=get_overdue_maintenance_report(
            reference=reference,
            rows=rows,
            total_count=total_count,
            objects_affected=objects_affected,
        )
    )


@router.get(
    "/statistics/top-employees",
    response_model=SingleEntityResponse[TopEmployeesReport],
    name="top_employees_statistics",
    summary="Топ сотрудников за месяц",
    description=(
        "Рейтинг сотрудников баллом 0–100 за выбранный месяц.\n\n"
        "Балл собирается из четырёх метрик и одного штрафа: своевременность "
        "плановых ТО (вес 25), скорость реакции на аварии против норматива "
        "(25), объём и сложность работ (30), надёжность закреплённого парка "
        "(20), минус до 15 баллов за повторные вызовы на тот же лифт в "
        "течение 14 дней после ремонта.\n\n"
        "Шкала — по нормативам, а не относительно лучшего: цифра сравнима "
        "между месяцами. Метрика, которую не из чего посчитать, выпадает, а "
        "её вес распределяется между остальными.\n\n"
        "`kind=mechanic` — механики и инженеры, `kind=foreman` — прорабы, и "
        "он доступен только админу: балл прораба наполовину состоит из "
        "среднего балла его людей.\n\n"
        "Сотрудник с числом работ меньше `min_works` помечается "
        "`is_provisional` и уезжает в конец списка в обоих порядках."
    ),
    tags=["Статистика"],
)
def get_top_employees_statistics(
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.EMPLOYEE_STATS_READ)),
    year: int = Query(..., ge=1990, le=2100, title="Год отчёта"),
    month: int = Query(..., ge=1, le=12, title="Месяц отчёта (1–12)"),
    kind: str = Query(
        "mechanic",
        regex="^(mechanic|foreman)$",
        title="Кого ранжировать",
        description="mechanic — механики и инженеры, foreman — прорабы (только админ).",
    ),
    order: str = Query(
        "best",
        regex="^(best|worst)$",
        title="Порядок",
        description="best — лучшие сверху, worst — худшие сверху.",
    ),
    limit: int = Query(
        5,
        ge=1,
        le=200,
        title="Сколько сотрудников вернуть",
        description="Карточке на главной хватает пяти.",
    ),
    offset: int = Query(0, ge=0, title="Сколько сотрудников пропустить"),
    min_works: int = Query(
        MIN_WORKS_FOR_RANKING,
        ge=0,
        le=100,
        title="Порог активности",
        description=(
            "Меньше этого числа работ за месяц — строка помечается «мало "
            "данных». Ноль отключает порог."
        ),
    ),
    division_id: int = Query(None, title="Только объекты и люди этого участка"),
    organization_id: int = Query(None, title="Только объекты этой организации"),
    company_id: int = Query(None, title="Только объекты этой компании"),
    scope=Depends(deps.get_read_scope),
):
    if kind == "foreman" and current_user.role_id != ADMIN:
        # Прораб не смотрит рейтинг прорабов: половина этого балла — оценка
        # чужих бригад, а сравнение руководителей между собой заказчик
        # оставил за админом.
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Рейтинг прорабов доступен только администратору",
        )

    period = month_period(year, month)
    filters = {
        "division_id": division_id,
        "organization_id": organization_id,
        "company_id": company_id,
    }

    scores = _collect_employee_scores(
        session=session,
        scope=scope,
        period=period,
        kind=kind,
        min_works=min_works,
        filters=filters,
    )

    return SingleEntityResponse(
        data=get_top_employees_report(
            period=period,
            scores=scores,
            kind=kind,
            worst_first=order == "worst",
            min_works=min_works,
            limit=limit,
            offset=offset,
        )
    )


def _collect_employee_scores(
    *,
    session,
    scope,
    period,
    kind: str,
    min_works: int,
    filters: dict,
):
    """Сбор фактов и расчёт балла.

    Механиков считаем всегда — даже когда спросили прорабов: половина балла
    прораба и есть средний балл его людей. Второй раз то же самое считать
    было бы и дороже, и опаснее: два расчёта разошлись бы при первой же
    правке весов.
    """
    median_steps = crud_statistics.median_checklist_steps(db=session)

    mechanics = crud_statistics.rateable_employees(
        db=session,
        scope=scope,
        role_ids=FIELD_ROLES,
        division_id=filters["division_id"],
    )
    orders = crud_statistics.employee_orders(
        db=session, period=period, scope=scope, **filters
    )
    maintenance = crud_statistics.employee_maintenance(
        db=session, period=period, scope=scope, **filters
    )
    objects_per_mechanic = crud_statistics.objects_per_mechanic(
        db=session, scope=scope, **filters
    )
    breakdowns_per_mechanic = crud_statistics.breakdowns_per_mechanic(
        db=session, period=period, scope=scope, **filters
    )
    # Окно поиска повторов шире месяца: авария первого числа следующего
    # месяца — это переделка ремонта, сделанного в конце этого.
    events = crud_statistics.breakdown_events(
        db=session,
        start=period.start,
        end=period.end + datetime.timedelta(days=REPEAT_WINDOW_DAYS),
        scope=scope,
        **filters,
    )

    mechanic_scores = score_employees(
        employees=mechanics,
        orders=orders,
        maintenance=maintenance,
        objects_per_mechanic=objects_per_mechanic,
        breakdowns_per_mechanic=breakdowns_per_mechanic,
        breakdown_events=events,
        median_steps=median_steps,
        period_end=period.end,
        min_works=min_works,
    )

    if kind == "mechanic":
        return mechanic_scores

    foremen = crud_statistics.rateable_employees(
        db=session,
        scope=scope,
        role_ids=frozenset({int(FOREMAN)}),
        division_id=filters["division_id"],
    )
    divisions_by_user = crud_statistics.divisions_by_user(
        db=session, user_ids=[row.user_id for row in foremen]
    )
    all_divisions = sorted(
        {
            division_id
            for divisions in divisions_by_user.values()
            for division_id in divisions
        }
    )

    schedule_rows = crud_statistics.schedule_execution_by_division(
        db=session, period=period, scope=scope, **filters
    )
    schedule_by_division = {
        row.division_id: (int(row.completed_count) / int(row.planned_count))
        for row in schedule_rows
        if row.division_id is not None and int(row.planned_count) > 0
    }

    today = datetime.date.today()
    overdue_by_division = crud_statistics.overdue_per_division(
        db=session,
        reference=month_period(today.year, today.month),
        scope=scope,
        **filters,
    )
    objects_by_division = crud_statistics.objects_per_division(
        db=session, scope=scope, **filters
    )

    return score_foremen(
        foremen=[
            _ForemanInput(
                user_id=row.user_id,
                name=row.name,
                role_id=row.role_id,
                division=row.division,
                division_ids=divisions_by_user.get(row.user_id, []),
            )
            for row in foremen
        ],
        mechanics_by_division=crud_statistics.mechanics_by_division(
            db=session, division_ids=all_divisions
        ),
        mechanic_scores=mechanic_scores,
        schedule_by_division=schedule_by_division,
        overdue_by_division=overdue_by_division,
        objects_by_division=objects_by_division,
        min_works=min_works,
    )


class _ForemanInput(NamedTuple):
    """Прораб со списком участков — строки запроса такого поля не несут."""

    user_id: int
    name: str
    role_id: int
    division: str
    division_ids: List[int]


def _collect_report(
    *,
    session,
    scope,
    year: int,
    month: int,
    limit,
    offset: int,
    division_id,
    organization_id,
    company_id,
    with_previous: bool,
) -> BreakdownsReport:
    """Сборка отчёта, общая для JSON-ручки и выгрузки в PDF.

    Одна на двоих намеренно: если бы каждая собирала отчёт сама, цифры на
    экране и в отправленном заказчику файле однажды разошлись бы, и понять
    почему было бы нечем.
    """
    period = month_period(year, month)
    filters = {
        "division_id": division_id,
        "organization_id": organization_id,
        "company_id": company_id,
    }

    rows = crud_statistics.top_breakdown_objects(
        db=session, period=period, scope=scope, limit=limit, offset=offset, **filters
    )
    total_breakdowns, objects_affected = crud_statistics.count_breakdown_objects(
        db=session, period=period, scope=scope, **filters
    )
    summary_rows = crud_statistics.breakdowns_by_category(
        db=session, period=period, scope=scope, **filters
    )

    object_ids = [row.object_id for row in rows]
    severity_by_object = crud_statistics.object_severity_breakdown(
        db=session, period=period, scope=scope, object_ids=object_ids, **filters
    )

    previous_counts = None
    if with_previous:
        previous_counts = crud_statistics.breakdown_counts_by_object(
            db=session,
            period=month_period(*previous_month(year, month)),
            scope=scope,
            object_ids=object_ids,
            **filters,
        )

    return get_breakdowns_report(
        period=period,
        rows=rows,
        total_breakdowns=total_breakdowns,
        objects_affected=objects_affected,
        summary_rows=summary_rows,
        severity_by_object=severity_by_object,
        previous_counts=previous_counts,
    )


if __name__ == "__main__":
    logging.info("Running...")
