:- module(inference_engine, [
    load_knowledge_base/1,      % +KBName — loads a knowledge base by name
    run_engine/1,               % -ResultDict — executes deduction and returns structured result
    get_all_facts/1,            % -FactsList — lists all current facts
    explain_how/2,              % +FactId, -ExplanationList — explains how a fact was derived
    explain_whynot/2,           % +FactTerm, -ExplanationList — explains why a fact failed
    reset_engine/0,             % Resets engine dynamic session state
    op(220, xfx, entao),
    op(35, xfy, se),
    op(240, fx, regra),
    op(500, fy, nao),
    op(600, xfy, e)
]).

/** <module> Academic Example Inference Engine (sp_exp2.pl from Moodle)
 *
 * Implements a non-interactive modular adaptation of the professors' reference
 * forward-chaining expert system (sp_exp2.pl) provided on Moodle in:
 * "prolog_engine/Ficheiros de Apoio Sistemas Periciais_ sp_exp1.pl, sp_exp2.pl e base de conhecimento-20260928/".
 * Features metaknowledge-driven rule triggering (facto_dispara_regras/2),
 * bidirectional explanation generation (como/1 -> how, whynot/1 -> why not),
 * negation as failure (nao), and custom DSL operators (regra, se, entao, e, nao).
 * Tested with the academic vehicles knowledge base (vehicles.pl / veiculos2.txt).
 *
 * NOTE: This academic example engine is distinct from the project's retail returns
 * domain expert engine (rules.pl / POC POST /evaluate), which addresses retail store
 * returns diagnostics.
 */

:- op(220, xfx, entao).
:- op(35, xfy, se).
:- op(240, fx, regra).
:- op(500, fy, nao).
:- op(600, xfy, e).

:- dynamic facto/2, ultimo_facto/1, justifica/3, (regra)/1, facto_dispara_regras/2.

% ==============================================================================
% Knowledge Base Management
% ==============================================================================

%!  load_knowledge_base(+KBName) is det.
%
%   Resets the engine and loads the specified knowledge base into the engine
%   module context.
%
%   @param KBName Atom or string designating the KB file without extension.
load_knowledge_base(KBName) :-
    reset_engine,
    resolve_kb_path(KBName, Path),
    load_files(Path, [module(inference_engine)]).

%!  resolve_kb_path(+KBName, -Path) is det.
%
%   Resolves the absolute or relative filesystem path to a knowledge base file.
resolve_kb_path(KBName, Path) :-
    atom_concat(KBName, '.pl', KBFile),
    (   % 1. Relative to working directory in container or project
        atomic_list_concat(['src/core/inference/kb/', KBFile], Candidate1),
        exists_file(Candidate1)
    ->  Path = Candidate1
    ;   % 2. Relative to this module file location
        source_file(inference_engine:load_knowledge_base(_), EngineFile),
        file_directory_name(EngineFile, EngineDir),
        atomic_list_concat([EngineDir, '/kb/', KBFile], Candidate2),
        exists_file(Candidate2)
    ->  Path = Candidate2
    ;   % 3. Relative to workspace root directory
        atomic_list_concat(['prolog_engine/src/core/inference/kb/', KBFile], Candidate3),
        exists_file(Candidate3)
    ->  Path = Candidate3
    ;   % 4. Direct file name
        exists_file(KBFile)
    ->  Path = KBFile
    ;   throw(error(existence_error(source_sink, KBName), load_knowledge_base/1))
    ).

%!  reset_engine is det.
%
%   Clears all dynamic facts, justifications, rule declarations, and
%   metaknowledge mappings from memory.
reset_engine :-
    retractall(facto(_, _)),
    retractall(ultimo_facto(_)),
    retractall(justifica(_, _, _)),
    retractall(regra(_)),
    retractall(facto_dispara_regras(_, _)).

% ==============================================================================
% Engine Execution & Inspection
% ==============================================================================

%!  run_engine(-ResultDict) is det.
%
%   Executes forward-chaining deduction over the loaded knowledge base.
%   Applies metaknowledge filtering to trigger candidate rules, asserting new
%   facts and logging rule justifications.
%
%   @param ResultDict Output dict containing execution metrics and derived facts.
run_engine(ResultDict) :-
    count_facts(InitialCount),
    arranca_motor,
    count_facts(TotalCount),
    find_derived_facts(InitialCount, DerivedFacts),
    length(DerivedFacts, DerivedCount),
    ResultDict = _{
        status: "success",
        initial_facts_count: InitialCount,
        derived_facts_count: DerivedCount,
        total_facts: TotalCount,
        derived_facts: DerivedFacts
    }.

count_facts(Count) :-
    (   ultimo_facto(Count)
    ->  true
    ;   aggregate_all(count, facto(_, _), Count)
    ).

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
%   Retrieves all facts currently present in the dynamic knowledge base.
%
%   @param FactsList List of dicts representing each known fact (_{id: N, fact: FactStr}).
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
% Explanation Generation (How & Why Not)
% ==============================================================================

%!  explain_how(+FactId, -ExplanationList) is det.
%
%   Produces a step-by-step justification chain explaining how a specific
%   fact was derived by the inference engine.
%
%   @param FactId          Integer identifier of the fact to justify.
%   @param ExplanationList List of strings containing human-readable reasoning traces.
explain_how(FactId, ExplanationList) :-
    (   \+ integer(FactId)
    ->  ExplanationList = ["Invalid fact ID: must be an integer"]
    ;   \+ facto(FactId, _)
    ->  format(string(Msg), "Conclusion not reached for fact ID ~w", [FactId]),
        ExplanationList = [Msg]
    ;   explain_how_internal(FactId, [], ExplanationList)
    ).

explain_how_internal(FactId, Visited, Explanations) :-
    (   member(FactId, Visited)
    ->  Explanations = []
    ;   justifica(FactId, RuleId, LFactos)
    ->  facto(FactId, FactTerm),
        format(string(Line1), "Fact ~w -> ~w concluded by rule ~w", [FactId, FactTerm, RuleId]),
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

%!  explain_whynot(+FactInput, -ExplanationList) is det.
%
%   Investigates why a candidate fact was not derived by the inference engine,
%   inspecting candidate rules and identifying unsatisfied premises.
%
%   @param FactInput       Compound term, atom, or string specifying the query fact.
%   @param ExplanationList List of strings explaining why the fact failed to hold.
explain_whynot(FactInput, ExplanationList) :-
    parse_fact_input(FactInput, FactTerm),
    explain_whynot_internal(FactTerm, 1, [], ExplanationList).

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
    format(string(RuleLine), "~wBecause by rule ~w:", [Prefix, RuleID]),
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

indent_prefix(Level, Prefix) :-
    Spaces is (Level - 1) * 2,
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
% Core Inference Engine (Forward Chaining & Pattern Matching)
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
        verifica_condicoes(LHS, LFactos),
        member(N, LFactos)
    ->  concluir(RHS, ID, LFactos)
    ;   true
    ),
    !,
    dispara_regras(N, Facto, LRegras).
dispara_regras(_, _, []) :- !.

facto_esta_numa_condicao(F, [F e _]).
facto_esta_numa_condicao(F, [avalia(F1) e _]) :- F =.. [H, H1|_], F1 =.. [H, H1|_].
facto_esta_numa_condicao(F, [_ e Fs]) :- facto_esta_numa_condicao(F, [Fs]).
facto_esta_numa_condicao(F, [F]).
facto_esta_numa_condicao(F, [avalia(F1)]) :- F =.. [H, H1|_], F1 =.. [H, H1|_].

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
    facto(N, X),
    verifica_condicoes([Y], LF).

verifica_condicoes([nao X], [nao X]) :- !,
    \+ facto(_, X).
verifica_condicoes([X], [N]) :-
    facto(N, X).

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
    facto(N, P1),
    compara(Valor1, Operando, Valor).

compara(V1, ==, V) :- V1 == V.
compara(V1, \==, V) :- V1 \== V.
compara(V1, >, V) :- V1 > V.
compara(V1, <, V) :- V1 < V.
compara(V1, >=, V) :- V1 >= V.
compara(V1, =<, V) :- V1 =< V.

encontra_regras_whynot(Facto, LLPF) :-
    findall((ID, LPF),
        (
            regra ID se LHS entao RHS,
            member(cria_facto(Facto), RHS),
            encontra_premissas_falsas(LHS, LPF),
            LPF \== []
        ),
        LLPF).

encontra_premissas_falsas([nao X e Y], LPF) :-
    verifica_condicoes([nao X], _),
    !,
    encontra_premissas_falsas([Y], LPF).
encontra_premissas_falsas([X e Y], LPF) :-
    verifica_condicoes([X], _),
    !,
    encontra_premissas_falsas([Y], LPF).
encontra_premissas_falsas([nao X], []) :-
    verifica_condicoes([nao X], _),
    !.
encontra_premissas_falsas([X], []) :-
    verifica_condicoes([X], _),
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
