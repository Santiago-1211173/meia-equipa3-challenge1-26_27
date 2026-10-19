:- module(retail_engine, [
    load_knowledge_base/1,      % +KBName — loads a retail knowledge base by name
    run_engine/1,               % -ResultDict — executes deduction and returns structured result
    run_interactive/1,          % -ResultDict — executes interactive deduction from empty/seed state
    run_interactive/2,          % +InitialFacts, -ResultDict — executes interactive deduction with initial facts
    evaluate_facts/2,           % +InitialFacts, -ResultDict — executes batch deduction on given facts
    assert_initial_facts_list/1,% +FactsList — asserts initial facts with sequencing
    reset_session/0,            % Clears dynamic session facts while preserving rules
    get_all_facts/1,            % -FactsList — lists all current facts in memory
    explain_how/2,              % +FactInput, -ExplanationList — explains how a fact was derived (Via 1: How)
    como/1,                     % +FactInput — prints terminal deductive explanation in Portuguese (Via 1: How)
    why_ask/1,                  % -ExplanationText — explains why the active rule is querying (Via 2: Why Ask)
    why_ask/2,                  % +RuleId, -ExplanationText — explains why a given rule queries (Via 2: Why Ask)
    why_ask/3,                  % +DadoInput, +BaseFacts, -ResponseDict — Why Ask dynamic causal explanation
    why_ask/0,                  % prints active Why Ask explanation to stdout (Via 2: Why Ask)
    explain_why_premise/3,      % +DadoInput, +BaseFacts, -ResponseDict — Why Ask dynamic causal explanation
    output_why/1,               % -JustificationList — synthesizes executive decision justifications (Via 3: Output Why)
    output_why/0,               % prints executive decision justifications to stdout (Via 3: Output Why)
    decision_justification/2,   % -Decision, -JustificationList — retrieves decision and justification (Via 3: Output Why)
    explain_whynot/2,           % +FactInput, -ExplanationList — explains why a fact failed (Via 4: Why Not)
    whynot/1,                   % +FactInput — prints why a fact failed to stdout in Portuguese (Via 4: Why Not)
    what_if/3,                  % +FactosAdicionar, +FactosRemover, -ResultadoComparativo — counterfactual sandbox (Via 5: What-If)
    obtem_facto/2,              % ?FactTerm, -FactId — retrieves or queries an askable fact
    regista_resposta/2,         % +FactTerm, -FactId — asserts a user-provided fact
    reset_engine/0,             % Resets dynamic session memory and state
    regra_ativa/2,              % Dynamic active candidate rule tracking for Why Ask
    regra_info/3,               % Normative rule description and family
    perguntavel/1,              % Askable attributes
    ja_perguntado/1,            % Loop prevention tracking
    facto/2,                    % Dynamic facts in working memory
    op(220, xfx, entao),
    op(35, xfy, se),
    op(240, fx, regra),
    op(500, fy, nao),
    op(600, xfy, e)
]).

/** <module> Retail Expert Inference Engine (Levi's Returns & Exchanges)
 *
 * Implements the isolated and extensible retail expert inference engine for
 * MEIA 2026/2027 Challenge 1 (Grupo 3: SmartCloth AI).
 *
 * Architecture & Parity:
 * - Isolated in `src/core/retail_engine/` to guarantee strict namespace separation
 *   from the academic reference engine (`src/core/inference/` sp_exp2.pl).
 * - Inherits and exports the canonical DSL operators:
 *     op(220, xfx, entao), op(35, xfy, se), op(240, fx, regra),
 *     op(500, fy, nao), op(600, xfy, e).
 * - Dialogic acquisition based on Prof. ACM mechanics (obtem_facto/2, perguntavel/1),
 *   safe handling of "não sei" without logical negation pollution, contextual
 *   tracking of "porquê?" (Why Ask) via active candidate rules, and full
 *   causal attribution (justifica/3 with origin 'utilizador').
 */

% Operator definitions for the canonical expert system DSL
:- op(220, xfx, entao).
:- op(35, xfy, se).
:- op(240, fx, regra).
:- op(500, fy, nao).
:- op(600, xfy, e).

% Dynamic predicate declarations local to retail_engine namespace
:- dynamic facto/2.
:- dynamic ultimo_facto/1.
:- dynamic justifica/3.
:- dynamic (regra)/1.
:- dynamic facto_dispara_regras/2.
:- dynamic perguntavel/1.
:- dynamic ja_perguntado/1.
:- dynamic regra_ativa/2.
:- dynamic regra_info/3.

% Import interactive dialogue manager
:- use_module(interactive, [
    perguntar/3,
    formatar_pergunta/2,
    explicar_porque_pergunta/2,
    set_mock_answers/1,
    clear_mock_answers/0,
    add_mock_answer/2,
    tem_mock_resposta/1,
    obter_mock_resposta/2,
    get_dialogue_log/1,
    clear_dialogue_log/0,
    enable_interactive_mode/0,
    disable_interactive_mode/0,
    modo_interativo/1,
    normalizar_resposta/3
]).

% ==============================================================================
% Knowledge Base Management
% ==============================================================================

%!  load_knowledge_base(+KBName) is det.
%
%   Resets dynamic memory and loads the specified retail knowledge base into
%   the retail_engine module context.
%
%   @param KBName Atom or string designating the KB file without extension.
load_knowledge_base(KBName) :-
    reset_engine,
    resolve_kb_path(KBName, Path),
    load_files(Path, [module(retail_engine)]).

%!  resolve_kb_path(+KBName, -Path) is det.
%
%   Resolves filesystem path to a retail knowledge base file across local and
%   container execution environments.
resolve_kb_path(KBName, Path) :-
    atom_concat(KBName, '.pl', KBFile),
    (   % 1. Relative to working directory in container or project
        atomic_list_concat(['src/core/retail_engine/kb/', KBFile], Candidate1),
        exists_file(Candidate1)
    ->  Path = Candidate1
    ;   % 2. Relative to this module file location
        source_file(retail_engine:load_knowledge_base(_), EngineFile),
        file_directory_name(EngineFile, EngineDir),
        atomic_list_concat([EngineDir, '/kb/', KBFile], Candidate2),
        exists_file(Candidate2)
    ->  Path = Candidate2
    ;   % 3. Relative to workspace root directory
        atomic_list_concat(['prolog_engine/src/core/retail_engine/kb/', KBFile], Candidate3),
        exists_file(Candidate3)
    ->  Path = Candidate3
    ;   % 4. Direct file name
        exists_file(KBFile)
    ->  Path = KBFile
    ;   throw(error(existence_error(source_sink, KBName), load_knowledge_base/1))
    ).

reset_session :-
    retractall(facto(_, _)),
    retractall(ultimo_facto(_)),
    retractall(justifica(_, _, _)),
    retractall(ja_perguntado(_)),
    retractall(regra_ativa(_, _)),
    clear_dialogue_log.

%!  reset_engine is det.
%
%   Clears all dynamic facts, justifications, rule declarations, metaknowledge,
%   dialogue state, and mock queues from the retail_engine memory.
reset_engine :-
    reset_session,
    retractall(regra(_)),
    retractall(facto_dispara_regras(_, _)),
    retractall(perguntavel(_)),
    retractall(regra_info(_, _, _)),
    clear_mock_answers,
    disable_interactive_mode.

% ==============================================================================
% Engine Execution & Inspection
% ==============================================================================

%!  run_engine(-ResultDict) is det.
%
%   Executes forward-chaining deduction over the currently loaded retail knowledge base.
%
%   @param ResultDict Output dict containing execution metrics and derived facts.
run_engine(ResultDict) :-
    count_facts(InitialCount),
    arranca_motor,
    count_facts(TotalCount),
    find_derived_facts(InitialCount, DerivedFacts),
    length(DerivedFacts, DerivedCount),
    (   facto(_, decisao(Decisao))
    ->  true
    ;   Decisao = nao_concluido
    ),
    output_why(Justifications),
    ResultDict = _{
        status: "success",
        decision: Decisao,
        justification: Justifications,
        initial_facts_count: InitialCount,
        derived_facts_count: DerivedCount,
        total_facts: TotalCount,
        derived_facts: DerivedFacts
    }.

%!  run_interactive(-ResultDict) is det.
%!  run_interactive(+InitialFacts, -ResultDict) is det.
%
%   Executes deduction in active dialogic mode. If starting facts are omitted,
%   queries observable starting attributes (e.g. colaborador_autorizado).
%   Missing premises needed by candidate rules are actively requested.
run_interactive(ResultDict) :-
    run_interactive([], ResultDict).

run_interactive(InitialFacts, ResultDict) :-
    setup_call_cleanup(
        enable_interactive_mode,
        (
            ensure_kb_loaded,
            reset_session,
            assert_initial_facts_list(InitialFacts),
            garantir_factos_iniciais_interativos,
            run_engine(BaseResult),
            get_dialogue_log(DialogueLog),
            (   facto(_, decisao(Decisao))
            ->  true
            ;   Decisao = nao_concluido
            ),
            ResultDict = BaseResult.put(_{
                decision: Decisao,
                dialogue_log: DialogueLog
            })
        ),
        disable_interactive_mode
    ).

%!  evaluate_facts(+InitialFacts, -ResultDict) is det.
%
%   Loads retail KB if needed, resets session, asserts InitialFacts,
%   executes forward-chaining deduction, and returns ResultDict.
evaluate_facts(InitialFacts, ResultDict) :-
    ensure_kb_loaded,
    reset_session,
    assert_initial_facts_list(InitialFacts),
    run_engine(ResultDict).

ensure_kb_loaded :-
    (   regra(_)
    ->  true
    ;   load_knowledge_base(retail_rules)
    ).

garantir_factos_iniciais_interativos :-
    % 1. Stage 0: Colaborador autorizado
    (   facto(_, colaborador_autorizado(_))
    ->  true
    ;   obtem_facto(colaborador_autorizado(_), _)
    ->  true
    ;   true
    ),
    (   facto(_, colaborador_autorizado(false))
    ->  % Precedence 1: unauthorized operator halts intake immediately
        true
    ;   % 2. Core stage 3a paragens, product condition, and proof
        obter_se_ausente(sku_reconhecido(_)),
        (   facto(_, sku_reconhecido(false))
        ->  true
        ;   obter_se_ausente(categoria_produto(_)),
            obter_se_ausente(estado_produto(_)),
            obter_se_ausente(comprovativo(_))
        )
    ).

obter_se_ausente(Template) :-
    (   facto(_, Template)
    ->  true
    ;   obtem_facto(Template, _)
    ->  true
    ;   true
    ).

assert_initial_facts_list(FactsList) :-
    length(FactsList, Count),
    retractall(ultimo_facto(_)),
    asserta(ultimo_facto(Count)),
    assert_initial_facts_recursive(FactsList, 1).

assert_initial_facts_recursive([], _).
assert_initial_facts_recursive([F|Rest], N) :-
    assertz(facto(N, F)),
    N1 is N + 1,
    assert_initial_facts_recursive(Rest, N1).

%!  count_facts(-Count) is det.
%
%   Counts current facts in working memory.
count_facts(Count) :-
    (   ultimo_facto(Count)
    ->  true
    ;   aggregate_all(count, facto(_, _), Count)
    ).

%!  has_fact(+FactTerm) is semidet.
%
%   Succeeds if FactTerm is asserted in working memory.
has_fact(FactTerm) :-
    facto(_, FactTerm).

%!  find_derived_facts(+InitialCount, -DerivedFacts) is det.
%
%   Retrieves structured details of all facts derived after the initial set.
find_derived_facts(InitialCount, DerivedFacts) :-
    findall(
        _{id: N, fact: FactStr, rule_id: RuleID, justified_by: NormJustifiedBy},
        (
            facto(N, FactTerm),
            N > InitialCount,
            term_string(FactTerm, FactStr),
            (   justifica(N, RuleID, RawJustifiedBy)
            ->  normalize_justification(RawJustifiedBy, NormJustifiedBy)
            ;   RuleID = 0, NormJustifiedBy = []
            )
        ),
        DerivedFacts
    ).

normalize_justification([], []).
normalize_justification([H|T], [NormH|NormT]) :-
    (   integer(H)
    ->  NormH = H
    ;   term_string(H, NormH)
    ),
    normalize_justification(T, NormT).

%!  get_all_facts(-FactsList) is det.
%
%   Retrieves all facts currently present in working memory.
get_all_facts(FactsList) :-
    findall(
        _{id: N, fact: FactStr},
        (
            facto(N, F),
            term_string(F, FactStr)
        ),
        FactsList
    ).

% ==============================================================================
% 5-Way Explainability Architecture (Explicabilidade em 5 Vias)
% ==============================================================================

% ------------------------------------------------------------------------------
% VIA 1: Como? (How — Rastreabilidade Causal Dedutiva)
% ------------------------------------------------------------------------------

%!  explain_how(+FactInput, -ExplanationList) is det.
%
%   Produces a causal explanation trace for a derived or initial fact,
%   recognizing evidence provided directly by the user ('utilizador')
%   and formatting formal rule identifiers with brackets (e.g. [PC-001]).
%   Accepts an integer FactId, a compound fact term (e.g. decisao(permitir)),
%   an atom or string.
explain_how(FactInput, ExplanationList) :-
    (   resolve_fact_id(FactInput, FactId)
    ->  explain_how_internal(FactId, [], ExplanationList)
    ;   format(string(Msg), "Conclusion not reached for ~w", [FactInput]),
        ExplanationList = [Msg]
    ).

explain_how_internal(FactId, Visited, Explanations) :-
    (   member(FactId, Visited)
    ->  Explanations = []
    ;   justifica(FactId, utilizador, _)
    ->  facto(FactId, FactTerm),
        format(string(Line), "Fact ~w -> ~w was provided by user (operador)", [FactId, FactTerm]),
        Explanations = [Line]
    ;   justifica(FactId, RuleId, LFactos)
    ->  facto(FactId, FactTerm),
        format_rule_id(RuleId, FormattedRule),
        format(string(Line1), "Fact ~w -> ~w concluded by rule ~w", [FactId, FactTerm, FormattedRule]),
        format(string(Line2), "Based on facts: ~w", [LFactos]),
        explain_supporting_facts(LFactos, [FactId|Visited], SubExplanations),
        append([[Line1, Line2], SubExplanations], Explanations)
    ;   facto(FactId, FactTerm)
    ->  format(string(Line), "Fact ~w -> ~w was an initial fact", [FactId, FactTerm]),
        Explanations = [Line]
    ;   Explanations = []
    ).

explain_supporting_facts([], _, []).
explain_supporting_facts([I|Rest], Visited, Explanations) :-
    (   integer(I)
    ->  explain_how_internal(I, Visited, ExpI)
    ;   format(string(CondLine), "Condition ~w is verified", [I]),
        ExpI = [CondLine]
    ),
    explain_supporting_facts(Rest, Visited, ExpRest),
    append(ExpI, ExpRest, Explanations).

%!  como(+FactInput) is det.
%
%   Prints the full deductive causal trace of a fact to standard output in Portuguese,
%   distinguishing user-provided facts ('utilizador') from initial facts and rule deductions,
%   and formatting formal retail rule identifiers with brackets (e.g. [PC-001]).
como(FactInput) :-
    (   resolve_fact_id(FactInput, FactId)
    ->  como_internal(FactId, 0, [])
    ;   integer(FactInput)
    ->  format("Facto nº ~w não existe na memória de trabalho.~n", [FactInput])
    ;   format("O facto '~w' não foi derivado nem existe na memória de trabalho.~n", [FactInput])
    ).

como_internal(FactId, Level, Visited) :-
    (   member(FactId, Visited)
    ->  true
    ;   justifica(FactId, utilizador, _)
    ->  facto(FactId, FactTerm),
        indent_prefix(Level, Prefix),
        format("~wO facto nº ~w -> ~w foi fornecido pelo utilizador (operador de balcão).~n", [Prefix, FactId, FactTerm])
    ;   justifica(FactId, RuleId, LFactos)
    ->  facto(FactId, FactTerm),
        indent_prefix(Level, Prefix),
        format_rule_id(RuleId, FormattedRule),
        format("~wConcluiu o facto nº ~w -> ~w pela regra ~w com base nos factos: ~w.~n", [Prefix, FactId, FactTerm, FormattedRule, LFactos]),
        SubLevel is Level + 1,
        como_supporting_facts(LFactos, SubLevel, [FactId|Visited])
    ;   facto(FactId, FactTerm)
    ->  indent_prefix(Level, Prefix),
        format("~wO facto nº ~w -> ~w era um facto inicial da base.~n", [Prefix, FactId, FactTerm])
    ;   true
    ).

como_supporting_facts([], _, _).
como_supporting_facts([I|Rest], Level, Visited) :-
    (   integer(I)
    ->  como_internal(I, Level, Visited)
    ;   indent_prefix(Level, Prefix),
        format("~wCondição ~w verificada.~n", [Prefix, I])
    ),
    como_supporting_facts(Rest, Level, Visited).

resolve_fact_id(FactInput, FactId) :-
    integer(FactInput),
    facto(FactInput, _),
    FactId = FactInput,
    !.
resolve_fact_id(FactInput, FactId) :-
    \+ integer(FactInput),
    parse_fact_input(FactInput, RawTerm),
    normalize_target_fact(RawTerm, FactTerm),
    facto(FactId, FactTerm),
    !.

format_rule_id(RuleId, Formatted) :-
    (   integer(RuleId)
    ->  format(string(Formatted), "~w", [RuleId])
    ;   atom(RuleId), sub_atom(RuleId, 0, 1, _, '[')
    ->  Formatted = RuleId
    ;   format(string(Formatted), "[~w]", [RuleId])
    ).

% ------------------------------------------------------------------------------
% VIA 2: Porquê da Pergunta? (Why Ask — Interrogação Contextual)
% ------------------------------------------------------------------------------

%!  why_ask(-ExplanationText) is det.
%
%   Provides the contextual justification for the active candidate rule
%   currently interrogating the operator.
why_ask(ExplanationText) :-
    (   regra_ativa(RuleId, _)
    ->  why_ask(RuleId, ExplanationText)
    ;   ExplanationText = "--- [PORQUÊ DA PERGUNTA] --- Não há nenhuma regra candidata ativa no momento."
    ),
    !.

%!  why_ask(+RuleId, -ExplanationText) is det.
%
%   Provides the normative justification for a given rule identifier.
why_ask(RuleId, ExplanationText) :-
    explicar_porque_pergunta(RuleId, ExplanationText),
    !.

%!  why_ask is det.
%
%   Prints the active Why Ask explanation to standard output.
why_ask :-
    why_ask(Text),
    format("~s~n", [Text]).

%!  why_ask(+DadoInput, +BaseFacts, -ResponseDict) is det.
%!  explain_why_premise(+DadoInput, +BaseFacts, -ResponseDict) is det.
%
%   Dynamically deduces Why Ask causal explanation for an input premise code
%   (e.g. "IN-001" or "mercado") given a partial set of observed base facts.
%   Identifies candidate rules reading this input (regras_dependentes), evaluates
%   rules whose remaining conditions are already satisfied in working memory
%   (regras_em_espera), and builds a structured explanation response.
explain_why_premise(DadoInput, BaseFacts, ResponseDict) :-
    ensure_kb_loaded,
    snapshot_working_memory(Snapshot),
    setup_call_cleanup(
        true,
        executar_explain_why(DadoInput, BaseFacts, ResponseDict),
        restore_working_memory(Snapshot)
    ).

why_ask(DadoInput, BaseFacts, ResponseDict) :-
    explain_why_premise(DadoInput, BaseFacts, ResponseDict).

executar_explain_why(DadoInput, BaseFacts, ResponseDict) :-
    resolve_dado_info(DadoInput, Codigo, DadoStr, Template, AttrList),
    (   catch(formatar_pergunta(Template, PerguntaText), _, fail)
    ->  true
    ;   format(string(PerguntaText), "Qual é o valor para o atributo ~w?", [DadoStr])
    ),

    % Setup partial scenario in working memory and deduce derived facts
    reset_session,
    normalize_fact_list(BaseFacts, ParsedFacts),
    assert_initial_facts_list(ParsedFacts),
    run_engine(_),

    % 1. Find all rules dependent on this premise's attribute(s)
    findall(RuleID, (
        regra RuleID se LHS entao _,
        flatten_lhs(LHS, Flat),
        member(P, Flat),
        premise_is_in_attrs(AttrList, P)
    ), DepRulesRaw),
    sort(DepRulesRaw, DepRulesSorted),
    maplist(term_to_string_safe, DepRulesSorted, RegrasDependentes),

    % 2. Find rules waiting solely for this premise
    findall(EsperaDict, (
        member(RuleID, DepRulesSorted),
        regra RuleID se LHS entao RHS,
        \+ facto(_, regra_disparada(RuleID)),
        flatten_lhs(LHS, Flat),
        partition(premise_is_in_attrs(AttrList), Flat, CondsDado, OtherConds),
        CondsDado \== [],
        forall(member(C, OtherConds), condicao_satisfeita(C)),
        term_to_string_safe(RuleID, RuleIDStr),
        extract_rule_conclusions(RHS, Conclusoes),
        format_condicoes_do_dado(CondsDado, CondicoesDoDado),
        (   regra_info(RuleID, Familia, Desc)
        ->  format(string(NomeRegra), "[~w] ~w", [RuleID, Desc]),
            term_to_string_safe(Familia, ModuloStr)
        ;   format(string(NomeRegra), "[~w] Regra ~w", [RuleID, RuleID]),
            ModuloStr = "geral"
        ),
        EsperaDict = _{
            codigoRegra: RuleIDStr,
            codigo_regra: RuleIDStr,
            nomeRegra: NomeRegra,
            nome_regra: NomeRegra,
            modulo: ModuloStr,
            artigoId: null,
            artigo_id: null,
            conclusoes: Conclusoes,
            condicoesDoDado: CondicoesDoDado,
            condicoes_do_dado: CondicoesDoDado
        }
    ), RegrasEmEspera),

    % 3. Formulate natural language summary with causal grounding
    (   RegrasEmEspera \== []
    ->  length(RegrasEmEspera, NumEspera),
        maplist(get_rule_code_from_espera, RegrasEmEspera, RuleCodes),
        atomic_list_concat(RuleCodes, ', ', RuleCodesStr),
        (   RegrasEmEspera = [FirstEspera|_],
            get_dict(codigoRegra, FirstEspera, FirstCode),
            regra_info(FirstCode, _, FirstDesc)
        ->  format(string(ResumoText),
                "A pergunta \"~w\" é determinante para ~w regra(s) em espera (~w). Fundamento: ~w",
                [PerguntaText, NumEspera, RuleCodesStr, FirstDesc])
        ;   format(string(ResumoText),
                "A pergunta \"~w\" é determinante para ~w regra(s) em espera (~w) no pedido atual.",
                [PerguntaText, NumEspera, RuleCodesStr])
        )
    ;   (   RegrasDependentes \== []
        ->  atomic_list_concat(RegrasDependentes, ', ', RegrasDepStr),
            format(string(ResumoText),
                "A pergunta \"~w\" é avaliada pelas políticas da loja (~w); no pedido atual, nenhuma decisão terminal está imediatamente dependente desta resposta porque os restantes requisitos ainda não foram avaliados.",
                [PerguntaText, RegrasDepStr])
        ;   format(string(ResumoText),
                "A pergunta \"~w\" é requerida pelo sistema pericial para validação das regras de devolução.",
                [PerguntaText])
        )
    ),

    ResponseDict = _{
        status: "success",
        codigo: Codigo,
        dado: DadoStr,
        pergunta: PerguntaText,
        resumo: ResumoText,
        regras_dependentes: RegrasDependentes,
        regrasQueDependem: RegrasDependentes,
        regras_em_espera: RegrasEmEspera,
        regrasEmEspera: RegrasEmEspera
    }.

dado_catalog("IN-001", mercado, mercado(_), [mercado]).
dado_catalog("IN-002", tipo_loja, tipo_loja(_), [tipo_loja]).
dado_catalog("IN-003", canal_compra, canal_compra(_), [canal_compra]).
dado_catalog("IN-004", comprovativo, comprovativo(_), [comprovativo, recibo_original]).
dado_catalog("IN-005", tipo_pedido, tipo_pedido(_), [tipo_pedido]).
dado_catalog("IN-006", dias_desde_compra, dias_desde_compra(_), [dias_desde_compra, dias_desde_envio]).
dado_catalog("IN-007", sku_reconhecido, sku_reconhecido(_), [sku_reconhecido, marca, categoria_produto]).
dado_catalog("IN-008", estado_produto, estado_produto(_), [estado_produto, defeito_fabrico, personalizado_ou_alterado]).
dado_catalog("IN-009", meio_pagamento, meio_pagamento(_), [meio_pagamento, cartao_interac_presente, cartao_perdido_ou_roubado, conta_cartao_ativa, tentativa_cartao_recusada, saldo_reembolsavel, afterpay_pede_excecao]).
dado_catalog("IN-010", revendivel, revendivel(_), [revendivel]).
dado_catalog("HS-006", colaborador_autorizado, colaborador_autorizado(_), [colaborador_autorizado, funcao_colaborador, sessao_pos_propria]).
dado_catalog("EX-001", pedido_excecao, pedido_excecao(_), [pedido_excecao, concluivel_no_sistema]).
dado_catalog("EX-002", cliente_contesta, cliente_contesta(_), [cliente_contesta, cliente_agitado, cliente_fornece_dados, barreira_linguistica]).
dado_catalog("EX-008", risco_fraude, risco_fraude(_), [risco_fraude]).
dado_catalog("CH-002", encomenda_encontrada, encomenda_encontrada(_), [encomenda_encontrada, portal_online_disponivel]).
dado_catalog("EP-001", troca_apenas_tamanho, troca_apenas_tamanho(_), [troca_apenas_tamanho]).

resolve_dado_info(DadoInput, Codigo, DadoStr, Template, AttrList) :-
    normalize_dado_string(DadoInput, NormStr),
    upcase_atom(NormStr, UpperAtom),
    atom_string(UpperAtom, UpperStr),
    (   dado_catalog(UpperStr, Attr, Templ, Attrs)
    ->  Codigo = UpperStr,
        atom_string(Attr, DadoStr),
        Template = Templ,
        AttrList = Attrs
    ;   downcase_atom(NormStr, LowerAtom),
        dado_catalog(Code, LowerAtom, Templ, Attrs)
    ->  Codigo = Code,
        atom_string(LowerAtom, DadoStr),
        Template = Templ,
        AttrList = Attrs
    ;   compound(DadoInput)
    ->  functor(DadoInput, Functor, _),
        downcase_atom(Functor, LowFunctor),
        (   dado_catalog(Code, LowFunctor, Templ, Attrs)
        ->  Codigo = Code,
            atom_string(LowFunctor, DadoStr),
            Template = Templ,
            AttrList = Attrs
        ;   atom_string(LowFunctor, DadoStr),
            Codigo = DadoStr,
            Template =.. [LowFunctor, _],
            AttrList = [LowFunctor]
        )
    ;   downcase_atom(NormStr, LowAtom),
        atom_string(LowAtom, DadoStr),
        Codigo = DadoStr,
        Template =.. [LowAtom, _],
        AttrList = [LowAtom]
    ).

normalize_dado_string(Input, Str) :-
    (   string(Input) -> normalize_space(string(Str), Input)
    ;   atom(Input) -> atom_string(Input, S), normalize_space(string(Str), S)
    ;   term_string(Input, S), normalize_space(string(Str), S)
    ).

flatten_lhs([], []) :- !.
flatten_lhs([H|T], Flat) :-
    !,
    flatten_lhs(H, FlatH),
    flatten_lhs(T, FlatT),
    append(FlatH, FlatT, Flat).
flatten_lhs(X e Y, Flat) :-
    !,
    flatten_lhs(X, FlatX),
    flatten_lhs(Y, FlatY),
    append(FlatX, FlatY, Flat).
flatten_lhs(Single, [Single]).

premise_attribute(nao avalia(Expr), Attr) :- !, premise_attribute(avalia(Expr), Attr).
premise_attribute(avalia(Expr), Attr) :- !,
    (   compound(Expr)
    ->  Expr =.. [Attr|_]
    ;   Attr = Expr
    ).
premise_attribute(nao Fact, Attr) :- !, premise_attribute(Fact, Attr).
premise_attribute(Fact, Attr) :-
    compound(Fact),
    !,
    functor(Fact, Attr, _).
premise_attribute(Atom, Atom) :-
    atom(Atom),
    !.

premise_is_in_attrs(Attrs, P) :-
    premise_attribute(P, Attr),
    member(Attr, Attrs).

extract_rule_conclusions(RHS, Conclusoes) :-
    findall(ConcStr, (
        member(cria_facto(F), RHS),
        \+ (F =.. [regra_disparada|_]),
        \+ (F =.. [motivo|_]),
        term_to_string_safe(F, ConcStr)
    ), ConclusoesRaw),
    (   ConclusoesRaw \== []
    ->  Conclusoes = ConclusoesRaw
    ;   findall(ConcStr, (
            member(cria_facto(F), RHS),
            \+ (F =.. [regra_disparada|_]),
            term_to_string_safe(F, ConcStr)
        ), Conclusoes)
    ).

format_condicoes_do_dado(CondsDado, CondicoesDoDado) :-
    maplist(format_single_condicao, CondsDado, CondicoesDoDado).

format_single_condicao(Cond, Dict) :-
    premise_attribute(Cond, Attr),
    atom_string(Attr, AttrStr),
    term_to_string_safe(Cond, CondStr),
    (   condicao_satisfeita(Cond)
    ->  Cumprida = true
    ;   Cumprida = false
    ),
    Dict = _{
        nome: AttrStr,
        descricao: CondStr,
        cumprida: Cumprida,
        valor: null,
        artigoId: null
    }.

get_rule_code_from_espera(EsperaDict, Code) :-
    (   get_dict(codigoRegra, EsperaDict, Code) -> true
    ;   get_dict(codigo_regra, EsperaDict, Code)
    ).

% ------------------------------------------------------------------------------
% VIA 3: Porquê da Decisão? (Output Why — Justificação Executiva da Conclusão)
% ------------------------------------------------------------------------------

%!  output_why(-JustificationsList) is det.
%
%   Synthesizes the terminal explanations from the inference run into a list
%   of human-readable justifications citing normative rule identifiers.
output_why(JustificationsList) :-
    findall(M, facto(_, motivo(M)), Motivos),
    (   Motivos \== []
    ->  JustificationsList = Motivos
    ;   findall(JustStr,
            (
                facto(_, regra_disparada(RID)),
                (   regra_info(RID, _, Desc)
                ->  format(string(JustStr), "[~w] ~w", [RID, Desc])
                ;   format(string(JustStr), "Regra [~w] disparada", [RID])
                )
            ),
            JustificationsList
        )
    ).

%!  output_why is det.
%
%   Prints the executive decision justification summary to standard output.
output_why :-
    (   facto(_, decisao(Dec))
    ->  format("=== [PORQUÊ DA DECISÃO: ~w] ===~n", [Dec])
    ;   format("=== [PORQUÊ DA DECISÃO: NÃO CONCLUÍDO] ===~n", [])
    ),
    output_why(JustList),
    (   JustList == []
    ->  format("Sem justificações registadas na sessão atual.~n", [])
    ;   forall(member(J, JustList), format("• ~s~n", [J]))
    ).

%!  decision_justification(-Decision, -JustificationsList) is det.
%
%   Retrieves the final canonical decision along with its executive justifications.
decision_justification(Decision, JustificationsList) :-
    (   facto(_, decisao(D))
    ->  Decision = D
    ;   Decision = nao_concluido
    ),
    output_why(JustificationsList).

% ------------------------------------------------------------------------------
% VIA 4: Porque Não? (Why Not — Análise Contrafactual de Desfechos Não Atingidos)
% ------------------------------------------------------------------------------

%!  explain_whynot(+FactInput, -ExplanationList) is det.
%
%   Investigates why a candidate fact or canonical decision failed to be derived.
%   Supports compound terms, atoms (including canonical decision verbs), and strings.
explain_whynot(FactInput, ExplanationList) :-
    parse_fact_input(FactInput, RawTerm),
    normalize_target_fact(RawTerm, FactTerm),
    explain_whynot_internal(FactTerm, 1, [], ExplanationList).

%!  whynot(+FactInput) is det.
%
%   Prints the full Why Not explanation tree to standard output in Portuguese.
whynot(FactInput) :-
    explain_whynot(FactInput, ExplanationList),
    (   ExplanationList == []
    ->  format("Não foram encontradas explicações para ~w.~n", [FactInput])
    ;   forall(member(Line, ExplanationList), format("~s~n", [Line]))
    ).

normalize_target_fact(permitir, decisao(permitir)) :- !.
normalize_target_fact(recusar, decisao(recusar)) :- !.
normalize_target_fact(rever, decisao(rever)) :- !.
normalize_target_fact(encaminhar, decisao(encaminhar)) :- !.
normalize_target_fact(F, F).

explain_whynot_internal(FactTerm, _, _, [Msg]) :-
    facto(_, FactTerm),
    !,
    format(string(Msg), "The fact ~w is already true in the knowledge base", [FactTerm]).
explain_whynot_internal(FactTerm, Level, Visited, ExplanationList) :-
    encontra_regras_whynot(FactTerm, LLPF),
    LLPF \== [],
    !,
    whynot_rules_explanation(LLPF, Level, [FactTerm|Visited], ExplanationList).
explain_whynot_internal(nao FactTerm, Level, _, [Msg]) :-
    !,
    indent_prefix(Level, Prefix),
    format(string(Msg), "~wBecause: The fact ~w is true", [Prefix, FactTerm]).
explain_whynot_internal(FactTerm, Level, _, [Msg]) :-
    indent_prefix(Level, Prefix),
    format(string(Msg), "~wBecause: The fact ~w is not defined in the knowledge base", [Prefix, FactTerm]).

whynot_rules_explanation([], _, _, []).
whynot_rules_explanation([(RuleID, LPF)|RestRules], Level, Visited, Explanations) :-
    indent_prefix(Level, Prefix),
    format_rule_id(RuleID, FormattedRule),
    format(string(RuleLine), "~wBecause by rule ~w:", [Prefix, FormattedRule]),
    SubLevel is Level + 1,
    whynot_premises_explanation(LPF, SubLevel, Visited, PremiseExps),
    whynot_rules_explanation(RestRules, Level, Visited, RestExps),
    append([[RuleLine], PremiseExps, RestExps], Explanations).

whynot_premises_explanation([], _, _, []).
whynot_premises_explanation([nao avalia(X)|Rest], Level, Visited, [Line|RestExps]) :-
    !,
    indent_prefix(Level, Prefix),
    format(string(Line), "~wCondition nao ~w is false", [Prefix, X]),
    whynot_premises_explanation(Rest, Level, Visited, RestExps).
whynot_premises_explanation([avalia(X)|Rest], Level, Visited, [Line|RestExps]) :-
    !,
    indent_prefix(Level, Prefix),
    format(string(Line), "~wCondition ~w is false", [Prefix, X]),
    whynot_premises_explanation(Rest, Level, Visited, RestExps).
whynot_premises_explanation([nao X|Rest], Level, Visited, [Line|RestExps]) :-
    !,
    indent_prefix(Level, Prefix),
    format(string(Line), "~wPremise nao ~w is false", [Prefix, X]),
    whynot_premises_explanation(Rest, Level, Visited, RestExps).
whynot_premises_explanation([P|Rest], Level, Visited, Explanations) :-
    indent_prefix(Level, Prefix),
    format(string(Line), "~wPremise ~w is false", [Prefix, P]),
    SubLevel is Level + 1,
    (   \+ member(P, Visited)
    ->  explain_whynot_internal(P, SubLevel, [P|Visited], SubExps)
    ;   SubExps = []
    ),
    whynot_premises_explanation(Rest, Level, Visited, RestExps),
    append([[Line], SubExps, RestExps], Explanations).

% ------------------------------------------------------------------------------
% VIA 5: E Se? (What-If — Simulação Contrafactual em Sandbox Isolada)
% ------------------------------------------------------------------------------

%!  what_if(+FactosAdicionar, +FactosRemover, -ComparacaoResultado) is det.
%
%   Executes a counterfactual What-If simulation inside an isolated transactional sandbox.
%   Uses setup_call_cleanup/3 to guarantee that working memory (facts, justifications,
%   counters, dialogue state) is deterministically restored to its exact original state,
%   even in the event of failure or exceptions.
%
%   @param FactosAdicionar     Term or list of terms to hypothetically assert.
%   @param FactosRemover       Term or list of patterns/terms to hypothetically retract.
%   @param ComparacaoResultado Structured dict detailing baseline vs. simulated outcome diff.
what_if(FactosAdicionar, FactosRemover, ComparacaoResultado) :-
    snapshot_working_memory(Snapshot),
    setup_call_cleanup(
        true,
        executar_simulacao_what_if(FactosAdicionar, FactosRemover, ComparacaoResultado),
        restore_working_memory(Snapshot)
    ).

snapshot_working_memory(snapshot(Facts, Ultimo, Justs, JaPerg)) :-
    findall(facto(N, F), facto(N, F), Facts),
    (   ultimo_facto(U) -> Ultimo = U ; Ultimo = 0 ),
    findall(justifica(N, R, P), justifica(N, R, P), Justs),
    findall(ja_perguntado(T), ja_perguntado(T), JaPerg).

restore_working_memory(snapshot(Facts, Ultimo, Justs, JaPerg)) :-
    retractall(facto(_, _)),
    retractall(ultimo_facto(_)),
    retractall(justifica(_, _, _)),
    retractall(ja_perguntado(_)),
    retractall(regra_ativa(_, _)),
    maplist(assertz, Facts),
    asserta(ultimo_facto(Ultimo)),
    maplist(assertz, Justs),
    maplist(assertz, JaPerg).

executar_simulacao_what_if(FactosAdicionar, FactosRemover, ComparacaoResultado) :-
    % 1. Capture baseline state
    (   facto(_, decisao(BaseDec))
    ->  BaselineDecision = BaseDec
    ;   BaselineDecision = nao_concluido
    ),
    output_why(BaselineJustification),

    % 2. Extract baseline initial/base facts
    findall(F,
        (
            facto(N, F),
            is_base_fact(N)
        ),
        BaseFacts),

    % 3. Normalize input lists
    normalize_fact_list(FactosAdicionar, AddList),
    normalize_fact_list(FactosRemover, RemPatterns),

    % 4. Filter base facts by removal patterns and replaced templates
    exclude(matches_removal(RemPatterns, AddList), BaseFacts, FilteredBaseFacts),
    append(FilteredBaseFacts, AddList, SimulatedBaseFacts),

    % 5. Execute simulation run
    reset_session,
    assert_initial_facts_list(SimulatedBaseFacts),
    run_engine(SimBaseResult),

    % 6. Extract simulated outcome
    (   facto(_, decisao(SimDec))
    ->  SimulatedDecision = SimDec
    ;   SimulatedDecision = nao_concluido
    ),
    output_why(SimulatedJustification),

    % 7. Diff outcome
    (   BaselineDecision == SimulatedDecision
    ->  DecisionChanged = false,
        format(string(ImpactSummary), "A decisão manteve-se inalterada em '~w'.", [BaselineDecision])
    ;   DecisionChanged = true,
        format(string(ImpactSummary), "A decisão mudou de '~w' para '~w' com a simulação contrafactual.", [BaselineDecision, SimulatedDecision])
    ),

    maplist(term_to_string_safe, AddList, AddedStrs),
    maplist(term_to_string_safe, RemPatterns, RemovedStrs),

    ComparacaoResultado = _{
        status: "success",
        baseline_decision: BaselineDecision,
        simulated_decision: SimulatedDecision,
        decision_changed: DecisionChanged,
        added_facts: AddedStrs,
        removed_facts: RemovedStrs,
        baseline_justification: BaselineJustification,
        simulated_justification: SimulatedJustification,
        impact_summary: ImpactSummary,
        simulated_facts_count: SimBaseResult.total_facts
    }.

is_base_fact(N) :-
    (   \+ justifica(N, _, _)
    ;   justifica(N, utilizador, _)
    ).

normalize_fact_list(L, ParsedList) :-
    is_list(L),
    !,
    maplist(parse_fact_input_safe, L, ParsedList).
normalize_fact_list(Single, [Parsed]) :-
    parse_fact_input_safe(Single, Parsed).

parse_fact_input_safe(Input, Term) :-
    (   var(Input)
    ->  Term = Input
    ;   parse_fact_input(Input, Term)
    ).

matches_removal(RemPatterns, AddList, Fact) :-
    (   member(P, RemPatterns),
        \+ \+ (P = Fact)
    )
    ;
    (   member(Add, AddList),
        compound(Add),
        compound(Fact),
        functor(Add, F, A),
        functor(Fact, F, A)
    ).

term_to_string_safe(Term, Str) :-
    (   string(Term) -> Str = Term
    ;   atom(Term) -> atom_string(Term, Str)
    ;   term_string(Term, Str)
    ).

indent_prefix(Level, Prefix) :-
    (   Level =< 1
    ->  Spaces = 0
    ;   Spaces is (Level - 1) * 2
    ),
    length(Chars, Spaces),
    maplist(=(32), Chars),
    string_codes(Prefix, Chars).

parse_fact_input(FactInput, FactTerm) :-
    (   string(FactInput)
    ->  term_string(FactTerm, FactInput)
    ;   atom(FactInput)
    ->  term_to_atom(FactTerm, FactInput)
    ;   FactTerm = FactInput
    ).

% ==============================================================================
% Dialogic Fact Acquisition (obtem_facto/2 & regista_resposta/2)
% ==============================================================================

%!  obtem_facto(?Facto, -FactoId) is nondet.
%
%   Retrieves fact ID if already in working memory. If missing, checks if
%   the attribute is declared askable (perguntavel/1) and has not been queried.
%   Marks ja_perguntado/1, queries the user/mock queue, and if answered
%   (Resp \== nao_sei), asserts the answer with origin 'utilizador'.
obtem_facto(F, N) :-
    facto(N, F),
    !.
obtem_facto(F, N) :-
    e_perguntavel(F, Template),
    \+ ja_perguntado(Template),
    assertz(ja_perguntado(Template)),
    solicita_facto(Template, F, Resp),
    Resp \== nao_sei,
    regista_resposta(Resp, N),
    facto(N, F).

e_perguntavel(F, Template) :-
    (   compound(F)
    ->  functor(F, Functor, Arity),
        functor(Template, Functor, Arity)
    ;   atom(F)
    ->  Template = F
    ;   fail
    ),
    perguntavel(Template).

solicita_facto(Template, F, Resp) :-
    perguntar(Template, F, Resp).

%!  regista_resposta(+FactTerm, -FactId) is det.
%
%   Asserts a user-supplied fact into working memory, marking its provenance
%   as 'utilizador' in justifica/3 for complete explainability auditability.
regista_resposta(FactTerm, N) :-
    retract(ultimo_facto(N1)),
    N is N1 + 1,
    asserta(ultimo_facto(N)),
    assertz(facto(N, FactTerm)),
    assertz(justifica(N, utilizador, [])).

% ==============================================================================
% Core Forward Chaining Engine Loop
% ==============================================================================

arranca_motor :-
    arranca_motor(1),
    !.

arranca_motor(N) :-
    facto(N, Facto),
    !,
    facto_dispara_regras1(Facto, LRegras),
    dispara_regras(N, Facto, LRegras),
    N1 is N + 1,
    arranca_motor(N1).
arranca_motor(_) :- !.

facto_dispara_regras1(Facto, LRegras) :-
    facto_dispara_regras(Facto, LRegras),
    !.
facto_dispara_regras1(_, []).

dispara_regras(N, Facto, [ID|LRegras]) :-
    (   regra ID se LHS entao RHS,
        facto_esta_numa_condicao(Facto, LHS),
        extrai_objetivo(RHS, Objetivo),
        setup_call_cleanup(
            asserta(regra_ativa(ID, Objetivo)),
            (
                verifica_condicoes(LHS, LFactos),
                member(N, LFactos)
            ),
            retractall(regra_ativa(ID, _))
        )
    ->  concluir(RHS, ID, LFactos)
    ;   true
    ),
    !,
    dispara_regras(N, Facto, LRegras).
dispara_regras(_, _, []) :- !.

extrai_objetivo([cria_facto(Obj)|_], Obj) :- !.
extrai_objetivo(Obj, Obj).

facto_esta_numa_condicao(F, [F e _]).
facto_esta_numa_condicao(F, [avalia(F1) e _]) :- F =.. [H|_], F1 =.. [H|_].
facto_esta_numa_condicao(F, [_ e Fs]) :- facto_esta_numa_condicao(F, [Fs]).
facto_esta_numa_condicao(F, [F]).
facto_esta_numa_condicao(F, [avalia(F1)]) :- F =.. [H|_], F1 =.. [H|_].

verifica_condicoes([nao avalia(X) e Y], [nao X|LF]) :- !,
    \+ avalia(_, X),
    verifica_condicoes([Y], LF).
verifica_condicoes([avalia(X) e Y], [N|LF]) :- !,
    avalia(N, X),
    verifica_condicoes([Y], LF).

verifica_condicoes([nao avalia(X)], [nao X]) :- !,
    \+ avalia(_, X).
verifica_condicoes([avalia(X)], [N]) :- !,
    avalia(N, X).

verifica_condicoes([nao X e Y], [nao X|LF]) :- !,
    \+ facto(_, X),
    verifica_condicoes([Y], LF).
verifica_condicoes([X e Y], [N|LF]) :- !,
    obtem_facto(X, N),
    verifica_condicoes([Y], LF).

verifica_condicoes([nao X], [nao X]) :- !,
    \+ facto(_, X).
verifica_condicoes([X], [N]) :-
    obtem_facto(X, N).

concluir([cria_facto(F)|Y], ID, LFactos) :-
    !,
    cria_facto(F, ID, LFactos),
    concluir(Y, ID, LFactos).
concluir([], _, _) :- !.

cria_facto(F, _, _) :-
    facto(_, F),
    !.
cria_facto(F, ID, LFactos) :-
    retract(ultimo_facto(N1)),
    N is N1 + 1,
    asserta(ultimo_facto(N)),
    assertz(justifica(N, ID, LFactos)),
    assertz(facto(N, F)),
    !.

avalia(N, P) :-
    P =.. [Functor, Entidade, Operando, Valor],
    P1 =.. [Functor, Entidade, Valor1],
    obtem_facto(P1, N),
    compara(Valor1, Operando, Valor).
avalia(N, P) :-
    P =.. [Functor, Operando, Valor],
    P1 =.. [Functor, Valor1],
    obtem_facto(P1, N),
    compara(Valor1, Operando, Valor).

compara(V1, ==, V) :- V1 == V.
compara(V1, \==, V) :- V1 \== V.
compara(V1, >, V) :- V1 > V.
compara(V1, <, V) :- V1 < V.
compara(V1, >=, V) :- V1 >= V.
compara(V1, =<, V) :- V1 =< V.
compara(V1, in, V) :- is_list(V), member(V1, V).
compara(V1, membro, V) :- is_list(V), member(V1, V).

% ==============================================================================
% Non-interrogative Condition Checking for Whynot Analysis
% ==============================================================================

encontra_regras_whynot(Facto, LLPF) :-
    findall((ID, LPF),
        (
            regra ID se LHS entao RHS,
            member(cria_facto(Facto), RHS),
            encontra_premissas_falsas(LHS, LPF),
            LPF \== []
        ),
        LLPF).

encontra_premissas_falsas([H|T], LPF) :-
    is_list(T), T \== [],
    !,
    encontra_premissas_falsas([H], LPF1),
    encontra_premissas_falsas(T, LPF2),
    append(LPF1, LPF2, LPF).
encontra_premissas_falsas([nao X e Y], LPF) :-
    condicao_satisfeita(nao X),
    !,
    encontra_premissas_falsas([Y], LPF).
encontra_premissas_falsas([X e Y], LPF) :-
    condicao_satisfeita(X),
    !,
    encontra_premissas_falsas([Y], LPF).
encontra_premissas_falsas([nao X], []) :-
    condicao_satisfeita(nao X),
    !.
encontra_premissas_falsas([X], []) :-
    condicao_satisfeita(X),
    !.
encontra_premissas_falsas([nao X e Y], [nao X|LPF]) :-
    !,
    encontra_premissas_falsas([Y], LPF).
encontra_premissas_falsas([X e Y], [X|LPF]) :-
    !,
    encontra_premissas_falsas([Y], LPF).
encontra_premissas_falsas([nao X], [nao X]) :- !.
encontra_premissas_falsas([X], [X]).
encontra_premissas_falsas([]).

condicao_satisfeita(nao avalia(X)) :-
    !,
    \+ avalia_sem_perguntar(X).
condicao_satisfeita(avalia(X)) :-
    !,
    avalia_sem_perguntar(X).
condicao_satisfeita(nao X) :-
    !,
    \+ facto(_, X).
condicao_satisfeita(X) :-
    facto(_, X).

avalia_sem_perguntar(P) :-
    P =.. [Functor, Entidade, Operando, Valor],
    P1 =.. [Functor, Entidade, Valor1],
    facto(_, P1),
    compara(Valor1, Operando, Valor).
avalia_sem_perguntar(P) :-
    P =.. [Functor, Operando, Valor],
    P1 =.. [Functor, Valor1],
    facto(_, P1),
    compara(Valor1, Operando, Valor).
