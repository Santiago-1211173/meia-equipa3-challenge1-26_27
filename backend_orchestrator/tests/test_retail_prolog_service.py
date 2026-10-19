"""Tests for RetailPrologService and official reference scenarios (1, 2, 7, 10, etc.)."""

from __future__ import annotations

import pytest

from app.clients.prolog_client import PrologClient
from app.core.config import settings
from app.services.retail_prolog_service import RetailPrologService, pedido_to_prolog_facts


def _get_service() -> RetailPrologService:
    url = getattr(settings, "PROLOG_ENGINE_URL", getattr(settings, "prolog_engine_url", "http://localhost:8080"))
    client = PrologClient(base_url=url)
    return RetailPrologService(prolog_client=client)


@pytest.mark.asyncio
async def test_scenario_1():
    """Scenario 1: Loose tags, exchange on day 29 (REVER, no TN-006)."""
    service = _get_service()
    sc = service.get_example_scenario_by_id(1)
    assert sc is not None
    res = await service.evaluate_return(sc)

    assert str(res.elegibilidade.value if hasattr(res.elegibilidade, "value") else res.elegibilidade) == "REVER"
    rule_codes = [r.codigoRegra for r in res.regras if r.codigoRegra]
    assert "TN-006" not in rule_codes


@pytest.mark.asyncio
async def test_scenario_2():
    """Scenario 2: Online Afterpay exchange exception (ENCAMINHAR, HS-005, TN-010, EX-006)."""
    service = _get_service()
    sc = service.get_example_scenario_by_id(2)
    assert sc is not None
    res = await service.evaluate_return(sc)

    assert str(res.elegibilidade.value if hasattr(res.elegibilidade, "value") else res.elegibilidade) == "ENCAMINHAR"
    rule_codes = [r.codigoRegra for r in res.regras if r.codigoRegra]
    assert "HS-005" in rule_codes
    assert "TN-010" in rule_codes
    assert "EX-006" in rule_codes


@pytest.mark.asyncio
async def test_scenario_7():
    """Scenario 7: Interac in Canada without original card (REVER, TN-011)."""
    service = _get_service()
    sc = service.get_example_scenario_by_id(7)
    assert sc is not None
    res = await service.evaluate_return(sc)

    assert str(res.elegibilidade.value if hasattr(res.elegibilidade, "value") else res.elegibilidade) == "REVER"
    rule_codes = [r.codigoRegra for r in res.regras if r.codigoRegra]
    assert "TN-011" in rule_codes


@pytest.mark.asyncio
async def test_scenario_10():
    """Scenario 10: Online late exchange with PayPal during portal outage (REVER, TN-008)."""
    service = _get_service()
    sc = service.get_example_scenario_by_id(10)
    assert sc is not None
    res = await service.evaluate_return(sc)

    assert str(res.elegibilidade.value if hasattr(res.elegibilidade, "value") else res.elegibilidade) == "REVER"
    rule_codes = [r.codigoRegra for r in res.regras if r.codigoRegra]
    assert "TN-008" in rule_codes


def test_afterpay_facts_physical_vs_online():
    """Verify afterpay_pede_excecao fact is ONLY emitted when online and exchange/exception."""
    # Physical in-store regular return: NO HS-005 / NO afterpay_pede_excecao
    pedido_fisico = {
        "tipoPedido": "devolucao",
        "compraOriginal": {
            "canal": "mainline",
            "pagamento": {"meio": "afterpay"}
        }
    }
    facts_fisico = pedido_to_prolog_facts(pedido_fisico)
    assert "meio_pagamento(afterpay)" in facts_fisico
    assert "afterpay_pede_excecao(true)" not in facts_fisico

    # Online exchange: DOES emit afterpay_pede_excecao
    pedido_online_troca = {
        "tipoPedido": "troca",
        "compraOriginal": {
            "canal": "levi_com",
            "pagamento": {"meio": "afterpay"}
        }
    }
    facts_online = pedido_to_prolog_facts(pedido_online_troca)
    assert "meio_pagamento(afterpay)" in facts_online
    assert "afterpay_pede_excecao(true)" in facts_online


def test_saldo_reembolsavel_tn006_facts():
    """Verify saldo_reembolsavel(true) is emitted when original paid > exchange items price."""
    pedido_troca_saldo = {
        "tipoPedido": "troca",
        "compraOriginal": {
            "pagamento": {"meio": "credito", "valorPago": 120.0}
        },
        "artigosTroca": [
            {"precoVenda": 80.0}
        ]
    }
    facts = pedido_to_prolog_facts(pedido_troca_saldo)
    assert "saldo_reembolsavel(true)" in facts


def test_acesso_aplicacao_pagamento_facts():
    """Verify acesso_aplicacao_pagamento(false) is mapped when false."""
    pedido_paypal = {
        "tipoPedido": "devolucao",
        "compraOriginal": {
            "pagamento": {"meio": "paypal", "acessoAplicacaoPagamento": False}
        }
    }
    facts = pedido_to_prolog_facts(pedido_paypal)
    assert "acesso_aplicacao_pagamento(false)" in facts


@pytest.mark.asyncio
async def test_explain_why_all_input_codes():
    """Verify explain_why returns accurate Prolog questions, rules, and waiting candidates."""
    service = _get_service()
    codes = [
        "IN-001", "IN-002", "IN-003", "IN-004", "IN-005",
        "IN-006", "IN-007", "IN-008", "IN-009", "IN-010",
        "EP-001", "EX-001", "EX-002",
    ]

    for code in codes:
        resp = await service.explain_why(code, {})
        assert resp.codigo == code
        assert resp.dado == code
        assert resp.pergunta is not None and len(resp.pergunta) > 10
        assert resp.resumo is not None and len(resp.resumo) > 15
        assert len(resp.regrasQueDependem) > 0
        if resp.regrasEmEspera:
            first_wait = resp.regrasEmEspera[0]
            assert first_wait.codigoRegra is not None
            assert first_wait.modulo is not None
            assert len(first_wait.condicoesDoDado) > 0


@pytest.mark.asyncio
async def test_explain_why_with_dynamic_waiting_rules():
    """Verify explain_why dynamically evaluates rules in waiting when scenario facts are present."""
    service = _get_service()
    # Scenario where payment is Interac with physical card present, but mercado is pending (IN-001)
    interac_pending_market_payload = {
        "compraOriginal": {
            "pagamento": {
                "meio": "interac",
                "cartaoFisicoPresente": True,
            }
        },
    }
    # When asking why IN-001 (mercado) is needed, TN-011 is waiting solely for mercado(canada)
    resp = await service.explain_why("IN-001", interac_pending_market_payload)
    assert resp.codigo == "IN-001"
    assert "TN-011" in resp.regrasQueDependem
    assert len(resp.regrasEmEspera) >= 1
    waiting_rule_codes = [r.codigoRegra for r in resp.regrasEmEspera]
    assert "TN-011" in waiting_rule_codes
    assert "TN-011" in resp.resumo


@pytest.mark.asyncio
async def test_explain_why_unknown_code_fallback():
    """Verify explain_why returns a graceful fallback when given an unknown code."""
    service = _get_service()
    resp = await service.explain_why("UNKNOWN-999", {})
    assert resp.codigo == "UNKNOWN-999"
    assert "UNKNOWN-999" in resp.pergunta
    assert resp.regrasQueDependem == []
    assert resp.regrasEmEspera == []

