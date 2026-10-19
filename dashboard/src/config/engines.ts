import type { EngineId } from "./gateway";

export interface EngineStep {
  title: string;
  hint: string;
}

export interface EngineMeta {
  id: EngineId;
  label: string;
  tagline: string;
  /** Rota do frontend que informa a saúde do motor. */
  healthPath: string;
  steps: EngineStep[];
}

// Fluxo comum às três abas: o utilizador compara motores sem reaprender a interface.
const FLOW_STEPS = {
  data: { title: "Dados", hint: "Escolha um cenário ou preencha os campos" },
  run: { title: "Executar", hint: "Envie os dados ao motor" },
  result: { title: "Resultado", hint: "Veja a decisão e a justificação" },
  next: { title: "Próximo passo", hint: "Reavalie ou limpe" },
} as const;

const DEFAULT_STEPS: EngineStep[] = [
  FLOW_STEPS.data,
  FLOW_STEPS.run,
  FLOW_STEPS.result,
  FLOW_STEPS.next,
];

export const ENGINES: EngineMeta[] = [
  {
    id: "returns",
    label: "Drools · Devoluções",
    tagline: "Elegibilidade de devoluções e trocas segundo a política da Levi's (Drools)",
    healthPath: "/api/returns/health",
    steps: DEFAULT_STEPS,
  },
  {
    id: "prolog",
    label: "Prolog · Devoluções",
    tagline: "Elegibilidade de devoluções e trocas segundo as 71 regras da Levi's (Prolog)",
    healthPath: "/api/prolog/health",
    steps: DEFAULT_STEPS,
  },
];

export const DEFAULT_ENGINE: EngineId = "returns";

export function resolveEngine(param: string | string[] | undefined): EngineMeta {
  const value = Array.isArray(param) ? param[0] : param;
  return ENGINES.find((engine) => engine.id === value) ?? ENGINES[0];
}
