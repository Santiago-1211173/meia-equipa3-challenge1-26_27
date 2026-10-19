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

def run_test():
    print("=================================================================")
    print("STEP 4 CONTRACT & PARITY VALIDATION SUITE (DROOLS vs PROLOG)")
    print("=================================================================")

    # 1. Official scenarios 1, 3, 7, 8
    print("\n--- Phase 4.1: Official Reference Scenarios 1, 3, 7, 8 ---")
    for sc_id in [1, 3, 7, 8]:
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
        
        assert eleg_p == eleg_d, f"Elegibilidade mismatch for Scenario {sc_id}: Prolog={eleg_p}, Drools={eleg_d}"

    # 2. Case 1: Gift return (DEVOLUCAO_OFERTA)
    print("\n--- Phase 4.2: Gift Return Contract (DEVOLUCAO_OFERTA) ---")
    gift_payload = {
        "id": "TEST-GIFT-01",
        "dataPedido": "2026-10-17",
        "tipoPedido": "DEVOLUCAO_OFERTA",
        "loja": {
            "codigo": "US-STORE-01",
            "mercado": "EUA",
            "tipoLoja": "MAINLINE",
            "skusSortido": ["501-ORIGINAL-FIT"]
        },
        "colaborador": {
            "id": "OP-01",
            "nome": "Operador",
            "funcao": "KEY_HOLDER"
        },
        "cliente": {
            "idCliente": "CLI-01",
            "forneceDados": True,
            "paisResidencia": "EUA"
        },
        "compraOriginal": {
            "canal": "MAINLINE",
            "dataCompra": "2026-10-01",
            "compraOferta": True,
            "moeda": "USD",
            "valorTotal": 89.99,
            "pagamento": {
                "meio": "CREDITO",
                "valorPago": 89.99,
                "estadoConta": "ATIVA",
                "cartaoFisicoPresente": True
            }
        },
        "comprovativo": {
            "tipo": "RECIBO_OFERTA",
            "confirmaCompra": True,
            "reciboOriginal": True
        },
        "artigos": [{
            "id": "ART-01",
            "produto": {
                "sku": "501-ORIGINAL-FIT",
                "skuReconhecidoPOS": True,
                "marca": "LEVIS",
                "categoria": "VESTUARIO"
            },
            "estado": {
                "condicaoUso": "NAO_USADO",
                "etiquetas": "COLOCADAS"
            },
            "preco": 89.99
        }]
    }

    res_drools_gift = post_json("http://localhost:8000/api/v1/levis/avaliar", gift_payload)
    res_prolog_gift = post_json("http://localhost:8000/api/v1/retail/avaliar", gift_payload)

    print(f"  Prolog Gift: Elegibilidade = {res_prolog_gift.get('elegibilidade')}, Regras = {extract_rules(res_prolog_gift)}")
    print(f"  Drools Gift: Elegibilidade = {res_drools_gift.get('elegibilidade')}, Regras = {extract_rules(res_drools_gift)}")
    assert res_drools_gift.get('elegibilidade') == res_prolog_gift.get('elegibilidade'), "Gift return mismatch!"
    print("  -> Passed! Drools correctly accepted DEVOLUCAO_OFERTA (no HTTP 400).")

    # 3. Case 2: Sem Comprovativo na Outlet (Blind return)
    print("\n--- Phase 4.3: Sem Comprovativo na Outlet (PT-002 + PT-005) ---")
    blind_payload = {
        "id": "TEST-BLIND-02",
        "dataPedido": "2026-10-17",
        "tipoPedido": "DEVOLUCAO",
        "loja": {
            "codigo": "US-STORE-OUTLET",
            "mercado": "EUA",
            "tipoLoja": "OUTLET",
            "skusSortido": ["501-ORIGINAL-FIT"]
        },
        "colaborador": {
            "id": "OP-01",
            "nome": "Operador",
            "funcao": "KEY_HOLDER"
        },
        "cliente": {
            "idCliente": "CLI-01",
            "forneceDados": True,
            "paisResidencia": "EUA"
        },
        "compraOriginal": {
            "canal": "OUTLET",
            "dataCompra": None,
            "idTransacao": None,
            "moeda": "USD",
            "valorTotal": 59.99,
            "pagamento": {
                "meio": "CREDITO",
                "valorPago": 59.99,
                "estadoConta": "ATIVA",
                "cartaoFisicoPresente": True
            }
        },
        "comprovativo": None,
        "artigos": [{
            "id": "ART-01",
            "produto": {
                "sku": "501-ORIGINAL-FIT",
                "skuReconhecidoPOS": True,
                "marca": "LEVIS",
                "categoria": "VESTUARIO"
            },
            "estado": {
                "condicaoUso": "NAO_USADO",
                "etiquetas": "COLOCADAS"
            },
            "preco": 59.99
        }]
    }

    res_drools_blind = post_json("http://localhost:8000/api/v1/levis/avaliar", blind_payload)
    res_prolog_blind = post_json("http://localhost:8000/api/v1/retail/avaliar", blind_payload)

    rules_d_blind = extract_rules(res_drools_blind)
    rules_p_blind = extract_rules(res_prolog_blind)

    print(f"  Prolog Blind: Elegibilidade = {res_prolog_blind.get('elegibilidade')}, Regras = {rules_p_blind}")
    print(f"  Drools Blind: Elegibilidade = {res_drools_blind.get('elegibilidade')}, Regras = {rules_d_blind}")
    assert res_drools_blind.get('elegibilidade') == res_prolog_blind.get('elegibilidade'), "Blind return mismatch!"
    assert "PT-002" in rules_d_blind and "PT-002" in rules_p_blind, "PT-002 not triggered in both engines!"
    assert "PT-005" in rules_d_blind and "PT-005" in rules_p_blind, "PT-005 not triggered in both engines!"
    print("  -> Passed! Both engines triggered PT-002 (devolução às cegas) and PT-005 (crédito de loja ao preço atual).")

    # 4. Case 3: Ajuste de Preco > 14 dias
    print("\n--- Phase 4.4: Ajuste de Preco > 14 dias (PT-008 Recusar) ---")
    adj_over14_payload = {
        "id": "TEST-ADJ-OVER14",
        "dataPedido": "2026-10-17",
        "tipoPedido": "AJUSTE_PRECO",
        "loja": {
            "codigo": "US-STORE-01",
            "mercado": "EUA",
            "tipoLoja": "MAINLINE",
            "skusSortido": ["501-ORIGINAL-FIT"]
        },
        "colaborador": {
            "id": "OP-01",
            "nome": "Operador",
            "funcao": "KEY_HOLDER"
        },
        "cliente": {
            "idCliente": "CLI-01",
            "forneceDados": True,
            "paisResidencia": "EUA"
        },
        "compraOriginal": {
            "canal": "MAINLINE",
            "dataCompra": "2026-09-25", # 22 days ago > 14
            "moeda": "USD",
            "valorTotal": 98.00,
            "pagamento": {
                "meio": "CREDITO",
                "valorPago": 98.00,
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
            "id": "ART-01",
            "produto": {
                "sku": "501-ORIGINAL-FIT",
                "skuReconhecidoPOS": True,
                "marca": "LEVIS",
                "categoria": "VESTUARIO"
            },
            "estado": {
                "condicaoUso": "NAO_USADO",
                "etiquetas": "COLOCADAS"
            },
            "preco": 98.00
        }]
    }

    res_drools_adj = post_json("http://localhost:8000/api/v1/levis/avaliar", adj_over14_payload)
    res_prolog_adj = post_json("http://localhost:8000/api/v1/retail/avaliar", adj_over14_payload)

    rules_d_adj = extract_rules(res_drools_adj)
    rules_p_adj = extract_rules(res_prolog_adj)

    print(f"  Prolog Adj >14d: Elegibilidade = {res_prolog_adj.get('elegibilidade')}, Regras = {rules_p_adj}")
    print(f"  Drools Adj >14d: Elegibilidade = {res_drools_adj.get('elegibilidade')}, Regras = {rules_d_adj}")
    assert res_drools_adj.get('elegibilidade') == "RECUSAR" and res_prolog_adj.get('elegibilidade') == "RECUSAR", "Both must RECUSAR!"
    assert "PT-008" in rules_d_adj and "PT-008" in rules_p_adj, "PT-008 not triggered in both engines!"
    print("  -> Passed! Both engines rejected price adjustment with PT-008.")

    # 5. Case 4: Ajuste de Preco <= 14 dias com foto de recibo (não original físico)
    print("\n--- Phase 4.5: Ajuste de Preco com Foto de Recibo (PT-008 Recusar) ---")
    adj_foto_payload = {
        "id": "TEST-ADJ-FOTO",
        "dataPedido": "2026-10-17",
        "tipoPedido": "AJUSTE_PRECO",
        "loja": {
            "codigo": "US-STORE-01",
            "mercado": "EUA",
            "tipoLoja": "MAINLINE",
            "skusSortido": ["501-ORIGINAL-FIT"]
        },
        "colaborador": {
            "id": "OP-01",
            "nome": "Operador",
            "funcao": "KEY_HOLDER"
        },
        "cliente": {
            "idCliente": "CLI-01",
            "forneceDados": True,
            "paisResidencia": "EUA"
        },
        "compraOriginal": {
            "canal": "MAINLINE",
            "dataCompra": "2026-10-10", # 7 days ago <= 14
            "moeda": "USD",
            "valorTotal": 98.00,
            "pagamento": {
                "meio": "CREDITO",
                "valorPago": 98.00,
                "estadoConta": "ATIVA",
                "cartaoFisicoPresente": True
            }
        },
        "comprovativo": {
            "tipo": "FOTOGRAFIA_RECIBO",
            "confirmaCompra": True,
            "reciboOriginal": False
        },
        "artigos": [{
            "id": "ART-01",
            "produto": {
                "sku": "501-ORIGINAL-FIT",
                "skuReconhecidoPOS": True,
                "marca": "LEVIS",
                "categoria": "VESTUARIO"
            },
            "estado": {
                "condicaoUso": "NAO_USADO",
                "etiquetas": "COLOCADAS"
            },
            "preco": 98.00
        }]
    }

    res_drools_foto = post_json("http://localhost:8000/api/v1/levis/avaliar", adj_foto_payload)
    res_prolog_foto = post_json("http://localhost:8000/api/v1/retail/avaliar", adj_foto_payload)

    rules_d_foto = extract_rules(res_drools_foto)
    rules_p_foto = extract_rules(res_prolog_foto)

    print(f"  Prolog Adj Foto: Elegibilidade = {res_prolog_foto.get('elegibilidade')}, Regras = {rules_p_foto}")
    print(f"  Drools Adj Foto: Elegibilidade = {res_drools_foto.get('elegibilidade')}, Regras = {rules_d_foto}")
    assert res_drools_foto.get('elegibilidade') == "RECUSAR" and res_prolog_foto.get('elegibilidade') == "RECUSAR", "Both must RECUSAR!"
    assert "PT-008" in rules_d_foto and "PT-008" in rules_p_foto, "PT-008 not triggered in both engines!"
    print("  -> Passed! Both engines rejected price adjustment with PT-008 due to lack of original physical receipt.")

    print("\n=================================================================")
    print("CONGRATULATIONS: 100% PARITY & CONTRACT COMPLIANCE CONFIRMED!")
    print("=================================================================")

if __name__ == "__main__":
    run_test()
