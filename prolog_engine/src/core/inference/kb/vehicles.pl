:- module(vehicles_kb, []).

/** <module> Academic Vehicles Knowledge Base (veiculos2.txt from Moodle)
 *
 * Example knowledge base defining facts, rules, and metaknowledge for
 * vehicle classification based on payload capacity, gross weight, and type.
 * Adapted directly from veiculos2.txt provided in the professors' Moodle files
 * ("prolog_engine/Ficheiros de Apoio Sistemas Periciais_ sp_exp1.pl, sp_exp2.pl e base de conhecimento-20260928/").
 * Used for testing and validation of the sp_exp2.pl academic inference engine.
 */

:- use_module('../engine').

:- dynamic facto/2, ultimo_facto/1, facto_dispara_regras/2, (regra)/1.

% ==============================================================================
% Metaconhecimento (Metaknowledge)
% Maps fact patterns to candidate rule IDs for forward-chaining activation
% ==============================================================================

facto_dispara_regras(tipo(_, passageiros), [1, 3, 8]).
facto_dispara_regras(tipo(_, mercadorias), [2, 8]).
facto_dispara_regras(tipo(_, misto), [4]).
facto_dispara_regras(lotacao(_, _), [5, 7]).
facto_dispara_regras(peso(_, _), [6, 7]).
facto_dispara_regras(classe(_, ligeiro), [1]).
facto_dispara_regras(classe(_, pesado), [2, 3, 4]).

% ==============================================================================
% Estado Inicial (Initial State Counters)
% ==============================================================================

ultimo_facto(3).

% ==============================================================================
% Regras de Inferência (Deductive Rules)
% regra ID se LHS entao RHS
% ==============================================================================

regra 1 se [tipo(V, passageiros) e classe(V, ligeiro)] entao [cria_facto(ligeiro(V, carro))].
regra 2 se [tipo(V, mercadorias) e classe(V, pesado)] entao [cria_facto(pesado(V, camiao))].
regra 3 se [tipo(V, passageiros) e classe(V, pesado)] entao [cria_facto(pesado(V, autocarro))].
regra 4 se [tipo(V, misto) e classe(V, pesado)] entao [cria_facto(pesado(V, camioneta))].
regra 5 se [avalia(lotacao(V, >, 9))] entao [cria_facto(classe(V, pesado))].
regra 6 se [avalia(peso(V, >, 3500))] entao [cria_facto(classe(V, pesado))].
regra 7 se [avalia(lotacao(V, =<, 9)) e avalia(peso(V, =<, 3500))] entao [cria_facto(classe(V, ligeiro))].
regra 8 se [tipo(V, mercadorias) e tipo(V, passageiros)] entao [cria_facto(tipo(V, misto))].

% ==============================================================================
% Factos Iniciais (Default Initial Facts)
% ==============================================================================

facto(1, lotacao(meu_veiculo, 3)).
facto(2, peso(meu_veiculo, 4500)).
facto(3, tipo(meu_veiculo, mercadorias)).
