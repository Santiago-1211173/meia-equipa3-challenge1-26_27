"""Pytest configuration, plugins, and shared fixtures for orchestrator tests."""

from __future__ import annotations

from pathlib import Path
import sys
from typing import Any, AsyncGenerator, Dict
from unittest.mock import AsyncMock

from fastapi import FastAPI
import httpx
from httpx import ASGITransport, AsyncClient
import pytest

import pytest_asyncio

# Ensure backend_orchestrator root is in sys.path
orchestrator_root = Path(__file__).resolve().parent.parent
if str(orchestrator_root) not in sys.path:
    sys.path.insert(0, str(orchestrator_root))

from app.api.deps import (
    get_drools_client,
    get_drools_service,
    get_inference_client,
    get_inference_service,
    get_levis_client,
    get_levis_service,
    get_orchestrator_service,
    get_prolog_client,
)
from app.clients.drools_client import DroolsClient
from app.clients.inference_client import InferenceClient
from app.clients.levis_client import LevisClient
from app.clients.prolog_client import PrologClient
from app.main import app
from app.services.drools_service import DroolsService
from app.services.inference_service import InferenceService
from app.services.levis_service import LevisService
from app.services.orchestrator_service import OrchestratorService

pytest_plugins = ("pytest_asyncio",)


@pytest.fixture
def mock_prolog_client() -> AsyncMock:
    """Fixture providing a mock PrologClient preconfigured with successful defaults."""
    mock = AsyncMock(spec=PrologClient)
    mock.check_health.return_value = True
    mock.evaluate.return_value = {
        "status": "success",
        "decision": "approved",
        "justification": ["Value is 42", "Dummy rule matched"],
    }
    mock.evaluate_retail.return_value = {
        "status": "success",
        "decision": "manager_override",
        "retail_decision": "rever",
        "justification": [
            "[PC-002] Artigo não usado com etiquetas soltas exige julgamento humano",
            "[PT-001] Comprovativo digital confirma a compra dentro de 30 dias",
        ],
        "initial_facts_count": 18,
        "derived_facts_count": 14,
        "total_facts": 32,
        "derived_facts": [
            {"id": 19, "fact": "controlo_sessao_conforme(true)", "rule_id": "CT-003"},
            {"id": 25, "fact": "decisao(rever)", "rule_id": "PC-002"},
        ],
    }
    mock.how_retail.return_value = {
        "status": "success",
        "fact": "decisao(rever)",
        "explanation": ["Fact 25 -> decisao(rever) concluded by rule [PC-002]"],
    }
    mock.whynot_retail.return_value = {
        "status": "success",
        "fact": "decisao(permitir)",
        "explanation": ["Because by rule [PT-003]: Condition comprovativo(recibo_impresso) is false"],
    }
    mock.whatif_retail.return_value = {
        "status": "success",
        "baseline_decision": "rever",
        "simulated_decision": "permitir",
        "impact_summary": "A decisão mudou de rever para permitir.",
    }
    mock.reset_retail.return_value = {"status": "success", "message": "Reset"}

    async def _mock_why_retail(payload: Dict[str, Any]) -> Dict[str, Any]:
        dado = str(payload.get("dado", "IN-001")).upper()
        facts = payload.get("base_facts", []) or []
        facts_str = " ".join(facts)
        if dado == "IN-001":
            is_interac = "interac" in facts_str
            espera = [
                {
                    "codigoRegra": "TN-011",
                    "codigo_regra": "TN-011",
                    "nomeRegra": "[TN-011] Exigir presença do cartão físico Interac no Canadá para estorno de débito.",
                    "nome_regra": "[TN-011] Exigir presença do cartão físico Interac no Canadá para estorno de débito.",
                    "modulo": "tn",
                    "artigoId": None,
                    "conclusoes": ["meio_reembolso(meio_original)", "processo_obrigatorio(pos)"],
                    "condicoesDoDado": [
                        {
                            "nome": "mercado",
                            "descricao": "mercado(canada)",
                            "cumprida": False,
                            "valor": None,
                            "artigoId": None,
                        }
                    ],
                }
            ] if is_interac else []
            resumo = (
                "A pergunta \"Qual é o mercado da transação de retalho?\" é determinante para 1 regra(s) em espera (TN-011) no pedido atual."
                if is_interac
                else "A pergunta \"Qual é o mercado da transação de retalho?\" é avaliada pelas políticas da loja (TN-011, TN-011-SEM-CARTAO, TN-012); no pedido atual, nenhuma decisão terminal está imediatamente dependente desta resposta porque os restantes requisitos ainda não foram avaliados."
            )
            return {
                "status": "success",
                "codigo": "IN-001",
                "dado": "mercado",
                "pergunta": "Qual é o mercado da transação de retalho? (eua/canada/porquê)",
                "regrasQueDependem": ["TN-011", "TN-011-SEM-CARTAO", "TN-012"],
                "regras_dependentes": ["TN-011", "TN-011-SEM-CARTAO", "TN-012"],
                "regrasEmEspera": espera,
                "regras_em_espera": espera,
                "resumo": resumo,
            }
        elif dado == "IN-008":
            return {
                "status": "success",
                "codigo": "IN-008",
                "dado": "estado_produto",
                "pergunta": "Qual é o estado físico do produto? (nao_usado/usado/danificado)",
                "regrasQueDependem": ["PC-001", "PC-002", "PC-003"],
                "regras_dependentes": ["PC-001", "PC-002", "PC-003"],
                "regrasEmEspera": [],
                "regras_em_espera": [],
                "resumo": "A pergunta é avaliada pelas regras de integridade do produto (PC-001, PC-002, PC-003).",
            }
        else:
            return {
                "status": "success",
                "codigo": dado,
                "dado": dado.lower(),
                "pergunta": f"Qual é o valor para o atributo {dado}?",
                "regrasQueDependem": [],
                "regras_dependentes": [],
                "regrasEmEspera": [],
                "regras_em_espera": [],
                "resumo": f"A pergunta {dado} é requerida pelo sistema pericial.",
            }

    mock.why_retail.side_effect = _mock_why_retail
    return mock



@pytest.fixture
def mock_drools_client() -> AsyncMock:
    """Fixture providing a mock DroolsClient preconfigured with successful defaults."""
    mock = AsyncMock(spec=DroolsClient)
    mock.check_health.return_value = True
    mock.get_health.return_value = {
        "status": "UP",
        "service": "drools-engine",
        "version": "1.0.0",
        "activeKieBase": "haemorrhageKBase",
        "totalRules": 13,
        "timestamp": "2026-10-01T12:00:00Z",
    }
    mock.evaluate.return_value = {
        "status": "SUCCESS",
        "primaryDiagnosis": "Otorrhagia",
        "conclusions": ["Otorrhagia"],
        "hypothesis": "upper type",
        "firedRules": ["r1_upper_type_classification", "r3_otorrhagia_ear_ache"],
        "timestamp": "2026-10-01T12:00:01Z",
        "evidencesEvaluated": {"bloodEar": "yes", "earAche": "yes"},
    }
    return mock


@pytest.fixture
def orchestrator_service(
    mock_prolog_client: AsyncMock,
    mock_drools_client: AsyncMock,
) -> OrchestratorService:
    """Fixture providing an OrchestratorService initialized with mock clients."""
    return OrchestratorService(
        prolog_client=mock_prolog_client,
        drools_client=mock_drools_client,
    )


@pytest.fixture
def drools_service(mock_drools_client: AsyncMock) -> DroolsService:
    """Fixture providing a DroolsService initialized with the mock DroolsClient."""
    return DroolsService(drools_client=mock_drools_client)


@pytest.fixture
def mock_inference_client() -> AsyncMock:
    """Fixture providing a mock InferenceClient preconfigured with successful defaults."""
    mock = AsyncMock(spec=InferenceClient)
    mock.load_kb.return_value = {

        "status": "success",
        "message": "Knowledge base 'vehicles' loaded successfully",
        "initial_facts_count": 3,
    }
    mock.run.return_value = {
        "status": "success",
        "initial_facts_count": 3,
        "derived_facts_count": 2,
        "total_facts": 5,
        "derived_facts": [
            {"id": 4, "fact": "classe(meu_veiculo,pesado)", "rule_id": 6, "justified_by": [2]},
            {"id": 5, "fact": "pesado(meu_veiculo,camiao)", "rule_id": 2, "justified_by": [3, 4]},
        ],
    }
    mock.get_facts.return_value = {
        "status": "success",
        "facts_count": 5,
        "facts": [
            {"id": 1, "fact": "lotacao(meu_veiculo,3)"},
            {"id": 2, "fact": "peso(meu_veiculo,4500)"},
            {"id": 3, "fact": "tipo(meu_veiculo,mercadorias)"},
            {"id": 4, "fact": "classe(meu_veiculo,pesado)"},
            {"id": 5, "fact": "pesado(meu_veiculo,camiao)"},
        ],
    }
    mock.explain_how.return_value = {
        "status": "success",
        "fact_id": 4,
        "explanation": [
            "Fact 4 -> classe(meu_veiculo,pesado) concluded by rule 6",
            "Based on facts: [2]",
            "Fact 2 -> peso(meu_veiculo,4500) was an initial fact",
        ],
    }
    mock.explain_whynot.return_value = {
        "status": "success",
        "fact": "classe(meu_veiculo,ligeiro)",
        "explanation": [
            "Because by rule 7:",
            "  Condition peso(meu_veiculo,=<,3500) is false",
        ],
    }
    mock.reset.return_value = {
        "status": "success",
        "message": "Inference engine session reset",
    }
    return mock


@pytest.fixture
def inference_service(mock_inference_client: AsyncMock) -> InferenceService:
    """Fixture providing an InferenceService initialized with the mock InferenceClient."""
    return InferenceService(inference_client=mock_inference_client)


@pytest.fixture
def mock_levis_client() -> AsyncMock:
    """Fixture providing a mock LevisClient preconfigured with successful defaults."""
    mock = AsyncMock(spec=LevisClient)
    mock.check_health.return_value = True
    mock.get_health.return_value = {
        "status": "UP",
        "service": "drools-engine-levis",
        "version": "1.0.0",
        "rulesCount": 98,
        "database": "CONNECTED",
    }
    mock.evaluate.return_value = {
        "avaliacaoId": "00000000-0000-0000-0000-000000000001",
        "pedidoId": "C01",
        "elegibilidade": "REVER",
        "tipoTransacao": "TROCA",
        "valorDevolucao": 69.50,
        "artigos": [
            {
                "artigoId": "A-1",
                "aprovado": True,
                "destino": "AREA_VENDAS",
                "valorReembolso": 69.50,
                "motivoRecusa": None,
                "regrasAplicadas": ["PT-003", "PC-002"],
            }
        ],
        "regras": [
            {"codigo": "PC-002", "nome": "Etiquetas soltas", "modulo": "M3", "efeito": "REVER"},
            {"codigo": "PT-003", "nome": "Troca normal", "modulo": "M5", "efeito": "PERMITIR"},
        ],
    }
    mock.get_evaluation.return_value = {
        "avaliacaoId": "00000000-0000-0000-0000-000000000001",
        "pedidoId": "C01",
        "elegibilidade": "REVER",
        "tipoTransacao": "TROCA",
        "valorDevolucao": 69.50,
        "artigos": [],
        "regras": [],
    }
    mock.list_evaluations.return_value = {
        "conteudo": [
            {
                "avaliacaoId": "00000000-0000-0000-0000-000000000001",
                "lojaCodigo": "US-ML-010",
                "elegibilidade": "REVER",
                "tipoTransacao": "TROCA",
                "valorDevolucao": 69.50,
            }
        ],
        "pagina": 0,
        "tamanho": 20,
        "totalElementos": 1,
        "totalPaginas": 1,
    }
    mock.get_missing_data.return_value = {
        "perguntas": [],
        "completo": True,
        "resumo": "Dados completos",
    }
    mock.get_why.return_value = {
        "codigo": "IN-010",
        "pergunta": "Possibilidade de revenda?",
        "justificacao": "Necessário para avaliar condição de revenda.",
        "regrasAfetadas": ["PC-002"],
    }
    mock.explain_how.return_value = {
        "passos": [
            {
                "ordem": 1,
                "codigoRegra": "CT-003",
                "modulo": "M0",
                "descricao": "Colaborador autorizado",
                "premissas": [],
                "conclusoes": ["autorizado"],
            }
        ],
        "modulosPercorridos": ["M0", "M3", "M5"],
        "resumo": "Caminho de regras disparadas com sucesso",
    }
    mock.explain_why_not.return_value = {
        "conclusao": "OUT-001",
        "valor": "PERMITIR",
        "valorObtido": "REVER",
        "regrasCandidatas": ["PT-003"],
        "resumo": "A elegibilidade não foi PERMITIR porque foi REVER",
    }
    mock.simulate.return_value = {
        "diferencas": [],
        "regrasNovas": [],
        "regrasRemovidas": [],
        "resumo": "Simulação idêntica ao original",
        "decisaoSimulada": {
            "avaliacaoId": "00000000-0000-0000-0000-000000000002",
            "pedidoId": "C01",
            "elegibilidade": "PERMITIR",
            "tipoTransacao": "TROCA",
            "valorDevolucao": 69.50,
            "artigos": [],
            "regras": [],
        },
    }
    mock.list_rules.return_value = [
        {"id": "PT-003", "modulos": ["M5"], "descricao": "Troca normal", "variantes": 1, "aValidar": False}
    ]
    mock.get_rule_detail.return_value = {
        "id": "PT-003",
        "variantes": [],
    }
    mock.list_dev_collaborators.return_value = [
        {"id": "C-1", "nome": "Key Holder", "funcao": "KEY_HOLDER", "idCredencialPOS": "POS-C-1"}
    ]
    return mock


@pytest.fixture
def levis_service(mock_levis_client: AsyncMock) -> LevisService:
    """Fixture providing a LevisService initialized with mock LevisClient."""
    return LevisService(levis_client=mock_levis_client)


@pytest.fixture
def test_app(
    mock_prolog_client: AsyncMock,
    mock_drools_client: AsyncMock,
    orchestrator_service: OrchestratorService,
    mock_inference_client: AsyncMock,
    inference_service: InferenceService,
    drools_service: DroolsService,
    mock_levis_client: AsyncMock,
    levis_service: LevisService,
) -> FastAPI:
    """Fixture providing the FastAPI application configured with mock dependencies."""
    app.dependency_overrides[get_prolog_client] = lambda: mock_prolog_client
    app.dependency_overrides[get_drools_client] = lambda: mock_drools_client
    app.dependency_overrides[get_orchestrator_service] = lambda: orchestrator_service
    app.dependency_overrides[get_inference_client] = lambda: mock_inference_client
    app.dependency_overrides[get_inference_service] = lambda: inference_service
    app.dependency_overrides[get_drools_service] = lambda: drools_service
    app.dependency_overrides[get_levis_client] = lambda: mock_levis_client
    app.dependency_overrides[get_levis_service] = lambda: levis_service

    # Also assign to state for robust resolution
    app.state.prolog_client = mock_prolog_client
    app.state.drools_client = mock_drools_client
    app.state.orchestrator_service = orchestrator_service
    app.state.inference_client = mock_inference_client
    app.state.inference_service = inference_service
    app.state.drools_service = drools_service
    app.state.levis_client = mock_levis_client
    app.state.levis_service = levis_service

    return app


@pytest_asyncio.fixture
async def async_client(
    test_app: FastAPI,
    mock_prolog_client: AsyncMock,
    mock_drools_client: AsyncMock,
    orchestrator_service: OrchestratorService,
    mock_inference_client: AsyncMock,
    inference_service: InferenceService,
    drools_service: DroolsService,
    mock_levis_client: AsyncMock,
    levis_service: LevisService,
) -> AsyncGenerator[AsyncClient, None]:
    """Fixture providing an asynchronous HTTP client configured for testing FastAPI endpoints."""
    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        yield client

    # Cleanup overrides and state after test execution
    test_app.dependency_overrides.clear()
    if hasattr(test_app.state, "prolog_client"):
        delattr(test_app.state, "prolog_client")
    if hasattr(test_app.state, "drools_client"):
        delattr(test_app.state, "drools_client")
    if hasattr(test_app.state, "orchestrator_service"):
        delattr(test_app.state, "orchestrator_service")
    if hasattr(test_app.state, "inference_client"):
        delattr(test_app.state, "inference_client")
    if hasattr(test_app.state, "inference_service"):
        delattr(test_app.state, "inference_service")
    if hasattr(test_app.state, "drools_service"):
        delattr(test_app.state, "drools_service")
    if hasattr(test_app.state, "levis_client"):
        delattr(test_app.state, "levis_client")
    if hasattr(test_app.state, "levis_service"):
        delattr(test_app.state, "levis_service")



@pytest.fixture
def sample_poc_approved_payload() -> Dict[str, Any]:
    """Sample request payload that triggers approved decision in POC."""
    return {
        "scenario": "test",
        "value": 42,
    }


@pytest.fixture
def sample_poc_rejected_payload() -> Dict[str, Any]:
    """Sample request payload that triggers rejected decision in POC."""
    return {
        "scenario": "test",
        "value": 15,
    }


@pytest.fixture
def sample_prolog_approved_response() -> Dict[str, Any]:
    """Sample raw Prolog response for approved test scenario."""
    return {
        "status": "success",
        "decision": "approved",
        "justification": [
            "Value is 42",
            "Dummy rule matched",
        ],
    }


@pytest.fixture
def sample_prolog_rejected_response() -> Dict[str, Any]:
    """Sample raw Prolog response for rejected test scenario."""
    return {
        "status": "success",
        "decision": "rejected",
        "justification": [
            "Value is not 42",
            "Default fallback rule applied",
        ],
    }
