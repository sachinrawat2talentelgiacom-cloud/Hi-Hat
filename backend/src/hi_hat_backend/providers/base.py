from abc import ABC, abstractmethod
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from pathlib import Path

from hi_hat_backend.models import ProviderHealth, TrackCandidate

ProgressCallback = Callable[[int, int | None], Awaitable[None]]


@dataclass(frozen=True, slots=True)
class ResolvedAudio:
    provider_track_id: str
    acquisition_url: str
    representation: str
    expected_size: int | None = None
    expires_at_epoch: int | None = None
    inline_manifest: str | None = None
    expected_duration_seconds: float | None = None


@dataclass(frozen=True, slots=True)
class AcquiredFile:
    path: Path
    provider_track_id: str


class MusicProvider(ABC):
    name: str

    @abstractmethod
    async def search(self, query: str, limit: int = 25) -> list[TrackCandidate]: ...

    @abstractmethod
    async def resolve_audio(
        self, provider_track_id: str, quality_preference: str = "best_lossless"
    ) -> ResolvedAudio: ...

    @abstractmethod
    async def acquire(self, resolved: ResolvedAudio, destination: Path, progress: ProgressCallback) -> AcquiredFile: ...

    @abstractmethod
    async def health_check(self) -> list[ProviderHealth]: ...
