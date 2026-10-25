:- encoding(utf8).
:- module(test_retail_explainability, [
    run_retail_explainability_tests/0
]).

/** <module> PLUnit Tests for Phase 4: 5-Way Explainability Architecture
 *
 * Validates the 5 diagnostic explainability perspectives:
 * 1. VIA 1: Como? (How) — Deductive causal tree with formal rule IDs ([PC-001], [PT-003]),
 *    clear discrimination between user-provided (operador), initial, and rule-derived facts.
 * 2. VIA 2: Porquê da Pergunta? (Why Ask) — Contextual normative justification during active
 *    premise interrogation, identifying rule ID, family, objective, and description.
 * 3. VIA 3: Porquê da Decisão? (Output Why) — Executive decision synthesis compiling
 *    justifications into list[str] with normative rule prefixes for canonical outcomes.
 * 4. VIA 4: Porque Não? (Why Not) — Counterfactual failure diagnosis reporting unsatisfied
 *    premises and recursive antecedents when full approval (PERMITIR) is not reached.
 * 5. VIA 5: E Se? (What-If) — Transactional sandbox simulation via setup_call_cleanup/3
 *    demonstrating decision diffing, impact reporting, and guaranteed zero memory pollution.
 */

:- use_module(library(plunit)).
:- use_module('../src/core/retail_engine/engine').
:- use_module('../src/core/retail_engine/interactive').

% Helper to verify fact existence in retail_engine
has_fact(Fact) :-
    retail_engine:facto(_, Fact),
    !.

contains_substr(Haystack, Needle) :-
    once(sub_string(Haystack, _, _, _, Needle)).

% Helper to seed baseline scenario facts cleanly
setup_baseline_facts(FactsList) :-
    retail_engine:load_knowledge_base(retail_rules),
    length(FactsList, Count),
    retractall(retail_engine:ultimo_facto(_)),
    asserta(retail_engine:ultimo_facto(Count)),
    setup_facts_rec(FactsList, 1).

setup_facts_rec([], _).
setup_facts_rec([F|Rest], N) :-
    assertz(retail_engine:facto(N, F)),
    N1 is N + 1,
    setup_facts_rec(Rest, N1).

:- begin_tests(retail_explainability_suite).

% ==============================================================================
% 1. VIA 1: COMO? (HOW) — DEDUCTIVE CAUSAL TRACE
% ==============================================================================

test(explain_how_rule_derived_decision_with_formal_brackets) :-
    % Standard eligible return -> PT-003 concludes decisao(permitir)
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(recibo_impresso),
        dias_desde_compra(14),
        meio_pagamento(credito)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),
    assertion(has_fact(decisao(permitir))),

    % Query explain_how for decisao(permitir) by term and verify formal rule brackets
    retail_engine:explain_how(decisao(permitir), Explanations),
    assertion(Explanations \== []),
    once((
        member(Line1, Explanations),
        sub_string(Line1, _, _, _, "concluded by rule [PT-003]")
    )),
    once((
        member(Line2, Explanations),
        sub_string(Line2, _, _, _, "Based on facts:")
    )),
    % Recursive supporting facts: estado_produto led to elegibilidade_produto via [PC-001]
    once((
        member(Line3, Explanations),
        sub_string(Line3, _, _, _, "concluded by rule [PC-001]")
    )).

test(explain_how_user_provided_fact_provenance) :-
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        comprovativo(recibo_impresso)
    ]),
    % Simulate user answering an askable fact dynamically
    retail_engine:regista_resposta(estado_produto(nao_usado_com_etiquetas), FactId),
    retail_engine:explain_how(FactId, Explanation),
    assertion(Explanation \== []),
    Explanation = [Line|_],
    assertion(sub_string(Line, _, _, _, "was provided by user")).

test(explain_how_initial_fact_provenance) :-
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true)
    ]),
    retail_engine:explain_how(1, Explanation),
    assertion(Explanation \== []),
    Explanation = [Line|_],
    assertion(sub_string(Line, _, _, _, "was an initial fact")).

test(explain_how_unreached_fact_graceful_message) :-
    setup_baseline_facts([
        colaborador_autorizado(true)
    ]),
    retail_engine:run_engine(_),
    retail_engine:explain_how(decisao(permitir), [Msg]),
    assertion(sub_string(Msg, _, _, _, "Conclusion not reached")).

test(como_terminal_output_execution) :-
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(recibo_impresso),
        dias_desde_compra(10),
        meio_pagamento(credito)
    ]),
    retail_engine:run_engine(_),
    % Test como/1 by fact term and by integer ID
    with_output_to(string(Output1), retail_engine:como(decisao(permitir))),
    assertion(sub_string(Output1, _, _, _, "Concluiu o facto")),
    assertion(sub_string(Output1, _, _, _, "[PT-003]")),
    assertion(sub_string(Output1, _, _, _, "inicial da base")),

    with_output_to(string(Output2), retail_engine:como(999)),
    assertion(sub_string(Output2, _, _, _, "não existe na memória")).

% ==============================================================================
% 2. VIA 2: PORQUÊ DA PERGUNTA? (WHY ASK) — ACTIVE CONTEXTUAL JUSTIFICATION
% ==============================================================================

test(why_ask_specific_rules_and_families) :-
    retail_engine:load_knowledge_base(retail_rules),

    % Test Why Ask for PC-001 (Product Condition)
    retail_engine:why_ask('PC-001', PCWhy),
    assertion(contains_substr(PCWhy, "PC-001")),
    assertion((contains_substr(PCWhy, "Product Condition") -> true ; contains_substr(PCWhy, "Estado do Produto"))),
    assertion(contains_substr(PCWhy, "etiquetas")),

    % Test Why Ask for PT-003 (Proof & Timeframe)
    retail_engine:why_ask('PT-003', PTWhy),
    assertion(contains_substr(PTWhy, "PT-003")),
    assertion((contains_substr(PTWhy, "Proof & Timeframe") -> true ; contains_substr(PTWhy, "Comprovativo e Prazos"))),
    assertion(contains_substr(PTWhy, "30 dias")),

    % Test Why Ask for HS-001 (Hard Stops)
    retail_engine:why_ask('HS-001', HSWhy),
    assertion(contains_substr(HSWhy, "HS-001")),
    assertion((contains_substr(HSWhy, "Hard Stops") -> true ; contains_substr(HSWhy, "Paragens Obrigatórias"))),
    assertion(contains_substr(HSWhy, "SKU")).

test(why_ask_variant_uses_visible_code_description) :-
    retail_engine:load_knowledge_base(retail_rules),
    retail_engine:why_ask('PC-002-REVENDIVEL', Why),
    assertion(contains_substr(Why, "PC-002 (variante PC-002-REVENDIVEL)")),
    assertion(contains_substr(Why, "Estado do Produto")),
    assertion(\+ contains_substr(Why, "necessária para avaliar as regras de elegibilidade")).

test(nome_familia_is_deterministic) :-
    findall(N, retail_interactive:nome_familia(pc, N), Nomes),
    assertion(Nomes == ["Product Condition (Estado do Produto)"]),
    findall(N, retail_interactive:nome_familia(xx, N), Gerais),
    assertion(Gerais == ["Regras Gerais de Devolução"]).

test(why_ask_active_rule_during_candidate_evaluation) :-
    retail_engine:load_knowledge_base(retail_rules),
    % Assert active rule dynamically to test live Why Ask resolution
    setup_call_cleanup(
        asserta(retail_engine:regra_ativa('PC-006', elegibilidade_produto(aprovada))),
        once((
            retail_engine:why_ask(ActiveWhy),
            assertion(sub_string(ActiveWhy, _, _, _, "PC-006")),
            assertion(sub_string(ActiveWhy, _, _, _, "defeito de fabrico"))
        )),
        retractall(retail_engine:regra_ativa('PC-006', _))
    ),
    % When no active rule is set
    retail_engine:why_ask(InactiveWhy),
    assertion(sub_string(InactiveWhy, _, _, _, "Não há nenhuma regra candidata ativa")).

test(why_ask_dynamic_premise_mercado_without_and_with_waiting_rules) :-
    retail_engine:load_knowledge_base(retail_rules),

    % Case A: Empty facts -> dependent rules found, but none waiting
    retail_engine:explain_why_premise("IN-001", [], Resp1),
    assertion(Resp1.status == "success"),
    assertion(Resp1.codigo == "IN-001"),
    assertion(Resp1.dado == "mercado"),
    assertion(contains_substr(Resp1.pergunta, "mercado")),
    assertion(member("TN-011", Resp1.regras_dependentes)),
    assertion(member("TN-012", Resp1.regras_dependentes)),
    assertion(Resp1.regras_em_espera == []),
    assertion(contains_substr(Resp1.resumo, "políticas da loja")),

    % Case B: Facts satisfy other conditions of TN-011 -> TN-011 is em espera!
    retail_engine:explain_why_premise(
        "IN-001",
        [meio_pagamento(interac), cartao_interac_presente(true)],
        Resp2
    ),
    assertion(Resp2.status == "success"),
    assertion(Resp2.regras_em_espera \== []),
    once((
        member(Espera, Resp2.regras_em_espera),
        Espera.codigoRegra == "TN-011",
        contains_substr(Espera.nomeRegra, "Interac"),
        Espera.modulo == "tn",
        assertion(member("meio_reembolso(meio_original)", Espera.conclusoes)),
        assertion(member("processo_obrigatorio(pos)", Espera.conclusoes)),
        once((
            member(Cond, Espera.condicoesDoDado),
            Cond.nome == "mercado",
            Cond.cumprida == false
        ))
    )),
    assertion(contains_substr(Resp2.resumo, "TN-011")),
    assertion(contains_substr(Resp2.resumo, "determinante")).

test(why_ask_dynamic_premise_timeframe_with_verified_facts) :-
    retail_engine:load_knowledge_base(retail_rules),

    % With verified return facts asserted, PT-003 and PT-004 are waiting solely for timeframe
    BaseFacts = [
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(recibo_impresso)
    ],
    retail_engine:explain_why_premise("IN-006", BaseFacts, Resp),
    assertion(Resp.status == "success"),
    assertion(Resp.codigo == "IN-006"),
    assertion(Resp.dado == "dias_desde_compra"),
    assertion(member("PT-003", Resp.regras_dependentes)),
    assertion(member("PT-004", Resp.regras_dependentes)),
    % Both PT-003 (<=30) and PT-004 (>30) are candidate waiting rules
    findall(Code, (
        member(E, Resp.regras_em_espera),
        Code = E.codigoRegra
    ), WaitingCodes),
    assertion(member("PT-003", WaitingCodes)),
    assertion(member("PT-004", WaitingCodes)),
    assertion(contains_substr(Resp.resumo, "PT-003")).

test(why_ask_dynamic_premise_attribute_aliases_and_casing) :-
    retail_engine:load_knowledge_base(retail_rules),

    % Query by lowercase string "in-001"
    retail_engine:explain_why_premise("in-001", [], R1),
    assertion(R1.codigo == "IN-001"),

    % Query by attribute name "mercado"
    retail_engine:explain_why_premise("mercado", [], R2),
    assertion(R2.codigo == "IN-001"),
    assertion(R2.dado == "mercado"),

    % Query by atom compound mercado(_)
    retail_engine:explain_why_premise(mercado(_), [], R3),
    assertion(R3.codigo == "IN-001"),

    % Query by condition name "estado_produto"
    retail_engine:explain_why_premise("estado_produto", [], R4),
    assertion(R4.codigo == "IN-008"),
    assertion(R4.dado == "estado_produto").

test(why_ask_dynamic_premise_sandbox_zero_pollution) :-
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(lavado)
    ]),
    retail_engine:count_facts(CountBefore),

    % Execute why ask evaluation with a different scenario
    retail_engine:explain_why_premise(
        "IN-001",
        [meio_pagamento(interac), cartao_interac_presente(true)],
        _
    ),

    % Working memory must be strictly restored to baseline
    retail_engine:count_facts(CountAfter),
    assertion(CountAfter == CountBefore),
    assertion(has_fact(estado_produto(lavado))),
    assertion(\+ has_fact(meio_pagamento(interac))).

% ==============================================================================
% 3. VIA 3: PORQUÊ DA DECISÃO? (OUTPUT WHY) — EXECUTIVE SUMMARY
% ==============================================================================

test(output_why_approved_decision_justifications) :-
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(recibo_impresso),
        dias_desde_compra(14),
        meio_pagamento(credito),
        sessao_pos_propria(true)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.status == "success"),
    assertion(Result.decision == permitir),
    assertion(Result.justification \== []),

    % Verify output_why extracts reasons with rule codes
    retail_engine:output_why(JustList),
    assertion(once((member(J1, JustList), sub_string(J1, _, _, _, "[PC-001]")))),
    assertion(once((member(J2, JustList), sub_string(J2, _, _, _, "[PT-001]")))),
    assertion(once((member(J3, JustList), sub_string(J3, _, _, _, "[PT-003]")))),

    % Verify decision_justification/2
    retail_engine:decision_justification(Decision, DecJusts),
    assertion(Decision == permitir),
    assertion(DecJusts == JustList).

test(output_why_rejected_biohazard_decision_justifications) :-
    % PC-008 isola a peça; a recusa vem do estado de uso (lavado, PC-005)
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(sujo_contaminado_inseguro),
        estado_produto(lavado)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.decision == recusar),
    retail_engine:output_why(JustList),
    assertion(once((member(J, JustList), sub_string(J, _, _, _, "[PC-008]")))),
    assertion(once((member(J, JustList), sub_string(J, _, _, _, "risco biológico")))).

test(output_why_terminal_printer_execution) :-
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(recibo_impresso),
        dias_desde_compra(7),
        meio_pagamento(credito)
    ]),
    retail_engine:run_engine(_),
    with_output_to(string(Out), retail_engine:output_why),
    assertion(sub_string(Out, _, _, _, "PORQUÊ DA DECISÃO: permitir")),
    assertion(sub_string(Out, _, _, _, "[PT-003]")).

% ==============================================================================
% 4. VIA 4: PORQUE NÃO? (WHY NOT) — CONTRAFACTUAL FAILURE DIAGNOSIS
% ==============================================================================

test(whynot_rejected_washed_item_fails_permitir) :-
    % Washed product rejected by PC-005
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(lavado),
        comprovativo(recibo_impresso),
        dias_desde_compra(14)
    ]),
    retail_engine:run_engine(Result),
    assertion(Result.decision == recusar),

    % Investigate why decisao(permitir) failed
    retail_engine:explain_whynot(decisao(permitir), Explanations),
    assertion(Explanations \== []),

    % PT-003 was evaluated as a candidate rule for permitir
    once((
        member(L1, Explanations),
        sub_string(L1, _, _, _, "Because by rule [PT-003]:")
    )),
    % elegibilidade_produto(aprovada) failed because PC-001/PC-006/PC-007 failed
    once((
        member(L2, Explanations),
        sub_string(L2, _, _, _, "Premise elegibilidade_produto(aprovada) is false")
    )),
    % Sub-explanation inside PC-001 shows unworn condition failed
    once((
        member(L3, Explanations),
        sub_string(L3, _, _, _, "Because by rule [PC-001]:")
    )),
    once((
        member(L4, Explanations),
        sub_string(L4, _, _, _, "Premise estado_produto(nao_usado_com_etiquetas) is false")
    )),
    % Refusal prevents approval: nao decisao(recusar) is false
    once((
        member(L5, Explanations),
        sub_string(L5, _, _, _, "Premise nao decisao(recusar) is false")
    )).

test(whynot_atom_shorthand_support) :-
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(lavado)
    ]),
    retail_engine:run_engine(_),
    % Test atom shorthand 'permitir' instead of compound 'decisao(permitir)'
    retail_engine:explain_whynot(permitir, Explanations),
    assertion(Explanations \== []),
    once((
        member(Line, Explanations),
        sub_string(Line, _, _, _, "rule [PT-003]")
    )).

test(whynot_already_true_fact_reports_truth) :-
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(sujo_contaminado_inseguro),
        estado_produto(lavado)
    ]),
    retail_engine:run_engine(_),
    assertion(has_fact(decisao(recusar))),
    retail_engine:explain_whynot(decisao(recusar), [Msg]),
    assertion(sub_string(Msg, _, _, _, "already true in the knowledge base")).

test(whynot_terminal_printer_execution) :-
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(lavado)
    ]),
    retail_engine:run_engine(_),
    with_output_to(string(Out), retail_engine:whynot(permitir)),
    assertion(sub_string(Out, _, _, _, "Because by rule [PT-003]:")),
    assertion(sub_string(Out, _, _, _, "elegibilidade_produto(aprovada)")).

% ==============================================================================
% 5. VIA 5: E SE? (WHAT-IF) — COUNTERFACTUAL SANDBOX SIMULATION
% ==============================================================================

test(what_if_rejection_to_approval_simulation) :-
    % Baseline: customer brings washed item with receipt -> recusar (PC-005)
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(lavado),
        comprovativo(recibo_impresso),
        dias_desde_compra(14),
        meio_pagamento(credito)
    ]),
    retail_engine:run_engine(BaselineResult),
    assertion(BaselineResult.decision == recusar),

    % Count memory footprint before what-if
    retail_engine:count_facts(PreCount),
    assertion(PreCount > 0),
    assertion(has_fact(estado_produto(lavado))),
    assertion(has_fact(decisao(recusar))),

    % Simulation: "What if the item was unworn with tags attached instead of washed?"
    retail_engine:what_if(
        [estado_produto(nao_usado_com_etiquetas)],
        [estado_produto(_)],
        SimResult
    ),

    % Verify simulation results
    assertion(SimResult.status == "success"),
    assertion(SimResult.baseline_decision == recusar),
    assertion(SimResult.simulated_decision == permitir),
    assertion(SimResult.decision_changed == true),
    assertion(once((member(J1, SimResult.baseline_justification), sub_string(J1, _, _, _, "[PC-005]")))),
    assertion(once((member(J2, SimResult.simulated_justification), sub_string(J2, _, _, _, "[PT-003]")))),
    assertion(sub_string(SimResult.impact_summary, _, _, _, "recusar")),
    assertion(sub_string(SimResult.impact_summary, _, _, _, "permitir")),

    % STRICT POST-CONDITION: Check that baseline memory is 100% restored
    retail_engine:count_facts(PostCount),
    assertion(PostCount == PreCount),
    assertion(has_fact(estado_produto(lavado))),
    assertion(has_fact(decisao(recusar))),
    assertion(\+ has_fact(estado_produto(nao_usado_com_etiquetas))),
    assertion(\+ has_fact(decisao(permitir))).

test(what_if_timeframe_repair_review_to_approval) :-
    % Baseline: verified purchase but at 45 days -> rever com gestão (PT-004)
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(true),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(recibo_impresso),
        dias_desde_compra(45),
        meio_pagamento(credito)
    ]),
    retail_engine:run_engine(BaselineResult),
    assertion(BaselineResult.decision == rever),

    retail_engine:count_facts(PreCount),

    % Simulation: "What if the purchase was made 14 days ago?"
    retail_engine:what_if(
        [dias_desde_compra(14)],
        [dias_desde_compra(_)],
        SimResult
    ),

    assertion(SimResult.baseline_decision == rever),
    assertion(SimResult.simulated_decision == permitir),
    assertion(SimResult.decision_changed == true),
    assertion(once((member(J1, SimResult.baseline_justification), sub_string(J1, _, _, _, "[PT-004]")))),
    assertion(once((member(J2, SimResult.simulated_justification), sub_string(J2, _, _, _, "[PT-003]")))),

    % Memory integrity preserved
    retail_engine:count_facts(PostCount),
    assertion(PostCount == PreCount),
    assertion(has_fact(dias_desde_compra(45))),
    assertion(has_fact(decisao(rever))).

test(what_if_unchanged_decision_simulation) :-
    % Baseline: Unrecognized SKU -> HS-001 (recusar)
    setup_baseline_facts([
        colaborador_autorizado(true),
        sku_reconhecido(false),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(recibo_impresso)
    ]),
    retail_engine:run_engine(BaselineResult),
    assertion(BaselineResult.decision == recusar),

    % Simulation: Changing tender to numerario does NOT fix invalid SKU
    retail_engine:what_if(
        [meio_pagamento(numerario)],
        [meio_pagamento(_)],
        SimResult
    ),
    assertion(SimResult.baseline_decision == recusar),
    assertion(SimResult.simulated_decision == recusar),
    assertion(SimResult.decision_changed == false),
    assertion(sub_string(SimResult.impact_summary, _, _, _, "inalterada")).

test(what_if_zero_pollution_on_empty_state) :-
    retail_engine:reset_engine,
    retail_engine:load_knowledge_base(retail_rules),
    % Working memory has 0 initial facts
    retail_engine:count_facts(PreCount),
    assertion(PreCount == 0),

    retail_engine:what_if(
        [
            colaborador_autorizado(true),
            sku_reconhecido(true),
            estado_produto(nao_usado_com_etiquetas),
            comprovativo(recibo_impresso),
            dias_desde_compra(10),
            meio_pagamento(credito)
        ],
        [],
        SimResult
    ),

    assertion(SimResult.status == "success"),
    assertion(SimResult.baseline_decision == nao_concluido),
    assertion(SimResult.simulated_decision == permitir),
    assertion(SimResult.decision_changed == true),

    % Ensure memory was completely cleaned up back to 0 facts
    retail_engine:count_facts(PostCount),
    assertion(PostCount == 0).

:- end_tests(retail_explainability_suite).

run_retail_explainability_tests :-
    run_tests([retail_explainability_suite]).
