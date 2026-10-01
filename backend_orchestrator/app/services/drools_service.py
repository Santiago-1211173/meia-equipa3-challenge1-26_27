"""Service coordinating with the Drools rule inference engine."""

from __future__ import annotations

from typing import Optional

from app.clients.drools_client import DroolsClient
from app.schemas.drools import (
    DroolsEvaluationResponse,
    DroolsEvidencesSchema,
    DroolsHealthResponse,
)


class DroolsService:
    """Service handling validation and evaluation calls to the Drools microservice."""

    def __init__(self, drools_client: Optional[DroolsClient] = None) -> None:
        """Initialize DroolsService with injected client."""
        self.drools_client = drools_client or DroolsClient()

    async def evaluate(self, evidences: DroolsEvidencesSchema) -> DroolsEvaluationResponse:
        """Evaluate clinical evidences against Drools business rules.

        Args:
            evidences: Validated clinical evidence payload.

        Returns:
            Structured DroolsEvaluationResponse containing conclusions and explainability trace.
        """
        raw_result = await self.drools_client.evaluate(evidences)
        return DroolsEvaluationResponse.model_validate(raw_result)

    async def get_health(self) -> DroolsHealthResponse:
        """Retrieve health and engine statistics from the Drools microservice.

        Returns:
            Structured DroolsHealthResponse with loaded rule count and active KieBase.
        """
        raw_health = await self.drools_client.get_health()
        return DroolsHealthResponse.model_validate(raw_health)
