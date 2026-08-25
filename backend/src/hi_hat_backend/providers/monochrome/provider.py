import asyncio
import base64
import json
import time
import uuid
from collections.abc import Iterable
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import httpx

from hi_hat_backend.models import AudioQuality, ProviderHealth, TrackCandidate
from hi_hat_backend.providers.base import (
    AcquiredFile,
    MusicProvider,
    ProgressCallback,
    ResolvedAudio,
)
from hi_hat_backend.providers.errors import (
    AccessRestricted,
    AudioSourceNotFound,
    LosslessNotAvailable,
    ProtectedContent,
    ProviderAccessDenied,
    ProviderResponseChanged,
    ProviderUnavailable,
    PublicInstanceAccessDenied,
)

_ALLOWED_MEDIA_SUFFIXES = (
    ".tidal.com",
    ".monochrome.tf",
    ".samidy.com",
    ".geeked.wtf",
)


class MonochromeProvider(MusicProvider):
    """Current Monochrome/Hi-Fi API adapter.

    Upstream shapes stay here. The public backend and Flutter client consume only
    normalized Hi Hat models.
    """

    name = "monochrome"

    def __init__(
        self,
        instances: list[str],
        client: httpx.AsyncClient | None = None,
        *,
        unified_api_base_url: str | None = None,
        unified_api_token: str | None = None,
        browser_helper_url: str | None = None,
        browser_timeout_seconds: int = 1800,
        browser_acquisition_root: Path | None = None,
    ) -> None:
        self.instances = [item.rstrip("/") for item in instances]
        self.client = client or httpx.AsyncClient(
            follow_redirects=True,
            timeout=httpx.Timeout(connect=5, read=20, write=20, pool=5),
            headers={"User-Agent": "Hi-Hat/0.1 (+personal authorized use)"},
        )
        self._failures = {instance: 0 for instance in self.instances}
        self._track_durations: dict[str, float] = {}
        self._track_metadata: dict[str, TrackCandidate] = {}
        self.unified_api_base_url = unified_api_base_url.rstrip("/") if unified_api_base_url else None
        self.unified_api_token = unified_api_token.strip() if unified_api_token else None
        self.browser_helper_url = browser_helper_url.rstrip("/") if browser_helper_url else None
        self.browser_timeout_seconds = browser_timeout_seconds
        self.browser_acquisition_root = (
            browser_acquisition_root or Path.home() / "AppData/Local/HiHat/Acquisitions"
        ).resolve()

    async def search(self, query: str, limit: int = 25) -> list[TrackCandidate]:
        clean_query = query.strip()
        if not clean_query:
            return []

        last_error: Exception | None = None
        for instance in self._ordered_instances():
            try:
                response = await self._request(instance, "/search/", params={"s": clean_query})
                items = self._search_items(response.json())
                self._failures[instance] = 0
                mapped = [self._map_track(item, instance) for item in items[:limit]]
                self._track_durations.update(
                    {track.provider_track_id: track.duration_seconds for track in mapped if track.duration_seconds}
                )
                self._track_metadata.update({track.provider_track_id: track for track in mapped})
                return mapped
            except (httpx.HTTPError, ValueError, ProviderResponseChanged) as exc:
                self._failures[instance] += 1
                last_error = exc
        raise ProviderUnavailable("No compatible Monochrome instance is available") from last_error

    async def resolve_audio(self, provider_track_id: str, quality_preference: str = "best_lossless") -> ResolvedAudio:
        del quality_preference
        if not provider_track_id or not provider_track_id.replace("-", "").isalnum():
            raise AudioSourceNotFound("Invalid track identifier")

        last_error: Exception | None = None
        access_denied = False
        if self.browser_helper_url:
            try:
                return await self._resolve_browser_acquisition(provider_track_id)
            except (httpx.HTTPError, ValueError, AudioSourceNotFound, ProviderResponseChanged) as exc:
                last_error = exc
        if self.unified_api_base_url and self.unified_api_token:
            try:
                return await self._resolve_authorized_unified(provider_track_id)
            except ProtectedContent as exc:
                access_denied = True
                last_error = exc
            except ProviderAccessDenied as exc:
                access_denied = True
                last_error = exc
            except (httpx.HTTPError, ValueError, AudioSourceNotFound, ProviderResponseChanged) as exc:
                last_error = exc

        for instance in self._ordered_instances():
            try:
                response = await self._request(instance, "/track/", params={"id": provider_track_id})
                resolved = self._resolve_inline_manifest(provider_track_id, response.json())
                self._failures[instance] = 0
                return resolved
            except ProtectedContent:
                raise
            except ProviderAccessDenied as exc:
                self._failures[instance] += 1
                access_denied = True
                last_error = exc
            except (httpx.HTTPError, ValueError, AudioSourceNotFound, ProviderResponseChanged) as exc:
                self._failures[instance] += 1
                last_error = exc
        if access_denied:
            raise ProviderAccessDenied(
                "All configured legitimate resolution strategies denied full-track access"
            ) from last_error
        raise LosslessNotAvailable("No permitted lossless source is available") from last_error

    def capabilities(self) -> dict[str, object]:
        return {
            "provider": self.name,
            "search": bool(self.instances),
            "local_library": True,
            "browser_acquisition": "client_managed",
            "browser_helper": bool(self.browser_helper_url),
            "authorized_unified_resolver": bool(self.unified_api_base_url and self.unified_api_token),
            "public_instances": [
                {
                    "base_url": instance,
                    "search": True,
                    "full_track": "unknown" if self._failures[instance] == 0 else "degraded",
                    "failure_count": self._failures[instance],
                }
                for instance in self.instances
            ],
        }

    async def _resolve_authorized_unified(self, track_id: str) -> ResolvedAudio:
        if not self.unified_api_base_url or not self.unified_api_token:
            raise ProviderUnavailable("The authorized Unified Playback resolver is not configured")
        response = await self.client.get(
            f"{self.unified_api_base_url}/api/v2/track/",
            params={"tidal_id": track_id, "quality": "LOSSLESS", "intent": "download"},
            headers={"Authorization": f"Bearer {self.unified_api_token}", "Accept": "application/json"},
        )
        if response.status_code in {401, 403, 428}:
            raise ProviderAccessDenied("The configured Unified Playback resolver denied access")
        if response.status_code == 404:
            raise AudioSourceNotFound("Unified Playback could not resolve this track")
        response.raise_for_status()
        payload = response.json()
        schema_major = str(payload.get("schema_version", "")).split(".", maxsplit=1)[0]
        if schema_major not in {"1", "2"}:
            raise ProviderResponseChanged("Unsupported Unified Playback response schema")
        resources = payload.get("playback")
        if not isinstance(resources, list):
            raise ProviderResponseChanged("Unified Playback returned no playback list")
        resource = next((item for item in resources if isinstance(item, dict) and item.get("url")), None)
        if not resource:
            raise AudioSourceNotFound("Unified Playback returned no audio resource")
        if resource.get("decryption_key") or resource.get("decryptionKey") or resource.get("drm"):
            raise ProtectedContent("The selected Unified Playback resource is encrypted")
        source_url = str(resource["url"])
        delivery = str(resource.get("delivery") or resource.get("kind") or "").lower()
        mime_type = str(resource.get("mime_type") or "").lower()
        if source_url.startswith("data:application/dash+xml"):
            try:
                encoded = source_url.split(",", maxsplit=1)[1]
                manifest = base64.b64decode(encoded).decode("utf-8")
            except (IndexError, ValueError, UnicodeDecodeError) as exc:
                raise ProviderResponseChanged("Unified Playback returned an invalid DASH manifest") from exc
            if "<ContentProtection" in manifest or "cenc:" in manifest:
                raise ProtectedContent("The selected Unified Playback manifest is encrypted")
            return ResolvedAudio(
                track_id,
                "inline://manifest.mpd",
                "dash_inline",
                inline_manifest=manifest,
                expected_duration_seconds=self._track_durations.get(track_id),
            )
        self._assert_allowed_media_url(source_url)
        if "hls" in delivery or "mpegurl" in mime_type or ".m3u8" in source_url:
            return ResolvedAudio(
                track_id, source_url, "hls", expected_duration_seconds=self._track_durations.get(track_id)
            )
        if "dash" in delivery or "dash" in mime_type or ".mpd" in source_url:
            return ResolvedAudio(
                track_id, source_url, "dash", expected_duration_seconds=self._track_durations.get(track_id)
            )
        return ResolvedAudio(
            track_id, source_url, "direct", expected_duration_seconds=self._track_durations.get(track_id)
        )

    async def acquire(self, resolved: ResolvedAudio, destination: Path, progress: ProgressCallback) -> AcquiredFile:
        destination.parent.mkdir(parents=True, exist_ok=True)
        if resolved.representation == "local":
            source = Path(resolved.acquisition_url).resolve()
            self._assert_controlled_local_flac(source)
            total = source.stat().st_size
            completed = 0
            with source.open("rb") as incoming, destination.open("wb") as target:
                while chunk := await asyncio.to_thread(incoming.read, 256 * 1024):
                    await asyncio.to_thread(target.write, chunk)
                    completed += len(chunk)
                    await progress(completed, total)
            return AcquiredFile(destination, resolved.provider_track_id)
        if resolved.representation == "dash_inline":
            if not resolved.inline_manifest:
                raise AudioSourceNotFound("The inline DASH manifest is missing")
            manifest_path = destination.with_suffix(".mpd")
            try:
                await asyncio.to_thread(manifest_path.write_text, resolved.inline_manifest, encoding="utf-8")
                await self._acquire_dash(str(manifest_path), destination)
            finally:
                manifest_path.unlink(missing_ok=True)
            await progress(destination.stat().st_size, destination.stat().st_size)
            return AcquiredFile(destination, resolved.provider_track_id)

        self._assert_allowed_media_url(resolved.acquisition_url)
        if resolved.representation in {"dash", "hls"}:
            await self._acquire_dash(resolved.acquisition_url, destination)
            await progress(destination.stat().st_size, destination.stat().st_size)
            return AcquiredFile(destination, resolved.provider_track_id)

        async with self.client.stream("GET", resolved.acquisition_url) as response:
            response.raise_for_status()
            total = int(response.headers["content-length"]) if response.headers.get("content-length") else None
            completed = 0
            with destination.open("wb") as target:
                async for chunk in response.aiter_bytes(256 * 1024):
                    target.write(chunk)
                    completed += len(chunk)
                    await progress(completed, total)
        return AcquiredFile(destination, resolved.provider_track_id)

    async def _resolve_browser_acquisition(self, track_id: str) -> ResolvedAudio:
        if not self.browser_helper_url:
            raise AudioSourceNotFound("The browser acquisition helper is not configured")
        health = await self.client.get(f"{self.browser_helper_url}/health", timeout=2)
        health.raise_for_status()
        if not health.json().get("webview_ready"):
            raise AudioSourceNotFound("The browser acquisition helper is still starting")

        track = self._track_metadata.get(track_id)
        acquisition_id = str(uuid.uuid4())
        response = await self.client.post(
            f"{self.browser_helper_url}/acquire",
            json={
                "acquisition_id": acquisition_id,
                "provider_track_id": track_id,
                "title": track.title if track else "Unknown track",
                "artist": track.artist if track else "Unknown artist",
                "album": (track.album or "") if track else "",
                "duration_seconds": (track.duration_seconds or 0) if track else 0,
                "quality": "LOSSLESS",
            },
            timeout=5,
        )
        response.raise_for_status()
        deadline = asyncio.get_running_loop().time() + self.browser_timeout_seconds
        while asyncio.get_running_loop().time() < deadline:
            status_response = await self.client.get(
                f"{self.browser_helper_url}/status/{acquisition_id}", timeout=5
            )
            status_response.raise_for_status()
            job = status_response.json()
            state = str(job.get("status", ""))
            if state == "READY_FOR_BACKEND":
                source = Path(str(job.get("local_path", ""))).resolve()
                self._assert_controlled_local_flac(source)
                return ResolvedAudio(
                    track_id,
                    str(source),
                    "local",
                    expected_duration_seconds=self._track_durations.get(track_id),
                )
            if state in {"FAILED", "CANCELLED"}:
                message = str(job.get("error_message") or "Browser acquisition did not complete")
                raise AudioSourceNotFound(message)
            await asyncio.sleep(0.75)
        await self.client.post(f"{self.browser_helper_url}/cancel/{acquisition_id}", timeout=5)
        raise AudioSourceNotFound("Browser acquisition timed out")

    def _assert_controlled_local_flac(self, path: Path) -> None:
        if path.suffix.lower() != ".flac" or not path.is_file():
            raise AudioSourceNotFound("The browser helper did not produce a FLAC file")
        try:
            path.relative_to(self.browser_acquisition_root)
        except ValueError as exc:
            raise AccessRestricted("The helper returned a file outside its controlled folder") from exc

    def _resolve_inline_manifest(self, track_id: str, payload: dict[str, Any]) -> ResolvedAudio:
        resource = payload.get("data", payload)
        if not isinstance(resource, dict):
            raise ProviderResponseChanged("The provider returned invalid track data")
        presentation = str(resource.get("assetPresentation") or "").upper()
        if presentation and presentation != "FULL":
            raise ProviderAccessDenied("The provider returned only a preview, not a full permitted track")
        encoded_manifest = resource.get("manifest")
        if not isinstance(encoded_manifest, str) or not encoded_manifest:
            raise AudioSourceNotFound("The provider returned no audio manifest")
        try:
            manifest = base64.b64decode(encoded_manifest, validate=True).decode("utf-8").strip()
        except (ValueError, UnicodeDecodeError) as exc:
            raise ProviderResponseChanged("The provider returned an invalid audio manifest") from exc
        if "<ContentProtection" in manifest or "cenc:" in manifest:
            raise ProtectedContent("Encrypted DASH audio is not supported")
        if "<MPD" in manifest:
            return ResolvedAudio(
                track_id,
                "inline://manifest.mpd",
                "dash_inline",
                inline_manifest=manifest,
                expected_duration_seconds=self._track_durations.get(track_id),
            )
        try:
            decoded = json.loads(manifest)
        except json.JSONDecodeError as exc:
            raise AudioSourceNotFound("Unsupported manifest representation") from exc
        urls = decoded.get("urls", []) if isinstance(decoded, dict) else []
        direct_url = next((item for item in urls if isinstance(item, str)), None)
        if not direct_url:
            raise AudioSourceNotFound("The manifest contains no downloadable audio URL")
        self._assert_allowed_media_url(direct_url)
        return ResolvedAudio(
            track_id, direct_url, "direct", expected_duration_seconds=self._track_durations.get(track_id)
        )

    async def health_check(self) -> list[ProviderHealth]:
        async def check(instance: str) -> ProviderHealth:
            started = time.perf_counter()
            try:
                response = await self.client.get(f"{instance}/search/", params={"s": "test"})
                compatible = response.status_code < 500 and response.headers.get("content-type", "").startswith(
                    "application/json"
                )
                return ProviderHealth(
                    provider=self.name,
                    base_url=instance,
                    healthy=response.is_success,
                    compatible=compatible,
                    latency_ms=round((time.perf_counter() - started) * 1000),
                    failure_count=self._failures[instance],
                    last_error=None if response.is_success else f"HTTP {response.status_code}",
                )
            except httpx.HTTPError as exc:
                return ProviderHealth(
                    provider=self.name,
                    base_url=instance,
                    healthy=False,
                    latency_ms=round((time.perf_counter() - started) * 1000),
                    failure_count=self._failures[instance] + 1,
                    last_error=type(exc).__name__,
                )

        return list(await asyncio.gather(*(check(instance) for instance in self.instances)))

    async def close(self) -> None:
        await self.client.aclose()

    async def _request(self, instance: str, path: str, params: dict[str, str]) -> httpx.Response:
        response = await self.client.get(f"{instance}{path}", params=params)
        if response.status_code in {401, 403}:
            raise PublicInstanceAccessDenied("The public instance denied access to this track")
        if response.status_code == 404:
            raise AudioSourceNotFound("The provider could not find this resource")
        response.raise_for_status()
        if "json" not in response.headers.get("content-type", ""):
            raise ProviderResponseChanged("The provider returned an unexpected response type")
        return response

    async def _resolve_manifest(self, track_id: str, payload: dict[str, Any]) -> ResolvedAudio:
        resource = payload.get("data", {}).get("data", payload.get("data", payload))
        attributes = resource.get("attributes", {}) if isinstance(resource, dict) else {}
        if attributes.get("drmData"):
            raise ProtectedContent("Encrypted or DRM-protected audio is not supported")
        manifest_url = attributes.get("uri")
        if not isinstance(manifest_url, str):
            raise AudioSourceNotFound("The provider did not return a manifest URL")
        self._assert_allowed_media_url(manifest_url)
        response = await self.client.get(manifest_url)
        response.raise_for_status()
        manifest = response.text.strip()
        if "<ContentProtection" in manifest or "cenc:" in manifest:
            raise ProtectedContent("Encrypted DASH audio is not supported")
        if "<MPD" in manifest:
            return ResolvedAudio(track_id, manifest_url, "dash")
        try:
            decoded = json.loads(manifest)
        except json.JSONDecodeError:
            try:
                decoded = json.loads(base64.b64decode(manifest).decode("utf-8"))
            except (ValueError, UnicodeDecodeError) as exc:
                raise AudioSourceNotFound("Unsupported manifest representation") from exc
        urls = decoded.get("urls", []) if isinstance(decoded, dict) else []
        direct_url = next((item for item in urls if isinstance(item, str)), None)
        if not direct_url:
            raise AudioSourceNotFound("The manifest contains no downloadable audio URL")
        self._assert_allowed_media_url(direct_url)
        return ResolvedAudio(track_id, direct_url, "direct")

    async def _acquire_dash(self, manifest_url: str, destination: Path) -> None:
        process = await asyncio.create_subprocess_exec(
            "ffmpeg",
            "-nostdin",
            "-v",
            "error",
            "-protocol_whitelist",
            "file,http,https,tcp,tls,crypto",
            "-i",
            manifest_url,
            "-map",
            "0:a:0",
            "-c:a",
            "copy",
            "-y",
            str(destination),
            stdout=asyncio.subprocess.DEVNULL,
            stderr=asyncio.subprocess.PIPE,
        )
        _, stderr = await process.communicate()
        if process.returncode:
            raise AudioSourceNotFound(f"Lossless DASH acquisition failed: {stderr.decode()[-300:]}")

    def _ordered_instances(self) -> Iterable[str]:
        return sorted(self.instances, key=lambda item: self._failures[item])

    @staticmethod
    def _find_section(value: Any, key: str, seen: set[int] | None = None) -> dict[str, Any] | None:
        seen = seen or set()
        if not isinstance(value, (dict, list)) or id(value) in seen:
            return None
        seen.add(id(value))
        if isinstance(value, dict):
            candidate = value.get(key)
            if isinstance(candidate, dict) and isinstance(candidate.get("items"), list):
                return candidate
            if isinstance(value.get("items"), list) and key in value:
                return value
            for child in value.values():
                found = MonochromeProvider._find_section(child, key, seen)
                if found:
                    return found
        else:
            for child in value:
                found = MonochromeProvider._find_section(child, key, seen)
                if found:
                    return found
        return None

    @classmethod
    def _search_items(cls, payload: Any) -> list[dict[str, Any]]:
        if isinstance(payload, dict):
            data = payload.get("data")
            if isinstance(data, dict) and isinstance(data.get("items"), list):
                return [item for item in data["items"] if isinstance(item, dict)]
        section = cls._find_section(payload, "tracks")
        if not section:
            raise ProviderResponseChanged("The Monochrome search response has no track section")
        return [item.get("item", item) for item in section["items"] if isinstance(item, dict)]

    @staticmethod
    def _map_track(item: dict[str, Any], instance: str) -> TrackCandidate:
        track_id = str(item.get("id", ""))
        artist = item.get("artist") or next(iter(item.get("artists") or []), {})
        album = item.get("album") or {}
        artist_name = artist.get("name") if isinstance(artist, dict) else str(artist)
        album_name = album.get("title") if isinstance(album, dict) else str(album)
        cover = album.get("cover") if isinstance(album, dict) else None
        artwork = f"/v1/artwork/{cover}" if cover else None
        quality_name = str(item.get("audioQuality") or "").upper()
        return TrackCandidate(
            id=f"monochrome:{track_id}",
            provider="monochrome",
            provider_track_id=track_id,
            title=str(item.get("title") or "Unknown track"),
            artist=artist_name or "Unknown artist",
            album=album_name or None,
            artwork_url=artwork,
            duration_seconds=item.get("duration"),
            explicit=bool(item.get("explicit")),
            available_quality=AudioQuality(
                codec="FLAC" if "LOSSLESS" in quality_name else None,
                lossless="LOSSLESS" in quality_name,
                label=quality_name or None,
            ),
        )

    @staticmethod
    def _assert_allowed_media_url(url: str) -> None:
        parsed = urlparse(url)
        hostname = (parsed.hostname or "").lower()
        if parsed.scheme != "https" or not any(
            hostname == suffix[1:] or hostname.endswith(suffix) for suffix in _ALLOWED_MEDIA_SUFFIXES
        ):
            raise AccessRestricted("The provider returned a non-allowlisted media URL")
