"""Pydantic schemas for the Drools rule inference engine (Haemorrhage)."""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field


class DroolsEvidencesSchema(BaseModel):
    """Clinical evidence payload for evaluating haemorrhage diagnosis against Drools rules."""

    bloodEar: Optional[str] = Field(
        default=None,
        description="Bleeding from the ear ('yes' or 'no').",
        examples=["yes"],
    )
    earAche: Optional[str] = Field(
        default=None,
        description="Presence of earache ('yes' or 'no').",
        examples=["yes"],
    )
    deafness: Optional[str] = Field(
        default=None,
        description="Presence of hearing loss or deafness ('yes' or 'no').",
        examples=["no"],
    )
    cerebrospinal: Optional[str] = Field(
        default=None,
        description="Discharge of cerebrospinal fluid from ear/nose ('yes' or 'no').",
        examples=["no"],
    )
    bloodNose: Optional[str] = Field(
        default=None,
        description="Bleeding from the nose ('yes' or 'no').",
        examples=["no"],
    )
    vomiting: Optional[str] = Field(
        default=None,
        description="Occurrence of vomiting ('yes' or 'no').",
        examples=["no"],
    )
    bloodBrown: Optional[str] = Field(
        default=None,
        description="Presence of brown/dark blood ('yes' or 'no').",
        examples=["no"],
    )
    bloodMouth: Optional[str] = Field(
        default=None,
        description="Bleeding from the mouth ('yes' or 'no').",
        examples=["no"],
    )
    bloodPenis: Optional[str] = Field(
        default=None,
        description="Bleeding from the penis / hematuria ('yes' or 'no').",
        examples=["no"],
    )
    bloodAnus: Optional[str] = Field(
        default=None,
        description="Bleeding from the anus ('yes' or 'no').",
        examples=["no"],
    )
    bloodCoffee: Optional[str] = Field(
        default=None,
        description="Presence of coffee-ground consistency blood ('yes' or 'no').",
        examples=["no"],
    )
    headAche: Optional[str] = Field(
        default=None,
        description="Presence of severe headache ('yes' or 'no').",
        examples=["no"],
    )
    bloodVagina: Optional[str] = Field(
        default=None,
        description="Bleeding from the vagina / metrorrhagia ('yes' or 'no').",
        examples=["no"],
    )

    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "bloodEar": "yes",
                "earAche": "yes",
            }
        },
    )


class DroolsEvaluationResponse(BaseModel):
    """Response returned after running inference through the Drools rule engine."""

    status: str = Field(
        ...,
        description="Execution status ('SUCCESS' or 'ERROR').",
        examples=["SUCCESS"],
    )
    primaryDiagnosis: str = Field(
        ...,
        description="Primary diagnostic conclusion determined by Drools rules.",
        examples=["Otorrhagia"],
    )
    conclusions: List[str] = Field(
        default_factory=list,
        description="List of all conclusions deduced by the fired rules.",
        examples=[["Otorrhagia"]],
    )
    hypothesis: Optional[str] = Field(
        default=None,
        description="Intermediate classification hypothesis derived ('upper type' or 'lower type').",
        examples=["upper type"],
    )
    firedRules: List[str] = Field(
        default_factory=list,
        description="Chronological sequence of rule IDs fired during the inference cycle.",
        examples=[["r1_upper_type_classification", "r3_otorrhagia_ear_ache"]],
    )
    timestamp: Optional[str] = Field(
        default=None,
        description="ISO timestamp of the evaluation.",
        examples=["2026-10-01T12:40:27Z"],
    )
    evidencesEvaluated: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Normalized snapshot of the input evidence attributes evaluated.",
    )

    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "status": "SUCCESS",
                "primaryDiagnosis": "Otorrhagia",
                "conclusions": ["Otorrhagia"],
                "hypothesis": "upper type",
                "firedRules": [
                    "r1_upper_type_classification",
                    "r3_otorrhagia_ear_ache",
                ],
                "timestamp": "2026-10-01T12:40:27Z",
                "evidencesEvaluated": {
                    "bloodEar": "yes",
                    "earAche": "yes",
                },
            }
        },
    )


class DroolsHealthResponse(BaseModel):
    """Response payload returned by the Drools health and status check endpoint."""

    status: str = Field(
        ...,
        description="Service health status ('UP' or 'DOWN').",
        examples=["UP"],
    )
    service: str = Field(
        ...,
        description="Identifier of the microservice.",
        examples=["drools-engine"],
    )
    version: str = Field(
        ...,
        description="Semantic version of the Drools microservice.",
        examples=["1.0.0"],
    )
    activeKieBase: str = Field(
        ...,
        description="Name of the active Drools KieBase in memory.",
        examples=["haemorrhageKBase"],
    )
    totalRules: int = Field(
        ...,
        ge=0,
        description="Total count of business rules loaded in the KieBase.",
        examples=[13],
    )
    timestamp: Optional[str] = Field(
        default=None,
        description="Timestamp of the health check.",
        examples=["2026-10-01T12:40:15Z"],
    )

    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "status": "UP",
                "service": "drools-engine",
                "version": "1.0.0",
                "activeKieBase": "haemorrhageKBase",
                "totalRules": 13,
                "timestamp": "2026-10-01T12:40:15Z",
            }
        },
    )
