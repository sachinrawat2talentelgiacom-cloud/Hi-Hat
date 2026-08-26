from datetime import UTC, datetime
from enum import StrEnum

from pydantic import BaseModel, Field


class AudioQuality(BaseModel):
    codec: str | None = None
    container: str | None = None
    lossless: bool = False
    bit_depth: int | None = None
    sample_rate: int | None = None
    channels: int | None = None
    bitrate: int | None = None
    duration_seconds: float | None = None
    label: str | None = None


class TrackCandidate(BaseModel):
    id: str
    provider: str
    provider_track_id: str
    title: str
    artist: str
    album: str | None = None
    artwork_url: str | None = None
    duration_seconds: float | None = None
    explicit: bool = False
    available_quality: AudioQuality | None = None
    year: str | None = None
    track_number: int | None = None
    disc_number: int | None = None
    genre: str | None = None
    bpm: int | None = None
    key: str | None = None
    isrc: str | None = None
    copyright: str | None = None
    replay_gain: float | None = None
    peak: float | None = None
    version: str | None = None
    vibrant_color: str | None = None


class ProviderHealth(BaseModel):
    provider: str
    base_url: str
    healthy: bool
    compatible: bool = False
    latency_ms: int | None = None
    failure_count: int = 0
    last_error: str | None = None
    last_check: datetime = Field(default_factory=lambda: datetime.now(UTC))


class DownloadStatus(StrEnum):
    QUEUED = "QUEUED"
    RESOLVING = "RESOLVING"
    DOWNLOADING = "DOWNLOADING"
    VERIFYING = "VERIFYING"
    READY = "READY"
    TRANSFERRING = "TRANSFERRING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"


class DownloadRequest(BaseModel):
    provider: str = "monochrome"
    provider_track_id: str
    preferred_quality: str = "best_lossless"


class DownloadJob(BaseModel):
    id: str
    track_id: str
    status: DownloadStatus = DownloadStatus.QUEUED
    progress: float = 0
    bytes_downloaded: int = 0
    total_bytes: int | None = None
    speed_bytes_per_second: float | None = None
    error_code: str | None = None
    error_message: str | None = None
    sha256: str | None = None
    file_size: int | None = None
    quality: AudioQuality | None = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
