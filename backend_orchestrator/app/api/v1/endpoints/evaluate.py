"""Evaluation endpoint for retail return/exchange scenarios."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_orchestrator_service
from app.core.exceptions import (
    PrologConnectionError,
    PrologResponseError,
    PrologTimeoutError,
)
from app.schemas.common import EvaluationResponse
from app.schemas.scenario import ScenarioInput
from app.services.orchestrator_service import OrchestratorService

router = APIRouter()


@router.post(
    "/evaluate",
    response_model=EvaluationResponse,
    status_code=status.HTTP_200_OK,
    summary="Evaluate scenario against reasoning engines",
    description=(
        "Receives scenario facts, orchestrates inference with the SWI-Prolog "
        "reasoning engine, and returns a canonical diagnosis with explainability."
    ),
    responses={
        200: {
            "description": "Evaluation successfully completed with explainability chain.",
            "model": EvaluationResponse,
        },
        400: {
            "description": "Bad Request: Reasoning engine rejected the payload.",
        },
        503: {
            "description": "Service Unavailable: Reasoning engine is unreachable or timed out.",
        },
    },
)
async def evaluate_scenario(
    scenario_input: ScenarioInput,
    orchestrator_service: OrchestratorService = Depends(get_orchestrator_service),
) -> EvaluationResponse:
    """Evaluate a scenario input and produce diagnostic decision."""
    try:
        return await orchestrator_service.evaluate_scenario(scenario_input)
    except (PrologConnectionError, PrologTimeoutError) as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=exc.message,
        ) from exc
    except PrologResponseError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=exc.message,
        ) from exc
