:- encoding(utf8).
/*  Coerência da base de conhecimento (equivalente a MetadadosRegrasTest, CoerenciaConclusoesTest,
    CatalogoRegrasTest e CoberturaRegrasTest do projeto Drools):

      - cada regra tem módulo, prioridade e descrição válidos e as conclusões no formato OUT-00n=VALOR;
      - cada condição usada existe e está descrita, e cada condição de entrada lê um dado;
      - cada dado de entrada (pergunta) é usado por alguma regra;
      - as ações das regras são conhecidas;
      - tudo o que uma regra altera nos campos OUT está declarado nas suas conclusões;
      - nenhuma regra dispara duas vezes sobre a mesma decisão;
      - cada ID da base de conhecimento dispara em algum pedido de teste e é referido num teste.
*/

:- use_module(library(plunit)).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(readutil)).
:- use_module(suporte).
:- use_module(verificador).
:- use_module('../src/motor/operadores').
:- use_module('../src/motor/motor', [regras_por_ordem/1, regra_info/2, regra_def/4, lhs_lista/2, grupos/1]).
:- use_module('../src/motor/memoria', [evento/6, alteracao/5, registo/7]).
:- use_module('../src/bc/condicoes').
:- use_module('../src/servico', [preparar_pedido/3, avaliar_pedido/2]).

regra(Nome, Info) :- regras_por_ordem(Ns), member(Nome, Ns), regra_info(Nome, Info).

ids(Ids) :- findall(I, ( regra(_, Info), I = Info.id ), Is), sort(Is, Ids).

condicao_da_regra(Nome, C) :-
    regra_def(Nome, LHS, _, _), lhs_lista(LHS, Cs), member(C0, Cs),
    ( C0 = (nao C) -> true ; C = C0 ).

%   Campo de saída de cada campo das decisões (OUT-001 a OUT-008).
campo_out(elegibilidade, 'OUT-001').
campo_out(tipoTransacao, 'OUT-002').
campo_out(valorDevolucao, 'OUT-003').
campo_out(baseValor, 'OUT-003').
campo_out(meioReembolso, 'OUT-004').
campo_out(aprovacao, 'OUT-005').
campo_out(processo, 'OUT-006').
campo_out(destino, 'OUT-007').
campo_out(descontoSaldo, 'OUT-007').
campo_out(Campo, 'OUT-008') :- atom(Campo), sub_atom(Campo, 0, _, _, 'documentacao.').

codigo_out(C) :- memberchk(C, ['OUT-001', 'OUT-002', 'OUT-003', 'OUT-004', 'OUT-005', 'OUT-006', 'OUT-007', 'OUT-008']).

% ---------------------------------------------------------------------------------------------
:- begin_tests(metadados).

test('A base tem 98 regras e 76 IDs') :-
    regras_por_ordem(Ns), length(Ns, 98),
    ids(Ids), length(Ids, 76).

test('Cada regra tem módulo, prioridade e descrição', [forall(regra(N, I))]) :-
    grupos(Gs), memberchk(I.modulo, Gs),
    integer(I.prioridade),
    string(I.descricao), I.descricao \== "",
    sub_atom(N, 0, _, _, I.id).

test('As conclusões estão no formato OUT-00n ou OUT-00n=VALOR', [forall(regra(_, I))]) :-
    forall(member(C, I.conclusoes),
           ( C = (Out = V) -> codigo_out(Out), atom(V) ; codigo_out(C) )).

test('Só EX-008 e PC-008 têm auto-focus, no grupo TRANSVERSAL') :-
    findall(Id, ( regra(_, I), get_dict(auto_foco, I, true), get_dict(id, I, Id) ), Ids), msort(Ids, ['EX-008', 'PC-008']),
    forall(( regra(_, I), I.auto_foco == true ), I.modulo == transversal).

test('Regras sem a guarda do fluxo terminado: só as previstas no ADR 0004') :-
    findall(Id, ( regra(_, I), get_dict(sem_guarda, I, true), get_dict(id, I, Id) ), Ids0), sort(Ids0, Ids),
    Ids == ['EX-002', 'EX-003', 'EX-008', 'OUT-001', 'OUT-007', 'PC-008'].

test('As ações das regras são conhecidas', [forall(regra(N, _))]) :-
    regra_def(N, _, RHS, _),
    forall(member(A, RHS),
           memberchk(A, [calcular(_), definir(_, _, _), aplicar(_, _, _), registar(_, _), resolver_revisao(_, _),
                         suspender(_), recusar_excecao(_), marcar_suspenso, agregar_artigos])).

:- end_tests(metadados).

% ---------------------------------------------------------------------------------------------
:- begin_tests(condicoes).

test('Cada condição usada está descrita e definida', [forall(( regra(N, _), condicao_da_regra(N, C) ))]) :-
    functor(C, Nome, Ar),
    condicao_info(Nome/Ar, _, _),
    current_predicate(condicoes:Nome/Ar).

test('Cada condição de entrada lê pelo menos um dado', [forall(( regra(N, _), condicao_da_regra(N, C) ))]) :-
    functor(C, Nome, Ar),
    (   condicao_info(Nome/Ar, entrada, _) -> once(le_dado(Nome, _)) ; true ).

test('Cada dado de entrada é usado por alguma regra', [forall(dado_entrada(D, _, _, _))]) :-
    once(( regra(N, _), condicao_da_regra(N, C), functor(C, Nome, _), le_dado(Nome, D) )).

:- end_tests(condicoes).

% ---------------------------------------------------------------------------------------------
%   Pedidos de teste que, em conjunto, fazem disparar todas as regras.
variacao(Alteracoes, Fraudes) :- variacao_(Alteracoes, Fraudes).

variacao_([], []).
variacao_(["colaborador.funcao"-"STYLIST"], []).
variacao_(["compraOriginal.canal"-"GROSSISTA", "cliente.contestaResultado"-true], []).
variacao_(["compraOriginal.canal"-"FRANQUIA_CANADA"], []).
variacao_(["compraOriginal.canal"-"DESCONHECIDO"], []).
variacao_(["artigos[0].produto.skuReconhecidoPOS"-false], []).
variacao_(["artigos[0].produto.skuReconhecidoPOS"-false, "artigos[0].produto.produtoFranquia"-true], []).
variacao_(["artigos[0].produto.produtoFranquia"-true], []).
variacao_(["artigos[0].produto.marca"-"DOCKERS"], []).
variacao_(["artigos[0].estado.embainhado"-true, "artigos[0].estado.sujoOuInseguro"-true], []).
variacao_(["artigos[0].produto.categoria"-"BODYWEAR", "artigos[0].estado.embalagemIntacta"-true, "artigos[0].revendivel"-true], []).
variacao_(["artigos[0].produto.categoria"-"BODYWEAR", "artigos[0].estado.embalagemIntacta"-true, "artigos[0].revendivel"-false], []).
variacao_(["artigos[0].produto.categoria"-"BODYWEAR", "artigos[0].estado.embalagemIntacta"-true], []).
variacao_(["artigos[0].produto.categoria"-"BODYWEAR"], []).
variacao_(["artigos[0].produto.categoria"-"BODYWEAR", "artigos[0].estado.conjuntoCompleto"-false], []).
variacao_(["artigos[0].produto.categoria"-"BODYWEAR", "artigos[0].estado.condicaoUso"-"USADO", "artigos[0].estado.sujoOuInseguro"-true], []).
variacao_(["artigos[0].estado.defeitoFabricoConfirmado"-true, "artigos[0].estado.condicaoUso"-"USADO"], []).
variacao_(["artigos[0].estado.etiquetas"-"SOLTAS"], []).
variacao_(["artigos[0].estado.etiquetas"-"SOLTAS", "artigos[0].revendivel"-true], []).
variacao_(["artigos[0].estado.etiquetas"-"SOLTAS", "artigos[0].revendivel"-false], []).
variacao_(["artigos[0].estado.etiquetas"-"AUSENTES"], []).
variacao_(["artigos[0].estado.etiquetas"-"AUSENTES", "artigos[0].revendivel"-true], []).
variacao_(["artigos[0].estado.etiquetas"-"AUSENTES", "artigos[0].revendivel"-false], []).
variacao_(["artigos[0].estado.condicaoUso"-"USADO"], []).
variacao_(["artigos[0].estado.condicaoUso"-"USADO", "pedidoExcecao"-_{aprovada:true}], []).
variacao_(["artigos[0].estado.condicaoUso"-"USADO", "pedidoExcecao"-_{aprovada:false}], []).
variacao_(["artigos[0].estado.condicaoUso"-"LAVADO"], []).
variacao_(["comprovativo"-null, "compraOriginal.dataCompra"-null, "cliente.forneceDados"-false], []).
variacao_(["comprovativo"-null, "compraOriginal.dataCompra"-null, "loja.tipoLoja"-"OUTLET",
           "compraOriginal.promocaoEscaloes"-true, "colaborador.funcao"-"LEAD_CASHIER", "colaborador.aprovadoPeloDM"-true], []).
variacao_(["compraOriginal.dataCompra"-"2026-02-01"], []).
variacao_(["compraOriginal.dataCompra"-"2026-02-01", "artigos[0].revendivel"-true], []).
variacao_(["compraOriginal.dataCompra"-"2026-02-01", "artigos[0].revendivel"-false], []).
variacao_(["tipoPedido"-"AJUSTE_PRECO"], []).
variacao_(["tipoPedido"-"AJUSTE_PRECO", "compraOriginal.dataCompra"-"2026-03-01"], []).
variacao_(["tipoPedido"-"AJUSTE_PRECO", "compraOriginal.ajustePrecoAplicado"-true], []).
variacao_(["tipoPedido"-"AJUSTE_PRECO", "compraOriginal.canal"-"BACKPOCKET"], []).
variacao_(["compraOriginal.canal"-"LEVI_COM", "compraOriginal.encomendaEncontrada"-true, "compraOriginal.dataEnvio"-"2026-03-21",
           "tipoPedido"-"TROCA", "compraOriginal.pagamento.meio"-"AFTERPAY"], []).
variacao_(["compraOriginal.canal"-"LEVI_COM", "compraOriginal.encomendaEncontrada"-true, "compraOriginal.dataEnvio"-"2026-02-01"], []).
variacao_(["compraOriginal.canal"-"LEVI_COM", "compraOriginal.encomendaEncontrada"-true, "compraOriginal.dataEnvio"-"2026-03-21",
           "tipoPedido"-"TROCA"], []).
variacao_(["compraOriginal.canal"-"LEVI_COM", "compraOriginal.encomendaEncontrada"-true, "portalOnlineDisponivel"-false], []).
variacao_(["compraOriginal.canal"-"LEVI_CA", "politicaPermiteAsCegasOnline"-true, "portalOnlineDisponivel"-false], []).
variacao_(["compraOriginal.canal"-"LEVI_CA", "politicaPermiteAsCegasOnline"-false], []).
variacao_(["compraOriginal.pagamento.estadoConta"-"ATIVA_CARTAO_PERDIDO"], []).
variacao_(["compraOriginal.pagamento.estadoConta"-"ENCERRADA"], []).
variacao_(["compraOriginal.pagamento.estadoConta"-"ENCERRADA", "compraOriginal.pagamento.reembolsoOriginalRecusado"-true], []).
variacao_(["compraOriginal.pagamento.meio"-"DEBITO"], []).
variacao_(["compraOriginal.pagamento.meio"-"APPLE_PAY"], []).
variacao_(["compraOriginal.pagamento.meio"-"PAYPAL"], []).
variacao_(["compraOriginal.pagamento.meio"-"VENMO", "compraOriginal.pagamento.acessoAplicacaoPagamento"-false], []).
variacao_(["compraOriginal.pagamento.meio"-"AFTERPAY"], []).
variacao_(["compraOriginal.pagamento.meio"-"NUMERARIO"], []).
variacao_(["compraOriginal.pagamento.meio"-"INTERAC", "loja.mercado"-"CANADA", "compraOriginal.canal"-"BACKPOCKET",
           "compraOriginal.pagamento.cartaoFisicoPresente"-true], []).
variacao_(["compraOriginal.pagamento.meio"-"INTERAC", "loja.mercado"-"CANADA"], []).
variacao_(["tipoPedido"-"DEVOLUCAO_OFERTA"], []).
variacao_(["tipoPedido"-"TROCA", "artigosTroca"-[_{apenasMudaTamanho:true, precoVenda:98.0}]], []).
variacao_(["tipoPedido"-"TROCA", "artigosTroca"-[_{apenasMudaTamanho:false, precoVenda:60.0}]], []).
variacao_(["cliente.contestaResultado"-true, "cliente.agitado"-true, "pedidoExcecao"-_{motivo:"x"}, "artigos[0].revendivel"-true], []).
variacao_(["cliente.contestaResultado"-true, "cliente.agitado"-true, "pedidoExcecao"-_{motivo:"x"}, "artigos[0].revendivel"-false], []).
variacao_(["cliente.contestaResultado"-true, "cliente.agitado"-true, "pedidoExcecao"-_{exigeMeioProibido:true}], []).
variacao_(["cliente.contestaResultado"-true, "cliente.agitado"-true, "pedidoExcecao"-_{concluivelNoSistema:false}], []).
variacao_(["pedidoExcecao"-_{aprovada:true, aprovador:_{nome:"Ana", funcao:"GESTAO_LOJA"}}], []).
variacao_(["comprovativo.tipo"-"RECIBO_DIGITAL", "comprovativo.confirmaCompra"-true], []).
variacao_(["loja.tipoLoja"-"OUTLET", "compraOriginal.canal"-"MAINLINE"], []).
variacao_(["compraOriginal.promocaoEscaloes"-true, "artigos[0].valorCalculadoPos"-55.25], []).
variacao_(["artigos[0].entreCanais"-true, "artigos[0].produto.emSaldo"-true], []).
variacao_(["artigos[0].entreCanais"-true, "loja.skusSortido"-["501-A-1"]], []).
variacao_(["artigos[0].entreCanais"-true], []).
variacao_(["artigos[0].estado.rfidCorreto"-false], []).
variacao_(["artigos[0].estado.danificado"-true], []).
variacao_(["artigos[0].estado.sujoOuInseguro"-true], ["Recibo adulterado"-"CONFIRMADO"]).

avaliar_variacao(Alteracoes, Fraudes) :-
    um_pedido(P0), com(P0, Alteracoes, P), avaliar(P, Fraudes).

%   Pedidos dos cenários e das variações, para as verificações sobre execuções.
execucao(cenario(N)) :- between(1, 10, N).
execucao(variacao(I)) :- findall(x, variacao(_, _), L), length(L, Total), between(1, Total, I).

executar(cenario(N)) :-
    ler_cenario(N, J), preparar_pedido(J, P, F), avaliar_pedido(P, F).
executar(variacao(I)) :-
    findall(A-F, variacao(A, F), Vs), nth1(I, Vs, A-F), avaliar_variacao(A, F).

:- begin_tests(execucoes).

test('Tudo o que uma regra altera nos campos OUT está nas suas conclusões', [forall(execucao(E))]) :-
    executar(E),
    forall(( evento(Seq, disparada, Nome, _, _, _), alteracao(Seq, _, Campo, _, Depois), campo_out(Campo, Out) ),
           ( regra_info(Nome, I),
             (   memberchk(Out, I.conclusoes) -> true
             ;   Out == 'OUT-008', memberchk('OUT-008', I.conclusoes) -> true
             ;   memberchk(Out = Depois, I.conclusoes) -> true
             ;   Campo == descontoSaldo, member(Out = _, I.conclusoes) -> true
             ;   Campo == baseValor, memberchk('OUT-003', I.conclusoes) -> true
             ;   format(user_error, "~w altera ~w (~w) sem o declarar~n", [Nome, Campo, Depois]), fail
             ) )).

test('Nenhuma regra dispara duas vezes sobre a mesma decisão', [forall(execucao(E))]) :-
    executar(E),
    findall(N-A, registo(_, A, _, N, _, _, _), Pares),
    msort(Pares, Ordenados), sort(Pares, Unicos),
    Ordenados == Unicos.

test('Cada ID da base dispara em algum pedido de teste') :-
    ids(Ids),
    findall(C, ( execucao(E), executar(E), evento(_, disparada, _, C, _, _) ), Cs0),
    sort(Cs0, Cs),
    subtract(Ids, Cs, SemDisparo),
    SemDisparo == [].

:- end_tests(execucoes).

% ---------------------------------------------------------------------------------------------
:- begin_tests(cobertura).

%   Definição de concluído do projeto Drools: cada regra é referida (pelo ID) num teste.
test('Cada ID da base é referido no nome de um teste') :-
    ids(Ids),
    diretorio_cenarios(DirCenarios), file_directory_name(DirCenarios, Dir),
    directory_files(Dir, Ficheiros),
    findall(T, ( member(F, Ficheiros), sub_atom(F, 0, _, _, testes_), file_name_extension(_, pl, F),
                 directory_file_path(Dir, F, Caminho), read_file_to_string(Caminho, T, [encoding(utf8)]) ), Textos),
    atomic_list_concat(Textos, Todo),
    findall(Id, ( member(Id, Ids), format(string(Padrao), "test('~w", [Id]), \+ sub_string(Todo, _, _, _, Padrao),
                  format(string(P2), "~w ", [Id]), \+ sub_string(Todo, _, _, _, P2) ), SemTeste),
    SemTeste == [].

:- end_tests(cobertura).
