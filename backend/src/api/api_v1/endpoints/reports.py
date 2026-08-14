"""Раздел «Отчёты»: что делали на объектах за период.

Три ручки. Первая отдаёт картину целиком — сводку, помесячную полосу и
матрицу объектов. Вторая раскрывает один объект: чек-листы актов, дефектные
ведомости и заявки с деталями. Третья отдаёт то же самое файлом Excel.

Вложенность отделена намеренно: на сотне лифтов за год чек-листы всех актов —
это мегабайты, которые экран покажет только по клику на строку.

Отчёт для экрана и отчёт для файла считает **одна функция** `_collect`.
Отличаются они одним параметром: экран просит страницу, файл — все объекты
периода. Две независимые сборки однажды разошлись бы, и объяснить, почему
цифра в отправленном заказчику файле не совпала с экраном, было бы нечем.
Тот же приём — у выгрузки топа поломок.
"""

import datetime
from io import BytesIO
from urllib.parse import quote

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse

from src.api import deps
from src.core.permissions import Permission, permissions_for
from src.core.response import SingleEntityResponse
from src.crud.crud_reports import crud_reports, report_range
from src.getters.reports import get_object_works_report, get_works_report
from src.schemas.reports import ObjectWorksReport, WorksReport
from src.services.reports_pdf import build_works_pdf, works_pdf_filename
from src.services.reports_xlsx import build_works_xlsx, works_filename

router = APIRouter()

#: Предел длины периода. Каждый месяц добавляет ветку в `CASE` и в `UNION ALL`,
#: и на десятилетнем периоде запрос распухает без всякой пользы: отчёты
#: отправляют за год, максимум за два.
_MAX_MONTHS = 36


def _period(date_from: datetime.date, date_to: datetime.date):
    """Границы отчёта с проверками, которые Query выразить не может."""
    if date_to < date_from:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Конец периода раньше начала",
        )

    period = report_range(date_from, date_to)
    if len(period.months) > _MAX_MONTHS:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Период длиннее {_MAX_MONTHS} месяцев",
        )
    return period


def _collect(
    *,
    session,
    scope,
    period,
    limit,
    offset: int = 0,
    with_months: bool = True,
    **filters,
) -> WorksReport:
    """Отчёт целиком. `limit=None` — все объекты отбора, для файла."""
    objects = crud_reports.objects(
        db=session, scope=scope, limit=limit, offset=offset, **filters
    )
    object_ids = [row.object_id for row in objects]
    common = {"db": session, "period": period, "scope": scope}

    return get_works_report(
        period=period,
        objects=objects,
        total_objects=crud_reports.count_objects(db=session, scope=scope, **filters),
        # Итоги и полоса считаются по всему отбору, а не по странице: иначе
        # сводка менялась бы при листании.
        maintenance_totals=crud_reports.maintenance_totals(**common, **filters),
        order_totals=crud_reports.order_totals(**common, **filters),
        defect_total=crud_reports.defect_total(**common, **filters),
        maintenance_months=(
            crud_reports.maintenance_by_month(**common, **filters)
            if with_months
            else []
        ),
        order_months=(
            crud_reports.orders_by_month(**common, **filters) if with_months else []
        ),
        defect_months=(
            crud_reports.defects_by_month(**common, **filters) if with_months else []
        ),
        # Разрезы — только по объектам страницы.
        maintenance_cells=crud_reports.maintenance_cells(
            **common, object_ids=object_ids, **filters
        ),
        order_counts=crud_reports.order_counts(
            **common, object_ids=object_ids, **filters
        ),
        defect_counts=crud_reports.defect_counts(
            **common, object_ids=object_ids, **filters
        ),
    )


@router.get(
    "/reports/works",
    response_model=SingleEntityResponse[WorksReport],
    name="works_report",
    summary="Работы на объектах за период",
    description=(
        "Сводка, помесячная полоса и матрица «объект × месяц» за период.\n\n"
        "**Границы периода у разных работ разные.** Заявки режутся по датам "
        "точно. Плановые ТО — по плановому месяцу целиком: у ячейки графика "
        "нет дня, и резать помесячный план по датам нечем. Период "
        "«15.03 — 20.06» захватывает ТО за весь март и весь июнь; какие "
        "месяцы реально вошли, видно в `period.month_from` и "
        "`period.month_to`.\n\n"
        "**Виды работ.** Авария — заявка, у категории которой взведён "
        "`counts_as_breakdown`; заявка без категории тоже считается аварией. "
        "Обращение заказчика — заявка, заведённая пользователем с ролью "
        "клиента. Прочее — всё остальное. Настоящая поломка остаётся "
        "поломкой, даже если о ней сообщил сам клиент.\n\n"
        "**Объекты берутся все**, включая те, где за период не было ни одной "
        "работы: пустая строка в отчёте — тоже результат.\n\n"
        "Матрица месяцев приходит полной: месяцы без работ есть в `months` "
        "нулями, иначе колонки разъехались бы между строками."
    ),
    tags=["Отчёты"],
)
def get_works_report_endpoint(
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.STATISTICS_READ)),
    date_from: datetime.date = Query(..., title="Начало периода, включительно"),
    date_to: datetime.date = Query(..., title="Конец периода, включительно"),
    limit: int = Query(25, ge=1, le=200, title="Сколько объектов вернуть"),
    offset: int = Query(0, ge=0, title="Сколько объектов пропустить"),
    division_id: int = Query(None, title="Только объекты этого участка"),
    organization_id: int = Query(None, title="Только объекты этой организации"),
    company_id: int = Query(None, title="Только объекты этой компании"),
    object_id: int = Query(None, title="Только этот объект"),
    scope=Depends(deps.get_read_scope),
):
    return SingleEntityResponse(
        data=_collect(
            session=session,
            scope=scope,
            period=_period(date_from, date_to),
            limit=limit,
            offset=offset,
            division_id=division_id,
            organization_id=organization_id,
            company_id=company_id,
            object_id=object_id,
        )
    )


@router.get(
    "/reports/works/export",
    name="works_report_export",
    summary="Работы на объектах за период — выгрузка в Excel или PDF",
    description=(
        "Тот же отчёт, что и `/reports/works`, но файлом. Формат выбирается "
        "параметром `format`.\n\n"
        "**Excel** — четыре листа: «Сводка» с цифрами и помесячной полосой, "
        "дальше «ТО», «Заявки» и «Дефекты» построчно, с автофильтром по "
        "шапке. Это рабочая выгрузка: по ней фильтруют и считают.\n\n"
        "**PDF** — документ для отправки клиенту: шапка с исполнителем и "
        "заказчиком, логотип организации, сводка, матрица месяцев в цветах "
        "графика ТО, место для подписи, дальше подробности по каждому "
        "объекту с чек-листами актов.\n\n"
        "**Фотографии** (`with_photos`) работают только в PDF и по умолчанию "
        "выключены: три снимка по четыре мегабайта на акт превращают годовой "
        "отчёт в файл, который не уйдёт ни по одной почте. Включённые "
        "ужимаются до трети ширины полосы.\n\n"
        "Выгружаются **все объекты отбора**, а не первая страница: файл "
        "отправляют заказчику целиком.\n\n"
        "Принимает и заголовок `Authorization`, и короткоживущий `?token=` из "
        "`POST /api/v1/files/export-link` — по нему кнопку «Скачать» можно "
        "сделать обычной ссылкой в новой вкладке."
    ),
    response_class=StreamingResponse,
    tags=["Отчёты"],
)
def export_works_report(
    session=Depends(deps.get_db),
    # Не `require(...)`, а `get_link_requester`: файл открывают в новой
    # вкладке, где заголовок `Authorization` не отправить. Право проверяется
    # ниже вручную — зависимость умеет только опознать человека.
    current_user=Depends(deps.get_link_requester),
    date_from: datetime.date = Query(..., title="Начало периода, включительно"),
    date_to: datetime.date = Query(..., title="Конец периода, включительно"),
    file_format: str = Query(
        "xlsx", alias="format", regex="^(xlsx|pdf)$", title="Формат файла"
    ),
    with_photos: bool = Query(
        False,
        title="Вкладывать фотографии (только PDF)",
        description="По умолчанию выключено: с фотографиями файл весит сотни мегабайт.",
    ),
    division_id: int = Query(None, title="Только объекты этого участка"),
    organization_id: int = Query(None, title="Только объекты этой организации"),
    company_id: int = Query(None, title="Только объекты этой компании"),
    object_id: int = Query(None, title="Только этот объект"),
    scope=Depends(deps.get_link_scope),
):
    if Permission.STATISTICS_READ not in permissions_for(current_user.role_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Недостаточно прав для этого действия",
        )

    period = _period(date_from, date_to)
    filters = {
        "division_id": division_id,
        "organization_id": organization_id,
        "company_id": company_id,
        "object_id": object_id,
    }

    report = _collect(
        session=session,
        scope=scope,
        period=period,
        # Без ограничения: в файл идёт весь отбор.
        limit=None,
        **filters,
    )
    common = {"db": session, "period": period, "scope": scope}
    details = {
        "maintenance_rows": crud_reports.maintenance_details(**common, **filters),
        "order_rows": crud_reports.order_details(**common, **filters),
        "defect_rows": crud_reports.defect_details(**common, **filters),
    }

    if file_format == "pdf":
        photos = {}
        if with_photos:
            photos = {
                "order_photos": crud_reports.order_photos(**common, **filters),
                "defect_photos": crud_reports.defect_photos(**common, **filters),
            }
        content = build_works_pdf(
            report,
            organization=crud_reports.executor_organization(
                db=session, scope=scope, **filters
            ),
            clients=crud_reports.client_names(db=session, scope=scope, **filters),
            now=period.now,
            with_photos=with_photos,
            **details,
            **photos,
        )
        filename = works_pdf_filename(report)
        media_type = "application/pdf"
    else:
        content = build_works_xlsx(report, now=period.now, **details)
        filename = works_filename(report)
        media_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

    human = (
        f"работы-{period.date_from.isoformat()}-"
        f"{period.date_to.isoformat()}.{file_format}"
    )

    return StreamingResponse(
        BytesIO(content),
        media_type=media_type,
        headers={
            # ASCII-имя для старых клиентов и полное — по RFC 5987. Кириллицу
            # в обычный `filename` класть нельзя: заголовок ходит в latin-1.
            "Content-Disposition": (
                f"attachment; filename=\"{filename}\"; filename*=UTF-8''{quote(human)}"
            ),
            "Content-Length": str(len(content)),
        },
    )


@router.get(
    "/reports/object/{object_id}/works",
    response_model=SingleEntityResponse[ObjectWorksReport],
    name="object_works_report",
    summary="Все работы на одном объекте за период",
    description=(
        "Раскрытая строка отчёта: плановые ТО с чек-листом акта и дефектными "
        "ведомостями, заявки со временем реакции и деталями.\n\n"
        "Три списка, а не один: у ТО и у заявки нет общего набора полей. "
        "Ленту по датам собирает тот, кто показывает, — слиянием списков.\n\n"
        "Чек-лист приходит разобранным из `step_list_fact`. Пустой `steps` "
        "означает, что механик чек-лист не заполнял либо заполнил в формате, "
        "который не читается, — но **не** что работ не было.\n\n"
        "Объект, недоступный по области видимости, отвечает `404`, а не "
        "пустым отчётом: иначе по ответу можно было бы перебором узнать, "
        "какие id существуют."
    ),
    tags=["Отчёты"],
)
def get_object_works_report_endpoint(
    object_id: int,
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.STATISTICS_READ)),
    date_from: datetime.date = Query(..., title="Начало периода, включительно"),
    date_to: datetime.date = Query(..., title="Конец периода, включительно"),
    scope=Depends(deps.get_read_scope),
):
    period = _period(date_from, date_to)

    report = _collect(
        session=session,
        scope=scope,
        period=period,
        limit=1,
        # Полоса по месяцам этой ручке не нужна: она про весь отбор, а здесь
        # отбор — один объект, и его помесячная картина уже в матрице.
        with_months=False,
        object_id=object_id,
    )
    if not report.items:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Объект не найден"
        )

    common = {"db": session, "period": period, "scope": scope}

    return SingleEntityResponse(
        data=get_object_works_report(
            period=period,
            # Та же строка объекта, что и в общем отчёте: считана одним кодом,
            # поэтому итоги в шапке раскрытой строки не могут разойтись с
            # цифрами в матрице.
            obj=report.items[0],
            maintenance=crud_reports.maintenance_details(**common, object_id=object_id),
            orders=crud_reports.order_details(**common, object_id=object_id),
            defects=crud_reports.defect_details(**common, object_id=object_id),
        )
    )
