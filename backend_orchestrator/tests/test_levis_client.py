"""Unit and integration tests for LevisClient using httpx MockTransport and live engine checks."""

from __future__ import annotations

import json
from typing import Any, Dict
import httpx
import pytest

from app.clients.levis_client import LevisClient
from app.core.exceptions import (
    LevisConnectionError,
    LevisResponseError,
    LevisTimeoutError,
)

MOCK_TOKEN = "eyJhbGciOiJIUzI1NiJ9.mock_token_payload.signature"


def create_token_response(token: str = MOCK_TOKEN) -> Dict[str, Any]:
    return {"token": token, "expiraEm": "2099-01-01T00:00:00Z"}


class TestLevisClientUnit:
    """Unit tests for LevisClient using MockTransport."""

    @pytest.mark.asyncio
    async def test_get_dev_token_and_cache(self) -> None:
        """Test obtaining and caching dev token."""
        calls = 0

        def handler(request: httpx.Request) -> httpx.Response:
            nonlocal calls
            if request.url.path == "/api/v1/dev/tokens":
                calls += 1
                return httpx.Response(200, json=create_token_response())
            return httpx.Response(404)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-levis:8082") as mock_http:
            client = LevisClient(base_url="http://mock-levis:8082", client=mock_http)
            
            token1 = await client._get_dev_token()
            assert token1 == MOCK_TOKEN
            assert calls == 1

            # Second call should use cache
            token2 = await client._get_dev_token()
            assert token2 == MOCK_TOKEN
            assert calls == 1

            # Force refresh should invoke endpoint again
            token3 = await client._get_dev_token(force_refresh=True)
            assert token3 == MOCK_TOKEN
            assert calls == 2

    @pytest.mark.asyncio
    async def test_evaluate_sanitizes_colaborador(self) -> None:
        """Test evaluate strips colaborador from the payload body and adds Bearer token."""
        received_body: Dict[str, Any] = {}

        def handler(request: httpx.Request) -> httpx.Response:
            nonlocal received_body
            if request.url.path == "/api/v1/dev/tokens":
                return httpx.Response(200, json=create_token_response())
            if request.url.path == "/api/v1/avaliacoes" and request.method == "POST":
                assert request.headers["authorization"] == f"Bearer {MOCK_TOKEN}"
                received_body = json.loads(request.content.decode("utf-8"))
                return httpx.Response(201, json={"avaliacaoId": "test-uuid-1", "elegibilidade": "REVER"})
            return httpx.Response(404)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-levis:8082") as mock_http:
            client = LevisClient(base_url="http://mock-levis:8082", client=mock_http)
            payload = {
                "id": "PED-1",
                "tipoPedido": "TROCA",
                "colaborador": {"id": "DEV-KH", "funcao": "KEY_HOLDER"},
                "artigos": [{"id": "A-1"}],
            }
            res = await client.evaluate(payload)
            assert res["avaliacaoId"] == "test-uuid-1"
            assert res["elegibilidade"] == "REVER"
            # Crucial: colaborador was removed from the request payload sent to Drools
            assert "colaborador" not in received_body
            assert received_body["id"] == "PED-1"

    @pytest.mark.asyncio
    async def test_get_evaluation(self) -> None:
        """Test get_evaluation by ID."""
        def handler(request: httpx.Request) -> httpx.Response:
            if request.url.path == "/api/v1/dev/tokens":
                return httpx.Response(200, json=create_token_response())
            if request.url.path == "/api/v1/avaliacoes/uuid-123":
                assert request.headers["authorization"] == f"Bearer {MOCK_TOKEN}"
                return httpx.Response(200, json={"avaliacaoId": "uuid-123", "elegibilidade": "PERMITIR"})
            return httpx.Response(404)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-levis:8082") as mock_http:
            client = LevisClient(base_url="http://mock-levis:8082", client=mock_http)
            res = await client.get_evaluation("uuid-123")
            assert res["avaliacaoId"] == "uuid-123"
            assert res["elegibilidade"] == "PERMITIR"

    @pytest.mark.asyncio
    async def test_list_evaluations(self) -> None:
        """Test list_evaluations with store code and pagination."""
        def handler(request: httpx.Request) -> httpx.Response:
            if request.url.path == "/api/v1/dev/tokens":
                return httpx.Response(200, json=create_token_response())
            if request.url.path == "/api/v1/avaliacoes":
                assert request.url.params["loja"] == "US-ML-010"
                assert request.url.params["pagina"] == "1"
                assert request.url.params["tamanho"] == "10"
                return httpx.Response(200, json={"conteudo": [], "pagina": 1, "tamanho": 10, "totalElementos": 0, "totalPaginas": 0})
            return httpx.Response(404)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-levis:8082") as mock_http:
            client = LevisClient(base_url="http://mock-levis:8082", client=mock_http)
            res = await client.list_evaluations(loja="US-ML-010", pagina=1, tamanho=10)
            assert res["pagina"] == 1
            assert res["conteudo"] == []

    @pytest.mark.asyncio
    async def test_explainability_methods(self) -> None:
        """Test get_missing_data, get_why, explain_how, explain_why_not, and simulate."""
        def handler(request: httpx.Request) -> httpx.Response:
            if request.url.path == "/api/v1/dev/tokens":
                return httpx.Response(200, json=create_token_response())
            if request.url.path == "/api/v1/avaliacoes/dados-em-falta":
                return httpx.Response(200, json={"perguntas": []})
            if request.url.path == "/api/v1/avaliacoes/porque":
                assert request.url.params["dado"] == "IN-010"
                return httpx.Response(200, json={"codigo": "IN-010", "pergunta": "Revendível?"})
            if request.url.path == "/api/v1/avaliacoes/aid-1/explicacoes/como":
                return httpx.Response(200, json={"passos": [], "resumo": "OK"})
            if request.url.path == "/api/v1/avaliacoes/aid-1/explicacoes/porque-nao":
                assert request.url.params["conclusao"] == "OUT-001:PERMITIR"
                return httpx.Response(200, json={"conclusao": "OUT-001", "valor": "PERMITIR", "resumo": "Nao permitida"})
            if request.url.path == "/api/v1/avaliacoes/aid-1/simulacoes":
                return httpx.Response(200, json={"diferencas": [], "resumo": "Simulado"})
            return httpx.Response(404)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-levis:8082") as mock_http:
            client = LevisClient(base_url="http://mock-levis:8082", client=mock_http)

            # Missing data
            md = await client.get_missing_data({"artigos": []})
            assert "perguntas" in md

            # Why
            why = await client.get_why("IN-010", {"artigos": []})
            assert why["codigo"] == "IN-010"

            # How
            how = await client.explain_how("aid-1")
            assert how["resumo"] == "OK"

            # Why not
            why_not = await client.explain_why_not("aid-1", conclusao="OUT-001:PERMITIR")
            assert why_not["conclusao"] == "OUT-001"

            # Simulate
            sim = await client.simulate("aid-1", {"alteracoes": {}})
            assert sim["resumo"] == "Simulado"

    @pytest.mark.asyncio
    async def test_rules_catalog_methods(self) -> None:
        """Test list_rules and get_rule_detail."""
        def handler(request: httpx.Request) -> httpx.Response:
            if request.url.path == "/api/v1/dev/tokens":
                return httpx.Response(200, json=create_token_response())
            if request.url.path == "/api/v1/regras":
                return httpx.Response(200, json=[{"id": "PT-003", "descricao": "Troca normal"}])
            if request.url.path == "/api/v1/regras/PT-003":
                return httpx.Response(200, json={"id": "PT-003", "variantes": []})
            return httpx.Response(404)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-levis:8082") as mock_http:
            client = LevisClient(base_url="http://mock-levis:8082", client=mock_http)

            rules = await client.list_rules()
            assert len(rules) == 1
            assert rules[0]["id"] == "PT-003"

            detail = await client.get_rule_detail("PT-003")
            assert detail["id"] == "PT-003"

    @pytest.mark.asyncio
    async def test_retry_on_401_token_expiration(self) -> None:
        """Test that client refreshes token and retries request on 401 response."""
        attempts = 0

        def handler(request: httpx.Request) -> httpx.Response:
            nonlocal attempts
            if request.url.path == "/api/v1/dev/tokens":
                return httpx.Response(200, json=create_token_response(f"token-v{attempts + 1}"))
            if request.url.path == "/api/v1/regras":
                attempts += 1
                if attempts == 1:
                    # First attempt with stale token returns 401
                    return httpx.Response(401, json={"message": "Token expired"})
                # Second attempt with refreshed token succeeds
                return httpx.Response(200, json=[{"id": "R-1"}])
            return httpx.Response(404)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-levis:8082") as mock_http:
            client = LevisClient(base_url="http://mock-levis:8082", client=mock_http)
            rules = await client.list_rules()
            assert len(rules) == 1
            assert rules[0]["id"] == "R-1"
            assert attempts == 2

    @pytest.mark.asyncio
    async def test_exception_mappings(self) -> None:
        """Test proper mapping to LevisConnectionError, LevisTimeoutError, LevisResponseError."""
        # Connection error
        def conn_err_handler(request: httpx.Request) -> httpx.Response:
            raise httpx.ConnectError("Connection refused")

        transport = httpx.MockTransport(conn_err_handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://offline:8082") as mock_http:
            client = LevisClient(base_url="http://offline:8082", client=mock_http)
            with pytest.raises(LevisConnectionError) as exc_info:
                await client.list_rules()
            assert "Could not connect to Levi's Drools engine" in str(exc_info.value)

        # Timeout error
        def timeout_handler(request: httpx.Request) -> httpx.Response:
            raise httpx.ReadTimeout("Read timed out")

        transport = httpx.MockTransport(timeout_handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://timeout:8082") as mock_http:
            client = LevisClient(base_url="http://timeout:8082", client=mock_http)
            with pytest.raises(LevisTimeoutError) as exc_info:
                await client.list_rules()
            assert "timed out" in str(exc_info.value)

        # HTTP error (422)
        def http_err_handler(request: httpx.Request) -> httpx.Response:
            if request.url.path == "/api/v1/dev/tokens":
                return httpx.Response(200, json=create_token_response())
            return httpx.Response(422, json={"detail": "Missing mandatory field 'artigos'"})

        transport = httpx.MockTransport(http_err_handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://err:8082") as mock_http:
            client = LevisClient(base_url="http://err:8082", client=mock_http)
            with pytest.raises(LevisResponseError) as exc_info:
                await client.evaluate({})
            assert exc_info.value.status_code == 422
            assert "Missing mandatory field" in str(exc_info.value)


class TestLevisClientLive:
    """Integration test against real Drools engine on localhost:8082."""

    @pytest.mark.asyncio
    async def test_live_engine_health_and_rules(self) -> None:
        """Check live Drools engine health and verify rules endpoint."""
        async with LevisClient() as client:
            is_healthy = await client.check_health()
            if not is_healthy:
                pytest.skip("Levi's Drools engine is not running on localhost:8082")

            # Check rules
            rules = await client.list_rules()
            assert len(rules) >= 50
            assert any(r["id"] == "PT-003" for r in rules)

            # Check rule detail
            rule_detail = await client.get_rule_detail("PT-003")
            assert rule_detail["id"] == "PT-003"
            assert len(rule_detail["variantes"]) >= 1
