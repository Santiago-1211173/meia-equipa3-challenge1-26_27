"""Unit tests for the asynchronous InferenceClient using httpx MockTransport."""

from __future__ import annotations

from typing import Any, Dict
import httpx
import pytest

from app.clients.inference_client import InferenceClient
from app.core.exceptions import (
    PrologConnectionError,
    PrologResponseError,
    PrologTimeoutError,
)


class TestInferenceClientMethods:
    """Test suite for InferenceClient HTTP operations against mock endpoints."""

    @pytest.mark.asyncio
    async def test_load_kb_success(self) -> None:
        """Test successful loading of a knowledge base."""
        expected_response = {
            "status": "success",
            "message": "Knowledge base 'vehicles' loaded successfully",
            "initial_facts_count": 3,
        }

        def handler(request: httpx.Request) -> httpx.Response:
            assert request.url.path == "/inference/load"
            assert request.method == "POST"
            assert request.headers["content-type"] == "application/json"
            return httpx.Response(200, json=expected_response)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = InferenceClient(base_url="http://mock-prolog:8080", client=mock_http)
            result = await client.load_kb("vehicles")

            assert result == expected_response
            assert result["initial_facts_count"] == 3

    @pytest.mark.asyncio
    async def test_load_kb_connection_error(self) -> None:
        """Test that connection failure in load_kb raises PrologConnectionError."""

        def handler(request: httpx.Request) -> httpx.Response:
            raise httpx.ConnectError("Connection refused")

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://offline-host:8080") as mock_http:
            client = InferenceClient(base_url="http://offline-host:8080", client=mock_http)
            with pytest.raises(PrologConnectionError) as exc_info:
                await client.load_kb("vehicles")

            assert "Could not connect to Prolog engine" in str(exc_info.value)
            assert exc_info.value.url == "http://offline-host:8080"

    @pytest.mark.asyncio
    async def test_load_kb_timeout(self) -> None:
        """Test that read timeout in load_kb raises PrologTimeoutError."""

        def handler(request: httpx.Request) -> httpx.Response:
            raise httpx.ReadTimeout("Socket timeout")

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = InferenceClient(base_url="http://mock-prolog:8080", timeout=3.0, client=mock_http)
            with pytest.raises(PrologTimeoutError) as exc_info:
                await client.load_kb("vehicles")

            assert "timed out after 3.0s" in str(exc_info.value)
            assert exc_info.value.timeout_seconds == 3.0

    @pytest.mark.asyncio
    async def test_load_kb_error_response_400(self) -> None:
        """Test that HTTP 400 from load_kb raises PrologResponseError with parsed body."""
        error_body = {
            "status": "error",
            "message": "Knowledge base 'nonexistent' not found",
        }

        def handler(request: httpx.Request) -> httpx.Response:
            return httpx.Response(400, json=error_body)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = InferenceClient(base_url="http://mock-prolog:8080", client=mock_http)
            with pytest.raises(PrologResponseError) as exc_info:
                await client.load_kb("nonexistent")

            assert exc_info.value.status_code == 400
            assert exc_info.value.message == "Knowledge base 'nonexistent' not found"
            assert exc_info.value.response_data == error_body

    @pytest.mark.asyncio
    async def test_run_engine_success(self) -> None:
        """Test successful execution of deduction cycle."""
        expected_response = {
            "status": "success",
            "initial_facts_count": 3,
            "derived_facts_count": 2,
            "total_facts": 5,
            "derived_facts": [
                {"id": 4, "fact": "classe(meu_veiculo,pesado)", "rule_id": 6, "justified_by": [2]},
                {"id": 5, "fact": "pesado(meu_veiculo,camiao)", "rule_id": 2, "justified_by": [3, 4]},
            ],
        }

        def handler(request: httpx.Request) -> httpx.Response:
            assert request.url.path == "/inference/run"
            assert request.method == "POST"
            return httpx.Response(200, json=expected_response)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = InferenceClient(base_url="http://mock-prolog:8080", client=mock_http)
            result = await client.run()

            assert result == expected_response
            assert result["derived_facts_count"] == 2
            assert len(result["derived_facts"]) == 2

    @pytest.mark.asyncio
    async def test_run_engine_connection_error(self) -> None:
        """Test that run() connection failure raises PrologConnectionError."""

        def handler(request: httpx.Request) -> httpx.Response:
            raise httpx.ConnectError("Connection refused")

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = InferenceClient(base_url="http://mock-prolog:8080", client=mock_http)
            with pytest.raises(PrologConnectionError):
                await client.run()

    @pytest.mark.asyncio
    async def test_run_engine_timeout(self) -> None:
        """Test that run() timeout raises PrologTimeoutError."""

        def handler(request: httpx.Request) -> httpx.Response:
            raise httpx.ReadTimeout("Timeout")

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = InferenceClient(base_url="http://mock-prolog:8080", timeout=2.0, client=mock_http)
            with pytest.raises(PrologTimeoutError):
                await client.run()

    @pytest.mark.asyncio
    async def test_get_facts_success(self) -> None:
        """Test successful retrieval of active facts."""
        expected_response = {
            "status": "success",
            "facts_count": 2,
            "facts": [
                {"id": 1, "fact": "lotacao(meu_veiculo,3)"},
                {"id": 2, "fact": "peso(meu_veiculo,4500)"},
            ],
        }

        def handler(request: httpx.Request) -> httpx.Response:
            assert request.url.path == "/inference/facts"
            assert request.method == "GET"
            return httpx.Response(200, json=expected_response)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = InferenceClient(base_url="http://mock-prolog:8080", client=mock_http)
            result = await client.get_facts()

            assert result == expected_response
            assert result["facts_count"] == 2

    @pytest.mark.asyncio
    async def test_explain_how_success(self) -> None:
        """Test explain_how causal reasoning retrieval."""
        expected_response = {
            "status": "success",
            "fact_id": 4,
            "explanation": [
                "Fact 4 -> classe(meu_veiculo,pesado) concluded by rule 6",
                "Based on facts: [2]",
            ],
        }

        def handler(request: httpx.Request) -> httpx.Response:
            assert request.url.path == "/inference/how"
            assert request.method == "POST"
            return httpx.Response(200, json=expected_response)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = InferenceClient(base_url="http://mock-prolog:8080", client=mock_http)
            result = await client.explain_how(4)

            assert result == expected_response
            assert result["fact_id"] == 4
            assert len(result["explanation"]) == 2

    @pytest.mark.asyncio
    async def test_explain_whynot_success(self) -> None:
        """Test explain_whynot diagnostic premises retrieval."""
        expected_response = {
            "status": "success",
            "fact": "classe(meu_veiculo,ligeiro)",
            "explanation": [
                "Because by rule 7:",
                "  Condition peso(meu_veiculo,=<,3500) is false",
            ],
        }

        def handler(request: httpx.Request) -> httpx.Response:
            assert request.url.path == "/inference/whynot"
            assert request.method == "POST"
            return httpx.Response(200, json=expected_response)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = InferenceClient(base_url="http://mock-prolog:8080", client=mock_http)
            result = await client.explain_whynot("classe(meu_veiculo,ligeiro)")

            assert result == expected_response
            assert len(result["explanation"]) == 2

    @pytest.mark.asyncio
    async def test_reset_success(self) -> None:
        """Test engine memory reset operation."""
        expected_response = {
            "status": "success",
            "message": "Inference engine session reset",
        }

        def handler(request: httpx.Request) -> httpx.Response:
            assert request.url.path == "/inference/reset"
            assert request.method == "POST"
            return httpx.Response(200, json=expected_response)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = InferenceClient(base_url="http://mock-prolog:8080", client=mock_http)
            result = await client.reset()

            assert result == expected_response
            assert result["status"] == "success"

    @pytest.mark.asyncio
    async def test_unsupported_method_raises_value_error(self) -> None:
        """Test that internal _request rejects unsupported HTTP verbs."""
        client = InferenceClient(base_url="http://mock-prolog:8080")
        with pytest.raises(ValueError, match="Unsupported HTTP method"):
            await client._request("DELETE", "/inference/reset")

    @pytest.mark.asyncio
    async def test_network_error_raises_prolog_connection_error(self) -> None:
        """Test that generic httpx.NetworkError translates to PrologConnectionError."""

        def handler(request: httpx.Request) -> httpx.Response:
            raise httpx.NetworkError("Network unreachable")

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = InferenceClient(base_url="http://mock-prolog:8080", client=mock_http)
            with pytest.raises(PrologConnectionError) as exc_info:
                await client.get_facts()

            assert "Network error" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_context_manager_lifecycle(self) -> None:
        """Test async context manager lifecycle and close cleanup."""
        async with InferenceClient(base_url="http://localhost:8080") as client:
            assert client._client is not None
            assert not client._client.is_closed

        assert client._client is None or client._client.is_closed
