"""FastAPI dependency providers for clients and services."""

from __future__ import annotations

from fastapi import Depends, Request

from app.clients.drools_client import DroolsClient
from app.clients.inference_client import InferenceClient
from app.clients.prolog_client import PrologClient
from app.services.drools_service import DroolsService
from app.services.inference_service import InferenceService
from app.services.orchestrator_service import OrchestratorService


def get_prolog_client(request: Request) -> PrologClient:
    """Provide PrologClient instance, reusing the application state instance if available."""
    if hasattr(request.app.state, "prolog_client") and request.app.state.prolog_client is not None:
        return request.app.state.prolog_client
    return PrologClient()


def get_drools_client(request: Request) -> DroolsClient:
    """Provide DroolsClient instance, reusing the application state instance if available."""
    if hasattr(request.app.state, "drools_client") and request.app.state.drools_client is not None:
        return request.app.state.drools_client
    return DroolsClient()


def get_orchestrator_service(
    request: Request,
    prolog_client: PrologClient = Depends(get_prolog_client),
    drools_client: DroolsClient = Depends(get_drools_client),
) -> OrchestratorService:
    """Provide OrchestratorService instance, reusing the application state instance if available."""
    if (
        hasattr(request.app.state, "orchestrator_service")
        and request.app.state.orchestrator_service is not None
    ):
        return request.app.state.orchestrator_service

    return OrchestratorService(prolog_client=prolog_client, drools_client=drools_client)


def get_drools_service(
    request: Request,
    drools_client: DroolsClient = Depends(get_drools_client),
) -> DroolsService:
    """Provide DroolsService instance, reusing the application state instance if available."""
    if hasattr(request.app.state, "drools_service") and request.app.state.drools_service is not None:
        return request.app.state.drools_service
    return DroolsService(drools_client=drools_client)


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


