"use client";

import React, { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import Navbar from "@/components/ui/Navbar";
import StatusFooter from "@/components/ui/StatusFooter";
import CaseComparisonModal from "@/components/home/CaseComparisonModal";
import type { InferenciaItem, PaginaResponse } from "@/types/inferences";
import { label } from "@/config/returnsLabels";

function formatRelativeDate(isoString: string): string {
  try {
    const date = new Date(isoString);
    if (isNaN(date.getTime())) return "Recente";
    return date.toLocaleDateString("pt-PT", {
      day: "2-digit",
      month: "short",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return "Recente";
  }
}

function getPageNumbers(currentPage: number, totalPages: number): (number | "...")[] {
  if (totalPages <= 1) return [1];
  if (totalPages <= 7) {
    return Array.from({ length: totalPages }, (_, i) => i + 1);
  }
  const current = currentPage + 1; // 1-indexed

  if (current <= 4) {
    return [1, 2, 3, 4, 5, "...", totalPages];
  }
  if (current >= totalPages - 3) {
    return [1, "...", totalPages - 4, totalPages - 3, totalPages - 2, totalPages - 1, totalPages];
  }
  return [1, "...", current - 1, current, current + 1, "...", totalPages];
}

export default function DecisoesPage() {
  const [outcomeFilter, setOutcomeFilter] = useState<"TODOS" | "PERMITIR" | "TROCA" | "RECUSAR" | "REVER">("TODOS");
  const [engineFilter, setEngineFilter] = useState<"TODOS" | "DROOLS" | "PROLOG">("TODOS");
  const [searchQuery, setSearchQuery] = useState("");
  const [debouncedSearchQuery, setDebouncedSearchQuery] = useState("");
  const [page, setPage] = useState<number>(0);
  const [pageSize, setPageSize] = useState<number>(10);
  const [totalPaginas, setTotalPaginas] = useState<number>(1);
  const [totalGeral, setTotalGeral] = useState<number | null>(null);

  const [inferences, setInferences] = useState<InferenciaItem[]>([]);
  const [totalElementos, setTotalElementos] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const [selectedInference, setSelectedInference] = useState<InferenciaItem | null>(null);
  const [comparingPedidoId, setComparingPedidoId] = useState<string | null>(null);
  const [seeding, setSeeding] = useState<boolean>(false);

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearchQuery(searchQuery);
      setPage(0);
    }, 300);
    return () => clearTimeout(timer);
  }, [searchQuery]);

  const handleEngineFilterChange = (val: "TODOS" | "DROOLS" | "PROLOG") => {
    setEngineFilter(val);
    setPage(0);
  };

  const handleOutcomeFilterChange = (val: "TODOS" | "PERMITIR" | "TROCA" | "RECUSAR" | "REVER") => {
    setOutcomeFilter(val);
    setPage(0);
  };

  const fetchInferences = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      params.set("pagina", String(page));
      params.set("tamanho", String(pageSize));

      if (engineFilter !== "TODOS") {
        params.set("motor", engineFilter);
      }
      if (outcomeFilter !== "TODOS") {
        params.set("elegibilidade", outcomeFilter);
      }
      if (debouncedSearchQuery.trim()) {
        params.set("busca", debouncedSearchQuery.trim());
      }

      const res = await fetch(`/api/avaliacoes?${params.toString()}`);
      if (!res.ok) {
        const errJson = await res.json().catch(() => null);
        throw new Error(errJson?.error?.message || errJson?.detail || `Erro ${res.status} ao carregar histórico.`);
      }
      const data: PaginaResponse<InferenciaItem> = await res.json();
      setInferences(data.conteudo || []);
      setTotalElementos(data.totalElementos ?? (data.conteudo || []).length);
      setTotalPaginas(Math.max(1, data.totalPaginas ?? Math.ceil((data.totalElementos || 1) / pageSize)));

      if (engineFilter === "TODOS" && outcomeFilter === "TODOS" && !debouncedSearchQuery.trim()) {
        setTotalGeral(data.totalElementos);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Falha ao consultar registos de decisões.");
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, engineFilter, outcomeFilter, debouncedSearchQuery]);

  useEffect(() => {
    fetchInferences();
  }, [fetchInferences]);

  const handleSeed = async () => {
    setSeeding(true);
    setError(null);
    try {
      const res = await fetch("/api/avaliacoes/seed", { method: "POST" });
      if (!res.ok) {
        throw new Error(`Erro ${res.status} ao semear cenários.`);
      }
      setPage(0);
      await fetchInferences();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Falha ao semear cenários de teste.");
    } finally {
      setSeeding(false);
    }
  };

  const startItem = totalElementos === 0 ? 0 : page * pageSize + 1;
  const endItem = Math.min((page + 1) * pageSize, totalElementos);

  const getOutcomeBadge = (elegibilidade: InferenciaItem["elegibilidade"]) => {
    switch (elegibilidade) {
      case "PERMITIR":
        return {
          label: "Aprovada",
          badgeClass: "bg-emerald-50 text-emerald-800 border border-emerald-200/90",
          icon: "check_circle",
          iconColor: "text-emerald-600",
          accentBorder: "border-l-emerald-500",
          containerBg: "bg-emerald-100 text-emerald-700 border-emerald-200",
        };
      case "TROCA":
        return {
          label: "Troca no Balcão",
          badgeClass: "bg-blue-50 text-blue-800 border border-blue-200/90",
          icon: "swap_horiz",
          iconColor: "text-blue-600",
          accentBorder: "border-l-blue-500",
          containerBg: "bg-blue-100 text-blue-700 border-blue-200",
        };
      case "RECUSAR":
        return {
          label: "Recusada",
          badgeClass: "bg-rose-50 text-rose-800 border border-rose-200/90",
          icon: "cancel",
          iconColor: "text-rose-600",
          accentBorder: "border-l-rose-500",
          containerBg: "bg-rose-100 text-rose-700 border-rose-200",
        };
      case "REVER":
      default:
        return {
          label: "Revisão Gerência",
          badgeClass: "bg-amber-50 text-amber-800 border border-amber-200/90",
          icon: "warning",
          iconColor: "text-amber-600",
          accentBorder: "border-l-amber-500",
          containerBg: "bg-amber-100 text-amber-700 border-amber-200",
        };
    }
  };

  return (
    <div className="min-h-screen flex flex-col justify-between bg-surface text-on-surface">
      {/* Top Fixed Navbar */}
      <Navbar
        activeRoute="decisoes"
        operatorName="Tiago Silva"
        operatorRole="Operador N2"
        streakCount={18}
      />

      {/* Main Content Area */}
      <main
        id="main-content"
        className="w-full max-w-7xl mx-auto px-4 sm:px-6 md:px-8 pt-28 pb-16 flex-1 flex flex-col gap-6"
      >
        {/* Page Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border-card/60 pb-6">
          <div className="flex flex-col">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[28px]">
                history_edu
              </span>
              <h1 className="font-display font-headline-lg text-2xl sm:text-3xl font-extrabold text-on-surface tracking-tight">
                Decisões &amp; Histórico Pericial
              </h1>
            </div>
            <p className="font-sans font-body-md text-on-surface-variant text-sm mt-1">
              Registo auditável e persistido de todas as inferências deliberadas pelos motores Drools e Prolog.
            </p>
          </div>

          <div className="flex items-center gap-2.5 self-start sm:self-auto">

            <Link
              href="/novo-atendimento"
              className="btn-tactile-primary px-5 py-2.5 text-xs font-sans font-semibold flex items-center justify-center gap-2 cursor-pointer shadow-xs"
            >
              <span className="material-symbols-outlined text-[18px]">add</span>
              <span>Novo Atendimento</span>
            </Link>
          </div>
        </div>

        {/* Filter and Search Bar */}
        <div className="flex flex-col gap-3.5 bg-white p-4 sm:p-5 rounded-2xl border border-border-card shadow-xs">
          {/* Search Input */}
          <div className="relative w-full">
            <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-on-surface-variant text-[20px]">
              search
            </span>
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Pesquisar por caso (#CENARIO-01), produto, código de regra (PC-001) ou motivo..."
              className="font-sans w-full pl-10 pr-10 py-2.5 rounded-xl bg-surface-container-low text-on-surface text-sm font-medium border border-border-card/70 focus:outline-2 focus:outline-primary placeholder:text-on-surface-variant/60"
            />
            {searchQuery && (
              <button
                type="button"
                onClick={() => {
                  setSearchQuery("");
                  setDebouncedSearchQuery("");
                  setPage(0);
                }}
                aria-label="Limpar pesquisa"
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-on-surface text-xs font-bold cursor-pointer"
              >
                ✕
              </button>
            )}
          </div>

          {/* Dual-Axis Filters: Motor & Resultado */}
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 pt-2 border-t border-slate-100">
            {/* Engine Filter */}
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold text-slate-500 uppercase tracking-wider shrink-0">
                Motor:
              </span>
              <div className="inline-flex items-center p-1 bg-surface-container-low rounded-lg border border-border-card/50 text-xs">
                <button
                  type="button"
                  onClick={() => handleEngineFilterChange("TODOS")}
                  className={`px-3 py-1 rounded-md transition-colors font-medium cursor-pointer ${
                    engineFilter === "TODOS"
                      ? "bg-white text-slate-900 font-bold shadow-xs"
                      : "text-slate-600 hover:text-slate-900"
                  }`}
                >
                  Todos
                </button>
                <button
                  type="button"
                  onClick={() => handleEngineFilterChange("DROOLS")}
                  className={`px-3 py-1 rounded-md transition-colors font-medium flex items-center gap-1.5 cursor-pointer ${
                    engineFilter === "DROOLS"
                      ? "bg-indigo-600 text-white font-bold shadow-xs"
                      : "text-indigo-700 hover:bg-indigo-50"
                  }`}
                >
                  <span className="material-symbols-outlined text-[14px]">account_tree</span>
                  <span>Drools</span>
                </button>
                <button
                  type="button"
                  onClick={() => handleEngineFilterChange("PROLOG")}
                  className={`px-3 py-1 rounded-md transition-colors font-medium flex items-center gap-1.5 cursor-pointer ${
                    engineFilter === "PROLOG"
                      ? "bg-emerald-600 text-white font-bold shadow-xs"
                      : "text-emerald-700 hover:bg-emerald-50"
                  }`}
                >
                  <span className="material-symbols-outlined text-[14px]">schema</span>
                  <span>Prolog</span>
                </button>
              </div>
            </div>

            {/* Outcome Filter */}
            <div className="flex items-center gap-2 overflow-x-auto pb-1 md:pb-0">
              <span className="text-xs font-bold text-slate-500 uppercase tracking-wider shrink-0">
                Resultado:
              </span>
              <div
                role="radiogroup"
                aria-label="Filtrar por resultado"
                className="flex items-center gap-1 p-1 bg-surface-container-low rounded-lg border border-border-card/50 text-xs"
              >
                {(
                  [
                    { key: "TODOS", label: "Todas" },
                    { key: "PERMITIR", label: "Aprovadas" },
                    { key: "TROCA", label: "Trocas" },
                    { key: "RECUSAR", label: "Recusadas" },
                    { key: "REVER", label: "Revisão" },
                  ] as const
                ).map((opt) => {
                  const isSelected = outcomeFilter === opt.key;
                  return (
                    <button
                      key={opt.key}
                      type="button"
                      role="radio"
                      aria-checked={isSelected}
                      onClick={() => handleOutcomeFilterChange(opt.key)}
                      className={`px-3 py-1 rounded-md transition-all cursor-pointer whitespace-nowrap font-medium ${
                        isSelected
                          ? "bg-slate-900 text-white font-bold shadow-xs"
                          : "text-slate-600 hover:bg-surface-container hover:text-slate-900"
                      }`}
                    >
                      {opt.label}
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        </div>

        {/* Error Alert */}
        {error && (
          <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-900 flex items-center justify-between gap-3 text-xs sm:text-sm">
            <div className="flex items-center gap-2.5">
              <span className="material-symbols-outlined text-rose-600 text-[20px]">
                error
              </span>
              <span>{error}</span>
            </div>
            <button
              type="button"
              onClick={fetchInferences}
              className="px-3 py-1 rounded-md bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs cursor-pointer transition-colors shadow-xs"
            >
              Tentar Novamente
            </button>
          </div>
        )}

        {/* Loading Skeletons */}
        {loading && inferences.length === 0 && (
          <div className="flex flex-col gap-3">
            {[1, 2, 3, 4, 5].map((n) => (
              <div
                key={n}
                className="p-4 sm:p-5 bg-white border border-border-card rounded-2xl flex flex-col gap-3 animate-pulse border-l-4 border-l-slate-200"
              >
                <div className="flex items-center justify-between gap-3">
                  <div className="flex items-center gap-2">
                    <div className="w-20 h-5 bg-slate-200 rounded-md" />
                    <div className="w-48 h-5 bg-slate-200 rounded" />
                    <div className="w-20 h-5 bg-slate-100 rounded-full" />
                  </div>
                  <div className="w-16 h-6 bg-slate-200 rounded" />
                </div>
                <div className="w-3/4 h-4 bg-slate-100 rounded" />
                <div className="pt-2 border-t border-slate-100 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-20 h-3 bg-slate-100 rounded" />
                    <div className="w-28 h-3 bg-slate-100 rounded" />
                    <div className="w-16 h-3 bg-slate-100 rounded" />
                  </div>
                  <div className="w-20 h-6 bg-slate-200 rounded-lg" />
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Inferences List */}
        {!error && inferences.length > 0 && (
          <div
            className={`flex flex-col gap-3 transition-opacity duration-150 ${
              loading ? "opacity-60 pointer-events-none" : "opacity-100"
            }`}
          >
            {inferences.map((item) => {
              const meta = getOutcomeBadge(item.elegibilidade);
              const isDrools = item.motor === "DROOLS";
              const primaryRule = item.regrasDisparadas[0];

              return (
                <div
                  key={item.id}
                  onClick={() => setSelectedInference(item)}
                  className={`group bg-white border border-border-card rounded-2xl p-4 sm:p-5 transition-all duration-200 hover:shadow-md hover:border-slate-300 cursor-pointer border-l-4 ${meta.accentBorder} flex flex-col gap-2.5`}
                >
                  {/* Top Row: Case ID, Product Name, Status Badge, Deliberated Value */}
                  <div className="flex items-start justify-between gap-3 min-w-0">
                    <div className="flex flex-wrap items-center gap-2 min-w-0">
                      <span className="font-mono tabular-nums font-bold text-xs text-slate-700 bg-slate-100 px-2 py-0.5 rounded-md shrink-0">
                        #{item.pedidoId}
                      </span>

                      <h3 className="text-sm sm:text-base font-sans font-bold text-slate-900 group-hover:text-primary transition-colors truncate">
                        {item.produtoNome}
                      </h3>

                      <span
                        className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold ${meta.badgeClass} shrink-0`}
                      >
                        <span className="material-symbols-outlined text-[15px]">
                          {meta.icon}
                        </span>
                        <span>{meta.label}</span>
                      </span>
                    </div>

                    <div className="text-right shrink-0">
                      <span className="font-sans tabular-nums text-lg sm:text-xl font-extrabold text-slate-900 tracking-tight">
                        {item.valorDevolucao.toFixed(2)} €
                      </span>
                    </div>
                  </div>

                  {/* Middle Row: Human-Readable Reason with subtle rule chip */}
                  <div className="flex items-start gap-2 text-xs sm:text-sm text-slate-600 leading-relaxed">
                    {primaryRule ? (
                      <>
                        <span className="inline-block mt-0.5 shrink-0 px-1.5 py-0.5 rounded bg-slate-100 text-slate-600 font-mono tabular-nums text-[11px] font-semibold">
                          {primaryRule.codigo}
                        </span>
                        <p className="line-clamp-2 text-slate-700">
                          {primaryRule.mensagem || primaryRule.nome}
                        </p>
                      </>
                    ) : (
                      <p className="text-slate-500 italic">
                        Deliberação automática do motor sem notas adicionais.
                      </p>
                    )}
                  </div>

                  {/* Bottom Row: Context Metadata and Quick Actions */}
                  <div className="mt-1 pt-3 border-t border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs text-slate-500">
                    <div className="flex flex-wrap items-center gap-3">
                      <span className="inline-flex items-center gap-1 text-slate-500">
                        <span className="material-symbols-outlined text-[15px] text-slate-400">
                          schedule
                        </span>
                        <span>{formatRelativeDate(item.executadoEm)}</span>
                      </span>

                      <span className="inline-flex items-center gap-1 text-slate-500">
                        <span className="material-symbols-outlined text-[15px] text-slate-400">
                          payments
                        </span>
                        <span>{label(item.meioReembolso || "MEIO_ORIGINAL")}</span>
                      </span>

                      <span
                        className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-[11px] font-mono tabular-nums font-medium border ${
                          isDrools
                            ? "bg-indigo-50/80 text-indigo-700 border-indigo-200/60"
                            : "bg-emerald-50/80 text-emerald-700 border-emerald-200/60"
                        }`}
                      >
                        <span className="material-symbols-outlined text-[13px]">
                          {isDrools ? "account_tree" : "schema"}
                        </span>
                        <span>{isDrools ? "Drools" : "Prolog"}</span>
                        <span className="text-slate-400 font-mono tabular-nums">· {item.duracaoMs} ms</span>
                      </span>

                      <span className="inline-flex items-center gap-1 text-[11px] text-slate-400">
                        <span className="material-symbols-outlined text-[14px]">
                          rule_settings
                        </span>
                        <span>
                          {item.regrasDisparadas.length} regra{item.regrasDisparadas.length === 1 ? "" : "s"}
                        </span>
                      </span>
                    </div>

                    <div className="flex items-center gap-2 self-end sm:self-auto shrink-0">
                      {item.temOutroMotor && (
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            setComparingPedidoId(item.pedidoId);
                          }}
                          title={`Confrontar Drools e Prolog para #${item.pedidoId}`}
                          className="px-2.5 py-1 rounded-lg bg-indigo-50 hover:bg-indigo-100 text-indigo-700 border border-indigo-200/80 text-xs font-semibold flex items-center gap-1 transition-colors cursor-pointer"
                        >
                          <span className="material-symbols-outlined text-[15px]">
                            compare_arrows
                          </span>
                          <span>Comparar</span>
                        </button>
                      )}

                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          setSelectedInference(item);
                        }}
                        className="px-3 py-1 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-semibold flex items-center gap-1 transition-colors cursor-pointer"
                      >
                        <span>Ver Veredito</span>
                        <span className="material-symbols-outlined text-[15px]">
                          arrow_forward
                        </span>
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Pagination Controls */}
        {!error && totalElementos > 0 && (
          <div className="flex flex-col sm:flex-row items-center justify-between gap-3 p-4 sm:p-5 bg-white border border-border-card rounded-2xl shadow-xs text-xs">
            {/* Left: Range and Items Per Page Selector */}
            <div className="flex items-center gap-3 text-slate-500 w-full sm:w-auto justify-between sm:justify-start">
              <span>
                A mostrar <strong className="text-slate-900 font-semibold">{startItem}–{endItem}</strong> de{" "}
                <strong className="text-slate-900 font-semibold">{totalElementos}</strong> deliberações
              </span>

              <div className="flex items-center gap-1.5 border-l border-slate-200 pl-3">
                <span className="text-slate-400 hidden md:inline">Por pág:</span>
                <div className="inline-flex rounded-lg bg-slate-100 p-0.5">
                  {[10, 20, 50].map((size) => (
                    <button
                      key={size}
                      type="button"
                      disabled={loading}
                      onClick={() => {
                        setPageSize(size);
                        setPage(0);
                      }}
                      className={`px-2 py-0.5 rounded-md font-medium transition-colors cursor-pointer ${
                        pageSize === size
                          ? "bg-white text-slate-900 font-bold shadow-2xs"
                          : "text-slate-600 hover:text-slate-900"
                      }`}
                    >
                      {size}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Right: Navigation Controls */}
            <nav aria-label="Paginação de histórico pericial" className="flex items-center gap-1">
              {/* First Page */}
              <button
                type="button"
                onClick={() => setPage(0)}
                disabled={page === 0 || loading}
                title="Primeira página"
                aria-label="Primeira página"
                className="p-1.5 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100 disabled:opacity-30 disabled:pointer-events-none transition-colors cursor-pointer"
              >
                <span className="material-symbols-outlined text-[18px]">first_page</span>
              </button>

              {/* Previous Page */}
              <button
                type="button"
                onClick={() => setPage((p) => Math.max(0, p - 1))}
                disabled={page === 0 || loading}
                title="Página anterior"
                aria-label="Página anterior"
                className="p-1.5 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100 disabled:opacity-30 disabled:pointer-events-none transition-colors cursor-pointer"
              >
                <span className="material-symbols-outlined text-[18px]">chevron_left</span>
              </button>

              {/* Mobile Page Indicator */}
              <span className="sm:hidden px-2 text-slate-600 font-medium">
                Pág. <strong className="text-slate-900 font-bold">{page + 1}</strong> de {totalPaginas}
              </span>

              {/* Desktop Page Numbers */}
              <div className="hidden sm:flex items-center gap-1">
                {getPageNumbers(page, totalPaginas).map((p, idx) => {
                  if (p === "...") {
                    return (
                      <span key={`ellipsis-${idx}`} className="px-1.5 text-slate-400 select-none">
                        …
                      </span>
                    );
                  }
                  const isCurrent = p === page + 1;
                  return (
                    <button
                      key={p}
                      type="button"
                      disabled={loading}
                      onClick={() => setPage(p - 1)}
                      aria-current={isCurrent ? "page" : undefined}
                      aria-label={`Página ${p}`}
                      className={`min-w-7 h-7 px-2 rounded-lg text-xs transition-colors cursor-pointer flex items-center justify-center ${
                        isCurrent
                          ? "bg-slate-900 text-white font-bold shadow-xs"
                          : "text-slate-600 hover:text-slate-900 hover:bg-slate-100 font-medium"
                      }`}
                    >
                      {p}
                    </button>
                  );
                })}
              </div>

              {/* Next Page */}
              <button
                type="button"
                onClick={() => setPage((p) => Math.min(totalPaginas - 1, p + 1))}
                disabled={page >= totalPaginas - 1 || loading}
                title="Página seguinte"
                aria-label="Página seguinte"
                className="p-1.5 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100 disabled:opacity-30 disabled:pointer-events-none transition-colors cursor-pointer"
              >
                <span className="material-symbols-outlined text-[18px]">chevron_right</span>
              </button>

              {/* Last Page */}
              <button
                type="button"
                onClick={() => setPage(totalPaginas - 1)}
                disabled={page >= totalPaginas - 1 || loading}
                title="Última página"
                aria-label="Última página"
                className="p-1.5 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100 disabled:opacity-30 disabled:pointer-events-none transition-colors cursor-pointer"
              >
                <span className="material-symbols-outlined text-[18px]">last_page</span>
              </button>
            </nav>
          </div>
        )}

        {/* Empty State Card */}
        {!loading && !error && inferences.length === 0 && (
          <div className="card-tactile p-12 bg-white rounded-3xl border-2 border-dashed border-border-card flex flex-col items-center justify-center text-center gap-4 animate-in fade-in duration-200">
            <div className="w-16 h-16 rounded-3xl bg-surface-container text-on-surface-variant flex items-center justify-center shadow-xs">
              <span className="material-symbols-outlined text-[36px]">inbox</span>
            </div>
            <div className="flex flex-col gap-1 max-w-md">
              <h3 className="font-sans text-on-surface text-lg font-bold">
                Nenhum atendimento encontrado
              </h3>
              <p className="font-sans text-on-surface-variant text-xs sm:text-sm">
                Não existem registos de devolução ou troca correspondentes ao filtro ou termo de pesquisa indicado.
              </p>
            </div>
            <div className="flex flex-wrap items-center justify-center gap-3 mt-2">
              <button
                type="button"
                onClick={() => {
                  setOutcomeFilter("TODOS");
                  setEngineFilter("TODOS");
                  setSearchQuery("");
                  setDebouncedSearchQuery("");
                  setPage(0);
                }}
                className="px-4 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-sans font-semibold text-xs transition-colors cursor-pointer"
              >
                Limpar Todos os Filtros
              </button>
              <button
                type="button"
                onClick={handleSeed}
                disabled={seeding}
                className="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-sans font-semibold text-xs flex items-center gap-2 cursor-pointer shadow-xs disabled:opacity-50"
              >
                <span className="material-symbols-outlined text-[18px]">
                  {seeding ? "sync" : "cloud_download"}
                </span>
                <span>{seeding ? "A Semear..." : "Semear 10 Cenários"}</span>
              </button>
              <Link
                href="/novo-atendimento"
                className="btn-tactile-primary px-5 py-2.5 text-xs font-sans font-semibold cursor-pointer"
              >
                Iniciar Novo Caso
              </Link>
            </div>
          </div>
        )}
      </main>

      {/* Decision Detail Modal */}
      {selectedInference && (
        <div
          role="dialog"
          aria-modal="true"
          aria-labelledby="modal-inference-title"
          className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 animate-in fade-in duration-150"
        >
          <div className="card-tactile bg-white max-w-lg w-full p-6 sm:p-7 rounded-3xl flex flex-col gap-5 border border-border-card shadow-2xl max-h-[90vh] overflow-y-auto">
            {/* Header */}
            <div className="flex items-start justify-between border-b border-slate-100 pb-3">
              <div className="flex items-center gap-3">
                <div
                  className={`w-11 h-11 rounded-2xl flex items-center justify-center ${
                    getOutcomeBadge(selectedInference.elegibilidade).containerBg
                  }`}
                >
                  <span className="material-symbols-outlined text-[24px]">
                    {getOutcomeBadge(selectedInference.elegibilidade).icon}
                  </span>
                </div>
                <div className="flex flex-col">
                  <div className="flex items-center gap-2">
                    <h3
                      id="modal-inference-title"
                      className="font-mono tabular-nums text-base sm:text-lg font-bold text-on-surface"
                    >
                      #{selectedInference.pedidoId}
                    </h3>
                    <span
                      className={`px-2 py-0.5 rounded text-[10px] font-mono tabular-nums font-bold border ${
                        selectedInference.motor === "DROOLS"
                          ? "bg-indigo-50 text-indigo-700 border-indigo-200"
                          : "bg-emerald-50 text-emerald-700 border-emerald-200"
                      }`}
                    >
                      {selectedInference.motor}
                    </span>
                  </div>
                  <span className="text-xs text-on-surface-variant font-medium font-sans">
                    {selectedInference.produtoNome}
                  </span>
                </div>
              </div>

              <button
                type="button"
                onClick={() => setSelectedInference(null)}
                aria-label="Fechar"
                className="w-8 h-8 rounded-full bg-surface-container flex items-center justify-center text-on-surface-variant hover:text-on-surface cursor-pointer"
              >
                ✕
              </button>
            </div>

            {/* Verdict Summary Box */}
            <div className="p-4 rounded-2xl bg-surface-container-low border border-border-card flex flex-col gap-2 text-xs font-sans">
              <div className="flex justify-between">
                <span className="text-on-surface-variant font-semibold">Motor &amp; Versão:</span>
                <span className="font-mono tabular-nums font-bold text-on-surface">
                  {selectedInference.motor} ({selectedInference.duracaoMs} ms)
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-on-surface-variant font-semibold">Data / Hora:</span>
                <span className="font-mono tabular-nums font-bold text-on-surface">
                  {new Date(selectedInference.executadoEm).toLocaleString("pt-PT")}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-on-surface-variant font-semibold">Tipo Transação:</span>
                <span className="font-bold text-on-surface">
                  {selectedInference.tipoTransacao || "N/A"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-on-surface-variant font-semibold">Meio Reembolso:</span>
                <span className="font-bold text-on-surface">
                  {selectedInference.meioReembolso || "N/A"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-on-surface-variant font-semibold">Valor da Transação:</span>
                <span className="font-sans tabular-nums font-extrabold text-primary text-sm">
                  {selectedInference.valorDevolucao.toFixed(2)} €
                </span>
              </div>
            </div>

            {/* Fired Rules List */}
            <div className="flex flex-col gap-2 font-sans">
              <span className="font-label-md text-xs font-bold uppercase tracking-wider text-on-surface-variant">
                Regras e Deduções Acionadas ({selectedInference.regrasDisparadas.length})
              </span>
              <div className="flex flex-col gap-2 max-h-52 overflow-y-auto pr-1">
                {selectedInference.regrasDisparadas.map((r, idx) => (
                  <div
                    key={idx}
                    className="p-3 rounded-xl bg-slate-50 border border-slate-100 flex flex-col gap-1 text-xs"
                  >
                    <div className="flex items-center justify-between">
                      <span className="font-bold font-mono tabular-nums text-slate-900">{r.codigo}</span>
                      {r.modulo && (
                        <span className="px-2 py-0.5 rounded text-[10px] bg-white border border-slate-200 text-slate-500 font-semibold font-mono tabular-nums">
                          {r.modulo}
                        </span>
                      )}
                    </div>
                    {r.nome && <span className="font-semibold text-slate-700">{r.nome}</span>}
                    {r.mensagem && (
                      <p className="text-slate-600 leading-relaxed">{r.mensagem}</p>
                    )}
                  </div>
                ))}
              </div>
            </div>

            {/* Actions */}
            <div className="flex items-center justify-between gap-3 pt-3 border-t border-slate-100">
              {selectedInference.temOutroMotor ? (
                <button
                  type="button"
                  onClick={() => {
                    const id = selectedInference.pedidoId;
                    setSelectedInference(null);
                    setComparingPedidoId(id);
                  }}
                  className="px-3.5 py-2 rounded-xl bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-sans font-semibold text-xs border border-indigo-200 flex items-center gap-1.5 transition-colors cursor-pointer"
                >
                  <span className="material-symbols-outlined text-[16px]">compare_arrows</span>
                  <span>Confrontar Motores</span>
                </button>
              ) : (
                <div />
              )}

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => window.print()}
                  className="btn-tactile-secondary px-4 py-2 text-xs font-sans font-semibold flex items-center gap-1.5 cursor-pointer"
                >
                  <span className="material-symbols-outlined text-[16px]">print</span>
                  <span>Imprimir</span>
                </button>
                <button
                  type="button"
                  onClick={() => setSelectedInference(null)}
                  className="btn-tactile-primary px-5 py-2 text-xs font-sans font-semibold cursor-pointer"
                >
                  Fechar
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Case Comparison Modal */}
      <CaseComparisonModal
        pedidoId={comparingPedidoId}
        isOpen={Boolean(comparingPedidoId)}
        onClose={() => setComparingPedidoId(null)}
      />

      {/* Bottom Status Footer */}
      <StatusFooter droolsStatus="online" prologStatus="online" />
    </div>
  );
}
