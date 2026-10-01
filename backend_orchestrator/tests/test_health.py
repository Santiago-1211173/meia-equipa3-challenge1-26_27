"""Tests for the health check and diagnostics endpoints."""

from __future__ import annotations

from unittest.mock import AsyncMock

from httpx import AsyncClient
import pytest


class TestHealthEndpoint:
    """Test suite for /health and /api/v1/health endpoints."""

    @pytest.mark.asyncio
    async def test_health_check_healthy_with_connected_prolog(
        self,
        async_client: AsyncClient,
        mock_prolog_client: AsyncMock,
    ) -> None:
        """Test that /health returns HTTP 200 and connected status when Prolog is reachable."""
        mock_prolog_client.check_health.return_value = True

        response = await async_client.get("/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["prolog_engine"] == "connected"
        assert data["drools_engine"] == "connected"
        assert "timestamp" in data

    @pytest.mark.asyncio
    async def test_health_check_healthy_with_disconnected_drools(
        self,
        async_client: AsyncClient,
        mock_prolog_client: AsyncMock,
        mock_drools_client: AsyncMock,
    ) -> None:
        """Test that /health reflects disconnected Drools engine when Drools is unreachable."""
        mock_prolog_client.check_health.return_value = True
        mock_drools_client.check_health.return_value = False

        response = await async_client.get("/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["prolog_engine"] == "connected"
        assert data["drools_engine"] == "disconnected"


    @pytest.mark.asyncio
    async def test_health_check_healthy_with_disconnected_prolog(
        self,
        async_client: AsyncClient,
        mock_prolog_client: AsyncMock,
    ) -> None:
        """Test that /health returns HTTP 200 and disconnected status when Prolog is unreachable."""
        mock_prolog_client.check_health.return_value = False

        response = await async_client.get("/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["prolog_engine"] == "disconnected"
        assert "timestamp" in data

    @pytest.mark.asyncio
    async def test_api_v1_health_check(
        self,
        async_client: AsyncClient,
        mock_prolog_client: AsyncMock,
    ) -> None:
        """Test that /api/v1/health endpoint also operates correctly."""
        mock_prolog_client.check_health.return_value = True

        response = await async_client.get("/api/v1/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["prolog_engine"] == "connected"

    @pytest.mark.asyncio
    async def test_root_endpoint(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Test that root endpoint (/) provides service metadata and docs pointers."""
        response = await async_client.get("/")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "online"
        assert "documentation" in data
        assert "api_v1" in data
