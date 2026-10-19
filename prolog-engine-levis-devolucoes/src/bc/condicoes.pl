:- encoding(utf8).
:- module(condicoes, [
    condicao_info/3,            % ?Nome/Aridade, ?Tipo, ?Descricao
    le_dado/2,                  % ?NomeCondicao, ?CodigoDado
    dado_entrada/4,             % ?Codigo, ?Nome, ?Caminho, ?Pergunta
    valor_condicao/2,           % +Condicao, -Texto
    eleg_aceite/1               % ?Elegibilidade
]).

:- discontiguous condicao_info/3.

/** <module> Vocabulário das condições das regras

Cada condição usada no lado esquerdo (`se`) de uma regra é um predicado deste módulo. Os nomes
seguem os do metadado `@condicoes` do projeto Drools, para que o rasto e as explicações dos dois
motores usem a mesma linguagem. As condições sobre um artigo recebem o identificador do artigo.

Cada condição declara:
  - condicao_info(Nome/Aridade, Tipo, Descricao), com Tipo:
      - `entrada`: depende só dos factos do pedido (é a que se mostra no "Como");
      - `estado`: depende do estado das decisões (resultado de outras regras);
      - `guarda`: guarda de execução (fluxo terminado, regra já disparada), não é explicada;
      - `gerador`: enumera os artigos do pedido;
  - le_dado(Nome, Dado): os dados de entrada que lê (para o "Porquê", como DependenciasDados).

Os testes `!= null` do DRL estão em cada condição: um objeto em falta torna a condição falsa
(salvo quando o DRL a admite, ex.: `pagamento == null || ...`).
*/

:- use_module('../motor/memoria').
:- use_module(pedido).

% =============================================================================================
% Guardas e geradores
% =============================================================================================

condicao_info(artigo/1, gerador, "Artigo do pedido").
condicao_info(pedidoAtivo/0, guarda, "O fluxo do pedido não terminou").
condicao_info(artigoAtivo/1, guarda, "O fluxo do artigo não terminou").
condicao_info(naoDisparou/2, guarda, "A regra ainda não disparou").
condicao_info(disparouRegra/2, estado, "A regra já disparou").

pedidoAtivo :- decisao(pedido, terminal, false).
artigoAtivo(A) :- decisao(artigo(A), terminal, false).
naoDisparou(Alvo, Codigo) :- \+ disparou(Alvo, Codigo).
disparouRegra(Alvo, Codigo) :- disparou(Alvo, Codigo).

% =============================================================================================
% Canal, loja, comprovativo e tipo de pedido
% =============================================================================================

condicao_info(canalGrossista/0, entrada, "Compra num retalhista grossista").
condicao_info(canalFranquiaCanada/0, entrada, "Compra na franquia do Canadá").
condicao_info(canalLoja/0, entrada, "Compra Mainline ou Outlet devolvida numa loja Levi's").
condicao_info(canalDesconhecido/0, entrada, "Canal de compra desconhecido").
condicao_info(compraMainlineOuOutlet/0, entrada, "Compra em loja Mainline ou Outlet").
condicao_info(compraForaDaLoja/0, entrada, "Compra fora das lojas Mainline e Outlet").
condicao_info(compraBackPocket/0, entrada, "Compra BackPocket").
condicao_info(compraOnline/0, entrada, "Compra em levi.com ou levi.ca").
condicao_info(compraNaoOnline/0, entrada, "Compra que não é online").
condicao_info(origemMainlineOuOnline/0, entrada, "Compra Mainline ou online").
condicao_info(lojaOutlet/0, entrada, "A loja recetora é Outlet").
condicao_info(lojaDefinida/0, entrada, "Loja recetora indicada").
condicao_info(mercadoCanada/0, entrada, "Loja no Canadá").
condicao_info(comprovativoValido/0, entrada, "Comprovativo válido (PT-001)").
condicao_info(comprovativoConfirmaCompra/0, entrada, "O comprovativo confirma a compra").
condicao_info(semComprovativoValido/0, entrada, "Sem comprovativo válido que confirme a compra").
condicao_info(reciboOriginal/0, entrada, "Recibo original").
condicao_info(reciboOriginalImpresso/0, entrada, "Recibo original impresso").
condicao_info(encomendaEncontrada/0, entrada, "A encomenda online foi encontrada").
condicao_info(encomendaNaoEncontrada/0, entrada, "A encomenda online não foi encontrada").
condicao_info(portalDisponivel/0, entrada, "Portal de devoluções online disponível").
condicao_info(portalIndisponivel/0, entrada, "Portal de devoluções online indisponível").
condicao_info(politicaPermiteAsCegasOnline/0, entrada, "A política permite a devolução online às cegas").
condicao_info(politicaNaoPermiteAsCegasOnline/0, entrada, "A política não permite a devolução online às cegas").
condicao_info(promocaoEscaloes/0, entrada, "Promoção por escalões").
condicao_info(stylistDaVendaConhecido/0, entrada, "Stylist da venda original conhecido").
condicao_info(ajustePreco/0, entrada, "Pedido de ajuste de preço").
condicao_info(naoEAjustePreco/0, entrada, "Não é um ajuste de preço").
condicao_info(devolucaoOferta/0, entrada, "Devolução de oferta").
condicao_info(naoEOferta/0, entrada, "Não é devolução de oferta").
condicao_info(pedidoTroca/0, entrada, "Pedido de troca").
condicao_info(apenasMudaTamanho/0, entrada, "A troca muda apenas o tamanho").
condicao_info(mudaModeloOuCor/0, entrada, "A troca muda o modelo ou a cor").
condicao_info(dataPedidoDefinida/0, entrada, "Data do pedido indicada").

canal(Canal) :- p([compraOriginal, canal], Canal).

canalGrossista :- canal(grossista).
canalFranquiaCanada :- canal(franquia_canada).
canalLoja :- lojaDefinida, canal(C), memberchk(C, [mainline, outlet]).
canalDesconhecido :- canal(desconhecido).
compraMainlineOuOutlet :- canal(C), memberchk(C, [mainline, outlet]).
compraForaDaLoja :- p([compraOriginal], Compra), Compra \== null, canal(C), \+ memberchk(C, [mainline, outlet]).
compraBackPocket :- canal(backpocket).
compraOnline :- compra_online.
compraNaoOnline :- \+ compra_online.
origemMainlineOuOnline :- canal(C), memberchk(C, [mainline, levi_com, levi_ca]).
lojaOutlet :- p([loja, tipoLoja], outlet).
lojaDefinida :- p([loja], L), L \== null.
mercadoCanada :- p([loja, mercado], canada).
comprovativoValido :- p([comprovativo, tipo], T), T \== null.
comprovativoConfirmaCompra :- p([comprovativo, confirmaCompra], true).
semComprovativoValido :- \+ ( comprovativoValido, comprovativoConfirmaCompra ).
reciboOriginal :- p([comprovativo, reciboOriginal], true).
reciboOriginalImpresso :- reciboOriginal, p([comprovativo, tipo], recibo_impresso).
encomendaEncontrada :- p([compraOriginal, encomendaEncontrada], true).
encomendaNaoEncontrada :- p([compraOriginal, encomendaEncontrada], false).
portalDisponivel :- p([portalOnlineDisponivel], true).
portalIndisponivel :- p([portalOnlineDisponivel], false).
politicaPermiteAsCegasOnline :- p([politicaPermiteAsCegasOnline], true).
politicaNaoPermiteAsCegasOnline :- p([politicaPermiteAsCegasOnline], false).
promocaoEscaloes :- p([compraOriginal, promocaoEscaloes], true).
stylistDaVendaConhecido :- p([compraOriginal, idStylistVenda], S), S \== null.
ajustePreco :- p([tipoPedido], ajuste_preco).
naoEAjustePreco :- \+ ajustePreco.
devolucaoOferta :- p([tipoPedido], devolucao_oferta).
naoEOferta :- \+ devolucaoOferta.
pedidoTroca :- p([tipoPedido], troca).
apenasMudaTamanho :-
    p([artigosTroca], Trocas), Trocas \== [],
    forall(member(T, Trocas), T.apenasMudaTamanho == true).
mudaModeloOuCor :-
    p([artigosTroca], Trocas),
    member(T, Trocas), T.apenasMudaTamanho == false, !.
dataPedidoDefinida :- p([dataPedido], D), D \== null.

% =============================================================================================
% Prazos
% =============================================================================================

condicao_info(ate30DiasDesdeCompra/0, entrada, "Até 30 dias desde a compra").
condicao_info(mais30DiasDesdeCompra/0, entrada, "Mais de 30 dias desde a compra").
condicao_info(ate14DiasDesdeCompra/0, entrada, "Até 14 dias desde a compra").
condicao_info(mais14DiasOuSemReciboOriginal/0, entrada, "Mais de 14 dias ou sem recibo original").
condicao_info(ate30DiasDesdeEnvio/0, entrada, "Até 30 dias desde o envio (ou data de envio desconhecida)").
condicao_info(mais30DiasDesdeEnvio/0, entrada, "Mais de 30 dias desde o envio").
condicao_info(semAjusteAnterior/0, entrada, "Sem ajuste de preço anterior").
condicao_info(ajusteAnterior/0, entrada, "Já houve um ajuste de preço").

ate30DiasDesdeCompra :- dias_desde_compra(D), D \== null, D =< 30.
mais30DiasDesdeCompra :- dias_desde_compra(D), D \== null, D > 30.
ate14DiasDesdeCompra :- dias_desde_compra(D), D \== null, D =< 14.
mais14DiasOuSemReciboOriginal :-
    (   \+ reciboOriginal
    ->  true
    ;   dias_desde_compra(D), ( D == null -> true ; D > 14 )
    ).
ate30DiasDesdeEnvio :- dias_desde_envio(D), ( D == null -> true ; D =< 30 ).
mais30DiasDesdeEnvio :- dias_desde_envio(D), D \== null, D > 30.
semAjusteAnterior :- p([compraOriginal, ajustePrecoAplicado], false).
ajusteAnterior :- p([compraOriginal, ajustePrecoAplicado], true).

% =============================================================================================
% Produto e estado do artigo
% =============================================================================================

condicao_info(produtoDefinido/1, entrada, "Produto do artigo indicado").
condicao_info(skuReconhecido/1, entrada, "SKU reconhecido no POS").
condicao_info(skuNaoReconhecido/1, entrada, "SKU não reconhecido no POS").
condicao_info(produtoFranquia/1, entrada, "Produto da franquia do Canadá").
condicao_info(produtoNaoFranquia/1, entrada, "Produto que não é da franquia do Canadá").
condicao_info(marcaExcluidaOuGrossistaNaoVendido/1, entrada, "Dockers, LS Signature, Beyond Yoga ou grossista não vendido na loja").
condicao_info(produtoModificado/1, entrada, "Produto personalizado, alterado ou embainhado").
condicao_info(naoModificado/1, entrada, "Produto não personalizado nem alterado (HS-003 prevalece)").
condicao_info(bodywear/1, entrada, "Bodywear").
condicao_info(naoBodywear/1, entrada, "Não é bodywear").
condicao_info(naoUsado/1, entrada, "Não usado").
condicao_info(usado/1, entrada, "Claramente usado").
condicao_info(lavado/1, entrada, "Lavado").
condicao_info(etiquetasColocadas/1, entrada, "Etiquetas originais colocadas").
condicao_info(etiquetasSoltas/1, entrada, "Etiquetas soltas").
condicao_info(etiquetasAusentes/1, entrada, "Sem etiquetas").
condicao_info(defeitoFabricoConfirmado/1, entrada, "Defeito de fabrico confirmado").
condicao_info(semDefeito/1, entrada, "Sem defeito de fabrico confirmado").
condicao_info(sujoOuInseguro/1, entrada, "Sujo, contaminado ou inseguro").
condicao_info(artigoSujoOuInseguro/1, entrada, "Artigo sujo, contaminado ou inseguro de manusear").
condicao_info(embalagemIntacta/1, entrada, "Embalagem original intacta").
condicao_info(semEmbalagem/1, entrada, "Sem a embalagem original").
condicao_info(conjuntoCompleto/1, entrada, "Conjunto completo").
condicao_info(conjuntoIncompletoOuUsado/1, entrada, "Faltam unidades do conjunto ou foi usado").
condicao_info(revendivel/1, entrada, "Verificável, reetiquetável e revendível (IN-010)").
condicao_info(naoRevendivel/1, entrada, "Não revendível (IN-010)").
condicao_info(revendivelPorAvaliar/1, entrada, "Possibilidade de revenda ainda por avaliar (IN-010)").
condicao_info(revendivelNaoNegado/1, entrada, "A revenda não foi recusada (IN-010)").
condicao_info(entreCanais/1, entrada, "Artigo comprado noutro canal ou loja").
condicao_info(emSaldo/1, entrada, "Já está em saldo").
condicao_info(naoEmSaldo/1, entrada, "Não está em saldo").
condicao_info(noSortidoDaLojaRecetora/1, entrada, "Está ou esteve no sortido da loja recetora").
condicao_info(foraDoSortidoDaLojaRecetora/1, entrada, "Fora do sortido da loja recetora").

produtoDefinido(A) :- a(A, [produto], P), P \== null.
skuReconhecido(A) :- a(A, [produto, skuReconhecidoPOS], true).
skuNaoReconhecido(A) :- a(A, [produto, skuReconhecidoPOS], false).
produtoFranquia(A) :- a(A, [produto, produtoFranquia], true).
produtoNaoFranquia(A) :- a(A, [produto, produtoFranquia], false).
marcaExcluidaOuGrossistaNaoVendido(A) :-
    produtoDefinido(A),
    (   a(A, [produto, marca], M), memberchk(M, [dockers, ls_signature, beyond_yoga])
    ->  true
    ;   a(A, [produto, grossista], true), a(A, [produto, vendidoNaLoja], false)
    ).
produtoModificado(A) :-
    a(A, [estado], E), E \== null,
    ( E.personalizado == true ; E.alterado == true ; E.embainhado == true ), !.
naoModificado(A) :- a(A, [estado], E), E \== null, \+ produtoModificado(A).
bodywear(A) :- a(A, [produto, categoria], bodywear).
naoBodywear(A) :- produtoDefinido(A), \+ bodywear(A).
naoUsado(A) :- a(A, [estado, condicaoUso], nao_usado).
usado(A) :- a(A, [estado, condicaoUso], usado).
lavado(A) :- a(A, [estado, condicaoUso], lavado).
etiquetasColocadas(A) :- a(A, [estado, etiquetas], colocadas).
etiquetasSoltas(A) :- a(A, [estado, etiquetas], soltas).
etiquetasAusentes(A) :- a(A, [estado, etiquetas], ausentes).
defeitoFabricoConfirmado(A) :- a(A, [estado, defeitoFabricoConfirmado], true).
semDefeito(A) :- a(A, [estado, defeitoFabricoConfirmado], false).
sujoOuInseguro(A) :- a(A, [estado, sujoOuInseguro], true).
artigoSujoOuInseguro(A) :- sujoOuInseguro(A).
embalagemIntacta(A) :- a(A, [estado, embalagemIntacta], true).
semEmbalagem(A) :- a(A, [estado, embalagemIntacta], false).
conjuntoCompleto(A) :- a(A, [estado, conjuntoCompleto], true).
conjuntoIncompletoOuUsado(A) :- ( a(A, [estado, conjuntoCompleto], false) -> true ; usado(A) ).
revendivel(A) :- a(A, [revendivel], true).
naoRevendivel(A) :- a(A, [revendivel], false).
revendivelPorAvaliar(A) :- a(A, [revendivel], null).
revendivelNaoNegado(A) :- \+ naoRevendivel(A).
entreCanais(A) :- a(A, [entreCanais], true).
emSaldo(A) :- a(A, [produto, emSaldo], true).
naoEmSaldo(A) :- a(A, [produto, emSaldo], false).
noSortidoDaLojaRecetora(A) :-
    lojaDefinida, a(A, [produto, sku], Sku), Sku \== null,
    p([loja, skusSortido], Sortido), memberchk(Sku, Sortido).
foraDoSortidoDaLojaRecetora(A) :- lojaDefinida, \+ noSortidoDaLojaRecetora(A).

% =============================================================================================
% Pagamento
% =============================================================================================

condicao_info(pagamentoAfterpay/0, entrada, "Pago com Afterpay").
condicao_info(naoAfterpay/0, entrada, "Não pago com Afterpay").
condicao_info(pagamentoCreditoOuDebito/0, entrada, "Pago a crédito ou débito").
condicao_info(pagamentoDebito/0, entrada, "Pago a débito").
condicao_info(pagamentoContactless/0, entrada, "Pago com Apple Pay ou Google Pay").
condicao_info(pagamentoComCartao/0, entrada, "Pago com cartão (crédito, débito ou contactless)").
condicao_info(pagamentoPaypalOuVenmo/0, entrada, "Pago com PayPal ou Venmo").
condicao_info(pagamentoInterac/0, entrada, "Pago com Interac").
condicao_info(pagamentoNumerarioOuCartaoOferta/0, entrada, "Pago em numerário ou cartão de oferta").
condicao_info(pagamentoSemProcessoProprio/0, entrada, "Meio sem processo próprio (não Afterpay, PayPal nem Venmo)").
condicao_info(acessoAplicacao/0, entrada, "O cliente acede à aplicação de pagamento").
condicao_info(semAcessoAplicacao/0, entrada, "O cliente não acede à aplicação de pagamento").
condicao_info(cartaoFisicoPresente/0, entrada, "Apresenta o mesmo cartão físico").
condicao_info(cartaoFisicoAusente/0, entrada, "Não apresenta o mesmo cartão físico").
condicao_info(contaAtivaCartaoPerdido/0, entrada, "Cartão perdido ou roubado com a conta ativa").
condicao_info(contaEncerrada/0, entrada, "Conta do cartão original encerrada").
condicao_info(reembolsoOriginalRecusado/0, entrada, "O reembolso ao meio original foi recusado").
condicao_info(reembolsoOriginalNaoRecusado/0, entrada, "O reembolso ao meio original não foi recusado").

meio(M) :- p([compraOriginal, pagamento, meio], M).
meio_em(Meios) :- meio(M), M \== null, memberchk(M, Meios).
sem_pagamento :- p([compraOriginal, pagamento], null).

pagamentoAfterpay :- meio(afterpay).
naoAfterpay :- ( sem_pagamento -> true ; \+ meio(afterpay) ).
pagamentoCreditoOuDebito :- meio_em([credito, debito]).
pagamentoDebito :- meio(debito).
pagamentoContactless :- meio_em([apple_pay, google_pay]).
pagamentoComCartao :- meio_em([credito, debito, apple_pay, google_pay]).
pagamentoPaypalOuVenmo :- meio_em([paypal, venmo]).
pagamentoInterac :- meio(interac).
pagamentoNumerarioOuCartaoOferta :- meio_em([numerario, cartao_oferta]).
pagamentoSemProcessoProprio :- ( sem_pagamento -> true ; \+ meio_em([afterpay, paypal, venmo]) ).
acessoAplicacao :- p([compraOriginal, pagamento, acessoAplicacaoPagamento], true).
semAcessoAplicacao :- p([compraOriginal, pagamento, acessoAplicacaoPagamento], false).
cartaoFisicoPresente :- p([compraOriginal, pagamento, cartaoFisicoPresente], true).
cartaoFisicoAusente :- p([compraOriginal, pagamento, cartaoFisicoPresente], false).
contaAtivaCartaoPerdido :- p([compraOriginal, pagamento, estadoConta], ativa_cartao_perdido).
contaEncerrada :- p([compraOriginal, pagamento, estadoConta], encerrada).
reembolsoOriginalRecusado :- p([compraOriginal, pagamento, reembolsoOriginalRecusado], true).
reembolsoOriginalNaoRecusado :- p([compraOriginal, pagamento, reembolsoOriginalRecusado], false).

% =============================================================================================
% Colaborador, cliente, fraude e exceção
% =============================================================================================

condicao_info(colaboradorAutorizado/0, entrada, "Colaborador autorizado (HS-006)").
condicao_info(colaboradorNaoAutorizado/0, entrada, "Colaborador não autorizado").
condicao_info(credencialPosPropria/0, entrada, "Credencial de POS própria").
condicao_info(processadorLeadCashierOuElevatedStylist/0, entrada, "Processador Lead Cashier ou Elevated Stylist").
condicao_info(clienteContesta/0, entrada, "O cliente contesta o resultado").
condicao_info(clienteAgitado/0, entrada, "O cliente está irritado ou causa perturbação").
condicao_info(clienteNaoForneceDadosOuBarreiraLinguistica/0, entrada, "O cliente não dá dados pessoais ou há barreira linguística").
condicao_info(indicioFraudeRelevante/0, entrada, "Indício de fraude significativo ou confirmado").
condicao_info(baixoRisco/0, entrada, "Sem indício de fraude significativo ou confirmado").
condicao_info(pedidoExcecao/0, entrada, "Há um pedido de exceção").
condicao_info(aprovacaoGestaoPendente/0, entrada, "Decisão da gestão pendente").
condicao_info(aprovadoPelaGestao/0, entrada, "Aprovado pela gestão").
condicao_info(recusadoPelaGestao/0, entrada, "Recusado pela gestão").
condicao_info(excecaoAprovada/0, entrada, "Exceção aprovada").
condicao_info(concluivelNoSistema/0, entrada, "O resultado pode ser concluído no sistema").
condicao_info(exigeControloObrigatorio/0, entrada, "A exceção exige meio proibido, SKU incorreto, produto excluído ou contornar um processo obrigatório").
condicao_info(pedidoDeExcecaoAoMeio/0, entrada, "Pede troca ou outro meio de reembolso").

colaboradorAutorizado :- colaborador_autorizado.
colaboradorNaoAutorizado :- \+ colaborador_autorizado.
credencialPosPropria :- p([colaborador, idCredencialPOS], C), C \== null.
processadorLeadCashierOuElevatedStylist :-
    p([colaborador, funcao], F), memberchk(F, [lead_cashier, elevated_stylist]).
clienteContesta :- p([cliente, contestaResultado], true).
clienteAgitado :- p([cliente, agitado], true).
clienteNaoForneceDadosOuBarreiraLinguistica :-
    p([cliente], C), C \== null,
    ( C.forneceDados == false ; C.barreiraLinguistica == true ), !.
indicioFraudeRelevante :- fraude(_, Nivel), memberchk(Nivel, [significativo, confirmado]), !.
baixoRisco :- \+ indicioFraudeRelevante.
pedidoExcecao :- p([pedidoExcecao], E), E \== null.
aprovacaoGestaoPendente :- p([pedidoExcecao, aprovada], null).
aprovadoPelaGestao :- p([pedidoExcecao, aprovada], true).
recusadoPelaGestao :- p([pedidoExcecao, aprovada], false).
excecaoAprovada :- aprovadoPelaGestao.
concluivelNoSistema :- p([pedidoExcecao, concluivelNoSistema], true).
exigeControloObrigatorio :-
    p([pedidoExcecao], E), E \== null,
    (   E.exigeMeioProibido == true ; E.exigeSkuIncorreto == true
    ;   E.envolveProdutoExcluido == true ; E.contornaProcessoObrigatorio == true
    ), !.
pedidoDeExcecaoAoMeio :-
    (   pedidoTroca
    ->  true
    ;   p([pedidoExcecao], E), E \== null,
        ( E.exigeMeioProibido == true ; E.contornaProcessoObrigatorio == true ), !
    ).

% =============================================================================================
% Estado das decisões (conclusões de outras regras)
% =============================================================================================

condicao_info(pedidoNaoSuspenso/0, estado, "Transação não suspensa").
condicao_info(verificacaoNaoDeterminada/0, estado, "Tipo de verificação ainda por determinar").
condicao_info(devolucaoVerificada/0, estado, "Devolução verificada (PT-001 ou CH-002)").
condicao_info(devolucaoAsCegas/0, estado, "Devolução às cegas (PT-002 ou CH-003)").
condicao_info(artigoElegivel/0, estado, "Há pelo menos um artigo elegível").
condicao_info(artigoRevendivel/0, estado, "Todos os artigos elegíveis são revendíveis").
condicao_info(artigoNaoRevendivel/0, estado, "Há um artigo elegível não revendível").
condicao_info(artigoRevendivelPorAvaliar/0, estado, "Há um artigo elegível com a revenda por avaliar (IN-010)").
condicao_info(artigoNaoRecusado/0, estado, "Há um artigo não recusado").
condicao_info(artigosNaoRecusadosRevendiveis/0, estado, "Todos os artigos não recusados são revendíveis").
condicao_info(artigoNaoRecusadoNaoRevendivel/0, estado, "Há um artigo não recusado que não é revendível").
condicao_info(encaminhadaBackPocket/0, estado, "Encaminhada para a BackPocket (CH-002)").
condicao_info(reembolsoAfterpayOnline/0, estado, "Reembolso Afterpay online na BackPocket (TN-010)").
condicao_info(devolucaoAsCegasOnlinePermitida/0, estado, "Devolução online às cegas permitida (CH-003)").
condicao_info(tokenizacaoAplicada/0, estado, "Reembolso tokenizado (TN-001)").
condicao_info(interacVerificado/0, estado, "Cartão Interac verificado (TN-011)").
condicao_info(assinaturasObtidas/0, estado, "Assinaturas obtidas (CT-005)").
condicao_info(escaladoResponsavelSenior/0, estado, "Escalado para o responsável sénior (EX-003)").
condicao_info(politicaExplicada/0, estado, "Política explicada ao cliente (EX-002)").
condicao_info(excecaoEmAvaliacao/0, estado, "Exceção em avaliação (EX-001 ou EX-004)").
condicao_info(excecaoNaoRecusada/0, estado, "A exceção não foi recusada").
condicao_info(semParagemHs/0, estado, "Nenhuma regra HS disparou").
condicao_info(paragemOuNaoVerificadaOuRiscoOuNaoConcluivel/0, estado, "Há uma paragem HS, a compra não é verificada, o risco não é baixo ou não é concluível").
condicao_info(resultadoRever/0, estado, "Um resultado é REVER").
condicao_info(resultadoEmitido/0, estado, "Já foi emitido um resultado").
condicao_info(trocaPermitida/0, estado, "Troca permitida").
condicao_info(transacaoReembolso/0, estado, "Transação de reembolso").
condicao_info(transacaoReembolsoOuAjuste/0, estado, "Transação de reembolso ou ajuste de preço").
condicao_info(elegibilidadeNaoRecusada/0, estado, "O pedido não foi recusado").
condicao_info(meioReembolsoOriginal/0, estado, "Reembolso no meio de pagamento original").
condicao_info(meioReembolsoCartaoOferta/0, estado, "Reembolso em cartão de oferta").
condicao_info(reembolsoNoMeioOriginalOuEmRevisao/0, estado, "Reembolso no meio original ou em revisão (CH-004)").
condicao_info(transacaoAProcessar/0, estado, "Transação a processar (não recusada e com tipo definido)").
condicao_info(baseValorDefinida/0, estado, "Base do valor definida").
condicao_info(valoresDosArtigos/0, estado, "Há artigos elegíveis com valor").
condicao_info(valorDevolucaoDefinido/0, estado, "Valor da devolução calculado").
condicao_info(valorDevolucaoMaiorQueTroca/0, estado, "O valor devolvido é maior do que o preço da troca").
condicao_info(artigoAceite/1, estado, "Artigo aceite ou em revisão").
condicao_info(bodywearAceite/1, estado, "Bodywear aceite (PC-007)").
condicao_info(inspecionado/1, estado, "Artigo inspecionado (CT-008)").
condicao_info(semDestino/1, estado, "Destino ainda por definir").
condicao_info(semDestinoOuIsolado/1, estado, "Destino por definir ou já isolado por risco biológico").
condicao_info(naoIsolado/1, estado, "Ainda não isolado por risco biológico").
condicao_info(semBaseEspecifica/1, estado, "Sem base de valor própria do artigo").
condicao_info(artigoOuPedidoRecusado/1, estado, "Artigo ou pedido recusado").

%!  eleg_aceite(?Elegibilidade) is nondet.
%
%   Elegibilidades de um artigo elegível (G3): PERMITIR ou em revisão.
eleg_aceite(permitir).
eleg_aceite(rever).

artigo_elegivel(A) :-
    artigo(A),
    decisao(artigo(A), terminal, false),
    decisao(artigo(A), elegibilidade, E), eleg_aceite(E).

artigo_nao_recusado(A) :-
    artigo(A),
    decisao(artigo(A), terminal, false),
    decisao(artigo(A), elegibilidade, E), E \== recusar.

pedidoNaoSuspenso :- suspenso(false).
verificacaoNaoDeterminada :- decisao(pedido, tipoVerificacao, nao_determinada).
devolucaoVerificada :- decisao(pedido, tipoVerificacao, verificada).
devolucaoAsCegas :- decisao(pedido, tipoVerificacao, as_cegas).
artigoElegivel :- artigo_elegivel(_), !.
artigoRevendivel :- \+ ( artigo_elegivel(A), \+ revendivel(A) ).
artigoNaoRevendivel :- artigo_elegivel(A), naoRevendivel(A), !.
artigoRevendivelPorAvaliar :- artigo_elegivel(A), revendivelPorAvaliar(A), !.
artigoNaoRecusado :- artigo_nao_recusado(_), !.
artigosNaoRecusadosRevendiveis :- \+ ( artigo_nao_recusado(A), \+ revendivel(A) ).
artigoNaoRecusadoNaoRevendivel :- artigo_nao_recusado(A), naoRevendivel(A), !.
encaminhadaBackPocket :- disparou(pedido, 'CH-002').
reembolsoAfterpayOnline :- disparou(pedido, 'TN-010').
devolucaoAsCegasOnlinePermitida :- disparou(pedido, 'CH-003').
tokenizacaoAplicada :- disparou(pedido, 'TN-001').
interacVerificado :- disparou(pedido, 'TN-011').
assinaturasObtidas :- disparou(pedido, 'CT-005').
escaladoResponsavelSenior :- disparou(pedido, 'EX-003').
politicaExplicada :- disparou(pedido, 'EX-002').
excecaoEmAvaliacao :- ( disparou(pedido, 'EX-001') -> true ; disparou(pedido, 'EX-004') ).
excecaoNaoRecusada :- decisao(pedido, excecaoRecusada, false).
semParagemHs :- \+ paragem_hs.
paragemOuNaoVerificadaOuRiscoOuNaoConcluivel :-
    \+ ( semParagemHs, devolucaoVerificada, baixoRisco, concluivelNoSistema ).
paragem_hs :-
    registo(_, _, Codigo, _, _, _, _),
    sub_atom(Codigo, 0, _, _, 'HS-'), !.
resultadoRever :-
    (   decisao(pedido, elegibilidade, rever)
    ->  true
    ;   artigo(A), decisao(artigo(A), terminal, false), decisao(artigo(A), elegibilidade, rever), !
    ).
resultadoEmitido :-
    (   decisao(pedido, elegibilidade, E), E \== null
    ->  true
    ;   artigo(A), decisao(artigo(A), elegibilidade, EA), EA \== null, !
    ).
trocaPermitida :- decisao(pedido, tipoTransacao, troca).
transacaoReembolso :- decisao(pedido, tipoTransacao, reembolso).
transacaoReembolsoOuAjuste :- decisao(pedido, tipoTransacao, T), memberchk(T, [reembolso, ajuste_preco]).
elegibilidadeNaoRecusada :- \+ decisao(pedido, elegibilidade, recusar).
meioReembolsoOriginal :- decisao(pedido, meioReembolso, meio_original).
meioReembolsoCartaoOferta :- decisao(pedido, meioReembolso, cartao_oferta).
reembolsoNoMeioOriginalOuEmRevisao :- ( meioReembolsoOriginal -> true ; disparou(pedido, 'CH-004') ).
transacaoAProcessar :-
    decisao(pedido, elegibilidade, E), E \== null, E \== recusar,
    decisao(pedido, tipoTransacao, T), T \== null, T \== nenhuma.
baseValorDefinida :- decisao(pedido, baseValor, B), B \== null.
valoresDosArtigos :- artigo_elegivel(A), decisao(artigo(A), valorDevolucao, V), V \== null, !.
valorDevolucaoDefinido :- decisao(pedido, valorDevolucao, V), V \== null.
valorDevolucaoMaiorQueTroca :-
    decisao(pedido, valorDevolucao, V), V \== null,
    preco_artigos_troca(Preco),
    V > Preco.
artigoAceite(A) :- decisao(artigo(A), elegibilidade, E), eleg_aceite(E).
bodywearAceite(A) :- disparou(artigo(A), 'PC-007').
inspecionado(A) :- disparou(artigo(A), 'CT-008').
semDestino(A) :- decisao(artigo(A), destino, null).
semDestinoOuIsolado(A) :- decisao(artigo(A), destino, D), memberchk(D, [null, risco_biologico]).
naoIsolado(A) :- \+ decisao(artigo(A), destino, risco_biologico).
semBaseEspecifica(A) :- decisao(artigo(A), baseValor, null).
artigoOuPedidoRecusado(A) :-
    ( decisao(artigo(A), elegibilidade, recusar) -> true ; decisao(pedido, elegibilidade, recusar) ).

preco_artigos_troca(Total) :-
    p([artigosTroca], Trocas),
    findall(Preco, ( member(T, Trocas), get_dict(precoVenda, T, Preco), Preco \== null ), Precos),
    sum_list(Precos, Total).

% =============================================================================================
% Dados de entrada ("Porquê": que pergunta lê cada condição; DadoEntrada e DependenciasDados)
% =============================================================================================

%   dado_entrada(Codigo, Nome, Caminho, Pergunta)
dado_entrada('IN-001', mercado, "loja.mercado", "Em que mercado fica a loja (Estados Unidos ou Canadá)?").
dado_entrada('IN-002', tipo_loja, "loja.tipoLoja", "A loja é Mainline ou Outlet?").
dado_entrada('IN-003', canal, "compraOriginal.canal", "Onde e em que condições foi feita a compra (canal, Stylist, promoção por escalões, ajuste anterior)?").
dado_entrada('IN-004', comprovativo, "comprovativo", "Que comprovativo de compra apresenta o cliente e o que confirma?").
dado_entrada('IN-005', pedido, "tipoPedido", "O que pede o cliente e, numa troca, o que leva?").
dado_entrada('IN-006', momento, "compraOriginal.dataCompra", "Quando foi feita a compra ou o envio da encomenda?").
dado_entrada('IN-007', produto, "artigos[].produto", "Que produto é devolvido (SKU, marca, categoria, sortido, saldo)?").
dado_entrada('IN-008', estado, "artigos[].estado", "Em que estado está o artigo (uso, etiquetas, alterações, defeito, embalagem, segurança)?").
dado_entrada('IN-009', pagamento, "compraOriginal.pagamento", "Como foi paga a compra e em que estado está esse meio?").
dado_entrada('IN-010', revenda, "artigos[].revendivel", "O artigo pode ser verificado, reetiquetado e revendido?").
dado_entrada('HS-006', colaborador, "colaborador", "Quem processa a transação e com que credencial de POS?").
dado_entrada('EX-002', cliente, "cliente", "O cliente fornece dados, contesta o resultado ou está agitado?").
dado_entrada('EX-001', excecao, "pedidoExcecao", "O cliente pede uma exceção e qual foi a decisão da gestão?").
dado_entrada('EX-008', fraude, "indicadoresFraude", "Há indícios de fraude ou inconsistências relevantes?").
dado_entrada('CH-002', online, "compraOriginal.encomendaEncontrada", "A encomenda online foi encontrada, o portal está disponível e a política permite a devolução às cegas?").

le_dado(C, 'IN-003') :- memberchk(C, [canalGrossista, canalFranquiaCanada, canalLoja, canalDesconhecido,
    compraMainlineOuOutlet, compraForaDaLoja, compraBackPocket, compraOnline, compraNaoOnline,
    origemMainlineOuOnline, entreCanais, promocaoEscaloes, stylistDaVendaConhecido,
    semAjusteAnterior, ajusteAnterior]).
le_dado(C, 'IN-002') :- memberchk(C, [lojaOutlet, lojaDefinida, canalLoja]).
le_dado(C, 'IN-001') :- memberchk(C, [mercadoCanada, lojaDefinida]).
le_dado(C, 'IN-004') :- memberchk(C, [comprovativoValido, comprovativoConfirmaCompra, semComprovativoValido,
    reciboOriginal, reciboOriginalImpresso, mais14DiasOuSemReciboOriginal]).
le_dado(C, 'CH-002') :- memberchk(C, [encomendaEncontrada, encomendaNaoEncontrada, portalDisponivel,
    portalIndisponivel, politicaPermiteAsCegasOnline, politicaNaoPermiteAsCegasOnline,
    devolucaoAsCegasOnlinePermitida]).
le_dado(C, 'IN-005') :- memberchk(C, [ajustePreco, naoEAjustePreco, devolucaoOferta, naoEOferta,
    pedidoTroca, apenasMudaTamanho, mudaModeloOuCor, pedidoDeExcecaoAoMeio]).
le_dado(C, 'IN-006') :- memberchk(C, [ate30DiasDesdeCompra, mais30DiasDesdeCompra, ate14DiasDesdeCompra,
    ate30DiasDesdeEnvio, mais30DiasDesdeEnvio, mais14DiasOuSemReciboOriginal, dataPedidoDefinida]).
le_dado(C, 'IN-007') :- memberchk(C, [produtoDefinido, skuReconhecido, skuNaoReconhecido, produtoFranquia,
    produtoNaoFranquia, marcaExcluidaOuGrossistaNaoVendido, bodywear, naoBodywear, emSaldo, naoEmSaldo,
    noSortidoDaLojaRecetora, foraDoSortidoDaLojaRecetora, bodywearAceite]).
le_dado(C, 'IN-008') :- memberchk(C, [produtoModificado, naoModificado, naoUsado, usado, lavado,
    etiquetasColocadas, etiquetasSoltas, etiquetasAusentes, defeitoFabricoConfirmado, semDefeito,
    sujoOuInseguro, artigoSujoOuInseguro, embalagemIntacta, semEmbalagem, conjuntoCompleto,
    conjuntoIncompletoOuUsado]).
le_dado(C, 'IN-010') :- memberchk(C, [revendivel, naoRevendivel, revendivelPorAvaliar, revendivelNaoNegado,
    artigoRevendivel, artigoNaoRevendivel, artigoRevendivelPorAvaliar, artigosNaoRecusadosRevendiveis,
    artigoNaoRecusadoNaoRevendivel]).
le_dado(C, 'IN-009') :- memberchk(C, [pagamentoAfterpay, naoAfterpay, pagamentoCreditoOuDebito,
    pagamentoDebito, pagamentoContactless, pagamentoComCartao, pagamentoPaypalOuVenmo, pagamentoInterac,
    pagamentoNumerarioOuCartaoOferta, pagamentoSemProcessoProprio, acessoAplicacao, semAcessoAplicacao,
    cartaoFisicoPresente, cartaoFisicoAusente, contaAtivaCartaoPerdido, contaEncerrada,
    reembolsoOriginalRecusado, reembolsoOriginalNaoRecusado]).
le_dado(C, 'HS-006') :- memberchk(C, [colaboradorAutorizado, colaboradorNaoAutorizado,
    credencialPosPropria, processadorLeadCashierOuElevatedStylist]).
le_dado(C, 'EX-002') :- memberchk(C, [clienteContesta, clienteAgitado, clienteNaoForneceDadosOuBarreiraLinguistica]).
le_dado(C, 'EX-008') :- memberchk(C, [indicioFraudeRelevante, baixoRisco, pedidoNaoSuspenso]).
le_dado(C, 'EX-001') :- memberchk(C, [pedidoExcecao, aprovacaoGestaoPendente, aprovadoPelaGestao,
    recusadoPelaGestao, excecaoAprovada, concluivelNoSistema, exigeControloObrigatorio,
    pedidoDeExcecaoAoMeio]).

% =============================================================================================
% Valores mostrados nas explicações
% =============================================================================================

%!  valor_condicao(+Condicao, -Texto) is det.
%
%   Os valores de entrada que a condição lê, para mostrar no "Como" e no "Porque não".
valor_condicao(Condicao, Texto) :-
    functor(Condicao, Nome, _),
    (   mostra(Nome, Fontes)
    ->  ( Condicao =.. [_, A|_] -> true ; A = _ ),
        findall(T, ( member(F, Fontes), texto_fonte(F, A, T) ), Partes),
        atomic_list_concat(Partes, ', ', Atomo),
        atom_string(Atomo, Texto)
    ;   Texto = null
    ).

texto_fonte(p(Caminho), _, T) :- !, p(Caminho, V), rotulo(Caminho, R), texto_valor(V, TV), format(string(T), "~w = ~w", [R, TV]).
texto_fonte(a(Caminho), A, T) :- !, a(A, Caminho, V), rotulo(Caminho, R), texto_valor(V, TV), format(string(T), "~w = ~w", [R, TV]).
texto_fonte(dias_compra, _, T) :- !, dias_desde_compra(D), format(string(T), "dias desde a compra = ~w", [D]).
texto_fonte(dias_envio, _, T) :- !, dias_desde_envio(D), format(string(T), "dias desde o envio = ~w", [D]).
texto_fonte(fraudes, _, T) :- !,
    findall(N, fraude(_, N), Ns), maplist(texto_valor, Ns, TNs),
    atomic_list_concat(TNs, '/', Niveis),
    format(string(T), "indícios = [~w]", [Niveis]).

rotulo(Caminho, R) :- last(Caminho, R).

texto_valor(V, T) :- valor_json(V, J), ( J == null -> T = null ; T = J ).

mostra(N, [p([compraOriginal, canal])]) :- memberchk(N, [canalGrossista, canalFranquiaCanada, canalDesconhecido,
    compraMainlineOuOutlet, compraForaDaLoja, compraBackPocket, compraOnline, compraNaoOnline, origemMainlineOuOnline]).
mostra(canalLoja, [p([compraOriginal, canal]), p([loja, tipoLoja])]).
mostra(N, [p([loja, tipoLoja])]) :- memberchk(N, [lojaOutlet, lojaDefinida]).
mostra(mercadoCanada, [p([loja, mercado])]).
mostra(N, [p([comprovativo, tipo]), p([comprovativo, confirmaCompra])]) :-
    memberchk(N, [comprovativoValido, comprovativoConfirmaCompra, semComprovativoValido]).
mostra(N, [p([comprovativo, tipo]), p([comprovativo, reciboOriginal])]) :- memberchk(N, [reciboOriginal, reciboOriginalImpresso]).
mostra(N, [p([compraOriginal, encomendaEncontrada])]) :- memberchk(N, [encomendaEncontrada, encomendaNaoEncontrada]).
mostra(N, [p([portalOnlineDisponivel])]) :- memberchk(N, [portalDisponivel, portalIndisponivel]).
mostra(N, [p([politicaPermiteAsCegasOnline])]) :- memberchk(N, [politicaPermiteAsCegasOnline, politicaNaoPermiteAsCegasOnline]).
mostra(promocaoEscaloes, [p([compraOriginal, promocaoEscaloes])]).
mostra(stylistDaVendaConhecido, [p([compraOriginal, idStylistVenda])]).
mostra(N, [p([tipoPedido])]) :- memberchk(N, [ajustePreco, naoEAjustePreco, devolucaoOferta, naoEOferta, pedidoTroca]).
mostra(N, [dias_compra]) :- memberchk(N, [ate30DiasDesdeCompra, mais30DiasDesdeCompra, ate14DiasDesdeCompra]).
mostra(mais14DiasOuSemReciboOriginal, [dias_compra, p([comprovativo, reciboOriginal])]).
mostra(N, [dias_envio]) :- memberchk(N, [ate30DiasDesdeEnvio, mais30DiasDesdeEnvio]).
mostra(N, [p([compraOriginal, ajustePrecoAplicado])]) :- memberchk(N, [semAjusteAnterior, ajusteAnterior]).
mostra(N, [a([produto, sku]), a([produto, skuReconhecidoPOS])]) :- memberchk(N, [skuReconhecido, skuNaoReconhecido]).
mostra(N, [a([produto, produtoFranquia])]) :- memberchk(N, [produtoFranquia, produtoNaoFranquia]).
mostra(marcaExcluidaOuGrossistaNaoVendido, [a([produto, marca]), a([produto, grossista]), a([produto, vendidoNaLoja])]).
mostra(N, [a([estado, personalizado]), a([estado, alterado]), a([estado, embainhado])]) :- memberchk(N, [produtoModificado, naoModificado]).
mostra(N, [a([produto, categoria])]) :- memberchk(N, [bodywear, naoBodywear]).
mostra(N, [a([estado, condicaoUso])]) :- memberchk(N, [naoUsado, usado, lavado]).
mostra(N, [a([estado, etiquetas])]) :- memberchk(N, [etiquetasColocadas, etiquetasSoltas, etiquetasAusentes]).
mostra(N, [a([estado, defeitoFabricoConfirmado])]) :- memberchk(N, [defeitoFabricoConfirmado, semDefeito]).
mostra(N, [a([estado, sujoOuInseguro])]) :- memberchk(N, [sujoOuInseguro, artigoSujoOuInseguro]).
mostra(N, [a([estado, embalagemIntacta])]) :- memberchk(N, [embalagemIntacta, semEmbalagem]).
mostra(conjuntoCompleto, [a([estado, conjuntoCompleto])]).
mostra(conjuntoIncompletoOuUsado, [a([estado, conjuntoCompleto]), a([estado, condicaoUso])]).
mostra(N, [a([revendivel])]) :- memberchk(N, [revendivel, naoRevendivel, revendivelPorAvaliar, revendivelNaoNegado]).
mostra(entreCanais, [a([entreCanais])]).
mostra(N, [a([produto, emSaldo])]) :- memberchk(N, [emSaldo, naoEmSaldo]).
mostra(N, [a([produto, sku])]) :- memberchk(N, [noSortidoDaLojaRecetora, foraDoSortidoDaLojaRecetora]).
mostra(N, [p([compraOriginal, pagamento, meio])]) :- memberchk(N, [pagamentoAfterpay, naoAfterpay,
    pagamentoCreditoOuDebito, pagamentoDebito, pagamentoContactless, pagamentoComCartao, pagamentoPaypalOuVenmo,
    pagamentoInterac, pagamentoNumerarioOuCartaoOferta, pagamentoSemProcessoProprio]).
mostra(N, [p([compraOriginal, pagamento, acessoAplicacaoPagamento])]) :- memberchk(N, [acessoAplicacao, semAcessoAplicacao]).
mostra(N, [p([compraOriginal, pagamento, cartaoFisicoPresente])]) :- memberchk(N, [cartaoFisicoPresente, cartaoFisicoAusente]).
mostra(N, [p([compraOriginal, pagamento, estadoConta])]) :- memberchk(N, [contaAtivaCartaoPerdido, contaEncerrada]).
mostra(N, [p([compraOriginal, pagamento, reembolsoOriginalRecusado])]) :- memberchk(N, [reembolsoOriginalRecusado, reembolsoOriginalNaoRecusado]).
mostra(N, [p([colaborador, funcao]), p([colaborador, aprovadoPeloDM])]) :- memberchk(N, [colaboradorAutorizado, colaboradorNaoAutorizado, processadorLeadCashierOuElevatedStylist]).
mostra(credencialPosPropria, [p([colaborador, idCredencialPOS])]).
mostra(clienteContesta, [p([cliente, contestaResultado])]).
mostra(clienteAgitado, [p([cliente, agitado])]).
mostra(clienteNaoForneceDadosOuBarreiraLinguistica, [p([cliente, forneceDados]), p([cliente, barreiraLinguistica])]).
mostra(N, [fraudes]) :- memberchk(N, [indicioFraudeRelevante, baixoRisco]).
mostra(N, [p([pedidoExcecao, aprovada])]) :- memberchk(N, [aprovacaoGestaoPendente, aprovadoPelaGestao, recusadoPelaGestao, excecaoAprovada]).
mostra(concluivelNoSistema, [p([pedidoExcecao, concluivelNoSistema])]).
mostra(exigeControloObrigatorio, [p([pedidoExcecao, exigeMeioProibido]), p([pedidoExcecao, exigeSkuIncorreto]),
    p([pedidoExcecao, envolveProdutoExcluido]), p([pedidoExcecao, contornaProcessoObrigatorio])]).
mostra(pedidoDeExcecaoAoMeio, [p([tipoPedido]), p([pedidoExcecao, exigeMeioProibido]), p([pedidoExcecao, contornaProcessoObrigatorio])]).
