:- encoding(utf8).
/*  Sistema pericial de devoluções e trocas Levi's — motor SWI-Prolog

    swipl main.pl                 inicia o servidor: interface web em http://localhost:8090/ e API REST
    swipl main.pl web             inicia o servidor e abre a interface no browser
    swipl main.pl consola         consulta interativa na consola
    swipl main.pl avaliar F.json  avalia um pedido em JSON e abre o menu de explicações

    A porta vem da variável PORT (por omissão 8090).
*/

:- use_module(library(www_browser)).
:- use_module(src/api/servidor).
:- use_module(src/interface/consola).

:- initialization(main, main).

porta(Porta) :-
    (   getenv('PORT', Texto), atom_number(Texto, Porta), integer(Porta), Porta > 0
    ->  true
    ;   Porta = 8090
    ).

main :-
    current_prolog_flag(argv, Argumentos),
    executar(Argumentos).

executar([consola|_]) :- !, consulta.
executar([avaliar, Ficheiro|_]) :- !, avaliar_ficheiro(Ficheiro).
executar([web|_]) :- !,
    servidor(Url),
    catch(www_open_url(Url), _, format("Abra ~w no browser.~n", [Url])),
    esperar.
executar(_) :-
    servidor(_),
    esperar.

servidor(Url) :-
    porta(Porta),
    iniciar_servidor(Porta),
    format(atom(Url), "http://localhost:~w/", [Porta]),
    format("~nSistema pericial (SWI-Prolog)~n"),
    format("  Interface: ~w~n", [Url]),
    format("  API REST:  ~wapi/v1~n", [Url]),
    format("Feche esta janela (ou Ctrl+C) para parar o servidor.~n").

esperar :- thread_get_message(_).
