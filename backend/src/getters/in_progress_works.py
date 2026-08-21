from src.schemas.in_progress_works import InProgressWork, WorkProgress, WorkState
from src.schemas.maintenance import MaintenanceObject
from src.services.checklist import parse_checklist
from src.utils.time_stamp import utc_to_timestamp


def get_in_progress_work(row) -> InProgressWork:
    """Строка текущих работ наружу.

    На входе строка выборки, а не запись модели: своей таблицы у ленты нет.

    Чек-лист разбирается общей функцией, а не читается из колонки как есть:
    форм в базе три, и своя разборка здесь разошлась бы с экраном механика.
    Пустой чек-лист даёт пустой `progress` — «пунктов нет» и «ни один не
    отмечен» на экране выглядят одинаково, а значат разное.

    Даты — `utc_to_timestamp`: `to_timestamp` роняет время суток, а у работы,
    начатой сегодня утром, время суток и есть весь смысл.
    """
    checklist = parse_checklist(row.step_list_fact)
    state = WorkState(row.state)

    return InProgressWork(
        kind=row.kind,
        work_id=row.work_id,
        object=MaintenanceObject(
            id=row.object_id, name=row.object_name, address=row.object_address
        )
        if row.object_id is not None
        else None,
        task_text=row.task_text,
        performer=row.performer,
        state=state,
        # У проблемы момента начала состояния нет: механик объявил её когда-то,
        # но когда — в системе не записано. В сортировке вместо него стоит
        # начало работы, а наружу отдавать его нельзя: экран показал бы часы,
        # которые ничего не значат.
        since=None if state is WorkState.PROBLEM else utc_to_timestamp(row.since),
        started_at=utc_to_timestamp(row.started_at),
        reason=row.reason,
        title=checklist.title,
        progress=WorkProgress(done=checklist.done, total=checklist.total)
        if checklist.total
        else None,
    )
