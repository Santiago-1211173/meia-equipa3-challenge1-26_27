:- encoding(utf8).
/*  Testes do modo interativo na consola, com as respostas do colaborador simuladas.
*/

:- use_module(library(plunit)).
:- use_module(suporte, [contem/2]).
:- use_module(verificador, [diretorio_cenarios/1]).
:- use_module('../src/interface/consola').
:- use_module('../src/motor/memoria', [decisao/3]).

%   Executa Objetivo com Entrada como texto escrito pelo colaborador e devolve o que foi mostrado.
com_entrada(Entrada, Objetivo, Saida) :-
    stream_property(Original, alias(user_input)),
    setup_call_cleanup(
        ( open_string(Entrada, In), set_stream(In, alias(user_input)) ),
        with_output_to(string(Saida), Objetivo),
        ( set_stream(Original, alias(user_input)), close(In) )).

cenario(N, F) :-
    diretorio_cenarios(D),
    format(atom(F), '~w/cenario-~|~`0t~d~2+.json', [D, N]).

:- begin_tests(consola).

test('Avaliar um ficheiro: pergunta a revenda (IN-010), explica e termina') :-
    cenario(1, F),
    com_entrada("porque\n\ncomo\nporque-nao OUT-001=PERMITIR\nporque IN-010\nsair\n", avaliar_ficheiro(F), Saida),
    contem(Saida, "IN-010"),
    contem(Saida, "Porquê?"),
    contem(Saida, "=== Decisão ==="),
    contem(Saida, "OUT-001 Elegibilidade (elegibilidade): REVER"),
    contem(Saida, "PC-002"),
    contem(Saida, "chegou a ser proposta por PT-003").

test('A resposta à revenda é usada e reavalia o pedido') :-
    cenario(1, F),
    com_entrada("sim\nsair\n", avaliar_ficheiro(F), Saida),
    contem(Saida, "OUT-001 Elegibilidade (elegibilidade): PERMITIR"),
    once(decisao(artigo("A-1"), elegibilidade, permitir)).

test('E se na consola repõe a avaliação original') :-
    cenario(4, F),
    com_entrada("e-se artigos[0].estado.embainhado=nao\nsair\n", avaliar_ficheiro(F), Saida),
    contem(Saida, "PC-006"),
    decisao(pedido, elegibilidade, recusar).

vazias(N, L) :- length(L, N), maplist(=(""), L).

test('Consulta completa por perguntas (valores por omissão)') :-
    %   Colaborador, loja e pedido (8 respostas por omissão), data do pedido, canal e comprovativo
    %   (9), data da compra, pagamento e produto (9), PVP, resto do artigo, cliente, exceção e fraude (14).
    vazias(8, V1), vazias(9, V2), vazias(9, V3), vazias(14, V4),
    append([V1, ["2026-03-31"], V2, ["2026-03-20"], V3, ["98"], V4, ["decisao", "sair", ""]], Linhas),
    atomic_list_concat(Linhas, '\n', Entrada),
    com_entrada(Entrada, consulta, Saida),
    contem(Saida, "=== Decisão ==="),
    contem(Saida, "OUT-001 Elegibilidade (elegibilidade): PERMITIR"),
    contem(Saida, "PT-003").

:- end_tests(consola).
