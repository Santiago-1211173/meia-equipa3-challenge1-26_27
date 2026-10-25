:- encoding(utf8).
:- module(test_retail_api, [
    run_retail_api_tests/0
]).

/** <module> PLUnit Integration Tests for Retail Engine REST API Layer (Phase 5)
 *
 * Validates all REST API transport routes:
 *   - POST /retail/evaluate
 *   - POST /retail/interactive
 *   - POST /retail/whatif
 *   - POST /retail/how
 *   - POST /retail/whynot
 *   - GET  /retail/facts
 *   - POST /retail/reset
 */

:- use_module(library(plunit)).
:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).

:- use_module('../src/api/server', [server_start/1, server_stop/1]).
:- use_module('../src/api/retail_routes', []).
:- use_module('../src/core/retail_engine/engine', [load_knowledge_base/1, reset_engine/0]).

% Distinct port to prevent collisions with other test suites
test_retail_port(8992).

:- begin_tests(retail_api_suite, [
    setup((
        test_retail_port(Port),
        server_start(Port),
        load_knowledge_base(retail_rules)
    )),
    cleanup((
        test_retail_port(Port),
        server_stop(Port),
        reset_engine
    ))
]).

% ------------------------------------------------------------------------------
% 1. POST /retail/evaluate Tests
% ------------------------------------------------------------------------------

test(evaluate_approved_canonical_apparel) :-
    test_retail_port(Port),
    format(atom(Url), 'http://127.0.0.1:~w/retail/evaluate', [Port]),
    Payload = _{
        colaborador_autorizado: true,
        sku_reconhecido: true,
        canal_compra: "mainline",
        categoria_produto: "vestuario",
        estado_produto: "nao_usado_com_etiquetas",
        comprovativo: "recibo_original",
        dias_desde_compra: 14,
        meio_pagamento: "cartao_credito"
    },
    http_post(Url, json(Payload), Reply, [json_object(dict)]),
    assertion(Reply.status == "success"),
    assertion(Reply.decision == "approved"),
    assertion(Reply.retail_decision == "permitir"),
    assertion(is_list(Reply.justification)),
    assertion(Reply.justification \== []).

test(evaluate_rejected_biohazard) :-
    % PC-008 só isola a peça; a recusa vem da alteração (HS-003), e PC-008 dispara na mesma
    test_retail_port(Port),
    format(atom(Url), 'http://127.0.0.1:~w/retail/evaluate', [Port]),
    Payload = _{
        colaborador_autorizado: true,
        sku_reconhecido: true,
        canal_compra: "mainline",
        categoria_produto: "vestuario",
        personalizado_ou_alterado: true,
        estado_produto: "sujo_contaminado_inseguro",
        comprovativo: "recibo_original",
        dias_desde_compra: 5,
        meio_pagamento: "cartao_credito"
    },
    http_post(Url, json(Payload), Reply, [json_object(dict)]),
    assertion(Reply.status == "success"),
    assertion(Reply.decision == "rejected"),
    assertion(Reply.retail_decision == "recusar"),
    assertion(is_list(Reply.justification)).

test(evaluate_manager_override_unauthorized_operator) :-
    test_retail_port(Port),
    format(atom(Url), 'http://127.0.0.1:~w/retail/evaluate', [Port]),
    Payload = _{
        colaborador_autorizado: false,
        sku_reconhecido: true,
        canal_compra: "mainline",
        categoria_produto: "vestuario",
        estado_produto: "nao_usado_com_etiquetas"
    },
    http_post(Url, json(Payload), Reply, [json_object(dict)]),
    assertion(Reply.status == "success"),
    assertion(Reply.decision == "manager_override"),
    assertion(Reply.retail_decision == "encaminhar").

test(evaluate_without_deciding_rule_is_not_a_refusal) :-
    % No rule decides (no condition, proof or request): not concluded, never "rejected"
    test_retail_port(Port),
    format(atom(Url), 'http://127.0.0.1:~w/retail/evaluate', [Port]),
    Payload = _{
        colaborador_autorizado: true,
        sku_reconhecido: true,
        canal_compra: "mainline"
    },
    http_post(Url, json(Payload), Reply, [json_object(dict)]),
    assertion(Reply.status == "success"),
    assertion(Reply.retail_decision == "nao_concluido"),
    assertion(Reply.decision == "manager_override"),
    assertion(is_list(Reply.regras_a_validar)).

test(evaluate_store_credit_only_blind_return) :-
    test_retail_port(Port),
    format(atom(Url), 'http://127.0.0.1:~w/retail/evaluate', [Port]),
    Payload = _{
        colaborador_autorizado: true,
        sku_reconhecido: true,
        canal_compra: "mainline",
        categoria_produto: "vestuario",
        estado_produto: "nao_usado_com_etiquetas",
        comprovativo: "sem_comprovativo",
        valor_transacao: 60
    },
    http_post(Url, json(Payload), Reply, [json_object(dict)]),
    assertion(Reply.status == "success"),
    assertion(Reply.decision == "store_credit_only").

test(evaluate_nested_json_payload) :-
    test_retail_port(Port),
    format(atom(Url), 'http://127.0.0.1:~w/retail/evaluate', [Port]),
    Payload = _{
        colaborador_autorizado: true,
        sku_reconhecido: true,
        item: _{
            categoria: "vestuario",
            estado: "nao_usado_com_etiquetas"
        },
        compra: _{
            canal: "mainline",
            dias_desde_compra: 10,
            meio_pagamento: "cartao_credito",
            comprovativo: "recibo_original"
        }
    },
    http_post(Url, json(Payload), Reply, [json_object(dict)]),
    assertion(Reply.status == "success"),
    assertion(Reply.decision == "approved").

test(evaluate_malformed_json_returns_400) :-
    test_retail_port(Port),
    format(atom(Url), 'http://127.0.0.1:~w/retail/evaluate', [Port]),
    catch(
        (
            http_post(Url, string('application/json', "{ invalid: json "), _Reply, []),
            fail
        ),
        error(existence_error(url, _), _),
        true
    ).

% ------------------------------------------------------------------------------
% 2. POST /retail/interactive Tests
% ------------------------------------------------------------------------------

test(interactive_dialogue_with_answers_completes) :-
    test_retail_port(Port),
    format(atom(Url), 'http://127.0.0.1:~w/retail/interactive', [Port]),
    Payload = _{
        answers: _{
            colaborador_autorizado: true,
            sku_reconhecido: true,
            canal_compra: "mainline",
            categoria_produto: "vestuario",
            estado_produto: "nao_usado_com_etiquetas",
            comprovativo: "recibo_original",
            dias_desde_compra: 12,
            meio_pagamento: "cartao_credito"
        }
    },
    http_post(Url, json(Payload), Reply, [json_object(dict)]),
    assertion(Reply.status == "completed"),
    assertion(Reply.decision == "approved"),
    assertion(is_list(Reply.dialogue_log)).

test(interactive_question_pending_when_missing_attribute) :-
    test_retail_port(Port),
    format(atom(Url), 'http://127.0.0.1:~w/retail/reset', [Port]),
    http_post(Url, json(_{}), _, [json_object(dict)]),
    format(atom(IntUrl), 'http://127.0.0.1:~w/retail/interactive', [Port]),
    http_post(IntUrl, json(_{}), Reply, [json_object(dict)]),
    assertion(Reply.status == "question"),
    assertion(Reply.decision == "nao_concluido"),
    assertion(is_dict(Reply.question)).

% ------------------------------------------------------------------------------
% 3. POST /retail/whatif Tests
% ------------------------------------------------------------------------------

test(whatif_counterfactual_simulation_and_rollback) :-
    test_retail_port(Port),
    format(atom(Url), 'http://127.0.0.1:~w/retail/whatif', [Port]),
    Payload = _{
        base_facts: [
            "colaborador_autorizado(true)",
            "sku_reconhecido(true)",
            "canal_compra(mainline)",
            "categoria_produto(vestuario)",
            "estado_produto(claramente_usado)",
            "comprovativo(recibo_original)",
            "dias_desde_compra(15)",
            "meio_pagamento(cartao_credito)"
        ],
        add: [
            "estado_produto(nao_usado_com_etiquetas)"
        ],
        remove: [
            "estado_produto(claramente_usado)"
        ]
    },
    http_post(Url, json(Payload), Reply, [json_object(dict)]),
    assertion(Reply.status == "success"),
    assertion(Reply.baseline_decision == "rever"),
    assertion(Reply.simulated_decision == "permitir"),
    assertion(Reply.decision_changed == true),
    % Verify session memory was completely rolled back
    format(atom(FactsUrl), 'http://127.0.0.1:~w/retail/facts', [Port]),
    http_get(FactsUrl, FactsReply, [json_object(dict)]),
    assertion(FactsReply.status == "success").

% ------------------------------------------------------------------------------
% 4. POST /retail/how Tests (Via 1: How)
% ------------------------------------------------------------------------------

test(how_explains_decision_causal_chain) :-
    test_retail_port(Port),
    % Setup facts first
    format(atom(EvalUrl), 'http://127.0.0.1:~w/retail/evaluate', [Port]),
    http_post(EvalUrl, json(_{
        colaborador_autorizado: true,
        sku_reconhecido: true,
        canal_compra: "mainline",
        categoria_produto: "vestuario",
        estado_produto: "nao_usado_com_etiquetas",
        comprovativo: "recibo_original",
        dias_desde_compra: 10,
        meio_pagamento: "cartao_credito"
    }), _, [json_object(dict)]),
    % Query How
    format(atom(HowUrl), 'http://127.0.0.1:~w/retail/how', [Port]),
    http_post(HowUrl, json(_{fact: "decisao(permitir)"}), HowReply, [json_object(dict)]),
    assertion(HowReply.status == "success"),
    assertion(is_list(HowReply.explanation)),
    assertion(HowReply.explanation \== []).

% ------------------------------------------------------------------------------
% 5. POST /retail/whynot Tests (Via 4: Why Not)
% ------------------------------------------------------------------------------

test(whynot_explains_failed_premises) :-
    test_retail_port(Port),
    % Evaluate washed state (rejected)
    format(atom(EvalUrl), 'http://127.0.0.1:~w/retail/evaluate', [Port]),
    http_post(EvalUrl, json(_{
        colaborador_autorizado: true,
        sku_reconhecido: true,
        canal_compra: "mainline",
        categoria_produto: "vestuario",
        estado_produto: "lavado",
        comprovativo: "recibo_original",
        dias_desde_compra: 10,
        meio_pagamento: "cartao_credito"
    }), _, [json_object(dict)]),
    % Query Why Not for outcome 'approved'
    format(atom(WhyNotUrl), 'http://127.0.0.1:~w/retail/whynot', [Port]),
    http_post(WhyNotUrl, json(_{decision: "approved"}), WhyNotReply, [json_object(dict)]),
    assertion(WhyNotReply.status == "success"),
    assertion(is_list(WhyNotReply.explanation)),
    assertion(WhyNotReply.explanation \== []).

% ------------------------------------------------------------------------------
% 6. POST /retail/why Tests
% ------------------------------------------------------------------------------

test(why_endpoint_with_partial_facts_identifies_waiting_rule) :-
    test_retail_port(Port),
    format(atom(WhyUrl), 'http://127.0.0.1:~w/retail/why', [Port]),
    Payload = _{
        dado: "IN-001",
        base_facts: _{
            meio_pagamento: "interac",
            cartao_interac_presente: true
        }
    },
    http_post(WhyUrl, json(Payload), Reply, [json_object(dict)]),
    assertion(Reply.status == "success"),
    assertion(Reply.codigo == "IN-001"),
    assertion(Reply.dado == "mercado"),
    assertion(is_list(Reply.regras_dependentes)),
    assertion(member("TN-011", Reply.regras_dependentes)),
    assertion(is_list(Reply.regras_em_espera)),
    assertion(Reply.regras_em_espera \== []),
    once((
        member(Espera, Reply.regras_em_espera),
        ( Espera.codigoRegra == "TN-011" ; Espera.codigo_regra == "TN-011" ),
        assertion(Espera.modulo == "tn")
    )).

test(why_endpoint_missing_dado_returns_400) :-
    test_retail_port(Port),
    format(atom(WhyUrl), 'http://127.0.0.1:~w/retail/why', [Port]),
    catch(
        (
            http_post(WhyUrl, json(_{base_facts: []}), _Reply, [json_object(dict)]),
            fail
        ),
        error(existence_error(url, _), _),
        true
    ).

% ------------------------------------------------------------------------------
% 7. GET /retail/facts & POST /retail/reset Tests
% ------------------------------------------------------------------------------

test(facts_and_reset_lifecycle) :-
    test_retail_port(Port),
    format(atom(ResetUrl), 'http://127.0.0.1:~w/retail/reset', [Port]),
    http_post(ResetUrl, json(_{}), ResetReply, [json_object(dict)]),
    assertion(ResetReply.status == "success"),
    format(atom(FactsUrl), 'http://127.0.0.1:~w/retail/facts', [Port]),
    http_get(FactsUrl, FactsReply, [json_object(dict)]),
    assertion(FactsReply.status == "success"),
    assertion(FactsReply.facts_count == 0).

:- end_tests(retail_api_suite).

run_retail_api_tests :-
    run_tests([retail_api_suite]).
