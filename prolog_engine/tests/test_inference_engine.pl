:- module(test_inference_engine, [
    run_all_tests/0
]).

/** <module> PLUnit Tests for the Core Inference Engine
 *
 * Validates knowledge base loading, forward-chaining deduction,
 * fact retrieval, explanation generation (how and why not),
 * state resets, and error handling for nonexistent knowledge bases.
 */

:- use_module(library(plunit)).
:- use_module('../src/core/inference/engine.pl').

:- begin_tests(inference_engine_tests).

test(load_vehicles_kb_success) :-
    load_knowledge_base(vehicles),
    get_all_facts(Facts),
    length(Facts, Count),
    assertion(Count == 3).

test(run_engine_derives_facts) :-
    load_knowledge_base(vehicles),
    run_engine(Result),
    assertion(Result.status == "success"),
    assertion(Result.initial_facts_count == 3),
    assertion(Result.derived_facts_count == 2),
    assertion(Result.total_facts == 5),
    assertion(length(Result.derived_facts, 2)).

test(get_all_facts_after_run) :-
    load_knowledge_base(vehicles),
    run_engine(_),
    get_all_facts(Facts),
    assertion(length(Facts, 5)),
    assertion(member(_{id: 1, fact: "lotacao(meu_veiculo,3)"}, Facts)),
    assertion(member(_{id: 2, fact: "peso(meu_veiculo,4500)"}, Facts)),
    assertion(member(_{id: 3, fact: "tipo(meu_veiculo,mercadorias)"}, Facts)),
    assertion(member(_{id: 4, fact: "classe(meu_veiculo,pesado)"}, Facts)),
    assertion(member(_{id: 5, fact: "pesado(meu_veiculo,camiao)"}, Facts)).

test(explain_how_derived_fact) :-
    load_knowledge_base(vehicles),
    run_engine(_),
    explain_how(4, Explanation),
    assertion(Explanation \== []),
    Explanation = [FirstLine|_],
    assertion(sub_string(FirstLine, _, _, _, "concluded by rule 6")).

test(explain_how_initial_fact) :-
    load_knowledge_base(vehicles),
    run_engine(_),
    explain_how(1, Explanation),
    assertion(Explanation \== []),
    Explanation = [Line|_],
    assertion(sub_string(Line, _, _, _, "was an initial fact")).

test(explain_whynot_false_premise) :-
    load_knowledge_base(vehicles),
    run_engine(_),
    explain_whynot(classe(meu_veiculo, ligeiro), Explanation),
    assertion(Explanation \== []),
    once((
        member(Line, Explanation),
        sub_string(Line, _, _, _, "rule 7")
    )).

test(reset_engine_clears_facts) :-
    load_knowledge_base(vehicles),
    run_engine(_),
    reset_engine,
    get_all_facts(Facts),
    assertion(Facts == []).

test(load_nonexistent_kb_fails_gracefully) :-
    catch(
        (load_knowledge_base(nonexistent_kb_for_test), Result = ok),
        error(existence_error(source_sink, _), _),
        Result = caught_expected_error
    ),
    assertion(Result == caught_expected_error).

:- end_tests(inference_engine_tests).

run_all_tests :-
    run_tests([inference_engine_tests]).
