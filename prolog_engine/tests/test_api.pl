:- module(test_api, [
    run_api_tests/0
]).

/** <module> Automated Integration Tests for HTTP API Layer
 *
 * Validates the REST API endpoints, JSON serialization/deserialization,
 * server startup/shutdown lifecycle, and error handling.
 */

:- use_module(library(plunit)).
:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).

:- use_module('../src/api/server', [server_start/1, server_stop/1]).
:- use_module('../src/api/routes', [handle_evaluate/1]).
:- use_module('../src/main', [get_port/1]).

% Define test port separate from default
test_port(8989).

:- begin_tests(api_integration, [
    setup((test_port(Port), server_start(Port))),
    cleanup((test_port(Port), server_stop(Port)))
]).

test(post_evaluate_approved) :-
    test_port(Port),
    format(atom(Url), 'http://127.0.0.1:~w/evaluate', [Port]),
    http_post(Url, json(_{scenario: "test", value: 42}), Reply, [json_object(dict)]),
    assertion(Reply.status == "success"),
    assertion(Reply.decision == "approved"),
    assertion(Reply.justification == ["Value is 42", "Dummy rule matched"]).

test(post_evaluate_rejected_value_mismatch) :-
    test_port(Port),
    format(atom(Url), 'http://127.0.0.1:~w/evaluate', [Port]),
    http_post(Url, json(_{scenario: "test", value: 15}), Reply, [json_object(dict)]),
    assertion(Reply.status == "success"),
    assertion(Reply.decision == "rejected"),
    assertion(Reply.justification == ["Value is not 42", "Default fallback rule applied"]).

test(post_evaluate_rejected_missing_value) :-
    test_port(Port),
    format(atom(Url), 'http://127.0.0.1:~w/evaluate', [Port]),
    http_post(Url, json(_{scenario: "test"}), Reply, [json_object(dict)]),
    assertion(Reply.status == "success"),
    assertion(Reply.decision == "rejected"),
    assertion(Reply.justification == ["Missing 'value' field in scenario", "Default fallback rule applied"]).

test(post_evaluate_malformed_json, [throws(error(existence_error(url, _), context(_, status(400, _))))]) :-
    test_port(Port),
    format(atom(Url), 'http://127.0.0.1:~w/evaluate', [Port]),
    http_post(Url, string('application/json', "invalid { json"), _Reply, []).

:- end_tests(api_integration).

:- begin_tests(main_bootstrap).

test(default_port_fallback) :-
    get_port(Port),
    assertion(integer(Port)),
    assertion(Port > 0).

:- end_tests(main_bootstrap).

run_api_tests :-
    run_tests([api_integration, main_bootstrap]).
