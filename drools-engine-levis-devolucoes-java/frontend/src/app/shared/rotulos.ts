/**
 * Rótulos dos valores dos enums da API, traduzíveis (i18n). As chaves são os valores enviados e
 * recebidos pela API; os ecrãs mostram sempre o rótulo.
 */

export type Rotulos = Readonly<Record<string, string>>;

export const TIPO_PEDIDO: Rotulos = {
  DEVOLUCAO: $localize`:@@enum.TipoPedido.DEVOLUCAO:Devolução`,
  TROCA: $localize`:@@enum.TipoPedido.TROCA:Troca`,
  AJUSTE_PRECO: $localize`:@@enum.TipoPedido.AJUSTE_PRECO:Ajuste de preço`,
  DEVOLUCAO_OFERTA: $localize`:@@enum.TipoPedido.DEVOLUCAO_OFERTA:Devolução de oferta`,
};

export const MERCADO: Rotulos = {
  EUA: $localize`:@@enum.Mercado.EUA:Estados Unidos`,
  CANADA: $localize`:@@enum.Mercado.CANADA:Canadá`,
};

export const TIPO_LOJA: Rotulos = {
  MAINLINE: 'Mainline',
  OUTLET: 'Outlet',
};

export const CANAL_COMPRA: Rotulos = {
  MAINLINE: $localize`:@@enum.CanalCompra.MAINLINE:Loja Mainline`,
  OUTLET: $localize`:@@enum.CanalCompra.OUTLET:Loja Outlet`,
  LEVI_COM: 'levi.com',
  LEVI_CA: 'levi.ca',
  BACKPOCKET: 'BackPocket',
  FRANQUIA_CANADA: $localize`:@@enum.CanalCompra.FRANQUIA_CANADA:Franquia (Canadá)`,
  GROSSISTA: $localize`:@@enum.CanalCompra.GROSSISTA:Grossista`,
  DESCONHECIDO: $localize`:@@enum.CanalCompra.DESCONHECIDO:Desconhecido`,
};

export const MEIO_PAGAMENTO: Rotulos = {
  CREDITO: $localize`:@@enum.MeioPagamento.CREDITO:Cartão de crédito`,
  DEBITO: $localize`:@@enum.MeioPagamento.DEBITO:Cartão de débito`,
  APPLE_PAY: 'Apple Pay',
  GOOGLE_PAY: 'Google Pay',
  PAYPAL: 'PayPal',
  VENMO: 'Venmo',
  AFTERPAY: 'Afterpay',
  INTERAC: 'Interac',
  NUMERARIO: $localize`:@@enum.MeioPagamento.NUMERARIO:Numerário`,
  CARTAO_OFERTA: $localize`:@@enum.MeioPagamento.CARTAO_OFERTA:Cartão de oferta`,
};

export const ESTADO_CONTA: Rotulos = {
  ATIVA: $localize`:@@enum.EstadoConta.ATIVA:Ativa`,
  ATIVA_CARTAO_PERDIDO: $localize`:@@enum.EstadoConta.ATIVA_CARTAO_PERDIDO:Ativa, cartão perdido`,
  ENCERRADA: $localize`:@@enum.EstadoConta.ENCERRADA:Encerrada`,
};

export const TIPO_COMPROVATIVO: Rotulos = {
  RECIBO_IMPRESSO: $localize`:@@enum.TipoComprovativo.RECIBO_IMPRESSO:Recibo impresso`,
  RECIBO_DIGITAL: $localize`:@@enum.TipoComprovativo.RECIBO_DIGITAL:Recibo digital`,
  CONFIRMACAO_ENCOMENDA: $localize`:@@enum.TipoComprovativo.CONFIRMACAO_ENCOMENDA:Confirmação de encomenda`,
  RECIBO_OFERTA: $localize`:@@enum.TipoComprovativo.RECIBO_OFERTA:Recibo de oferta`,
  CONSULTA_TRANSACAO: $localize`:@@enum.TipoComprovativo.CONSULTA_TRANSACAO:Consulta da transação no POS`,
  FOTOGRAFIA_RECIBO: $localize`:@@enum.TipoComprovativo.FOTOGRAFIA_RECIBO:Fotografia do recibo`,
  CONSULTA_BACKPOCKET: $localize`:@@enum.TipoComprovativo.CONSULTA_BACKPOCKET:Consulta na BackPocket`,
};

export const MARCA: Rotulos = {
  LEVIS: "Levi's",
  DOCKERS: 'Dockers',
  LS_SIGNATURE: 'Levi Strauss Signature',
  BEYOND_YOGA: 'Beyond Yoga',
  OUTRA: $localize`:@@enum.Marca.OUTRA:Outra`,
};

export const CATEGORIA_PRODUTO: Rotulos = {
  VESTUARIO: $localize`:@@enum.CategoriaProduto.VESTUARIO:Vestuário`,
  ACESSORIO: $localize`:@@enum.CategoriaProduto.ACESSORIO:Acessório`,
  BODYWEAR: 'Bodywear',
};

export const CONDICAO_USO: Rotulos = {
  NAO_USADO: $localize`:@@enum.CondicaoUso.NAO_USADO:Não usado`,
  USADO: $localize`:@@enum.CondicaoUso.USADO:Usado`,
  LAVADO: $localize`:@@enum.CondicaoUso.LAVADO:Lavado`,
};

export const ESTADO_ETIQUETAS: Rotulos = {
  COLOCADAS: $localize`:@@enum.EstadoEtiquetas.COLOCADAS:Colocadas`,
  SOLTAS: $localize`:@@enum.EstadoEtiquetas.SOLTAS:Soltas`,
  AUSENTES: $localize`:@@enum.EstadoEtiquetas.AUSENTES:Ausentes`,
};

export const TIPO_TRANSACAO: Rotulos = {
  REEMBOLSO: $localize`:@@enum.TipoTransacao.REEMBOLSO:Reembolso`,
  TROCA: $localize`:@@enum.TipoTransacao.TROCA:Troca`,
  TROCA_MESMO_ARTIGO: $localize`:@@enum.TipoTransacao.TROCA_MESMO_ARTIGO:Troca pelo mesmo artigo`,
  CREDITO_LOJA: $localize`:@@enum.TipoTransacao.CREDITO_LOJA:Crédito de loja`,
  AJUSTE_PRECO: $localize`:@@enum.TipoTransacao.AJUSTE_PRECO:Ajuste de preço`,
  NENHUMA: $localize`:@@enum.TipoTransacao.NENHUMA:Nenhuma`,
};

export const NIVEL_RISCO: Rotulos = {
  BAIXO: $localize`:@@enum.NivelRisco.BAIXO:Baixo`,
  SIGNIFICATIVO: $localize`:@@enum.NivelRisco.SIGNIFICATIVO:Significativo`,
  CONFIRMADO: $localize`:@@enum.NivelRisco.CONFIRMADO:Confirmado`,
};

export const FUNCAO: Rotulos = {
  STYLIST: 'Stylist',
  ELEVATED_STYLIST: 'Elevated Stylist',
  LEAD_CASHIER: 'Lead Cashier',
  KEY_HOLDER: 'Key Holder',
  GESTAO_LOJA: $localize`:@@enum.Funcao.GESTAO_LOJA:Gestão da Loja`,
  XSTORE_MANAGER: 'Xstore Manager',
};

export const ELEGIBILIDADE: Rotulos = {
  PERMITIR: $localize`:@@enum.Elegibilidade.PERMITIR:Permitir`,
  REVER: $localize`:@@enum.Elegibilidade.REVER:Rever`,
  ENCAMINHAR: $localize`:@@enum.Elegibilidade.ENCAMINHAR:Encaminhar`,
  RECUSAR: $localize`:@@enum.Elegibilidade.RECUSAR:Recusar`,
};

export const TIPO_VERIFICACAO: Rotulos = {
  NAO_DETERMINADA: $localize`:@@enum.TipoVerificacao.NAO_DETERMINADA:Não determinada`,
  VERIFICADA: $localize`:@@enum.TipoVerificacao.VERIFICADA:Verificada`,
  AS_CEGAS: $localize`:@@enum.TipoVerificacao.AS_CEGAS:Às cegas`,
};

export const BASE_VALOR: Rotulos = {
  VALOR_PAGO: $localize`:@@enum.BaseValor.VALOR_PAGO:Valor pago`,
  PRECO_ATUAL: $localize`:@@enum.BaseValor.PRECO_ATUAL:Preço atual`,
  VALOR_PROMOCIONAL: $localize`:@@enum.BaseValor.VALOR_PROMOCIONAL:Valor promocional`,
  VALOR_ESCALAO: $localize`:@@enum.BaseValor.VALOR_ESCALAO:Valor do escalão`,
  VALOR_POS: $localize`:@@enum.BaseValor.VALOR_POS:Valor calculado pelo POS`,
  PVP_ORIGINAL: $localize`:@@enum.BaseValor.PVP_ORIGINAL:PVP original`,
};

export const MEIO_REEMBOLSO: Rotulos = {
  MEIO_ORIGINAL: $localize`:@@enum.MeioReembolso.MEIO_ORIGINAL:Meio de pagamento original`,
  CARTAO_OFERTA: $localize`:@@enum.MeioReembolso.CARTAO_OFERTA:Cartão de oferta`,
  CARTAO_OFERTA_ELETRONICO: $localize`:@@enum.MeioReembolso.CARTAO_OFERTA_ELETRONICO:Cartão de oferta eletrónico`,
  MEIO_ALTERNATIVO: $localize`:@@enum.MeioReembolso.MEIO_ALTERNATIVO:Meio alternativo`,
  APLICACAO_PAGAMENTO: $localize`:@@enum.MeioReembolso.APLICACAO_PAGAMENTO:Aplicação de pagamento`,
  CREDITO_LOJA: $localize`:@@enum.MeioReembolso.CREDITO_LOJA:Crédito de loja`,
};

export const NIVEL_APROVACAO: Rotulos = {
  NENHUMA: $localize`:@@enum.NivelAprovacao.NENHUMA:Nenhuma`,
  XSTORE_MANAGER: 'Xstore Manager',
  RESPONSAVEL_SENIOR: $localize`:@@enum.NivelAprovacao.RESPONSAVEL_SENIOR:Responsável sénior`,
  DISTRICT_AREA: $localize`:@@enum.NivelAprovacao.DISTRICT_AREA:District ou Area Manager`,
};

export const PROCESSO_OBRIGATORIO: Rotulos = {
  POS: 'POS',
  BACKPOCKET: 'BackPocket',
  AFTERPAY: 'Afterpay',
  PAYPAL_VENMO: 'PayPal / Venmo',
  VERIFONE_INTERAC: 'VeriFone / Interac',
  FRANQUIA_CANADA: $localize`:@@enum.ProcessoObrigatorio.FRANQUIA_CANADA:Franquia (Canadá)`,
  DANO: $localize`:@@enum.ProcessoObrigatorio.DANO:Processo de dano`,
  RISCO_BIOLOGICO: $localize`:@@enum.ProcessoObrigatorio.RISCO_BIOLOGICO:Risco biológico`,
};

export const DESTINO_PRODUTO: Rotulos = {
  AREA_VENDAS: $localize`:@@enum.DestinoProduto.AREA_VENDAS:Área de vendas`,
  SALDOS: $localize`:@@enum.DestinoProduto.SALDOS:Saldos`,
  REETIQUETAR: $localize`:@@enum.DestinoProduto.REETIQUETAR:Reetiquetar`,
  BAIXA_DANO: $localize`:@@enum.DestinoProduto.BAIXA_DANO:Baixa por dano`,
  RISCO_BIOLOGICO: $localize`:@@enum.DestinoProduto.RISCO_BIOLOGICO:Risco biológico`,
  DEVOLUCAO_CLIENTE: $localize`:@@enum.DestinoProduto.DEVOLUCAO_CLIENTE:Devolver ao cliente`,
};

export const CAUSA_NAO_DISPARO: Rotulos = {
  DISPAROU: $localize`:@@enum.CausaNaoDisparo.DISPAROU:Disparou`,
  MODULO_NAO_ALCANCADO: $localize`:@@enum.CausaNaoDisparo.MODULO_NAO_ALCANCADO:O módulo não foi alcançado`,
  CANCELADA_POR_PRECEDENCIA: $localize`:@@enum.CausaNaoDisparo.CANCELADA_POR_PRECEDENCIA:Cancelada por uma regra com precedência`,
  CONDICOES_FALHADAS: $localize`:@@enum.CausaNaoDisparo.CONDICOES_FALHADAS:As condições não se verificaram`,
};

/** Rótulo do valor, ou o próprio valor se não houver rótulo; "—" se vazio. */
export function rotulo(rotulos: Rotulos, valor: string | null | undefined): string {
  if (valor === null || valor === undefined || valor === '') {
    return '—';
  }
  return rotulos[valor] ?? valor;
}

/** Nome de uma regra sem o ID no início (os nomes das regras começam pelo ID, ex.: "PT-003 ..."). */
export function semCodigo(
  nome: string | null | undefined,
  codigo: string | null | undefined,
): string {
  if (!nome) {
    return '';
  }
  return codigo && nome.startsWith(codigo) ? nome.slice(codigo.length).trim() : nome;
}

// Camada de incerteza (docs/08)

/** Grau de uso observado pelo colaborador, de 0 a 4 (docs/08 §4.1). */
export const GRAU_USO: Rotulos = {
  '0': $localize`:@@enum.GrauUso.0:Nenhum`,
  '1': $localize`:@@enum.GrauUso.1:Ligeiro`,
  '2': $localize`:@@enum.GrauUso.2:Moderado`,
  '3': $localize`:@@enum.GrauUso.3:Evidente`,
  '4': $localize`:@@enum.GrauUso.4:Intenso`,
};

export const RESPOSTA: Rotulos = {
  SIM: $localize`:@@enum.Resposta.SIM:Sim`,
  NAO: $localize`:@@enum.Resposta.NAO:Não`,
  NAO_SEI: $localize`:@@enum.Resposta.NAO_SEI:Não sei`,
};

export const HIPOTESE: Rotulos = {
  FRAUDE: $localize`:@@enum.Hipotese.FRAUDE:Risco de fraude`,
  DEFEITO_FABRICO: $localize`:@@enum.Hipotese.DEFEITO_FABRICO:Defeito de fabrico`,
  REVENDIBILIDADE: $localize`:@@enum.Hipotese.REVENDIBILIDADE:Revendibilidade`,
  RECOMENDACAO_CREDITO: $localize`:@@enum.Hipotese.RECOMENDACAO_CREDITO:Recomendação de crédito de loja`,
};

export const METODO_INCERTEZA: Rotulos = {
  FATOR_CERTEZA: $localize`:@@enum.MetodoIncerteza.FATOR_CERTEZA:Fator de certeza`,
  BAYES: $localize`:@@enum.MetodoIncerteza.BAYES:Probabilidade bayesiana`,
  FUZZY: $localize`:@@enum.MetodoIncerteza.FUZZY:Lógica fuzzy`,
};

export const CLASSIFICACAO_INCERTEZA: Rotulos = {
  RISCO_ALTO: $localize`:@@enum.ClassificacaoIncerteza.RISCO_ALTO:Risco alto`,
  RISCO_MEDIO: $localize`:@@enum.ClassificacaoIncerteza.RISCO_MEDIO:Risco médio`,
  RISCO_BAIXO: $localize`:@@enum.ClassificacaoIncerteza.RISCO_BAIXO:Risco baixo`,
  PROPOR_PC006: $localize`:@@enum.ClassificacaoIncerteza.PROPOR_PC006:Propor PC-006 (defeito provável)`,
  REVER_DEFEITO: $localize`:@@enum.ClassificacaoIncerteza.REVER_DEFEITO:Inspeção adicional`,
  DESGASTE: $localize`:@@enum.ClassificacaoIncerteza.DESGASTE:Desgaste`,
  REVENDIVEL: $localize`:@@enum.ClassificacaoIncerteza.REVENDIVEL:Revendível`,
  REVENDIBILIDADE_INDETERMINADA: $localize`:@@enum.ClassificacaoIncerteza.REVENDIBILIDADE_INDETERMINADA:Indeterminada`,
  NAO_REVENDIVEL: $localize`:@@enum.ClassificacaoIncerteza.NAO_REVENDIVEL:Não revendível`,
  CREDITO_RECOMENDADO: $localize`:@@enum.ClassificacaoIncerteza.CREDITO_RECOMENDADO:Crédito recomendado`,
  CREDITO_A_CRITERIO: $localize`:@@enum.ClassificacaoIncerteza.CREDITO_A_CRITERIO:Crédito a critério da gestão`,
  CREDITO_NAO_RECOMENDADO: $localize`:@@enum.ClassificacaoIncerteza.CREDITO_NAO_RECOMENDADO:Crédito não recomendado`,
};
