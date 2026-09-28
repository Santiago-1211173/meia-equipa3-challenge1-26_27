"""Inference service coordinating academic example engine operations (sp_exp2.pl from Moodle)."""

from __future__ import annotations

from typing import Optional

from app.clients.inference_client import InferenceClient
from app.schemas.inference import (
    ExplainHowResponse,
    ExplainWhynotResponse,
    GetFactsResponse,
    LoadKnowledgeBaseResponse,
    ResetEngineResponse,
    RunEngineResponse,
)


class InferenceService:
    """Service layer orchestrating operations with the academic example engine (sp_exp2.pl from Moodle).

    Translates domain requests into client transport calls and serializes
    untyped responses into strongly validated Pydantic models.
    """

    def __init__(self, inference_client: Optional[InferenceClient] = None) -> None:
        """Initialize the inference service.

        Args:
            inference_client: Optional injected InferenceClient instance.
        """
        self.inference_client = inference_client or InferenceClient()

    async def load_knowledge_base(self, knowledge_base: str) -> LoadKnowledgeBaseResponse:
        """Load a knowledge base into the inference engine.

        Args:
            knowledge_base: Identifier of the knowledge base to load.

        Returns:
            Validated LoadKnowledgeBaseResponse model.
        """
        raw_response = await self.inference_client.load_kb(knowledge_base=knowledge_base)
        return LoadKnowledgeBaseResponse.model_validate(raw_response)

    async def run_engine(self) -> RunEngineResponse:
        """Execute forward-chaining deduction on active facts.

        Returns:
            Validated RunEngineResponse model with derived facts.
        """
        raw_response = await self.inference_client.run()
        return RunEngineResponse.model_validate(raw_response)

    async def get_facts(self) -> GetFactsResponse:
        """Fetch all facts asserted in working memory.

        Returns:
            Validated GetFactsResponse model.
        """
        raw_response = await self.inference_client.get_facts()
        return GetFactsResponse.model_validate(raw_response)

    async def explain_how(self, fact_id: int) -> ExplainHowResponse:
        """Generate the causal explanation chain for a fact.

        Args:
            fact_id: Identifier of the fact.

        Returns:
            Validated ExplainHowResponse model.
        """
        raw_response = await self.inference_client.explain_how(fact_id=fact_id)
        return ExplainHowResponse.model_validate(raw_response)

    async def explain_whynot(self, fact: str) -> ExplainWhynotResponse:
        """Generate diagnostic reasons explaining why a fact was not concluded.

        Args:
            fact: Fact term string.

        Returns:
            Validated ExplainWhynotResponse model.
        """
        raw_response = await self.inference_client.explain_whynot(fact=fact)
        return ExplainWhynotResponse.model_validate(raw_response)

    async def reset_engine(self) -> ResetEngineResponse:
        """Reset the working memory and knowledge base state.

        Returns:
            Validated ResetEngineResponse model.
        """
        raw_response = await self.inference_client.reset()
        return ResetEngineResponse.model_validate(raw_response)
