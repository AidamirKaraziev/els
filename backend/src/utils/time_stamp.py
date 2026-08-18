from datetime import date, datetime, timezone
from typing import Optional, Union


def to_timestamp(d: Union[None, datetime, date, int]) -> Optional[int]:
    if d is None:
        return None
    if d is int:
        return d
    if isinstance(d, date):
        dt = datetime(year=d.year, month=d.month, day=d.day)
        return int(dt.timestamp())
    if isinstance(d, datetime):
        dt = d
        result = int(dt.timestamp())
        return result
    else:
        return d


def utc_to_timestamp(d: Optional[datetime]) -> Optional[int]:
    """Метка времени с точностью до секунды, обратная `datetime_from_timestamp`.

    Отдельная функция, а не `to_timestamp`, по двум причинам.

    Во-первых, `to_timestamp` теряет время суток: `datetime` — наследник
    `date`, поэтому первая же ветка там собирает дату заново из года, месяца и
    дня, а часы и минуты выбрасывает. Для `created_at` заявки это давно так и
    никого не смущает, но для метки синхронизации означало бы, что все правки
    за сутки неотличимы.

    Во-вторых, наивное время в базе — это UTC (`datetime.utcnow` в моделях), и
    считать его местным нельзя: клиент прислал бы метку, сдвинутую на часовой
    пояс сервера, и при отрицательном сдвиге часть изменений он бы **не
    получил вовсе**.
    """
    if d is None:
        return None
    return int(d.replace(tzinfo=timezone.utc).timestamp())


def date_from_timestamp(ts: Optional[int]) -> Optional[date]:
    if ts is None:
        return None
    return datetime.utcfromtimestamp(ts).date()


def datetime_from_timestamp(ts: Optional[int]) -> Optional[datetime]:
    if ts is None:
        return None
    return datetime.utcfromtimestamp(ts)
