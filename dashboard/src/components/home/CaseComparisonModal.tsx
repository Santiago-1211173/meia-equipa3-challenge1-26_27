"use client";

import React, { useEffect, useState } from "react";
import type { ComparacaoMotoresResponse, InferenciaItem, RegraItemDto } from "@/types/inferences";

export interface CaseComparisonModalProps {
  pedidoId: string | null;
  isOpen: boolean;
  onClose: () => void;
}

export default function CaseComparisonModal({
  pedidoId,
  isOpen,
  onClose,
}: CaseComparisonModalProps) {
  const [data, setData] = useState<ComparacaoMotoresResponse | null>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen || !pedidoId) {
      setData(null);
      setError(null);
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);

    fetch(`/api/avaliacoes/comparacao/${encodeURIComponent(pedidoId)}`)
      .then(async (res) => {
        if (!res.ok) {
          const errJson = await res.json().catch(() => null);
          const msg =
            errJson?.error?.message ||
            errJson?.detail ||
            `Erro ${res.status} ao carregar comparação.`;
          throw new Error(msg);
        }
        return res.json() as Promise<ComparacaoMotoresResponse>;
      })
      .then((comp) => {
        if (active) {
          setData(comp);
          setLoading(false);
        }
      })
      .catch((err) => {
        if (active) {
          setError(err instanceof Error ? err.message : "Erro desconhecido.");
          setLoading(false);
        }
      });

    return () => {
      active = false;
    };
  }, [isOpen, pedidoId]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && isOpen) {
        onClose();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const renderElegibilidadeBadge = (elegibilidade?: string | null) => {
    switch (elegibilidade) {
      case "PERMITIR":
        return (
          <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-900 border border-emerald-300 flex items-center gap-1">
            <span className="material-symbols-outlined text-[15px] text-emerald-700">check_circle</span>
            PERMITIR (Aprovado)
          </span>
        );
      case "TROCA":
        return (
          <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-blue-100 text-blue-900 border border-blue-300 flex items-center gap-1">
            <span className="material-symbols-outlined text-[15px] text-blue-700">sync_alt</span>
            TROCA (Substituição)
          </span>
        );
      case "RECUSAR":
        return (
          <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-rose-100 text-rose-900 border border-rose-300 flex items-center gap-1">
            <span className="material-symbols-outlined text-[15px] text-rose-700">cancel</span>
            RECUSAR (Não Elegível)
          </span>
        );
      case "REVER":
      default:
        return (
          <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-900 border border-amber-300 flex items-center gap-1">
            <span className="material-symbols-outlined text-[15px] text-amber-700">warning</span>
            REVER (Escalado Gerência)
          </span>
        );
    }
  };

  const renderEngineColumn = (
    instance: InferenciaItem | null | undefined,
    title: string,
    paradigm: string,
    theme: "drools" | "prolog"
  ) => {
    const isDrools = theme === "drools";
    const headerBorder = isDrools ? "border-indigo-200" : "border-emerald-200";
    const badgeBg = isDrools
      ? "bg-indigo-50 text-indigo-700 border-indigo-200"
      : "bg-emerald-50 text-emerald-700 border-emerald-200";
    const iconColor = isDrools ? "text-indigo-600" : "text-emerald-600";

    if (!instance) {
      return (
        <div className={`p-6 rounded-2xl bg-slate-50 border ${headerBorder} flex flex-col items-center justify-center text-center gap-3 min-h-[300px]`}>
          <span className="material-symbols-outlined text-4xl text-slate-300">block</span>
          <p className="text-sm font-semibold text-slate-600">
            Nenhuma deliberação registada para {title}.
          </p>
          <span className="text-xs text-slate-400">
            Execute uma nova inferência com este motor para habilitar a comparação.
          </span>
        </div>
      );
    }

    return (
      <div className={`rounded-2xl border ${headerBorder} bg-white flex flex-col overflow-hidden shadow-xs`}>
        {/* Engine Header */}
        <div className={`p-4 border-b ${headerBorder} flex items-center justify-between gap-3 ${isDrools ? "bg-indigo-50/50" : "bg-emerald-50/50"}`}>
          <div className="flex items-center gap-2.5">
            <span className={`material-symbols-outlined text-[24px] ${iconColor}`}>
              {isDrools ? "account_tree" : "schema"}
            </span>
            <div className="flex flex-col">
              <div className="flex items-center gap-2">
                <span className="font-bold text-sm text-slate-900">{title}</span>
                <span className={`px-2 py-0.5 rounded text-[10px] font-mono tabular-nums font-bold border ${badgeBg}`}>
                  {isDrools ? "DRL" : "PROLOG"}
                </span>
              </div>
              <span className="text-[11px] text-slate-500 font-medium font-sans">{paradigm}</span>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <span className="px-2 py-1 rounded-md bg-white border border-slate-200 text-xs font-mono font-bold tabular-nums text-slate-700 flex items-center gap-1 shadow-2xs">
              <span className="material-symbols-outlined text-[14px] text-slate-400">schedule</span>
              {instance.duracaoMs} ms
            </span>
          </div>
        </div>

        {/* Verdict Details Matrix */}
        <div className="p-4 flex flex-col gap-3.5 text-xs border-b border-slate-100 font-sans">
          <div className="flex items-center justify-between gap-2">
            <span className="text-slate-500 font-medium">Decisão de Elegibilidade:</span>
            {renderElegibilidadeBadge(instance.elegibilidade)}
          </div>

          <div className="grid grid-cols-2 gap-2 p-3 rounded-xl bg-slate-50 border border-slate-100">
            <div>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
                Tipo Transação
              </span>
              <span className="font-semibold text-slate-800 text-xs">
                {instance.tipoTransacao || "NENHUMA"}
              </span>
            </div>
            <div>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
                Meio Reembolso
              </span>
              <span className="font-semibold text-slate-800 text-xs truncate block" title={instance.meioReembolso || "N/A"}>
                {instance.meioReembolso || "N/A"}
              </span>
            </div>
            <div className="mt-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
                Valor Atribuído
              </span>
              <span className="font-bold text-slate-900 text-sm font-sans tabular-nums">
                {instance.valorDevolucao.toFixed(2)} €
              </span>
            </div>
            <div className="mt-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
                Nível Aprovação
              </span>
              <span className="font-semibold text-slate-800 text-xs truncate block">
                {instance.nivelAprovacao || "Balcão (Automático)"}
              </span>
            </div>
          </div>
        </div>

        {/* Fired Rules / Deductions List */}
        <div className="p-4 flex-1 flex flex-col gap-2 font-sans">
          <div className="flex items-center justify-between text-xs font-bold text-slate-700">
            <span className="uppercase tracking-wider text-[11px] text-slate-500">
              {isDrools ? "Regras DRL Disparadas" : "Deduções Lógicas de 1ª Ordem"}
            </span>
            <span className="px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 text-[10px] font-mono tabular-nums">
              {instance.regrasDisparadas.length} nós
            </span>
          </div>

          <div className="flex flex-col gap-2 max-h-60 overflow-y-auto pr-1">
            {instance.regrasDisparadas.length === 0 ? (
              <p className="text-xs text-slate-400 italic py-2">
                Nenhuma regra específica registada nesta avaliação.
              </p>
            ) : (
              instance.regrasDisparadas.map((regra: RegraItemDto, idx: number) => (
                <div
                  key={`${regra.codigo}-${idx}`}
                  className="p-2.5 rounded-lg bg-slate-50/80 hover:bg-slate-100/80 border border-slate-100 transition-colors text-xs flex flex-col gap-1"
                >
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-mono tabular-nums font-bold text-slate-800 text-[11px]">
                      {regra.codigo}
                    </span>
                    {regra.modulo && (
                      <span className="px-1.5 py-0.5 rounded text-[10px] bg-white border border-slate-200 text-slate-500 font-semibold font-mono tabular-nums">
                        {regra.modulo}
                      </span>
                    )}
                  </div>
                  {regra.nome && (
                    <span className="font-semibold text-slate-700 text-[11px] line-clamp-1">
                      {regra.nome}
                    </span>
                  )}
                  {regra.mensagem && (
                    <p className="text-slate-600 text-[11px] leading-relaxed">
                      {regra.mensagem}
                    </p>
                  )}
                </div>
              ))
            )}
          </div>
        </div>

        {/* Column Footer */}
        <div className="p-3 bg-slate-50/60 border-t border-slate-100 text-[10px] text-slate-400 flex items-center justify-between font-mono tabular-nums">
          <span className="truncate" title={instance.motorVersao || undefined}>
            {instance.motorVersao || "Versão padrão"}
          </span>
          <span>
            {new Date(instance.executadoEm).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" })}
          </span>
        </div>
      </div>
    );
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="comparison-modal-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 md:p-6 bg-black/50 backdrop-blur-xs animate-fadeIn overflow-y-auto"
    >
      <div className="bg-white w-full max-w-5xl max-h-[92vh] overflow-y-auto rounded-3xl p-5 sm:p-7 shadow-2xl border border-slate-200 flex flex-col gap-5 my-auto">
        {/* Modal Header */}
        <div className="flex items-start justify-between gap-4 border-b border-slate-200 pb-4">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-2xl bg-indigo-50 border border-indigo-200 text-indigo-700 flex items-center justify-center shadow-xs shrink-0">
              <span className="material-symbols-outlined text-[24px]">compare_arrows</span>
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-xs font-bold text-indigo-600 uppercase tracking-wider font-sans">
                  Auditoria Cruzada de Motores
                </span>
                <span className="px-2 py-0.5 rounded-full bg-slate-100 text-slate-700 font-mono text-xs font-bold tabular-nums">
                  #{pedidoId}
                </span>
              </div>
              <h3
                id="comparison-modal-title"
                className="font-sans text-lg sm:text-xl font-bold text-slate-900 mt-0.5"
              >
                Confronto Pericial: Drools vs Prolog
              </h3>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            aria-label="Fechar comparação"
            className="w-9 h-9 rounded-xl bg-slate-100 text-slate-500 hover:text-slate-900 hover:bg-slate-200 flex items-center justify-center cursor-pointer transition-colors shrink-0"
          >
            <span className="material-symbols-outlined text-[20px]">close</span>
          </button>
        </div>

        {/* Loading State */}
        {loading && (
          <div className="flex flex-col items-center justify-center py-16 gap-4 animate-pulse">
            <div className="w-12 h-12 rounded-full border-3 border-indigo-600 border-t-transparent animate-spin" />
            <p className="text-sm font-semibold text-slate-700">
              A confrontar deliberações em tempo real no PostgreSQL...
            </p>
            <span className="text-xs text-slate-400">
              A carregar matriz de consenso e rastreios de regras para #{pedidoId}
            </span>
          </div>
        )}

        {/* Error State */}
        {!loading && error && (
          <div className="p-6 rounded-2xl bg-rose-50 border border-rose-200 text-rose-900 flex flex-col items-center text-center gap-3">
            <span className="material-symbols-outlined text-4xl text-rose-600">error</span>
            <h4 className="font-bold text-base">Não foi possível carregar o confronto</h4>
            <p className="text-xs text-rose-700 max-w-md">{error}</p>
            <button
              type="button"
              onClick={() => {
                setError(null);
                setLoading(true);
                fetch(`/api/avaliacoes/comparacao/${encodeURIComponent(pedidoId || "")}`)
                  .then((r) => r.json())
                  .then((res) => {
                    setData(res);
                    setLoading(false);
                  })
                  .catch((e) => {
                    setError(e.message);
                    setLoading(false);
                  });
              }}
              className="mt-2 px-4 py-2 rounded-lg bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs cursor-pointer transition-colors shadow-xs"
            >
              Tentar Novamente
            </button>
          </div>
        )}

        {/* Success / Comparison View */}
        {!loading && !error && data && (
          <>
            {/* Consensus / Divergence Banner */}
            <div
              className={`p-4 sm:p-5 rounded-2xl border flex flex-col md:flex-row md:items-center justify-between gap-4 ${
                data.consenso
                  ? "bg-emerald-50/80 border-emerald-200 text-emerald-950"
                  : "bg-amber-50/90 border-amber-200 text-amber-950"
              }`}
            >
              <div className="flex items-start gap-3.5">
                <span
                  className={`material-symbols-outlined text-[28px] shrink-0 mt-0.5 ${
                    data.consenso ? "text-emerald-600" : "text-amber-600"
                  }`}
                >
                  {data.consenso ? "verified" : "warning"}
                </span>

                <div className="flex flex-col gap-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <h4 className="font-extrabold text-sm sm:text-base">
                      {data.consenso
                        ? "Consenso Operacional Confirmado"
                        : "Divergência Detetada entre Motores"}
                    </h4>
                    <span
                      className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                        data.consenso
                          ? "bg-emerald-200/80 text-emerald-900 border border-emerald-300"
                          : "bg-amber-200/80 text-amber-900 border border-amber-300"
                      }`}
                    >
                      {data.consenso ? "100% Acordo" : "Atenção Requerida"}
                    </span>
                  </div>

                  <p className="text-xs leading-relaxed opacity-90">{data.resumoConsenso}</p>

                  {/* List of specific divergences if any */}
                  {data.divergencias && data.divergencias.length > 0 && (
                    <div className="mt-2 flex flex-col gap-1">
                      <span className="text-[11px] font-bold uppercase tracking-wider text-amber-900/80">
                        Pontos de Discordância Canónica:
                      </span>
                      <ul className="list-disc list-inside space-y-0.5 text-xs text-amber-900">
                        {data.divergencias.map((div, idx) => (
                          <li key={idx} className="leading-snug">{div}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                </div>
              </div>

              {/* Relative Speed Metric Pill */}
              {data.razaoVelocidade && (
                <div className="px-3.5 py-2 rounded-xl bg-white/90 border border-slate-200/80 text-slate-800 text-xs font-semibold flex items-center gap-2 self-start md:self-auto shrink-0 shadow-2xs">
                  <span className="material-symbols-outlined text-[18px] text-indigo-600">
                    speed
                  </span>
                  <span>{data.razaoVelocidade}</span>
                </div>
              )}
            </div>

            {/* Side-by-Side Dual Engine Comparison Columns */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 sm:gap-6">
              {renderEngineColumn(
                data.instanciaDrools,
                "Drools Rule Engine",
                "ReteOO / Encadeamento Direto (Forward Chaining)",
                "drools"
              )}
              {renderEngineColumn(
                data.instanciaProlog,
                "SWI-Prolog Engine",
                "Cláusulas Horn / Resolução SLD (Backward Chaining)",
                "prolog"
              )}
            </div>

            {/* Modal Bottom Actions */}
            <div className="flex flex-col sm:flex-row items-center justify-between gap-3 pt-4 border-t border-slate-200">
              <span className="text-xs text-slate-400 flex items-center gap-1.5">
                <span className="material-symbols-outlined text-[16px] text-emerald-600">
                  database
                </span>
                Dados persistidos em PostgreSQL (tabela unificada historico_inferencias)
              </span>

              <div className="flex items-center gap-2 self-end sm:self-auto">
                <button
                  type="button"
                  onClick={() => window.print()}
                  className="px-4 py-2 rounded-xl bg-white hover:bg-slate-100 text-slate-700 font-bold text-xs border border-slate-200 flex items-center gap-1.5 transition-colors cursor-pointer shadow-xs"
                >
                  <span className="material-symbols-outlined text-[16px]">print</span>
                  <span>Imprimir Relatório</span>
                </button>

                <button
                  type="button"
                  onClick={onClose}
                  className="px-5 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs transition-colors cursor-pointer shadow-xs"
                >
                  Fechar
                </button>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
