"""Unit and integration tests for Drools endpoints in the orchestrator."""

from __future__ import annotations

from unittest.mock import AsyncMock

from httpx import AsyncClient
import pytest

from app.core.exceptions import (
    DroolsConnectionError,
    DroolsResponseError,
    DroolsTimeoutError,
)


class TestDroolsEndpoints:
    """Test suite for /api/v1/drools endpoints."""

    @pytest.mark.asyncio
    async def test_drools_evaluate_success(
        self,
        async_client: AsyncClient,
        mock_drools_client: AsyncMock,
    ) -> None:
        """Test successful evaluation of clinical evidence via Drools engine."""
        mock_drools_client.evaluate.return_value = {
            "status": "SUCCESS",
            "primaryDiagnosis": "Otorrhagia",
            "conclusions": ["Otorrhagia"],
            "hypothesis": "upper type",
            "firedRules": ["r1_upper_type_classification", "r3_otorrhagia_ear_ache"],
            "timestamp": "2026-10-01T12:00:01Z",
            "evidencesEvaluated": {
                "bloodEar": "yes",
                "earAche": "yes",
            },
        }

        payload = {"bloodEar": "yes", "earAche": "yes"}
        response = await async_client.post("/api/v1/drools/evaluate", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "SUCCESS"
        assert data["primaryDiagnosis"] == "Otorrhagia"
        assert data["hypothesis"] == "upper type"
        assert "r3_otorrhagia_ear_ache" in data["firedRules"]

    @pytest.mark.asyncio
    async def test_drools_evaluate_connection_error(
        self,
        async_client: AsyncClient,
        mock_drools_client: AsyncMock,
    ) -> None:
        """Test 503 response when Drools engine is unreachable."""
        mock_drools_client.evaluate.side_effect = DroolsConnectionError(
            message="Connection refused to Drools engine",
            url="http://drools-engine:8080",
        )

        payload = {"bloodEar": "yes"}
        response = await async_client.post("/api/v1/drools/evaluate", json=payload)

        assert response.status_code == 503
        assert "Connection refused" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_drools_evaluate_timeout_error(
        self,
        async_client: AsyncClient,
        mock_drools_client: AsyncMock,
    ) -> None:
        """Test 503 response when Drools engine times out."""
        mock_drools_client.evaluate.side_effect = DroolsTimeoutError(
            message="Drools evaluation timed out after 5.0s",
            timeout_seconds=5.0,
        )

        payload = {"bloodEar": "yes"}
        response = await async_client.post("/api/v1/drools/evaluate", json=payload)

        assert response.status_code == 503
        assert "timed out" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_drools_evaluate_bad_request(
        self,
        async_client: AsyncClient,
        mock_drools_client: AsyncMock,
    ) -> None:
        """Test 400 response when Drools engine rejects payload."""
        mock_drools_client.evaluate.side_effect = DroolsResponseError(
            message="Input validation failed on Drools engine",
            status_code=400,
            response_data={"error": "Invalid field"},
        )

        payload = {"bloodEar": "invalid"}
        response = await async_client.post("/api/v1/drools/evaluate", json=payload)

        assert response.status_code == 400
        assert "validation failed" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_drools_health_success(
        self,
        async_client: AsyncClient,
        mock_drools_client: AsyncMock,
    ) -> None:
        """Test 200 response on Drools health check."""
        mock_drools_client.get_health.return_value = {
            "status": "UP",
            "service": "drools-engine",
            "version": "1.0.0",
            "activeKieBase": "haemorrhageKBase",
            "totalRules": 13,
            "timestamp": "2026-10-01T12:00:00Z",
        }

        response = await async_client.get("/api/v1/drools/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "UP"
        assert data["service"] == "drools-engine"
        assert data["totalRules"] == 13
