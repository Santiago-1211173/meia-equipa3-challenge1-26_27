:- encoding(utf8).
:- module(servico, [
    preparar_pedido/3,          % +Json, -Pedido, -Fraudes
    avaliar_pedido/2,           % +Pedido, +Fraudes
    avaliar_json/2,             % +Json, -DecisaoJson
    decisao_json/2,             % +Extra, -DecisaoJson
    disparos/1,                 % -Disparos
    codigos_disparados/1,       % -Codigos (pedido e artigos)
    codigos_disparados_alvo/2,  % +Alvo, -Codigos
    versao_base_conhecimento/1
]).

/** <module> Serviço pericial: preparar o pedido, avaliar e montar a decisão

Camada entre a entrada (JSON da API, cenários de teste, consola) e o motor. Monta a decisão no
formato do `DecisaoResponse` da API Drools (OUT-001 a OUT-008, resultado por artigo e rasto das
regras disparadas).
*/

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(motor/memoria).
:- use_module(motor/motor).
:- use_module(bc/pedido).

versao_base_conhecimento("pt.isep.meia:prolog-engine-levis-devolucoes:1.0.0").

%!  preparar_pedido(+Json, -Pedido, -Fraudes) is det.
%
%   Aceita dois formatos:
%     - o dos cenários de teste: `{"pedido": {...modelo...}, "indicadoresFraude": [...]}`;
%     - o da API (`PedidoAvaliacaoRequest`), com os indícios de fraude dentro do pedido. Como esta
%       API não usa tokens, o colaborador vem no campo `colaborador` do próprio pedido.
preparar_pedido(Json, Pedido, Fraudes) :-
    (   get_dict(pedido, Json, JsonPedido), is_dict(JsonPedido)
    ->  ( get_dict(indicadoresFraude, Json, JsonFraudes) -> true ; JsonFraudes = [] )
    ;   JsonPedido = Json,
        ( get_dict(indicadoresFraude, Json, JsonFraudes) -> true ; JsonFraudes = [] )
    ),
    normalizar_pedido(JsonPedido, Pedido),
    normalizar_fraudes(JsonFraudes, Pedido.id, Fraudes).

avaliar_pedido(Pedido, Fraudes) :-
    motor:avaliar(Pedido, Fraudes).

%!  avaliar_json(+Json, -DecisaoJson) is det.
avaliar_json(Json, Decisao) :-
    preparar_pedido(Json, Pedido, Fraudes),
    avaliar_pedido(Pedido, Fraudes),
    decisao_json(_{}, Decisao).

%!  disparos(-Disparos) is det.
%
%   Regras disparadas, pela ordem: disparo(Seq, Nome, Codigo, Modulo, ArtigoId).
disparos(Disparos) :-
    findall(disparo(Seq, Nome, Codigo, Modulo, ArtigoId),
            evento(Seq, disparada, Nome, Codigo, Modulo, ArtigoId),
            Disparos).

codigos_disparados(Codigos) :-
    findall(C, evento(_, disparada, _, C, _, _), Cs),
    list_to_set(Cs, Codigos).

codigos_disparados_alvo(Alvo, Codigos) :-
    findall(C, registo(_, Alvo, C, _, _, _, _), Cs),
    list_to_set(Cs, Codigos).

%!  decisao_json(+Extra, -Json) is det.
%
%   A decisão da avaliação em memória, no formato do DecisaoResponse. Extra pode trazer
%   avaliacaoId e avaliadaEm.
decisao_json(Extra, Json) :-
    pedido_atual(Pedido),
    versao_base_conhecimento(Versao),
    ( get_dict(avaliacaoId, Extra, AvId) -> true ; AvId = null ),
    ( get_dict(avaliadaEm, Extra, Em) -> true ; Em = null ),
    campos_json(pedido, [elegibilidade, tipoVerificacao, tipoTransacao, valorDevolucao, baseValor,
                         meioReembolso, aprovacao, processo, terminal, excecaoRecusada], Campos),
    documentacao_json(Documentacao),
    alvos([pedido|Artigos]),
    maplist(artigo_json, Artigos, ArtigosJson),
    regras_json(Regras, AValidar),
    dict_pairs(Base, decisao, Campos),
    Json = Base.put(_{avaliacaoId:AvId, pedidoId:Pedido.id, avaliadaEm:Em,
                      versaoBaseConhecimento:Versao, documentacao:Documentacao,
                      artigos:ArtigosJson, regras:Regras, regrasAValidar:AValidar}).

campos_json(Alvo, Nomes, Pares) :-
    findall(Nome-J, ( member(Nome, Nomes), decisao(Alvo, Nome, V), valor_json(V, J) ), Pares).

documentacao_json(Doc) :-
    findall(Nome-J,
            ( decisao(pedido, Campo, V),
              atom_concat('documentacao.', Nome, Campo),
              valor_json_texto(V, J) ),
            Pares),
    dict_pairs(Doc, documentacao, Pares).

valor_json_texto(V, J) :- ( string(V) -> J = V ; valor_json(V, J) ).

artigo_json(artigo(Id), Json) :-
    campos_json(artigo(Id), [elegibilidade, tipoTransacao, valorDevolucao, baseValor, destino,
                             descontoSaldo, aprovacao, terminal], Pares),
    dict_pairs(Json0, artigo, Pares),
    Json = Json0.put(artigoId, Id).

regras_json(Regras, AValidar) :-
    disparos(Disparos),
    findall(R, ( nth1(Ordem, Disparos, D), regra_disparada_json(Ordem, D, R) ), Regras),
    findall(C, ( member(disparo(_, Nome, C, _, _), Disparos), regra_info(Nome, I), I.a_validar == true ), Cs),
    list_to_set(Cs, AValidar).

regra_disparada_json(Ordem, disparo(Seq, Nome, Codigo, Modulo, ArtigoId), Json) :-
    regra_info(Nome, Info),
    (   registo_do_disparo(Seq, _, Resultado, Mensagem) -> true ; Resultado = null, Mensagem = null ),
    valor_json(Modulo, ModuloJson),
    valor_json(Resultado, ResultadoJson),
    atom_string(Nome, NomeTexto),
    Json = _{ordem:Ordem, codigoRegra:Codigo, nomeRegra:NomeTexto, modulo:ModuloJson,
             artigoId:ArtigoId, resultado:ResultadoJson, mensagem:Mensagem, aValidar:Info.a_validar}.
