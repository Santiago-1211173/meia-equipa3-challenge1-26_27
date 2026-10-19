:- encoding(utf8).
:- module(verificador, [
    ler_cenario/2,              % +Numero, -Json
    verificar_cenario/2,        % +Json, -Falhas
    diretorio_cenarios/1
]).

/** <module> Verificação dos cenários de aceitação

Os 10 cenários de `docs/06-casos-teste.md` (cópia dos JSON do projeto Drools, com os resultados
esperados derivados de `docs/02`). A comparação segue o `CenariosEsforcoTest` do Drools:

  - cada campo esperado (elegibilidade, tipoVerificacao, ..., documentação) tem de coincidir;
  - `regrasDisparadas` têm de ter disparado (no pedido ou em algum artigo);
  - `regrasNaoDisparadas` não podem ter disparado;
  - por artigo: elegibilidade, tipoTransacao, destino, descontoSaldo, valor e regras do artigo.
*/

:- use_module(library(json)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module('../src/servico').
:- use_module('../src/motor/memoria').
:- use_module('../src/bc/pedido').

:- dynamic diretorio_/1.

:- prolog_load_context(directory, D), atom_concat(D, '/cenarios', C), assertz(diretorio_(C)).

diretorio_cenarios(D) :- diretorio_(D).

ler_cenario(N, Json) :-
    diretorio_(D),
    format(atom(F), '~w/cenario-~|~`0t~d~2+.json', [D, N]),
    setup_call_cleanup(open(F, read, In, [encoding(utf8)]),
                       json_read_dict(In, Json, [value_string_as(string)]),
                       close(In)).

%!  verificar_cenario(+Json, -Falhas) is det.
%
%   Avalia o pedido do cenário e devolve a lista das diferenças em relação ao esperado.
verificar_cenario(Json, Falhas) :-
    preparar_pedido(Json, Pedido, Fraudes),
    avaliar_pedido(Pedido, Fraudes),
    Esperado = Json.esperado,
    findall(F, falha_pedido(Esperado, F), F1),
    findall(F, falha_artigos(Esperado, F), F2),
    append(F1, F2, Falhas).

campo_pedido(elegibilidade).
campo_pedido(tipoVerificacao).
campo_pedido(tipoTransacao).
campo_pedido(baseValor).
campo_pedido(meioReembolso).
campo_pedido(aprovacao).
campo_pedido(processo).
campo_pedido(terminal).
campo_pedido(excecaoRecusada).

falha_pedido(Esperado, campo(Campo, esperado(E), obtido(O))) :-
    campo_pedido(Campo),
    get_dict(Campo, Esperado, E), E \== null,
    decisao(pedido, Campo, V), valor_json(V, O),
    \+ igual(E, O).
falha_pedido(Esperado, campo(valorDevolucao, esperado(E), obtido(O))) :-
    get_dict(valorDevolucao, Esperado, E), E \== null,
    decisao(pedido, valorDevolucao, O),
    \+ ( number(O), abs(O - E) < 0.005 ).
falha_pedido(Esperado, campo(Doc, esperado(E), obtido(O))) :-
    get_dict(documentacao, Esperado, Documentacao), Documentacao \== null,
    member(Nome, [idStylistAtribuido, reciboAgrafado, assinaturaTestemunha, retencaoAte]),
    get_dict(Nome, Documentacao, E), E \== null,
    atom_concat('documentacao.', Nome, Doc),
    decisao(pedido, Doc, V), ( string(V) -> O = V ; valor_json(V, O) ),
    \+ igual(E, O).
falha_pedido(Esperado, nao_disparou(Codigo)) :-
    get_dict(regrasDisparadas, Esperado, Lista), Lista \== null,
    codigos_disparados(Disparadas),
    member(C, Lista), atom_string(Codigo, C),
    \+ memberchk(Codigo, Disparadas).
falha_pedido(Esperado, disparou_indevidamente(Codigo)) :-
    get_dict(regrasNaoDisparadas, Esperado, Lista), Lista \== null,
    codigos_disparados(Disparadas),
    member(C, Lista), atom_string(Codigo, C),
    memberchk(Codigo, Disparadas).

falha_artigos(Esperado, artigo(Id, Falha)) :-
    get_dict(artigos, Esperado, Artigos), Artigos \== null,
    dict_pairs(Artigos, _, Pares),
    member(IdAtomo-EA, Pares),
    atom_string(IdAtomo, Id),
    falha_artigo(Id, EA, Falha).

falha_artigo(Id, EA, campo(Campo, esperado(E), obtido(O))) :-
    member(Campo, [elegibilidade, tipoTransacao, destino, descontoSaldo]),
    get_dict(Campo, EA, E), E \== null,
    decisao(artigo(Id), Campo, V), valor_json(V, O),
    \+ igual(E, O).
falha_artigo(Id, EA, campo(valorDevolucao, esperado(E), obtido(O))) :-
    get_dict(valorDevolucao, EA, E), E \== null,
    decisao(artigo(Id), valorDevolucao, O),
    \+ ( number(O), abs(O - E) < 0.005 ).
falha_artigo(Id, EA, nao_disparou(Codigo)) :-
    get_dict(regrasDisparadas, EA, Lista), Lista \== null,
    codigos_disparados_alvo(artigo(Id), Disparadas),
    member(C, Lista), atom_string(Codigo, C),
    \+ memberchk(Codigo, Disparadas).

igual(E, O) :- E == O, !.
igual(E, O) :- string(E), atom(O), atom_string(O, E), !.
igual(E, O) :- atom(E), string(O), atom_string(E, O), !.
igual(E, O) :- number(E), number(O), E =:= O.
