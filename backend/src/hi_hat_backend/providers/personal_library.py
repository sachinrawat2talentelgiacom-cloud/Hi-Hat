import asyncio
import hashlib
import shutil
import time
from pathlib import Path

from mutagen.flac import FLAC, FLACNoHeaderError

from hi_hat_backend.models import AudioQuality, ProviderHealth, TrackCandidate
from hi_hat_backend.providers.base import AcquiredFile, MusicProvider, ProgressCallback, ResolvedAudio
from hi_hat_backend.providers.errors import AudioSourceNotFound


class PersonalLibraryProvider(MusicProvider):
    """Indexes user-controlled FLAC folders and copies originals through the normal validation pipeline."""

    name = "personal_library"

    def __init__(self, roots: list[Path]) -> None:
        self.roots = [root.resolve() for root in roots]
        self._paths: dict[str, Path] = {}

    async def search(self, query: str, limit: int = 25) -> list[TrackCandidate]:
        return await asyncio.to_thread(self._search_sync, query, limit)

    def _search_sync(self, query: str, limit: int) -> list[TrackCandidate]:
        terms = query.casefold().split()
        results: list[TrackCandidate] = []
        for root in self.roots:
            if not root.is_dir():
                continue
            for path in root.rglob("*.flac"):
                try:
                    audio = FLAC(path)
                except (FLACNoHeaderError, OSError):
                    continue
                title = str(audio.get("title", [path.stem])[0])
                artist = str(audio.get("artist", audio.get("albumartist", ["Unknown artist"]))[0])
                album = str(audio.get("album", [""])[0]) or None
                haystack = f"{title} {artist} {album or ''}".casefold()
                if terms and not all(term in haystack for term in terms):
                    continue
                track_id = hashlib.sha256(str(path).encode()).hexdigest()
                self._paths[track_id] = path
                results.append(
                    TrackCandidate(
                        id=f"personal_library:{track_id}",
                        provider=self.name,
                        provider_track_id=track_id,
                        title=title,
                        artist=artist,
                        album=album,
                        duration_seconds=float(audio.info.length),
                        available_quality=AudioQuality(
                            codec="FLAC",
                            container="FLAC",
                            lossless=True,
                            bit_depth=audio.info.bits_per_sample,
                            sample_rate=audio.info.sample_rate,
                            channels=audio.info.channels,
                            duration_seconds=float(audio.info.length),
                            label="LOCAL FLAC",
                        ),
                    )
                )
                if len(results) >= limit:
                    return results
        return results

    async def resolve_audio(self, provider_track_id: str, quality_preference: str = "best_lossless") -> ResolvedAudio:
        del quality_preference
        path = self._paths.get(provider_track_id)
        if not path or not path.is_file():
            raise AudioSourceNotFound("The personal-library FLAC is no longer available")
        audio = await asyncio.to_thread(FLAC, path)
        return ResolvedAudio(
            provider_track_id,
            str(path),
            "local",
            expected_size=path.stat().st_size,
            expected_duration_seconds=float(audio.info.length),
        )

    async def acquire(self, resolved: ResolvedAudio, destination: Path, progress: ProgressCallback) -> AcquiredFile:
        source = Path(resolved.acquisition_url)
        if not source.is_file() or not any(source.is_relative_to(root) for root in self.roots):
            raise AudioSourceNotFound("The personal-library source is outside configured roots")
        destination.parent.mkdir(parents=True, exist_ok=True)
        await asyncio.to_thread(shutil.copyfile, source, destination)
        size = destination.stat().st_size
        await progress(size, size)
        return AcquiredFile(destination, resolved.provider_track_id)

    async def health_check(self) -> list[ProviderHealth]:
        started = time.perf_counter()
        return [
            ProviderHealth(
                provider=self.name,
                base_url=str(root),
                healthy=root.is_dir(),
                compatible=root.is_dir(),
                latency_ms=round((time.perf_counter() - started) * 1000),
                last_error=None if root.is_dir() else "Folder not found",
            )
            for root in self.roots
        ]
