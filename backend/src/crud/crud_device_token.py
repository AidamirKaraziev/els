"""Токены устройств: регистрация, снятие, выборка для отправки.

Без `CRUDBase`: здесь нет ни областей видимости, ни постраничных списков —
токен виден только серверу, наружу отдаётся лишь факт «зарегистрирован».
"""

from typing import Iterable, List

from sqlalchemy.orm import Session

from src.models import DeviceToken


def upsert(db: Session, *, user_id: int, token: str, platform: str) -> DeviceToken:
    """Записать токен за пользователем.

    Токен уже есть — перевесить на нового хозяина и обновить `updated_at`:
    тот же телефон, но вошёл другой человек. Дублей не бывает по `UNIQUE`.
    """
    record = db.query(DeviceToken).filter(DeviceToken.token == token).first()
    if record is None:
        record = DeviceToken(user_id=user_id, token=token, platform=platform)
        db.add(record)
    else:
        record.user_id = user_id
        record.platform = platform
    db.commit()
    db.refresh(record)
    return record


def delete(db: Session, *, user_id: int, token: str) -> bool:
    """Снять токен при выходе. Чужой токен не трогаем — отвечаем «не было»."""
    deleted = (
        db.query(DeviceToken)
        .filter(DeviceToken.token == token, DeviceToken.user_id == user_id)
        .delete(synchronize_session=False)
    )
    db.commit()
    return deleted > 0


def tokens_for_users(db: Session, user_ids: Iterable[int]) -> List[str]:
    ids = [i for i in set(user_ids) if i is not None]
    if not ids:
        return []
    rows = db.query(DeviceToken.token).filter(DeviceToken.user_id.in_(ids)).all()
    return [row[0] for row in rows]


def drop_tokens(db: Session, tokens: Iterable[str]) -> int:
    """Убрать токены, о которых FCM сказал «такого устройства больше нет»."""
    tokens = list(tokens)
    if not tokens:
        return 0
    deleted = (
        db.query(DeviceToken)
        .filter(DeviceToken.token.in_(tokens))
        .delete(synchronize_session=False)
    )
    db.commit()
    return deleted
