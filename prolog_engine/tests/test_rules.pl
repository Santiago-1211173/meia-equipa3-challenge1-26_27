:- module(test_rules, [
    run_all_tests/0
]).

:- use_module(library(plunit)).
:- use_module('../src/core/rules.pl').

:- begin_tests(rules_evaluation).

test(approved_exact_42) :-
    Input = _{scenario: "test", value: 42},
    evaluate_scenario(Input, Decision, Explanations),
    assertion(Decision == approved),
    assertion(Explanations == ["Value is 42", "Dummy rule matched"]).

test(approved_float_42) :-
    Input = _{scenario: "test", value: 42.0},
    evaluate_scenario(Input, Decision, Explanations),
    assertion(Decision == approved),
    assertion(Explanations == ["Value is 42", "Dummy rule matched"]).

test(rejected_different_value) :-
    Input = _{scenario: "test", value: 15},
    evaluate_scenario(Input, Decision, Explanations),
    assertion(Decision == rejected),
    assertion(Explanations == ["Value is not 42", "Default fallback rule applied"]).

test(rejected_non_numeric_value) :-
    Input = _{scenario: "test", value: "hello"},
    evaluate_scenario(Input, Decision, Explanations),
    assertion(Decision == rejected),
    assertion(Explanations == ["Value is not 42", "Default fallback rule applied"]).

test(rejected_missing_value_field) :-
    Input = _{scenario: "test", other: 100},
    evaluate_scenario(Input, Decision, Explanations),
    assertion(Decision == rejected),
    assertion(Explanations == ["Missing 'value' field in scenario", "Default fallback rule applied"]).

test(error_invalid_dict_atom) :-
    Input = not_a_dict,
    evaluate_scenario(Input, Decision, Explanations),
    assertion(Decision == error),
    assertion(Explanations == ["Scenario payload is not a valid Prolog dictionary"]).

test(error_invalid_dict_list) :-
    Input = [scenario, test],
    evaluate_scenario(Input, Decision, Explanations),
    assertion(Decision == error),
    assertion(Explanations == ["Scenario payload is not a valid Prolog dictionary"]).

:- end_tests(rules_evaluation).

run_all_tests :-
    run_tests([rules_evaluation]).
