"""Каждая ручка обязана объявить, кому она доступна.

Смысл теста — не проверить конкретное право, а не дать забыть о нём. Ручка без
объявленного доступа не падает и не ругается: она просто открыта всем, и
заметить это можно только вручную. Именно так в проекте и накопилось 27
открытых ручек.

Публичные ручки перечислены поимённо: чтобы открыть ещё одну, придётся дописать
её сюда, и это будет видно в ревью.
"""

import pytest

from src.api import deps
from src.main import app

# Ручки без токена. Каждая — осознанное решение, а не недосмотр.
PUBLIC = {
    # Вход: токена ещё нет по определению.
    ("POST", "/api/v1/auth/login"),
    # Обновление и выход проверяют не токен доступа, а refresh-токен в теле.
    ("POST", "/api/v1/auth/refresh"),
    ("POST", "/api/v1/auth/logout"),
    # «Забыли пароль»: человек как раз не может войти.
    ("POST", "/api/v1/auth/password/reset-request"),
    ("POST", "/api/v1/auth/password/reset-confirm"),
    # Служебное, добавляется самим FastAPI.
    ("GET", "/api/v1/openapi.json"),
    ("GET", "/docs"),
    ("GET", "/docs/oauth2-redirect"),
    ("GET", "/redoc"),
}

def _routes():
    for route in app.routes:
        methods = getattr(route, "methods", None)
        if not methods:
            continue
        for method in sorted(methods):
            if method in ("HEAD", "OPTIONS"):
                continue
            yield method, route.path, route


def _declares_access(route) -> bool:
    """Есть ли в зависимостях ручки проверка пользователя.

    `require(...)` возвращает вложенную функцию, зависящую от
    `get_current_user`, поэтому обходим дерево зависимостей целиком, а не
    только верхний уровень.
    """
    stack = list(route.dependant.dependencies)
    seen = set()
    while stack:
        dependency = stack.pop()
        call = dependency.call
        if call in (deps.get_current_user, deps.get_link_requester):
            # `get_link_requester` — тот же вход, но умеющий ещё и
            # короткоживущий токен в адресе: заголовок нельзя послать ни из
            # `<img src>`, ни при переходе по ссылке на скачивание.
            return True
        if id(call) in seen:
            continue
        seen.add(id(call))
        stack.extend(dependency.dependencies)
    return False


def test_every_route_requires_authentication():
    unprotected = [
        f"{method} {path}"
        for method, path, route in _routes()
        if (method, path) not in PUBLIC and not _declares_access(route)
    ]
    assert not unprotected, (
        "Ручки без проверки доступа — они открыты всем:\n  "
        + "\n  ".join(sorted(unprotected))
        + "\n\nДобавьте Depends(deps.require(Permission.X)) либо, если ручка "
        "действительно публичная, внесите её в PUBLIC этого теста."
    )


def test_public_list_has_no_stale_entries():
    """Список публичных ручек не должен переживать сами ручки."""
    existing = {(method, path) for method, path, _ in _routes()}
    stale = PUBLIC - existing
    assert not stale, "В списке публичных ручек есть несуществующие: " + ", ".join(
        f"{m} {p}" for m, p in sorted(stale)
    )


@pytest.mark.parametrize(
    "method, path",
    [
        # Выборочная проверка, что расстановка не свелась к «всем всё можно»:
        # у этих ручек право должно быть именно на запись.
        ("POST", "/api/v1/object/"),
        ("POST", "/api/v1/order/"),
        ("PUT", "/api/v1/locations/{location_id}/"),
        ("DELETE", "/api/v1/cp/admin/universal-user/{user_id}/"),
    ],
)
def test_writing_routes_are_guarded(method, path):
    match = [r for m, p, r in _routes() if m == method and p == path]
    assert match, f"Ручка {method} {path} пропала — поправьте тест"
    assert _declares_access(match[0])
