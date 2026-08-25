from pathlib import Path

import httpx
import pytest

from hi_hat_backend.config import Settings
from hi_hat_backend.main import create_app


@pytest.mark.asyncio
async def test_health_is_public(tmp_path: Path) -> None:
    app = create_app(Settings(data_dir=tmp_path / "data", staging_dir=tmp_path / "tmp"))
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/v1/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


@pytest.mark.asyncio
async def test_search_requires_bearer_token(tmp_path: Path) -> None:
    app = create_app(Settings(api_token="secret", data_dir=tmp_path / "data", staging_dir=tmp_path / "tmp"))
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/v1/search", params={"q": "signal"})
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_capabilities_report_authorized_resolver_configuration(tmp_path: Path) -> None:
    app = create_app(
        Settings(
            api_token="secret",
            data_dir=tmp_path / "data",
            staging_dir=tmp_path / "tmp",
            monochrome_unified_api_base_url="https://unified.example",
            monochrome_unified_api_token="authorized-token",
        )
    )
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(
            "/v1/providers/capabilities",
            headers={"Authorization": "Bearer secret"},
        )
    assert response.status_code == 200
    assert response.json()["authorized_unified_resolver"] is True
