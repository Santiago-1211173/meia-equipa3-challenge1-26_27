:- encoding(utf8).
:- module(test_retail_rules, [
    run_retail_rules_tests/0
]).

/** <module> PLUnit Tests for Phase 2: Retail Rules Knowledge Base (71 Rules, 9 Families)
 *
 * Validates:
 * 1. Completeness of all 71 rules across the 9 families.
 * 2. Proper declaration of askable attributes (perguntavel/1) and exclusion of diagnostic conclusions.
 * 3. Strict precedence hierarchy (Precedences 1 to 7 from RPAC Section 4.6):
 *    - Precedence 1: HS-006 (unauthorized operator)
 *    - Precedence 2: Mandatory routing (CH-002, CH-007, CH-008)
 *    - Precedence 3: Hard Stops (HS-001, HS-002, HS-003, HS-004)
 *    - Precedence 4: Biohazard/Safety (PC-008, BW-004)
 *    - Precedence 5: Category specific (PC-007) before general condition (PC-001 to PC-005)
 *    - Precedence 6: Proof and timeframe (PT-001 to PT-008, CH-003, CH-005)
 *    - Precedence 7: Manager review and escalation (EX-001 to EX-008)
 * 4. Tender, exchange, controls, and bodywear disposition families (TN, EP, CT, BW).
 */

:- use_module(library(plunit)).
:- use_module('../src/core/retail_engine/engine').

% ==============================================================================
% Scenario Setup Helpers
% ==============================================================================

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

% ==============================================================================
% Test Suite
% ==============================================================================

:- begin_tests(retail_rules_suite).

% ------------------------------------------------------------------------------
% 1. Metaknowledge & Rule Counts
% ------------------------------------------------------------------------------

test(all_71_rules_loaded) :-
    retail_engine:load_knowledge_base(retail_rules),
    aggregate_all(count, retail_engine:regra(_), Count),
    % 74 + 15 variantes (PC-002, PC-003: revendível / não revendível; PC-004: aprovado / recusado;
    % PT-004: não revendível; PT-007: ajuste anterior / fora da loja; CH-002: em revisão;
    % CH-003: não permitida; CH-004: às cegas; TN-008: sem app; EX-006: Afterpay; BW-003: usado;
    % PT-006: barreira linguística)
    assertion(Count == 90).

test(nine_families_exact_counts) :-
    retail_engine:load_knowledge_base(retail_rules),
    aggregate_all(count, retail_engine:regra_info(_, hs, _), HsCount),
    aggregate_all(count, retail_engine:regra_info(_, pc, _), PcCount),
    aggregate_all(count, retail_engine:regra_info(_, pt, _), PtCount),
    aggregate_all(count, retail_engine:regra_info(_, ch, _), ChCount),
    aggregate_all(count, retail_engine:regra_info(_, tn, _), TnCount),
    aggregate_all(count, retail_engine:regra_info(_, ep, _), EpCount),
    aggregate_all(count, retail_engine:regra_info(_, ex, _), ExCount),
    aggregate_all(count, retail_engine:regra_info(_, ct, _), CtCount),
    aggregate_all(count, retail_engine:regra_info(_, bw, _), BwCount),
    assertion(HsCount == 6),
    assertion(PcCount == 8),
    assertion(PtCount == 10),
    assertion(ChCount == 10),
    assertion(TnCount == 13),
    assertion(EpCount == 7),
    assertion(ExCount == 8),
    assertion(CtCount == 8),
    assertion(BwCount == 4).

test(askable_observable_attributes_and_exclusions) :-
    retail_engine:load_knowledge_base(retail_rules),
    % Observables must be askable
    assertion(retail_engine:perguntavel(colaborador_autorizado(_))),
    assertion(retail_engine:perguntavel(sku_reconhecido(_))),
    assertion(retail_engine:perguntavel(estado_produto(_))),
    assertion(retail_engine:perguntavel(comprovativo(_))),
    assertion(retail_engine:perguntavel(dias_desde_compra(_))),
    assertion(retail_engine:perguntavel(meio_pagamento(_))),
    % Diagnostic conclusions must NEVER be askable
    assertion(\+ retail_engine:perguntavel(decisao(_))),
    assertion(\+ retail_engine:perguntavel(elegibilidade_produto(_))),
    assertion(\+ retail_engine:perguntavel(tipo_verificacao(_))),
    assertion(\+ retail_engine:perguntavel(valor_devolucao(_))),
    assertion(\+ retail_engine:perguntavel(meio_reembolso(_))),
    assertion(\+ retail_engine:perguntavel(processo_obrigatorio(_))),
    assertion(\+ retail_engine:perguntavel(destino_produto(_))),
    assertion(\+ retail_engine:perguntavel(aprovacao(_))).

% ------------------------------------------------------------------------------
% 2. Precedence 1: HS-006 (Operator Authorization)
% ------------------------------------------------------------------------------

test(hs_006_unauthorized_operator_routes_immediately) :-
    assert_scenario_facts([
        colaborador_autorizado(false),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),
    assertion(has_fact(decisao(encaminhar))),
    assertion(has_fact(aprovacao(responsavel_senior))),
    assertion(has_fact(regra_disparada('HS-006'))).

% ------------------------------------------------------------------------------
% 3. Precedence 2: Mandatory Channel Routing (CH-008, CH-007, CH-002)
% ------------------------------------------------------------------------------

test(ch_008_wholesale_purchase_rejected) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(grossista),
        sku_reconhecido(true)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(recusar))),
    assertion(has_fact(processo_obrigatorio(processo_grossista))),
    assertion(has_fact(regra_disparada('CH-008'))).

test(ch_007_canadian_franchise_routed) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(franquia_canada),
        sku_reconhecido(true)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(encaminhar))),
    assertion(has_fact(processo_obrigatorio(franquia_canada))),
    assertion(has_fact(regra_disparada('CH-007'))).

test(ch_002_online_order_found_routed_to_backpocket) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(levi_com),
        encomenda_encontrada(true),
        portal_online_disponivel(true),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(encaminhar))),
    assertion(has_fact(processo_obrigatorio(backpocket))),
    assertion(has_fact(regra_disparada('CH-002'))).

% ------------------------------------------------------------------------------
% 4. Precedence 3: Hard Stop Rules (HS-001, HS-002, HS-003, HS-004, HS-005)
% ------------------------------------------------------------------------------

test(hs_001_unrecognized_pos_sku_rejected) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(mainline),
        sku_reconhecido(false)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(recusar))),
    assertion(has_fact(tipo_transacao(nenhuma))),
    assertion(has_fact(regra_disparada('HS-001'))).

test(hs_002_excluded_brands_rejected) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(mainline),
        sku_reconhecido(true),
        marca(dockers)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(recusar))),
    assertion(has_fact(regra_disparada('HS-002'))).

test(hs_003_customized_altered_item_rejected) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(mainline),
        sku_reconhecido(true),
        personalizado_ou_alterado(true),
        defeito_fabrico(true) % Defect cannot override HS-003
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(recusar))),
    assertion(has_fact(destino_produto(devolver_cliente))),
    assertion(has_fact(regra_disparada('HS-003'))).

test(hs_004_generic_sku_canadian_franchise_routed) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(franquia_canada),
        sku_reconhecido(false)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(encaminhar))),
    assertion(has_fact(processo_obrigatorio(franquia_canada))),
    assertion(has_fact(regra_disparada('HS-004'))).

test(hs_005_afterpay_exception_prohibited) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(levi_com),
        meio_pagamento(afterpay),
        afterpay_pede_excecao(true)
    ]),
    retail_engine:run_engine(_),
    % Recusa a exceção ao meio, não a devolução (reembolso pela Afterpay)
    assertion(has_fact(excecao_recusada(true))),
    assertion(\+ has_fact(decisao(recusar))),
    assertion(has_fact(processo_obrigatorio(afterpay_app))),
    assertion(has_fact(regra_disparada('HS-005'))).

% ------------------------------------------------------------------------------
% 5. Precedence 4: Biohazard / Safety (PC-008, BW-004)
% ------------------------------------------------------------------------------

test(pc_008_biohazard_isolation_without_refusal) :-
    % PC-008 isola a peça; não recusa — a elegibilidade fica com o estado de uso
    assert_scenario_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        categoria_produto(vestuario),
        estado_produto(sujo_contaminado_inseguro)
    ]),
    retail_engine:run_engine(_),
    assertion(\+ has_fact(decisao(recusar))),
    assertion(has_fact(destino_produto(isolamento_risco_biologico))),
    assertion(has_fact(regra_disparada('PC-008'))).

test(pc_008_soiled_worn_item_follows_pc_004) :-
    verified_return_facts(claramente_usado, [estado_produto(sujo_contaminado_inseguro)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(_),
    assertion(has_fact(destino_produto(isolamento_risco_biologico))),
    assertion(has_fact(decisao(rever))),
    assertion(has_fact(regra_disparada('PC-004'))),
    assertion(\+ has_fact(decisao(recusar))).

% ------------------------------------------------------------------------------
% 6. Precedence 5: Category Specific (PC-007 Bodywear) vs General (PC-001..PC-005)
% ------------------------------------------------------------------------------

test(pc_007_bodywear_allowed_in_worn_state) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        categoria_produto(bodywear),
        estado_produto(claramente_usado),
        comprovativo(recibo_impresso),
        dias_desde_compra(15)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(elegibilidade_produto(aprovada))),
    assertion(has_fact(regra_disparada('PC-007'))),
    assertion(\+ has_fact(regra_disparada('PC-004'))).

test(pc_006_manufacturing_defect_with_damage_out) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        personalizado_ou_alterado(false),
        defeito_fabrico(true),
        comprovativo(recibo_impresso),
        dias_desde_compra(20)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(elegibilidade_produto(aprovada))),
    assertion(has_fact(destino_produto(baixa_dano))),
    assertion(has_fact(processo_obrigatorio(baixa_dano))),
    assertion(has_fact(regra_disparada('PC-006'))).

test(pc_005_washed_product_rejected) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        defeito_fabrico(false),
        estado_produto(lavado)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(recusar))),
    assertion(has_fact(destino_produto(devolver_cliente))),
    assertion(has_fact(regra_disparada('PC-005'))).

test(pc_002_pc_003_unworn_tags_review) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(nao_usado_etiquetas_soltas)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(rever))),
    assertion(has_fact(aprovacao(gestor_xstore))),
    assertion(has_fact(regra_disparada('PC-002'))).

test(pc_004_worn_item_exact_item_swap_only) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        defeito_fabrico(false),
        estado_produto(claramente_usado)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(rever))),
    assertion(has_fact(tipo_transacao(troca_mesmo_artigo))),
    assertion(has_fact(regra_disparada('PC-004'))).

% PC-002 / PC-003 com a resposta sobre a revenda (IN-010) e PC-004 com a decisão da gestão:
% resposta positiva → produto elegível (o comprovativo e o prazo decidem); negativa → recusar.
verified_return_facts(Estado, Extra, Facts) :-
    append([
        colaborador_autorizado(true), canal_compra(mainline), sku_reconhecido(true),
        categoria_produto(vestuario), estado_produto(Estado), defeito_fabrico(false),
        comprovativo(recibo_impresso), dias_desde_compra(10), tipo_pedido(devolucao)
    ], Extra, Facts).

test(pc_002_resellable_item_is_approved) :-
    verified_return_facts(nao_usado_etiquetas_soltas, [revendivel(true)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == permitir),
    assertion(has_fact(elegibilidade_produto(aprovada))),
    assertion(has_fact(regra_disparada('PC-002'))),
    assertion(\+ has_fact(decisao(rever))),
    assertion(\+ has_fact(regra_disparada('EX-001'))).

test(pc_002_not_resellable_item_is_refused) :-
    verified_return_facts(nao_usado_etiquetas_soltas, [revendivel(false)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == recusar),
    assertion(has_fact(tipo_transacao(nenhuma))),
    assertion(has_fact(regra_disparada('PC-002'))),
    assertion(\+ has_fact(elegibilidade_produto(aprovada))).

test(pc_003_resellable_item_is_approved) :-
    verified_return_facts(nao_usado_sem_etiquetas, [revendivel(true)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == permitir),
    assertion(has_fact(regra_disparada('PC-003'))),
    assertion(\+ has_fact(decisao(rever))).

test(pc_003_not_resellable_item_is_refused) :-
    verified_return_facts(nao_usado_sem_etiquetas, [revendivel(false)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == recusar),
    assertion(has_fact(regra_disparada('PC-003'))).

% Defeito de fabrico confirmado: PC-006 prevalece sobre PC-002 / PC-003, mesmo sem revenda possível
defective_return_facts(Estado, Facts) :-
    Facts = [
        colaborador_autorizado(true), canal_compra(mainline), sku_reconhecido(true),
        categoria_produto(vestuario), estado_produto(Estado), defeito_fabrico(true), revendivel(false),
        comprovativo(recibo_impresso), dias_desde_compra(10), tipo_pedido(devolucao)
    ].

test(pc_006_defect_prevails_over_pc_002_loose_tags) :-
    defective_return_facts(nao_usado_etiquetas_soltas, Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == permitir),
    assertion(has_fact(regra_disparada('PC-006'))),
    assertion(\+ has_fact(regra_disparada('PC-002'))),
    assertion(\+ has_fact(decisao(recusar))).

test(pc_006_defect_prevails_over_pc_003_no_tags) :-
    defective_return_facts(nao_usado_sem_etiquetas, Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == permitir),
    assertion(has_fact(regra_disparada('PC-006'))),
    assertion(\+ has_fact(regra_disparada('PC-003'))).

test(pc_004_management_approved_exact_item_exchange) :-
    verified_return_facts(claramente_usado, [excecao_aprovada(true)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(_),
    assertion(has_fact(elegibilidade_produto(aprovada))),
    assertion(has_fact(tipo_transacao(troca_mesmo_artigo))),
    assertion(has_fact(regra_disparada('PC-004'))),
    assertion(\+ has_fact(decisao(rever))).

test(pc_004_management_refused) :-
    verified_return_facts(claramente_usado, [excecao_aprovada(false)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == recusar),
    assertion(has_fact(tipo_transacao(nenhuma))),
    assertion(has_fact(regra_disparada('PC-004'))).

% ------------------------------------------------------------------------------
% 7. Precedence 6: Proof & Timeframe (PT-001 to PT-008)
% ------------------------------------------------------------------------------

test(pt_003_verified_return_within_30_days_full_refund) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(mainline),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(recibo_impresso),
        dias_desde_compra(14),
        meio_pagamento(credito)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(tipo_verificacao(verificada))),
    assertion(has_fact(decisao(permitir))),
    assertion(has_fact(tipo_transacao(reembolso_ou_troca))),
    assertion(has_fact(valor_devolucao(valor_pago))),
    assertion(has_fact(meio_reembolso(meio_original))),
    assertion(has_fact(regra_disparada('PT-003'))),
    assertion(has_fact(regra_disparada('TN-001'))).

test(pt_004_verified_return_over_30_days_store_credit_review) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(mainline),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(recibo_impresso),
        dias_desde_compra(45)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(tipo_verificacao(verificada))),
    assertion(has_fact(decisao(rever))),
    assertion(has_fact(aprovacao(gestor_xstore))),
    assertion(has_fact(meio_reembolso(credito_loja))),
    assertion(has_fact(regra_disparada('PT-004'))).

test(pt_005_blind_return_exchange_or_store_credit) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(mainline),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(nenhum)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(tipo_verificacao(as_cegas))),
    assertion(has_fact(decisao(permitir))),
    assertion(has_fact(tipo_transacao(troca_ou_credito))),
    assertion(has_fact(valor_devolucao(preco_atual))),
    assertion(has_fact(meio_reembolso(credito_loja))),
    assertion(has_fact(regra_disparada('PT-005'))).

test(pt_006_language_barrier_selects_skip_like_drools) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(mainline),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(nenhum),
        cliente_fornece_dados(true),
        barreira_linguistica(true)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(processo_acao(selecionar_saltar))),
    assertion(has_fact(regra_disparada('PT-006'))),
    assertion(has_fact(decisao(permitir))).

test(pt_006_refused_data_and_language_barrier_fire_once) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(mainline),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(nenhum),
        cliente_fornece_dados(false),
        barreira_linguistica(true)
    ]),
    retail_engine:run_engine(_),
    aggregate_all(count, (has_fact(motivo(M)), sub_string(M, 0, _, _, "[PT-006]")), Motivos),
    assertion(Motivos == 1).

test(pt_007_pt_008_price_adjustment_scenarios) :-
    % PT-007: Allowed up to 14 days
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(mainline),
        tipo_pedido(ajuste_preco),
        comprovativo(recibo_impresso),
        recibo_original(true),
        dias_desde_compra(10)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(permitir))),
    assertion(has_fact(tipo_transacao(ajuste_preco))),
    assertion(has_fact(valor_devolucao(diferenca_pos))),
    assertion(has_fact(regra_disparada('PT-007'))),

    % PT-008: Rejected after 14 days
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(mainline),
        tipo_pedido(ajuste_preco),
        comprovativo(recibo_impresso),
        dias_desde_compra(20)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(recusar))),
    assertion(has_fact(regra_disparada('PT-008'))).

test(pt_004_after_30_days_resellable_goes_to_review) :-
    verified_return_facts(nao_usado_com_etiquetas, [revendivel(true)], Facts0),
    once(select(dias_desde_compra(10), Facts0, dias_desde_compra(45), Facts)),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == rever),
    assertion(has_fact(regra_disparada('PT-004'))).

test(pt_004_after_30_days_not_resellable_is_refused) :-
    % "Otherwise DENY", also for an item still under review by another rule (defect, PC-006)
    defective_return_facts(nao_usado_etiquetas_soltas, Facts0),
    once(select(dias_desde_compra(10), Facts0, dias_desde_compra(45), Facts)),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == recusar),
    assertion(has_fact(regra_disparada('PT-004'))),
    assertion(has_fact(tipo_transacao(nenhuma))).

price_adjustment_facts(Extra, Facts) :-
    append([colaborador_autorizado(true), tipo_pedido(ajuste_preco), dias_desde_compra(10)], Extra, Facts).

test(pt_007_digital_original_receipt_allows_adjustment) :-
    % IN-004: o recibo original pode ser impresso ou digital
    price_adjustment_facts([canal_compra(mainline), comprovativo(confirmacao_encomenda), recibo_original(true)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == permitir),
    assertion(has_fact(regra_disparada('PT-007'))).

test(pt_007_adjustment_already_applied_is_refused) :-
    price_adjustment_facts([canal_compra(mainline), comprovativo(recibo_impresso), recibo_original(true),
                            ajuste_preco_anterior(true)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == recusar),
    assertion(has_fact(regra_disparada('PT-007'))),
    assertion(\+ has_fact(decisao(permitir))).

test(pt_007_online_purchase_adjustment_goes_to_review) :-
    price_adjustment_facts([canal_compra(levi_com), comprovativo(confirmacao_encomenda), recibo_original(true)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == rever),
    assertion(has_fact(aprovacao(responsavel_senior))),
    assertion(has_fact(regra_disparada('PT-007'))).

% ------------------------------------------------------------------------------
% 8. Channel & Tender Rules (CH, TN)
% ------------------------------------------------------------------------------

online_not_found_facts(Extra, Facts) :-
    append([
        colaborador_autorizado(true), canal_compra(levi_com), encomenda_encontrada(false),
        sku_reconhecido(true), categoria_produto(vestuario), estado_produto(nao_usado_com_etiquetas),
        comprovativo(nenhum), tipo_pedido(devolucao)
    ], Extra, Facts).

test(ch_002_online_item_under_review_is_routed_to_backpocket) :-
    assert_scenario_facts([
        colaborador_autorizado(true), canal_compra(levi_com), encomenda_encontrada(true),
        portal_online_disponivel(true), sku_reconhecido(true), categoria_produto(vestuario),
        estado_produto(claramente_usado), comprovativo(confirmacao_encomenda), tipo_pedido(devolucao)
    ]),
    retail_engine:run_engine(R),
    assertion(R.decision == encaminhar),
    assertion(has_fact(regra_disparada('PC-004'))),
    assertion(has_fact(regra_disparada('CH-002'))),
    assertion(has_fact(processo_obrigatorio(backpocket))).

test(ch_003_blind_online_return_refused_when_policy_forbids) :-
    online_not_found_facts([politica_permite_as_cegas_online(false), portal_online_disponivel(true)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == recusar),
    assertion(has_fact(regra_disparada('CH-003'))),
    assertion(\+ has_fact(meio_reembolso(cartao_oferta))).

test(ch_003_blind_online_return_with_gift_card_when_policy_permits) :-
    online_not_found_facts([politica_permite_as_cegas_online(true), portal_online_disponivel(true)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == permitir),
    assertion(has_fact(tipo_verificacao(as_cegas))),
    assertion(has_fact(meio_reembolso(cartao_oferta))),
    assertion(has_fact(regra_disparada('CH-003'))),
    assertion(\+ has_fact(regra_disparada('CH-004'))).

test(ch_004_portal_outage_blind_return_to_original_tender) :-
    online_not_found_facts([politica_permite_as_cegas_online(true), portal_online_disponivel(false)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == permitir),
    assertion(has_fact(meio_reembolso(meio_original))),
    assertion(has_fact(regra_disparada('CH-004'))).

test(ch_009_outlet_blind_return_promotional_pricing) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        tipo_loja(outlet),
        canal_compra(outlet),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(nenhum)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(valor_devolucao(preco_atual_outlet))),
    assertion(has_fact(regra_disparada('CH-009'))).

test(tn_008_paypal_venmo_requires_app_flow) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        meio_pagamento(paypal)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(processo_obrigatorio(fluxo_app))),
    assertion(has_fact(meio_reembolso(fluxo_app))),
    assertion(has_fact(regra_disparada('TN-008'))).

test(tn_008_paypal_without_app_access_goes_to_review) :-
    verified_return_facts(nao_usado_com_etiquetas, [meio_pagamento(paypal), acesso_aplicacao_pagamento(false)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(rever))),
    assertion(has_fact(aprovacao(responsavel_senior))),
    assertion(has_fact(meio_reembolso(fluxo_app))),
    assertion(has_fact(regra_disparada('TN-008'))).

test(tn_011_interac_without_card_goes_to_review) :-
    verified_return_facts(nao_usado_com_etiquetas,
                          [mercado(canada), meio_pagamento(interac), cartao_interac_presente(false)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(rever))),
    assertion(has_fact(meio_reembolso(sem_meio_definido))),
    assertion(has_fact(regra_disparada('TN-011'))).

test(tn_011_missing_card_irrelevant_for_store_credit) :-
    % Mais de 30 dias: o reembolso não vai para o Interac (PT-004, crédito de loja)
    assert_scenario_facts([
        colaborador_autorizado(true), canal_compra(mainline), sku_reconhecido(true),
        categoria_produto(vestuario), estado_produto(nao_usado_com_etiquetas), defeito_fabrico(false),
        comprovativo(recibo_impresso), dias_desde_compra(45), tipo_pedido(devolucao),
        mercado(canada), meio_pagamento(interac), cartao_interac_presente(false)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(regra_disparada('PT-004'))),
    assertion(\+ has_fact(regra_disparada('TN-011'))),
    assertion(\+ has_fact(meio_reembolso(sem_meio_definido))).

test(tn_011_interac_canada_in_store_physical_card) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        mercado(canada),
        meio_pagamento(interac),
        cartao_interac_presente(true)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(meio_reembolso(meio_original))),
    assertion(has_fact(processo_obrigatorio(pos))),
    assertion(has_fact(regra_disparada('TN-011'))).

% ------------------------------------------------------------------------------
% 9. Exchanges & Promotions (EP)
% ------------------------------------------------------------------------------

test(ep_001_exchange_size_only_honors_original_promo) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(recibo_impresso),
        tipo_pedido(troca),
        troca_apenas_tamanho(true)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(preservar_preco_promocional(true))),
    assertion(has_fact(regra_disparada('EP-001'))).

% ------------------------------------------------------------------------------
% 10. Bodywear Disposition (BW-001, BW-002, BW-003, BW-004)
% ------------------------------------------------------------------------------

test(bw_001_bodywear_intact_packaging_to_sales_floor) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        categoria_produto(bodywear),
        embalagem_intacta(true),
        estado_produto(nao_usado_com_etiquetas)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(destino_produto(area_vendas))),
    assertion(has_fact(regra_disparada('BW-001'))).

test(bw_002_bodywear_missing_packaging_clearance_50) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        categoria_produto(bodywear),
        embalagem_intacta(false),
        pecas_em_falta(false),
        estado_produto(nao_usado_com_etiquetas)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(destino_produto(saldos))),
    assertion(has_fact(desconto_saldos(50))),
    assertion(has_fact(riscar_codigo_barras_vermelho(true))),
    assertion(has_fact(regra_disparada('BW-002'))).

test(bw_003_bodywear_missing_units_damage_out) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        categoria_produto(bodywear),
        pecas_em_falta(true)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(destino_produto(baixa_dano))),
    assertion(has_fact(processo_obrigatorio(baixa_dano))),
    assertion(has_fact(regra_disparada('BW-003'))).

test(bw_003_worn_bodywear_damage_out) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        categoria_produto(bodywear),
        estado_produto(claramente_usado)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(elegibilidade_produto(aprovada))),
    assertion(has_fact(destino_produto(baixa_dano))),
    assertion(has_fact(regra_disparada('BW-003'))).

% ------------------------------------------------------------------------------
% 11. Manager Exceptions & Hard Stop Integrity (EX-004, EX-006)
% ------------------------------------------------------------------------------

test(ex_006_manager_exception_cannot_override_afterpay) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        canal_compra(levi_com),
        tentativa_excecao(true),
        meio_pagamento(afterpay),
        afterpay_pede_excecao(true)
    ]),
    retail_engine:run_engine(_),
    % Recusa a exceção, não o pedido
    assertion(has_fact(excecao_recusada(true))),
    assertion(\+ has_fact(decisao(recusar))),
    assertion(has_fact(regra_disparada('EX-006'))).

test(ex_006_exception_bypassing_mandatory_control_is_refused) :-
    verified_return_facts(nao_usado_com_etiquetas, [tentativa_excecao(true), excecao_contorna_controlo(true)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(has_fact(excecao_recusada(true))),
    assertion(has_fact(regra_disparada('EX-006'))),
    assertion(R.decision == permitir).

test(ex_006_cancels_ex_004_and_ex_005) :-
    verified_return_facts(nao_usado_com_etiquetas,
                          [revendivel(true), cliente_agitado(true), risco_fraude(baixo), concluivel_no_sistema(true),
                           tentativa_excecao(true), excecao_contorna_controlo(true)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(_),
    assertion(has_fact(regra_disparada('EX-006'))),
    assertion(\+ has_fact(regra_disparada('EX-004'))),
    assertion(\+ has_fact(regra_disparada('EX-005'))).

% ------------------------------------------------------------------------------
% 12. Engine decision and rules to validate
% ------------------------------------------------------------------------------

test(final_decision_is_the_most_severe_not_the_first) :-
    % PERMITIR < REVER < ENCAMINHAR < RECUSAR, as in Drools (ADR 0004)
    assert_scenario_facts([decisao(permitir), decisao(recusar), decisao(rever)]),
    retail_engine:decisao_final(D1),
    assertion(D1 == recusar),
    assert_scenario_facts([decisao(permitir), decisao(rever)]),
    retail_engine:decisao_final(D2),
    assertion(D2 == rever),
    assert_scenario_facts([colaborador_autorizado(true)]),
    retail_engine:decisao_final(D3),
    assertion(D3 == nao_concluido).

test(rules_to_validate_are_reported_from_fired_rules) :-
    verified_return_facts(nao_usado_com_etiquetas, [], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    % PT-003 is marked [a validar: A-22]; PC-001 is not
    assertion(memberchk('PT-003', R.regras_a_validar)),
    assertion(\+ memberchk('PC-001', R.regras_a_validar)).

test(rules_to_validate_use_the_visible_code_of_variants) :-
    verified_return_facts(nao_usado_etiquetas_soltas, [revendivel(true)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(memberchk('PC-002', R.regras_a_validar)),
    assertion(\+ memberchk('PC-002-REVENDIVEL', R.regras_a_validar)).

test(ex_006_in_store_afterpay_with_manager_exception_not_refused) :-
    % Compra em loja com Afterpay e exceção da gerência: nada a contornar
    verified_return_facts(nao_usado_com_etiquetas,
                          [meio_pagamento(afterpay), tentativa_excecao(true), excecao_aprovada(true)], Facts),
    assert_scenario_facts(Facts),
    retail_engine:run_engine(R),
    assertion(R.decision == permitir),
    assertion(\+ has_fact(regra_disparada('EX-006'))),
    assertion(\+ has_fact(excecao_recusada(true))).

test(ct_001_ct_003_session_and_audit_controls) :-
    assert_scenario_facts([
        colaborador_autorizado(true),
        sessao_pos_propria(true),
        comprovativo(recibo_impresso)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(credenciais_validadas(true))),
    assertion(has_fact(controlo_sessao_conforme(true))),
    assertion(has_fact(documentacao(assinaturas))),
    assertion(has_fact(regra_disparada('CT-001'))),
    assertion(has_fact(regra_disparada('CT-003'))).

:- end_tests(retail_rules_suite).

run_retail_rules_tests :-
    run_tests([retail_rules_suite]).
