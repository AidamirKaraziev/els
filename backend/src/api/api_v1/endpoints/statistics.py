"""Статистика для главной страницы.

Здесь топ поломок и выполнение графика ТО. Рядом встанут просроченные ТО и
топ сотрудников — период и фильтры у них общие.
"""

import logging
from io import BytesIO
from urllib.parse import quote

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse

from src.api import deps
from src.core.permissions import Permission, permissions_for
from src.core.response import SingleEntityResponse
from src.crud.crud_statistics import crud_statistics, month_period, previous_month
from src.getters.statistics import get_breakdowns_report, get_schedule_execution_report
from src.schemas.statistics import BreakdownsReport, ScheduleExecutionReport
from src.services.breakdowns_pdf import build_breakdowns_pdf

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
