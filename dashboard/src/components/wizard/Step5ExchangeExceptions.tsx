"use client";

import React from "react";
import { useWizard } from "./WizardContext";
import SlickSlider from "@/components/ui/SlickSlider";

const EXCHANGE_MODALITIES = [
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
] as const;

const CUSTOMER_SITUATIONS = [
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
] as const;

export default function Step5ExchangeExceptions() {
  const { state, setField } = useWizard();
  const isExchange = state.requestType === "TROCA";

  const getExchangeBadgeText = () => {
    switch (state.exchangeOption) {
      case "OUTRO_ARTIGO":
        return "Troca: Outro Artigo";
      case "MESMO_MODELO":
        return "Troca: Mesmo Modelo";
      default:
        return "";
    }
  };

  const getSituationBadgeText = () => {
    switch (state.customerSituation) {
      case "CONTESTA":
        return "Contestação";
      case "CHAMAR_GERENCIA":
        return "Chamar Gerência";
      case "CONFORME":
        return "Cliente Conforme";
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
              Modalidade de Troca
            </h3>
            {state.exchangeOption && state.exchangeOption !== "NENHUMA" ? (
              <span
                className={`font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold select-none ${
                  state.exchangeOption === "OUTRO_ARTIGO"
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
                Obrigatório
              </span>
            )}
          </div>

          {/* Minimalist Cards Grid em 2 colunas */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
            {EXCHANGE_MODALITIES.map((item) => {
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
                  className={`group rounded-xl p-4 sm:p-5 cursor-pointer flex items-center justify-between gap-4 transition-all duration-150 focus-visible:outline-2 bg-white ${
                    isAmberTone ? "focus-visible:outline-amber-500" : "focus-visible:outline-emerald-600"
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
            Situação do Cliente no Balcão
          </h3>
          {state.customerSituation ? (
            <span
              className={`font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold select-none ${
                state.customerSituation === "CONFORME"
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
              Obrigatório
            </span>
          )}
        </div>

        {/* Minimalist Cards Grid em 2 colunas */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
          {CUSTOMER_SITUATIONS.map((item) => {
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
                className={`group rounded-xl p-4 sm:p-5 cursor-pointer flex items-center justify-between gap-4 transition-all duration-150 focus-visible:outline-2 bg-white ${
                  isAmberTone ? "focus-visible:outline-amber-500" : "focus-visible:outline-emerald-600"
                } ${
                  item.fullWidth ? "sm:col-span-2" : ""
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
            Exceção da Gerência
          </h3>
          {state.managerException === true ? (
            <span className="font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200/60 select-none">
              <span className="material-symbols-outlined text-[13px] font-bold">check</span>
              Autorizada
            </span>
          ) : state.managerException === false ? (
            <span className="font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-slate-100 text-slate-700 border border-slate-200/60 select-none">
              <span className="material-symbols-outlined text-[13px] font-bold">close</span>
              Não Autorizada
            </span>
          ) : (
            <span className="font-sans inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200/80 select-none">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
              Obrigatório
            </span>
          )}
        </div>

        {/* Autorização de Exceção pela Gerência com SlickSlider */}
        <div
          className={`rounded-xl p-4 sm:p-5 border transition-all duration-150 flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white ${
            state.managerException === true
              ? "border-2 border-emerald-600"
              : state.managerException === false
              ? "border border-slate-300"
              : "border border-slate-200 hover:border-slate-300"
          }`}
        >
          <div className="flex items-center gap-3.5 min-w-0">
            <div
              className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-colors ${
                state.managerException === true
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
                  Exceção de Gerência Autorizada?
                </h4>
                {state.managerException === true ? (
                  <span className="font-sans text-[11px] font-bold text-emerald-700 bg-emerald-50 border border-emerald-200/60 px-2 py-0.5 rounded-full shrink-0">
                    Autorizada
                  </span>
                ) : state.managerException === false ? (
                  <span className="font-sans text-[11px] font-semibold text-slate-600 bg-slate-100 border border-slate-200/60 px-2 py-0.5 rounded-full shrink-0">
                    Não Autorizada
                  </span>
                ) : (
                  <span className="font-sans inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200/80 shrink-0 select-none">
                    <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
                    Obrigatório
                  </span>
                )}
              </div>
              <p className="font-sans text-xs text-slate-500 mt-0.5 leading-relaxed">
                Responsável presente autoriza flexibilização de prazo ou política comercial 
    
              </p>
            </div>
          </div>

          <div className="shrink-0 w-full sm:w-auto">
            <SlickSlider
              options={[
                { label: "Não", value: false, tone: "info", icon: "close" },
                { label: "Autorizada", value: true, tone: "success", icon: "verified" },
              ]}
              value={state.managerException}
              onChange={(val) => setField("managerException", val)}
              ariaLabel="Exceção de Gerência Autorizada"
              width="w-full sm:w-[210px]"
            />
          </div>
        </div>
      </div>
    </div>
  );
}
