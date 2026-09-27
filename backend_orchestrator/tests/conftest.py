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

from app.api.deps import get_orchestrator_service, get_prolog_client
from app.clients.prolog_client import PrologClient
from app.main import app
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
def orchestrator_service(mock_prolog_client: AsyncMock) -> OrchestratorService:
    """Fixture providing an OrchestratorService initialized with the mock PrologClient."""
    return OrchestratorService(prolog_client=mock_prolog_client)


@pytest.fixture
def test_app(
    mock_prolog_client: AsyncMock,
    orchestrator_service: OrchestratorService,
) -> FastAPI:
    """Fixture providing the FastAPI application configured with mock dependencies."""
    app.dependency_overrides[get_prolog_client] = lambda: mock_prolog_client
    app.dependency_overrides[get_orchestrator_service] = lambda: orchestrator_service

    # Also assign to state for robust resolution
    app.state.prolog_client = mock_prolog_client
    app.state.orchestrator_service = orchestrator_service

    return app


@pytest_asyncio.fixture
async def async_client(
    test_app: FastAPI,
    mock_prolog_client: AsyncMock,
    orchestrator_service: OrchestratorService,
) -> AsyncGenerator[AsyncClient, None]:
    """Fixture providing an asynchronous HTTP client configured for testing FastAPI endpoints."""
    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        yield client

    # Cleanup overrides and state after test execution
    test_app.dependency_overrides.clear()
    if hasattr(test_app.state, "prolog_client"):
        delattr(test_app.state, "prolog_client")
    if hasattr(test_app.state, "orchestrator_service"):
        delattr(test_app.state, "orchestrator_service")


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
