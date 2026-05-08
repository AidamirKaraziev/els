"""Смок-тесты API. Расширяйте проверками CRUD и авторизации по мере необходимости."""

import pytest

from src.config import settings


@pytest.mark.integration
def test_settings_use_test_mode():
    assert settings.MODE == "TEST"


@pytest.mark.integration
def test_openapi_json_returns_200(client):
    resp = client.get(f"{settings.API_V1_STR}/openapi.json")
    assert resp.status_code == 200
    assert "openapi" in resp.json()
