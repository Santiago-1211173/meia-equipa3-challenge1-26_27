:- module(inference_routes, [
    handle_inference_load/1,
    handle_inference_run/1,
    handle_inference_facts/1,
    handle_inference_how/1,
    handle_inference_whynot/1,
    handle_inference_reset/1
]).

/** <module> Academic Example Engine HTTP Routing (sp_exp2.pl from Moodle)
 *
 * Exposes REST API endpoints for the professors' academic example forward-chaining
 * expert system inference engine (sp_exp2.pl from Moodle support files).
 * Provides handlers for:
 *   - POST /inference/load   : Loads a named knowledge base (e.g. vehicles)
 *   - POST /inference/run    : Executes forward-chaining deduction over loaded facts
 *   - GET  /inference/facts  : Lists all currently known facts
 *   - POST /inference/how    : Justifies how a fact was derived (como/1 in sp_exp2.pl)
 *   - POST /inference/whynot : Explains why a fact was not concluded (whynot/1 in sp_exp2.pl)
 *   - POST /inference/reset  : Resets the academic engine dynamic memory session
 */

:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module('../core/inference/engine', [
    load_knowledge_base/1,
    run_engine/1,
    get_all_facts/1,
    explain_how/2,
    explain_whynot/2,
    reset_engine/0
]).

% Register HTTP endpoints with http_dispatch
:- http_handler(root('inference/load'), handle_inference_load, [method(post)]).
:- http_handler(root('inference/run'), handle_inference_run, [method(post)]).
:- http_handler(root('inference/facts'), handle_inference_facts, [method(get)]).
:- http_handler(root('inference/how'), handle_inference_how, [method(post)]).
:- http_handler(root('inference/whynot'), handle_inference_whynot, [method(post)]).
:- http_handler(root('inference/reset'), handle_inference_reset, [method(post)]).

%!  handle_inference_load(+Request) is det.
%
%   HTTP handler for POST /inference/load.
%   Loads a knowledge base by name into the inference engine session.
%   Expects JSON body: `{"knowledge_base": "vehicles"}`.
handle_inference_load(Request) :-
    catch(
        http_read_json_dict(Request, Dict),
        ReadError,
        (
            format(user_error, '~N[INFERENCE ROUTES ERROR] Failed to parse request JSON: ~w~n', [ReadError]),
            reply_json_dict(_{
                status: "error",
                message: "Invalid JSON payload or missing required parameters"
            }, [status(400)]),
            !
        )
    ),
    (   var(Dict)
    ->  true
    ;   (   get_dict(knowledge_base, Dict, KBNameRaw),
            KBNameRaw \== ""
        ->  (   atom(KBNameRaw)
            ->  KBName = KBNameRaw
            ;   string(KBNameRaw)
            ->  atom_string(KBName, KBNameRaw)
            ;   term_to_atom(KBNameRaw, KBName)
            ),
            catch(
                (
                    load_knowledge_base(KBName),
                    get_all_facts(FactsList),
                    length(FactsList, InitialCount),
                    format(string(SuccessMsg), "Knowledge base '~w' loaded successfully", [KBName]),
                    reply_json_dict(_{
                        status: "success",
                        message: SuccessMsg,
                        initial_facts_count: InitialCount
                    })
                ),
                _LoadError,
                (
                    format(string(ErrMsg), "Knowledge base '~w' not found", [KBName]),
                    reply_json_dict(_{
                        status: "error",
                        message: ErrMsg
                    }, [status(400)])
                )
            )
        ;   reply_json_dict(_{
                status: "error",
                message: "Missing required parameter 'knowledge_base'"
            }, [status(400)])
        )
    ).

%!  handle_inference_run(+Request) is det.
%
%   HTTP handler for POST /inference/run.
%   Executes forward-chaining deduction over the currently loaded knowledge base.
%   Accepts empty body or empty JSON object `{}`.
handle_inference_run(Request) :-
    read_json_or_empty(Request, _Dict, StatusCode),
    (   StatusCode =:= 400
    ->  reply_json_dict(_{
            status: "error",
            message: "Invalid JSON payload"
        }, [status(400)])
    ;   catch(
            (
                run_engine(ResultDict),
                reply_json_dict(ResultDict)
            ),
            RunError,
            (
                format(user_error, '~N[INFERENCE ERROR] run_engine failed: ~w~n', [RunError]),
                reply_json_dict(_{
                    status: "error",
                    message: "Inference engine execution failed"
                }, [status(500)])
            )
        )
    ).

%!  handle_inference_facts(+Request) is det.
%
%   HTTP handler for GET /inference/facts.
%   Returns a list of all facts currently present in the dynamic knowledge base.
handle_inference_facts(_Request) :-
    get_all_facts(FactsList),
    length(FactsList, FactsCount),
    reply_json_dict(_{
        status: "success",
        facts_count: FactsCount,
        facts: FactsList
    }).

%!  handle_inference_how(+Request) is det.
%
%   HTTP handler for POST /inference/how.
%   Produces a step-by-step reasoning trace explaining how a fact was derived.
%   Expects JSON body: `{"fact_id": 4}`.
handle_inference_how(Request) :-
    catch(
        http_read_json_dict(Request, Dict),
        ReadError,
        (
            format(user_error, '~N[INFERENCE ROUTES ERROR] Failed to parse request JSON: ~w~n', [ReadError]),
            reply_json_dict(_{
                status: "error",
                message: "Invalid JSON payload or missing required parameters"
            }, [status(400)]),
            !
        )
    ),
    (   var(Dict)
    ->  true
    ;   (   get_dict(fact_id, Dict, RawFactId),
            (   integer(RawFactId)
            ->  FactId = RawFactId
            ;   atom(RawFactId), atom_number(RawFactId, FactId), integer(FactId)
            ;   string(RawFactId), number_string(FactId, RawFactId), integer(FactId)
            )
        ->  explain_how(FactId, ExplanationList),
            reply_json_dict(_{
                status: "success",
                fact_id: FactId,
                explanation: ExplanationList
            })
        ;   reply_json_dict(_{
                status: "error",
                message: "Missing or invalid required parameter 'fact_id'"
            }, [status(400)])
        )
    ).

%!  handle_inference_whynot(+Request) is det.
%
%   HTTP handler for POST /inference/whynot.
%   Explains why a candidate fact was not derived, detailing failed premises.
%   Expects JSON body: `{"fact": "classe(meu_veiculo,ligeiro)"}`.
handle_inference_whynot(Request) :-
    catch(
        http_read_json_dict(Request, Dict),
        ReadError,
        (
            format(user_error, '~N[INFERENCE ROUTES ERROR] Failed to parse request JSON: ~w~n', [ReadError]),
            reply_json_dict(_{
                status: "error",
                message: "Invalid JSON payload or missing required parameters"
            }, [status(400)]),
            !
        )
    ),
    (   var(Dict)
    ->  true
    ;   (   get_dict(fact, Dict, FactStr),
            FactStr \== ""
        ->  catch(
                (
                    explain_whynot(FactStr, ExplanationList),
                    (   string(FactStr)
                    ->  FactOutput = FactStr
                    ;   term_string(FactStr, FactOutput)
                    ),
                    reply_json_dict(_{
                        status: "success",
                        fact: FactOutput,
                        explanation: ExplanationList
                    })
                ),
                WhyNotError,
                (
                    format(user_error, '~N[INFERENCE ROUTES ERROR] explain_whynot failed: ~w~n', [WhyNotError]),
                    reply_json_dict(_{
                        status: "error",
                        message: "Invalid fact expression"
                    }, [status(400)])
                )
            )
        ;   reply_json_dict(_{
                status: "error",
                message: "Missing required parameter 'fact'"
            }, [status(400)])
        )
    ).

%!  handle_inference_reset(+Request) is det.
%
%   HTTP handler for POST /inference/reset.
%   Clears dynamic facts, justifications, and rule declarations from memory.
%   Accepts empty body or empty JSON object `{}`.
handle_inference_reset(Request) :-
    read_json_or_empty(Request, _Dict, _StatusCode),
    reset_engine,
    reply_json_dict(_{
        status: "success",
        message: "Inference engine session reset"
    }).

%!  read_json_or_empty(+Request, -Dict, -StatusCode) is det.
%
%   Safely reads a JSON dictionary from the HTTP request, permitting empty bodies.
%   Returns StatusCode 200 on success or empty body, or 400 if malformed JSON is supplied.
read_json_or_empty(Request, Dict, StatusCode) :-
    catch(
        (   http_read_json_dict(Request, Dict),
            StatusCode = 200
        ),
        Error,
        (   (   Error = error(syntax_error(json(unexpected_end_of_file)), _)
            ->  Dict = _{},
                StatusCode = 200
            ;   format(user_error, '~N[INFERENCE ROUTES ERROR] Failed to parse request JSON: ~w~n', [Error]),
                Dict = _{},
                StatusCode = 400
            )
        )
    ).
