"""Unit and integration tests for the asynchronous PrologClient."""

from __future__ import annotations

import httpx
import pytest

from app.clients.prolog_client import PrologClient
from app.core.exceptions import (
    InferenceEngineError,
    PrologConnectionError,
    PrologResponseError,
    PrologTimeoutError,
)
from app.schemas.scenario import ScenarioInput


class TestCustomExceptions:
    """Validate exception inheritance and attributes."""

    def test_exception_inheritance_hierarchy(self) -> None:
        """Verify that all Prolog errors inherit from InferenceEngineError."""
        assert issubclass(PrologConnectionError, InferenceEngineError)
        assert issubclass(PrologTimeoutError, InferenceEngineError)
        assert issubclass(PrologResponseError, InferenceEngineError)
        assert issubclass(InferenceEngineError, Exception)

    def test_prolog_response_error_attributes(self) -> None:
        """Verify status_code and response_data storage on PrologResponseError."""
        err = PrologResponseError(
            message="Invalid syntax",
            status_code=400,
            response_data={"status": "error", "message": "Invalid syntax"},
        )
        assert err.status_code == 400
        assert err.response_data == {"status": "error", "message": "Invalid syntax"}
        assert str(err) == "Invalid syntax"

    def test_prolog_timeout_error_attributes(self) -> None:
        """Verify timeout_seconds storage on PrologTimeoutError."""
        err = PrologTimeoutError("Timed out", timeout_seconds=5.0)
        assert err.timeout_seconds == 5.0
        assert "Timed out" in str(err)

    def test_prolog_connection_error_attributes(self) -> None:
        """Verify url storage on PrologConnectionError."""
        err = PrologConnectionError("Failed connection", url="http://localhost:8080")
        assert err.url == "http://localhost:8080"
        assert "Failed connection" in str(err)


class TestPrologClientEvaluation:
    """Tests for PrologClient evaluate and health check using mock transport."""

    @pytest.mark.asyncio
    async def test_evaluate_success_approved(self) -> None:
        """Test successful approval response from Prolog engine."""
        expected_response = {
            "status": "success",
            "decision": "approved",
            "justification": ["Value is 42", "Dummy rule matched"],
        }

        def handler(request: httpx.Request) -> httpx.Response:
            assert request.url.path == "/evaluate"
            assert request.headers["content-type"] == "application/json"
            return httpx.Response(200, json=expected_response)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            result = await client.evaluate({"scenario": "test", "value": 42})

            assert result == expected_response
            assert result["status"] == "success"
            assert result["decision"] == "approved"
            assert len(result["justification"]) == 2

    @pytest.mark.asyncio
    async def test_evaluate_success_rejected(self) -> None:
        """Test successful rejection response from Prolog engine."""
        expected_response = {
            "status": "success",
            "decision": "rejected",
            "justification": ["Value is not 42", "Default fallback rule applied"],
        }

        def handler(request: httpx.Request) -> httpx.Response:
            return httpx.Response(200, json=expected_response)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            result = await client.evaluate({"scenario": "test", "value": 15})

            assert result["decision"] == "rejected"
            assert result["justification"] == ["Value is not 42", "Default fallback rule applied"]

    @pytest.mark.asyncio
    async def test_evaluate_accepts_pydantic_model(self) -> None:
        """Test that evaluate accepts ScenarioInput Pydantic models directly."""
        scenario = ScenarioInput(scenario="test", value=42)

        def handler(request: httpx.Request) -> httpx.Response:
            import json

            data = json.loads(request.content)
            assert data == {"scenario": "test", "value": 42}
            return httpx.Response(200, json={"status": "success", "decision": "approved", "justification": []})

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            result = await client.evaluate(scenario)
            assert result["decision"] == "approved"

    @pytest.mark.asyncio
    async def test_evaluate_raises_prolog_connection_error(self) -> None:
        """Test that network connection errors raise typed PrologConnectionError."""

        def handler(request: httpx.Request) -> httpx.Response:
            raise httpx.ConnectError("Connection refused by target machine")

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://offline-host:8080") as mock_http:
            client = PrologClient(base_url="http://offline-host:8080", client=mock_http)
            with pytest.raises(PrologConnectionError) as exc_info:
                await client.evaluate({"scenario": "test", "value": 42})

            assert "Could not connect to Prolog engine" in str(exc_info.value)
            assert exc_info.value.url == "http://offline-host:8080"

    @pytest.mark.asyncio
    async def test_evaluate_raises_prolog_timeout_error(self) -> None:
        """Test that request timeouts raise typed PrologTimeoutError."""

        def handler(request: httpx.Request) -> httpx.Response:
            raise httpx.ReadTimeout("Timed out waiting for socket read")

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", timeout=2.5, client=mock_http)
            with pytest.raises(PrologTimeoutError) as exc_info:
                await client.evaluate({"scenario": "test", "value": 42})

            assert "timed out after 2.5s" in str(exc_info.value)
            assert exc_info.value.timeout_seconds == 2.5

    @pytest.mark.asyncio
    async def test_evaluate_raises_prolog_response_error_on_400(self) -> None:
        """Test that HTTP 400 Bad Request raises PrologResponseError with JSON payload."""
        error_body = {
            "status": "error",
            "message": "Invalid JSON payload or missing required parameters",
            "decision": "error",
            "justification": [],
        }

        def handler(request: httpx.Request) -> httpx.Response:
            return httpx.Response(400, json=error_body)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            with pytest.raises(PrologResponseError) as exc_info:
                await client.evaluate({"invalid": "payload"})

            assert exc_info.value.status_code == 400
            assert exc_info.value.message == "Invalid JSON payload or missing required parameters"
            assert exc_info.value.response_data == error_body

    @pytest.mark.asyncio
    async def test_evaluate_raises_prolog_response_error_on_500_plain_text(self) -> None:
        """Test that HTTP 500 with plain text error raises PrologResponseError."""

        def handler(request: httpx.Request) -> httpx.Response:
            return httpx.Response(500, text="Internal Prolog crash")

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            with pytest.raises(PrologResponseError) as exc_info:
                await client.evaluate({"scenario": "test", "value": 42})

            assert exc_info.value.status_code == 500
            assert "raw" in exc_info.value.response_data

    @pytest.mark.asyncio
    async def test_check_health_returns_true_when_healthy(self) -> None:
        """Test check_health returning True on successful Prolog ping."""

        def handler(request: httpx.Request) -> httpx.Response:
            return httpx.Response(200, json={"status": "success", "decision": "approved", "justification": []})

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            assert await client.check_health() is True

    @pytest.mark.asyncio
    async def test_check_health_returns_false_on_connection_failure(self) -> None:
        """Test check_health returning False when Prolog is unreachable."""

        def handler(request: httpx.Request) -> httpx.Response:
            raise httpx.ConnectError("Connection refused")

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            assert await client.check_health() is False

    @pytest.mark.asyncio
    async def test_check_health_returns_false_on_error_response(self) -> None:
        """Test check_health returning False when Prolog returns error status."""

        def handler(request: httpx.Request) -> httpx.Response:
            return httpx.Response(500, json={"status": "error"})

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            assert await client.check_health() is False

    @pytest.mark.asyncio
    async def test_client_context_manager_and_close(self) -> None:
        """Test async context manager lifecycle and close cleanup."""
        async with PrologClient(base_url="http://localhost:8080") as client:
            assert client._client is not None
            assert not client._client.is_closed

        assert client._client is None or client._client.is_closed
