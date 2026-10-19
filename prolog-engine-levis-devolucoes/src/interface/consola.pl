:- encoding(utf8).
:- module(consola, [
    consulta/0,                 % Consulta interativa: perguntas, avaliação e explicações
    avaliar_ficheiro/1,         % +FicheiroJson: avalia um pedido em JSON e abre o menu
    menu_explicacoes/0
]).

/** <module> Modo interativo na consola

O sistema pergunta ao colaborador os dados do pedido, um grupo de cada vez (os mesmos dados da
API: IN-001 a IN-010, colaborador, cliente, exceção e indícios de fraude). Em qualquer pergunta,
responder `porque` (ou `?`) mostra a explicação "Porquê?": que regras dependem da resposta e quais
estão à espera dela, dado o que já foi respondido.

Depois da avaliação, se faltar decidir a possibilidade de revenda de um artigo (IN-010, como o
`perguntar(...)` da regra PC-002 no relatório), o sistema pergunta-a e reavalia. Por fim abre um
menu de explicações: Como, Porque não, Porquê, O que falta e E se.

==
?- consulta.
?- avaliar_ficheiro('testes/cenarios/cenario-01.json').
==
*/

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(json)).
:- use_module('../motor/memoria').
:- use_module('../motor/motor').
:- use_module('../bc/pedido').
:- use_module('../bc/condicoes').
:- use_module('../servico').
:- use_module('../explicacoes/explicacoes').

:- thread_local respostas_/1.        % respostas_(JsonPedido) em construção
:- thread_local json_atual_/1.       % pedido JSON da última avaliação

% ---------------------------------------------------------------------------------------------
% Consulta
% ---------------------------------------------------------------------------------------------

consulta :-
    titulo("Sistema pericial de devoluções e trocas Levi's (EUA e Canadá)"),
    format("Responda a cada pergunta e prima Enter. O valor entre [ ] é usado se não escrever nada.~n"),
    format("Em qualquer pergunta: 'porque' (ou '?') explica porque é feita; 'sair' termina.~n"),
    retractall(respostas_(_)),
    get_time(T), format_time(string(Hoje), '%F', T),
    assertz(respostas_(_{id:"CONSOLA-1", dataPedido:Hoje})),
    catch(( perguntas_colaborador,
            perguntas_loja,
            perguntas_pedido,
            perguntas_canal,
            perguntas_comprovativo,
            perguntas_pagamento,
            perguntas_artigos,
            perguntas_troca,
            perguntas_cliente,
            perguntas_excecao,
            perguntas_fraude,
            respostas_(Json),
            avaliar_e_perguntar_revenda(Json)
          ),
          sair, format("~nConsulta terminada.~n")).

avaliar_ficheiro(Ficheiro) :-
    retractall(respostas_(_)),
    setup_call_cleanup(open(Ficheiro, read, In, [encoding(utf8)]),
                       json_read_dict(In, Json, [value_string_as(string)]),
                       close(In)),
    catch(avaliar_e_perguntar_revenda(Json), sair, format("~nConsulta terminada.~n")).

avaliar_e_perguntar_revenda(Json0) :-
    avaliar_json_atual(Json0),
    perguntar_revenda(Json0, Json),
    (   Json \== Json0 -> avaliar_json_atual(Json) ; true ),
    mostrar_decisao,
    menu_explicacoes.

avaliar_json_atual(Json) :-
    preparar_pedido(Json, Pedido, Fraudes),
    dados_em_falta(Pedido, Falta),
    (   Falta.completo == false
    ->  format("~nAtenção: faltam dados obrigatórios; a decisão pode não ser completa:~n"),
        forall(( member(D, Falta.dados), D.obrigatorio == true ),
               format("  - ~w ~w (~w)~n", [D.codigo, D.descricao, D.caminho]))
    ;   true
    ),
    avaliar_pedido(Pedido, Fraudes),
    retractall(json_atual_(_)),
    assertz(json_atual_(Json)).

%   IN-010: para cada artigo que precise da avaliação da revenda, pergunta e reavalia.
perguntar_revenda(Json0, Json) :-
    pedido_atual(Pedido),
    dados_em_falta(Pedido, Falta),
    findall(D, ( member(D, Falta.dados), D.codigo == 'IN-010' ), Revendas),
    (   Revendas == []
    ->  Json = Json0
    ;   length(Revendas, NR),
        format("~nA decisão depende da possibilidade de revenda de ~d artigo(s) (IN-010).~n", [NR]),
        foldl(perguntar_revenda_artigo, Revendas, Json0, Json)
    ).

perguntar_revenda_artigo(D, Json0, Json) :-
    format(string(Texto), "~w? (sim / nao / Enter se ainda não sabe)", [D.descricao]),
    perguntar('IN-010', Texto, sim_nao_vazio, "", Resposta),
    (   Resposta == ""
    ->  Json = Json0
    ;   aplicar_alteracoes(Json0, [D.caminho-Resposta], Json)
    ).

% ---------------------------------------------------------------------------------------------
% Grupos de perguntas
% ---------------------------------------------------------------------------------------------

perguntas_colaborador :-
    secao("Colaborador (HS-006)"),
    menu('HS-006', "Função do colaborador que processa",
         ["GESTAO_LOJA", "KEY_HOLDER", "XSTORE_MANAGER", "LEAD_CASHIER", "ELEVATED_STYLIST", "STYLIST"], "KEY_HOLDER", F),
    guardar("colaborador.funcao", F),
    (   memberchk(F, ["LEAD_CASHIER", "ELEVATED_STYLIST"])
    ->  sim_nao('HS-006', "Aprovado pelo District Manager?", "nao", DM), guardar("colaborador.aprovadoPeloDM", DM)
    ;   true
    ),
    texto('HS-006', "Identificador do colaborador", "C-1", Id), guardar("colaborador.id", Id),
    texto('HS-006', "Credencial de POS (vazio se não tem)", "POS-C-1", Cred), guardar_texto("colaborador.idCredencialPOS", Cred).

perguntas_loja :-
    secao("Loja recetora (IN-001, IN-002)"),
    menu('IN-001', "Mercado", ["EUA", "CANADA"], "EUA", M), guardar("loja.mercado", M),
    menu('IN-002', "Tipo de loja", ["MAINLINE", "OUTLET"], "MAINLINE", T), guardar("loja.tipoLoja", T),
    texto('IN-002', "Código da loja", "LOJA-1", C), guardar("loja.codigo", C),
    sim_nao('IN-002', "Cobertura de loja única (SSC)?", "nao", SSC), guardar("loja.coberturaLojaUnica", SSC).

perguntas_pedido :-
    secao("Pedido do cliente (IN-005, IN-006)"),
    menu('IN-005', "O que pede o cliente", ["DEVOLUCAO", "TROCA", "DEVOLUCAO_OFERTA", "AJUSTE_PRECO"], "DEVOLUCAO", T),
    guardar("tipoPedido", T),
    respostas_(R), data('IN-006', "Data do pedido (AAAA-MM-DD)", R.dataPedido, D), guardar("dataPedido", D).

perguntas_canal :-
    secao("Compra original (IN-003)"),
    menu('IN-003', "Canal de compra",
         ["MAINLINE", "OUTLET", "LEVI_COM", "LEVI_CA", "BACKPOCKET", "FRANQUIA_CANADA", "GROSSISTA", "DESCONHECIDO"], "MAINLINE", C),
    guardar("compraOriginal.canal", C),
    (   memberchk(C, ["LEVI_COM", "LEVI_CA"])
    ->  secao("Encomenda online (CH-002)"),
        sim_nao('CH-002', "A encomenda foi encontrada (BackPocket)?", "sim", E), guardar("compraOriginal.encomendaEncontrada", E),
        sim_nao('CH-002', "O portal de devoluções online está disponível?", "sim", P), guardar("portalOnlineDisponivel", P),
        (   E == false
        ->  sim_nao('CH-002', "A política permite a devolução online às cegas neste caso?", "nao", PA),
            guardar("politicaPermiteAsCegasOnline", PA)
        ;   true
        ),
        data('IN-006', "Data de envio da encomenda (AAAA-MM-DD)", "", DE), guardar_texto("compraOriginal.dataEnvio", DE)
    ;   true
    ),
    texto('IN-003', "Stylist da venda original (vazio se desconhecido)", "", S), guardar_texto("compraOriginal.idStylistVenda", S),
    sim_nao('IN-003', "A compra foi feita numa promoção por escalões?", "nao", PE), guardar("compraOriginal.promocaoEscaloes", PE),
    respostas_(R),
    (   R.tipoPedido == "AJUSTE_PRECO"
    ->  sim_nao('IN-003', "Já foi aplicado um ajuste de preço a esta compra?", "nao", AJ), guardar("compraOriginal.ajustePrecoAplicado", AJ)
    ;   true
    ).

perguntas_comprovativo :-
    secao("Comprovativo de compra (IN-004)"),
    sim_nao('IN-004', "O cliente apresenta comprovativo de compra?", "sim", Tem),
    (   Tem == true
    ->  menu('IN-004', "Tipo de comprovativo",
             ["RECIBO_IMPRESSO", "RECIBO_DIGITAL", "CONFIRMACAO_ENCOMENDA", "RECIBO_OFERTA", "CONSULTA_TRANSACAO",
              "FOTOGRAFIA_RECIBO", "CONSULTA_BACKPOCKET"], "RECIBO_IMPRESSO", T),
        guardar("comprovativo.tipo", T),
        sim_nao('IN-004', "O comprovativo confirma a compra?", "sim", C), guardar("comprovativo.confirmaCompra", C),
        sim_nao('IN-004', "É o recibo original?", "sim", O), guardar("comprovativo.reciboOriginal", O),
        (   T == "RECIBO_IMPRESSO"
        ->  sim_nao('IN-004', "O cliente fica com o recibo?", "nao", M), guardar("comprovativo.clienteMantemRecibo", M),
            sim_nao('IN-004', "O recibo inclui outros artigos?", "nao", OA), guardar("comprovativo.incluiOutrosArtigos", OA)
        ;   true
        ),
        (   \+ online
        ->  data('IN-006', "Data da compra indicada no comprovativo (AAAA-MM-DD)", "", D), guardar_texto("compraOriginal.dataCompra", D)
        ;   true
        )
    ;   true
    ).

perguntas_pagamento :-
    respostas_(R),
    (   ( get_dict(comprovativo, R, _) ; online )
    ->  secao("Pagamento original (IN-009)"),
        menu('IN-009', "Meio de pagamento",
             ["CREDITO", "DEBITO", "APPLE_PAY", "GOOGLE_PAY", "PAYPAL", "VENMO", "AFTERPAY", "INTERAC", "NUMERARIO", "CARTAO_OFERTA"],
             "CREDITO", M),
        guardar("compraOriginal.pagamento.meio", M),
        (   memberchk(M, ["CREDITO", "DEBITO", "APPLE_PAY", "GOOGLE_PAY"])
        ->  menu('IN-009', "Estado da conta do cartão", ["ATIVA", "ATIVA_CARTAO_PERDIDO", "ENCERRADA"], "ATIVA", E),
            guardar("compraOriginal.pagamento.estadoConta", E),
            (   ( E == "ENCERRADA" ; M == "DEBITO" )
            ->  sim_nao('IN-009', "O reembolso ao meio original já foi recusado?", "nao", Rec),
                guardar("compraOriginal.pagamento.reembolsoOriginalRecusado", Rec)
            ;   true
            )
        ;   M == "INTERAC"
        ->  sim_nao('IN-009', "O cliente apresenta o mesmo cartão Interac físico?", "sim", F),
            guardar("compraOriginal.pagamento.cartaoFisicoPresente", F)
        ;   memberchk(M, ["PAYPAL", "VENMO"])
        ->  sim_nao('IN-009', "O cliente consegue aceder à aplicação de pagamento?", "sim", A),
            guardar("compraOriginal.pagamento.acessoAplicacaoPagamento", A)
        ;   true
        )
    ;   true
    ).

perguntas_artigos :-
    secao("Artigos devolvidos (IN-007, IN-008)"),
    numero('IN-007', "Quantos artigos são devolvidos?", 1, N0), N is max(1, integer(N0)),
    numlist(1, N, Is),
    foldl(pergunta_artigo, Is, [], ArtigosInv),
    reverse(ArtigosInv, Artigos),
    guardar_valor(artigos, Artigos).

pergunta_artigo(I, Acc, [Artigo|Acc]) :-
    format(string(Id), "A-~d", [I]),
    format("~n  Artigo ~w~n", [Id]),
    texto('IN-007', "SKU", "SKU-1", Sku),
    sim_nao('IN-007', "O SKU é reconhecido no POS?", "sim", Rec),
    menu('IN-007', "Marca", ["LEVIS", "DOCKERS", "LS_SIGNATURE", "BEYOND_YOGA", "OUTRA"], "LEVIS", Marca),
    menu('IN-007', "Categoria", ["VESTUARIO", "ACESSORIO", "BODYWEAR"], "VESTUARIO", Cat),
    sim_nao('IN-007', "É um produto da franquia do Canadá?", "nao", Franquia),
    sim_nao('IN-007', "É um produto grossista?", "nao", Grossista),
    (   Grossista == true -> sim_nao('IN-007', "É vendido nesta loja?", "nao", Vendido) ; Vendido = true ),
    numero('IN-007', "PVP original", 0, Pvp),
    numero('IN-007', "Preço de venda atual", Pvp, Atual),
    sim_nao('IN-007', "Já está em saldo?", "nao", Saldo),
    numero('IN-007', "Valor pago pelo cliente", Atual, Pago),
    sim_nao('IN-003', "Foi comprado noutro canal ou loja (entre canais)?", "nao", Entre),
    menu('IN-008', "Estado de uso", ["NAO_USADO", "USADO", "LAVADO"], "NAO_USADO", Uso),
    (   Cat \== "BODYWEAR", Uso == "NAO_USADO"
    ->  menu('IN-008', "Etiquetas", ["COLOCADAS", "SOLTAS", "AUSENTES"], "COLOCADAS", Etiq)
    ;   Etiq = null
    ),
    sim_nao('IN-008', "Foi personalizado, alterado ou embainhado?", "nao", Alterado),
    sim_nao('IN-008', "Tem defeito de fabrico confirmado?", "nao", Defeito),
    sim_nao('IN-008', "Está sujo, contaminado ou inseguro de manusear?", "nao", Sujo),
    sim_nao('IN-008', "Tem dano visível?", "nao", Dano),
    (   Cat == "BODYWEAR"
    ->  sim_nao('IN-008', "A embalagem original está intacta?", "sim", Emb),
        sim_nao('IN-008', "O conjunto está completo?", "sim", Conj)
    ;   Emb = false, Conj = true
    ),
    Estado0 = _{condicaoUso:Uso, alterado:Alterado, defeitoFabricoConfirmado:Defeito,
                sujoOuInseguro:Sujo, danificado:Dano, embalagemIntacta:Emb, conjuntoCompleto:Conj},
    ( Etiq == null -> Estado = Estado0 ; Estado = Estado0.put(etiquetas, Etiq) ),
    Artigo = _{id:Id, quantidade:1, precoPago:Pago, entreCanais:Entre, estado:Estado,
               produto:_{sku:Sku, skuReconhecidoPOS:Rec, marca:Marca, categoria:Cat, produtoFranquia:Franquia,
                         grossista:Grossista, vendidoNaLoja:Vendido, pvpOriginal:Pvp, precoAtual:Atual, emSaldo:Saldo}}.

perguntas_troca :-
    respostas_(R),
    (   R.tipoPedido == "TROCA"
    ->  secao("Artigo de troca (IN-005)"),
        sim_nao('IN-005', "A troca muda apenas o tamanho?", "sim", Tam),
        numero('IN-005', "Preço de venda do artigo de troca", 0, Preco),
        guardar_valor(artigosTroca, [_{apenasMudaTamanho:Tam, precoVenda:Preco}])
    ;   true
    ).

perguntas_cliente :-
    secao("Cliente (EX-002)"),
    respostas_(R),
    (   \+ get_dict(comprovativo, R, _)
    ->  sim_nao('EX-002', "O cliente fornece dados pessoais?", "sim", D), guardar("cliente.forneceDados", D),
        sim_nao('EX-002', "Há barreira linguística?", "nao", B), guardar("cliente.barreiraLinguistica", B)
    ;   true
    ),
    sim_nao('EX-002', "O cliente contesta o resultado padrão?", "nao", C), guardar("cliente.contestaResultado", C),
    sim_nao('EX-002', "O cliente está irritado ou a causar perturbação?", "nao", A), guardar("cliente.agitado", A).

perguntas_excecao :-
    secao("Exceção (EX-001)"),
    sim_nao('EX-001', "O cliente pede uma exceção à política?", "nao", Pede),
    (   Pede == true
    ->  texto('EX-001', "Motivo", "", Motivo), guardar_texto("pedidoExcecao.motivo", Motivo),
        menu('EX-001', "Resolução pedida", ["REEMBOLSO", "TROCA", "TROCA_MESMO_ARTIGO", "CREDITO_LOJA", "AJUSTE_PRECO"], "REEMBOLSO", Res),
        guardar("pedidoExcecao.resolucaoPedida", Res),
        sim_nao('EX-001', "Exige um meio de pagamento proibido?", "nao", MP), guardar("pedidoExcecao.exigeMeioProibido", MP),
        sim_nao('EX-001', "Exige um SKU incorreto?", "nao", SK), guardar("pedidoExcecao.exigeSkuIncorreto", SK),
        sim_nao('EX-001', "Envolve um produto excluído?", "nao", PX), guardar("pedidoExcecao.envolveProdutoExcluido", PX),
        sim_nao('EX-001', "Contorna um processo obrigatório (Afterpay, PayPal, Venmo, online)?", "nao", CP),
        guardar("pedidoExcecao.contornaProcessoObrigatorio", CP),
        sim_nao('EX-001', "O resultado pode ser concluído no sistema?", "sim", CS), guardar("pedidoExcecao.concluivelNoSistema", CS),
        menu('EX-001', "Decisão da gestão", ["PENDENTE", "APROVADA", "RECUSADA"], "PENDENTE", Dec),
        (   Dec == "APROVADA" -> guardar("pedidoExcecao.aprovada", true)
        ;   Dec == "RECUSADA" -> guardar("pedidoExcecao.aprovada", false)
        ;   true
        )
    ;   true
    ).

perguntas_fraude :-
    secao("Indícios de fraude (EX-008)"),
    sim_nao('EX-008', "Há indícios de fraude ou inconsistências relevantes?", "nao", Ha),
    (   Ha == true
    ->  texto('EX-008', "Descrição do indício", "", D),
        menu('EX-008', "Nível de risco", ["BAIXO", "SIGNIFICATIVO", "CONFIRMADO"], "SIGNIFICATIVO", N),
        guardar_valor(indicadoresFraude, [_{descricao:D, nivelRisco:N}])
    ;   true
    ).

online :-
    respostas_(R),
    get_dict(compraOriginal, R, C), get_dict(canal, C, Canal),
    memberchk(Canal, ["LEVI_COM", "LEVI_CA"]).

% ---------------------------------------------------------------------------------------------
% Perguntas e respostas
% ---------------------------------------------------------------------------------------------

guardar(Caminho, Valor) :-
    retract(respostas_(R0)),
    aplicar_alteracoes(R0, [Caminho-Valor], R),
    assertz(respostas_(R)).

guardar_texto(_, "") :- !.
guardar_texto(Caminho, Valor) :- guardar(Caminho, Valor).

guardar_valor(Chave, Valor) :-
    retract(respostas_(R0)),
    R = R0.put(Chave, Valor),
    assertz(respostas_(R)).

menu(Dado, Texto, Opcoes, Omissao, Valor) :-
    format("~n~w:~n", [Texto]),
    forall(nth1(I, Opcoes, O), format("  ~d) ~w~n", [I, O])),
    nth1(IO, Opcoes, Omissao),
    format(string(P), "Opção [~d]", [IO]),
    repeat,
        perguntar(Dado, P, texto, "", R),
        (   R == "" -> Valor = Omissao
        ;   number_string(N, R), integer(N), nth1(N, Opcoes, Valor) -> true
        ;   string_upper(R, RU), memberchk(RU, Opcoes) -> Valor = RU
        ;   format("Opção inválida.~n"), fail
        ),
    !.

sim_nao(Dado, Texto, Omissao, Valor) :-
    format(string(P), "~w (sim/nao) [~w]", [Texto, Omissao]),
    repeat,
        perguntar(Dado, P, texto, Omissao, R),
        (   resposta_booleana(R, Valor) -> true
        ;   format("Responda sim ou nao.~n"), fail
        ),
    !.

texto(Dado, Texto, Omissao, Valor) :-
    format(string(P), "~w [~w]", [Texto, Omissao]),
    perguntar(Dado, P, texto, Omissao, Valor).

numero(Dado, Texto, Omissao, Valor) :-
    format(string(P), "~w [~w]", [Texto, Omissao]),
    repeat,
        perguntar(Dado, P, texto, "", R),
        (   R == "" -> Valor = Omissao
        ;   number_string(Valor, R) -> true
        ;   format("Indique um número.~n"), fail
        ),
    !.

data(Dado, Texto, Omissao, Valor) :-
    format(string(P), "~w [~w]", [Texto, Omissao]),
    repeat,
        perguntar(Dado, P, texto, Omissao, Valor),
        (   Valor == "" -> true
        ;   catch(normalizar_pedido(_{dataPedido:Valor}, _), _, fail) -> true
        ;   format("Data inválida (use AAAA-MM-DD).~n"), fail
        ),
    !.

resposta_booleana(R, B) :-
    string_lower(R, L),
    (   memberchk(L, ["sim", "s", "yes", "y", "true"]) -> B = true
    ;   memberchk(L, ["nao", "não", "n", "no", "false"]) -> B = false
    ).

%!  perguntar(+Dado, +Texto, +Tipo, +Omissao, -Resposta) is det.
%
%   Lê uma linha. "porque" ou "?" mostra a explicação Porquê do dado e repete a pergunta.
perguntar(Dado, Texto, Tipo, Omissao, Resposta) :-
    format("~w: ", [Texto]), flush_output,
    read_line_to_string(user_input, Linha0),
    (   Linha0 == end_of_file -> throw(sair) ; true ),
    normalize_space(string(Linha), Linha0),
    string_lower(Linha, Min),
    (   memberchk(Min, ["porque", "porquê", "?", "porque?", "porquê?"])
    ->  explicar_pergunta(Dado),
        perguntar(Dado, Texto, Tipo, Omissao, Resposta)
    ;   Min == "sair"
    ->  throw(sair)
    ;   Tipo == sim_nao_vazio
    ->  (   Linha == "" -> Resposta = ""
        ;   resposta_booleana(Linha, Resposta) -> true
        ;   format("Responda sim, nao ou Enter.~n"),
            perguntar(Dado, Texto, Tipo, Omissao, Resposta)
        )
    ;   Linha == ""
    ->  Resposta = Omissao
    ;   Resposta = Linha
    ).

explicar_pergunta(Dado) :-
    (   respostas_(R)
    ->  catch(( preparar_pedido(R, P, F), avaliar_pedido(P, F) ), _, true)
    ;   true
    ),
    (   catch(porque(Dado, E), Erro, ( print_message(error, Erro), fail ))
    ->  format("~n  Porquê? ~w~n", [E.resumo]),
        format("  Regras que usam esta resposta: ~w~n~n", [E.regrasQueDependem])
    ;   true
    ).

% ---------------------------------------------------------------------------------------------
% Decisão e menu de explicações
% ---------------------------------------------------------------------------------------------

mostrar_decisao :-
    titulo("Decisão"),
    forall(member(Codigo-Campo, ['OUT-001'-elegibilidade, 'OUT-002'-tipoTransacao, 'OUT-003'-valorDevolucao,
                                 'OUT-003'-baseValor, 'OUT-004'-meioReembolso, 'OUT-005'-aprovacao,
                                 'OUT-006'-processo]),
           ( campo_saida(Codigo, Desc, _, _), decisao(pedido, Campo, V), valor_json(V, J),
             format("  ~w ~w (~w): ~w~n", [Codigo, Desc, Campo, J]) )),
    decisao(pedido, terminal, Terminal), decisao(pedido, excecaoRecusada, ExR),
    format("  Fluxo terminado por paragem: ~w; exceção recusada: ~w~n", [Terminal, ExR]),
    forall(( decisao(pedido, C, V), atom_concat('documentacao.', N, C), V \== null, V \== false ),
           ( valor_json(V, J0), ( string(V) -> J = V ; J = J0 ), format("  OUT-008 ~w: ~w~n", [N, J]) )),
    format("~n  Artigos:~n"),
    forall(( alvos(As), member(artigo(Id), As) ),
           ( decisao(artigo(Id), elegibilidade, E), decisao(artigo(Id), destino, D),
             decisao(artigo(Id), valorDevolucao, Vl), decisao(artigo(Id), descontoSaldo, Ds),
             maplist(valor_json, [E, D, Vl], [EJ, DJ, VJ]),
             format("    ~w: OUT-001 ~w, OUT-007 ~w (desconto ~w%), valor ~w~n", [Id, EJ, DJ, Ds, VJ]) )),
    codigos_disparados(Cs),
    atomic_list_concat(Cs, ', ', TC),
    format("~n  Regras disparadas: ~w~n", [TC]),
    decisao_json(_{}, DJson),
    (   DJson.regrasAValidar \== []
    ->  atomic_list_concat(DJson.regrasAValidar, ', ', TV),
        format("  Com comportamento provisório (a validar, ADR 0003): ~w~n", [TV])
    ;   true
    ).

menu_explicacoes :-
    format("~nExplicações (escreva um comando; 'ajuda' mostra a lista):~n"),
    ajuda,
    repeat,
        format("~nexplicação> "), flush_output,
        read_line_to_string(user_input, Linha0),
        (   Linha0 == end_of_file -> Linha = "sair" ; normalize_space(string(Linha), Linha0) ),
        split_string(Linha, " ", "", Partes),
        catch(comando(Partes), Erro, ( mostrar_erro(Erro) )),
        Partes = ["sair"|_],
    !.

mostrar_erro(error(_, Mensagem)) :- string(Mensagem), !, format("~w~n", [Mensagem]).
mostrar_erro(Erro) :- print_message(error, Erro).

ajuda :-
    format("  decisao                     mostra a decisão~n"),
    format("  como                        caminho completo (regras disparadas por ordem)~n"),
    format("  como OUT-001 [A-1]          como se chegou a uma conclusão (OUT-007 precisa do artigo)~n"),
    format("  porque-nao PT-003 [A-1]     porque é que uma regra não disparou~n"),
    format("  porque-nao OUT-001=PERMITIR [A-1]  porque é que uma conclusão não foi obtida~n"),
    format("  porque IN-010               porque é que o sistema pergunta um dado~n"),
    format("  falta                       dados em falta~n"),
    format("  e-se caminho=valor [...]    reavalia com alterações (ex.: e-se artigos[0].revendivel=sim)~n"),
    format("  json                        mostra o pedido em JSON~n"),
    format("  sair~n").

comando(["sair"|_]) :- !.
comando([""]) :- !.
comando(["ajuda"]) :- !, ajuda.
comando(["decisao"]) :- !, mostrar_decisao.
comando(["como"]) :- !,
    como(C),
    forall(member(P, C.passos),
           ( ( P.artigoId == null -> A = "" ; format(string(A), " [~w]", [P.artigoId]) ),
             ( P.resultado == null -> R = "" ; format(string(R), " ~w", [P.resultado]) ),
             format("  ~d. ~w ~w~w~w: ~w~n", [P.ordem, P.modulo, P.codigoRegra, A, R, P.mensagem]) )),
    format("~n  ~w~n", [C.resumo]).
comando(["como", Codigo|Resto]) :- !,
    artigo_arg(Resto, Artigo),
    atom_string(C, Codigo),
    como_conclusao(C, Artigo, E),
    format("  ~w~n", [E.resumo]),
    forall(member(Passo, E.caminho), format("    ~w~n", [Passo])),
    (   E.condicoes \== []
    ->  format("  Condições da regra ~w:~n", [E.regra]),
        forall(member(Cd, E.condicoes), mostrar_condicao(Cd))
    ;   true
    ).
comando(["porque-nao", Alvo|Resto]) :- !,
    artigo_arg(Resto, Artigo),
    (   split_string(Alvo, "=:", "", [Codigo, Valor])
    ->  atom_string(C, Codigo),
        porque_nao_conclusao(C, Valor, Artigo, E),
        format("  ~w~n", [E.resumo]),
        forall(member(R, E.regras), mostrar_porque_nao(R))
    ;   atom_string(C, Alvo),
        porque_nao_regra(C, Artigo, E),
        mostrar_porque_nao(E)
    ).
comando(["porque", Dado]) :- !,
    atom_string(D, Dado),
    porque(D, E),
    format("  ~w~n", [E.resumo]).
comando(["falta"]) :- !,
    pedido_atual(P),
    dados_em_falta(P, F),
    format("  ~w~n", [F.resumo]),
    forall(member(D, F.dados),
           ( ( D.obrigatorio == true -> O = "obrigatório" ; O = "para decidir uma revisão" ),
             format("    ~w ~w (~w) — ~w~n", [D.codigo, D.descricao, D.caminho, O]) )).
comando(["e-se"|Alteracoes]) :- !,
    Alteracoes \== [],
    json_atual_(Json),
    maplist(alteracao_texto, Alteracoes, Pares),
    dict_pairs(Dict, alteracoes, Pares),
    resultado_comparavel(Original),
    e_se(Json, Dict, Original, E),
    format("  ~w~n", [E.resumo]),
    forall(member(D, E.diferencas), format("    ~w.~w: ~w → ~w~n", [D.alvo, D.campo, D.original, D.simulado])),
    format("  Regras novas: ~w; regras que deixaram de disparar: ~w~n", [E.regrasNovas, E.regrasRemovidas]),
    format("  (a avaliação original foi reposta)~n"),
    avaliar_json_atual(Json).
comando(["json"]) :- !,
    json_atual_(Json),
    json_write_dict(current_output, Json, [width(100)]), nl.
comando(Outro) :-
    atomic_list_concat(Outro, ' ', T),
    format("Comando desconhecido: ~w (escreva 'ajuda').~n", [T]).

artigo_arg([], null) :- !.
artigo_arg([A|_], A).

alteracao_texto(Texto, Chave-Valor) :-
    split_string(Texto, "=", "", [Caminho, V0]),
    atom_string(Chave, Caminho),
    (   resposta_booleana(V0, B) -> Valor = B
    ;   V0 == "null" -> Valor = null
    ;   number_string(N, V0) -> Valor = N
    ;   Valor = V0
    ).

mostrar_porque_nao(E) :-
    format("  ~w: ~w~n", [E.causa, E.resumo]),
    forall(member(Cd, E.condicoes), mostrar_condicao(Cd)).

mostrar_condicao(Cd) :-
    ( Cd.cumprida == true -> M = "✔" ; Cd.cumprida == false -> M = "✘" ; M = "?" ),
    ( Cd.valor == null -> V = "" ; format(string(V), " (~w)", [Cd.valor]) ),
    ( Cd.artigoId == null -> A = "" ; format(string(A), " [~w]", [Cd.artigoId]) ),
    format("      ~w ~w~w~w~n", [M, Cd.descricao, A, V]).

titulo(T) :- format("~n=== ~w ===~n", [T]).
secao(T) :- format("~n--- ~w ---~n", [T]).
