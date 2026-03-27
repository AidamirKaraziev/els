from datetime import date, datetime
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


def date_from_timestamp(ts: Optional[int]) -> Optional[date]:
    if ts is None:
        return None
    return datetime.utcfromtimestamp(ts).date()


def datetime_from_timestamp(ts: Optional[int]) -> Optional[datetime]:
    if ts is None:
        return None
    return datetime.utcfromtimestamp(ts)
