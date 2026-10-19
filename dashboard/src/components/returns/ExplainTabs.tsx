"use client";

import React, { createContext, useCallback, useContext, useEffect, useState } from "react";
import { ApiClientError, api } from "@/client/api";
import ErrorBanner from "@/components/shared/ErrorBanner";
import {
  ELIGIBILITY,
  WHAT_IF_PRESETS,
  cause,
  cleanRuleCodes,
  label,
  moduleLabel,
} from "@/config/returnsLabels";
import type {
  CondicaoDto,
  DadoEmFaltaDto,
  DadosEmFaltaResponse,
  Elegibilidade,
  ExplicacaoComoResponse,
  ExplicacaoPorqueNaoConclusaoResponse,
  ReturnRequest,
  SimulacaoResponse,
} from "@/types/returns";

const ExplainBaseContext = createContext<string>("/api/returns");
const LOCALE = "locale=pt-PT";

export type TabId = "how" | "whynot" | "whatif" | "missing";

const TABS: { id: TabId; label: string; icon: string }[] = [
  { id: "how", label: "Como Decidiu?", icon: "route" },
  { id: "whynot", label: "Porque Não...?", icon: "help_outline" },
  { id: "whatif", label: "Simulação E Se...", icon: "science" },
  { id: "missing", label: "Factos e Validações", icon: "fact_check" },
];

const messageOf = (err: unknown) =>
  err instanceof ApiClientError ? err.message : "Não foi possível obter a resposta do motor.";

function useRemote<T>(load: () => Promise<T>) {
  const [settled, setSettled] = useState<{
    source: () => Promise<T>;
    data: T | null;
    error: string | null;
  } | null>(null);
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let cancelled = false;
    load()
      .then((data) => !cancelled && setSettled({ source: load, data, error: null }))
      .catch((err) => !cancelled && setSettled({ source: load, data: null, error: messageOf(err) }));
    return () => {
      cancelled = true;
    };
  }, [load, attempt]);

  const current = settled?.source === load ? settled : null;
  const retry = useCallback(() => {
    setSettled(null);
    setAttempt((value) => value + 1);
  }, []);

  return {
    data: current?.data ?? null,
    error: current?.error ?? null,
    loading: current === null,
    retry,
  };
}

function Status({
  loading,
  error,
  retry,
}: {
  loading: boolean;
  error: string | null;
  retry: () => void;
}) {
  if (error) return <ErrorBanner message={error} onRetry={retry} />;
  if (loading)
    return (
      <div className="flex items-center gap-2.5 p-4 rounded-xl bg-slate-50 border border-slate-200 text-slate-600 text-xs sm:text-sm font-medium animate-pulse">
        <span className="material-symbols-outlined text-emerald-600 text-[20px] animate-spin">sync</span>
        <span>A consultar o motor de inferência pericial...</span>
      </div>
    );
  return null;
}

function Conditions({ items }: { items: CondicaoDto[] }) {
  if (items.length === 0) {
    return (
      <div className="p-3 rounded-xl bg-slate-50 border border-slate-200/70 text-xs text-slate-500 italic flex items-center gap-2 mt-1">
        <span className="material-symbols-outlined text-[16px] text-slate-400 shrink-0">info</span>
        <span>As condições estruturais desta regra não foram atingidas no contexto deste pedido.</span>
      </div>
    );
  }

  return (
    <ul className="flex flex-col gap-2 mt-2">
      {items.map((item, index) => (
        <li
          key={index}
          className={`flex items-start gap-2.5 p-3 rounded-xl text-xs transition-all ${
            item.cumprida
              ? "bg-emerald-50/70 border border-emerald-200/80 text-emerald-950"
              : "bg-rose-50/70 border border-rose-200/80 text-rose-950"
          }`}
        >
          <span
            className={`material-symbols-outlined text-[18px] shrink-0 mt-0.5 ${
              item.cumprida ? "text-emerald-600" : "text-rose-500"
            }`}
          >
            {item.cumprida ? "check_circle" : "cancel"}
          </span>
          <div className="flex flex-col flex-1 min-w-0">
            <span className="font-semibold text-slate-900 leading-snug">
              {item.nome || item.descricao || "Critério de validação"}
            </span>
            {item.descricao && item.descricao !== item.nome && (
              <span className="text-[11px] text-slate-600 mt-0.5">
                {item.descricao}
              </span>
            )}
            {item.valor && (
              <span className="text-[11px] text-slate-500 font-sans mt-0.5">
                Valor apurado no pedido: <strong className="text-slate-800 tabular-nums">{item.valor}</strong>
              </span>
            )}
          </div>
        </li>
      ))}
    </ul>
  );
}

/** 1. Aba Como Decidiu (como/1) */
function HowTab({ evaluationId }: { evaluationId: string }) {
  const base = useContext(ExplainBaseContext);
  const load = useCallback(
    () => api<ExplicacaoComoResponse>(`${base}/avaliacoes/${evaluationId}/explicacoes/como?${LOCALE}`),
    [base, evaluationId]
  );
  const { data, error, loading, retry } = useRemote(load);

  // Determinar a regra terminal para o banner de conclusão
  const lastStep = data?.passos && data.passos.length > 0 ? data.passos[data.passos.length - 1] : null;
  const conclusionText = lastStep
    ? `Decisão estabelecida pela Regra [${lastStep.codigoRegra ?? "NORM"}] — ${cleanRuleCodes(lastStep.nomeRegra || lastStep.mensagem || "Decisão terminal")}`
    : data?.paragem
    ? cleanRuleCodes(data.paragem)
    : "Decisão pericial estabelecida";

  return (
    <div className="flex flex-col gap-4 text-left">
      <Status loading={loading} error={error} retry={retry} />
      {data && (
        <>
          {/* Banner de Conclusão Elegante e Minimalista */}
          <div className="font-sans p-3.5 sm:p-4 rounded-xl bg-emerald-50/70 border border-emerald-200/80 text-emerald-950 text-xs sm:text-sm font-medium flex items-center gap-2.5 shadow-2xs">
            <span className="material-symbols-outlined text-emerald-600 text-[20px] shrink-0">task_alt</span>
            <div className="flex flex-wrap items-center gap-1.5 min-w-0">
              <strong className="text-emerald-900 font-bold whitespace-nowrap">Cadeia Dedutiva Concluída:</strong>
              <span className="text-emerald-800">{conclusionText}</span>
            </div>
          </div>

          {/* Resumo Global da Cadeia */}
          {data.resumo && (
            <div className="font-sans p-4 rounded-xl bg-slate-50 border border-slate-200/80 text-slate-700 text-xs sm:text-sm leading-relaxed flex items-start gap-2.5">
              <span className="material-symbols-outlined text-slate-400 text-[18px] shrink-0 mt-0.5">account_tree</span>
              <div className="flex flex-col gap-0.5">
                <strong className="font-sans text-slate-900 block">Resumo do Raciocínio Normativo:</strong>
                <span>{cleanRuleCodes(data.resumo)}</span>
              </div>
            </div>
          )}

          {/* Linha Temporal de Regras Disparadas */}
          <div className="flex flex-col gap-3 relative before:absolute before:top-4 before:bottom-4 before:left-5 before:w-0.5 before:bg-slate-200 before:z-0">
            {data.passos.map((step) => {
              const ruleCode = step.codigoRegra || (step.nomeRegra?.match(/^[A-Z]{2,4}-\d{3,4}/)?.[0] ?? null);
              const ruleTitle = cleanRuleCodes(step.nomeRegra) || step.nomeRegra || moduleLabel(step.modulo);
              const message = cleanRuleCodes(step.mensagem);
              const isApproved = step.resultado === "PERMITIR";
              const isRejected = step.resultado === "RECUSAR";
              const isReview = step.resultado === "REVER";

              return (
                <div
                  key={step.ordem}
                  className="p-4 bg-white border border-slate-200 rounded-xl shadow-2xs relative z-10 ml-0 sm:ml-2 flex items-start gap-3.5 hover:border-slate-300 transition-all"
                >
                  {/* Número de Ordem */}
                  <div
                    className={`font-mono tabular-nums w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold shrink-0 shadow-2xs ${
                      isApproved
                        ? "bg-emerald-50 text-emerald-800 border border-emerald-300"
                        : isRejected
                        ? "bg-rose-50 text-rose-800 border border-rose-300"
                        : isReview
                        ? "bg-amber-50 text-amber-800 border border-amber-300"
                        : "bg-slate-100 text-slate-700 border border-slate-200"
                    }`}
                  >
                    {step.ordem}
                  </div>

                  <div className="flex flex-col flex-1 gap-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap justify-between">
                      {/* Código e Título da Regra */}
                      <div className="flex items-center gap-2 flex-wrap min-w-0">
                        {ruleCode && (
                          <span className="font-mono text-xs font-bold text-slate-700 bg-slate-100 px-2 py-0.5 rounded border border-slate-200/90 shrink-0">
                            {ruleCode}
                          </span>
                        )}
                        <span className="font-sans font-bold text-sm text-slate-900 leading-snug">
                          {ruleTitle}
                        </span>
                      </div>

                      {/* Badges de Módulo e Desfecho */}
                      <div className="flex items-center gap-1.5 flex-wrap font-sans">
                        {step.modulo && (
                          <span className="px-2 py-0.5 rounded-md bg-slate-100 text-[10px] font-semibold text-slate-600 border border-slate-200/80">
                            {moduleLabel(step.modulo)}
                          </span>
                        )}
                        {step.resultado ? (
                          <span
                            className={`px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider ${
                              isApproved
                                ? "bg-emerald-50 text-emerald-700 border border-emerald-200"
                                : isRejected
                                ? "bg-rose-50 text-rose-700 border border-rose-200"
                                : "bg-amber-50 text-amber-700 border border-amber-200"
                            }`}
                          >
                            {ELIGIBILITY[step.resultado]?.label ?? step.resultado}
                          </span>
                        ) : (
                          <span className="px-2 py-0.5 rounded-md bg-slate-50 text-slate-500 border border-slate-200 text-[10px] font-semibold">
                            Conforme
                          </span>
                        )}
                        {step.aValidar && (
                          <span className="px-2 py-0.5 rounded-md bg-amber-50 text-amber-800 text-[10px] font-semibold border border-amber-200">
                            Requer Validação
                          </span>
                        )}
                      </div>
                    </div>

                    {message && (
                      <p className="font-sans text-xs sm:text-sm text-slate-600 leading-relaxed mt-1">
                        {message}
                      </p>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </>
      )}
    </div>
  );
}

/** 2. Aba Porque Não? (whynot/1) */
function WhyNotTab({
  evaluationId,
  obtained,
}: {
  evaluationId: string;
  obtained: Elegibilidade | null;
}) {
  const base = useContext(ExplainBaseContext);
  const targets = (Object.keys(ELIGIBILITY) as Elegibilidade[]).filter((value) => value !== obtained);
  const [target, setTarget] = useState<Elegibilidade>(targets[0] || "PERMITIR");

  const load = useCallback(
    () =>
      api<ExplicacaoPorqueNaoConclusaoResponse>(
        `${base}/avaliacoes/${evaluationId}/explicacoes/porque-nao?conclusao=${encodeURIComponent(
          `OUT-001:${target}`
        )}&${LOCALE}`
      ),
    [base, evaluationId, target]
  );
  const { data, error, loading, retry } = useRemote(load);

  return (
    <div className="flex flex-col gap-4 text-left">
      {/* Pílulas de Seleção de Desfecho Alternativo */}
      <div className="flex flex-col gap-1.5">
        <span className="font-sans text-xs font-semibold text-slate-500">
          Selecione o desfecho alternativo para analisar as regras e critérios não cumpridos:
        </span>
        <div className="flex flex-wrap gap-2">
          {targets.map((value) => {
            const isActive = value === target;
            const elInfo = ELIGIBILITY[value];
            return (
              <button
                key={value}
                type="button"
                className={`px-3.5 py-1.5 rounded-lg text-xs font-sans font-bold border transition-all cursor-pointer flex items-center gap-1.5 ${
                  isActive
                    ? "bg-slate-900 text-white border-slate-900 shadow-2xs"
                    : "bg-white text-slate-700 border-slate-200 hover:bg-slate-50 hover:border-slate-300"
                }`}
                aria-pressed={isActive}
                onClick={() => setTarget(value)}
              >
                <span>Porque não</span>
                <span className={isActive ? "text-emerald-300" : "text-slate-900 font-extrabold"}>
                  &ldquo;{elInfo?.label ?? value}&rdquo;?
                </span>
              </button>
            );
          })}
        </div>
      </div>

      <Status loading={loading} error={error} retry={retry} />

      {data && (
        <div className="flex flex-col gap-4">
          {data.resumo && (
            <div className="font-sans p-4 rounded-xl bg-slate-50 border border-slate-200/80 text-slate-700 text-xs sm:text-sm leading-relaxed flex items-start gap-2.5">
              <span className="material-symbols-outlined text-slate-400 text-[18px] shrink-0 mt-0.5">help</span>
              <div className="flex flex-col gap-0.5">
                <strong className="font-sans text-slate-900 block">Diagnóstico de Não Disparo:</strong>
                <span>{cleanRuleCodes(data.resumo)}</span>
              </div>
            </div>
          )}

          {/* Lista de Regras Candidatas com Nome Explícito e Critérios de Falha */}
          <div className="grid grid-cols-1 gap-3">
            {data.regras.map((rule, index) => {
              const ruleTitle = rule.variante
                ? rule.variante
                : rule.codigoRegra
                ? `${rule.codigoRegra}: ${cleanRuleCodes(rule.resumo || "Critério Alternativo")}`
                : cause(rule.causa);

              return (
                <div
                  key={index}
                  className="p-4 sm:p-5 bg-white border border-slate-200 rounded-xl flex flex-col gap-2.5 shadow-2xs hover:border-slate-300 transition-all"
                >
                  <div className="flex items-center justify-between gap-2 flex-wrap">
                    <div className="flex items-center gap-2 flex-wrap min-w-0">
                      {rule.codigoRegra && (
                        <span className="font-mono text-xs font-bold text-slate-700 bg-slate-100 px-2 py-0.5 rounded border border-slate-200/90 shrink-0">
                          {rule.codigoRegra}
                        </span>
                      )}
                      <span className="font-sans font-bold text-sm text-slate-900 leading-snug">
                        {rule.variante ? cleanRuleCodes(rule.variante) : ruleTitle}
                      </span>
                    </div>

                    <span
                      className={`font-sans px-2.5 py-0.5 rounded-md text-[11px] font-bold border shrink-0 ${
                        target === "RECUSAR"
                          ? "bg-rose-50 text-rose-700 border-rose-200"
                          : target === "REVER"
                          ? "bg-amber-50 text-amber-700 border-amber-200"
                          : target === "PERMITIR"
                          ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                          : "bg-blue-50 text-blue-700 border-blue-200"
                      }`}
                    >
                      Teria resultado em: {ELIGIBILITY[target]?.label ?? target}
                    </span>
                  </div>

                  {rule.resumo && (
                    <p className="font-sans text-xs sm:text-sm text-slate-600 leading-relaxed">
                      {rule.resumo}
                    </p>
                  )}

                  <Conditions items={rule.condicoes} />
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

/** 3. Aba E Se...? (whatif - Simulação Contrafactual) */
function WhatIfTab({ evaluationId }: { evaluationId: string }) {
  const base = useContext(ExplainBaseContext);
  const [simulation, setSimulation] = useState<SimulacaoResponse | null>(null);
  const [selectedPreset, setSelectedPreset] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [path, setPath] = useState("");
  const [value, setValue] = useState("");

  async function simulate(changes: Record<string, unknown>) {
    setLoading(true);
    setError(null);
    try {
      setSimulation(
        await api<SimulacaoResponse>(`${base}/avaliacoes/${evaluationId}/simulacoes?${LOCALE}`, {
          method: "POST",
          body: { alteracoes: changes },
        })
      );
    } catch (err) {
      setSimulation(null);
      setError(messageOf(err));
    } finally {
      setLoading(false);
    }
  }

  function customChange(): Record<string, unknown> {
    let parsed: unknown = value;
    try {
      parsed = JSON.parse(value);
    } catch {
      // Texto simples segue como string
    }
    return { [path.trim()]: parsed };
  }

  const simulated = simulation?.decisaoSimulada?.elegibilidade;
  const realDiffs = (simulation?.diferencas || []).filter((d) => d.original !== d.simulado);

  return (
    <div className="flex flex-col gap-4 text-left">
      <p className="font-sans text-xs sm:text-sm text-slate-600 leading-relaxed">
        Simule como a deliberação pericial mudaria caso os pressupostos da peça ou da compra do cliente fossem alterados:
      </p>

      {/* Cartões de Presets com Moldura Ativa */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        {WHAT_IF_PRESETS.map((preset) => {
          const isSelected = selectedPreset === preset.label;
          return (
            <button
              key={preset.label}
              type="button"
              disabled={loading}
              onClick={() => {
                setSelectedPreset(preset.label);
                simulate(preset.changes);
              }}
              className={`p-4 rounded-xl text-left transition-all cursor-pointer disabled:opacity-50 border ${
                isSelected
                  ? "border-emerald-600 ring-2 ring-emerald-500/20 shadow-xs bg-emerald-50/30"
                  : "bg-white border-slate-200 hover:border-emerald-500 hover:shadow-2xs"
              }`}
            >
              <div className="flex items-center gap-1.5 text-emerald-700 font-sans font-bold text-[10px] uppercase tracking-wider mb-1.5">
                <span className="material-symbols-outlined text-[15px]">science</span>
                <span>Hipótese Rápida</span>
              </div>
              <span className="font-sans font-bold text-xs sm:text-sm text-slate-900 leading-snug block">
                {preset.label}
              </span>
            </button>
          );
        })}
      </div>

      {/* Simulador Personalizado */}
      <details className="group rounded-xl border border-slate-200 bg-slate-50/70 p-3.5">
        <summary className="font-sans text-xs font-bold uppercase tracking-wider text-slate-500 cursor-pointer flex items-center justify-between">
          <span>Personalizar Parâmetro Contrafactual</span>
          <span className="material-symbols-outlined text-[18px] group-open:rotate-180 transition-transform">
            expand_more
          </span>
        </summary>
        <div className="flex flex-col sm:flex-row items-center gap-2 mt-3 pt-3 border-t border-slate-200">
          <input
            className="font-sans w-full sm:flex-1 px-3 py-2 rounded-lg bg-white border border-slate-200 text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-emerald-500"
            aria-label="Caminho do campo"
            placeholder="Ex: artigos[0].estado.etiquetas"
            value={path}
            onChange={(event) => setPath(event.target.value)}
          />
          <input
            className="font-sans w-full sm:flex-1 px-3 py-2 rounded-lg bg-white border border-slate-200 text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-emerald-500"
            aria-label="Novo valor"
            placeholder="Ex: COLOCADAS"
            value={value}
            onChange={(event) => setValue(event.target.value)}
          />
          <button
            type="button"
            className="font-sans w-full sm:w-auto px-4 py-2 rounded-lg bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold whitespace-nowrap cursor-pointer disabled:opacity-50 transition-colors"
            disabled={loading || !path.trim() || !value.trim()}
            onClick={() => {
              setSelectedPreset(null);
              simulate(customChange());
            }}
          >
            Simular Hipótese
          </button>
        </div>
      </details>

      {loading && (
        <div className="font-sans flex items-center gap-2 p-3 text-xs text-slate-500 font-medium animate-pulse">
          <span className="material-symbols-outlined text-emerald-600 text-[18px] animate-spin">sync</span>
          <span>A deduzir desfecho hipotético no motor...</span>
        </div>
      )}

      {error && <ErrorBanner message={error} />}

      {simulation && (
        <div className="p-4 sm:p-5 bg-white border border-slate-200 rounded-xl shadow-2xs flex flex-col gap-3.5">
          <div className="flex items-center justify-between gap-3 flex-wrap">
            <span className="font-sans text-xs font-bold uppercase tracking-wider text-slate-500">
              Resultado da Hipótese Contrafactual
            </span>
            {simulated && (
              <span
                className={`font-sans px-3 py-1 rounded-full text-xs font-bold border ${
                  simulated === "PERMITIR"
                    ? "bg-emerald-50 text-emerald-800 border-emerald-300"
                    : simulated === "RECUSAR"
                    ? "bg-rose-50 text-rose-800 border-rose-300"
                    : "bg-amber-50 text-amber-800 border-amber-300"
                }`}
              >
                Decisão Simulada: {ELIGIBILITY[simulated]?.label ?? simulated}
              </span>
            )}
          </div>

          {simulation.resumo && (
            <p className="font-sans text-xs sm:text-sm text-slate-700 leading-relaxed font-medium">
              {cleanRuleCodes(simulation.resumo)}
            </p>
          )}

          {/* Dinâmica de Regras Novas / Removidas */}
          {(simulation.regrasNovas?.length > 0 || simulation.regrasRemovidas?.length > 0) && (
            <div className="flex flex-wrap items-center gap-3 pt-1 text-xs font-sans">
              {simulation.regrasNovas.length > 0 && (
                <div className="flex items-center gap-1.5 flex-wrap">
                  <span className="text-slate-500 font-medium">Regras ativadas:</span>
                  {simulation.regrasNovas.map((code) => (
                    <span
                      key={code}
                      className="font-mono text-[11px] font-bold text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200"
                    >
                      +{code}
                    </span>
                  ))}
                </div>
              )}
              {simulation.regrasRemovidas.length > 0 && (
                <div className="flex items-center gap-1.5 flex-wrap">
                  <span className="text-slate-500 font-medium">Regras desativadas:</span>
                  {simulation.regrasRemovidas.map((code) => (
                    <span
                      key={code}
                      className="font-mono text-[11px] font-bold text-rose-800 bg-rose-50 px-2 py-0.5 rounded border border-rose-200 line-through"
                    >
                      -{code}
                    </span>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Tabela de Diferenças Significativas */}
          {realDiffs.length > 0 ? (
            <div className="w-full overflow-x-auto rounded-xl border border-slate-200 shadow-2xs mt-1">
              <table className="w-full text-left border-collapse text-xs font-sans tabular-nums">
                <thead className="bg-slate-50 text-slate-600 font-bold border-b border-slate-200">
                  <tr>
                    <th scope="col" className="p-2.5">Onde</th>
                    <th scope="col" className="p-2.5">Campo Alterado</th>
                    <th scope="col" className="p-2.5">Valor Original</th>
                    <th scope="col" className="p-2.5">Valor Hipotético</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 bg-white">
                  {realDiffs.map((diff, index) => (
                    <tr key={index} className="hover:bg-slate-50/60 transition-colors">
                      <td className="p-2.5 font-sans font-bold text-slate-900">{diff.alvo ?? "Pedido"}</td>
                      <td className="p-2.5 text-slate-700 font-medium">{label(diff.campo)}</td>
                      <td className="p-2.5 text-rose-700 font-semibold">{label(diff.original)}</td>
                      <td className="p-2.5 text-emerald-700 font-bold">{label(diff.simulado)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="font-sans p-3 rounded-xl bg-slate-50 border border-slate-200/80 text-slate-600 text-xs flex items-center gap-2 mt-1">
              <span className="material-symbols-outlined text-[18px] text-slate-400 shrink-0">info</span>
              <span>Esta alteração contrafactual pontual não modifica o veredito de elegibilidade calculado pelo motor pericial.</span>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

type RecordUnknown = Record<string, unknown>;

/** Extração de Factos e Pressupostos Auditados a partir do Pedido do Wizard */
function getAuditedFacts(request: ReturnRequest) {
  const req = request as RecordUnknown;
  const loja = (typeof req.loja === "object" && req.loja !== null ? req.loja : {}) as RecordUnknown;
  const compra = (typeof req.compraOriginal === "object" && req.compraOriginal !== null ? req.compraOriginal : {}) as RecordUnknown;
  const pagamento = (typeof compra.pagamento === "object" && compra.pagamento !== null ? compra.pagamento : {}) as RecordUnknown;
  const comprovativo = (typeof req.comprovativo === "object" && req.comprovativo !== null ? req.comprovativo : null) as RecordUnknown | null;
  const artigos = Array.isArray(req.artigos) ? (req.artigos as RecordUnknown[]) : [];
  const firstArt = artigos.length > 0 ? artigos[0] : {};
  const estadoArt = (typeof firstArt.estado === "object" && firstArt.estado !== null ? firstArt.estado : {}) as RecordUnknown;
  const colab = (typeof req.colaborador === "object" && req.colaborador !== null ? req.colaborador : {}) as RecordUnknown;
  const prod = (typeof firstArt.produto === "object" && firstArt.produto !== null ? firstArt.produto : {}) as RecordUnknown;

  const isBlind = !comprovativo || comprovativo.tipo === "SEM_COMPROVATIVO";

  return [
    {
      category: "Canal de Aquisição",
      icon: "storefront",
      value: compra.canal ? label(compra.canal) : (loja.tipoLoja ? label(loja.tipoLoja) : "Loja Própria (Mainline)"),
      detail: compra.idTransacao ? `Transação: ${String(compra.idTransacao)}` : "Canal validado pelo motor",
    },
    {
      category: "Loja de Atendimento",
      icon: "domain",
      value: (loja.nome as string) || (loja.tipoLoja ? `Loja ${label(loja.tipoLoja)}` : "Loja Física Oficial"),
      detail: loja.codigo ? `Unidade: ${String(loja.codigo)} (${String(loja.mercado || "EUA")})` : "Conformidade geográfica confirmada",
    },
    {
      category: "Estado Físico da Peça",
      icon: "checkroom",
      value: estadoArt.condicaoUso
        ? `${label(estadoArt.condicaoUso)}, Etiquetas ${label(estadoArt.etiquetas || "COLOCADAS")}`
        : "Artigo não usado com etiquetas originais afixadas",
      detail: prod.sku ? `SKU: ${String(prod.sku)}` : "Inspeção física aprovada",
    },
    {
      category: "Comprovativo de Compra",
      icon: "receipt_long",
      value: isBlind
        ? "Sem comprovativo (Processo às Cegas)"
        : (comprovativo?.tipo ? label(comprovativo.tipo) : "Recibo de compra apresentado"),
      detail: comprovativo?.idComprovativo ? `Ref: ${String(comprovativo.idComprovativo)}` : "Verificação de compra apurada",
    },
    {
      category: "Meio de Pagamento Original",
      icon: "credit_card",
      value: pagamento.meio ? label(pagamento.meio) : "Meio de pagamento verificado",
      detail: pagamento.estadoConta ? `Conta ${label(pagamento.estadoConta).toLowerCase()}` : "Registo de liquidação validado",
    },
    {
      category: "Operador de Caixa",
      icon: "badge",
      value: colab.nome ? String(colab.nome) : "Operador de Balcão Autorizado",
      detail: colab.funcao ? `Função: ${label(colab.funcao)} (POS Ativo)` : "Sessão POS autenticada",
    },
    {
      category: "Janela Temporal / Prazo",
      icon: "calendar_today",
      value: compra.dataCompra ? `Compra registada a ${String(compra.dataCompra)}` : "Dentro do prazo regulamentar",
      detail: "Conformidade com a janela de 28 dias da política",
    },
  ];
}

/** 4. Aba Factos e Validações (missing / dados-em-falta) */
function MissingTab({ request }: { request: ReturnRequest }) {
  const base = useContext(ExplainBaseContext);
  const load = useCallback(
    () =>
      api<DadosEmFaltaResponse>(`${base}/dados-em-falta?${LOCALE}`, {
        method: "POST",
        body: request,
      }),
    [base, request]
  );
  const { data, error, loading, retry } = useRemote(load);

  const auditedFacts = getAuditedFacts(request);
  const sortedDados = (data?.dados || []).slice().sort((a, b) => (b.obrigatorio ? 1 : 0) - (a.obrigatorio ? 1 : 0));

  return (
    <div className="flex flex-col gap-5 text-left">
      <Status loading={loading} error={error} retry={retry} />
      {data && (
        <>
          {/* Banner de Auditoria */}
          <div
            className={`font-sans p-4 rounded-xl border flex items-center gap-3 text-xs sm:text-sm font-medium shadow-2xs ${
              data.completo
                ? "bg-emerald-50/70 border-emerald-200/80 text-emerald-950"
                : "bg-amber-50/70 border-amber-200/80 text-amber-950"
            }`}
          >
            <span
              className={`material-symbols-outlined text-[24px] shrink-0 ${
                data.completo ? "text-emerald-600" : "text-amber-600"
              }`}
            >
              {data.completo ? "verified" : "help_center"}
            </span>
            <div className="flex flex-col gap-0.5">
              <strong className="font-bold">
                {data.completo
                  ? "Auditoria Normativa Concluída com Sucesso"
                  : "Pendências de Dados Identificadas"}
              </strong>
              <span className="leading-relaxed">
                {data.completo
                  ? "O pedido reúne a totalidade dos dados requeridos pelas políticas comerciais para uma deliberação vinculativa e auditável."
                  : "Existem dados complementares recomendados para assegurar conformidade integral com as normas de auditoria."}{" "}
                {cleanRuleCodes(data.resumo)}
              </span>
            </div>
          </div>

          {/* Dados em Falta (se existirem) ordenados por prioridade */}
          {sortedDados.length > 0 && (
            <div className="flex flex-col gap-2.5">
              <span className="font-sans text-xs font-bold uppercase tracking-wider text-rose-600">
                Dados em Falta ou Recomendações Normativas
              </span>
              <div className="flex flex-col gap-2.5">
                {sortedDados.map((item: DadoEmFaltaDto) => (
                  <div
                    key={item.codigo}
                    className="p-4 bg-white border border-slate-200 rounded-xl flex flex-col gap-2 shadow-2xs"
                  >
                    <div className="flex items-center justify-between gap-3 flex-wrap">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-bold text-slate-700 bg-slate-100 px-2 py-0.5 rounded border border-slate-200">
                          {item.codigo}
                        </span>
                        <span className="font-sans font-bold text-xs sm:text-sm text-slate-900">
                          {item.descricao ?? "Dado de balcão"}
                        </span>
                      </div>
                      {item.obrigatorio ? (
                        <span className="font-sans px-2.5 py-0.5 rounded-md bg-rose-50 text-rose-700 text-[10px] font-bold uppercase tracking-wider border border-rose-200 shrink-0">
                          Obrigatório
                        </span>
                      ) : (
                        <span className="font-sans px-2.5 py-0.5 rounded-md bg-slate-100 text-slate-600 text-[10px] font-semibold border border-slate-200 shrink-0">
                          Recomendado
                        </span>
                      )}
                    </div>
                    {item.porque?.resumo && (
                      <p className="font-sans text-xs text-slate-600 leading-relaxed">
                        <strong>Impacto Normativo:</strong> {item.porque.resumo}
                      </p>
                    )}
                    {item.porque?.regrasQueDependem && item.porque.regrasQueDependem.length > 0 && (
                      <div className="flex items-center gap-1.5 flex-wrap text-[11px] text-slate-500 font-sans">
                        <span>Afeta as regras:</span>
                        {item.porque.regrasQueDependem.map((r) => (
                          <span key={r} className="font-mono text-[10px] font-bold px-1.5 py-0.5 bg-slate-100 rounded text-slate-700">
                            {r}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Grelha de 2 Colunas com os Factos Auditados pelo Motor */}
          <div className="flex flex-col gap-2.5">
            <div className="flex items-center justify-between px-1">
              <span className="font-sans text-xs font-bold uppercase tracking-wider text-slate-500">
                Factos e Premissas Auditados pelo Motor
              </span>
              <span className="font-sans text-[11px] text-slate-400">
                {auditedFacts.length} pressupostos validados
              </span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {auditedFacts.map((fact, idx) => (
                <div
                  key={idx}
                  className="p-3.5 bg-white border border-slate-200 rounded-xl flex items-start gap-3 shadow-2xs hover:border-slate-300 transition-all"
                >
                  <span className="material-symbols-outlined text-[20px] text-slate-400 shrink-0 mt-0.5">
                    {fact.icon}
                  </span>
                  <div className="flex flex-col flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-1 mb-0.5">
                      <span className="font-sans text-[11px] font-semibold text-slate-400 uppercase tracking-wider truncate">
                        {fact.category}
                      </span>
                      <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-700 text-[10px] font-bold border border-emerald-200 shrink-0">
                        <span className="material-symbols-outlined text-[12px]">check</span>
                        <span>Validado</span>
                      </span>
                    </div>
                    <span className="font-sans font-bold text-xs sm:text-sm text-slate-900 leading-snug">
                      {fact.value}
                    </span>
                    <span className="font-sans text-[11px] text-slate-500 mt-0.5 truncate">
                      {fact.detail}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </>
      )}
    </div>
  );
}

function MissingEvaluationBanner({ tab }: { tab: string }) {
  return (
    <div className="font-sans p-5 rounded-xl bg-slate-50 border border-slate-200 text-slate-600 text-xs sm:text-sm text-left flex items-start sm:items-center gap-3">
      <span className="material-symbols-outlined text-amber-500 text-[22px] shrink-0 mt-0.5 sm:mt-0">info</span>
      <div className="flex flex-col gap-0.5">
        <span className="font-bold text-slate-800">Identificador de Avaliação Indisponível</span>
        <span className="text-slate-500 leading-relaxed">
          Não é possível carregar a análise &ldquo;{tab}&rdquo; sem um ID de avaliação registado pelo motor.
        </span>
      </div>
    </div>
  );
}

export default function ExplainTabs({
  evaluationId,
  request,
  obtained,
  base = "/api/returns",
}: {
  evaluationId: string;
  request: ReturnRequest;
  obtained: Elegibilidade | null;
  base?: string;
  paymentMethod?: string;
}) {
  const [active, setActive] = useState<TabId>("how");
  const hasEvaluationId = Boolean(evaluationId && evaluationId.trim().length > 0);

  return (
    <ExplainBaseContext.Provider value={base}>
      <section className="w-full flex flex-col gap-4 text-left" aria-label="Explicações da decisão">
        {/* Navigation Tabs Pill Bar */}
        <div
          role="tablist"
          className="flex flex-wrap gap-1.5 p-1.5 bg-slate-100/90 rounded-xl border border-slate-200/80"
        >
          {TABS.map((tab) => {
            const isActive = active === tab.id;
            return (
              <button
                key={tab.id}
                type="button"
                role="tab"
                id={`tab-${tab.id}`}
                aria-selected={isActive}
                aria-controls={`panel-${tab.id}`}
                className={`px-3.5 py-2 rounded-lg text-xs sm:text-sm font-sans font-bold flex items-center gap-2 transition-all cursor-pointer ${
                  isActive
                    ? "bg-white text-slate-900 border border-slate-200 shadow-2xs"
                    : "text-slate-600 hover:text-slate-900 hover:bg-white/60"
                }`}
                onClick={() => setActive(tab.id)}
              >
                <span className="material-symbols-outlined text-[17px]">{tab.icon}</span>
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* Tab Panels */}
        <div role="tabpanel" id="panel-how" aria-labelledby="tab-how" hidden={active !== "how"}>
          {hasEvaluationId ? (
            <HowTab evaluationId={evaluationId} />
          ) : (
            <MissingEvaluationBanner tab="Como Decidiu" />
          )}
        </div>
        <div role="tabpanel" id="panel-whynot" aria-labelledby="tab-whynot" hidden={active !== "whynot"}>
          {hasEvaluationId ? (
            <WhyNotTab evaluationId={evaluationId} obtained={obtained} />
          ) : (
            <MissingEvaluationBanner tab="Porque Não" />
          )}
        </div>
        <div role="tabpanel" id="panel-whatif" aria-labelledby="tab-whatif" hidden={active !== "whatif"}>
          {hasEvaluationId ? (
            <WhatIfTab evaluationId={evaluationId} />
          ) : (
            <MissingEvaluationBanner tab="Simulação E Se" />
          )}
        </div>
        <div role="tabpanel" id="panel-missing" aria-labelledby="tab-missing" hidden={active !== "missing"}>
          <MissingTab request={request} />
        </div>
      </section>
    </ExplainBaseContext.Provider>
  );
}
