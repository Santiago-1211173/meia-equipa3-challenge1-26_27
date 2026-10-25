:- encoding(utf8).
:- module(retail_rules, []).

/** <module> Official Retail Rules Knowledge Base (Levi's Returns & Exchanges)
 *
 * Implements the 71 canonical business rules distributed across 9 families:
 *   1. Hard Stops (HS-001 to HS-006)
 *   2. Product Condition (PC-001 to PC-008)
 *   3. Proof & Timeframe (PT-001 to PT-008)
 *   4. Channel & Store Type (CH-001 to CH-010)
 *   5. Refund Tender (TN-001 to TN-012)
 *   6. Exchange & Promotion (EP-001 to EP-007)
 *   7. Manager Review & Escalation (EX-001 to EX-008)
 *   8. Authorization & Controls (CT-001 to CT-008)
 *   9. Bodywear Disposition (BW-001 to BW-004)
 *
 * References:
 *   - RPAC-Team3.md (Knowledge Acquisition Report, Group 3)
 *   - Returns & Exchanges Knowledge Base.md (expert knowledge base written by the domain
 *     expert, D. Hopper, from the official Levi Strauss & Co. returns and exchanges policy)
 *   - MI_Perguntas_ACM.md (Expert System Metaknowledge & Dialogic Reasoning)
 */

:- use_module('../engine').
:- use_module('../uncertainty_cf', [
    combine_cf/3,
    accumulate_cf/2,
    manager_exception_advice/1
]).

:- dynamic facto/2.
:- dynamic ultimo_facto/1.
:- dynamic justifica/3.
:- dynamic (regra)/1.
:- dynamic facto_dispara_regras/2.
:- dynamic perguntavel/1.
:- dynamic ja_perguntado/1.
:- dynamic regra_ativa/2.
:- dynamic regra_info/3.
:- dynamic paragem_obrigatoria/1.
:- dynamic regra_transversal/1.
:- dynamic regra_a_validar/2.

% ==============================================================================
% Initial Fact Counter
% ==============================================================================
ultimo_facto(0).

% ==============================================================================
% Declarations of Askable Attributes (perguntavel/1)
% Observable by retail floor associates. Diagnostic conclusions are prohibited.
% ==============================================================================
perguntavel(colaborador_autorizado(_)).
perguntavel(mercado(_)).
perguntavel(tipo_loja(_)).
perguntavel(canal_compra(_)).
perguntavel(comprovativo(_)).
perguntavel(tipo_pedido(_)).
perguntavel(dias_desde_compra(_)).
perguntavel(dias_desde_envio(_)).
perguntavel(sku_reconhecido(_)).
perguntavel(marca(_)).
perguntavel(personalizado_ou_alterado(_)).
perguntavel(categoria_produto(_)).
perguntavel(estado_produto(_)).
perguntavel(defeito_fabrico(_)).
perguntavel(meio_pagamento(_)).
perguntavel(revendivel(_)).
perguntavel(encomenda_encontrada(_)).
perguntavel(portal_online_disponivel(_)).
perguntavel(cliente_fornece_dados(_)).
perguntavel(barreira_linguistica(_)).
perguntavel(troca_apenas_tamanho(_)).
perguntavel(cartao_perdido_ou_roubado(_)).
perguntavel(conta_cartao_ativa(_)).
perguntavel(tentativa_cartao_recusada(_)).
perguntavel(cartao_interac_presente(_)).
perguntavel(embalagem_intacta(_)).
perguntavel(pecas_em_falta(_)).
perguntavel(cliente_contesta(_)).
perguntavel(cliente_agitado(_)).
perguntavel(funcao_colaborador(_)).
perguntavel(sessao_pos_propria(_)).
perguntavel(stylist_venda_original(_)).
perguntavel(recibo_entregue(_)).
perguntavel(no_sortido(_)).
perguntavel(artigo_em_saldo(_)).
perguntavel(artigo_entre_canais(_)).
perguntavel(saldo_reembolsavel(_)).
perguntavel(afterpay_pede_excecao(_)).
perguntavel(promocao_escaloes(_)).
perguntavel(risco_fraude(_)).
perguntavel(concluivel_no_sistema(_)).
perguntavel(recibo_original(_)).

% ==============================================================================
% Metaknowledge: Indexing Facts to Candidate Rules (facto_dispara_regras/2)
% ==============================================================================
facto_dispara_regras(colaborador_autorizado(_), ['HS-006', 'CT-001', 'CT-003']).
facto_dispara_regras(recibo_original(_), ['PT-008', 'PT-008-SEM-RECIBO', 'PT-007', 'PT-007-FORA-LOJA']).
facto_dispara_regras(sku_reconhecido(_), ['HS-001', 'HS-004']).
facto_dispara_regras(marca(_), ['HS-002']).
facto_dispara_regras(personalizado_ou_alterado(_), ['HS-003']).
facto_dispara_regras(afterpay_pede_excecao(_), ['HS-005', 'EX-006-AFTERPAY']).
facto_dispara_regras(categoria_produto(_), ['PC-007', 'BW-001', 'BW-002', 'BW-003', 'BW-003-USADO', 'BW-004']).
% As variantes com a resposta (revenda, decisão da gestão) vêm antes da "pendente": no modo
% interativo a pergunta é feita primeiro e só sem resposta é que a regra fica em revisão.
facto_dispara_regras(estado_produto(_), ['PC-008', 'BW-004', 'BW-001', 'BW-002', 'BW-003', 'BW-003-USADO', 'PC-001', 'PC-002-REVENDIVEL', 'PC-002-NAO-REVENDIVEL', 'PC-002', 'PC-003-REVENDIVEL', 'PC-003-NAO-REVENDIVEL', 'PC-003', 'PC-004-APROVADO', 'PC-004-RECUSADO', 'PC-004', 'PC-005']).
facto_dispara_regras(revendivel(_), ['PC-002-REVENDIVEL', 'PC-002-NAO-REVENDIVEL', 'PC-003-REVENDIVEL', 'PC-003-NAO-REVENDIVEL', 'PT-004-NAO-REVENDIVEL']).
facto_dispara_regras(defeito_fabrico(_), ['PC-006']).
facto_dispara_regras(comprovativo(_), ['PT-001', 'PT-002', 'PT-008', 'PT-008-FOTO', 'PT-008-SEM-RECIBO']).
facto_dispara_regras(tipo_verificacao(_), ['PT-003', 'PT-004', 'PT-004-NAO-REVENDIVEL', 'PT-005', 'PT-006', 'PT-006-BARREIRA', 'PT-007', 'CH-009', 'CH-010', 'TN-001', 'TN-007', 'EP-001', 'EP-003', 'EP-004', 'CT-001', 'CT-002', 'CT-004']).
facto_dispara_regras(elegibilidade_produto(_), ['PT-003', 'PT-004', 'PT-005', 'CH-002', 'CH-003', 'CH-004', 'CH-004-AS-CEGAS', 'CH-005', 'CH-006', 'CH-009', 'CH-010', 'EP-001', 'EP-002', 'EP-003', 'EP-004', 'EP-005', 'EP-006', 'EP-007']).
facto_dispara_regras(dias_desde_compra(_), ['PT-003', 'PT-004', 'PT-004-NAO-REVENDIVEL', 'PT-007', 'PT-007-FORA-LOJA', 'PT-008']).
facto_dispara_regras(dias_desde_envio(_), ['CH-005']).
facto_dispara_regras(cliente_fornece_dados(_), ['PT-006', 'PT-006-BARREIRA']).
facto_dispara_regras(barreira_linguistica(_), ['PT-006-BARREIRA']).
facto_dispara_regras(tipo_pedido(_), ['PT-007-AJUSTE-ANTERIOR', 'PT-007', 'PT-007-FORA-LOJA', 'PT-008', 'PT-008-SEM-RECIBO', 'PT-008-FOTO', 'CH-006', 'TN-001', 'TN-006', 'TN-007', 'EP-001', 'EP-002']).
facto_dispara_regras(ajuste_preco_anterior(_), ['PT-007-AJUSTE-ANTERIOR']).
facto_dispara_regras(canal_compra(_), ['CH-008', 'CH-007', 'HS-004', 'CH-001', 'CH-002', 'CH-003', 'CH-003-NAO-PERMITIDA', 'CH-004', 'CH-004-AS-CEGAS', 'CH-005', 'CH-006', 'TN-009', 'TN-010', 'TN-012', 'PT-007']).
facto_dispara_regras(tipo_loja(_), ['CH-001', 'CH-009', 'CH-010']).
facto_dispara_regras(encomenda_encontrada(_), ['CH-002', 'CH-003', 'CH-003-NAO-PERMITIDA', 'CH-004', 'CH-004-AS-CEGAS']).
facto_dispara_regras(portal_online_disponivel(_), ['CH-002', 'CH-004', 'CH-004-AS-CEGAS']).
facto_dispara_regras(politica_permite_as_cegas_online(_), ['CH-003', 'CH-004-AS-CEGAS']).
facto_dispara_regras(meio_pagamento(_), ['HS-005', 'TN-001', 'TN-002', 'TN-003', 'TN-004', 'TN-005', 'TN-008', 'TN-008-SEM-APP', 'TN-009', 'TN-010', 'TN-011', 'TN-011-SEM-CARTAO', 'TN-012']).
facto_dispara_regras(acesso_aplicacao_pagamento(_), ['TN-008-SEM-APP']).
facto_dispara_regras(cartao_perdido_ou_roubado(_), ['TN-002']).
facto_dispara_regras(conta_cartao_ativa(_), ['TN-002', 'TN-003']).
facto_dispara_regras(tentativa_cartao_recusada(_), ['TN-003', 'TN-004']).
facto_dispara_regras(saldo_reembolsavel(_), ['TN-006']).
facto_dispara_regras(mercado(_), ['TN-011', 'TN-011-SEM-CARTAO', 'TN-012']).
facto_dispara_regras(cartao_interac_presente(_), ['TN-011', 'TN-011-SEM-CARTAO', 'TN-012']).
facto_dispara_regras(troca_apenas_tamanho(_), ['EP-001', 'EP-002']).
facto_dispara_regras(promocao_escaloes(_), ['EP-003', 'EP-004']).
facto_dispara_regras(artigo_entre_canais(_), ['EP-005', 'EP-006', 'EP-007']).
facto_dispara_regras(no_sortido(_), ['EP-005', 'EP-006']).
facto_dispara_regras(artigo_em_saldo(_), ['EP-007']).
facto_dispara_regras(decisao(_), ['EX-001', 'CH-002-EM-REVISAO']).
facto_dispara_regras(cliente_contesta(_), ['EX-002']).
facto_dispara_regras(cliente_agitado(_), ['EX-003']).
facto_dispara_regras(aprovacao(_), ['EX-004']).
facto_dispara_regras(excecao_autorizavel(_), ['EX-005']).
facto_dispara_regras(tentativa_excecao(_), ['EX-006', 'EX-006-AFTERPAY']).
facto_dispara_regras(excecao_contorna_controlo(_), ['EX-006']).
facto_dispara_regras(excecao_aprovada(_), ['EX-007', 'PC-004-APROVADO', 'PC-004-RECUSADO']).
facto_dispara_regras(risco_fraude(_), ['EX-008', 'EX-004']).
facto_dispara_regras(funcao_colaborador(_), ['CT-002']).
facto_dispara_regras(sessao_pos_propria(_), ['CT-003']).
facto_dispara_regras(stylist_venda_original(_), ['CT-004']).
facto_dispara_regras(transacao_concluida(_), ['CT-005', 'CT-006', 'CT-007']).
facto_dispara_regras(recibo_entregue(_), ['CT-006']).
facto_dispara_regras(destino_produto(_), ['CT-008']).
facto_dispara_regras(embalagem_intacta(_), ['BW-001', 'BW-002']).
facto_dispara_regras(pecas_em_falta(_), ['BW-002', 'BW-003']).

% ==============================================================================
% Metaknowledge: Hard-Stop Precedence and Inference Control (RPAC 4.6)
% ==============================================================================
% Terminal hard stops, in precedence order (HS-006 → CH-008/CH-007 → HS-001..004).
% HS-004 is a specialisation of CH-007 (franchise product without a recognised
% SKU) with the same conclusion, so it is tried just before CH-007 (specificity).
% Once one fires the inference stops: only the transversal rules below may still
% fire. HS-005 is not terminal — it only refuses the Afterpay method exception.
paragem_obrigatoria('HS-006').
paragem_obrigatoria('CH-008').
paragem_obrigatoria('HS-004').
paragem_obrigatoria('CH-007').
paragem_obrigatoria('HS-001').
paragem_obrigatoria('HS-002').
paragem_obrigatoria('HS-003').

% Transversal safety and customer-handling rules, which apply regardless of the
% outcome (biohazard isolation, fraud escalation, customer dispute/agitation).
regra_transversal('PC-008').
regra_transversal('BW-004').
regra_transversal('EX-008').
regra_transversal('EX-002').
regra_transversal('EX-003').

% ==============================================================================
% Metaknowledge: Interpretations Still to Validate with the Expert (ADR 0003)
% ==============================================================================
% The same "[a validar: A-xx]" marks as the matching Drools rules, per variant. The
% engine reports the visible code of each fired rule here as regras_a_validar.
regra_a_validar('HS-006', ['A-23']).
regra_a_validar('CH-007', ['A-07']).
regra_a_validar('PC-002', ['A-19']).
regra_a_validar('PC-002-REVENDIVEL', ['A-19']).
regra_a_validar('PC-003', ['A-19']).
regra_a_validar('PC-003-REVENDIVEL', ['A-19']).
regra_a_validar('PC-004', ['A-18', 'A-19', 'A-29']).
regra_a_validar('PC-004-APROVADO', ['A-18', 'A-29']).
regra_a_validar('PC-004-RECUSADO', ['A-18', 'A-29']).
regra_a_validar('PC-008', ['A-15', 'A-28']).
regra_a_validar('PT-003', ['A-22']).
regra_a_validar('PT-004', ['A-17', 'A-19']).
regra_a_validar('PT-005', ['A-13', 'A-16']).
regra_a_validar('PT-007-AJUSTE-ANTERIOR', ['A-14']).
regra_a_validar('PT-007-FORA-LOJA', ['A-14']).
regra_a_validar('PT-008', ['A-14']).
regra_a_validar('PT-008-SEM-RECIBO', ['A-14']).
regra_a_validar('PT-008-FOTO', ['A-14']).
regra_a_validar('CH-003', ['A-03']).
regra_a_validar('CH-003-NAO-PERMITIDA', ['A-03']).
regra_a_validar('CH-004', ['A-04']).
regra_a_validar('CH-005', ['A-05', 'A-06', 'A-22']).
regra_a_validar('CH-010', ['A-21']).
regra_a_validar('TN-004', ['A-11']).
regra_a_validar('TN-007', ['A-12']).
regra_a_validar('TN-008-SEM-APP', ['A-05']).
regra_a_validar('TN-011-SEM-CARTAO', ['A-10']).
regra_a_validar('EP-003', ['A-21', 'A-30']).
regra_a_validar('EX-004', ['A-18']).
regra_a_validar('EX-008', ['A-26']).

% ==============================================================================
% Rule Metadata (regra_info/3)
% ==============================================================================
regra_info('HS-001', hs, "Recusar quando o produto não tem SKU reconhecido no sistema POS.").
regra_info('HS-002', hs, "Recusar marcas excluídas (Dockers, LS Signature, Beyond Yoga ou grossista não vendido).").
regra_info('HS-003', hs, "Recusar produtos personalizados, alterados ou embainhados.").
regra_info('HS-004', hs, "Encaminhar para processo próprio da franquia canadiana sem usar SKU genérico.").
regra_info('HS-005', hs, "Recusar a exceção ao meio de reembolso de compra online Afterpay e reembolsar através da Afterpay.").
regra_info('HS-006', hs, "Encaminhar transação quando colaborador não possui credenciais autorizadas.").

regra_info('PC-001', pc, "Permitir elegibilidade para artigo não usado com etiquetas originais intactas.").
regra_info('PC-002', pc, "Rever com gestão artigo não usado com etiquetas soltas; aprovar só se vendável.").
regra_info('PC-003', pc, "Rever com gestão artigo não usado sem etiquetas; aprovar só se preparável para venda.").
regra_info('PC-004', pc, "Rever com gestão artigo usado sem defeito; aprovar apenas troca pelo mesmo artigo.").
regra_info('PC-005', pc, "Recusar artigo lavado sem defeito de fabrico.").
regra_info('PC-006', pc, "Permitir reembolso ou substituição com baixa por dano para defeito de fabrico.").
regra_info('PC-007', pc, "Permitir bodywear em qualquer estado ao abrigo da política de satisfação.").
regra_info('PC-008', pc, "Isolar em saco de risco biológico artigos sujos, contaminados ou inseguros; não revender.").

regra_info('PT-001', pt, "Classificar como devolução verificada quando comprovativo válido confirma a compra.").
regra_info('PT-002', pt, "Classificar como devolução às cegas na ausência de comprovativo verificável.").
regra_info('PT-003', pt, "Permitir reembolso total no meio original ou troca para devolução verificada até 30 dias.").
regra_info('PT-004', pt, "Rever com gestão devolução verificada após 30 dias; crédito de loja sob critério.").
regra_info('PT-005', pt, "Permitir exclusivamente troca ou crédito de loja ao preço atual para devolução às cegas.").
regra_info('PT-006', pt, "Selecionar 'Saltar' se cliente sem recibo não fornece dados ou há barreira linguística.").
regra_info('PT-007', pt, "Permitir ajuste de preço único no POS até 14 dias para compra em loja com recibo.").
regra_info('PT-008', pt, "Recusar ajuste de preço após 14 dias ou sem recibo original.").
regra_info('PT-008-SEM-RECIBO', pt, "Recusar ajuste de preço sem recibo original físico.").
regra_info('PT-008-FOTO', pt, "Recusar ajuste de preço com fotografia de recibo sem recibo original.").

regra_info('CH-001', ch, "Aplicar regras de comprovativo e avaliação da loja recetora para Mainline e Outlet.").
regra_info('CH-002', ch, "Encaminhar compra online verificada através da BackPocket com reembolso original.").
regra_info('CH-003', ch, "Encomenda online não encontrada: às cegas com cartão de oferta se a política o permitir; senão recusar.").
regra_info('CH-004', ch, "Portal online indisponível: devolução às cegas permitida no meio de pagamento original.").
regra_info('CH-005', ch, "Emitir cartão de oferta para devolução online expedida há mais de 30 dias.").
regra_info('CH-006', ch, "Concluir troca online e estornar saldo remanescente ao meio de pagamento original.").
regra_info('CH-007', ch, "Encaminhar produto da franquia do Canadá para processo próprio com SKU de franquia.").
regra_info('CH-008', ch, "Recusar produto de grossista e encaminhar cliente para retalhista original.").
regra_info('CH-009', ch, "Calcular valor de devolução às cegas em Outlet pelo preço atual com promoções ativas.").
regra_info('CH-010', ch, "Devolução com recibo de Mainline/Online em Outlet ao PVP original quando permitido.").

regra_info('TN-001', tn, "Reembolso automático tokenizado em cartão de crédito/débito sem pedir cartão físico.").
regra_info('TN-002', tn, "Reembolso automático para conta bancária associada se cartão foi perdido/roubado.").
regra_info('TN-003', tn, "Permitir meio alternativo se conta do cartão estiver encerrada e estorno recusado.").
regra_info('TN-004', tn, "Proibir estorno em numerário para débito sem tentativa e recusa prévia do cartão.").
regra_info('TN-005', tn, "Reembolso automático para conta associada em compras contactless (Apple/Google Pay).").
regra_info('TN-006', tn, "Estornar saldo remanescente ao cartão original após troca parcial.").
regra_info('TN-007', tn, "Devolução de oferta: crédito de loja ao portador ou estorno ao comprador original.").
regra_info('TN-008', tn, "Exigir fluxo da aplicação para compras efetuadas via PayPal ou Venmo.").
regra_info('TN-009', tn, "Processar devolução Afterpay de loja através da app com talão de devolução do POS.").
regra_info('TN-010', tn, "Processar compra online Afterpay na BackPocket para o método original sem exceções.").
regra_info('TN-011', tn, "Exigir presença do cartão físico Interac no Canadá para estorno de débito.").
regra_info('TN-011-SEM-CARTAO', tn, "Rever com chefia sénior Interac no Canadá sem cartão físico original.").
regra_info('TN-012', tn, "Processar Interac BackPocket com estorno manual na VeriFone pelo valor exato.").

regra_info('EP-001', ep, "Honrar preço original ou promocional em troca com recibo que altera apenas o tamanho.").
regra_info('EP-002', ep, "Tratar troca com alteração de modelo ou cor como devolução seguida de nova venda.").
regra_info('EP-003', ep, "Devolução às cegas em promoção por escalões avaliada pela quantidade devolvida na sessão.").
regra_info('EP-004', ep, "Devolução com recibo em promoção por escalões calculada pelo POS com base na quantidade original.").
regra_info('EP-005', ep, "Reprecificar ao valor atual e retornar à área de vendas artigo entre canais no sortido.").
regra_info('EP-006', ep, "Colocar em saldos com 20% de desconto sobre preço devolvido artigo fora do sortido.").
regra_info('EP-007', ep, "Manter em saldos com promoções ativas artigo entre canais já em liquidação.").

regra_info('EX-001', ex, "Critério da gestão avalia vendabilidade, comprovativo, tempo, risco e circunstâncias.").
regra_info('EX-002', ex, "Explicar política e oferecer melhor alternativa regulamentar perante contestação.").
regra_info('EX-003', ex, "Escalar para responsável sénior perante cliente agitado; agitação não cria direito.").
regra_info('EX-004', ex, "Autorizar exceção de apaziguamento apenas sem hard stops, baixo risco e sistema apto.").
regra_info('EX-005', ex, "Adotar resolução menos abrangente para exceção aprovada em artigo vendável.").
regra_info('EX-006', ex, "Recusar a exceção que exija meio proibido, SKU incorreto, produto excluído ou contornar Afterpay, PayPal, Venmo ou o processo online.").
regra_info('EX-007', ex, "Documentar formalmente motivo, aprovador, valor e destino de exceção autorizada.").
regra_info('EX-008', ex, "Pausar transação, envolver gestão e reportar à Segurança perante indícios de fraude.").

regra_info('CT-001', ct, "Devolução verificada conduzida por colaborador autorizado com credenciais próprias.").
regra_info('CT-002', ct, "Devolução às cegas por Lead Cashier ou Elevated Stylist requer aprovação do XStore Manager.").
regra_info('CT-003', ct, "Mesmo colaborador conclui transação do início ao fim com as suas próprias credenciais.").
regra_info('CT-004', ct, "Atribuir devolução com recibo ao Stylist responsável pela venda original.").
regra_info('CT-005', ct, "Recolher assinaturas obrigatórias do cliente, operador e testemunha/SSC.").
regra_info('CT-006', ct, "Agrafar recibo original entregue ou anotar na cópia de loja se cliente retiver.").
regra_info('CT-007', ct, "Reter suporte de loja e assinaturas durante 90 dias em arquivo regulamentar.").
regra_info('CT-008', ct, "Inspecionar danos, etiquetas de preço e precisão RFID antes de repor em área de vendas.").

regra_info('BW-001', bw, "Retornar à área de vendas bodywear não usado com embalagem original intacta.").
regra_info('BW-002', bw, "Colocar em saldos com 50% de desconto e código riscado a vermelho bodywear sem embalagem.").
regra_info('BW-003', bw, "Baixa por dano do conjunto completo se bodywear tiver unidades em falta ou foi usado.").
regra_info('BW-004', bw, "Isolar imediatamente em saco de risco biológico bodywear usado e sujo ou contaminado.").

% ==============================================================================
% 1. FAMÍLIA HS: HARD STOPS (PARAGENS OBRIGATÓRIAS)
% ==============================================================================

% HS-006: Pré-condição de autorização do colaborador (Precedência 1)
regra 'HS-006' se [colaborador_autorizado(false)]
               entao [cria_facto(decisao(encaminhar)),
                      cria_facto(aprovacao(responsavel_senior)),
                      cria_facto(regra_disparada('HS-006')),
                      cria_facto(motivo("[HS-006] Colaborador não autorizado a processar devoluções ou trocas: encaminhar para Gestão da Loja, Key Holder, Lead Cashier ou Elevated Stylist aprovado."))].

% HS-001: SKU não reconhecido no sistema POS (Precedência 3)
regra 'HS-001' se [sku_reconhecido(false) e nao canal_compra(franquia_canada)]
               entao [cria_facto(decisao(recusar)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(regra_disparada('HS-001')),
                      cria_facto(motivo("[HS-001] SKU não reconhecido no sistema POS: recusar devolução e troca. É obrigatório um SKU de produto válido."))].

% HS-002: Marcas excluídas da rede Levi's (Precedência 3)
regra 'HS-002' se [avalia(marca(in, [dockers, signature, beyond_yoga, grossista_nao_vendido]))]
               entao [cria_facto(decisao(recusar)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(regra_disparada('HS-002')),
                      cria_facto(motivo("[HS-002] Marca excluída: Dockers, Levi Strauss Signature, Beyond Yoga ou grossista não vendido não são aceites em lojas Levi's."))].

% HS-003: Peças alteradas, embainhadas ou personalizadas (Precedência 3)
regra 'HS-003' se [personalizado_ou_alterado(true)]
               entao [cria_facto(decisao(recusar)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(destino_produto(devolver_cliente)),
                      cria_facto(regra_disparada('HS-003')),
                      cria_facto(motivo("[HS-003] Produto personalizado, alterado ou embainhado não é elegível para devolução ou troca, mesmo que apresente defeito."))].

% HS-004: Produto da franquia canadiana sem SKU de franquia (Precedência 3)
regra 'HS-004' se [sku_reconhecido(false) e canal_compra(franquia_canada)]
               entao [cria_facto(decisao(encaminhar)),
                      cria_facto(processo_obrigatorio(franquia_canada)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(regra_disparada('HS-004')),
                      cria_facto(motivo("[HS-004] Não usar SKU diferente ou genérico para produto da franquia do Canadá: encaminhar para o processo próprio da franquia."))].

% HS-005: Proibição estrita de exceções de meio de reembolso com Afterpay. Recusa a exceção, não a
% devolução: o reembolso segue pela Afterpay para o método original (como o Drools, excecaoRecusada).
regra 'HS-005' se [meio_pagamento(afterpay) e afterpay_pede_excecao(true)]
               entao [cria_facto(excecao_recusada(true)),
                      cria_facto(processo_obrigatorio(afterpay_app)),
                      cria_facto(regra_disparada('HS-005')),
                      cria_facto(motivo("[HS-005] Exceções de meio para devolução online Afterpay são proibidas: recusar a exceção e reembolsar exclusivamente através da Afterpay no método original."))].

% ==============================================================================
% 2. FAMÍLIA PC: PRODUCT CONDITION (ESTADO FÍSICO DO PRODUTO)
% ==============================================================================

% PC-008: Risco biológico / insalubridade (Precedência 4 - isolamento de risco biológico).
% Só define o manuseamento e o destino: a elegibilidade continua a ser decidida pelo estado de uso
% da peça (o orquestrador envia também esse estado), como no Drools.
regra 'PC-008' se [estado_produto(sujo_contaminado_inseguro)]
               entao [cria_facto(destino_produto(isolamento_risco_biologico)),
                      cria_facto(regra_disparada('PC-008')),
                      cria_facto(motivo("[PC-008] Artigo sujo, contaminado ou inseguro: isolar imediatamente em saco de risco biológico e cessar manuseamento normal."))].

% PC-007: Bodywear aceite em qualquer estado (Precedência 5 - antes de PC-001 a PC-005)
regra 'PC-007' se [categoria_produto(bodywear) e nao decisao(recusar)]
               entao [cria_facto(elegibilidade_produto(aprovada)),
                      cria_facto(regra_disparada('PC-007')),
                      cria_facto(motivo("[PC-007] Bodywear aceite em qualquer estado ao abrigo da política de satisfação incondicional. Destino determinado pelas regras BW."))].

% PC-006: Defeito de fabrico confirmado em peça não alterada (Precedência 5)
regra 'PC-006' se [defeito_fabrico(true) e nao personalizado_ou_alterado(true) e nao decisao(recusar)]
               entao [cria_facto(elegibilidade_produto(aprovada)),
                      cria_facto(destino_produto(baixa_dano)),
                      cria_facto(processo_obrigatorio(baixa_dano)),
                      cria_facto(regra_disparada('PC-006')),
                      cria_facto(motivo("[PC-006] Defeito de fabrico confirmado em peça não alterada: permitir reembolso ou substituição com baixa por dano do artigo devolvido."))].

% PC-001: Não usado com etiquetas originais afixadas
regra 'PC-001' se [estado_produto(nao_usado_com_etiquetas) e nao categoria_produto(bodywear) e nao personalizado_ou_alterado(true) e nao decisao(recusar)]
               entao [cria_facto(elegibilidade_produto(aprovada)),
                      cria_facto(regra_disparada('PC-001')),
                      cria_facto(motivo("[PC-001] Artigo não usado em estado original com etiquetas afixadas: produto com condição física elegível."))].

% PC-002 e PC-003 dependem da possibilidade de revenda (IN-010, revendivel/1): por avaliar → rever;
% revendível → produto elegível (aprovado pela gestão); não revendível → recusar. PC-004 depende da
% decisão da gestão (excecao_aprovada/1): pendente → rever; aprovada → só troca pelo mesmo artigo;
% recusada → recusar. Como no Drools, cada regra tem três variantes; todas registam o mesmo código.
% Com defeito de fabrico confirmado nenhuma se aplica: prevalece PC-006 (RPAC, Figura 3).

% PC-002: Não usado com etiquetas soltas — revenda por avaliar
regra 'PC-002' se [estado_produto(nao_usado_etiquetas_soltas) e nao defeito_fabrico(true) e nao categoria_produto(bodywear) e nao revendivel(true) e nao revendivel(false) e nao decisao(recusar)]
               entao [cria_facto(decisao(rever)),
                      cria_facto(aprovacao(gestor_xstore)),
                      cria_facto(regra_disparada('PC-002')),
                      cria_facto(motivo("[PC-002] Não usado com etiquetas soltas: rever com a gestão. Aprovar apenas se a peça puder ser verificada, reetiquetada e revendida (falta avaliar a revenda, IN-010)."))].

% PC-002: Não usado com etiquetas soltas — revendível
regra 'PC-002-REVENDIVEL' se [estado_produto(nao_usado_etiquetas_soltas) e nao defeito_fabrico(true) e nao categoria_produto(bodywear) e revendivel(true) e nao decisao(recusar)]
               entao [cria_facto(elegibilidade_produto(aprovada)),
                      cria_facto(aprovacao(gestor_xstore)),
                      cria_facto(regra_disparada('PC-002')),
                      cria_facto(motivo("[PC-002] Etiquetas soltas, artigo verificável, reetiquetável e revendível: aprovado pela gestão."))].

% PC-002: Não usado com etiquetas soltas — não revendível
regra 'PC-002-NAO-REVENDIVEL' se [estado_produto(nao_usado_etiquetas_soltas) e nao defeito_fabrico(true) e nao categoria_produto(bodywear) e revendivel(false) e nao decisao(recusar)]
               entao [cria_facto(decisao(recusar)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(regra_disparada('PC-002')),
                      cria_facto(motivo("[PC-002] Etiquetas soltas e o artigo não pode ser verificado, reetiquetado e revendido: recusar."))].

% PC-003: Não usado sem etiquetas — revenda por avaliar
regra 'PC-003' se [estado_produto(nao_usado_sem_etiquetas) e nao defeito_fabrico(true) e nao categoria_produto(bodywear) e nao revendivel(true) e nao revendivel(false) e nao decisao(recusar)]
               entao [cria_facto(decisao(rever)),
                      cria_facto(aprovacao(gestor_xstore)),
                      cria_facto(regra_disparada('PC-003')),
                      cria_facto(motivo("[PC-003] Não usado sem etiquetas: rever com a gestão. Aprovar apenas se puder ser preparado para revenda; caso contrário recusar (falta avaliar a revenda, IN-010)."))].

% PC-003: Não usado sem etiquetas — revendível
regra 'PC-003-REVENDIVEL' se [estado_produto(nao_usado_sem_etiquetas) e nao defeito_fabrico(true) e nao categoria_produto(bodywear) e revendivel(true) e nao decisao(recusar)]
               entao [cria_facto(elegibilidade_produto(aprovada)),
                      cria_facto(aprovacao(gestor_xstore)),
                      cria_facto(regra_disparada('PC-003')),
                      cria_facto(motivo("[PC-003] Sem etiquetas, artigo verificável e preparável para revenda: aprovado pela gestão."))].

% PC-003: Não usado sem etiquetas — não revendível
regra 'PC-003-NAO-REVENDIVEL' se [estado_produto(nao_usado_sem_etiquetas) e nao defeito_fabrico(true) e nao categoria_produto(bodywear) e revendivel(false) e nao decisao(recusar)]
               entao [cria_facto(decisao(recusar)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(regra_disparada('PC-003')),
                      cria_facto(motivo("[PC-003] Sem etiquetas e o artigo não pode ser verificado nem preparado para revenda: recusar."))].

% PC-004: Claramente usado sem defeito — decisão da gestão pendente
regra 'PC-004' se [estado_produto(claramente_usado) e nao defeito_fabrico(true) e nao categoria_produto(bodywear) e nao excecao_aprovada(true) e nao excecao_aprovada(false) e nao decisao(recusar)]
               entao [cria_facto(decisao(rever)),
                      cria_facto(tipo_transacao(troca_mesmo_artigo)),
                      cria_facto(aprovacao(gestor_xstore)),
                      cria_facto(regra_disparada('PC-004')),
                      cria_facto(motivo("[PC-004] Artigo claramente usado sem defeito: recusar reembolso. Gestão pode aprovar apenas troca pelo mesmo artigo, sem numerário nem crédito irrestrito."))].

% PC-004: Claramente usado sem defeito — a gestão aprovou a troca pelo mesmo artigo
regra 'PC-004-APROVADO' se [estado_produto(claramente_usado) e nao defeito_fabrico(true) e nao categoria_produto(bodywear) e excecao_aprovada(true) e nao decisao(recusar)]
               entao [cria_facto(elegibilidade_produto(aprovada)),
                      cria_facto(tipo_transacao(troca_mesmo_artigo)),
                      cria_facto(aprovacao(gestor_xstore)),
                      cria_facto(regra_disparada('PC-004')),
                      cria_facto(motivo("[PC-004] Artigo usado: a gestão aprovou apenas uma troca pelo mesmo artigo, sem numerário nem crédito de loja."))].

% PC-004: Claramente usado sem defeito — a gestão recusou
regra 'PC-004-RECUSADO' se [estado_produto(claramente_usado) e nao defeito_fabrico(true) e nao categoria_produto(bodywear) e excecao_aprovada(false) e nao decisao(recusar)]
               entao [cria_facto(decisao(recusar)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(regra_disparada('PC-004')),
                      cria_facto(motivo("[PC-004] Artigo usado e a gestão não aprovou a troca pelo mesmo artigo: recusar o reembolso."))].

% PC-005: Lavado sem defeito de fabrico
regra 'PC-005' se [estado_produto(lavado) e nao defeito_fabrico(true) e nao categoria_produto(bodywear) e nao decisao(recusar)]
               entao [cria_facto(decisao(recusar)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(destino_produto(devolver_cliente)),
                      cria_facto(regra_disparada('PC-005')),
                      cria_facto(motivo("[PC-005] Produto lavado sem defeito de fabrico: recusar devolução e troca. O artigo lavado não é vendável."))].

% ==============================================================================
% 3. FAMÍLIA PT: PROOF & TIMEFRAME (COMPROVATIVOS E PRAZOS)
% ==============================================================================

% PT-001: Comprovativo válido confirma a compra em loja física
regra 'PT-001' se [avalia(comprovativo(in, [recibo_impresso, recibo_digital, confirmacao_encomenda, recibo_oferta, consulta_transacao, foto_recibo, consulta_backpocket])) e nao canal_compra(levi_com) e nao canal_compra(levi_ca)]
               entao [cria_facto(tipo_verificacao(verificada)),
                      cria_facto(tem_comprovativo(true)),
                      cria_facto(regra_disparada('PT-001')),
                      cria_facto(motivo("[PT-001] Comprovativo válido confirma a compra: devolução verificada."))].

% PT-002: Compra não verificável: devolução às cegas
regra 'PT-002' se [comprovativo(nenhum) e nao tipo_pedido(ajuste_preco) e nao canal_compra(levi_com) e nao canal_compra(levi_ca)]
               entao [cria_facto(tipo_verificacao(as_cegas)),
                      cria_facto(tem_comprovativo(false)),
                      cria_facto(regra_disparada('PT-002')),
                      cria_facto(motivo("[PT-002] Não é possível verificar a compra: processar como devolução às cegas se o artigo for elegível."))].

% PT-003: Devolução verificada elegível até 30 dias (Precedência 6)
regra 'PT-003' se [tipo_verificacao(verificada) e elegibilidade_produto(aprovada) e avalia(dias_desde_compra(=<, 30)) e nao tipo_pedido(ajuste_preco) e nao decisao(recusar) e nao decisao(encaminhar) e nao decisao(rever)]
               entao [cria_facto(decisao(permitir)),
                      cria_facto(tipo_transacao(reembolso_ou_troca)),
                      cria_facto(valor_devolucao(valor_pago)),
                      cria_facto(meio_reembolso(meio_original)),
                      cria_facto(regra_disparada('PT-003')),
                      cria_facto(motivo("[PT-003] Devolução verificada elegível até 30 dias: permitir reembolso total no meio original ou troca elegível."))].

% PT-004: Devolução verificada após 30 dias (Precedência 6) — rever; a gestão pode aprovar crédito de loja
regra 'PT-004' se [tipo_verificacao(verificada) e elegibilidade_produto(aprovada) e avalia(dias_desde_compra(>, 30)) e nao revendivel(false) e nao tipo_pedido(ajuste_preco) e nao decisao(recusar) e nao decisao(encaminhar)]
               entao [cria_facto(decisao(rever)),
                      cria_facto(aprovacao(gestor_xstore)),
                      cria_facto(meio_reembolso(credito_loja)),
                      cria_facto(regra_disparada('PT-004')),
                      cria_facto(motivo("[PT-004] Devolução verificada com mais de 30 dias: rever com a gestão. Crédito de loja pode ser aprovado se vendável e baixo risco."))].

% PT-004: "Otherwise DENY" — depois de 30 dias e o artigo não é vendável (IN-010 = não), também quando o
% artigo ainda estava em revisão por outra regra (como o Drools)
regra 'PT-004-NAO-REVENDIVEL' se [tipo_verificacao(verificada) e avalia(dias_desde_compra(>, 30)) e revendivel(false) e nao tipo_pedido(ajuste_preco) e nao avalia(canal_compra(in, [levi_com, levi_ca])) e nao decisao(recusar)]
               entao [cria_facto(decisao(recusar)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(regra_disparada('PT-004')),
                      cria_facto(motivo("[PT-004] Devolução verificada com mais de 30 dias e o artigo não é vendável: recusar."))].

% PT-005: Devolução às cegas com artigo elegível (Precedência 6)
regra 'PT-005' se [tipo_verificacao(as_cegas) e elegibilidade_produto(aprovada) e nao tipo_pedido(ajuste_preco) e nao decisao(recusar) e nao decisao(encaminhar)]
               entao [cria_facto(decisao(permitir)),
                      cria_facto(tipo_transacao(troca_ou_credito)),
                      cria_facto(valor_devolucao(preco_atual)),
                      cria_facto(meio_reembolso(credito_loja)),
                      cria_facto(regra_disparada('PT-005')),
                      cria_facto(motivo("[PT-005] Devolução às cegas com produto elegível: permitir exclusivamente troca ou crédito de loja ao preço de venda atual."))].

% PT-006: Cliente sem recibo recusa dados ou barreira linguística
regra 'PT-006' se [tipo_verificacao(as_cegas) e cliente_fornece_dados(false)]
               entao [cria_facto(processo_acao(selecionar_saltar)),
                      cria_facto(regra_disparada('PT-006')),
                      cria_facto(motivo("[PT-006] Cliente sem recibo recusa fornecer dados ou há barreira linguística: selecionar 'Saltar' e prosseguir a devolução às cegas."))].

% PT-006: a mesma regra pela barreira linguística (no Drools: forneceDados == false || barreiraLinguistica == true)
regra 'PT-006-BARREIRA' se [tipo_verificacao(as_cegas) e nao regra_disparada('PT-006') e barreira_linguistica(true)]
               entao [cria_facto(processo_acao(selecionar_saltar)),
                      cria_facto(regra_disparada('PT-006')),
                      cria_facto(motivo("[PT-006] Cliente sem recibo com barreira linguística: selecionar 'Saltar' e prosseguir a devolução às cegas, sem pressionar o cliente a dar dados pessoais."))].

% PT-007: Ajuste de preço de compra em loja até 14 dias com recibo original (impresso ou digital,
% IN-004), uma única vez por compra
regra 'PT-007' se [tipo_pedido(ajuste_preco) e avalia(canal_compra(in, [mainline, outlet, loja_fisica])) e tipo_verificacao(verificada) e recibo_original(true) e avalia(dias_desde_compra(=<, 14)) e nao ajuste_preco_anterior(true)]
               entao [cria_facto(decisao(permitir)),
                      cria_facto(tipo_transacao(ajuste_preco)),
                      cria_facto(valor_devolucao(diferenca_pos)),
                      cria_facto(regra_disparada('PT-007')),
                      cria_facto(motivo("[PT-007] Ajuste de preço de compra em loja até 14 dias com recibo original: permitir ajuste único pela diferença calculada pelo POS."))].

% PT-007: O ajuste de 14 dias é único — já foi aplicado a esta compra
regra 'PT-007-AJUSTE-ANTERIOR' se [tipo_pedido(ajuste_preco) e ajuste_preco_anterior(true) e nao decisao(recusar)]
               entao [cria_facto(decisao(recusar)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(regra_disparada('PT-007')),
                      cria_facto(motivo("[PT-007] Já foi aplicado um ajuste de preço a esta compra: o ajuste de 14 dias é único; recusar."))].

% PT-007: Só cobre compras em loja; o ajuste de compras online ou BackPocket não está previsto
regra 'PT-007-FORA-LOJA' se [tipo_pedido(ajuste_preco) e nao avalia(canal_compra(in, [mainline, outlet, loja_fisica])) e recibo_original(true) e avalia(dias_desde_compra(=<, 14)) e nao ajuste_preco_anterior(true) e nao decisao(recusar)]
               entao [cria_facto(decisao(rever)),
                      cria_facto(aprovacao(responsavel_senior)),
                      cria_facto(regra_disparada('PT-007')),
                      cria_facto(motivo("[PT-007] Ajuste de preço de uma compra fora da loja: a política só prevê o ajuste de 14 dias para compras em loja. Rever com a gestão."))].

% PT-008: Ajuste de preço após 14 dias ou sem recibo original
regra 'PT-008' se [tipo_pedido(ajuste_preco) e avalia(dias_desde_compra(>, 14))]
               entao [cria_facto(decisao(recusar)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(regra_disparada('PT-008')),
                      cria_facto(motivo("[PT-008] Pedido de ajuste de preço após 14 dias ou sem recibo original: recusar ajuste de preço."))].

regra 'PT-008-SEM-RECIBO' se [tipo_pedido(ajuste_preco) e recibo_original(false)]
               entao [cria_facto(decisao(recusar)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(regra_disparada('PT-008')),
                      cria_facto(motivo("[PT-008] Pedido de ajuste de preço sem recibo original: recusar ajuste de preço."))].

regra 'PT-008-FOTO' se [tipo_pedido(ajuste_preco) e comprovativo(foto_recibo)]
               entao [cria_facto(decisao(recusar)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(regra_disparada('PT-008')),
                      cria_facto(motivo("[PT-008] Pedido de ajuste de preço com fotografia de recibo sem recibo original: recusar ajuste de preço."))].

% ==============================================================================
% 4. FAMÍLIA CH: CHANNEL & STORE TYPE (CANAIS E TIPOS DE LOJA)
% ==============================================================================

% CH-001: Devolução cruzada entre lojas físicas Mainline e Outlet
regra 'CH-001' se [avalia(canal_compra(in, [mainline, outlet])) e avalia(tipo_loja(in, [mainline, outlet]))]
               entao [cria_facto(regras_canal(loja_recetora)),
                      cria_facto(regra_disparada('CH-001')),
                      cria_facto(motivo("[CH-001] Compra Mainline ou Outlet devolvida em loja física: aplicar regras de comprovativo e avaliação da loja recetora."))].

% CH-002: Encomenda online encontrada na loja física (Precedência 2)
regra 'CH-002' se [avalia(canal_compra(in, [levi_com, levi_ca])) e encomenda_encontrada(true) e portal_online_disponivel(true) e elegibilidade_produto(aprovada)]
               entao [cria_facto(decisao(encaminhar)),
                      cria_facto(processo_obrigatorio(backpocket)),
                      cria_facto(tipo_verificacao(verificada)),
                      cria_facto(tipo_transacao(reembolso)),
                      cria_facto(valor_devolucao(valor_pago)),
                      cria_facto(meio_reembolso(meio_original)),
                      cria_facto(regra_disparada('CH-002')),
                      cria_facto(motivo("[CH-002] Encomenda online encontrada com portal ativo: encaminhar através da BackPocket com reembolso no meio original."))].

% CH-002: O documento não condiciona o encaminhamento à elegibilidade — um artigo em revisão (PC-002,
% PC-003, PC-004) também segue para a BackPocket, onde a revisão acontece (como o Drools)
regra 'CH-002-EM-REVISAO' se [avalia(canal_compra(in, [levi_com, levi_ca])) e encomenda_encontrada(true) e portal_online_disponivel(true) e decisao(rever) e nao tipo_pedido(ajuste_preco) e nao decisao(recusar)]
               entao [cria_facto(decisao(encaminhar)),
                      cria_facto(processo_obrigatorio(backpocket)),
                      cria_facto(tipo_verificacao(verificada)),
                      cria_facto(regra_disparada('CH-002')),
                      cria_facto(motivo("[CH-002] Encomenda online encontrada com portal ativo: encaminhar através da BackPocket, onde o artigo em revisão é avaliado."))].

% CH-003: Encomenda online não encontrada — às cegas só quando a política o permite (RPAC, Figura 5)
regra 'CH-003' se [avalia(canal_compra(in, [levi_com, levi_ca])) e encomenda_encontrada(false) e politica_permite_as_cegas_online(true) e nao tipo_pedido(ajuste_preco) e elegibilidade_produto(aprovada)]
               entao [cria_facto(tipo_verificacao(as_cegas)),
                      cria_facto(meio_reembolso(cartao_oferta)),
                      cria_facto(regra_disparada('CH-003')),
                      cria_facto(motivo("[CH-003] Encomenda online não encontrada: devolução às cegas permitida pela política, com cartão de oferta."))].

% CH-003: Encomenda online não encontrada e a política não permite a devolução às cegas
regra 'CH-003-NAO-PERMITIDA' se [avalia(canal_compra(in, [levi_com, levi_ca])) e encomenda_encontrada(false) e nao politica_permite_as_cegas_online(true) e nao tipo_pedido(ajuste_preco)]
               entao [cria_facto(decisao(recusar)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(regra_disparada('CH-003')),
                      cria_facto(motivo("[CH-003] Encomenda online não encontrada e a política não permite a devolução às cegas neste caso: recusar."))].

% CH-004: Portal online indisponível — a devolução às cegas permitida vai para o meio original
regra 'CH-004-AS-CEGAS' se [avalia(canal_compra(in, [levi_com, levi_ca])) e encomenda_encontrada(false) e politica_permite_as_cegas_online(true) e portal_online_disponivel(false) e elegibilidade_produto(aprovada)]
               entao [cria_facto(meio_reembolso(meio_original)),
                      cria_facto(regra_disparada('CH-004')),
                      cria_facto(motivo("[CH-004] Portal de devoluções online indisponível: a devolução às cegas permitida é processada no meio de pagamento original, em vez do cartão de oferta."))].

% CH-004: Encomenda online encontrada com o portal indisponível (caso que a política não cobre, A-04)
regra 'CH-004' se [avalia(canal_compra(in, [levi_com, levi_ca])) e encomenda_encontrada(true) e portal_online_disponivel(false) e elegibilidade_produto(aprovada)]
               entao [cria_facto(decisao(rever)),
                      cria_facto(aprovacao(responsavel_senior)),
                      cria_facto(regra_disparada('CH-004')),
                      cria_facto(motivo("[CH-004] Encomenda online com portal indisponível: caso sem previsão documental expressa; rever com gestão sénior."))].

% CH-005: Encomenda online enviada há mais de 30 dias
regra 'CH-005' se [avalia(canal_compra(in, [levi_com, levi_ca])) e avalia(dias_desde_envio(>, 30)) e elegibilidade_produto(aprovada) e nao meio_pagamento(paypal) e nao meio_pagamento(venmo) e nao meio_pagamento(afterpay)]
               entao [cria_facto(meio_reembolso(cartao_oferta)),
                      cria_facto(regra_disparada('CH-005')),
                      cria_facto(motivo("[CH-005] Encomenda online expedida há mais de 30 dias: emitir cartão de oferta para artigo elegível."))].

% CH-006: Cliente online solicita troca em loja física
regra 'CH-006' se [avalia(canal_compra(in, [levi_com, levi_ca])) e tipo_pedido(troca) e elegibilidade_produto(aprovada) e nao meio_pagamento(afterpay)]
               entao [cria_facto(tipo_transacao(troca)),
                      cria_facto(meio_reembolso(meio_original)),
                      cria_facto(regra_disparada('CH-006')),
                      cria_facto(motivo("[CH-006] Troca de encomenda online: concluir a troca e devolver eventual saldo remanescente ao meio original."))].

% CH-007: Produto da franquia do Canadá apresentado em loja (Precedência 2)
regra 'CH-007' se [canal_compra(franquia_canada)]
               entao [cria_facto(decisao(encaminhar)),
                      cria_facto(processo_obrigatorio(franquia_canada)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(regra_disparada('CH-007')),
                      cria_facto(motivo("[CH-007] Produto da franquia do Canadá: encaminhar para o processo específico da franquia com o SKU de franquia."))].

% CH-008: Produto de retalhista grossista (Precedência 2)
regra 'CH-008' se [canal_compra(grossista)]
               entao [cria_facto(decisao(recusar)),
                      cria_facto(tipo_transacao(nenhuma)),
                      cria_facto(processo_obrigatorio(processo_grossista)),
                      cria_facto(regra_disparada('CH-008')),
                      cria_facto(motivo("[CH-008] Produto adquirido em grossista: recusar e encaminhar o cliente para o retalhista original."))].

% CH-009: Devolução às cegas em loja Outlet
regra 'CH-009' se [tipo_loja(outlet) e tipo_verificacao(as_cegas) e elegibilidade_produto(aprovada)]
               entao [cria_facto(valor_devolucao(preco_atual_outlet)),
                      cria_facto(regra_disparada('CH-009')),
                      cria_facto(motivo("[CH-009] Devolução ou troca às cegas em Outlet: calcular pelo preço de venda atual após promoções ativas da Outlet."))].

% CH-010: Devolução com recibo Mainline/Online em Outlet
regra 'CH-010' se [tipo_loja(outlet) e avalia(canal_compra(in, [mainline, levi_com, levi_ca])) e tipo_verificacao(verificada) e elegibilidade_produto(aprovada)]
               entao [cria_facto(valor_devolucao(pvp_original)),
                      cria_facto(regra_disparada('CH-010')),
                      cria_facto(motivo("[CH-010] Devolução com recibo de Mainline/Online em Outlet: processar ao PVP original se permitido pelo POS e pela política."))].

% ==============================================================================
% 5. FAMÍLIA TN: REFUND TENDER (MEIOS DE REEMBOLSO)
% ==============================================================================

% TN-001: Devolução verificada em cartão de crédito ou débito
regra 'TN-001' se [tipo_verificacao(verificada) e avalia(meio_pagamento(in, [credito, debito])) e nao tipo_pedido(devolucao_oferta) e nao decisao(recusar)]
               entao [cria_facto(meio_reembolso(meio_original)),
                      cria_facto(procedimento_reembolso(tokenizado_sem_pedir_cartao)),
                      cria_facto(regra_disparada('TN-001')),
                      cria_facto(motivo("[TN-001] Reembolso verificado em cartão de crédito ou débito: estorno tokenizado automático sem pedir cartão físico."))].

% TN-002: Cartão original perdido ou roubado com conta bancária ativa
regra 'TN-002' se [avalia(meio_pagamento(in, [credito, debito])) e cartao_perdido_ou_roubado(true) e conta_cartao_ativa(true)]
               entao [cria_facto(meio_reembolso(meio_original)),
                      cria_facto(procedimento_reembolso(tokenizado_para_conta_ativa)),
                      cria_facto(regra_disparada('TN-002')),
                      cria_facto(motivo("[TN-002] Cartão original perdido ou roubado com conta bancária ativa: estorno automático para a conta bancária associada."))].

% TN-003: Conta do cartão original encerrada com estorno recusado
regra 'TN-003' se [avalia(meio_pagamento(in, [credito, debito])) e conta_cartao_ativa(false) e tentativa_cartao_recusada(true)]
               entao [cria_facto(meio_reembolso(cartao_alternativo)),
                      cria_facto(regra_disparada('TN-003')),
                      cria_facto(motivo("[TN-003] Conta do cartão encerrada e tentativa original recusada: sistema autoriza meio alternativo (outro cartão, numerário ou vale)."))].

% TN-004: Proibição de numerário para débito sem recusa do cartão
regra 'TN-004' se [meio_pagamento(debito) e nao tentativa_cartao_recusada(true)]
               entao [cria_facto(proibido_numerario(true)),
                      cria_facto(regra_disparada('TN-004')),
                      cria_facto(motivo("[TN-004] Pagamento original com débito: não emitir numerário sem tentativa prévia e recusa no cartão de débito original."))].

% TN-005: Pagamento contactless (Apple Pay / Google Pay)
regra 'TN-005' se [avalia(meio_pagamento(in, [contactless, apple_pay, google_pay]))]
               entao [cria_facto(meio_reembolso(meio_original)),
                      cria_facto(procedimento_reembolso(conta_associada)),
                      cria_facto(regra_disparada('TN-005')),
                      cria_facto(motivo("[TN-005] Pagamento contactless (Apple Pay / Google Pay): estorno automático para o cartão ou conta bancária associada."))].

% TN-006: Troca parcial com saldo remanescente reembolsável
regra 'TN-006' se [tipo_pedido(troca) e saldo_reembolsavel(true) e avalia(meio_pagamento(in, [credito, debito]))]
               entao [cria_facto(meio_reembolso(meio_original)),
                      cria_facto(procedimento_reembolso(estorno_saldo_remanescente)),
                      cria_facto(regra_disparada('TN-006')),
                      cria_facto(motivo("[TN-006] Troca com saldo remanescente: concluir troca e estornar valor restante automaticamente ao cartão original."))].

% TN-007: Devolução de oferta com comprovativo
regra 'TN-007' se [tipo_pedido(devolucao_oferta) e tipo_verificacao(verificada)]
               entao [cria_facto(meio_reembolso(credito_loja)),
                      cria_facto(regra_disparada('TN-007')),
                      cria_facto(motivo("[TN-007] Devolução de oferta com recibo: oferecer crédito de loja ao portador ou estorno tokenizado ao comprador original."))].

% TN-008: Compra efetuada via PayPal ou Venmo
regra 'TN-008' se [avalia(meio_pagamento(in, [paypal, venmo])) e nao acesso_aplicacao_pagamento(false)]
               entao [cria_facto(processo_obrigatorio(fluxo_app)),
                      cria_facto(meio_reembolso(fluxo_app)),
                      cria_facto(regra_disparada('TN-008')),
                      cria_facto(motivo("[TN-008] Compra via PayPal ou Venmo: cliente deve aceder à aplicação para estorno; proibido substituir meio fora desse fluxo."))].

% TN-008: O cliente não consegue aceder à aplicação — o reembolso só pode seguir o fluxo da app e não
% se substitui o meio, por isso o reembolso no meio original (compra com comprovativo até 30 dias, PT-003,
% ou encomenda online encontrada) fica em revisão (como o Drools, A-05). Só usa factos de entrada, para
% disparar antes de PT-003 e a revisão ser a decisão do motor.
regra 'TN-008-SEM-APP' se [avalia(meio_pagamento(in, [paypal, venmo])) e acesso_aplicacao_pagamento(false) e nao comprovativo(nenhum) e nao avalia(dias_desde_compra(>, 30)) e nao decisao(recusar)]
               entao [cria_facto(decisao(rever)),
                      cria_facto(aprovacao(responsavel_senior)),
                      cria_facto(processo_obrigatorio(fluxo_app)),
                      cria_facto(meio_reembolso(fluxo_app)),
                      cria_facto(regra_disparada('TN-008')),
                      cria_facto(motivo("[TN-008] Compra via PayPal ou Venmo e o cliente não consegue aceder à aplicação: o reembolso só pode ser feito pelo fluxo da aplicação; não substituir por outro meio. Rever com a gestão."))].

% TN-009: Compra física com Afterpay
regra 'TN-009' se [meio_pagamento(afterpay) e avalia(canal_compra(in, [mainline, outlet, loja_fisica]))]
               entao [cria_facto(processo_obrigatorio(afterpay_app)),
                      cria_facto(regra_disparada('TN-009')),
                      cria_facto(motivo("[TN-009] Compra em loja paga com Afterpay: cliente localiza compra na app Afterpay; devolução total à Afterpay e recibo do POS."))].

% TN-010: Compra online paga com Afterpay
regra 'TN-010' se [meio_pagamento(afterpay) e avalia(canal_compra(in, [levi_com, levi_ca]))]
               entao [cria_facto(processo_obrigatorio(backpocket)),
                      cria_facto(meio_reembolso(meio_original)),
                      cria_facto(regra_disparada('TN-010')),
                      cria_facto(motivo("[TN-010] Compra online com Afterpay: processar na BackPocket para o método original. Sem trocas nem cartões de oferta."))].

% TN-011: Interac no Canadá em loja física com cartão físico presente
regra 'TN-011' se [mercado(canada) e meio_pagamento(interac) e cartao_interac_presente(true)]
               entao [cria_facto(meio_reembolso(meio_original)),
                      cria_facto(processo_obrigatorio(pos)),
                      cria_facto(regra_disparada('TN-011')),
                      cria_facto(motivo("[TN-011] Interac Canadá em loja física: o cliente deve apresentar o mesmo cartão físico Interac utilizado na compra."))].

% TN-011: Interac no Canadá sem o mesmo cartão físico presente. Só importa quando o reembolso vai
% para o Interac: compra em loja com comprovativo até 30 dias (PT-003), não, por exemplo, crédito de
% loja. Só usa factos de entrada, para disparar antes de PT-003 e a revisão ser a decisão do motor.
regra 'TN-011-SEM-CARTAO' se [mercado(canada) e meio_pagamento(interac) e avalia(cartao_interac_presente(in, [false, nao, ausente])) e nao comprovativo(nenhum) e nao avalia(dias_desde_compra(>, 30)) e nao avalia(canal_compra(in, [levi_com, levi_ca])) e nao decisao(recusar)]
               entao [cria_facto(decisao(rever)),
                      cria_facto(aprovacao(responsavel_senior)),
                      cria_facto(meio_reembolso(sem_meio_definido)),
                      cria_facto(regra_disparada('TN-011')),
                      cria_facto(motivo("[TN-011] Interac Canadá sem cartão físico original: os terminais Interac não suportam tokenização; rever com a chefia sénior sem meio definido."))].

% TN-012: Interac no Canadá para compra efetuada via BackPocket
regra 'TN-012' se [mercado(canada) e meio_pagamento(interac) e canal_compra(backpocket) e cartao_interac_presente(true)]
               entao [cria_facto(processo_obrigatorio(interac_verifone)),
                      cria_facto(regra_disparada('TN-012')),
                      cria_facto(motivo("[TN-012] Interac Canadá compra BackPocket: concluir na BackPocket e efetuar estorno manual na VeriFone pelo valor exato com cartão presente."))].

% ==============================================================================
% 6. FAMÍLIA EP: EXCHANGE & PROMOTION (TROCAS E PROMOÇÕES)
% ==============================================================================

% EP-001: Troca com recibo que altera apenas o tamanho do artigo
regra 'EP-001' se [tipo_pedido(troca) e tipo_verificacao(verificada) e troca_apenas_tamanho(true) e elegibilidade_produto(aprovada)]
               entao [cria_facto(preservar_preco_promocional(true)),
                      cria_facto(regra_disparada('EP-001')),
                      cria_facto(motivo("[EP-001] Troca com recibo com alteração apenas de tamanho: honrar preço de compra original ou promocional."))].

% EP-002: Troca com alteração de modelo ou cor
regra 'EP-002' se [tipo_pedido(troca) e troca_apenas_tamanho(false) e elegibilidade_produto(aprovada)]
               entao [cria_facto(devolucao_e_nova_venda(true)),
                      cria_facto(regra_disparada('EP-002')),
                      cria_facto(motivo("[EP-002] Troca com alteração de modelo ou cor: devolver artigo ao valor elegível e faturar o novo ao preço de venda atual."))].

% EP-003: Promoção por escalões em devolução às cegas
regra 'EP-003' se [tipo_verificacao(as_cegas) e promocao_escaloes(true) e elegibilidade_produto(aprovada)]
               entao [cria_facto(valor_devolucao(escalao_quantidade_atual)),
                      cria_facto(regra_disparada('EP-003')),
                      cria_facto(motivo("[EP-003] Devolução às cegas sob promoção por escalões: aplicar escalão pelo número de artigos devolvidos na transação atual."))].

% EP-004: Promoção por escalões em devolução verificada com recibo
regra 'EP-004' se [tipo_verificacao(verificada) e promocao_escaloes(true) e elegibilidade_produto(aprovada)]
               entao [cria_facto(valor_devolucao(calculado_pos_qtd_original)),
                      cria_facto(regra_disparada('EP-004')),
                      cria_facto(motivo("[EP-004] Devolução com recibo sob promoção por escalões: reembolso calculado pelo POS com base na quantidade original faturada."))].

% EP-005: Artigo entre canais que está ou esteve no sortido da loja recetora
regra 'EP-005' se [artigo_entre_canais(true) e no_sortido(true) e elegibilidade_produto(aprovada) e nao estado_produto(sujo_contaminado_inseguro)]
               entao [cria_facto(destino_produto(area_vendas)),
                      cria_facto(reprecificar_preco_atual(true)),
                      cria_facto(regra_disparada('EP-005')),
                      cria_facto(motivo("[EP-005] Artigo entre canais que está ou esteve no sortido da loja recetora: reprecificar ao preço atual e retornar à área de vendas."))].

% EP-006: Artigo entre canais fora do sortido da loja recetora
regra 'EP-006' se [artigo_entre_canais(true) e no_sortido(false) e elegibilidade_produto(aprovada) e nao estado_produto(sujo_contaminado_inseguro)]
               entao [cria_facto(destino_produto(saldos)),
                      cria_facto(desconto_saldos(20)),
                      cria_facto(regra_disparada('EP-006')),
                      cria_facto(motivo("[EP-006] Artigo entre canais que não faz parte do sortido: colocar em saldos com 20% de desconto sobre o preço devolvido."))].

% EP-007: Artigo entre canais já em liquidação/saldo
regra 'EP-007' se [artigo_entre_canais(true) e artigo_em_saldo(true) e elegibilidade_produto(aprovada)]
               entao [cria_facto(destino_produto(saldos)),
                      cria_facto(regra_disparada('EP-007')),
                      cria_facto(motivo("[EP-007] Artigo entre canais já em saldo: colocar em saldos aplicando as promoções atuais elegíveis."))].

% ==============================================================================
% 7. FAMÍLIA EX: MANAGER REVIEW & ESCALATION (EXCEÇÕES E ESCALAMENTO)
% ==============================================================================

% EX-001: Critério da gestão em situações que admitem revisão (Precedência 7)
regra 'EX-001' se [decisao(rever)]
               entao [cria_facto(aprovacao(gestor_xstore)),
                      cria_facto(regra_disparada('EX-001')),
                      cria_facto(motivo("[EX-001] Critério da gestão: avaliar vendabilidade, comprovativo, tempo decorrido, valor, risco de fraude e circunstâncias."))].

% EX-002: Cliente contesta o desfecho padrão
regra 'EX-002' se [cliente_contesta(true) e nao cliente_agitado(true)]
               entao [cria_facto(acao_operacional(explicar_politica_e_oferecer_alternativa)),
                      cria_facto(regra_disparada('EX-002')),
                      cria_facto(motivo("[EX-002] Cliente contesta o resultado: explicar a política e apresentar a melhor alternativa regulamentar."))].

% EX-003: Cliente irritado ou perturbação no balcão
regra 'EX-003' se [cliente_agitado(true)]
               entao [cria_facto(aprovacao(responsavel_senior)),
                      cria_facto(regra_disparada('EX-003')),
                      cria_facto(motivo("[EX-003] Cliente irritado ou perturbação: escalar para responsável sénior. A agitação não altera a elegibilidade do produto."))].

% EX-004: Condições estritas para exceção de apaziguamento por líder sénior
% Não se aplica a uma exceção que contorna um controlo obrigatório: EX-006 recusa-a e anula EX-004 e
% EX-005 (testado nos factos de entrada, para não depender da ordem de disparo)
regra 'EX-004' se [aprovacao(responsavel_senior) e risco_fraude(baixo) e concluivel_no_sistema(true) e nao personalizado_ou_alterado(true) e nao sku_reconhecido(false) e nao estado_produto(sujo_contaminado_inseguro) e nao excecao_contorna_controlo(true) e nao afterpay_pede_excecao(true) e nao excecao_recusada(true)]
               entao [cria_facto(excecao_autorizavel(true)),
                      cria_facto(regra_disparada('EX-004')),
                      cria_facto(motivo("[EX-004] Exceção de apaziguamento autorizável: ausência de hard stops, artigo verificável, baixo risco e operação executável."))].

% EX-005: Aplicação da resolução menos abrangente para artigo vendável
% EX-006 anula EX-004 e EX-005: uma exceção recusada não é autorizável nem tem resolução
regra 'EX-005' se [excecao_autorizavel(true) e revendivel(true) e nao excecao_recusada(true)]
               entao [cria_facto(preferencia_resolucao(menos_abrangente)),
                      cria_facto(regra_disparada('EX-005')),
                      cria_facto(motivo("[EX-005] Exceção para artigo vendável: aplicar resolução menos abrangente (troca mesmo artigo > crédito loja > meio original)."))].

% EX-006: Recusa imperativa de exceção que viola controlos absolutos. Recusa a exceção, não o
% pedido: segue-se o processo obrigatório (como o Drools, excecaoRecusada).
regra 'EX-006' se [tentativa_excecao(true) e excecao_contorna_controlo(true)]
               entao [cria_facto(excecao_recusada(true)),
                      cria_facto(regra_disparada('EX-006')),
                      cria_facto(motivo("[EX-006] A exceção pedida exige um meio de pagamento proibido, um SKU incorreto, um produto excluído ou contornar a Afterpay, o PayPal, o Venmo ou o processamento online: recusar a exceção e usar o processo obrigatório."))].

% EX-006: A exceção pedida contorna a Afterpay de uma compra online (a mesma situação de HS-005)
regra 'EX-006-AFTERPAY' se [tentativa_excecao(true) e afterpay_pede_excecao(true)]
               entao [cria_facto(excecao_recusada(true)),
                      cria_facto(regra_disparada('EX-006')),
                      cria_facto(motivo("[EX-006] A exceção pedida contorna a Afterpay: recusar a exceção e reembolsar pelo processo obrigatório da Afterpay."))].

% EX-007: Documentação mandatória de exceção aprovada
regra 'EX-007' se [excecao_aprovada(true)]
               entao [cria_facto(documentacao(documentar_excecao)),
                      cria_facto(regra_disparada('EX-007')),
                      cria_facto(motivo("[EX-007] Exceção aprovada: documentar motivo, gestor aprovador, valor, resultado, preocupação do cliente e destino do produto."))].

% EX-008: Indicadores de fraude ou inconsistências materiais
regra 'EX-008' se [risco_fraude(alto)]
               entao [cria_facto(decisao(rever)),
                      cria_facto(pausar_transacao(true)),
                      cria_facto(aprovacao(escalamento_distrital)),
                      cria_facto(documentacao(relatar_seguranca)),
                      cria_facto(regra_disparada('EX-008')),
                      cria_facto(motivo("[EX-008] Indicadores de fraude ou inconsistências: pausar transação, envolver gestão e reportar à Segurança Global."))].

% ==============================================================================
% 8. FAMÍLIA CT: AUTHORIZATION CONTROLS (CONTROLOS E PROCEDIMENTOS)
% ==============================================================================

% CT-001: Devolução verificada por pessoal autorizado
regra 'CT-001' se [tipo_verificacao(verificada) e colaborador_autorizado(true)]
               entao [cria_facto(credenciais_validadas(true)),
                      cria_facto(documentacao(assinaturas)),
                      cria_facto(regra_disparada('CT-001')),
                      cria_facto(motivo("[CT-001] Devolução verificada processada por colaborador autorizado com credenciais de POS próprias."))].

% CT-002: Devolução às cegas por Lead Cashier ou Elevated Stylist exige gestor
regra 'CT-002' se [tipo_verificacao(as_cegas) e avalia(funcao_colaborador(in, [lead_cashier, elevated_stylist]))]
               entao [cria_facto(aprovacao(gestor_xstore)),
                      cria_facto(regra_disparada('CT-002')),
                      cria_facto(motivo("[CT-002] Devolução às cegas processada por Lead Cashier ou Elevated Stylist exige aprovação do XStore Manager."))].

% CT-003: Sessão própria do colaborador do início ao fim
regra 'CT-003' se [colaborador_autorizado(true) e sessao_pos_propria(true)]
               entao [cria_facto(controlo_sessao_conforme(true)),
                      cria_facto(regra_disparada('CT-003')),
                      cria_facto(motivo("[CT-003] O mesmo colaborador conduz a transação do início ao fim com credenciais próprias de POS."))].

% CT-004: Atribuição de venda ao Stylist original em devolução com recibo
regra 'CT-004' se [tipo_verificacao(verificada) e stylist_venda_original(StylistID)]
               entao [cria_facto(atribuicao_venda(StylistID)),
                      cria_facto(regra_disparada('CT-004')),
                      cria_facto(motivo("[CT-004] Devolução com recibo atribuída nos registos ao Stylist que concretizou a venda original."))].

% CT-005: Assinaturas obrigatórias na conclusão da devolução
regra 'CT-005' se [transacao_concluida(true)]
               entao [cria_facto(documentacao(assinaturas)),
                      cria_facto(regra_disparada('CT-005')),
                      cria_facto(motivo("[CT-005] Recolher assinatura do cliente (ou 'Recusado'), do operador e testemunha (ou 'SSC')."))].

% CT-006: Tratamento e arquivo do recibo original entregue
regra 'CT-006' se [transacao_concluida(true) e recibo_entregue(true)]
               entao [cria_facto(documentacao(agrafar_recibo)),
                      cria_facto(regra_disparada('CT-006')),
                      cria_facto(motivo("[CT-006] Recibo original entregue agrafado à cópia de loja; se cliente retém com outros itens, anotar na cópia."))].

% CT-007: Retenção documental durante 90 dias
regra 'CT-007' se [transacao_concluida(true)]
               entao [cria_facto(documentacao(reter_90_dias)),
                      cria_facto(regra_disparada('CT-007')),
                      cria_facto(motivo("[CT-007] Reter suportes físicos e assinaturas nos arquivos de media retention durante 90 dias."))].

% CT-008: Inspeção obrigatória antes de retorno à área de vendas
regra 'CT-008' se [destino_produto(area_vendas)]
               entao [cria_facto(inspecao_rfid_etiquetas(obrigatoria)),
                      cria_facto(regra_disparada('CT-008')),
                      cria_facto(motivo("[CT-008] Produto devolvido a revender deve ser inspecionado quanto a danos, etiquetas e precisão RFID antes de voltar à área de vendas."))].

% ==============================================================================
% 9. FAMÍLIA BW: BODYWEAR DISPOSITION (DESTINO DE VESTUÁRIO ÍNTIMO)
% ==============================================================================

% BW-001: Embalagem intacta, não usado e vendável
regra 'BW-001' se [categoria_produto(bodywear) e embalagem_intacta(true) e estado_produto(nao_usado_com_etiquetas) e nao estado_produto(sujo_contaminado_inseguro)]
               entao [cria_facto(destino_produto(area_vendas)),
                      cria_facto(regra_disparada('BW-001')),
                      cria_facto(motivo("[BW-001] Bodywear com embalagem original intacta confirmado não usado e vendável: devolver à área de vendas."))].

% BW-002: Sem embalagem, mas não usado e conjunto completo
regra 'BW-002' se [categoria_produto(bodywear) e embalagem_intacta(false) e pecas_em_falta(false) e estado_produto(nao_usado_com_etiquetas) e nao estado_produto(sujo_contaminado_inseguro)]
               entao [cria_facto(destino_produto(saldos)),
                      cria_facto(desconto_saldos(50)),
                      cria_facto(riscar_codigo_barras_vermelho(true)),
                      cria_facto(regra_disparada('BW-002')),
                      cria_facto(motivo("[BW-002] Bodywear sem embalagem original mas conjunto completo e não usado: saldos com 50% de desconto e código riscado a vermelho."))].

% BW-003: Unidades em falta ou usado sem contaminação biológica
regra 'BW-003' se [categoria_produto(bodywear) e pecas_em_falta(true) e nao estado_produto(sujo_contaminado_inseguro)]
               entao [cria_facto(destino_produto(baixa_dano)),
                      cria_facto(processo_obrigatorio(baixa_dano)),
                      cria_facto(regra_disparada('BW-003')),
                      cria_facto(motivo("[BW-003] Bodywear com unidades em falta do conjunto ou usado: baixa por dano de todo o conjunto."))].

% BW-003: Bodywear usado (sem risco biológico, que é BW-004)
regra 'BW-003-USADO' se [categoria_produto(bodywear) e estado_produto(claramente_usado) e nao estado_produto(sujo_contaminado_inseguro) e nao decisao(recusar)]
               entao [cria_facto(destino_produto(baixa_dano)),
                      cria_facto(processo_obrigatorio(baixa_dano)),
                      cria_facto(regra_disparada('BW-003')),
                      cria_facto(motivo("[BW-003] Bodywear usado: baixa por dano de todo o conjunto."))].

% BW-004: Usado e sujo, contaminado ou inseguro
regra 'BW-004' se [categoria_produto(bodywear) e estado_produto(sujo_contaminado_inseguro)]
               entao [cria_facto(destino_produto(isolamento_risco_biologico)),
                      cria_facto(regra_disparada('BW-004')),
                      cria_facto(motivo("[BW-004] Bodywear usado, sujo, contaminado ou inseguro: colocar imediatamente em saco de risco biológico e isolar."))].
