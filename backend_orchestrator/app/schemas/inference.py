"""Pydantic schemas for the academic example inference engine (sp_exp2.pl from Moodle)."""

from __future__ import annotations

from typing import List, Union

from pydantic import BaseModel, ConfigDict, Field


class LoadKnowledgeBaseRequest(BaseModel):
    """Request payload to load a knowledge base into the inference engine."""

    knowledge_base: str = Field(
        ...,
        min_length=1,
        description="Name of the knowledge base file (without .pl extension) to load.",
        examples=["vehicles"],
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "knowledge_base": "vehicles",
            }
        }
    )


class LoadKnowledgeBaseResponse(BaseModel):
    """Response returned after attempting to load a knowledge base."""

    status: str = Field(
        ...,
        description="Status indicator of the operation ('success' or 'error').",
        examples=["success"],
    )
    message: str = Field(
        ...,
        description="Informative status message detailing result of operation.",
        examples=["Knowledge base 'vehicles' loaded successfully"],
    )
    initial_facts_count: int = Field(
        ...,
        ge=0,
        description="Count of facts initially asserted upon loading.",
        examples=[3],
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "status": "success",
                "message": "Knowledge base 'vehicles' loaded successfully",
                "initial_facts_count": 3,
            }
        }
    )


class DerivedFactSchema(BaseModel):
    """Representation of an inferred fact with its justification chain."""

    id: int = Field(
        ...,
        ge=1,
        description="Sequential identifier assigned to the derived fact.",
        examples=[4],
    )
    fact: str = Field(
        ...,
        min_length=1,
        description="String representation of the inferred Prolog fact.",
        examples=["classe(meu_veiculo,pesado)"],
    )
    rule_id: int = Field(
        ...,
        ge=1,
        description="Identifier of the rule that fired and produced this fact.",
        examples=[6],
    )
    justified_by: List[Union[int, str]] = Field(
        default_factory=list,
        description="List of fact identifiers or condition strings justifying this derivation.",
        examples=[[2]],
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "id": 4,
                "fact": "classe(meu_veiculo,pesado)",
                "rule_id": 6,
                "justified_by": [2],
            }
        }
    )


class RunEngineResponse(BaseModel):
    """Response returned after running forward-chaining deduction."""

    status: str = Field(
        ...,
        description="Status indicator of the inference execution ('success' or 'error').",
        examples=["success"],
    )
    initial_facts_count: int = Field(
        ...,
        ge=0,
        description="Number of facts present before running the inference engine.",
        examples=[3],
    )
    derived_facts_count: int = Field(
        ...,
        ge=0,
        description="Number of new facts derived during the inference cycle.",
        examples=[2],
    )
    total_facts: int = Field(
        ...,
        ge=0,
        description="Total number of facts in working memory after execution.",
        examples=[5],
    )
    derived_facts: List[DerivedFactSchema] = Field(
        default_factory=list,
        description="List of all facts derived by the forward-chaining engine.",
        examples=[
            [
                {
                    "id": 4,
                    "fact": "classe(meu_veiculo,pesado)",
                    "rule_id": 6,
                    "justified_by": [2],
                },
                {
                    "id": 5,
                    "fact": "pesado(meu_veiculo,camiao)",
                    "rule_id": 2,
                    "justified_by": [3, 4],
                },
            ]
        ],
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "status": "success",
                "initial_facts_count": 3,
                "derived_facts_count": 2,
                "total_facts": 5,
                "derived_facts": [
                    {
                        "id": 4,
                        "fact": "classe(meu_veiculo,pesado)",
                        "rule_id": 6,
                        "justified_by": [2],
                    },
                    {
                        "id": 5,
                        "fact": "pesado(meu_veiculo,camiao)",
                        "rule_id": 2,
                        "justified_by": [3, 4],
                    },
                ],
            }
        }
    )


class FactSchema(BaseModel):
    """Representation of a single fact in working memory."""

    id: int = Field(
        ...,
        ge=1,
        description="Sequential identifier of the fact.",
        examples=[1],
    )
    fact: str = Field(
        ...,
        min_length=1,
        description="String representation of the Prolog fact.",
        examples=["lotacao(meu_veiculo,3)"],
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "id": 1,
                "fact": "lotacao(meu_veiculo,3)",
            }
        }
    )


class GetFactsResponse(BaseModel):
    """Response containing all facts currently in working memory."""

    status: str = Field(
        ...,
        description="Status indicator of the operation ('success' or 'error').",
        examples=["success"],
    )
    facts_count: int = Field(
        ...,
        ge=0,
        description="Total count of facts currently asserted in working memory.",
        examples=[5],
    )
    facts: List[FactSchema] = Field(
        default_factory=list,
        description="List of all active facts in working memory.",
        examples=[
            [
                {"id": 1, "fact": "lotacao(meu_veiculo,3)"},
                {"id": 2, "fact": "peso(meu_veiculo,4500)"},
                {"id": 3, "fact": "tipo(meu_veiculo,mercadorias)"},
                {"id": 4, "fact": "classe(meu_veiculo,pesado)"},
                {"id": 5, "fact": "pesado(meu_veiculo,camiao)"},
            ]
        ],
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "status": "success",
                "facts_count": 5,
                "facts": [
                    {"id": 1, "fact": "lotacao(meu_veiculo,3)"},
                    {"id": 2, "fact": "peso(meu_veiculo,4500)"},
                    {"id": 3, "fact": "tipo(meu_veiculo,mercadorias)"},
                    {"id": 4, "fact": "classe(meu_veiculo,pesado)"},
                    {"id": 5, "fact": "pesado(meu_veiculo,camiao)"},
                ],
            }
        }
    )


class ExplainHowRequest(BaseModel):
    """Request payload to query the derivation trace of a fact."""

    fact_id: int = Field(
        ...,
        ge=1,
        description="Sequential ID of the fact to explain.",
        examples=[4],
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "fact_id": 4,
            }
        }
    )


class ExplainHowResponse(BaseModel):
    """Response providing the causal explainability trace for a fact."""

    status: str = Field(
        ...,
        description="Status indicator of the explanation query ('success' or 'error').",
        examples=["success"],
    )
    fact_id: int = Field(
        ...,
        ge=1,
        description="Sequential identifier of the fact being explained.",
        examples=[4],
    )
    explanation: List[str] = Field(
        default_factory=list,
        description="Sequential explainability chain detailing how the fact was derived.",
        examples=[
            [
                "Fact 4 -> classe(meu_veiculo,pesado) concluded by rule 6",
                "Based on facts: [2]",
                "Fact 2 -> peso(meu_veiculo,4500) was an initial fact",
            ]
        ],
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "status": "success",
                "fact_id": 4,
                "explanation": [
                    "Fact 4 -> classe(meu_veiculo,pesado) concluded by rule 6",
                    "Based on facts: [2]",
                    "Fact 2 -> peso(meu_veiculo,4500) was an initial fact",
                ],
            }
        }
    )


class ExplainWhynotRequest(BaseModel):
    """Request payload to query why a fact could not be concluded."""

    fact: str = Field(
        ...,
        min_length=1,
        description="Prolog term string of the target fact to investigate.",
        examples=["classe(meu_veiculo,ligeiro)"],
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "fact": "classe(meu_veiculo,ligeiro)",
            }
        }
    )


class ExplainWhynotResponse(BaseModel):
    """Response detailing why a specific fact was not derived."""

    status: str = Field(
        ...,
        description="Status indicator of the explanation query ('success' or 'error').",
        examples=["success"],
    )
    fact: str = Field(
        ...,
        min_length=1,
        description="String representation of the queried fact term.",
        examples=["classe(meu_veiculo,ligeiro)"],
    )
    explanation: List[str] = Field(
        default_factory=list,
        description="Diagnostic reasons detailing why the fact could not be derived.",
        examples=[
            [
                "Investigating why not: classe(meu_veiculo,ligeiro)",
                "Rule 7 could conclude classe(meu_veiculo,ligeiro), but:",
                "  Premise failed: avalia(peso(meu_veiculo,=<,3500))",
            ]
        ],
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "status": "success",
                "fact": "classe(meu_veiculo,ligeiro)",
                "explanation": [
                    "Investigating why not: classe(meu_veiculo,ligeiro)",
                    "Rule 7 could conclude classe(meu_veiculo,ligeiro), but:",
                    "  Premise failed: avalia(peso(meu_veiculo,=<,3500))",
                ],
            }
        }
    )


class ResetEngineResponse(BaseModel):
    """Response confirming reset of the inference engine session."""

    status: str = Field(
        ...,
        description="Status indicator of the reset operation ('success' or 'error').",
        examples=["success"],
    )
    message: str = Field(
        ...,
        description="Informative status message confirming session reset.",
        examples=["Inference engine session reset"],
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "status": "success",
                "message": "Inference engine session reset",
            }
        }
    )
