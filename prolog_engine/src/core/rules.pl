:- module(rules, [
    evaluate_scenario/3
]).

/** <module> Core Logic and Business Rules (Domain Layer)
 *
 * This module provides the pure deductive reasoning engine for the returns
 * and exchanges diagnostic expert system. It defines the knowledge base
 * and business rules completely decoupled from transport protocols (HTTP)
 * and wire formats (JSON).
 *
 * Data interchange between the API layer and this core domain layer is achieved
 * using native SWI-Prolog Dicts (e.g. `_{scenario: "test", value: 42}`).
 */

%!  evaluate_scenario(+ScenarioDict, -Decision, -ExplanationList) is det.
%
%   Evaluates an input scenario represented as a native Prolog dict.
%   Deduces a categorical Decision and produces an explanatory list of
%   justification strings demonstrating the reasoning trace.
%
%   @param ScenarioDict    Native SWI-Prolog dict containing scenario facts.
%   @param Decision        Atom representing the evaluation outcome (`approved`, `rejected`, or `error`).
%   @param ExplanationList List of strings explaining why the decision was made (Explainability).
%

% Rule 1: Successful match when 'value' is equal to 42
evaluate_scenario(ScenarioDict, approved, ["Value is 42", "Dummy rule matched"]) :-
    is_dict(ScenarioDict),
    get_dict(value, ScenarioDict, Value),
    number(Value),
    Value =:= 42,
    !.

% Rule 2: Rejection fallback when 'value' is present but does not equal 42
evaluate_scenario(ScenarioDict, rejected, ["Value is not 42", "Default fallback rule applied"]) :-
    is_dict(ScenarioDict),
    get_dict(value, ScenarioDict, Value),
    ( \+ number(Value) ; Value =\= 42 ),
    !.

% Rule 3: Rejection fallback when 'value' field is missing from the scenario dict
evaluate_scenario(ScenarioDict, rejected, ["Missing 'value' field in scenario", "Default fallback rule applied"]) :-
    is_dict(ScenarioDict),
    \+ get_dict(value, ScenarioDict, _),
    !.

% Rule 4: Error fallback when input argument is not a valid Prolog dict
evaluate_scenario(_InvalidInput, error, ["Scenario payload is not a valid Prolog dictionary"]) :-
    !.
