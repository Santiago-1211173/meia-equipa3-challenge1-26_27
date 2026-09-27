"""Retail returns domain schemas preparing for real-world store policy rules."""

from __future__ import annotations

from enum import Enum
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class ItemCondition(str, Enum):
    """Condition assessment of the returned merchandise."""

    UNWORN_CLEAN = "unworn_clean"
    WORN = "worn"
    WASHED = "washed"
    DAMAGED = "damaged"
    DEFECTIVE = "defective"


class ItemSchema(BaseModel):
    """Product attributes and physical state relevant to return eligibility."""

    category: str = Field(
        ...,
        min_length=1,
        description="Merchandise category (e.g., 'apparel', 'footwear', 'electronics', 'intimate').",
        examples=["apparel"],
    )
    is_underwear: bool = Field(
        default=False,
        description="Indicates whether the item is classified as underwear or intimate hygiene wear.",
        examples=[False],
    )
    has_tags: bool = Field(
        ...,
        description="Indicates whether the original manufacturer/store tags and packaging are intact.",
        examples=[True],
    )
    condition: ItemCondition = Field(
        ...,
        description="Evaluated physical condition of the item.",
        examples=[ItemCondition.UNWORN_CLEAN],
    )

    model_config = ConfigDict(
        use_enum_values=True,
        json_schema_extra={
            "example": {
                "category": "apparel",
                "is_underwear": False,
                "has_tags": True,
                "condition": "unworn_clean",
            }
        },
    )


class PurchaseSchema(BaseModel):
    """Transaction details and purchase context."""

    has_receipt: bool = Field(
        ...,
        description="Whether a valid sales receipt is presented by the customer.",
        examples=[True],
    )
    is_gift_receipt: bool = Field(
        default=False,
        description="Indicates if the presented receipt is a gift receipt.",
        examples=[False],
    )
    days_since_purchase: int = Field(
        ...,
        ge=0,
        description="Elapsed days between the date of purchase and the return request.",
        examples=[18],
    )
    channel: str = Field(
        default="physical_store",
        description="Sales channel through which the item was acquired (e.g., 'physical_store', 'online').",
        examples=["physical_store"],
    )
    payment_method: str = Field(
        default="credit_card",
        description="Method used for original tender (e.g., 'credit_card', 'cash', 'store_credit').",
        examples=["credit_card"],
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "has_receipt": True,
                "is_gift_receipt": False,
                "days_since_purchase": 18,
                "channel": "physical_store",
                "payment_method": "credit_card",
            }
        }
    )


class RetailReturnScenarioInput(BaseModel):
    """Complete domain scenario payload for retail returns and exchanges."""

    scenario: Literal["retail_return"] = Field(
        default="retail_return",
        description="Discriminator identifier for retail return evaluation scenarios.",
        examples=["retail_return"],
    )
    item: ItemSchema = Field(
        ...,
        description="Detailed item specifications and physical condition.",
    )
    purchase: PurchaseSchema = Field(
        ...,
        description="Purchase transaction metadata and timeline.",
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "scenario": "retail_return",
                "item": {
                    "category": "apparel",
                    "is_underwear": False,
                    "has_tags": True,
                    "condition": "unworn_clean",
                },
                "purchase": {
                    "has_receipt": True,
                    "is_gift_receipt": False,
                    "days_since_purchase": 18,
                    "channel": "physical_store",
                    "payment_method": "credit_card",
                },
            }
        }
    )
