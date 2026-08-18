"""Права и матрица «роль → права».

Проверяется зависимостью на эндпоинте, а не внутри CRUD:

    @router.put("/cp/object/{object_id}/")
    def update_object(user=Depends(require(Permission.OBJECT_UPDATE)), ...):

Так доступ виден прямо в сигнатуре ручки, попадает в OpenAPI и не может быть
случайно пропущен — без зависимости эндпоинт просто не получит пользователя.
Раньше проверки жили в CRUD магическими числами (`if user.role_id != 1`), и
ручка, не проходившая через «правильный» CRUD-метод, молча оказывалась
открытой.

Право отвечает на вопрос «можно ли ему такое действие вообще». На вопрос «над
какими именно записями» отвечает область видимости — `src/core/access.py`.
Оба нужны: прораб имеет право менять объекты, но только на своих участках.

Договорённости, которые кодирует матрица: [[матрица прав по ролям]] в vault.
"""

from enum import Enum
from typing import Dict, FrozenSet

from src.core.roles import Role


class Permission(str, Enum):
    # Пользователи
    USER_READ = "user:read"
    USER_CREATE = "user:create"
    USER_UPDATE = "user:update"
    USER_ARCHIVE = "user:archive"
    USER_DELETE = "user:delete"

    # Объекты (лифты)
    OBJECT_READ = "object:read"
    OBJECT_CREATE = "object:create"
    OBJECT_UPDATE = "object:update"
    OBJECT_DELETE = "object:delete"

    # Заявки
    ORDER_READ = "order:read"
    ORDER_CREATE = "order:create"
    ORDER_UPDATE = "order:update"
    # Перевод в «Выполнено» — отдельно от обычного изменения: диспетчер ведёт
    # заявку, но закрывает её исполнитель или прораб.
    ORDER_CLOSE = "order:close"
    # Мягкое удаление. Отдельно от `*_DELETE`, как у пользователей: настоящий
    # `DELETE` необратим и остаётся у админа, а убрать ошибочную запись из
    # списков должен уметь и прораб.
    ORDER_ARCHIVE = "order:archive"
    ORDER_DELETE = "order:delete"

    # Акты: шаблоны, фактические, дефектные ведомости
    ACT_READ = "act:read"
    ACT_CREATE = "act:create"
    ACT_UPDATE = "act:update"
    ACT_ARCHIVE = "act:archive"
    ACT_DELETE = "act:delete"

    # Отметка «проверил» на сданной работе. Отдельно от `act:update` и
    # `order:update`: править акт и заявку по работе может тот, кто её делал,
    # а отмечать проверенной — только тот, кто проверяет. Иначе механик
    # закрывал бы собственный счётчик у прораба.
    WORK_REVIEW = "work:review"

    # Плановые ТО
    PLANNED_TO_READ = "planned_to:read"
    PLANNED_TO_WRITE = "planned_to:write"
    PLANNED_TO_ARCHIVE = "planned_to:archive"

    # Контрагенты: компании-клиенты, наши юрлица, договоры, контактные лица
    COUNTERPARTY_READ = "counterparty:read"
    COUNTERPARTY_WRITE = "counterparty:write"

    # Участки
    DIVISION_READ = "division:read"
    DIVISION_WRITE = "division:write"

    # Справочники: города, типы объектов и договоров, причины и категории
    # неисправностей, специальности, модели техники, статусы, этапы
    DIRECTORY_READ = "directory:read"
    DIRECTORY_WRITE = "directory:write"

    # Статистика на главной
    STATISTICS_READ = "statistics:read"
    # Рейтинг сотрудников — отдельно от остальной статистики. Клиенту
    # внутренний рейтинг подрядчика не показываем, механику — его собственное
    # место в списке худших.
    EMPLOYEE_STATS_READ = "employee_stats:read"

    # Файлы: фото заявок, сканы, PDF
    FILE_READ = "file:read"
    FILE_UPLOAD = "file:upload"


# Что доступно любому, кто вошёл в систему. Своё видят все, иначе человек не
# сможет открыть собственный профиль.
_BASE: FrozenSet[Permission] = frozenset(
    {
        Permission.DIRECTORY_READ,
        Permission.FILE_READ,
        Permission.STATISTICS_READ,
    }
)

# Читать людей и объекты может любой сотрудник: без списка механиков нельзя
# назначить исполнителя, без карточки объекта — приехать на вызов. Границу
# «кого именно видно» держит область видимости, а не право.
_EMPLOYEE_READ: FrozenSet[Permission] = _BASE | {
    Permission.USER_READ,
    Permission.OBJECT_READ,
    Permission.ORDER_READ,
    Permission.ACT_READ,
    Permission.PLANNED_TO_READ,
    Permission.COUNTERPARTY_READ,
    Permission.DIVISION_READ,
}

# Работа на объекте: механик и инженер-наладчик делают одно и то же, отличаясь
# только тем, на какие объекты их можно назначить.
_FIELD_WORK: FrozenSet[Permission] = _EMPLOYEE_READ | {
    Permission.ORDER_UPDATE,
    Permission.ORDER_CLOSE,
    Permission.ACT_CREATE,
    Permission.ACT_UPDATE,
    Permission.FILE_UPLOAD,
}

ROLE_PERMISSIONS: Dict[Role, FrozenSet[Permission]] = {
    Role.ADMIN: frozenset(Permission),
    Role.FOREMAN: _FIELD_WORK
    | {
        Permission.OBJECT_CREATE,
        Permission.OBJECT_UPDATE,
        Permission.ORDER_CREATE,
        Permission.PLANNED_TO_WRITE,
        Permission.COUNTERPARTY_WRITE,
        # Прораб ведёт своих людей: заводит механиков на свои участки и
        # архивирует уволившихся. Удалять не может — удаление пользователя
        # обнуляет автора у его заявок.
        Permission.USER_CREATE,
        Permission.USER_UPDATE,
        Permission.USER_ARCHIVE,
        # Мягкое удаление работы и графика — там же, где право заводить их.
        # Механику не даём: убрать заявку, которую не хочется делать, он бы
        # смог, а заметить это было бы некому.
        Permission.ORDER_ARCHIVE,
        Permission.ACT_ARCHIVE,
        Permission.PLANNED_TO_ARCHIVE,
        # Рейтинг своих механиков: прораб видит людей своих участков, режет
        # выдачу область видимости.
        Permission.EMPLOYEE_STATS_READ,
        # Лента сданных работ: прораб смотрит, что сдали за него люди, и
        # гасит счётчик отметкой «проверил».
        Permission.WORK_REVIEW,
    },
    Role.MECHANIC: _FIELD_WORK,
    Role.ENGINEER: _FIELD_WORK,
    Role.DISPATCHER: _EMPLOYEE_READ
    | {
        Permission.ORDER_CREATE,
        Permission.ORDER_UPDATE,
        Permission.FILE_UPLOAD,
        # ORDER_CLOSE намеренно нет: диспетчер принимает и ведёт заявку, а
        # «Выполнено» ставит тот, кто работал.
    },
    Role.CLIENT: _BASE
    | {
        Permission.OBJECT_READ,
        Permission.ORDER_READ,
        Permission.ORDER_CREATE,
    },
}


def permissions_for(role_id: int) -> FrozenSet[Permission]:
    """Права роли. Неизвестная роль не получает ничего.

    В базе `role_id` обнуляемый (`ondelete="SET NULL"`), так что сюда может
    прийти `None` — и это должно означать «прав нет», а не исключение в
    середине запроса.
    """
    try:
        role = Role(role_id)
    except ValueError:
        return frozenset()
    return ROLE_PERMISSIONS.get(role, frozenset())


def has_permission(role_id: int, permission: Permission) -> bool:
    return permission in permissions_for(role_id)
