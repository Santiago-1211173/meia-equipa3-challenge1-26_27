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

    async def _post(self, path: str, payload: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Execute POST request against the Prolog engine with robust exception handling."""
        client = self._get_client()
        url = f"{self.base_url}{path}"
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
                message=f"Prolog engine timed out after {self.timeout}s during request to {path}: {exc}",
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

    async def _get(self, path: str) -> Dict[str, Any]:
        """Execute GET request against the Prolog engine with robust exception handling."""
        client = self._get_client()
        url = f"{self.base_url}{path}"

        try:
            response = await client.get(url, timeout=self.timeout)
            response.raise_for_status()
            return response.json()

        except httpx.ConnectError as exc:
            raise PrologConnectionError(
                message=f"Could not connect to Prolog engine at '{self.base_url}': {exc}",
                url=self.base_url,
            ) from exc

        except httpx.TimeoutException as exc:
            raise PrologTimeoutError(
                message=f"Prolog engine timed out after {self.timeout}s during request to {path}: {exc}",
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

    async def evaluate_academic(self, payload: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Submit scenario facts to the academic/POC Prolog endpoint POST /evaluate."""
        return await self._post("/evaluate", payload)

    async def evaluate_retail(self, payload: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Submit retail return facts to the Levi's expert engine endpoint POST /retail/evaluate."""
        return await self._post("/retail/evaluate", payload)

    async def interactive_retail(self, payload: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Engage in dialogic interrogation via POST /retail/interactive."""
        return await self._post("/retail/interactive", payload)

    async def whatif_retail(self, payload: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Execute counterfactual sandbox simulation via POST /retail/whatif."""
        return await self._post("/retail/whatif", payload)

    async def how_retail(self, payload: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Query deductive causal chain via POST /retail/how."""
        return await self._post("/retail/how", payload)

    async def whynot_retail(self, payload: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Analyze failed candidate rule premises via POST /retail/whynot."""
        return await self._post("/retail/whynot", payload)

    async def why_retail(self, payload: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Query why an input premise is requested via POST /retail/why."""
        return await self._post("/retail/why", payload)

    async def facts_retail(self) -> Dict[str, Any]:
        """Retrieve all current facts from working memory via GET /retail/facts."""
        return await self._get("/retail/facts")

    async def reset_retail(self) -> Dict[str, Any]:
        """Reset the retail inference engine session via POST /retail/reset."""
        return await self._post("/retail/reset", {})

    async def evaluate(
        self,
        payload: Union[Dict[str, Any], Any],
        mode: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Submit scenario facts to the configured or requested Prolog inference engine.

        Supports dynamic mode toggling:
          - 'retail': Evaluates using the Levi's retail expert returns engine (POST /retail/evaluate)
          - 'academic': Evaluates using the academic reference/POC engine (POST /evaluate)
          - 'dual': Executes both and synthesizes their diagnostic output

        Args:
            payload: Fact dictionary or Pydantic model.
            mode: Optional explicit mode override ('retail', 'academic', 'dual').
                  Defaults to settings.PROLOG_ENGINE_MODE.
        """
        request_dict = payload.model_dump() if hasattr(payload, "model_dump") else payload
        is_academic_test = isinstance(request_dict, dict) and request_dict.get("scenario") == "test"

        target_mode = mode or ("academic" if is_academic_test else settings.PROLOG_ENGINE_MODE)

        if target_mode == "academic":
            return await self.evaluate_academic(payload)
        elif target_mode == "dual":
            retail_res = await self.evaluate_retail(payload)
            academic_res = await self.evaluate_academic(payload)
            combined_just = list(retail_res.get("justification", []))
            combined_just.append(f"[Dual Mode] Academic engine verdict: {academic_res.get('decision')}")
            return {**retail_res, "justification": combined_just, "dual_academic": academic_res}
        else:
            return await self.evaluate_retail(payload)

    async def check_health(self) -> bool:
        """Perform a liveness and responsiveness check against the Prolog engine.

        Returns:
            True if the engine responds successfully with HTTP 200, False otherwise.
        """
        try:
            result = await self.evaluate_academic({"scenario": "health_check", "value": 42})
            return result.get("status") == "success"
        except Exception:
            return False
