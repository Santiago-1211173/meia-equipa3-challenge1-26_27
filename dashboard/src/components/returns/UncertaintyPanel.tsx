"use client";

import React, { useState } from "react";
import { api, ApiClientError } from "@/client/api";
import { useLocale, type Locale } from "@/contexts/LocaleContext";
import {
  CLASSES_POR_HIPOTESE,
  avisoDemonstrativo,
  classificacaoLabel,
  classificacaoTone,
  escalaDoGrau,
  formatarGrau,
  hipoteseIcon,
  hipoteseLabel,
  hipotesePorArtigo,
  metodoLabel,
  notaDoMetodo,
  type ToneIncerteza,
} from "@/config/uncertaintyLabels";
import type {
  ClassificacaoIncerteza,
  ExplicacaoConclusaoResponse,
  ExplicacaoPorqueNaoConclusaoResponse,
  GrauCrencaDto,
  ParametrosIncertezaResponse,
} from "@/types/returns";

export interface UncertaintyPanelProps {
  graus: GrauCrencaDto[];
  /** Avaliação no motor Drools; sem ela não há "Como?" nem "Porque não?". */
  evaluationId?: string | null;
  /** Prefixo do proxy do motor (ex.: /api/returns). */
  base?: string;
  /** Versão reduzida (histórico): sem explicações nem parâmetros. */
  compact?: boolean;
}

const TONE: Record<ToneIncerteza, { badge: string; icon: string; bar: string }> = {
  success: {
    badge: "bg-emerald-50 text-emerald-700 border-emerald-200",
    icon: "bg-emerald-50 text-emerald-700 border-emerald-200/60",
    bar: "bg-emerald-500",
  },
  warning: {
    badge: "bg-amber-50 text-amber-700 border-amber-200",
    icon: "bg-amber-50 text-amber-700 border-amber-200/60",
    bar: "bg-amber-500",
  },
  danger: {
    badge: "bg-rose-50 text-rose-700 border-rose-200",
    icon: "bg-rose-50 text-rose-700 border-rose-200/60",
    bar: "bg-rose-500",
  },
  info: {
    badge: "bg-indigo-50 text-indigo-700 border-indigo-200",
    icon: "bg-indigo-50 text-indigo-700 border-indigo-200/60",
    bar: "bg-indigo-500",
  },
};

function apiLocale(locale: Locale): string {
  return locale === "en" ? "locale=en" : "locale=pt-PT";
}

function mensagemDeErro(err: unknown, locale: Locale): string {
  if (err instanceof ApiClientError || err instanceof Error) return err.message;
  return locale === "en" ? "Could not load the explanation." : "Não foi possível obter a explicação.";
}

function numero(valor: number, locale: Locale, casas = 2): string {
  return valor.toLocaleString(locale === "en" ? "en-US" : "pt-PT", {
    minimumFractionDigits: casas,
    maximumFractionDigits: casas,
  });
}

/** Barra com a posição do valor na escala do grau (o fator de certeza é centrado em 0). */
function Escala({ grau, tone }: { grau: GrauCrencaDto; tone: ToneIncerteza }) {
  const { min, max } = escalaDoGrau(grau);
  const pos = Math.min(1, Math.max(0, (grau.valor - min) / (max - min)));
  const zero = Math.min(1, Math.max(0, (0 - min) / (max - min)));
  const left = Math.min(pos, zero);
  const width = Math.abs(pos - zero);
  return (
    <div className="flex flex-col gap-1" aria-hidden="true">
      <div className="relative h-1.5 rounded-full bg-slate-100 overflow-hidden">
        <div
          className={`absolute top-0 bottom-0 rounded-full ${TONE[tone].bar}`}
          style={{ left: `${left * 100}%`, width: `${Math.max(width * 100, 1.5)}%` }}
        />
        {min < 0 && <div className="absolute top-0 bottom-0 w-px bg-slate-300" style={{ left: `${zero * 100}%` }} />}
      </div>
      <div className="flex justify-between font-mono tabular-nums text-[10px] text-slate-400">
        <span>{min}</span>
        <span>{max}</span>
      </div>
    </div>
  );
}

function GrauCard({
  grau,
  evaluationId,
  base,
  compact,
  locale,
}: {
  grau: GrauCrencaDto;
  evaluationId?: string | null;
  base: string;
  compact: boolean;
  locale: Locale;
}) {
  const isEn = locale === "en";
  const tone = classificacaoTone(grau.classificacao);
  const nota = notaDoMetodo(grau.metodo, locale);
  const porArtigo = hipotesePorArtigo(grau.hipotese);
  const outrasClasses = grau.hipotese
    ? CLASSES_POR_HIPOTESE[grau.hipotese].filter((c) => c !== grau.classificacao)
    : [];

  const [aberto, setAberto] = useState<"como" | ClassificacaoIncerteza | null>(null);
  const [aCarregar, setACarregar] = useState(false);
  const [erro, setErro] = useState<string | null>(null);
  const [como, setComo] = useState<ExplicacaoConclusaoResponse | null>(null);
  const [porqueNao, setPorqueNao] = useState<ExplicacaoPorqueNaoConclusaoResponse | null>(null);

  const podeExplicar = !compact && Boolean(evaluationId && grau.hipotese);
  const conclusao = `INCERTEZA.${grau.hipotese}`;
  // O motor só aceita o artigo nas hipóteses calculadas por artigo
  const artigo = porArtigo && grau.artigoId ? `&artigo=${encodeURIComponent(grau.artigoId)}` : "";

  const explicar = async (alvo: "como" | ClassificacaoIncerteza) => {
    if (aberto === alvo) {
      setAberto(null);
      return;
    }
    setAberto(alvo);
    setErro(null);
    setACarregar(true);
    try {
      if (alvo === "como") {
        setComo(
          await api<ExplicacaoConclusaoResponse>(
            `${base}/avaliacoes/${evaluationId}/explicacoes/como?conclusao=${encodeURIComponent(conclusao)}${artigo}&${apiLocale(locale)}`
          )
        );
      } else {
        setPorqueNao(
          await api<ExplicacaoPorqueNaoConclusaoResponse>(
            `${base}/avaliacoes/${evaluationId}/explicacoes/porque-nao?conclusao=${encodeURIComponent(`${conclusao}:${alvo}`)}${artigo}&${apiLocale(locale)}`
          )
        );
      }
    } catch (err: unknown) {
      setErro(mensagemDeErro(err, locale));
    } finally {
      setACarregar(false);
    }
  };

  const contribuicoesAplicadas = grau.contribuicoes.filter((c) => c.aplicada).length;

  return (
    <div className="p-4 bg-white border border-slate-200 rounded-xl shadow-2xs hover:border-slate-300 transition-all flex flex-col gap-3">
      {/* Cabeçalho: hipótese, artigo e método */}
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-center gap-3 min-w-0">
          <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 border ${TONE[tone].icon}`}>
            <span className="material-symbols-outlined text-[20px]">{hipoteseIcon(grau.hipotese)}</span>
          </div>
          <div className="flex flex-col min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h4 className="font-sans font-bold text-slate-900 text-sm tracking-tight leading-snug">
                {hipoteseLabel(grau.hipotese, locale)}
              </h4>
              {grau.artigoId && (
                <span className="font-mono tabular-nums text-[10px] font-bold text-slate-500 bg-slate-100 border border-slate-200 px-1.5 py-0.5 rounded">
                  {grau.artigoId}
                </span>
              )}
            </div>
            <span className="font-sans text-[11px] text-slate-500">
              {metodoLabel(grau.metodo, locale)}
              {nota && <span className="text-slate-400"> ({nota})</span>}
            </span>
          </div>
        </div>
        <div className="flex flex-col items-end shrink-0">
          <span className="font-sans tabular-nums text-xl font-bold text-slate-900 leading-none">
            {formatarGrau(grau, locale)}
          </span>
        </div>
      </div>

      <Escala grau={grau} tone={tone} />

      <div className="flex items-center justify-between gap-2 flex-wrap">
        <span className={`font-sans inline-flex px-2 py-0.5 rounded-md text-xs font-bold border ${TONE[tone].badge}`}>
          {classificacaoLabel(grau.classificacao, locale)}
        </span>
        {podeExplicar && (
          <button
            type="button"
            onClick={() => explicar("como")}
            aria-expanded={aberto === "como"}
            className={`font-sans px-2.5 py-1 rounded-lg border text-[11px] font-semibold flex items-center gap-1 transition-colors cursor-pointer ${aberto === "como"
                ? "bg-slate-900 border-slate-900 text-white"
                : "bg-white border-slate-200 text-slate-700 hover:bg-slate-50"
              }`}
          >
            <span className="material-symbols-outlined text-[14px]">account_tree</span>
            {isEn ? "How?" : "Como?"}
          </button>
        )}
      </div>

      {/* Contribuições: os passos do cálculo */}
      {grau.contribuicoes.length > 0 && (
        <details className="group rounded-lg bg-slate-50 border border-slate-100">
          <summary className="font-sans text-xs font-semibold text-slate-600 px-3 py-2 cursor-pointer select-none flex items-center justify-between gap-2 list-none">
            <span>
              {isEn ? "Contributions" : "Contribuições"}{" "}
              <span className="font-normal text-slate-400 tabular-nums">
                ({contribuicoesAplicadas}/{grau.contribuicoes.length} {isEn ? "applied" : "aplicadas"})
              </span>
            </span>
            <span className="material-symbols-outlined text-[16px] text-slate-400 transition-transform group-open:rotate-180">
              expand_more
            </span>
          </summary>
          <ul className="flex flex-col gap-1.5 px-3 pb-3">
            {grau.contribuicoes.map((c, idx) => (
              <li
                key={`${c.codigo}-${idx}`}
                className={`font-sans text-xs leading-relaxed flex items-start gap-2 ${c.aplicada ? "text-slate-700" : "text-slate-400"}`}
              >
                <span className="material-symbols-outlined text-[14px] mt-px shrink-0">
                  {c.aplicada ? "check_circle" : "remove_circle_outline"}
                </span>
                <span className="min-w-0">
                  <span className="font-mono tabular-nums font-bold">{c.codigo}</span> {c.descricao}{" "}
                  <span className="tabular-nums text-slate-400">· {numero(c.peso, locale)}</span>
                  {c.aplicada ? (
                    <span className="tabular-nums text-slate-500">
                      {" "}
                      ({numero(c.valorAntes, locale)} → {numero(c.valorDepois, locale)})
                    </span>
                  ) : (
                    c.motivoNaoAplicada && <span className="italic"> — {c.motivoNaoAplicada}</span>
                  )}
                </span>
              </li>
            ))}
          </ul>
        </details>
      )}

      {/* Porque não outra classificação? */}
      {podeExplicar && outrasClasses.length > 0 && (
        <div className="flex items-center gap-1.5 flex-wrap">
          <span className="font-sans text-[11px] text-slate-400">{isEn ? "Why not" : "Porque não"}</span>
          {outrasClasses.map((classe) => (
            <button
              key={classe}
              type="button"
              onClick={() => explicar(classe)}
              aria-expanded={aberto === classe}
              className={`font-sans px-2 py-0.5 rounded-md border text-[11px] font-semibold transition-colors cursor-pointer ${aberto === classe
                  ? "bg-slate-900 border-slate-900 text-white"
                  : "bg-white border-slate-200 text-slate-600 hover:bg-slate-50"
                }`}
            >
              {classificacaoLabel(classe, locale)}?
            </button>
          ))}
        </div>
      )}

      {/* Resultado da explicação pedida */}
      {aberto && (
        <div className="rounded-lg border border-slate-200 bg-slate-50/60 p-3 flex flex-col gap-2 animate-in fade-in duration-150">
          {aCarregar ? (
            <span className="font-sans text-xs text-slate-500 flex items-center gap-2">
              <span className="material-symbols-outlined text-[16px] animate-spin">progress_activity</span>
              {isEn ? "Asking the engine…" : "A consultar o motor…"}
            </span>
          ) : erro ? (
            <p role="alert" className="font-sans text-xs text-rose-700">
              {erro}
            </p>
          ) : aberto === "como" && como ? (
            <>
              {como.resumo && <p className="font-sans text-xs text-slate-700 leading-relaxed">{como.resumo}</p>}
              {como.caminho.length > 0 && (
                <ol className="flex flex-col gap-1 list-decimal list-inside font-sans text-xs text-slate-600 leading-relaxed">
                  {como.caminho.map((passo, idx) => (
                    <li key={idx}>{passo}</li>
                  ))}
                </ol>
              )}
              {como.regra && (
                <span className="font-sans text-[11px] text-slate-400">
                  {isEn ? "Rule" : "Regra"} <span className="font-mono font-bold text-slate-500">{como.regra}</span>
                </span>
              )}
            </>
          ) : aberto !== "como" && porqueNao ? (
            <>
              {porqueNao.resumo && <p className="font-sans text-xs text-slate-700 leading-relaxed">{porqueNao.resumo}</p>}
              {porqueNao.propostaPor.length > 0 && (
                <div className="flex flex-col gap-1">
                  <span className="font-sans text-[11px] font-semibold text-slate-500">
                    {isEn ? "What would change the classification" : "O que mudaria a classificação"}
                  </span>
                  <ul className="flex flex-col gap-1 font-sans text-xs text-slate-600 leading-relaxed">
                    {porqueNao.propostaPor.map((item, idx) => (
                      <li key={idx} className="flex items-start gap-1.5">
                        <span className="material-symbols-outlined text-[14px] text-slate-400 mt-px">arrow_right</span>
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </>
          ) : null}
        </div>
      )}
    </div>
  );
}

/** Pesos e limiares em vigor, lidos do motor (nunca escritos no dashboard). */
function Parametros({ base, locale }: { base: string; locale: Locale }) {
  const isEn = locale === "en";
  const [parametros, setParametros] = useState<ParametrosIncertezaResponse | null>(null);
  const [aCarregar, setACarregar] = useState(false);
  const [erro, setErro] = useState<string | null>(null);

  const carregar = async () => {
    if (parametros || aCarregar) return;
    setACarregar(true);
    setErro(null);
    try {
      setParametros(await api<ParametrosIncertezaResponse>(`${base}/incerteza/parametros`));
    } catch (err: unknown) {
      setErro(mensagemDeErro(err, locale));
    } finally {
      setACarregar(false);
    }
  };

  const tabela = (titulo: string, valores: Record<string, number>) =>
    Object.keys(valores).length > 0 && (
      <div className="flex flex-col gap-1">
        <span className="font-sans text-[11px] font-semibold text-slate-500">{titulo}</span>
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-1.5">
          {Object.entries(valores).map(([chave, valor]) => (
            <div key={chave} className="flex items-center justify-between gap-2 px-2 py-1 rounded-md bg-white border border-slate-100">
              <span className="font-mono text-[11px] text-slate-500 truncate" title={chave}>
                {chave}
              </span>
              <span className="font-mono tabular-nums text-[11px] font-bold text-slate-800">{numero(valor, locale)}</span>
            </div>
          ))}
        </div>
      </div>
    );

  return (
    <details
      className="group rounded-xl bg-slate-50 border border-slate-200"
      onToggle={(e) => {
        if ((e.currentTarget as HTMLDetailsElement).open) void carregar();
      }}
    >
      <summary className="font-sans text-xs font-semibold text-slate-600 px-4 py-2.5 cursor-pointer select-none flex items-center justify-between gap-2 list-none">
        <span className="flex items-center gap-1.5">
          <span className="material-symbols-outlined text-[16px] text-slate-400">tune</span>
          {isEn ? "Parameters in force" : "Parâmetros em vigor"}
        </span>
        <span className="material-symbols-outlined text-[16px] text-slate-400 transition-transform group-open:rotate-180">
          expand_more
        </span>
      </summary>
      <div className="px-4 pb-4 flex flex-col gap-3">
        {aCarregar && (
          <span className="font-sans text-xs text-slate-500">{isEn ? "Loading…" : "A carregar…"}</span>
        )}
        {erro && (
          <p role="alert" className="font-sans text-xs text-rose-700">
            {erro}
          </p>
        )}
        {parametros && (
          <>
            <span className="font-sans text-[11px] text-slate-500">
              {isEn ? "Version" : "Versão"} <span className="font-mono font-bold">{parametros.versao ?? "—"}</span>
              {parametros.demonstrativo && (isEn ? " · demonstrative" : " · demonstrativos")}
              {" · "}
              {isEn ? "defect prior" : "prior do defeito"}{" "}
              <span className="font-mono font-bold tabular-nums">{numero(parametros.priorDefeito, locale)}</span>
            </span>
            {tabela(isEn ? "Fraud certainty factors" : "Fatores de certeza (fraude)", parametros.fatoresCerteza)}
            {tabela(isEn ? "Defect likelihood ratios" : "Razões de verosimilhança (defeito)", parametros.razoesVerosimilhanca)}
            {tabela(isEn ? "Classification thresholds" : "Limiares de classificação", parametros.limiares)}
          </>
        )}
      </div>
    </details>
  );
}

/**
 * Avaliação da incerteza (docs/08 do motor Drools): um cartão por grau de crença, com o valor
 * na escala do método, a classificação, as contribuições e o "Como?" / "Porque não?" de cada um.
 */
export default function UncertaintyPanel({
  graus,
  evaluationId,
  base = "/api/returns",
  compact = false,
}: UncertaintyPanelProps) {
  const { locale } = useLocale();
  const isEn = locale === "en";
  if (graus.length === 0) return null;

  const demonstrativo = graus.some((g) => g.demonstrativo);
  const versao = graus.find((g) => g.versaoParametros)?.versaoParametros;

  return (
    <div className="flex flex-col gap-3">
      {demonstrativo && (
        <div
          role="note"
          className="flex items-start gap-2.5 px-3.5 py-2.5 rounded-xl bg-amber-50 border border-amber-200 text-amber-800"
        >
          <span className="material-symbols-outlined text-[18px] mt-px shrink-0">science</span>
          <p className="font-sans text-xs leading-relaxed">
            {avisoDemonstrativo(locale)}
            {versao && (
              <span className="text-amber-700/80">
                {" "}
                ({isEn ? "parameters" : "parâmetros"} <span className="font-mono font-bold">{versao}</span>)
              </span>
            )}
          </p>
        </div>
      )}

      <div className={`grid grid-cols-1 gap-3 ${compact ? "" : "md:grid-cols-2"}`}>
        {graus.map((grau) => (
          <GrauCard
            key={`${grau.hipotese}|${grau.artigoId ?? ""}`}
            grau={grau}
            evaluationId={evaluationId}
            base={base}
            compact={compact}
            locale={locale}
          />
        ))}
      </div>

      {!compact && <Parametros base={base} locale={locale} />}
    </div>
  );
}
