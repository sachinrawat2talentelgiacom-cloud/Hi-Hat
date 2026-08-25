class ProviderError(RuntimeError):
    code = "PROVIDER_ERROR"
    retryable = False


class ProviderUnavailable(ProviderError):
    code = "PROVIDER_UNAVAILABLE"
    retryable = True


class TrackNotFound(ProviderError):
    code = "TRACK_NOT_FOUND"


class LosslessNotAvailable(ProviderError):
    code = "LOSSLESS_NOT_AVAILABLE"


class AudioSourceNotFound(ProviderError):
    code = "AUDIO_SOURCE_NOT_FOUND"


class ProviderResponseChanged(ProviderError):
    code = "PROVIDER_RESPONSE_CHANGED"


class AccessRestricted(ProviderError):
    code = "ACCESS_RESTRICTED"


class ProviderAccessDenied(AccessRestricted):
    code = "PROVIDER_ACCESS_DENIED"
    retryable = True


class PublicInstanceAccessDenied(ProviderAccessDenied):
    code = "PUBLIC_INSTANCE_ACCESS_DENIED"


class ProtectedContent(AccessRestricted):
    code = "UNSUPPORTED_PROTECTED_CONTENT"
