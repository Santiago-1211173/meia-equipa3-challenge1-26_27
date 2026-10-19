:- module(test_retail_expert_scenarios, [
    run_expert_scenarios_tests/0
]).

/** <module> PLUnit Tests for Official Levi's Expert Test Scenarios (10 Scenarios)
 *
 * Validates the 10 official retail return scenarios established with domain
 * expert Dustin Hopper against the Prolog inference engine (src/core/retail_engine/engine.pl).
 *
 * Scenarios:
 *   1. Scenario 1: Tags detached, exchange on day 29 (REVER / Manager Review)
 *   2. Scenario 2: Agitated customer with Afterpay return (ENCAMINHAR / Route BackPocket)
 *   3. Scenario 3: Gift return in Outlet without receipt (PERMITIR / Store Credit Blind Return)
 *   4. Scenario 4: Hemmed/altered jeans with manufacturing defect (RECUSAR / Denied by HS-003)
 *   5. Scenario 5: Wholesale product return dispute (RECUSAR / Denied by CH-008 / HS-002)
 *   6. Scenario 6: Multi-item blind return with biohazard & fraud risk (REVER / District Area Escalation)
 *   7. Scenario 7: Interac debit card replacement in Canada (REVER / Manager Review for Tender)
 *   8. Scenario 8: Price adjustment after promotion change with photo receipt (RECUSAR / Denied by PT-008)
 *   9. Scenario 9: Bodywear set returned with biohazard contamination (PERMITIR refund, BW-004 biohazard isolation)
 *  10. Scenario 10: Online late exchange with PayPal during portal outage (REVER / Senior Review & App Flow)
 */

:- use_module(library(plunit)).
:- use_module('../src/core/retail_engine/engine').

assert_scenario_facts(FactsList) :-
    retail_engine:load_knowledge_base(retail_rules),
    assert_facts_recursive(FactsList, 1).

assert_facts_recursive([], N) :-
    FinalCount is N - 1,
    retractall(retail_engine:ultimo_facto(_)),
    asserta(retail_engine:ultimo_facto(FinalCount)).
assert_facts_recursive([H|T], N) :-
    assertz(retail_engine:facto(N, H)),
    N1 is N + 1,
    assert_facts_recursive(T, N1).

has_fact(Fact) :-
    retail_engine:facto(_, Fact).

:- begin_tests(retail_expert_scenarios_suite).

% ------------------------------------------------------------------------------
% Scenario 1: As etiquetas soltas, troca ao 29.º dia
% ------------------------------------------------------------------------------
test(scenario_01_tags_detached_exchange) :-
    assert_scenario_facts([
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(mainline), tipo_loja(mainline),
        sku_reconhecido(true), marca(levis), categoria_produto(vestuario),
        estado_produto(nao_usado_etiquetas_soltas),
        comprovativo(recibo_digital), dias_desde_compra(29),
        tipo_pedido(troca), troca_apenas_tamanho(true),
        meio_pagamento(credito),
        artigo_entre_canais(true), no_sortido(true),
        stylist_venda_original('S-21'), transacao_concluida(true), recibo_entregue(false)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),
    assertion(has_fact(decisao(rever))),
    assertion(has_fact(regra_disparada('PC-002'))),
    assertion(has_fact(regra_disparada('CH-001'))),
    assertion(has_fact(regra_disparada('PT-001'))),
    assertion(has_fact(regra_disparada('EX-001'))).

% ------------------------------------------------------------------------------
% Scenario 2: O cliente irritado com Afterpay
% ------------------------------------------------------------------------------
test(scenario_02_afterpay_dispute_routing) :-
    assert_scenario_facts([
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(levi_com), encomenda_encontrada(true), portal_online_disponivel(true),
        sku_reconhecido(true), marca(levis), categoria_produto(vestuario),
        estado_produto(nao_usado_com_etiquetas),
        meio_pagamento(afterpay), afterpay_pede_excecao(true), tentativa_excecao(true),
        tipo_pedido(troca), cliente_contesta(true), cliente_agitado(true),
        artigo_entre_canais(true), no_sortido(false),
        transacao_concluida(true)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),
    assertion(has_fact(regra_disparada('CH-002'))),
    assertion(has_fact(regra_disparada('TN-010'))),
    assertion(has_fact(regra_disparada('HS-005'))),
    assertion(has_fact(regra_disparada('EX-003'))),
    assertion(has_fact(regra_disparada('EX-006'))),
    assertion(has_fact(processo_obrigatorio(backpocket))).

% ------------------------------------------------------------------------------
% Scenario 3: A devolução de oferta na Outlet sem recibo
% ------------------------------------------------------------------------------
test(scenario_03_outlet_gift_blind_return) :-
    assert_scenario_facts([
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(outlet), tipo_loja(outlet),
        sku_reconhecido(true), marca(levis), categoria_produto(vestuario),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(nenhum), tipo_pedido(devolucao_oferta), cliente_fornece_dados(true),
        transacao_concluida(true), destino_produto(area_vendas)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),
    assertion(has_fact(decisao(permitir))),
    assertion(has_fact(tipo_verificacao(as_cegas))),
    assertion(has_fact(meio_reembolso(credito_loja))),
    assertion(has_fact(regra_disparada('PT-002'))),
    assertion(has_fact(regra_disparada('PT-005'))),
    assertion(has_fact(regra_disparada('CH-009'))).

% ------------------------------------------------------------------------------
% Scenario 4: As calças com bainha e defeito
% ------------------------------------------------------------------------------
test(scenario_04_altered_hemmed_with_defect_rejected) :-
    assert_scenario_facts([
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(mainline), tipo_loja(mainline),
        sku_reconhecido(true), marca(levis), categoria_produto(vestuario),
        personalizado_ou_alterado(true), defeito_fabrico(true),
        comprovativo(recibo_impresso), dias_desde_compra(10),
        tipo_pedido(devolucao)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),
    assertion(has_fact(decisao(recusar))),
    assertion(has_fact(destino_produto(devolver_cliente))),
    assertion(has_fact(regra_disparada('HS-003'))).

% ------------------------------------------------------------------------------
% Scenario 5: A disputa sobre produto grossista
% ------------------------------------------------------------------------------
test(scenario_05_wholesale_dispute_rejected) :-
    assert_scenario_facts([
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(grossista),
        sku_reconhecido(true), marca(signature), categoria_produto(vestuario),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(recibo_impresso), cliente_contesta(true),
        tipo_pedido(devolucao)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),
    assertion(has_fact(decisao(recusar))),
    assertion(has_fact(regra_disparada('CH-008'))),
    assertion(has_fact(regra_disparada('EX-002'))).

% ------------------------------------------------------------------------------
% Scenario 6: A devolução sem recibo de artigos em estados diferentes
% ------------------------------------------------------------------------------
test(scenario_06_blind_multi_item_biohazard_escalation) :-
    assert_scenario_facts([
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(mainline), tipo_loja(mainline),
        comprovativo(nenhum),
        estado_produto(sujo_contaminado_inseguro),
        risco_fraude(alto), cliente_fornece_dados(false),
        tipo_pedido(devolucao)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),
    assertion(has_fact(decisao(rever))),
    assertion(has_fact(aprovacao(escalamento_distrital))),
    assertion(\+ has_fact(decisao(recusar))),
    assertion(has_fact(regra_disparada('EX-008'))),
    assertion(has_fact(regra_disparada('PC-008'))),
    assertion(has_fact(destino_produto(isolamento_risco_biologico))).

% ------------------------------------------------------------------------------
% Scenario 7: A substituição do cartão Interac no Canadá
% ------------------------------------------------------------------------------
test(scenario_07_canada_interac_card_mismatch) :-
    assert_scenario_facts([
        colaborador_autorizado(true), sessao_pos_propria(true),
        mercado(canada), canal_compra(mainline), tipo_loja(mainline),
        sku_reconhecido(true), marca(levis), categoria_produto(vestuario),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(recibo_impresso), dias_desde_compra(18),
        meio_pagamento(interac), cartao_interac_presente(false),
        cliente_contesta(true),
        stylist_venda_original('S-77'), transacao_concluida(true), recibo_entregue(true),
        destino_produto(area_vendas)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),
    assertion(has_fact(decisao(rever))),
    assertion(has_fact(aprovacao(responsavel_senior))),
    assertion(has_fact(meio_reembolso(sem_meio_definido))),
    assertion(\+ has_fact(decisao(permitir))),
    assertion(has_fact(regra_disparada('TN-011'))),
    assertion(has_fact(regra_disparada('PT-001'))),
    assertion(has_fact(regra_disparada('EX-002'))),
    assertion(has_fact(regra_disparada('CH-001'))).

% ------------------------------------------------------------------------------
% Scenario 8: O ajuste de preço após alteração de promoção
% ------------------------------------------------------------------------------
test(scenario_08_price_adjustment_photo_receipt_rejected) :-
    assert_scenario_facts([
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(mainline), tipo_loja(mainline),
        sku_reconhecido(true), marca(levis), categoria_produto(vestuario),
        estado_produto(nao_usado_com_etiquetas),
        tipo_pedido(ajuste_preco), comprovativo(foto_recibo), dias_desde_compra(13),
        cliente_contesta(true)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),
    assertion(has_fact(regra_disparada('PT-001'))),
    assertion(has_fact(regra_disparada('EX-002'))),
    assertion(\+ has_fact(regra_disparada('PT-007'))).

% ------------------------------------------------------------------------------
% Scenario 9: O conjunto de bodywear devolvido com um risco de segurança
% ------------------------------------------------------------------------------
test(scenario_09_bodywear_soiled_satisfaction_biohazard) :-
    assert_scenario_facts([
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(outlet), tipo_loja(outlet),
        sku_reconhecido(true), marca(levis),
        categoria_produto(bodywear), estado_produto(sujo_contaminado_inseguro),
        comprovativo(recibo_impresso), dias_desde_compra(21),
        meio_pagamento(credito),
        stylist_venda_original('S-99'), transacao_concluida(true), recibo_entregue(true)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),
    assertion(has_fact(decisao(permitir))),
    assertion(has_fact(destino_produto(isolamento_risco_biologico))),
    assertion(\+ has_fact(decisao(recusar))),
    assertion(has_fact(regra_disparada('PC-008'))),
    assertion(has_fact(regra_disparada('BW-004'))).

% ------------------------------------------------------------------------------
% Scenario 10: A troca online tardia com PayPal durante uma falha do portal
% ------------------------------------------------------------------------------
test(scenario_10_online_late_exchange_portal_down_paypal) :-
    assert_scenario_facts([
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(levi_com), encomenda_encontrada(true), portal_online_disponivel(false),
        sku_reconhecido(true), marca(levis), categoria_produto(vestuario),
        estado_produto(nao_usado_com_etiquetas),
        meio_pagamento(paypal), dias_desde_envio(37),
        tipo_pedido(troca), artigo_entre_canais(true), no_sortido(false),
        tentativa_excecao(true), cliente_contesta(true),
        destino_produto(area_vendas)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),
    assertion(has_fact(decisao(rever))),
    assertion(has_fact(aprovacao(responsavel_senior))),
    assertion(has_fact(processo_obrigatorio(fluxo_app))),
    assertion(\+ has_fact(meio_reembolso(cartao_oferta))),
    assertion(has_fact(regra_disparada('CH-004'))),
    assertion(has_fact(regra_disparada('TN-008'))),
    assertion(has_fact(regra_disparada('EX-001'))),
    assertion(has_fact(regra_disparada('EP-006'))).

:- end_tests(retail_expert_scenarios_suite).

run_expert_scenarios_tests :-
    run_tests([retail_expert_scenarios_suite]).
