"""Integration tests for the inference REST API endpoints (/api/v1/inference/*)."""

from __future__ import annotations

import importlib
from typing import Any, Dict
from unittest.mock import AsyncMock

from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
import pytest

from app.core import config
from app.core.exceptions import (
    PrologConnectionError,
    PrologResponseError,
    PrologTimeoutError,
)


class TestInferenceEndpointsIntegration:
    """Test suite verifying /api/v1/inference/* endpoints with mocked Prolog backend."""

    @pytest.mark.asyncio
    async def test_post_load_success(
        self,
        async_client: AsyncClient,
        mock_inference_client: AsyncMock,
    ) -> None:
        """Verify successful POST /api/v1/inference/load."""
        mock_inference_client.load_kb.return_value = {
            "status": "success",
            "message": "Knowledge base 'vehicles' loaded successfully",
            "initial_facts_count": 3,
        }

        response = await async_client.post(
            "/api/v1/inference/load",
            json={"knowledge_base": "vehicles"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["message"] == "Knowledge base 'vehicles' loaded successfully"
        assert data["initial_facts_count"] == 3
        mock_inference_client.load_kb.assert_awaited_once_with(knowledge_base="vehicles")

    @pytest.mark.asyncio
    async def test_post_load_validation_error_422(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Verify that empty knowledge_base string triggers HTTP 422."""
        response = await async_client.post(
            "/api/v1/inference/load",
            json={"knowledge_base": ""},
        )
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_post_load_backend_connection_error_503(
        self,
        async_client: AsyncClient,
        mock_inference_client: AsyncMock,
    ) -> None:
        """Verify that backend connection failure in /load maps to HTTP 503."""
        mock_inference_client.load_kb.side_effect = PrologConnectionError(
            message="Could not connect to Prolog engine",
            url="http://localhost:8080",
        )

        response = await async_client.post(
            "/api/v1/inference/load",
            json={"knowledge_base": "vehicles"},
        )

        assert response.status_code == 503
        data = response.json()
        assert "Could not connect to Prolog engine" in data["detail"]

    @pytest.mark.asyncio
    async def test_post_load_backend_response_error_400(
        self,
        async_client: AsyncClient,
        mock_inference_client: AsyncMock,
    ) -> None:
        """Verify that backend rejection in /load maps to HTTP 400."""
        mock_inference_client.load_kb.side_effect = PrologResponseError(
            message="Knowledge base 'nonexistent' not found",
            status_code=400,
        )

        response = await async_client.post(
            "/api/v1/inference/load",
            json={"knowledge_base": "nonexistent"},
        )

        assert response.status_code == 400
        data = response.json()
        assert "not found" in data["detail"]

    @pytest.mark.asyncio
    async def test_post_run_success(
        self,
        async_client: AsyncClient,
        mock_inference_client: AsyncMock,
    ) -> None:
        """Verify successful POST /api/v1/inference/run."""
        mock_inference_client.run.return_value = {
            "status": "success",
            "initial_facts_count": 3,
            "derived_facts_count": 2,
            "total_facts": 5,
            "derived_facts": [
                {"id": 4, "fact": "classe(meu_veiculo,pesado)", "rule_id": 6, "justified_by": [2]},
                {"id": 5, "fact": "pesado(meu_veiculo,camiao)", "rule_id": 2, "justified_by": [3, 4]},
            ],
        }

        response = await async_client.post("/api/v1/inference/run", json={})

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["initial_facts_count"] == 3
        assert data["derived_facts_count"] == 2
        assert data["total_facts"] == 5
        assert len(data["derived_facts"]) == 2
        assert data["derived_facts"][0]["fact"] == "classe(meu_veiculo,pesado)"
        mock_inference_client.run.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_post_run_timeout_error_503(
        self,
        async_client: AsyncClient,
        mock_inference_client: AsyncMock,
    ) -> None:
        """Verify that timeout during /run maps to HTTP 503."""
        mock_inference_client.run.side_effect = PrologTimeoutError(
            message="Prolog request timed out after 5.0s",
            timeout_seconds=5.0,
        )

        response = await async_client.post("/api/v1/inference/run", json={})

        assert response.status_code == 503
        data = response.json()
        assert "timed out after 5.0s" in data["detail"]

    @pytest.mark.asyncio
    async def test_get_facts_success(
        self,
        async_client: AsyncClient,
        mock_inference_client: AsyncMock,
    ) -> None:
        """Verify successful GET /api/v1/inference/facts."""
        mock_inference_client.get_facts.return_value = {
            "status": "success",
            "facts_count": 3,
            "facts": [
                {"id": 1, "fact": "lotacao(meu_veiculo,3)"},
                {"id": 2, "fact": "peso(meu_veiculo,4500)"},
                {"id": 3, "fact": "tipo(meu_veiculo,mercadorias)"},
            ],
        }

        response = await async_client.get("/api/v1/inference/facts")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["facts_count"] == 3
        assert len(data["facts"]) == 3
        assert data["facts"][0]["id"] == 1
        mock_inference_client.get_facts.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_get_facts_error_400(
        self,
        async_client: AsyncClient,
        mock_inference_client: AsyncMock,
    ) -> None:
        """Verify that backend 400 on GET /facts maps to HTTP 400."""
        mock_inference_client.get_facts.side_effect = PrologResponseError(
            message="Engine error reading facts",
            status_code=400,
        )

        response = await async_client.get("/api/v1/inference/facts")

        assert response.status_code == 400
        data = response.json()
        assert "Engine error reading facts" in data["detail"]

    @pytest.mark.asyncio
    async def test_post_how_success(
        self,
        async_client: AsyncClient,
        mock_inference_client: AsyncMock,
    ) -> None:
        """Verify successful POST /api/v1/inference/how."""
        mock_inference_client.explain_how.return_value = {
            "status": "success",
            "fact_id": 4,
            "explanation": [
                "Fact 4 -> classe(meu_veiculo,pesado) concluded by rule 6",
                "Based on facts: [2]",
            ],
        }

        response = await async_client.post(
            "/api/v1/inference/how",
            json={"fact_id": 4},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["fact_id"] == 4
        assert len(data["explanation"]) == 2
        mock_inference_client.explain_how.assert_awaited_once_with(fact_id=4)

    @pytest.mark.asyncio
    async def test_post_how_invalid_fact_id_422(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Verify that fact_id < 1 triggers HTTP 422 validation error."""
        response = await async_client.post(
            "/api/v1/inference/how",
            json={"fact_id": 0},
        )
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_post_whynot_success(
        self,
        async_client: AsyncClient,
        mock_inference_client: AsyncMock,
    ) -> None:
        """Verify successful POST /api/v1/inference/whynot."""
        mock_inference_client.explain_whynot.return_value = {
            "status": "success",
            "fact": "classe(meu_veiculo,ligeiro)",
            "explanation": [
                "Because by rule 7:",
                "  Condition peso(meu_veiculo,=<,3500) is false",
            ],
        }

        response = await async_client.post(
            "/api/v1/inference/whynot",
            json={"fact": "classe(meu_veiculo,ligeiro)"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["fact"] == "classe(meu_veiculo,ligeiro)"
        assert len(data["explanation"]) == 2
        mock_inference_client.explain_whynot.assert_awaited_once_with(fact="classe(meu_veiculo,ligeiro)")

    @pytest.mark.asyncio
    async def test_post_whynot_empty_fact_422(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Verify that empty fact term string triggers HTTP 422 validation error."""
        response = await async_client.post(
            "/api/v1/inference/whynot",
            json={"fact": ""},
        )
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_post_reset_success(
        self,
        async_client: AsyncClient,
        mock_inference_client: AsyncMock,
    ) -> None:
        """Verify successful POST /api/v1/inference/reset."""
        mock_inference_client.reset.return_value = {
            "status": "success",
            "message": "Inference engine session reset",
        }

        response = await async_client.post("/api/v1/inference/reset", json={})

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["message"] == "Inference engine session reset"
        mock_inference_client.reset.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_post_reset_connection_error_503(
        self,
        async_client: AsyncClient,
        mock_inference_client: AsyncMock,
    ) -> None:
        """Verify that reset connection failure maps to HTTP 503."""
        mock_inference_client.reset.side_effect = PrologConnectionError(
            message="Connection failed during reset",
            url="http://localhost:8080",
        )

        response = await async_client.post("/api/v1/inference/reset", json={})

        assert response.status_code == 503
        data = response.json()
        assert "Connection failed during reset" in data["detail"]

    @pytest.mark.asyncio
    async def test_inference_endpoints_404_when_disabled(
        self,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Verify that when INFERENCE_ENGINE_ENABLED is False, endpoints return HTTP 404."""
        from app.api.v1 import router as v1_router

        monkeypatch.setattr(config.settings, "INFERENCE_ENGINE_ENABLED", False)
        reloaded_router = importlib.reload(v1_router)

        disabled_app = FastAPI()
        disabled_app.include_router(reloaded_router.api_v1_router, prefix="/api/v1")

        transport = ASGITransport(app=disabled_app)
        async with AsyncClient(transport=transport, base_url="http://testserver") as client:
            resp_facts = await client.get("/api/v1/inference/facts")
            assert resp_facts.status_code == 404

            resp_load = await client.post(
                "/api/v1/inference/load",
                json={"knowledge_base": "vehicles"},
            )
            assert resp_load.status_code == 404

        # Restore module state
        monkeypatch.setattr(config.settings, "INFERENCE_ENGINE_ENABLED", True)
        importlib.reload(v1_router)
