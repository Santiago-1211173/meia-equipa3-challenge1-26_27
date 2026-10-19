:- encoding(utf8).
/*  Testes de M0 (autorização), M2 (canal) e M3 (elegibilidade do produto).
    Porta de AutorizacaoECanalTest e ElegibilidadeProdutoTest do projeto Drools.
*/

:- use_module(library(plunit)).
:- use_module(suporte).

% ---------------------------------------------------------------------------------------------
:- begin_tests(m0_autorizacao).

test('HS-006 encaminha e termina o fluxo', [forall(member(F-DM, ["STYLIST"-false, "STYLIST"-true, "LEAD_CASHIER"-false, "ELEVATED_STYLIST"-false]))]) :-
    um_pedido(P0), com(P0, ["colaborador.funcao"-F, "colaborador.aprovadoPeloDM"-DM], P), avaliar(P),
    pedido(elegibilidade, encaminhar),
    pedido(terminal, true),
    regras_de_negocio(['HS-006']),
    registo('HS-006', encaminhar, _).

test('HS-006 sem colaborador identificado encaminha') :-
    um_pedido(P0), com(P0, ["colaborador"-null], P), avaliar(P),
    regras_de_negocio(['HS-006']).

test('HS-006 é avaliada antes do canal: nem o grossista chega a M2') :-
    um_pedido(P0), com(P0, ["colaborador.funcao"-"STYLIST", "compraOriginal.canal"-"GROSSISTA"], P), avaliar(P),
    regras_de_negocio(['HS-006']).

test('HS-006 não dispara para Gestão, Key Holder e XStore Manager (A-23)', [forall(member(F, ["GESTAO_LOJA", "KEY_HOLDER", "XSTORE_MANAGER"]))]) :-
    um_pedido(P0), com(P0, ["colaborador.funcao"-F], P), avaliar(P),
    nao_disparou('HS-006').

test('CT-003 colaborador autorizado conclui com a credencial própria') :-
    um_pedido(P0), com(P0, ["colaborador.funcao"-"LEAD_CASHIER", "colaborador.aprovadoPeloDM"-true], P), avaliar(P),
    disparou('CT-003'),
    registo('CT-003', null, Msg), contem(Msg, "POS-C-1").

test('CT-003 sem credencial de POS não dispara') :-
    um_pedido(P0), com(P0, ["colaborador.idCredencialPOS"-null], P), avaliar(P),
    nao_disparou('CT-003').

test('CT-003 dispara uma só vez') :-
    um_pedido(P), avaliar(P),
    vezes('CT-003', 1).

:- end_tests(m0_autorizacao).

% ---------------------------------------------------------------------------------------------
:- begin_tests(m2_canal).

test('CH-008 grossista recusa e termina o fluxo') :-
    um_pedido(P0), com(P0, ["compraOriginal.canal"-"GROSSISTA"], P), avaliar(P),
    pedido(elegibilidade, recusar), pedido(tipoTransacao, nenhuma), pedido(terminal, true),
    regras_de_negocio(['CT-003', 'CH-008']).

test('CH-007 encaminha para a franquia em qualquer mercado (A-07)', [forall(member(M, ["EUA", "CANADA"]))]) :-
    um_pedido(P0), com(P0, ["loja.mercado"-M, "compraOriginal.canal"-"FRANQUIA_CANADA"], P), avaliar(P),
    pedido(elegibilidade, encaminhar), pedido(processo, franquia_canada), pedido(terminal, true),
    regras_de_negocio(['CT-003', 'CH-007']).

test('CH-001 aplica as regras da loja recetora sem decidir', [forall(member(C, ["MAINLINE", "OUTLET"]))]) :-
    um_pedido(P0), com(P0, ["compraOriginal.canal"-C], P), avaliar(P),
    disparos(D), comeca_por(D, ['CT-003', 'CH-001']),
    registo('CH-001', null, _),
    pedido(terminal, false).

test('CH-001 não dispara para outros canais', [forall(member(C, ["LEVI_COM", "LEVI_CA", "BACKPOCKET", "DESCONHECIDO"]))]) :-
    um_pedido(P0), com(P0, ["compraOriginal.canal"-C], P), avaliar(P),
    nao_disparou('CH-001').

test('IN-003 canal desconhecido prossegue para M3 (A-01)') :-
    um_pedido(P0), com(P0, ["compraOriginal.canal"-"DESCONHECIDO"], P), avaliar(P),
    disparos(D), comeca_por(D, ['CT-003', 'IN-003']),
    registo('IN-003', null, _),
    pedido(terminal, false).

:- end_tests(m2_canal).

% ---------------------------------------------------------------------------------------------
:- begin_tests(m3_paragens).

test('HS-001 SKU não reconhecido recusa o artigo') :-
    um_pedido(P0), com(P0, ["artigos[0].produto.skuReconhecidoPOS"-false], P), avaliar(P),
    artigo("A-1", elegibilidade, recusar), artigo("A-1", terminal, true), artigo("A-1", tipoTransacao, nenhuma),
    disparou('HS-001'), nao_disparou('PC-001'), nao_disparou('HS-004'),
    pedido(terminal, false).

test('HS-004 SKU da franquia não reconhecido encaminha para a franquia') :-
    um_pedido(P0), com(P0, ["artigos[0].produto.skuReconhecidoPOS"-false, "artigos[0].produto.produtoFranquia"-true], P), avaliar(P),
    artigo("A-1", elegibilidade, encaminhar), artigo("A-1", terminal, true),
    pedido(processo, franquia_canada),
    disparou('HS-004'), nao_disparou('HS-001'), nao_disparou('PC-001').

test('CH-007 produto da franquia com SKU reconhecido encaminha') :-
    um_pedido(P0), com(P0, ["artigos[0].produto.produtoFranquia"-true], P), avaliar(P),
    artigo("A-1", elegibilidade, encaminhar),
    registos_artigo("A-1", Rs), memberchk('CH-007', Rs),
    pedido(processo, franquia_canada),
    nao_disparou('PC-001').

test('HS-002 marca excluída recusa', [forall(member(M, ["DOCKERS", "LS_SIGNATURE", "BEYOND_YOGA"]))]) :-
    um_pedido(P0), com(P0, ["artigos[0].produto.marca"-M], P), avaliar(P),
    artigo("A-1", elegibilidade, recusar), artigo("A-1", terminal, true),
    disparou('HS-002'), nao_disparou('PC-001').

test('HS-002 produto grossista não vendido na loja recusa') :-
    um_pedido(P0), com(P0, ["artigos[0].produto.grossista"-true, "artigos[0].produto.vendidoNaLoja"-false], P), avaliar(P),
    artigo("A-1", elegibilidade, recusar), disparou('HS-002').

test('HS-002 produto grossista vendido na loja não é recusado') :-
    um_pedido(P0), com(P0, ["artigos[0].produto.grossista"-true], P), avaliar(P),
    nao_disparou('HS-002'), disparou('PC-001').

test('HS-003 produto modificado recusa', [forall(member(Campo, ["personalizado", "alterado", "embainhado"]))]) :-
    string_concat("artigos[0].estado.", Campo, Caminho),
    um_pedido(P0), com(P0, [Caminho-true], P), avaliar(P),
    artigo("A-1", elegibilidade, recusar), artigo("A-1", terminal, true),
    disparou('HS-003'), nao_disparou('PC-001').

test('HS-003 prevalece sobre PC-006: embainhado com defeito é recusado') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.embainhado"-true, "artigos[0].estado.defeitoFabricoConfirmado"-true], P), avaliar(P),
    artigo("A-1", elegibilidade, recusar), disparou('HS-003'), nao_disparou('PC-006').

test('Uma só paragem por artigo (HS-002 antes de HS-003)') :-
    um_pedido(P0), com(P0, ["artigos[0].produto.marca"-"DOCKERS", "artigos[0].estado.alterado"-true], P), avaliar(P),
    disparou('HS-002'), nao_disparou('HS-003').

:- end_tests(m3_paragens).

% ---------------------------------------------------------------------------------------------
:- begin_tests(m3_estado).

estado(P0, Uso, Etiquetas, P) :-
    com(P0, ["artigos[0].estado.condicaoUso"-Uso, "artigos[0].estado.etiquetas"-Etiquetas], P).

test('PC-001 não usado com etiquetas é permitido') :-
    um_pedido(P), avaliar(P),
    artigo("A-1", elegibilidade, permitir), artigo("A-1", aprovacao, nenhuma),
    vezes('PC-001', 1).

test('PC-002 etiquetas soltas sem avaliação de revenda: rever (A-19)') :-
    um_pedido(P0), estado(P0, "NAO_USADO", "SOLTAS", P), avaliar(P),
    artigo("A-1", elegibilidade, rever), artigo("A-1", aprovacao, responsavel_senior),
    registo('PC-002', _, Msg), contem(Msg, "IN-010").

test('PC-002 etiquetas soltas e revendível: aprovado') :-
    um_pedido(P0), estado(P0, "NAO_USADO", "SOLTAS", P1), com(P1, ["artigos[0].revendivel"-true], P), avaliar(P),
    artigo("A-1", elegibilidade, permitir), artigo("A-1", aprovacao, responsavel_senior).

test('PC-002 etiquetas soltas e não revendível: recusado sem terminar') :-
    um_pedido(P0), estado(P0, "NAO_USADO", "SOLTAS", P1), com(P1, ["artigos[0].revendivel"-false], P), avaliar(P),
    artigo("A-1", elegibilidade, recusar), artigo("A-1", terminal, false).

test('PC-003 sem etiquetas por avaliar: rever') :-
    um_pedido(P0), estado(P0, "NAO_USADO", "AUSENTES", P), avaliar(P),
    artigo("A-1", elegibilidade, rever), artigo("A-1", aprovacao, responsavel_senior).

test('PC-003 sem etiquetas e revendível: aprovado') :-
    um_pedido(P0), estado(P0, "NAO_USADO", "AUSENTES", P1), com(P1, ["artigos[0].revendivel"-true], P), avaliar(P),
    artigo("A-1", elegibilidade, permitir).

test('PC-003 sem etiquetas e não revendível: recusado') :-
    um_pedido(P0), estado(P0, "NAO_USADO", "AUSENTES", P1), com(P1, ["artigos[0].revendivel"-false], P), avaliar(P),
    artigo("A-1", elegibilidade, recusar).

test('PC-004 usado sem decisão da gestão: rever (A-18, A-29)') :-
    um_pedido(P0), estado(P0, "USADO", "AUSENTES", P), avaliar(P),
    artigo("A-1", elegibilidade, rever), artigo("A-1", aprovacao, responsavel_senior),
    registo('PC-004', _, Msg), contem(Msg, "mesmo artigo").

test('PC-004 usado com aprovação da gestão: só troca pelo mesmo artigo') :-
    um_pedido(P0), estado(P0, "USADO", "AUSENTES", P1),
    excecao(P1, _{motivo:"Pede reembolso de artigo usado", aprovada:true}, P), avaliar(P),
    artigo("A-1", elegibilidade, permitir), artigo("A-1", tipoTransacao, troca_mesmo_artigo).

test('PC-004 usado recusado pela gestão') :-
    um_pedido(P0), estado(P0, "USADO", "AUSENTES", P1),
    excecao(P1, _{motivo:"Pede reembolso de artigo usado", aprovada:false}, P), avaliar(P),
    artigo("A-1", elegibilidade, recusar), artigo("A-1", tipoTransacao, nenhuma).

test('PC-004 usado com dano mas sem defeito confirmado (A-29)') :-
    um_pedido(P0), estado(P0, "USADO", "AUSENTES", P1), com(P1, ["artigos[0].estado.danificado"-true], P), avaliar(P),
    disparou('PC-004').

test('PC-005 lavado é recusado') :-
    um_pedido(P0), estado(P0, "LAVADO", "AUSENTES", P), avaliar(P),
    artigo("A-1", elegibilidade, recusar), artigo("A-1", tipoTransacao, nenhuma).

test('PC-006 prevalece sobre PC-004 e PC-005', [forall(member(U, ["USADO", "LAVADO"]))]) :-
    um_pedido(P0), estado(P0, U, "AUSENTES", P1), com(P1, ["artigos[0].estado.defeitoFabricoConfirmado"-true], P), avaliar(P),
    artigo("A-1", elegibilidade, permitir),
    disparou('PC-006'), nao_disparou('PC-004'), nao_disparou('PC-005').

test('PC-007 bodywear aceite em qualquer estado', [forall(member(U, ["NAO_USADO", "USADO", "LAVADO"]))]) :-
    um_pedido(P0), estado(P0, U, "AUSENTES", P1),
    com(P1, ["artigos[0].produto.categoria"-"BODYWEAR", "artigos[0].estado.defeitoFabricoConfirmado"-true], P), avaliar(P),
    artigo("A-1", elegibilidade, permitir),
    registos_artigo("A-1", ['PC-007']).

test('PC-007 bodywear modificado continua recusado por HS-003') :-
    um_pedido(P0), com(P0, ["artigos[0].produto.categoria"-"BODYWEAR", "artigos[0].estado.alterado"-true], P), avaliar(P),
    disparou('HS-003'), nao_disparou('PC-007').

test('Vários artigos: cada um tem o seu resultado') :-
    um_pedido(P0), sem_comprovativo(P0, P1),
    estado(P1, "NAO_USADO", "AUSENTES", P2),
    mais_um_artigo(P2, "A-2", ["estado.condicaoUso"-"USADO", "estado.etiquetas"-"AUSENTES"], P3),
    mais_um_artigo(P3, "A-3", ["estado.condicaoUso"-"USADO", "estado.etiquetas"-"AUSENTES", "estado.sujoOuInseguro"-true], P),
    avaliar(P),
    registos_artigo("A-1", ['PC-003']),
    registos_artigo("A-2", ['PC-004']),
    registos_artigo("A-3", ['PC-008', 'PC-004']).

test('Uma paragem num artigo não termina os outros') :-
    um_pedido(P0), mais_um_artigo(P0, "A-2", ["estado.embainhado"-true], P), avaliar(P),
    artigo("A-1", elegibilidade, permitir), artigo("A-2", elegibilidade, recusar),
    pedido(terminal, false).

:- end_tests(m3_estado).
