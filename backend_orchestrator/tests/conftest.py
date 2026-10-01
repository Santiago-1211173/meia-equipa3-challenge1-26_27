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
    get_orchestrator_service,
    get_prolog_client,
)
from app.clients.drools_client import DroolsClient
from app.clients.inference_client import InferenceClient
from app.clients.prolog_client import PrologClient
from app.main import app
from app.services.drools_service import DroolsService
from app.services.inference_service import InferenceService
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
def test_app(
    mock_prolog_client: AsyncMock,
    mock_drools_client: AsyncMock,
    orchestrator_service: OrchestratorService,
    mock_inference_client: AsyncMock,
    inference_service: InferenceService,
    drools_service: DroolsService,
) -> FastAPI:
    """Fixture providing the FastAPI application configured with mock dependencies."""
    app.dependency_overrides[get_prolog_client] = lambda: mock_prolog_client
    app.dependency_overrides[get_drools_client] = lambda: mock_drools_client
    app.dependency_overrides[get_orchestrator_service] = lambda: orchestrator_service
    app.dependency_overrides[get_inference_client] = lambda: mock_inference_client
    app.dependency_overrides[get_inference_service] = lambda: inference_service
    app.dependency_overrides[get_drools_service] = lambda: drools_service

    # Also assign to state for robust resolution
    app.state.prolog_client = mock_prolog_client
    app.state.drools_client = mock_drools_client
    app.state.orchestrator_service = orchestrator_service
    app.state.inference_client = mock_inference_client
    app.state.inference_service = inference_service
    app.state.drools_service = drools_service

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
