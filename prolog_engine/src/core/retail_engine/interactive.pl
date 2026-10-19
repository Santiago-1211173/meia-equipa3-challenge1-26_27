:- module(retail_interactive, [
    perguntar/3,                  % +Template, +Contexto, -Resposta
    formatar_pergunta/2,          % +Template, -TextoPergunta
    explicar_porque_pergunta/2,   % +RegraID, -TextoExplicacao
    set_mock_answers/1,           % +ListAnswers
    clear_mock_answers/0,         % Clears mock answers
    add_mock_answer/2,            % +Attr, +Value
    tem_mock_resposta/1,          % +Template
    obter_mock_resposta/2,        % +Template, -Resposta
    get_dialogue_log/1,           % -Log
    clear_dialogue_log/0,
    enable_interactive_mode/0,
    disable_interactive_mode/0,
    enable_terminal_mode/0,
    disable_terminal_mode/0,
    modo_terminal_ativo/0,
    modo_interativo/1,
    normalizar_resposta/3         % +Template, +RawInput, -Normalized
]).

/** <module> Retail Engine Interactive Dialogue & Questioning Manager
 *
 * Implements the dialogic reasoning system based on Prof. ACM's mechanics
 * (MI_Perguntas_ACM.md) and Levi's retail business policies (RPAC-Team3.md).
 *
 * Key Responsibilities:
 * 1. Formulating user-friendly questions for observable floor attributes.
 * 2. Handling "porquê?" (Why Ask) inquiries by providing the active candidate
 *    rule identifier, family, target objective, and policy justification.
 * 3. Handling "não sei" (nao_sei) safely without asserting logical falsehoods.
 * 4. Tracking dialogue history and mock answer queues for automated PLUnit tests.
 */

:- use_module(library(lists)).

% ==============================================================================
% Dynamic Dialogue State
% ==============================================================================
:- dynamic mock_resposta/2.
:- dynamic mock_mode_ativo/0.
:- dynamic dialogue_log/1.
:- dynamic modo_interativo/1.
:- dynamic modo_terminal_ativo/0.

% Initial state: non-interactive by default
modo_interativo(false).

enable_interactive_mode :-
    retractall(modo_interativo(_)),
    asserta(modo_interativo(true)).

disable_interactive_mode :-
    retractall(modo_interativo(_)),
    asserta(modo_interativo(false)).

enable_terminal_mode :-
    asserta(modo_terminal_ativo).

disable_terminal_mode :-
    retractall(modo_terminal_ativo).

% ==============================================================================
% Mock Answer Management (Automated Testing Support)
% ==============================================================================

%!  set_mock_answers(+ListAnswers) is det.
%
%   Sets a list of mock answers for automated tests.
%   Supports:
%     - Template - Value
%     - Template - [Val1, Val2, ...]
%     - CompoundFactTerm (e.g., colaborador_autorizado(true))
set_mock_answers(ListAnswers) :-
    clear_mock_answers,
    asserta(mock_mode_ativo),
    maplist(register_mock_answer, ListAnswers).

register_mock_answer(Template - ValuesList) :-
    is_list(ValuesList),
    !,
    canonical_template(Template, Key),
    assertz(mock_resposta(Key, ValuesList)).
register_mock_answer(Template - SingleValue) :-
    !,
    canonical_template(Template, Key),
    assertz(mock_resposta(Key, [SingleValue])).
register_mock_answer(FactTerm) :-
    compound(FactTerm),
    canonical_template(FactTerm, Key),
    assertz(mock_resposta(Key, [FactTerm])).

canonical_template(Term, Key) :-
    (   compound(Term)
    ->  functor(Term, Functor, Arity),
        functor(Key, Functor, Arity)
    ;   atom(Term)
    ->  Key = Term
    ;   fail
    ).

clear_mock_answers :-
    retractall(mock_mode_ativo),
    retractall(mock_resposta(_, _)).

add_mock_answer(Template, Value) :-
    asserta(mock_mode_ativo),
    canonical_template(Template, Key),
    (   retract(mock_resposta(Key, ExistingList))
    ->  append(ExistingList, [Value], Updated),
        assertz(mock_resposta(Key, Updated))
    ;   assertz(mock_resposta(Key, [Value]))
    ).

tem_mock_resposta(Template) :-
    (   var(Template)
    ->  mock_resposta(Template, [H|_]),
        H \== []
    ;   canonical_template(Template, Key),
        mock_resposta(Key, [H|_]),
        H \== []
    ).

obter_mock_resposta(Template, Resposta) :-
    (   var(Template)
    ->  mock_resposta(Key, _),
        Template = Key
    ;   canonical_template(Template, Key)
    ),
    retract(mock_resposta(Key, [First|Rest])),
    !,
    (   Rest \== []
    ->  assertz(mock_resposta(Key, Rest))
    ;   true
    ),
    (   member(First, ['porquê', 'porque', 'porquê?', 'porque?', why, 'why?'])
    ->  % Mock triggered a Why Ask question!
        (   retail_engine:regra_ativa(ActiveRule, Objective)
        ->  true
        ;   ActiveRule = desconhecida, Objective = nenhum
        ),
        explicar_porque_pergunta(ActiveRule, WhyExplanation),
        assertz(dialogue_log(why_asked(Key, ActiveRule, Objective, WhyExplanation))),
        % Proceed to pop the next answer in queue
        obter_mock_resposta(Template, Resposta)
    ;   normalizar_resposta(Template, First, Resposta)
    ).

% ==============================================================================
% Dialogue History & Logging
% ==============================================================================

get_dialogue_log(Log) :-
    findall(Entry, dialogue_log(Entry), Log).

clear_dialogue_log :-
    retractall(dialogue_log(_)).

% ==============================================================================
% Interactive Question Asking (perguntar/3)
% ==============================================================================

%!  perguntar(+Template, +Contexto, -Resposta) is det.
%
%   Coordinates obtaining an answer for an askable attribute.
%   If mock answers are registered, consumes from the mock queue.
%   If running in interactive mode, prompts the user via terminal.
%   Otherwise, safely defaults to 'nao_sei' to prevent hanging in headless modes.
tem_algum_mock :-
    mock_mode_ativo,
    !.
tem_algum_mock :-
    mock_resposta(_, _),
    !.

is_terminal_thread :-
    modo_terminal_ativo,
    (   stream_property(current_input, tty(true))
    ->  true
    ;   \+ stream_property(current_input, end_of_file)
    ).

perguntar(Template, _Contexto, Resposta) :-
    formatar_pergunta(Template, QuestionText),
    assertz(dialogue_log(asked(Template, QuestionText))),
    (   tem_mock_resposta(Template)
    ->  obter_mock_resposta(Template, Resposta),
        assertz(dialogue_log(answered(Template, Resposta)))
    ;   tem_algum_mock
    ->  % In mock testing mode: unmocked questions default to nao_sei
        Resposta = nao_sei,
        assertz(dialogue_log(unknown(Template)))
    ;   is_terminal_thread
    ->  perguntar_terminal_loop(Template, QuestionText, Resposta)
    ;   % Non-interactive headless/HTTP fallback
        Resposta = nao_sei,
        assertz(dialogue_log(unknown(Template)))
    ).

perguntar_terminal_loop(Template, QuestionText, Resposta) :-
    format('~N~w~n> ', [QuestionText]),
    flush_output,
    read_line_to_string(current_input, RawInput),
    (   RawInput == end_of_file
    ->  Resposta = nao_sei,
        assertz(dialogue_log(unknown(Template)))
    ;   normalize_string_input(RawInput, NormalizedInput),
        (   member(NormalizedInput, ['porquê', 'porque', 'porquê?', 'porque?', why, 'why?'])
        ->  (   retail_engine:regra_ativa(ActiveRule, Objective)
            ->  true
            ;   ActiveRule = desconhecida, Objective = nenhum
            ),
            explicar_porque_pergunta(ActiveRule, WhyExplanation),
            format('~N~s~n~n', [WhyExplanation]),
            assertz(dialogue_log(why_asked(Template, ActiveRule, Objective, WhyExplanation))),
            % Repeat prompt
            perguntar_terminal_loop(Template, QuestionText, Resposta)
        ;   member(NormalizedInput, [nao_sei, 'não sei', ns, desconhecido, unknown, '?'])
        ->  format('~N[REGISTO] Resposta \'não sei\' anotada.~n', []),
            Resposta = nao_sei,
            assertz(dialogue_log(unknown(Template)))
        ;   normalizar_resposta(Template, NormalizedInput, Resposta)
        ->  assertz(dialogue_log(answered(Template, Resposta)))
        ;   format('~N[ERRO] Resposta inválida. Por favor responda novamente ou digite \'não sei\' ou \'porquê?\'.~n', []),
            perguntar_terminal_loop(Template, QuestionText, Resposta)
        )
    ).

normalize_string_input(Str, Atom) :-
    string(Str),
    !,
    normalize_space(string(Trimmed), Str),
    atom_string(Atom, Trimmed).
normalize_string_input(Atom, Atom).

% ==============================================================================
% Response Normalization & Fact Building
% ==============================================================================

%!  normalizar_resposta(+Template, +RawInput, -TermoFacto) is det.
%
%   Normalizes user responses into standardized domain fact terms.
normalizar_resposta(Template, RawInput, TermoFacto) :-
    (   RawInput == nao_sei
    ->  TermoFacto = nao_sei
    ;   compound(RawInput)
    ->  TermoFacto = RawInput
    ;   % Normalize boolean variations
        member(RawInput, [sim, s, true, yes, y])
    ->  montar_termo_facto(Template, true, TermoFacto)
    ;   member(RawInput, [nao, 'não', n, false, no])
    ->  montar_termo_facto(Template, false, TermoFacto)
    ;   % Numeric conversion if applicable
        atom(RawInput),
        atom_number(RawInput, Number)
    ->  montar_termo_facto(Template, Number, TermoFacto)
    ;   number(RawInput)
    ->  montar_termo_facto(Template, RawInput, TermoFacto)
    ;   % Standard atom value
        montar_termo_facto(Template, RawInput, TermoFacto)
    ).

montar_termo_facto(Template, Valor, TermoFacto) :-
    Template =.. [Functor|Args],
    (   Args = [_]
    ->  TermoFacto =.. [Functor, Valor]
    ;   Args = [Entidade, _]
    ->  TermoFacto =.. [Functor, Entidade, Valor]
    ;   TermoFacto =.. [Functor, Valor]
    ).

% ==============================================================================
% Why Ask Explanation (explicar_porque_pergunta/2)
% ==============================================================================

%!  explicar_porque_pergunta(+RegraID, -TextoExplicacao) is det.
%
%   Constructs an explanatory message showing why the active rule is requesting
%   the specified attribute, citing the rule ID, family, objective, and description.
explicar_porque_pergunta(RegraID, TextoExplicacao) :-
    (   retail_engine:regra_info(RegraID, Familia, Descricao),
        retail_engine:regra_ativa(RegraID, Objetivo)
    ->  nome_familia(Familia, NomeFamilia),
        format(string(TextoExplicacao),
            "--- [PORQUÊ DA PERGUNTA: REGRA ~w] ---~nFamília: ~w (~w)~nObjetivo em teste: ~w~nFundamento normativo: ~w",
            [RegraID, Familia, NomeFamilia, Objetivo, Descricao])
    ;   retail_engine:regra_info(RegraID, Familia, Descricao)
    ->  nome_familia(Familia, NomeFamilia),
        format(string(TextoExplicacao),
            "--- [PORQUÊ DA PERGUNTA: REGRA ~w] ---~nFamília: ~w (~w)~nFundamento normativo: ~w",
            [RegraID, Familia, NomeFamilia, Descricao])
    ;   format(string(TextoExplicacao),
            "--- [PORQUÊ DA PERGUNTA] ---~nEsta informação é necessária para avaliar as regras de elegibilidade da devolução.", [])
    ).

nome_familia(hs, "Hard Stops (Paragens Obrigatórias)").
nome_familia(pc, "Product Condition (Estado do Produto)").
nome_familia(pt, "Proof & Timeframe (Comprovativo e Prazos)").
nome_familia(ch, "Channel & Store Type (Canal e Tipo de Loja)").
nome_familia(tn, "Refund Tender (Meio de Reembolso)").
nome_familia(ep, "Exchange & Promotion (Trocas e Promoções)").
nome_familia(ex, "Manager Review & Escalation (Revisão da Gestão)").
nome_familia(ct, "Authorization & Controls (Auditoria e Controlos)").
nome_familia(bw, "Bodywear Disposition (Destino de Roupa Íntima)").
nome_familia(_, "Regras Gerais de Devolução").

% ==============================================================================
% Question Formatting for Observable Attributes
% ==============================================================================

formatar_pergunta(colaborador_autorizado(_),
    "O colaborador tem sessão e credenciais autorizadas no terminal POS? (sim/nao/porquê)").
formatar_pergunta(mercado(_),
    "Qual é o mercado da transação de retalho? (eua/canada/porquê)").
formatar_pergunta(tipo_loja(_),
    "Qual é o tipo da loja recetora? (mainline/outlet/porquê)").
formatar_pergunta(canal_compra(_),
    "Qual foi o canal de compra original? (mainline/outlet/levi_com/levi_ca/grossista/franquia_canada/porquê)").
formatar_pergunta(comprovativo(_),
    "Qual o comprovativo de compra apresentado pelo cliente? (recibo_impresso/recibo_digital/confirmacao_encomenda/recibo_oferta/consulta_transacao/foto_recibo/consulta_backpocket/nenhum/porquê)").
formatar_pergunta(tipo_pedido(_),
    "Qual é o tipo de pedido formulado pelo cliente? (devolucao/troca/ajuste_preco/porquê)").
formatar_pergunta(dias_desde_compra(_),
    "Quantos dias decorreram desde a data da compra? (número de dias/porquê)").
formatar_pergunta(dias_desde_envio(_),
    "Quantos dias decorreram desde o envio da encomenda online? (número de dias/porquê)").
formatar_pergunta(sku_reconhecido(_),
    "O código SKU do artigo é reconhecido no catálogo do sistema POS? (sim/nao/porquê)").
formatar_pergunta(marca(_),
    "Qual é a marca do artigo? (levis/dockers/ls_signature/beyond_yoga/outra/porquê)").
formatar_pergunta(personalizado_ou_alterado(_),
    "O artigo foi personalizado, alterado ou embainhado? (sim/nao/porquê)").
formatar_pergunta(categoria_produto(_),
    "Qual é a categoria do produto? (vestuario_geral/bodywear/acessorios/porquê)").
formatar_pergunta(estado_produto(_),
    "Qual é o estado físico do artigo? (nao_usado_com_etiquetas/nao_usado_etiquetas_soltas/nao_usado_sem_etiquetas/claramente_usado/lavado/sujo_contaminado_inseguro/porquê)").
formatar_pergunta(defeito_fabrico(_),
    "O artigo apresenta defeito comprovado de fabrico? (sim/nao/porquê)").
formatar_pergunta(meio_pagamento(_),
    "Qual foi o meio de pagamento original utilizado na compra? (credito/debito/numerario/afterpay/gift_card/paypal_venmo/interac/porquê)").
formatar_pergunta(revendivel(_),
    "O artigo está apto para revenda imediata na área de vendas? (sim/nao/porquê)").
formatar_pergunta(encomenda_encontrada(_),
    "A encomenda online foi localizada no sistema de encomendas? (sim/nao/porquê)").
formatar_pergunta(portal_online_disponivel(_),
    "O portal de devoluções online está disponível e operacional? (sim/nao/porquê)").
formatar_pergunta(cliente_fornece_dados(_),
    "O cliente sem recibo forneceu dados de identificação pessoal? (sim/nao/porquê)").
formatar_pergunta(barreira_linguistica(_),
    "Existe barreira linguística insuperável que impeça a recolha de dados? (sim/nao/porquê)").
formatar_pergunta(troca_apenas_tamanho(_),
    "A troca solicitada é apenas de tamanho para o mesmo modelo e cor? (sim/nao/porquê)").
formatar_pergunta(cartao_perdido_ou_roubado(_),
    "O cartão bancário original foi reportado como perdido ou roubado? (sim/nao/porquê)").
formatar_pergunta(conta_cartao_ativa(_),
    "A conta bancária associada ao cartão original continua ativa? (sim/nao/porquê)").
formatar_pergunta(tentativa_cartao_recusada(_),
    "A tentativa de estorno para o cartão original foi recusada pelo terminal POS? (sim/nao/porquê)").
formatar_pergunta(cartao_interac_presente(_),
    "O cartão Interac físico de débito canadiano está presente em loja? (sim/nao/porquê)").
formatar_pergunta(embalagem_intacta(_),
    "A embalagem original do artigo de bodywear está intacta e selada? (sim/nao/porquê)").
formatar_pergunta(pecas_em_falta(_),
    "Há peças ou unidades em falta no conjunto multipack de bodywear? (sim/nao/porquê)").
formatar_pergunta(cliente_contesta(_),
    "O cliente contesta a recusa regulamentar inicial de balcão? (sim/nao/porquê)").
formatar_pergunta(cliente_agitado(_),
    "O cliente apresenta comportamento hostil, agressivo ou agitado? (sim/nao/porquê)").
formatar_pergunta(funcao_colaborador(_),
    "Qual é a função do colaborador no POS? (vendedor/gerente/supervisor/porquê)").
formatar_pergunta(sessao_pos_propria(_),
    "A transação está a ser efetuada na sessão de POS própria do colaborador? (sim/nao/porquê)").
formatar_pergunta(stylist_venda_original(_),
    "Foi identificado o Stylist que realizou a venda original? (sim/nao/porquê)").
formatar_pergunta(recibo_entregue(_),
    "O cliente entregou o recibo original em papel ao colaborador? (sim/nao/porquê)").
formatar_pergunta(no_sortido(_),
    "O artigo devolvido pertence ao sortido ativo da loja recetora? (sim/nao/porquê)").
formatar_pergunta(artigo_em_saldo(_),
    "O artigo encontra-se atualmente em saldo ou liquidação? (sim/nao/porquê)").
formatar_pergunta(artigo_entre_canais(_),
    "Trata-se de devolução entre canais de venda distintos? (sim/nao/porquê)").
formatar_pergunta(saldo_reembolsavel(_),
    "Existe saldo monetário remanescente a reembolsar ao cliente? (sim/nao/porquê)").
formatar_pergunta(afterpay_pede_excecao(_),
    "O cliente solicita exceção de meio de reembolso para devolução Afterpay? (sim/nao/porquê)").
formatar_pergunta(promocao_escaloes(_),
    "A compra original beneficiou de promoção por escalões? (sim/nao/porquê)").
formatar_pergunta(risco_fraude(_),
    "Qual o nível de risco de fraude avaliado pela gestão? (baixo/medio/alto/porquê)").
formatar_pergunta(concluivel_no_sistema(_),
    "A exceção de gerência é tecnicamente concluível no sistema POS? (sim/nao/porquê)").
formatar_pergunta(Template, Texto) :-
    (   compound(Template)
    ->  functor(Template, Functor, _)
    ;   atom(Template)
    ->  Functor = Template
    ;   Functor = atributo_desconhecido
    ),
    format(string(Texto), "Qual é o valor para o atributo ~w? (valor/nao_sei/porquê)", [Functor]).
