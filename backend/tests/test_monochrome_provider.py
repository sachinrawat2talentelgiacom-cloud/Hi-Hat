import base64
from pathlib import Path

import httpx
import pytest
import respx

from hi_hat_backend.providers.errors import ProviderAccessDenied
from hi_hat_backend.providers.monochrome import MonochromeProvider


@pytest.mark.asyncio
async def test_browser_helper_returns_controlled_local_flac(tmp_path: Path) -> None:
    acquisition_root = tmp_path / "Acquisitions"
    source = acquisition_root / "job-1" / "incoming.flac"
    source.parent.mkdir(parents=True)
    source.write_bytes(b"fLaC\x00\x00test")
    search_payload = {
        "data": {"items": [{"id": "42", "title": "Signal", "artist": "Aster", "duration": 241}]}
    }
    async with httpx.AsyncClient() as client:
        provider = MonochromeProvider(
            ["https://api.monochrome.tf"],
            client,
            browser_helper_url="http://127.0.0.1:8876",
            browser_acquisition_root=acquisition_root,
        )
        with respx.mock:
            respx.get("https://api.monochrome.tf/search/", params={"s": "Signal"}).mock(
                return_value=httpx.Response(200, json=search_payload)
            )
            respx.get("http://127.0.0.1:8876/health").mock(
                return_value=httpx.Response(200, json={"webview_ready": True})
            )
            respx.post("http://127.0.0.1:8876/acquire").mock(
                return_value=httpx.Response(200, json={"status": "NAVIGATING"})
            )
            respx.get(url__regex=r"http://127\.0\.0\.1:8876/status/.+").mock(
                return_value=httpx.Response(
                    200, json={"status": "READY_FOR_BACKEND", "local_path": str(source)}
                )
            )
            await provider.search("Signal")
            resolved = await provider.resolve_audio("42")

    assert resolved.representation == "local"
    assert resolved.acquisition_url == str(source.resolve())


@pytest.mark.asyncio
async def test_browser_helper_rejects_file_outside_controlled_root(tmp_path: Path) -> None:
    source = tmp_path / "outside.flac"
    source.write_bytes(b"fLaC\x00\x00test")
    acquisition_root = tmp_path / "Acquisitions"
    async with httpx.AsyncClient() as client:
        provider = MonochromeProvider(
            [],
            client,
            browser_helper_url="http://127.0.0.1:8876",
            browser_acquisition_root=acquisition_root,
        )
        with respx.mock:
            respx.get("http://127.0.0.1:8876/health").mock(
                return_value=httpx.Response(200, json={"webview_ready": True})
            )
            respx.post("http://127.0.0.1:8876/acquire").mock(
                return_value=httpx.Response(200, json={"status": "NAVIGATING"})
            )
            respx.get(url__regex=r"http://127\.0\.0\.1:8876/status/.+").mock(
                return_value=httpx.Response(
                    200, json={"status": "READY_FOR_BACKEND", "local_path": str(source)}
                )
            )
            with pytest.raises(Exception, match="controlled folder"):
                await provider.resolve_audio("42")


@pytest.mark.asyncio
async def test_search_normalizes_nested_tracks() -> None:
    payload = {
        "data": {
            "tracks": {
                "items": [
                    {
                        "id": 42,
                        "title": "Signal",
                        "artist": {"name": "Aster"},
                        "album": {"title": "Field Notes", "cover": "abc-def"},
                        "duration": 241,
                        "audioQuality": "HI_RES_LOSSLESS",
                    }
                ]
            }
        }
    }
    async with httpx.AsyncClient() as client:
        provider = MonochromeProvider(["https://api.monochrome.tf"], client)
        with respx.mock:
            route = respx.get("https://api.monochrome.tf/search/", params={"s": "Signal"}).mock(
                return_value=httpx.Response(200, json=payload)
            )
            results = await provider.search("Signal")

    assert len(results) == 1
    assert results[0].provider_track_id == "42"
    assert results[0].artist == "Aster"
    assert results[0].available_quality is not None
    assert results[0].available_quality.lossless is True
    assert results[0].artwork_url == "/v1/artwork/abc-def"
    assert route.called


@pytest.mark.asyncio
async def test_search_fails_over_to_compatible_instance() -> None:
    payload = {"data": {"items": [{"id": "2", "title": "Second", "artist": "Artist"}]}}
    async with httpx.AsyncClient() as client:
        provider = MonochromeProvider(["https://api.monochrome.tf", "https://monochrome-api.samidy.com"], client)
        with respx.mock:
            respx.get("https://api.monochrome.tf/search/", params={"s": "Second"}).mock(
                return_value=httpx.Response(503, json={"error": "down"})
            )
            respx.get("https://monochrome-api.samidy.com/search/", params={"s": "Second"}).mock(
                return_value=httpx.Response(200, json=payload)
            )
            results = await provider.search("Second")

    assert [item.title for item in results] == ["Second"]


@pytest.mark.asyncio
async def test_resolve_rejects_drm_manifest() -> None:
    manifest = '<MPD><ContentProtection schemeIdUri="urn:mpeg:dash:mp4protection:2011"/></MPD>'
    response = {
        "data": {
            "trackId": 42,
            "assetPresentation": "FULL",
            "manifestMimeType": "application/dash+xml",
            "manifest": base64.b64encode(manifest.encode()).decode(),
        }
    }
    async with httpx.AsyncClient() as client:
        provider = MonochromeProvider(["https://api.monochrome.tf"], client)
        with respx.mock:
            respx.get("https://api.monochrome.tf/track/", params={"id": "42"}).mock(
                return_value=httpx.Response(200, json=response)
            )
            with pytest.raises(Exception, match="Encrypted"):
                await provider.resolve_audio("42")


@pytest.mark.asyncio
async def test_resolve_accepts_full_inline_dash_manifest() -> None:
    manifest = "<?xml version='1.0'?><MPD><Period /></MPD>"
    response = {
        "data": {
            "trackId": 42,
            "assetPresentation": "FULL",
            "audioQuality": "HI_RES_LOSSLESS",
            "manifestMimeType": "application/dash+xml",
            "manifest": base64.b64encode(manifest.encode()).decode(),
        }
    }
    async with httpx.AsyncClient() as client:
        provider = MonochromeProvider(["https://api.monochrome.tf"], client)
        with respx.mock:
            respx.get("https://api.monochrome.tf/track/", params={"id": "42"}).mock(
                return_value=httpx.Response(200, json=response)
            )
            resolved = await provider.resolve_audio("42")

    assert resolved.representation == "dash_inline"
    assert resolved.inline_manifest == manifest


@pytest.mark.asyncio
async def test_resolve_rejects_preview_asset() -> None:
    response = {
        "data": {
            "trackId": 42,
            "assetPresentation": "PREVIEW",
            "manifest": base64.b64encode(b"<MPD />").decode(),
        }
    }
    async with httpx.AsyncClient() as client:
        provider = MonochromeProvider(["https://api.monochrome.tf"], client)
        with respx.mock:
            respx.get("https://api.monochrome.tf/track/", params={"id": "42"}).mock(
                return_value=httpx.Response(200, json=response)
            )
            with pytest.raises(ProviderAccessDenied, match="legitimate resolution strategies"):
                await provider.resolve_audio("42")


@pytest.mark.asyncio
async def test_resolve_fails_over_after_single_instance_403() -> None:
    manifest = "<?xml version='1.0'?><MPD><Period /></MPD>"
    response = {
        "data": {
            "trackId": 42,
            "assetPresentation": "FULL",
            "audioQuality": "LOSSLESS",
            "manifestMimeType": "application/dash+xml",
            "manifest": base64.b64encode(manifest.encode()).decode(),
        }
    }
    async with httpx.AsyncClient() as client:
        provider = MonochromeProvider(["https://denied.example", "https://working.example"], client)
        with respx.mock:
            denied = respx.get("https://denied.example/track/", params={"id": "42"}).mock(
                return_value=httpx.Response(403, json={"detail": "denied"})
            )
            working = respx.get("https://working.example/track/", params={"id": "42"}).mock(
                return_value=httpx.Response(200, json=response)
            )
            resolved = await provider.resolve_audio("42")

    assert denied.called
    assert working.called
    assert resolved.representation == "dash_inline"
    assert provider._failures["https://denied.example"] == 1


@pytest.mark.asyncio
async def test_authorized_unified_strategy_succeeds_before_public_instances() -> None:
    envelope = {
        "schema_version": "2.0",
        "playback": [
            {
                "source": "monochrome",
                "kind": "direct",
                "mime_type": "audio/flac",
                "url": "https://audio.monochrome.tf/authorized.flac",
            }
        ],
    }
    async with httpx.AsyncClient() as client:
        provider = MonochromeProvider(
            ["https://public.example"],
            client,
            unified_api_base_url="https://unified.example",
            unified_api_token="user-authorized-token",
        )
        with respx.mock:
            unified = respx.get(
                "https://unified.example/api/v2/track/",
                params={"tidal_id": "42", "quality": "LOSSLESS", "intent": "download"},
                headers={"Authorization": "Bearer user-authorized-token"},
            ).mock(return_value=httpx.Response(200, json=envelope))
            public = respx.get("https://public.example/track/").mock(return_value=httpx.Response(500))
            resolved = await provider.resolve_audio("42")

    assert unified.called
    assert not public.called
    assert resolved.representation == "direct"
    assert resolved.acquisition_url.endswith("authorized.flac")


@pytest.mark.asyncio
async def test_protected_authorized_strategy_does_not_bypass_public_denial() -> None:
    envelope = {
        "schema_version": "2.0",
        "playback": [
            {
                "source": "amazon",
                "url": "https://audio.monochrome.tf/encrypted.mp4",
                "decryption_key": "not-used",
            }
        ],
    }
    async with httpx.AsyncClient() as client:
        provider = MonochromeProvider(
            ["https://public.example"],
            client,
            unified_api_base_url="https://unified.example",
            unified_api_token="user-authorized-token",
        )
        with respx.mock:
            respx.get("https://unified.example/api/v2/track/").mock(return_value=httpx.Response(200, json=envelope))
            respx.get("https://public.example/track/").mock(return_value=httpx.Response(403))
            with pytest.raises(ProviderAccessDenied, match="legitimate resolution strategies"):
                await provider.resolve_audio("42")
