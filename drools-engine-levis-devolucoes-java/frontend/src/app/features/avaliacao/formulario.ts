import {
  CANAL_COMPRA,
  CATEGORIA_PRODUTO,
  CONDICAO_USO,
  ESTADO_CONTA,
  ESTADO_ETIQUETAS,
  FUNCAO,
  GRAU_USO,
  MARCA,
  MEIO_PAGAMENTO,
  MERCADO,
  NIVEL_RISCO,
  RESPOSTA,
  Rotulos,
  TIPO_COMPROVATIVO,
  TIPO_LOJA,
  TIPO_PEDIDO,
  TIPO_TRANSACAO,
} from '../../shared/rotulos';

/**
 * Definição do pedido de avaliação como formulário: passos, grupos (cada um ligado às perguntas da
 * base de conhecimento a que responde) e campos com o mesmo caminho que a API usa.
 */

export type TipoCampo =
  | 'texto'
  | 'texto-longo'
  | 'data'
  | 'inteiro'
  | 'decimal'
  /** boolean da API: falso por omissão */
  | 'booleano'
  /** Boolean da API: vazio quer dizer "não indicado" (o sistema completa ou usa o valor por omissão) */
  | 'booleano-opcional'
  | 'opcoes'
  /** inteiro escolhido numa escala de opções (ex.: grau de uso de 0 a 4) */
  | 'escala'
  /** lista de textos (ex.: SKUs), escrita separada por vírgulas */
  | 'lista';

export interface Campo {
  /** Caminho no pedido; nos grupos repetíveis, relativo a cada item */
  readonly caminho: string;
  readonly rotulo: string;
  readonly tipo: TipoCampo;
  readonly opcoes?: Rotulos;
  readonly obrigatorio?: boolean;
  /** Só aparece quando este campo (relativo ao item, nos grupos repetíveis) é verdadeiro */
  readonly visivelSe?: string;
}

export interface Repeticao {
  /** Caminho da lista no pedido (ex.: `artigos`) */
  readonly caminho: string;
  readonly rotuloItem: string;
  readonly adicionar: string;
  /** Pelo menos um item (ex.: artigos) */
  readonly minimo: number;
}

export interface Grupo {
  readonly id: string;
  readonly titulo: string;
  /** Perguntas da base de conhecimento (IN-001, HS-006, ...) a que o grupo responde */
  readonly dados: readonly string[];
  readonly campos: readonly Campo[];
  readonly repeticao?: Repeticao;
  /**
   * Objeto opcional: se ficar por preencher, é enviado vazio (ex.: sem comprovativo é uma devolução
   * às cegas).
   */
  readonly opcional?: string;
  /** Só aparece quando o objeto indicado foi preenchido */
  readonly visivelSe?: string;
}

export interface Passo {
  readonly id: string;
  readonly titulo: string;
  readonly grupos: readonly Grupo[];
}

function camposProduto(): Campo[] {
  return [
    {
      caminho: 'produto.sku',
      rotulo: $localize`:@@campo.produto.sku:SKU`,
      tipo: 'texto',
      obrigatorio: true,
    },
    {
      caminho: 'produto.marca',
      rotulo: $localize`:@@campo.produto.marca:Marca`,
      tipo: 'opcoes',
      opcoes: MARCA,
    },
    {
      caminho: 'produto.categoria',
      rotulo: $localize`:@@campo.produto.categoria:Categoria`,
      tipo: 'opcoes',
      opcoes: CATEGORIA_PRODUTO,
    },
    {
      caminho: 'produto.skuReconhecidoPOS',
      rotulo: $localize`:@@campo.produto.skuReconhecidoPOS:SKU reconhecido pelo POS`,
      tipo: 'booleano-opcional',
    },
    {
      caminho: 'produto.vendidoNaLoja',
      rotulo: $localize`:@@campo.produto.vendidoNaLoja:Vendido nesta loja (sortido)`,
      tipo: 'booleano-opcional',
    },
    {
      caminho: 'produto.emSaldo',
      rotulo: $localize`:@@campo.produto.emSaldo:Em saldo`,
      tipo: 'booleano-opcional',
    },
    {
      caminho: 'produto.grossista',
      rotulo: $localize`:@@campo.produto.grossista:Produto de grossista`,
      tipo: 'booleano-opcional',
    },
    {
      caminho: 'produto.produtoFranquia',
      rotulo: $localize`:@@campo.produto.produtoFranquia:Produto de franquia`,
      tipo: 'booleano-opcional',
    },
    {
      caminho: 'produto.pvpOriginal',
      rotulo: $localize`:@@campo.produto.pvpOriginal:PVP original`,
      tipo: 'decimal',
    },
    {
      caminho: 'produto.precoAtual',
      rotulo: $localize`:@@campo.produto.precoAtual:Preço atual`,
      tipo: 'decimal',
    },
    {
      caminho: 'produto.defeitoConhecido',
      rotulo: $localize`:@@campo.produto.defeitoConhecido:Defeito conhecido para o SKU (catálogo)`,
      tipo: 'booleano-opcional',
    },
  ];
}

/** Perguntas da inspeção do defeito (docs/08 §3.3), só quando o cliente alega defeito. */
function perguntasDeInspecao(): Campo[] {
  const pergunta = (codigo: string, rotulo: string): Campo => ({
    caminho: `estado.inspecaoDefeito.${codigo}`,
    rotulo,
    tipo: 'opcoes',
    opcoes: RESPOSTA,
    visivelSe: 'estado.alegaDefeito',
  });
  return [
    pergunta('ED-01', $localize`:@@campo.inspecao.ED-01:Dano numa costura ou ponto de união`),
    pergunta('ED-02', $localize`:@@campo.inspecao.ED-02:Dano localizado num único ponto`),
    pergunta('ED-05', $localize`:@@campo.inspecao.ED-05:Desgaste generalizado do tecido`),
    pergunta('ED-06', $localize`:@@campo.inspecao.ED-06:Sinais de lavagem repetida`),
    pergunta(
      'ED-07',
      $localize`:@@campo.inspecao.ED-07:Dano compatível com uso indevido (corte, queimadura, rasgão)`,
    ),
  ];
}

export const PASSOS: readonly Passo[] = [
  {
    id: 'pedido',
    titulo: $localize`:@@passo.pedido:Pedido e loja`,
    grupos: [
      {
        id: 'pedido',
        titulo: $localize`:@@grupo.pedido:Pedido do cliente`,
        dados: ['IN-005', 'IN-006'],
        campos: [
          {
            caminho: 'tipoPedido',
            rotulo: $localize`:@@campo.tipoPedido:O que pede o cliente`,
            tipo: 'opcoes',
            opcoes: TIPO_PEDIDO,
          },
          {
            caminho: 'dataPedido',
            rotulo: $localize`:@@campo.dataPedido:Data do pedido`,
            tipo: 'data',
          },
          { caminho: 'id', rotulo: $localize`:@@campo.id:Referência do pedido`, tipo: 'texto' },
        ],
      },
      {
        id: 'loja',
        titulo: $localize`:@@grupo.loja:Loja`,
        dados: ['IN-001', 'IN-002'],
        campos: [
          {
            caminho: 'loja.codigo',
            rotulo: $localize`:@@campo.loja.codigo:Código da loja`,
            tipo: 'texto',
            obrigatorio: true,
          },
          {
            caminho: 'loja.nome',
            rotulo: $localize`:@@campo.loja.nome:Nome da loja`,
            tipo: 'texto',
          },
          {
            caminho: 'loja.mercado',
            rotulo: $localize`:@@campo.loja.mercado:Mercado`,
            tipo: 'opcoes',
            opcoes: MERCADO,
          },
          {
            caminho: 'loja.tipoLoja',
            rotulo: $localize`:@@campo.loja.tipoLoja:Tipo de loja`,
            tipo: 'opcoes',
            opcoes: TIPO_LOJA,
          },
          {
            caminho: 'loja.lojaBackPocket',
            rotulo: $localize`:@@campo.loja.lojaBackPocket:Loja com BackPocket`,
            tipo: 'booleano',
          },
          {
            caminho: 'loja.coberturaLojaUnica',
            rotulo: $localize`:@@campo.loja.coberturaLojaUnica:Cobertura de loja única`,
            tipo: 'booleano',
          },
          {
            caminho: 'loja.skusSortido',
            rotulo: $localize`:@@campo.loja.skusSortido:SKUs do sortido (separados por vírgulas)`,
            tipo: 'lista',
          },
        ],
      },
    ],
  },
  {
    id: 'compra',
    titulo: $localize`:@@passo.compra:Compra e pagamento`,
    grupos: [
      {
        id: 'compra',
        titulo: $localize`:@@grupo.compra:Compra original`,
        dados: ['IN-003', 'IN-006'],
        campos: [
          {
            caminho: 'compraOriginal.canal',
            rotulo: $localize`:@@campo.compraOriginal.canal:Canal de compra`,
            tipo: 'opcoes',
            opcoes: CANAL_COMPRA,
          },
          {
            caminho: 'compraOriginal.idTransacao',
            rotulo: $localize`:@@campo.compraOriginal.idTransacao:Transação ou encomenda`,
            tipo: 'texto',
          },
          {
            caminho: 'compraOriginal.dataCompra',
            rotulo: $localize`:@@campo.compraOriginal.dataCompra:Data da compra`,
            tipo: 'data',
          },
          {
            caminho: 'compraOriginal.dataEnvio',
            rotulo: $localize`:@@campo.compraOriginal.dataEnvio:Data de envio (online)`,
            tipo: 'data',
          },
          {
            caminho: 'compraOriginal.quantidadeComprada',
            rotulo: $localize`:@@campo.compraOriginal.quantidadeComprada:Quantidade comprada`,
            tipo: 'inteiro',
          },
          {
            caminho: 'compraOriginal.idStylistVenda',
            rotulo: $localize`:@@campo.compraOriginal.idStylistVenda:Stylist da venda`,
            tipo: 'texto',
          },
          {
            caminho: 'compraOriginal.promocaoEscaloes',
            rotulo: $localize`:@@campo.compraOriginal.promocaoEscaloes:Promoção por escalões`,
            tipo: 'booleano',
          },
          {
            caminho: 'compraOriginal.ajustePrecoAplicado',
            rotulo: $localize`:@@campo.compraOriginal.ajustePrecoAplicado:Já teve ajuste de preço`,
            tipo: 'booleano',
          },
          {
            caminho: 'compraOriginal.compraOferta',
            rotulo: $localize`:@@campo.compraOriginal.compraOferta:Compra para oferta`,
            tipo: 'booleano',
          },
        ],
      },
      {
        id: 'pagamento',
        titulo: $localize`:@@grupo.pagamento:Pagamento original`,
        dados: ['IN-009'],
        opcional: 'compraOriginal.pagamento',
        campos: [
          {
            caminho: 'compraOriginal.pagamento.meio',
            rotulo: $localize`:@@campo.compraOriginal.pagamento.meio:Meio de pagamento`,
            tipo: 'opcoes',
            opcoes: MEIO_PAGAMENTO,
          },
          {
            caminho: 'compraOriginal.pagamento.valorPago',
            rotulo: $localize`:@@campo.compraOriginal.pagamento.valorPago:Valor pago`,
            tipo: 'decimal',
          },
          {
            caminho: 'compraOriginal.pagamento.estadoConta',
            rotulo: $localize`:@@campo.compraOriginal.pagamento.estadoConta:Estado da conta`,
            tipo: 'opcoes',
            opcoes: ESTADO_CONTA,
          },
          {
            caminho: 'compraOriginal.pagamento.cartaoFisicoPresente',
            rotulo: $localize`:@@campo.compraOriginal.pagamento.cartaoFisicoPresente:Cartão físico presente`,
            tipo: 'booleano',
          },
          {
            caminho: 'compraOriginal.pagamento.acessoAplicacaoPagamento',
            rotulo: $localize`:@@campo.compraOriginal.pagamento.acessoAplicacaoPagamento:Acede à aplicação de pagamento`,
            tipo: 'booleano-opcional',
          },
          {
            caminho: 'compraOriginal.pagamento.reembolsoOriginalRecusado',
            rotulo: $localize`:@@campo.compraOriginal.pagamento.reembolsoOriginalRecusado:Reembolso ao meio original recusado`,
            tipo: 'booleano',
          },
        ],
      },
      {
        id: 'online',
        titulo: $localize`:@@grupo.online:Compra online`,
        dados: ['CH-002'],
        campos: [
          {
            caminho: 'compraOriginal.encomendaEncontrada',
            rotulo: $localize`:@@campo.compraOriginal.encomendaEncontrada:Encomenda encontrada`,
            tipo: 'booleano-opcional',
          },
          {
            caminho: 'portalOnlineDisponivel',
            rotulo: $localize`:@@campo.portalOnlineDisponivel:Portal de devoluções disponível`,
            tipo: 'booleano-opcional',
          },
          {
            caminho: 'politicaPermiteAsCegasOnline',
            rotulo: $localize`:@@campo.politicaPermiteAsCegasOnline:A política permite a devolução às cegas`,
            tipo: 'booleano-opcional',
          },
        ],
      },
    ],
  },
  {
    id: 'comprovativo',
    titulo: $localize`:@@passo.comprovativo:Comprovativo`,
    grupos: [
      {
        id: 'comprovativo',
        titulo: $localize`:@@grupo.comprovativo:Comprovativo de compra (vazio se não houver)`,
        dados: ['IN-004'],
        opcional: 'comprovativo',
        campos: [
          {
            caminho: 'comprovativo.tipo',
            rotulo: $localize`:@@campo.comprovativo.tipo:Tipo de comprovativo`,
            tipo: 'opcoes',
            opcoes: TIPO_COMPROVATIVO,
          },
          {
            caminho: 'comprovativo.confirmaCompra',
            rotulo: $localize`:@@campo.comprovativo.confirmaCompra:Confirma a compra`,
            tipo: 'booleano',
          },
          {
            caminho: 'comprovativo.reciboOriginal',
            rotulo: $localize`:@@campo.comprovativo.reciboOriginal:Recibo original`,
            tipo: 'booleano',
          },
          {
            caminho: 'comprovativo.clienteMantemRecibo',
            rotulo: $localize`:@@campo.comprovativo.clienteMantemRecibo:O cliente fica com o recibo`,
            tipo: 'booleano',
          },
          {
            caminho: 'comprovativo.incluiOutrosArtigos',
            rotulo: $localize`:@@campo.comprovativo.incluiOutrosArtigos:Inclui outros artigos`,
            tipo: 'booleano',
          },
        ],
      },
    ],
  },
  {
    id: 'artigos',
    titulo: $localize`:@@passo.artigos:Artigos`,
    grupos: [
      {
        id: 'artigos',
        titulo: $localize`:@@grupo.artigos:Artigos devolvidos`,
        dados: ['IN-007', 'IN-008', 'IN-010'],
        repeticao: {
          caminho: 'artigos',
          rotuloItem: $localize`:@@grupo.artigos.item:Artigo`,
          adicionar: $localize`:@@grupo.artigos.adicionar:Adicionar artigo`,
          minimo: 1,
        },
        campos: [
          {
            caminho: 'id',
            rotulo: $localize`:@@campo.artigos.id:Identificação do artigo`,
            tipo: 'texto',
            obrigatorio: true,
          },
          ...camposProduto(),
          {
            caminho: 'quantidade',
            rotulo: $localize`:@@campo.artigos.quantidade:Quantidade`,
            tipo: 'inteiro',
          },
          {
            caminho: 'precoPago',
            rotulo: $localize`:@@campo.artigos.precoPago:Preço pago`,
            tipo: 'decimal',
          },
          {
            caminho: 'valorCalculadoPos',
            rotulo: $localize`:@@campo.artigos.valorCalculadoPos:Valor calculado pelo POS`,
            tipo: 'decimal',
          },
          {
            caminho: 'entreCanais',
            rotulo: $localize`:@@campo.artigos.entreCanais:Devolução entre canais`,
            tipo: 'booleano',
          },
          {
            caminho: 'estado.condicaoUso',
            rotulo: $localize`:@@campo.estado.condicaoUso:Condição de uso`,
            tipo: 'opcoes',
            opcoes: CONDICAO_USO,
          },
          {
            caminho: 'estado.etiquetas',
            rotulo: $localize`:@@campo.estado.etiquetas:Etiquetas`,
            tipo: 'opcoes',
            opcoes: ESTADO_ETIQUETAS,
          },
          {
            caminho: 'estado.personalizado',
            rotulo: $localize`:@@campo.estado.personalizado:Personalizado`,
            tipo: 'booleano',
          },
          {
            caminho: 'estado.alterado',
            rotulo: $localize`:@@campo.estado.alterado:Alterado`,
            tipo: 'booleano',
          },
          {
            caminho: 'estado.embainhado',
            rotulo: $localize`:@@campo.estado.embainhado:Embainhado`,
            tipo: 'booleano',
          },
          {
            caminho: 'estado.defeitoFabricoConfirmado',
            rotulo: $localize`:@@campo.estado.defeitoFabricoConfirmado:Defeito de fabrico confirmado`,
            tipo: 'booleano',
          },
          {
            caminho: 'estado.danificado',
            rotulo: $localize`:@@campo.estado.danificado:Danificado`,
            tipo: 'booleano',
          },
          {
            caminho: 'estado.sujoOuInseguro',
            rotulo: $localize`:@@campo.estado.sujoOuInseguro:Sujo ou inseguro (risco biológico)`,
            tipo: 'booleano',
          },
          {
            caminho: 'estado.embalagemIntacta',
            rotulo: $localize`:@@campo.estado.embalagemIntacta:Embalagem intacta`,
            tipo: 'booleano',
          },
          {
            caminho: 'estado.conjuntoCompleto',
            rotulo: $localize`:@@campo.estado.conjuntoCompleto:Conjunto completo`,
            tipo: 'booleano-opcional',
          },
          {
            caminho: 'estado.etiquetaPrecoCorreta',
            rotulo: $localize`:@@campo.estado.etiquetaPrecoCorreta:Etiqueta de preço correta`,
            tipo: 'booleano-opcional',
          },
          {
            caminho: 'estado.rfidCorreto',
            rotulo: $localize`:@@campo.estado.rfidCorreto:RFID correto`,
            tipo: 'booleano-opcional',
          },
          {
            caminho: 'estado.grauUso',
            rotulo: $localize`:@@campo.estado.grauUso:Grau de uso`,
            tipo: 'escala',
            opcoes: GRAU_USO,
          },
          {
            caminho: 'estado.alegaDefeito',
            rotulo: $localize`:@@campo.estado.alegaDefeito:O cliente alega defeito`,
            tipo: 'booleano',
          },
          ...perguntasDeInspecao(),
          {
            caminho: 'revendivel',
            rotulo: $localize`:@@campo.artigos.revendivel:Pode ser revendido`,
            tipo: 'booleano-opcional',
          },
        ],
      },
      {
        id: 'artigosTroca',
        titulo: $localize`:@@grupo.artigosTroca:Artigos que o cliente leva (troca)`,
        dados: ['IN-005'],
        repeticao: {
          caminho: 'artigosTroca',
          rotuloItem: $localize`:@@grupo.artigosTroca.item:Artigo de troca`,
          adicionar: $localize`:@@grupo.artigosTroca.adicionar:Adicionar artigo de troca`,
          minimo: 0,
        },
        campos: [
          ...camposProduto(),
          {
            caminho: 'precoVenda',
            rotulo: $localize`:@@campo.artigosTroca.precoVenda:Preço de venda`,
            tipo: 'decimal',
          },
          {
            caminho: 'apenasMudaTamanho',
            rotulo: $localize`:@@campo.artigosTroca.apenasMudaTamanho:Só muda de tamanho`,
            tipo: 'booleano',
          },
        ],
      },
    ],
  },
  {
    id: 'cliente',
    titulo: $localize`:@@passo.cliente:Cliente e exceções`,
    grupos: [
      {
        id: 'cliente',
        titulo: $localize`:@@grupo.cliente:Cliente`,
        dados: ['EX-002'],
        campos: [
          {
            caminho: 'cliente.id',
            rotulo: $localize`:@@campo.cliente.id:Identificação do cliente`,
            tipo: 'texto',
          },
          {
            caminho: 'cliente.forneceDados',
            rotulo: $localize`:@@campo.cliente.forneceDados:Fornece os seus dados`,
            tipo: 'booleano-opcional',
          },
          {
            caminho: 'cliente.contestaResultado',
            rotulo: $localize`:@@campo.cliente.contestaResultado:Contesta o resultado`,
            tipo: 'booleano',
          },
          {
            caminho: 'cliente.agitado',
            rotulo: $localize`:@@campo.cliente.agitado:Está agitado`,
            tipo: 'booleano',
          },
          {
            caminho: 'cliente.barreiraLinguistica',
            rotulo: $localize`:@@campo.cliente.barreiraLinguistica:Barreira linguística`,
            tipo: 'booleano',
          },
          {
            caminho: 'cliente.explicaOrigemCompra',
            rotulo: $localize`:@@campo.cliente.explicaOrigemCompra:Explica onde e quando comprou`,
            tipo: 'opcoes',
            opcoes: RESPOSTA,
          },
          {
            caminho: 'cliente.pedeNumerario',
            rotulo: $localize`:@@campo.cliente.pedeNumerario:Pede o reembolso em numerário`,
            tipo: 'booleano',
          },
        ],
      },
      {
        id: 'excecao',
        titulo: $localize`:@@grupo.excecao:Pedido de exceção (vazio se não houver)`,
        dados: ['EX-001'],
        opcional: 'pedidoExcecao',
        campos: [
          {
            caminho: 'pedidoExcecao.motivo',
            rotulo: $localize`:@@campo.pedidoExcecao.motivo:Motivo`,
            tipo: 'texto-longo',
          },
          {
            caminho: 'pedidoExcecao.resolucaoPedida',
            rotulo: $localize`:@@campo.pedidoExcecao.resolucaoPedida:Resolução pedida`,
            tipo: 'opcoes',
            opcoes: TIPO_TRANSACAO,
          },
          {
            caminho: 'pedidoExcecao.exigeMeioProibido',
            rotulo: $localize`:@@campo.pedidoExcecao.exigeMeioProibido:Exige um meio de reembolso proibido`,
            tipo: 'booleano',
          },
          {
            caminho: 'pedidoExcecao.exigeSkuIncorreto',
            rotulo: $localize`:@@campo.pedidoExcecao.exigeSkuIncorreto:Exige um SKU incorreto`,
            tipo: 'booleano',
          },
          {
            caminho: 'pedidoExcecao.envolveProdutoExcluido',
            rotulo: $localize`:@@campo.pedidoExcecao.envolveProdutoExcluido:Envolve um produto excluído`,
            tipo: 'booleano',
          },
          {
            caminho: 'pedidoExcecao.contornaProcessoObrigatorio',
            rotulo: $localize`:@@campo.pedidoExcecao.contornaProcessoObrigatorio:Contorna um processo obrigatório`,
            tipo: 'booleano',
          },
          {
            caminho: 'pedidoExcecao.concluivelNoSistema',
            rotulo: $localize`:@@campo.pedidoExcecao.concluivelNoSistema:Pode ser concluída no sistema`,
            tipo: 'booleano-opcional',
          },
          {
            caminho: 'pedidoExcecao.preocupacaoCliente',
            rotulo: $localize`:@@campo.pedidoExcecao.preocupacaoCliente:Preocupação do cliente`,
            tipo: 'texto-longo',
          },
          {
            caminho: 'pedidoExcecao.aprovada',
            rotulo: $localize`:@@campo.pedidoExcecao.aprovada:Aprovada pela gestão`,
            tipo: 'booleano-opcional',
          },
        ],
      },
      {
        id: 'aprovador',
        titulo: $localize`:@@grupo.aprovador:Quem aprovou ou recusou a exceção`,
        dados: ['EX-001'],
        opcional: 'pedidoExcecao.aprovador',
        visivelSe: 'pedidoExcecao',
        campos: [
          {
            caminho: 'pedidoExcecao.aprovador.id',
            rotulo: $localize`:@@campo.aprovador.id:Identificação`,
            tipo: 'texto',
          },
          {
            caminho: 'pedidoExcecao.aprovador.nome',
            rotulo: $localize`:@@campo.aprovador.nome:Nome`,
            tipo: 'texto',
          },
          {
            caminho: 'pedidoExcecao.aprovador.funcao',
            rotulo: $localize`:@@campo.aprovador.funcao:Função`,
            tipo: 'opcoes',
            opcoes: FUNCAO,
          },
          {
            caminho: 'pedidoExcecao.aprovador.aprovadoPeloDM',
            rotulo: $localize`:@@campo.aprovador.aprovadoPeloDM:Aprovado pelo District Manager`,
            tipo: 'booleano',
          },
          {
            caminho: 'pedidoExcecao.aprovador.idCredencialPOS',
            rotulo: $localize`:@@campo.aprovador.idCredencialPOS:Credencial de POS`,
            tipo: 'texto',
          },
        ],
      },
      {
        id: 'fraude',
        titulo: $localize`:@@grupo.fraude:Indícios de fraude`,
        dados: ['EX-008'],
        repeticao: {
          caminho: 'indicadoresFraude',
          rotuloItem: $localize`:@@grupo.fraude.item:Indício`,
          adicionar: $localize`:@@grupo.fraude.adicionar:Registar indício`,
          minimo: 0,
        },
        campos: [
          {
            caminho: 'descricao',
            rotulo: $localize`:@@campo.indicadoresFraude.descricao:Descrição`,
            tipo: 'texto',
            obrigatorio: true,
          },
          {
            caminho: 'nivelRisco',
            rotulo: $localize`:@@campo.indicadoresFraude.nivelRisco:Nível de risco`,
            tipo: 'opcoes',
            opcoes: NIVEL_RISCO,
            obrigatorio: true,
          },
        ],
      },
    ],
  },
];

export const GRUPOS: readonly Grupo[] = PASSOS.flatMap((p) => p.grupos);

/** Caminho completo de um campo (com o índice do item, nos grupos repetíveis). */
export function caminhoCompleto(grupo: Grupo, campo: Campo, indice?: number): string {
  return grupo.repeticao
    ? `${grupo.repeticao.caminho}[${indice ?? 0}].${campo.caminho}`
    : campo.caminho;
}
