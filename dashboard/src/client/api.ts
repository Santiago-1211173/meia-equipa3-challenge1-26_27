import type { ApiError, ApiErrorCode } from "@/server/gateway";

/** Erro lançado pelo cliente; a mensagem já está pronta para mostrar ao utilizador. */
export class ApiClientError extends Error {
  constructor(
    message: string,
    readonly code: ApiErrorCode | "NETWORK",
    readonly status: number
  ) {
    super(message);
    this.name = "ApiClientError";
  }
}

function isApiError(payload: unknown): payload is ApiError {
  return (
    typeof payload === "object" &&
    payload !== null &&
    "error" in payload &&
    typeof (payload as ApiError).error?.message === "string"
  );
}

export async function api<T>(
  path: string,
  init: { method?: "GET" | "POST"; body?: unknown } = {}
): Promise<T> {
  let res: Response;
  try {
    res = await fetch(path, {
      method: init.method ?? "GET",
      headers: init.body !== undefined ? { "Content-Type": "application/json" } : undefined,
      body: init.body !== undefined ? JSON.stringify(init.body) : undefined,
    });
  } catch {
    throw new ApiClientError("Sem ligação ao servidor. Tente novamente.", "NETWORK", 0);
  }

  const payload: unknown = await res.json().catch(() => null);
  if (!res.ok) {
    if (isApiError(payload)) {
      throw new ApiClientError(payload.error.message, payload.error.code, payload.error.status);
    }
    throw new ApiClientError(`Erro inesperado (${res.status}).`, "UPSTREAM_ERROR", res.status);
  }
  return payload as T;
}
