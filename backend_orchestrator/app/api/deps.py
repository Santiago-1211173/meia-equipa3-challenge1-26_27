"""FastAPI dependency providers for clients and services."""

from __future__ import annotations

from fastapi import Depends, Request

from app.clients.prolog_client import PrologClient
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
