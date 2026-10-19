:- encoding(utf8).
/*  Testes de aceitação: os 10 cenários de teste de esforço (docs/06), com os mesmos JSON e os
    mesmos resultados esperados do projeto Drools (CenariosEsforcoTest). É o conjunto de casos de
    teste partilhado pelos dois motores (Relatório Prévio, 2.2.3).
*/

:- use_module(library(plunit)).
:- use_module(verificador).

:- begin_tests(cenarios).

test('Existem os dez cenários') :-
    forall(between(1, 10, N), ler_cenario(N, _)).

test('Cenário cumpre o esperado', [forall(between(1, 10, N)), true(Falhas == [])]) :-
    ler_cenario(N, Json),
    verificar_cenario(Json, Falhas).

:- end_tests(cenarios).
