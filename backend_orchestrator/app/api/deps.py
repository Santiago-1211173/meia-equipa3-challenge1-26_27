"""FastAPI dependency providers for clients and services."""

from __future__ import annotations

from fastapi import Depends, Request

from app.clients.inference_client import InferenceClient
from app.clients.prolog_client import PrologClient
from app.services.inference_service import InferenceService
from app.services.orchestrator_service import OrchestratorService


def get_prolog_client(request: Request) -> PrologClient:
    """Provide PrologClient instance, reusing the application state instance if available."""
    if hasattr(request.app.state, "prolog_client") and request.app.state.prolog_client is not None:
        return request.app.state.prolog_client
    return PrologClient()


def get_orchestrator_service(
    request: Request,
    prolog_client: PrologClient = Depends(get_prolog_client),
) -> OrchestratorService:
    """Provide OrchestratorService instance, reusing the application state instance if available."""
    if (
        hasattr(request.app.state, "orchestrator_service")
        and request.app.state.orchestrator_service is not None
    ):
        return request.app.state.orchestrator_service

    return OrchestratorService(prolog_client=prolog_client)


def get_inference_client(request: Request) -> InferenceClient:
    """Provide InferenceClient instance, reusing the application state instance if available."""
    if hasattr(request.app.state, "inference_client") and request.app.state.inference_client is not None:
        return request.app.state.inference_client
    return InferenceClient()


def get_inference_service(
    request: Request,
    inference_client: InferenceClient = Depends(get_inference_client),
) -> InferenceService:
    """Provide InferenceService instance, reusing the application state instance if available."""
    if (
        hasattr(request.app.state, "inference_service")
        and request.app.state.inference_service is not None
    ):
        return request.app.state.inference_service

    return InferenceService(inference_client=inference_client)

