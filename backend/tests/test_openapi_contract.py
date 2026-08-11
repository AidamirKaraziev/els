"""
Контракт API: клиенты не должны узнавать об изменениях постфактум.

На бэкенде висят два клиента — веб и мобильное приложение из `frontend/`,
поэтому пропавшая ручка или новое обязательное поле ломают людей в проде.
Тест сравнивает текущий OpenAPI с зафиксированным снимком и падает на любом
расхождении.

Снимок описывает **поверхность** API, а не весь документ целиком: пути, методы,
обязательные параметры и обязательные поля тела запроса. Названия и описания
в снимок не входят намеренно — иначе тест падал бы на каждой правке текста,
его бы начали обновлять не глядя, и смысл потерялся бы.

Изменение контракта — это нормально. Ненормально — не заметить его:

    make openapi-update

и в диффе снимка видно ровно то, что меняется для клиентов. Эту правку
показывать в ревью вместе с кодом.
"""

import json
import os
from pathlib import Path

import pytest

_SNAPSHOT = Path(__file__).parent / "snapshots" / "openapi_surface.json"
_HTTP_METHODS = frozenset({"get", "post", "put", "patch", "delete"})


def _required_body_fields(operation: dict, components: dict) -> list:
    """Обязательные поля тела запроса, с раскрытием одного уровня $ref."""
    content = operation.get("requestBody", {}).get("content", {})
    for media in content.values():
        schema = media.get("schema", {})
        ref = schema.get("$ref")
        if ref:
            name = ref.rsplit("/", 1)[-1]
            schema = components.get(name, {})
        return sorted(schema.get("required", []))
    return []


def extract_surface(openapi: dict) -> dict:
    """Срез OpenAPI, который реально важен клиентам."""
    components = openapi.get("components", {}).get("schemas", {})
    surface = {}

    for path, methods in sorted(openapi.get("paths", {}).items()):
        for method, operation in sorted(methods.items()):
            if method.lower() not in _HTTP_METHODS:
                continue
            surface[f"{method.upper()} {path}"] = {
                "required_params": sorted(
                    param["name"]
                    for param in operation.get("parameters", [])
                    if param.get("required")
                ),
                "required_body": _required_body_fields(operation, components),
            }

    return surface


def _describe_changes(expected: dict, actual: dict) -> str:
    removed = sorted(set(expected) - set(actual))
    added = sorted(set(actual) - set(expected))
    changed = sorted(
        route
        for route in set(expected) & set(actual)
        if expected[route] != actual[route]
    )

    lines = []
    if removed:
        lines.append("Пропали ручки (клиенты получат 404 или 405):")
        lines += [f"  - {route}" for route in removed]
    if added:
        lines.append("Появились ручки:")
        lines += [f"  + {route}" for route in added]
    if changed:
        lines.append("Изменились обязательные поля:")
        for route in changed:
            lines.append(f"  ~ {route}")
            lines.append(f"      было:  {expected[route]}")
            lines.append(f"      стало: {actual[route]}")

    lines.append("")
    lines.append("Если изменение осознанное — обновите снимок: make openapi-update")
    return "\n".join(lines)


@pytest.mark.integration
def test_openapi_surface_matches_snapshot(client):
    from src.config import settings

    resp = client.get(f"{settings.API_V1_STR}/openapi.json")
    assert resp.status_code == 200

    actual = extract_surface(resp.json())

    if os.environ.get("UPDATE_OPENAPI_SNAPSHOT") == "1":
        _SNAPSHOT.parent.mkdir(parents=True, exist_ok=True)
        _SNAPSHOT.write_text(
            json.dumps(actual, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        pytest.skip(f"Снимок обновлён: {len(actual)} ручек")

    assert _SNAPSHOT.exists(), (
        f"Нет снимка контракта ({_SNAPSHOT.name}). Создайте: make openapi-update"
    )

    expected = json.loads(_SNAPSHOT.read_text(encoding="utf-8"))

    assert actual == expected, "\n" + _describe_changes(expected, actual)


@pytest.mark.integration
def test_deletion_is_not_done_via_get(client):
    """
    Удаление через GET — то, что мы собираемся починить на этапе 4.

    Тест фиксирует текущий список: пока долг не разобран, он держит планку и не
    даёт добавить новых. Каждая исправленная ручка убирается из списка, и по нему
    видно движение. Дошли до нуля — тест превращается в запрет на регресс.
    """
    known_debt = {
        "/api/v1/locations/{location_id}/",
        "/api/v1/steps/{step_id}/",
        "/api/v1/sub-steps/{sub_step_id}/",
        "/api/v1/working-specialty/{working_specialty_id}/",
    }

    from src.config import settings

    resp = client.get(f"{settings.API_V1_STR}/openapi.json")
    schema = resp.json()

    deleting_gets = {
        path
        for path, methods in schema.get("paths", {}).items()
        for method, operation in methods.items()
        if method.lower() == "get"
        and "удал"
        in (operation.get("summary", "") + operation.get("description", "")).lower()
    }

    new_ones = deleting_gets - known_debt
    assert not new_ones, (
        "Появилась ручка, удаляющая данные по GET. Так делать нельзя: префетч "
        "браузера или поисковый робот сотрёт данные.\n"
        + "\n".join(f"  {path}" for path in sorted(new_ones))
    )

    fixed = known_debt - deleting_gets
    assert not fixed, (
        "Долг уменьшился — уберите эти пути из known_debt в тесте:\n"
        + "\n".join(f"  {path}" for path in sorted(fixed))
    )
