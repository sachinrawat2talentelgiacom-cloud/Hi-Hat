import asyncio
import hashlib
import json
import shutil
from pathlib import Path

from mutagen.flac import FLAC, FLACNoHeaderError

from hi_hat_backend.models import AudioQuality


class InvalidAudioFile(RuntimeError):
    code = "DOWNLOAD_VALIDATION_FAILED"


class FullTrackNotAvailable(InvalidAudioFile):
    code = "FULL_TRACK_NOT_AVAILABLE"


async def validate_audio(path: Path, expected_duration_seconds: float | None = None) -> tuple[str, AudioQuality]:
    if not path.is_file() or path.stat().st_size < 1024:
        raise InvalidAudioFile("Audio file is missing or incomplete")

    digest = await asyncio.to_thread(_sha256, path)
    try:
        flac = await asyncio.to_thread(FLAC, path)
    except FLACNoHeaderError as exc:
        raise InvalidAudioFile("Downloaded file is not a valid FLAC") from exc

    duration = float(flac.info.length)
    if expected_duration_seconds and abs(duration - expected_duration_seconds) > max(
        8, expected_duration_seconds * 0.08
    ):
        raise FullTrackNotAvailable("The acquired audio duration does not match the full track")

    ffprobe = shutil.which("ffprobe")
    if not ffprobe:
        return digest, AudioQuality(
            codec="FLAC",
            container="FLAC",
            lossless=True,
            sample_rate=flac.info.sample_rate,
            bit_depth=flac.info.bits_per_sample,
            channels=flac.info.channels,
            bitrate=flac.info.bitrate,
            duration_seconds=duration,
            label="verified",
        )

    process = await asyncio.create_subprocess_exec(
        ffprobe,
        "-v",
        "error",
        "-select_streams",
        "a:0",
        "-show_entries",
        "stream=codec_name,sample_rate,bits_per_raw_sample,channels,bit_rate",
        "-of",
        "json",
        str(path),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, _ = await process.communicate()
    if process.returncode:
        raise InvalidAudioFile("ffprobe could not decode the downloaded file")
    streams = json.loads(stdout).get("streams", [])
    if not streams or streams[0].get("codec_name") != "flac":
        raise InvalidAudioFile("Downloaded audio is not FLAC")
    stream = streams[0]
    return digest, AudioQuality(
        codec="FLAC",
        container="FLAC",
        lossless=True,
        sample_rate=_int_or_none(stream.get("sample_rate")) or flac.info.sample_rate,
        bit_depth=_int_or_none(stream.get("bits_per_raw_sample")) or flac.info.bits_per_sample,
        channels=_int_or_none(stream.get("channels")) or flac.info.channels,
        bitrate=_int_or_none(stream.get("bit_rate")),
        duration_seconds=duration,
        label="verified",
    )


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _int_or_none(value: object) -> int | None:
    try:
        return int(value) if value not in (None, "") else None
    except (TypeError, ValueError):
        return None
