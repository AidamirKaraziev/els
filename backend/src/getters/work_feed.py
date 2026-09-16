from src.schemas.maintenance import MaintenanceObject
from src.schemas.work_feed import (
    NewWorkCategory,
    NewWorkObject,
    NewWorkOpenItem,
    WorkEmployee,
    WorkFeedItem,
    WorkSection,
)
from src.services.checklist import parse_checklist
from src.utils.time_stamp import utc_to_timestamp


def get_work_feed_item(row) -> WorkFeedItem:
    """Строка ленты наружу.

    На входе строка объединённой выборки, а не запись модели: своей таблицы у
    ленты нет. Название регламента берётся из чек-листа общей разборкой —
    форм в базе три, и читать колонку как есть нельзя. Даты —
    `utc_to_timestamp`: `to_timestamp` роняет время суток, а у таймера в
    строке время суток и есть весь смысл.
    """
    return WorkFeedItem(
        kind=row.kind,
        work_id=row.work_id,
        status=row.status,
        act_title=parse_checklist(row.step_list_fact).title
        if row.step_list_fact
        else None,
        object=MaintenanceObject(
            id=row.object_id, name=row.object_name, address=row.object_address
        )
        if row.object_id is not None
        else None,
        object_type=row.object_type,
        task_text=row.task_text,
        performer_id=row.performer_id,
        performer=row.performer,
        performer_phone=row.performer_phone,
        created_at=utc_to_timestamp(row.created_at),
        accepted_at=utc_to_timestamp(row.accepted_at),
        started_at=utc_to_timestamp(row.started_at),
        paused_at=utc_to_timestamp(row.paused_at),
        closed_at=utc_to_timestamp(row.closed_at),
        updated_at=utc_to_timestamp(row.updated_at),
        has_defect=bool(row.has_defect),
        comment=row.comment,
        is_actual=row.is_actual is not False,
        section_id=row.section_id,
        section=row.section,
        reviewed=row.reviewed_at is not None,
        attention=row.attention,
    )


def get_work_section(row) -> WorkSection:
    return WorkSection(id=row[0], title=row[1])


def get_work_employee(row) -> WorkEmployee:
    return WorkEmployee(
        id=row.id,
        name=row.name,
        specialty=row.specialty,
        section_id=row.section_id,
        section=row.section,
        phone=row.phone,
    )


def get_new_work_object(row) -> NewWorkObject:
    return NewWorkObject(
        id=row.id,
        name=row.name,
        address=row.address,
        type=row.type,
        factory_number=row.factory_number,
        registration_number=row.registration_number,
        section_id=row.section_id,
        section=row.section,
        mechanic_id=row.mechanic_id,
        mechanic=row.mechanic,
        foreman=row.foreman,
        contact_name=row.contact_name,
        contact_phone=row.contact_phone,
    )


def category_title(name, code) -> str:
    """«Р (Ремонт по заявке)» → «Ремонт по заявке».

    В справочнике код зашит в имя — так его видит админка. Форме нужны
    порознь: код на бейдж, описание в строку. Имя без такой обёртки
    отдаётся как есть.
    """
    if not name:
        return name
    text = name.strip()
    if code and text.startswith(code):
        rest = text[len(code) :].strip()
        if rest.startswith("(") and rest.endswith(")"):
            return rest[1:-1].strip()
    return text


def get_new_work_category(category) -> NewWorkCategory:
    return NewWorkCategory(
        id=category.id,
        code=category.code,
        name=category_title(category.name, category.code),
        counts_as_breakdown=bool(category.counts_as_breakdown),
    )


def get_new_work_open_item(row) -> NewWorkOpenItem:
    return NewWorkOpenItem(
        kind=row.kind,
        status=row.status,
        title=row.task_text
        or (parse_checklist(row.step_list_fact).title if row.step_list_fact else None),
        performer=row.performer,
    )
