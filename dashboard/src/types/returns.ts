/**
 * Tipos do motor de devoluções. Espelham o contrato do gateway; os enums de marca chegam
 * já neutralizados pela camada de acesso (src/server/brand.ts).
 */

export type Elegibilidade = "PERMITIR" | "RECUSAR" | "REVER" | "ENCAMINHAR";

/** Pedido de avaliação completo (estrutura aninhada definida pelo motor). */
export type ReturnRequest = Record<string, unknown>;

export interface DocumentacaoResponse {
  assinaturaCliente?: string | null;
  assinaturaProcessador?: string | null;
  assinaturaTestemunha?: string | null;
  idStylistAtribuido?: string | null;
  reciboAgrafado?: boolean;
  notaRecibo?: string | null;
  retencaoAte?: string | null;
  registoExcecao?: string | null;
}

export interface RegistoRegraResponse {
  ordem: number;
  codigoRegra?: string | null;
  nomeRegra?: string | null;
  modulo?: string | null;
  artigoId?: string | null;
  resultado?: Elegibilidade | null;
  mensagem?: string | null;
  aValidar?: boolean;
}

export interface ResultadoArtigoResponse {
  artigoId: string;
  elegibilidade?: Elegibilidade | null;
  tipoTransacao?: string | null;
  valorDevolucao?: number | string | null;
  baseValor?: string | null;
  destino?: string | null;
  descontoSaldo?: number;
  aprovacao?: string | null;
  terminal?: boolean;
}

export interface CfTraceStep {
  evidence: string;
  cf: number;
  runningCf: number;
  combination: string;
  description: string;
}

export interface UncertaintyCf {
  finalCf: number;
  linguisticLabel: string;
  cfFactorsFired: CfTraceStep[];
  cfTrace: CfTraceStep[];
  context?: string | null;
  source?: string | null;
}

/** Camada de incerteza do motor Drools (docs/08): hipóteses, métodos e classificações. */
export type Hipotese = "FRAUDE" | "DEFEITO_FABRICO" | "REVENDIBILIDADE" | "RECOMENDACAO_CREDITO";

export type MetodoIncerteza = "FATOR_CERTEZA" | "BAYES" | "FUZZY";

export type ClassificacaoIncerteza =
  | "RISCO_ALTO"
  | "RISCO_MEDIO"
  | "RISCO_BAIXO"
  | "PROPOR_PC006"
  | "REVER_DEFEITO"
  | "DESGASTE"
  | "REVENDIVEL"
  | "REVENDIBILIDADE_INDETERMINADA"
  | "NAO_REVENDIVEL"
  | "CREDITO_RECOMENDADO"
  | "CREDITO_A_CRITERIO"
  | "CREDITO_NAO_RECOMENDADO";

/** Resposta do colaborador às perguntas da inspeção e do comportamento do cliente. */
export type Resposta = "SIM" | "NAO" | "NAO_SEI";

export interface ContribuicaoDto {
  codigo?: string | null;
  descricao?: string | null;
  peso: number;
  valorAntes: number;
  valorDepois: number;
  aplicada: boolean;
  motivoNaoAplicada?: string | null;
}

export interface GrauCrencaDto {
  hipotese?: Hipotese | null;
  metodo?: MetodoIncerteza | null;
  artigoId?: string | null;
  valor: number;
  classificacao?: ClassificacaoIncerteza | null;
  contribuicoes: ContribuicaoDto[];
  demonstrativo: boolean;
  versaoParametros?: string | null;
}

export interface ParametrosIncertezaResponse {
  versao?: string | null;
  demonstrativo: boolean;
  fatoresCerteza: Record<string, number>;
  razoesVerosimilhanca: Record<string, number>;
  priorDefeito: number;
  limiares: Record<string, number>;
  ficheirosFcl: Record<string, string>;
}

export interface DecisaoResponse {
  avaliacaoId?: string | null;
  pedidoId?: string | null;
  avaliadaEm?: string | null;
  versaoBaseConhecimento?: string | null;
  elegibilidade?: Elegibilidade | null;
  tipoVerificacao?: string | null;
  tipoTransacao?: string | null;
  valorDevolucao?: number | string | null;
  baseValor?: string | null;
  meioReembolso?: string | null;
  aprovacao?: string | null;
  processo?: string | null;
  terminal?: boolean;
  excecaoRecusada?: boolean;
  documentacao?: DocumentacaoResponse | null;
  artigos: ResultadoArtigoResponse[];
  regras: RegistoRegraResponse[];
  regrasAValidar: string[];
  uncertaintyCf?: UncertaintyCf | null;
  /** Graus de crença da camada de incerteza (só o motor Drools os calcula). */
  incerteza?: GrauCrencaDto[];
}

export interface CondicaoDto {
  nome?: string | null;
  descricao?: string | null;
  cumprida?: boolean | null;
  valor?: string | null;
  artigoId?: string | null;
}

export interface PassoExplicacaoDto {
  ordem: number;
  modulo?: string | null;
  codigoRegra?: string | null;
  nomeRegra?: string | null;
  artigoId?: string | null;
  resultado?: Elegibilidade | null;
  mensagem?: string | null;
  aValidar?: boolean;
}

export interface ExplicacaoComoResponse {
  passos: PassoExplicacaoDto[];
  modulosPercorridos: string[];
  paragem?: string | null;
  resumo?: string | null;
}

/** "Como?" de uma conclusão (OUT-xxx) ou de um grau de crença (INCERTEZA.<HIPOTESE>). */
export interface ExplicacaoConclusaoResponse {
  conclusao?: string | null;
  artigoId?: string | null;
  valores: Record<string, string>;
  regra?: string | null;
  mensagem?: string | null;
  condicoes: CondicaoDto[];
  caminho: string[];
  resumo?: string | null;
}

export interface ExplicacaoPorqueNaoResponse {
  codigoRegra?: string | null;
  artigoId?: string | null;
  causa?: string | null;
  regraResponsavel?: string | null;
  variante?: string | null;
  condicoes: CondicaoDto[];
  resumo?: string | null;
}

export interface ExplicacaoPorqueNaoConclusaoResponse {
  conclusao?: string | null;
  valor?: string | null;
  artigoId?: string | null;
  valorObtido?: string | null;
  obtida?: boolean;
  propostaPor: string[];
  definidoPor?: string | null;
  regras: ExplicacaoPorqueNaoResponse[];
  resumo?: string | null;
}

export interface RegraEmEsperaDto {
  codigoRegra?: string | null;
  nomeRegra?: string | null;
  modulo?: string | null;
  artigoId?: string | null;
  conclusoes: string[];
  condicoesDoDado: CondicaoDto[];
}

export interface ExplicacaoPorqueResponse {
  dado?: string | null;
  codigo?: string | null;
  pergunta?: string | null;
  regrasQueDependem: string[];
  regrasEmEspera: RegraEmEsperaDto[];
  resumo?: string | null;
}

export interface DadoEmFaltaDto {
  codigo: string;
  caminho: string;
  descricao?: string | null;
  obrigatorio?: boolean;
  porque?: ExplicacaoPorqueResponse | null;
}

export interface DadosEmFaltaResponse {
  dados: DadoEmFaltaDto[];
  completo?: boolean;
  resumo?: string | null;
  /** Uma paragem obrigatória terminou a inferência: não é preciso mais nenhum dado. */
  terminal?: boolean;
  /** Regra de paragem que terminou a inferência (ex.: HS-003). */
  paragem?: string | null;
}

export interface DiferencaDto {
  alvo?: string | null;
  campo?: string | null;
  original?: string | null;
  simulado?: string | null;
}

export interface SimulacaoResponse {
  diferencas: DiferencaDto[];
  regrasNovas: string[];
  regrasRemovidas: string[];
  resumo?: string | null;
  decisaoSimulada?: DecisaoResponse | null;
}

export interface CenarioExemploResponse {
  id: number;
  titulo: string;
  estado?: string | null;
  aValidar: string[];
  pressupostos: string[];
  justificacao: string[];
  pedido: ReturnRequest;
  esperado?: Record<string, unknown> | null;
}

export interface RegraResumoDto {
  id: string;
  modulos: string[];
  descricao?: string | null;
  variantes: number;
  aValidar: boolean;
}
