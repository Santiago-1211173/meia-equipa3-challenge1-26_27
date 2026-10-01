"""API v1 router aggregating all endpoints."""

from __future__ import annotations

from fastapi import APIRouter

from app.api.v1.endpoints import drools, evaluate, health

api_v1_router = APIRouter()

api_v1_router.include_router(health.router, tags=["Health"])
api_v1_router.include_router(evaluate.router, tags=["Evaluation"])
api_v1_router.include_router(drools.router)

from app.core.config import settings

if settings.INFERENCE_ENGINE_ENABLED:
    from app.api.v1.endpoints import inference

    api_v1_router.include_router(inference.router)


