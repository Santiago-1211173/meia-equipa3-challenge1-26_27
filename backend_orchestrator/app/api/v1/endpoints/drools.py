"""FastAPI endpoints for Drools rule inference engine (Haemorrhage) and health diagnostic."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_drools_service
from app.core.exceptions import (
    DroolsConnectionError,
    DroolsResponseError,
    DroolsTimeoutError,
)
from app.schemas.drools import (
    DroolsEvaluationResponse,
    DroolsEvidencesSchema,
    DroolsHealthResponse,
)
from app.services.drools_service import DroolsService

router = APIRouter(
    prefix="/drools",
    tags=["Drools Inference Engine (Haemorrhage)"],
)


@router.post(
    "/evaluate",
    response_model=DroolsEvaluationResponse,
    status_code=status.HTTP_200_OK,
    summary="Evaluate clinical evidence against Drools business rules (Haemorrhage)",
    description=(
        "Submits observed clinical symptoms and evidence to the Java Drools rule engine, "
        "returning the primary diagnosis, derived hypotheses, and the full sequence of fired rules."
    ),
    responses={
        200: {
            "description": "Evaluation successfully completed with conclusions and explainability trace.",
            "model": DroolsEvaluationResponse,
        },
        400: {"description": "Bad Request: Drools engine rejected the evidence payload."},
        503: {"description": "Service Unavailable: Drools engine is unreachable or timed out."},
    },
)
async def evaluate_drools(
    payload: DroolsEvidencesSchema,
    drools_service: DroolsService = Depends(get_drools_service),
) -> DroolsEvaluationResponse:
    """Evaluate clinical evidences using the Drools inference engine."""
    try:
        return await drools_service.evaluate(payload)
    except (DroolsConnectionError, DroolsTimeoutError) as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=exc.message,
        ) from exc
    except DroolsResponseError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=exc.message,
        ) from exc


@router.get(
    "/health",
    response_model=DroolsHealthResponse,
    status_code=status.HTTP_200_OK,
    summary="Check Drools inference engine health and rule status",
    description="Inspects the operational status, loaded rule count, and active KieBase of the Drools microservice.",
    responses={
        200: {
            "description": "Drools engine health information.",
            "model": DroolsHealthResponse,
        },
        503: {"description": "Service Unavailable: Drools engine is unreachable or timed out."},
    },
)
async def get_drools_health(
    drools_service: DroolsService = Depends(get_drools_service),
) -> DroolsHealthResponse:
    """Retrieve health and status from the Drools inference engine."""
    try:
        return await drools_service.get_health()
    except (DroolsConnectionError, DroolsTimeoutError) as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=exc.message,
        ) from exc
    except DroolsResponseError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=exc.message,
        ) from exc
