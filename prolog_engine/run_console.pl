:- encoding(utf8).
:- use_module(library(plunit)).
:- use_module(src/core/retail_engine/engine).
:- use_module(src/core/retail_engine/interactive).

/** <module> Launcher de Consola Interativa SWI-Prolog
 *
 * MEIA 2026/2027 · Paradigmas de Programação em Inteligência Artificial (PPROGIA)
 * Desafio 1 · Equipa 3
 *
 * Sistema Pericial de Diagnóstico para Devoluções e Trocas no Retalho (Levi's)
 * Base de Conhecimento com 71 Regras, 7 Precedências e 5 Vias de Explicabilidade.
 *
 * Utilização direta:
 *   swipl -s run_console.pl
 */

% ==============================================================================
% Ponto de Entrada e Apresentação
% ==============================================================================

iniciar :-
    format('~N================================================================================~n', []),
    format('  MEIA 2026/2027 · PPROGIA · Desafio 1 (Equipa 3)~n', []),
    format('  SISTEMA PERICIAL DE DEVOLUÇÕES E TROCAS LEVI STRAUSS & CO. (71 REGRAS)~n', []),
    format('================================================================================~n~n', []),
    format('Bem-vindo à consola pericial declarativa em SWI-Prolog.~n', []),
    format('O motor implementa inferência dedutiva (forward-chaining), raciocínio dialógico~n', []),
    format('segundo o modelo do Prof. ACM e 5 vias formais de explicabilidade pericial.~n~n', []),
    ajuda.

ajuda :-
    format('COMANDOS DISPONÍVEIS NA CONSOLA:~n', []),
    format('  ?- avaliar_interativo.   -> Inicia triagem guiada com perguntas e respostas.~n', []),
    format('  ?- cenario(N).           -> Executa um dos 10 cenários de teste oficiais (1 a 10).~n', []),
    format('  ?- listar_cenarios.      -> Lista os 10 cenários de retalho pré-configurados.~n', []),
    format('  ?- como(Facto).          -> Explicação causal retrospetiva (Como o facto foi deduzido).~n', []),
    format('  ?- whynot(Facto).        -> Explicação contrafactual (Porque é que o facto falhou).~n', []),
    format('  ?- output_why.           -> Mostra as justificações executivas da decisão final.~n', []),
    format('  ?- factos.               -> Lista todos os factos presentes na memória de trabalho.~n', []),
    format('  ?- limpar.               -> Limpa a memória da sessão atual para novo teste.~n', []),
    format('  ?- testar.               -> Executa a suite completa de 91 testes automatizados PLUnit.~n', []),
    format('  ?- ajuda.                -> Exibe este resumo de comandos.~n~n', []),
    format('DURANTE A TRIAGEM INTERATIVA (avaliar_interativo):~n', []),
    format('  • Pode responder com as opções sugeridas (ex.: sim, nao, s, n).~n', []),
    format('  • Se desconhecer o facto, responda: nao_sei (ou ?). O motor continua em segurança.~n', []),
    format('  • Para questionar a razão da pergunta, responda: porquê?~n~n', []).

% ==============================================================================
% Triagem Guiada Interativa (Diálogo ACM)
% ==============================================================================

avaliar_interativo :-
    format('~N================================================================================~n', []),
    format('  A INICIAR TRIAGEM INTERATIVA DE BALCÃO (DIÁLOGO DIALÓGICO ACM)                ~n', []),
    format('================================================================================~n', []),
    format('Por favor, responda às questões formuladas pelo motor pericial.~n', []),
    format('Respostas aceites: valores sugeridos, sim/nao, nao_sei ou porquê?~n', []),
    format('--------------------------------------------------------------------------------~n~n', []),
    setup_call_cleanup(
        enable_terminal_mode,
        run_interactive(Resultado),
        disable_terminal_mode
    ),
    format('~N================================================================================~n', []),
    format('                         DESFECHO DO DIAGNÓSTICO PERICIAL                       ~n', []),
    format('================================================================================~n', []),
    format('  Decisão Final     : ~w~n', [Resultado.decision]),
    format('  Factos Fornecidos : ~w~n', [Resultado.initial_facts_count]),
    format('  Factos Deduzidos  : ~w~n', [Resultado.derived_facts_count]),
    format('  Total em Memória  : ~w~n', [Resultado.total_facts]),
    format('--------------------------------------------------------------------------------~n', []),
    format('Justificações da Política de Retalho:~n', []),
    (   Resultado.justification == []
    ->  format('  (Nenhuma justificação explícita registada)~n', [])
    ;   forall(member(J, Resultado.justification), format('  • ~s~n', [J]))
    ),
    format('--------------------------------------------------------------------------------~n', []),
    format('Sugestões de Exploração:~n', []),
    format('  ?- como(decisao(~w)).       -> Visualizar a dedução causal do desfecho.~n', [Resultado.decision]),
    format('  ?- whynot(decisao(permitir)). -> Inquirir porque razão não foi aprovado.~n', []),
    format('  ?- output_why.                -> Reexibir as justificações da decisão.~n', []),
    format('  ?- factos.                    -> Inspecionar todos os factos em memória.~n', []),
    format('================================================================================~n~n', []).

% ==============================================================================
% Execução e Inspeção dos 10 Cenários de Retalho Oficiais
% ==============================================================================

cenario :-
    listar_cenarios.

listar_cenarios :-
    format('~N================================================================================~n', []),
    format('                10 CENÁRIOS DE RETALHO OFICIAIS (LEVI STRAUSS & CO.)            ~n', []),
    format('================================================================================~n', []),
    forall(dados_cenario(N, Titulo, _, DecisaoEsperada, _),
        format('  [~|~`0t~d~2+] ~w ~t~48| -> [~w]~n', [N, Titulo, DecisaoEsperada])),
    format('================================================================================~n', []),
    format('Para executar qualquer cenário, utilize: ?- cenario(N). (ex: ?- cenario(1).)~n~n', []).

cenario(N) :-
    integer(N),
    dados_cenario(N, Titulo, Descricao, DecisaoEsperada, Factos),
    !,
    format('~N================================================================================~n', []),
    format('  EXECUÇÃO PEDAGÓGICA: CENÁRIO ~w~n', [N]),
    format('  Título: ~w~n', [Titulo]),
    format('================================================================================~n', []),
    format('Descrição Normativa:~n  ~w~n~n', [Descricao]),
    format('Decisão Regulamentar Esperada: ~w~n', [DecisaoEsperada]),
    length(Factos, NumFactos),
    format('Factos Iniciais Submetidos (~w factos):~n', [NumFactos]),
    forall(member(F, Factos), format('  • ~w~n', [F])),
    format('--------------------------------------------------------------------------------~n', []),
    format('A processar inferência dedutiva (forward-chaining)...~n', []),
    retail_engine:load_knowledge_base(retail_rules),
    retail_engine:reset_session,
    retail_engine:assert_initial_facts_list(Factos),
    retail_engine:run_engine(Resultado),
    format('~N--------------------------------------------------------------------------------~n', []),
    format('RESULTADOS OBTIDOS PELO MOTOR:~n', []),
    format('  Decisão Concluída : ~w~n', [Resultado.decision]),
    format('  Factos Iniciais   : ~w~n', [NumFactos]),
    format('  Factos Deduzidos  : ~w~n', [Resultado.derived_facts_count]),
    format('  Total em Memória  : ~w~n', [Resultado.total_facts]),
    format('~nRegras Disparadas durante a Inferência:~n', []),
    findall(RID, retail_engine:facto(_, regra_disparada(RID)), Regras),
    (   Regras == []
    ->  format('  (Nenhuma regra registada)~n', [])
    ;   forall(member(R, Regras),
            (   retail_engine:regra_info(R, Fam, Desc)
            ->  format('  • [~w] (~w) ~w~n', [R, Fam, Desc])
            ;   format('  • [~w]~n', [R])
            ))
    ),
    format('~nJustificações Executivas (Via 3: Output Why):~n', []),
    (   Resultado.justification == []
    ->  format('  (Sem justificações disponíveis)~n', [])
    ;   forall(member(J, Resultado.justification), format('  • ~s~n', [J]))
    ),
    format('--------------------------------------------------------------------------------~n', []),
    format('Comandos recomendados para demonstração de explicabilidade:~n', []),
    format('  ?- como(decisao(~w)).       -> Ver encadeamento dedutivo completo do desfecho.~n', [Resultado.decision]),
    (   Resultado.decision \== permitir
    ->  format('  ?- whynot(decisao(permitir)). -> Demonstrar análise contrafactual Porque Não.~n', [])
    ;   format('  ?- como(1).                   -> Inspecionar facto específico pelo seu ID.~n', [])
    ),
    format('  ?- factos.                    -> Ver tabela integral de factos em memória.~n', []),
    format('================================================================================~n~n', []).

cenario(N) :-
    format('~N[ERRO] O cenário ~w não existe. Por favor escolha um número de 1 a 10.~n', [N]),
    format('Digite ?- listar_cenarios. para ver todos os cenários disponíveis.~n~n', []).

% ==============================================================================
% Definição dos 10 Cenários de Retalho Oficiais da Levi's
% ==============================================================================

dados_cenario(1,
    "As etiquetas soltas, troca ao 29.º dia",
    "Cliente solicita troca apenas de tamanho ao 29.º dia com recibo digital de loja mainline. As etiquetas estão soltas mas a peça não foi usada. Requer autorização de gerência por estar no limiar do prazo com etiquetas desprendidas.",
    rever,
    [
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(mainline), tipo_loja(mainline),
        sku_reconhecido(true), marca(levis), categoria_produto(vestuario),
        estado_produto(nao_usado_etiquetas_soltas),
        comprovativo(recibo_digital), dias_desde_compra(29),
        tipo_pedido(troca), troca_apenas_tamanho(true),
        meio_pagamento(credito),
        artigo_entre_canais(true), no_sortido(true),
        stylist_venda_original('S-21'), transacao_concluida(true), recibo_entregue(false)
    ]).

dados_cenario(2,
    "O cliente irritado com Afterpay",
    "Artigo de vestuário comprado online via Afterpay. Cliente contesta agressivamente em loja e exige exceção de estorno em numerário ou cartão. Encaminhado obrigatoriamente para o fluxo BackPocket.",
    recusar,
    [
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(levi_com), encomenda_encontrada(true), portal_online_disponivel(true),
        sku_reconhecido(true), marca(levis), categoria_produto(vestuario),
        estado_produto(nao_usado_com_etiquetas),
        meio_pagamento(afterpay), afterpay_pede_excecao(true), tentativa_excecao(true),
        tipo_pedido(troca), cliente_contesta(true), cliente_agitado(true),
        artigo_entre_canais(true), no_sortido(false),
        transacao_concluida(true)
    ]).

dados_cenario(3,
    "A devolução de oferta na Outlet sem recibo",
    "Artigo de vestuário com etiquetas apresentado numa loja Outlet como devolução de prenda sem recibo. Cliente fornece identificação completa. Permitida devolução cega com reembolso em crédito de loja.",
    permitir,
    [
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(outlet), tipo_loja(outlet),
        sku_reconhecido(true), marca(levis), categoria_produto(vestuario),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(nenhum), tipo_pedido(devolucao_oferta), cliente_fornece_dados(true),
        transacao_concluida(true), destino_produto(area_vendas)
    ]).

dados_cenario(4,
    "As calças com bainha e defeito de fabrico",
    "Artigo personalizado e embainhado com alegado defeito de fabrico ao 10.º dia. Acionamento do Hard Stop HS-003: peças alteradas pelo cliente são de aceitação expressamente interdita.",
    recusar,
    [
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(mainline), tipo_loja(mainline),
        sku_reconhecido(true), marca(levis), categoria_produto(vestuario),
        personalizado_ou_alterado(true), defeito_fabrico(true),
        comprovativo(recibo_impresso), dias_desde_compra(10),
        tipo_pedido(devolucao)
    ]).

dados_cenario(5,
    "A disputa sobre produto grossista (Wholesale)",
    "Cliente tenta devolver em loja própria Levi's um par de calças Signature adquirido num retalhista grossista terceiro (ex.: Walmart/Costco). Recusa mandatória por incompatibilidade de canal de retalho.",
    recusar,
    [
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(grossista),
        sku_reconhecido(true), marca(signature), categoria_produto(vestuario),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(recibo_impresso), cliente_contesta(true),
        tipo_pedido(devolucao)
    ]).

dados_cenario(6,
    "Devolução sem recibo com risco biológico e fraude",
    "Tentativa de devolução sem recibo de peça com sujidade e contaminação biológica. Cliente recusa identificação e apresenta risco de fraude elevado. Encaminhado para escalamento distrital e isolamento biohazard.",
    rever,
    [
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(mainline), tipo_loja(mainline),
        comprovativo(nenhum),
        estado_produto(sujo_contaminado_inseguro),
        risco_fraude(alto), cliente_fornece_dados(false),
        tipo_pedido(devolucao)
    ]).

dados_cenario(7,
    "A substituição do cartão de débito Interac no Canadá",
    "Transação realizada no mercado canadiano com débito Interac. Artigo em estado perfeito no 18.º dia com recibo, mas cliente não dispõe do cartão físico Interac para estorno eletrónico no terminal.",
    rever,
    [
        colaborador_autorizado(true), sessao_pos_propria(true),
        mercado(canada), canal_compra(mainline), tipo_loja(mainline),
        sku_reconhecido(true), marca(levis), categoria_produto(vestuario),
        estado_produto(nao_usado_com_etiquetas),
        comprovativo(recibo_impresso), dias_desde_compra(18),
        meio_pagamento(interac), cartao_interac_presente(false),
        cliente_contesta(true),
        stylist_venda_original('S-77'), transacao_concluida(true), recibo_entregue(true),
        destino_produto(area_vendas)
    ]).

dados_cenario(8,
    "Ajuste de preço com fotografia de recibo",
    "Cliente solicita ajuste de preço promocional ao 13.º dia apresentando apenas fotografia digital do recibo no smartphone. Recusado segundo a norma PT-008 (fotos não constituem comprovativo fiscal).",
    recusar,
    [
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(mainline), tipo_loja(mainline),
        sku_reconhecido(true), marca(levis), categoria_produto(vestuario),
        estado_produto(nao_usado_com_etiquetas),
        tipo_pedido(ajuste_preco), comprovativo(foto_recibo), dias_desde_compra(13),
        cliente_contesta(true)
    ]).

dados_cenario(9,
    "Conjunto de bodywear com risco de segurança e garantia",
    "Conjunto de bodywear devolvido usado e contaminado ao 21.º dia com recibo. Acionamento conjugado da garantia de satisfação (estorno aprovado) com isolamento estrito de resíduo biológico para destruição.",
    permitir,
    [
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(outlet), tipo_loja(outlet),
        sku_reconhecido(true), marca(levis),
        categoria_produto(bodywear), estado_produto(sujo_contaminado_inseguro),
        comprovativo(recibo_impresso), dias_desde_compra(21),
        meio_pagamento(credito),
        stylist_venda_original('S-99'), transacao_concluida(true), recibo_entregue(true)
    ]).

dados_cenario(10,
    "Troca online tardia com PayPal durante falha do portal",
    "Compra em levi.com paga via PayPal entregue há 37 dias. Portal de devoluções online inoperacional. Cliente desloca-se à loja física para troca de modelo. Requer aprovação sénior por superação do prazo.",
    rever,
    [
        colaborador_autorizado(true), sessao_pos_propria(true),
        canal_compra(levi_com), encomenda_encontrada(true), portal_online_disponivel(false),
        sku_reconhecido(true), marca(levis), categoria_produto(vestuario),
        estado_produto(nao_usado_com_etiquetas),
        meio_pagamento(paypal), dias_desde_envio(37),
        tipo_pedido(troca), artigo_entre_canais(true), no_sortido(false),
        tentativa_excecao(true), cliente_contesta(true),
        destino_produto(area_vendas)
    ]).

% ==============================================================================
% Utilitários de Navegação e Inspeção em Consola
% ==============================================================================

factos :-
    findall((Id, Termo), retail_engine:facto(Id, Termo), Lista),
    (   Lista == []
    ->  format('~NA memória de trabalho do motor está vazia (0 factos).~n~n', [])
    ;   length(Lista, Total),
        format('~N================================================================================~n', []),
        format('                 FACTOS ATIVOS NA MEMÓRIA DE TRABALHO (~w factos)              ~n', [Total]),
        format('================================================================================~n', []),
        forall(member((N, F), Lista),
            format('  [#~|~`0t~d~2+] ~w~n', [N, F])),
        format('================================================================================~n~n', [])
    ).

limpar :-
    retail_engine:reset_session,
    retail_interactive:clear_dialogue_log,
    retail_interactive:clear_mock_answers,
    format('~N[OK] Memória de sessão e histórico reinicializados com sucesso.~n~n', []).

testar :-
    format('~N================================================================================~n', []),
    format('  A EXECUTAR SUÍTE DE TESTES AUTOMATIZADOS PLUNIT (91 TESTES)                  ~n', []),
    format('================================================================================~n~n', []),
    ensure_loaded([
        tests/test_retail_rules,
        tests/test_retail_interactive,
        tests/test_retail_explainability,
        tests/test_retail_api,
        tests/test_retail_expert_scenarios,
        tests/test_inference_engine
    ]),
    plunit:run_tests,
    format('~N================================================================================~n', []),
    format('  >>> [CONCLUÍDO] Todos os testes executados com sucesso! <<<~n', []),
    format('================================================================================~n~n', []).

:- initialization(iniciar, main).
