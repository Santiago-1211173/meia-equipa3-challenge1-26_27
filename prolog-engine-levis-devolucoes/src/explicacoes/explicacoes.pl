:- encoding(utf8).
:- module(explicacoes, [
    como/1,                     % -Explicacao
    como_conclusao/3,           % +CodigoSaida, +ArtigoId, -Explicacao
    porque_nao_regra/3,         % +CodigoRegra, +ArtigoId, -Explicacao
    porque_nao_conclusao/4,     % +CodigoSaida, +Valor, +ArtigoId, -Explicacao
    porque/2,                   % +CodigoDado, -Explicacao
    dados_em_falta/2,           % +Pedido, -Explicacao
    e_se/4,                     % +JsonPedido, +Alteracoes, +Original, -Explicacao
    resultado_comparavel/1,     % -Resultado
    aplicar_alteracoes/3,       % +Json0, +Pares(Caminho-Valor), -Json
    campo_saida/4               % ?Codigo, ?Descricao, ?DoArtigo, ?Campos
]).

/** <module> Explicações do sistema pericial

As cinco explicações do projeto Drools (ADR 0005 e ADR 0006), sobre a avaliação em memória:

  - **Como?** o caminho seguido: todas as regras disparadas, por ordem, ou o caminho até uma
    conclusão (OUT-001 a OUT-008), com as condições de entrada da regra que a fixou;
  - **Porque não?** porque é que uma regra não disparou (disparou, módulo não alcançado, cancelada
    por precedência, condições falhadas) ou porque é que uma conclusão não foi obtida;
  - **Porquê?** porque é que o sistema faz uma pergunta: as regras que dependem do dado e as que,
    neste pedido, só esperam por essa resposta;
  - **O que falta?** os dados obrigatórios (IN-001 a IN-009, HS-006) e os que decidem uma revisão
    (IN-010) ainda em falta;
  - **E se?** reavalia o pedido com alterações e mostra as diferenças.

Como no sp_exp2.pl, as condições das regras são termos: o "Porque não" avalia-as diretamente no
estado final e indica as que falham.
*/

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(pairs)).
:- use_module('../motor/operadores').
:- use_module('../motor/memoria').
:- use_module('../motor/motor').
:- use_module('../bc/pedido').
:- use_module('../bc/condicoes').
:- use_module('../servico').

% ---------------------------------------------------------------------------------------------
% Campos de saída (CampoSaida)
% ---------------------------------------------------------------------------------------------

campo_saida('OUT-001', "Elegibilidade", false, [elegibilidade]).
campo_saida('OUT-002', "Tipo de transação", false, [tipoTransacao]).
campo_saida('OUT-003', "Valor da devolução", false, [valorDevolucao, baseValor]).
campo_saida('OUT-004', "Meio de reembolso", false, [meioReembolso]).
campo_saida('OUT-005', "Aprovação", false, [aprovacao]).
campo_saida('OUT-006', "Processo obrigatório", false, [processo]).
campo_saida('OUT-007', "Destino do produto", true, [destino, descontoSaldo]).
campo_saida('OUT-008', "Documentação", false, ['documentacao.']).

campo_inclui(Codigo, Campo) :-
    campo_saida(Codigo, _, _, Campos),
    member(C, Campos),
    (   sub_atom(C, _, 1, 0, '.')
    ->  sub_atom(Campo, 0, _, _, C)
    ;   Campo == C
    ),
    !.

campo_principal(Codigo, Campo) :-
    (   Codigo == 'OUT-008'
    ->  Campo = 'documentacao.retencaoAte'
    ;   campo_saida(Codigo, _, _, [Campo|_])
    ).

alvo_de(null, pedido) :- !.
alvo_de(Id, artigo(Id)).

verificar_artigo(Codigo, ArtigoId) :-
    campo_saida(Codigo, _, DoArtigo, _),
    !,
    (   DoArtigo == true, ArtigoId == null
    ->  format(string(M), "~w é uma conclusão por artigo: indique o artigo", [Codigo]),
        throw(error(domain_error(artigo, null), M))
    ;   true
    ).
verificar_artigo(Codigo, _) :-
    format(string(M), "Campo de saída desconhecido: ~w", [Codigo]),
    throw(error(existence_error(campo_saida, Codigo), M)).

% ---------------------------------------------------------------------------------------------
% Como?
% ---------------------------------------------------------------------------------------------

%!  como(-Explicacao) is det.
%
%   O caminho completo: as regras disparadas por ordem, os modulos percorridos e a paragem
%   obrigatoria que terminou o fluxo, se houve.
como(_{passos:Passos, modulosPercorridos:Modulos, paragem:Paragem, resumo:Resumo}) :-
    disparos(Disparos),
    findall(P, ( nth1(Ordem, Disparos, D), passo(Ordem, D, P) ), Passos),
    findall(O-MJ, ( member(disparo(_, _, _, M, _), Disparos), ordem_modulo(M, O), valor_json(M, MJ) ), Pares0),
    sort(Pares0, Pares),
    pairs_values(Pares, Modulos),
    length(Passos, NP), length(Modulos, NM),
    format(string(R0), "Foram aplicadas ~d regras em ~d módulos.", [NP, NM]),
    (   member(disparo(Seq, _, Codigo, Mod, _), Disparos),
        alteracao(Seq, pedido, terminal, _, true)
    ->  Paragem = Codigo,
        valor_json(Mod, ModJ),
        format(string(Resumo), "~w A paragem obrigatória ~w terminou o fluxo no módulo ~w.", [R0, Codigo, ModJ])
    ;   Paragem = null,
        Resumo = R0
    ).

passo(Ordem, disparo(Seq, Nome, Codigo, Modulo, ArtigoId), Passo) :-
    regra_info(Nome, Info),
    (   registo_do_disparo(Seq, _, Resultado, Mensagem) -> true ; Resultado = null, Mensagem = null ),
    valor_json(Modulo, ModJ),
    valor_json(Resultado, ResJ),
    atom_string(Nome, NomeTexto),
    Passo = _{ordem:Ordem, modulo:ModJ, codigoRegra:Codigo, nomeRegra:NomeTexto, artigoId:ArtigoId,
              resultado:ResJ, mensagem:Mensagem, aValidar:Info.a_validar}.

%!  como_conclusao(+Codigo, +ArtigoId, -Explicacao) is det.
%
%   O caminho de uma conclusão (ex.: OUT-001 do pedido, OUT-007 de um artigo): os valores finais,
%   cada alteração do campo por ordem e as condições de entrada da regra que fixou o valor.
como_conclusao(Codigo, ArtigoId, Explicacao) :-
    once(como_conclusao_(Codigo, ArtigoId, Explicacao)).

como_conclusao_(Codigo, ArtigoId, Explicacao) :-
    verificar_artigo(Codigo, ArtigoId),
    alvo_de(ArtigoId, Alvo),
    campos_decisao(Alvo, Campos),
    findall(C-J, ( member(C, Campos), campo_inclui(Codigo, C), decisao(Alvo, C, V), valor_texto(V, J) ), ParesValores),
    dict_pairs(Valores, valores, ParesValores),
    disparos(Disparos),
    findall(Texto-Disparo,
            ( member(Disparo, Disparos), Disparo = disparo(Seq, _, Cod, _, _),
              alteracao(Seq, Alvo, Campo, Antes, Depois), campo_inclui(Codigo, Campo),
              valor_texto(Antes, TA), valor_texto(Depois, TD),
              format(string(Texto), "~w: ~w ~w → ~w", [Cod, Campo, TA, TD]) ),
            Alteracoes),
    pairs_keys(Alteracoes, Caminho),
    pairs_values(ParesValores, ListaValores),
    lista_texto(ListaValores, TextoValores),
    (   last(Alteracoes, _-disparo(SeqU, NomeU, CodU, _, ArtU))
    ->  ( registo_do_disparo(SeqU, _, _, Mensagem) -> true ; Mensagem = null ),
        condicoes_regra(NomeU, ArtU, Avaliadas),
        include(sobre_entrada, Avaliadas, CondEntrada),
        maplist(condicao_json, CondEntrada, CondJson),
        ( Mensagem == null -> atom_string(NomeU, TextoMsg) ; TextoMsg = Mensagem ),
        format(string(Resumo), "~w = ~w: concluído por ~w — ~w", [Codigo, TextoValores, CodU, TextoMsg]),
        Regra = CodU
    ;   Regra = null, Mensagem = null, CondJson = [],
        format(string(Resumo), "~w = ~w: nenhuma regra chegou a esta conclusão.", [Codigo, TextoValores])
    ),
    Explicacao = _{conclusao:Codigo, artigoId:ArtigoId, valores:Valores, regra:Regra, mensagem:Mensagem,
                   condicoes:CondJson, caminho:Caminho, resumo:Resumo}.

valor_texto(V, T) :- ( string(V) -> T = V ; valor_json(V, J), ( J == null -> T = "null" ; format(string(T), "~w", [J]) ) ).

lista_texto(Lista, Texto) :-
    atomic_list_concat(Lista, ', ', A),
    format(string(Texto), "[~w]", [A]).

% ---------------------------------------------------------------------------------------------
% Avaliação das condições de uma regra num contexto (pedido ou artigo)
% ---------------------------------------------------------------------------------------------

%!  condicoes_regra(+Nome, +ArtigoId, -Avaliadas) is det.
%
%   Condições da regra (sem guardas nem o gerador artigo/1), avaliadas no estado atual:
%   lista de cond(Termo, Tipo, Descricao, Cumprida, Valor, ArtigoId).
condicoes_regra(Nome, ArtigoId, Avaliadas) :-
    regra_def(Nome, LHS, _, _),
    lhs_lista(LHS, Condicoes),
    (   memberchk(artigo(A), Condicoes), ArtigoId \== null
    ->  A = ArtigoId
    ;   true
    ),
    findall(cond(C, Tipo, Desc, Cumprida, Valor, Art),
            ( member(C, Condicoes),
              info_condicao(C, Tipo, Desc),
              Tipo \== guarda, Tipo \== gerador,
              ( ground(C) -> ( avaliar_condicao(C) -> Cumprida = true ; Cumprida = false ) ; Cumprida = null ),
              ( ground(C) -> valor_condicao(C, Valor) ; Valor = null ),
              ( C =.. [_, X|_], memberchk(artigo(X), Condicoes) -> Art = ArtigoId ; Art = null )
            ),
            Avaliadas).

info_condicao(nao C, Tipo, Desc) :- !,
    info_condicao(C, Tipo, D0),
    format(string(Desc), "não: ~w", [D0]).
info_condicao(C, Tipo, Desc) :-
    functor(C, Nome, Ar),
    (   condicao_info(Nome/Ar, Tipo, Desc) -> true ; Tipo = entrada, term_string(C, Desc) ).

sobre_entrada(cond(_, entrada, _, _, _, _)).

condicao_json(cond(C, _, Desc, Cumprida, Valor, Art), _{nome:Nome, descricao:Desc, cumprida:Cumprida, valor:Valor, artigoId:Art}) :-
    ( C = (nao C1) -> functor(C1, N0, _), atom_concat(nao_, N0, Nome) ; functor(C, Nome, _) ).

falhada(cond(_, _, _, false, _, _)).
cumprida(cond(_, _, _, true, _, _)).

% ---------------------------------------------------------------------------------------------
% Porque não?
% ---------------------------------------------------------------------------------------------

%!  porque_nao_regra(+Codigo, +ArtigoId, -Explicacao) is det.
%
%   Causa por que a regra (todas as variantes com o ID) não disparou: DISPAROU,
%   MODULO_NAO_ALCANCADO, CANCELADA_POR_PRECEDENCIA ou CONDICOES_FALHADAS.
porque_nao_regra(Codigo, ArtigoId, Explicacao) :-
    once(porque_nao_regra_(Codigo, ArtigoId, Explicacao)).

porque_nao_regra_(Codigo, ArtigoId, Explicacao) :-
    findall(Nome-Info, ( regra_info(Nome, Info), Info.id == Codigo ), Variantes),
    (   Variantes == []
    ->  format(string(M), "Regra desconhecida: ~w", [Codigo]),
        throw(error(existence_error(regra, Codigo), M))
    ;   true
    ),
    Variantes = [_-Primeira|_],
    ordem_modulo(Primeira.modulo, OrdemRegra),
    (   forall(member(_-I, Variantes), I.sem_guarda == true) -> SemGuarda = true ; SemGuarda = false ),
    (   disparou_codigo(Codigo, ArtigoId)
    ->  format(string(R), "A regra ~w disparou.", [Codigo]),
        Explicacao = _{codigoRegra:Codigo, artigoId:ArtigoId, causa:"DISPAROU", regraResponsavel:null,
                       variante:null, condicoes:[], resumo:R}
    ;   SemGuarda == false, paragem(ArtigoId, <, OrdemRegra, CodP, ModP)
    ->  valor_json(ModP, ModJ),
        format(string(R), "A regra ~w não chegou a ser avaliada: a paragem obrigatória ~w terminou o fluxo no módulo ~w.",
               [Codigo, CodP, ModJ]),
        Explicacao = _{codigoRegra:Codigo, artigoId:ArtigoId, causa:"MODULO_NAO_ALCANCADO", regraResponsavel:CodP,
                       variante:null, condicoes:[], resumo:R}
    ;   cancelamento(Codigo, ArtigoId, NomeCancelada, CodigoCulpada, MensagemCulpada)
    ->  format(string(R), "A regra ~w foi ativada, mas foi cancelada depois de ~w ter disparado com precedência: ~w",
               [Codigo, CodigoCulpada, MensagemCulpada]),
        atom_string(NomeCancelada, Variante),
        Explicacao = _{codigoRegra:Codigo, artigoId:ArtigoId, causa:"CANCELADA_POR_PRECEDENCIA",
                       regraResponsavel:CodigoCulpada, variante:Variante, condicoes:[], resumo:R}
    ;   variante_mais_proxima(Variantes, ArtigoId, NomeMelhor, Melhor),
        include(falhada, Melhor, Falhadas),
        maplist(condicao_json, Melhor, CondJson),
        atom_string(NomeMelhor, Variante),
        (   Falhadas == [], SemGuarda == false, paragem(ArtigoId, =, OrdemRegra, CodP, _)
        ->  mensagem_do_codigo(CodP, MsgP),
            format(string(R), "A regra ~w foi ativada, mas foi cancelada depois de ~w ter disparado com precedência: ~w",
                   [Codigo, CodP, MsgP]),
            Explicacao = _{codigoRegra:Codigo, artigoId:ArtigoId, causa:"CANCELADA_POR_PRECEDENCIA",
                           regraResponsavel:CodP, variante:Variante, condicoes:CondJson, resumo:R}
        ;   (   Falhadas == []
            ->  format(string(R), "A regra ~w não disparou, embora as condições declaradas se verifiquem no estado final; foi impedida pela ordem de avaliação ou já não se aplicava quando o seu módulo foi avaliado.", [Codigo])
            ;   findall(D, member(cond(_, _, D, _, _, _), Falhadas), Ds),
                atomic_list_concat(Ds, '; ', TextoFalhadas),
                format(string(R), "A regra ~w não disparou porque estas condições não se verificam: ~w.", [Codigo, TextoFalhadas])
            ),
            Explicacao = _{codigoRegra:Codigo, artigoId:ArtigoId, causa:"CONDICOES_FALHADAS", regraResponsavel:null,
                           variante:Variante, condicoes:CondJson, resumo:R}
        )
    ).

disparou_codigo(Codigo, ArtigoId) :-
    evento(_, disparada, _, Codigo, _, Art),
    ( ArtigoId == null -> true ; Art == ArtigoId ; Art == null ),
    !.

%   Primeiro disparo que terminou o fluxo do pedido ou do artigo num modulo anterior (<) ou no
%   proprio modulo (=) da regra.
paragem(ArtigoId, Comparacao, OrdemRegra, Codigo, Modulo) :-
    disparos(Disparos),
    member(disparo(Seq, _, Codigo, Modulo, _), Disparos),
    (   alteracao(Seq, pedido, terminal, _, true)
    ;   ArtigoId \== null, alteracao(Seq, artigo(ArtigoId), terminal, _, true)
    ),
    ordem_modulo(Modulo, OrdemP),
    compare_ordem(Comparacao, OrdemP, OrdemRegra),
    !.

compare_ordem(<, A, B) :- A < B.
compare_ordem(=, A, B) :- A =:= B.

cancelamento(Codigo, ArtigoId, NomeCancelada, CodigoCulpada, MensagemCulpada) :-
    findall(Seq-Nome, ( evento(Seq, cancelada, Nome, Codigo, _, Art), ( ArtigoId == null -> true ; Art == ArtigoId ) ), Cs),
    last(Cs, SeqC-NomeCancelada),
    findall(S-C, ( evento(S, disparada, _, C, _, _), S < SeqC ), Anteriores),
    last(Anteriores, SeqD-CodigoCulpada),
    (   registo_do_disparo(SeqD, _, _, MensagemCulpada) -> true ; MensagemCulpada = CodigoCulpada ).

mensagem_do_codigo(Codigo, Mensagem) :-
    (   evento(Seq, disparada, _, Codigo, _, _), registo_do_disparo(Seq, _, _, Mensagem)
    ->  true
    ;   Mensagem = Codigo
    ).

%   A variante mais próxima de disparar: menos condições falhadas e, em empate, mais cumpridas.
variante_mais_proxima(Variantes, ArtigoId, NomeMelhor, Melhor) :-
    findall(k(F, NC)-(Nome-Avaliadas),
            ( member(Nome-Info, Variantes),
              contexto_artigo(Info, ArtigoId, Art),
              condicoes_regra(Nome, Art, Avaliadas),
              include(falhada, Avaliadas, Fs), length(Fs, F),
              include(cumprida, Avaliadas, Cs), length(Cs, C), NC is -C ),
            Candidatas),
    keysort(Candidatas, [_-(NomeMelhor-Melhor)|_]).

contexto_artigo(Info, ArtigoId, Art) :-
    (   Info.de_artigo == true
    ->  (   ArtigoId \== null -> Art = ArtigoId ; artigo(Art) )
    ;   Art = null
    ).

%!  porque_nao_conclusao(+Codigo, +Valor, +ArtigoId, -Explicacao) is det.
%
%   Porque é que a conclusão Codigo = Valor (ex.: OUT-001 = PERMITIR) não foi obtida: que regras
%   a chegaram a propor, que regra fixou o valor final e porque é que as outras produtoras não
%   dispararam.
porque_nao_conclusao(Codigo, Valor0, ArtigoId, Explicacao) :-
    once(porque_nao_conclusao_(Codigo, Valor0, ArtigoId, Explicacao)).

porque_nao_conclusao_(Codigo, Valor0, ArtigoId, Explicacao) :-
    verificar_artigo(Codigo, ArtigoId),
    normalizar_valor_conclusao(Valor0, Valor),
    alvo_de(ArtigoId, Alvo),
    campo_principal(Codigo, Campo),
    decisao(Alvo, Campo, Obtido),
    valor_texto(Obtido, TextoObtido),
    valor_texto(Valor, TextoValor),
    format(string(Rotulo), "~w = ~w", [Codigo, TextoValor]),
    disparos(Disparos),
    (   findall(C, ( member(disparo(Seq, _, C, _, _), Disparos), alteracao(Seq, Alvo, Campo, _, _) ), Cs),
        last(Cs, DefinidoPor) -> true ; DefinidoPor = null ),
    findall(C, ( member(disparo(_, Nome, C, _, Art), Disparos), Art == ArtigoId,
                 produz(Nome, Codigo, Valor) ), Ps),
    list_to_set(Ps, PropostaPor),
    (   Obtido == Valor
    ->  format(string(R), "A conclusão ~w foi obtida (por ~w).", [Rotulo, DefinidoPor]),
        Explicacao = _{conclusao:Codigo, valor:TextoValor, artigoId:ArtigoId, valorObtido:TextoObtido, obtida:true,
                       propostaPor:PropostaPor, definidoPor:DefinidoPor, regras:[], resumo:R}
    ;   findall(Id, ( regras_por_ordem(Nomes), member(N, Nomes), produz(N, Codigo, Valor),
                      regra_info(N, I), Id = I.id ), Ids0),
        list_to_set(Ids0, Produtoras),
        findall(E, ( member(Id, Produtoras), porque_nao_regra(Id, ArtigoId, E) ), Regras),
        (   Produtoras == []
        ->  format(string(R), "Nenhuma regra da base de conhecimento produz a conclusão ~w.", [Rotulo])
        ;   PropostaPor \== []
        ->  atomic_list_concat(PropostaPor, ', ', TP),
            ( DefinidoPor == null -> TD = "-" ; TD = DefinidoPor ),
            format(string(R), "A conclusão ~w chegou a ser proposta por ~w, mas o resultado final é ~w, definido por ~w (prevalece o resultado mais severo ou posterior).",
                   [Rotulo, TP, TextoObtido, TD])
        ;   findall(T, ( member(E, Regras), format(string(T), "~w — ~w", [E.codigoRegra, E.resumo]) ), Ts),
            atomic_list_concat(Ts, ' ', TR),
            format(string(R), "A conclusão ~w não foi obtida (resultado: ~w). Nenhuma das regras que a podem produzir o fez: ~w",
                   [Rotulo, TextoObtido, TR])
        ),
        Explicacao = _{conclusao:Codigo, valor:TextoValor, artigoId:ArtigoId, valorObtido:TextoObtido, obtida:false,
                       propostaPor:PropostaPor, definidoPor:DefinidoPor, regras:Regras, resumo:R}
    ).

normalizar_valor_conclusao(V, A) :-
    (   ( V == null ; V == "null" ; V == "NULL" ; V == 'NULL' )
    ->  A = null
    ;   enum_json(A, V)
    ).

%!  produz(+Nome, +Codigo, +Valor) is semidet.
%
%   A regra declara em `conclusoes` que pode produzir Codigo = Valor (ou Codigo sem valor).
produz(Nome, Codigo, Valor) :-
    regra_info(Nome, Info),
    member(C, Info.conclusoes),
    (   C == Codigo
    ->  true
    ;   C = (Codigo = V), V == Valor
    ),
    !.

% ---------------------------------------------------------------------------------------------
% Porquê?
% ---------------------------------------------------------------------------------------------

%!  porque(+CodigoDado, -Explicacao) is det.
%
%   Porque é que o sistema pergunta o dado (IN-001..IN-010, HS-006, EX-001, EX-002, EX-008,
%   CH-002): as regras que o leem e as que, no pedido atual, têm as outras condições cumpridas
%   e esperam pela resposta.
porque(Dado0, Explicacao) :-
    once(porque_(Dado0, Explicacao)).

porque_(Dado0, Explicacao) :-
    ( atom(Dado0) -> Dado = Dado0 ; atom_string(Dado, Dado0) ),
    (   dado_entrada(Dado, _, _, Pergunta) -> true
    ;   format(string(M), "Dado desconhecido: ~w", [Dado]),
        throw(error(existence_error(dado, Dado), M))
    ),
    regras_por_ordem(Nomes),
    include(le_o_dado(Dado), Nomes, Relacionadas),
    findall(Id, ( member(N, Relacionadas), regra_info(N, I), Id = I.id ), Ids0),
    list_to_set(Ids0, Ids),
    findall(Espera, ( member(N, Relacionadas), em_espera(N, Dado, Espera) ), EmEspera),
    atomic_list_concat(Ids, ', ', TextoIds),
    length(EmEspera, NE),
    (   NE =:= 0
    ->  format(string(R), "A pergunta \"~w\" é usada pelas regras ~w; neste pedido, nenhuma decisão está pendente desta resposta.",
               [Pergunta, TextoIds])
    ;   findall(T, ( member(E, EmEspera), texto_espera(E, T) ), Ts),
        atomic_list_concat(Ts, '; ', TE),
        format(string(R), "Pergunto \"~w\" porque ~d decisão(ões) deste pedido dependem da resposta: ~w.", [Pergunta, NE, TE])
    ),
    Explicacao = _{dado:Dado, pergunta:Pergunta, regrasQueDependem:Ids, regrasEmEspera:EmEspera, resumo:R}.

le_o_dado(Dado, Nome) :-
    regra_def(Nome, LHS, _, _),
    lhs_lista(LHS, Condicoes),
    member(C, Condicoes),
    nome_condicao(C, NC),
    le_dado(NC, Dado),
    !.

nome_condicao(nao C, N) :- !, nome_condicao(C, N).
nome_condicao(C, N) :- functor(C, N, _).

em_espera(Nome, Dado, Espera) :-
    regra_info(Nome, Info),
    contexto_artigo(Info, null, Art),
    \+ disparou_nome(Nome, Art),
    \+ bloqueada(Info, Art),
    condicoes_regra(Nome, Art, Avaliadas),
    forall(( member(Cd, Avaliadas), Cd = cond(C, _, _, false, _, _) ), ( nome_condicao(C, NC), le_dado(NC, Dado) )),
    include(cond_le(Dado), Avaliadas, DoDado),
    maplist(condicao_json, DoDado, DoDadoJson),
    findall(T, ( member(Conc, Info.conclusoes), conclusao_texto(Conc, T) ), Conclusoes),
    valor_json(Info.modulo, Modulo),
    atom_string(Nome, NomeTexto),
    Espera = _{codigoRegra:Info.id, nomeRegra:NomeTexto, modulo:Modulo, artigoId:Art,
               conclusoes:Conclusoes, condicoesDoDado:DoDadoJson}.

cond_le(Dado, cond(C, _, _, _, _, _)) :- nome_condicao(C, NC), le_dado(NC, Dado).

disparou_nome(Nome, Art) :-
    evento(_, disparada, Nome, _, _, A),
    ( Art == null -> true ; A == Art ),
    !.

bloqueada(Info, Art) :-
    Info.sem_guarda == false,
    (   decisao(pedido, terminal, true)
    ->  true
    ;   Art \== null, decisao(artigo(Art), terminal, true)
    ).

conclusao_texto(C = V, T) :- !, valor_texto(V, TV), format(string(T), "~w=~w", [C, TV]).
conclusao_texto(C, T) :- format(string(T), "~w", [C]).

texto_espera(E, T) :-
    ( E.artigoId == null -> TA = "" ; format(string(TA), " [~w]", [E.artigoId]) ),
    (   E.conclusoes == []
    ->  TC = ""
    ;   atomic_list_concat(E.conclusoes, ', ', C), format(string(TC), " → [~w]", [C])
    ),
    format(string(T), "~w~w~w", [E.codigoRegra, TA, TC]).

% ---------------------------------------------------------------------------------------------
% O que falta? (DetetorDadosEmFalta)
% ---------------------------------------------------------------------------------------------

%!  dados_em_falta(+Pedido, -Explicacao) is det.
%
%   Os dados de entrada em falta num pedido normalizado. Os obrigatórios impedem a avaliação;
%   IN-010 só é necessário para decidir uma revisão. Cada dado traz o seu "Porquê" (calculado
%   sobre a avaliação em memória, se existir).
dados_em_falta(Pedido, Explicacao) :-
    once(dados_em_falta_(Pedido, Explicacao)).

dados_em_falta_(Pedido, _{dados:Dados, completo:Completo, resumo:Resumo}) :-
    findall(falta(C, Caminho, D, O), falta(Pedido, C, Caminho, D, O), Faltas),
    findall(J, ( member(falta(C, Caminho, D, O), Faltas), falta_json(C, Caminho, D, O, J) ), Dados),
    findall(x, member(falta(_, _, _, true), Faltas), Obrig),
    length(Obrig, NO), length(Faltas, NT), NOpc is NT - NO,
    (   NO =:= 0
    ->  Completo = true,
        Resumo = "Os dados obrigatórios estão completos."
    ;   Completo = false,
        format(string(Resumo), "Faltam ~d dado(s) obrigatório(s) e ~d dado(s) para decidir uma revisão.", [NO, NOpc])
    ).

falta_json(Codigo, Caminho, Descricao, Obrigatorio, Json) :-
    (   catch(porque(Codigo, Porque), _, fail) -> true ; Porque = null ),
    Json = _{codigo:Codigo, caminho:Caminho, descricao:Descricao, obrigatorio:Obrigatorio, porque:Porque}.

falta(P, 'HS-006', "colaborador.funcao", "Função do colaborador que processa", true) :-
    campo(P, [colaborador, funcao], null).
falta(P, 'IN-001', "loja.mercado", "Mercado (Estados Unidos ou Canadá)", true) :-
    campo(P, [loja, mercado], null).
falta(P, 'IN-002', "loja.tipoLoja", "Tipo de loja (Mainline ou Outlet)", true) :-
    campo(P, [loja, tipoLoja], null).
falta(P, 'IN-003', "compraOriginal.canal", "Canal de compra (ou \"desconhecido\")", true) :-
    campo(P, [compraOriginal, canal], null).
falta(P, 'IN-004', "comprovativo.tipo", "Tipo de comprovativo apresentado", true) :-
    campo(P, [comprovativo], C), C \== null, campo(C, [tipo], null).
falta(P, 'IN-005', "tipoPedido", "Pedido do cliente (devolução, troca, oferta ou ajuste)", true) :-
    campo(P, [tipoPedido], null).
falta(P, 'IN-006', "dataPedido", "Data do pedido", true) :-
    campo(P, [dataPedido], null).
falta(P, 'IN-006', Caminho, Descricao, true) :-
    campo(P, [compraOriginal], Compra), Compra \== null,
    (   online(P)
    ->  campo(Compra, [dataEnvio], null),
        Caminho = "compraOriginal.dataEnvio", Descricao = "Data de envio da encomenda online"
    ;   campo(P, [comprovativo], Comp), Comp \== null,
        campo(Compra, [dataCompra], null),
        Caminho = "compraOriginal.dataCompra", Descricao = "Data da compra indicada no comprovativo"
    ).
falta(P, 'IN-009', "compraOriginal.pagamento.meio", "Meio de pagamento original", true) :-
    ( campo(P, [comprovativo], Comp), Comp \== null -> true ; online(P) ),
    campo(P, [compraOriginal], Compra), Compra \== null,
    campo(Compra, [pagamento, meio], null).
falta(P, Codigo, Caminho, Descricao, Obrigatorio) :-
    nth0(I, P.artigos, Artigo),
    format(string(Prefixo), "artigos[~d].", [I]),
    falta_artigo(P, Artigo, Prefixo, Codigo, Caminho, Descricao, Obrigatorio).
falta(P, 'IN-007', "artigos", "Pelo menos um artigo devolvido", true) :-
    P.artigos == [].

online(P) :- campo(P, [compraOriginal, canal], C), memberchk(C, [levi_com, levi_ca]).

falta_artigo(_, Artigo, Prefixo, 'IN-007', Caminho, Descricao, true) :-
    Id = Artigo.id,
    (   Artigo.produto == null
    ->  atom_concat(Prefixo, produto, C0), atom_string(C0, Caminho),
        format(string(Descricao), "Produto do artigo ~w", [Id])
    ;   member(Campo-Rotulo, [sku-"SKU", marca-"Marca", categoria-"Categoria"]),
        campo(Artigo, [produto, Campo], null),
        format(string(Caminho), "~wproduto.~w", [Prefixo, Campo]),
        format(string(Descricao), "~w do artigo ~w", [Rotulo, Id])
    ).
falta_artigo(P, Artigo, Prefixo, Codigo, Caminho, Descricao, Obrigatorio) :-
    Id = Artigo.id,
    Estado = Artigo.estado,
    (   ( Estado == null ; campo(Estado, [condicaoUso], null) )
    ->  Codigo = 'IN-008', Obrigatorio = true,
        format(string(Caminho), "~westado.condicaoUso", [Prefixo]),
        format(string(Descricao), "Estado de uso do artigo ~w", [Id])
    ;   ( campo(Artigo, [produto, categoria], bodywear) -> Bodywear = true ; Bodywear = false ),
        (   Bodywear == false, Estado.condicaoUso == nao_usado, Estado.etiquetas == null,
            Codigo = 'IN-008', Obrigatorio = true,
            format(string(Caminho), "~westado.etiquetas", [Prefixo]),
            format(string(Descricao), "Estado das etiquetas do artigo ~w", [Id])
        ;   Artigo.revendivel == null,
            precisa_avaliar_revenda(P, Artigo, Bodywear),
            Codigo = 'IN-010', Obrigatorio = false,
            format(string(Caminho), "~wrevendivel", [Prefixo]),
            format(string(Descricao), "Possibilidade de verificar, reetiquetar e revender o artigo ~w", [Id])
        )
    ).

precisa_avaliar_revenda(P, Artigo, Bodywear) :-
    Estado = Artigo.estado,
    (   Bodywear == false, Estado.condicaoUso == nao_usado,
        memberchk(Estado.etiquetas, [soltas, ausentes]),
        Estado.defeitoFabricoConfirmado == false
    ->  true
    ;   Bodywear == true, Estado.condicaoUso == nao_usado,
        Estado.embalagemIntacta == true, Estado.conjuntoCompleto == true
    ->  true
    ;   campo(P, [comprovativo], Comp), Comp \== null,
        \+ online(P),
        campo(P, [compraOriginal, dataCompra], Data), Data \== null,
        campo(P, [dataPedido], DataPedido), DataPedido \== null,
        dias_entre(Data, DataPedido, Dias),
        Dias > 30
    ).

% ---------------------------------------------------------------------------------------------
% E se?
% ---------------------------------------------------------------------------------------------

%!  e_se(+JsonPedido, +Alteracoes, +Original, -Explicacao) is det.
%
%   Reavalia o pedido (JSON) com as alterações (dict caminho -> valor, ex.:
%   "compraOriginal.pagamento.meio": "DEBITO", "artigos[0].revendivel": true) e compara com a
%   avaliação Original (resultado de resultado_comparavel/1, feito antes). A memória fica com a
%   avaliação simulada.
e_se(JsonPedido, Alteracoes, Original, Explicacao) :-
    dict_pairs(Alteracoes, _, Pares),
    forall(member(Caminho-_, Pares), validar_caminho(Caminho)),
    (   foldl(aplicar_alteracao, Pares, JsonPedido, JsonSimulado)
    ->  true
    ;   throw(error(domain_error(alteracao, Pares), "Alteração inválida: um índice de lista não existe no pedido."))
    ),
    servico:preparar_pedido(JsonSimulado, Pedido, Fraudes),
    servico:avaliar_pedido(Pedido, Fraudes),
    resultado_comparavel(Simulado),
    Original = resultado(InstO, CodigosO),
    Simulado = resultado(InstS, CodigosS),
    findall(D, diferenca(InstO, InstS, D), Diferencas),
    subtract(CodigosS, CodigosO, Novas),
    subtract(CodigosO, CodigosS, Removidas),
    length(Diferencas, ND),
    (   ND =:= 0
    ->  Resumo = "A alteração não muda o resultado."
    ;   format(string(Resumo), "A alteração muda ~d campo(s) do resultado.", [ND])
    ),
    decisao_json(_{}, DecisaoSimulada),
    Explicacao = _{diferencas:Diferencas, regrasNovas:Novas, regrasRemovidas:Removidas,
                   resumo:Resumo, decisaoSimulada:DecisaoSimulada}.

%!  aplicar_alteracoes(+Json0, +Pares, -Json) is det.
%
%   Aplica alterações Caminho-Valor (ex.: "artigos[0].revendivel"-true) a um pedido JSON.
aplicar_alteracoes(Json0, Pares, Json) :-
    foldl(aplicar_alteracao, Pares, Json0, Json).

%!  resultado_comparavel(-Resultado) is det.
%
%   Os valores finais das decisões e os códigos das regras disparadas da avaliação em memória.
resultado_comparavel(resultado(Instantaneo, Codigos)) :-
    instantaneo(Instantaneo),
    codigos_disparados(Codigos).

diferenca(InstO, InstS, _{alvo:AlvoTexto, campo:Campo, original:TO, simulado:TS}) :-
    member(Alvo-CamposO, InstO),
    memberchk(Alvo-CamposS, InstS),
    member(Campo=VO, CamposO),
    memberchk(Campo=VS, CamposS),
    VO \== VS,
    valor_texto(VO, TO), valor_texto(VS, TS),
    ( Alvo = artigo(Id) -> AlvoTexto = Id ; AlvoTexto = "pedido" ).

validar_caminho(Caminho) :-
    segmentos_caminho(Caminho, Segs),
    (   caminho_valido(Segs)
    ->  true
    ;   format(string(M), "Caminho desconhecido no pedido: ~w", [Caminho]),
        throw(error(domain_error(caminho, Caminho), M))
    ).

segmentos_caminho(Caminho, Segs) :-
    ( atom(Caminho) -> atom_string(Caminho, Texto) ; Texto = Caminho ),
    split_string(Texto, ".", "", Partes),
    foldl(segmentos, Partes, [], Segs0), reverse(Segs0, Segs).

aplicar_alteracao(Caminho-Valor, Json0, Json) :-
    segmentos_caminho(Caminho, Segs),
    (   get_dict(pedido, Json0, P0), is_dict(P0)
    ->  definir_caminho(Segs, P0, Valor, P1),
        Json = Json0.put(pedido, P1)
    ;   definir_caminho(Segs, Json0, Valor, Json)
    ).

segmentos(Parte, Acc0, Acc) :-
    (   split_string(Parte, "[]", "", [Nome, IndiceTexto, _]),
        number_string(Indice, IndiceTexto)
    ->  atom_string(Chave, Nome),
        Acc = [indice(Indice), chave(Chave)|Acc0]
    ;   atom_string(Chave, Parte),
        Acc = [chave(Chave)|Acc0]
    ).

definir_caminho([], _, Valor, Valor).
definir_caminho([chave(K)|Resto], Objeto0, Valor, Objeto) :-
    ( is_dict(Objeto0) -> O0 = Objeto0 ; O0 = _{} ),
    ( get_dict(K, O0, Filho0) -> true ; Filho0 = null ),
    definir_caminho(Resto, Filho0, Valor, Filho),
    put_dict(K, O0, Filho, Objeto).
definir_caminho([indice(I)|Resto], Lista0, Valor, Lista) :-
    must_be(list, Lista0),
    nth0(I, Lista0, Elem0, Outros),
    definir_caminho(Resto, Elem0, Valor, Elem),
    nth0(I, Lista, Elem, Outros).
