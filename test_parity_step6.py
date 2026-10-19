import urllib.request
import json
import sys

def post_json(url, data):
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode('utf-8'),
        headers={"Content-Type": "application/json"}
    )
    resp = urllib.request.urlopen(req)
    return json.loads(resp.read().decode('utf-8'))

def get_json(url):
    req = urllib.request.Request(url)
    resp = urllib.request.urlopen(req)
    return json.loads(resp.read().decode('utf-8'))

def extract_rules(res):
    rules = []
    for r in res.get("regras", []):
        c = r.get("codigoRegra")
        if c:
            rules.append(c)
    return rules

def test_scenario_1():
    print("\n--- Test: Scenario 1 (Exchange without refundable balance) ---")
    sc_data = get_json("http://localhost:8000/api/v1/retail/cenarios-exemplo/1")
    res_p = post_json("http://localhost:8000/api/v1/retail/avaliar", sc_data)
    res_d = post_json("http://localhost:8000/api/v1/levis/avaliar", sc_data)

    assert res_p.get("elegibilidade") == "REVER"
    assert res_d.get("elegibilidade") == "REVER"
    rules_p = extract_rules(res_p)
    rules_d = extract_rules(res_d)
    assert "TN-006" not in rules_p, "TN-006 must not fire when exchange price exceeds original price"
    assert "TN-006" not in rules_d, "TN-006 must not fire in Drools for Scenario 1"
    print("  Scenario 1: Verified (REVER, no TN-006)")

def test_scenario_2():
    print("\n--- Test: Scenario 2 (Online Afterpay Exchange Exception) ---")
    sc_data = get_json("http://localhost:8000/api/v1/retail/cenarios-exemplo/2")
    res_p = post_json("http://localhost:8000/api/v1/retail/avaliar", sc_data)
    res_d = post_json("http://localhost:8000/api/v1/levis/avaliar", sc_data)

    assert res_p.get("elegibilidade") == "ENCAMINHAR"
    assert res_d.get("elegibilidade") == "ENCAMINHAR"
    rules_p = extract_rules(res_p)
    rules_d = extract_rules(res_d)
    assert "HS-005" in rules_p, "Scenario 2 must trigger HS-005 in Prolog"
    assert "HS-005" in rules_d, "Scenario 2 must trigger HS-005 in Drools"
    assert "TN-010" in rules_p, "Scenario 2 must trigger TN-010 in Prolog"
    assert "TN-010" in rules_d, "Scenario 2 must trigger TN-010 in Drools"
    print("  Scenario 2: Verified (ENCAMINHAR, HS-005, TN-010)")

def test_scenario_7():
    print("\n--- Test: Scenario 7 (Interac Canada without physical card) ---")
    sc_data = get_json("http://localhost:8000/api/v1/retail/cenarios-exemplo/7")
    res_p = post_json("http://localhost:8000/api/v1/retail/avaliar", sc_data)
    res_d = post_json("http://localhost:8000/api/v1/levis/avaliar", sc_data)

    assert res_p.get("elegibilidade") == "REVER"
    assert res_d.get("elegibilidade") == "REVER"
    rules_p = extract_rules(res_p)
    rules_d = extract_rules(res_d)
    assert "TN-011" in rules_p, "Scenario 7 must trigger TN-011 in Prolog"
    assert "TN-011" in rules_d, "Scenario 7 must trigger TN-011 in Drools"
    assert res_p.get("meioReembolso") is None or res_p.get("meioReembolso") == "SEM_MEIO_DEFINIDO"
    print("  Scenario 7: Verified (REVER, TN-011, no tender defined)")

def test_scenario_10():
    print("\n--- Test: Scenario 10 (Online late exchange with PayPal) ---")
    sc_data = get_json("http://localhost:8000/api/v1/retail/cenarios-exemplo/10")
    res_p = post_json("http://localhost:8000/api/v1/retail/avaliar", sc_data)
    res_d = post_json("http://localhost:8000/api/v1/levis/avaliar", sc_data)

    assert res_p.get("elegibilidade") == "REVER"
    assert res_d.get("elegibilidade") == "REVER"
    rules_p = extract_rules(res_p)
    rules_d = extract_rules(res_d)
    assert "TN-008" in rules_p, "Scenario 10 must trigger TN-008 in Prolog"
    assert "TN-008" in rules_d, "Scenario 10 must trigger TN-008 in Drools"
    print("  Scenario 10: Verified (REVER, TN-008)")

def test_afterpay_in_store_physical():
    print("\n--- Test: Afterpay In-Store Physical Purchase (TN-009 without HS-005) ---")
    payload = {
        "id": "TEST-AFTERPAY-PHYSICAL",
        "dataPedido": "2026-10-17",
        "tipoPedido": "DEVOLUCAO",
        "loja": {
            "codigo": "US-STORE-01",
            "mercado": "EUA",
            "tipoLoja": "MAINLINE",
            "skusSortido": ["501-ORIGINAL-FIT"]
        },
        "colaborador": {
            "id": "OP-042",
            "nome": "Tiago Silva",
            "funcao": "KEY_HOLDER",
            "idCredencialPOS": "POS-042"
        },
        "cliente": {
            "id": "CLI-DEFAULT",
            "forneceDados": True,
            "contestaResultado": False,
            "agitado": False
        },
        "compraOriginal": {
            "idTransacao": "TX-ORIG-AFTERPAY-STORE",
            "canal": "MAINLINE",
            "dataCompra": "2026-10-05",
            "moeda": "USD",
            "valorTotal": 89.9,
            "pagamento": {
                "meio": "AFTERPAY",
                "valorPago": 89.9,
                "estadoConta": "ATIVA",
                "cartaoFisicoPresente": True,
                "reembolsoOriginalRecusado": False,
                "acessoAplicacaoPagamento": True
            },
            "idStylistVenda": "S-18",
            "quantidadeComprada": 1
        },
        "comprovativo": {
            "tipo": "RECIBO_IMPRESSO",
            "idComprovativo": "RCP-84920",
            "confirmaCompra": True,
            "reciboOriginal": True
        },
        "artigos": [
            {
                "id": "A-01",
                "produto": {
                    "sku": "501-ORIGINAL-FIT",
                    "skuReconhecidoPOS": True,
                    "marca": "LEVIS",
                    "categoria": "VESTUARIO",
                    "vendidoNaLoja": True,
                    "pvpOriginal": 89.9,
                    "precoAtual": 89.9
                },
                "quantidade": 1,
                "precoPago": 89.9,
                "revendivel": True,
                "estado": {
                    "condicaoUso": "NAO_USADO",
                    "etiquetas": "COLOCADAS",
                    "revendivel": True
                },
                "entreCanais": False
            }
        ]
    }

    res_p = post_json("http://localhost:8000/api/v1/retail/avaliar", payload)
    res_d = post_json("http://localhost:8000/api/v1/levis/avaliar", payload)

    rules_p = extract_rules(res_p)
    rules_d = extract_rules(res_d)

    print(f"  Prolog Regras: {rules_p}")
    print(f"  Drools Regras: {rules_d}")

    assert "TN-009" in rules_p, "TN-009 must fire in Prolog for in-store Afterpay"
    assert "TN-009" in rules_d, "TN-009 must fire in Drools for in-store Afterpay"
    assert "HS-005" not in rules_p, "HS-005 must NOT fire for physical in-store Afterpay return"
    assert "HS-005" not in rules_d, "HS-005 must NOT fire in Drools for physical in-store Afterpay return"
    print("  Afterpay In-Store: Verified (TN-009 triggered, HS-005 correctly avoided)")

def test_exchange_with_refundable_balance_tn006():
    print("\n--- Test: Partial Exchange with Refundable Balance (TN-006 Parity) ---")
    payload = {
        "id": "TEST-EXCHANGE-TN006",
        "dataPedido": "2026-10-17",
        "tipoPedido": "TROCA",
        "loja": {
            "codigo": "US-STORE-01",
            "mercado": "EUA",
            "tipoLoja": "MAINLINE",
            "skusSortido": ["501-ORIGINAL-FIT", "721-HIGH-RISE"]
        },
        "colaborador": {
            "id": "OP-042",
            "nome": "Tiago Silva",
            "funcao": "KEY_HOLDER",
            "idCredencialPOS": "POS-042"
        },
        "cliente": {
            "id": "CLI-DEFAULT",
            "forneceDados": True,
            "contestaResultado": False,
            "agitado": False
        },
        "compraOriginal": {
            "idTransacao": "TX-ORIG-CREDIT",
            "canal": "MAINLINE",
            "dataCompra": "2026-10-05",
            "moeda": "USD",
            "valorTotal": 120.0,
            "pagamento": {
                "meio": "CREDITO",
                "valorPago": 120.0,
                "estadoConta": "ATIVA",
                "cartaoFisicoPresente": True,
                "reembolsoOriginalRecusado": False,
                "acessoAplicacaoPagamento": True
            },
            "idStylistVenda": "S-18",
            "quantidadeComprada": 1
        },
        "comprovativo": {
            "tipo": "RECIBO_IMPRESSO",
            "idComprovativo": "RCP-120",
            "confirmaCompra": True,
            "reciboOriginal": True
        },
        "artigos": [
            {
                "id": "A-01",
                "produto": {
                    "sku": "501-ORIGINAL-FIT",
                    "skuReconhecidoPOS": True,
                    "marca": "LEVIS",
                    "categoria": "VESTUARIO",
                    "vendidoNaLoja": True,
                    "pvpOriginal": 120.0,
                    "precoAtual": 120.0
                },
                "quantidade": 1,
                "precoPago": 120.0,
                "revendivel": True,
                "estado": {
                    "condicaoUso": "NAO_USADO",
                    "etiquetas": "COLOCADAS",
                    "revendivel": True
                },
                "entreCanais": False
            }
        ],
        "artigosTroca": [
            {
                "produto": {
                    "sku": "721-HIGH-RISE",
                    "skuReconhecidoPOS": True,
                    "marca": "LEVIS",
                    "categoria": "VESTUARIO",
                    "vendidoNaLoja": True,
                    "pvpOriginal": 80.0,
                    "precoAtual": 80.0
                },
                "apenasMudaTamanho": False,
                "precoVenda": 80.0
            }
        ]
    }

    res_p = post_json("http://localhost:8000/api/v1/retail/avaliar", payload)
    res_d = post_json("http://localhost:8000/api/v1/levis/avaliar", payload)

    rules_p = extract_rules(res_p)
    rules_d = extract_rules(res_d)

    print(f"  Prolog Regras: {rules_p}")
    print(f"  Drools Regras: {rules_d}")

    assert "TN-006" in rules_p, "TN-006 must fire in Prolog when exchange balance is refundable"
    assert "TN-006" in rules_d, "TN-006 must fire in Drools when exchange balance is refundable"
    print("  Exchange with Balance: Verified (TN-006 triggered in both engines)")

def test_interac_with_physical_card_present():
    print("\n--- Test: Interac Canada with Physical Card Present (TN-011 Padrão) ---")
    payload = {
        "id": "TEST-INTERAC-CARD-PRESENT",
        "dataPedido": "2026-10-17",
        "tipoPedido": "DEVOLUCAO",
        "loja": {
            "codigo": "CA-STORE-01",
            "mercado": "CANADA",
            "tipoLoja": "MAINLINE",
            "skusSortido": ["501-ORIGINAL-FIT"]
        },
        "colaborador": {
            "id": "OP-042",
            "nome": "Tiago Silva",
            "funcao": "KEY_HOLDER",
            "idCredencialPOS": "POS-042"
        },
        "cliente": {
            "id": "CLI-DEFAULT",
            "forneceDados": True,
            "contestaResultado": False,
            "agitado": False
        },
        "compraOriginal": {
            "idTransacao": "TX-ORIG-INTERAC",
            "canal": "MAINLINE",
            "dataCompra": "2026-10-05",
            "moeda": "CAD",
            "valorTotal": 98.0,
            "pagamento": {
                "meio": "INTERAC",
                "valorPago": 98.0,
                "estadoConta": "ATIVA",
                "cartaoFisicoPresente": True,
                "reembolsoOriginalRecusado": False,
                "acessoAplicacaoPagamento": True
            },
            "idStylistVenda": "S-18",
            "quantidadeComprada": 1
        },
        "comprovativo": {
            "tipo": "RECIBO_IMPRESSO",
            "idComprovativo": "RCP-98",
            "confirmaCompra": True,
            "reciboOriginal": True
        },
        "artigos": [
            {
                "id": "A-01",
                "produto": {
                    "sku": "501-ORIGINAL-FIT",
                    "skuReconhecidoPOS": True,
                    "marca": "LEVIS",
                    "categoria": "VESTUARIO",
                    "vendidoNaLoja": True,
                    "pvpOriginal": 98.0,
                    "precoAtual": 98.0
                },
                "quantidade": 1,
                "precoPago": 98.0,
                "revendivel": True,
                "estado": {
                    "condicaoUso": "NAO_USADO",
                    "etiquetas": "COLOCADAS",
                    "revendivel": True
                },
                "entreCanais": False
            }
        ]
    }

    res_p = post_json("http://localhost:8000/api/v1/retail/avaliar", payload)
    res_d = post_json("http://localhost:8000/api/v1/levis/avaliar", payload)

    assert res_p.get("elegibilidade") == "PERMITIR"
    assert res_d.get("elegibilidade") == "PERMITIR"
    rules_p = extract_rules(res_p)
    rules_d = extract_rules(res_d)

    assert "TN-011" in rules_p
    assert "TN-011" in rules_d
    assert res_p.get("meioReembolso") == "MEIO_ORIGINAL"
    assert res_d.get("meioReembolso") == "MEIO_ORIGINAL"
    print("  Interac with Card Present: Verified (PERMITIR, TN-011, MEIO_ORIGINAL)")

def test_paypal_without_app_access():
    print("\n--- Test: PayPal without App Access (Review Required - Scenario 10 Parity) ---")
    sc_data = get_json("http://localhost:8000/api/v1/retail/cenarios-exemplo/10")

    res_p = post_json("http://localhost:8000/api/v1/retail/avaliar", sc_data)
    res_d = post_json("http://localhost:8000/api/v1/levis/avaliar", sc_data)

    print("  res_p:", res_p.get("elegibilidade"), extract_rules(res_p))
    print("  res_d:", res_d.get("elegibilidade"), extract_rules(res_d))

    assert res_p.get("elegibilidade") == "REVER"
    assert res_d.get("elegibilidade") == "REVER"
    rules_p = extract_rules(res_p)
    rules_d = extract_rules(res_d)
    assert "TN-008" in rules_p
    assert "TN-008" in rules_d
    assert res_p.get("processo") == "PAYPAL_VENMO"
    assert res_d.get("processo") == "PAYPAL_VENMO"
    print("  PayPal without App Access: Verified (REVER, TN-008, PAYPAL_VENMO in both engines)")

if __name__ == "__main__":
    print("=" * 70)
    print("STEP 6 REFUND & PAYMENT METHODS PARITY SUITE")
    print("=" * 70)
    test_scenario_1()
    test_scenario_2()
    test_scenario_7()
    test_scenario_10()
    test_afterpay_in_store_physical()
    test_exchange_with_refundable_balance_tn006()
    test_interac_with_physical_card_present()
    test_paypal_without_app_access()
    print("\n" + "=" * 70)
    print("ALL STEP 6 TESTS PASSED WITH 100% PARITY BETWEEN DROOLS & PROLOG!")
    print("=" * 70)
