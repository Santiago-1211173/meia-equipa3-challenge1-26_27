:- module(main, [
    main/0,
    get_port/1
]).

/** <module> Application Entry Point (Bootstrap & Orchestration)
 *
 * This module orchestrates the startup of the Prolog inference micro-service.
 * It loads the transport (API) and domain (Core) layers, discovers the target
 * listening port from the environment, initializes the HTTP daemon, and maintains
 * the main thread alive to ensure continuous execution inside a container.
 */

:- use_module(api/server, [server_start/1, server_stop/1]).
:- use_module(api/routes, [handle_evaluate/1]).
:- use_module(core/rules, [evaluate_scenario/3]).

%!  get_port(-Port) is det.
%
%   Retrieves the HTTP port from the 'PORT' environment variable.
%   Falls back to 8080 if not set or if the value is not a valid positive integer.
get_port(Port) :-
    getenv('PORT', PortAtom),
    atom_number(PortAtom, Port),
    integer(Port),
    Port > 0,
    !.
get_port(8080).

%!  main is det.
%
%   Application entry point. Initiates the server and blocks on the main thread
%   until a termination signal or interruption occurs.
main :-
    get_port(Port),
    format('~N=================================================~n', []),
    format('  Prolog Inference Engine - REST API Microservice~n', []),
    format('  Retail Returns & Exchanges Diagnostic POC~n', []),
    format('=================================================~n', []),
    format('[MAIN] Initializing server on port ~w...~n', [Port]),
    server_start(Port),
    format('[MAIN] Microservice is ready to accept requests.~n', []),
    % Keep the process alive for Docker/daemon execution
    catch(
        thread_get_message(_),
        Signal,
        (
            format('~N[MAIN] Received signal (~w). Shutting down server on port ~w...~n', [Signal, Port]),
            server_stop(Port),
            halt(0)
        )
    ).

% Set default goal when executed as main script
:- initialization(main, main).
