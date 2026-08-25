from hi_hat_backend.providers.base import MusicProvider


class ProviderManager:
    def __init__(self, providers: list[MusicProvider]) -> None:
        self._providers = {provider.name: provider for provider in providers}

    def get(self, name: str) -> MusicProvider:
        try:
            return self._providers[name]
        except KeyError as exc:
            raise ValueError(f"Unknown provider: {name}") from exc

    @property
    def providers(self) -> list[MusicProvider]:
        return list(self._providers.values())
