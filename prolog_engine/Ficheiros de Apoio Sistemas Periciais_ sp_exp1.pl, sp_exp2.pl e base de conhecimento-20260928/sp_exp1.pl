

:-op(220,xfx,entao).
:-op(35,xfy,se).
:-op(240,fx,regra).
:-op(600,xfy,e).

:-dynamic justifica/3.

% Carregamento da Base de Conhecimento

carrega_bc:-
	write('NOME DA BASE DE CONHECIMENTO (terminar com .)-> '),
% usar se necessario caminho absoluto com / e colocar entre plicas
		read(NBC),
		consult(NBC).

% Arranque do Motor de Inferência

arranca_motor:-facto(N,Facto),
		regra ID se LHS entao RHS,
		facto_dispara_regra(N,Facto,ID,LHS,RHS),
		ultimo_facto(N),ultima_regra(ID).


% Verificar se o LHS da regra tem sucesso

facto_dispara_regra(N,Facto,ID,LHS,RHS):-
	facto_esta_numa_condicao(Facto,LHS),
	verifica_condicoes(LHS,LFactos),
	member(N,LFactos),
	concluir(RHS,ID,LFactos),
	!.

facto_dispara_regra(_,_,_,_,_).


facto_esta_numa_condicao(F,[F  e _]).

facto_esta_numa_condicao(F,[avalia(F1)  e _]):- F=..[X,X1|_],F1=..[X,X1|_].

facto_esta_numa_condicao(F,[_ e Fs]):-
	facto_esta_numa_condicao(F,[Fs]).

facto_esta_numa_condicao(F,[F]).

facto_esta_numa_condicao(F,[avalia(F1)]):-F=..[X,X1|_],F1=..[X,X1|_].



verifica_condicoes([X e Y],[N|LF]):-
	facto(N,X),!,
	verifica_condicoes([Y],LF).

verifica_condicoes([avalia(X) e Y],[N|LF]):-
	avalia(N,X),!,
	verifica_condicoes([Y],LF).

verifica_condicoes([X],[N]):- facto(N,X),!.

verifica_condicoes([avalia(X)],[N]):- avalia(N,X).


avalia(N,P):-	P=..[Functor,Entidade,Operando,Valor],
		P1=..[Functor,Entidade,Valor1],
		facto(N,P1),
		compara(Valor1,Operando,Valor).

compara(V1,==,V):- V1==V.
compara(V1,\==,V):- V1\==V.
compara(V1,>,V):-V1>V.
compara(V1,<,V):-V1<V.
compara(V1,>=,V):-V1>=V.
compara(V1,=<,V):-V1=<V.


% Aplicar o RHS da regra que foi disparada com sucesso

concluir([cria_facto(F)|Y],ID,LFactos):-
	!,
	cria_facto(F,ID,LFactos),
	concluir(Y,ID,LFactos).

concluir([],_,_):-!.



cria_facto(F,_,_):-
	facto(_,F),!.

cria_facto(F,ID,LFactos):-
	retract(ultimo_facto(N1)),
	N is N1+1,
	asserta(ultimo_facto(N)),
	assertz(justifica(N,ID,LFactos)),
	assertz(facto(N,F)),
	write('Foi concluído o facto nº '),write(N),write(' -> '),write(F),get0(_),!.



% Visualização da base de factos

mostra_factos:-
	findall(N, facto(N, _), LFactos),
	escreve_factos(LFactos).

escreve_factos([I|R]):-facto(I,F),
	write('O facto nº '),write(I),write(' -> '),write(F),nl,
	escreve_factos(R).
escreve_factos([]).




