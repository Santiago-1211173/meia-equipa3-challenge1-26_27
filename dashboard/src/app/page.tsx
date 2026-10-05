"use client";

import React, { useState, useEffect, useCallback } from "react";
import {
  DEFAULT_API_BASE_URL,
  POC_PRESETS,
  DROOLS_PRESETS,
  PocPreset,
  DroolsPreset,
} from "../config/api";
import {
  OrchestratorHealthResponse,
  EvaluationResponse,
  DroolsEvaluationResponse,
  RunEngineResponse,
  GetFactsResponse,
} from "../types";

export default function DashboardPage() {
  const [activeTab, setActiveTab] = useState<"prolog" | "drools" | "academic" | "playground">("prolog");

  // Health state
  const [health, setHealth] = useState<OrchestratorHealthResponse | null>(null);
  const [healthLoading, setHealthLoading] = useState<boolean>(false);
  const [healthError, setHealthError] = useState<string | null>(null);

  // Tab 1: Prolog POC Evaluate
  const [prologScenario, setPrologScenario] = useState<string>("test");
  const [prologValue, setPrologValue] = useState<number>(42);
  const [prologLoading, setPrologLoading] = useState<boolean>(false);
  const [prologResult, setPrologResult] = useState<EvaluationResponse | null>(null);
  const [prologDuration, setPrologDuration] = useState<number | null>(null);
  const [prologError, setPrologError] = useState<string | null>(null);

  // Tab 2: Drools Evaluate
  const [selectedDroolsPresetId, setSelectedDroolsPresetId] = useState<string>("otorrhagia");
  const [droolsPayloadText, setDroolsPayloadText] = useState<string>(
    JSON.stringify(DROOLS_PRESETS[0].payload, null, 2)
  );
  const [droolsLoading, setDroolsLoading] = useState<boolean>(false);
  const [droolsResult, setDroolsResult] = useState<DroolsEvaluationResponse | null>(null);
  const [droolsDuration, setDroolsDuration] = useState<number | null>(null);
  const [droolsError, setDroolsError] = useState<string | null>(null);

  // Tab 3: Academic Engine
  const [academicLoading, setAcademicLoading] = useState<boolean>(false);
  const [academicAction, setAcademicAction] = useState<string | null>(null);
  const [academicResponse, setAcademicResponse] = useState<any>(null);
  const [academicError, setAcademicError] = useState<string | null>(null);

  // Tab 4: HTTP Playground
  const [pgMethod, setPgMethod] = useState<"GET" | "POST">("GET");
  const [pgEndpoint, setPgEndpoint] = useState<string>("/api/v1/health");
  const [pgBody, setPgBody] = useState<string>("");
  const [pgLoading, setPgLoading] = useState<boolean>(false);
  const [pgStatus, setPgStatus] = useState<number | null>(null);
  const [pgResult, setPgResult] = useState<any>(null);
  const [pgDuration, setPgDuration] = useState<number | null>(null);
  const [pgError, setPgError] = useState<string | null>(null);

  // Fetch health check
  const fetchHealth = useCallback(async () => {
    setHealthLoading(true);
    setHealthError(null);
    try {
      const res = await fetch(`${DEFAULT_API_BASE_URL}/health`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      setHealth(data);
    } catch (err: any) {
      setHealthError(err.message || "Falha ao contactar orquestrador");
      setHealth(null);
    } finally {
      setHealthLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchHealth();
  }, [fetchHealth]);

  // Execute Prolog POC
  const handlePrologEvaluate = async (scenario: string, value: number) => {
    setPrologLoading(true);
    setPrologError(null);
    setPrologResult(null);
    const start = performance.now();
    try {
      const res = await fetch(`${DEFAULT_API_BASE_URL}/api/v1/evaluate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ scenario, value }),
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.detail ? JSON.stringify(data.detail) : `Erro HTTP ${res.status}`);
      }
      setPrologResult(data);
      setPrologDuration(Math.round(performance.now() - start));
    } catch (err: any) {
      setPrologError(err.message || "Erro na avaliação Prolog");
    } finally {
      setPrologLoading(false);
    }
  };

  // Select POC Preset
  const applyPocPreset = (preset: PocPreset) => {
    setPrologScenario(preset.payload.scenario);
    setPrologValue(preset.payload.value);
    handlePrologEvaluate(preset.payload.scenario, preset.payload.value);
  };

  // Execute Drools Evaluate
  const handleDroolsEvaluate = async () => {
    setDroolsLoading(true);
    setDroolsError(null);
    setDroolsResult(null);
    const start = performance.now();
    try {
      let payload;
      try {
        payload = JSON.parse(droolsPayloadText);
      } catch (e) {
        throw new Error("JSON de entrada inválido.");
      }
      const res = await fetch(`${DEFAULT_API_BASE_URL}/api/v1/drools/evaluate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.detail ? JSON.stringify(data.detail) : `Erro HTTP ${res.status}`);
      }
      setDroolsResult(data);
      setDroolsDuration(Math.round(performance.now() - start));
    } catch (err: any) {
      setDroolsError(err.message || "Erro na avaliação Drools");
    } finally {
      setDroolsLoading(false);
    }
  };

  // Select Drools Preset
  const applyDroolsPreset = (preset: DroolsPreset) => {
    setSelectedDroolsPresetId(preset.id);
    setDroolsPayloadText(JSON.stringify(preset.payload, null, 2));
  };

  // Execute Academic Engine Action
  const handleAcademicAction = async (action: "load" | "run" | "facts" | "reset") => {
    setAcademicLoading(true);
    setAcademicError(null);
    setAcademicAction(action);
    try {
      let res: Response;
      if (action === "load") {
        res = await fetch(`${DEFAULT_API_BASE_URL}/api/v1/inference/load`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ knowledge_base: "vehicles" }),
        });
      } else if (action === "run") {
        res = await fetch(`${DEFAULT_API_BASE_URL}/api/v1/inference/run`, {
          method: "POST",
        });
      } else if (action === "facts") {
        res = await fetch(`${DEFAULT_API_BASE_URL}/api/v1/inference/facts`, {
          method: "GET",
        });
      } else {
        res = await fetch(`${DEFAULT_API_BASE_URL}/api/v1/inference/reset`, {
          method: "POST",
        });
      }

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.detail ? JSON.stringify(data.detail) : `Erro HTTP ${res.status}`);
      }
      setAcademicResponse(data);
    } catch (err: any) {
      setAcademicError(err.message || "Erro na operação académica");
    } finally {
      setAcademicLoading(false);
    }
  };

  // Execute Playground HTTP
  const handlePlaygroundSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setPgLoading(true);
    setPgError(null);
    setPgResult(null);
    setPgStatus(null);
    const start = performance.now();
    try {
      const options: RequestInit = {
        method: pgMethod,
        headers: { "Content-Type": "application/json" },
      };
      if (pgMethod === "POST" && pgBody.trim()) {
        try {
          JSON.parse(pgBody);
        } catch {
          throw new Error("O corpo do pedido não é um JSON válido.");
        }
        options.body = pgBody;
      }
      const res = await fetch(`${DEFAULT_API_BASE_URL}${pgEndpoint}`, options);
      setPgStatus(res.status);
      const data = await res.json();
      setPgResult(data);
      setPgDuration(Math.round(performance.now() - start));
    } catch (err: any) {
      setPgError(err.message || "Erro no pedido HTTP");
    } finally {
      setPgLoading(false);
    }
  };

  return (
    <div className="container">
      {/* Header */}
      <header className="header">
        <div className="header-title">
          <h1>Expert System — API Tester</h1>
          <p>Interface simples para teste e validação de endpoints periciais</p>
        </div>

        <div className="header-status">
          <div
            className={`service-pill ${
              health?.status === "healthy" ? "online" : "offline"
            }`}
          >
            <span className="status-dot"></span>
            FastAPI: {health?.status === "healthy" ? "Online (:8000)" : "Offline"}
          </div>

          <div
            className={`service-pill ${
              health?.prolog_engine === "connected" ? "online" : "offline"
            }`}
          >
            <span className="status-dot"></span>
            Prolog: {health?.prolog_engine === "connected" ? "Conectado (:8080)" : "Desconectado"}
          </div>

          <div
            className={`service-pill ${
              health?.drools_engine === "connected" ? "online" : "offline"
            }`}
          >
            <span className="status-dot"></span>
            Drools: {health?.drools_engine === "connected" ? "Conectado (:8082)" : "Desconectado"}
          </div>

          <button
            className="btn-refresh"
            onClick={fetchHealth}
            disabled={healthLoading}
          >
            {healthLoading ? "A verificar..." : "↻ Atualizar"}
          </button>
        </div>
      </header>

      {/* Tabs */}
      <nav className="tabs-nav">
        <button
          className={`tab-btn ${activeTab === "prolog" ? "active" : ""}`}
          onClick={() => setActiveTab("prolog")}
        >
          1. Prolog: Avaliação (POC)
        </button>
        <button
          className={`tab-btn ${activeTab === "drools" ? "active" : ""}`}
          onClick={() => setActiveTab("drools")}
        >
          2. Drools: Hemorragias
        </button>
        <button
          className={`tab-btn ${activeTab === "academic" ? "active" : ""}`}
          onClick={() => setActiveTab("academic")}
        >
          3. Prolog: Motor Académico
        </button>
        <button
          className={`tab-btn ${activeTab === "playground" ? "active" : ""}`}
          onClick={() => setActiveTab("playground")}
        >
          4. Playground HTTP
        </button>
      </nav>

      {/* TAB 1: PROLOG EVALUATE */}
      {activeTab === "prolog" && (
        <div className="grid-2">
          <div className="card">
            <h2 className="card-title">Enviar Avaliação</h2>
            <p className="card-desc">
              Testa o endpoint <code>POST /api/v1/evaluate</code> contra as regras de inferência Prolog.
            </p>

            <div className="presets-section">
              <div className="presets-label">Cenários Rápidos (1 clique)</div>
              <div className="presets-btns">
                {POC_PRESETS.map((p) => (
                  <button
                    key={p.id}
                    className={`btn-preset ${
                      prologScenario === p.payload.scenario && prologValue === p.payload.value
                        ? "active"
                        : ""
                    }`}
                    onClick={() => applyPocPreset(p)}
                  >
                    {p.name}
                  </button>
                ))}
              </div>
            </div>

            <form
              onSubmit={(e) => {
                e.preventDefault();
                handlePrologEvaluate(prologScenario, prologValue);
              }}
            >
              <div className="form-group">
                <label className="form-label">Identificador do Cenário (scenario)</label>
                <input
                  type="text"
                  className="form-input"
                  value={prologScenario}
                  onChange={(e) => setPrologScenario(e.target.value)}
                  placeholder="test"
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Valor Numérico (value)</label>
                <input
                  type="number"
                  className="form-input"
                  value={prologValue}
                  onChange={(e) => setPrologValue(Number(e.target.value))}
                  placeholder="42"
                  required
                />
                <span style={{ fontSize: "0.76rem", color: "var(--text-subtle)", marginTop: "4px", display: "block" }}>
                  Regra: <code>42</code> = Aprovado | Outro valor = Rejeitado
                </span>
              </div>

              <button
                type="submit"
                className="btn-primary"
                disabled={prologLoading}
              >
                {prologLoading ? "A avaliar no Prolog..." : "Executar Avaliação (Prolog)"}
              </button>
            </form>
          </div>

          <div className="card">
            <h2 className="card-title">Resultado da Avaliação</h2>
            <p className="card-desc">Decisão e cadeia de justificação devolvida pelo motor pericial.</p>

            {prologError && <div className="error-banner">{prologError}</div>}

            {prologResult ? (
              <div>
                <div className="result-box">
                  <div className="result-header">
                    <span
                      className={`badge-decision ${
                        prologResult.decision === "approved"
                          ? "approved"
                          : prologResult.decision === "rejected"
                          ? "rejected"
                          : "info"
                      }`}
                    >
                      {prologResult.decision.toUpperCase()}
                    </span>
                    <span className="meta-info">
                      Motor: {prologResult.engine} | {prologDuration}ms
                    </span>
                  </div>

                  <div style={{ marginTop: "10px" }}>
                    <div className="presets-label">Justificação / Regras Disparadas:</div>
                    <ul className="justification-list">
                      {prologResult.justification?.map((item, idx) => (
                        <li key={idx} className="justification-item">
                          {item}
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>

                <div className="presets-label" style={{ marginTop: "14px" }}>
                  Payload JSON da Resposta:
                </div>
                <pre className="code-block">{JSON.stringify(prologResult, null, 2)}</pre>
              </div>
            ) : (
              <div className="empty-state">
                {prologLoading ? (
                  "A comunicar com o motor de inferência..."
                ) : (
                  "Clique num cenário rápido ou preencha o formulário e clique em 'Executar Avaliação'."
                )}
              </div>
            )}
          </div>
        </div>
      )}

      {/* TAB 2: DROOLS EVALUATE */}
      {activeTab === "drools" && (
        <div className="grid-2">
          <div className="card">
            <h2 className="card-title">Avaliação Drools (Regras de Produção)</h2>
            <p className="card-desc">
              Testa o endpoint <code>POST /api/v1/drools/evaluate</code> contra o motor Java / Drools.
            </p>

            <div className="presets-section">
              <div className="presets-label">Diagnósticos Pré-Configurados</div>
              <div className="presets-btns">
                {DROOLS_PRESETS.map((p) => (
                  <button
                    key={p.id}
                    className={`btn-preset ${selectedDroolsPresetId === p.id ? "active" : ""}`}
                    onClick={() => applyDroolsPreset(p)}
                  >
                    {p.name}
                  </button>
                ))}
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Sintomas / Evidências (JSON)</label>
              <textarea
                className="form-textarea"
                rows={8}
                value={droolsPayloadText}
                onChange={(e) => setDroolsPayloadText(e.target.value)}
              />
            </div>

            <button
              className="btn-primary"
              onClick={handleDroolsEvaluate}
              disabled={droolsLoading}
            >
              {droolsLoading ? "A avaliar no Drools..." : "Executar Avaliação (Drools)"}
            </button>
          </div>

          <div className="card">
            <h2 className="card-title">Resultado Drools</h2>
            <p className="card-desc">Diagnóstico clínico, conclusões e regras Rete-OO disparadas.</p>

            {droolsError && <div className="error-banner">{droolsError}</div>}

            {droolsResult ? (
              <div>
                <div className="result-box">
                  <div className="result-header">
                    <span className="badge-decision approved">
                      {droolsResult.primaryDiagnosis || "Diagnóstico Identificado"}
                    </span>
                    <span className="meta-info">
                      Status: {droolsResult.status} | {droolsDuration}ms
                    </span>
                  </div>

                  {droolsResult.hypothesis && (
                    <div style={{ fontSize: "0.84rem", color: "var(--text-muted)", marginBottom: "8px" }}>
                      Hipótese Deduzida: <strong>{droolsResult.hypothesis}</strong>
                    </div>
                  )}

                  <div className="presets-label" style={{ marginTop: "10px" }}>
                    Regras Disparadas ({droolsResult.firedRules?.length || 0}):
                  </div>
                  <ul className="justification-list">
                    {droolsResult.firedRules?.map((rule, idx) => (
                      <li key={idx} className="justification-item">
                        <code>{rule}</code>
                      </li>
                    ))}
                  </ul>
                </div>

                <div className="presets-label" style={{ marginTop: "14px" }}>
                  Payload JSON da Resposta:
                </div>
                <pre className="code-block">{JSON.stringify(droolsResult, null, 2)}</pre>
              </div>
            ) : (
              <div className="empty-state">
                {droolsLoading ? (
                  "A executar avaliação Rete-OO no Drools..."
                ) : (
                  "Selecione um caso clínico pré-configurado e clique em 'Executar Avaliação'."
                )}
              </div>
            )}
          </div>
        </div>
      )}

      {/* TAB 3: ACADEMIC PROLOG INFERENCE */}
      {activeTab === "academic" && (
        <div>
          <div className="card" style={{ marginBottom: "20px" }}>
            <h2 className="card-title">Motor de Inferência Académico (sp_exp2.pl)</h2>
            <p className="card-desc">
              Motor dedutivo pedagógico baseado no ficheiro de apoio do Moodle. Suporta carregamento de base de conhecimento,
              encadeamento para a frente (*forward chaining*) e listagem de factos.
            </p>

            <div className="btn-group-row">
              <button
                className="btn-action"
                disabled={academicLoading}
                onClick={() => handleAcademicAction("load")}
              >
                📥 1. Carregar Base &quot;vehicles&quot;
              </button>
              <button
                className="btn-action"
                disabled={academicLoading}
                onClick={() => handleAcademicAction("run")}
              >
                ⚙️ 2. Executar Inferência
              </button>
              <button
                className="btn-action"
                disabled={academicLoading}
                onClick={() => handleAcademicAction("facts")}
              >
                📋 3. Listar Factos Ativos
              </button>
              <button
                className="btn-action"
                disabled={academicLoading}
                onClick={() => handleAcademicAction("reset")}
              >
                🔄 4. Reset do Motor
              </button>
            </div>
          </div>

          <div className="card">
            <h2 className="card-title">
              {academicAction ? `Resposta da Ação: ${academicAction.toUpperCase()}` : "Registo de Operação"}
            </h2>
            <p className="card-desc">Saída gerada pelo motor SWI-Prolog com factos ou regras deduzidas.</p>

            {academicError && <div className="error-banner">{academicError}</div>}

            {academicResponse ? (
              <div>
                {academicResponse.derived_facts && (
                  <div className="result-box" style={{ marginBottom: "14px" }}>
                    <div className="result-header">
                      <span className="badge-decision info">
                        {academicResponse.derived_facts_count} Factos Derivados
                      </span>
                      <span className="meta-info">Total Factos: {academicResponse.total_facts}</span>
                    </div>

                    <ul className="justification-list">
                      {academicResponse.derived_facts.map((df: any) => (
                        <li key={df.id} className="justification-item">
                          <strong>ID {df.id}:</strong> <code>{df.fact}</code> (Regra #{df.rule_id} via factos {JSON.stringify(df.justified_by)})
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                {academicResponse.facts && (
                  <div className="result-box" style={{ marginBottom: "14px" }}>
                    <div className="result-header">
                      <span className="badge-decision info">
                        {academicResponse.facts_count} Factos em Memória
                      </span>
                    </div>

                    <ul className="justification-list">
                      {academicResponse.facts.map((f: any) => (
                        <li key={f.id} className="justification-item">
                          <strong>ID {f.id}:</strong> <code>{f.fact}</code>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                <div className="presets-label">JSON Retornado:</div>
                <pre className="code-block">{JSON.stringify(academicResponse, null, 2)}</pre>
              </div>
            ) : (
              <div className="empty-state">
                {academicLoading ? "A executar operação..." : "Clique numa das ações acima (ex.: Carregar Base -> Executar)."}
              </div>
            )}
          </div>
        </div>
      )}

      {/* TAB 4: HTTP PLAYGROUND */}
      {activeTab === "playground" && (
        <div className="grid-2">
          <div className="card">
            <h2 className="card-title">Playground HTTP Livre</h2>
            <p className="card-desc">Execute qualquer pedido direto contra a API do FastAPI Orquestrador.</p>

            <form onSubmit={handlePlaygroundSubmit}>
              <div style={{ display: "grid", gridTemplateColumns: "100px 1fr", gap: "10px", marginBottom: "14px" }}>
                <div>
                  <label className="form-label">Método</label>
                  <select
                    className="form-input"
                    value={pgMethod}
                    onChange={(e) => setPgMethod(e.target.value as "GET" | "POST")}
                  >
                    <option value="GET">GET</option>
                    <option value="POST">POST</option>
                  </select>
                </div>
                <div>
                  <label className="form-label">Endpoint</label>
                  <input
                    type="text"
                    className="form-input"
                    value={pgEndpoint}
                    onChange={(e) => setPgEndpoint(e.target.value)}
                    placeholder="/api/v1/health"
                    required
                  />
                </div>
              </div>

              {pgMethod === "POST" && (
                <div className="form-group">
                  <label className="form-label">Corpo do Pedido (JSON)</label>
                  <textarea
                    className="form-textarea"
                    rows={8}
                    value={pgBody}
                    onChange={(e) => setPgBody(e.target.value)}
                    placeholder='{"scenario": "test", "value": 42}'
                  />
                </div>
              )}

              <button
                type="submit"
                className="btn-primary"
                disabled={pgLoading}
              >
                {pgLoading ? "A enviar pedido..." : "Enviar Pedido HTTP"}
              </button>
            </form>
          </div>

          <div className="card">
            <h2 className="card-title">Resposta HTTP</h2>
            <p className="card-desc">Status code, tempo de resposta e conteúdo retornado.</p>

            {pgError && <div className="error-banner">{pgError}</div>}

            {pgResult !== null ? (
              <div>
                <div className="result-header">
                  <span
                    className={`badge-decision ${
                      pgStatus && pgStatus < 300 ? "approved" : "rejected"
                    }`}
                  >
                    HTTP {pgStatus}
                  </span>
                  <span className="meta-info">{pgDuration}ms</span>
                </div>

                <div className="presets-label" style={{ marginTop: "10px" }}>
                  Resposta (JSON):
                </div>
                <pre className="code-block">{JSON.stringify(pgResult, null, 2)}</pre>
              </div>
            ) : (
              <div className="empty-state">
                {pgLoading ? "A aguardar resposta..." : "Defina o endpoint e clique em 'Enviar Pedido HTTP'."}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
