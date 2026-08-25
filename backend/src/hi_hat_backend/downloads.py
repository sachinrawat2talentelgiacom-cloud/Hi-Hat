import asyncio
import contextlib
import time
from datetime import UTC, datetime
from pathlib import Path
from uuid import uuid4

import httpx

from hi_hat_backend.models import DownloadJob, DownloadRequest, DownloadStatus
from hi_hat_backend.providers.errors import ProviderError
from hi_hat_backend.providers.manager import ProviderManager
from hi_hat_backend.validation import InvalidAudioFile, validate_audio


class DownloadManager:
    def __init__(self, providers: ProviderManager, staging_dir: Path) -> None:
        self.providers = providers
        self.staging_dir = staging_dir
        self.jobs: dict[str, DownloadJob] = {}
        self.paths: dict[str, Path] = {}
        self.events: dict[str, list[asyncio.Queue[DownloadJob]]] = {}
        self.tasks: dict[str, asyncio.Task[None]] = {}

    def create(self, request: DownloadRequest) -> DownloadJob:
        existing = next(
            (
                job
                for job in self.jobs.values()
                if job.track_id == request.provider_track_id
                and job.status not in {DownloadStatus.FAILED, DownloadStatus.CANCELLED}
            ),
            None,
        )
        if existing:
            return existing
        job = DownloadJob(id=uuid4().hex, track_id=request.provider_track_id)
        self.jobs[job.id] = job
        self.tasks[job.id] = asyncio.create_task(self._run(job, request))
        return job

    def get(self, job_id: str) -> DownloadJob:
        try:
            return self.jobs[job_id]
        except KeyError as exc:
            raise KeyError("Download not found") from exc

    def file_path(self, job_id: str) -> Path:
        job = self.get(job_id)
        if job.status not in {DownloadStatus.READY, DownloadStatus.TRANSFERRING}:
            raise RuntimeError("Download is not ready for transfer")
        return self.paths[job_id]

    async def mark_transferring(self, job_id: str) -> DownloadJob:
        return await self._update(self.get(job_id), status=DownloadStatus.TRANSFERRING)

    async def complete(self, job_id: str) -> DownloadJob:
        return await self._update(self.get(job_id), status=DownloadStatus.COMPLETED, progress=1)

    async def cancel(self, job_id: str) -> DownloadJob:
        job = self.get(job_id)
        task = self.tasks.get(job_id)
        if task and not task.done():
            task.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await task
        path = self.paths.get(job_id)
        if path:
            path.unlink(missing_ok=True)
        return await self._update(job, status=DownloadStatus.CANCELLED)

    async def subscribe(self, job_id: str):
        queue: asyncio.Queue[DownloadJob] = asyncio.Queue(maxsize=8)
        self.events.setdefault(job_id, []).append(queue)
        try:
            yield self.get(job_id)
            while True:
                yield await queue.get()
        finally:
            self.events[job_id].remove(queue)

    async def _run(self, job: DownloadJob, request: DownloadRequest) -> None:
        provider = self.providers.get(request.provider)
        partial = self.staging_dir / f"{job.id}.part"
        destination = self.staging_dir / f"{job.id}.flac"
        started = time.monotonic()
        try:
            await self._update(job, status=DownloadStatus.RESOLVING)
            resolved = await provider.resolve_audio(request.provider_track_id, request.preferred_quality)
            await self._update(job, status=DownloadStatus.DOWNLOADING)

            async def progress(completed: int, total: int | None) -> None:
                elapsed = max(time.monotonic() - started, 0.001)
                normalized = min(completed / total, 0.94) if total else job.progress
                await self._update(
                    job,
                    bytes_downloaded=completed,
                    total_bytes=total,
                    progress=normalized,
                    speed_bytes_per_second=completed / elapsed,
                )

            acquired = await provider.acquire(resolved, partial, progress)
            await self._update(job, status=DownloadStatus.VERIFYING, progress=0.96)
            digest, quality = await validate_audio(acquired.path, resolved.expected_duration_seconds)
            await asyncio.to_thread(acquired.path.replace, destination)
            self.paths[job.id] = destination
            await self._update(
                job,
                status=DownloadStatus.READY,
                progress=1,
                sha256=digest,
                file_size=destination.stat().st_size,
                quality=quality,
            )
        except asyncio.CancelledError:
            partial.unlink(missing_ok=True)
            destination.unlink(missing_ok=True)
            raise
        except (ProviderError, InvalidAudioFile, httpx.HTTPError) as exc:
            partial.unlink(missing_ok=True)
            destination.unlink(missing_ok=True)
            code = getattr(exc, "code", "DOWNLOAD_FAILED")
            await self._update(
                job,
                status=DownloadStatus.FAILED,
                error_code=code,
                error_message=str(exc),
            )
        except Exception:  # defensive boundary: raw errors stay server-side
            partial.unlink(missing_ok=True)
            destination.unlink(missing_ok=True)
            await self._update(
                job,
                status=DownloadStatus.FAILED,
                error_code="DOWNLOAD_FAILED",
                error_message="The download failed. Try again.",
            )

    async def _update(self, job: DownloadJob, **changes: object) -> DownloadJob:
        changes["updated_at"] = datetime.now(UTC)
        updated = job.model_copy(update=changes)
        self.jobs[job.id] = updated
        for queue in self.events.get(job.id, []):
            if queue.full():
                with contextlib.suppress(asyncio.QueueEmpty):
                    queue.get_nowait()
            queue.put_nowait(updated)
        return updated
