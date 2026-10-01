"""Health check response schema."""

from __future__ import annotations

from datetime import datetime, timezone

from pydantic import BaseModel, ConfigDict, Field


class HealthResponse(BaseModel):
    """Schema for health check endpoint responses."""

    status: str = Field(
        default="healthy",
        description="Operational status of the FastAPI orchestrator service.",
        examples=["healthy"],
    )
    prolog_engine: str = Field(
        ...,
        description="Connectivity status to the SWI-Prolog reasoning engine ('connected' or 'disconnected').",
        examples=["connected"],
    )
    drools_engine: str = Field(
        default="disconnected",
        description="Connectivity status to the Drools reasoning engine ('connected' or 'disconnected').",
        examples=["connected"],
    )
    timestamp: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="UTC timestamp of the diagnostic check.",
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "status": "healthy",
                "prolog_engine": "connected",
                "drools_engine": "connected",
                "timestamp": "2026-09-27T20:00:00Z",
            }
        }
    )

