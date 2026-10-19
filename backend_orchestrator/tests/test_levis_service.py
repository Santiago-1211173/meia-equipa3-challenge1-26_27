"""Unit and integration tests for LevisService."""

from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import AsyncMock
import pytest

from app.schemas.levis import (
    CenarioExemploResponse,
    DadosEmFaltaResponse,
    DecisaoResponse,
    ElegibilidadeEnum,
    ExplicacaoComoResponse,
    ExplicacaoConclusaoResponse,
    ExplicacaoPorqueNaoConclusaoResponse,
    ExplicacaoPorqueNaoResponse,
    ExplicacaoPorqueResponse,
    PaginaResponse,
    PedidoAvaliacaoRequest,
    RegraDetalheDto,
    RegraResumoDto,
    SimulacaoResponse,
    TipoPedidoEnum,
)
from app.services.levis_service import LevisService


class TestLevisServiceMocked:
    """Test LevisService with mocked client."""

    @pytest.mark.asyncio
    async def test_evaluate_returns_decisao_response(self) -> None:
        """Test evaluate converts dict into DecisaoResponse."""
        mock_client = AsyncMock()
        mock_client.evaluate.return_value = {
            "avaliacaoId": "00000000-0000-0000-0000-000000000001",
            "pedidoId": "C01",
            "elegibilidade": "REVER",
            "tipoTransacao": "TROCA",
            "valorDevolucao": 69.50,
            "artigos": [],
            "regras": [],
        }

        service = LevisService(levis_client=mock_client)
        req = PedidoAvaliacaoRequest(id="C01", tipoPedido=TipoPedidoEnum.TROCA, artigos=[])
        res = await service.evaluate(req)

        assert isinstance(res, DecisaoResponse)
        assert res.elegibilidade == ElegibilidadeEnum.REVER
        assert res.valorDevolucao == 69.50
        mock_client.evaluate.assert_awaited_once_with(req)

    @pytest.mark.asyncio
    async def test_get_evaluation(self) -> None:
        """Test get_evaluation returns DecisaoResponse."""
        mock_client = AsyncMock()
        mock_client.get_evaluation.return_value = {
            "avaliacaoId": "00000000-0000-0000-0000-000000000002",
            "elegibilidade": "PERMITIR",
            "artigos": [],
            "regras": [],
        }

        service = LevisService(levis_client=mock_client)
        res = await service.get_evaluation("00000000-0000-0000-0000-000000000002")

        assert isinstance(res, DecisaoResponse)
        assert res.elegibilidade == ElegibilidadeEnum.PERMITIR
        mock_client.get_evaluation.assert_awaited_once_with("00000000-0000-0000-0000-000000000002")

    @pytest.mark.asyncio
    async def test_list_evaluations(self) -> None:
        """Test list_evaluations returns PaginaResponse."""
        mock_client = AsyncMock()
        mock_client.list_evaluations.return_value = {
            "conteudo": [
                {
                    "avaliacaoId": "00000000-0000-0000-0000-000000000003",
                    "lojaCodigo": "US-ML-010",
                    "elegibilidade": "REVER",
                }
            ],
            "pagina": 0,
            "tamanho": 20,
            "totalElementos": 1,
            "totalPaginas": 1,
        }

        service = LevisService(levis_client=mock_client)
        res = await service.list_evaluations(loja="US-ML-010")

        assert isinstance(res, PaginaResponse)
        assert len(res.conteudo) == 1
        assert res.conteudo[0].lojaCodigo == "US-ML-010"

    @pytest.mark.asyncio
    async def test_explainability_methods(self) -> None:
        """Test missing data, why, how, and why not typing."""
        mock_client = AsyncMock()
        mock_client.get_missing_data.return_value = {"perguntas": [], "completo": True}
        mock_client.get_why.return_value = {"codigo": "IN-010", "pergunta": "Possibilidade de revenda?"}
        mock_client.explain_how.side_effect = [
            {"passos": [], "modulosPercorridos": ["M0"], "resumo": "Caminho completo"},
            {"conclusao": "OUT-001", "valores": {}, "resumo": "Caminho conclusao"},
        ]
        mock_client.explain_why_not.side_effect = [
            {"conclusao": "OUT-001", "valor": "PERMITIR", "regras": [], "resumo": "Nao permitida"},
            {"codigoRegra": "PT-003", "causa": "CONDICOES_FALHADAS", "resumo": "Condicao falhou"},
        ]
        mock_client.simulate.return_value = {
            "diferencas": [],
            "regrasNovas": [],
            "regrasRemovidas": [],
            "resumo": "Sem diferencas",
            "decisaoSimulada": {"avaliacaoId": "00000000-0000-0000-0000-000000000004", "elegibilidade": "PERMITIR", "artigos": [], "regras": []},
        }

        service = LevisService(levis_client=mock_client)

        # Missing data
        md = await service.get_missing_data({"artigos": []})
        assert isinstance(md, DadosEmFaltaResponse)

        # Why
        why = await service.get_why("IN-010", {"artigos": []})
        assert isinstance(why, ExplicacaoPorqueResponse)

        # How (full)
        how_full = await service.explain_how("aid-1")
        assert isinstance(how_full, ExplicacaoComoResponse)

        # How (conclusao)
        how_conc = await service.explain_how("aid-1", conclusao="OUT-001")
        assert isinstance(how_conc, ExplicacaoConclusaoResponse)

        # Why not (conclusao)
        wn_conc = await service.explain_why_not("aid-1", conclusao="OUT-001:PERMITIR")
        assert isinstance(wn_conc, ExplicacaoPorqueNaoConclusaoResponse)

        # Why not (regra)
        wn_regra = await service.explain_why_not("aid-1", regra="PT-003")
        assert isinstance(wn_regra, ExplicacaoPorqueNaoResponse)

        # Simulate
        sim = await service.simulate("aid-1", {"alteracoes": {}})
        assert isinstance(sim, SimulacaoResponse)

    @pytest.mark.asyncio
    async def test_rules_catalog(self) -> None:
        """Test list_rules and get_rule_detail."""
        mock_client = AsyncMock()
        mock_client.list_rules.return_value = [
            {"id": "PT-003", "modulos": ["M5"], "descricao": "Troca normal", "variantes": 1, "aValidar": False}
        ]
        mock_client.get_rule_detail.return_value = {
            "id": "PT-003",
            "variantes": [],
        }

        service = LevisService(levis_client=mock_client)
        rules = await service.list_rules()
        assert len(rules) == 1
        assert isinstance(rules[0], RegraResumoDto)

        detail = await service.get_rule_detail("PT-003")
        assert isinstance(detail, RegraDetalheDto)


class TestLevisServiceScenarios:
    """Test scenario loading from local filesystem."""

    def test_get_example_scenarios(self) -> None:
        """Verify that all 10 scenarios are loaded and properly sorted."""
        service = LevisService()
        scenarios = service.get_example_scenarios()

        assert len(scenarios) == 10
        for i, sc in enumerate(scenarios, start=1):
            assert isinstance(sc, CenarioExemploResponse)
            assert sc.id == i
            assert len(sc.titulo) > 0
            assert sc.pedido is not None
            assert len(sc.pedido.artigos) >= 1

    def test_get_example_scenario_by_id(self) -> None:
        """Verify retrieval by ID."""
        service = LevisService()
        sc1 = service.get_example_scenario_by_id(1)
        assert sc1 is not None
        assert sc1.id == 1
        assert "etiquetas soltas" in sc1.titulo.lower()

        sc_none = service.get_example_scenario_by_id(999)
        assert sc_none is None


class TestLevisServiceLive:
    """Integration test against live Drools engine on localhost:8082."""

    @pytest.mark.asyncio
    async def test_live_scenario_01_evaluation(self) -> None:
        """Submit scenario 1 to live engine via LevisService and check decision and explainability."""
        service = LevisService()
        if not await service.check_health():
            pytest.skip("Drools engine is offline on localhost:8082")

        sc1 = service.get_example_scenario_by_id(1)
        assert sc1 is not None

        # 1. Evaluate
        decision = await service.evaluate(sc1.pedido)
        assert decision.avaliacaoId is not None
        assert decision.elegibilidade == ElegibilidadeEnum.REVER
        assert len(decision.regras) >= 10

        # 2. Get Evaluation
        fetched = await service.get_evaluation(decision.avaliacaoId)
        assert fetched.avaliacaoId == decision.avaliacaoId
        assert fetched.elegibilidade == ElegibilidadeEnum.REVER

        # 3. Explain Como
        como = await service.explain_how(decision.avaliacaoId)
        assert isinstance(como, ExplicacaoComoResponse)
        assert len(como.passos) >= 10

        # 4. Explain Porque Nao
        wn = await service.explain_why_not(decision.avaliacaoId, conclusao="OUT-001:PERMITIR")
        assert isinstance(wn, ExplicacaoPorqueNaoConclusaoResponse)
        assert wn.conclusao == "OUT-001"
        assert wn.valor == "PERMITIR"
        assert wn.valorObtido == "REVER"
