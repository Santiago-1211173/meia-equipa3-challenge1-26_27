"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { ApiClientError, api } from "@/client/api";
import { ENGINES } from "@/config/engines";
import DecisionSummary from "@/components/returns/DecisionSummary";
import ExplainTabs from "@/components/returns/ExplainTabs";
import RequestEditor from "@/components/returns/RequestEditor";
import RequestSummary from "@/components/returns/RequestSummary";
import ScenarioPicker from "@/components/returns/ScenarioPicker";
import EmptyState from "@/components/shared/EmptyState";
import EngineWorkspace from "@/components/shared/EngineWorkspace";
import ErrorBanner from "@/components/shared/ErrorBanner";
import type { CenarioExemploResponse, DecisaoResponse, ReturnRequest } from "@/types/returns";

interface Evaluation {
  decision: DecisaoResponse;
  request: ReturnRequest;
  requestText: string;
  durationMs: number;
}

function parseRequest(text: string): { request: ReturnRequest | null; error: string | null } {
  if (!text.trim()) return { request: null, error: null };
  try {
    const value: unknown = JSON.parse(text);
    if (value && typeof value === "object" && !Array.isArray(value)) {
      return { request: value as ReturnRequest, error: null };
    }
    return { request: null, error: "O pedido tem de ser um objeto JSON." };
  } catch {
    return { request: null, error: "JSON inválido. Verifique vírgulas, aspas e chavetas." };
  }
}

export default function ReturnsPanel({ engineId = "returns" }: { engineId?: "returns" | "prolog" } = {}) {
  const engine = ENGINES.find((item) => item.id === engineId) ?? ENGINES[0];
  const BASE = engineId === "prolog" ? "/api/prolog" : "/api/returns";

  const [scenarios, setScenarios] = useState<CenarioExemploResponse[] | null>(null);
  const [scenariosError, setScenariosError] = useState<string | null>(null);
  const [scenarioId, setScenarioId] = useState<number | null>(null);
  const [requestText, setRequestText] = useState("");
  const [evaluation, setEvaluation] = useState<Evaluation | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const loadScenarios = useCallback(() => {
    setScenariosError(null);
    api<CenarioExemploResponse[]>(`${BASE}/cenarios-exemplo`)
      .then(setScenarios)
      .catch((err) =>
        setScenariosError(err instanceof ApiClientError ? err.message : "Não foi possível carregar os cenários.")
      );
  }, [BASE]);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- carga inicial dos cenários
    loadScenarios();
  }, [loadScenarios]);

  const { request, error: jsonError } = useMemo(() => parseRequest(requestText), [requestText]);
  const scenario = scenarios?.find((item) => item.id === scenarioId) ?? null;
  const stale = evaluation !== null && evaluation.requestText !== requestText;
  const currentStep = evaluation ? 3 : request ? 1 : 0;

  function selectScenario(next: CenarioExemploResponse) {
    setScenarioId(next.id);
    setRequestText(JSON.stringify(next.pedido, null, 2));
    setEvaluation(null);
    setError(null);
  }

  function reset() {
    setScenarioId(null);
    setRequestText("");
    setEvaluation(null);
    setError(null);
  }

  async function evaluate() {
    if (!request) return;
    setLoading(true);
    setError(null);
    const start = performance.now();
    try {
      const decision = await api<DecisaoResponse>(`${BASE}/avaliar`, { method: "POST", body: request });
      setEvaluation({ decision, request, requestText, durationMs: Math.round(performance.now() - start) });
    } catch (err) {
      setEvaluation(null);
      setError(err instanceof ApiClientError ? err.message : "Não foi possível concluir a avaliação.");
    } finally {
      setLoading(false);
    }
  }

  const input = (
    <>
      <h3 className="card-title font-sans font-bold">1. Escolha um cenário</h3>
      <p className="card-desc font-sans">
        Cada cenário é um pedido de devolução ou troca pronto a avaliar. Pode ajustá-lo antes de executar.
      </p>
      <ScenarioPicker
        scenarios={scenarios}
        selectedId={scenarioId}
        error={scenariosError}
        onSelect={selectScenario}
        onRetry={loadScenarios}
      />

      {requestText && (
        <div className="request-block">
          <div className="presets-label font-sans">Pedido selecionado</div>
          {request && <RequestSummary request={request} scenario={scenario} />}
          <RequestEditor value={requestText} error={jsonError} onChange={setRequestText} />
        </div>
      )}

      <button type="button" className="btn-primary font-sans font-bold" onClick={evaluate} disabled={loading || !request}>
        {loading ? "A avaliar..." : "2. Avaliar pedido"}
      </button>
      {!requestText && <p className="field-hint font-sans">Escolha um cenário para continuar.</p>}
    </>
  );

  const result = (
    <>
      <h3 className="card-title font-sans font-bold">3. Resultado</h3>
      <p className="card-desc font-sans">A decisão do motor, a justificação e o que mudaria noutras condições.</p>

      {error && <ErrorBanner message={error} onRetry={evaluate} />}

      {evaluation ? (
        <>
          {stale && (
            <p className="field-hint field-error font-sans" role="status">
              O pedido foi alterado desde esta avaliação. Avalie de novo para atualizar o resultado.
            </p>
          )}
          <DecisionSummary decision={evaluation.decision} durationMs={evaluation.durationMs} />

          {evaluation.decision.avaliacaoId ? (
            <ExplainTabs
              key={evaluation.decision.avaliacaoId}
              evaluationId={evaluation.decision.avaliacaoId}
              request={evaluation.request}
              obtained={evaluation.decision.elegibilidade ?? null}
              base={BASE}
            />
          ) : (
            <p className="field-hint font-sans">Esta avaliação não foi guardada, por isso não há explicações disponíveis.</p>
          )}

          <div className="btn-group-row">
            <button type="button" className="btn-action font-sans font-bold" onClick={evaluate} disabled={loading || !request}>
              {loading ? "A avaliar..." : "Reavaliar"}
            </button>
            <button type="button" className="btn-action font-sans font-bold" onClick={reset}>
              Nova avaliação
            </button>
          </div>
        </>
      ) : (
        !error && (
          <EmptyState
            title={loading ? "A executar a avaliação..." : "Sem resultado ainda"}
            hint={loading ? undefined : "Escolha um cenário e clique em “Avaliar pedido”."}
          />
        )
      )}
    </>
  );

  return <EngineWorkspace engine={engine} currentStep={currentStep} input={input} result={result} />;
}
