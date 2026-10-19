:- encoding(utf8).
:- module(regras, []).

/** <module> Base de conhecimento: regras de devoluções e trocas Levi's (EUA e Canadá)

Tradução para Prolog das 98 regras DRL do projeto `drools-engine-levis-devolucoes-java`, que
implementam as 71 regras do Relatório Prévio de Aquisição de Conhecimento (IDs HS, PC, PT, CH, TN,
EP, EX, CT, BW) e as regras de suporte (IN-003, OUT-001, OUT-003, OUT-004, OUT-007).

Formato de cada regra (linguagem do sp_exp2.pl, com os metadados em `com`):

==
regra Nome
    se [ Condicao1 e Condicao2 e ... e nao CondicaoN ]
    entao [ Acao1, Acao2, ... ]
    com [ modulo(M), prioridade(P), conclusoes([...]), descricao("...") ].
==

  - O Nome é o do DRL e começa pelo ID da regra (o ID pode repetir-se: variantes da mesma regra).
  - As condições são predicados do módulo `condicoes`. As regras por artigo começam por
    `artigo(A)`, que percorre os artigos do pedido.
  - As guardas `pedidoAtivo`/`artigoAtivo(A)` (fluxo não terminado) e `naoDisparou(Alvo, ID)`
    correspondem a `Decisao( terminal == false )` e `disparou( "ID" ) == false` do DRL.
  - As ações alteram a decisão do pedido (`pedido`) ou de um artigo (`artigo(A)`):
      - aplicar(Alvo, Resultado, Mensagem): regista e aplica um resultado (nunca baixa a severidade;
        as paragens obrigatórias terminam o fluxo, ADR 0004);
      - registar(Alvo, Mensagem): regista uma ação sem resultado;
      - definir(Alvo, Campo, Valor): define um campo de saída (OUT-002 a OUT-008);
      - suspender(Mensagem), recusar_excecao(Mensagem), marcar_suspenso, agregar_artigos;
      - calcular(Objetivo): calcula valores usados nas ações seguintes (como o código Java do RHS).
  - Os metadados: modulo (agenda-group), prioridade (salience), auto_foco, conclusoes (as
    conclusões OUT que a regra pode produzir, `@conclusoes` do DRL) e descricao (`[a validar: A-xx]`
    marca o comportamento provisório do ADR 0003).
*/

:- use_module('../motor/operadores').
:- use_module('../motor/memoria').
:- use_module(pedido).
:- use_module(condicoes, []).

:- discontiguous (regra)/1.

% =============================================================================================
% TRANSVERSAL — interrupções que podem ocorrer em qualquer modulo (auto-focus)
% =============================================================================================

regra 'EX-008 Indícios de fraude ou inconsistências relevantes'
    se [ indicioFraudeRelevante e pedidoNaoSuspenso ]
    entao [ calcular(descricao_indicio_relevante(Descricao)),
            marcar_suspenso,
            suspender(["Transação suspensa por indícios de fraude: ", Descricao,
                       ". Envolver a Gestão da Loja e comunicar ao District ou Area Manager e à Global Safety and Security."]) ]
    com [ modulo(transversal), prioridade(1000), auto_foco,
          conclusoes(['OUT-001'=rever, 'OUT-005'=district_area]),
          descricao("Suspender a transação, envolver a Gestão da Loja e comunicar o risco significativo ou confirmado ao District ou Area Manager e à Global Safety and Security. Só um indício significativo ou confirmado suspende [a validar: A-26].") ].

regra 'PC-008 Artigo sujo, contaminado ou inseguro de manusear'
    se [ artigo(A) e artigoSujoOuInseguro(A) e naoIsolado(A) ]
    entao [ definir(artigo(A), destino, risco_biologico),
            registar(artigo(A), "Artigo inseguro: minimizar o manuseamento, saco de risco biológico etiquetado e datado, sala de reservas, e-mail ao escritório corporativo; não revender e aguardar instruções de eliminação.") ]
    com [ modulo(transversal), prioridade(900), auto_foco,
          conclusoes(['OUT-007'=risco_biologico]),
          descricao("Minimizar o manuseamento; colocar num saco de risco biológico, etiquetado e datado; guardar na sala de reservas; enviar e-mail ao escritório corporativo; não revender e aguardar instruções de eliminação. Não altera a elegibilidade [a validar: A-15, A-28].") ].

% =============================================================================================
% M0 — Autorização
% =============================================================================================

regra 'HS-006 Colaborador não autorizado a processar devoluções ou trocas'
    se [ pedidoAtivo e colaboradorNaoAutorizado ]
    entao [ aplicar(pedido, encaminhar, "Colaborador sem autorização para devoluções ou trocas: encaminhar para a Gestão da Loja, um Key Holder, ou um Lead Cashier ou Elevated Stylist aprovado pelo District Manager.") ]
    com [ modulo(m0), prioridade(100),
          conclusoes(['OUT-001'=encaminhar]),
          descricao("Encaminhar para a Gestão da Loja, um Key Holder, ou um Lead Cashier ou Elevated Stylist aprovado pelo District Manager. O XStore Manager é considerado autorizado [a validar: A-23].") ].

regra 'CT-003 Mesmo colaborador do início ao fim com credenciais próprias'
    se [ pedidoAtivo e naoDisparou(pedido, 'CT-003') e colaboradorAutorizado e credencialPosPropria ]
    entao [ calcular(p([colaborador, id], Id)),
            calcular(p([colaborador, idCredencialPOS], Credencial)),
            registar(pedido, ["O colaborador ", Id, " conclui a transação do início ao fim com a sua credencial de POS (",
                              Credencial, "), sem a partilhar."]) ]
    com [ modulo(m0), prioridade(90), conclusoes([]),
          descricao("O colaborador que inicia sessão no POS conclui a transação do início ao fim; as credenciais não podem ser partilhadas.") ].

% =============================================================================================
% M2 — Canal de compra (IN-001 a IN-009 sao dados de entrada: M1 não tem regras)
% =============================================================================================

regra 'CH-008 Produto grossista'
    se [ pedidoAtivo e canalGrossista ]
    entao [ definir(pedido, tipoTransacao, nenhuma),
            aplicar(pedido, recusar, "Produto comprado num retalhista grossista: as lojas Levi's não aceitam a devolução. Encaminhar o cliente para o retalhista original.") ]
    com [ modulo(m2), prioridade(100),
          conclusoes(['OUT-001'=recusar, 'OUT-002'=nenhuma]),
          descricao("Recusar e encaminhar o cliente para o retalhista grossista original: as lojas Levi's não aceitam devoluções de produtos grossistas.") ].

regra 'CH-007 Produto da franquia do Canadá'
    se [ pedidoAtivo e canalFranquiaCanada ]
    entao [ definir(pedido, processo, franquia_canada),
            definir(pedido, tipoTransacao, nenhuma),
            aplicar(pedido, encaminhar, "Produto da franquia do Canadá: seguir o processo de devolução da franquia, com o SKU da franquia; não substituir por um SKU genérico.") ]
    com [ modulo(m2), prioridade(100),
          conclusoes(['OUT-001'=encaminhar, 'OUT-002'=nenhuma, 'OUT-006'=franquia_canada]),
          descricao("Encaminhar para o processo específico de devolução da franquia do Canadá, com o SKU da franquia e nunca um SKU genérico. Aplica-se em qualquer mercado [a validar: A-07].") ].

regra 'CH-001 Compra Mainline ou Outlet devolvida numa loja Levi\'s'
    se [ pedidoAtivo e naoDisparou(pedido, 'CH-001') e canalLoja ]
    entao [ calcular(p([compraOriginal, canal], Canal)),
            calcular(p([loja, tipoLoja], TipoLoja)),
            registar(pedido, ["Compra ", Canal, " devolvida na loja ", TipoLoja,
                              ": aplicam-se as regras de comprovativo (verificada ou às cegas) e de avaliação da loja recetora."]) ]
    com [ modulo(m2), prioridade(50), conclusoes([]),
          descricao("Aplicar as regras de devolução verificada ou às cegas e as regras de avaliação da loja recetora: as devoluções entre canais são permitidas quando o produto é elegível.") ].

regra 'IN-003 Canal de compra desconhecido'
    se [ pedidoAtivo e naoDisparou(pedido, 'IN-003') e canalDesconhecido ]
    entao [ registar(pedido, "Canal de compra desconhecido: prosseguir para a verificação do produto; o comprovativo decide se a devolução é verificada ou às cegas.") ]
    com [ modulo(m2), prioridade(50), conclusoes([]),
          descricao("Canal desconhecido: segue para a elegibilidade do produto (M3) e o comprovativo decide em M4 (docs/03) [a validar: A-01].") ].

% =============================================================================================
% M3 — Elegibilidade do produto (por artigo). Paragens obrigatórias (HS) e estado (PC).
% Precedências: PC-007 > PC-006 > PC-001..PC-005; HS-003 > PC-006.
% =============================================================================================

regra 'HS-001 Produto não reconhecido no POS'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e skuNaoReconhecido(A) e produtoNaoFranquia(A) ]
    entao [ calcular(a(A, [produto, sku], Sku)),
            definir(artigo(A), tipoTransacao, nenhuma),
            aplicar(artigo(A), recusar, ["SKU ", Sku, " não reconhecido no POS: recusar a devolução e a troca. Não usar um SKU diferente ou genérico (HS-004)."]) ]
    com [ modulo(m3), prioridade(100),
          conclusoes(['OUT-001'=recusar, 'OUT-002'=nenhuma]),
          descricao("Recusar a devolução e a troca: é necessário um SKU de produto válido. Não usar um SKU diferente ou genérico.") ].

regra 'HS-004 SKU da franquia do Canadá não reconhecido'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e skuNaoReconhecido(A) e produtoFranquia(A) ]
    entao [ definir(artigo(A), tipoTransacao, nenhuma),
            aplicar(artigo(A), encaminhar, "Produto da franquia do Canadá sem SKU reconhecido: não usar um SKU diferente ou genérico; seguir o processo de devolução da franquia com o SKU da franquia (CH-007)."),
            definir(pedido, processo, franquia_canada) ]
    com [ modulo(m3), prioridade(100),
          conclusoes(['OUT-001'=encaminhar, 'OUT-002'=nenhuma, 'OUT-006'=franquia_canada]),
          descricao("Não usar um SKU diferente ou genérico; o produto da franquia do Canadá segue o processo da franquia (CH-007).") ].

regra 'CH-007 Produto da franquia do Canadá apresentado na loja'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e skuReconhecido(A) e produtoFranquia(A) ]
    entao [ definir(artigo(A), tipoTransacao, nenhuma),
            aplicar(artigo(A), encaminhar, "Produto da franquia do Canadá: seguir o processo de devolução da franquia, com o SKU da franquia."),
            definir(pedido, processo, franquia_canada) ]
    com [ modulo(m3), prioridade(100),
          conclusoes(['OUT-001'=encaminhar, 'OUT-002'=nenhuma, 'OUT-006'=franquia_canada]),
          descricao("Produto da franquia do Canadá com SKU reconhecido: encaminhar para o processo da franquia, com o SKU da franquia [a validar: A-07].") ].

regra 'HS-002 Marca ou produto grossista não aceite na loja'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e skuReconhecido(A) e marcaExcluidaOuGrossistaNaoVendido(A) ]
    entao [ calcular(a(A, [produto, marca], Marca)),
            calcular(( a(A, [produto, grossista], true) -> Extra = ", grossista não vendido na loja" ; Extra = "" )),
            definir(artigo(A), tipoTransacao, nenhuma),
            aplicar(artigo(A), recusar, ["As lojas de retalho Levi's não aceitam este produto (", Marca, Extra,
                                         "): recusar a devolução e a troca."]) ]
    com [ modulo(m3), prioridade(90),
          conclusoes(['OUT-001'=recusar, 'OUT-002'=nenhuma]),
          descricao("Recusar a devolução e a troca de Dockers, Levi Strauss Signature, Beyond Yoga ou produto grossista não vendido na loja.") ].

regra 'HS-003 Produto personalizado, alterado ou embainhado'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e produtoModificado(A) ]
    entao [ definir(artigo(A), tipoTransacao, nenhuma),
            aplicar(artigo(A), recusar, "Produto personalizado, alterado ou embainhado: não pode ser devolvido nem trocado, mesmo com defeito.") ]
    com [ modulo(m3), prioridade(80),
          conclusoes(['OUT-001'=recusar, 'OUT-002'=nenhuma]),
          descricao("Recusar a devolução e a troca de produto personalizado, alterado ou embainhado, mesmo que tenha defeito.") ].

regra 'PC-007 Bodywear aceite em qualquer estado'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e naoDisparou(artigo(A), 'PC-007') e bodywear(A) ]
    entao [ aplicar(artigo(A), permitir, "Bodywear: a devolução é aceite em qualquer estado; o destino é definido pelas regras BW.") ]
    com [ modulo(m3), prioridade(70),
          conclusoes(['OUT-001'=permitir]),
          descricao("Permitir a devolução de bodywear em qualquer estado; o destino é definido pelas regras BW. Prevalece sobre PC-004 e PC-005.") ].

regra 'PC-006 Defeito de fabrico confirmado'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e naoDisparou(artigo(A), 'PC-006')
         e defeitoFabricoConfirmado(A) e naoModificado(A) e naoBodywear(A) ]
    entao [ aplicar(artigo(A), permitir, "Defeito de fabrico confirmado: reembolso pelo meio de pagamento permitido ou substituição por um artigo sem defeito; o artigo devolvido tem baixa por dano.") ]
    com [ modulo(m3), prioridade(60),
          conclusoes(['OUT-001'=permitir]),
          descricao("Permitir o reembolso pelo meio permitido ou a substituição por um artigo sem defeito; dar baixa por dano ao artigo devolvido (M9). Só para produto não personalizado nem alterado (HS-003 prevalece).") ].

regra 'PC-001 Não usado com etiquetas colocadas'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e naoDisparou(artigo(A), 'PC-001')
         e naoUsado(A) e etiquetasColocadas(A) e semDefeito(A) e naoBodywear(A) ]
    entao [ aplicar(artigo(A), permitir, "Não usado, em estado original, com as etiquetas colocadas: estado elegível, sujeito às regras de canal, comprovativo e prazo.") ]
    com [ modulo(m3), prioridade(50),
          conclusoes(['OUT-001'=permitir]),
          descricao("Estado elegível padrão: permitir se forem cumpridas as regras de canal, comprovativo e prazo.") ].

regra 'PC-002 Etiquetas soltas: rever a possibilidade de revenda'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e naoDisparou(artigo(A), 'PC-002')
         e naoUsado(A) e etiquetasSoltas(A) e semDefeito(A) e naoBodywear(A) e revendivelPorAvaliar(A) ]
    entao [ definir(artigo(A), aprovacao, responsavel_senior),
            aplicar(artigo(A), rever, "Etiquetas soltas: a gestão aprova só se o artigo puder ser verificado, corretamente reetiquetado e revendido. Falta avaliar a possibilidade de revenda (IN-010).") ]
    com [ modulo(m3), prioridade(50),
          conclusoes(['OUT-001'=rever, 'OUT-005'=responsavel_senior]),
          descricao("Não usado com etiquetas soltas: rever; aprovar só se o artigo puder ser verificado, reetiquetado e revendido (IN-010). Aprovação da gestão [a validar: A-19].") ].

regra 'PC-002 Etiquetas soltas: aprovado, artigo revendível'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e naoDisparou(artigo(A), 'PC-002')
         e naoUsado(A) e etiquetasSoltas(A) e semDefeito(A) e naoBodywear(A) e revendivel(A) ]
    entao [ definir(artigo(A), aprovacao, responsavel_senior),
            aplicar(artigo(A), permitir, "Etiquetas soltas, artigo verificável, reetiquetável e revendível: aprovado pela gestão.") ]
    com [ modulo(m3), prioridade(50),
          conclusoes(['OUT-001'=permitir, 'OUT-005'=responsavel_senior]),
          descricao("Não usado com etiquetas soltas e revendível (IN-010 = sim): aprovar com a gestão [a validar: A-19].") ].

regra 'PC-002 Etiquetas soltas: recusado, artigo não revendível'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e naoDisparou(artigo(A), 'PC-002')
         e naoUsado(A) e etiquetasSoltas(A) e semDefeito(A) e naoBodywear(A) e naoRevendivel(A) ]
    entao [ definir(artigo(A), tipoTransacao, nenhuma),
            aplicar(artigo(A), recusar, "Etiquetas soltas e o artigo não pode ser verificado, reetiquetado e revendido: recusar.") ]
    com [ modulo(m3), prioridade(50),
          conclusoes(['OUT-001'=recusar, 'OUT-002'=nenhuma]),
          descricao("Não usado com etiquetas soltas e não revendível (IN-010 = não): recusar.") ].

regra 'PC-003 Sem etiquetas: rever a possibilidade de revenda'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e naoDisparou(artigo(A), 'PC-003')
         e naoUsado(A) e etiquetasAusentes(A) e semDefeito(A) e naoBodywear(A) e revendivelPorAvaliar(A) ]
    entao [ definir(artigo(A), aprovacao, responsavel_senior),
            aplicar(artigo(A), rever, "Sem etiquetas: a gestão aprova só se o artigo puder ser verificado e preparado para revenda. Falta avaliar a possibilidade de revenda (IN-010).") ]
    com [ modulo(m3), prioridade(50),
          conclusoes(['OUT-001'=rever, 'OUT-005'=responsavel_senior]),
          descricao("Não usado sem etiquetas: rever; aprovar só se o artigo puder ser verificado e preparado para revenda (IN-010). Aprovação da gestão [a validar: A-19].") ].

regra 'PC-003 Sem etiquetas: aprovado, artigo revendível'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e naoDisparou(artigo(A), 'PC-003')
         e naoUsado(A) e etiquetasAusentes(A) e semDefeito(A) e naoBodywear(A) e revendivel(A) ]
    entao [ definir(artigo(A), aprovacao, responsavel_senior),
            aplicar(artigo(A), permitir, "Sem etiquetas, artigo verificável e preparável para revenda: aprovado pela gestão.") ]
    com [ modulo(m3), prioridade(50),
          conclusoes(['OUT-001'=permitir, 'OUT-005'=responsavel_senior]),
          descricao("Não usado sem etiquetas e revendível (IN-010 = sim): aprovar com a gestão [a validar: A-19].") ].

regra 'PC-003 Sem etiquetas: recusado, artigo não revendível'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e naoDisparou(artigo(A), 'PC-003')
         e naoUsado(A) e etiquetasAusentes(A) e semDefeito(A) e naoBodywear(A) e naoRevendivel(A) ]
    entao [ definir(artigo(A), tipoTransacao, nenhuma),
            aplicar(artigo(A), recusar, "Sem etiquetas e o artigo não pode ser verificado nem preparado para revenda: recusar.") ]
    com [ modulo(m3), prioridade(50),
          conclusoes(['OUT-001'=recusar, 'OUT-002'=nenhuma]),
          descricao("Não usado sem etiquetas e não revendível (IN-010 = não): recusar.") ].

regra 'PC-004 Claramente usado: rever troca pelo mesmo artigo'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e naoDisparou(artigo(A), 'PC-004')
         e usado(A) e semDefeito(A) e naoBodywear(A) e aprovacaoGestaoPendente ]
    entao [ definir(artigo(A), aprovacao, responsavel_senior),
            aplicar(artigo(A), rever, "Artigo claramente usado: o reembolso é recusado. A gestão pode aprovar apenas uma troca pelo mesmo artigo; não emitir numerário nem crédito de loja sem restrições.") ]
    com [ modulo(m3), prioridade(50),
          conclusoes(['OUT-001'=rever, 'OUT-005'=responsavel_senior]),
          descricao("Usado sem defeito confirmado: recusar o reembolso; a gestão pode aprovar apenas uma troca pelo mesmo artigo. Decisão da gestão pendente [a validar: A-18, A-19, A-29].") ].

regra 'PC-004 Claramente usado: troca pelo mesmo artigo aprovada'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e naoDisparou(artigo(A), 'PC-004')
         e usado(A) e semDefeito(A) e naoBodywear(A) e aprovadoPelaGestao ]
    entao [ definir(artigo(A), aprovacao, responsavel_senior),
            definir(artigo(A), tipoTransacao, troca_mesmo_artigo),
            aplicar(artigo(A), permitir, "Artigo usado: a gestão aprovou apenas uma troca pelo mesmo artigo, sem numerário nem crédito de loja.") ]
    com [ modulo(m3), prioridade(50),
          conclusoes(['OUT-001'=permitir, 'OUT-002'=troca_mesmo_artigo, 'OUT-005'=responsavel_senior]),
          descricao("Usado sem defeito confirmado e a gestão aprovou: só troca pelo mesmo artigo, sem numerário nem crédito de loja [a validar: A-18, A-29].") ].

regra 'PC-004 Claramente usado: recusado pela gestão'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e naoDisparou(artigo(A), 'PC-004')
         e usado(A) e semDefeito(A) e naoBodywear(A) e recusadoPelaGestao ]
    entao [ definir(artigo(A), tipoTransacao, nenhuma),
            aplicar(artigo(A), recusar, "Artigo usado e a gestão não aprovou a troca pelo mesmo artigo: recusar o reembolso.") ]
    com [ modulo(m3), prioridade(50),
          conclusoes(['OUT-001'=recusar, 'OUT-002'=nenhuma]),
          descricao("Usado sem defeito confirmado e a gestão não aprovou a troca pelo mesmo artigo: recusar [a validar: A-18, A-29].") ].

regra 'PC-005 Lavado sem defeito de fabrico confirmado'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e naoDisparou(artigo(A), 'PC-005')
         e lavado(A) e semDefeito(A) e naoBodywear(A) ]
    entao [ definir(artigo(A), tipoTransacao, nenhuma),
            aplicar(artigo(A), recusar, "Produto lavado sem defeito de fabrico confirmado: não é vendável; recusar a devolução e a troca.") ]
    com [ modulo(m3), prioridade(50),
          conclusoes(['OUT-001'=recusar, 'OUT-002'=nenhuma]),
          descricao("Recusar a devolução e a troca: produto lavado não é vendável.") ].

% =============================================================================================
% M4 — Comprovativo (só compras que não são online; levi.com e levi.ca seguem ONLINE, A-02)
% =============================================================================================

regra 'PT-001 Comprovativo válido confirma a compra'
    se [ pedidoAtivo e verificacaoNaoDeterminada e compraNaoOnline e comprovativoValido e comprovativoConfirmaCompra ]
    entao [ calcular(p([comprovativo, tipo], Tipo)),
            definir(pedido, tipoVerificacao, verificada),
            registar(pedido, ["Comprovativo válido (", Tipo, ") confirma a compra: devolução verificada."]) ]
    com [ modulo(m4), prioridade(100), conclusoes([]),
          descricao("Tratar como devolução verificada: recibo impresso ou digital, confirmação de encomenda, recibo de oferta, consulta da transação, fotografia do recibo ou consulta de encomenda BackPocket.") ].

regra 'PT-002 Compra não verificável: devolução às cegas'
    se [ pedidoAtivo e verificacaoNaoDeterminada e compraNaoOnline e naoEAjustePreco e semComprovativoValido ]
    entao [ definir(pedido, tipoVerificacao, as_cegas),
            registar(pedido, "Não é possível verificar a compra: devolução às cegas, se o produto for elegível.") ]
    com [ modulo(m4), prioridade(90), conclusoes([]),
          descricao("Não é possível verificar a compra: processar apenas como devolução às cegas, se o produto for elegível por outros motivos.") ].

regra 'PT-006 Cliente sem recibo não fornece dados ou há barreira linguística'
    se [ pedidoAtivo e devolucaoAsCegas e naoDisparou(pedido, 'PT-006') e clienteNaoForneceDadosOuBarreiraLinguistica ]
    entao [ registar(pedido, "Selecionar \"Saltar\" e prosseguir com a devolução às cegas; não pressionar o cliente a dar dados pessoais.") ]
    com [ modulo(m4), prioridade(80), conclusoes([]),
          descricao("Selecionar \"Saltar\" e prosseguir com a devolução às cegas elegível; não pressionar o cliente para fornecer informações.") ].

% =============================================================================================
% M5 — Prazo de devolução e ajuste de preço (as regras de prazo exigem um artigo elegível)
% =============================================================================================

regra 'PT-003 Devolução verificada até 30 dias'
    se [ pedidoAtivo e devolucaoVerificada e naoDisparou(pedido, 'PT-003')
         e compraNaoOnline e naoEAjustePreco e ate30DiasDesdeCompra e artigoElegivel ]
    entao [ calcular(dias_desde_compra(Dias)),
            calcular(( condicoes:pedidoTroca
                     -> Tipo = troca, Texto = "troca elegível."
                     ;  Tipo = reembolso, Texto = "reembolso total do valor pago no meio de pagamento original." )),
            definir(pedido, tipoTransacao, Tipo),
            definir(pedido, meioReembolso, meio_original),
            definir(pedido, baseValor, valor_pago),
            aplicar(pedido, permitir, ["Devolução verificada há ", Dias, " dias (até 30): ", Texto]) ]
    com [ modulo(m5), prioridade(100),
          conclusoes(['OUT-001'=permitir, 'OUT-002'=reembolso, 'OUT-002'=troca, 'OUT-003', 'OUT-004'=meio_original]),
          descricao("Permitir o reembolso total do valor pago no meio de pagamento original, ou uma troca elegível. Prazo de 30 dias inclusive [a validar: A-22].") ].

regra 'PT-004 Devolução verificada após 30 dias: rever'
    se [ pedidoAtivo e devolucaoVerificada e naoDisparou(pedido, 'PT-004')
         e compraNaoOnline e naoEAjustePreco e mais30DiasDesdeCompra e artigoElegivel e artigoRevendivelPorAvaliar ]
    entao [ calcular(dias_desde_compra(Dias)),
            definir(pedido, aprovacao, responsavel_senior),
            aplicar(pedido, rever, ["Devolução verificada há ", Dias, " dias (mais de 30): sem direito automático a reembolso. ",
                                    "A gestão pode aprovar crédito de loja se o artigo for vendável, verificável e de baixo risco. ",
                                    "Falta avaliar a possibilidade de revenda (IN-010)."]) ]
    com [ modulo(m5), prioridade(100),
          conclusoes(['OUT-001'=rever, 'OUT-005'=responsavel_senior]),
          descricao("Após 30 dias: rever. O crédito de loja pode ser aprovado se o artigo for vendável, verificável e de baixo risco. Falta avaliar a revenda (IN-010) [a validar: A-17, A-19].") ].

regra 'PT-004 Devolução verificada após 30 dias: crédito de loja aprovado'
    se [ pedidoAtivo e devolucaoVerificada e naoDisparou(pedido, 'PT-004')
         e compraNaoOnline e naoEAjustePreco e mais30DiasDesdeCompra e artigoElegivel e artigoRevendivel e baixoRisco ]
    entao [ calcular(dias_desde_compra(Dias)),
            definir(pedido, tipoTransacao, credito_loja),
            definir(pedido, meioReembolso, credito_loja),
            definir(pedido, baseValor, valor_pago),
            definir(pedido, aprovacao, responsavel_senior),
            aplicar(pedido, permitir, ["Devolução verificada há ", Dias, " dias (mais de 30): artigo vendável, verificável ",
                                       "e de baixo risco; a gestão aprova crédito de loja."]) ]
    com [ modulo(m5), prioridade(100),
          conclusoes(['OUT-001'=permitir, 'OUT-002'=credito_loja, 'OUT-003', 'OUT-004'=credito_loja, 'OUT-005'=responsavel_senior]),
          descricao("Após 30 dias, artigo vendável, verificável e de baixo risco: crédito de loja aprovado pela gestão. Baixo risco = sem indício significativo ou confirmado [a validar: A-17, A-19].") ].

regra 'PT-004 Devolução verificada após 30 dias: recusada, artigo não vendável'
    se [ pedidoAtivo e devolucaoVerificada e naoDisparou(pedido, 'PT-004')
         e compraNaoOnline e naoEAjustePreco e mais30DiasDesdeCompra e artigoNaoRevendivel ]
    entao [ calcular(dias_desde_compra(Dias)),
            definir(pedido, tipoTransacao, nenhuma),
            aplicar(pedido, recusar, ["Devolução verificada há ", Dias, " dias (mais de 30) e o artigo não é vendável: recusar."]) ]
    com [ modulo(m5), prioridade(100),
          conclusoes(['OUT-001'=recusar, 'OUT-002'=nenhuma]),
          descricao("Após 30 dias e o artigo não é vendável (IN-010 = não): recusar.") ].

regra 'PT-005 Devolução às cegas: só troca ou crédito de loja ao preço atual'
    se [ pedidoAtivo e devolucaoAsCegas e naoDisparou(pedido, 'PT-005')
         e compraNaoOnline e naoEAjustePreco e artigoElegivel ]
    entao [ calcular(( condicoes:pedidoTroca
                     -> Tipo = troca, Meio = null, Texto = "troca"
                     ;  Tipo = credito_loja, Meio = credito_loja, Texto = "crédito de loja" )),
            definir(pedido, tipoTransacao, Tipo),
            definir(pedido, meioReembolso, Meio),
            definir(pedido, baseValor, preco_atual),
            aplicar(pedido, permitir, ["Devolução às cegas: apenas ", Texto, ", ao preço de venda atual. ",
                                       "Não é possível reembolsar em numerário nem no meio de pagamento original sem comprovativo."]) ]
    com [ modulo(m5), prioridade(100),
          conclusoes(['OUT-001'=permitir, 'OUT-002'=credito_loja, 'OUT-002'=troca, 'OUT-003', 'OUT-004'=credito_loja, 'OUT-004'=null]),
          descricao("Artigo sem recibo elegível: permitir apenas troca ou crédito de loja, ao preço de venda atual; sem numerário nem meio original. Sem prazo [a validar: A-13, A-16].") ].

regra 'PT-008 Ajuste de preço após 14 dias ou sem recibo original'
    se [ pedidoAtivo e naoDisparou(pedido, 'PT-008') e ajustePreco e mais14DiasOuSemReciboOriginal ]
    entao [ calcular(( condicoes:reciboOriginal -> Motivo = "após 14 dias" ; Motivo = "sem o recibo original" )),
            definir(pedido, tipoTransacao, nenhuma),
            aplicar(pedido, recusar, ["Ajuste de preço pedido ", Motivo, ": recusar o ajuste."]) ]
    com [ modulo(m5), prioridade(100),
          conclusoes(['OUT-001'=recusar, 'OUT-002'=nenhuma]),
          descricao("Recusar o ajuste de preço: falta o prazo de 14 dias ou o recibo original. A fotografia do recibo não é o recibo original [a validar: A-14].") ].

regra 'PT-007 Ajuste de preço único em compra de loja até 14 dias'
    se [ pedidoAtivo e devolucaoVerificada e naoDisparou(pedido, 'PT-007')
         e ajustePreco e compraMainlineOuOutlet e semAjusteAnterior e reciboOriginal e ate14DiasDesdeCompra ]
    entao [ calcular(dias_desde_compra(Dias)),
            definir(pedido, tipoTransacao, ajuste_preco),
            definir(pedido, baseValor, valor_pos),
            definir(pedido, meioReembolso, meio_original),
            aplicar(pedido, permitir, ["Compra em loja há ", Dias, " dias com recibo original: ajuste de preço único ",
                                       "para o artigo idêntico, pela diferença calculada pelo POS."]) ]
    com [ modulo(m5), prioridade(90),
          conclusoes(['OUT-001'=permitir, 'OUT-002'=ajuste_preco, 'OUT-003', 'OUT-004'=meio_original]),
          descricao("Compra em loja, até 14 dias, com recibo original: permitir um ajuste de preço único para o artigo idêntico, pela diferença calculada pelo POS.") ].

regra 'PT-007 Ajuste de preço já aplicado nesta compra'
    se [ pedidoAtivo e naoDisparou(pedido, 'PT-007') e naoDisparou(pedido, 'PT-008') e ajustePreco e ajusteAnterior ]
    entao [ definir(pedido, tipoTransacao, nenhuma),
            aplicar(pedido, recusar, "Já foi aplicado um ajuste de preço a esta compra: o ajuste de 14 dias é único.") ]
    com [ modulo(m5), prioridade(90),
          conclusoes(['OUT-001'=recusar, 'OUT-002'=nenhuma]),
          descricao("O ajuste de preço de 14 dias é único: se já foi aplicado, recusar [a validar: A-14].") ].

regra 'PT-007 Ajuste de preço de compra fora da loja: rever'
    se [ pedidoAtivo e naoDisparou(pedido, 'PT-007') e naoDisparou(pedido, 'PT-008')
         e ajustePreco e compraForaDaLoja e semAjusteAnterior e reciboOriginal e ate14DiasDesdeCompra ]
    entao [ calcular(p([compraOriginal, canal], Canal)),
            definir(pedido, aprovacao, responsavel_senior),
            aplicar(pedido, rever, ["Ajuste de preço de uma compra ", Canal, ": a política só prevê o ajuste ",
                                    "de 14 dias para compras em loja. Rever com a gestão."]) ]
    com [ modulo(m5), prioridade(90),
          conclusoes(['OUT-001'=rever, 'OUT-005'=responsavel_senior]),
          descricao("PT-007 só cobre compras em loja; o ajuste de compras online ou BackPocket não está previsto: rever [a validar: A-14].") ].

% =============================================================================================
% ONLINE — levi.com e levi.ca devolvidos na loja. A Afterpay é avaliada antes de qualquer outro
% meio (TN-010, HS-005 > CH-006); CH-004 substitui o meio predefinido de CH-003.
% =============================================================================================

regra 'CH-002 Encomenda online encontrada: processar na BackPocket'
    se [ pedidoAtivo e naoDisparou(pedido, 'CH-002')
         e compraOnline e naoEAjustePreco e encomendaEncontrada e portalDisponivel e artigoElegivel ]
    entao [ calcular(p([compraOriginal, canal], Canal)),
            calcular(( p([loja, mercado], eua)
                     -> Extra = " Nos EUA, o cliente pode pedir um cartão de oferta eletrónico para outra compra online ou na BackPocket."
                     ;  Extra = "" )),
            definir(pedido, tipoVerificacao, verificada),
            definir(pedido, processo, backpocket),
            definir(pedido, tipoTransacao, reembolso),
            definir(pedido, meioReembolso, meio_original),
            definir(pedido, baseValor, valor_pago),
            aplicar(pedido, encaminhar, ["Encomenda ", Canal, " encontrada: processar a devolução na BackPocket ",
                                         "e reembolsar no meio de pagamento original.", Extra]) ]
    com [ modulo(online), prioridade(100),
          conclusoes(['OUT-001'=encaminhar, 'OUT-002'=reembolso, 'OUT-003', 'OUT-004'=meio_original, 'OUT-006'=backpocket]),
          descricao("Encaminhar através da BackPocket e reembolsar no meio de pagamento original; o cliente nos EUA pode pedir um cartão de oferta eletrónico.") ].

regra 'CH-004 Encomenda encontrada com o portal online indisponível: rever'
    se [ pedidoAtivo e naoDisparou(pedido, 'CH-004')
         e compraOnline e naoEAjustePreco e encomendaEncontrada e portalIndisponivel e artigoElegivel ]
    entao [ calcular(p([compraOriginal, canal], Canal)),
            definir(pedido, tipoVerificacao, verificada),
            definir(pedido, aprovacao, responsavel_senior),
            aplicar(pedido, rever, ["Encomenda ", Canal, " encontrada, mas o portal de devoluções online está ",
                                    "indisponível: a política não prevê este caso. Rever com a gestão."]) ]
    com [ modulo(online), prioridade(100),
          conclusoes(['OUT-001'=rever, 'OUT-005'=responsavel_senior]),
          descricao("Encomenda encontrada mas o portal está indisponível: nenhum documento cobre o caso; rever com a gestão, sem meio de reembolso definido [a validar: A-04].") ].

regra 'TN-010 Compra online com Afterpay'
    se [ pedidoAtivo e encaminhadaBackPocket e naoDisparou(pedido, 'TN-010') e compraOnline e pagamentoAfterpay ]
    entao [ definir(pedido, tipoTransacao, reembolso),
            definir(pedido, meioReembolso, meio_original),
            definir(pedido, processo, backpocket),
            registar(pedido, "Compra online com Afterpay: reembolso na BackPocket para a Afterpay. Sem troca, cartão de oferta nem meio de pagamento alternativo.") ]
    com [ modulo(online), prioridade(80),
          conclusoes(['OUT-002'=reembolso, 'OUT-004'=meio_original, 'OUT-006'=backpocket]),
          descricao("Processar na BackPocket para o método original; não fornecer troca, cartão de oferta nem meio de pagamento alternativo.") ].

regra 'HS-005 Exceção ao meio de pagamento Afterpay online'
    se [ pedidoAtivo e reembolsoAfterpayOnline e naoDisparou(pedido, 'HS-005') e pedidoDeExcecaoAoMeio ]
    entao [ calcular(( condicoes:pedidoTroca -> Pedido = "troca" ; Pedido = "outro meio de reembolso" )),
            recusar_excecao(["As exceções ao meio de pagamento Afterpay são proibidas: recusar o pedido de ", Pedido,
                             " e reembolsar através da Afterpay para o método original."]) ]
    com [ modulo(online), prioridade(70), conclusoes([]),
          descricao("Recusar a exceção (troca, cartão de oferta, numerário ou outro meio) e reembolsar através da Afterpay para o método original.") ].

regra 'CH-005 Encomenda online enviada há mais de 30 dias'
    se [ pedidoAtivo e encaminhadaBackPocket e naoDisparou(pedido, 'CH-005')
         e compraOnline e mais30DiasDesdeEnvio e pagamentoSemProcessoProprio ]
    entao [ calcular(dias_desde_envio(Dias)),
            definir(pedido, tipoTransacao, reembolso),
            definir(pedido, meioReembolso, cartao_oferta),
            aplicar(pedido, permitir, ["Encomenda online enviada há ", Dias, " dias (mais de 30): emitir cartão de oferta."]) ]
    com [ modulo(online), prioridade(60),
          conclusoes(['OUT-001'=permitir, 'OUT-002'=reembolso, 'OUT-004'=cartao_oferta]),
          descricao("Emitir cartão de oferta quando o artigo for elegível por outros motivos. Não se aplica a Afterpay (TN-010) nem a PayPal/Venmo (TN-008 prevalece) [a validar: A-05, A-06, A-22].") ].

regra 'CH-006 Troca de encomenda online'
    se [ pedidoAtivo e encaminhadaBackPocket e naoDisparou(pedido, 'CH-006')
         e compraOnline e pedidoTroca e ate30DiasDesdeEnvio e naoAfterpay ]
    entao [ definir(pedido, tipoTransacao, troca),
            definir(pedido, meioReembolso, meio_original),
            aplicar(pedido, permitir, "Troca de encomenda online: concluir a troca e devolver qualquer saldo remanescente ao meio de pagamento original.") ]
    com [ modulo(online), prioridade(60),
          conclusoes(['OUT-001'=permitir, 'OUT-002'=troca, 'OUT-004'=meio_original]),
          descricao("Concluir a troca e devolver qualquer saldo elegível remanescente ao meio de pagamento original; a Afterpay continua excluída (TN-010, HS-005).") ].

regra 'CH-003 Encomenda online não encontrada: às cegas com cartão de oferta'
    se [ pedidoAtivo e naoDisparou(pedido, 'CH-003')
         e compraOnline e naoEAjustePreco e encomendaNaoEncontrada e politicaPermiteAsCegasOnline e artigoElegivel ]
    entao [ definir(pedido, tipoVerificacao, as_cegas),
            definir(pedido, tipoTransacao, reembolso),
            definir(pedido, meioReembolso, cartao_oferta),
            definir(pedido, baseValor, preco_atual),
            aplicar(pedido, permitir, "Encomenda online não encontrada: devolução às cegas permitida pela política, com cartão de oferta. O processamento às cegas de devoluções online deve ser pouco comum.") ]
    com [ modulo(online), prioridade(100),
          conclusoes(['OUT-001'=permitir, 'OUT-002'=reembolso, 'OUT-003', 'OUT-004'=cartao_oferta]),
          descricao("Usar uma devolução às cegas apenas quando o cenário da política o permitir; o meio predefinido é o cartão de oferta [a validar: A-03].") ].

regra 'CH-003 Encomenda online não encontrada: às cegas não permitida'
    se [ pedidoAtivo e naoDisparou(pedido, 'CH-003')
         e compraOnline e naoEAjustePreco e encomendaNaoEncontrada e politicaNaoPermiteAsCegasOnline ]
    entao [ definir(pedido, tipoVerificacao, as_cegas),
            definir(pedido, tipoTransacao, nenhuma),
            aplicar(pedido, recusar, "Encomenda online não encontrada e a política não permite a devolução às cegas neste caso: recusar.") ]
    com [ modulo(online), prioridade(100),
          conclusoes(['OUT-001'=recusar, 'OUT-002'=nenhuma]),
          descricao("Encomenda não encontrada e a política não permite a devolução às cegas neste caso: recusar [a validar: A-03].") ].

regra 'CH-004 Portal online indisponível: às cegas no meio original'
    se [ pedidoAtivo e devolucaoAsCegas e meioReembolsoCartaoOferta e devolucaoAsCegasOnlinePermitida
         e naoDisparou(pedido, 'CH-004') e compraOnline e politicaPermiteAsCegasOnline e portalIndisponivel ]
    entao [ definir(pedido, meioReembolso, meio_original),
            aplicar(pedido, permitir, "Portal de devoluções online indisponível: a devolução às cegas permitida é processada no meio de pagamento original, em vez do cartão de oferta.") ]
    com [ modulo(online), prioridade(90),
          conclusoes(['OUT-001'=permitir, 'OUT-004'=meio_original]),
          descricao("Portal online indisponível: processar a devolução às cegas permitida no meio de pagamento original (substitui o cartão de oferta de CH-003).") ].

% =============================================================================================
% M6 — Resultado, troca e exceções. EX-002 e EX-003 não têm a guarda do fluxo terminado: o
% cliente pode contestar uma recusa terminal (ADR 0004). EX-006 anula EX-004 e EX-005.
% =============================================================================================

regra 'EP-001 Troca com recibo que altera apenas o tamanho'
    se [ pedidoAtivo e trocaPermitida e devolucaoVerificada e naoDisparou(pedido, 'EP-001') e apenasMudaTamanho ]
    entao [ registar(pedido, "Troca com recibo que muda apenas o tamanho: o artigo de substituição mantém o preço de venda original ou promocional pago.") ]
    com [ modulo(m6), prioridade(100), conclusoes([]),
          descricao("Respeitar o preço de venda original ou promocional para o artigo de substituição: a correspondência de promoções limita-se a trocas de tamanho.") ].

regra 'EP-002 Troca que altera o modelo ou a cor'
    se [ pedidoAtivo e trocaPermitida e naoDisparou(pedido, 'EP-002') e mudaModeloOuCor ]
    entao [ registar(pedido, "A troca muda o modelo ou a cor: devolver o artigo original pelo seu valor elegível e vender o novo artigo ao preço atual.") ]
    com [ modulo(m6), prioridade(100), conclusoes([]),
          descricao("Devolver o artigo original pelo seu valor elegível e vender o novo artigo ao preço atual.") ].

regra 'EX-001 Uma regra devolveu REVER: critério da gestão'
    se [ pedidoAtivo e naoDisparou(pedido, 'EX-001') e resultadoRever ]
    entao [ calcular(aprovacao_minima(responsavel_senior, Aprovacao)),
            definir(pedido, aprovacao, Aprovacao),
            registar(pedido, "Decisão da gestão: avaliar a possibilidade de revenda (fator formal de qualquer exceção), o comprovativo, o tempo decorrido, o valor da transação, o risco de fraude e as circunstâncias do cliente.") ]
    com [ modulo(m6), prioridade(90),
          conclusoes(['OUT-005'=responsavel_senior]),
          descricao("Avaliar a possibilidade de revenda, o comprovativo, o tempo decorrido, o valor da transação, o risco de fraude e as circunstâncias do cliente.") ].

regra 'EX-002 O cliente contesta o resultado padrão'
    se [ naoDisparou(pedido, 'EX-002') e clienteContesta e resultadoEmitido ]
    entao [ registar(pedido, "O cliente contesta o resultado: explicar a política e oferecer a melhor alternativa em conformidade com a política, antes de considerar qualquer exceção.") ]
    com [ modulo(m6), prioridade(80), conclusoes([]),
          descricao("Explicar a política e oferecer a melhor alternativa em conformidade com a política, antes de considerar uma exceção. Também depois de uma paragem obrigatória (ADR 0004).") ].

regra 'EX-003 O cliente fica irritado ou cria perturbação'
    se [ politicaExplicada e naoDisparou(pedido, 'EX-003') e clienteAgitado ]
    entao [ calcular(aprovacao_minima(responsavel_senior, Aprovacao)),
            definir(pedido, aprovacao, Aprovacao),
            registar(pedido, "Cliente irritado ou a causar perturbação: escalar para o responsável sénior de serviço, que avalia o apaziguamento e a segurança da loja. A agitação, por si só, não cria elegibilidade.") ]
    com [ modulo(m6), prioridade(70),
          conclusoes(['OUT-005'=responsavel_senior]),
          descricao("Escalar para o responsável sénior de serviço. A agitação por si só não cria elegibilidade (ADR 0004).") ].

regra 'EX-004 Exceção de apaziguamento: pode ser aprovada'
    se [ pedidoAtivo e devolucaoVerificada e escaladoResponsavelSenior e naoDisparou(pedido, 'EX-004')
         e pedidoExcecao e concluivelNoSistema e semParagemHs e baixoRisco ]
    entao [ registar(pedido, "Exceção de apaziguamento: o responsável sénior pode aprová-la (sem paragens obrigatórias, compra verificada, risco de fraude baixo e concluível no sistema), salvo os controlos de EX-006.") ]
    com [ modulo(m6), prioridade(60), conclusoes([]),
          descricao("Aprovar apenas quando nenhuma regra de paragem obrigatória se aplique, o artigo possa ser verificado, o risco de fraude seja baixo e o resultado possa ser concluído no sistema [a validar: A-18].") ].

regra 'EX-004 Exceção de apaziguamento: não pode ser aprovada'
    se [ pedidoAtivo e escaladoResponsavelSenior e naoDisparou(pedido, 'EX-004')
         e pedidoExcecao e paragemOuNaoVerificadaOuRiscoOuNaoConcluivel ]
    entao [ recusar_excecao("A exceção de apaziguamento não pode ser aprovada: as exceções não podem contornar paragens obrigatórias, exigem uma compra verificável, risco de fraude baixo e um resultado concluível no sistema.") ]
    com [ modulo(m6), prioridade(55), conclusoes([]),
          descricao("A exceção de apaziguamento não pode contornar controlos absolutos: há uma paragem obrigatória, a compra não é verificável, o risco de fraude não é baixo ou o resultado não pode ser concluído no sistema.") ].

regra 'EX-006 A exceção exige contornar um controlo obrigatório'
    se [ pedidoAtivo e naoDisparou(pedido, 'EX-006') e excecaoEmAvaliacao e pedidoExcecao e exigeControloObrigatorio ]
    entao [ recusar_excecao("A exceção pedida exige um meio de pagamento proibido, um SKU incorreto, um produto excluído ou contornar um processo obrigatório: recusar a exceção e usar o processo obrigatório. Estes controlos não são discricionários.") ]
    com [ modulo(m6), prioridade(50), conclusoes([]),
          descricao("Recusar a exceção que exija um meio de pagamento proibido, um SKU incorreto, um produto excluído, ou contornar a Afterpay, o PayPal, o Venmo ou o processamento online, e usar o processo obrigatório. Anula EX-004 e EX-005.") ].

regra 'EX-005 Exceção elegível com artigo vendável: resolução menos abrangente'
    se [ pedidoAtivo e excecaoNaoRecusada e naoDisparou(pedido, 'EX-005') e excecaoEmAvaliacao
         e pedidoExcecao e artigoNaoRecusado e artigosNaoRecusadosRevendiveis ]
    entao [ registar(pedido, "Exceção elegível e artigo vendável: preferir a resolução menos abrangente — 1) troca pelo mesmo artigo, 2) crédito de loja, 3) reembolso no meio de pagamento original quando permitido.") ]
    com [ modulo(m6), prioridade(40), conclusoes([]),
          descricao("Preferir a resolução menos abrangente: troca pelo mesmo artigo, depois crédito de loja, depois reembolso no meio de pagamento original quando permitido.") ].

regra 'EX-005 Exceção com artigo não vendável: recusar'
    se [ pedidoAtivo e excecaoNaoRecusada e naoDisparou(pedido, 'EX-005') e excecaoEmAvaliacao
         e pedidoExcecao e artigoNaoRecusadoNaoRevendivel ]
    entao [ recusar_excecao("O artigo não é vendável: a possibilidade de revenda é um fator formal de qualquer exceção. Recusar a exceção.") ]
    com [ modulo(m6), prioridade(40), conclusoes([]),
          descricao("A possibilidade de revenda é um fator formal em qualquer exceção: artigo não vendável, recusar a exceção.") ].

% =============================================================================================
% M7 — Valor da devolução (por artigo elegível, a partir da base definida em M5 ou ONLINE).
% Ordem: CH-009/CH-010 (110) > EP-003/EP-004 (100) > valor genérico OUT-003 (90) > total (10).
% =============================================================================================

regra 'CH-009 Devolução às cegas na Outlet: preço atual após promoções'
    se [ artigo(A) e pedidoAtivo e baseValorDefinida e devolucaoAsCegas e lojaOutlet e produtoDefinido(A)
         e artigoAtivo(A) e naoDisparou(artigo(A), 'CH-009') e artigoAceite(A) ]
    entao [ calcular(a(A, [produto, precoAtual], Preco)),
            calcular(a(A, [produto, pvpOriginal], Pvp)),
            definir(artigo(A), valorDevolucao, Preco),
            definir(artigo(A), baseValor, valor_promocional),
            registar(artigo(A), ["Devolução às cegas na Outlet: valor ao preço atual após as promoções ativas (",
                                 Preco, "), não ao PVP (", Pvp, ")."]) ]
    com [ modulo(m7), prioridade(110),
          conclusoes(['OUT-003']),
          descricao("Na devolução ou troca às cegas na Outlet, usar o preço de venda atual após as promoções ativas da Outlet, não o PVP.") ].

regra 'CH-010 Compra Mainline ou online com recibo devolvida na Outlet: PVP original'
    se [ artigo(A) e pedidoAtivo e baseValorDefinida e devolucaoVerificada e lojaOutlet e origemMainlineOuOnline
         e produtoDefinido(A) e artigoAtivo(A) e naoDisparou(artigo(A), 'CH-010') e artigoAceite(A) ]
    entao [ calcular(p([compraOriginal, canal], Canal)),
            calcular(a(A, [produto, pvpOriginal], Pvp)),
            definir(artigo(A), valorDevolucao, Pvp),
            definir(artigo(A), baseValor, pvp_original),
            registar(artigo(A), ["Compra ", Canal, " com recibo devolvida na Outlet: valor ao PVP original (",
                                 Pvp, "), se o POS e a política o permitirem."]) ]
    com [ modulo(m7), prioridade(110),
          conclusoes(['OUT-003']),
          descricao("A devolução entre canais com recibo, da Mainline ou Online para a Outlet, pode ser processada ao PVP original quando permitido pelo POS e pela política [a validar: A-21].") ].

regra 'EP-003 Devolução às cegas numa promoção por escalões'
    se [ artigo(A) e pedidoAtivo e baseValorDefinida e devolucaoAsCegas e promocaoEscaloes
         e artigoAtivo(A) e naoDisparou(artigo(A), 'EP-003') e artigoAceite(A) ]
    entao [ calcular(artigos_devolvidos(Devolvidos)),
            calcular(a(A, [valorCalculadoPos], Valor)),
            calcular(( Valor == null -> Falta = "; falta o valor do escalão calculado pelo POS." ; Falta = "." )),
            definir(artigo(A), valorDevolucao, Valor),
            definir(artigo(A), baseValor, valor_escalao),
            registar(artigo(A), ["Devolução às cegas numa promoção por escalões: o escalão é determinado pelos ", Devolvidos,
                                 " artigos devolvidos nesta transação", Falta]) ]
    com [ modulo(m7), prioridade(100),
          conclusoes(['OUT-003']),
          descricao("Usar o número de artigos devolvidos na transação atual para determinar o valor do escalão aplicável; o valor vem do POS [a validar: A-21, A-30].") ].

regra 'EP-004 Devolução com recibo numa promoção por escalões'
    se [ artigo(A) e pedidoAtivo e baseValorDefinida e devolucaoVerificada e promocaoEscaloes
         e artigoAtivo(A) e naoDisparou(artigo(A), 'EP-004') e artigoAceite(A) ]
    entao [ calcular(p([compraOriginal, quantidadeComprada], Quantidade)),
            calcular(a(A, [valorCalculadoPos], Valor)),
            calcular(( Valor == null -> Falta = "; falta o valor calculado pelo POS." ; Falta = "." )),
            definir(artigo(A), valorDevolucao, Valor),
            definir(artigo(A), baseValor, valor_pos),
            registar(artigo(A), ["Devolução com recibo numa promoção por escalões: reembolso calculado pelo POS com base na quantidade ",
                                 "original comprada (", Quantidade, ")", Falta]) ]
    com [ modulo(m7), prioridade(100),
          conclusoes(['OUT-003']),
          descricao("Utilizar o reembolso calculado pelo POS com base na quantidade original comprada.") ].

regra 'OUT-003 Valor do artigo segundo a base da decisão'
    se [ artigo(A) e pedidoAtivo e baseValorDefinida e artigoAtivo(A) e semBaseEspecifica(A)
         e naoDisparou(artigo(A), 'OUT-003') e artigoAceite(A) ]
    entao [ calcular(decisao(pedido, baseValor, Base)),
            calcular(valor_da_base(Base, A, Valor)),
            calcular(( Valor == null -> TextoValor = "por determinar" ; TextoValor = Valor )),
            definir(artigo(A), valorDevolucao, Valor),
            definir(artigo(A), baseValor, Base),
            registar(artigo(A), ["Valor do artigo: ", TextoValor, " (", Base, ")."]) ]
    com [ modulo(m7), prioridade(90),
          conclusoes(['OUT-003']),
          descricao("Valor da devolução do artigo pela base definida em M5 ou no caminho online: valor original pago, preço de venda atual ou valor calculado pelo POS.") ].

regra 'OUT-003 Valor total da devolução'
    se [ pedidoAtivo e baseValorDefinida e naoDisparou(pedido, 'OUT-003') e valoresDosArtigos ]
    entao [ calcular(valor_total(Total, BaseDoPedido, NumeroArtigos)),
            definir(pedido, valorDevolucao, Total),
            definir(pedido, baseValor, BaseDoPedido),
            registar(pedido, ["Valor total da devolução: ", Total, " (", NumeroArtigos, " artigo(s), base ", BaseDoPedido, ")."]) ]
    com [ modulo(m7), prioridade(10),
          conclusoes(['OUT-003']),
          descricao("Soma dos valores dos artigos elegíveis; a base do pedido passa a ser a dos artigos quando é comum a todos.") ].

% =============================================================================================
% M7 — Meio de reembolso. As regras TN só se aplicam a um reembolso (ou ajuste) verificado no
% meio original (PT-003, PT-007, CH-002, CH-004 ou CH-006). O meio alternativo só depois de o
% original falhar. TN-006 corre depois do total (OUT-003, prioridade 10).
% =============================================================================================

regra 'TN-007 Devolução de oferta paga a crédito ou débito'
    se [ pedidoAtivo e devolucaoVerificada e elegibilidadeNaoRecusada e meioReembolsoOriginal e transacaoReembolso
         e naoDisparou(pedido, 'TN-007') e devolucaoOferta e pagamentoCreditoOuDebito ]
    entao [ calcular(p([compraOriginal, pagamento, meio], Meio)),
            calcular(( p([pedidoExcecao, resolucaoPedida], credito_loja)
                     -> Tipo = credito_loja, MeioReembolso = credito_loja, Escolha = "; o destinatário escolheu crédito de loja."
                     ;  Tipo = reembolso, MeioReembolso = meio_original, Escolha = "." )),
            definir(pedido, tipoTransacao, Tipo),
            definir(pedido, meioReembolso, MeioReembolso),
            registar(pedido, ["Devolução de oferta com recibo que mostra pagamento a ", Meio,
                              ": oferecer reembolso tokenizado para o cartão original do comprador ou crédito de loja", Escolha]) ]
    com [ modulo(m7), prioridade(80),
          conclusoes(['OUT-002'=reembolso, 'OUT-002'=credito_loja, 'OUT-004'=meio_original, 'OUT-004'=credito_loja]),
          descricao("Oferecer reembolso tokenizado para o cartão original do comprador, ou emitir crédito de loja. A escolha é do cliente (resolucaoPedida) [a validar: A-12].") ].

regra 'TN-001 Devolução verificada paga a crédito ou débito'
    se [ pedidoAtivo e devolucaoVerificada e elegibilidadeNaoRecusada e meioReembolsoOriginal e transacaoReembolsoOuAjuste
         e naoDisparou(pedido, 'TN-001') e naoEOferta e pagamentoCreditoOuDebito ]
    entao [ calcular(p([compraOriginal, pagamento, meio], Meio)),
            registar(pedido, ["Pagamento a ", Meio, ": reembolso automático no cartão original por tokenização, ",
                              "sem pedir ao cliente para apresentar o cartão."]) ]
    com [ modulo(m7), prioridade(70), conclusoes([]),
          descricao("Reembolsar automaticamente o cartão original através de tokenização; não pedir ao cliente para apresentar o cartão.") ].

regra 'TN-002 Cartão perdido ou roubado com a conta ativa'
    se [ pedidoAtivo e meioReembolsoOriginal e tokenizacaoAplicada e naoDisparou(pedido, 'TN-002') e contaAtivaCartaoPerdido ]
    entao [ registar(pedido, "Cartão original perdido ou roubado, mas a conta está ativa: o reembolso vai automaticamente para a conta do cartão original.") ]
    com [ modulo(m7), prioridade(65), conclusoes([]),
          descricao("Reembolsar automaticamente para a conta do cartão original: o token continua associado à conta ativa.") ].

regra 'TN-003 Conta encerrada: tentar primeiro o cartão original'
    se [ pedidoAtivo e meioReembolsoOriginal e tokenizacaoAplicada e naoDisparou(pedido, 'TN-003')
         e contaEncerrada e reembolsoOriginalNaoRecusado ]
    entao [ registar(pedido, "Conta do cartão original encerrada: tentar primeiro o reembolso no cartão original. Só se for recusado se pode usar outro cartão, numerário ou cartão de oferta.") ]
    com [ modulo(m7), prioridade(65), conclusoes([]),
          descricao("Conta do cartão original encerrada: tentar primeiro o cartão original; só após a recusa se pode usar outro meio.") ].

regra 'TN-003 Conta encerrada: reembolso original recusado, meio alternativo'
    se [ pedidoAtivo e meioReembolsoOriginal e tokenizacaoAplicada e naoDisparou(pedido, 'TN-003')
         e contaEncerrada e reembolsoOriginalRecusado ]
    entao [ definir(pedido, meioReembolso, meio_alternativo),
            registar(pedido, "O reembolso ao cartão original (conta encerrada) foi recusado: usar um cartão de crédito ou débito diferente, numerário ou cartão de oferta.") ]
    com [ modulo(m7), prioridade(65),
          conclusoes(['OUT-004'=meio_alternativo]),
          descricao("Depois de o reembolso ao cartão original ser recusado, o sistema pode usar um cartão diferente, numerário ou cartão de oferta.") ].

regra 'TN-004 Débito: sem numerário antes da recusa do reembolso original'
    se [ pedidoAtivo e meioReembolsoOriginal e tokenizacaoAplicada e naoDisparou(pedido, 'TN-004')
         e pagamentoDebito e reembolsoOriginalNaoRecusado ]
    entao [ registar(pedido, "Compra a débito: não emitir numerário; reembolsar o cartão de débito original enquanto esse reembolso não for recusado.") ]
    com [ modulo(m7), prioridade(60), conclusoes([]),
          descricao("Compra em débito e o reembolso ao débito original ainda não foi recusado: não emitir numerário; reembolsar o cartão de débito original. Não se aplica ao Interac [a validar: A-11].") ].

regra 'TN-005 Pagamento contactless (Apple Pay ou Google Pay)'
    se [ pedidoAtivo e devolucaoVerificada e elegibilidadeNaoRecusada e meioReembolsoOriginal e transacaoReembolsoOuAjuste
         e naoDisparou(pedido, 'TN-005') e pagamentoContactless ]
    entao [ calcular(p([compraOriginal, pagamento, meio], Meio)),
            registar(pedido, ["Pagamento contactless (", Meio, "): reembolso automático para o cartão ou conta bancária associada."]) ]
    com [ modulo(m7), prioridade(70), conclusoes([]),
          descricao("Reembolsar automaticamente para o cartão ou conta bancária associada: o reembolso segue a conta original.") ].

regra 'TN-008 Compra via PayPal ou Venmo'
    se [ pedidoAtivo e elegibilidadeNaoRecusada e naoDisparou(pedido, 'TN-008') e reembolsoNoMeioOriginalOuEmRevisao
         e pagamentoPaypalOuVenmo e acessoAplicacao ]
    entao [ calcular(p([compraOriginal, pagamento, meio], Meio)),
            definir(pedido, meioReembolso, aplicacao_pagamento),
            definir(pedido, processo, paypal_venmo),
            registar(pedido, ["Compra via ", Meio, ": o cliente acede à aplicação e o reembolso é processado pelo fluxo ",
                              "prescrito da aplicação; não substituir por outro meio."]) ]
    com [ modulo(m7), prioridade(70),
          conclusoes(['OUT-004'=aplicacao_pagamento, 'OUT-006'=paypal_venmo]),
          descricao("O cliente acede à aplicação de pagamento e o reembolso é processado pelo fluxo prescrito da aplicação; não substituir por outro meio. PayPal e Venmo não são tokenizados.") ].

regra 'TN-008 PayPal ou Venmo sem acesso à aplicação na loja'
    se [ pedidoAtivo e elegibilidadeNaoRecusada e naoDisparou(pedido, 'TN-008') e reembolsoNoMeioOriginalOuEmRevisao
         e pagamentoPaypalOuVenmo e semAcessoAplicacao ]
    entao [ calcular(p([compraOriginal, pagamento, meio], Meio)),
            calcular(aprovacao_minima(responsavel_senior, Aprovacao)),
            definir(pedido, meioReembolso, aplicacao_pagamento),
            definir(pedido, processo, paypal_venmo),
            definir(pedido, aprovacao, Aprovacao),
            aplicar(pedido, rever, ["Compra via ", Meio, " e o cliente não consegue aceder à aplicação: o reembolso só ",
                                    "pode ser feito pelo fluxo da aplicação; não substituir por outro meio. Rever com a gestão."]) ]
    com [ modulo(m7), prioridade(70),
          conclusoes(['OUT-001'=rever, 'OUT-004'=aplicacao_pagamento, 'OUT-006'=paypal_venmo, 'OUT-005'=responsavel_senior]),
          descricao("O cliente não consegue aceder à aplicação: não substituir o meio de pagamento; rever com a gestão, sem meio alternativo [a validar: A-05].") ].

regra 'TN-009 Compra em loja com Afterpay'
    se [ pedidoAtivo e devolucaoVerificada e elegibilidadeNaoRecusada e meioReembolsoOriginal
         e naoDisparou(pedido, 'TN-009') e compraNaoOnline e pagamentoAfterpay ]
    entao [ definir(pedido, processo, afterpay),
            registar(pedido, "Compra em loja com Afterpay: o cliente localiza a encomenda na aplicação Afterpay; a loja processa a devolução total para a Afterpay (não as prestações) e entrega o recibo de devolução do POS.") ]
    com [ modulo(m7), prioridade(70),
          conclusoes(['OUT-006'=afterpay]),
          descricao("O cliente localiza a encomenda na aplicação Afterpay; processar a devolução total para a Afterpay e fornecer o recibo de devolução do POS.") ].

regra 'TN-011 Interac no Canadá com o mesmo cartão físico'
    se [ pedidoAtivo e devolucaoVerificada e elegibilidadeNaoRecusada e meioReembolsoOriginal
         e naoDisparou(pedido, 'TN-011') e mercadoCanada e compraNaoOnline e pagamentoInterac e cartaoFisicoPresente ]
    entao [ registar(pedido, "Interac no Canadá: o cliente apresentou o mesmo cartão físico usado na compra; reembolso Interac.") ]
    com [ modulo(m7), prioridade(70), conclusoes([]),
          descricao("Compra em loja paga com Interac no Canadá: o cliente apresenta o mesmo cartão Interac físico usado na compra; os cartões Interac não são tokenizados.") ].

regra 'TN-011 Interac no Canadá sem o mesmo cartão físico'
    se [ pedidoAtivo e devolucaoVerificada e elegibilidadeNaoRecusada e meioReembolsoOriginal
         e naoDisparou(pedido, 'TN-011') e mercadoCanada e compraNaoOnline e pagamentoInterac e cartaoFisicoAusente ]
    entao [ calcular(aprovacao_minima(responsavel_senior, Aprovacao)),
            definir(pedido, meioReembolso, null),
            definir(pedido, aprovacao, Aprovacao),
            aplicar(pedido, rever, "Compra paga com Interac: é obrigatório apresentar o mesmo cartão físico usado na compra (os cartões Interac não são tokenizados). Sem esse cartão não se processa o reembolso Interac nem se insere o cartão manualmente; não usar outro cartão nem numerário. Rever com a gestão.") ]
    com [ modulo(m7), prioridade(70),
          conclusoes(['OUT-001'=rever, 'OUT-004'=null, 'OUT-005'=responsavel_senior]),
          descricao("Sem o mesmo cartão Interac físico não se processa o reembolso Interac nem se insere o cartão manualmente; um cartão de substituição não é o mesmo cartão. Rever, sem meio alternativo [a validar: A-10].") ].

regra 'TN-012 Compra BackPocket no Canadá paga com Interac'
    se [ pedidoAtivo e meioReembolsoOriginal e interacVerificado e naoDisparou(pedido, 'TN-012') e compraBackPocket ]
    entao [ calcular(decisao(pedido, valorDevolucao, Valor)),
            calcular(( Valor == null -> TextoValor = "" ; TextoValor = [" (", Valor, ")"] )),
            definir(pedido, processo, verifone_interac),
            registar(pedido, ["Compra BackPocket paga com Interac: concluir a devolução na BackPocket e emitir um reembolso manual ",
                              "na VeriFone pelo valor exato", TextoValor, ", com o cartão presente e sem inserção manual."]) ]
    com [ modulo(m7), prioridade(5),
          conclusoes(['OUT-006'=verifone_interac]),
          descricao("Verificar o Interac; concluir a devolução na BackPocket; emitir um reembolso manual na VeriFone pelo valor exato, com o cartão presente e sem inserção manual.") ].

regra 'OUT-004 Compra paga em numerário ou cartão de oferta'
    se [ pedidoAtivo e devolucaoVerificada e elegibilidadeNaoRecusada e meioReembolsoOriginal
         e naoDisparou(pedido, 'OUT-004') e pagamentoNumerarioOuCartaoOferta ]
    entao [ calcular(p([compraOriginal, pagamento, meio], Meio)),
            registar(pedido, ["Compra paga em ", Meio, ": reembolso no meio de pagamento original."]) ]
    com [ modulo(m7), prioridade(70), conclusoes([]),
          descricao("Nenhuma regra TN cobre o numerário nem o cartão de oferta: reembolso no meio original, segundo PT-003 (docs/03) [a validar: A-09].") ].

regra 'TN-006 Troca parcial com saldo reembolsável'
    se [ pedidoAtivo e devolucaoVerificada e trocaPermitida e valorDevolucaoDefinido e meioReembolsoOriginal
         e naoDisparou(pedido, 'TN-006') e pagamentoComCartao e valorDevolucaoMaiorQueTroca ]
    entao [ calcular(saldo_troca(Saldo)),
            registar(pedido, ["Troca parcial: concluir a troca e reembolsar automaticamente o saldo de ", Saldo,
                              " para o cartão original."]) ]
    com [ modulo(m7), prioridade(5), conclusoes([]),
          descricao("Concluir a troca e reembolsar automaticamente o valor remanescente para o cartão original.") ].

% =============================================================================================
% M8 — Controlos e documentação (transação a processar: não recusada e com tipo definido).
% Ordem: CT-001, CT-002, CT-004, CT-005, CT-006, EX-007 e, por fim, CT-007.
% =============================================================================================

regra 'CT-001 Devolução verificada processada por pessoal autorizado'
    se [ pedidoAtivo e transacaoAProcessar e devolucaoVerificada e naoDisparou(pedido, 'CT-001') e colaboradorAutorizado ]
    entao [ calcular(p([colaborador, funcao], Funcao)),
            registar(pedido, ["Devolução verificada: processada por ", Funcao, " autorizado, com a sua própria credencial de POS."]) ]
    com [ modulo(m8), prioridade(100), conclusoes([]),
          descricao("A Gestão da Loja, o Key Holder, ou um Lead Cashier ou Elevated Stylist aprovado pelo District Manager processam a transação com as suas próprias credenciais de POS.") ].

regra 'CT-002 Devolução às cegas por Lead Cashier ou Elevated Stylist'
    se [ pedidoAtivo e transacaoAProcessar e devolucaoAsCegas e naoDisparou(pedido, 'CT-002') e processadorLeadCashierOuElevatedStylist ]
    entao [ calcular(p([colaborador, funcao], Funcao)),
            calcular(( decisao(pedido, aprovacao, nenhuma) -> Aprovacao = xstore_manager ; decisao(pedido, aprovacao, Aprovacao) )),
            definir(pedido, aprovacao, Aprovacao),
            registar(pedido, ["Devolução às cegas processada por ", Funcao, ": obter a aprovação do XStore Manager."]) ]
    com [ modulo(m8), prioridade(100),
          conclusoes(['OUT-005'=xstore_manager]),
          descricao("A devolução às cegas processada por um Lead Cashier ou Elevated Stylist aprovado exige a aprovação do XStore Manager.") ].

regra 'CT-004 Atribuir a devolução ao Stylist da venda original'
    se [ pedidoAtivo e transacaoAProcessar e devolucaoVerificada e naoDisparou(pedido, 'CT-004') e stylistDaVendaConhecido ]
    entao [ calcular(p([compraOriginal, idStylistVenda], Stylist)),
            definir(pedido, 'documentacao.idStylistAtribuido', Stylist),
            registar(pedido, ["Atribuir a devolução ao Stylist da venda original (", Stylist, ")."]) ]
    com [ modulo(m8), prioridade(90),
          conclusoes(['OUT-008']),
          descricao("A devolução com recibo concluída é atribuída ao Stylist creditado com a venda original.") ].

regra 'CT-005 Assinaturas do recibo de devolução'
    se [ pedidoAtivo e transacaoAProcessar e naoDisparou(pedido, 'CT-005') ]
    entao [ calcular(( p([loja, coberturaLojaUnica], true)
                     -> Testemunha = "SSC", Texto = "\"SSC\" (cobertura de loja única)."
                     ;  Testemunha = "Assinatura da testemunha", Texto = "de uma testemunha." )),
            calcular(( p([colaborador, id], Id), Id \== null -> Processador = Id ; Processador = "processador" )),
            calcular(atomics_to_string(["Assinatura de ", Processador], AssinaturaProcessador)),
            definir(pedido, 'documentacao.assinaturaCliente', "Assinatura do cliente ou \"Recusado\""),
            definir(pedido, 'documentacao.assinaturaProcessador', AssinaturaProcessador),
            definir(pedido, 'documentacao.assinaturaTestemunha', Testemunha),
            registar(pedido, ["Recibo de devolução: assinatura do cliente (ou \"Recusado\"), do processador e ", Texto]) ]
    com [ modulo(m8), prioridade(80),
          conclusoes(['OUT-008']),
          descricao("Obter a assinatura do cliente ou escrever \"Recusado\"; a assinatura do processador; e a da testemunha ou \"SSC\" em cobertura de loja única.") ].

regra 'CT-006 Recibo original entregue'
    se [ pedidoAtivo e assinaturasObtidas e naoDisparou(pedido, 'CT-006') e reciboOriginalImpresso ]
    entao [ calcular(p([comprovativo, clienteMantemRecibo], Mantem)),
            calcular(p([comprovativo, incluiOutrosArtigos], Outros)),
            calcular(nota_recibo(Mantem, Outros, Agrafado, Nota, Texto)),
            definir(pedido, 'documentacao.reciboAgrafado', Agrafado),
            definir(pedido, 'documentacao.notaRecibo', Nota),
            registar(pedido, Texto) ]
    com [ modulo(m8), prioridade(70),
          conclusoes(['OUT-008']),
          descricao("Agrafar o recibo original ao exemplar da loja; se o cliente o mantiver ou se incluir outros artigos, anotar esse facto no exemplar da loja.") ].

regra 'EX-007 Documentar a exceção aprovada'
    se [ pedidoAtivo e excecaoNaoRecusada e naoDisparou(pedido, 'EX-007') e excecaoAprovada ]
    entao [ calcular(registo_excecao(Registo)),
            definir(pedido, 'documentacao.registoExcecao', Registo),
            registar(pedido, ["Exceção aprovada documentada. ", Registo]) ]
    com [ modulo(m8), prioridade(60),
          conclusoes(['OUT-008']),
          descricao("Documentar o motivo, o aprovador, o valor, o resultado, a preocupação do cliente e o destino do produto na cópia da loja ou no registo aprovado.") ].

regra 'CT-007 Retenção dos suportes durante 90 dias'
    se [ pedidoAtivo e assinaturasObtidas e naoDisparou(pedido, 'CT-007') e dataPedidoDefinida ]
    entao [ calcular(p([dataPedido], DataPedido)),
            calcular(data_mais_dias(DataPedido, 90, Ate)),
            calcular(( compra_online -> Extra = "; arquivar a cópia da devolução online com os suportes diários." ; Extra = "." )),
            definir(pedido, 'documentacao.retencaoAte', Ate),
            registar(pedido, ["Conservar o exemplar da loja e as assinaturas até ", Ate, " (90 dias)", Extra]) ]
    com [ modulo(m8), prioridade(50),
          conclusoes(['OUT-008']),
          descricao("Conservar o exemplar da loja e as assinaturas nos ficheiros de retenção de suportes durante 90 dias; arquivar as cópias das devoluções online com os suportes diários.") ].

% =============================================================================================
% M9 — Destino do produto e agregação do pedido (ADR 0002).
% Ordem: recusado (100); bodywear BW-004 > BW-003 > BW-001/BW-002 (95-85); defeito PC-006 (85);
% inspeção CT-008 (80); entre canais EP-007 > EP-005/EP-006 (70-60); agregação OUT-001 (1).
% OUT-007 e OUT-001 correm também depois de uma recusa terminal, mas não com o pedido suspenso.
% Num ajuste de preço o artigo não é entregue: as regras de destino não se aplicam (A-14).
% =============================================================================================

regra 'OUT-007 Artigo recusado: devolução ao cliente'
    se [ naoEAjustePreco e pedidoNaoSuspenso e artigo(A) e semDestino(A)
         e naoDisparou(artigo(A), 'OUT-007') e artigoOuPedidoRecusado(A) ]
    entao [ definir(artigo(A), destino, devolucao_cliente),
            registar(artigo(A), "Devolução recusada: o artigo é devolvido ao cliente.") ]
    com [ modulo(m9), prioridade(100),
          conclusoes(['OUT-007'=devolucao_cliente]),
          descricao("Transação ou artigo recusado: o artigo é devolvido ao cliente (docs/03, módulo 10). Um artigo inseguro continua isolado [a validar: A-28].") ].

regra 'BW-004 Bodywear usado e sujo ou inseguro'
    se [ pedidoAtivo e elegibilidadeNaoRecusada e naoEAjustePreco e artigo(A)
         e bodywear(A) e usado(A) e sujoOuInseguro(A) e artigoAtivo(A) e bodywearAceite(A)
         e naoDisparou(artigo(A), 'BW-004') e semDestinoOuIsolado(A) ]
    entao [ definir(artigo(A), destino, risco_biologico),
            registar(artigo(A), "Bodywear usado e sujo ou inseguro: saco de risco biológico imediato, etiquetado e datado, sala de reservas, e-mail ao escritório corporativo e instruções de eliminação.") ]
    com [ modulo(m9), prioridade(95),
          conclusoes(['OUT-007'=risco_biologico]),
          descricao("Colocar imediatamente num saco de risco biológico, etiquetar e datar, guardar na sala de reservas, enviar e-mail ao escritório corporativo e seguir as instruções de eliminação. Prevalece sobre BW-003.") ].

regra 'BW-003 Bodywear com unidades em falta ou usado'
    se [ pedidoAtivo e elegibilidadeNaoRecusada e naoEAjustePreco e artigo(A)
         e bodywear(A) e conjuntoIncompletoOuUsado(A) e artigoAtivo(A) e semDestino(A)
         e bodywearAceite(A) e naoDisparou(artigo(A), 'BW-003') ]
    entao [ calcular(( a(A, [estado, conjuntoCompleto], true) -> Motivo = "usado" ; Motivo = "com unidades em falta" )),
            definir(artigo(A), destino, baixa_dano),
            registar(artigo(A), ["Bodywear ", Motivo, ": dar baixa por dano a todo o conjunto."]) ]
    com [ modulo(m9), prioridade(90),
          conclusoes(['OUT-007'=baixa_dano]),
          descricao("Dar baixa por dano a todo o conjunto quando faltam unidades do conjunto original ou o produto foi usado.") ].

regra 'BW-001 Bodywear com embalagem intacta: inspeção confirma revenda'
    se [ pedidoAtivo e elegibilidadeNaoRecusada e naoEAjustePreco e artigo(A)
         e bodywear(A) e embalagemIntacta(A) e conjuntoCompleto(A) e naoUsado(A) e revendivel(A)
         e artigoAtivo(A) e semDestino(A) e bodywearAceite(A) e naoDisparou(artigo(A), 'BW-001') ]
    entao [ definir(artigo(A), destino, area_vendas),
            registar(artigo(A), "Bodywear com embalagem intacta: a inspeção confirma que não foi usado e é vendável; devolver à área de vendas.") ]
    com [ modulo(m9), prioridade(85),
          conclusoes(['OUT-007'=area_vendas]),
          descricao("Embalagem original intacta: inspecionar totalmente e devolver à venda apenas quando for confirmado que não foi usado e é vendável.") ].

regra 'BW-001 Bodywear com embalagem intacta: inspeção não confirma revenda'
    se [ pedidoAtivo e elegibilidadeNaoRecusada e naoEAjustePreco e artigo(A)
         e bodywear(A) e embalagemIntacta(A) e conjuntoCompleto(A) e naoUsado(A) e naoRevendivel(A)
         e artigoAtivo(A) e semDestino(A) e bodywearAceite(A) e naoDisparou(artigo(A), 'BW-001') ]
    entao [ definir(artigo(A), destino, baixa_dano),
            registar(artigo(A), "Bodywear com embalagem intacta, mas a inspeção não confirma que é vendável: dar baixa por dano.") ]
    com [ modulo(m9), prioridade(85),
          conclusoes(['OUT-007'=baixa_dano]),
          descricao("Embalagem intacta, mas a inspeção não confirma que é vendável: baixa por dano (docs/03).") ].

regra 'BW-001 Bodywear com embalagem intacta: inspecionar'
    se [ pedidoAtivo e elegibilidadeNaoRecusada e naoEAjustePreco e artigo(A)
         e bodywear(A) e embalagemIntacta(A) e conjuntoCompleto(A) e naoUsado(A) e revendivelPorAvaliar(A)
         e artigoAtivo(A) e semDestino(A) e bodywearAceite(A) e naoDisparou(artigo(A), 'BW-001') ]
    entao [ registar(artigo(A), "Bodywear com embalagem intacta: inspecionar totalmente para sinais de uso. Devolver à venda só se for confirmado que não foi usado e é vendável; caso contrário, baixa por dano.") ]
    com [ modulo(m9), prioridade(85), conclusoes([]),
          descricao("Embalagem intacta e a inspeção ainda não foi feita (IN-010): inspecionar totalmente antes de decidir o destino.") ].

regra 'BW-002 Bodywear sem embalagem, não usado e completo'
    se [ pedidoAtivo e elegibilidadeNaoRecusada e naoEAjustePreco e artigo(A)
         e bodywear(A) e semEmbalagem(A) e conjuntoCompleto(A) e naoUsado(A)
         e artigoAtivo(A) e semDestino(A) e bodywearAceite(A) e naoDisparou(artigo(A), 'BW-002') ]
    entao [ definir(artigo(A), destino, saldos),
            definir(artigo(A), descontoSaldo, 50),
            registar(artigo(A), "Bodywear sem embalagem, não usado e completo: pendurar em saldos com 50% de desconto, riscar o código de barras a vermelho e aplicar as promoções de saldo elegíveis.") ]
    com [ modulo(m9), prioridade(85),
          conclusoes(['OUT-007'=saldos]),
          descricao("Pendurar em saldos, marcar com 50 por cento de desconto, riscar o código de barras a vermelho e aplicar as promoções de saldo elegíveis.") ].

regra 'PC-006 Baixa por dano do artigo com defeito de fabrico'
    se [ pedidoAtivo e elegibilidadeNaoRecusada e naoEAjustePreco e artigo(A)
         e naoBodywear(A) e defeitoFabricoConfirmado(A) e artigoAtivo(A) e semDestino(A) e artigoAceite(A) ]
    entao [ definir(artigo(A), destino, baixa_dano),
            registar(artigo(A), "Artigo com defeito de fabrico confirmado: dar baixa por dano.") ]
    com [ modulo(m9), prioridade(85),
          conclusoes(['OUT-007'=baixa_dano]),
          descricao("Dar baixa por dano ao artigo devolvido com defeito de fabrico confirmado.") ].

regra 'CT-008 Inspeção antes de devolver à área de vendas'
    se [ pedidoAtivo e elegibilidadeNaoRecusada e naoEAjustePreco e artigo(A)
         e naoBodywear(A) e semDefeito(A) e artigoAtivo(A) e semDestino(A)
         e naoDisparou(artigo(A), 'CT-008') e artigoAceite(A) ]
    entao [ calcular(destino_inspecao(A, Destino, Mensagem)),
            definir(artigo(A), destino, Destino),
            registar(artigo(A), Mensagem) ]
    com [ modulo(m9), prioridade(80),
          conclusoes(['OUT-007'=baixa_dano, 'OUT-007'=reetiquetar, 'OUT-007'=area_vendas]),
          descricao("Inspecionar o dano, as etiquetas de preço e a precisão do RFID antes de devolver o produto à área de vendas; só o produto vendável e corretamente preparado volta ao stock.") ].

regra 'EP-007 Artigo entre canais já em saldo'
    se [ pedidoAtivo e elegibilidadeNaoRecusada e naoEAjustePreco e artigo(A)
         e entreCanais(A) e emSaldo(A) e artigoAtivo(A) e semDestino(A)
         e inspecionado(A) e naoDisparou(artigo(A), 'EP-007') ]
    entao [ definir(artigo(A), destino, saldos),
            registar(artigo(A), "Artigo entre canais já em saldo: colocar em saldos com as promoções de saldo elegíveis atuais.") ]
    com [ modulo(m9), prioridade(70),
          conclusoes(['OUT-007'=saldos]),
          descricao("Colocar em saldos e aplicar as promoções de saldo elegíveis atuais: a mercadoria em saldo mantém-se em saldo. Avaliada antes de EP-006.") ].

regra 'EP-005 Artigo entre canais no sortido da loja recetora'
    se [ pedidoAtivo e elegibilidadeNaoRecusada e naoEAjustePreco e artigo(A)
         e entreCanais(A) e naoEmSaldo(A) e revendivelNaoNegado(A) e noSortidoDaLojaRecetora(A)
         e artigoAtivo(A) e semDestino(A) e inspecionado(A) e naoDisparou(artigo(A), 'EP-005') ]
    entao [ calcular(a(A, [produto, precoAtual], Preco)),
            definir(artigo(A), destino, area_vendas),
            registar(artigo(A), ["Artigo entre canais que está ou esteve no sortido da loja recetora: reprecificar ao preço de venda ",
                                 "atual da loja (", Preco, ") e devolver à área de vendas."]) ]
    com [ modulo(m9), prioridade(60),
          conclusoes(['OUT-007'=area_vendas]),
          descricao("Reprecificar ao preço de venda atual da loja recetora e devolver à área de vendas, se for vendável.") ].

regra 'EP-006 Artigo entre canais fora do sortido da loja recetora'
    se [ pedidoAtivo e elegibilidadeNaoRecusada e naoEAjustePreco e artigo(A)
         e entreCanais(A) e naoEmSaldo(A) e foraDoSortidoDaLojaRecetora(A)
         e artigoAtivo(A) e semDestino(A) e inspecionado(A) e naoDisparou(artigo(A), 'EP-006') ]
    entao [ calcular(decisao(artigo(A), valorDevolucao, Valor)),
            calcular(( Valor == null -> TextoValor = "" ; TextoValor = [" (", Valor, ")"] )),
            definir(artigo(A), destino, saldos),
            definir(artigo(A), descontoSaldo, 20),
            registar(artigo(A), ["Artigo entre canais fora do sortido da loja recetora: colocar em saldos com 20% de desconto sobre o ",
                                 "preço devolvido", TextoValor, ", combinável com as promoções elegíveis na loja."]) ]
    com [ modulo(m9), prioridade(60),
          conclusoes(['OUT-007'=saldos]),
          descricao("Colocar em saldos e marcar com 20 por cento de desconto sobre o preço devolvido, combinável com as promoções elegíveis na loja.") ].

regra 'OUT-001 Elegibilidade do pedido a partir dos artigos'
    se [ naoDisparou(pedido, 'OUT-001') e pedidoNaoSuspenso ]
    entao [ agregar_artigos ]
    com [ modulo(m9), prioridade(1),
          conclusoes(['OUT-001'=permitir, 'OUT-001'=rever, 'OUT-001'=encaminhar, 'OUT-001'=recusar, 'OUT-002'=nenhuma]),
          descricao("A elegibilidade do pedido é a mais severa entre a do pedido e as dos artigos; se todos os artigos forem recusados, não há transação [a validar: A-25].") ].

% =============================================================================================
% Funções usadas nos cálculos (lado direito), como as `function` do DRL
% =============================================================================================

descricao_indicio_relevante(Descricao) :-
    fraude(Descricao, Nivel),
    memberchk(Nivel, [significativo, confirmado]),
    !.

%!  aprovacao_minima(+Nivel, -Aprovacao) is det.
%
%   Mantém a escalada para District/Area (EX-008) se já existir; caso contrário usa Nivel.
aprovacao_minima(Nivel, Aprovacao) :-
    (   decisao(pedido, aprovacao, district_area)
    ->  Aprovacao = district_area
    ;   Aprovacao = Nivel
    ).

%!  valor_da_base(+Base, +ArtigoId, -Valor) is det.
valor_da_base(valor_pago, A, V) :- !, a(A, [precoPago], V).
valor_da_base(preco_atual, A, V) :- !, a(A, [produto, precoAtual], V).
valor_da_base(valor_pos, A, V) :- !, a(A, [valorCalculadoPos], V).
valor_da_base(_, _, null).

artigos_devolvidos(Total) :-
    p([artigos], Artigos),
    findall(Q, ( member(Art, Artigos), get_dict(quantidade, Art, Q) ), Qs),
    sum_list(Qs, Total).

%!  valor_total(-Total, -Base, -NumeroArtigos) is det.
%
%   Soma dos valores dos artigos elegíveis com valor; a base do pedido passa a ser a dos artigos
%   quando é comum a todos.
valor_total(Total, Base, N) :-
    findall(V-B,
            ( artigo(A),
              decisao(artigo(A), terminal, false),
              decisao(artigo(A), elegibilidade, E), condicoes:eleg_aceite(E),
              decisao(artigo(A), valorDevolucao, V), V \== null,
              decisao(artigo(A), baseValor, B)
            ),
            Pares),
    length(Pares, N),
    pairs_keys_values(Pares, Valores, Bases),
    sum_list(Valores, Total),
    sort(Bases, BasesDistintas),
    (   BasesDistintas = [Unica], Unica \== null
    ->  Base = Unica
    ;   decisao(pedido, baseValor, Base)
    ).

saldo_troca(Saldo) :-
    decisao(pedido, valorDevolucao, Valor),
    condicoes:preco_artigos_troca(Preco),
    Saldo is Valor - Preco.

nota_recibo(true, _, false, "O cliente manteve o recibo original.",
            "O cliente mantém o recibo original: anotar no exemplar da loja.") :- !.
nota_recibo(false, true, true, "O recibo original inclui outros artigos.",
            "Agrafar o recibo original ao exemplar da loja. O recibo inclui outros artigos: anotar no exemplar da loja.") :- !.
nota_recibo(false, false, true, null, "Agrafar o recibo original ao exemplar da loja.").

registo_excecao(Registo) :-
    p([pedidoExcecao, aprovador], Aprovador),
    (   Aprovador == null
    ->  TextoAprovador = "(por indicar)"
    ;   get_dict(nome, Aprovador, Nome),
        get_dict(funcao, Aprovador, Funcao),
        TextoAprovador = [Nome, " (", Funcao, ")"]
    ),
    p([pedidoExcecao, motivo], Motivo),
    p([pedidoExcecao, preocupacaoCliente], Preocupacao),
    decisao(pedido, valorDevolucao, Valor),
    ( Valor == null -> TextoValor = "(por determinar)" ; TextoValor = Valor ),
    decisao(pedido, tipoTransacao, Resultado),
    motor:texto_mensagem(["Motivo: ", Motivo, "; aprovador: ", TextoAprovador, "; valor: ", TextoValor,
                          "; resultado: ", Resultado, "; preocupação do cliente: ", Preocupacao,
                          "; destino do produto: ver o resultado por artigo (M9)."], Registo).

%!  destino_inspecao(+ArtigoId, -Destino, -Mensagem) is det.
%
%   CT-008: dano -> baixa por dano; artigo entre canais -> o destino segue EP-005/006/007;
%   etiqueta de preço ou RFID incorretos -> reetiquetar; caso contrário -> área de vendas.
destino_inspecao(A, Destino, Mensagem) :-
    a(A, [estado, danificado], Danificado),
    (   ( a(A, [estado, etiquetaPrecoCorreta], false) ; a(A, [estado, rfidCorreto], false) )
    ->  Reetiquetar = true
    ;   Reetiquetar = false
    ),
    (   Danificado == true
    ->  Destino = baixa_dano,
        Mensagem = "Inspeção: o artigo tem dano; dar baixa por dano."
    ;   condicoes:entreCanais(A)
    ->  Destino = null,
        ( Reetiquetar == true -> Corrigir = "; corrigir a etiqueta de preço e o RFID" ; Corrigir = "" ),
        atomics_to_string(["Inspeção sem dano", Corrigir,
                           ". Artigo entre canais: o destino segue EP-005, EP-006 ou EP-007."], Mensagem)
    ;   Reetiquetar == true
    ->  Destino = reetiquetar,
        Mensagem = "Inspeção: etiqueta de preço ou RFID incorretos; reetiquetar e corrigir o RFID antes de voltar à área de vendas."
    ;   Destino = area_vendas,
        Mensagem = "Inspeção conforme (sem dano, etiqueta de preço e RFID corretos): devolver à área de vendas."
    ).