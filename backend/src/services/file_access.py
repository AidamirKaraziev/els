"""Кому какой загруженный файл положен.

Файл наследует доступ от записи, к которой прикреплён: фото заявки видит тот,
кто видит заявку, акт ПТО — тот, кто видит лифт. Владелец определяется по
пути (`src/core/files.py`), дальше в ход идут те же функции области видимости,
что и для самих записей, — чтобы «видно в списке» и «можно скачать» не
разъехались.

**Неизвестная сущность в пути — отказ.** Не «раз правил нет, значит можно»:
файл, положенный в обход `adding_file`, и подобранный адрес выглядят
одинаково, и открывать их по умолчанию нельзя.
"""

from typing import Optional

from sqlalchemy.orm import Session

from src.core.access import (
    AccessScope,
    can_access_act_fact,
    can_access_defective_act,
    can_access_object,
    can_access_order,
    can_access_user,
)
from src.core.files import FileOwner
from src.core.permissions import Permission, permissions_for
from src.models import ActFact, DefectiveAct, Object, Order, UniversalUser

#: Сущности без области видимости: контрагенты, справочники, структура. Их
#: файлы (логотипы, сканы договоров, фото контактных лиц) открыты тому, кому
#: открыта сама сущность, — правом, а не областью.
_BY_PERMISSION = {
    "company": Permission.COUNTERPARTY_READ,
    "organization": Permission.COUNTERPARTY_READ,
    "contract": Permission.COUNTERPARTY_READ,
    "contact_person": Permission.COUNTERPARTY_READ,
    "division": Permission.DIVISION_READ,
}


def can_download(
    *, db: Session, owner: Optional[FileOwner], user: UniversalUser, scope: AccessScope
) -> bool:
    """Можно ли этому человеку скачать файл этой записи."""
    if owner is None:
        return False

    if owner.entity in _BY_PERMISSION:
        return _BY_PERMISSION[owner.entity] in permissions_for(user.role_id)

    if owner.entity == "objects":
        obj = db.query(Object).filter(Object.id == owner.record_id).first()
        return can_access_object(scope, obj)

    if owner.entity == "order_photo":
        # Каталог называется по фотографии, но `id` в пути — это заявка:
        # `adding_file` для фото заявки зовётся с `order_id`. Перепутать легко,
        # а ошибка тихая, поэтому проверяем именно заявку.
        order = db.query(Order).filter(Order.id == owner.record_id).first()
        return can_access_order(scope, order)

    if owner.entity == "act_fact":
        act = db.query(ActFact).filter(ActFact.id == owner.record_id).first()
        return can_access_act_fact(scope, act)

    if owner.entity == "defective_act":
        act = db.query(DefectiveAct).filter(DefectiveAct.id == owner.record_id).first()
        return can_access_defective_act(scope, act)

    if owner.entity == "universal_user":
        # Своё удостоверение человек видит всегда, чужие — по области. Права
        # `USER_READ` тут мало: оно есть у всех сотрудников, а скан документа
        # коллеги с другого участка сотруднику не нужен.
        if owner.record_id == user.id:
            return True
        target = (
            db.query(UniversalUser).filter(UniversalUser.id == owner.record_id).first()
        )
        return can_access_user(scope, target)

    return False
