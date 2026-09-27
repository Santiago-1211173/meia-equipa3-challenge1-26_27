"""Asynchronous HTTP client for communicating with the SWI-Prolog inference microservice."""

from __future__ import annotations

from typing import Any, Dict, Optional, Union

import httpx

from app.core.config import settings
from app.core.exceptions import (
    PrologConnectionError,
    PrologResponseError,
    PrologTimeoutError,
)


class PrologClient:
    """Asynchronous HTTP transport client for the SWI-Prolog reasoning engine.

    Manages connection pooling, request serialization, timeout enforcement,
    and resilience translation into typed domain exceptions.
    """

    def __init__(
        self,
        base_url: Optional[str] = None,
        timeout: Optional[float] = None,
        client: Optional[httpx.AsyncClient] = None,
    ) -> None:
        """Initialize the Prolog client.

        Args:
            base_url: Base URL of the Prolog service (defaults to settings.PROLOG_ENGINE_URL).
            timeout: Request timeout in seconds (defaults to settings.PROLOG_TIMEOUT_SECONDS).
            client: Optional pre-configured httpx.AsyncClient (e.g. from FastAPI lifespan or tests).
        """
        self.base_url = (base_url or settings.PROLOG_ENGINE_URL).rstrip("/")
        self.timeout = timeout if timeout is not None else settings.PROLOG_TIMEOUT_SECONDS
        self._external_client = client is not None
        self._client = client

    def _get_client(self) -> httpx.AsyncClient:
        """Return the active AsyncClient or initialize an internally managed instance."""
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(
                base_url=self.base_url,
                timeout=self.timeout,
                headers={
                    "Content-Type": "application/json",
                    "Accept": "application/json",
                },
            )
            self._external_client = False
        return self._client

    async def close(self) -> None:
        """Close the internally managed HTTP client session if applicable."""
        if self._client is not None and not self._external_client and not self._client.is_closed:
            await self._client.aclose()
            self._client = None

    async def __aenter__(self) -> PrologClient:
        """Enter the async context manager."""
        self._get_client()
        return self

    async def __aexit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        """Exit the async context manager and release client resources."""
        await self.close()

    async def evaluate(self, payload: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Submit scenario facts to the Prolog inference engine via POST /evaluate.

        Args:
            payload: Fact dictionary adhering to the Prolog /evaluate contract
                     (e.g., {"scenario": "test", "value": 42}) or a Pydantic model.

        Returns:
            Dict containing the serialized Prolog evaluation response
            (status, decision, justification).

        Raises:
            PrologConnectionError: On network, DNS, or socket connection failures.
            PrologTimeoutError: If the Prolog engine exceeds the configured timeout.
            PrologResponseError: If the Prolog engine returns HTTP 4xx or 5xx.
        """
        client = self._get_client()
        url = f"{self.base_url}/evaluate"

        # Serialize Pydantic models to dict if provided
        request_data = payload.model_dump() if hasattr(payload, "model_dump") else payload

        try:
            response = await client.post(
                url,
                json=request_data,
                timeout=self.timeout,
            )
            response.raise_for_status()
            return response.json()

        except httpx.ConnectError as exc:
            raise PrologConnectionError(
                message=f"Could not connect to Prolog engine at '{self.base_url}': {exc}",
                url=self.base_url,
            ) from exc

        except httpx.TimeoutException as exc:
            raise PrologTimeoutError(
                message=f"Prolog engine timed out after {self.timeout}s during evaluation: {exc}",
                timeout_seconds=self.timeout,
            ) from exc

        except httpx.HTTPStatusError as exc:
            status_code = exc.response.status_code
            error_data = None
            message = f"Prolog engine returned HTTP {status_code}"
            try:
                error_data = exc.response.json()
                if isinstance(error_data, dict) and "message" in error_data:
                    message = error_data["message"]
            except Exception:
                error_data = {"raw": exc.response.text}

            raise PrologResponseError(
                message=message,
                status_code=status_code,
                response_data=error_data if isinstance(error_data, dict) else {},
            ) from exc

        except httpx.NetworkError as exc:
            raise PrologConnectionError(
                message=f"Network error while communicating with Prolog engine: {exc}",
                url=self.base_url,
            ) from exc

    async def check_health(self) -> bool:
        """Perform a liveness and responsiveness check against the Prolog engine.

        Returns:
            True if the engine responds successfully with HTTP 200, False otherwise.
        """
        try:
            result = await self.evaluate({"scenario": "health_check", "value": 42})
            return result.get("status") == "success"
        except Exception:
            return False
