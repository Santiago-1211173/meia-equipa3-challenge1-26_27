"""Integration and unit tests for Levi's Drools Expert REST endpoints (/api/v1/levis/*).

Validates evaluation, multi-way explainability (How, Why Not, Why, Missing Data),
counterfactual simulation (What If), rules catalog, and official test scenarios.
"""

from __future__ import annotations

from unittest.mock import AsyncMock
from httpx import AsyncClient
import pytest

from app.core.exceptions import (
    LevisConnectionError,
    LevisResponseError,
    LevisTimeoutError,
)
from app.services.levis_service import LevisService


class TestLevisEndpoints:
    """Test suite for Levi's Drools expert reasoning endpoints with mocked backend."""

    # =========================================================================
    # 1. CORE EVALUATION TESTS
    # =========================================================================

    @pytest.mark.asyncio
    async def test_evaluate_levis_scenario_success(
        self,
        async_client: AsyncClient,
        mock_levis_client: AsyncMock,
    ) -> None:
        """Test submission of Levi's Scenario 1 returning elegibilidade == 'REVER'."""
        # 1. Fetch official scenario 1 definition
        sc1_resp = await async_client.get("/api/v1/levis/cenarios-exemplo/1")
        assert sc1_resp.status_code == 200
        sc1_data = sc1_resp.json()
        assert sc1_data["id"] == 1
        assert "pedido" in sc1_data

        # 2. Submit whole wrapped scenario to /avaliar
        eval_resp_wrapped = await async_client.post(
            "/api/v1/levis/avaliar",
            json=sc1_data,
        )
        assert eval_resp_wrapped.status_code == 200
        data_wrapped = eval_resp_wrapped.json()
        assert data_wrapped["elegibilidade"] == "REVER"
        assert data_wrapped["pedidoId"] == "C01"
        assert float(data_wrapped["valorDevolucao"]) == 69.50
        assert len(data_wrapped["artigos"]) >= 1
        assert len(data_wrapped["regras"]) >= 1

        # 3. Submit unwrapped 'pedido' dictionary directly to /avaliar
        eval_resp_pedido = await async_client.post(
            "/api/v1/levis/avaliar",
            json=sc1_data["pedido"],
        )
        assert eval_resp_pedido.status_code == 200
        data_pedido = eval_resp_pedido.json()
        assert data_pedido["elegibilidade"] == "REVER"
        assert data_pedido["pedidoId"] == "C01"
        assert float(data_pedido["valorDevolucao"]) == 69.50

    @pytest.mark.asyncio
    async def test_evaluate_levis_missing_required_fields(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Test validation error HTTP 422 when payload is missing required schema fields."""
        # Empty payload
        resp_empty = await async_client.post("/api/v1/levis/avaliar", json={})
        assert resp_empty.status_code == 422

        # Missing required 'artigos' and 'tipoPedido'
        resp_missing = await async_client.post(
            "/api/v1/levis/avaliar",
            json={"id": "INCOMPLETE_01"},
        )
        assert resp_missing.status_code == 422

        # Invalid data types
        resp_invalid_types = await async_client.post(
            "/api/v1/levis/avaliar",
            json={
                "id": "INVALID_01",
                "tipoPedido": "NAO_EXISTE",
                "artigos": "deveria_ser_uma_lista",
            },
        )
        assert resp_invalid_types.status_code == 422

    # =========================================================================
    # 2. EXPLAINABILITY TESTS (CHAINED HOW & WHY NOT)
    # =========================================================================

    @pytest.mark.asyncio
    async def test_levis_explainability_how_and_whynot(
        self,
        async_client: AsyncClient,
        mock_levis_client: AsyncMock,
    ) -> None:
        """Chained test: evaluate -> obtain evaluation ID -> query /como and /porque-nao."""
        # Step 1: Submit scenario 1 and extract the resulting evaluation UUID
        sc1_resp = await async_client.get("/api/v1/levis/cenarios-exemplo/1")
        assert sc1_resp.status_code == 200
        pedido = sc1_resp.json()["pedido"]

        eval_resp = await async_client.post("/api/v1/levis/avaliar", json=pedido)
        assert eval_resp.status_code == 200
        eval_id = eval_resp.json()["avaliacaoId"]
        assert eval_id == "00000000-0000-0000-0000-000000000001"

        # Step 2: Query /como for complete deduction timeline
        como_resp = await async_client.get(
            f"/api/v1/levis/avaliacoes/{eval_id}/explicacoes/como"
        )
        assert como_resp.status_code == 200
        como_data = como_resp.json()
        assert "passos" in como_data
        assert "modulosPercorridos" in como_data
        assert len(como_data["passos"]) >= 1
        assert como_data["passos"][0]["codigoRegra"] == "CT-003"

        # Query /como for single conclusion derivation tree
        mock_levis_client.explain_how.return_value = {
            "conclusao": "OUT-001",
            "valores": {"OUT-001": "REVER"},
            "resumo": "Dedução isolada para elegibilidade OUT-001",
        }
        como_conc_resp = await async_client.get(
            f"/api/v1/levis/avaliacoes/{eval_id}/explicacoes/como",
            params={"conclusao": "OUT-001"},
        )
        assert como_conc_resp.status_code == 200
        assert como_conc_resp.json()["conclusao"] == "OUT-001"

        # Step 3: Query /porque-nao for rejected outcome (Why not PERMITIR?)
        mock_levis_client.explain_why_not.return_value = {
            "conclusao": "OUT-001",
            "valor": "PERMITIR",
            "valorObtido": "REVER",
            "regrasCandidatas": ["PT-003"],
            "resumo": "A elegibilidade não foi PERMITIR porque foi REVER",
        }
        wn_resp = await async_client.get(
            f"/api/v1/levis/avaliacoes/{eval_id}/explicacoes/porque-nao",
            params={"conclusao": "OUT-001:PERMITIR"},
        )
        assert wn_resp.status_code == 200
        wn_data = wn_resp.json()
        assert wn_data["conclusao"] == "OUT-001"
        assert wn_data["valor"] == "PERMITIR"
        assert wn_data["valorObtido"] == "REVER"

        # Query /porque-nao for why a specific rule did not fire
        mock_levis_client.explain_why_not.return_value = {
            "codigoRegra": "PT-003",
            "causa": "CONDICOES_FALHADAS",
            "resumo": "Premissa de etiquetas intactas falhou",
        }
        wn_regra_resp = await async_client.get(
            f"/api/v1/levis/avaliacoes/{eval_id}/explicacoes/porque-nao",
            params={"regra": "PT-003"},
        )
        assert wn_regra_resp.status_code == 200
        assert wn_regra_resp.json()["codigoRegra"] == "PT-003"

    # =========================================================================
    # 3. ENGINE UNAVAILABLE / RESILIENCE TESTS
    # =========================================================================

    @pytest.mark.asyncio
    async def test_levis_engine_unavailable(
        self,
        async_client: AsyncClient,
        mock_levis_client: AsyncMock,
    ) -> None:
        """Test graceful HTTP 503 response when Drools engine is unavailable or times out."""
        # 1. Connection error on evaluation
        mock_levis_client.evaluate.side_effect = LevisConnectionError(
            message="Connection refused to Drools engine on http://localhost:8082",
            url="http://localhost:8082/api/v1/avaliar",
        )
        sc1_resp = await async_client.get("/api/v1/levis/cenarios-exemplo/1")
        pedido = sc1_resp.json()["pedido"]

        resp_conn = await async_client.post("/api/v1/levis/avaliar", json=pedido)
        assert resp_conn.status_code == 503
        assert "Connection refused" in resp_conn.json()["detail"]

        # 2. Timeout error on evaluation
        mock_levis_client.evaluate.side_effect = LevisTimeoutError(
            message="Levi's Drools evaluation timed out after 10.0s",
            timeout_seconds=10.0,
        )
        resp_timeout = await async_client.post("/api/v1/levis/avaliar", json=pedido)
        assert resp_timeout.status_code == 503
        assert "timed out" in resp_timeout.json()["detail"]

        # 3. Connection error on health check
        mock_levis_client.get_health.side_effect = LevisConnectionError(
            message="Engine health check failed: unreachable",
            url="http://localhost:8082/api/v1/health",
        )
        resp_health = await async_client.get("/api/v1/levis/health")
        assert resp_health.status_code == 503
        assert "unreachable" in resp_health.json()["detail"]

    @pytest.mark.asyncio
    async def test_levis_engine_error_mapping(
        self,
        async_client: AsyncClient,
        mock_levis_client: AsyncMock,
    ) -> None:
        """Test mapping of LevisResponseError to appropriate HTTP status codes (400 and 502)."""
        sc1_resp = await async_client.get("/api/v1/levis/cenarios-exemplo/1")
        pedido = sc1_resp.json()["pedido"]

        # 400 Bad Request translation
        mock_levis_client.evaluate.side_effect = LevisResponseError(
            message="Incompatible store configuration",
            status_code=400,
            response_data={"detail": "Incompatible store configuration"},
        )
        resp_400 = await async_client.post("/api/v1/levis/avaliar", json=pedido)
        assert resp_400.status_code == 400
        assert "Incompatible store configuration" in resp_400.json()["detail"]

        # 500 upstream server error translated to 502 Bad Gateway
        mock_levis_client.evaluate.side_effect = LevisResponseError(
            message="Drools Rule Engine Internal Exception",
            status_code=500,
            response_data={"message": "Internal Drools compilation failure"},
        )
        resp_502 = await async_client.post("/api/v1/levis/avaliar", json=pedido)
        assert resp_502.status_code == 502
        assert "compilation failure" in resp_502.json()["detail"]

    # =========================================================================
    # 4. ADDITIONAL ENDPOINTS TESTS
    # =========================================================================

    @pytest.mark.asyncio
    async def test_get_and_list_evaluations(
        self,
        async_client: AsyncClient,
        mock_levis_client: AsyncMock,
    ) -> None:
        """Test GET /avaliacoes and GET /avaliacoes/{id}."""
        # List evaluations
        resp_list = await async_client.get("/api/v1/levis/avaliacoes?loja=US-ML-010")
        assert resp_list.status_code == 200
        page = resp_list.json()
        assert page["totalElementos"] == 1
        assert page["conteudo"][0]["lojaCodigo"] == "US-ML-010"

        # Get single evaluation
        resp_single = await async_client.get(
            "/api/v1/levis/avaliacoes/00000000-0000-0000-0000-000000000001"
        )
        assert resp_single.status_code == 200
        eval_data = resp_single.json()
        assert eval_data["avaliacaoId"] == "00000000-0000-0000-0000-000000000001"
        assert eval_data["elegibilidade"] == "REVER"

    @pytest.mark.asyncio
    async def test_missing_data_and_why_endpoints(
        self,
        async_client: AsyncClient,
        mock_levis_client: AsyncMock,
    ) -> None:
        """Test POST /dados-em-falta and POST /porque."""
        sc1_resp = await async_client.get("/api/v1/levis/cenarios-exemplo/1")
        pedido = sc1_resp.json()["pedido"]

        # Dados em falta
        resp_missing = await async_client.post(
            "/api/v1/levis/dados-em-falta",
            json=pedido,
        )
        assert resp_missing.status_code == 200
        data_missing = resp_missing.json()
        assert data_missing["completo"] is True

        # Porquê
        resp_why = await async_client.post(
            "/api/v1/levis/porque",
            params={"dado": "IN-010"},
            json=pedido,
        )
        assert resp_why.status_code == 200
        data_why = resp_why.json()
        assert data_why.get("dado") == "IN-010" or data_why.get("codigo") == "IN-010"
        assert "revenda" in data_why["pergunta"].lower()

    @pytest.mark.asyncio
    async def test_counterfactual_simulation_endpoint(
        self,
        async_client: AsyncClient,
        mock_levis_client: AsyncMock,
    ) -> None:
        """Test POST /avaliacoes/{id}/simulacoes."""
        eval_id = "00000000-0000-0000-0000-000000000001"
        payload = {"alteracoes": {"portalOnlineDisponivel": True}}

        resp_sim = await async_client.post(
            f"/api/v1/levis/avaliacoes/{eval_id}/simulacoes",
            json=payload,
        )
        assert resp_sim.status_code == 200
        sim_data = resp_sim.json()
        assert "decisaoSimulada" in sim_data
        assert sim_data["decisaoSimulada"]["elegibilidade"] == "PERMITIR"

    @pytest.mark.asyncio
    async def test_rules_catalog_endpoints(
        self,
        async_client: AsyncClient,
        mock_levis_client: AsyncMock,
    ) -> None:
        """Test GET /regras and GET /regras/{codigo}."""
        # List rules
        resp_rules = await async_client.get("/api/v1/levis/regras")
        assert resp_rules.status_code == 200
        rules = resp_rules.json()
        assert len(rules) == 1
        assert rules[0]["id"] == "PT-003"

        # Get rule detail
        resp_detail = await async_client.get("/api/v1/levis/regras/PT-003")
        assert resp_detail.status_code == 200
        detail = resp_detail.json()
        assert detail["id"] == "PT-003"

    @pytest.mark.asyncio
    async def test_example_scenarios_endpoints(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Test GET /cenarios-exemplo and GET /cenarios-exemplo/{id}."""
        # List all 10 scenarios
        resp_scenarios = await async_client.get("/api/v1/levis/cenarios-exemplo")
        assert resp_scenarios.status_code == 200
        scenarios = resp_scenarios.json()
        assert len(scenarios) == 10
        assert scenarios[0]["id"] == 1
        assert scenarios[9]["id"] == 10

        # Scenario out of bounds triggers validation error 422
        resp_oob = await async_client.get("/api/v1/levis/cenarios-exemplo/99")
        assert resp_oob.status_code == 422

    @pytest.mark.asyncio
    async def test_dev_collaborators_and_health_endpoints(
        self,
        async_client: AsyncClient,
        mock_levis_client: AsyncMock,
    ) -> None:
        """Test GET /colaboradores-dev and GET /health."""
        # Collaborators
        resp_colab = await async_client.get("/api/v1/levis/colaboradores-dev")
        assert resp_colab.status_code == 200
        colabs = resp_colab.json()
        assert len(colabs) >= 1
        assert colabs[0]["id"] == "C-1"

        # Health
        resp_health = await async_client.get("/api/v1/levis/health")
        assert resp_health.status_code == 200
        health = resp_health.json()
        assert health["status"] == "UP"
        assert health["rulesCount"] == 98


class TestLevisEndpointsLive:
    """Integration test suite executing requests against the live Drools engine on localhost:8082."""

    @pytest.mark.asyncio
    async def test_live_scenario_01_full_pipeline(self) -> None:
        """Submit scenario 1 to live engine via FastAPI router and verify end-to-end decisions and explanations."""
        service = LevisService()
        if not await service.check_health():
            pytest.skip("Levi's Drools engine is offline on localhost:8082")

        # Load scenario 1 directly from service
        sc1 = service.get_example_scenario_by_id(1)
        assert sc1 is not None

        # 1. Direct evaluation through LevisService connected to live Spring Boot
        decision = await service.evaluate(sc1.pedido)
        assert decision.avaliacaoId is not None
        assert decision.elegibilidade.value == "REVER"
        assert decision.valorDevolucao == 69.50
        assert len(decision.regras) >= 10

        # 2. Retrieve persisted evaluation from PostgreSQL
        persisted = await service.get_evaluation(decision.avaliacaoId)
        assert persisted.avaliacaoId == decision.avaliacaoId
        assert persisted.elegibilidade.value == "REVER"

        # 3. Explain Como
        como = await service.explain_how(decision.avaliacaoId)
        assert len(como.passos) >= 10

        # 4. Explain Porque Não
        wn = await service.explain_why_not(decision.avaliacaoId, conclusao="OUT-001:PERMITIR")
        assert wn.conclusao == "OUT-001"
        assert wn.valor == "PERMITIR"
        assert wn.valorObtido == "REVER"
