:- encoding(utf8).
:- module(operadores, [
    op(240, fx, regra),
    op(230, xfx, com),
    op(220, xfx, entao),
    op(35, xfy, se),
    op(600, xfy, e),
    op(500, fy, nao)
]).

/** <module> Operadores da linguagem de regras

Os operadores são os do sp_exp2.pl (material de apoio da UC): `regra`, `se`, `entao`, `e` e `nao`.
Acrescenta-se `com`, que junta à regra os seus metadados (equivalente às anotações do DRL):

==
regra 'PT-003 Devolução verificada até 30 dias'
    se [ pedidoAtivo e devolucaoVerificada e ... ]
    entao [ definir(pedido, meioReembolso, meio_original), aplicar(pedido, permitir, "...") ]
    com [ modulo(m5), prioridade(100), conclusoes([...]), descricao("...") ].
==

Com estas prioridades, a regra lê-se `regra(com(entao(se(Nome, LHS), RHS), Meta))`.
*/
