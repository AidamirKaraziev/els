"""Ручка сущности, которая режется по области, обязана эту область объявить.

Брат-близнец `test_every_route_declares_access`, но про другую ошибку. Тот
следит, чтобы ручка не осталась без проверки доступа. Этот — чтобы ручка,
доступ у которой объявлен, не отдавала при этом чужие записи.

Забытый фильтр не падает: ответ приходит, статус 200, в логах чисто, просто
данных больше, чем положено. Заметить это можно только глазами, поэтому здесь
не выборочная проверка, а правило на префикс пути: новая ручка объектов,
заявок, актов, ТО, людей или статистики автоматически обязана зависеть от
`get_read_scope` или `get_write_scope`.

Исключения перечислены поимённо: чтобы выпустить ручку без области, придётся
дописать её сюда, и это будет видно в ревью.
"""

from src.api import deps
from src.main import app

# Префиксы путей сущностей, которые режутся по области видимости.
SCOPED_PREFIXES = (
    "/api/v1/all-objects",
    "/api/v1/object/",
    "/api/v1/order/",
    "/api/v1/order-photo/",
    "/api/v1/all-acts-fact",
    "/api/v1/act-fact/",
    "/api/v1/all-planned-to",
    "/api/v1/planned-to/",
    "/api/v1/defective-act/",
    "/api/v1/defective-act-photo/",
    "/api/v1/statistics/",
    "/api/v1/cp/all-users",
    "/api/v1/cp/all-employee",
    "/api/v1/cp/all-client",
    "/api/v1/cp/client/{company_id}",
    "/api/v1/cp/universal-user/{user_id}",
    "/api/v1/universal-user/sort-by-role",
    "/api/v1/company/clients/",
)

# Ручки под этими префиксами, которым область не нужна. Пока таких нет. Список
# оставлен намеренно: он и есть то место, где будущее исключение придётся
# написать руками — и объяснить в ревью.
WITHOUT_SCOPE: set = set()


def _routes():
    for route in app.routes:
        methods = getattr(route, "methods", None)
        if not methods or not hasattr(route, "dependant"):
            continue
        for method in sorted(methods):
            if method in ("HEAD", "OPTIONS"):
                continue
            yield method, route.path, route


def _declares_scope(route) -> bool:
    """Есть ли в дереве зависимостей ручки область видимости."""
    stack = list(route.dependant.dependencies)
    seen = set()
    while stack:
        dependency = stack.pop()
        call = dependency.call
        if call in (deps.get_read_scope, deps.get_write_scope, deps.get_link_scope):
            return True
        if id(call) in seen:
            continue
        seen.add(id(call))
        stack.extend(dependency.dependencies)
    return False


def _is_scoped_entity(path: str) -> bool:
    return path.startswith(SCOPED_PREFIXES)


def test_every_scoped_route_declares_its_scope():
    forgotten = [
        f"{method} {path}"
        for method, path, route in _routes()
        if _is_scoped_entity(path)
        and (method, path) not in WITHOUT_SCOPE
        and not _declares_scope(route)
    ]
    assert not forgotten, (
        "Ручки сущностей с областью видимости, но без самой области — "
        "они отдают чужие записи и молчат об этом:\n  "
        + "\n  ".join(sorted(forgotten))
        + "\n\nДобавьте Depends(deps.get_read_scope) либо, если ручка "
        "действительно не должна резаться, внесите её в WITHOUT_SCOPE."
    )


def test_exception_list_has_no_stale_entries():
    """Список исключений не должен переживать сами ручки."""
    existing = {(method, path) for method, path, _ in _routes()}
    stale = WITHOUT_SCOPE - existing
    assert not stale, "В списке исключений есть несуществующие ручки: " + ", ".join(
        f"{m} {p}" for m, p in sorted(stale)
    )


def test_the_rule_actually_matches_something():
    """Страховка от опечатки в префиксах.

    Ошибись здесь в пути — тест выше начнёт проходить всегда, ничего не
    проверяя, и это не будет видно.
    """
    matched = [path for _, path, _ in _routes() if _is_scoped_entity(path)]
    assert len(matched) > 30, (
        f"Префиксы поймали всего {len(matched)} ручек — похоже, пути разъехались"
    )
