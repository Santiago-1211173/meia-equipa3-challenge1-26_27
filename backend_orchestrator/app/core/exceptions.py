"""Custom domain exceptions for inference engines and orchestrator communication."""

from __future__ import annotations

from typing import Any, Dict, Optional


class InferenceEngineError(Exception):
    """Base exception for all inference engine communication and processing errors."""

    def __init__(self, message: str = "Inference engine error occurred.") -> None:
        self.message = message
        super().__init__(self.message)


class PrologConnectionError(InferenceEngineError):
    """Raised when network connection or DNS resolution to the Prolog engine fails."""

    def __init__(
        self,
        message: str = "Failed to establish connection to the Prolog inference engine.",
        url: Optional[str] = None,
    ) -> None:
        self.url = url
        super().__init__(message)


class PrologTimeoutError(InferenceEngineError):
    """Raised when a request to the Prolog inference engine times out."""

    def __init__(
        self,
        message: str = "Prolog inference engine request timed out.",
        timeout_seconds: Optional[float] = None,
    ) -> None:
        self.timeout_seconds = timeout_seconds
        super().__init__(message)


class PrologResponseError(InferenceEngineError):
    """Raised when the Prolog inference engine responds with an HTTP error status (4xx/5xx)."""

    def __init__(
        self,
        message: str = "Prolog engine returned an error response.",
        status_code: int = 500,
        response_data: Optional[Dict[str, Any]] = None,
    ) -> None:
        self.status_code = status_code
        self.response_data = response_data or {}
        super().__init__(message)


class DroolsConnectionError(InferenceEngineError):
    """Raised when network connection or DNS resolution to the Drools engine fails."""

    def __init__(
        self,
        message: str = "Failed to establish connection to the Drools inference engine.",
        url: Optional[str] = None,
    ) -> None:
        self.url = url
        super().__init__(message)


class DroolsTimeoutError(InferenceEngineError):
    """Raised when a request to the Drools inference engine times out."""

    def __init__(
        self,
        message: str = "Drools inference engine request timed out.",
        timeout_seconds: Optional[float] = None,
    ) -> None:
        self.timeout_seconds = timeout_seconds
        super().__init__(message)


class DroolsResponseError(InferenceEngineError):
    """Raised when the Drools inference engine responds with an HTTP error status (4xx/5xx)."""

    def __init__(
        self,
        message: str = "Drools engine returned an error response.",
        status_code: int = 500,
        response_data: Optional[Dict[str, Any]] = None,
    ) -> None:
        self.status_code = status_code
        self.response_data = response_data or {}
        super().__init__(message)

