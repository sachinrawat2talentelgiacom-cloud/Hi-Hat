from pathlib import Path

import pytest

from hi_hat_backend.providers.personal_library import PersonalLibraryProvider
from hi_hat_backend.validation import FullTrackNotAvailable, validate_audio

FIXTURE = Path(__file__).parent / "assets" / "player_test.flac"


@pytest.mark.asyncio
async def test_cc0_fixture_is_a_complete_valid_flac() -> None:
    digest, quality = await validate_audio(FIXTURE)

    assert len(digest) == 64
    assert quality.codec == "FLAC"
    assert quality.lossless is True
    assert quality.sample_rate and quality.sample_rate > 0
    assert quality.bit_depth and quality.bit_depth > 0
    assert quality.duration_seconds and quality.duration_seconds > 0


@pytest.mark.asyncio
async def test_duration_mismatch_rejects_preview() -> None:
    with pytest.raises(FullTrackNotAvailable):
        await validate_audio(FIXTURE, expected_duration_seconds=180)


@pytest.mark.asyncio
async def test_personal_library_search_resolve_and_copy(tmp_path: Path) -> None:
    library = tmp_path / "owned"
    library.mkdir()
    source = library / "Drippy.flac"
    source.write_bytes(FIXTURE.read_bytes())
    provider = PersonalLibraryProvider([library])

    results = await provider.search("gapless")
    assert len(results) == 1
    assert results[0].provider == "personal_library"
    assert results[0].available_quality and results[0].available_quality.lossless

    resolved = await provider.resolve_audio(results[0].provider_track_id)
    destination = tmp_path / "download.part"
    progress_events: list[tuple[int, int | None]] = []

    async def progress(completed: int, total: int | None) -> None:
        progress_events.append((completed, total))

    acquired = await provider.acquire(resolved, destination, progress)
    _, quality = await validate_audio(acquired.path, resolved.expected_duration_seconds)

    assert acquired.path.read_bytes() == source.read_bytes()
    assert quality.codec == "FLAC"
    assert progress_events[-1][0] == source.stat().st_size
