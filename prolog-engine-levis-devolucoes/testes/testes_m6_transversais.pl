:- encoding(utf8).
/*  Testes de M6 (resultado, troca e exceções), das interrupções transversais (EX-008, PC-008) e
    da robustez com dados em falta.
    Porta de ResultadoEExcecoesTest, TransversaisTest e RobustezDadosEmFaltaTest do projeto Drools.
*/

:- use_module(library(plunit)).
:- use_module(suporte).
:- use_module('../src/motor/memoria', [suspenso/1, decisao/3]).
:- use_module('../src/servico', [preparar_pedido/3, avaliar_pedido/2]).

troca(ApenasTamanho, P) :-
    um_pedido(P0), com(P0, ["tipoPedido"-"TROCA"], P1),
    P = P1.put(artigosTroca, [_{produto:_{sku:"501-NOVO", skuReconhecidoPOS:true, marca:"LEVIS", categoria:"VESTUARIO"},
                                apenasMudaTamanho:ApenasTamanho, precoVenda:98.0}]).

%   Cliente que contesta e fica agitado, com um pedido de exceção.
cliente_agitado_com_excecao(Campos, P) :-
    um_pedido(P0),
    com(P0, ["cliente.contestaResultado"-true, "cliente.agitado"-true], P1),
    E0 = _{motivo:"Quer uma exceção à política"},
    excecao(P1, E0.put(Campos), P).

% ---------------------------------------------------------------------------------------------
:- begin_tests(m6_trocas).

test('EP-001 troca com recibo só de tamanho mantém o preço') :-
    troca(true, P), avaliar(P),
    disparou('PT-003'), disparou('EP-001'), nao_disparou('EP-002'),
    registo('EP-001', _, Msg), contem(Msg, "original ou promocional").

test('EP-001 troca às cegas só de tamanho não tem correspondência de promoção') :-
    troca(true, P0), sem_comprovativo(P0, P), avaliar(P),
    disparou('PT-005'), nao_disparou('EP-001').

test('EP-002 troca de modelo ou cor vende o novo ao preço atual') :-
    troca(false, P), avaliar(P),
    disparou('EP-002'), nao_disparou('EP-001').

test('EP-002 troca às cegas de modelo') :-
    troca(false, P0), sem_comprovativo(P0, P), avaliar(P),
    disparou('PT-005'), disparou('EP-002').

test('EP-001 e EP-002 não disparam numa devolução') :-
    um_pedido(P), avaliar(P),
    nao_disparou('EP-001'), nao_disparou('EP-002').

:- end_tests(m6_trocas).

% ---------------------------------------------------------------------------------------------
:- begin_tests(m6_revisao_e_escalonamento).

test('EX-001 artigo em revisão pede o critério da gestão') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.etiquetas"-"SOLTAS"], P), avaliar(P),
    disparou('PC-002'), disparou('EX-001'), pedido(aprovacao, responsavel_senior),
    registo('EX-001', _, Msg), contem(Msg, "revenda"), contem(Msg, "fraude").

test('EX-001 pedido em revisão pede o critério da gestão') :-
    um_pedido(P0), dias_desde_compra(P0, 40, P), avaliar(P),
    disparou('PT-004'), disparou('EX-001').

test('EX-001 sem revisão não dispara') :-
    um_pedido(P), avaliar(P), nao_disparou('EX-001').

test('EX-002 cliente que contesta recebe a explicação da política') :-
    um_pedido(P0), com(P0, ["cliente.contestaResultado"-true], P), avaliar(P),
    disparou('EX-002'), pedido(elegibilidade, permitir).

test('EX-002 dispara mesmo depois de uma paragem obrigatória (ADR 0004)') :-
    um_pedido(P0), com(P0, ["compraOriginal.canal"-"GROSSISTA", "cliente.contestaResultado"-true], P), avaliar(P),
    pedido(terminal, true), disparos(D), sequencia(D, ['CH-008', 'EX-002']), pedido(elegibilidade, recusar).

test('EX-002 sem contestação não dispara') :-
    um_pedido(P), avaliar(P), nao_disparou('EX-002').

test('EX-003 cliente agitado é escalado sem mudar a elegibilidade') :-
    um_pedido(P0), com(P0, ["cliente.contestaResultado"-true, "cliente.agitado"-true], P), avaliar(P),
    disparos(D), sequencia(D, ['EX-002', 'EX-003']),
    pedido(aprovacao, responsavel_senior), pedido(elegibilidade, permitir),
    registo('EX-003', _, Msg), contem(Msg, "não cria elegibilidade").

test('EX-003 agitação sem contestação não escala') :-
    um_pedido(P0), com(P0, ["cliente.agitado"-true], P), avaliar(P),
    nao_disparou('EX-003').

:- end_tests(m6_revisao_e_escalonamento).

% ---------------------------------------------------------------------------------------------
:- begin_tests(m6_excecoes).

test('EX-004 exceção que cumpre os controlos pode ser aprovada') :-
    cliente_agitado_com_excecao(_{}, P), avaliar(P),
    disparos(D), sequencia(D, ['EX-003', 'EX-004']),
    registo('EX-004', null, _), pedido(excecaoRecusada, false).

test('EX-004 com uma paragem obrigatória não pode ser aprovada') :-
    cliente_agitado_com_excecao(_{}, P0), mais_um_artigo(P0, "A-2", ["estado.alterado"-true], P), avaliar(P),
    registo('EX-004', recusar, _), pedido(excecaoRecusada, true).

test('EX-004 compra não verificada não pode ser aprovada') :-
    cliente_agitado_com_excecao(_{}, P0), sem_comprovativo(P0, P), avaliar(P),
    registo('EX-004', recusar, _).

test('EX-004 resultado não concluível no sistema não pode ser aprovado (A-18)') :-
    cliente_agitado_com_excecao(_{concluivelNoSistema:false}, P), avaliar(P),
    registo('EX-004', recusar, _).

test('EX-006 anula a aprovação de EX-004') :-
    cliente_agitado_com_excecao(_{exigeMeioProibido:true}, P), avaliar(P),
    disparos(D), sequencia(D, ['EX-004', 'EX-006']),
    registo('EX-006', recusar, _), pedido(excecaoRecusada, true), nao_disparou('EX-005').

test('EX-006 exceção que contorna o processo obrigatório numa revisão') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.etiquetas"-"SOLTAS"], P1),
    excecao(P1, _{contornaProcessoObrigatorio:true}, P), avaliar(P),
    disparou('EX-001'), disparou('EX-006').

test('EX-005 exceção elegível com artigo vendável prefere a resolução menos abrangente') :-
    cliente_agitado_com_excecao(_{}, P0), com(P0, ["artigos[0].revendivel"-true], P), avaliar(P),
    disparos(D), sequencia(D, ['EX-004', 'EX-005']),
    registo('EX-005', _, Msg), contem(Msg, "troca pelo mesmo artigo"), contem(Msg, "crédito de loja").

test('EX-005 exceção com artigo não vendável é recusada') :-
    cliente_agitado_com_excecao(_{}, P0), com(P0, ["artigos[0].revendivel"-false], P), avaliar(P),
    registo('EX-005', recusar, _), pedido(excecaoRecusada, true).

test('EX-005 sem avaliação de revenda não recomenda') :-
    cliente_agitado_com_excecao(_{}, P), avaliar(P),
    nao_disparou('EX-005').

test('EX-005 artigo usado com exceção aprovada só troca pelo mesmo artigo') :-
    cliente_agitado_com_excecao(_{aprovada:true}, P0),
    com(P0, ["artigos[0].estado.condicaoUso"-"USADO", "artigos[0].revendivel"-true], P), avaliar(P),
    artigo("A-1", tipoTransacao, troca_mesmo_artigo).

:- end_tests(m6_excecoes).

% ---------------------------------------------------------------------------------------------
avaliar_com_indicios(J0, Indicios) :-
    J = J0.put(indicadoresFraude, Indicios),
    preparar_pedido(J, Pedido, Fraudes),
    avaliar_pedido(Pedido, Fraudes).

:- begin_tests(transversais).

test('EX-008 indício relevante suspende a transação', [forall(member(N, ["SIGNIFICATIVO", "CONFIRMADO"]))]) :-
    um_pedido(P), avaliar(P, ["Recibo adulterado"-N]),
    suspenso(true),
    pedido(elegibilidade, rever), pedido(aprovacao, district_area), pedido(terminal, true),
    regras_de_negocio(['EX-008']),
    registo('EX-008', _, Msg), contem(Msg, "Recibo adulterado").

test('EX-008 indício de risco baixo não suspende (A-26)') :-
    um_pedido(P), avaliar(P, ["Hesitação na resposta"-"BAIXO"]),
    suspenso(false), nao_disparou('EX-008'), pedido(terminal, false).

test('EX-008 indício de outro pedido não suspende') :-
    um_pedido(P), avaliar_com_indicios(P, [_{pedidoId:"P-2", descricao:"Outro pedido", nivelRisco:"CONFIRMADO"}]),
    nao_disparou('EX-008').

test('EX-008 vários indícios suspendem uma só vez') :-
    um_pedido(P), avaliar(P, ["Recibo adulterado"-"CONFIRMADO", "Etiqueta trocada"-"SIGNIFICATIVO"]),
    regras_de_negocio(['EX-008']).

test('PC-008 isola o artigo por risco biológico') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.sujoOuInseguro"-true], P), avaliar(P),
    artigo("A-1", destino, risco_biologico), disparou_artigo("A-1", 'PC-008'),
    disparos(['PC-008'|_]), vezes('PC-008', 1).

test('PC-008 não altera a elegibilidade do artigo nem do pedido (A-15)') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.sujoOuInseguro"-true], P), avaliar(P),
    registo('PC-008', null, _),
    artigo("A-1", elegibilidade, permitir), artigo("A-1", terminal, false), pedido(terminal, false).

test('PC-008 só afeta o artigo inseguro') :-
    um_pedido(P0), mais_um_artigo(P0, "A-2", ["estado.sujoOuInseguro"-true], P), avaliar(P),
    artigo("A-1", destino, D1), D1 \== risco_biologico,
    artigo("A-2", destino, risco_biologico).

test('PC-008 isola o artigo mesmo com a transação suspensa por fraude (A-28)') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.sujoOuInseguro"-true], P),
    avaliar(P, ["Inconsistência"-"SIGNIFICATIVO"]),
    regras_de_negocio(['EX-008', 'PC-008']),
    artigo("A-1", destino, risco_biologico).

test('PC-008 artigo sem estado não dispara') :-
    um_pedido(P0), com(P0, ["artigos[0].estado"-null], P), avaliar(P),
    nao_disparou('PC-008').

:- end_tests(transversais).

% ---------------------------------------------------------------------------------------------
pedido_incompleto("sem compra original", ["compraOriginal"-null]).
pedido_incompleto("sem pagamento", ["compraOriginal.pagamento"-null]).
pedido_incompleto("sem canal", ["compraOriginal.canal"-null]).
pedido_incompleto("sem loja", ["loja"-null]).
pedido_incompleto("sem cliente", ["cliente"-null]).
pedido_incompleto("sem comprovativo", ["comprovativo"-null]).
pedido_incompleto("sem tipo de pedido", ["tipoPedido"-null]).
pedido_incompleto("sem data do pedido", ["dataPedido"-null]).
pedido_incompleto("artigo sem produto", ["artigos[0].produto"-null]).
pedido_incompleto("artigo sem estado", ["artigos[0].estado"-null]).
pedido_incompleto("artigo sem preço pago", ["artigos[0].precoPago"-null]).
pedido_incompleto("troca sem artigos de troca", ["tipoPedido"-"TROCA", "artigosTroca"-[]]).
pedido_incompleto("online sem pagamento", ["compraOriginal.canal"-"LEVI_COM", "compraOriginal.encomendaEncontrada"-true,
                                           "compraOriginal.pagamento"-null]).
pedido_incompleto("ajuste de preço sem compra original", ["tipoPedido"-"AJUSTE_PRECO", "compraOriginal"-null]).

:- begin_tests(robustez_dados_em_falta).

test('Avalia sem erros com dados em falta', [forall(pedido_incompleto(_, Alteracoes))]) :-
    um_pedido(P0), com(P0, Alteracoes, P),
    avaliar(P).

test('Avalia sem erros com dados em falta, às cegas', [forall(pedido_incompleto(_, Alteracoes))]) :-
    um_pedido(P0), com(P0, ["comprovativo"-null], P1),
    (   get_dict(compraOriginal, P1, C), C \== null -> com(P1, ["compraOriginal.dataCompra"-null], P2) ; P2 = P1 ),
    com(P2, Alteracoes, P),
    avaliar(P).

:- end_tests(robustez_dados_em_falta).
