// Gateway e motores: configurável via variável de ambiente ou fallback para localhost.
export const GATEWAY_URL = process.env.GATEWAY_URL || "http://localhost:8000";

export const GATEWAY_TIMEOUT_MS = 15_000;

export type EngineId = "returns" | "prolog";

export type Method = "GET" | "POST";

export interface AllowedRoute {
  method: Method;
  /** Padrão relativo ao prefixo; `*` casa exatamente um segmento. */
  pattern: string;
}

export interface EngineProxyConfig {
  /** Prefixo do gateway onde o motor está exposto. */
  gatewayPrefix: string;
  allowed: AllowedRoute[];
}

export interface AvaliacoesProxyConfig {
  /** Prefixo do gateway para histórico unificado e comparações. */
  gatewayPrefix: string;
  allowed: AllowedRoute[];
}

// Só os paths listados aqui podem ser alcançados pelo browser.
export const ENGINE_PROXY: Record<EngineId, EngineProxyConfig> = {
  returns: {
    gatewayPrefix: "/api/v1/levis",
    allowed: [
      { method: "POST", pattern: "avaliar" },
      { method: "GET", pattern: "avaliacoes" },
      { method: "GET", pattern: "avaliacoes/*" },
      { method: "GET", pattern: "avaliacoes/*/explicacoes/como" },
      { method: "GET", pattern: "avaliacoes/*/explicacoes/porque-nao" },
      { method: "POST", pattern: "avaliacoes/*/simulacoes" },
      { method: "POST", pattern: "dados-em-falta" },
      { method: "POST", pattern: "porque" },
      { method: "GET", pattern: "regras" },
      { method: "GET", pattern: "regras/*" },
      { method: "GET", pattern: "cenarios-exemplo" },
      { method: "GET", pattern: "cenarios-exemplo/*" },
      { method: "GET", pattern: "health" },
    ],
  },
  prolog: {
    gatewayPrefix: "/api/v1/retail",
    allowed: [
      { method: "POST", pattern: "avaliar" },
      { method: "GET", pattern: "avaliacoes" },
      { method: "GET", pattern: "avaliacoes/*" },
      { method: "GET", pattern: "avaliacoes/*/explicacoes/como" },
      { method: "GET", pattern: "avaliacoes/*/explicacoes/porque-nao" },
      { method: "POST", pattern: "avaliacoes/*/simulacoes" },
      { method: "POST", pattern: "dados-em-falta" },
      { method: "POST", pattern: "porque" },
      { method: "GET", pattern: "cenarios-exemplo" },
      { method: "GET", pattern: "cenarios-exemplo/*" },
      { method: "GET", pattern: "health" },
    ],
  },
};

export const AVALIACOES_PROXY: AvaliacoesProxyConfig = {
  gatewayPrefix: "/api/v1/avaliacoes",
  allowed: [
    { method: "GET", pattern: "" },
    { method: "GET", pattern: "*" },
    { method: "GET", pattern: "comparacao/*" },
    { method: "POST", pattern: "seed" },
    { method: "POST", pattern: "avaliar-ambos" },
  ],
};
