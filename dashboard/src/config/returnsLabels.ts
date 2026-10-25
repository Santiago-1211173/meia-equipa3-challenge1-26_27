import type { Elegibilidade, DocumentacaoResponse } from "@/types/returns";
import type { Locale } from "@/contexts/LocaleContext";

type Tone = "approved" | "rejected" | "info";

export const ELIGIBILITY_PT: Record<Elegibilidade, { label: string; tone: Tone; hint: string }> = {
  PERMITIR: { label: "Permitido", tone: "approved", hint: "O pedido cumpre a política." },
  RECUSAR: { label: "Recusado", tone: "rejected", hint: "O pedido não cumpre a política." },
  REVER: { label: "Requer revisão", tone: "info", hint: "Precisa de aprovação antes de avançar." },
  ENCAMINHAR: { label: "Encaminhar", tone: "info", hint: "Deve seguir por outro canal." },
};

export const ELIGIBILITY_EN: Record<Elegibilidade, { label: string; tone: Tone; hint: string }> = {
  PERMITIR: { label: "Allowed / Approved", tone: "approved", hint: "Request strictly complies with return policy." },
  RECUSAR: { label: "Denied / Rejected", tone: "rejected", hint: "Request does not meet commercial policy criteria." },
  REVER: { label: "Management Review", tone: "info", hint: "Requires managerial approval before settlement." },
  ENCAMINHAR: { label: "Escalate / Forward", tone: "info", hint: "Must be processed via specialized channel/workflow." },
};

export const ELIGIBILITY = ELIGIBILITY_PT;

export function getEligibility(elig: Elegibilidade, locale: Locale = "pt") {
  return locale === "en" ? ELIGIBILITY_EN[elig] : ELIGIBILITY_PT[elig];
}

const LABELS_PT: Record<string, string> = {
  // tipo de pedido / transação (OUT-002)
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
  // base de valor (OUT-003)
  VALOR_PAGO: "Valor pago",
  PRECO_ATUAL: "Preço atual",
  VALOR_PROMOCIONAL: "Valor promocional",
  VALOR_ESCALAO: "Valor por escalão",
  VALOR_POS: "Valor no ponto de venda",
  PVP_ORIGINAL: "Preço original",
  // reembolso / tender (OUT-004)
  ORIGINAL: "Meio de pagamento original",
  MEIO_ORIGINAL: "Meio de pagamento original",
  CARTAO_OFERTA: "Cartão-oferta",
  CARTAO_OFERTA_ELETRONICO: "Cartão-oferta eletrónico",
  DINHEIRO: "Numerário",
  NUMERARIO: "Numerário",
  CASH: "Numerário",
  MEIO_ALTERNATIVO: "Meio alternativo",
  APLICACAO_PAGAMENTO: "Aplicação de pagamento",
  // aprovação (OUT-005)
  XSTORE_MANAGER: "Gestor de loja",
  RESPONSAVEL_SENIOR: "Responsável sénior",
  DISTRICT_AREA: "Gestão de área",
  DISTRICT_MANAGER: "Gestão de distrito",
  GESTAO_LOJA: "Gestão da loja",
  KEY_HOLDER: "Responsável de turno",
  LEAD_CASHIER: "Responsável de caixa",
  ELEVATED_STYLIST: "Stylist sénior",
  STYLIST: "Stylist",
  // processos (OUT-006)
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
  BAIXA_DANO: "Dar baixa (dano)",
  RISCO_BIOLOGICO: "Risco biológico",
  // destino do artigo (OUT-007)
  AREA_VENDAS: "Voltar à área de vendas",
  SALDOS: "Enviar para saldos",
  REETIQUETAR: "Reetiquetar",
  DEVOLUCAO_CLIENTE: "Devolver ao cliente",
  // comprovativo e canal
  RECIBO_IMPRESSO: "Recibo impresso",
  RECIBO_ORIGINAL: "Recibo original",
  RECIBO_DIGITAL: "Recibo digital",
  CONFIRMACAO_ENCOMENDA: "Confirmação de encomenda",
  CONFIRMACAO_ONLINE: "Confirmação online",
  RECIBO_OFERTA: "Recibo de oferta",
  CONSULTA_TRANSACAO: "Consulta da transação",
  CONSULTA_POS: "Consulta no POS",
  SEM_COMPROVATIVO: "Sem comprovativo",
  FOTOGRAFIA_RECIBO: "Fotografia do recibo",
  CONSULTA_BACKPOCKET: "Consulta no sistema de apoio",
  MAINLINE: "Loja principal (Mainline)",
  OUTLET: "Loja Outlet",
  SITE_PROPRIO: "Site da marca",
  SITE_PROPRIO_CA: "Site da marca (Canadá)",
  LEVI_COM: "Site da marca (Levi.com)",
  LEVI_CA: "Site da marca (Levi.ca)",
  FISICA: "Loja física",
  ONLINE_BACKPOCKET: "Online (BackPocket)",
  FRANQUIA_CA: "Franquia (Canadá)",
  GROSSISTA: "Canal grossista",
  DESCONHECIDO: "Canal desconhecido",
  // artigo
  NOVO_ETIQUETAS: "Novo com etiquetas",
  NOVO_ETIQUETAS_SOLTAS: "Novo com etiquetas soltas",
  NOVO_SEM_ETIQUETAS: "Novo sem etiquetas",
  NAO_USADO: "Não usado",
  USADO: "Usado",
  LAVADO: "Lavado",
  MANCHADO: "Manchado / Danificado",
  COLOCADAS: "Colocadas",
  SOLTAS: "Soltas",
  AUSENTES: "Ausentes",
  // pagamento
  CREDITO: "Cartão de crédito",
  DEBITO: "Cartão de débito",
  CARTAO: "Cartão bancário",
  CARTAO_BANCARIO: "Cartão bancário",
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

const LABELS_EN: Record<string, string> = {
  // tipo de pedido / transação (OUT-002)
  DEVOLUCAO: "Return",
  TROCA: "Exchange",
  AJUSTE_PRECO: "Price Adjustment",
  DEVOLUCAO_OFERTA: "Gift Return",
  REEMBOLSO: "Monetary Refund",
  TROCA_MESMO_ARTIGO: "Direct Size Exchange",
  CREDITO_LOJA: "Store Credit",
  NENHUMA: "None (Standard Associate)",
  // verificação
  VERIFICADA: "Verified Purchase",
  AS_CEGAS: "Blind Return (Unverified)",
  NAO_DETERMINADA: "Undetermined",
  // base de valor (OUT-003)
  VALOR_PAGO: "Paid Value",
  PRECO_ATUAL: "Current Selling Price",
  VALOR_PROMOCIONAL: "Promotional Price",
  VALOR_ESCALAO: "Tiered Discount Value",
  VALOR_POS: "POS Registered Value",
  PVP_ORIGINAL: "Original MSRP",
  // reembolso / tender (OUT-004)
  ORIGINAL: "Original Tender",
  MEIO_ORIGINAL: "Original Tender",
  CARTAO_OFERTA: "Physical Gift Card",
  CARTAO_OFERTA_ELETRONICO: "E-Gift Card",
  DINHEIRO: "Cash",
  NUMERARIO: "Cash",
  CASH: "Cash",
  MEIO_ALTERNATIVO: "Alternative Method",
  APLICACAO_PAGAMENTO: "Payment App",
  // aprovação (OUT-005)
  XSTORE_MANAGER: "Store Manager Override",
  RESPONSAVEL_SENIOR: "Senior Manager Override",
  DISTRICT_AREA: "Area Management",
  DISTRICT_MANAGER: "District Manager",
  GESTAO_LOJA: "Store Manager Override",
  KEY_HOLDER: "Key Holder",
  LEAD_CASHIER: "Lead Cashier",
  ELEVATED_STYLIST: "Senior Stylist",
  STYLIST: "Stylist",
  // processos (OUT-006)
  POS: "Point of Sale (POS)",
  BACKPOCKET: "BackPocket System",
  APLICACAO_BACKPOCKET: "BackPocket System",
  AFTERPAY: "Afterpay Portal",
  AFTERPAY_APP: "Afterpay Portal",
  PAYPAL_VENMO: "PayPal / Venmo App",
  FLUXO_APP: "Payment App (PayPal / Venmo)",
  VERIFONE_INTERAC: "Verifone Interac Terminal",
  INTERAC_VERIFONE: "Verifone Interac Terminal",
  FRANQUIA_CANADA: "Canadian Franchise Workflow",
  PROCESSO_GROSSISTA: "Wholesale Partner Channel",
  DANO: "Damaged Goods Logging",
  BAIXA_DANO: "Damage Write-Off",
  RISCO_BIOLOGICO: "Biohazard Isolation",
  // destino do artigo (OUT-007)
  AREA_VENDAS: "Return to Sales Floor",
  SALDOS: "Markdown / Clearance",
  REETIQUETAR: "Retagging Required",
  DEVOLUCAO_CLIENTE: "Return to Customer",
  // comprovativo e canal
  RECIBO_IMPRESSO: "Printed Receipt",
  RECIBO_ORIGINAL: "Original Receipt",
  RECIBO_DIGITAL: "Digital Receipt",
  CONFIRMACAO_ENCOMENDA: "Order Confirmation",
  CONFIRMACAO_ONLINE: "Online Order Confirmation",
  RECIBO_OFERTA: "Gift Receipt",
  CONSULTA_TRANSACAO: "Transaction Lookup",
  CONSULTA_POS: "POS Transaction Lookup",
  SEM_COMPROVATIVO: "No Proof of Purchase",
  FOTOGRAFIA_RECIBO: "Receipt Photograph",
  CONSULTA_BACKPOCKET: "BackPocket System Lookup",
  MAINLINE: "Mainline Retail Store",
  OUTLET: "Outlet Store",
  SITE_PROPRIO: "Brand Web Store",
  SITE_PROPRIO_CA: "Brand Web Store (Canada)",
  LEVI_COM: "Levi.com Web Store",
  LEVI_CA: "Levi.ca Web Store",
  FISICA: "Physical Retail Store",
  ONLINE_BACKPOCKET: "Online (BackPocket)",
  FRANQUIA_CA: "Canadian Franchise",
  GROSSISTA: "Wholesale Channel",
  DESCONHECIDO: "Unknown Channel",
  // artigo
  NOVO_ETIQUETAS: "Pristine with Attached Tags",
  NOVO_ETIQUETAS_SOLTAS: "Unworn with Loose Tags",
  NOVO_SEM_ETIQUETAS: "Unworn without Tags",
  NAO_USADO: "Unworn",
  USADO: "Worn / Used",
  LAVADO: "Washed",
  MANCHADO: "Stained / Damaged",
  COLOCADAS: "Attached",
  SOLTAS: "Loose",
  AUSENTES: "Missing",
  // pagamento
  CREDITO: "Credit Card",
  DEBITO: "Debit Card",
  CARTAO: "Bank Card",
  CARTAO_BANCARIO: "Bank Card",
  APPLE_PAY: "Apple Pay",
  GOOGLE_PAY: "Google Pay",
  PAYPAL: "PayPal",
  VENMO: "Venmo",
  INTERAC: "Interac Debit",
  // Conclusões do motor ACM
  "OUT-001:PERMITIR": "Allow Return",
  "OUT-001:RECUSAR": "Deny Return",
  "OUT-001:REVER": "Manager Review Required",
  "OUT-001:ENCAMINHAR": "Escalate Request",
};

export const LABELS = LABELS_PT;

/** Rótulo bilingue para um valor de enum; valores desconhecidos ficam legíveis. */
export function label(value: unknown, locale: Locale = "pt"): string {
  if (value === null || value === undefined || value === "") return "—";
  const text = String(value);
  const dict = locale === "en" ? LABELS_EN : LABELS_PT;
  if (dict[text]) return dict[text];
  const upper = text.toUpperCase();
  if (dict[upper]) return dict[upper];

  // Fallback para português se não encontrado no dicionário inglês
  if (locale === "en" && LABELS_PT[upper]) {
    // se não há tradução específica, formatar de forma limpa
  } else if (LABELS_PT[upper]) {
    return LABELS_PT[upper];
  }

  return /^[A-Z0-9_]+$/.test(text)
    ? text.charAt(0) + text.slice(1).toLowerCase().replace(/_/g, " ")
    : text;
}

/** Formata valor monetário respeitando o idioma e a moeda selecionados. */
export function money(
  value: unknown,
  locale: Locale = "pt",
  currency?: string
): string {
  if (value === null || value === undefined || value === "") return "—";
  const amount = Number(value);
  if (!Number.isFinite(amount)) return String(value);

  const loc = locale === "en" ? "en-US" : "pt-PT";
  const formatted = new Intl.NumberFormat(loc, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);

  if (currency === "CAD") {
    return locale === "en" ? `CAD $${formatted}` : `${formatted} CAD $`;
  }
  if (currency === "USD") {
    return locale === "en" ? `$${formatted}` : `${formatted} USD`;
  }
  if (currency === "EUR") {
    return locale === "en" ? `€${formatted}` : `${formatted} €`;
  }

  // Padrão conforme idioma ativo
  if (locale === "en") {
    return `$${formatted}`;
  }
  return `${formatted} €`;
}

const CAUSES_PT: Record<string, string> = {
  DISPAROU: "A regra disparou",
  MODULO_NAO_ALCANCADO: "O raciocínio não chegou a este passo",
  CANCELADA_POR_PRECEDENCIA: "Outra regra com prioridade impediu-a",
  CONDICOES_FALHADAS: "Condições não satisfeitas",
};

const CAUSES_EN: Record<string, string> = {
  DISPAROU: "Rule fired successfully",
  MODULO_NAO_ALCANCADO: "Evaluation did not reach this step",
  CANCELADA_POR_PRECEDENCIA: "Preempted by higher priority rule",
  CONDICOES_FALHADAS: "Conditions not met",
};

export const CAUSES = CAUSES_PT;

export function cause(value: unknown, locale: Locale = "pt"): string {
  if (typeof value !== "string") return "—";
  const dict = locale === "en" ? CAUSES_EN : CAUSES_PT;
  return dict[value] ?? label(value, locale);
}

/** Simulações "e se?" de um clique em português e inglês. */
export const WHAT_IF_PRESETS_PT: { label: string; changes: Record<string, unknown> }[] = [
  { label: "As etiquetas estivessem colocadas", changes: { "artigos[0].estado.etiquetas": "COLOCADAS" } },
  { label: "O portal online estivesse disponível", changes: { portalOnlineDisponivel: true } },
  { label: "O artigo estivesse claramente usado", changes: { "artigos[0].estado.condicaoUso": "USADO" } },
];

export const WHAT_IF_PRESETS_EN: { label: string; changes: Record<string, unknown> }[] = [
  { label: "If tags were attached", changes: { "artigos[0].estado.etiquetas": "COLOCADAS" } },
  { label: "If online portal were operational", changes: { portalOnlineDisponivel: true } },
  { label: "If item were clearly used", changes: { "artigos[0].estado.condicaoUso": "USADO" } },
];

export const WHAT_IF_PRESETS = WHAT_IF_PRESETS_PT;

export function getWhatIfPresets(locale: Locale = "pt") {
  return locale === "en" ? WHAT_IF_PRESETS_EN : WHAT_IF_PRESETS_PT;
}

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

  // Limpeza de preposições órfãs no final resultantes da remoção de código (ex: "fixada por", "determined by")
  cleaned = cleaned.replace(/\s+(?:por|de|com|em|para|a|by|of|with|in|for|to)\s*$/i, "").trim();

  // Se o texto resultante for apenas "Regra", número + "Regra" ou vazio, manter o texto original
  const testNormalized = cleaned.toLowerCase().replace(/^\d+\s*/, "").trim();
  if (testNormalized === "regra" || testNormalized === "rule" || cleaned.length === 0) {
    return text.trim();
  }

  return cleaned;
}

const MODULE_LABELS_PT: Record<string, string> = {
  M0: "Procedimentos de Balcão",
  "M0-CONTEXTO": "Procedimentos de Balcão",
  M1: "Identificação do Produto",
  "M1-PRODUTO": "Identificação do Produto",
  M2: "Compatibilidade de Canais",
  "M2-CANAIS": "Compatibilidade de Canais",
  EVIDENCIA: "Evidências de Incerteza",
  INCERTEZA: "Graus de Crença (Incerteza)",
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

const MODULE_LABELS_EN: Record<string, string> = {
  M0: "Counter Procedures",
  "M0-CONTEXTO": "Counter Procedures",
  M1: "Product Identification",
  "M1-PRODUTO": "Product Identification",
  M2: "Channel Compatibility",
  "M2-CANAIS": "Channel Compatibility",
  EVIDENCIA: "Uncertainty Evidence",
  INCERTEZA: "Belief Degrees (Uncertainty)",
  M3: "Physical Condition & Tags",
  "M3-ESTADO": "Physical Condition & Tags",
  M4: "Proof of Purchase",
  "M4-PRAZOS_RECIBOS": "Proof of Purchase",
  "M4-COMPROVATIVO": "Proof of Purchase",
  M5: "Timeframe & Policy Windows",
  "M5-PRAZO": "Timeframe & Policy Windows",
  M6: "Exchanges & Exceptions",
  "M6-EXCECOES": "Exchanges & Exceptions",
  "M6-TROCAS": "Exchanges & Exceptions",
  M7: "Settlement & Payment Tender",
  "M7-TENDER_MEIOS": "Settlement & Payment Tender",
  "M7-LIQUIDACAO": "Settlement & Payment Tender",
  M8: "Mandatory Documentation",
  "M8-CONCLUSAO": "Mandatory Documentation",
  "M8-DOCUMENTACAO": "Mandatory Documentation",
  M9: "Disposition & Routing",
  "M9-DESTINO": "Disposition & Routing",
};

export const MODULE_LABELS = MODULE_LABELS_PT;

/** Devolve rótulo legível bilingue para módulos de regras */
export function moduleLabel(code?: string | null, locale: Locale = "pt"): string {
  if (!code) return locale === "en" ? "General Validation" : "Validação Geral";
  const upper = code.toUpperCase();
  const dict = locale === "en" ? MODULE_LABELS_EN : MODULE_LABELS_PT;
  if (dict[upper]) return dict[upper];
  for (const [key, val] of Object.entries(dict)) {
    if (upper.startsWith(key)) return val;
  }
  return label(code, locale);
}

/**
 * Determina a ação operacional e respetiva instrução/hint para o operador no balcão,
 * com base na elegibilidade oficial (OUT-001), nível de aprovação (OUT-005) e processo (OUT-006).
 */
export function formatOperationalAction(
  processo?: string | null,
  aprovacao?: string | null,
  elegibilidade?: Elegibilidade | null,
  locale: Locale = "pt"
): { action: string; hint: string } {
  const normProcesso = processo ? processo.trim().toUpperCase() : null;
  const normAprovacao = aprovacao ? aprovacao.trim().toUpperCase() : null;
  const isEn = locale === "en";

  // 1. Recusa oficial
  if (elegibilidade === "RECUSAR") {
    return {
      action: isEn ? "Return item to customer" : "Devolver artigo ao cliente",
      hint: isEn ? "Issue official counter refusal notice" : "Emitir comprovativo oficial de recusa no balcão",
    };
  }

  // 2. Aprovação mandatória de chefia
  if (normAprovacao && normAprovacao !== "NENHUMA") {
    return {
      action: isEn
        ? `Request ${label(normAprovacao, "en")} authorization`
        : `Solicitar autorização de ${label(normAprovacao, "pt")}`,
      hint: isEn
        ? "Mandatory manager PIN or signature on POS terminal"
        : "PIN ou assinatura obrigatória no terminal POS",
    };
  }

  // 3. Processos operacionais obrigatórios específicos
  if (normProcesso === "BACKPOCKET" || normProcesso === "APLICACAO_BACKPOCKET") {
    return {
      action: isEn ? "Process in BackPocket System" : "Processar no Sistema BackPocket",
      hint: isEn ? "Access dedicated store support web application" : "Aceder à aplicação dedicada de apoio à loja",
    };
  }

  if (normProcesso === "AFTERPAY" || normProcesso === "AFTERPAY_APP") {
    return {
      action: isEn ? "Process Afterpay return" : "Processar devolução Afterpay",
      hint: isEn ? "Follow terminal-specific BNPL workflow" : "Seguir fluxo específico do terminal para BNPL",
    };
  }

  if (normProcesso === "VERIFONE_INTERAC" || normProcesso === "INTERAC_VERIFONE") {
    return {
      action: isEn ? "Insert card into Verifone terminal" : "Inserir cartão no terminal Verifone",
      hint: isEn ? "Physical Canadian Interac debit card required" : "Exige presença de cartão físico Interac",
    };
  }

  if (normProcesso === "PAYPAL_VENMO" || normProcesso === "FLUXO_APP") {
    return {
      action: isEn ? "Process via mobile payment app" : "Processar via aplicação móvel",
      hint: isEn ? "Complete digital reversal in PayPal / Venmo flow" : "Concluir estorno no fluxo digital PayPal / Venmo",
    };
  }

  if (normProcesso === "FRANQUIA_CANADA") {
    return {
      action: isEn ? "Route to Canadian Franchise workflow" : "Encaminhar para processo de Franquia",
      hint: isEn ? "Apply franchise SKU rules and exclusive store workflow" : "Aplicar regras de SKU e fluxo exclusivo da franquia",
    };
  }

  if (normProcesso === "PROCESSO_GROSSISTA") {
    return {
      action: isEn ? "Route to wholesale partner channel" : "Encaminhar para canal grossista",
      hint: isEn ? "Return cannot be processed at direct retail store" : "Devolução não processável em loja direta",
    };
  }

  if (normProcesso === "DANO" || normProcesso === "BAIXA_DANO") {
    return {
      action: isEn ? "Process damage write-off" : "Processar baixa por dano",
      hint: isEn ? "Log item into damaged merchandise inventory" : "Registar artigo no fluxo de mercadoria danificada",
    };
  }

  if (normProcesso === "RISCO_BIOLOGICO") {
    return {
      action: isEn ? "Follow biohazard safety protocol" : "Seguir protocolo de risco biológico",
      hint: isEn ? "Isolate in biohazard bag and dispose of immediately" : "Proceder ao isolamento e descarte imediato",
    };
  }

  // 4. Elegibilidade permitida sem exceção
  if (elegibilidade === "PERMITIR") {
    return {
      action: isEn ? "Complete transaction on Regular POS" : "Concluir transação no POS Regular",
      hint: isEn ? "Process within standard register counter workflow" : "Executar no fluxo padrão de balcão",
    };
  }

  // 5. Fallback para revisão de supervisor
  if (elegibilidade === "REVER") {
    return {
      action: isEn ? "Submit for supervisor review" : "Submeter à validação de supervisor",
      hint: isEn ? "In-person exception assessment required" : "Análise presencial de exceção necessária",
    };
  }

  return {
    action: isEn ? "Complete transaction on Regular POS" : "Concluir transação no POS Regular",
    hint: isEn ? "Process within standard register counter workflow" : "Executar no fluxo padrão de balcão",
  };
}

/**
 * Formata os detalhes de documentação e controlo (OUT-008) em linguagem operacional clara,
 * extraindo dinamicamente datas de retenção, notas, registos de exceção e assinaturas.
 */
export function formatDocumentationDetails(
  doc?: DocumentacaoResponse | null,
  locale: Locale = "pt"
): {
  label: string;
  subtext: string;
} {
  const isEn = locale === "en";

  if (!doc) {
    return {
      label: isEn
        ? "Standard digital POS archive"
        : "Arquivo digital standard no POS",
      subtext: isEn
        ? "No special physical retention requirements"
        : "Sem requisitos especiais de retenção física",
    };
  }

  // Rótulo principal derivado das obrigações
  let mainLabel = isEn
    ? "Compliance and accounting archive"
    : "Conformidade e arquivo contabilístico";

  if (doc.reciboAgrafado) {
    mainLabel = isEn
      ? "Staple receipt and collect signature"
      : "Agrafar recibo e recolher assinatura";
  } else if (doc.assinaturaCliente || doc.assinaturaProcessador || doc.assinaturaTestemunha) {
    mainLabel = isEn
      ? "Collect mandatory register tape signature"
      : "Recolher assinatura obrigatória no talão";
  } else if (doc.registoExcecao) {
    mainLabel = isEn
      ? "Mandatory exception log entry"
      : "Registo de exceção obrigatório";
  } else if (doc.retencaoAte) {
    mainLabel = isEn
      ? `Retain documentation until ${doc.retencaoAte}`
      : `Reter documentação até ${doc.retencaoAte}`;
  }

  // Subtexto contextualizado com as informações específicas presentes
  const details: string[] = [];
  if (doc.retencaoAte) {
    details.push(
      isEn ? `Retention until ${doc.retencaoAte}` : `Retenção até ${doc.retencaoAte}`
    );
  }
  if (doc.registoExcecao) {
    details.push(
      isEn ? `Exception log: ${doc.registoExcecao}` : `Registo: ${doc.registoExcecao}`
    );
  }
  if (doc.notaRecibo) {
    details.push(cleanRuleCodes(doc.notaRecibo));
  }

  const subtext =
    details.length > 0
      ? details.join(" • ")
      : doc.reciboAgrafado
      ? isEn
        ? "Physical archive with customer original receipt"
        : "Arquivo físico com talão original do cliente"
      : isEn
      ? "Compliance and accounting archive"
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
  meioOriginal?: string | null,
  locale: Locale = "pt"
): string {
  const isEn = locale === "en";

  if (elegibilidade === "RECUSAR") {
    return isEn
      ? "No financial settlement authorized"
      : "Nenhuma liquidação financeira autorizada";
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
    return isEn
      ? "Issued on physical or electronic gift card"
      : "Emitido em cartão-oferta físico ou digital";
  }

  if (
    effectiveTender.includes("NUMERARIO") ||
    effectiveTender.includes("DINHEIRO") ||
    effectiveTender.includes("CASH")
  ) {
    return isEn
      ? "Immediate register cash disbursement"
      : "Liquidação imediata em caixa físico";
  }

  if (
    effectiveTender.includes("ORIGINAL") ||
    effectiveTender.includes("CREDITO") ||
    effectiveTender.includes("DEBITO") ||
    effectiveTender.includes("CARTAO") ||
    effectiveTender.includes("BANCARIO")
  ) {
    return isEn
      ? "Secure reversal processed via acquiring bank"
      : "Estorno seguro processado via adquirente";
  }

  if (
    effectiveTender.includes("APLICACAO") ||
    effectiveTender.includes("PAYPAL") ||
    effectiveTender.includes("VENMO") ||
    effectiveTender.includes("AFTERPAY") ||
    effectiveTender.includes("APPLE") ||
    effectiveTender.includes("GOOGLE")
  ) {
    return isEn
      ? "Reversal processed through payment account app"
      : "Estorno processado na aplicação da conta de pagamento";
  }

  if (effectiveTender.includes("VERIFONE") || effectiveTender.includes("INTERAC")) {
    return isEn
      ? "Refund to Interac debit card via Verifone terminal"
      : "Reembolso no cartão Interac via terminal Verifone";
  }

  if (effectiveTender.includes("ALTERNATIVO")) {
    return isEn
      ? "Settlement via agreed alternative method"
      : "Liquidação através de modalidade alternativa acordada";
  }

  if (tt.includes("TROCA")) {
    return isEn
      ? "Value offset applied at the time of exchange"
      : "Compensação de valor liquidada no ato da troca";
  }

  if (tt.includes("AJUSTE")) {
    return isEn
      ? "Difference refunded to original payment method"
      : "Diferença devolvida no meio da transação original";
  }

  if (elegibilidade === "REVER") {
    return isEn
      ? "Contingent upon in-person managerial approval"
      : "Condicionado à aprovação presencial da chefia";
  }

  return isEn
    ? "Settlement in compliance with official policy"
    : "Liquidação em conformidade com a política oficial";
}

/**
 * Produz o subtítulo contextualizado para a modalidade da transação (Card 02 / OUT-002),
 * evitando contradições entre crédito de loja e reembolso em conta.
 */
export function formatResolutionSubtext(
  tipoTransacao?: string | null,
  meioReembolso?: string | null,
  elegibilidade?: Elegibilidade | null,
  meioOriginal?: string | null,
  locale: Locale = "pt"
): string {
  const isEn = locale === "en";

  if (elegibilidade === "RECUSAR") {
    return isEn
      ? "Return item to customer with refusal slip"
      : "Devolver artigo ao cliente com comprovativo";
  }
  if (elegibilidade === "REVER") {
    return isEn
      ? "Subject to management evaluation and override"
      : "Conforme avaliação e validação da chefia";
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
    return isEn
      ? "1-year validity across all retail stores and online"
      : "Validade de 1 ano em todas as lojas físicas e online";
  }

  if (tt.includes("TROCA")) {
    return isEn
      ? "Immediate in-store replacement with qualifying item"
      : "Substituição imediata por artigo elegível em loja";
  }

  if (tt.includes("AJUSTE")) {
    return isEn
      ? "Refund of promotional price variance"
      : "Reembolso do diferencial de preço promocional";
  }

  if (
    effectiveTender.includes("NUMERARIO") ||
    effectiveTender.includes("DINHEIRO") ||
    effectiveTender.includes("CASH")
  ) {
    return isEn
      ? "Direct counter cash handover"
      : "Entrega direta em numerário no balcão";
  }

  return isEn
    ? "Automatically credited to original payment tender"
    : "Creditado automaticamente na conta de origem";
}
