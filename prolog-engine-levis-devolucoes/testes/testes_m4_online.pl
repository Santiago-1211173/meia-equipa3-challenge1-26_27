:- encoding(utf8).
/*  Testes de M4 (comprovativo), M5 (prazo e ajuste de preço) e do caminho ONLINE.
    Porta de ComprovativoEPrazoTest e CaminhoOnlineTest do projeto Drools.
*/

:- use_module(library(plunit)).
:- use_module(suporte).

ajuste(Dias, P) :-
    um_pedido(P0), com(P0, ["tipoPedido"-"AJUSTE_PRECO"], P1), dias_desde_compra(P1, Dias, P).

% ---------------------------------------------------------------------------------------------
:- begin_tests(m4_comprovativo).

test('PT-001 comprovativo que confirma a compra é verificado',
     [forall(member(T, ["RECIBO_IMPRESSO", "RECIBO_DIGITAL", "CONFIRMACAO_ENCOMENDA", "RECIBO_OFERTA",
                        "CONSULTA_TRANSACAO", "FOTOGRAFIA_RECIBO", "CONSULTA_BACKPOCKET"]))]) :-
    um_pedido(P0), com(P0, ["comprovativo.tipo"-T, "comprovativo.reciboOriginal"-false], P), avaliar(P),
    pedido(tipoVerificacao, verificada), disparou('PT-001'), nao_disparou('PT-002').

test('Compras online não passam por M4', [forall(member(C, ["LEVI_COM", "LEVI_CA"]))]) :-
    um_pedido(P0), com(P0, ["compraOriginal.canal"-C], P), avaliar(P),
    nao_disparou('PT-001'), nao_disparou('PT-002'), nao_disparou('PT-003').

test('PT-002 sem comprovativo é às cegas') :-
    um_pedido(P0), sem_comprovativo(P0, P), avaliar(P),
    pedido(tipoVerificacao, as_cegas), disparou('PT-002'), nao_disparou('PT-001').

test('PT-002 comprovativo que não confirma a compra é às cegas') :-
    um_pedido(P0), com(P0, ["comprovativo.confirmaCompra"-false], P), avaliar(P),
    pedido(tipoVerificacao, as_cegas).

test('PT-002 ajuste de preço sem comprovativo não é devolução às cegas') :-
    ajuste(5, P0), sem_comprovativo(P0, P), avaliar(P),
    nao_disparou('PT-002').

test('PT-006 cliente que não dá dados salta o passo') :-
    um_pedido(P0), sem_comprovativo(P0, P1), com(P1, ["cliente.forneceDados"-false], P), avaliar(P),
    disparos(D), sequencia(D, ['PT-002', 'PT-006']),
    registo('PT-006', _, Msg), contem(Msg, "Saltar").

test('PT-006 barreira linguística salta o passo') :-
    um_pedido(P0), sem_comprovativo(P0, P1), com(P1, ["cliente.barreiraLinguistica"-true], P), avaliar(P),
    disparou('PT-006').

test('PT-006 não se aplica com recibo') :-
    um_pedido(P0), com(P0, ["cliente.forneceDados"-false], P), avaliar(P),
    nao_disparou('PT-006').

:- end_tests(m4_comprovativo).

% ---------------------------------------------------------------------------------------------
:- begin_tests(m5_prazo).

test('PT-003 verificada até 30 dias inclusive: reembolso no meio original (A-22)', [forall(member(D, [0, 29, 30]))]) :-
    um_pedido(P0), dias_desde_compra(P0, D, P), avaliar(P),
    pedido(elegibilidade, permitir), pedido(tipoTransacao, reembolso),
    pedido(meioReembolso, meio_original), pedido(baseValor, valor_pago).

test('PT-003 troca verificada até 30 dias') :-
    um_pedido(P0), com(P0, ["tipoPedido"-"TROCA"], P1), dias_desde_compra(P1, 29, P), avaliar(P),
    pedido(tipoTransacao, troca), pedido(elegibilidade, permitir).

test('PT-003 artigo em revisão conta como elegível') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.etiquetas"-"SOLTAS"], P), avaliar(P),
    disparou('PC-002'), disparou('PT-003').

test('PT-003 sem artigos elegíveis não há prazo a aplicar') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.alterado"-true], P), avaliar(P),
    disparou('PT-001'), nao_disparou('PT-003').

test('PT-004 após 30 dias sem avaliação de revenda: rever') :-
    um_pedido(P0), dias_desde_compra(P0, 31, P), avaliar(P),
    pedido(elegibilidade, rever), pedido(aprovacao, responsavel_senior), pedido(tipoTransacao, null).

test('PT-004 após 30 dias, revendível e de baixo risco: crédito de loja') :-
    um_pedido(P0), dias_desde_compra(P0, 45, P1), com(P1, ["artigos[0].revendivel"-true], P),
    avaliar(P, ["Hesitação"-"BAIXO"]),
    pedido(elegibilidade, permitir), pedido(tipoTransacao, credito_loja),
    pedido(meioReembolso, credito_loja), pedido(aprovacao, responsavel_senior).

test('PT-004 após 30 dias e não revendível: recusado') :-
    um_pedido(P0), dias_desde_compra(P0, 45, P1), com(P1, ["artigos[0].revendivel"-false], P), avaliar(P),
    pedido(elegibilidade, recusar), pedido(tipoTransacao, nenhuma).

test('PT-004 com um artigo por avaliar não aprova crédito') :-
    um_pedido(P0), dias_desde_compra(P0, 45, P1), com(P1, ["artigos[0].revendivel"-true], P2),
    mais_um_artigo(P2, "A-2", [], P), avaliar(P),
    pedido(elegibilidade, rever), pedido(tipoTransacao, null).

test('PT-005 às cegas: só crédito de loja ao preço atual') :-
    um_pedido(P0), sem_comprovativo(P0, P), avaliar(P),
    pedido(elegibilidade, permitir), pedido(tipoTransacao, credito_loja),
    pedido(meioReembolso, credito_loja), pedido(baseValor, preco_atual).

test('PT-005 troca às cegas ao preço atual') :-
    um_pedido(P0), com(P0, ["tipoPedido"-"TROCA"], P1), sem_comprovativo(P1, P), avaliar(P),
    pedido(tipoTransacao, troca), pedido(meioReembolso, null), pedido(baseValor, preco_atual).

test('PT-005 devolução de oferta sem recibo: crédito de loja (A-13)') :-
    um_pedido(P0), com(P0, ["tipoPedido"-"DEVOLUCAO_OFERTA"], P1), sem_comprovativo(P1, P), avaliar(P),
    pedido(tipoTransacao, credito_loja).

test('PT-005 às cegas sem artigos elegíveis não permite') :-
    um_pedido(P0), sem_comprovativo(P0, P1), com(P1, ["artigos[0].estado.condicaoUso"-"LAVADO"], P), avaliar(P),
    disparou('PT-002'), nao_disparou('PT-005').

:- end_tests(m5_prazo).

% ---------------------------------------------------------------------------------------------
:- begin_tests(m5_ajuste_preco).

test('PT-007 compra em loja até 14 dias com recibo original', [forall(member(C, ["MAINLINE", "OUTLET"]))]) :-
    ajuste(14, P0), com(P0, ["compraOriginal.canal"-C], P), avaliar(P),
    pedido(elegibilidade, permitir), pedido(tipoTransacao, ajuste_preco), pedido(baseValor, valor_pos).

test('PT-007 o ajuste é único: já aplicado, recusa (A-14)') :-
    ajuste(5, P0), com(P0, ["compraOriginal.ajustePrecoAplicado"-true], P), avaliar(P),
    pedido(elegibilidade, recusar), pedido(tipoTransacao, nenhuma).

test('PT-007 compra fora da loja: rever (A-14)', [forall(member(C, ["LEVI_COM", "BACKPOCKET"]))]) :-
    ajuste(5, P0), com(P0, ["compraOriginal.canal"-C], P), avaliar(P),
    pedido(elegibilidade, rever), pedido(tipoTransacao, T), T \== ajuste_preco.

test('PT-008 após 14 dias é recusado') :-
    ajuste(15, P), avaliar(P),
    pedido(elegibilidade, recusar), disparou('PT-008'), nao_disparou('PT-007').

test('PT-008 fotografia do recibo não é o recibo original (A-14)') :-
    ajuste(13, P0), com(P0, ["comprovativo.tipo"-"FOTOGRAFIA_RECIBO", "comprovativo.reciboOriginal"-false], P), avaliar(P),
    pedido(elegibilidade, recusar),
    registo('PT-008', _, Msg), contem(Msg, "sem o recibo original"),
    nao_disparou('PT-007').

test('PT-008 sem comprovativo é recusado') :-
    ajuste(3, P0), sem_comprovativo(P0, P), avaliar(P),
    pedido(elegibilidade, recusar).

:- end_tests(m5_ajuste_preco).

% ---------------------------------------------------------------------------------------------
%   Encomenda levi.com encontrada, enviada há 10 dias, paga com cartão de crédito.
encomenda_online(P) :-
    um_pedido(P0),
    com(P0, ["compraOriginal.canal"-"LEVI_COM", "comprovativo.tipo"-"CONFIRMACAO_ENCOMENDA",
             "comprovativo.reciboOriginal"-false, "compraOriginal.encomendaEncontrada"-true], P1),
    dias_desde_compra(P1, 12, P2),
    dias_desde_envio(P2, 10, P).

nao_encontrada(Permite, P) :-
    encomenda_online(P0),
    com(P0, ["compraOriginal.encomendaEncontrada"-false, "politicaPermiteAsCegasOnline"-Permite], P).

:- begin_tests(online).

test('CH-002 encaminha para a BackPocket no meio original', [forall(member(C, ["LEVI_COM", "LEVI_CA"]))]) :-
    encomenda_online(P0), com(P0, ["compraOriginal.canal"-C], P), avaliar(P),
    pedido(elegibilidade, encaminhar), pedido(processo, backpocket), pedido(tipoVerificacao, verificada),
    pedido(tipoTransacao, reembolso), pedido(meioReembolso, meio_original), pedido(terminal, false).

test('CH-002 cliente nos EUA pode pedir cartão de oferta eletrónico') :-
    encomenda_online(P1), avaliar(P1),
    registo('CH-002', _, M1), contem(M1, "cartão de oferta eletrónico"),
    encomenda_online(P0), com(P0, ["loja.mercado"-"CANADA", "compraOriginal.canal"-"LEVI_CA"], P2), avaliar(P2),
    registo('CH-002', _, M2), \+ contem(M2, "cartão de oferta eletrónico").

test('CH-002 sem artigos elegíveis não encaminha') :-
    encomenda_online(P0), com(P0, ["artigos[0].estado.condicaoUso"-"LAVADO"], P), avaliar(P),
    nao_disparou('CH-002').

test('CH-004 encomenda encontrada com o portal indisponível: rever (A-04)') :-
    encomenda_online(P0), com(P0, ["portalOnlineDisponivel"-false], P), avaliar(P),
    pedido(elegibilidade, rever), pedido(aprovacao, responsavel_senior), pedido(meioReembolso, null),
    nao_disparou('CH-002').

test('TN-010 reembolso na BackPocket para a Afterpay') :-
    encomenda_online(P0), com(P0, ["compraOriginal.pagamento.meio"-"AFTERPAY"], P), avaliar(P),
    disparos(D), sequencia(D, ['CH-002', 'TN-010']),
    pedido(tipoTransacao, reembolso), pedido(meioReembolso, meio_original), pedido(excecaoRecusada, false).

test('TN-010 e HS-005 prevalecem sobre CH-006: troca Afterpay recusada') :-
    encomenda_online(P0), com(P0, ["tipoPedido"-"TROCA", "compraOriginal.pagamento.meio"-"AFTERPAY"], P), avaliar(P),
    disparou('TN-010'), disparou('HS-005'), nao_disparou('CH-006'),
    pedido(excecaoRecusada, true), pedido(tipoTransacao, reembolso),
    pedido(elegibilidade, encaminhar), pedido(terminal, false).

test('HS-005 pedido de outro meio com Afterpay é recusado') :-
    encomenda_online(P0), com(P0, ["compraOriginal.pagamento.meio"-"AFTERPAY"], P1),
    excecao(P1, _{motivo:"Quer cartão de oferta", exigeMeioProibido:true}, P), avaliar(P),
    disparou('HS-005'), registo('HS-005', recusar, _).

test('HS-005 sem pedido de exceção não dispara') :-
    encomenda_online(P0), com(P0, ["compraOriginal.pagamento.meio"-"AFTERPAY"], P), avaliar(P),
    nao_disparou('HS-005').

test('CH-005 Afterpay tardio continua na Afterpay') :-
    encomenda_online(P0), dias_desde_envio(P0, 40, P1), com(P1, ["compraOriginal.pagamento.meio"-"AFTERPAY"], P), avaliar(P),
    disparou('TN-010'), nao_disparou('CH-005'), pedido(meioReembolso, meio_original).

test('CH-005 enviada há mais de 30 dias recebe cartão de oferta') :-
    encomenda_online(P0), dias_desde_envio(P0, 31, P), avaliar(P),
    pedido(meioReembolso, cartao_oferta), pedido(tipoTransacao, reembolso).

test('CH-005 até 30 dias não dispara') :-
    encomenda_online(P0), dias_desde_envio(P0, 30, P), avaliar(P),
    nao_disparou('CH-005').

test('CH-005 PayPal e Venmo tardios não recebem cartão de oferta (A-05)', [forall(member(M, ["PAYPAL", "VENMO"]))]) :-
    encomenda_online(P0), dias_desde_envio(P0, 37, P1), com(P1, ["compraOriginal.pagamento.meio"-M], P), avaliar(P),
    nao_disparou('CH-005').

test('CH-006 troca online com saldo no meio original') :-
    encomenda_online(P0), com(P0, ["tipoPedido"-"TROCA"], P), avaliar(P),
    pedido(tipoTransacao, troca), pedido(meioReembolso, meio_original).

test('CH-005 troca online tardia segue CH-005 (A-06)') :-
    encomenda_online(P0), com(P0, ["tipoPedido"-"TROCA"], P1), dias_desde_envio(P1, 35, P), avaliar(P),
    disparou('CH-005'), nao_disparou('CH-006').

test('CH-003 às cegas permitida com cartão de oferta') :-
    nao_encontrada(true, P), avaliar(P),
    pedido(elegibilidade, permitir), pedido(tipoVerificacao, as_cegas), pedido(meioReembolso, cartao_oferta).

test('CH-003 sem cenário da política que o permita: recusar (A-03)') :-
    nao_encontrada(false, P), avaliar(P),
    pedido(elegibilidade, recusar), pedido(tipoTransacao, nenhuma).

test('CH-004 substitui o meio predefinido de CH-003') :-
    nao_encontrada(true, P0), com(P0, ["portalOnlineDisponivel"-false], P), avaliar(P),
    disparos(D), sequencia(D, ['CH-003', 'CH-004']),
    pedido(meioReembolso, meio_original), pedido(elegibilidade, permitir).

test('CH-004 portal indisponível não reverte uma recusa') :-
    nao_encontrada(false, P0), com(P0, ["portalOnlineDisponivel"-false], P), avaliar(P),
    nao_disparou('CH-004'), pedido(elegibilidade, recusar).

:- end_tests(online).
