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
