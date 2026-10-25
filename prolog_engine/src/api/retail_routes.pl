:- encoding(utf8).
:- module(retail_routes, [
    handle_retail_evaluate/1,
    handle_retail_interactive/1,
    handle_retail_whatif/1,
    handle_retail_how/1,
    handle_retail_whynot/1,
    handle_retail_why/1,
    handle_retail_facts/1,
    handle_retail_reset/1
]).

/** <module> Retail Returns & Exchanges REST API Transport Routes
 *
 * Implements the HTTP routing and JSON serialization/deserialization layer
 * for the Levi's retail returns expert inference engine (MEIA Challenge 1).
 *
 * Endpoints:
 *   - POST /retail/evaluate    : Canonical batch evaluation returning EvaluationResponse with justification[]
 *   - POST /retail/interactive : Step-by-step or simulated active dialogue interrogation
 *   - POST /retail/whatif      : Counterfactual simulation sandbox with zero session side-effects
 *   - POST /retail/how         : Recursive deductive justification for a fact by ID or term (Via 1: How)
 *   - POST /retail/whynot      : Comprehensive failure tree analysis for unreached outcomes (Via 4: Why Not)
 *   - GET  /retail/facts       : Inspection of working memory state
 *   - POST /retail/reset       : Reset of working memory and interactive state
 */

:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(lists)).

:- use_module('../core/retail_engine/engine', [
    load_knowledge_base/1,
    run_engine/1,
    run_interactive/1,
    run_interactive/2,
    evaluate_facts/2,
    get_all_facts/1,
    explain_how/2,
    why_ask/1,
    why_ask/2,
    explain_why_premise/3,
    output_why/1,
    explain_whynot/2,
    what_if/3,
    reset_engine/0,
    reset_session/0,
    regra_ativa/2,
    facto/2
]).
:- use_module('../core/retail_engine/uncertainty_cf', [
    manager_exception_advice/1
]).
:- use_module('../core/retail_engine/interactive', [
    set_mock_answers/1,
    add_mock_answer/2,
    clear_mock_answers/0,
    formatar_pergunta/2,
    explicar_porque_pergunta/2,
    get_dialogue_log/1,
    clear_dialogue_log/0
]).

% ==============================================================================
% HTTP Endpoint Registrations
% ==============================================================================

:- http_handler(root('retail/evaluate'),    handle_retail_evaluate,    [method(post)]).
:- http_handler(root('retail/interactive'), handle_retail_interactive, [method(post)]).
:- http_handler(root('retail/whatif'),      handle_retail_whatif,      [method(post)]).
:- http_handler(root('retail/how'),         handle_retail_how,         [method(post)]).
:- http_handler(root('retail/whynot'),      handle_retail_whynot,      [method(post)]).
:- http_handler(root('retail/why'),         handle_retail_why,         [method(post)]).
:- http_handler(root('retail/facts'),       handle_retail_facts,       [method(get)]).
:- http_handler(root('retail/reset'),       handle_retail_reset,       [method(post)]).

% ==============================================================================
% 1. POST /retail/evaluate — Batch Evaluation
% ==============================================================================

%!  handle_retail_evaluate(+Request) is det.
%
%   Processes batch retail return evaluation requests. Parses input facts,
%   asserts them into the retail engine working memory, executes forward chaining,
%   and serializes the result conforming to canonical EvaluationResponse.
handle_retail_evaluate(Request) :-
    catch(
        http_read_json_dict(Request, PayloadDict),
        ReadError,
        (
            format(user_error, '~N[RETAIL ROUTES ERROR] Failed to parse evaluate JSON: ~w~n', [ReadError]),
            reply_json_dict(_{
                status: "error",
                message: "Invalid JSON payload or missing required parameters",
                decision: "error",
                justification: []
            }, [status(400)]),
            !
        )
    ),
    (   var(PayloadDict)
    ->  true
    ;   catch(
            (
                dict_to_retail_facts(PayloadDict, FactsList),
                evaluate_facts(FactsList, ResultDict),
                map_canonical_decision(ResultDict.decision, CanonicalDecision),
                uncertainty_advice(UncertaintyCF),
                reply_json_dict(_{
                    status: "success",
                    decision: CanonicalDecision,
                    retail_decision: ResultDict.decision,
                    hard_stop: ResultDict.hard_stop,
                    justification: ResultDict.justification,
                    regras_a_validar: ResultDict.regras_a_validar,
                    initial_facts_count: ResultDict.initial_facts_count,
                    derived_facts_count: ResultDict.derived_facts_count,
                    total_facts: ResultDict.total_facts,
                    derived_facts: ResultDict.derived_facts,
                    uncertainty_cf: UncertaintyCF
                })
            ),
            EvalError,
            (
                format(user_error, '~N[RETAIL ROUTES ERROR] Evaluation failed: ~w~n', [EvalError]),
                reply_json_dict(_{
                    status: "error",
                    message: "Retail inference execution failed",
                    decision: "error",
                    justification: []
                }, [status(500)])
            )
        )
    ).

% ==============================================================================
% 2. POST /retail/interactive — Step-by-Step / Dialogic Interrogation
% ==============================================================================

%!  handle_retail_interactive(+Request) is det.
%
%   Coordinates dialogic reasoning per Prof. ACM mechanics. Supports
%   submitting incremental answers, querying Why Ask, or executing
%   multi-turn questioning until a terminal decision is reached.
handle_retail_interactive(Request) :-
    read_json_or_empty(Request, PayloadDict, StatusCode),
    (   StatusCode =:= 400
    ->  reply_json_dict(_{
            status: "error",
            message: "Invalid JSON payload"
        }, [status(400)])
    ;   catch(
            (
                % Process provided answers/mock_answers if present
                process_interactive_answers(PayloadDict),
                % Extract initial facts if present
                extract_initial_facts_interactive(PayloadDict, InitialFacts),
                % Execute interactive cycle
                run_interactive(InitialFacts, ResultDict),
                get_dialogue_log(RawLog),
                format_dialogue_log(RawLog, FormattedLog),
                (   ResultDict.decision \== nao_concluido
                ->  % Completed with decision
                    map_canonical_decision(ResultDict.decision, CanonicalDecision),
                    reply_json_dict(_{
                        status: "completed",
                        decision: CanonicalDecision,
                        retail_decision: ResultDict.decision,
                        hard_stop: ResultDict.hard_stop,
                        justification: ResultDict.justification,
                        regras_a_validar: ResultDict.regras_a_validar,
                        dialogue_log: FormattedLog,
                        total_facts: ResultDict.total_facts,
                        derived_facts: ResultDict.derived_facts
                    })
                ;   % Pending next question
                    find_next_pending_question(RawLog, PendingQuestion),
                    reply_json_dict(_{
                        status: "question",
                        decision: "nao_concluido",
                        question: PendingQuestion,
                        justification: ResultDict.justification,
                        dialogue_log: FormattedLog,
                        total_facts: ResultDict.total_facts
                    })
                )
            ),
            InterError,
            (
                format(user_error, '~N[RETAIL ROUTES ERROR] Interactive step failed: ~w~n', [InterError]),
                reply_json_dict(_{
                    status: "error",
                    message: "Interactive dialogue processing failed"
                }, [status(500)])
            )
        )
    ).

% ==============================================================================
% 3. POST /retail/whatif — Counterfactual Simulation Sandbox
% ==============================================================================

%!  handle_retail_whatif(+Request) is det.
%
%   Executes isolated counterfactual simulation without modifying session state.
handle_retail_whatif(Request) :-
    catch(
        http_read_json_dict(Request, PayloadDict),
        ReadError,
        (
            format(user_error, '~N[RETAIL ROUTES ERROR] Failed to parse whatif JSON: ~w~n', [ReadError]),
            reply_json_dict(_{
                status: "error",
                message: "Invalid JSON payload or missing required parameters"
            }, [status(400)]),
            !
        )
    ),
    (   var(PayloadDict)
    ->  true
    ;   catch(
            (
                % Setup optional base facts if specified
                setup_whatif_base_facts(PayloadDict),
                % Parse add and remove lists
                extract_whatif_facts(PayloadDict, add, AddTerms),
                extract_whatif_facts(PayloadDict, remove, RemTerms),
                what_if(AddTerms, RemTerms, CompareResult),
                reply_json_dict(CompareResult)
            ),
            WhatIfError,
            (
                format(user_error, '~N[RETAIL ROUTES ERROR] What-if simulation failed: ~w~n', [WhatIfError]),
                reply_json_dict(_{
                    status: "error",
                    message: "Counterfactual what-if simulation failed"
                }, [status(400)])
            )
        )
    ).

% ==============================================================================
% 4. POST /retail/how — Deductive Causal Explanation (Via 1: How)
% ==============================================================================

%!  handle_retail_how(+Request) is det.
%
%   Produces step-by-step deductive trace for a fact (by fact_id or compound term).
handle_retail_how(Request) :-
    catch(
        http_read_json_dict(Request, PayloadDict),
        ReadError,
        (
            format(user_error, '~N[RETAIL ROUTES ERROR] Failed to parse how JSON: ~w~n', [ReadError]),
            reply_json_dict(_{
                status: "error",
                message: "Invalid JSON payload or missing required parameters"
            }, [status(400)]),
            !
        )
    ),
    (   var(PayloadDict)
    ->  true
    ;   (   get_dict(fact_id, PayloadDict, RawFactId)
        ->  (   integer(RawFactId) -> FactInput = RawFactId
            ;   atom(RawFactId), atom_number(RawFactId, FactInput), integer(FactInput)
            ;   string(RawFactId), number_string(FactInput, RawFactId), integer(FactInput)
            ;   FactInput = RawFactId
            )
        ;   get_dict(fact, PayloadDict, RawFact)
        ->  parse_fact_input(RawFact, FactInput)
        ;   FactInput = none
        ),
        (   FactInput \== none
        ->  catch(
                (
                    explain_how(FactInput, ExplanationList),
                    term_to_string_safe(FactInput, FactStr),
                    reply_json_dict(_{
                        status: "success",
                        fact: FactStr,
                        explanation: ExplanationList
                    })
                ),
                HowError,
                (
                    format(user_error, '~N[RETAIL ROUTES ERROR] explain_how failed: ~w~n', [HowError]),
                    reply_json_dict(_{
                        status: "error",
                        message: "Failed to generate how explanation"
                    }, [status(400)])
                )
            )
        ;   reply_json_dict(_{
                status: "error",
                message: "Missing required parameter 'fact_id' or 'fact'"
            }, [status(400)])
        )
    ).

% ==============================================================================
% 5. POST /retail/whynot — Failure Tree Analysis (Via 4: Why Not)
% ==============================================================================

%!  handle_retail_whynot(+Request) is det.
%
%   Analyzes why a target outcome (e.g. 'permitir', 'recusar', or 'decisao(permitir)')
%   failed to be concluded, recursing over unsatisfied candidate rule premises.
handle_retail_whynot(Request) :-
    catch(
        http_read_json_dict(Request, PayloadDict),
        ReadError,
        (
            format(user_error, '~N[RETAIL ROUTES ERROR] Failed to parse whynot JSON: ~w~n', [ReadError]),
            reply_json_dict(_{
                status: "error",
                message: "Invalid JSON payload or missing required parameters"
            }, [status(400)]),
            !
        )
    ),
    (   var(PayloadDict)
    ->  true
    ;   (   get_dict(fact, PayloadDict, RawFact)
        ->  FactRaw = RawFact
        ;   get_dict(decision, PayloadDict, RawDec)
        ->  FactRaw = RawDec
        ;   get_dict(outcome, PayloadDict, RawOut)
        ->  FactRaw = RawOut
        ;   FactRaw = none
        ),
        (   FactRaw \== none
        ->  catch(
                (
                    normalize_whynot_target(FactRaw, TargetFact),
                    explain_whynot(TargetFact, ExplanationList),
                    term_to_string_safe(TargetFact, FactStr),
                    reply_json_dict(_{
                        status: "success",
                        fact: FactStr,
                        explanation: ExplanationList
                    })
                ),
                WhyNotError,
                (
                    format(user_error, '~N[RETAIL ROUTES ERROR] explain_whynot failed: ~w~n', [WhyNotError]),
                    reply_json_dict(_{
                        status: "error",
                        message: "Invalid fact expression for whynot analysis"
                    }, [status(400)])
                )
            )
        ;   reply_json_dict(_{
                status: "error",
                message: "Missing required parameter 'fact' or 'decision'"
            }, [status(400)])
        )
    ).

% ==============================================================================
% 6. POST /retail/why — Dynamic Why Ask Explicability (Via 2: Why Ask)
% ==============================================================================

%!  handle_retail_why(+Request) is det.
%
%   Processes Why Ask explicability queries (Via 2: Why Ask).
%   Given an input premise code or attribute (e.g. "IN-001" or "mercado")
%   and optional base facts from the current return evaluation session,
%   dynamically determines candidate dependent rules, active waiting rules,
%   and normative causal justification.
handle_retail_why(Request) :-
    read_json_or_empty(Request, PayloadDict, StatusCode),
    (   StatusCode =:= 400
    ->  reply_json_dict(_{
            status: "error",
            message: "Invalid JSON payload"
        }, [status(400)])
    ;   extract_why_dado(PayloadDict, DadoRaw),
        (   DadoRaw == none
        ->  reply_json_dict(_{
                status: "error",
                message: "Missing required parameter 'dado' or 'codigo'"
            }, [status(400)])
        ;   extract_why_base_facts(PayloadDict, BaseFacts),
            catch(
                (
                    explain_why_premise(DadoRaw, BaseFacts, ResponseDict),
                    reply_json_dict(ResponseDict)
                ),
                WhyError,
                (
                    format(user_error, '~N[RETAIL ROUTES ERROR] explain_why_premise failed: ~w~n', [WhyError]),
                    reply_json_dict(_{
                        status: "error",
                        message: "Explain why processing failed"
                    }, [status(500)])
                )
            )
        )
    ).

extract_why_dado(PayloadDict, Dado) :-
    (   get_dict(dado, PayloadDict, D) -> Dado = D
    ;   get_dict(codigo, PayloadDict, D) -> Dado = D
    ;   get_dict(attribute, PayloadDict, D) -> Dado = D
    ;   get_dict(dado_codigo, PayloadDict, D) -> Dado = D
    ;   get_dict(input, PayloadDict, D) -> Dado = D
    ;   Dado = none
    ).

extract_why_base_facts(PayloadDict, BaseFacts) :-
    (   get_dict(base_facts, PayloadDict, Raw)
    ->  dict_to_retail_facts(Raw, BaseFacts)
    ;   get_dict(facts, PayloadDict, Raw)
    ->  dict_to_retail_facts(Raw, BaseFacts)
    ;   get_dict(initial_facts, PayloadDict, Raw)
    ->  dict_to_retail_facts(Raw, BaseFacts)
    ;   BaseFacts = []
    ).

% ==============================================================================
% 6. GET /retail/facts — Memory Inspection
% ==============================================================================

%!  handle_retail_facts(+Request) is det.
%
%   Retrieves all facts currently asserted in the retail engine session.
handle_retail_facts(_Request) :-
    get_all_facts(FactsList),
    length(FactsList, FactsCount),
    reply_json_dict(_{
        status: "success",
        facts_count: FactsCount,
        facts: FactsList
    }).

% ==============================================================================
% 7. POST /retail/reset — Session Reset
% ==============================================================================

%!  handle_retail_reset(+Request) is det.
%
%   Resets the retail engine working memory and dialogic session state.
handle_retail_reset(Request) :-
    read_json_or_empty(Request, _Dict, _StatusCode),
    reset_engine,
    clear_dialogue_log,
    clear_mock_answers,
    load_knowledge_base(retail_rules),
    reply_json_dict(_{
        status: "success",
        message: "Retail inference engine session reset"
    }).

% ==============================================================================
% Helpers: Decision Mapping
% ==============================================================================

%!  uncertainty_advice(-Advice) is det.
%
%   Read-only MYCIN advisor. A failure here must not change the decision
%   already computed, so the handler still returns the deterministic verdict
%   with a neutral certainty object.
uncertainty_advice(Advice) :-
    catch(manager_exception_advice(Advice), _, fail),
    !.
uncertainty_advice(_{
    final_cf: 0.0,
    linguistic_label: "Unknown / Borderline Manager Call (Inconclusivo / Critério Estrito)",
    cf_factors_fired: [],
    cf_trace: [],
    context: "auxiliary",
    source: "EX-001"
}).

%!  map_canonical_decision(+PrologDecision, -CanonicalDecision) is det.
%
%   Maps Prolog retail decision atoms into canonical DTO DecisionEnum strings.
map_canonical_decision(permitir, Canonical) :-
    (   ( facto(_, meio_reembolso(vale_loja))
        ; facto(_, meio_reembolso(cartao_oferta))
        ; facto(_, meio_reembolso(credito_loja))
        ; facto(_, tipo_transacao(troca_ou_credito)) )
    ->  Canonical = "store_credit_only"
    ;   Canonical = "approved"
    ),
    !.
map_canonical_decision(recusar, "rejected") :- !.
map_canonical_decision(rever, "manager_override") :- !.
map_canonical_decision(encaminhar, "manager_override") :- !.
map_canonical_decision(troca_direta, "approved") :- !.
map_canonical_decision(vale_loja, "store_credit_only") :- !.
% No rule decided: the case needs management judgement, never a refusal without a justifying rule
map_canonical_decision(nao_concluido, "manager_override") :- !.
map_canonical_decision(approved, "approved") :- !.
map_canonical_decision(rejected, "rejected") :- !.
map_canonical_decision(manager_override, "manager_override") :- !.
map_canonical_decision(store_credit_only, "store_credit_only") :- !.
map_canonical_decision(Other, OtherStr) :-
    term_to_string_safe(Other, OtherStr).

normalize_whynot_target(approved, decisao(permitir)) :- !.
normalize_whynot_target("approved", decisao(permitir)) :- !.
normalize_whynot_target(rejected, decisao(recusar)) :- !.
normalize_whynot_target("rejected", decisao(recusar)) :- !.
normalize_whynot_target(manager_override, decisao(rever)) :- !.
normalize_whynot_target("manager_override", decisao(rever)) :- !.
normalize_whynot_target(permitir, decisao(permitir)) :- !.
normalize_whynot_target("permitir", decisao(permitir)) :- !.
normalize_whynot_target(recusar, decisao(recusar)) :- !.
normalize_whynot_target("recusar", decisao(recusar)) :- !.
normalize_whynot_target(rever, decisao(rever)) :- !.
normalize_whynot_target("rever", decisao(rever)) :- !.
normalize_whynot_target(encaminhar, decisao(encaminhar)) :- !.
normalize_whynot_target("encaminhar", decisao(encaminhar)) :- !.
normalize_whynot_target(Raw, Target) :-
    parse_fact_input(Raw, Target).

% ==============================================================================
% Helpers: JSON to Facts Serialization
% ==============================================================================

%!  dict_to_retail_facts(+DictOrList, -FactsList) is det.
%
%   Translates arbitrary JSON dicts (flat, nested, or explicit 'facts' lists)
%   or a list of fact terms/strings into native Prolog domain facts.
dict_to_retail_facts(List, FactsList) :-
    is_list(List),
    !,
    maplist(parse_fact_input, List, FactsList).
dict_to_retail_facts(Dict, FactsList) :-
    (   get_dict(facts, Dict, RawFacts), is_list(RawFacts)
    ->  maplist(parse_fact_input, RawFacts, FactsList)
    ;   get_dict(initial_facts, Dict, RawFacts), is_list(RawFacts)
    ->  maplist(parse_fact_input, RawFacts, FactsList)
    ;   dict_pairs(Dict, _, Pairs),
        pairs_to_facts(Pairs, FactsList)
    ).

pairs_to_facts([], []).
pairs_to_facts([Key-Val|Rest], Facts) :-
    (   member(Key, [scenario, status, message, mode])
    ->  % Ignored operational fields
        pairs_to_facts(Rest, Facts)
    ;   is_dict(Val)
    ->  % Nested structure (e.g. item, compra, purchase)
        dict_pairs(Val, _, SubPairs),
        pairs_to_facts(SubPairs, SubFacts),
        pairs_to_facts(Rest, RestFacts),
        append(SubFacts, RestFacts, Facts)
    ;   is_list(Val), member(Key, [facts, initial_facts])
    ->  maplist(parse_fact_input, Val, SubFacts),
        pairs_to_facts(Rest, RestFacts),
        append(SubFacts, RestFacts, Facts)
    ;   pair_to_fact(Key, Val, FactTerm)
    ->  pairs_to_facts(Rest, RestFacts),
        Facts = [FactTerm|RestFacts]
    ;   pairs_to_facts(Rest, Facts)
    ).

pair_to_fact(Key, Val, FactTerm) :-
    normalize_attr_name(Key, AttrAtom),
    normalize_attr_value(Val, NormVal),
    FactTerm =.. [AttrAtom, NormVal].

normalize_attr_name(KeyAtom, Normalized) :-
    atom_string(KeyAtom, Str),
    camel_to_snake(Str, SnakeStr),
    downcase_atom_string(SnakeStr, LowerSnake),
    atom_string(RawAtom, LowerSnake),
    map_attribute_alias(RawAtom, Normalized).

map_attribute_alias(days_since_purchase, dias_desde_compra) :- !.
map_attribute_alias(dayssincepurchase, dias_desde_compra) :- !.
map_attribute_alias(payment_method, meio_pagamento) :- !.
map_attribute_alias(paymentmethod, meio_pagamento) :- !.
map_attribute_alias(channel, canal_compra) :- !.
map_attribute_alias(canal, canal_compra) :- !.
map_attribute_alias(category, categoria_produto) :- !.
map_attribute_alias(categoria, categoria_produto) :- !.
map_attribute_alias(condition, estado_produto) :- !.
map_attribute_alias(estado, estado_produto) :- !.
map_attribute_alias(proof, comprovativo) :- !.
map_attribute_alias(receipt, comprovativo) :- !.
map_attribute_alias(transaction_value, valor_transacao) :- !.
map_attribute_alias(has_tags, etiquetas_preservadas) :- !.
map_attribute_alias(is_underwear, categoria_produto_bodywear) :- !.
map_attribute_alias(A, A).

normalize_attr_value(Val, NormVal) :-
    (   Val == true -> NormVal = true
    ;   Val == false -> NormVal = false
    ;   number(Val) -> NormVal = Val
    ;   atom(Val) -> atom_string(Val, S), downcase_atom_string(S, LowS), atom_string(Atom, LowS), map_value_alias(Atom, NormVal)
    ;   string(Val) -> downcase_atom_string(Val, LowS), atom_string(Atom, LowS), map_value_alias(Atom, NormVal)
    ;   NormVal = Val
    ).

map_value_alias(recibo_original, recibo_impresso) :- !.
map_value_alias(recibooriginal, recibo_impresso) :- !.
map_value_alias(cartao_credito, credito) :- !.
map_value_alias(cartaocredito, credito) :- !.
map_value_alias(credit_card, credito) :- !.
map_value_alias(cartao_debito, debito) :- !.
map_value_alias(debit_card, debito) :- !.
map_value_alias(sem_comprovativo, nenhum) :- !.
map_value_alias(no_receipt, nenhum) :- !.
map_value_alias(V, V).

camel_to_snake(Str, Snake) :-
    string_chars(Str, Chars),
    chars_to_snake(Chars, SnakeChars),
    string_chars(Snake, SnakeChars).

chars_to_snake([], []).
chars_to_snake([C|Rest], [C1|SnakeRest]) :-
    char_type(C, upper),
    !,
    downcase_atom(C, LowC),
    atom_chars(LowC, [C1]),
    chars_to_snake(Rest, SubRest),
    (   Rest \== []
    ->  SnakeRest = ['_'|SubRest]
    ;   SnakeRest = SubRest
    ).
chars_to_snake([C|Rest], [C|SnakeRest]) :-
    chars_to_snake(Rest, SnakeRest).

downcase_atom_string(In, Out) :-
    atom_string(Atom, In),
    downcase_atom(Atom, LowAtom),
    atom_string(LowAtom, Out).

parse_fact_input(Input, Term) :-
    (   compound(Input)
    ->  normalize_compound_fact(Input, Term)
    ;   atom(Input)
    ->  (   catch(term_string(T, Input), _, fail)
        ->  normalize_compound_fact(T, Term)
        ;   Term = Input
        )
    ;   string(Input)
    ->  (   catch(term_string(T, Input), _, fail)
        ->  normalize_compound_fact(T, Term)
        ;   atom_string(Atom, Input), Term = Atom
        )
    ;   is_dict(Input)
    ->  (   get_dict(name, Input, Name), get_dict(value, Input, Val)
        ->  normalize_attr_name(Name, Attr),
            normalize_attr_value(Val, NormVal),
            Term =.. [Attr, NormVal]
        ;   Term = Input
        )
    ;   Term = Input
    ).

normalize_compound_fact(TermIn, TermOut) :-
    compound(TermIn),
    TermIn =.. [Functor, Arg],
    normalize_attr_name(Functor, NormFunctor),
    normalize_attr_value(Arg, NormArg),
    !,
    TermOut =.. [NormFunctor, NormArg].
normalize_compound_fact(T, T).

term_to_string_safe(Term, String) :-
    (   string(Term) -> String = Term
    ;   atom(Term) -> atom_string(Term, String)
    ;   term_string(Term, String)
    ).

% ==============================================================================
% Helpers: Interactive & What-If Utilities
% ==============================================================================

process_interactive_answers(Payload) :-
    clear_mock_answers,
    (   get_dict(answers, Payload, Answers)
    ->  register_answers_dict_or_list(Answers)
    ;   get_dict(mock_answers, Payload, MockAnswers)
    ->  register_answers_dict_or_list(MockAnswers)
    ;   get_dict(answer, Payload, SingleAnswer)
    ->  register_answers_dict_or_list([SingleAnswer])
    ;   true
    ).

register_answers_dict_or_list(Dict) :-
    is_dict(Dict),
    !,
    dict_pairs(Dict, _, Pairs),
    maplist(register_pair_answer, Pairs).
register_answers_dict_or_list(List) :-
    is_list(List),
    !,
    maplist(register_single_answer, List).
register_answers_dict_or_list(_).

register_pair_answer(Key-Val) :-
    normalize_attr_name(Key, Attr),
    normalize_attr_value(Val, NormVal),
    Template =.. [Attr, _],
    add_mock_answer(Template, NormVal).

register_single_answer(AnswerItem) :-
    (   is_dict(AnswerItem),
        get_dict(attribute, AnswerItem, AttrRaw),
        get_dict(value, AnswerItem, ValRaw)
    ->  normalize_attr_name(AttrRaw, Attr),
        normalize_attr_value(ValRaw, NormVal),
        Template =.. [Attr, _],
        add_mock_answer(Template, NormVal)
    ;   parse_fact_input(AnswerItem, FactTerm),
        compound(FactTerm)
    ->  functor(FactTerm, Functor, Arity),
        functor(Template, Functor, Arity),
        arg(1, FactTerm, Val),
        add_mock_answer(Template, Val)
    ;   true
    ).

extract_initial_facts_interactive(Payload, Facts) :-
    (   get_dict(initial_facts, Payload, Raw)
    ->  maplist(parse_fact_input, Raw, Facts)
    ;   get_dict(facts, Payload, Raw)
    ->  maplist(parse_fact_input, Raw, Facts)
    ;   Facts = []
    ).

format_dialogue_log([], []).
format_dialogue_log([asked(Template, Text)|Rest], [_{type: "asked", attribute: AttrStr, question: Text}|RestFormatted]) :-
    term_to_string_safe(Template, AttrStr),
    format_dialogue_log(Rest, RestFormatted).
format_dialogue_log([answered(Template, Resp)|Rest], [_{type: "answered", attribute: AttrStr, answer: RespStr}|RestFormatted]) :-
    term_to_string_safe(Template, AttrStr),
    term_to_string_safe(Resp, RespStr),
    format_dialogue_log(Rest, RestFormatted).
format_dialogue_log([unknown(Template)|Rest], [_{type: "unknown", attribute: AttrStr}|RestFormatted]) :-
    term_to_string_safe(Template, AttrStr),
    format_dialogue_log(Rest, RestFormatted).
format_dialogue_log([why_asked(Template, RuleId, Obj, Exp)|Rest], [_{type: "why_asked", attribute: AttrStr, rule_id: RuleId, objective: Obj, explanation: Exp}|RestFormatted]) :-
    term_to_string_safe(Template, AttrStr),
    format_dialogue_log(Rest, RestFormatted).
format_dialogue_log([Other|Rest], [_{type: "other", raw: OtherStr}|RestFormatted]) :-
    term_to_string_safe(Other, OtherStr),
    format_dialogue_log(Rest, RestFormatted).

find_next_pending_question(RawLog, Pending) :-
    % Locate the last asked or unknown entry
    reverse(RawLog, RevLog),
    (   member(Entry, RevLog),
        ( Entry = asked(Template, QuestionText) ; Entry = unknown(Template) )
    ->  (   Entry = asked(Template, QuestionText)
        ->  true
        ;   formatar_pergunta(Template, QuestionText)
        ),
        term_to_string_safe(Template, AttrStr),
        (   retail_engine:regra_ativa(RuleId, Objective)
        ->  explicar_porque_pergunta(RuleId, WhyText)
        ;   RuleId = none, Objective = none, WhyText = "A regra ativa investiga este atributo para determinar a decisão de devolução."
        ),
        Pending = _{
            attribute: AttrStr,
            prompt: QuestionText,
            rule_active: RuleId,
            objective: Objective,
            why: WhyText
        }
    ;   Pending = _{
            attribute: "none",
            prompt: "Sem perguntas pendentes.",
            rule_active: none,
            why: ""
        }
    ).

setup_whatif_base_facts(Payload) :-
    (   get_dict(base_facts, Payload, BaseFactsRaw)
    ->  dict_to_retail_facts(BaseFactsRaw, BaseFacts),
        evaluate_facts(BaseFacts, _)
    ;   true
    ).

extract_whatif_facts(Payload, Key, Terms) :-
    (   get_dict(Key, Payload, RawList)
    ->  (   is_list(RawList)
        ->  maplist(parse_fact_input, RawList, Terms)
        ;   is_dict(RawList)
        ->  dict_to_retail_facts(RawList, Terms)
        ;   parse_fact_input(RawList, Single), Terms = [Single]
        )
    ;   Terms = []
    ).

read_json_or_empty(Request, Dict, StatusCode) :-
    catch(
        (   http_read_json_dict(Request, Dict),
            StatusCode = 200
        ),
        Error,
        (   (   Error = error(syntax_error(json(unexpected_end_of_file)), _)
            ->  Dict = _{},
                StatusCode = 200
            ;   format(user_error, '~N[RETAIL ROUTES ERROR] Failed to parse JSON: ~w~n', [Error]),
                Dict = _{},
                StatusCode = 400
            )
        )
    ).
