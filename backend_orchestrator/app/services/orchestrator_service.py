"""Orchestrator service coordinating inference engines and response synthesis."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, Optional, Union

from pydantic import BaseModel

from app.clients.prolog_client import PrologClient
from app.schemas.common import DecisionEnum, EngineSourceEnum, EvaluationResponse
from app.schemas.scenario import ScenarioInput


class OrchestratorService:
    """Service coordinating inference across knowledge engines.

    Acts as the orchestration layer between the public API and
    specialized reasoning engines (SWI-Prolog and future Drools engine).
    Ensures schema adaptation, explainability chain aggregation, and error handling.
    """

    def __init__(self, prolog_client: Optional[PrologClient] = None) -> None:
        """Initialize orchestrator service with reasoning engine clients.

        Args:
            prolog_client: Optional injected PrologClient instance.
        """
        self.prolog_client = prolog_client or PrologClient()

    async def evaluate_scenario(
        self, scenario_data: Union[ScenarioInput, BaseModel, Dict[str, Any]]
    ) -> EvaluationResponse:
        """Evaluate a scenario against reasoning engines and return canonical response.

        Args:
            scenario_data: Scenario input model or dictionary of facts.

        Returns:
            Canonical EvaluationResponse containing decision and explainability chain.
        """
        # 1. Adapt input data to facts payload
        if isinstance(scenario_data, BaseModel):
            payload = scenario_data.model_dump()
        elif isinstance(scenario_data, dict):
            payload = dict(scenario_data)
        else:
            raise ValueError(f"Unsupported scenario_data type: {type(scenario_data)}")

        # 2. Invoke Prolog inference engine
        raw_response = await self.prolog_client.evaluate(payload)

        # 3. Architectural Extension Point for Drools Engine:
        # In future phases, we will invoke the Drools engine concurrently or sequentially:
        # drools_response = await self.drools_client.evaluate(payload)
        # We will then synthesize and compare diagnostic justifications:
        # return self._aggregate_decisions(prolog_response=raw_response, drools_response=drools_response)

        # 4. Map engine response to canonical domain model
        return self._map_prolog_response(raw_response)

    def _map_prolog_response(self, raw: Dict[str, Any]) -> EvaluationResponse:
        """Map raw dictionary from Prolog engine to canonical EvaluationResponse.

        Args:
            raw: Dictionary returned by the Prolog evaluate endpoint.

        Returns:
            Typed canonical EvaluationResponse with explainability.
        """
        status = raw.get("status", "success")
        raw_decision = str(raw.get("decision", "rejected")).lower()

        try:
            decision = DecisionEnum(raw_decision)
        except ValueError:
            decision = DecisionEnum.ERROR if status == "error" else DecisionEnum.REJECTED

        justification = raw.get("justification", [])
        if not isinstance(justification, list):
            justification = [str(justification)] if justification else []

        message = raw.get("message")

        return EvaluationResponse(
            status=status,
            decision=decision,
            justification=justification,
            engine=EngineSourceEnum.PROLOG,
            timestamp=datetime.now(timezone.utc),
            message=message,
        )

    async def check_health(self) -> Dict[str, str]:
        """Check operational connectivity to reasoning engines.

        Returns:
            Dict containing orchestrator status and engine connectivity.
        """
        is_prolog_connected = await self.prolog_client.check_health()
        return {
            "status": "healthy",
            "prolog_engine": "connected" if is_prolog_connected else "disconnected",
        }
