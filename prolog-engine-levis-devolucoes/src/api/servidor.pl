:- encoding(utf8).
:- module(servidor, [
    iniciar_servidor/1,         % +Porta
    parar_servidor/1,           % +Porta
    limpar_avaliacoes/0
]).

/** <module> API REST do sistema pericial (SWI-Prolog HTTP)

Endpoints com os mesmos caminhos e formatos JSON da API Drools (`docs/05`, ADR 0008), para que
os dois motores possam ser usados e comparados pelo mesmo cliente:

| Método | Caminho                                              | Resposta                         |
|--------|------------------------------------------------------|----------------------------------|
| GET    | /api/v1/saude                                        | estado do serviço                |
| POST   | /api/v1/avaliacoes                                   | 201 DecisaoResponse              |
| GET    | /api/v1/avaliacoes?loja=&pagina=&tamanho=            | PaginaDto<AvaliacaoResumo>       |
| GET    | /api/v1/avaliacoes/{id}                              | DecisaoResponse                  |
| POST   | /api/v1/avaliacoes/dados-em-falta                    | DadosEmFaltaResponse             |
| POST   | /api/v1/avaliacoes/porque?dado=IN-010                | ExplicacaoPorqueResponse         |
| GET    | /api/v1/avaliacoes/{id}/explicacoes/como             | Como (completo ou ?conclusao=)   |
| GET    | /api/v1/avaliacoes/{id}/explicacoes/porque-nao       | ?conclusao=OUT-001:VALOR ou ?regra= |
| POST   | /api/v1/avaliacoes/{id}/simulacoes                   | SimulacaoResponse ("E se?")      |
| GET    | /api/v1/regras                                       | catálogo das regras              |
| GET    | /api/v1/regras/{codigo}                              | variantes de uma regra           |

Diferenças em relação à API Drools (fora do âmbito pedido): sem autenticação JWT (o colaborador
vem no campo `colaborador` do pedido), as avaliações ficam em memória (sem PostgreSQL) e os
textos das explicações só existem em português.
*/

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_header)).
:- use_module(library(http/http_files)).
:- use_module(library(json)).
:- use_module(library(uuid)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module('../motor/operadores').
:- use_module('../motor/memoria').
:- use_module('../motor/motor').
:- use_module('../bc/pedido').
:- use_module('../bc/condicoes').
:- use_module('../servico').
:- use_module('../explicacoes/explicacoes').

:- meta_predicate com_erros(0).

:- dynamic avaliacao_/4.            % avaliacao_(Id, AvaliadaEm, Json, Resumo)

:- http_handler('/api/v1/saude', saude, [method(get)]).
:- http_handler('/api/v1/avaliacoes', avaliacoes, [methods([get, post, options])]).
:- http_handler('/api/v1/avaliacoes/dados-em-falta', dados_falta, [methods([post, options])]).
:- http_handler('/api/v1/avaliacoes/porque', porque_dado, [methods([post, options])]).
:- http_handler('/api/v1/avaliacoes/', avaliacao_recurso, [prefix, methods([get, post, options])]).
:- http_handler('/api/v1/regras', regras, [method(get)]).
:- http_handler('/api/v1/regras/', regra, [prefix, method(get)]).
:- http_handler('/api/v1/exemplos', exemplos, [method(get)]).

% ---------------------------------------------------------------------------------------------
% Interface web (pasta web/): a página fica em http://localhost:PORTA/
% ---------------------------------------------------------------------------------------------

:- dynamic raiz_projeto_/1.
:- prolog_load_context(directory, D),
   file_directory_name(D, Src), file_directory_name(Src, Raiz),
   assertz(raiz_projeto_(Raiz)).

pasta_projeto(Sub, Caminho) :-
    raiz_projeto_(Raiz),
    directory_file_path(Raiz, Sub, Caminho).

:- http_handler('/', pagina_inicial, []).
:- http_handler('/web/', ficheiro_web, [prefix]).
:- http_handler('/swagger-ui.html', pagina_swagger, []).
:- http_handler('/swagger', pagina_swagger, []).
:- http_handler('/v3/api-docs', especificacao_openapi, []).

pagina_inicial(Pedido) :-
    pasta_projeto('web/index.html', F),
    http_reply_file(F, [unsafe(true), headers(['Cache-Control'('no-cache')])], Pedido).

%   Swagger UI (web/swagger.html) e a especificação OpenAPI (web/openapi.json), nos mesmos
%   caminhos da API Drools (springdoc).
pagina_swagger(Pedido) :-
    pasta_projeto('web/swagger.html', F),
    http_reply_file(F, [unsafe(true), headers(['Cache-Control'('no-cache')])], Pedido).

especificacao_openapi(Pedido) :-
    pasta_projeto('web/openapi.json', F),
    format("Access-Control-Allow-Origin: *~n"),
    http_reply_file(F, [unsafe(true), mime_type('application/json'), headers(['Cache-Control'('no-cache')])], Pedido).

ficheiro_web(Pedido) :-
    pasta_projeto(web, Dir),
    http_reply_from_files(Dir, [headers(['Cache-Control'('no-cache')])], Pedido).
ficheiro_web(Pedido) :-
    http_404([], Pedido).

%   GET /api/v1/exemplos: os 10 cenários de teste (docs/06), para carregar na interface.
exemplos(_Pedido) :-
    com_erros(( pasta_projeto('testes/cenarios', Dir),
                directory_files(Dir, Fs0), msort(Fs0, Fs),
                findall(E, ( member(F, Fs), file_name_extension(_, json, F),
                             directory_file_path(Dir, F, Caminho), exemplo(Caminho, E) ), Lista),
                responder(200, Lista) )).

exemplo(Caminho, _{id:Id, titulo:Titulo, pedido:Pedido}) :-
    setup_call_cleanup(open(Caminho, read, In, [encoding(utf8)]),
                       json_read_dict(In, J, [value_string_as(string)]),
                       close(In)),
    Id = J.id, Titulo = J.titulo,
    ( get_dict(indicadoresFraude, J, F) -> true ; F = [] ),
    Pedido = J.pedido.put(indicadoresFraude, F).

iniciar_servidor(Porta) :-
    http_server(http_dispatch, [port(Porta)]).

parar_servidor(Porta) :-
    catch(http_stop_server(Porta, []), _, true).

limpar_avaliacoes :-
    retractall(avaliacao_(_, _, _, _)).

% ---------------------------------------------------------------------------------------------
% Respostas e erros (ProblemDetail, RFC 9457)
% ---------------------------------------------------------------------------------------------

responder(Estado, Json) :-
    responder(Estado, Json, []).
responder(Estado, Json, Cabecalhos) :-
    format("Access-Control-Allow-Origin: *~n"),
    forall(member(Nome-Valor, Cabecalhos), format("~w: ~w~n", [Nome, Valor])),
    reply_json_dict(Json, [status(Estado), width(0)]).

problema(Estado, Tipo, Titulo, Detalhe, Erros) :-
    atom_concat('/problemas/', Tipo, Uri),
    Json0 = _{type:Uri, title:Titulo, status:Estado, detail:Detalhe},
    ( Erros == [] -> Json = Json0 ; Json = Json0.put(erros, Erros) ),
    format("Access-Control-Allow-Origin: *~n"),
    reply_json_dict(Json, [status(Estado), content_type('application/problem+json; charset=UTF-8'), width(0)]).

%   Executa um tratador e transforma as exceções em respostas de erro.
com_erros(Objetivo) :-
    catch(Objetivo, Erro, tratar_erro(Erro)).

tratar_erro(http(Estado, Tipo, Titulo, Detalhe, Erros)) :- !,
    problema(Estado, Tipo, Titulo, Detalhe, Erros).
tratar_erro(error(syntax_error(json(_)), _)) :- !,
    problema(400, 'pedido-invalido', "Pedido inválido", "O corpo não é JSON válido.", []).
tratar_erro(error(type_error(T, V), _)) :- !,
    format(string(D), "Valor inválido (~w esperado): ~q", [T, V]),
    problema(400, 'pedido-invalido', "Pedido inválido", D, []).
tratar_erro(error(existence_error(_, _), Mensagem)) :- string(Mensagem), !,
    problema(404, 'nao-encontrado', "Recurso não encontrado", Mensagem, []).
tratar_erro(error(domain_error(_, _), Mensagem)) :- string(Mensagem), !,
    problema(400, 'pedido-invalido', "Pedido inválido", Mensagem, []).
tratar_erro(Erro) :-
    term_string(Erro, Texto),
    problema(500, 'erro-interno', "Erro interno", Texto, []).

opcoes :-
    format("Access-Control-Allow-Origin: *~n"),
    format("Access-Control-Allow-Methods: GET, POST, OPTIONS~n"),
    format("Access-Control-Allow-Headers: Content-Type, Accept-Language~n"),
    format("Content-Type: text/plain~n~n").

ler_json(Pedido, Json) :-
    catch(http_read_json_dict(Pedido, Json, [value_string_as(string)]),
          _, throw(error(syntax_error(json(invalido)), _))),
    (   is_dict(Json) -> true
    ;   throw(http(400, 'pedido-invalido', "Pedido inválido", "O corpo tem de ser um objeto JSON.", []))
    ).

% ---------------------------------------------------------------------------------------------
% Tratadores
% ---------------------------------------------------------------------------------------------

saude(_Pedido) :-
    versao_base_conhecimento(Versao),
    regras_por_ordem(Nomes), length(Nomes, N),
    responder(200, _{status:"UP", motor:"SWI-Prolog", versaoBaseConhecimento:Versao, regras:N}).

avaliacoes(Pedido) :-
    memberchk(method(Metodo), Pedido),
    (   Metodo == options -> opcoes
    ;   Metodo == post -> com_erros(avaliar(Pedido))
    ;   com_erros(listar(Pedido))
    ).

%   POST /api/v1/avaliacoes: avalia e grava. Um pedido sem os dados obrigatórios é recusado com
%   422 e a lista do que falta (como o ValidadorPedido).
avaliar(Pedido) :-
    ler_json(Pedido, Json),
    preparar_pedido(Json, PedidoN, Fraudes),
    validar_completo(PedidoN),
    avaliar_pedido(PedidoN, Fraudes),
    uuid(IdAtomo), atom_string(IdAtomo, Id),
    get_time(Agora), format_time(string(Em), '%FT%T', Agora),
    decisao_json(_{avaliacaoId:Id, avaliadaEm:Em}, Decisao),
    campo(PedidoN, [loja, codigo], LojaCodigo),
    Resumo = _{avaliacaoId:Id, pedidoId:Decisao.pedidoId, avaliadaEm:Em,
               lojaCodigo:LojaCodigo, elegibilidade:Decisao.elegibilidade,
               tipoTransacao:Decisao.tipoTransacao, valorDevolucao:Decisao.valorDevolucao},
    assertz(avaliacao_(Id, Em, Json, Resumo)),
    atom_concat('/api/v1/avaliacoes/', Id, Local),
    responder(201, Decisao, ['Location'-Local]).

validar_completo(PedidoN) :-
    dados_em_falta(PedidoN, Falta),
    (   Falta.completo == true
    ->  true
    ;   findall(E, ( member(D, Falta.dados), D.obrigatorio == true,
                     format(string(E), "~w (~w): ~w", [D.codigo, D.caminho, D.descricao]) ), Erros),
        throw(http(422, 'pedido-incompleto', "Pedido incompleto",
                   "Faltam dados obrigatórios para avaliar o pedido.", Erros))
    ).

listar(Pedido) :-
    http_parameters(Pedido, [ loja(Loja, [optional(true), string]),
                              pagina(Pagina, [default(0), integer]),
                              tamanho(Tamanho, [default(20), integer]) ]),
    findall(R, ( avaliacao_(_, _, _, R), ( var(Loja) -> true ; R.lojaCodigo == Loja ) ), Todos0),
    reverse(Todos0, Todos),
    length(Todos, Total),
    Inicio is Pagina * Tamanho,
    length(Prefixo, Inicio),
    (   append(Prefixo, Resto, Todos) -> true ; Resto = [] ),
    ( length(Conteudo, Tamanho), append(Conteudo, _, Resto) -> true ; Conteudo = Resto ),
    TotalPaginas is (Total + Tamanho - 1) // max(1, Tamanho),
    responder(200, _{conteudo:Conteudo, pagina:Pagina, tamanho:Tamanho,
                     totalElementos:Total, totalPaginas:TotalPaginas}).

%   POST /dados-em-falta e /porque aceitam pedidos incompletos: servem o preenchimento.
dados_falta(Pedido) :-
    memberchk(method(Metodo), Pedido),
    (   Metodo == options -> opcoes
    ;   com_erros(( ler_json(Pedido, Json),
                    avaliar_parcial(Json, PedidoN),
                    dados_em_falta(PedidoN, Resposta),
                    responder(200, Resposta) ))
    ).

porque_dado(Pedido) :-
    memberchk(method(Metodo), Pedido),
    (   Metodo == options -> opcoes
    ;   com_erros(( http_parameters(Pedido, [dado(Dado, [string])]),
                    ler_json(Pedido, Json),
                    avaliar_parcial(Json, _),
                    porque(Dado, Resposta),
                    responder(200, Resposta) ))
    ).

avaliar_parcial(Json, PedidoN) :-
    preparar_pedido(Json, PedidoN, Fraudes),
    avaliar_pedido(PedidoN, Fraudes).

%   /api/v1/avaliacoes/{id}, /{id}/explicacoes/como, /{id}/explicacoes/porque-nao, /{id}/simulacoes
avaliacao_recurso(Pedido) :-
    memberchk(method(Metodo), Pedido),
    (   Metodo == options
    ->  opcoes
    ;   memberchk(path_info(Caminho), Pedido),
        split_string(Caminho, "/", "/", Partes),
        com_erros(recurso(Metodo, Partes, Pedido))
    ).

recurso(get, [Id], _) :- !,
    reavaliar(Id, Em, _),
    decisao_json(_{avaliacaoId:Id, avaliadaEm:Em}, Decisao),
    responder(200, Decisao).
recurso(get, [Id, "explicacoes", "como"], Pedido) :- !,
    http_parameters(Pedido, [ conclusao(Conclusao, [optional(true), atom]),
                              artigo(Artigo, [optional(true), string]) ]),
    reavaliar(Id, _, _),
    ( var(Artigo) -> ArtigoId = null ; ArtigoId = Artigo ),
    (   var(Conclusao)
    ->  como(Resposta)
    ;   como_conclusao(Conclusao, ArtigoId, Resposta)
    ),
    responder(200, Resposta).
recurso(get, [Id, "explicacoes", "porque-nao"], Pedido) :- !,
    http_parameters(Pedido, [ conclusao(Conclusao, [optional(true), string]),
                              regra(Regra, [optional(true), atom]),
                              artigo(Artigo, [optional(true), string]) ]),
    reavaliar(Id, _, _),
    ( var(Artigo) -> ArtigoId = null ; ArtigoId = Artigo ),
    (   nonvar(Regra)
    ->  porque_nao_regra(Regra, ArtigoId, Resposta)
    ;   nonvar(Conclusao)
    ->  (   split_string(Conclusao, ":=", " ", [Codigo, Valor])
        ->  atom_string(CodigoAtomo, Codigo),
            porque_nao_conclusao(CodigoAtomo, Valor, ArtigoId, Resposta)
        ;   throw(http(400, 'pedido-invalido', "Pedido inválido",
                       "A conclusão tem o formato OUT-00n:VALOR (ex.: OUT-001:PERMITIR).", []))
        )
    ;   throw(http(400, 'pedido-invalido', "Pedido inválido", "Indique 'conclusao' ou 'regra'.", []))
    ),
    responder(200, Resposta).
recurso(post, [Id, "simulacoes"], Pedido) :- !,
    ler_json(Pedido, Corpo),
    (   get_dict(alteracoes, Corpo, Alteracoes), is_dict(Alteracoes) -> true
    ;   throw(http(400, 'pedido-invalido', "Pedido inválido", "O corpo tem de ter 'alteracoes' (objeto caminho -> valor).", []))
    ),
    reavaliar(Id, _, Json),
    resultado_comparavel(Original),
    e_se(Json, Alteracoes, Original, Resposta),
    responder(200, Resposta).
recurso(_, _, _) :-
    throw(http(404, 'nao-encontrado', "Recurso não encontrado", "Caminho desconhecido.", [])).

%   As explicações reavaliam o pedido gravado (o motor é determinístico, como a ReavaliacaoService).
reavaliar(Id, Em, Json) :-
    (   avaliacao_(Id, Em, Json, _)
    ->  avaliar_parcial(Json, _)
    ;   format(string(M), "Avaliação inexistente: ~w", [Id]),
        throw(http(404, 'nao-encontrado', "Recurso não encontrado", M, []))
    ).

regras(_Pedido) :-
    com_erros(( findall(Id, ( regras_por_ordem(Ns), member(N, Ns), regra_info(N, I), Id = I.id ), Ids0),
                list_to_set(Ids0, Ids),
                maplist(resumo_regra, Ids, Lista),
                responder(200, Lista) )).

regra(Pedido) :-
    memberchk(path_info(Caminho), Pedido),
    split_string(Caminho, "/", "/", [Codigo]),
    atom_string(Id, Codigo),
    com_erros(( findall(V, ( regras_por_ordem(Ns), member(N, Ns), regra_info(N, I), I.id == Id, variante_json(N, V) ), Vs),
                (   Vs == []
                ->  format(string(M), "Regra desconhecida: ~w", [Id]),
                    throw(http(404, 'nao-encontrado', "Recurso não encontrado", M, []))
                ;   responder(200, _{id:Id, variantes:Vs})
                ) )).

resumo_regra(Id, _{id:Id, modulos:Modulos, descricao:Descricao, variantes:N, aValidar:AValidar}) :-
    findall(N0-I, ( regras_por_ordem(Ns), member(N0, Ns), regra_info(N0, I), I.id == Id ), Vs),
    length(Vs, N),
    Vs = [_-Primeira|_],
    Descricao = Primeira.descricao,
    findall(M, ( member(_-I, Vs), valor_json(I.modulo, M) ), Ms), list_to_set(Ms, Modulos),
    ( member(_-I, Vs), I.a_validar == true -> AValidar = true ; AValidar = false ).

variante_json(Nome, Json) :-
    regra_info(Nome, Info),
    Json = _{nome:NomeTexto, modulo:Modulo, prioridade:Prioridade, descricao:Descricao,
             condicoes:Condicoes, conclusoes:Conclusoes, aValidar:AValidar},
    Descricao = Info.descricao,
    AValidar = Info.a_validar,
    atom_string(Nome, NomeTexto),
    valor_json(Info.modulo, Modulo),
    Prioridade = Info.prioridade,
    regra_def(Nome, LHS, _, _),
    lhs_lista(LHS, Cs),
    copy_term(Cs, Cs1), numbervars(Cs1, 0, _),
    findall(T, ( member(C, Cs1), \+ guarda(C), format(string(T), "~W", [C, [numbervars(true), quoted(true)]]) ), Condicoes),
    findall(T, ( member(C, Info.conclusoes), conclusao_texto(C, T) ), Conclusoes).

guarda(C) :- functor(C, N, A), condicao_info(N/A, Tipo, _), memberchk(Tipo, [guarda, gerador]).

conclusao_texto(C = V, T) :- !, valor_json(V, J), format(string(T), "~w=~w", [C, J]).
conclusao_texto(C, T) :- format(string(T), "~w", [C]).
