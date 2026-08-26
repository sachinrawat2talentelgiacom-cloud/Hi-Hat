import asyncio
import json
from contextlib import asynccontextmanager
from typing import Annotated

import httpx
from fastapi import Depends, FastAPI, Header, HTTPException, Query, status
from fastapi.responses import FileResponse, Response, StreamingResponse

from hi_hat_backend.config import Settings, get_settings
from hi_hat_backend.downloads import DownloadManager
from hi_hat_backend.models import DownloadJob, DownloadRequest, ProviderHealth, TrackCandidate
from hi_hat_backend.providers.errors import ProviderError
from hi_hat_backend.providers.manager import ProviderManager
from hi_hat_backend.providers.monochrome import MonochromeProvider
from hi_hat_backend.providers.personal_library import PersonalLibraryProvider


class Services:
    def __init__(self, settings: Settings) -> None:
        self.http = httpx.AsyncClient(follow_redirects=True)
        self.monochrome = MonochromeProvider(
            settings.monochrome_api_instances,
            self.http,
            unified_api_base_url=settings.monochrome_unified_api_base_url,
            unified_api_token=settings.monochrome_unified_api_token,
            browser_helper_url=settings.monochrome_browser_helper_url,
            browser_timeout_seconds=settings.monochrome_browser_timeout_seconds,
            browser_acquisition_root=settings.monochrome_browser_acquisition_root,
        )
        self.personal_library = PersonalLibraryProvider(settings.personal_library_roots)
        self.providers = ProviderManager([self.personal_library, self.monochrome])
        self.downloads = DownloadManager(self.providers, settings.staging_dir)

    async def close(self) -> None:
        await self.http.aclose()


def create_app(settings: Settings | None = None) -> FastAPI:
    resolved_settings = settings or get_settings()
    services = Services(resolved_settings)

    @asynccontextmanager
    async def lifespan(_: FastAPI):
        resolved_settings.data_dir.mkdir(parents=True, exist_ok=True)
        resolved_settings.staging_dir.mkdir(parents=True, exist_ok=True)
        yield
        await services.close()

    app = FastAPI(title=resolved_settings.app_name, version="0.1.0", lifespan=lifespan)
    app.state.services = services
    app.state.settings = resolved_settings

    def authorize(authorization: Annotated[str | None, Header()] = None) -> None:
        expected = f"Bearer {resolved_settings.api_token}"
        if authorization != expected:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid API token")

    protected = Depends(authorize)

    @app.get("/v1/health")
    async def health() -> dict[str, str]:
        return {"status": "ok", "service": "hi-hat"}

    @app.get("/v1/provider/status", dependencies=[protected])
    async def provider_status() -> list[ProviderHealth]:
        statuses = await asyncio.gather(*(provider.health_check() for provider in services.providers.providers))
        return [status for provider_statuses in statuses for status in provider_statuses]

    @app.get("/v1/providers/capabilities", dependencies=[protected])
    async def provider_capabilities() -> dict[str, object]:
        capabilities = services.monochrome.capabilities()
        capabilities["personal_library"] = {
            "configured": bool(services.personal_library.roots),
            "roots": len(services.personal_library.roots),
            "automatic": True,
            "full_flac": True,
        }
        capabilities["manual_import"] = True
        return capabilities

    @app.post("/v1/providers/browser/show-auth", dependencies=[protected])
    async def show_browser_auth() -> dict[str, str]:
        helper_url = resolved_settings.monochrome_browser_helper_url
        if not helper_url:
            raise HTTPException(status_code=503, detail="Provider browser helper is not configured")
        try:
            response = await services.http.post(f"{helper_url}/show-auth", timeout=5)
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=503, detail="Provider browser helper is unavailable") from exc
        return {"status": "shown"}

    @app.post("/v1/providers/browser/reset-session", dependencies=[protected])
    async def reset_browser_session() -> dict[str, str]:
        helper_url = resolved_settings.monochrome_browser_helper_url
        if not helper_url:
            raise HTTPException(status_code=503, detail="Provider browser helper is not configured")
        try:
            response = await services.http.post(f"{helper_url}/reset-session", timeout=10)
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=503, detail="Provider browser helper is unavailable") from exc
        return {"status": "reset"}

    @app.get("/v1/search", dependencies=[protected])
    async def search(
        q: Annotated[str, Query(min_length=1, max_length=200)],
        limit: Annotated[int, Query(ge=1, le=50)] = 25,
    ) -> list[TrackCandidate]:
        try:
            local = await services.personal_library.search(q, limit)
            if len(local) >= limit:
                return local
            try:
                remote = await services.monochrome.search(q, limit - len(local))
            except ProviderError:
                if local:
                    return local
                raise
            return [*local, *remote]
        except ProviderError as exc:
            raise HTTPException(
                status_code=503,
                detail={"code": exc.code, "message": str(exc)},
            ) from exc

    @app.post("/v1/downloads", response_model=DownloadJob, status_code=202, dependencies=[protected])
    async def create_download(payload: DownloadRequest) -> DownloadJob:
        try:
            services.providers.get(payload.provider)
        except ValueError as exc:
            raise HTTPException(status_code=400, detail=str(exc)) from exc
        return services.downloads.create(payload)

    @app.get("/v1/downloads/{job_id}", response_model=DownloadJob, dependencies=[protected])
    async def get_download(job_id: str) -> DownloadJob:
        try:
            return services.downloads.get(job_id)
        except KeyError as exc:
            raise HTTPException(status_code=404, detail="Download not found") from exc

    @app.get("/v1/downloads/{job_id}/events", dependencies=[protected])
    async def download_events(job_id: str) -> StreamingResponse:
        try:
            services.downloads.get(job_id)
        except KeyError as exc:
            raise HTTPException(status_code=404, detail="Download not found") from exc

        async def stream():
            async for job in services.downloads.subscribe(job_id):
                yield f"data: {json.dumps(job.model_dump(mode='json'))}\n\n"
                if job.status in {"READY", "COMPLETED", "FAILED", "CANCELLED"}:
                    break

        return StreamingResponse(stream(), media_type="text/event-stream")

    @app.get("/v1/downloads/{job_id}/file", dependencies=[protected])
    async def download_file(job_id: str) -> FileResponse:
        try:
            path = services.downloads.file_path(job_id)
            await services.downloads.mark_transferring(job_id)
        except KeyError as exc:
            raise HTTPException(status_code=404, detail="Download not found") from exc
        except RuntimeError as exc:
            raise HTTPException(status_code=409, detail=str(exc)) from exc
        return FileResponse(path, media_type="audio/flac", filename=f"{job_id}.flac")

    @app.post("/v1/downloads/{job_id}/complete", response_model=DownloadJob, dependencies=[protected])
    async def complete_download(job_id: str) -> DownloadJob:
        try:
            return await services.downloads.complete(job_id)
        except KeyError as exc:
            raise HTTPException(status_code=404, detail="Download not found") from exc

    @app.delete("/v1/downloads/{job_id}", response_model=DownloadJob, dependencies=[protected])
    async def cancel_download(job_id: str) -> DownloadJob:
        try:
            return await services.downloads.cancel(job_id)
        except KeyError as exc:
            raise HTTPException(status_code=404, detail="Download not found") from exc

    @app.get("/v1/artwork/{cover_id}", dependencies=[protected])
    async def artwork(cover_id: str) -> Response:
        if not cover_id.replace("-", "").isalnum():
            raise HTTPException(status_code=400, detail="Invalid artwork identifier")
        last_error: Exception | None = None
        # Try direct Tidal CDN first for standard UUID covers
        if "-" in cover_id or len(cover_id) == 32:
            try:
                clean_uuid = cover_id.replace("-", "/")
                upstream = await services.http.get(
                    f"https://resources.tidal.com/images/{clean_uuid}/640x640.jpg",
                    headers={"User-Agent": "Mozilla/5.0"},
                )
                if upstream.status_code == 200:
                    content_type = upstream.headers.get("content-type", "image/jpeg")
                    return Response(
                        upstream.content,
                        media_type=content_type,
                        headers={"Cache-Control": "private, max-age=86400"},
                    )
            except httpx.HTTPError as exc:
                last_error = exc

        for instance in services.monochrome.instances:
            try:
                upstream = await services.http.get(f"{instance}/cover/", params={"id": cover_id, "size": "640"})
                upstream.raise_for_status()
                content_type = upstream.headers.get("content-type", "")
                if not content_type.startswith("image/"):
                    continue
                return Response(
                    upstream.content,
                    media_type=content_type,
                    headers={"Cache-Control": "private, max-age=86400"},
                )
            except httpx.HTTPError as exc:
                last_error = exc
        raise HTTPException(status_code=502, detail="Artwork unavailable") from last_error

    return app


app = create_app()
