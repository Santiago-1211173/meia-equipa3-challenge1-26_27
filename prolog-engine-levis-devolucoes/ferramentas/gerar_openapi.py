"""Gera web/openapi.json (OpenAPI 3.0) da API REST do motor Prolog.

Uso (na pasta prolog-engine-levis-devolucoes):  python ferramentas/gerar_openapi.py
Os exemplos dos pedidos são os 10 cenários de testes/cenarios/.
"""
import json
import os

projeto = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def ref(nome):
    return {'$ref': f'#/components/schemas/{nome}'}

def enum(*valores, nulo=False):
    s = {'type': 'string', 'enum': list(valores)}
    if nulo:
        s['nullable'] = True
    return s

def obj(props, descricao=None, obrigatorios=None):
    s = {'type': 'object', 'properties': props}
    if descricao:
        s['description'] = descricao
    if obrigatorios:
        s['required'] = obrigatorios
    return s

def arr(item):
    return {'type': 'array', 'items': item}

def b(desc=None, omissao=None, nulo=False):
    s = {'type': 'boolean'}
    if desc:
        s['description'] = desc
    if omissao is not None:
        s['default'] = omissao
    if nulo:
        s['nullable'] = True
    return s

def txt(desc=None, nulo=True, **extra):
    s = {'type': 'string'}
    if desc:
        s['description'] = desc
    if nulo:
        s['nullable'] = True
    s.update(extra)
    return s

def num(desc=None):
    s = {'type': 'number', 'nullable': True}
    if desc:
        s['description'] = desc
    return s

ELEG = ['PERMITIR', 'REVER', 'ENCAMINHAR', 'RECUSAR']
TRANSACAO = ['REEMBOLSO', 'TROCA', 'TROCA_MESMO_ARTIGO', 'CREDITO_LOJA', 'AJUSTE_PRECO', 'NENHUMA']
DADOS = ['IN-001', 'IN-002', 'IN-003', 'IN-004', 'IN-005', 'IN-006', 'IN-007', 'IN-008', 'IN-009', 'IN-010',
         'HS-006', 'EX-001', 'EX-002', 'EX-008', 'CH-002']
SAIDAS = ['OUT-001', 'OUT-002', 'OUT-003', 'OUT-004', 'OUT-005', 'OUT-006', 'OUT-007', 'OUT-008']

schemas = {
    # ----------------------------------------------------------------------------- pedido
    'Colaborador': obj({
        'id': txt('Identificador do colaborador'),
        'nome': txt(),
        'funcao': enum('GESTAO_LOJA', 'KEY_HOLDER', 'XSTORE_MANAGER', 'LEAD_CASHIER', 'ELEVATED_STYLIST', 'STYLIST', nulo=True),
        'aprovadoPeloDM': b('Lead Cashier ou Elevated Stylist aprovado pelo District Manager', False),
        'idCredencialPOS': txt('Credencial de POS própria (CT-003)'),
    }, 'Colaborador que processa (HS-006). Na API Drools vem do token JWT; aqui vem no corpo do pedido.'),
    'Loja': obj({
        'codigo': txt(), 'nome': txt(),
        'mercado': {**enum('EUA', 'CANADA', nulo=True), 'description': 'IN-001'},
        'tipoLoja': {**enum('MAINLINE', 'OUTLET', nulo=True), 'description': 'IN-002'},
        'lojaBackPocket': b(omissao=False),
        'coberturaLojaUnica': b('Cobertura de loja única: a testemunha é "SSC" (CT-005)', False),
        'skusSortido': arr({'type': 'string'}),
    }, 'Loja recetora'),
    'Cliente': obj({
        'id': txt(),
        'forneceDados': b('PT-006', True),
        'barreiraLinguistica': b(omissao=False),
        'contestaResultado': b('EX-002', False),
        'agitado': b('EX-003', False),
    }, 'Cliente (EX-002, EX-003, PT-006)'),
    'Pagamento': obj({
        'meio': {**enum('CREDITO', 'DEBITO', 'APPLE_PAY', 'GOOGLE_PAY', 'PAYPAL', 'VENMO', 'AFTERPAY', 'INTERAC',
                        'NUMERARIO', 'CARTAO_OFERTA', nulo=True), 'description': 'IN-009'},
        'valorPago': num(),
        'estadoConta': enum('ATIVA', 'ATIVA_CARTAO_PERDIDO', 'ENCERRADA', nulo=True),
        'cartaoFisicoPresente': b('Interac: o mesmo cartão físico (TN-011)', False),
        'reembolsoOriginalRecusado': b('TN-003, TN-004', False),
        'acessoAplicacaoPagamento': b('PayPal/Venmo: o cliente acede à aplicação (TN-008)', True),
    }, 'Pagamento original (IN-009)'),
    'CompraOriginal': obj({
        'idTransacao': txt(),
        'canal': {**enum('MAINLINE', 'OUTLET', 'LEVI_COM', 'LEVI_CA', 'BACKPOCKET', 'FRANQUIA_CANADA', 'GROSSISTA',
                         'DESCONHECIDO', nulo=True), 'description': 'IN-003'},
        'dataCompra': txt('IN-006', format='date'),
        'dataEnvio': txt('IN-006 (compras online)', format='date'),
        'pagamento': {**ref('Pagamento'), 'nullable': True},
        'idStylistVenda': txt('CT-004'),
        'quantidadeComprada': {'type': 'integer', 'default': 0},
        'promocaoEscaloes': b('EP-003, EP-004', False),
        'encomendaEncontrada': b('CH-002, CH-003', False),
        'ajustePrecoAplicado': b('PT-007', False),
        'compraOferta': b(omissao=False),
    }, 'Compra original (IN-003, IN-006, IN-009)'),
    'Comprovativo': obj({
        'tipo': {**enum('RECIBO_IMPRESSO', 'RECIBO_DIGITAL', 'CONFIRMACAO_ENCOMENDA', 'RECIBO_OFERTA', 'CONSULTA_TRANSACAO',
                        'FOTOGRAFIA_RECIBO', 'CONSULTA_BACKPOCKET', nulo=True), 'description': 'IN-004'},
        'confirmaCompra': b(omissao=False),
        'reciboOriginal': b('PT-007, PT-008, CT-006', False),
        'clienteMantemRecibo': b(omissao=False),
        'incluiOutrosArtigos': b(omissao=False),
    }, 'Comprovativo apresentado (IN-004); null = sem comprovativo (devolução às cegas)'),
    'Produto': obj({
        'sku': txt(),
        'skuReconhecidoPOS': b('HS-001', False),
        'marca': enum('LEVIS', 'DOCKERS', 'LS_SIGNATURE', 'BEYOND_YOGA', 'OUTRA', nulo=True),
        'categoria': enum('VESTUARIO', 'ACESSORIO', 'BODYWEAR', nulo=True),
        'grossista': b(omissao=False), 'vendidoNaLoja': b(omissao=False),
        'produtoFranquia': b('CH-007, HS-004', False),
        'pvpOriginal': num(), 'precoAtual': num(),
        'emSaldo': b('EP-007', False),
    }, 'Produto (IN-007)'),
    'EstadoProduto': obj({
        'condicaoUso': enum('NAO_USADO', 'USADO', 'LAVADO', nulo=True),
        'etiquetas': enum('COLOCADAS', 'SOLTAS', 'AUSENTES', nulo=True),
        'personalizado': b(omissao=False), 'alterado': b(omissao=False), 'embainhado': b(omissao=False),
        'defeitoFabricoConfirmado': b(omissao=False),
        'sujoOuInseguro': b('PC-008', False),
        'danificado': b(omissao=False),
        'etiquetaPrecoCorreta': b(omissao=True), 'rfidCorreto': b(omissao=True),
        'embalagemIntacta': b('Bodywear (BW-001, BW-002)', False),
        'conjuntoCompleto': b('Bodywear (BW-003)', True),
    }, 'Estado do artigo (IN-008)'),
    'Artigo': obj({
        'id': txt(nulo=False),
        'produto': {**ref('Produto'), 'nullable': True},
        'quantidade': {'type': 'integer', 'default': 1},
        'precoPago': num(),
        'estado': {**ref('EstadoProduto'), 'nullable': True},
        'entreCanais': b('EP-005 a EP-007', False),
        'revendivel': b('IN-010: pode ser verificado, reetiquetado e revendido (null = por avaliar)', nulo=True),
        'valorCalculadoPos': num('PT-007, EP-003, EP-004'),
    }, 'Artigo devolvido'),
    'ArtigoTroca': obj({
        'produto': {**ref('Produto'), 'nullable': True},
        'apenasMudaTamanho': b('EP-001 / EP-002', False),
        'precoVenda': num('TN-006'),
    }, 'Artigo levado numa troca'),
    'PedidoExcecao': obj({
        'motivo': txt(),
        'resolucaoPedida': enum(*TRANSACAO[:-1], nulo=True),
        'exigeMeioProibido': b(omissao=False), 'exigeSkuIncorreto': b(omissao=False),
        'envolveProdutoExcluido': b(omissao=False), 'contornaProcessoObrigatorio': b(omissao=False),
        'concluivelNoSistema': b('EX-004', True),
        'aprovada': b('Decisão da gestão (PC-004, EX-007); null = pendente', nulo=True),
        'aprovador': {**ref('Colaborador'), 'nullable': True},
        'preocupacaoCliente': txt(),
    }, 'Pedido de exceção (EX-001 a EX-007)'),
    'IndicadorFraude': obj({
        'pedidoId': txt('Opcional; se vier, tem de ser o id do pedido'),
        'descricao': txt(),
        'nivelRisco': enum('BAIXO', 'SIGNIFICATIVO', 'CONFIRMADO', nulo=True),
    }, 'Indício de fraude (EX-008): só SIGNIFICATIVO ou CONFIRMADO suspende'),
    'PedidoAvaliacao': obj({
        'id': txt('Referência do pedido', nulo=False),
        'dataPedido': txt('IN-006', format='date'),
        'tipoPedido': {**enum('DEVOLUCAO', 'TROCA', 'DEVOLUCAO_OFERTA', 'AJUSTE_PRECO', nulo=True), 'description': 'IN-005'},
        'loja': {**ref('Loja'), 'nullable': True},
        'colaborador': {**ref('Colaborador'), 'nullable': True},
        'cliente': {**ref('Cliente'), 'nullable': True},
        'compraOriginal': {**ref('CompraOriginal'), 'nullable': True},
        'comprovativo': {**ref('Comprovativo'), 'nullable': True},
        'artigos': arr(ref('Artigo')),
        'artigosTroca': arr(ref('ArtigoTroca')),
        'portalOnlineDisponivel': b('CH-004', True),
        'politicaPermiteAsCegasOnline': b('CH-003', False),
        'pedidoExcecao': {**ref('PedidoExcecao'), 'nullable': True},
        'indicadoresFraude': arr(ref('IndicadorFraude')),
    }, 'Pedido de avaliação (formato do PedidoAvaliacaoRequest da API Drools, com o colaborador no corpo). '
       'Os campos em falta recebem o valor por omissão do modelo.', ['id']),

    # ----------------------------------------------------------------------------- decisão
    'Documentacao': obj({
        'assinaturaCliente': txt(), 'assinaturaProcessador': txt(), 'assinaturaTestemunha': txt(),
        'idStylistAtribuido': txt(), 'reciboAgrafado': b(), 'notaRecibo': txt(),
        'retencaoAte': txt(format='date'), 'registoExcecao': txt(),
    }, 'OUT-008'),
    'ResultadoArtigo': obj({
        'artigoId': txt(nulo=False),
        'elegibilidade': enum(*ELEG, nulo=True),
        'tipoTransacao': enum(*TRANSACAO, nulo=True),
        'valorDevolucao': num(),
        'baseValor': enum('VALOR_PAGO', 'PRECO_ATUAL', 'VALOR_PROMOCIONAL', 'VALOR_ESCALAO', 'VALOR_POS', 'PVP_ORIGINAL', nulo=True),
        'destino': enum('AREA_VENDAS', 'SALDOS', 'REETIQUETAR', 'BAIXA_DANO', 'RISCO_BIOLOGICO', 'DEVOLUCAO_CLIENTE', nulo=True),
        'descontoSaldo': {'type': 'integer'},
        'aprovacao': enum('NENHUMA', 'XSTORE_MANAGER', 'RESPONSAVEL_SENIOR', 'DISTRICT_AREA'),
        'terminal': b(),
    }, 'Resultado de um artigo (ADR 0002)'),
    'RegistoRegra': obj({
        'ordem': {'type': 'integer'}, 'codigoRegra': txt(nulo=False), 'nomeRegra': txt(nulo=False),
        'modulo': txt(nulo=False), 'artigoId': txt(), 'resultado': enum(*ELEG, nulo=True),
        'mensagem': txt(), 'aValidar': b(),
    }, 'Regra disparada'),
    'Decisao': obj({
        'avaliacaoId': txt(format='uuid'), 'pedidoId': txt(nulo=False), 'avaliadaEm': txt(format='date-time'),
        'versaoBaseConhecimento': txt(nulo=False),
        'elegibilidade': {**enum(*ELEG, nulo=True), 'description': 'OUT-001'},
        'tipoVerificacao': enum('NAO_DETERMINADA', 'VERIFICADA', 'AS_CEGAS'),
        'tipoTransacao': {**enum(*TRANSACAO, nulo=True), 'description': 'OUT-002'},
        'valorDevolucao': num('OUT-003'),
        'baseValor': enum('VALOR_PAGO', 'PRECO_ATUAL', 'VALOR_PROMOCIONAL', 'VALOR_ESCALAO', 'VALOR_POS', 'PVP_ORIGINAL', nulo=True),
        'meioReembolso': {**enum('MEIO_ORIGINAL', 'CARTAO_OFERTA', 'CARTAO_OFERTA_ELETRONICO', 'MEIO_ALTERNATIVO',
                                 'APLICACAO_PAGAMENTO', 'CREDITO_LOJA', nulo=True), 'description': 'OUT-004'},
        'aprovacao': {**enum('NENHUMA', 'XSTORE_MANAGER', 'RESPONSAVEL_SENIOR', 'DISTRICT_AREA'), 'description': 'OUT-005'},
        'processo': {**enum('POS', 'BACKPOCKET', 'AFTERPAY', 'PAYPAL_VENMO', 'VERIFONE_INTERAC', 'FRANQUIA_CANADA', 'DANO',
                            'RISCO_BIOLOGICO', nulo=True), 'description': 'OUT-006'},
        'terminal': b('Uma paragem obrigatória terminou o fluxo'),
        'excecaoRecusada': b(),
        'documentacao': ref('Documentacao'),
        'artigos': arr(ref('ResultadoArtigo')),
        'regras': arr(ref('RegistoRegra')),
        'regrasAValidar': arr({'type': 'string'}),
    }, 'Decisão (DecisaoResponse)'),
    'AvaliacaoResumo': obj({
        'avaliacaoId': txt(format='uuid'), 'pedidoId': txt(), 'avaliadaEm': txt(format='date-time'),
        'lojaCodigo': txt(), 'elegibilidade': enum(*ELEG, nulo=True), 'tipoTransacao': enum(*TRANSACAO, nulo=True),
        'valorDevolucao': num(),
    }),
    'PaginaAvaliacoes': obj({
        'conteudo': arr(ref('AvaliacaoResumo')), 'pagina': {'type': 'integer'}, 'tamanho': {'type': 'integer'},
        'totalElementos': {'type': 'integer'}, 'totalPaginas': {'type': 'integer'},
    }),

    # ----------------------------------------------------------------------------- explicações
    'Condicao': obj({
        'nome': txt(nulo=False), 'descricao': txt(nulo=False), 'cumprida': b(nulo=True),
        'valor': txt('Valores de entrada que a condição lê'), 'artigoId': txt(),
    }),
    'Passo': obj({
        'ordem': {'type': 'integer'}, 'modulo': txt(nulo=False), 'codigoRegra': txt(nulo=False),
        'nomeRegra': txt(nulo=False), 'artigoId': txt(), 'resultado': enum(*ELEG, nulo=True),
        'mensagem': txt(), 'aValidar': b(),
    }),
    'ExplicacaoComo': obj({
        'passos': arr(ref('Passo')), 'modulosPercorridos': arr({'type': 'string'}),
        'paragem': txt('Paragem obrigatória que terminou o fluxo'), 'resumo': txt(nulo=False),
    }, 'Como? — caminho completo'),
    'ExplicacaoConclusao': obj({
        'conclusao': txt(nulo=False), 'artigoId': txt(), 'valores': {'type': 'object', 'additionalProperties': {'type': 'string'}},
        'regra': txt('Regra que fixou o valor'), 'mensagem': txt(), 'condicoes': arr(ref('Condicao')),
        'caminho': arr({'type': 'string'}), 'resumo': txt(nulo=False),
    }, 'Como? — caminho de uma conclusão'),
    'PorqueNaoRegra': obj({
        'codigoRegra': txt(nulo=False), 'artigoId': txt(),
        'causa': enum('DISPAROU', 'MODULO_NAO_ALCANCADO', 'CANCELADA_POR_PRECEDENCIA', 'CONDICOES_FALHADAS'),
        'regraResponsavel': txt(), 'variante': txt(), 'condicoes': arr(ref('Condicao')), 'resumo': txt(nulo=False),
    }, 'Porque não? — uma regra'),
    'PorqueNaoConclusao': obj({
        'conclusao': txt(nulo=False), 'valor': txt(nulo=False), 'artigoId': txt(), 'valorObtido': txt(),
        'obtida': b(), 'propostaPor': arr({'type': 'string'}), 'definidoPor': txt(),
        'regras': arr(ref('PorqueNaoRegra')), 'resumo': txt(nulo=False),
    }, 'Porque não? — uma conclusão'),
    'RegraEmEspera': obj({
        'codigoRegra': txt(nulo=False), 'nomeRegra': txt(nulo=False), 'modulo': txt(nulo=False), 'artigoId': txt(),
        'conclusoes': arr({'type': 'string'}), 'condicoesDoDado': arr(ref('Condicao')),
    }),
    'ExplicacaoPorque': obj({
        'dado': txt(nulo=False), 'pergunta': txt(nulo=False), 'regrasQueDependem': arr({'type': 'string'}),
        'regrasEmEspera': arr(ref('RegraEmEspera')), 'resumo': txt(nulo=False),
    }, 'Porquê? — porque é que o sistema faz uma pergunta'),
    'DadoEmFalta': obj({
        'codigo': txt(nulo=False), 'caminho': txt(nulo=False), 'descricao': txt(nulo=False), 'obrigatorio': b(),
        'porque': {**ref('ExplicacaoPorque'), 'nullable': True},
    }),
    'DadosEmFalta': obj({'dados': arr(ref('DadoEmFalta')), 'completo': b(), 'resumo': txt(nulo=False)}, 'O que falta?'),
    'Simulacao': obj({
        'alteracoes': {'type': 'object', 'additionalProperties': True,
                       'description': 'Caminho → novo valor (null remove)',
                       'example': {'artigos[0].revendivel': True, 'compraOriginal.pagamento.meio': 'DEBITO'}},
    }, 'E se?', ['alteracoes']),
    'Diferenca': obj({'alvo': txt(nulo=False), 'campo': txt(nulo=False), 'original': txt(), 'simulado': txt()}),
    'ResultadoSimulacao': obj({
        'diferencas': arr(ref('Diferenca')), 'regrasNovas': arr({'type': 'string'}),
        'regrasRemovidas': arr({'type': 'string'}), 'resumo': txt(nulo=False), 'decisaoSimulada': ref('Decisao'),
    }),

    # ----------------------------------------------------------------------------- catálogo e outros
    'RegraResumo': obj({
        'id': txt(nulo=False), 'modulos': arr({'type': 'string'}), 'descricao': txt(nulo=False),
        'variantes': {'type': 'integer'}, 'aValidar': b(),
    }),
    'Variante': obj({
        'nome': txt(nulo=False), 'modulo': txt(nulo=False), 'prioridade': {'type': 'integer'}, 'descricao': txt(nulo=False),
        'condicoes': arr({'type': 'string'}), 'conclusoes': arr({'type': 'string'}), 'aValidar': b(),
    }),
    'RegraDetalhe': obj({'id': txt(nulo=False), 'variantes': arr(ref('Variante'))}),
    'Exemplo': obj({'id': {'type': 'integer'}, 'titulo': txt(nulo=False), 'pedido': ref('PedidoAvaliacao')}),
    'Saude': obj({'status': txt(nulo=False), 'motor': txt(nulo=False), 'versaoBaseConhecimento': txt(nulo=False),
                  'regras': {'type': 'integer'}}),
    'Problema': obj({
        'type': txt(nulo=False), 'title': txt(nulo=False), 'status': {'type': 'integer'}, 'detail': txt(),
        'erros': arr({'type': 'string'}),
    }, 'ProblemDetail (RFC 9457)'),
}

# --------------------------------------------------------------------------------- exemplos (cenários)
def cenario(n):
    with open(os.path.join(projeto, 'testes', 'cenarios', f'cenario-{n:02d}.json'), encoding='utf-8') as f:
        c = json.load(f)
    pedido = dict(c['pedido'])
    pedido['indicadoresFraude'] = c.get('indicadoresFraude', [])
    return {'summary': f"Cenário {n}: {c['titulo']}", 'value': pedido}

exemplos = {f'cenario{n}': cenario(n) for n in range(1, 11)}

def resp(descricao, esquema=None, extra=None):
    r = {'description': descricao}
    if esquema:
        r['content'] = {'application/json': {'schema': esquema}}
    if extra:
        r.update(extra)
    return r

problema = {'application/problem+json': {'schema': ref('Problema')}}
erro = lambda d: {'description': d, 'content': problema}
id_param = {'name': 'id', 'in': 'path', 'required': True, 'description': 'avaliacaoId devolvido pelo POST /avaliacoes',
            'schema': {'type': 'string'}}
artigo_param = {'name': 'artigo', 'in': 'query', 'required': False, 'description': 'ID do artigo (ex.: A-1)',
                'schema': {'type': 'string'}}
corpo_pedido = {'required': True, 'content': {'application/json': {'schema': ref('PedidoAvaliacao'), 'examples': exemplos}}}

paths = {
    '/api/v1/saude': {'get': {
        'tags': ['Serviço'], 'summary': 'Estado do serviço', 'operationId': 'saude',
        'responses': {'200': resp('Serviço disponível', ref('Saude'))}}},
    '/api/v1/avaliacoes': {
        'post': {
            'tags': ['Avaliações'], 'summary': 'Avaliar um pedido de devolução', 'operationId': 'avaliar',
            'description': 'Corre o motor de inferência sobre o pedido e grava a avaliação (em memória). '
                           'Escolha um dos 10 cenários em "Examples". Um pedido sem dados obrigatórios dá 422.',
            'requestBody': corpo_pedido,
            'responses': {
                '201': resp('Avaliação gravada', ref('Decisao'),
                            {'headers': {'Location': {'schema': {'type': 'string'}, 'description': 'URL da avaliação'}}}),
                '400': erro('JSON inválido'), '422': erro('Faltam dados obrigatórios (lista em "erros")')}},
        'get': {
            'tags': ['Avaliações'], 'summary': 'Listar as avaliações (mais recentes primeiro)', 'operationId': 'listarAvaliacoes',
            'parameters': [
                {'name': 'loja', 'in': 'query', 'schema': {'type': 'string'}, 'description': 'Código da loja'},
                {'name': 'pagina', 'in': 'query', 'schema': {'type': 'integer', 'default': 0}},
                {'name': 'tamanho', 'in': 'query', 'schema': {'type': 'integer', 'default': 20}}],
            'responses': {'200': resp('Página de avaliações', ref('PaginaAvaliacoes'))}}},
    '/api/v1/avaliacoes/{id}': {'get': {
        'tags': ['Avaliações'], 'summary': 'Consultar uma avaliação', 'operationId': 'consultarAvaliacao',
        'parameters': [id_param],
        'responses': {'200': resp('Decisão', ref('Decisao')), '404': erro('Avaliação inexistente')}}},
    '/api/v1/avaliacoes/dados-em-falta': {'post': {
        'tags': ['Explicações'], 'summary': 'O que falta? (aceita pedidos incompletos)', 'operationId': 'dadosEmFalta',
        'requestBody': corpo_pedido,
        'responses': {'200': resp('Dados em falta, cada um com o seu Porquê', ref('DadosEmFalta'))}}},
    '/api/v1/avaliacoes/porque': {'post': {
        'tags': ['Explicações'], 'summary': 'Porquê? — porque é que o sistema pergunta um dado', 'operationId': 'porque',
        'parameters': [{'name': 'dado', 'in': 'query', 'required': True, 'schema': {'type': 'string', 'enum': DADOS},
                        'description': 'Código do dado de entrada'}],
        'requestBody': corpo_pedido,
        'responses': {'200': resp('Explicação', ref('ExplicacaoPorque')), '404': erro('Dado desconhecido')}}},
    '/api/v1/avaliacoes/{id}/explicacoes/como': {'get': {
        'tags': ['Explicações'], 'summary': 'Como? — caminho completo ou de uma conclusão', 'operationId': 'como',
        'description': 'Sem "conclusao": todas as regras disparadas, por ordem. Com "conclusao": como se chegou a esse campo '
                       'de saída (OUT-007 precisa do artigo).',
        'parameters': [id_param,
                       {'name': 'conclusao', 'in': 'query', 'schema': {'type': 'string', 'enum': SAIDAS}},
                       artigo_param],
        'responses': {'200': {'description': 'Explicação', 'content': {'application/json': {'schema': {
            'oneOf': [ref('ExplicacaoComo'), ref('ExplicacaoConclusao')]}}}},
            '400': erro('Conclusão por artigo sem o artigo'), '404': erro('Avaliação inexistente')}}},
    '/api/v1/avaliacoes/{id}/explicacoes/porque-nao': {'get': {
        'tags': ['Explicações'], 'summary': 'Porque não? — uma conclusão ou uma regra', 'operationId': 'porqueNao',
        'description': 'Indique "conclusao" (formato OUT-00n:VALOR, ex.: OUT-001:PERMITIR) ou "regra" (ex.: PT-003).',
        'parameters': [id_param,
                       {'name': 'conclusao', 'in': 'query', 'schema': {'type': 'string', 'example': 'OUT-001:PERMITIR'}},
                       {'name': 'regra', 'in': 'query', 'schema': {'type': 'string', 'example': 'PT-004'}},
                       artigo_param],
        'responses': {'200': {'description': 'Explicação', 'content': {'application/json': {'schema': {
            'oneOf': [ref('PorqueNaoConclusao'), ref('PorqueNaoRegra')]}}}},
            '400': erro('Parâmetros inválidos'), '404': erro('Avaliação ou regra inexistente')}}},
    '/api/v1/avaliacoes/{id}/simulacoes': {'post': {
        'tags': ['Explicações'], 'summary': 'E se? — reavaliar com alterações', 'operationId': 'simular',
        'description': 'Reavalia o pedido gravado com as alterações indicadas, sem alterar a avaliação gravada.',
        'parameters': [id_param],
        'requestBody': {'required': True, 'content': {'application/json': {'schema': ref('Simulacao'), 'examples': {
            'revenda': {'summary': 'O artigo pode ser revendido', 'value': {'alteracoes': {'artigos[0].revendivel': True}}},
            'debito': {'summary': 'Pago a débito e embainhado',
                       'value': {'alteracoes': {'compraOriginal.pagamento.meio': 'DEBITO', 'artigos[0].estado.embainhado': True}}},
            'semComprovativo': {'summary': 'Sem comprovativo', 'value': {'alteracoes': {'comprovativo': None}}}}}}},
        'responses': {'200': resp('Diferenças e decisão simulada', ref('ResultadoSimulacao')),
                      '400': erro('Caminho desconhecido'), '404': erro('Avaliação inexistente')}}},
    '/api/v1/regras': {'get': {
        'tags': ['Regras'], 'summary': 'Catálogo das regras (76 IDs)', 'operationId': 'listarRegras',
        'responses': {'200': resp('Regras', arr(ref('RegraResumo')))}}},
    '/api/v1/regras/{codigo}': {'get': {
        'tags': ['Regras'], 'summary': 'Variantes de uma regra', 'operationId': 'detalheRegra',
        'parameters': [{'name': 'codigo', 'in': 'path', 'required': True, 'schema': {'type': 'string', 'example': 'PC-002'}}],
        'responses': {'200': resp('Variantes', ref('RegraDetalhe')), '404': erro('Regra desconhecida')}}},
    '/api/v1/exemplos': {'get': {
        'tags': ['Serviço'], 'summary': 'Os 10 cenários de teste (docs/06)', 'operationId': 'exemplos',
        'responses': {'200': resp('Cenários', arr(ref('Exemplo')))}}},
}

spec = {
    'openapi': '3.0.3',
    'info': {
        'title': 'Sistema pericial de devoluções e trocas Levi\'s — motor SWI-Prolog',
        'version': '1.0.0',
        'description': (
            'API REST do motor Prolog, com os mesmos caminhos e formatos JSON da API Drools.\n\n'
            '**Como experimentar:** em `POST /api/v1/avaliacoes`, carregue em *Try it out*, escolha um cenário em '
            '*Examples* e carregue em *Execute*. Copie o `avaliacaoId` da resposta para usar nas explicações '
            '(Como?, Porque não?, E se?).\n\n'
            'Diferenças em relação à API Drools: sem JWT (o colaborador vem no corpo do pedido), avaliações em memória '
            'e textos só em português.'),
    },
    'servers': [{'url': '/', 'description': 'Este servidor'}],
    'tags': [
        {'name': 'Avaliações', 'description': 'Avaliar pedidos e consultar decisões'},
        {'name': 'Explicações', 'description': 'Como?, Porque não?, Porquê?, O que falta? e E se?'},
        {'name': 'Regras', 'description': 'Catálogo da base de conhecimento'},
        {'name': 'Serviço', 'description': 'Estado e exemplos'},
    ],
    'paths': paths,
    'components': {'schemas': schemas},
}

with open(os.path.join(projeto, 'web', 'openapi.json'), 'w', encoding='utf-8') as f:
    json.dump(spec, f, ensure_ascii=False, indent=2)
print('ok', len(paths), 'caminhos', len(schemas), 'esquemas')
