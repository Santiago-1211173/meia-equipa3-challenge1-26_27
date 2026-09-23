:- module(server, [
    server_start/1,
    server_stop/1
]).

/** <module> HTTP Server Daemon Management (Transport Layer)
 *
 * This module is responsible for starting and stopping the multi-threaded
 * HTTP daemon in SWI-Prolog using `library(http/thread_httpd)` and
 * `library(http/http_dispatch)`.
 *
 * It isolates the server lifecycle and socket management from the endpoint
 * definitions and business domain logic.
 */

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).

%!  server_start(+Port) is det.
%
%   Starts the multi-threaded HTTP server daemon on the specified TCP port.
%
%   @param Port Port number (integer or numeric atom, e.g. 8080 or '8080').
server_start(Port) :-
    integer(Port),
    Port > 0,
    http_server(http_dispatch, [port(Port)]),
    format('~N[SERVER] Prolog HTTP server daemon successfully started on port ~w~n', [Port]),
    !.
server_start(Port) :-
    atom(Port),
    atom_number(Port, IntPort),
    integer(IntPort),
    IntPort > 0,
    server_start(IntPort),
    !.
server_start(InvalidPort) :-
    format(user_error, '~N[SERVER ERROR] Invalid port specified: ~w~n', [InvalidPort]),
    fail.

%!  server_stop(+Port) is det.
%
%   Stops the HTTP server daemon running on the specified TCP port.
%
%   @param Port Port number (integer or numeric atom).
server_stop(Port) :-
    integer(Port),
    http_stop_server(Port, []),
    format('~N[SERVER] Prolog HTTP server daemon stopped on port ~w~n', [Port]),
    !.
server_stop(Port) :-
    atom(Port),
    atom_number(Port, IntPort),
    integer(IntPort),
    server_stop(IntPort),
    !.
server_stop(InvalidPort) :-
    format(user_error, '~N[SERVER ERROR] Cannot stop server on invalid port: ~w~n', [InvalidPort]),
    fail.
