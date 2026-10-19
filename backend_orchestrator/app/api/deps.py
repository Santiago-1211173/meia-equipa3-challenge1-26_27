"""FastAPI dependency providers for clients and services."""

from __future__ import annotations

from fastapi import Depends, Request

from app.clients.drools_client import DroolsClient
from app.clients.inference_client import InferenceClient
from app.clients.levis_client import LevisClient
from app.clients.prolog_client import PrologClient
from app.db.session import get_db  # noqa: F401
from app.services.drools_service import DroolsService
from app.services.inference_service import InferenceService
from app.services.levis_service import LevisService
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


def get_levis_client(request: Request) -> LevisClient:
    """Provide LevisClient instance, reusing the application state instance if available."""
    if hasattr(request.app.state, "levis_client") and request.app.state.levis_client is not None:
        return request.app.state.levis_client
    return LevisClient()


def get_levis_service(
    request: Request,
    levis_client: LevisClient = Depends(get_levis_client),
) -> LevisService:
    """Provide LevisService instance, reusing the application state instance if available."""
    if hasattr(request.app.state, "levis_service") and request.app.state.levis_service is not None:
        return request.app.state.levis_service
    return LevisService(levis_client=levis_client)


def get_retail_prolog_service(
    request: Request,
    prolog_client: PrologClient = Depends(get_prolog_client),
    levis_service: LevisService = Depends(get_levis_service),
):
    """Provide RetailPrologService instance, reusing application state if available."""
    if hasattr(request.app.state, "retail_prolog_service") and request.app.state.retail_prolog_service is not None:
        return request.app.state.retail_prolog_service
    from app.services.retail_prolog_service import RetailPrologService
    svc = RetailPrologService(prolog_client=prolog_client, levis_service=levis_service)
    request.app.state.retail_prolog_service = svc
    return svc


def get_inferences_service(
    request: Request,
    levis_service: LevisService = Depends(get_levis_service),
    retail_prolog_service=Depends(get_retail_prolog_service),
):
    """Provide InferencesService instance, reusing application state if available."""
    if hasattr(request.app.state, "inferences_service") and request.app.state.inferences_service is not None:
        return request.app.state.inferences_service
    from app.services.inferences_service import InferencesService
    svc = InferencesService(levis_service=levis_service, retail_service=retail_prolog_service)
    request.app.state.inferences_service = svc
    return svc





