"""Unit tests for Pydantic schema validation and serialization."""

from __future__ import annotations

from datetime import datetime
import pytest
from pydantic import ValidationError

from app.schemas.common import DecisionEnum, EngineSourceEnum, EvaluationResponse
from app.schemas.health import HealthResponse
from app.schemas.retail import (
    ItemCondition,
    ItemSchema,
    PurchaseSchema,
    RetailReturnScenarioInput,
)
from app.schemas.scenario import ScenarioInput


class TestScenarioInput:
    """Tests for POC ScenarioInput schema."""

    def test_valid_integer_value(self):
        payload = {"scenario": "test", "value": 42}
        schema = ScenarioInput(**payload)
        assert schema.scenario == "test"
        assert schema.value == 42
        assert schema.model_dump() == payload

    def test_valid_float_value(self):
        payload = {"scenario": "test", "value": 42.5}
        schema = ScenarioInput(**payload)
        assert schema.scenario == "test"
        assert schema.value == 42.5

    def test_valid_zero_and_negative_value(self):
        schema_zero = ScenarioInput(scenario="test", value=0)
        assert schema_zero.value == 0

        schema_neg = ScenarioInput(scenario="test", value=-10)
        assert schema_neg.value == -10

    def test_invalid_string_value_rejected(self):
        with pytest.raises(ValidationError) as exc_info:
            ScenarioInput.model_validate({"scenario": "test", "value": "not_a_number"})
        assert "value" in str(exc_info.value)

    def test_missing_required_fields_rejected(self):
        with pytest.raises(ValidationError):
            ScenarioInput.model_validate({})

    def test_missing_value_field_rejected(self):
        with pytest.raises(ValidationError):
            ScenarioInput.model_validate({"scenario": "test"})

    def test_missing_scenario_field_rejected(self):
        with pytest.raises(ValidationError):
            ScenarioInput.model_validate({"value": 42})

    def test_empty_scenario_rejected(self):
        with pytest.raises(ValidationError):
            ScenarioInput.model_validate({"scenario": "", "value": 10})


class TestEvaluationResponse:
    """Tests for canonical EvaluationResponse schema."""

    def test_default_values(self):
        response = EvaluationResponse(
            status="success",
            decision=DecisionEnum.APPROVED,
            justification=["Rule 1 matched", "Rule 2 matched"],
        )
        assert response.status == "success"
        assert response.decision == DecisionEnum.APPROVED
        assert response.justification == ["Rule 1 matched", "Rule 2 matched"]
        assert response.engine == EngineSourceEnum.PROLOG
        assert response.timestamp is not None
        assert isinstance(response.timestamp, datetime)
        assert response.message is None

    def test_all_decision_enums_supported(self):
        for decision_enum in DecisionEnum:
            response = EvaluationResponse(
                status="success",
                decision=decision_enum,
                justification=["Test justification"],
            )
            assert response.decision == decision_enum

    def test_custom_engine_and_decision(self):
        response = EvaluationResponse(
            status="success",
            decision=DecisionEnum.STORE_CREDIT_ONLY,
            justification=["Return period expired, store credit allowed"],
            engine=EngineSourceEnum.AGGREGATED,
            message="Diagnosed with Drools and Prolog",
        )
        assert response.decision == "store_credit_only"
        assert response.engine == "aggregated"
        assert response.message == "Diagnosed with Drools and Prolog"

    def test_invalid_decision_enum_rejected(self):
        with pytest.raises(ValidationError):
            EvaluationResponse.model_validate(
                {
                    "status": "success",
                    "decision": "unsupported_decision",
                    "justification": [],
                }
            )

    def test_invalid_engine_enum_rejected(self):
        with pytest.raises(ValidationError):
            EvaluationResponse.model_validate(
                {
                    "status": "success",
                    "decision": "approved",
                    "justification": [],
                    "engine": "invalid_engine",
                }
            )

    def test_json_serialization(self):
        response = EvaluationResponse(
            status="success",
            decision=DecisionEnum.REJECTED,
            justification=["Value is not 42"],
        )
        json_data = response.model_dump_json()
        assert '"decision":"rejected"' in json_data
        assert '"engine":"prolog"' in json_data


class TestHealthResponse:
    """Tests for HealthResponse schema."""

    def test_valid_health_response(self):
        response = HealthResponse(status="healthy", prolog_engine="connected")
        assert response.status == "healthy"
        assert response.prolog_engine == "connected"
        assert response.timestamp is not None

    def test_missing_prolog_engine_rejected(self):
        with pytest.raises(ValidationError):
            HealthResponse.model_validate({"status": "healthy"})


class TestRetailSchemas:
    """Tests for retail domain extension schemas."""

    def test_valid_retail_return_scenario(self):
        item = ItemSchema(
            category="apparel",
            is_underwear=False,
            has_tags=True,
            condition=ItemCondition.UNWORN_CLEAN,
        )
        purchase = PurchaseSchema(
            has_receipt=True,
            is_gift_receipt=False,
            days_since_purchase=14,
            channel="physical_store",
            payment_method="credit_card",
        )
        scenario = RetailReturnScenarioInput(item=item, purchase=purchase)

        assert scenario.scenario == "retail_return"
        assert scenario.item.category == "apparel"
        assert scenario.item.condition == "unworn_clean"
        assert scenario.purchase.has_receipt is True
        assert scenario.purchase.days_since_purchase == 14

    def test_purchase_defaults(self):
        purchase = PurchaseSchema(
            has_receipt=True,
            days_since_purchase=5,
        )
        assert purchase.is_gift_receipt is False
        assert purchase.channel == "physical_store"
        assert purchase.payment_method == "credit_card"

    def test_invalid_item_condition_rejected(self):
        with pytest.raises(ValidationError):
            ItemSchema.model_validate(
                {
                    "category": "apparel",
                    "is_underwear": False,
                    "has_tags": True,
                    "condition": "torn",
                }
            )

    def test_negative_days_since_purchase_rejected(self):
        with pytest.raises(ValidationError):
            PurchaseSchema.model_validate(
                {
                    "has_receipt": True,
                    "days_since_purchase": -1,
                }
            )
