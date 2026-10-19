:- encoding(utf8).
:- module(memoria, [
    iniciar_memoria/2,          % +Pedido, +Fraudes
    limpar_memoria/0,
    pedido_atual/1,             % -Pedido
    fraude/2,                   % ?Descricao, ?NivelRisco
    suspenso/1,                 % -Booleano
    marcar_suspenso/0,
    decisao/3,                  % ?Alvo, ?Campo, ?Valor
    alterar_decisao/3,          % +Alvo, +Campo, +Valor
    alvos/1,                    % -Alvos (pedido e artigos, pela ordem do pedido)
    campos_decisao/2,           % +Alvo, -Campos
    disparou/2,                 % ?Alvo, ?CodigoRegra
    registo/7,                  % ?Seq, ?Alvo, ?Codigo, ?Nome, ?Modulo, ?Resultado, ?Mensagem
    acrescentar_registo/6,      % +Alvo, +Codigo, +Nome, +Modulo, +Resultado, +Mensagem
    registo_do_disparo/4,       % +SeqDisparo, -Alvo, -Resultado, -Mensagem
    evento/6,                   % ?Seq, ?Tipo, ?Nome, ?Codigo, ?Modulo, ?ArtigoId
    acrescentar_evento/5,       % +Tipo, +Nome, +Codigo, +Modulo, +ArtigoId
    alteracao/5,                % ?SeqDisparo, ?Alvo, ?Campo, ?Antes, ?Depois
    disparo_atual/1,            % -SeqDisparo
    definir_disparo_atual/1,
    versao/2,                   % +Alvo, -Versao
    incrementar_versao/1,
    proximo_seq/1,
    instantaneo/1               % -Instantaneo: lista Alvo-[Campo=Valor]
]).

/** <module> Memória de trabalho

Guarda, por avaliação, os factos de entrada (o pedido e os indícios de fraude), o estado das
decisões (a do pedido e uma por artigo, como `Decisao` e `DecisaoArtigo` no Drools, ADR 0002) e o
rasto da execução (registos das regras, eventos da agenda e alterações aos campos).

Os predicados são `thread_local`: cada pedido HTTP corre na sua thread e tem a sua memória.
*/

:- thread_local
    pedido_atual_/1,
    fraude_/2,
    suspenso_/1,
    decisao_/3,
    registo_/7,
    registo_disparo_/2,
    evento_/6,
    alteracao_/5,
    versao_/2,
    seq_/1,
    disparo_atual_/1.

%!  iniciar_memoria(+Pedido, +Fraudes) is det.
%
%   Limpa a memória e insere os factos de uma nova avaliação: o pedido normalizado, os indícios
%   de fraude (lista de fraude(Descricao, Nivel)) e as decisões iniciais.
iniciar_memoria(Pedido, Fraudes) :-
    limpar_memoria,
    assertz(pedido_atual_(Pedido)),
    forall(member(fraude(Descricao, Nivel), Fraudes), assertz(fraude_(Descricao, Nivel))),
    assertz(suspenso_(false)),
    assertz(seq_(0)),
    forall(campo_inicial(pedido, Campo, Valor), assertz(decisao_(pedido, Campo, Valor))),
    forall(( member(Artigo, Pedido.artigos), Id = Artigo.id ),
           forall(campo_inicial(artigo, Campo, Valor), assertz(decisao_(artigo(Id), Campo, Valor)))),
    forall(alvo_inicial(Alvo), assertz(versao_(Alvo, 0))).

alvo_inicial(entrada).
alvo_inicial(pedido).
alvo_inicial(artigo(Id)) :- pedido_atual_(P), member(A, P.artigos), Id = A.id.

limpar_memoria :-
    retractall(pedido_atual_(_)),
    retractall(fraude_(_, _)),
    retractall(suspenso_(_)),
    retractall(decisao_(_, _, _)),
    retractall(registo_(_, _, _, _, _, _, _)),
    retractall(registo_disparo_(_, _)),
    retractall(evento_(_, _, _, _, _, _)),
    retractall(alteracao_(_, _, _, _, _)),
    retractall(versao_(_, _)),
    retractall(seq_(_)),
    retractall(disparo_atual_(_)).

%   Campos de saída e valores iniciais (Decisao e DecisaoArtigo do modelo Java).
campo_inicial(pedido, elegibilidade, null).
campo_inicial(pedido, terminal, false).
campo_inicial(pedido, tipoVerificacao, nao_determinada).
campo_inicial(pedido, tipoTransacao, null).
campo_inicial(pedido, valorDevolucao, null).
campo_inicial(pedido, baseValor, null).
campo_inicial(pedido, meioReembolso, null).
campo_inicial(pedido, aprovacao, nenhuma).
campo_inicial(pedido, processo, null).
campo_inicial(pedido, excecaoRecusada, false).
campo_inicial(pedido, 'documentacao.assinaturaCliente', null).
campo_inicial(pedido, 'documentacao.assinaturaProcessador', null).
campo_inicial(pedido, 'documentacao.assinaturaTestemunha', null).
campo_inicial(pedido, 'documentacao.idStylistAtribuido', null).
campo_inicial(pedido, 'documentacao.reciboAgrafado', false).
campo_inicial(pedido, 'documentacao.notaRecibo', null).
campo_inicial(pedido, 'documentacao.retencaoAte', null).
campo_inicial(pedido, 'documentacao.registoExcecao', null).
campo_inicial(artigo, elegibilidade, null).
campo_inicial(artigo, terminal, false).
campo_inicial(artigo, tipoTransacao, null).
campo_inicial(artigo, valorDevolucao, null).
campo_inicial(artigo, baseValor, null).
campo_inicial(artigo, destino, null).
campo_inicial(artigo, aprovacao, nenhuma).
campo_inicial(artigo, descontoSaldo, 0).

%!  campos_decisao(+Alvo, -Campos) is det.
campos_decisao(pedido, Campos) :- !, findall(C, campo_inicial(pedido, C, _), Campos).
campos_decisao(artigo(_), Campos) :- findall(C, campo_inicial(artigo, C, _), Campos).

pedido_atual(P) :- pedido_atual_(P).
fraude(Descricao, Nivel) :- fraude_(Descricao, Nivel).
suspenso(S) :- suspenso_(S).

marcar_suspenso :-
    retractall(suspenso_(_)),
    assertz(suspenso_(true)).

decisao(Alvo, Campo, Valor) :- decisao_(Alvo, Campo, Valor).

%!  alterar_decisao(+Alvo, +Campo, +Valor) is det.
%
%   Altera um campo de uma decisão e regista a alteração no disparo em curso (para o "Como" e o
%   "Porque não"). Uma alteração para o mesmo valor não fica registada.
alterar_decisao(Alvo, Campo, Valor) :-
    decisao_(Alvo, Campo, Antes),
    !,
    (   Antes == Valor
    ->  true
    ;   retract(decisao_(Alvo, Campo, Antes)),
        assertz(decisao_(Alvo, Campo, Valor)),
        (   disparo_atual_(Seq)
        ->  assertz(alteracao_(Seq, Alvo, Campo, Antes, Valor))
        ;   true
        )
    ).
alterar_decisao(Alvo, Campo, _) :-
    throw(error(existence_error(campo_decisao, Alvo-Campo), _)).

alvos([pedido|Artigos]) :-
    pedido_atual_(P),
    findall(artigo(Id), ( member(A, P.artigos), Id = A.id ), Artigos).

disparou(Alvo, Codigo) :- registo_(_, Alvo, Codigo, _, _, _, _), !.

registo(Seq, Alvo, Codigo, Nome, Modulo, Resultado, Mensagem) :-
    registo_(Seq, Alvo, Codigo, Nome, Modulo, Resultado, Mensagem).

acrescentar_registo(Alvo, Codigo, Nome, Modulo, Resultado, Mensagem) :-
    proximo_seq(Seq),
    assertz(registo_(Seq, Alvo, Codigo, Nome, Modulo, Resultado, Mensagem)),
    (   disparo_atual_(Disparo)
    ->  assertz(registo_disparo_(Seq, Disparo))
    ;   true
    ).

%!  registo_do_disparo(+SeqDisparo, -Alvo, -Resultado, -Mensagem) is semidet.
%
%   O registo feito por um disparo (cada disparo faz um registo, como no DRL).
registo_do_disparo(Disparo, Alvo, Resultado, Mensagem) :-
    registo_disparo_(Seq, Disparo),
    registo_(Seq, Alvo, _, _, _, Resultado, Mensagem),
    !.

evento(Seq, Tipo, Nome, Codigo, Modulo, ArtigoId) :-
    evento_(Seq, Tipo, Nome, Codigo, Modulo, ArtigoId).

acrescentar_evento(Tipo, Nome, Codigo, Modulo, ArtigoId) :-
    proximo_seq(Seq),
    assertz(evento_(Seq, Tipo, Nome, Codigo, Modulo, ArtigoId)),
    (   Tipo == disparada
    ->  definir_disparo_atual(Seq)
    ;   true
    ).

alteracao(Seq, Alvo, Campo, Antes, Depois) :- alteracao_(Seq, Alvo, Campo, Antes, Depois).

disparo_atual(Seq) :- disparo_atual_(Seq).

definir_disparo_atual(Seq) :-
    retractall(disparo_atual_(_)),
    assertz(disparo_atual_(Seq)).

versao(Alvo, V) :- ( versao_(Alvo, V0) -> V = V0 ; V = 0 ).

incrementar_versao(Alvo) :-
    versao(Alvo, V0),
    V is V0 + 1,
    retractall(versao_(Alvo, _)),
    assertz(versao_(Alvo, V)).

proximo_seq(Seq) :-
    retract(seq_(S0)),
    Seq is S0 + 1,
    assertz(seq_(Seq)).

%!  instantaneo(-Instantaneo) is det.
%
%   Valores finais dos campos de cada decisão: [pedido-[Campo=Valor, ...], artigo(Id)-[...], ...].
instantaneo(Instantaneo) :-
    alvos(Alvos),
    findall(Alvo-Campos,
            ( member(Alvo, Alvos),
              campos_decisao(Alvo, Nomes),
              findall(C=V, ( member(C, Nomes), decisao_(Alvo, C, V) ), Campos)
            ),
            Instantaneo).
