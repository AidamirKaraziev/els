"""Статистика для главной страницы.

Пока здесь топ поломок. Рядом встанут просроченные ТО, выполнение графиков
и топ сотрудников — период и фильтры у них общие.
"""

import logging
from io import BytesIO
from urllib.parse import quote

from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse

from src.api import deps
from src.core.response import SingleEntityResponse
from src.core.roles import ADMIN, DISPATCHER, ENGINEER, FOREMAN, MECHANIC
from src.crud.crud_statistics import crud_statistics, month_period, previous_month
from src.crud.users.crud_universal_user import crud_universal_users
from src.getters.statistics import get_breakdowns_report
from src.schemas.statistics import BreakdownsReport
from src.services.breakdowns_pdf import build_breakdowns_pdf
from src.templates_raise import get_raise

ALL_EMPLOYER = [ADMIN, FOREMAN, MECHANIC, ENGINEER, DISPATCHER]

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
    current_user=Depends(deps.get_current_universal_user_by_bearer),
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
):
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ALL_EMPLOYER
    )
    get_raise(code=code)

    return SingleEntityResponse(
        data=_collect_report(
            session=session,
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
        "всегда — в бумажном отчёте колонка динамики самая ценная."
    ),
    response_class=StreamingResponse,
    tags=["Статистика"],
)
def export_breakdowns_statistics(
    session=Depends(deps.get_db),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    year: int = Query(..., ge=1990, le=2100, title="Год отчёта"),
    month: int = Query(..., ge=1, le=12, title="Месяц отчёта (1–12)"),
    division_id: int = Query(None, title="Только объекты этого участка"),
    organization_id: int = Query(None, title="Только объекты этой организации"),
    company_id: int = Query(None, title="Только объекты этой компании"),
):
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ALL_EMPLOYER
    )
    get_raise(code=code)

    report = _collect_report(
        session=session,
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


def _collect_report(
    *,
    session,
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
        db=session, period=period, limit=limit, offset=offset, **filters
    )
    total_breakdowns, objects_affected = crud_statistics.count_breakdown_objects(
        db=session, period=period, **filters
    )
    summary_rows = crud_statistics.breakdowns_by_category(
        db=session, period=period, **filters
    )

    object_ids = [row.object_id for row in rows]
    severity_by_object = crud_statistics.object_severity_breakdown(
        db=session, period=period, object_ids=object_ids, **filters
    )

    previous_counts = None
    if with_previous:
        previous_counts = crud_statistics.breakdown_counts_by_object(
            db=session,
            period=month_period(*previous_month(year, month)),
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
