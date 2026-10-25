:- encoding(utf8).
:- module(test_retail_interactive, [
    run_retail_interactive_tests/0
]).

/** <module> PLUnit Tests for Phase 3: Dialogic Engine Mechanics & Interactive Reasoning
 *
 * Validates:
 * 1. Dynamic premise acquisition (obtem_facto/2) when facts are missing.
 * 2. Proper causal attribution (justifica(N, utilizador, [])) and explanation (como/1, explain_how/2).
 * 3. Safe handling of "não sei" (nao_sei) without asserting logical falsehoods.
 * 4. Loop prevention: each attribute is queried at most once (ja_perguntado/1).
 * 5. Bidirectional "porquê?" (Why Ask) inquiry with active rule tracking (regra_ativa/2, regra_info/3).
 * 6. Exclusion of diagnostic conclusions from being asked.
 * 7. Numeric condition evaluation via asking (avalia/2).
 * 8. End-to-end interactive session execution (run_interactive/1 and run_interactive/2).
 * 9. Precedence 1 immediate stop on unauthorized operator via dialog.
 * 10. Memory reset cleans all dialogue states, ja_perguntado, and mock queues.
 */

:- use_module(library(plunit)).
:- use_module('../src/core/retail_engine/engine').
:- use_module('../src/core/retail_engine/interactive').

% Helper to check fact existence
has_fact(Fact) :-
    retail_engine:facto(_, Fact).

:- begin_tests(retail_interactive_suite).

% ------------------------------------------------------------------------------
% 1. Dynamic Premise Acquisition & User Attribution
% ------------------------------------------------------------------------------

test(missing_askable_fact_queried_and_attributed_to_user) :-
    retail_engine:load_knowledge_base(retail_rules),
    % Seed with authorized operator
    assertz(retail_engine:facto(1, colaborador_autorizado(true))),
    retractall(retail_engine:ultimo_facto(_)),
    asserta(retail_engine:ultimo_facto(1)),

    % CT-003 needs sessao_pos_propria(true)
    retail_interactive:set_mock_answers([
        sessao_pos_propria(_) - true
    ]),

    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),

    % Verify fact was asserted with 'utilizador' provenance
    retail_engine:facto(PosFactId, sessao_pos_propria(true)),
    assertion(integer(PosFactId)),
    assertion(retail_engine:justifica(PosFactId, utilizador, [])),

    % Verify explain_how identifies the user as origin
    retail_engine:explain_how(PosFactId, Explanations),
    assertion(once((member(Line, Explanations), sub_string(Line, _, _, _, "was provided by user")))).

% ------------------------------------------------------------------------------
% 2. Safe Handling of "Não Sei" (nao_sei)
% ------------------------------------------------------------------------------

test(nao_sei_does_not_assert_falsehood_and_fails_rule_gracefully) :-
    retail_engine:load_knowledge_base(retail_rules),
    assertz(retail_engine:facto(1, colaborador_autorizado(true))),
    retractall(retail_engine:ultimo_facto(_)),
    asserta(retail_engine:ultimo_facto(1)),

    % CT-003 needs sessao_pos_propria; operator responds nao_sei
    retail_interactive:set_mock_answers([
        sessao_pos_propria(_) - nao_sei
    ]),

    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),

    % Verify that NO sessao_pos_propria fact was asserted
    assertion(\+ retail_engine:facto(_, sessao_pos_propria(_))),

    % Verify ja_perguntado is recorded
    assertion(retail_engine:ja_perguntado(sessao_pos_propria(_))),

    % Rule CT-003 fails gracefully and did not trigger conclusion
    assertion(\+ has_fact(regra_disparada('CT-003'))).

% ------------------------------------------------------------------------------
% 3. Loop Prevention: Attribute Queried At Most Once
% ------------------------------------------------------------------------------

test(loop_prevention_single_query_per_attribute) :-
    retail_engine:load_knowledge_base(retail_rules),
    assertz(retail_engine:facto(1, colaborador_autorizado(true))),
    assertz(retail_engine:facto(2, tipo_verificacao(verificada))),
    retractall(retail_engine:ultimo_facto(_)),
    asserta(retail_engine:ultimo_facto(2)),

    % Both CT-001 and CT-003 test sessao_pos_propria(true)
    retail_interactive:set_mock_answers([
        sessao_pos_propria(_) - true,
        recibo_entregue(_) - true
    ]),

    retail_engine:run_engine(_),
    retail_interactive:get_dialogue_log(Log),

    % Count how many times sessao_pos_propria was asked
    findall(Q, member(asked(sessao_pos_propria(_), Q), Log), PosQuestions),
    length(PosQuestions, PosQuestionCount),
    assertion(PosQuestionCount == 1).

% ------------------------------------------------------------------------------
% 4. Bidirectional "Porquê?" (Why Ask) Inquiry
% ------------------------------------------------------------------------------

test(why_ask_explains_active_candidate_rule_and_business_rationale) :-
    retail_engine:load_knowledge_base(retail_rules),
    % Trigger PT-003 which checks dias_desde_compra
    assertz(retail_engine:facto(1, tipo_verificacao(verificada))),
    assertz(retail_engine:facto(2, elegibilidade_produto(aprovada))),
    retractall(retail_engine:ultimo_facto(_)),
    asserta(retail_engine:ultimo_facto(2)),

    % When asked about dias_desde_compra, operator asks "porquê?", then answers 14
    retail_interactive:set_mock_answers([
        dias_desde_compra(_) - [porquê, 14],
        meio_pagamento(_) - credito,
        sessao_pos_propria(_) - true,
        recibo_entregue(_) - true
    ]),

    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),

    % Verify dialogue log contains the why_asked event
    retail_interactive:get_dialogue_log(Log),
    once(member(why_asked(dias_desde_compra(_), ActiveRule, Objective, WhyText), Log)),
    assertion(ActiveRule == 'PT-003'),
    assertion(Objective == decisao(permitir)),
    % Explanation cites family or normative description
    assertion(sub_string(WhyText, _, _, _, "PT-003")),
    assertion(sub_string(WhyText, _, _, _, "Proof & Timeframe") ;
              sub_string(WhyText, _, _, _, "Comprovativo e Prazos")).

% ------------------------------------------------------------------------------
% 5. Exclusion of Diagnostic Conclusions
% ------------------------------------------------------------------------------

test(diagnostic_conclusions_are_never_askable) :-
    retail_engine:load_knowledge_base(retail_rules),
    assertion(\+ retail_engine:perguntavel(decisao(_))),
    assertion(\+ retail_engine:perguntavel(elegibilidade_produto(_))),
    assertion(\+ retail_engine:perguntavel(tipo_verificacao(_))),
    assertion(\+ retail_engine:perguntavel(meio_reembolso(_))),
    assertion(\+ retail_engine:perguntavel(processo_obrigatorio(_))),
    assertion(\+ retail_engine:perguntavel(destino_produto(_))),
    assertion(\+ retail_engine:perguntavel(aprovacao(_))).

% ------------------------------------------------------------------------------
% 6. Numeric Condition Evaluation via Asking (avalia/2)
% ------------------------------------------------------------------------------

test(numeric_condition_evaluation_within_and_beyond_30_days) :-
    % Subtest A: Within 30 days -> PT-003 (permitir)
    retail_engine:load_knowledge_base(retail_rules),
    assertz(retail_engine:facto(1, colaborador_autorizado(true))),
    assertz(retail_engine:facto(2, sku_reconhecido(true))),
    assertz(retail_engine:facto(3, estado_produto(nao_usado_com_etiquetas))),
    assertz(retail_engine:facto(4, comprovativo(recibo_impresso))),
    assertz(retail_engine:facto(5, meio_pagamento(credito))),
    retractall(retail_engine:ultimo_facto(_)),
    asserta(retail_engine:ultimo_facto(5)),

    retail_interactive:set_mock_answers([
        dias_desde_compra(_) - 14,
        sessao_pos_propria(_) - true,
        recibo_entregue(_) - true
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(permitir))),
    assertion(has_fact(regra_disparada('PT-003'))),

    % Subtest B: Beyond 30 days -> PT-004 (rever com gerência)
    retail_engine:load_knowledge_base(retail_rules),
    assertz(retail_engine:facto(1, colaborador_autorizado(true))),
    assertz(retail_engine:facto(2, sku_reconhecido(true))),
    assertz(retail_engine:facto(3, estado_produto(nao_usado_com_etiquetas))),
    assertz(retail_engine:facto(4, comprovativo(recibo_impresso))),
    assertz(retail_engine:facto(5, meio_pagamento(credito))),
    retractall(retail_engine:ultimo_facto(_)),
    asserta(retail_engine:ultimo_facto(5)),

    retail_interactive:set_mock_answers([
        dias_desde_compra(_) - 45,
        sessao_pos_propria(_) - true,
        recibo_entregue(_) - true
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(rever))),
    assertion(has_fact(regra_disparada('PT-004'))).

% ------------------------------------------------------------------------------
% 7. Negative Answer Routing (SKU Não Reconhecido -> HS-001)
% ------------------------------------------------------------------------------

test(negative_answer_routing_unrecognized_sku_hard_stop) :-
    retail_interactive:set_mock_answers([
        colaborador_autorizado(_) - true,
        sku_reconhecido(_) - false
    ]),

    retail_engine:run_interactive(ResultDict),
    assertion(ResultDict.status == "success"),
    assertion(has_fact(decisao(recusar))),
    assertion(has_fact(regra_disparada('HS-001'))),

    % Check causal trace
    retail_engine:facto(DecFactId, decisao(recusar)),
    retail_engine:explain_how(DecFactId, HowTrace),
    assertion(once((member(Line, HowTrace), sub_string(Line, _, _, _, "HS-001")))).

% ------------------------------------------------------------------------------
% 8. End-to-End Interactive Session (run_interactive/2)
% ------------------------------------------------------------------------------

test(run_interactive_with_partial_initial_facts) :-
    InitialFacts = [
        colaborador_autorizado(true),
        canal_compra(mainline)
    ],

    retail_interactive:set_mock_answers([
        sku_reconhecido(_) - true,
        categoria_produto(_) - vestuario_geral,
        estado_produto(_) - nao_usado_com_etiquetas,
        comprovativo(_) - recibo_impresso,
        dias_desde_compra(_) - 7,
        meio_pagamento(_) - credito,
        sessao_pos_propria(_) - true,
        recibo_entregue(_) - true
    ]),

    retail_engine:run_interactive(InitialFacts, ResultDict),
    assertion(ResultDict.status == "success"),
    assertion(ResultDict.decision == permitir),
    assertion(ResultDict.dialogue_log \== []).

% ------------------------------------------------------------------------------
% 9. End-to-End Interactive Session From Empty State (run_interactive/1)
% ------------------------------------------------------------------------------

test(run_interactive_from_empty_state_seeds_colaborador) :-
    retail_interactive:set_mock_answers([
        colaborador_autorizado(_) - true,
        sku_reconhecido(_) - true,
        categoria_produto(_) - vestuario_geral,
        estado_produto(_) - nao_usado_com_etiquetas,
        comprovativo(_) - recibo_impresso,
        dias_desde_compra(_) - 12,
        meio_pagamento(_) - credito,
        sessao_pos_propria(_) - true,
        recibo_entregue(_) - true
    ]),

    retail_engine:run_interactive(ResultDict),
    assertion(ResultDict.status == "success"),
    assertion(ResultDict.decision == permitir),
    assertion(has_fact(colaborador_autorizado(true))).

% ------------------------------------------------------------------------------
% 10. Precedence 1: Unauthorized Operator Immediate Halt
% ------------------------------------------------------------------------------

test(precedence_1_unauthorized_operator_stops_immediately) :-
    retail_interactive:set_mock_answers([
        colaborador_autorizado(_) - false
    ]),

    retail_engine:run_interactive(ResultDict),
    assertion(ResultDict.status == "success"),
    assertion(ResultDict.decision == encaminhar),
    assertion(has_fact(regra_disparada('HS-006'))),
    % No further questions should have been asked about product or receipt
    assertion(\+ has_fact(sku_reconhecido(_))),
    assertion(\+ has_fact(comprovativo(_))).

% ------------------------------------------------------------------------------
% 11. Bodywear Disposition Interactive Branching (BW-001)
% ------------------------------------------------------------------------------

test(bodywear_interactive_branching_to_sales_floor) :-
    InitialFacts = [
        colaborador_autorizado(true),
        sku_reconhecido(true),
        categoria_produto(bodywear),
        comprovativo(recibo_impresso),
        dias_desde_compra(5),
        meio_pagamento(debito)
    ],

    retail_interactive:set_mock_answers([
        embalagem_intacta(_) - true,
        estado_produto(_) - nao_usado_com_etiquetas,
        sessao_pos_propria(_) - true,
        recibo_entregue(_) - true
    ]),

    retail_engine:run_interactive(InitialFacts, ResultDict),
    assertion(ResultDict.status == "success"),
    assertion(has_fact(decisao(permitir))),
    assertion(has_fact(regra_disparada('BW-001'))),
    assertion(has_fact(destino_produto(area_vendas))).

% ------------------------------------------------------------------------------
% 11b. PC-002 asks about resale (IN-010) before leaving the item in review
% ------------------------------------------------------------------------------

pc_002_initial_facts([
    colaborador_autorizado(true), canal_compra(mainline), sku_reconhecido(true),
    categoria_produto(vestuario), estado_produto(nao_usado_etiquetas_soltas),
    comprovativo(recibo_impresso), dias_desde_compra(10), tipo_pedido(devolucao)
]).

test(pc_002_asks_resale_and_approves_when_resellable) :-
    retail_engine:load_knowledge_base(retail_rules),
    retail_interactive:set_mock_answers([revendivel(_) - true]),
    pc_002_initial_facts(Facts),
    retail_engine:run_interactive(Facts, R),
    assertion(memberchk(asked(revendivel(_), _), R.dialogue_log)),
    assertion(has_fact(elegibilidade_produto(aprovada))),
    assertion(\+ has_fact(decisao(rever))).

test(pc_002_unknown_resale_stays_in_review) :-
    retail_engine:load_knowledge_base(retail_rules),
    retail_interactive:set_mock_answers([revendivel(_) - nao_sei]),
    pc_002_initial_facts(Facts),
    retail_engine:run_interactive(Facts, R),
    assertion(R.decision == rever),
    assertion(has_fact(regra_disparada('PC-002'))),
    assertion(\+ has_fact(elegibilidade_produto(aprovada))).

% ------------------------------------------------------------------------------
% 12. Reset Clears All Dynamic Memory and Interrogation State
% ------------------------------------------------------------------------------

test(reset_engine_clears_all_interrogation_and_mock_state) :-
    retail_engine:load_knowledge_base(retail_rules),
    retail_interactive:set_mock_answers([sku_reconhecido(_) - true]),
    assertz(retail_engine:ja_perguntado(sku_reconhecido(_))),
    assertz(retail_engine:regra_ativa('PC-001', teste)),

    retail_engine:reset_engine,

    assertion(\+ retail_engine:ja_perguntado(_)),
    assertion(\+ retail_engine:regra_ativa(_, _)),
    assertion(\+ retail_interactive:tem_mock_resposta(_)),
    retail_interactive:get_dialogue_log(Log),
    assertion(Log == []).

% ------------------------------------------------------------------------------
% 13. Numeric Answers Are Validated in the Terminal (re-ask on invalid input)
% ------------------------------------------------------------------------------

test(terminal_rejects_non_numeric_days_and_asks_again) :-
    retail_engine:load_knowledge_base(retail_rules),
    setup_call_cleanup(
        open_string("abc\n-3\n12\n", In),
        with_output_to(string(Out),
            with_input_from(In,
                retail_interactive:perguntar_terminal_loop(dias_desde_compra(_), "Dias?", Resposta))),
        close(In)
    ),
    assertion(Resposta == dias_desde_compra(12)),
    aggregate_all(count, sub_string(Out, _, _, _, "indique um número"), Erros),
    assertion(Erros == 2).

with_input_from(In, Goal) :-
    current_input(Old),
    setup_call_cleanup(set_input(In), Goal, set_input(Old)).

:- end_tests(retail_interactive_suite).

run_retail_interactive_tests :-
    run_tests([retail_interactive_suite]).
