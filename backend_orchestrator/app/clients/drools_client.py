"""Asynchronous HTTP client for communicating with the Drools rule inference microservice."""

from __future__ import annotations

from typing import Any, Dict, Optional, Union

import httpx

from app.core.config import settings
from app.core.exceptions import (
    DroolsConnectionError,
    DroolsResponseError,
    DroolsTimeoutError,
)


class DroolsClient:
    """Asynchronous HTTP client for the Drools rule reasoning engine.

    Manages connection pooling, serialization, timeout handling,
    and exception mapping for the Drools microservice.
    """

    def __init__(
        self,
        base_url: Optional[str] = None,
        timeout: Optional[float] = None,
        client: Optional[httpx.AsyncClient] = None,
    ) -> None:
        """Initialize the Drools client.

        Args:
            base_url: Base URL of the Drools service (defaults to settings.DROOLS_ENGINE_URL).
            timeout: Request timeout in seconds (defaults to settings.DROOLS_TIMEOUT_SECONDS).
            client: Optional pre-configured httpx.AsyncClient.
        """
        self.base_url = (base_url or settings.DROOLS_ENGINE_URL).rstrip("/")
        self.timeout = timeout if timeout is not None else settings.DROOLS_TIMEOUT_SECONDS
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

    async def __aenter__(self) -> DroolsClient:
        """Enter the async context manager."""
        self._get_client()
        return self

    async def __aexit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        """Exit the async context manager and release client resources."""
        await self.close()

    async def evaluate(self, payload: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Submit clinical evidence facts to the Drools inference engine.

        Args:
            payload: Clinical evidence dictionary or Pydantic model.

        Returns:
            Dict containing the serialized Drools evaluation response.

        Raises:
            DroolsConnectionError: On network, DNS, or socket connection failures.
            DroolsTimeoutError: If the Drools engine exceeds the configured timeout.
            DroolsResponseError: If the Drools engine returns HTTP 4xx or 5xx.
        """
        client = self._get_client()
        url = f"{self.base_url}/api/v1/inference/evaluate"

        request_data = payload.model_dump(exclude_none=True) if hasattr(payload, "model_dump") else payload

        try:
            response = await client.post(
                url,
                json=request_data,
                timeout=self.timeout,
            )
            response.raise_for_status()
            return response.json()

        except httpx.ConnectError as exc:
            raise DroolsConnectionError(
                message=f"Could not connect to Drools engine at '{self.base_url}': {exc}",
                url=self.base_url,
            ) from exc

        except httpx.TimeoutException as exc:
            raise DroolsTimeoutError(
                message=f"Drools engine timed out after {self.timeout}s during evaluation: {exc}",
                timeout_seconds=self.timeout,
            ) from exc

        except httpx.HTTPStatusError as exc:
            status_code = exc.response.status_code
            error_data = None
            message = f"Drools engine returned HTTP {status_code}"
            try:
                error_data = exc.response.json()
                if isinstance(error_data, dict) and "message" in error_data:
                    message = error_data["message"]
            except Exception:
                error_data = {"raw": exc.response.text}

            raise DroolsResponseError(
                message=message,
                status_code=status_code,
                response_data=error_data if isinstance(error_data, dict) else {},
            ) from exc

        except httpx.NetworkError as exc:
            raise DroolsConnectionError(
                message=f"Network error while communicating with Drools engine: {exc}",
                url=self.base_url,
            ) from exc

    async def get_health(self) -> Dict[str, Any]:
        """Retrieve operational health information from the Drools engine.

        Returns:
            Dict containing health information (status, service, version, totalRules).
        """
        client = self._get_client()
        url = f"{self.base_url}/api/v1/inference/health"

        try:
            response = await client.get(url, timeout=self.timeout)
            response.raise_for_status()
            return response.json()
        except httpx.ConnectError as exc:
            raise DroolsConnectionError(
                message=f"Could not connect to Drools engine health endpoint at '{self.base_url}': {exc}",
                url=self.base_url,
            ) from exc
        except httpx.TimeoutException as exc:
            raise DroolsTimeoutError(
                message=f"Drools engine health check timed out after {self.timeout}s: {exc}",
                timeout_seconds=self.timeout,
            ) from exc
        except httpx.HTTPStatusError as exc:
            raise DroolsResponseError(
                message=f"Drools engine health check failed with HTTP {exc.response.status_code}",
                status_code=exc.response.status_code,
            ) from exc
        except httpx.NetworkError as exc:
            raise DroolsConnectionError(
                message=f"Network error while checking Drools engine health: {exc}",
                url=self.base_url,
            ) from exc

    async def check_health(self) -> bool:
        """Perform a quick liveness and readiness check against the Drools engine.

        Returns:
            True if the engine responds successfully with HTTP 200 and status 'UP', False otherwise.
        """
        try:
            health_data = await self.get_health()
            return health_data.get("status") == "UP"
        except Exception:
            return False
