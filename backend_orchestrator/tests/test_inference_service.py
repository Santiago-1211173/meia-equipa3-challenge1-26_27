"""Unit tests for the InferenceService layer with mocked InferenceClient."""

from __future__ import annotations

from unittest.mock import AsyncMock
import pytest

from app.clients.inference_client import InferenceClient
from app.schemas.inference import (
    ExplainHowResponse,
    ExplainWhynotResponse,
    GetFactsResponse,
    LoadKnowledgeBaseResponse,
    ResetEngineResponse,
    RunEngineResponse,
)
from app.services.inference_service import InferenceService


class TestInferenceService:
    """Test suite for InferenceService orchestration and schema serialization."""

    @pytest.mark.asyncio
    async def test_load_knowledge_base_returns_typed_schema(
        self,
        mock_inference_client: AsyncMock,
        inference_service: InferenceService,
    ) -> None:
        """Verify load_knowledge_base maps response to LoadKnowledgeBaseResponse."""
        mock_inference_client.load_kb.return_value = {
            "status": "success",
            "message": "Loaded vehicles",
            "initial_facts_count": 3,
        }

        result = await inference_service.load_knowledge_base("vehicles")

        assert isinstance(result, LoadKnowledgeBaseResponse)
        assert result.status == "success"
        assert result.message == "Loaded vehicles"
        assert result.initial_facts_count == 3
        mock_inference_client.load_kb.assert_awaited_once_with(knowledge_base="vehicles")

    @pytest.mark.asyncio
    async def test_run_engine_returns_typed_schema(
        self,
        mock_inference_client: AsyncMock,
        inference_service: InferenceService,
    ) -> None:
        """Verify run_engine maps response to RunEngineResponse with derived facts."""
        mock_inference_client.run.return_value = {
            "status": "success",
            "initial_facts_count": 3,
            "derived_facts_count": 2,
            "total_facts": 5,
            "derived_facts": [
                {"id": 4, "fact": "classe(meu_veiculo,pesado)", "rule_id": 6, "justified_by": [2]},
                {"id": 5, "fact": "pesado(meu_veiculo,camiao)", "rule_id": 2, "justified_by": [3, 4]},
            ],
        }

        result = await inference_service.run_engine()

        assert isinstance(result, RunEngineResponse)
        assert result.status == "success"
        assert result.initial_facts_count == 3
        assert result.derived_facts_count == 2
        assert result.total_facts == 5
        assert len(result.derived_facts) == 2
        assert result.derived_facts[0].id == 4
        assert result.derived_facts[0].rule_id == 6
        assert result.derived_facts[0].justified_by == [2]
        mock_inference_client.run.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_get_facts_returns_typed_schema(
        self,
        mock_inference_client: AsyncMock,
        inference_service: InferenceService,
    ) -> None:
        """Verify get_facts maps response to GetFactsResponse."""
        mock_inference_client.get_facts.return_value = {
            "status": "success",
            "facts_count": 3,
            "facts": [
                {"id": 1, "fact": "lotacao(meu_veiculo,3)"},
                {"id": 2, "fact": "peso(meu_veiculo,4500)"},
                {"id": 3, "fact": "tipo(meu_veiculo,mercadorias)"},
            ],
        }

        result = await inference_service.get_facts()

        assert isinstance(result, GetFactsResponse)
        assert result.status == "success"
        assert result.facts_count == 3
        assert len(result.facts) == 3
        assert result.facts[1].id == 2
        assert result.facts[1].fact == "peso(meu_veiculo,4500)"
        mock_inference_client.get_facts.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_explain_how_returns_typed_schema(
        self,
        mock_inference_client: AsyncMock,
        inference_service: InferenceService,
    ) -> None:
        """Verify explain_how maps response to ExplainHowResponse."""
        mock_inference_client.explain_how.return_value = {
            "status": "success",
            "fact_id": 4,
            "explanation": [
                "Fact 4 -> classe(meu_veiculo,pesado) concluded by rule 6",
                "Based on facts: [2]",
            ],
        }

        result = await inference_service.explain_how(4)

        assert isinstance(result, ExplainHowResponse)
        assert result.status == "success"
        assert result.fact_id == 4
        assert len(result.explanation) == 2
        mock_inference_client.explain_how.assert_awaited_once_with(fact_id=4)

    @pytest.mark.asyncio
    async def test_explain_whynot_returns_typed_schema(
        self,
        mock_inference_client: AsyncMock,
        inference_service: InferenceService,
    ) -> None:
        """Verify explain_whynot maps response to ExplainWhynotResponse."""
        mock_inference_client.explain_whynot.return_value = {
            "status": "success",
            "fact": "classe(meu_veiculo,ligeiro)",
            "explanation": [
                "Because by rule 7:",
                "  Condition peso(meu_veiculo,=<,3500) is false",
            ],
        }

        result = await inference_service.explain_whynot("classe(meu_veiculo,ligeiro)")

        assert isinstance(result, ExplainWhynotResponse)
        assert result.status == "success"
        assert result.fact == "classe(meu_veiculo,ligeiro)"
        assert len(result.explanation) == 2
        mock_inference_client.explain_whynot.assert_awaited_once_with(fact="classe(meu_veiculo,ligeiro)")

    @pytest.mark.asyncio
    async def test_reset_engine_returns_typed_schema(
        self,
        mock_inference_client: AsyncMock,
        inference_service: InferenceService,
    ) -> None:
        """Verify reset_engine maps response to ResetEngineResponse."""
        mock_inference_client.reset.return_value = {
            "status": "success",
            "message": "Session reset",
        }

        result = await inference_service.reset_engine()

        assert isinstance(result, ResetEngineResponse)
        assert result.status == "success"
        assert result.message == "Session reset"
        mock_inference_client.reset.assert_awaited_once()

    def test_default_client_initialization(self) -> None:
        """Verify InferenceService initializes an internal InferenceClient if none is provided."""
        service = InferenceService()
        assert isinstance(service.inference_client, InferenceClient)
