"use client";

import React from "react";
import { useWizard } from "./WizardContext";

interface RequestTypeItem {
  id: "DEVOLUCAO" | "TROCA" | "GIFT" | "AJUSTE_PRECO";
  title: string;
  subtitle: string;
  badge: string;
  icon: string;
}

const REQUEST_TYPES: RequestTypeItem[] = [
  {
    id: "DEVOLUCAO",
    title: "Devolução Standard",
    subtitle: "Reembolso monetário regular pelo meio de pagamento utilizado",
    badge: "Padrão",
    icon: "assignment_return",
  },
  {
    id: "TROCA",
    title: "Troca por Artigo",
    subtitle: "Substituição por outro tamanho, modelo ou cor de artigo em loja",
    badge: "Troca",
    icon: "swap_horiz",
  },
  {
    id: "GIFT",
    title: "Devolução de Oferta",
    subtitle: "Apresentação de recibo de presente; emissão de vale ou crédito de loja",
    badge: "Oferta",
    icon: "featured_seasonal_and_gifts",
  },
  {
    id: "AJUSTE_PRECO",
    title: "Ajuste de Preço",
    subtitle: "Reembolso da diferença de promoção ou desconto posterior de loja",
    badge: "Acerto",
    icon: "price_change",
  },
];

interface ProofOfPurchaseItem {
  id: "RECIBO_ORIGINAL" | "CONFIRMACAO_ONLINE" | "RECIBO_OFERTA" | "CONSULTA_POS" | "SEM_COMPROVATIVO";
  title: string;
  subtitle: string;
  badge: string;
  icon: string;
}

const PROOFS_OF_PURCHASE: ProofOfPurchaseItem[] = [
  {
    id: "RECIBO_ORIGINAL",
    title: "Recibo Original",
    subtitle: "Talão de caixa impresso com código de barras e NIF",
    badge: "Físico",
    icon: "receipt_long",
  },
  {
    id: "CONFIRMACAO_ONLINE",
    title: "Confirmação Online",
    subtitle: "Email de confirmação de encomenda ou fatura digital da app",
    badge: "Digital",
    icon: "mark_email_read",
  },
  {
    id: "RECIBO_OFERTA",
    title: "Recibo de Oferta",
    subtitle: "Talão emitido no momento da compra sem valor monetário visível",
    badge: "Gift",
    icon: "redeem",
  },
  {
    id: "CONSULTA_POS",
    title: "Consulta no POS",
    subtitle: "Pesquisa no sistema pelo cartão de pagamento ou cliente",
    badge: "Sistema",
    icon: "point_of_sale",
  },
  {
    id: "SEM_COMPROVATIVO",
    title: "Sem Comprovativo",
    subtitle: "O cliente não apresenta qualquer talão físico ou registo digital de compra",
    badge: "Exceção",
    icon: "block",
  },
];

export default function Step4ReceiptTimeline() {
  const { state, setField } = useWizard();

  return (
    <div className="w-full flex flex-col gap-6">
      {/* 1. Tipo de Pedido */}
      <div className="w-full flex flex-col gap-3">
        {/* Typographic Section Header */}
        <div className="flex items-center gap-2 px-1">
          <span className="font-mono tabular-nums text-xs font-bold text-slate-400 select-none">01</span>
          <span className="text-slate-300">/</span>
          <h3 className="font-sans text-sm sm:text-base font-bold text-slate-900 tracking-tight">
            Tipo de Pedido
          </h3>
          {state.requestType ? (
            <span className="font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200/60 select-none">
              <span className="material-symbols-outlined text-[13px] font-bold">check</span>
              Definido
            </span>
          ) : (
            <span className="font-sans inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200/80 select-none">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
              Obrigatório
            </span>
          )}
        </div>

        {/* Minimalist Cards Grid no mesmo estilo do Passo 2 e Passo 3 */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
          {REQUEST_TYPES.map((item) => {
            const isSelected = state.requestType === item.id;
            const isAjustePreco = item.id === "AJUSTE_PRECO";
            const isAjusteRecusado =
              isAjustePreco &&
              ((state.daysSincePurchase !== null && state.daysSincePurchase > 14) ||
                (state.proofOfPurchase && state.proofOfPurchase !== "RECIBO_ORIGINAL"));

            const handleSelect = () => {
              setField("requestType", item.id);
            };

            const borderClass = isSelected
              ? isAjusteRecusado
                ? "border-2 border-rose-500"
                : "border-2 border-emerald-600"
              : "border border-slate-200 hover:border-slate-300";

            const iconClass = isSelected
              ? isAjusteRecusado
                ? "bg-rose-50 text-rose-700 border border-rose-200/60"
                : "bg-emerald-50 text-emerald-700 border border-emerald-200/60"
              : "bg-slate-100 text-slate-500 border border-slate-200/60";

            const radioClass = isSelected
              ? isAjusteRecusado
                ? "bg-rose-500 text-white"
                : "bg-emerald-600 text-white"
              : "border-2 border-slate-300";

            return (
              <div
                key={item.id}
                role="radio"
                aria-checked={isSelected}
                tabIndex={0}
                onClick={handleSelect}
                onKeyDown={(e) => {
                  if (e.key === "Enter" || e.key === " ") {
                    e.preventDefault();
                    handleSelect();
                  }
                }}
                className={`group rounded-xl p-4 sm:p-5 cursor-pointer flex items-center justify-between gap-4 transition-all duration-150 focus-visible:outline-2 bg-white ${
                  isAjusteRecusado && isSelected
                    ? "focus-visible:outline-rose-500"
                    : "focus-visible:outline-emerald-600"
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

      {/* 2. Comprovativo de Compra */}
      <div className="w-full flex flex-col gap-3">
        {/* Typographic Section Header */}
        <div className="flex items-center gap-2 px-1">
          <span className="font-mono tabular-nums text-xs font-bold text-slate-400 select-none">02</span>
          <span className="text-slate-300">/</span>
          <h3 className="font-sans text-sm sm:text-base font-bold text-slate-900 tracking-tight">
            Comprovativo de Compra
          </h3>
          {state.proofOfPurchase ? (
            <span className="font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200/60 select-none">
              <span className="material-symbols-outlined text-[13px] font-bold">check</span>
              Definido
            </span>
          ) : (
            <span className="font-sans inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200/80 select-none">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
              Obrigatório
            </span>
          )}
        </div>

        {/* Minimalist Cards Grid alinhado em 2 colunas para harmonia total */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
          {PROOFS_OF_PURCHASE.map((item) => {
            const isSelected = state.proofOfPurchase === item.id;
            const isFullWidth = item.id === "SEM_COMPROVATIVO";
            const isAmber = item.id === "SEM_COMPROVATIVO";

            const borderClass = isSelected
              ? isAmber
                ? "border-2 border-amber-500"
                : "border-2 border-emerald-600"
              : "border border-slate-200 hover:border-slate-300";

            const iconClass = isSelected
              ? isAmber
                ? "bg-amber-50 text-amber-700 border border-amber-200/60"
                : "bg-emerald-50 text-emerald-700 border border-emerald-200/60"
              : "bg-slate-100 text-slate-500 border border-slate-200/60";

            const radioClass = isSelected
              ? isAmber
                ? "bg-amber-500 text-white"
                : "bg-emerald-600 text-white"
              : "border-2 border-slate-300";

            return (
              <div
                key={item.id}
                role="radio"
                aria-checked={isSelected}
                tabIndex={0}
                onClick={() => setField("proofOfPurchase", item.id)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" || e.key === " ") {
                    e.preventDefault();
                    setField("proofOfPurchase", item.id);
                  }
                }}
                className={`group rounded-xl p-4 sm:p-5 cursor-pointer flex items-center justify-between gap-4 transition-all duration-150 focus-visible:outline-2 bg-white ${
                  isAmber ? "focus-visible:outline-amber-500" : "focus-visible:outline-emerald-600"
                } ${
                  isFullWidth ? "sm:col-span-2" : ""
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

      {/* 3. Janela Temporal desde a Compra */}
      <div className="w-full flex flex-col gap-3">
        {/* Typographic Section Header */}
        <div className="flex items-center gap-2 px-1">
          <span className="font-mono tabular-nums text-xs font-bold text-slate-400 select-none">03</span>
          <span className="text-slate-300">/</span>
          <h3 className="font-sans text-sm sm:text-base font-bold text-slate-900 tracking-tight">
            Janela Temporal desde a Compra
          </h3>
          {state.daysSincePurchase !== null ? (
            state.daysSincePurchase <= 30 ? (
              <span className="font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200/60 select-none">
                <span className="material-symbols-outlined text-[13px] font-bold">check</span>
                Regular (≤ 30d)
              </span>
            ) : (
              <span className="font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200/80 select-none">
                <span className="material-symbols-outlined text-[13px] font-bold">warning</span>
                Fora de Prazo ({state.daysSincePurchase}d)
              </span>
            )
          ) : (
            <span className="font-sans inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200/80 select-none">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
              Obrigatório
            </span>
          )}
        </div>

        {/* Minimalist Cards Grid em 2 colunas */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
          {/* Card: Até 30 Dias */}
          <div
            role="radio"
            aria-checked={state.daysSincePurchase !== null && state.daysSincePurchase <= 30}
            tabIndex={0}
            onClick={() => setField("daysSincePurchase", 14)}
            onKeyDown={(e) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault();
                setField("daysSincePurchase", 14);
              }
            }}
            className={`group rounded-xl p-4 sm:p-5 cursor-pointer flex items-center justify-between gap-4 transition-all duration-150 focus-visible:outline-2 focus-visible:outline-emerald-600 bg-white ${
              state.daysSincePurchase !== null && state.daysSincePurchase <= 30
                ? "border-2 border-emerald-600"
                : "border border-slate-200 hover:border-slate-300"
            }`}
          >
            <div className="flex items-center gap-3.5 min-w-0">
              <div
                className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-colors ${
                  state.daysSincePurchase !== null && state.daysSincePurchase <= 30
                    ? "bg-emerald-50 text-emerald-700 border border-emerald-200/60"
                    : "bg-slate-100 text-slate-500 border border-slate-200/60"
                }`}
              >
                <span className="material-symbols-outlined text-[22px]">schedule</span>
              </div>
              <div className="flex flex-col min-w-0">
                <div className="flex items-center gap-2">
                  <h4 className="font-sans font-bold text-slate-900 text-sm sm:text-base tracking-tight">
                    Até 30 Dias
                  </h4>
                  <span className="font-sans text-[11px] font-semibold text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded shrink-0">
                    Janela Regular
                  </span>
                </div>
                <p className="font-sans text-xs text-slate-500 mt-0.5 leading-relaxed">
                  Compra efetuada há menos de 30 dias. Elegível para reembolso integral ou troca
                </p>
              </div>
            </div>

            <div
              aria-hidden="true"
              className={`w-5 h-5 rounded-full flex items-center justify-center shrink-0 transition-colors ${
                state.daysSincePurchase !== null && state.daysSincePurchase <= 30
                  ? "bg-emerald-600 text-white"
                  : "border-2 border-slate-300"
              }`}
            >
              {state.daysSincePurchase !== null && state.daysSincePurchase <= 30 && (
                <span className="material-symbols-outlined text-[13px] font-bold">check</span>
              )}
            </div>
          </div>

          {/* Card: Mais de 30 Dias */}
          <div
            role="radio"
            aria-checked={state.daysSincePurchase !== null && state.daysSincePurchase > 30}
            tabIndex={0}
            onClick={() => setField("daysSincePurchase", 45)}
            onKeyDown={(e) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault();
                setField("daysSincePurchase", 45);
              }
            }}
            className={`group rounded-xl p-4 sm:p-5 cursor-pointer flex items-center justify-between gap-4 transition-all duration-150 focus-visible:outline-2 focus-visible:outline-emerald-600 bg-white ${
              state.daysSincePurchase !== null && state.daysSincePurchase > 30
                ? "border-2 border-amber-500"
                : "border border-slate-200 hover:border-slate-300"
            }`}
          >
            <div className="flex items-center gap-3.5 min-w-0">
              <div
                className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-colors ${
                  state.daysSincePurchase !== null && state.daysSincePurchase > 30
                    ? "bg-amber-50 text-amber-700 border border-amber-200/60"
                    : "bg-slate-100 text-slate-500 border border-slate-200/60"
                }`}
              >
                <span className="material-symbols-outlined text-[22px]">history_toggle_off</span>
              </div>
              <div className="flex flex-col min-w-0">
                <div className="flex items-center gap-2">
                  <h4 className="font-sans font-bold text-slate-900 text-sm sm:text-base tracking-tight">
                    Mais de 30 Dias
                  </h4>
                  <span className="font-sans text-[11px] font-semibold text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded shrink-0">
                    Fora de Prazo
                  </span>
                </div>
                <p className="font-sans text-xs text-slate-500 mt-0.5 leading-relaxed">
                  Compra efetuada há mais de 30 dias. Sujeito a crédito em loja ou valor residual
                </p>
              </div>
            </div>

            <div
              aria-hidden="true"
              className={`w-5 h-5 rounded-full flex items-center justify-center shrink-0 transition-colors ${
                state.daysSincePurchase !== null && state.daysSincePurchase > 30
                  ? "bg-amber-500 text-white"
                  : "border-2 border-slate-300"
              }`}
            >
              {state.daysSincePurchase !== null && state.daysSincePurchase > 30 && (
                <span className="material-symbols-outlined text-[13px] font-bold">check</span>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

