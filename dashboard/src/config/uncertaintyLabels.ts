import type { Locale } from "@/contexts/LocaleContext";
import type {
  ClassificacaoIncerteza,
  GrauCrencaDto,
  Hipotese,
  MetodoIncerteza,
  Resposta,
} from "@/types/returns";

/**
 * Rótulos da camada de incerteza do motor Drools (docs/08 do motor). Os valores numéricos
 * (pesos, limiares) nunca ficam aqui: vêm do motor, que os lê do ficheiro de parâmetros.
 */

type Bilingue = { pt: string; en: string };

export type ToneIncerteza = "success" | "warning" | "danger" | "info";

const HIPOTESES: Record<Hipotese, Bilingue & { icon: string }> = {
  FRAUDE: { pt: "Risco de fraude", en: "Fraud risk", icon: "gpp_maybe" },
  DEFEITO_FABRICO: { pt: "Defeito de fabrico", en: "Manufacturing defect", icon: "report_problem" },
  REVENDIBILIDADE: { pt: "Revendibilidade", en: "Resaleability", icon: "storefront" },
  RECOMENDACAO_CREDITO: { pt: "Recomendação de crédito de loja", en: "Store credit recommendation", icon: "card_giftcard" },
};

const METODOS: Record<MetodoIncerteza, Bilingue> = {
  FATOR_CERTEZA: { pt: "Fator de certeza", en: "Certainty factor" },
  BAYES: { pt: "Probabilidade bayesiana", en: "Bayesian probability" },
  FUZZY: { pt: "Lógica fuzzy", en: "Fuzzy logic" },
};

const CLASSIFICACOES: Record<ClassificacaoIncerteza, Bilingue & { tone: ToneIncerteza }> = {
  RISCO_ALTO: { pt: "Risco alto", en: "High risk", tone: "danger" },
  RISCO_MEDIO: { pt: "Risco médio", en: "Medium risk", tone: "warning" },
  RISCO_BAIXO: { pt: "Risco baixo", en: "Low risk", tone: "success" },
  PROPOR_PC006: { pt: "Propor PC-006 (defeito provável)", en: "Propose PC-006 (likely defect)", tone: "warning" },
  REVER_DEFEITO: { pt: "Inspeção adicional", en: "Further inspection", tone: "warning" },
  DESGASTE: { pt: "Desgaste", en: "Wear and tear", tone: "info" },
  REVENDIVEL: { pt: "Revendível", en: "Resaleable", tone: "success" },
  REVENDIBILIDADE_INDETERMINADA: { pt: "Indeterminada", en: "Undetermined", tone: "warning" },
  NAO_REVENDIVEL: { pt: "Não revendível", en: "Not resaleable", tone: "danger" },
  CREDITO_RECOMENDADO: { pt: "Crédito recomendado", en: "Credit recommended", tone: "success" },
  CREDITO_A_CRITERIO: { pt: "Crédito a critério da gestão", en: "Credit at management's discretion", tone: "warning" },
  CREDITO_NAO_RECOMENDADO: { pt: "Crédito não recomendado", en: "Credit not recommended", tone: "danger" },
};

/** Classificações possíveis de cada hipótese, para a pergunta "Porque não?". */
export const CLASSES_POR_HIPOTESE: Record<Hipotese, ClassificacaoIncerteza[]> = {
  FRAUDE: ["RISCO_BAIXO", "RISCO_MEDIO", "RISCO_ALTO"],
  DEFEITO_FABRICO: ["PROPOR_PC006", "REVER_DEFEITO", "DESGASTE"],
  REVENDIBILIDADE: ["REVENDIVEL", "REVENDIBILIDADE_INDETERMINADA", "NAO_REVENDIVEL"],
  RECOMENDACAO_CREDITO: ["CREDITO_RECOMENDADO", "CREDITO_A_CRITERIO", "CREDITO_NAO_RECOMENDADO"],
};

/** O defeito de fabrico e a revendibilidade são calculados por artigo; os outros para o pedido. */
export function hipotesePorArtigo(hipotese: Hipotese | null | undefined): boolean {
  return hipotese === "DEFEITO_FABRICO" || hipotese === "REVENDIBILIDADE";
}

export function hipoteseLabel(hipotese: Hipotese | null | undefined, locale: Locale): string {
  if (!hipotese) return "—";
  return HIPOTESES[hipotese]?.[locale] ?? hipotese;
}

export function hipoteseIcon(hipotese: Hipotese | null | undefined): string {
  return (hipotese && HIPOTESES[hipotese]?.icon) || "psychology";
}

export function metodoLabel(metodo: MetodoIncerteza | null | undefined, locale: Locale): string {
  if (!metodo) return "—";
  return METODOS[metodo]?.[locale] ?? metodo;
}

export function classificacaoLabel(classe: string | null | undefined, locale: Locale): string {
  if (!classe) return "—";
  return CLASSIFICACOES[classe as ClassificacaoIncerteza]?.[locale] ?? classe;
}

export function classificacaoTone(classe: string | null | undefined): ToneIncerteza {
  return CLASSIFICACOES[classe as ClassificacaoIncerteza]?.tone ?? "info";
}

/** Escala de cada grau: o fator de certeza vai de -1 a 1 e a recomendação de crédito de 0 a 100. */
export function escalaDoGrau(grau: Pick<GrauCrencaDto, "hipotese" | "metodo">): { min: number; max: number } {
  if (grau.hipotese === "RECOMENDACAO_CREDITO") return { min: 0, max: 100 };
  if (grau.metodo === "FATOR_CERTEZA") return { min: -1, max: 1 };
  return { min: 0, max: 1 };
}

/** Recomendação em pontos (0 a 100); os restantes graus com duas casas decimais. */
export function formatarGrau(grau: Pick<GrauCrencaDto, "hipotese" | "valor">, locale: Locale): string {
  const casas = grau.hipotese === "RECOMENDACAO_CREDITO" ? 0 : 2;
  return grau.valor.toLocaleString(locale === "en" ? "en-US" : "pt-PT", {
    minimumFractionDigits: casas,
    maximumFractionDigits: casas,
  });
}

/** Nota que impede ler um fator de certeza como probabilidade. */
export function notaDoMetodo(metodo: MetodoIncerteza | null | undefined, locale: Locale): string | null {
  if (metodo !== "FATOR_CERTEZA") return null;
  return locale === "en" ? "from -1 to 1; not a probability" : "de -1 a 1; não é uma probabilidade";
}

export const RESPOSTAS: { value: Resposta; pt: string; en: string }[] = [
  { value: "SIM", pt: "Sim", en: "Yes" },
  { value: "NAO", pt: "Não", en: "No" },
  { value: "NAO_SEI", pt: "Não sei", en: "Not sure" },
];

/** Perguntas da inspeção do defeito alegado, respondidas pelo colaborador (docs/08 §3.3). */
export const PERGUNTAS_INSPECAO: { codigo: string; icon: string; pt: string; en: string; hintPt: string; hintEn: string }[] = [
  {
    codigo: "ED-01",
    icon: "linear_scale",
    pt: "Dano numa costura ou ponto de união?",
    en: "Damage on a seam or joining point?",
    hintPt: "Costura aberta, ponto solto ou união desfeita",
    hintEn: "Open seam, loose stitch or undone joint",
  },
  {
    codigo: "ED-02",
    icon: "my_location",
    pt: "Dano localizado num único ponto?",
    en: "Damage located at a single point?",
    hintPt: "Falha isolada, sem desgaste à volta",
    hintEn: "Isolated flaw, no surrounding wear",
  },
  {
    codigo: "ED-05",
    icon: "texture",
    pt: "Desgaste generalizado do tecido?",
    en: "Widespread fabric wear?",
    hintPt: "Tecido gasto ou com borboto em várias zonas",
    hintEn: "Fabric thinned or pilling in several areas",
  },
  {
    codigo: "ED-06",
    icon: "local_laundry_service",
    pt: "Sinais de lavagem repetida?",
    en: "Signs of repeated washing?",
    hintPt: "Cor desbotada ou etiqueta de composição gasta",
    hintEn: "Faded colour or worn care label",
  },
  {
    codigo: "ED-07",
    icon: "content_cut",
    pt: "Dano compatível com uso indevido?",
    en: "Damage consistent with misuse?",
    hintPt: "Corte, queimadura ou rasgão",
    hintEn: "Cut, burn or tear",
  },
];

/** Grau de uso observado (0 a 4), usado pela lógica fuzzy da revendibilidade (docs/08 §4.1). */
export const GRAUS_DE_USO: { value: number; pt: string; en: string }[] = [
  { value: 0, pt: "Nenhum", en: "None" },
  { value: 1, pt: "Ligeiro", en: "Slight" },
  { value: 2, pt: "Moderado", en: "Moderate" },
  { value: 3, pt: "Evidente", en: "Evident" },
  { value: 4, pt: "Intenso", en: "Heavy" },
];

export function avisoDemonstrativo(locale: Locale): string {
  return locale === "en"
    ? "Demonstrative values, not calibrated: do not use them for real decisions. In the review zones the decision always belongs to management."
    : "Valores demonstrativos, não calibrados: não os use para decisões reais. Nas zonas de revisão a decisão é sempre da gestão.";
}
