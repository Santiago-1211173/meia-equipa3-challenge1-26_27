import {
  ENGINE_PROXY,
  AVALIACOES_PROXY,
  GATEWAY_TIMEOUT_MS,
  GATEWAY_URL,
  type EngineId,
} from "@/config/gateway";
import { toEngine, toNeutral } from "./brand";

export type ApiErrorCode =
  | "ENGINE_UNAVAILABLE"
  | "TIMEOUT"
  | "BAD_REQUEST"
  | "NOT_FOUND"
  | "UPSTREAM_ERROR"
  | "NOT_ALLOWED";

/** Formato único de erro devolvido por todas as rotas /api/*. */
export interface ApiError {
  error: {
    code: ApiErrorCode;
    message: string;
    status: number;
  };
}

function errorResponse(code: ApiErrorCode, message: string, status: number) {
  const body: ApiError = { error: { code, message, status } };
  return Response.json(body, { status });
}

function messageFromDetail(payload: unknown, fallback: string): string {
  if (payload && typeof payload === "object" && "detail" in payload) {
    const detail = (payload as { detail: unknown }).detail;
    if (typeof detail === "string") return detail;
    if (detail !== undefined) return JSON.stringify(detail);
  }
  return fallback;
}

function codeFromStatus(status: number): ApiErrorCode {
  if (status === 404) return "NOT_FOUND";
  if (status === 503) return "ENGINE_UNAVAILABLE";
  if (status >= 400 && status < 500) return "BAD_REQUEST";
  return "UPSTREAM_ERROR";
}

function matches(pattern: string, segments: string[]): boolean {
  if (pattern === "" && segments.length === 0) return true;
  const parts = pattern.split("/").filter(Boolean);
  return (
    parts.length === segments.length &&
    parts.every((part, i) => part === "*" || part === segments[i])
  );
}

/**
 * Chamada única ao gateway: timeout, erro normalizado e tipagem.
 * Em sucesso devolve o JSON do gateway como está; em falha, um ApiError.
 */
export async function gatewayFetch(
  path: string,
  init: { method: "GET" | "POST"; body?: string; search?: string },
  options: { neutralBrand?: boolean } = {}
): Promise<Response> {
  const url = `${GATEWAY_URL}${path}${init.search ?? ""}`;
  try {
    const upstream = await fetch(url, {
      method: init.method,
      headers: init.body ? { "Content-Type": "application/json" } : undefined,
      body: init.body,
      cache: "no-store",
      signal: AbortSignal.timeout(GATEWAY_TIMEOUT_MS),
    });

    let payload: unknown = await upstream.json().catch(() => null);
    if (options.neutralBrand) payload = toNeutral(payload);

    if (!upstream.ok) {
      return errorResponse(
        codeFromStatus(upstream.status),
        messageFromDetail(payload, `Erro ${upstream.status} no serviço.`),
        upstream.status
      );
    }
    return Response.json(payload, { status: upstream.status });
  } catch (err) {
    if (err instanceof DOMException && err.name === "TimeoutError") {
      return errorResponse("TIMEOUT", "O motor demorou demasiado a responder.", 504);
    }
    return errorResponse(
      "ENGINE_UNAVAILABLE",
      "Não foi possível contactar o motor. Verifique se o serviço está ativo.",
      503
    );
  }
}

/** Proxy genérico de um motor, restrito à lista de rotas permitidas. */
export async function proxyEngine(
  engine: EngineId,
  request: Request,
  segments: string[]
): Promise<Response> {
  const config = ENGINE_PROXY[engine];
  const method = request.method as "GET" | "POST";
  const allowed = config.allowed.some(
    (route) => route.method === method && matches(route.pattern, segments)
  );
  if (!allowed) {
    return errorResponse("NOT_ALLOWED", "Operação não disponível.", 404);
  }

  const path = `${config.gatewayPrefix}/${segments.map(encodeURIComponent).join("/")}`;
  const neutralBrand = engine === "returns" || engine === "prolog";
  let body = method === "POST" ? await request.text() : undefined;
  if (neutralBrand && body) {
    try {
      body = JSON.stringify(toEngine(JSON.parse(body)));
    } catch {
      // Corpo inválido segue como está; o gateway responde com o erro de validação.
    }
  }
  return gatewayFetch(
    path,
    { method, body: body || undefined, search: new URL(request.url).search },
    { neutralBrand }
  );
}

/** Proxy genérico e seguro para as rotas unificadas de histórico de inferências e comparação de motores. */
export async function proxyAvaliacoes(
  request: Request,
  segments: string[] = []
): Promise<Response> {
  const config = AVALIACOES_PROXY;
  const method = request.method as "GET" | "POST";
  const allowed = config.allowed.some(
    (route) => route.method === method && matches(route.pattern, segments)
  );
  if (!allowed) {
    return errorResponse("NOT_ALLOWED", "Operação não disponível.", 404);
  }

  const subpath = segments.length > 0 ? `/${segments.map(encodeURIComponent).join("/")}` : "";
  const path = `${config.gatewayPrefix}${subpath}`;
  const body = method === "POST" ? await request.text() : undefined;

  return gatewayFetch(path, {
    method,
    body: body || undefined,
    search: new URL(request.url).search,
  });
}
