:- module(test_retail_engine_phase1, [
    run_phase1_tests/0
]).

/** <module> PLUnit Tests for Phase 1: Retail Engine Isolation & Baseline Parity
 *
 * Validates:
 * 1. Coexistence of inference_engine (sp_exp2) and retail_engine without symbol collision.
 * 2. Independent dynamic memory states (asserts in one do not leak to the other).
 * 3. Independent reset_engine operations.
 * 4. Canonical DSL operator availability in retail_engine.
 */

:- use_module(library(plunit)).
:- use_module('../src/core/inference/engine', []).
:- use_module('../src/core/retail_engine/engine', []).

:- begin_tests(retail_engine_phase1_tests).

test(modules_load_coexist) :-
    current_module(inference_engine),
    current_module(retail_engine).

test(canonical_operators_defined_in_retail_engine) :-
    current_op(220, xfx, retail_engine:entao),
    current_op(35, xfy, retail_engine:se),
    current_op(240, fx, retail_engine:regra),
    current_op(500, fy, retail_engine:nao),
    current_op(600, xfy, retail_engine:e).

test(namespace_isolation_facts_and_reset) :-
    % 1. Load academic vehicles KB into inference_engine
    inference_engine:load_knowledge_base(vehicles),
    inference_engine:get_all_facts(AcadFacts),
    length(AcadFacts, AcadCount),
    assertion(AcadCount == 3),

    % 2. Reset and populate retail_engine
    retail_engine:reset_engine,
    retail_engine:get_all_facts(RetailFactsEmpty),
    assertion(RetailFactsEmpty == []),

    % Assert facts directly in retail_engine
    assertz(retail_engine:facto(1, in001_operator_id(op_123))),
    assertz(retail_engine:ultimo_facto(1)),
    retail_engine:get_all_facts(RetailFacts1),
    assertion(length(RetailFacts1, 1)),

    % 3. Verify academic inference_engine remains completely intact
    inference_engine:get_all_facts(AcadFactsAfter),
    assertion(AcadFactsAfter = AcadFacts),

    % 4. Reset retail_engine and verify inference_engine is untouched
    retail_engine:reset_engine,
    retail_engine:get_all_facts(RetailFactsReset),
    assertion(RetailFactsReset == []),
    inference_engine:get_all_facts(AcadFactsStillThere),
    assertion(AcadFactsStillThere = AcadFacts),

    % 5. Reset academic engine and verify retail_engine stays clean
    inference_engine:reset_engine,
    inference_engine:get_all_facts(AcadFactsCleared),
    assertion(AcadFactsCleared == []).

test(academic_inference_engine_execution_intact) :-
    inference_engine:load_knowledge_base(vehicles),
    inference_engine:run_engine(Result),
    assertion(Result.status == "success"),
    assertion(Result.derived_facts_count == 2),
    assertion(Result.total_facts == 5).

:- end_tests(retail_engine_phase1_tests).

run_phase1_tests :-
    run_tests([retail_engine_phase1_tests]).
