:- encoding(utf8).
/*  Testes de M8 (controlos e documentação) e M9 (destino do produto e agregação).
    Porta de ControlosTest e DestinoProdutoTest do projeto Drools.
*/

:- use_module(library(plunit)).
:- use_module(suporte).

com_excecao(Campos, P) :-
    um_pedido(P0),
    E0 = _{motivo:"Cliente de longa data", preocupacaoCliente:"Viagem marcada"},
    E = E0.put(Campos),
    excecao(P0, E, P).

% ---------------------------------------------------------------------------------------------
:- begin_tests(m8_autorizacao).

test('CT-001 devolução verificada por pessoal autorizado') :-
    um_pedido(P), avaliar(P),
    disparou('CT-001'), registo('CT-001', _, Msg), contem(Msg, "KEY_HOLDER").

test('CT-001 transação recusada não tem controlos') :-
    um_pedido(P0), com(P0, ["tipoPedido"-"AJUSTE_PRECO"], P1), dias_desde_compra(P1, 30, P), avaliar(P),
    nao_disparou('CT-001'), nao_disparou('CT-005'), nao_disparou('CT-007').

test('CT-002 às cegas por Lead Cashier ou Elevated Stylist exige XStore Manager', [forall(member(F, ["LEAD_CASHIER", "ELEVATED_STYLIST"]))]) :-
    um_pedido(P0), com(P0, ["colaborador.funcao"-F, "colaborador.aprovadoPeloDM"-true], P1), sem_comprovativo(P1, P), avaliar(P),
    pedido(aprovacao, xstore_manager), disparou('CT-002'), nao_disparou('CT-001').

test('CT-002 às cegas por Key Holder não exige XStore Manager') :-
    um_pedido(P0), sem_comprovativo(P0, P), avaliar(P),
    nao_disparou('CT-002'), pedido(aprovacao, nenhuma).

test('CT-002 não baixa uma aprovação mais alta') :-
    um_pedido(P0), com(P0, ["colaborador.funcao"-"LEAD_CASHIER", "colaborador.aprovadoPeloDM"-true,
                            "artigos[0].estado.etiquetas"-"SOLTAS"], P1),
    sem_comprovativo(P1, P), avaliar(P),
    disparou('EX-001'), disparou('CT-002'), pedido(aprovacao, responsavel_senior).

:- end_tests(m8_autorizacao).

% ---------------------------------------------------------------------------------------------
:- begin_tests(m8_documentos).

test('CT-004 atribui ao Stylist da venda original') :-
    um_pedido(P), avaliar(P),
    pedido('documentacao.idStylistAtribuido', "S-7").

test('CT-004 devolução às cegas não é atribuída') :-
    um_pedido(P0), sem_comprovativo(P0, P), avaliar(P),
    pedido('documentacao.idStylistAtribuido', null).

test('CT-005 três assinaturas') :-
    um_pedido(P), avaliar(P),
    pedido('documentacao.assinaturaCliente', C), contem(C, "Recusado"),
    pedido('documentacao.assinaturaProcessador', Pr), contem(Pr, "C-1"),
    pedido('documentacao.assinaturaTestemunha', "Assinatura da testemunha").

test('CT-005 cobertura de loja única usa SSC') :-
    um_pedido(P0), com(P0, ["loja.coberturaLojaUnica"-true], P), avaliar(P),
    pedido('documentacao.assinaturaTestemunha', "SSC").

test('CT-006 recibo original é agrafado') :-
    um_pedido(P), avaliar(P),
    pedido('documentacao.reciboAgrafado', true), pedido('documentacao.notaRecibo', null).

test('CT-006 cliente que mantém o recibo fica anotado') :-
    um_pedido(P0), com(P0, ["comprovativo.clienteMantemRecibo"-true], P), avaliar(P),
    pedido('documentacao.reciboAgrafado', false),
    pedido('documentacao.notaRecibo', N), contem(N, "manteve").

test('CT-006 recibo com outros artigos fica anotado') :-
    um_pedido(P0), com(P0, ["comprovativo.incluiOutrosArtigos"-true], P), avaliar(P),
    pedido('documentacao.reciboAgrafado', true),
    pedido('documentacao.notaRecibo', N), contem(N, "outros artigos").

test('CT-006 recibo digital não é agrafado') :-
    um_pedido(P0), com(P0, ["comprovativo.tipo"-"RECIBO_DIGITAL"], P), avaliar(P),
    nao_disparou('CT-006').

test('CT-007 retenção de 90 dias') :-
    um_pedido(P), avaliar(P),
    pedido('documentacao.retencaoAte', date(2026, 6, 29)),
    disparos(D), once(nth0(I5, D, 'CT-005')), once(nth0(I7, D, 'CT-007')), I5 < I7.

test('CT-007 devolução online arquiva com os suportes diários') :-
    um_pedido(P0), com(P0, ["compraOriginal.canal"-"LEVI_COM", "compraOriginal.encomendaEncontrada"-true], P1),
    dias_desde_envio(P1, 5, P), avaliar(P),
    registo('CT-007', _, Msg), contem(Msg, "suportes diários").

test('EX-007 documenta a exceção aprovada') :-
    com_excecao(_{aprovada:true, aprovador:_{nome:"Ana Gestora", funcao:"GESTAO_LOJA"}}, P), avaliar(P),
    pedido('documentacao.registoExcecao', R),
    forall(member(T, ["Cliente de longa data", "Ana Gestora", "98.00", "REEMBOLSO", "Viagem marcada", "M9"]), contem(R, T)),
    disparos(D), once(nth0(IE, D, 'EX-007')), once(nth0(IC, D, 'CT-007')), IE < IC.

test('EX-007 exceção pendente não é documentada') :-
    com_excecao(_{}, P), avaliar(P),
    nao_disparou('EX-007').

test('EX-007 exceção recusada pelo sistema não é documentada como aprovada') :-
    com_excecao(_{aprovada:true, exigeMeioProibido:true}, P0),
    com(P0, ["cliente.contestaResultado"-true, "cliente.agitado"-true], P), avaliar(P),
    disparou('EX-006'), nao_disparou('EX-007').

:- end_tests(m8_documentos).

% ---------------------------------------------------------------------------------------------
bodywear(Alteracoes, P) :-
    um_pedido(P0),
    com(P0, ["artigos[0].produto.categoria"-"BODYWEAR", "artigos[0].estado.embalagemIntacta"-true,
             "artigos[0].estado.conjuntoCompleto"-true], P1),
    com(P1, Alteracoes, P).

entre_canais(Alteracoes, P) :-
    um_pedido(P0), com(P0, ["artigos[0].entreCanais"-true], P1), com(P1, Alteracoes, P).

:- begin_tests(m9_destino).

test('OUT-007 artigo recusado é devolvido ao cliente') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.embainhado"-true], P), avaliar(P),
    artigo("A-1", destino, devolucao_cliente).

test('OUT-007 depois de uma recusa terminal do pedido, o artigo volta ao cliente') :-
    um_pedido(P0), com(P0, ["compraOriginal.canal"-"GROSSISTA"], P), avaliar(P),
    pedido(terminal, true), artigo("A-1", destino, devolucao_cliente).

test('OUT-007 um artigo inseguro recusado continua isolado (A-28)') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.embainhado"-true, "artigos[0].estado.sujoOuInseguro"-true], P), avaliar(P),
    artigo("A-1", destino, risco_biologico).

test('OUT-007 num ajuste de preço o artigo não é entregue (A-14)') :-
    um_pedido(P0), com(P0, ["tipoPedido"-"AJUSTE_PRECO"], P1),
    dias_desde_compra(P1, 5, P2), avaliar(P2),
    artigo("A-1", destino, null), nao_disparou('CT-008'), nao_disparou('OUT-007'),
    dias_desde_compra(P1, 20, P3), avaliar(P3),
    artigo("A-1", destino, null).

test('OUT-007 pedido suspenso não tem destino') :-
    um_pedido(P), avaliar(P, ["Recibo adulterado"-"CONFIRMADO"]),
    artigo("A-1", destino, null), nao_disparou('OUT-007'), nao_disparou('OUT-001').

test('BW-004 prevalece sobre BW-003: usado e sujo vai para risco biológico') :-
    bodywear(["artigos[0].estado.condicaoUso"-"USADO", "artigos[0].estado.sujoOuInseguro"-true,
              "artigos[0].estado.conjuntoCompleto"-false], P), avaliar(P),
    artigo("A-1", destino, risco_biologico),
    disparou_artigo("A-1", 'BW-004'), \+ disparou_artigo("A-1", 'BW-003').

test('BW-003 conjunto incompleto tem baixa por dano') :-
    bodywear(["artigos[0].estado.conjuntoCompleto"-false], P), avaliar(P),
    artigo("A-1", destino, baixa_dano), disparou_artigo("A-1", 'BW-003').

test('BW-003 usado sem sujidade tem baixa por dano') :-
    bodywear(["artigos[0].estado.condicaoUso"-"USADO"], P), avaliar(P),
    artigo("A-1", destino, baixa_dano).

test('BW-001 embalagem intacta e inspeção confirmada volta à venda') :-
    bodywear(["artigos[0].revendivel"-true], P), avaliar(P),
    artigo("A-1", destino, area_vendas).

test('BW-001 embalagem intacta sem confirmação de revenda tem baixa por dano') :-
    bodywear(["artigos[0].revendivel"-false], P), avaliar(P),
    artigo("A-1", destino, baixa_dano).

test('BW-001 embalagem intacta por inspecionar fica pendente') :-
    bodywear([], P), avaliar(P),
    artigo("A-1", destino, null), disparou_artigo("A-1", 'BW-001').

test('BW-002 sem embalagem, não usado e completo vai para saldos a 50%') :-
    bodywear(["artigos[0].estado.embalagemIntacta"-false], P), avaliar(P),
    artigo("A-1", destino, saldos), artigo("A-1", descontoSaldo, 50).

test('PC-006 defeito de fabrico tem baixa por dano') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.defeitoFabricoConfirmado"-true], P), avaliar(P),
    artigo("A-1", destino, baixa_dano), \+ disparou_artigo("A-1", 'CT-008').

test('CT-008 inspeção conforme volta à área de vendas') :-
    um_pedido(P), avaliar(P),
    artigo("A-1", destino, area_vendas).

test('CT-008 artigo com dano tem baixa por dano') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.danificado"-true], P), avaliar(P),
    artigo("A-1", destino, baixa_dano).

test('CT-008 etiqueta ou RFID incorretos: reetiquetar') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.rfidCorreto"-false], P), avaliar(P),
    artigo("A-1", destino, reetiquetar).

test('CT-008 artigo em revisão também é inspecionado') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.etiquetas"-"SOLTAS"], P), avaliar(P),
    artigo("A-1", elegibilidade, rever), artigo("A-1", destino, area_vendas).

test('EP-007 antes de EP-006: artigo já em saldo continua em saldo') :-
    entre_canais(["artigos[0].produto.emSaldo"-true], P), avaliar(P),
    artigo("A-1", destino, saldos), artigo("A-1", descontoSaldo, 0),
    disparou_artigo("A-1", 'EP-007'), \+ disparou_artigo("A-1", 'EP-006').

test('EP-005 no sortido da loja recetora volta à venda reprecificado') :-
    entre_canais(["loja.skusSortido"-["501-A-1"]], P), avaliar(P),
    artigo("A-1", destino, area_vendas), disparou_artigo("A-1", 'EP-005').

test('EP-006 fora do sortido vai para saldos a 20%') :-
    entre_canais([], P), avaliar(P),
    artigo("A-1", destino, saldos), artigo("A-1", descontoSaldo, 20).

test('EP-006 artigo entre canais com dano tem baixa por dano') :-
    entre_canais(["artigos[0].estado.danificado"-true], P), avaliar(P),
    artigo("A-1", destino, baixa_dano), \+ disparou_artigo("A-1", 'EP-006').

:- end_tests(m9_destino).

% ---------------------------------------------------------------------------------------------
:- begin_tests(m9_agregacao).

test('OUT-001 o pedido fica com o resultado mais severo dos artigos (A-25)') :-
    um_pedido(P0), mais_um_artigo(P0, "A-2", ["estado.etiquetas"-"SOLTAS"], P), avaliar(P),
    pedido(elegibilidade, rever),
    registo('OUT-001', _, Msg), contem(Msg, "2 artigo(s)").

test('OUT-001 todos os artigos recusados recusa o pedido') :-
    um_pedido(P0), com(P0, ["artigos[0].estado.embainhado"-true], P), avaliar(P),
    pedido(elegibilidade, recusar), pedido(tipoTransacao, nenhuma).

test('OUT-001 artigo recusado e artigo permitido recusa o pedido') :-
    um_pedido(P0), mais_um_artigo(P0, "A-2", ["estado.embainhado"-true], P), avaliar(P),
    pedido(elegibilidade, recusar), pedido(tipoTransacao, reembolso),
    artigo("A-1", destino, area_vendas), artigo("A-2", destino, devolucao_cliente).

test('OUT-001 dispara uma só vez, no fim') :-
    um_pedido(P), avaliar(P),
    disparos(D), last(D, 'OUT-001'), vezes('OUT-001', 1).

:- end_tests(m9_agregacao).
