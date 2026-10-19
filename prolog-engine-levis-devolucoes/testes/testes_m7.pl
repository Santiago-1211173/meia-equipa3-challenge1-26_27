:- encoding(utf8).
/*  Testes de M7: meio de reembolso e valor da devolução.
    Porta de MeioReembolsoTest e ValorDevolucaoTest do projeto Drools.
*/

:- use_module(library(plunit)).
:- use_module(suporte).

pago_com(Meio, P) :- um_pedido(P0), com(P0, ["compraOriginal.pagamento.meio"-Meio], P).

conta(Meio, Estado, Recusado, P) :-
    pago_com(Meio, P0),
    com(P0, ["compraOriginal.pagamento.estadoConta"-Estado, "compraOriginal.pagamento.reembolsoOriginalRecusado"-Recusado], P).

interac_no_canada(Presente, P) :-
    pago_com("INTERAC", P0),
    com(P0, ["loja.mercado"-"CANADA", "compraOriginal.pagamento.cartaoFisicoPresente"-Presente], P).

troca_com_preco(Preco, P) :-
    um_pedido(P0), com(P0, ["tipoPedido"-"TROCA"], P1),
    P = P1.put(artigosTroca, [_{produto:_{sku:"501-NOVO", skuReconhecidoPOS:true, marca:"LEVIS", categoria:"VESTUARIO"},
                                apenasMudaTamanho:false, precoVenda:Preco}]).

% ---------------------------------------------------------------------------------------------
:- begin_tests(m7_meio_reembolso).

test('TN-001 reembolso tokenizado sem pedir o cartão', [forall(member(M, ["CREDITO", "DEBITO"]))]) :-
    pago_com(M, P), avaliar(P),
    disparou('TN-001'), pedido(meioReembolso, meio_original),
    registo('TN-001', _, Msg), contem(Msg, "sem pedir ao cliente").

test('TN-001 devolução às cegas não usa regras TN') :-
    um_pedido(P0), sem_comprovativo(P0, P), avaliar(P),
    nao_disparou('TN-001').

test('TN-002 cartão perdido com conta ativa reembolsa a conta') :-
    conta("CREDITO", "ATIVA_CARTAO_PERDIDO", false, P), avaliar(P),
    disparos(D), sequencia(D, ['TN-001', 'TN-002']), pedido(meioReembolso, meio_original).

test('TN-003 conta encerrada: tenta primeiro o cartão original') :-
    conta("CREDITO", "ENCERRADA", false, P), avaliar(P),
    disparou('TN-003'), pedido(meioReembolso, meio_original).

test('TN-003 conta encerrada com recusa: meio alternativo') :-
    conta("CREDITO", "ENCERRADA", true, P), avaliar(P),
    pedido(meioReembolso, meio_alternativo).

test('TN-004 débito não recebe numerário antes da recusa') :-
    pago_com("DEBITO", P), avaliar(P),
    disparou('TN-004'), registo('TN-004', _, Msg), contem(Msg, "não emitir numerário").

test('TN-004 débito com conta encerrada e recusa já pode ter meio alternativo') :-
    conta("DEBITO", "ENCERRADA", true, P), avaliar(P),
    disparou('TN-003'), nao_disparou('TN-004'), pedido(meioReembolso, meio_alternativo).

test('TN-005 contactless reembolsa o cartão ou conta associada', [forall(member(M, ["APPLE_PAY", "GOOGLE_PAY"]))]) :-
    pago_com(M, P), avaliar(P),
    disparou('TN-005'), nao_disparou('TN-001').

test('TN-006 troca parcial reembolsa o saldo no cartão original') :-
    troca_com_preco(60.0, P), avaliar(P),
    disparou('EP-002'), disparou('TN-006'),
    registo('TN-006', _, Msg), contem(Msg, "38.00").

test('TN-006 troca sem saldo não reembolsa') :-
    troca_com_preco(128.0, P), avaliar(P),
    nao_disparou('TN-006').

test('TN-007 oferta com recibo reembolsa o cartão do comprador') :-
    um_pedido(P0), com(P0, ["tipoPedido"-"DEVOLUCAO_OFERTA"], P), avaliar(P),
    disparou('TN-007'), nao_disparou('TN-001'), pedido(meioReembolso, meio_original).

test('TN-007 o destinatário da oferta pode escolher crédito de loja (A-12)') :-
    um_pedido(P0), com(P0, ["tipoPedido"-"DEVOLUCAO_OFERTA"], P1),
    excecao(P1, _{resolucaoPedida:"CREDITO_LOJA"}, P), avaliar(P),
    pedido(tipoTransacao, credito_loja), pedido(meioReembolso, credito_loja).

test('TN-008 PayPal e Venmo pelo fluxo da aplicação', [forall(member(M, ["PAYPAL", "VENMO"]))]) :-
    pago_com(M, P), avaliar(P),
    pedido(meioReembolso, aplicacao_pagamento), pedido(processo, paypal_venmo), pedido(elegibilidade, permitir).

test('TN-008 sem acesso à aplicação: não substituir o meio, rever (A-05)') :-
    pago_com("PAYPAL", P0), com(P0, ["compraOriginal.pagamento.acessoAplicacaoPagamento"-false], P), avaliar(P),
    pedido(elegibilidade, rever), pedido(meioReembolso, aplicacao_pagamento), pedido(aprovacao, responsavel_senior).

test('TN-009 Afterpay em loja devolve tudo à Afterpay') :-
    pago_com("AFTERPAY", P), avaliar(P),
    pedido(processo, afterpay), registo('TN-009', _, Msg), contem(Msg, "recibo de devolução do POS").

test('TN-011 Interac no Canadá com o mesmo cartão') :-
    interac_no_canada(true, P), avaliar(P),
    disparou('TN-011'), nao_disparou('TN-001'), nao_disparou('TN-004'),
    pedido(elegibilidade, permitir), pedido(meioReembolso, meio_original).

test('TN-011 Interac sem o mesmo cartão físico: rever (A-10)') :-
    interac_no_canada(false, P), avaliar(P),
    pedido(elegibilidade, rever), pedido(meioReembolso, null), pedido(aprovacao, responsavel_senior).

test('TN-012 Interac em compra BackPocket usa a VeriFone') :-
    interac_no_canada(true, P0), com(P0, ["compraOriginal.canal"-"BACKPOCKET"], P), avaliar(P),
    disparos(D), once(nth0(I1, D, 'TN-011')), once(nth0(I2, D, 'TN-012')), I1 < I2,
    pedido(processo, verifone_interac),
    registo('TN-012', _, Msg), contem(Msg, "valor exato"), contem(Msg, "98.00").

test('TN-012 Interac BackPocket sem cartão não usa a VeriFone') :-
    interac_no_canada(false, P0), com(P0, ["compraOriginal.canal"-"BACKPOCKET"], P), avaliar(P),
    nao_disparou('TN-012').

test('OUT-004 numerário e cartão de oferta: meio original (A-09)', [forall(member(M, ["NUMERARIO", "CARTAO_OFERTA"]))]) :-
    pago_com(M, P), avaliar(P),
    disparou('OUT-004'), pedido(meioReembolso, meio_original).

:- end_tests(m7_meio_reembolso).

% ---------------------------------------------------------------------------------------------
%   Artigo pago com promoção (69.50), preço atual 39.99, PVP 98.00.
pedido_com_precos(P) :-
    um_pedido(P0),
    com(P0, ["artigos[0].precoPago"-69.5, "artigos[0].produto.precoAtual"-39.99, "artigos[0].produto.pvpOriginal"-98.0], P).

outlet(P0, P) :- com(P0, ["loja.tipoLoja"-"OUTLET"], P).

com_escaloes(P0, P) :- com(P0, ["compraOriginal.promocaoEscaloes"-true, "artigos[0].valorCalculadoPos"-55.25], P).

igual_valor(V, E) :- number(V), abs(V - E) < 0.005.

:- begin_tests(m7_valor).

test('OUT-003 devolução verificada pelo valor pago') :-
    pedido_com_precos(P), avaliar(P),
    artigo("A-1", valorDevolucao, V), igual_valor(V, 69.5), artigo("A-1", baseValor, valor_pago),
    pedido(valorDevolucao, T), igual_valor(T, 69.5), pedido(baseValor, valor_pago).

test('OUT-003 às cegas na Mainline pelo preço atual') :-
    pedido_com_precos(P0), sem_comprovativo(P0, P), avaliar(P),
    artigo("A-1", valorDevolucao, V), igual_valor(V, 39.99), artigo("A-1", baseValor, preco_atual),
    nao_disparou('CH-009').

test('OUT-003 ajuste de preço pela diferença calculada pelo POS') :-
    pedido_com_precos(P0), com(P0, ["tipoPedido"-"AJUSTE_PRECO", "artigos[0].valorCalculadoPos"-12.0], P), avaliar(P),
    pedido(valorDevolucao, V), igual_valor(V, 12.0), pedido(baseValor, valor_pos).

test('OUT-003 o total soma só os artigos elegíveis') :-
    pedido_com_precos(P0),
    mais_um_artigo(P0, "A-2", ["precoPago"-30.5], P1),
    mais_um_artigo(P1, "A-3", ["estado.alterado"-true], P), avaliar(P),
    pedido(valorDevolucao, V), igual_valor(V, 100.0), artigo("A-3", valorDevolucao, null).

test('OUT-003 pedido recusado não tem valor') :-
    pedido_com_precos(P0), com(P0, ["tipoPedido"-"AJUSTE_PRECO"], P1), dias_desde_compra(P1, 20, P), avaliar(P),
    pedido(valorDevolucao, null), nao_disparou('OUT-003').

test('OUT-003 revisão pendente não tem valor') :-
    pedido_com_precos(P0), dias_desde_compra(P0, 40, P), avaliar(P),
    pedido(valorDevolucao, null).

test('CH-009 às cegas na Outlet ao preço promocional atual') :-
    pedido_com_precos(P0), outlet(P0, P1), sem_comprovativo(P1, P), avaliar(P),
    artigo("A-1", valorDevolucao, V), igual_valor(V, 39.99), artigo("A-1", baseValor, valor_promocional),
    pedido(baseValor, valor_promocional), disparou('CH-009').

test('CH-009 com recibo na Outlet não aplica CH-009 nem CH-010') :-
    pedido_com_precos(P0), outlet(P0, P1), com(P1, ["compraOriginal.canal"-"OUTLET"], P), avaliar(P),
    nao_disparou('CH-009'), nao_disparou('CH-010').

test('CH-010 Mainline ou online com recibo na Outlet: PVP original (A-21)', [forall(member(C, ["MAINLINE", "LEVI_COM", "LEVI_CA"]))]) :-
    pedido_com_precos(P0), outlet(P0, P1),
    com(P1, ["compraOriginal.canal"-C, "comprovativo.tipo"-"CONFIRMACAO_ENCOMENDA", "comprovativo.reciboOriginal"-false,
             "compraOriginal.encomendaEncontrada"-true], P2),
    dias_desde_envio(P2, 5, P), avaliar(P),
    artigo("A-1", valorDevolucao, V), igual_valor(V, 98.0), artigo("A-1", baseValor, pvp_original),
    registo('CH-010', _, Msg), contem(Msg, "se o POS e a política o permitirem").

test('EP-003 às cegas: escalão pelo número de artigos devolvidos (A-30)') :-
    pedido_com_precos(P0), outlet(P0, P1), sem_comprovativo(P1, P2), com_escaloes(P2, P3),
    mais_um_artigo(P3, "A-2", [], P), avaliar(P),
    disparou('CH-009'), disparou('EP-003'),
    artigo("A-1", valorDevolucao, V), igual_valor(V, 55.25), artigo("A-1", baseValor, valor_escalao),
    registo('EP-003', _, Msg), contem(Msg, "2 artigos devolvidos").

test('EP-003 sem valor do POS o valor fica por determinar') :-
    um_pedido(P0), sem_comprovativo(P0, P1), com(P1, ["compraOriginal.promocaoEscaloes"-true], P), avaliar(P),
    artigo("A-1", valorDevolucao, null),
    registo('EP-003', _, Msg), contem(Msg, "falta o valor do escalão"),
    pedido(valorDevolucao, null).

test('EP-004 com recibo pelo valor calculado pelo POS') :-
    pedido_com_precos(P0), com_escaloes(P0, P), avaliar(P),
    artigo("A-1", baseValor, valor_pos), pedido(valorDevolucao, V), igual_valor(V, 55.25),
    disparou('EP-004'), nao_disparou('EP-003').

:- end_tests(m7_valor).
