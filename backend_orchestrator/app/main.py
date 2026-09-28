"""FastAPI application entry point, middleware configuration, and lifecycle management."""

from __future__ import annotations

from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import httpx

from app.api.v1.endpoints.health import router as health_router
from app.api.v1.router import api_v1_router
from app.clients.prolog_client import PrologClient
from app.core.config import settings
from app.services.orchestrator_service import OrchestratorService


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Manage application startup and shutdown lifecycle.

    Initializes persistent HTTP transport pooling for reasoning engines
    and ensures clean connection closure on service termination.
    """
    # Startup: Initialize shared HTTP client and clients/services
    http_client = httpx.AsyncClient(
        base_url=settings.PROLOG_ENGINE_URL,
        timeout=settings.PROLOG_TIMEOUT_SECONDS,
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    prolog_client = PrologClient(
        base_url=settings.PROLOG_ENGINE_URL,
        timeout=settings.PROLOG_TIMEOUT_SECONDS,
        client=http_client,
    )
    orchestrator_service = OrchestratorService(prolog_client=prolog_client)

    app.state.http_client = http_client
    app.state.prolog_client = prolog_client
    app.state.orchestrator_service = orchestrator_service

    if settings.INFERENCE_ENGINE_ENABLED:
        from app.clients.inference_client import InferenceClient
        from app.services.inference_service import InferenceService

        inference_client = InferenceClient(
            base_url=settings.PROLOG_ENGINE_URL,
            timeout=settings.PROLOG_TIMEOUT_SECONDS,
            client=http_client,
        )
        inference_service = InferenceService(inference_client=inference_client)
        app.state.inference_client = inference_client
        app.state.inference_service = inference_service

    yield

    # Shutdown: Cleanly release network sockets and connection pools
    if not http_client.is_closed:
        await http_client.aclose()


tags_metadata = [
    {
        "name": "Academic Example Engine (sp_exp2 / Moodle)",
        "description": (
            "**Motor de Inferência de Exemplo dos Professores** (adaptado diretamente dos ficheiros de apoio do Moodle: "
            "`prolog_engine/Ficheiros de Apoio Sistemas Periciais_ sp_exp1.pl, sp_exp2.pl e base de conhecimento-20260928/sp_exp2.pl`). "
            "Este motor serve de referência pedagógica e está estritamente segmentado do motor de retalho, podendo ser ativado/desativado "
            "via variável de ambiente `INFERENCE_ENGINE_ENABLED`."
        ),
    },
    {
        "name": "Evaluation",
        "description": (
            "**Motor Pericial do Domínio de Retalho** (Devoluções e Trocas de Mercadorias — Heurísticas Dustin Hopper). "
            "Atualmente implementa a Prova de Conceito (POC) de avaliação das regras de elegibilidade (`rules.pl`). "
            "O desenvolvimento integral deste segundo motor de retalho fica reservado para as fases subsequentes do projeto."
        ),
    },
    {
        "name": "Health",
        "description": "Endpoints de diagnóstico de conectividade, prontidão e integridade do sistema.",
    },
]

# Create FastAPI application instance with rich metadata
app = FastAPI(
    title=settings.PROJECT_NAME,
    description=(
        "Orchestration layer for the Retail Returns & Exchanges Diagnostic Expert System. "
        "Coordinates rule evaluation across deductive logic engines (SWI-Prolog and future Drools), "
        "enforcing explainability chains, transparent justifications, and resilient fallback handling.\n\n"
        "### Segmentação dos Motores Prolog no Sistema:\n"
        "1. **Motor 1 (Exemplo Académico / Moodle):** Adaptado de `sp_exp2.pl` dos professores, exposto em `/api/v1/inference/*`.\n"
        "2. **Motor 2 (Domínio de Retalho / Dustin Hopper):** Regras de devoluções de retalho, exposto em `/api/v1/evaluate` (desenvolvimento de produção diferido)."
    ),
    version="1.0.0",
    openapi_tags=tags_metadata,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

# Configure Cross-Origin Resource Sharing (CORS) for Frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register API v1 routes (/api/v1/health, /api/v1/evaluate)
app.include_router(api_v1_router, prefix=settings.API_V1_STR)

# Register root health endpoint (/health) for monitoring and container healthchecks
app.include_router(health_router, tags=["Health"])


@app.get("/", include_in_schema=False)
async def root() -> dict[str, str]:
    """Root informative endpoint directing to interactive API documentation."""
    return {
        "service": settings.PROJECT_NAME,
        "status": "online",
        "documentation": "/docs",
        "api_v1": settings.API_V1_STR,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=settings.PORT,
        reload=settings.DEBUG,
    )
