"""Tests for Phase 5: Retail Prolog expert engine integration, routes, and feature toggles."""

from __future__ import annotations

from typing import Any, Dict
from unittest.mock import AsyncMock

import httpx
import pytest
from httpx import AsyncClient

from app.clients.prolog_client import PrologClient
from app.core.config import settings
from app.schemas.common import DecisionEnum, EngineSourceEnum, EvaluationResponse
from app.schemas.scenario import ScenarioInput
from app.services.orchestrator_service import OrchestratorService


class TestPrologClientRetailEndpoints:
    """Validate PrologClient methods for the retail engine REST layer."""

    @pytest.mark.asyncio
    async def test_evaluate_retail_endpoint(self) -> None:
        """Verify POST /retail/evaluate is invoked properly."""
        expected_resp = {
            "status": "success",
            "decision": "approved",
            "retail_decision": "permitir",
            "justification": ["[PT-003] Devolução verificada elegível"],
        }

        def handler(request: httpx.Request) -> httpx.Response:
            assert request.url.path == "/retail/evaluate"
            return httpx.Response(200, json=expected_resp)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            res = await client.evaluate_retail({"colaborador_autorizado": True})
            assert res["status"] == "success"
            assert res["decision"] == "approved"

    @pytest.mark.asyncio
    async def test_interactive_retail_endpoint(self) -> None:
        """Verify POST /retail/interactive is invoked properly."""
        expected_resp = {
            "status": "question",
            "decision": "nao_concluido",
            "question": {"attribute": "estado_produto", "prompt": "Qual é o estado?"},
        }

        def handler(request: httpx.Request) -> httpx.Response:
            assert request.url.path == "/retail/interactive"
            return httpx.Response(200, json=expected_resp)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            res = await client.interactive_retail({})
            assert res["status"] == "question"
            assert res["question"]["attribute"] == "estado_produto"

    @pytest.mark.asyncio
    async def test_whatif_retail_endpoint(self) -> None:
        """Verify POST /retail/whatif is invoked properly."""
        expected_resp = {
            "status": "success",
            "baseline_decision": "rever",
            "simulated_decision": "permitir",
            "decision_changed": True,
        }

        def handler(request: httpx.Request) -> httpx.Response:
            assert request.url.path == "/retail/whatif"
            return httpx.Response(200, json=expected_resp)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            res = await client.whatif_retail({"add": ["estado_produto(nao_usado_com_etiquetas)"]})
            assert res["decision_changed"] is True
            assert res["simulated_decision"] == "permitir"

    @pytest.mark.asyncio
    async def test_how_and_whynot_retail_endpoints(self) -> None:
        """Verify POST /retail/how and POST /retail/whynot."""
        def handler(request: httpx.Request) -> httpx.Response:
            if request.url.path == "/retail/how":
                return httpx.Response(200, json={"status": "success", "explanation": ["Rule PT-003 fired"]})
            elif request.url.path == "/retail/whynot":
                return httpx.Response(200, json={"status": "success", "explanation": ["Premise failed: washed"]})
            return httpx.Response(404)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            how_res = await client.how_retail({"fact": "decisao(permitir)"})
            assert "explanation" in how_res

            whynot_res = await client.whynot_retail({"decision": "approved"})
            assert "explanation" in whynot_res

    @pytest.mark.asyncio
    async def test_facts_and_reset_retail_endpoints(self) -> None:
        """Verify GET /retail/facts and POST /retail/reset."""
        def handler(request: httpx.Request) -> httpx.Response:
            if request.url.path == "/retail/facts":
                return httpx.Response(200, json={"status": "success", "facts_count": 0, "facts": []})
            elif request.url.path == "/retail/reset":
                return httpx.Response(200, json={"status": "success", "message": "Retail inference engine session reset"})
            return httpx.Response(404)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            facts_res = await client.facts_retail()
            assert facts_res["facts_count"] == 0

            reset_res = await client.reset_retail()
            assert reset_res["status"] == "success"


class TestFeatureToggleAndModeSwitching:
    """Validate dynamic switching between retail, academic, and dual modes."""

    @pytest.mark.asyncio
    async def test_mode_switch_academic_calls_evaluate(self) -> None:
        """Test mode='academic' explicitly targets /evaluate."""
        def handler(request: httpx.Request) -> httpx.Response:
            assert request.url.path == "/evaluate"
            return httpx.Response(200, json={"status": "success", "decision": "approved", "justification": ["POC rule"]})

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            res = await client.evaluate({"scenario": "custom", "value": 42}, mode="academic")
            assert res["decision"] == "approved"

    @pytest.mark.asyncio
    async def test_mode_switch_retail_calls_retail_evaluate(self) -> None:
        """Test mode='retail' explicitly targets /retail/evaluate."""
        def handler(request: httpx.Request) -> httpx.Response:
            assert request.url.path == "/retail/evaluate"
            return httpx.Response(200, json={"status": "success", "decision": "approved", "justification": ["[PT-003]"]})

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            res = await client.evaluate({"colaborador_autorizado": True}, mode="retail")
            assert res["decision"] == "approved"

    @pytest.mark.asyncio
    async def test_mode_switch_dual_combines_decisions(self) -> None:
        """Test mode='dual' invokes both engines and synthesizes justifications."""
        def handler(request: httpx.Request) -> httpx.Response:
            if request.url.path == "/retail/evaluate":
                return httpx.Response(200, json={"status": "success", "decision": "approved", "justification": ["Retail approved"]})
            elif request.url.path == "/evaluate":
                return httpx.Response(200, json={"status": "success", "decision": "approved", "justification": ["Academic approved"]})
            return httpx.Response(404)

        transport = httpx.MockTransport(handler)
        async with httpx.AsyncClient(transport=transport, base_url="http://mock-prolog:8080") as mock_http:
            client = PrologClient(base_url="http://mock-prolog:8080", client=mock_http)
            res = await client.evaluate({"colaborador_autorizado": True}, mode="dual")
            assert res["decision"] == "approved"
            assert any("Dual Mode" in j for j in res["justification"])


class TestOrchestratorDecisionMapping:
    """Validate Portuguese domain terms mapping into canonical DecisionEnum."""

    @pytest.mark.parametrize(
        ("raw_decision", "expected_enum"),
        [
            ("permitir", DecisionEnum.APPROVED),
            ("aprovado", DecisionEnum.APPROVED),
            ("approved", DecisionEnum.APPROVED),
            ("recusar", DecisionEnum.REJECTED),
            ("rejeitado", DecisionEnum.REJECTED),
            ("rejected", DecisionEnum.REJECTED),
            ("rever", DecisionEnum.MANAGER_OVERRIDE),
            ("encaminhar", DecisionEnum.MANAGER_OVERRIDE),
            ("manager_override", DecisionEnum.MANAGER_OVERRIDE),
            ("vale_loja", DecisionEnum.STORE_CREDIT_ONLY),
            ("credito_loja", DecisionEnum.STORE_CREDIT_ONLY),
            ("store_credit_only", DecisionEnum.STORE_CREDIT_ONLY),
            ("error", DecisionEnum.ERROR),
        ],
    )
    def test_prolog_decision_mapping(self, raw_decision: str, expected_enum: DecisionEnum) -> None:
        service = OrchestratorService(prolog_client=AsyncMock(), drools_client=AsyncMock())
        result = service._map_prolog_response({"status": "success", "decision": raw_decision, "justification": []})
        assert result.decision == expected_enum


class TestFastAPIRetailRoutes:
    """Validate FastAPI router endpoints for /api/v1/retail/*."""

    @pytest.mark.asyncio
    async def test_api_retail_evaluate(self, async_client: AsyncClient, mock_prolog_client: AsyncMock) -> None:
        mock_prolog_client.evaluate_retail.return_value = {
            "status": "success",
            "decision": "approved",
            "retail_decision": "permitir",
            "justification": ["[PT-003] Devolução aprovada"],
        }

        resp = await async_client.post("/api/v1/retail/evaluate", json={"colaborador_autorizado": True})
        assert resp.status_code == 200
        data = resp.json()
        assert data["decision"] == "approved"
        assert data["retail_decision"] == "permitir"

    @pytest.mark.asyncio
    async def test_api_retail_interactive(self, async_client: AsyncClient, mock_prolog_client: AsyncMock) -> None:
        mock_prolog_client.interactive_retail.return_value = {
            "status": "question",
            "decision": "nao_concluido",
            "question": {"attribute": "estado_produto", "prompt": "Qual é o estado?"},
        }

        resp = await async_client.post("/api/v1/retail/interactive", json={})
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "question"
        assert data["question"]["attribute"] == "estado_produto"

    @pytest.mark.asyncio
    async def test_api_retail_whatif(self, async_client: AsyncClient, mock_prolog_client: AsyncMock) -> None:
        mock_prolog_client.whatif_retail.return_value = {
            "status": "success",
            "baseline_decision": "rever",
            "simulated_decision": "permitir",
            "decision_changed": True,
        }

        resp = await async_client.post(
            "/api/v1/retail/whatif",
            json={"add": ["estado_produto(nao_usado_com_etiquetas)"], "remove": ["estado_produto(claramente_usado)"]},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["decision_changed"] is True
