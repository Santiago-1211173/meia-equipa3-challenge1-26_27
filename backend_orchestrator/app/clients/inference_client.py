"""Asynchronous HTTP client for communicating with the academic example inference engine (sp_exp2.pl from Moodle)."""

from __future__ import annotations

from typing import Any, Dict, Optional

import httpx

from app.core.config import settings
from app.core.exceptions import (
    PrologConnectionError,
    PrologResponseError,
    PrologTimeoutError,
)


class InferenceClient:
    """Asynchronous HTTP client for the academic example engine (sp_exp2.pl from Moodle).

    Interacts with the /inference/* endpoints exposed by the Prolog microservice,
    managing lifecycle, timeouts, connection pooling, and error translation into
    canonical domain exceptions for the professors' forward-chaining example system.
    """

    def __init__(
        self,
        base_url: Optional[str] = None,
        timeout: Optional[float] = None,
        client: Optional[httpx.AsyncClient] = None,
    ) -> None:
        """Initialize the Inference client.

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

    async def __aenter__(self) -> InferenceClient:
        """Enter the async context manager."""
        self._get_client()
        return self

    async def __aexit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        """Exit the async context manager and release client resources."""
        await self.close()

    async def _request(
        self,
        method: str,
        path: str,
        json_payload: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Perform an HTTP request and translate HTTP/network failures to domain exceptions.

        Args:
            method: HTTP verb ('GET' or 'POST').
            path: Relative path to endpoint starting with '/' (e.g. '/inference/load').
            json_payload: Optional JSON dictionary payload for POST requests.

        Returns:
            Dict containing the decoded JSON response payload.

        Raises:
            PrologConnectionError: On socket, DNS, or network connection failures.
            PrologTimeoutError: If request execution exceeds the configured timeout.
            PrologResponseError: If the remote service responds with HTTP 4xx or 5xx.
        """
        client = self._get_client()
        url = f"{self.base_url}{path}"

        try:
            if method.upper() == "GET":
                response = await client.get(url, timeout=self.timeout)
            elif method.upper() == "POST":
                response = await client.post(
                    url,
                    json=json_payload if json_payload is not None else {},
                    timeout=self.timeout,
                )
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")

            response.raise_for_status()
            return response.json()

        except httpx.ConnectError as exc:
            raise PrologConnectionError(
                message=f"Could not connect to Prolog engine at '{self.base_url}': {exc}",
                url=self.base_url,
            ) from exc

        except httpx.TimeoutException as exc:
            raise PrologTimeoutError(
                message=f"Prolog engine timed out after {self.timeout}s: {exc}",
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

    async def load_kb(self, knowledge_base: str) -> Dict[str, Any]:
        """Load a specified knowledge base into the Prolog inference engine.

        Args:
            knowledge_base: Name of the knowledge base file (e.g., 'vehicles').

        Returns:
            Dict containing loading status, message, and initial facts count.
        """
        return await self._request("POST", "/inference/load", {"knowledge_base": knowledge_base})

    async def run(self) -> Dict[str, Any]:
        """Execute the forward-chaining inference cycle over active working memory.

        Returns:
            Dict containing execution metrics and all derived facts.
        """
        return await self._request("POST", "/inference/run", {})

    async def get_facts(self) -> Dict[str, Any]:
        """Retrieve all facts currently asserted in working memory.

        Returns:
            Dict containing total facts count and list of active facts.
        """
        return await self._request("GET", "/inference/facts")

    async def explain_how(self, fact_id: int) -> Dict[str, Any]:
        """Query the causal explanation trace for a given fact ID.

        Args:
            fact_id: Identifier of the fact to explain.

        Returns:
            Dict containing status, fact_id, and explanation lines.
        """
        return await self._request("POST", "/inference/how", {"fact_id": fact_id})

    async def explain_whynot(self, fact: str) -> Dict[str, Any]:
        """Query why a target fact term was not concluded.

        Args:
            fact: String representation of the target fact term.

        Returns:
            Dict containing status, queried fact, and diagnostic reasons.
        """
        return await self._request("POST", "/inference/whynot", {"fact": fact})

    async def reset(self) -> Dict[str, Any]:
        """Reset the working memory and knowledge base state of the inference engine.

        Returns:
            Dict confirming successful reset.
        """
        return await self._request("POST", "/inference/reset", {})
