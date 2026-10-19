:- encoding(utf8).
/*  Executa todos os testes:

    swipl testes/executar.pl

    Termina com o código 0 se todos passarem e 1 caso contrário.
*/

:- use_module(library(plunit)).

:- load_files([ testes_cenarios,
                testes_m0_m3,
                testes_m4_online,
                testes_m6_transversais,
                testes_m7,
                testes_m8_m9,
                testes_explicacoes,
                testes_coerencia,
                testes_consola,
                testes_api
              ], [if(not_loaded)]).

:- initialization(main, main).

main :-
    (   run_tests
    ->  halt(0)
    ;   halt(1)
    ).
