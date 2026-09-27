"""Canonical evaluation response schemas and common enumeration models."""

from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


class DecisionEnum(str, Enum):
    """Possible evaluation decision outcomes produced by the reasoning engines."""

    APPROVED = "approved"
    REJECTED = "rejected"
    STORE_CREDIT_ONLY = "store_credit_only"
    MANAGER_OVERRIDE = "manager_override"
    ERROR = "error"


class EngineSourceEnum(str, Enum):
    """Source inference engine that produced or aggregated the decision."""

    PROLOG = "prolog"
    DROOLS = "drools"
    AGGREGATED = "aggregated"


class EvaluationResponse(BaseModel):
    """Canonical evaluation response returned to clients/frontend."""

    status: str = Field(
        ...,
        description="Status indicator of the evaluation outcome ('success' or 'error').",
        examples=["success"],
    )
    decision: DecisionEnum = Field(
        ...,
        description="Deterministic inference decision reached by the expert system.",
        examples=[DecisionEnum.APPROVED],
    )
    justification: List[str] = Field(
        default_factory=list,
        description="Explainability chain (Why/Why not) detailing the rules and facts applied.",
        examples=[["Value is 42", "Dummy rule matched"]],
    )
    engine: EngineSourceEnum = Field(
        default=EngineSourceEnum.PROLOG,
        description="Inference engine that produced the decision.",
        examples=[EngineSourceEnum.PROLOG],
    )
    timestamp: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="UTC timestamp at which the evaluation was produced.",
    )
    message: Optional[str] = Field(
        default=None,
        description="Optional diagnostic or error message providing additional operational context.",
        examples=[None],
    )

    model_config = ConfigDict(
        use_enum_values=True,
        json_schema_extra={
            "example": {
                "status": "success",
                "decision": "approved",
                "justification": [
                    "Value is 42",
                    "Dummy rule matched",
                ],
                "engine": "prolog",
                "timestamp": "2026-09-27T20:00:00Z",
                "message": None,
            }
        },
    )
