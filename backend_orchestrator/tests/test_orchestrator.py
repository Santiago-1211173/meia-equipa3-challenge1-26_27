"""Integration and unit tests for the orchestrator layer and evaluation endpoints."""

from __future__ import annotations

from typing import Any, Dict
from unittest.mock import AsyncMock

from httpx import AsyncClient
import pytest

from app.core.exceptions import (
    PrologConnectionError,
    PrologResponseError,
    PrologTimeoutError,
)
from app.schemas.common import DecisionEnum, EngineSourceEnum
from app.schemas.scenario import ScenarioInput
from app.services.orchestrator_service import OrchestratorService


class TestOrchestratorEndpointIntegration:
    """End-to-end integration tests for POST /api/v1/evaluate with mocked Prolog backend."""

    @pytest.mark.asyncio
    async def test_scenario_a_evaluate_approved_success(
        self,
        async_client: AsyncClient,
        mock_prolog_client: AsyncMock,
        sample_poc_approved_payload: Dict[str, Any],
        sample_prolog_approved_response: Dict[str, Any],
    ) -> None:
        """Cenário A: Sucesso com aprovação (value = 42 -> decision: "approved")."""
        mock_prolog_client.evaluate.return_value = sample_prolog_approved_response

        response = await async_client.post(
            "/api/v1/evaluate",
            json=sample_poc_approved_payload,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["decision"] == "approved"
        assert data["justification"] == ["Value is 42", "Dummy rule matched"]
        assert data["engine"] == "prolog"
        assert "timestamp" in data
        mock_prolog_client.evaluate.assert_awaited_once_with(sample_poc_approved_payload)

    @pytest.mark.asyncio
    async def test_scenario_b_evaluate_rejected_success(
        self,
        async_client: AsyncClient,
        mock_prolog_client: AsyncMock,
        sample_poc_rejected_payload: Dict[str, Any],
        sample_prolog_rejected_response: Dict[str, Any],
    ) -> None:
        """Cenário B: Sucesso com rejeição (value = 15 -> decision: "rejected")."""
        mock_prolog_client.evaluate.return_value = sample_prolog_rejected_response

        response = await async_client.post(
            "/api/v1/evaluate",
            json=sample_poc_rejected_payload,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["decision"] == "rejected"
        assert data["justification"] == ["Value is not 42", "Default fallback rule applied"]
        assert data["engine"] == "prolog"
        assert "timestamp" in data
        mock_prolog_client.evaluate.assert_awaited_once_with(sample_poc_rejected_payload)

    @pytest.mark.asyncio
    async def test_scenario_c_connectivity_failure_raises_503(
        self,
        async_client: AsyncClient,
        mock_prolog_client: AsyncMock,
        sample_poc_approved_payload: Dict[str, Any],
    ) -> None:
        """Cenário C: Falha de conectividade (Prolog offline -> HTTP 503 Service Unavailable)."""
        mock_prolog_client.evaluate.side_effect = PrologConnectionError(
            message="Could not connect to Prolog engine at http://localhost:8080",
            url="http://localhost:8080",
        )

        response = await async_client.post(
            "/api/v1/evaluate",
            json=sample_poc_approved_payload,
        )

        assert response.status_code == 503
        data = response.json()
        assert "Could not connect to Prolog engine" in data["detail"]

    @pytest.mark.asyncio
    async def test_scenario_d_timeout_raises_503(
        self,
        async_client: AsyncClient,
        mock_prolog_client: AsyncMock,
        sample_poc_approved_payload: Dict[str, Any],
    ) -> None:
        """Cenário D: Timeout do motor Prolog -> HTTP 503 Service Unavailable."""
        mock_prolog_client.evaluate.side_effect = PrologTimeoutError(
            message="Prolog inference engine request timed out after 5.0s",
            timeout_seconds=5.0,
        )

        response = await async_client.post(
            "/api/v1/evaluate",
            json=sample_poc_approved_payload,
        )

        assert response.status_code == 503
        data = response.json()
        assert "timed out after 5.0s" in data["detail"]

    @pytest.mark.asyncio
    async def test_prolog_engine_error_response_raises_400(
        self,
        async_client: AsyncClient,
        mock_prolog_client: AsyncMock,
        sample_poc_approved_payload: Dict[str, Any],
    ) -> None:
        """Verify that HTTP 400 from Prolog engine maps to HTTP 400 Bad Request."""
        mock_prolog_client.evaluate.side_effect = PrologResponseError(
            message="Invalid JSON payload or missing required parameters",
            status_code=400,
            response_data={"status": "error", "message": "Invalid JSON"},
        )

        response = await async_client.post(
            "/api/v1/evaluate",
            json=sample_poc_approved_payload,
        )

        assert response.status_code == 400
        data = response.json()
        assert "Invalid JSON payload" in data["detail"]

    @pytest.mark.asyncio
    async def test_invalid_payload_type_rejected_with_422(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Verify that invalid payload data types trigger FastAPI 422 Unprocessable Entity."""
        response = await async_client.post(
            "/api/v1/evaluate",
            json={"scenario": "test", "value": "not_a_number"},
        )
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_empty_payload_rejected_with_422(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Verify that empty payload triggers FastAPI 422 Unprocessable Entity."""
        response = await async_client.post(
            "/api/v1/evaluate",
            json={},
        )
        assert response.status_code == 422


class TestOrchestratorServiceUnit:
    """Unit tests for OrchestratorService logic and response mapping in isolation."""

    @pytest.mark.asyncio
    async def test_evaluate_with_pydantic_scenario_input(
        self,
        mock_prolog_client: AsyncMock,
        orchestrator_service: OrchestratorService,
    ) -> None:
        """Verify evaluation works seamlessly when passing a ScenarioInput model."""
        mock_prolog_client.evaluate.return_value = {
            "status": "success",
            "decision": "approved",
            "justification": ["Value is 42"],
        }
        scenario = ScenarioInput(scenario="test", value=42)

        result = await orchestrator_service.evaluate_scenario(scenario)

        assert result.status == "success"
        assert result.decision == DecisionEnum.APPROVED
        assert result.justification == ["Value is 42"]
        assert result.engine == EngineSourceEnum.PROLOG
        mock_prolog_client.evaluate.assert_awaited_once_with({"scenario": "test", "value": 42})

    @pytest.mark.asyncio
    async def test_evaluate_with_dict_payload(
        self,
        mock_prolog_client: AsyncMock,
        orchestrator_service: OrchestratorService,
    ) -> None:
        """Verify evaluation works when passing a raw dictionary."""
        mock_prolog_client.evaluate.return_value = {
            "status": "success",
            "decision": "rejected",
            "justification": ["Value is not 42"],
        }
        payload = {"scenario": "test", "value": 15}

        result = await orchestrator_service.evaluate_scenario(payload)

        assert result.decision == DecisionEnum.REJECTED
        assert result.justification == ["Value is not 42"]

    @pytest.mark.asyncio
    async def test_evaluate_raises_value_error_for_invalid_type(
        self,
        orchestrator_service: OrchestratorService,
    ) -> None:
        """Verify that passing an unsupported data type raises ValueError."""
        with pytest.raises(ValueError, match="Unsupported scenario_data type"):
            await orchestrator_service.evaluate_scenario([1, 2, 3])  # type: ignore[arg-type]

    def test_map_prolog_response_unknown_decision_fallback(
        self,
        orchestrator_service: OrchestratorService,
    ) -> None:
        """Verify mapping falls back cleanly when engine returns unknown decision string."""
        raw_unknown = {
            "status": "success",
            "decision": "completely_unknown_decision",
            "justification": ["Fallback check"],
        }
        result = orchestrator_service._map_prolog_response(raw_unknown)
        assert result.decision == DecisionEnum.REJECTED

        raw_error = {
            "status": "error",
            "decision": "unknown_error_decision",
            "justification": [],
        }
        result_err = orchestrator_service._map_prolog_response(raw_error)
        assert result_err.decision == DecisionEnum.ERROR

    def test_map_prolog_response_string_justification_conversion(
        self,
        orchestrator_service: OrchestratorService,
    ) -> None:
        """Verify mapping converts single string justification to a list of strings."""
        raw = {
            "status": "success",
            "decision": "approved",
            "justification": "Single string justification",
        }
        result = orchestrator_service._map_prolog_response(raw)
        assert result.justification == ["Single string justification"]

    @pytest.mark.asyncio
    async def test_check_health_connected_and_disconnected(
        self,
        mock_prolog_client: AsyncMock,
        mock_drools_client: AsyncMock,
        orchestrator_service: OrchestratorService,
    ) -> None:
        """Verify health status reporting for connected and disconnected engine states."""
        mock_prolog_client.check_health.return_value = True
        mock_drools_client.check_health.return_value = True
        status_connected = await orchestrator_service.check_health()
        assert status_connected == {
            "status": "healthy",
            "prolog_engine": "connected",
            "drools_engine": "connected",
        }

        mock_prolog_client.check_health.return_value = False
        mock_drools_client.check_health.return_value = False
        status_disconnected = await orchestrator_service.check_health()
        assert status_disconnected == {
            "status": "healthy",
            "prolog_engine": "disconnected",
            "drools_engine": "disconnected",
        }



class TestAppLifespan:
    """Tests for application lifespan setup and teardown."""

    @pytest.mark.asyncio
    async def test_lifespan_initializes_and_cleans_resources(self) -> None:
        """Verify that FastAPI lifespan initializes clients and closes HTTP connection on exit."""
        from fastapi import FastAPI
        from app.main import lifespan

        dummy_app = FastAPI()
        async with lifespan(dummy_app):
            assert hasattr(dummy_app.state, "http_client")
            assert hasattr(dummy_app.state, "prolog_client")
            assert hasattr(dummy_app.state, "orchestrator_service")
            assert not dummy_app.state.http_client.is_closed

        assert dummy_app.state.http_client.is_closed
