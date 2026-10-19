:- encoding(utf8).
:- use_module(library(plunit)).

/** <module> Executor Autónomo de Testes Batch em SWI-Prolog
 *
 * MEIA 2026/2027 · Paradigmas de Programação em Inteligência Artificial (PPROGIA)
 * Desafio 1 · Equipa 3
 *
 * Carrega e executa a totalidade das suites de testes PLUnit do motor de retalho
 * e preservação académica, terminando com código de saída 0 (sucesso) ou 1 (falha).
 *
 * Utilização direta:
 *   swipl -s run_tests.pl
 */

% Carregamento de todas as suites PLUnit do sistema
:- [tests/test_retail_rules].
:- [tests/test_retail_interactive].
:- [tests/test_retail_explainability].
:- [tests/test_retail_api].
:- [tests/test_retail_expert_scenarios].
:- [tests/test_inference_engine].

%!  run_all is det.
%
%   Executa todas as suites PLUnit e termina com o código de saída apropriado.
run_all :-
    format('~N===============================================================~n', []),
    format('  MEIA 2026/2027 · PPROGIA · Suíte de Testes Automatizados PLUnit~n', []),
    format('  Motor Pericial de Devoluções e Trocas Levi\'s (71 Regras)~n', []),
    format('===============================================================~n~n', []),
    (   run_tests
    ->  format('~N===============================================================~n', []),
        format('  >>> [SUCESSO] 100%% dos testes PLUnit aprovados com sucesso! <<<~n', []),
        format('===============================================================~n~n', []),
        halt(0)
    ;   format('~N===============================================================~n', []),
        format('  >>> [FALHA] Ocorreram falhas durante a execução dos testes! <<<~n', []),
        format('===============================================================~n~n', []),
        halt(1)
    ).

:- initialization(run_all, main).
