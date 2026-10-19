:- encoding(utf8).
/*  Testes das explicações: Como, Porque não, Porquê, E se e O que falta.
    Porta de ExplicadoresTest e SimulacaoEDadosEmFaltaTest do projeto Drools (pericial-explanation).
*/

:- use_module(library(plunit)).
:- use_module(library(lists)).
:- use_module(suporte).
:- use_module(verificador).
:- use_module('../src/servico', [preparar_pedido/3, avaliar_pedido/2]).
:- use_module('../src/motor/memoria', [pedido_atual/1]).
:- use_module('../src/explicacoes/explicacoes').

cenario(N) :-
    ler_cenario(N, Json),
    preparar_pedido(Json, Pedido, Fraudes),
    avaliar_pedido(Pedido, Fraudes).

codigos_regras(Explicacoes, Codigos) :- findall(C, ( member(E, Explicacoes), C = E.codigoRegra ), Codigos).
nomes_condicoes(Condicoes, Nomes) :- findall(N, ( member(C, Condicoes), N = C.nome ), Nomes).
falhadas(E, Nomes) :- findall(N, ( member(C, E.condicoes), C.cumprida == false, N = C.nome ), Nomes).

% ---------------------------------------------------------------------------------------------
:- begin_tests(como).

test('Cenário 5: caminho completo até à paragem obrigatória CH-008') :-
    cenario(5), como(E),
    findall(C, ( member(P, E.passos), C = P.codigoRegra ), ['CT-003', 'CH-008', 'EX-002', 'OUT-007', 'OUT-001']),
    E.paragem == 'CH-008',
    E.modulosPercorridos == ['M0', 'M2', 'M6', 'M9'],
    forall(member(T, ["5 regras", "4 módulos", "CH-008", "M2"]), contem(E.resumo, T)).

test('Cenário 10: passo com ambiguidade, resultado e mensagem') :-
    cenario(10), como(E),
    findall(P, ( member(P, E.passos), P.codigoRegra == 'CH-004' ), [Passo]),
    Passo.aValidar == true, Passo.resultado == 'REVER', contem(Passo.mensagem, "portal"),
    E.paragem == null.

test('Cenário 7: como se concluiu OUT-001 = REVER (PT-003 e depois TN-011)') :-
    cenario(7), como_conclusao('OUT-001', null, E),
    E.regra == 'TN-011',
    E.valores.elegibilidade == "REVER",
    length(E.caminho, 2), E.caminho = [Primeiro|_], sub_string(Primeiro, 0, _, _, "PT-003"),
    nomes_condicoes(E.condicoes, Nomes),
    forall(member(N, [mercadoCanada, pagamentoInterac, cartaoFisicoAusente]), memberchk(N, Nomes)),
    forall(member(C, E.condicoes), C.cumprida == true),
    forall(member(T, ["OUT-001", "REVER", "TN-011"]), contem(E.resumo, T)).

test('Cenário 9: como se concluiu o destino do artigo (OUT-007)') :-
    cenario(9), como_conclusao('OUT-007', "A-1", E),
    E.valores.destino == "RISCO_BIOLOGICO", E.regra == 'PC-008'.

test('Cenário 9: a documentação tem o caminho dos controlos (OUT-008)') :-
    cenario(9), como_conclusao('OUT-008', null, E),
    E.regra == 'CT-007',
    member(H1, E.caminho), sub_string(H1, 0, _, _, "CT-004"), !,
    member(H2, E.caminho), sub_string(H2, 0, _, _, "CT-005"), !.

test('Conclusão sem regra; destino sem artigo é um erro') :-
    cenario(1), como_conclusao('OUT-006', null, E), E.regra == null,
    cenario(9), catch(como_conclusao('OUT-007', null, _), error(domain_error(_, _), _), true).

:- end_tests(como).

% ---------------------------------------------------------------------------------------------
:- begin_tests(porque_nao_conclusao).

test('Cenário 1: porque não PERMITIR? PT-003 propôs, mas a revisão prevaleceu') :-
    cenario(1), porque_nao_conclusao('OUT-001', "PERMITIR", null, E),
    E.obtida == false, E.valorObtido == "REVER",
    memberchk('PT-003', E.propostaPor), E.definidoPor == 'OUT-001',
    contem(E.resumo, "PT-003"), contem(E.resumo, "REVER").

test('Cenário 8: porque não ajuste de preço? Só PT-007 o produz, e falta o recibo original') :-
    cenario(8), porque_nao_conclusao('OUT-002', "AJUSTE_PRECO", null, E),
    E.obtida == false, E.propostaPor == [],
    E.regras = [R], R.codigoRegra == 'PT-007', R.causa == "CONDICOES_FALHADAS",
    falhadas(R, F), memberchk(reciboOriginal, F),
    contem(E.resumo, "PT-007").

test('Cenário 5: porque não reembolso? As regras que o produzem nunca foram alcançadas') :-
    cenario(5), porque_nao_conclusao('OUT-002', "REEMBOLSO", null, E),
    codigos_regras(E.regras, Cs),
    forall(member(C, ['PT-003', 'CH-002', 'CH-005']), memberchk(C, Cs)),
    forall(member(R, E.regras), R.causa == "MODULO_NAO_ALCANCADO").

test('Cenário 9: porque não área de vendas? O artigo é isolado') :-
    cenario(9), porque_nao_conclusao('OUT-007', "AREA_VENDAS", "A-1", E),
    E.valorObtido == "RISCO_BIOLOGICO",
    codigos_regras(E.regras, Cs),
    forall(member(C, ['CT-008', 'BW-001', 'EP-005']), memberchk(C, Cs)).

test('Cenário 4: conclusão obtida') :-
    cenario(4), porque_nao_conclusao('OUT-001', "RECUSAR", null, E),
    E.obtida == true, E.regras == [].

:- end_tests(porque_nao_conclusao).

% ---------------------------------------------------------------------------------------------
:- begin_tests(porque_nao_regra).

test('Cenário 5: HS-002 nunca foi avaliada, CH-008 terminou o fluxo em M2') :-
    cenario(5), porque_nao_regra('HS-002', null, E),
    E.causa == "MODULO_NAO_ALCANCADO", E.regraResponsavel == 'CH-008',
    contem(E.resumo, "CH-008"), contem(E.resumo, "M2").

test('Cenário 6: o fluxo foi suspenso por EX-008') :-
    cenario(6), porque_nao_regra('PT-002', null, E),
    E.causa == "MODULO_NAO_ALCANCADO", E.regraResponsavel == 'EX-008'.

test('PC-001 vencida por HS-002 (marca excluída), com mais prioridade no mesmo módulo') :-
    um_pedido(P0), com(P0, ["artigos[0].produto.marca"-"DOCKERS"], P), avaliar(P),
    porque_nao_regra('PC-001', "A-1", E),
    E.causa == "CANCELADA_POR_PRECEDENCIA", E.regraResponsavel == 'HS-002'.

test('Cenário 4: PC-006 falha porque o produto foi embainhado (HS-003 prevalece)') :-
    cenario(4), porque_nao_regra('PC-006', "A-1", E),
    E.causa == "CONDICOES_FALHADAS",
    falhadas(E, F), memberchk(naoModificado, F),
    contem(E.resumo, "HS-003 prevalece").

test('Regra que disparou e regra desconhecida') :-
    cenario(7), porque_nao_regra('PT-003', null, E), E.causa == "DISPAROU",
    catch(porque_nao_regra('XX-999', null, _), error(existence_error(regra, _), _), true).

:- end_tests(porque_nao_regra).

% ---------------------------------------------------------------------------------------------
:- begin_tests(porque).

test('Cenário 1: porquê perguntar se o artigo pode ser revendido? PC-002 espera a resposta') :-
    cenario(1), porque('IN-010', E),
    contem(E.pergunta, "reetiquetado e revendido"),
    forall(member(C, ['PC-002', 'PC-003', 'PT-004', 'BW-001']), memberchk(C, E.regrasQueDependem)),
    findall(N, ( member(R, E.regrasEmEspera), N = R.nomeRegra ), Nomes), msort(Nomes, Ordenados),
    Ordenados == ["PC-002 Etiquetas soltas: aprovado, artigo revendível",
                  "PC-002 Etiquetas soltas: recusado, artigo não revendível"],
    forall(member(R, E.regrasEmEspera), R.artigoId == "A-1"),
    findall(C, ( member(R, E.regrasEmEspera), member(C, R.conclusoes) ), Cs),
    memberchk("OUT-001=PERMITIR", Cs), memberchk("OUT-001=RECUSAR", Cs),
    contem(E.resumo, "2 decisão(ões)"), contem(E.resumo, "PC-002").

test('Cenário 1: o dado em falta devolvido pelo "O que falta?" traz o seu porquê') :-
    cenario(1), pedido_atual(P), dados_em_falta(P, F),
    F.dados = [D|_], D.codigo == 'IN-010',
    D.porque.dado == 'IN-010', D.porque.regrasEmEspera \== [].

test('Cenário 8: porquê perguntar pelo comprovativo?') :-
    cenario(8), porque('IN-004', E),
    findall(R, ( member(R, E.regrasEmEspera), R.codigoRegra == 'PT-007' ), Rs), Rs \== [],
    findall(R, ( member(R, Rs), sub_string(R.nomeRegra, 0, _, _, "PT-007 Ajuste de preço único") ), [Unico]),
    nomes_condicoes(Unico.condicoesDoDado, Ns), memberchk(reciboOriginal, Ns).

test('Depois de uma paragem obrigatória nenhuma decisão espera pela resposta') :-
    cenario(5), porque('IN-009', E),
    E.regrasEmEspera == [],
    memberchk('TN-001', E.regrasQueDependem), memberchk('TN-008', E.regrasQueDependem),
    contem(E.resumo, "nenhuma decisão está pendente").

:- end_tests(porque).

% ---------------------------------------------------------------------------------------------
simular(Json, Alteracoes, E) :-
    preparar_pedido(Json, P, F), avaliar_pedido(P, F),
    resultado_comparavel(Original),
    e_se(Json, Alteracoes, Original, E).

:- begin_tests(e_se).

test('Cenário 10: e se o portal estivesse disponível? CH-002 em vez de CH-004') :-
    ler_cenario(10, J), simular(J, _{portalOnlineDisponivel:true}, E),
    memberchk('CH-002', E.regrasNovas), memberchk('CH-004', E.regrasRemovidas),
    E.diferencas \== [], contem(E.resumo, "campo(s)").

test('Cenário 8: e se trouxesse o recibo original? PT-007 permite o ajuste') :-
    ler_cenario(8, J), simular(J, _{'comprovativo.reciboOriginal':true}, E),
    E.decisaoSimulada.elegibilidade == 'PERMITIR', E.decisaoSimulada.tipoTransacao == 'AJUSTE_PRECO',
    member(D, E.diferencas), D.alvo == "pedido", D.campo == elegibilidade,
    D.original == "RECUSAR", D.simulado == "PERMITIR", !,
    memberchk('PT-007', E.regrasNovas), memberchk('PT-008', E.regrasRemovidas).

test('Alterações em listas e enumerados') :-
    um_pedido(P), simular(P, _{'artigos[0].estado.embainhado':true, 'compraOriginal.pagamento.meio':"DEBITO"}, E),
    memberchk('HS-003', E.regrasNovas), E.decisaoSimulada.elegibilidade == 'RECUSAR'.

test('Sem diferenças') :-
    um_pedido(P), simular(P, _{'cliente.forneceDados':true}, E),
    E.diferencas == [], contem(E.resumo, "não muda").

test('Valor nulo remove o comprovativo') :-
    um_pedido(P), simular(P, _{comprovativo:null}, E),
    memberchk('PT-002', E.regrasNovas), memberchk('PT-005', E.regrasNovas).

test('Caminho inválido') :-
    um_pedido(P),
    catch(simular(P, _{naoExiste:1}, _), error(domain_error(caminho, _), _), true),
    catch(simular(P, _{'artigos[5].revendivel':true}, _), error(domain_error(alteracao, _), _), true).

:- end_tests(e_se).

% ---------------------------------------------------------------------------------------------
falta_codigos(Json, Codigos, Obrigatorios) :-
    preparar_pedido(Json, P, _),
    dados_em_falta(P, F),
    findall(C, ( member(D, F.dados), C = D.codigo ), Codigos),
    findall(C, ( member(D, F.dados), D.obrigatorio == true, C = D.codigo ), Obrigatorios).

:- begin_tests(o_que_falta).

test('Cenário 1: falta avaliar a revenda (IN-010) para resolver PC-002') :-
    ler_cenario(1, J), preparar_pedido(J, P, _), dados_em_falta(P, F),
    F.dados = [D], D.codigo == 'IN-010', D.caminho == "artigos[0].revendivel", D.obrigatorio == false.

test('Cenário 3: devolução às cegas sem dados obrigatórios em falta (A-16)') :-
    ler_cenario(3, J), falta_codigos(J, _, []).

test('Todos os cenários têm os dados obrigatórios', [forall(between(1, 10, N))]) :-
    ler_cenario(N, J), falta_codigos(J, _, []).

test('Pedido incompleto') :-
    um_pedido(P0),
    com(P0, ["loja"-null, "tipoPedido"-null, "compraOriginal.pagamento"-null, "compraOriginal.dataCompra"-null,
             "artigos[0].estado.etiquetas"-null, "artigos[0].produto.sku"-null], P),
    falta_codigos(P, _, Obrigatorios),
    msort(Obrigatorios, Ordenados),
    Ordenados == ['IN-001', 'IN-002', 'IN-005', 'IN-006', 'IN-007', 'IN-008', 'IN-009'].

test('Verificada após trinta dias precisa da revenda') :-
    um_pedido(P0), dias_desde_compra(P0, 40, P),
    falta_codigos(P, ['IN-010'], []).

:- end_tests(o_que_falta).
