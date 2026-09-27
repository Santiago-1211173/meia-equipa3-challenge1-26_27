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

    yield

    # Shutdown: Cleanly release network sockets and connection pools
    if not http_client.is_closed:
        await http_client.aclose()


# Create FastAPI application instance with rich metadata
app = FastAPI(
    title=settings.PROJECT_NAME,
    description=(
        "Orchestration layer for the Retail Returns & Exchanges Diagnostic Expert System. "
        "Coordinates rule evaluation across deductive logic engines (SWI-Prolog and future Drools), "
        "enforcing explainability chains, transparent justifications, and resilient fallback handling."
    ),
    version="1.0.0",
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
