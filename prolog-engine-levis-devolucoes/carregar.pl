:- encoding(utf8).
/*  Carrega o sistema no interpretador, para uso interativo:

    swipl carregar.pl
    ?- consulta.                                             % perguntas, decisão e explicações
    ?- avaliar_ficheiro('testes/cenarios/cenario-01.json').  % avalia um pedido em JSON
    ?- iniciar_servidor(8090).                               % API REST
*/

:- use_module(src/motor/operadores).
:- use_module(src/motor/memoria).
:- use_module(src/motor/motor).
:- use_module(src/bc/pedido).
:- use_module(src/bc/condicoes).
:- use_module(src/servico).
:- use_module(src/explicacoes/explicacoes).
:- use_module(src/interface/consola).
:- use_module(src/api/servidor).
