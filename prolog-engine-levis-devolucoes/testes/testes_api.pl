:- encoding(utf8).
/*  Testes da API REST por HTTP (equivalente a CenariosApiIT e aos testes dos controllers do
    projeto Drools): o servidor arranca numa porta de teste e os pedidos passam pela pilha HTTP.
*/

:- use_module(library(plunit)).
:- use_module(library(http/http_open)).
:- use_module(library(http/http_json)).
:- use_module(library(json)).
:- use_module(library(lists)).
:- use_module(verificador).
:- use_module('../src/api/servidor').

porta_teste(8199).

url(Caminho, Url) :- porta_teste(P), format(atom(Url), "http://localhost:~w~w", [P, Caminho]).

pedir(Metodo, Caminho, Corpo, Estado, Resposta) :-
    url(Caminho, Url),
    Opcoes0 = [method(Metodo), status_code(Estado), request_header('Accept'='application/json')],
    (   Corpo == none -> Opcoes = Opcoes0 ; Opcoes = [post(json(Corpo))|Opcoes0] ),
    setup_call_cleanup(http_open(Url, In, Opcoes),
                       ( set_stream(In, encoding(utf8)), json_read_dict(In, Resposta, [value_string_as(string)]) ),
                       close(In)).

pedir_bruto(Caminho, Texto, Estado) :-
    url(Caminho, Url),
    setup_call_cleanup(http_open(Url, In, [method(post), status_code(Estado),
                                           post(string('application/json', Texto))]),
                       read_string(In, _, _), close(In)).

%   Pedido no formato da API: o pedido do cenário com os indícios de fraude lá dentro.
pedido_api(N, Pedido, Esperado) :-
    ler_cenario(N, J),
    Pedido = J.pedido.put(indicadoresFraude, J.indicadoresFraude),
    Esperado = J.esperado.

avaliar_cenario(N, Id, Decisao) :-
    pedido_api(N, Pedido, _),
    pedir(post, '/api/v1/avaliacoes', Pedido, 201, Decisao),
    Id = Decisao.avaliacaoId.

iniciar :- porta_teste(P), limpar_avaliacoes, iniciar_servidor(P).
parar :- porta_teste(P), parar_servidor(P).

:- begin_tests(api, [setup(iniciar), cleanup(parar)]).

test('Saúde do serviço') :-
    pedir(get, '/api/v1/saude', none, 200, R),
    R.status == "UP", R.regras == 98.

test('Os 10 cenários passam por HTTP com a elegibilidade esperada', [forall(between(1, 10, N))]) :-
    pedido_api(N, Pedido, Esperado),
    pedir(post, '/api/v1/avaliacoes', Pedido, 201, Decisao),
    Decisao.elegibilidade == Esperado.elegibilidade,
    Decisao.pedidoId == Pedido.id,
    forall(member(C, Esperado.regrasDisparadas), ( member(R, Decisao.regras), R.codigoRegra == C -> true )).

test('Consultar uma avaliação gravada') :-
    avaliar_cenario(1, Id, D1),
    atom_concat('/api/v1/avaliacoes/', Id, Caminho),
    pedir(get, Caminho, none, 200, D2),
    D2.elegibilidade == D1.elegibilidade, D2.avaliacaoId == Id,
    D2.regrasAValidar \== [].

test('Listar avaliações por página') :-
    avaliar_cenario(3, _, _),
    pedir(get, '/api/v1/avaliacoes?pagina=0&tamanho=2', none, 200, R),
    R.totalElementos >= 1, length(R.conteudo, L), L =< 2.

test('Como: caminho completo e de uma conclusão') :-
    avaliar_cenario(5, Id, _),
    format(atom(C1), '/api/v1/avaliacoes/~w/explicacoes/como', [Id]),
    pedir(get, C1, none, 200, Como), Como.paragem == "CH-008",
    format(atom(C2), '/api/v1/avaliacoes/~w/explicacoes/como?conclusao=OUT-001', [Id]),
    pedir(get, C2, none, 200, Conclusao), Conclusao.regra == "CH-008".

test('Porque não: conclusão e regra') :-
    avaliar_cenario(1, Id, _),
    format(atom(C1), '/api/v1/avaliacoes/~w/explicacoes/porque-nao?conclusao=OUT-001:PERMITIR', [Id]),
    pedir(get, C1, none, 200, E1), E1.obtida == false, E1.valorObtido == "REVER",
    format(atom(C2), '/api/v1/avaliacoes/~w/explicacoes/porque-nao?regra=PC-001&artigo=A-1', [Id]),
    pedir(get, C2, none, 200, E2), E2.causa == "CONDICOES_FALHADAS".

test('E se: simulação sem alterar a avaliação gravada') :-
    avaliar_cenario(1, Id, _),
    format(atom(C), '/api/v1/avaliacoes/~w/simulacoes', [Id]),
    pedir(post, C, _{alteracoes:_{'artigos[0].revendivel':true}}, 200, S),
    S.decisaoSimulada.elegibilidade == "PERMITIR",
    member(Dif, S.diferencas), Dif.campo == "elegibilidade", Dif.original == "REVER", !,
    atom_concat('/api/v1/avaliacoes/', Id, Caminho),
    pedir(get, Caminho, none, 200, D), D.elegibilidade == "REVER".

test('O que falta e Porquê aceitam pedidos incompletos') :-
    pedir(post, '/api/v1/avaliacoes/dados-em-falta', _{id:"X", artigos:[]}, 200, F),
    F.completo == false,
    pedido_api(1, Pedido, _),
    pedir(post, '/api/v1/avaliacoes/porque?dado=IN-010', Pedido, 200, P),
    P.regrasEmEspera \== [].

test('Pedido incompleto é recusado com 422 e a lista do que falta') :-
    pedir(post, '/api/v1/avaliacoes', _{id:"X"}, 422, R),
    R.status == 422, R.erros \== [].

test('Avaliação inexistente dá 404') :-
    pedir(get, '/api/v1/avaliacoes/nao-existe', none, 404, R),
    R.status == 404.

test('JSON inválido dá 400') :-
    pedir_bruto('/api/v1/avaliacoes', "{\"id\":", 400).

test('Interface web: página, ficheiros e exemplos') :-
    url('/', U1), http_open(U1, In1, [status_code(200), header(content_type, T1)]), read_string(In1, _, H), close(In1),
    sub_atom(T1, 0, _, _, 'text/html'), once(sub_string(H, _, _, _, "app.js")),
    url('/web/app.js', U2), http_open(U2, In2, [status_code(200)]), close(In2),
    url('/web/nao-existe.js', U3), http_open(U3, In3, [status_code(404)]), close(In3),
    pedir(get, '/api/v1/exemplos', none, 200, Exemplos), length(Exemplos, 10),
    Exemplos = [E|_], E.pedido.id == "C01".

test('Swagger: página e especificação OpenAPI com todos os caminhos da API') :-
    url('/swagger-ui.html', U1), http_open(U1, In1, [status_code(200)]), read_string(In1, _, H), close(In1),
    once(sub_string(H, _, _, _, "SwaggerUIBundle")),
    pedir(get, '/v3/api-docs', none, 200, Spec),
    Spec.openapi == "3.0.3",
    dict_pairs(Spec.paths, _, Pares), length(Pares, 11),
    forall(member(C, ['/api/v1/avaliacoes', '/api/v1/avaliacoes/{id}/explicacoes/porque-nao', '/api/v1/regras/{codigo}']),
           get_dict(C, Spec.paths, _)).

test('Catálogo das regras') :-
    pedir(get, '/api/v1/regras', none, 200, Regras), length(Regras, 76),
    pedir(get, '/api/v1/regras/PC-002', none, 200, R), length(R.variantes, 3).

:- end_tests(api).
