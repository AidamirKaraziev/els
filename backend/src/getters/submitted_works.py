from src.schemas.maintenance import MaintenanceObject
from src.schemas.submitted_works import SubmittedWork
from src.utils.time_stamp import utc_to_timestamp


def get_submitted_work(row) -> SubmittedWork:
    """Строка ленты наружу.

    На входе строка объединённой выборки, а не запись модели: у ленты нет
    своей таблицы, ТО и заявка приезжают в ней общими колонками.

    Даты переводятся `utc_to_timestamp`: обе метки пишутся в UTC, а `to_timestamp`
    роняет время суток — для ленты, упорядоченной по времени сдачи, это
    означало бы кучу работ, сданных «в полночь».
    """
    return SubmittedWork(
        kind=row.kind,
        work_id=row.work_id,
        object=MaintenanceObject(
            id=row.object_id, name=row.object_name, address=row.object_address
        )
        if row.object_id is not None
        else None,
        task_text=row.task_text,
        performer=row.performer,
        closed_at=utc_to_timestamp(row.closed_at),
        reviewed_at=utc_to_timestamp(row.reviewed_at),
        reviewer=row.reviewer,
    )
