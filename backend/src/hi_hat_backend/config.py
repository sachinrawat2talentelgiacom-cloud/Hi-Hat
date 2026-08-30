from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="HI_HAT_", env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "Hi Hat Backend"
    api_token: str = "development-only-change-me"
    bind_host: str = "127.0.0.1"
    bind_port: int = 8765
    data_dir: Path = Path("data")
    staging_dir: Path = Path("tmp")
    job_ttl_hours: int = 24
    monochrome_api_instances: list[str] = Field(
        default_factory=lambda: [
            "https://monochrome-api.samidy.com",
            "https://api.monochrome.tf",
        ]
    )
    # Optional user-authorized Unified Playback service. Hi Hat deliberately
    # does not embed Monochrome's browser token or attempt its Turnstile flow.
    monochrome_unified_api_base_url: str | None = None
    monochrome_unified_api_token: str | None = None
    monochrome_browser_helper_url: str | None = "http://127.0.0.1:8876"
    monochrome_browser_timeout_seconds: int = 1800
    monochrome_browser_acquisition_root: Path = Path.home() / "AppData/Local/HiHat/Acquisitions"
    personal_library_roots: list[Path] = Field(default_factory=list)
    deepl_api_key: str | None = None
    deepl_api_base_url: str = "https://api-free.deepl.com"


@lru_cache
def get_settings() -> Settings:
    return Settings()
