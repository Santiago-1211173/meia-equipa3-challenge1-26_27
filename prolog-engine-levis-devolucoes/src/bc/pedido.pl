:- encoding(utf8).
:- module(pedido, [
    normalizar_pedido/2,        % +Json, -Pedido
    normalizar_fraudes/3,       % +Json, +PedidoId, -Fraudes
    campo/3,                    % +Objeto, +Caminho, -Valor
    p/2,                        % +Caminho, -Valor          (pedido em avaliação)
    artigo/1,                   % ?ArtigoId                 (pela ordem do pedido)
    a/3,                        % +ArtigoId, +Caminho, -Valor
    artigo_dict/2,              % +ArtigoId, -Artigo
    dias_desde_compra/1,        % -Dias (ou null)
    dias_desde_envio/1,         % -Dias (ou null)
    compra_online/0,
    colaborador_autorizado/0,
    data_mais_dias/3,           % +Data, +Dias, -Data
    dias_entre/3,               % +DataInicio, +DataFim, -Dias
    enum_json/2,                % ?Atomo, ?TextoJson
    valor_json/2,               % +ValorProlog, -ValorJson
    caminho_valido/1            % +Segmentos: [chave(K), indice(I), ...]
]).

/** <module> Pedido de devolução: normalização e acesso aos factos de entrada

O pedido chega em JSON (o formato do modelo Java ou o `PedidoAvaliacaoRequest` da API) e é
normalizado num dict com todos os campos do modelo:

  - os valores de enumerados passam a átomos em minúsculas (`"KEY_HOLDER"` -> `key_holder`);
  - as datas passam a `date(A, M, D)`;
  - os campos em falta recebem o valor por omissão do modelo Java (ex.: `forneceDados = true`,
    `conjuntoCompleto = true`) ou `null` quando o modelo os admite nulos.

As regras leem o pedido em avaliação através de p/2 e a/3, que nunca falham: devolvem `null`
quando um objeto do caminho não existe (como os testes `!= null` do DRL).
*/

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module('../motor/memoria', [pedido_atual/1]).

% ---------------------------------------------------------------------------------------------
% Esquema do modelo (PedidoDevolucao e objetos associados)
% ---------------------------------------------------------------------------------------------

%   esquema(Objeto, Campo, Tipo, Omissao)
esquema(pedido, id, texto, null).
esquema(pedido, dataPedido, data, null).
esquema(pedido, tipoPedido, enum, null).
esquema(pedido, loja, objeto(loja), null).
esquema(pedido, colaborador, objeto(colaborador), null).
esquema(pedido, cliente, objeto(cliente), null).
esquema(pedido, compraOriginal, objeto(compra), null).
esquema(pedido, comprovativo, objeto(comprovativo), null).
esquema(pedido, artigos, lista(artigo), []).
esquema(pedido, artigosTroca, lista(artigoTroca), []).
esquema(pedido, portalOnlineDisponivel, booleano, true).
esquema(pedido, politicaPermiteAsCegasOnline, booleano, false).
esquema(pedido, pedidoExcecao, objeto(excecao), null).

esquema(loja, codigo, texto, null).
esquema(loja, nome, texto, null).
esquema(loja, mercado, enum, null).
esquema(loja, tipoLoja, enum, null).
esquema(loja, lojaBackPocket, booleano, false).
esquema(loja, coberturaLojaUnica, booleano, false).
esquema(loja, skusSortido, lista(texto), []).

esquema(colaborador, id, texto, null).
esquema(colaborador, nome, texto, null).
esquema(colaborador, funcao, enum, null).
esquema(colaborador, aprovadoPeloDM, booleano, false).
esquema(colaborador, idCredencialPOS, texto, null).

esquema(cliente, id, texto, null).
esquema(cliente, forneceDados, booleano, true).
esquema(cliente, barreiraLinguistica, booleano, false).
esquema(cliente, contestaResultado, booleano, false).
esquema(cliente, agitado, booleano, false).

esquema(compra, idTransacao, texto, null).
esquema(compra, canal, enum, null).
esquema(compra, dataCompra, data, null).
esquema(compra, dataEnvio, data, null).
esquema(compra, pagamento, objeto(pagamento), null).
esquema(compra, idStylistVenda, texto, null).
esquema(compra, quantidadeComprada, numero, 0).
esquema(compra, promocaoEscaloes, booleano, false).
esquema(compra, encomendaEncontrada, booleano, false).
esquema(compra, ajustePrecoAplicado, booleano, false).
esquema(compra, compraOferta, booleano, false).

esquema(pagamento, meio, enum, null).
esquema(pagamento, valorPago, numero, null).
esquema(pagamento, estadoConta, enum, null).
esquema(pagamento, cartaoFisicoPresente, booleano, false).
esquema(pagamento, reembolsoOriginalRecusado, booleano, false).
esquema(pagamento, acessoAplicacaoPagamento, booleano, true).

esquema(comprovativo, tipo, enum, null).
esquema(comprovativo, confirmaCompra, booleano, false).
esquema(comprovativo, reciboOriginal, booleano, false).
esquema(comprovativo, clienteMantemRecibo, booleano, false).
esquema(comprovativo, incluiOutrosArtigos, booleano, false).

esquema(artigo, id, texto, null).
esquema(artigo, produto, objeto(produto), null).
esquema(artigo, quantidade, numero, 1).
esquema(artigo, precoPago, numero, null).
esquema(artigo, estado, objeto(estado), null).
esquema(artigo, entreCanais, booleano, false).
esquema(artigo, revendivel, booleano_nulo, null).
esquema(artigo, valorCalculadoPos, numero, null).

esquema(artigoTroca, produto, objeto(produto), null).
esquema(artigoTroca, apenasMudaTamanho, booleano, false).
esquema(artigoTroca, precoVenda, numero, null).

esquema(produto, sku, texto, null).
esquema(produto, skuReconhecidoPOS, booleano, false).
esquema(produto, marca, enum, null).
esquema(produto, categoria, enum, null).
esquema(produto, grossista, booleano, false).
esquema(produto, vendidoNaLoja, booleano, false).
esquema(produto, produtoFranquia, booleano, false).
esquema(produto, pvpOriginal, numero, null).
esquema(produto, precoAtual, numero, null).
esquema(produto, emSaldo, booleano, false).

esquema(estado, condicaoUso, enum, null).
esquema(estado, etiquetas, enum, null).
esquema(estado, personalizado, booleano, false).
esquema(estado, alterado, booleano, false).
esquema(estado, embainhado, booleano, false).
esquema(estado, defeitoFabricoConfirmado, booleano, false).
esquema(estado, sujoOuInseguro, booleano, false).
esquema(estado, danificado, booleano, false).
esquema(estado, etiquetaPrecoCorreta, booleano, true).
esquema(estado, rfidCorreto, booleano, true).
esquema(estado, embalagemIntacta, booleano, false).
esquema(estado, conjuntoCompleto, booleano, true).

esquema(excecao, motivo, texto, null).
esquema(excecao, resolucaoPedida, enum, null).
esquema(excecao, exigeMeioProibido, booleano, false).
esquema(excecao, exigeSkuIncorreto, booleano, false).
esquema(excecao, envolveProdutoExcluido, booleano, false).
esquema(excecao, contornaProcessoObrigatorio, booleano, false).
esquema(excecao, concluivelNoSistema, booleano, true).
esquema(excecao, aprovada, booleano_nulo, null).
esquema(excecao, aprovador, objeto(colaborador), null).
esquema(excecao, preocupacaoCliente, texto, null).

esquema(pedido, indicadoresFraude, lista(fraude), []).
esquema(fraude, pedidoId, texto, null).
esquema(fraude, descricao, texto, null).
esquema(fraude, nivelRisco, enum, null).

%!  caminho_valido(+Segmentos) is semidet.
%
%   O caminho (ex.: [chave(artigos), indice(0), chave(revendivel)]) existe no modelo do pedido.
caminho_valido(Segmentos) :-
    caminho_valido(Segmentos, objeto(pedido)).

caminho_valido([], _).
caminho_valido([chave(K)|Resto], objeto(Tipo)) :-
    esquema(Tipo, K, TipoCampo, _),
    caminho_valido(Resto, TipoCampo).
caminho_valido([indice(I)|Resto], lista(Tipo)) :-
    integer(I), I >= 0,
    (   memberchk(Tipo, [texto, numero]) -> Resto == [] ; caminho_valido(Resto, objeto(Tipo)) ).

% ---------------------------------------------------------------------------------------------
% Normalização
% ---------------------------------------------------------------------------------------------

%!  normalizar_pedido(+Json, -Pedido) is det.
%
%   Json é um dict lido de JSON (json_read_dict/3). Os campos desconhecidos são ignorados.
normalizar_pedido(Json, Pedido) :-
    normalizar_objeto(pedido, Json, Pedido).

normalizar_objeto(_, null, null) :- !.
normalizar_objeto(Tipo, Json, Objeto) :-
    is_dict(Json),
    !,
    findall(Campo-Valor,
            ( esquema(Tipo, Campo, TipoCampo, Omissao),
              (   get_dict(Campo, Json, Bruto), Bruto \== null
              ->  normalizar_valor(TipoCampo, Bruto, Valor)
              ;   Valor = Omissao
              )
            ),
            Pares),
    dict_pairs(Objeto, Tipo, Pares).
normalizar_objeto(Tipo, Json, _) :-
    throw(error(type_error(objeto(Tipo), Json), _)).

normalizar_valor(texto, V, T) :- !, ( string(V) -> T = V ; term_string(V, T0), T = T0 ).
normalizar_valor(numero, V, N) :- !, ( number(V) -> N = V ; atom_number(V, N) ).
normalizar_valor(booleano, V, B) :- !, booleano(V, B).
normalizar_valor(booleano_nulo, V, B) :- !, booleano(V, B).
normalizar_valor(enum, V, A) :- !, enum_json(A, V).
normalizar_valor(data, V, D) :- !, texto_data(V, D).
normalizar_valor(objeto(Tipo), V, O) :- !, normalizar_objeto(Tipo, V, O).
normalizar_valor(lista(Tipo), V, L) :- !,
    must_be(list, V),
    maplist(normalizar_elemento(Tipo), V, L).

normalizar_elemento(texto, V, T) :- !, normalizar_valor(texto, V, T).
normalizar_elemento(Tipo, V, O) :- normalizar_objeto(Tipo, V, O).

booleano(true, true) :- !.
booleano(false, false) :- !.
booleano("true", true) :- !.
booleano("false", false) :- !.
booleano(V, _) :- throw(error(type_error(booleano, V), _)).

%!  enum_json(?Atomo, ?Texto) is det.
%
%   Converte entre o valor de enumerado em JSON ("LEAD_CASHIER") e o átomo usado nas regras
%   (lead_cashier).
enum_json(A, T) :-
    (   nonvar(T)
    ->  ( string(T) -> S = T ; atom_string(T, S) ),
        string_lower(S, Min),
        atom_string(A, Min)
    ;   atom_string(A, S),
        string_upper(S, T)
    ).

texto_data(date(A, M, D), date(A, M, D)) :- !.
texto_data(Texto, date(A, M, D)) :-
    split_string(Texto, "-", "", [SA, SM, SD]),
    number_string(A, SA), number_string(M, SM), number_string(D, SD),
    !.
texto_data(Texto, _) :- throw(error(type_error(data, Texto), _)).

%!  normalizar_fraudes(+Json, +PedidoId, -Fraudes) is det.
%
%   Lista de indícios de fraude: fraude(Descricao, NivelRisco). Aceita o formato do modelo
%   (com pedidoId, que tem de coincidir com o pedido) e o da API (sem pedidoId).
normalizar_fraudes(null, _, []) :- !.
normalizar_fraudes(Lista, PedidoId, Fraudes) :-
    must_be(list, Lista),
    findall(fraude(Descricao, Nivel),
            ( member(F, Lista),
              (   get_dict(pedidoId, F, Id), Id \== null
              ->  normalizar_valor(texto, Id, IdTexto), IdTexto == PedidoId
              ;   true
              ),
              ( get_dict(descricao, F, D0), D0 \== null -> normalizar_valor(texto, D0, Descricao) ; Descricao = "" ),
              ( get_dict(nivelRisco, F, N0), N0 \== null -> enum_json(Nivel, N0) ; Nivel = null )
            ),
            Fraudes).

% ---------------------------------------------------------------------------------------------
% Acesso aos factos do pedido em avaliação
% ---------------------------------------------------------------------------------------------

%!  campo(+Objeto, +Caminho, -Valor) is det.
%
%   Valor de um caminho (lista de campos) num objeto normalizado; `null` se algum objeto
%   intermédio for nulo.
campo(Objeto, Caminho, Valor) :-
    campo_(Objeto, Caminho, V),
    Valor = V.

campo_(Valor, [], Valor) :- !.
campo_(null, _, null) :- !.
campo_(Objeto, [Campo|Resto], Valor) :-
    (   get_dict(Campo, Objeto, V0)
    ->  campo_(V0, Resto, Valor)
    ;   Valor = null
    ).

p(Caminho, Valor) :-
    pedido_atual(P),
    campo(P, Caminho, Valor).

artigo(Id) :-
    pedido_atual(P),
    member(A, P.artigos),
    Id = A.id.

artigo_dict(Id, Artigo) :-
    pedido_atual(P),
    member(Artigo, P.artigos),
    Artigo.id == Id,
    !.

a(Id, Caminho, Valor) :-
    (   artigo_dict(Id, Artigo)
    ->  campo(Artigo, Caminho, Valor)
    ;   Valor = null
    ).

dias_desde_compra(Dias) :- dias_desde([compraOriginal, dataCompra], Dias).
dias_desde_envio(Dias) :- dias_desde([compraOriginal, dataEnvio], Dias).

dias_desde(Caminho, Dias) :-
    p(Caminho, Data),
    p([dataPedido], DataPedido),
    (   ( Data == null ; DataPedido == null )
    ->  Dias = null
    ;   dias_entre(Data, DataPedido, Dias)
    ).

dias_entre(date(A1, M1, D1), date(A2, M2, D2), Dias) :-
    date_time_stamp(date(A1, M1, D1, 12, 0, 0, 0, -, -), S1),
    date_time_stamp(date(A2, M2, D2, 12, 0, 0, 0, -, -), S2),
    Dias is round((S2 - S1) / 86400).

data_mais_dias(date(A, M, D), N, date(A2, M2, D2)) :-
    D1 is D + N,
    date_time_stamp(date(A, M, D1, 12, 0, 0, 0, -, -), S),
    stamp_date_time(S, date(A2, M2, D2, _, _, _, _, _, _), 'UTC').

%!  compra_online is semidet.
%
%   isCompraOnline() do modelo: compra em levi.com ou levi.ca.
compra_online :-
    p([compraOriginal, canal], Canal),
    memberchk(Canal, [levi_com, levi_ca]).

%!  colaborador_autorizado is semidet.
%
%   Colaborador.isAutorizado(): Gestão da Loja, Key Holder e XStore Manager (A-23); Lead Cashier
%   e Elevated Stylist só com aprovação do District Manager; Stylist nunca.
colaborador_autorizado :-
    p([colaborador, funcao], Funcao),
    (   memberchk(Funcao, [gestao_loja, key_holder, xstore_manager])
    ->  true
    ;   memberchk(Funcao, [lead_cashier, elevated_stylist]),
        p([colaborador, aprovadoPeloDM], true)
    ).

% ---------------------------------------------------------------------------------------------
% Conversão para JSON
% ---------------------------------------------------------------------------------------------

%!  valor_json(+Valor, -Json) is det.
%
%   Valores de saída: átomos de enumerado em maiúsculas, datas em ISO-8601, valores monetários
%   com duas casas decimais no maximo.
valor_json(null, null) :- !.
valor_json(true, true) :- !.
valor_json(false, false) :- !.
valor_json(date(A, M, D), Texto) :- !, format(string(Texto), "~d-~|~`0t~d~2+-~|~`0t~d~2+", [A, M, D]).
valor_json(N, J) :- float(N), !, J is round(N * 100) / 100.
valor_json(N, N) :- number(N), !.
valor_json(S, S) :- string(S), !.
valor_json(A, T) :- atom(A), !, enum_json(A, T0), atom_string(Atomo, T0), T = Atomo.
valor_json(T, S) :- term_string(T, S).
