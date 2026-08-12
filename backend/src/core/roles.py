"""Роли системы.

Источник истины — этот перечень, а не строки в таблице `roles`. Таблица нужна
внешнему ключу и названиям в интерфейсе; при старте приложение сверяет её с
перечнем и ругается на расхождение.

Роли здесь — должности в лифтовой компании. Они меняются вместе со штатным
расписанием, а не по вторникам, поэтому таблиц `permissions` и
`role_permissions` в проекте нет: права описаны матрицей в
`src/core/permissions.py`.
"""

from enum import IntEnum


class Role(IntEnum):
    ADMIN = 1
    FOREMAN = 2
    MECHANIC = 3
    ENGINEER = 4
    DISPATCHER = 5
    CLIENT = 6

    @property
    def title(self) -> str:
        return _TITLES[self]


_TITLES = {
    Role.ADMIN: "Админ",
    Role.FOREMAN: "Прораб",
    Role.MECHANIC: "Механик",
    Role.ENGINEER: "Инженер наладчик",
    Role.DISPATCHER: "Диспетчер",
    Role.CLIENT: "Клиент",
}

# Прежние имена: на них завязано полсотни модулей. `IntEnum` сравнивается с
# числом как число, поэтому старый код продолжает работать без правок, а новый
# пишется через `Role`.
ADMIN = Role.ADMIN
FOREMAN = Role.FOREMAN
MECHANIC = Role.MECHANIC
ENGINEER = Role.ENGINEER
DISPATCHER = Role.DISPATCHER
CLIENT_ID = Role.CLIENT

# Роли, работающие на объектах: их можно назначить механиком в карточке
# объекта и исполнителем в заявке.
FIELD_ROLES = frozenset({Role.MECHANIC, Role.ENGINEER})

# Наёмные сотрудники — все, кроме клиентов.
EMPLOYEE_ROLES = frozenset(set(Role) - {Role.CLIENT})
