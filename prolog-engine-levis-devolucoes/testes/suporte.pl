:- encoding(utf8).
:- module(suporte, [
    um_pedido/1,                % -Json: o caso padrão do PedidoBuilder
    com/3,                      % +Json0, +Alteracoes, -Json
    mais_um_artigo/4,           % +Json0, +Id, +Alteracoes, -Json
    sem_comprovativo/2,         % +Json0, -Json
    excecao/3,                  % +Json0, +CamposExcecao, -Json
    avaliar/1,                  % +Json
    avaliar/2,                  % +Json, +Fraudes (lista Descricao-Nivel)
    disparos/1,                 % -Codigos pela ordem de disparo
    regras_de_negocio/1,        % -Codigos sem as regras de suporte OUT-
    disparou/1,                 % +Codigo
    nao_disparou/1,             % +Codigo
    vezes/2,                    % +Codigo, -N
    pedido/2,                   % +Campo, -Valor
    artigo/3,                   % +ArtigoId, +Campo, -Valor
    registo/3,                  % +Codigo, -Resultado, -Mensagem (primeiro registo da regra)
    registos_artigo/2,          % +ArtigoId, -Codigos (sem M7 e M9)
    disparou_artigo/2,          % +ArtigoId, +Codigo (registo na decisão do artigo)
    contem/2,                   % +Texto, +Parte
    comeca_por/2,               % +Lista, +Prefixo
    sequencia/2,                % +Lista, +Subsequencia (elementos consecutivos)
    dias_antes/2,               % +Dias, -DataTexto (antes de 2026-03-31)
    dias_desde_compra/3,        % +Json0, +Dias, -Json
    dias_desde_envio/3          % +Json0, +Dias, -Json
]).

/** <module> Suporte dos testes (equivalente ao PedidoBuilder e ao MotorTeste do Drools)

O pedido por omissão é o do `PedidoBuilder`: loja Mainline nos EUA, Key Holder, compra Mainline
há 10 dias paga a crédito, recibo impresso original e um artigo Levi's de vestuário, não usado
e com etiquetas colocadas. As alterações são pares Caminho-Valor no formato do "E se?".
*/

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module('../src/motor/memoria', [decisao/3, registo/7, evento/6]).
:- use_module('../src/servico', [preparar_pedido/3, avaliar_pedido/2]).
:- use_module('../src/explicacoes/explicacoes', [aplicar_alteracoes/3]).
:- use_module('../src/bc/pedido', [data_mais_dias/3, valor_json/2]).

um_pedido(_{
    id:"P-1", dataPedido:"2026-03-31", tipoPedido:"DEVOLUCAO",
    loja:_{codigo:"L-001", nome:"Loja de teste", mercado:"EUA", tipoLoja:"MAINLINE"},
    colaborador:_{id:"C-1", nome:"Colaborador de teste", funcao:"KEY_HOLDER", idCredencialPOS:"POS-C-1"},
    cliente:_{},
    compraOriginal:_{idTransacao:"T-1", canal:"MAINLINE", dataCompra:"2026-03-21",
                     pagamento:_{meio:"CREDITO", valorPago:98.0, estadoConta:"ATIVA"},
                     idStylistVenda:"S-7", quantidadeComprada:1},
    comprovativo:_{tipo:"RECIBO_IMPRESSO", confirmaCompra:true, reciboOriginal:true},
    artigos:[Artigo]
}) :-
    artigo_padrao("A-1", Artigo).

artigo_padrao(Id, _{
    id:Id, precoPago:98.0, quantidade:1,
    produto:_{sku:Sku, skuReconhecidoPOS:true, marca:"LEVIS", categoria:"VESTUARIO", vendidoNaLoja:true,
              pvpOriginal:98.0, precoAtual:98.0},
    estado:_{condicaoUso:"NAO_USADO", etiquetas:"COLOCADAS"}
}) :-
    string_concat("501-", Id, Sku).

com(J0, Alteracoes, J) :- aplicar_alteracoes(J0, Alteracoes, J).

mais_um_artigo(J0, Id, Alteracoes, J) :-
    artigo_padrao(Id, A0),
    com(A0, Alteracoes, A),
    append(J0.artigos, [A], Artigos),
    J = J0.put(artigos, Artigos).

sem_comprovativo(J0, J) :-
    com(J0, ["comprovativo"-null, "compraOriginal.dataCompra"-null], J).

excecao(J0, Campos, J) :-
    J = J0.put(pedidoExcecao, Campos).

avaliar(J) :- avaliar(J, []).
avaliar(J0, Fraudes) :-
    findall(_{descricao:D, nivelRisco:N}, member(D-N, Fraudes), Lista),
    J = J0.put(indicadoresFraude, Lista),
    preparar_pedido(J, Pedido, F),
    avaliar_pedido(Pedido, F).

disparos(Codigos) :-
    findall(C, evento(_, disparada, _, C, _, _), Codigos).

regras_de_negocio(Codigos) :-
    disparos(Todos),
    exclude([C]>>sub_atom(C, 0, _, _, 'OUT-'), Todos, Codigos).

disparou(C) :- disparos(L), memberchk(C, L), !.
nao_disparou(C) :- \+ disparou(C).

vezes(C, N) :- disparos(L), include(==(C), L, Cs), length(Cs, N).

pedido(Campo, V) :- once(decisao(pedido, Campo, V0)), V = V0.
artigo(Id, Campo, V) :- once(decisao(artigo(Id), Campo, V0)), V = V0.

registo(Codigo, Resultado, Mensagem) :-
    findall(S-(R-M), registo(S, _, Codigo, _, _, R, M), Rs),
    msort(Rs, [_-(Resultado-Mensagem)|_]).

registos_artigo(Id, Codigos) :-
    findall(C, ( registo(_, artigo(Id), C, _, Modulo, _, _), Modulo \== m7, Modulo \== m9 ), Codigos).

disparou_artigo(Id, Codigo) :- registo(_, artigo(Id), Codigo, _, _, _, _), !.

contem(Texto, Parte) :- sub_string(Texto, _, _, _, Parte), !.

comeca_por(Lista, Prefixo) :- append(Prefixo, _, Lista), !.

sequencia(Lista, Sub) :- append(_, Resto, Lista), append(Sub, _, Resto), !.

dias_antes(Dias, Texto) :-
    Menos is -Dias,
    data_mais_dias(date(2026, 3, 31), Menos, Data),
    valor_json(Data, Texto).

dias_desde_compra(J0, Dias, J) :- dias_antes(Dias, D), com(J0, ["compraOriginal.dataCompra"-D], J).
dias_desde_envio(J0, Dias, J) :- dias_antes(Dias, D), com(J0, ["compraOriginal.dataEnvio"-D], J).
