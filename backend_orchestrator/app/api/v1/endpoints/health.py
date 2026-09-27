"""Health check and diagnostics endpoint."""

from __future__ import annotations

from fastapi import APIRouter, Depends, status

from app.api.deps import get_orchestrator_service
from app.schemas.health import HealthResponse
from app.services.orchestrator_service import OrchestratorService

router = APIRouter()


@router.get(
    "/health",
    response_model=HealthResponse,
    status_code=status.HTTP_200_OK,
    summary="Health check and engine connectivity status",
    description="Returns the operational status of the FastAPI orchestrator and checks connectivity to the Prolog inference engine.",
)
async def get_health(
    orchestrator_service: OrchestratorService = Depends(get_orchestrator_service),
) -> HealthResponse:
    """Perform health and connectivity check across services."""
    health_data = await orchestrator_service.check_health()
    return HealthResponse(
        status=health_data.get("status", "healthy"),
        prolog_engine=health_data.get("prolog_engine", "disconnected"),
    )
