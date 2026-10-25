"use client";

import React from "react";
import { useWizard, usaCamadaIncerteza } from "./WizardContext";
import { useLocale } from "@/contexts/LocaleContext";
import SlickSlider from "@/components/ui/SlickSlider";
import SegmentedChoice from "@/components/ui/SegmentedChoice";
import { RESPOSTAS } from "@/config/uncertaintyLabels";
import type { Resposta } from "@/types/returns";

interface ExchangeModalityItem {
  id: "MESMO_MODELO" | "OUTRO_ARTIGO";
  title: string;
  subtitle: string;
  badge: string;
  icon: string;
  tone: "emerald" | "amber";
}

const EXCHANGE_MODALITIES_PT: ExchangeModalityItem[] = [
  {
    id: "MESMO_MODELO",
    title: "Mesmo Modelo / Tamanho",
    subtitle: "Troca direta de tamanho mantendo o preço de compra original ou promocional (EP-001)",
    badge: "Troca Direta",
    icon: "straighten",
    tone: "emerald",
  },
  {
    id: "OUTRO_ARTIGO",
    title: "Outro Artigo Diferente",
    subtitle: "Escolha de peça de modelo ou cor diferente com acerto de saldo no caixa ou vale (EP-002)",
    badge: "Acerto Saldo",
    icon: "style",
    tone: "amber",
  },
];

const EXCHANGE_MODALITIES_EN: ExchangeModalityItem[] = [
  {
    id: "MESMO_MODELO",
    title: "Same Model / Size",
    subtitle: "Direct size exchange honoring original or promotional purchase price (EP-001)",
    badge: "Direct Exchange",
    icon: "straighten",
    tone: "emerald",
  },
  {
    id: "OUTRO_ARTIGO",
    title: "Different Item",
    subtitle: "Selection of different model or color with balance difference settled at register (EP-002)",
    badge: "Balance Difference",
    icon: "style",
    tone: "amber",
  },
];

interface CustomerSituationItem {
  id: "CONFORME" | "CONTESTA" | "CHAMAR_GERENCIA";
  title: string;
  subtitle: string;
  badge: string;
  icon: string;
  fullWidth: boolean;
  tone: "emerald" | "amber";
}

const CUSTOMER_SITUATIONS_PT: CustomerSituationItem[] = [
  {
    id: "CONFORME",
    title: "Conforme / Aceite",
    subtitle: "O cliente compreende cordialmente os termos e aceita a resolução de loja",
    badge: "Cordial",
    icon: "sentiment_satisfied",
    fullWidth: true,
    tone: "emerald",
  },
  {
    id: "CONTESTA",
    title: "Contesta Política",
    subtitle: "O cliente contesta prazos, etiquetas ou limites de valor estabelecidos",
    badge: "Contestação",
    icon: "rate_review",
    fullWidth: false,
    tone: "amber",
  },
  {
    id: "CHAMAR_GERENCIA",
    title: "Chamar Gerência",
    subtitle: "Intervenção do responsável de turno ou chefe de loja para escalonamento presencial",
    badge: "Escalonamento",
    icon: "support_agent",
    fullWidth: false,
    tone: "amber",
  },
];

const CUSTOMER_SITUATIONS_EN: CustomerSituationItem[] = [
  {
    id: "CONFORME",
    title: "Compliant / Accepted",
    subtitle: "Customer cordially accepts and understands the store resolution terms",
    badge: "Cordial",
    icon: "sentiment_satisfied",
    fullWidth: true,
    tone: "emerald",
  },
  {
    id: "CONTESTA",
    title: "Disputes Policy",
    subtitle: "Customer disputes deadlines, label conditions, or monetary valuation limits",
    badge: "Dispute",
    icon: "rate_review",
    fullWidth: false,
    tone: "amber",
  },
  {
    id: "CHAMAR_GERENCIA",
    title: "Call Store Manager",
    subtitle: "Intervention requested from shift supervisor or store manager for on-site escalation",
    badge: "Escalation",
    icon: "support_agent",
    fullWidth: false,
    tone: "amber",
  },
];

export default function Step5ExchangeExceptions() {
  const { state, setField } = useWizard();
  const { locale } = useLocale();

  const isEn = locale === "en";
  const exchangeModalities = isEn ? EXCHANGE_MODALITIES_EN : EXCHANGE_MODALITIES_PT;
  const customerSituations = isEn ? CUSTOMER_SITUATIONS_EN : CUSTOMER_SITUATIONS_PT;

  const isExchange = state.requestType === "TROCA";
  const comIncerteza = usaCamadaIncerteza(state);

  const getExchangeBadgeText = () => {
    switch (state.exchangeOption) {
      case "OUTRO_ARTIGO":
        return isEn ? "Exchange: Different Item" : "Troca: Outro Artigo";
      case "MESMO_MODELO":
        return isEn ? "Exchange: Same Model" : "Troca: Mesmo Modelo";
      default:
        return "";
    }
  };

  const getSituationBadgeText = () => {
    switch (state.customerSituation) {
      case "CONTESTA":
        return isEn ? "Dispute" : "Contestação";
      case "CHAMAR_GERENCIA":
        return isEn ? "Call Manager" : "Chamar Gerência";
      case "CONFORME":
        return isEn ? "Compliant Customer" : "Cliente Conforme";
      default:
        return "";
    }
  };

  return (
    <div className="w-full flex flex-col gap-6">
      {/* 1. Modalidade de Troca (Apenas exibido quando Tipo de Pedido é TROCA) */}
      {isExchange && (
        <div className="w-full flex flex-col gap-3">
          {/* Typographic Section Header */}
          <div className="flex items-center gap-2 px-1">
            <span className="font-mono tabular-nums text-xs font-bold text-slate-400 select-none">01</span>
            <span className="text-slate-300">/</span>
            <h3 className="font-sans text-sm sm:text-base font-bold text-slate-900 tracking-tight">
              {isEn ? "Exchange Modality" : "Modalidade de Troca"}
            </h3>
            {state.exchangeOption && state.exchangeOption !== "NENHUMA" ? (
              <span
                className={`font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold select-none ${state.exchangeOption === "OUTRO_ARTIGO"
                    ? "bg-amber-50 text-amber-700 border border-amber-200/80"
                    : "bg-emerald-50 text-emerald-700 border border-emerald-200/60"
                  }`}
              >
                <span className="material-symbols-outlined text-[13px] font-bold">check</span>
                {getExchangeBadgeText()}
              </span>
            ) : (
              <span className="font-sans inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200/80 select-none">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
                {isEn ? "Required" : "Obrigatório"}
              </span>
            )}
          </div>

          {/* Minimalist Cards Grid em 2 colunas */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
            {exchangeModalities.map((item) => {
              const isSelected = state.exchangeOption === item.id;
              const isAmberTone = item.tone === "amber";

              const borderClass = isSelected
                ? isAmberTone
                  ? "border-2 border-amber-500"
                  : "border-2 border-emerald-600"
                : "border border-slate-200 hover:border-slate-300";

              const iconClass = isSelected
                ? isAmberTone
                  ? "bg-amber-50 text-amber-700 border border-amber-200/60"
                  : "bg-emerald-50 text-emerald-700 border border-emerald-200/60"
                : "bg-slate-100 text-slate-500 border border-slate-200/60";

              const radioClass = isSelected
                ? isAmberTone
                  ? "bg-amber-500 text-white"
                  : "bg-emerald-600 text-white"
                : "border-2 border-slate-300";

              return (
                <div
                  key={item.id}
                  role="radio"
                  aria-checked={isSelected}
                  tabIndex={0}
                  onClick={() => setField("exchangeOption", item.id)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" || e.key === " ") {
                      e.preventDefault();
                      setField("exchangeOption", item.id);
                    }
                  }}
                  className={`group rounded-xl p-4 sm:p-5 cursor-pointer flex items-center justify-between gap-4 transition-all duration-150 focus-visible:outline-2 bg-white ${isAmberTone ? "focus-visible:outline-amber-500" : "focus-visible:outline-emerald-600"
                    } ${borderClass}`}
                >
                  <div className="flex items-center gap-3.5 min-w-0">
                    <div
                      className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-colors ${iconClass}`}
                    >
                      <span className="material-symbols-outlined text-[22px]">{item.icon}</span>
                    </div>
                    <div className="flex flex-col min-w-0">
                      <div className="flex items-center gap-2">
                        <h4 className="font-sans font-bold text-slate-900 text-sm sm:text-base tracking-tight">
                          {item.title}
                        </h4>
                        <span className="font-sans text-[11px] font-semibold text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded shrink-0">
                          {item.badge}
                        </span>
                      </div>
                      <p className="font-sans text-xs text-slate-500 mt-0.5 leading-relaxed">
                        {item.subtitle}
                      </p>
                    </div>
                  </div>

                  <div
                    aria-hidden="true"
                    className={`w-5 h-5 rounded-full flex items-center justify-center shrink-0 transition-colors ${radioClass}`}
                  >
                    {isSelected && (
                      <span className="material-symbols-outlined text-[13px] font-bold">check</span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Situação do Cliente no Balcão: 02 se for troca, 01 se não for */}
      <div className="w-full flex flex-col gap-3">
        {/* Typographic Section Header */}
        <div className="flex items-center gap-2 px-1">
          <span className="font-mono tabular-nums text-xs font-bold text-slate-400 select-none">
            {isExchange ? "02" : "01"}
          </span>
          <span className="text-slate-300">/</span>
          <h3 className="font-sans text-sm sm:text-base font-bold text-slate-900 tracking-tight">
            {isEn ? "Customer Demeanor at Counter" : "Situação do Cliente no Balcão"}
          </h3>
          {state.customerSituation ? (
            <span
              className={`font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold select-none ${state.customerSituation === "CONFORME"
                  ? "bg-emerald-50 text-emerald-700 border border-emerald-200/60"
                  : "bg-amber-50 text-amber-700 border border-amber-200/80"
                }`}
            >
              <span className="material-symbols-outlined text-[13px] font-bold">check</span>
              {getSituationBadgeText()}
            </span>
          ) : (
            <span className="font-sans inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200/80 select-none">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
              {isEn ? "Required" : "Obrigatório"}
            </span>
          )}
        </div>

        {/* Minimalist Cards Grid em 2 colunas */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
          {customerSituations.map((item) => {
            const isSelected = state.customerSituation === item.id;
            const isAmberTone = item.tone === "amber";

            const borderClass = isSelected
              ? isAmberTone
                ? "border-2 border-amber-500"
                : "border-2 border-emerald-600"
              : "border border-slate-200 hover:border-slate-300";

            const iconClass = isSelected
              ? isAmberTone
                ? "bg-amber-50 text-amber-700 border border-amber-200/60"
                : "bg-emerald-50 text-emerald-700 border border-emerald-200/60"
              : "bg-slate-100 text-slate-500 border border-slate-200/60";

            const radioClass = isSelected
              ? isAmberTone
                ? "bg-amber-500 text-white"
                : "bg-emerald-600 text-white"
              : "border-2 border-slate-300";

            return (
              <div
                key={item.id}
                role="radio"
                aria-checked={isSelected}
                tabIndex={0}
                onClick={() => setField("customerSituation", item.id)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" || e.key === " ") {
                    e.preventDefault();
                    setField("customerSituation", item.id);
                  }
                }}
                className={`group rounded-xl p-4 sm:p-5 cursor-pointer flex items-center justify-between gap-4 transition-all duration-150 focus-visible:outline-2 bg-white ${isAmberTone ? "focus-visible:outline-amber-500" : "focus-visible:outline-emerald-600"
                  } ${item.fullWidth ? "sm:col-span-2" : ""
                  } ${borderClass}`}
              >
                <div className="flex items-center gap-3.5 min-w-0">
                  <div
                    className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-colors ${iconClass}`}
                  >
                    <span className="material-symbols-outlined text-[22px]">{item.icon}</span>
                  </div>
                  <div className="flex flex-col min-w-0">
                    <div className="flex items-center gap-2">
                      <h4 className="font-sans font-bold text-slate-900 text-sm sm:text-base tracking-tight">
                        {item.title}
                      </h4>
                      <span className="font-sans text-[11px] font-semibold text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded shrink-0">
                        {item.badge}
                      </span>
                    </div>
                    <p className="font-sans text-xs text-slate-500 mt-0.5 leading-relaxed">
                      {item.subtitle}
                    </p>
                  </div>
                </div>

                <div
                  aria-hidden="true"
                  className={`w-5 h-5 rounded-full flex items-center justify-center shrink-0 transition-colors ${radioClass}`}
                >
                  {isSelected && (
                    <span className="material-symbols-outlined text-[13px] font-bold">check</span>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* 3. Exceção da Gerência: 03 se for troca, 02 se não for */}
      <div className="w-full flex flex-col gap-3">
        {/* Typographic Section Header */}
        <div className="flex items-center gap-2 px-1">
          <span className="font-mono tabular-nums text-xs font-bold text-slate-400 select-none">
            {isExchange ? "03" : "02"}
          </span>
          <span className="text-slate-300">/</span>
          <h3 className="font-sans text-sm sm:text-base font-bold text-slate-900 tracking-tight">
            {isEn ? "Manager Exception" : "Exceção da Gerência"}
          </h3>
          {state.managerException === true ? (
            <span className="font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200/60 select-none">
              <span className="material-symbols-outlined text-[13px] font-bold">check</span>
              {isEn ? "Authorized" : "Autorizada"}
            </span>
          ) : state.managerException === false ? (
            <span className="font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-slate-100 text-slate-700 border border-slate-200/60 select-none">
              <span className="material-symbols-outlined text-[13px] font-bold">close</span>
              {isEn ? "Not Authorized" : "Não Autorizada"}
            </span>
          ) : (
            <span className="font-sans inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200/80 select-none">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
              {isEn ? "Required" : "Obrigatório"}
            </span>
          )}
        </div>

        {/* Autorização de Exceção pela Gerência com SlickSlider */}
        <div
          className={`rounded-xl p-4 sm:p-5 border transition-all duration-150 flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white ${state.managerException === true
              ? "border-2 border-emerald-600"
              : state.managerException === false
                ? "border border-slate-300"
                : "border border-slate-200 hover:border-slate-300"
            }`}
        >
          <div className="flex items-center gap-3.5 min-w-0">
            <div
              className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-colors ${state.managerException === true
                  ? "bg-emerald-50 text-emerald-700 border border-emerald-200/60"
                  : "bg-slate-100 text-slate-500 border border-slate-200/60"
                }`}
            >
              <span className="material-symbols-outlined text-[22px]">
                {state.managerException === true ? "verified" : "admin_panel_settings"}
              </span>
            </div>
            <div className="flex flex-col min-w-0">
              <div className="flex items-center gap-2">
                <h4 className="font-sans font-bold text-slate-900 text-sm sm:text-base tracking-tight leading-snug">
                  {isEn ? "Manager Exception Authorized?" : "Exceção de Gerência Autorizada?"}
                </h4>
                {state.managerException === true ? (
                  <span className="font-sans text-[11px] font-bold text-emerald-700 bg-emerald-50 border border-emerald-200/60 px-2 py-0.5 rounded-full shrink-0">
                    {isEn ? "Authorized" : "Autorizada"}
                  </span>
                ) : state.managerException === false ? (
                  <span className="font-sans text-[11px] font-semibold text-slate-600 bg-slate-100 border border-slate-200/60 px-2 py-0.5 rounded-full shrink-0">
                    {isEn ? "Not Authorized" : "Não Autorizada"}
                  </span>
                ) : (
                  <span className="font-sans inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200/80 shrink-0 select-none">
                    <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
                    {isEn ? "Required" : "Obrigatório"}
                  </span>
                )}
              </div>
              <p className="font-sans text-xs text-slate-500 mt-0.5 leading-relaxed">
                {isEn
                  ? "Duty manager present authorizes timeline flexibility or commercial policy discretion"
                  : "Responsável presente autoriza flexibilização de prazo ou política comercial"}
              </p>
            </div>
          </div>

          <div className="shrink-0 w-full sm:w-auto">
            <SlickSlider
              options={[
                { label: isEn ? "No" : "Não", value: false, tone: "info", icon: "close" },
                { label: isEn ? "Authorized" : "Autorizada", value: true, tone: "success", icon: "verified" },
              ]}
              value={state.managerException}
              onChange={(val) => setField("managerException", val)}
              ariaLabel={isEn ? "Manager Exception Authorized" : "Exceção de Gerência Autorizada"}
              width="w-full sm:w-[210px]"
            />
          </div>
        </div>
      </div>

      {/* 4. Sinais de risco no balcão: evidências do risco de fraude da camada de incerteza (só Drools) */}
      {comIncerteza && (
        <div className="w-full flex flex-col gap-3">
          {/* Typographic Section Header */}
          <div className="flex items-center gap-2 px-1 flex-wrap">
            <span className="font-mono tabular-nums text-xs font-bold text-slate-400 select-none">
              {isExchange ? "04" : "03"}
            </span>
            <span className="text-slate-300">/</span>
            <h3 className="font-sans text-sm sm:text-base font-bold text-slate-900 tracking-tight">
              {isEn ? "Risk Signals at the Counter" : "Sinais de Risco no Balcão"}
            </h3>
            <span className="font-sans inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-semibold bg-slate-100 text-slate-500 border border-slate-200/80 select-none">
              {isEn ? "Optional" : "Opcional"}
            </span>
            <span className="font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-indigo-50 text-indigo-700 border border-indigo-200/80 select-none">
              <span className="material-symbols-outlined text-[13px]">psychology</span>
              {isEn ? "Drools · Uncertainty" : "Drools · Incerteza"}
            </span>
          </div>
          <p className="font-sans text-xs text-slate-500 px-1 -mt-1 leading-relaxed">
            {isEn
              ? "Combined with the proof of purchase and the tags, these answers feed the estimated fraud risk. A risk signal never refuses a return by itself: it asks for management review."
              : "Junto com o comprovativo e as etiquetas, estas respostas alimentam o risco de fraude estimado. Um sinal de risco nunca recusa a devolução por si: pede a revisão da gestão."}
          </p>

          <div className="grid grid-cols-1 gap-3.5">
            {/* Card: o cliente explica a origem da compra (EF-04) */}
            <div
              className={`rounded-xl p-4 sm:p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 transition-all duration-200 bg-white ${state.purchaseOriginExplained === "NAO"
                  ? "border-2 border-amber-500"
                  : state.purchaseOriginExplained
                    ? "border border-slate-300"
                    : "border border-slate-200 hover:border-slate-300"
                }`}
            >
              <div className="flex items-center gap-3.5 min-w-0">
                <div
                  className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-colors ${state.purchaseOriginExplained === "NAO"
                      ? "bg-amber-50 text-amber-700 border border-amber-200/60"
                      : state.purchaseOriginExplained === "SIM"
                        ? "bg-emerald-50 text-emerald-700 border border-emerald-200/60"
                        : "bg-slate-100 text-slate-500 border border-slate-200/60"
                    }`}
                >
                  <span className="material-symbols-outlined text-[22px]">travel_explore</span>
                </div>
                <div className="flex flex-col min-w-0">
                  <h4 className="font-sans font-bold text-slate-900 text-sm sm:text-base tracking-tight leading-snug">
                    {isEn ? "Does the customer explain where and when they bought it?" : "O cliente explica onde e quando comprou?"}
                  </h4>
                  <p className="font-sans text-xs text-slate-500 mt-0.5 leading-relaxed">
                    {isEn ? "Store, approximate date or channel of the purchase" : "Loja, data aproximada ou canal da compra"}
                  </p>
                </div>
              </div>
              <SegmentedChoice<Resposta>
                options={RESPOSTAS.map((r) => ({
                  label: isEn ? r.en : r.pt,
                  value: r.value,
                  tone: r.value === "SIM" ? "success" : r.value === "NAO" ? "warning" : "neutral",
                }))}
                value={state.purchaseOriginExplained}
                onChange={(val) => setField("purchaseOriginExplained", val)}
                ariaLabel={isEn ? "Customer explains where and when they bought it" : "O cliente explica onde e quando comprou"}
                width="w-full sm:w-[252px]"
              />
            </div>

            {/* Card: o cliente pede numerário (EF-05) */}
            <div
              className={`rounded-xl p-4 sm:p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 transition-all duration-200 bg-white ${state.asksForCash
                  ? "border-2 border-amber-500"
                  : "border border-slate-200 hover:border-slate-300"
                }`}
            >
              <div className="flex items-center gap-3.5 min-w-0">
                <div
                  className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-colors ${state.asksForCash
                      ? "bg-amber-50 text-amber-700 border border-amber-200/60"
                      : state.asksForCash === false
                        ? "bg-emerald-50 text-emerald-700 border border-emerald-200/60"
                        : "bg-slate-100 text-slate-500 border border-slate-200/60"
                    }`}
                >
                  <span className="material-symbols-outlined text-[22px]">payments</span>
                </div>
                <div className="flex flex-col min-w-0">
                  <h4 className="font-sans font-bold text-slate-900 text-sm sm:text-base tracking-tight leading-snug">
                    {isEn ? "Does the customer ask for a cash refund?" : "O cliente pede o reembolso em numerário?"}
                  </h4>
                  <p className="font-sans text-xs text-slate-500 mt-0.5 leading-relaxed">
                    {isEn
                      ? "Only counts as a risk signal when the purchase cannot be verified"
                      : "Só conta como sinal de risco quando a compra não pode ser verificada"}
                  </p>
                </div>
              </div>
              <SlickSlider
                options={[
                  { label: isEn ? "No" : "Não", value: false, tone: "success", icon: "check" },
                  { label: isEn ? "Asks for cash" : "Pede numerário", value: true, tone: "warning", icon: "payments" },
                ]}
                value={state.asksForCash}
                onChange={(val) => setField("asksForCash", val)}
                ariaLabel={isEn ? "Customer asks for a cash refund" : "O cliente pede o reembolso em numerário"}
                width="w-full sm:w-[232px]"
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
