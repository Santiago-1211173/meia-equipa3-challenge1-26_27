"""FastAPI endpoints for the academic example inference engine (sp_exp2.pl from Moodle) and explainability."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_inference_service
from app.core.exceptions import (
    PrologConnectionError,
    PrologResponseError,
    PrologTimeoutError,
)
from app.schemas.inference import (
    ExplainHowRequest,
    ExplainHowResponse,
    ExplainWhynotRequest,
    ExplainWhynotResponse,
    GetFactsResponse,
    LoadKnowledgeBaseRequest,
    LoadKnowledgeBaseResponse,
    ResetEngineResponse,
    RunEngineResponse,
)
from app.services.inference_service import InferenceService

router = APIRouter(
    prefix="/inference",
    tags=["Academic Example Engine (sp_exp2 / Moodle)"],
)


@router.post(
    "/load",
    response_model=LoadKnowledgeBaseResponse,
    status_code=status.HTTP_200_OK,
    summary="Load academic example KB (sp_exp2 / Moodle)",
    description=(
        "Loads a designated knowledge base (e.g. 'vehicles', adapted from veiculos2.txt) "
        "into the professors' academic example inference engine (sp_exp2.pl from Moodle)."
    ),
    responses={
        200: {
            "description": "Knowledge base successfully loaded into the academic example engine.",
            "model": LoadKnowledgeBaseResponse,
        },
        400: {"description": "Bad Request: Knowledge base not found or load failed."},
        503: {"description": "Service Unavailable: Prolog engine is unreachable or timed out."},
    },
)
async def load_knowledge_base(
    payload: LoadKnowledgeBaseRequest,
    inference_service: InferenceService = Depends(get_inference_service),
) -> LoadKnowledgeBaseResponse:
    """Load knowledge base by name into working memory."""
    try:
        return await inference_service.load_knowledge_base(payload.knowledge_base)
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


@router.post(
    "/run",
    response_model=RunEngineResponse,
    status_code=status.HTTP_200_OK,
    summary="Run academic forward-chaining deduction (sp_exp2 / Moodle)",
    description=(
        "Executes the forward-chaining cycle using the academic example engine (sp_exp2.pl from Moodle) "
        "across all active facts and metaknowledge rules."
    ),
    responses={
        200: {
            "description": "Inference successfully completed with derived facts.",
            "model": RunEngineResponse,
        },
        400: {"description": "Bad Request: Engine execution error."},
        503: {"description": "Service Unavailable: Prolog engine is unreachable or timed out."},
    },
)
async def run_engine(
    inference_service: InferenceService = Depends(get_inference_service),
) -> RunEngineResponse:
    """Run deduction cycle of the academic example engine and return derived facts."""
    try:
        return await inference_service.run_engine()
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


@router.get(
    "/facts",
    response_model=GetFactsResponse,
    status_code=status.HTTP_200_OK,
    summary="List all active facts (sp_exp2 / Moodle)",
    description="Returns all facts currently held in working memory by the academic example engine.",
    responses={
        200: {
            "description": "List of active facts in working memory.",
            "model": GetFactsResponse,
        },
        503: {"description": "Service Unavailable: Prolog engine is unreachable or timed out."},
    },
)
async def get_facts(
    inference_service: InferenceService = Depends(get_inference_service),
) -> GetFactsResponse:
    """Retrieve all asserted facts from the academic example engine."""
    try:
        return await inference_service.get_facts()
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


@router.post(
    "/how",
    response_model=ExplainHowResponse,
    status_code=status.HTTP_200_OK,
    summary="Explain how a fact was derived (sp_exp2 / Moodle)",
    description=(
        "Traces the causal reasoning path and rules (como/1 in sp_exp2.pl) "
        "that concluded a specific fact in the academic example engine."
    ),
    responses={
        200: {
            "description": "Causal explainability chain for the fact.",
            "model": ExplainHowResponse,
        },
        400: {"description": "Bad Request: Fact ID not found or invalid."},
        503: {"description": "Service Unavailable: Prolog engine is unreachable or timed out."},
    },
)
async def explain_how(
    payload: ExplainHowRequest,
    inference_service: InferenceService = Depends(get_inference_service),
) -> ExplainHowResponse:
    """Explain how a fact was inferred using the academic engine's justification tree."""
    try:
        return await inference_service.explain_how(payload.fact_id)
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


@router.post(
    "/whynot",
    response_model=ExplainWhynotResponse,
    status_code=status.HTTP_200_OK,
    summary="Explain why a fact was not derived (sp_exp2 / Moodle)",
    description=(
        "Analyzes candidate rules for a fact term and pinpoints unsatisfied conditions "
        "(whynot/1 in sp_exp2.pl) in the academic example engine."
    ),
    responses={
        200: {
            "description": "Diagnostic explanation of failed rule conditions.",
            "model": ExplainWhynotResponse,
        },
        400: {"description": "Bad Request: Malformed term or query error."},
        503: {"description": "Service Unavailable: Prolog engine is unreachable or timed out."},
    },
)
async def explain_whynot(
    payload: ExplainWhynotRequest,
    inference_service: InferenceService = Depends(get_inference_service),
) -> ExplainWhynotResponse:
    """Explain why a fact was not inferred in the academic example engine."""
    try:
        return await inference_service.explain_whynot(payload.fact)
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


@router.post(
    "/reset",
    response_model=ResetEngineResponse,
    status_code=status.HTTP_200_OK,
    summary="Reset academic inference engine (sp_exp2 / Moodle)",
    description="Clears all facts, justifications, and knowledge base rules in the academic example engine session.",
    responses={
        200: {
            "description": "Inference engine reset confirmation.",
            "model": ResetEngineResponse,
        },
        503: {"description": "Service Unavailable: Prolog engine is unreachable or timed out."},
    },
)
async def reset_engine(
    inference_service: InferenceService = Depends(get_inference_service),
) -> ResetEngineResponse:
    """Reset working memory and loaded rules."""
    try:
        return await inference_service.reset_engine()
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
