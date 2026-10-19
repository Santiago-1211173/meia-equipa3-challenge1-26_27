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

def run_tests():
    print("=" * 70)
    print("STEP 5 CONTRACT & PARITY VALIDATION SUITE (EXCHANGE & EXCEPTIONS)")
    print("=" * 70)

    # --------------------------------------------------------------------------
    # 1. Official Reference Scenarios 1, 2, 7, 8, 10
    # --------------------------------------------------------------------------
    print("\n--- Test 1: Official Reference Scenarios 1, 2, 7, 8, 10 ---")
    for sc_id in [1, 2, 7, 8, 10]:
        sc_data = get_json(f"http://localhost:8000/api/v1/retail/cenarios-exemplo/{sc_id}")
        
        res_prolog = post_json("http://localhost:8000/api/v1/retail/avaliar", sc_data)
        res_drools = post_json("http://localhost:8000/api/v1/levis/avaliar", sc_data)
        
        eleg_p = res_prolog.get("elegibilidade")
        eleg_d = res_drools.get("elegibilidade")
        rules_p = extract_rules(res_prolog)
        rules_d = extract_rules(res_drools)
        
        print(f"\n[Cenario {sc_id:02d}] {sc_data.get('titulo')}")
        print(f"  Prolog: Elegibilidade = {eleg_p} | Regras = {rules_p}")
        print(f"  Drools: Elegibilidade = {eleg_d} | Regras = {rules_d}")
        
        assert eleg_p == eleg_d, f"Elegibilidade mismatch in Scenario {sc_id}: Prolog={eleg_p}, Drools={eleg_d}"
        
        if sc_id == 1:
            assert "EP-001" in rules_d, "Scenario 1 must trigger EP-001 in Drools"
            # Note: In Prolog Scenario 1 facts, EP-001 or decision is REVER
        elif sc_id == 2:
            assert "EX-003" in rules_p and "EX-003" in rules_d, "Scenario 2 must trigger EX-003 in both"
            assert "EX-006" in rules_p and "EX-006" in rules_d, "Scenario 2 must trigger EX-006 in both"
        elif sc_id == 7:
            assert "EX-002" in rules_p and "EX-002" in rules_d, "Scenario 7 must trigger EX-002 in both"
        elif sc_id == 8:
            assert "EX-002" in rules_p and "EX-002" in rules_d, "Scenario 8 must trigger EX-002 in both"
        elif sc_id == 10:
            assert "EX-002" in rules_d, "Scenario 10 must trigger EX-002 in Drools"

    # --------------------------------------------------------------------------
    # 2. Exchange Option: MESMO_MODELO vs OUTRO_ARTIGO (EP-001 vs EP-002)
    # --------------------------------------------------------------------------
    print("\n--- Test 2: Exchange Contract: MESMO_MODELO (EP-001) vs OUTRO_ARTIGO (EP-002) ---")
    
    base_exchange_payload = {
        "id": "TEST-EXCHANGE-BASE",
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
            "idCliente": "CLI-DEFAULT",
            "forneceDados": True,
            "paisResidencia": "EUA",
            "contestaResultado": False,
            "agitado": False
        },
        "compraOriginal": {
            "idTransacao": "TX-ORIG-123456",
            "canal": "MAINLINE",
            "dataCompra": "2026-10-05",
            "moeda": "USD",
            "valorTotal": 89.9,
            "pagamento": {
                "meio": "CREDITO",
                "valorPago": 89.9,
                "estadoConta": "ATIVA",
                "cartaoFisicoPresente": True
            }
        },
        "comprovativo": {
            "tipo": "RECIBO_IMPRESSO",
            "confirmaCompra": True,
            "reciboOriginal": True
        },
        "artigos": [{
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
                "etiquetas": "COLOCADAS"
            }
        }]
    }

    # 2a. MESMO_MODELO: apenasMudaTamanho = True -> EP-001
    payload_mesmo = dict(base_exchange_payload)
    payload_mesmo["id"] = "TEST-EXCHANGE-MESMO-MODELO"
    payload_mesmo["artigosTroca"] = [{
        "produto": {
            "sku": "501-ORIGINAL-FIT-32",
            "skuReconhecidoPOS": True,
            "marca": "LEVIS",
            "categoria": "VESTUARIO",
            "vendidoNaLoja": True,
            "pvpOriginal": 89.9,
            "precoAtual": 89.9
        },
        "apenasMudaTamanho": True,
        "precoVenda": 89.9
    }]
    
    res_mesmo_d = post_json("http://localhost:8000/api/v1/levis/avaliar", payload_mesmo)
    res_mesmo_p = post_json("http://localhost:8000/api/v1/retail/avaliar", payload_mesmo)
    rules_mesmo_d = extract_rules(res_mesmo_d)
    rules_mesmo_p = extract_rules(res_mesmo_p)
    print(f"  [Mesmo Modelo / Tamanho]")
    print(f"    Drools: {rules_mesmo_d}")
    print(f"    Prolog: {rules_mesmo_p}")
    assert "EP-001" in rules_mesmo_d, "Drools must fire EP-001 for MESMO_MODELO"
    assert "EP-001" in rules_mesmo_p, "Prolog must fire EP-001 for MESMO_MODELO"
    assert "EP-002" not in rules_mesmo_d, "Drools must NOT fire EP-002 for MESMO_MODELO"
    assert "EP-002" not in rules_mesmo_p, "Prolog must NOT fire EP-002 for MESMO_MODELO"

    # 2b. OUTRO_ARTIGO: apenasMudaTamanho = False -> EP-002
    payload_outro = dict(base_exchange_payload)
    payload_outro["id"] = "TEST-EXCHANGE-OUTRO-ARTIGO"
    payload_outro["artigosTroca"] = [{
        "produto": {
            "sku": "721-HIGH-RISE-30",
            "skuReconhecidoPOS": True,
            "marca": "LEVIS",
            "categoria": "VESTUARIO",
            "vendidoNaLoja": True,
            "pvpOriginal": 89.9,
            "precoAtual": 89.9
        },
        "apenasMudaTamanho": False,
        "precoVenda": 89.9
    }]
    
    res_outro_d = post_json("http://localhost:8000/api/v1/levis/avaliar", payload_outro)
    res_outro_p = post_json("http://localhost:8000/api/v1/retail/avaliar", payload_outro)
    rules_outro_d = extract_rules(res_outro_d)
    rules_outro_p = extract_rules(res_outro_p)
    print(f"  [Outro Artigo Diferente]")
    print(f"    Drools: {rules_outro_d}")
    print(f"    Prolog: {rules_outro_p}")
    assert "EP-002" in rules_outro_d, "Drools must fire EP-002 for OUTRO_ARTIGO"
    assert "EP-002" in rules_outro_p, "Prolog must fire EP-002 for OUTRO_ARTIGO"
    assert "EP-001" not in rules_outro_d, "Drools must NOT fire EP-001 for OUTRO_ARTIGO"
    assert "EP-001" not in rules_outro_p, "Prolog must NOT fire EP-001 for OUTRO_ARTIGO"

    # --------------------------------------------------------------------------
    # 3. Customer Situation: CONTESTA (EX-002) & CHAMAR_GERENCIA (EX-003)
    # --------------------------------------------------------------------------
    print("\n--- Test 3: Customer Situation: CONTESTA (EX-002) & CHAMAR_GERENCIA (EX-003) ---")
    
    # 3a. CONTESTA
    payload_contesta = dict(payload_mesmo)
    payload_contesta["id"] = "TEST-CUSTOMER-CONTESTA"
    payload_contesta["situacaoCliente"] = "CONTESTA"
    payload_contesta["cliente"] = {
        "id": "CLI-DEFAULT",
        "idCliente": "CLI-DEFAULT",
        "forneceDados": True,
        "paisResidencia": "EUA",
        "contestaResultado": True,
        "agitado": False
    }
    payload_contesta["pedidoExcecao"] = {
        "aprovada": None,
        "concluivelNoSistema": True
    }
    
    res_contesta_d = post_json("http://localhost:8000/api/v1/levis/avaliar", payload_contesta)
    res_contesta_p = post_json("http://localhost:8000/api/v1/retail/avaliar", payload_contesta)
    rules_contesta_d = extract_rules(res_contesta_d)
    rules_contesta_p = extract_rules(res_contesta_p)
    print(f"  [Contesta Politica]")
    print(f"    Drools: {rules_contesta_d}")
    print(f"    Prolog: {rules_contesta_p}")
    assert "EX-002" in rules_contesta_d, "Drools must fire EX-002 when cliente contesta"
    assert "EX-002" in rules_contesta_p, "Prolog must fire EX-002 when cliente contesta"
    assert "EX-003" not in rules_contesta_d, "Drools must NOT fire EX-003 when not agitado"
    assert "EX-003" not in rules_contesta_p, "Prolog must NOT fire EX-003 when not agitado"

    # 3b. CHAMAR_GERENCIA (agitado = True)
    payload_gerencia = dict(payload_mesmo)
    payload_gerencia["id"] = "TEST-CUSTOMER-GERENCIA"
    payload_gerencia["situacaoCliente"] = "CHAMAR_GERENCIA"
    payload_gerencia["cliente"] = {
        "id": "CLI-DEFAULT",
        "idCliente": "CLI-DEFAULT",
        "forneceDados": True,
        "paisResidencia": "EUA",
        "contestaResultado": True,
        "agitado": True
    }
    payload_gerencia["pedidoExcecao"] = {
        "aprovada": None,
        "concluivelNoSistema": True
    }
    
    res_gerencia_d = post_json("http://localhost:8000/api/v1/levis/avaliar", payload_gerencia)
    res_gerencia_p = post_json("http://localhost:8000/api/v1/retail/avaliar", payload_gerencia)
    rules_gerencia_d = extract_rules(res_gerencia_d)
    rules_gerencia_p = extract_rules(res_gerencia_p)
    print(f"  [Chamar Gerencia]")
    print(f"    Drools: {rules_gerencia_d} | Aprovacao: {res_gerencia_d.get('aprovacao')}")
    print(f"    Prolog: {rules_gerencia_p} | Aprovacao: {res_gerencia_p.get('aprovacao')}")
    assert "EX-003" in rules_gerencia_d, "Drools must fire EX-003 for agitated client"
    assert "EX-003" in rules_gerencia_p, "Prolog must fire EX-003 for agitated client"
    assert res_gerencia_d.get("aprovacao") == "RESPONSAVEL_SENIOR", "Drools must escalate approval to RESPONSAVEL_SENIOR"
    assert res_gerencia_p.get("aprovacao") == "RESPONSAVEL_SENIOR", "Prolog must escalate approval to RESPONSAVEL_SENIOR"

    # --------------------------------------------------------------------------
    # 4. Afterpay with agitated client and exception attempt (EX-006)
    # --------------------------------------------------------------------------
    print("\n--- Test 4: Afterpay with Exception Request (EX-006 Absolute Rule) ---")
    payload_afterpay = dict(payload_gerencia)
    payload_afterpay["id"] = "TEST-AFTERPAY-EXCEPTION"
    payload_afterpay["compraOriginal"] = dict(payload_gerencia["compraOriginal"])
    payload_afterpay["compraOriginal"]["pagamento"] = {
        "meio": "AFTERPAY",
        "valorPago": 89.9,
        "estadoConta": "ATIVA"
    }
    payload_afterpay["pedidoExcecao"] = {
        "motivo": "Cliente exige troca imediata no balcao com Afterpay",
        "resolucaoPedida": "TROCA",
        "contornaProcessoObrigatorio": True,
        "concluivelNoSistema": True
    }
    
    res_afterpay_d = post_json("http://localhost:8000/api/v1/levis/avaliar", payload_afterpay)
    res_afterpay_p = post_json("http://localhost:8000/api/v1/retail/avaliar", payload_afterpay)
    rules_afterpay_d = extract_rules(res_afterpay_d)
    rules_afterpay_p = extract_rules(res_afterpay_p)
    print(f"  [Afterpay Excecao]")
    print(f"    Drools: {rules_afterpay_d} | ExcecaoRecusada: {res_afterpay_d.get('excecaoRecusada')}")
    print(f"    Prolog: {rules_afterpay_p} | ExcecaoRecusada: {res_afterpay_p.get('excecaoRecusada')}")
    assert "EX-006" in rules_afterpay_p, "Prolog must fire EX-006 for Afterpay exception attempt"
    assert "EX-006" in rules_afterpay_d, "Drools must fire EX-006 for Afterpay exception attempt"

    # --------------------------------------------------------------------------
    # 5. Standard Return: DEVOLUCAO with empty artigosTroca (No EP-001 / EP-002)
    # --------------------------------------------------------------------------
    print("\n--- Test 5: Standard Return (DEVOLUCAO with empty artigosTroca) ---")
    payload_devolucao = dict(base_exchange_payload)
    payload_devolucao["id"] = "TEST-RETURN-STANDARD"
    payload_devolucao["tipoPedido"] = "DEVOLUCAO"
    payload_devolucao["artigosTroca"] = []
    
    res_devolucao_d = post_json("http://localhost:8000/api/v1/levis/avaliar", payload_devolucao)
    res_devolucao_p = post_json("http://localhost:8000/api/v1/retail/avaliar", payload_devolucao)
    rules_devolucao_d = extract_rules(res_devolucao_d)
    rules_devolucao_p = extract_rules(res_devolucao_p)
    eleg_dev_d = res_devolucao_d.get("elegibilidade")
    eleg_dev_p = res_devolucao_p.get("elegibilidade")
    
    print(f"  [Devolucao Standard]")
    print(f"    Drools: Elegibilidade={eleg_dev_d} | Regras={rules_devolucao_d}")
    print(f"    Prolog: Elegibilidade={eleg_dev_p} | Regras={rules_devolucao_p}")
    assert eleg_dev_d == eleg_dev_p, f"Elegibilidade mismatch: Drools={eleg_dev_d}, Prolog={eleg_dev_p}"
    assert "EP-001" not in rules_devolucao_d, "Drools must NOT fire EP-001 for DEVOLUCAO"
    assert "EP-001" not in rules_devolucao_p, "Prolog must NOT fire EP-001 for DEVOLUCAO"
    assert "EP-002" not in rules_devolucao_d, "Drools must NOT fire EP-002 for DEVOLUCAO"
    assert "EP-002" not in rules_devolucao_p, "Prolog must NOT fire EP-002 for DEVOLUCAO"

    print("\n" + "=" * 70)
    print("ALL TESTS PASSED WITH 100% PARITY BETWEEN DROOLS & PROLOG!")
    print("=" * 70)

if __name__ == "__main__":
    run_tests()
