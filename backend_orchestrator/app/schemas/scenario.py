"""POC scenario input schemas matching the current Prolog engine contract."""

from __future__ import annotations

from typing import List, Union

from pydantic import BaseModel, ConfigDict, Field


class ScenarioInput(BaseModel):
    """Input payload for evaluating POC test scenarios."""

    scenario: str = Field(
        ...,
        min_length=1,
        description="Scenario type identifier or test scenario name to be evaluated.",
        examples=["test"],
    )
    value: Union[int, float] = Field(
        ...,
        description="Numeric value tested against demonstration inference rules in the engine.",
        examples=[42],
    )

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "scenario": "test",
                    "value": 42,
                },
                {
                    "scenario": "test",
                    "value": 15,
                },
            ]
        }
    )
