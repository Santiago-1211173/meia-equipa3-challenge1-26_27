:- encoding(utf8).
:- module(motor, [
    avaliar/2,                  % +Pedido, +Fraudes
    grupos/1,                   % -Grupos (agenda-groups pela ordem de avaliação)
    ordem_modulo/2,             % +Modulo, -Ordem
    regra_def/4,                % ?Nome, ?Condicoes, ?Acoes, ?Meta
    regra_info/2,               % ?Nome, ?Info (dict com id, modulo, prioridade, ...)
    regras_por_ordem/1,         % -Nomes (pela ordem de declaração)
    lhs_lista/2,                % +LHS, -Condicoes
    avaliar_condicao/1,         % +Condicao
    paragem/1,                  % ?CodigoRegra
    texto_mensagem/2,           % +Fragmentos, -Texto
    mais_severo/2,              % +Elegibilidade, +Elegibilidade
    limite_disparos/1
]).

/** <module> Motor de inferência (encadeamento progressivo com agenda)

Reproduz a semântica de execução do Drools usada no projeto Java:

  - **Agenda-groups:** os módulos são avaliados pela ordem de grupos/1 (TRANSVERSAL, M0 a M9,
    ONLINE entre M5 e M6), como o foco dado pelo `ExecutorSessao` (OrdemAgenda). Um grupo é
    avaliado até não ter ativações e não volta a ser avaliado.
  - **Resolução de conflitos:** em cada ciclo dispara a ativação de maior prioridade (`salience`);
    em empate, a regra declarada primeiro e, na mesma regra, o primeiro artigo do pedido.
    Depois de cada disparo as ativações são recalculadas (o estado mudou).
  - **Auto-focus:** as regras com `auto_foco` (EX-008, PC-008) passam à frente de qualquer grupo.
  - **Refração:** uma ativação (regra + ligações) só volta a disparar se uma das decisões que a
    regra lê tiver sido alterada depois do disparo (as versões das decisões fazem parte da
    chave), como um `modify` no Drools. Os ciclos evitam-se com as guardas naoDisparou/2.
  - **Limite:** mais de 1000 disparos indicam um ciclo nas regras (lança um erro).

A base de conhecimento (módulo `regras`) é separada do motor: as regras são termos
`regra Nome se Condicoes entao Acoes com Meta` e as condições são predicados do módulo `condicoes`.
*/

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(pairs)).
:- use_module(operadores).
:- use_module(memoria).
:- use_module('../bc/pedido', [valor_json/2, enum_json/2]).
:- use_module('../bc/condicoes', []).
:- use_module('../bc/regras', []).

:- dynamic catalogo_/2.            % catalogo_(Nome, Info), construído ao carregar
:- thread_local refratada_/3.       % refratada_(Nome, Ligacoes, Versoes)

limite_disparos(1000).

grupos([transversal, m0, m1, m2, m3, m4, m5, online, m6, m7, m8, m9]).

ordem_modulo(Modulo, Ordem) :-
    grupos(Gs),
    (   nth0(Ordem, Gs, Modulo) -> true ; Ordem = 99 ).

paragem('HS-001').
paragem('HS-002').
paragem('HS-003').
paragem('HS-004').
paragem('HS-006').
paragem('CH-007').
paragem('CH-008').

% ---------------------------------------------------------------------------------------------
% Catálogo das regras
% ---------------------------------------------------------------------------------------------

%!  regra_def(?Nome, ?Condicoes, ?Acoes, ?Meta) is nondet.
regra_def(Nome, LHS, RHS, Meta) :-
    regras:(regra Nome se LHS entao RHS com Meta).

%!  regra_info(?Nome, ?Info) is nondet.
%
%   Metadados de uma regra: dict com id, nome, modulo, prioridade, ordem, auto_foco, conclusoes,
%   descricao, a_validar (a descrição tem "[a validar: ...]"), sem_guarda (a regra não tem a
%   guarda do fluxo terminado) e de_artigo (a regra é avaliada por artigo).
regra_info(Nome, Info) :-
    catalogo_(Nome, Info).

regras_por_ordem(Nomes) :-
    findall(O-N, ( catalogo_(N, I), O = I.ordem ), Pares0),
    keysort(Pares0, Pares),
    pairs_values(Pares, Nomes).

construir_catalogo :-
    retractall(catalogo_(_, _)),
    findall(Nome-LHS-Meta, regra_def(Nome, LHS, _, Meta), Regras),
    foldl(registar_regra, Regras, 0, _).

registar_regra(Nome-LHS-Meta, Ordem0, Ordem) :-
    Ordem is Ordem0 + 1,
    (   memberchk(id(Id), Meta) -> true ; codigo_do_nome(Nome, Id) ),
    must_be(atom, Id),
    (   memberchk(modulo(Modulo), Meta) -> true
    ;   throw(error(domain_error(regra_com_modulo, Nome), _))
    ),
    option_meta(prioridade(Prioridade), Meta, 0),
    option_meta(conclusoes(Conclusoes), Meta, []),
    option_meta(descricao(Descricao), Meta, ""),
    ( memberchk(auto_foco, Meta) -> AutoFoco = true ; AutoFoco = false ),
    ( sub_string(Descricao, _, _, _, "[a validar") -> AValidar = true ; AValidar = false ),
    lhs_lista(LHS, Condicoes),
    (   ( memberchk(pedidoAtivo, Condicoes) ; memberchk(artigoAtivo(_), Condicoes) )
    ->  SemGuarda = false
    ;   SemGuarda = true
    ),
    ( memberchk(artigo(_), Condicoes) -> DeArtigo = true ; DeArtigo = false ),
    Info = info{id:Id, nome:Nome, modulo:Modulo, prioridade:Prioridade, ordem:Ordem,
                auto_foco:AutoFoco, conclusoes:Conclusoes, descricao:Descricao,
                a_validar:AValidar, sem_guarda:SemGuarda, de_artigo:DeArtigo},
    assertz(catalogo_(Nome, Info)).

option_meta(Opcao, Meta, Omissao) :-
    (   memberchk(Opcao, Meta)
    ->  true
    ;   arg(1, Opcao, Omissao)
    ).

codigo_do_nome(Nome, Id) :-
    atom_string(Nome, S),
    split_string(S, " ", "", [Primeira|_]),
    atom_string(Id, Primeira).

:- initialization(construir_catalogo).

% ---------------------------------------------------------------------------------------------
% Avaliação
% ---------------------------------------------------------------------------------------------

%!  avaliar(+Pedido, +Fraudes) is det.
%
%   Avalia um pedido normalizado (pedido:normalizar_pedido/2) com os indícios de fraude
%   (lista de fraude(Descricao, Nivel)). O resultado fica na memória de trabalho (memoria).
avaliar(Pedido, Fraudes) :-
    iniciar_memoria(Pedido, Fraudes),
    retractall(refratada_(_, _, _)),
    grupos(Grupos),
    foldl(avaliar_grupo, Grupos, 0, _).

avaliar_grupo(Grupo, N0, N) :-
    ciclo(Grupo, [], N0, N).

ciclo(Grupo, Anteriores, N0, N) :-
    ativacoes(Grupo, Ativacoes),
    pairs_keys_values_(Ativacoes, Chaves),
    forall(( member(K, Chaves), \+ memberchk(K, Anteriores) ), evento_ativacao(criada, K)),
    forall(( member(K, Anteriores), \+ memberchk(K, Chaves) ), evento_ativacao(cancelada, K)),
    (   Ativacoes = [Primeira|_]
    ->  disparar(Primeira),
        N1 is N0 + 1,
        limite_disparos(Limite),
        (   N1 >= Limite
        ->  throw(error(limite_disparos(N1), 'Possível ciclo nas regras'))
        ;   true
        ),
        Primeira = ativacao(NomeP, LigP, _),
        subtract(Chaves, [NomeP-LigP], Restantes),
        ciclo(Grupo, Restantes, N1, N)
    ;   N = N0
    ).

pairs_keys_values_(Ativacoes, Chaves) :-
    findall(Nome-Lig, member(ativacao(Nome, Lig, _), Ativacoes), Chaves).

evento_ativacao(Tipo, Nome-Ligacoes) :-
    regra_info(Nome, Info),
    artigo_das_ligacoes(Nome, Ligacoes, ArtigoId),
    acrescentar_evento(Tipo, Nome, Info.id, Info.modulo, ArtigoId).

%!  ativacoes(+Grupo, -Ativacoes) is det.
%
%   Ativações elegíveis no ciclo, pela ordem de disparo: primeiro as das regras com auto-focus,
%   depois as do grupo em foco; em cada parte, por prioridade e ordem de declaração.
ativacoes(Grupo, Ativacoes) :-
    regras_candidatas(Grupo, Nomes),
    findall(ativacao(Nome, Ligacoes, Versoes),
            ( member(Nome, Nomes),
              ligacoes_ativas(Nome, Ligacoes),
              versoes(Nome, Ligacoes, Versoes),
              \+ refratada_(Nome, Ligacoes, Versoes)
            ),
            Ativacoes).

regras_candidatas(Grupo, Nomes) :-
    findall(k(0, P, O)-N,
            ( catalogo_(N, I), I.auto_foco == true, I.modulo \== Grupo,
              P is -I.prioridade, O = I.ordem ),
            Foco),
    findall(k(1, P, O)-N,
            ( catalogo_(N, I), I.modulo == Grupo, P is -I.prioridade, O = I.ordem ),
            DoGrupo),
    append(Foco, DoGrupo, Todos),
    keysort(Todos, Ordenados),
    pairs_values(Ordenados, Nomes).

%!  ligacoes_ativas(+Nome, -Ligacoes) is nondet.
%
%   Ligações das variáveis do lado esquerdo para as quais todas as condições se verificam.
ligacoes_ativas(Nome, Ligacoes) :-
    regra_def(Nome, LHS, _, _),
    lhs_lista(LHS, Condicoes),
    term_variables(Condicoes, Vars),
    findall(Vars, avaliar_condicoes(Condicoes), Todas),
    list_to_set(Todas, Distintas),
    member(Ligacoes, Distintas).

versoes(Nome, Ligacoes, [VE, VP|VA]) :-
    versao(entrada, VE),
    versao(pedido, VP),
    artigo_das_ligacoes(Nome, Ligacoes, ArtigoId),
    (   ArtigoId == null
    ->  VA = []
    ;   versao(artigo(ArtigoId), V), VA = [V]
    ).

%!  artigo_das_ligacoes(+Nome, +Ligacoes, -ArtigoId) is det.
%
%   Artigo a que uma ativação se refere (a variável do gerador artigo/1), ou null.
artigo_das_ligacoes(Nome, Ligacoes, ArtigoId) :-
    regra_def(Nome, LHS, _, _),
    lhs_lista(LHS, Condicoes),
    term_variables(Condicoes, Vars),
    Vars = Ligacoes,
    (   memberchk(artigo(A), Condicoes), nonvar(A)
    ->  ArtigoId = A
    ;   ArtigoId = null
    ),
    !.
artigo_das_ligacoes(_, _, null).

%!  lhs_lista(+LHS, -Condicoes) is det.
%
%   O lado esquerdo é uma lista com uma conjunção `C1 e C2 e ...` (como no sp_exp2.pl).
lhs_lista([], []) :- !.
lhs_lista([Conj], Condicoes) :- !, conj_lista(Conj, Condicoes).
lhs_lista(Lista, Condicoes) :- is_list(Lista), !, maplist(conj_lista, Lista, Ls), append(Ls, Condicoes).

conj_lista(A e B, [A|Resto]) :- !, conj_lista(B, Resto).
conj_lista(C, [C]).

avaliar_condicoes([]).
avaliar_condicoes([C|Cs]) :-
    avaliar_condicao(C),
    avaliar_condicoes(Cs).

%!  avaliar_condicao(+Condicao) is nondet.
avaliar_condicao(nao C) :- !, \+ avaliar_condicao(C).
avaliar_condicao(C) :- condicoes:C.

% ---------------------------------------------------------------------------------------------
% Disparo e ações (lado direito)
% ---------------------------------------------------------------------------------------------

:- thread_local tocado_/1.

disparar(ativacao(Nome, Ligacoes, Versoes)) :-
    assertz(refratada_(Nome, Ligacoes, Versoes)),
    regra_def(Nome, LHS, RHS, _),
    lhs_lista(LHS, Condicoes),
    term_variables(Condicoes, Ligacoes),
    regra_info(Nome, Info),
    artigo_das_ligacoes(Nome, Ligacoes, ArtigoId),
    acrescentar_evento(disparada, Nome, Info.id, Info.modulo, ArtigoId),
    retractall(tocado_(_)),
    Contexto = contexto(Nome, Info.id, Info.modulo),
    (   executar_acoes(RHS, Contexto)
    ->  true
    ;   throw(error(acao_falhou(Nome), _))
    ),
    forall(retract(tocado_(Alvo)), incrementar_versao(Alvo)).

executar_acoes([], _).
executar_acoes([Acao|Acoes], Contexto) :-
    executar_acao(Acao, Contexto),
    executar_acoes(Acoes, Contexto).

tocar(Alvo) :- ( tocado_(Alvo) -> true ; assertz(tocado_(Alvo)) ).

modulo_registo(transversal, null) :- !.
modulo_registo(M, M).

executar_acao(calcular(Objetivo), contexto(Nome, _, _)) :- !,
    (   regras:Objetivo
    ->  true
    ;   throw(error(calculo_falhou(Nome, Objetivo), _))
    ).
executar_acao(definir(Alvo, Campo, Valor), _) :- !,
    alterar_decisao(Alvo, Campo, Valor),
    tocar(Alvo).
executar_acao(aplicar(Alvo, Resultado, Mensagem), contexto(Nome, Id, Modulo)) :- !,
    texto_mensagem(Mensagem, Texto),
    modulo_registo(Modulo, ModReg),
    acrescentar_registo(Alvo, Id, Nome, ModReg, Resultado, Texto),
    decisao(Alvo, elegibilidade, Atual),
    (   mais_severo(Resultado, Atual)
    ->  alterar_decisao(Alvo, elegibilidade, Resultado)
    ;   true
    ),
    (   paragem(Id), memberchk(Resultado, [recusar, encaminhar])
    ->  alterar_decisao(Alvo, terminal, true)
    ;   true
    ),
    tocar(Alvo).
executar_acao(registar(Alvo, Mensagem), contexto(Nome, Id, Modulo)) :- !,
    texto_mensagem(Mensagem, Texto),
    modulo_registo(Modulo, ModReg),
    acrescentar_registo(Alvo, Id, Nome, ModReg, null, Texto),
    tocar(Alvo).
executar_acao(resolver_revisao(Alvo, Mensagem), contexto(Nome, Id, Modulo)) :- !,
    texto_mensagem(Mensagem, Texto),
    modulo_registo(Modulo, ModReg),
    acrescentar_registo(Alvo, Id, Nome, ModReg, permitir, Texto),
    (   decisao(Alvo, elegibilidade, rever)
    ->  alterar_decisao(Alvo, elegibilidade, permitir)
    ;   true
    ),
    tocar(Alvo).
executar_acao(suspender(Mensagem), contexto(Nome, Id, Modulo)) :- !,
    texto_mensagem(Mensagem, Texto),
    modulo_registo(Modulo, ModReg),
    acrescentar_registo(pedido, Id, Nome, ModReg, rever, Texto),
    alterar_decisao(pedido, elegibilidade, rever),
    alterar_decisao(pedido, aprovacao, district_area),
    alterar_decisao(pedido, terminal, true),
    tocar(pedido).
executar_acao(recusar_excecao(Mensagem), contexto(Nome, Id, Modulo)) :- !,
    texto_mensagem(Mensagem, Texto),
    modulo_registo(Modulo, ModReg),
    acrescentar_registo(pedido, Id, Nome, ModReg, recusar, Texto),
    alterar_decisao(pedido, excecaoRecusada, true),
    tocar(pedido).
executar_acao(marcar_suspenso, _) :- !,
    marcar_suspenso,
    tocar(entrada).
executar_acao(agregar_artigos, contexto(Nome, Id, Modulo)) :- !,
    agregar_artigos(Nome, Id, Modulo),
    tocar(pedido).
executar_acao(Acao, contexto(Nome, _, _)) :-
    throw(error(domain_error(acao, Acao), Nome)).

%!  agregar_artigos(+Nome, +Id, +Modulo) is det.
%
%   Decisao.agregarArtigos (ADR 0002): a elegibilidade do pedido passa a ser a mais severa entre
%   as dos artigos (RECUSAR > ENCAMINHAR > REVER > PERMITIR), sem baixar a já registada; se todos
%   os artigos forem recusados, não há transação.
agregar_artigos(Nome, Id, Modulo) :-
    alvos([pedido|Artigos0]),
    msort(Artigos0, Artigos),
    findall(E, ( member(Alvo, Artigos), decisao(Alvo, elegibilidade, E), E \== null ), Elegs),
    foldl(mais_severa, Elegs, null, Pior),
    decisao(pedido, elegibilidade, Atual),
    (   Pior \== null, mais_severo(Pior, Atual)
    ->  alterar_decisao(pedido, elegibilidade, Pior)
    ;   true
    ),
    length(Artigos, Total),
    contar(permitir, Elegs, Permitidos),
    contar(recusar, Elegs, Recusados),
    contar(rever, Elegs, EmRevisao),
    (   Total > 0, Recusados =:= Total
    ->  alterar_decisao(pedido, tipoTransacao, nenhuma)
    ;   true
    ),
    decisao(pedido, elegibilidade, Final),
    texto_mensagem([Total, " artigo(s): ", Permitidos, " permitido(s), ", EmRevisao, " em revisão, ",
                    Recusados, " recusado(s). Elegibilidade do pedido: ", Final, "."], Texto),
    acrescentar_registo(pedido, Id, Nome, Modulo, Final, Texto).

contar(X, L, N) :- include(==(X), L, Xs), length(Xs, N).

mais_severa(E, Pior0, Pior) :- ( mais_severo(E, Pior0) -> Pior = E ; Pior = Pior0 ).

severidade(permitir, 0).
severidade(rever, 1).
severidade(encaminhar, 2).
severidade(recusar, 3).

%!  mais_severo(+A, +B) is semidet.
%
%   A é mais severo do que B; qualquer resultado é mais severo do que null.
mais_severo(_, null) :- !.
mais_severo(A, B) :- severidade(A, SA), severidade(B, SB), SA > SB.

% ---------------------------------------------------------------------------------------------
% Mensagens
% ---------------------------------------------------------------------------------------------

%!  texto_mensagem(+Fragmentos, -Texto) is det.
%
%   Uma mensagem é um texto ou uma lista de fragmentos (textos, números, enumerados, datas).
texto_mensagem(Texto, Texto) :- string(Texto), !.
texto_mensagem(Fragmentos, Texto) :-
    is_list(Fragmentos), !,
    maplist(fragmento, Fragmentos, Partes),
    atomics_to_string(Partes, Texto).
texto_mensagem(Outro, Texto) :- fragmento(Outro, Texto).

fragmento(S, S) :- string(S), !.
fragmento(L, T) :- is_list(L), !, texto_mensagem(L, T).
fragmento(null, "null") :- !.
fragmento(N, T) :- integer(N), !, number_string(N, T).
fragmento(N, T) :- float(N), !, numero_texto(N, T).
fragmento(date(A, M, D), T) :- !, valor_json(date(A, M, D), T).
fragmento(A, T) :- atom(A), !, enum_json(A, T).
fragmento(X, T) :- term_string(X, T).

%   Os valores monetários (números decimais) aparecem com duas casas decimais.
numero_texto(N, T) :-
    format(string(T), "~2f", [N]).
