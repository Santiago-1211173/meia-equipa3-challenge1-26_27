import type { Elegibilidade, DocumentacaoResponse } from "@/types/returns";

type Tone = "approved" | "rejected" | "info";

export const ELIGIBILITY: Record<Elegibilidade, { label: string; tone: Tone; hint: string }> = {
  PERMITIR: { label: "Permitido", tone: "approved", hint: "O pedido cumpre a política." },
  RECUSAR: { label: "Recusado", tone: "rejected", hint: "O pedido não cumpre a política." },
  REVER: { label: "Requer revisão", tone: "info", hint: "Precisa de aprovação antes de avançar." },
  ENCAMINHAR: { label: "Encaminhar", tone: "info", hint: "Deve seguir por outro canal." },
};

const LABELS: Record<string, string> = {
  // tipo de pedido / transação
  DEVOLUCAO: "Devolução",
  TROCA: "Troca",
  AJUSTE_PRECO: "Ajuste de preço",
  DEVOLUCAO_OFERTA: "Devolução de oferta",
  REEMBOLSO: "Reembolso",
  TROCA_MESMO_ARTIGO: "Troca pelo mesmo artigo",
  CREDITO_LOJA: "Crédito de loja",
  NENHUMA: "Nenhuma",
  // verificação
  VERIFICADA: "Compra verificada",
  AS_CEGAS: "Sem comprovativo (às cegas)",
  NAO_DETERMINADA: "Não determinada",
  // reembolso / tender
  MEIO_ORIGINAL: "Meio de pagamento original",
  CARTAO_OFERTA: "Cartão-oferta",
  CARTAO_OFERTA_ELETRONICO: "Cartão-oferta eletrónico",
  MEIO_ALTERNATIVO: "Meio alternativo",
  APLICACAO_PAGAMENTO: "Aplicação de pagamento",
  // aprovação
  XSTORE_MANAGER: "Gestor de loja",
  RESPONSAVEL_SENIOR: "Responsável sénior",
  DISTRICT_AREA: "Gestão de área",
  // destino do artigo
  AREA_VENDAS: "Voltar à área de vendas",
  SALDOS: "Enviar para saldos",
  REETIQUETAR: "Reetiquetar",
  BAIXA_DANO: "Dar baixa (dano)",
  RISCO_BIOLOGICO: "Risco biológico",
  DEVOLUCAO_CLIENTE: "Devolver ao cliente",
  // base de valor
  VALOR_PAGO: "Valor pago",
  PRECO_ATUAL: "Preço atual",
  VALOR_PROMOCIONAL: "Valor promocional",
  VALOR_ESCALAO: "Valor por escalão",
  VALOR_POS: "Valor no ponto de venda",
  PVP_ORIGINAL: "Preço original",
  // processo
  POS: "Ponto de venda",
  BACKPOCKET: "Sistema de apoio (BackPocket)",
  APLICACAO_BACKPOCKET: "Sistema de apoio (BackPocket)",
  AFTERPAY: "Afterpay",
  AFTERPAY_APP: "Afterpay",
  PAYPAL_VENMO: "PayPal / Venmo",
  FLUXO_APP: "Aplicação móvel (PayPal / Venmo)",
  VERIFONE_INTERAC: "Terminal Verifone / Interac",
  INTERAC_VERIFONE: "Terminal Verifone / Interac",
  FRANQUIA_CANADA: "Franquia (Canadá)",
  PROCESSO_GROSSISTA: "Processo grossista",
  DANO: "Processo de dano",

  // comprovativo e canal
  RECIBO_IMPRESSO: "Recibo impresso",
  RECIBO_DIGITAL: "Recibo digital",
  CONFIRMACAO_ENCOMENDA: "Confirmação de encomenda",
  RECIBO_OFERTA: "Recibo de oferta",
  CONSULTA_TRANSACAO: "Consulta da transação",
  FOTOGRAFIA_RECIBO: "Fotografia do recibo",
  CONSULTA_BACKPOCKET: "Consulta no sistema de apoio",
  MAINLINE: "Loja principal",
  OUTLET: "Outlet",
  SITE_PROPRIO: "Site da marca",
  SITE_PROPRIO_CA: "Site da marca (Canadá)",
  LEVI_COM: "Site da marca",
  LEVI_CA: "Site da marca (Canadá)",
  GROSSISTA: "Grossista",
  DESCONHECIDO: "Desconhecido",
  // artigo
  NAO_USADO: "Não usado",
  USADO: "Usado",
  LAVADO: "Lavado",
  COLOCADAS: "Colocadas",
  SOLTAS: "Soltas",
  AUSENTES: "Ausentes",
  // colaborador
  STYLIST: "Stylist",
  ELEVATED_STYLIST: "Stylist sénior",
  LEAD_CASHIER: "Responsável de caixa",
  KEY_HOLDER: "Responsável de turno",
  GESTAO_LOJA: "Gestão da loja",
  // pagamento
  CREDITO: "Cartão de crédito",
  DEBITO: "Cartão de débito",
  CARTAO: "Cartão bancário",
  CARTAO_BANCARIO: "Cartão bancário",
  NUMERARIO: "Numerário",
  APPLE_PAY: "Apple Pay",
  GOOGLE_PAY: "Google Pay",
  PAYPAL: "PayPal",
  VENMO: "Venmo",
  INTERAC: "Interac Débito",
  // Conclusões do motor ACM
  "OUT-001:PERMITIR": "Permitir Devolução",
  "OUT-001:RECUSAR": "Recusar Devolução",
  "OUT-001:REVER": "Requer Revisão por Chefia",
  "OUT-001:ENCAMINHAR": "Encaminhar Pedido",
};

/** Rótulo em português para um valor de enum; valores desconhecidos ficam legíveis. */
export function label(value: unknown): string {
  if (value === null || value === undefined || value === "") return "—";
  const text = String(value);
  if (LABELS[text]) return LABELS[text];
  const upper = text.toUpperCase();
  if (LABELS[upper]) return LABELS[upper];
  return /^[A-Z0-9_]+$/.test(text)
    ? text.charAt(0) + text.slice(1).toLowerCase().replace(/_/g, " ")
    : text;
}

export function money(value: unknown): string {
  if (value === null || value === undefined || value === "") return "—";
  const amount = Number(value);
  return Number.isFinite(amount)
    ? new Intl.NumberFormat("pt-PT", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(amount)
    : String(value);
}

const CAUSES: Record<string, string> = {
  DISPAROU: "A regra disparou",
  MODULO_NAO_ALCANCADO: "O raciocínio não chegou a este passo",
  CANCELADA_POR_PRECEDENCIA: "Outra regra com prioridade impediu-a",
  CONDICOES_FALHADAS: "Condições não satisfeitas",
};

export const cause = (value: unknown) => (typeof value === "string" ? (CAUSES[value] ?? label(value)) : "—");

/** Simulações "e se?" de um clique. Os caminhos seguem a estrutura canónica do pedido. */
export const WHAT_IF_PRESETS: { label: string; changes: Record<string, unknown> }[] = [
  { label: "As etiquetas estivessem colocadas", changes: { "artigos[0].estado.etiquetas": "COLOCADAS" } },
  { label: "O portal online estivesse disponível", changes: { portalOnlineDisponivel: true } },
  { label: "O artigo estivesse claramente usado", changes: { "artigos[0].estado.condicaoUso": "USADO" } },
];

/** Remove códigos de regra internos (ex: PT-003, IN-005, CT-001, OUT-001, etc.) e termos técnicos de marca */
export function cleanRuleCodes(text?: string | null): string {
  if (!text) return "";
  let cleaned = text
    // 1. Remove padrões com igualdade: "OUT-001=PERMITIR" ou "OUT-002"
    .replace(/\b[A-Z]{2,4}-\d{3,4}(?:-[A-Z0-9]+)?=[A-Z_]+\b/g, "")
    // 2. Remove códigos com separador: "PT-003: ", "PT-003 - ", "PT-003 "
    .replace(/\b[A-Z]{2,4}-\d{3,4}(?:-[A-Z0-9]+)?\s*[:–—-]?\s*/g, "")
    // 3. Remove códigos isolados (incluindo sufixos alfanuméricos)
    .replace(/\b[A-Z]{2,4}-\d{3,4}(?:-[A-Z0-9]+)?\b/g, "")
    // 4. Remove menção a "Regra Marca"
    .replace(/\s*Regra Marca\s*/gi, "")
    // Normalizar espaços
    .replace(/\s{2,}/g, " ")
    .trim();

  // Limpeza de pontuação inicial e final residual
  cleaned = cleaned.replace(/^[:–—\-;,.]\s*/, "").replace(/\s*[:–—\-;,.]$/, "").trim();

  // Limpeza de preposições órfãs no final resultantes da remoção de código (ex: "fixada por")
  cleaned = cleaned.replace(/\s+(?:por|de|com|em|para|a)\s*$/i, "").trim();

  // Se o texto resultante for apenas "Regra", número + "Regra" ou vazio, manter o texto original
  const testNormalized = cleaned.toLowerCase().replace(/^\d+\s*/, "").trim();
  if (testNormalized === "regra" || cleaned.length === 0) {
    return text.trim();
  }

  return cleaned;
}

const MODULE_LABELS: Record<string, string> = {
  M0: "Procedimentos de Balcão",
  "M0-CONTEXTO": "Procedimentos de Balcão",
  M1: "Identificação do Produto",
  "M1-PRODUTO": "Identificação do Produto",
  M2: "Compatibilidade de Canais",
  "M2-CANAIS": "Compatibilidade de Canais",
  M3: "Condição Física e Etiquetas",
  "M3-ESTADO": "Condição Física e Etiquetas",
  M4: "Comprovativo de Compra",
  "M4-PRAZOS_RECIBOS": "Comprovativo de Compra",
  "M4-COMPROVATIVO": "Comprovativo de Compra",
  M5: "Janela Temporal e Prazos",
  "M5-PRAZO": "Janela Temporal e Prazos",
  M6: "Trocas e Exceções",
  "M6-EXCECOES": "Trocas e Exceções",
  "M6-TROCAS": "Trocas e Exceções",
  M7: "Liquidação e Pagamento",
  "M7-TENDER_MEIOS": "Liquidação e Pagamento",
  "M7-LIQUIDACAO": "Liquidação e Pagamento",
  M8: "Documentação Obrigatória",
  "M8-CONCLUSAO": "Documentação Obrigatória",
  "M8-DOCUMENTACAO": "Documentação Obrigatória",
  M9: "Inspeção e Encaminhamento",
  "M9-DESTINO": "Inspeção e Encaminhamento",
};

/** Devolve rótulo legível em português europeu para módulos de regras */
export function moduleLabel(code?: string | null): string {
  if (!code) return "Validação Geral";
  const upper = code.toUpperCase();
  if (MODULE_LABELS[upper]) return MODULE_LABELS[upper];
  for (const [key, val] of Object.entries(MODULE_LABELS)) {
    if (upper.startsWith(key)) return val;
  }
  return label(code);
}

/**
 * Determina a ação operacional e respetiva instrução/hint para o operador no balcão,
 * com base na elegibilidade oficial (OUT-001), nível de aprovação (OUT-005) e processo (OUT-006).
 */
export function formatOperationalAction(
  processo?: string | null,
  aprovacao?: string | null,
  elegibilidade?: Elegibilidade | null
): { action: string; hint: string } {
  const normProcesso = processo ? processo.trim().toUpperCase() : null;
  const normAprovacao = aprovacao ? aprovacao.trim().toUpperCase() : null;

  // 1. Recusa oficial
  if (elegibilidade === "RECUSAR") {
    return {
      action: "Devolver artigo ao cliente",
      hint: "Emitir comprovativo oficial de recusa no balcão",
    };
  }

  // 2. Aprovação mandatória de chefia
  if (normAprovacao && normAprovacao !== "NENHUMA") {
    return {
      action: `Solicitar autorização de ${label(normAprovacao)}`,
      hint: "PIN ou assinatura obrigatória no terminal POS",
    };
  }

  // 3. Processos operacionais obrigatórios específicos
  if (normProcesso === "BACKPOCKET" || normProcesso === "APLICACAO_BACKPOCKET") {
    return {
      action: "Processar no Sistema BackPocket",
      hint: "Aceder à aplicação dedicada de apoio à loja",
    };
  }

  if (normProcesso === "AFTERPAY" || normProcesso === "AFTERPAY_APP") {
    return {
      action: "Processar devolução Afterpay",
      hint: "Seguir fluxo específico do terminal para BNPL",
    };
  }

  if (normProcesso === "VERIFONE_INTERAC" || normProcesso === "INTERAC_VERIFONE") {
    return {
      action: "Inserir cartão no terminal Verifone",
      hint: "Exige presença de cartão físico Interac",
    };
  }

  if (normProcesso === "PAYPAL_VENMO" || normProcesso === "FLUXO_APP") {
    return {
      action: "Processar via aplicação móvel",
      hint: "Concluir estorno no fluxo digital PayPal / Venmo",
    };
  }

  if (normProcesso === "FRANQUIA_CANADA") {
    return {
      action: "Encaminhar para processo de Franquia",
      hint: "Aplicar regras de SKU e fluxo exclusivo da franquia",
    };
  }

  if (normProcesso === "PROCESSO_GROSSISTA") {
    return {
      action: "Encaminhar para canal grossista",
      hint: "Devolução não processável em loja direta",
    };
  }

  if (normProcesso === "DANO" || normProcesso === "BAIXA_DANO") {
    return {
      action: "Processar baixa por dano",
      hint: "Registar artigo no fluxo de mercadoria danificada",
    };
  }

  if (normProcesso === "RISCO_BIOLOGICO") {
    return {
      action: "Seguir protocolo de risco biológico",
      hint: "Proceder ao isolamento e descarte imediato",
    };
  }

  // 4. Elegibilidade permitida sem exceção
  if (elegibilidade === "PERMITIR") {
    return {
      action: "Concluir transação no POS Regular",
      hint: "Executar no fluxo padrão de balcão",
    };
  }

  // 5. Fallback para revisão de supervisor
  if (elegibilidade === "REVER") {
    return {
      action: "Submeter à validação de supervisor",
      hint: "Análise presencial de exceção necessária",
    };
  }

  return {
    action: "Concluir transação no POS Regular",
    hint: "Executar no fluxo padrão de balcão",
  };
}

/**
 * Formata os detalhes de documentação e controlo (OUT-008) em linguagem operacional clara,
 * extraindo dinamicamente datas de retenção, notas, registos de exceção e assinaturas.
 */
export function formatDocumentationDetails(doc?: DocumentacaoResponse | null): {
  label: string;
  subtext: string;
} {
  if (!doc) {
    return {
      label: "Arquivo digital standard no POS",
      subtext: "Sem requisitos especiais de retenção física",
    };
  }

  // Rótulo principal derivado das obrigações
  let mainLabel = "Conformidade e arquivo contabilístico";
  if (doc.reciboAgrafado) {
    mainLabel = "Agrafar recibo e recolher assinatura";
  } else if (doc.assinaturaCliente || doc.assinaturaProcessador || doc.assinaturaTestemunha) {
    mainLabel = "Recolher assinatura obrigatória no talão";
  } else if (doc.registoExcecao) {
    mainLabel = "Registo de exceção obrigatório";
  } else if (doc.retencaoAte) {
    mainLabel = `Reter documentação até ${doc.retencaoAte}`;
  }

  // Subtexto contextualizado com as informações específicas presentes
  const details: string[] = [];
  if (doc.retencaoAte) {
    details.push(`Retenção até ${doc.retencaoAte}`);
  }
  if (doc.registoExcecao) {
    details.push(`Registo: ${doc.registoExcecao}`);
  }
  if (doc.notaRecibo) {
    details.push(cleanRuleCodes(doc.notaRecibo));
  }

  const subtext =
    details.length > 0
      ? details.join(" • ")
      : doc.reciboAgrafado
      ? "Arquivo físico com talão original do cliente"
      : "Conformidade e arquivo contabilístico";

  return {
    label: mainLabel,
    subtext,
  };
}

/**
 * Produz o subtítulo pericial contextualizado para o meio de liquidação (Card 03 / OUT-004),
 * erradicando referências fictícias a tokenização quando o meio for numerário, crédito de loja, etc.
 */
export function formatTenderSubtext(
  meioReembolso?: string | null,
  tipoTransacao?: string | null,
  elegibilidade?: Elegibilidade | null,
  meioOriginal?: string | null
): string {
  if (elegibilidade === "RECUSAR") {
    return "Nenhuma liquidação financeira autorizada";
  }

  const clean = (val?: string | null) =>
    (val ?? "")
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toUpperCase();

  const mr = clean(meioReembolso);
  const tt = clean(tipoTransacao);
  const mo = clean(meioOriginal);

  // Quando o meio é o original e conhecemos a forma de pagamento de origem, contextualizar
  const effectiveTender = mr.includes("ORIGINAL") && mo ? mo : mr;

  if (
    tt.includes("CREDITO") ||
    effectiveTender.includes("OFERTA") ||
    effectiveTender.includes("CREDITO")
  ) {
    return "Emitido em cartão-oferta físico ou digital";
  }

  if (
    effectiveTender.includes("NUMERARIO") ||
    effectiveTender.includes("DINHEIRO") ||
    effectiveTender.includes("CASH")
  ) {
    return "Liquidação imediata em caixa físico";
  }

  if (
    effectiveTender.includes("ORIGINAL") ||
    effectiveTender.includes("CREDITO") ||
    effectiveTender.includes("DEBITO") ||
    effectiveTender.includes("CARTAO") ||
    effectiveTender.includes("BANCARIO")
  ) {
    return "Estorno seguro processado via adquirente";
  }

  if (
    effectiveTender.includes("APLICACAO") ||
    effectiveTender.includes("PAYPAL") ||
    effectiveTender.includes("VENMO") ||
    effectiveTender.includes("AFTERPAY") ||
    effectiveTender.includes("APPLE") ||
    effectiveTender.includes("GOOGLE")
  ) {
    return "Estorno processado na aplicação da conta de pagamento";
  }

  if (effectiveTender.includes("VERIFONE") || effectiveTender.includes("INTERAC")) {
    return "Reembolso no cartão Interac via terminal Verifone";
  }

  if (effectiveTender.includes("ALTERNATIVO")) {
    return "Liquidação através de modalidade alternativa acordada";
  }

  if (tt.includes("TROCA")) {
    return "Compensação de valor liquidada no ato da troca";
  }

  if (tt.includes("AJUSTE")) {
    return "Diferença devolvida no meio da transação original";
  }

  if (elegibilidade === "REVER") {
    return "Condicionado à aprovação presencial da chefia";
  }

  return "Liquidação em conformidade com a política oficial";
}

/**
 * Produz o subtítulo contextualizado para a modalidade da transação (Card 02 / OUT-002),
 * evitando contradições entre crédito de loja e reembolso em conta.
 */
export function formatResolutionSubtext(
  tipoTransacao?: string | null,
  meioReembolso?: string | null,
  elegibilidade?: Elegibilidade | null,
  meioOriginal?: string | null
): string {
  if (elegibilidade === "RECUSAR") {
    return "Devolver artigo ao cliente com comprovativo";
  }
  if (elegibilidade === "REVER") {
    return "Conforme avaliação e validação da chefia";
  }

  const clean = (val?: string | null) =>
    (val ?? "")
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toUpperCase();

  const tt = clean(tipoTransacao);
  const mr = clean(meioReembolso);
  const mo = clean(meioOriginal);

  const effectiveTender = mr.includes("ORIGINAL") && mo ? mo : mr;

  if (
    tt.includes("CREDITO") ||
    effectiveTender.includes("OFERTA") ||
    effectiveTender.includes("CREDITO")
  ) {
    return "Validade de 1 ano em todas as lojas físicas e online";
  }

  if (tt.includes("TROCA")) {
    return "Substituição imediata por artigo elegível em loja";
  }

  if (tt.includes("AJUSTE")) {
    return "Reembolso do diferencial de preço promocional";
  }

  if (
    effectiveTender.includes("NUMERARIO") ||
    effectiveTender.includes("DINHEIRO") ||
    effectiveTender.includes("CASH")
  ) {
    return "Entrega direta em numerário no balcão";
  }

  return "Creditado automaticamente na conta de origem";
}


