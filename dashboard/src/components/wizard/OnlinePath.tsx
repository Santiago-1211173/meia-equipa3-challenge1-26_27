"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { useWizard } from "./WizardContext";
import VerdictScreen from "./VerdictScreen";
import { api, ApiClientError } from "@/client/api";
import type { DecisaoResponse } from "@/types/returns";

export default function OnlinePath() {
  const router = useRouter();
  const {
    state,
    setField,
    buildReturnRequest,
    resetWizard,
    evaluationResult,
    lastRequest,
    evaluationDurationMs,
    setEvaluationData,
    exitTo,
  } = useWizard();

  const [isProcessing, setIsProcessing] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [durationMs, setDurationMs] = useState<number>(0);

  // Manipular processamento na BackPocket
  const handleProcessBackPocket = async () => {
    setIsProcessing(true);
    setErrorMessage(null);

    // Assegurar campos de compra online coerentes
    setField("purchaseChannel", "ONLINE_BACKPOCKET");
    if (state.onlineInStoreExchange) {
      setField("requestType", "TROCA");
      setField("exchangeOption", "MESMO_MODELO");
    } else {
      setField("requestType", "DEVOLUCAO");
      setField("exchangeOption", "NENHUMA");
    }

    if (state.onlineOrderFound) {
      setField("proofOfPurchase", "CONFIRMACAO_ONLINE");
    } else {
      setField("proofOfPurchase", "SEM_COMPROVATIVO");
    }

    if (state.onlineDaysWindow === "UNDER_30") {
      setField("daysSincePurchase", 14);
    } else {
      setField("daysSincePurchase", 45);
    }

    const payload = buildReturnRequest();

    const endpoint =
      state.engine === "prolog"
        ? "/api/prolog/avaliar"
        : "/api/returns/avaliar";

    const startTime = performance.now();
    try {
      const response = await api<DecisaoResponse>(endpoint, {
        method: "POST",
        body: payload,
      });
      const duration = Math.round(performance.now() - startTime);
      setDurationMs(duration);
      setEvaluationData(response, payload, duration);
      router.push("/novo-atendimento/veredito");
    } catch (err: unknown) {
      let msg = "Não foi possível concluir o processamento no motor.";
      if (err instanceof ApiClientError) {
        msg = err.message;
      } else if (err instanceof Error) {
        msg = err.message;
      }
      setErrorMessage(msg);
    } finally {
      setIsProcessing(false);
    }
  };

  // Se já temos veredito avaliado pelo motor (fallback inline)
  if (evaluationResult) {
    return (
      <div className="w-full max-w-4xl mx-auto px-4 sm:px-6 py-4">
        <VerdictScreen
          result={evaluationResult}
          request={lastRequest || buildReturnRequest()}
          engine={state.engine || "returns"}
          durationMs={durationMs || evaluationDurationMs}
          currency={state.currency}
          onReset={() => {
            exitTo("/novo-atendimento/passo/1");
          }}
          onHome={() => {
            exitTo("/");
          }}
        />
      </div>
    );
  }

  // Previsão textual do veredito para o assistente de balcão (XAI Live)
  const getExpectedResolution = () => {
    if (state.onlineInStoreExchange) {
      return {
        badge: "Troca Imediata",
        badgeVariant: "bg-blue-100 text-blue-900 border-blue-200",
        headline: "Troca Imediata no Balcão por Artigo de Loja",
        detail:
          "Substituição direta de tamanho ou cor do artigo de comércio eletrónico sem acerto adicional de valor em caixa.",
      };
    }

    if (!state.onlineOrderFound) {
      return {
        badge: "Requer Validação",
        badgeVariant: "bg-amber-100 text-amber-900 border-amber-200",
        headline: "Devolução sem Encomenda Localizada",
        detail:
          "Sem número de encomenda confirmado no BackPocket. Proceder a devolução às cegas com emissão de vale de loja após conferência física.",
      };
    }

    if (state.onlinePaymentMethod === "BNPL") {
      return {
        badge: "Reembolso Digital App",
        badgeVariant: "bg-rose-100 text-rose-900 border-rose-200",
        headline: "Estorno Conduzido na App Afterpay",
        detail:
          "Estorno restrito pela plataforma Afterpay. Bloqueio total de reembolso em numerário ou cartão físico na caixa de loja.",
      };
    }

    if (state.onlineDaysWindow === "OVER_30") {
      return {
        badge: "Vale de Loja",
        badgeVariant: "bg-amber-100 text-amber-900 border-amber-200",
        headline: "Emissão de Cartão de Oferta / Vale Levi's",
        detail:
          "Janela de devolução online superior a 30 dias decorridos da expedição. Compensação atribuída em saldo de loja.",
      };
    }

    return {
      badge: "Estorno Integral",
      badgeVariant: "bg-emerald-100 text-emerald-900 border-emerald-200",
      headline: "Estorno Tokenizado no Cartão Original",
      detail:
        "Reembolso automático e seguro para a conta bancária do cliente através do token guardado no gateway de comércio eletrónico.",
    };
  };

  const preview = getExpectedResolution();

  return (
    <div className="w-full max-w-full sm:max-w-xl md:max-w-[680px] lg:max-w-5xl xl:max-w-6xl mx-auto px-4 sm:px-6 flex flex-col items-center gap-8">
      {/* Modal de Loading ao Processar na BackPocket */}
      {isProcessing && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl p-8 max-w-md w-full flex flex-col items-center gap-4 text-center shadow-2xl border-2 border-emerald-400">
            <div className="w-16 h-16 rounded-3xl bg-emerald-100 text-primary flex items-center justify-center shadow-[0_4px_0_#A7F3D0]">
              <span className="material-symbols-outlined text-[36px] animate-spin">
                refresh
              </span>
            </div>
            <div className="flex flex-col gap-1">
              <h3 className="font-sans text-on-surface text-xl font-bold">
                A Conectar à BackPocket...
              </h3>
              <p className="font-sans text-on-surface-variant text-xs sm:text-sm">
                A sincronizar o pedido web com o motor{" "}
                <span className="font-bold text-primary">
                  {state.engine === "prolog" ? "Prolog (Dedução Lógica)" : "Drools (Regras Rete-OO)"}
                </span>{" "}
                e a validar as políticas de liquidação digital.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Progress Indicator & Flow Header */}
      <div className="w-full flex flex-col items-center text-center gap-3">
        {/* Conditional Branch Pill */}
        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-emerald-50 border border-emerald-200/80 text-primary shadow-xs">
          <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
          <span className="font-sans text-xs font-extrabold uppercase tracking-wider">
            COMPRA ONLINE &amp; BACKPOCKET • FLUXO ASSISTIDO
          </span>
        </div>

        {/* Segmented Step Bar (Duolingo Style) */}
        <div className="w-full max-w-md flex items-center gap-2 my-1">
          <div className="h-2 flex-1 rounded-full bg-primary" />
          <div className="h-2 flex-1 rounded-full bg-primary" />
          <div className="h-2 flex-1 rounded-full bg-primary relative overflow-hidden">
            <span className="absolute inset-0 bg-primary-container animate-pulse opacity-60" />
          </div>
          <div className="h-2 flex-1 rounded-full bg-surface-container-highest" />
        </div>

        <h1 className="font-display text-3xl sm:text-4xl font-extrabold text-on-surface tracking-tight">
          Caminho Online &amp; BackPocket
        </h1>
        <p className="font-sans text-sm sm:text-base text-on-surface-variant max-w-xl font-medium">
          Tratamento simples de encomendas levi.com / levi.ca e pedidos BackPocket
        </p>
      </div>

      {/* TACTILE CARDS CONTAINER */}
      <div className="w-full flex flex-col gap-6">
        {/* BLOCO 1: Localização da Encomenda Web */}
        <section className="bg-white rounded-[2.5rem] p-6 sm:p-8 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-surface-container-highest/60 flex flex-col gap-6 transition-all hover:shadow-[0_12px_36px_rgb(0,0,0,0.06)]">
          <div className="flex items-center justify-between border-b border-surface-container-low pb-4">
            <div className="flex items-center gap-3">
              <div className="font-mono tabular-nums w-9 h-9 rounded-2xl bg-emerald-100 text-primary font-bold text-sm flex items-center justify-center shadow-xs">
                1
              </div>
              <div>
                <h2 className="font-sans text-lg sm:text-xl font-bold text-on-surface">
                  Localização da Encomenda Web
                </h2>
                <p className="font-sans text-xs text-on-surface-variant font-medium">
                  Validação de Encomenda &amp; Prova de Compra
                </p>
              </div>
            </div>
            {state.onlineOrderFound ? (
              <span className="font-sans inline-flex items-center gap-1 px-3 py-1 rounded-full bg-emerald-50 text-emerald-800 border border-emerald-200 text-xs font-bold shadow-xs">
                <span className="material-symbols-outlined text-[15px] text-primary">verified</span>
                <span>Pronto a Processar</span>
              </span>
            ) : (
              <span className="font-sans inline-flex items-center gap-1 px-3 py-1 rounded-full bg-amber-50 text-amber-800 border border-amber-200 text-xs font-bold shadow-xs">
                <span className="material-symbols-outlined text-[15px] text-amber-600">warning</span>
                <span>Requer Verificação</span>
              </span>
            )}
          </div>

          {/* Interactive Simulated Order Scan / Lookup Bar */}
          <div className="bg-surface-container-low/70 rounded-2xl p-4 border border-surface-container-highest/70 flex flex-col sm:flex-row items-center justify-between gap-3">
            <div className="flex items-center gap-3 w-full sm:w-auto">
              <div className="w-9 h-9 rounded-xl bg-white border border-border-card flex items-center justify-center text-primary shadow-xs">
                <span className="material-symbols-outlined text-[20px]">qr_code_scanner</span>
              </div>
              <div className="flex flex-col">
                <span className="font-sans text-[11px] font-extrabold uppercase tracking-wider text-on-surface-variant">
                  Referência da Encomenda Web
                </span>
                <span className="font-mono tabular-nums text-sm font-bold text-on-surface">
                  {state.onlineOrderNumber || "WEB-84920-PT"}
                </span>
              </div>
            </div>
            <div className="flex items-center gap-2 self-end sm:self-center font-sans">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <span className="text-xs font-bold text-on-surface-variant">
                Canal: levi.com • Token BackPocket Ativo
              </span>
            </div>
          </div>

          {/* Question Options (Tactile Duolingo Cards) */}
          <div className="flex flex-col gap-2.5">
            <label className="font-sans text-xs font-extrabold uppercase tracking-wider text-on-surface-variant">
              A encomenda foi localizada no portal BackPocket ou Levi.com?
            </label>
            <div role="radiogroup" aria-label="Localização da encomenda web" className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
              {/* Option 1: Selected */}
              <button
                type="button"
                role="radio"
                aria-checked={state.onlineOrderFound}
                onClick={() => {
                  setField("onlineOrderFound", true);
                  setField("proofOfPurchase", "CONFIRMACAO_ONLINE");
                }}
                className={`relative rounded-2xl p-4 sm:p-5 flex items-start gap-3.5 text-left transition-all cursor-pointer focus-visible:outline-2 focus-visible:outline-primary ${
                  state.onlineOrderFound
                    ? "bg-emerald-50/70 border-2 border-primary shadow-sm translate-y-[-1px]"
                    : "bg-white border-2 border-surface-container-highest/80 hover:border-outline-variant opacity-70 hover:opacity-100"
                }`}
              >
                <div
                  className={`w-6 h-6 rounded-full flex items-center justify-center shrink-0 mt-0.5 ${
                    state.onlineOrderFound
                      ? "bg-primary text-white shadow-xs"
                      : "border-2 border-outline-variant bg-white"
                  }`}
                >
                  {state.onlineOrderFound && (
                    <span className="material-symbols-outlined text-[16px] font-bold">check</span>
                  )}
                </div>
                <div className="flex flex-col">
                  <span className="font-sans text-sm font-bold text-on-surface">
                    Sim, Encomenda Localizada
                  </span>
                  <span className="font-sans text-xs text-on-surface-variant mt-0.5 leading-relaxed font-medium">
                    Comprovativo eletrónico e dados da encomenda confirmados.
                  </span>
                </div>
              </button>

              {/* Option 2: Unselected */}
              <button
                type="button"
                role="radio"
                aria-checked={!state.onlineOrderFound}
                onClick={() => {
                  setField("onlineOrderFound", false);
                  setField("proofOfPurchase", "SEM_COMPROVATIVO");
                }}
                className={`relative rounded-2xl p-4 sm:p-5 flex items-start gap-3.5 text-left transition-all cursor-pointer focus-visible:outline-2 focus-visible:outline-primary ${
                  !state.onlineOrderFound
                    ? "bg-amber-50/70 border-2 border-amber-500 shadow-sm translate-y-[-1px]"
                    : "bg-white border-2 border-surface-container-highest/80 hover:border-outline-variant opacity-70 hover:opacity-100"
                }`}
              >
                <div
                  className={`w-6 h-6 rounded-full flex items-center justify-center shrink-0 mt-0.5 ${
                    !state.onlineOrderFound
                      ? "bg-amber-600 text-white shadow-xs"
                      : "border-2 border-outline-variant bg-white"
                  }`}
                >
                  {!state.onlineOrderFound && (
                    <span className="material-symbols-outlined text-[16px] font-bold">check</span>
                  )}
                </div>
                <div className="flex flex-col">
                  <span className="font-sans text-sm font-bold text-on-surface">
                    Não Encontrada / Sem Registo
                  </span>
                  <span className="font-sans text-xs text-on-surface-variant mt-0.5 leading-relaxed font-medium">
                    Requer verificação manual ou devolução sem registo prévio.
                  </span>
                </div>
              </button>
            </div>
          </div>
        </section>

        {/* BLOCO 2: Método de Pagamento Original & Compliance */}
        <section className="bg-white rounded-[2.5rem] p-6 sm:p-8 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-surface-container-highest/60 flex flex-col gap-6 transition-all hover:shadow-[0_12px_36px_rgb(0,0,0,0.06)]">
          <div className="flex items-center justify-between border-b border-surface-container-low pb-4">
            <div className="flex items-center gap-3">
              <div className="font-mono tabular-nums w-9 h-9 rounded-2xl bg-emerald-100 text-primary font-bold text-sm flex items-center justify-center shadow-xs">
                2
              </div>
              <div>
                <h2 className="font-sans text-lg sm:text-xl font-bold text-on-surface">
                  Método de Pagamento Original
                </h2>
                <p className="font-sans text-xs text-on-surface-variant font-medium">
                  Identificação do meio original de pagamento
                </p>
              </div>
            </div>
            <span className="font-sans inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-surface-container text-on-surface text-xs font-bold">
              <span className="w-2 h-2 rounded-full bg-primary" />
              <span>
                {state.onlinePaymentMethod === "CC"
                  ? "Detetado: CC Tokenizado"
                  : state.onlinePaymentMethod === "BNPL"
                  ? "Detetado: Afterpay (BNPL)"
                  : state.onlinePaymentMethod === "PAYPAL"
                  ? "Detetado: PayPal / Venmo"
                  : "Detetado: Carteira Digital"}
              </span>
            </span>
          </div>

          {/* Compliance Notice para Afterpay (BNPL) */}
          {state.onlinePaymentMethod === "BNPL" && (
            <div className="p-4 rounded-2xl bg-amber-50 border-2 border-amber-300 flex items-start gap-3.5 shadow-xs animate-in fade-in duration-200">
              <span className="material-symbols-outlined text-amber-700 text-[24px] mt-0.5">
                warning
              </span>
              <div className="flex flex-col text-xs text-amber-950 font-sans">
                <span className="font-sans font-bold text-sm text-amber-900">
                  Regra Estrita de Reembolso BNPL / Afterpay
                </span>
                <span className="mt-0.5 leading-relaxed">
                  Compras efetuadas via Afterpay só podem ser estornadas através da aplicação móvel ou substituídas por vale de loja no balcão. Reembolso direto em dinheiro ou cartão físico em caixa é estritamente bloqueado.
                </span>
              </div>
            </div>
          )}

          {/* 2x2 Payment Tender Grid */}
          <div className="flex flex-col gap-2.5">
            <label className="font-sans text-xs font-extrabold uppercase tracking-wider text-on-surface-variant">
              Selecione o meio original de liquidação:
            </label>
            <div role="radiogroup" aria-label="Método de pagamento original" className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
              {/* Card 1: Credit / Debit */}
              <button
                type="button"
                role="radio"
                aria-checked={state.onlinePaymentMethod === "CC"}
                onClick={() => setField("onlinePaymentMethod", "CC")}
                className={`relative rounded-2xl p-4 flex flex-col gap-2.5 text-left transition-all cursor-pointer focus-visible:outline-2 focus-visible:outline-primary ${
                  state.onlinePaymentMethod === "CC"
                    ? "bg-emerald-50/70 border-2 border-primary shadow-sm"
                    : "bg-white border-2 border-surface-container-highest/80 hover:border-outline-variant opacity-80 hover:opacity-100"
                }`}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <span className="material-symbols-outlined text-primary text-[22px]">
                      credit_card
                    </span>
                    <span className="font-sans text-sm font-bold text-on-surface">
                      Cartão de Crédito/Débito
                    </span>
                  </div>
                  <div
                    className={`w-5 h-5 rounded-full flex items-center justify-center text-xs ${
                      state.onlinePaymentMethod === "CC"
                        ? "bg-primary text-white"
                        : "border-2 border-outline-variant"
                    }`}
                  >
                    {state.onlinePaymentMethod === "CC" && (
                      <span className="material-symbols-outlined text-[14px]">check</span>
                    )}
                  </div>
                </div>
                <div className="flex items-center justify-between pt-1 font-sans">
                  <span className="text-xs text-on-surface-variant font-medium">
                    Visa •••• 4920
                  </span>
                  <span className="px-2.5 py-0.5 rounded-full bg-emerald-200/70 text-emerald-900 text-[11px] font-extrabold">
                    Token BackPocket Ativo
                  </span>
                </div>
              </button>

              {/* Card 2: Afterpay */}
              <button
                type="button"
                role="radio"
                aria-checked={state.onlinePaymentMethod === "BNPL"}
                onClick={() => setField("onlinePaymentMethod", "BNPL")}
                className={`relative rounded-2xl p-4 flex flex-col gap-2.5 text-left transition-all cursor-pointer focus-visible:outline-2 focus-visible:outline-primary ${
                  state.onlinePaymentMethod === "BNPL"
                    ? "bg-amber-50/80 border-2 border-amber-500 shadow-sm"
                    : "bg-white border-2 border-surface-container-highest/80 hover:border-amber-400 opacity-80 hover:opacity-100"
                }`}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <span className="material-symbols-outlined text-amber-700 text-[22px]">
                      hourglass_top
                    </span>
                    <span className="font-sans text-sm font-bold text-on-surface">
                      Afterpay (BNPL)
                    </span>
                  </div>
                  <span className="font-sans px-2 py-0.5 rounded-md bg-rose-100 text-rose-700 text-[10px] font-extrabold">
                    Reembolso via App
                  </span>
                </div>
                <span className="font-sans text-xs text-on-surface-variant leading-tight font-medium">
                  Reembolso estrito pela app. Bloqueio em caixa.
                </span>
              </button>

              {/* Card 3: PayPal / Venmo */}
              <button
                type="button"
                role="radio"
                aria-checked={state.onlinePaymentMethod === "PAYPAL"}
                onClick={() => setField("onlinePaymentMethod", "PAYPAL")}
                className={`relative rounded-2xl p-4 flex flex-col gap-2.5 text-left transition-all cursor-pointer focus-visible:outline-2 focus-visible:outline-primary ${
                  state.onlinePaymentMethod === "PAYPAL"
                    ? "bg-blue-50/80 border-2 border-secondary shadow-sm"
                    : "bg-white border-2 border-surface-container-highest/80 hover:border-outline-variant opacity-80 hover:opacity-100"
                }`}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <span className="material-symbols-outlined text-secondary text-[22px]">
                      account_balance_wallet
                    </span>
                    <span className="font-sans text-sm font-bold text-on-surface">
                      PayPal / Venmo
                    </span>
                  </div>
                  <div
                    className={`w-5 h-5 rounded-full flex items-center justify-center text-xs ${
                      state.onlinePaymentMethod === "PAYPAL"
                        ? "bg-secondary text-white"
                        : "border-2 border-outline-variant"
                    }`}
                  >
                    {state.onlinePaymentMethod === "PAYPAL" && (
                      <span className="material-symbols-outlined text-[14px]">check</span>
                    )}
                  </div>
                </div>
                <span className="font-sans text-xs text-on-surface-variant leading-tight font-medium">
                  Crédito estornado à conta de origem digital.
                </span>
              </button>

              {/* Card 4: Apple / Google Pay */}
              <button
                type="button"
                role="radio"
                aria-checked={state.onlinePaymentMethod === "WALLETS"}
                onClick={() => setField("onlinePaymentMethod", "WALLETS")}
                className={`relative rounded-2xl p-4 flex flex-col gap-2.5 text-left transition-all cursor-pointer focus-visible:outline-2 focus-visible:outline-primary ${
                  state.onlinePaymentMethod === "WALLETS"
                    ? "bg-emerald-50/70 border-2 border-primary shadow-sm"
                    : "bg-white border-2 border-surface-container-highest/80 hover:border-outline-variant opacity-80 hover:opacity-100"
                }`}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <span className="material-symbols-outlined text-on-surface text-[22px]">
                      contactless
                    </span>
                    <span className="font-sans text-sm font-bold text-on-surface">
                      Apple Pay / Google Pay
                    </span>
                  </div>
                  <div
                    className={`w-5 h-5 rounded-full flex items-center justify-center text-xs ${
                      state.onlinePaymentMethod === "WALLETS"
                        ? "bg-primary text-white"
                        : "border-2 border-outline-variant"
                    }`}
                  >
                    {state.onlinePaymentMethod === "WALLETS" && (
                      <span className="material-symbols-outlined text-[14px]">check</span>
                    )}
                  </div>
                </div>
                <span className="font-sans text-xs text-on-surface-variant leading-tight font-medium">
                  Reembolso por aproximação ou via token salvaguardado.
                </span>
              </button>
            </div>
          </div>
        </section>

        {/* BLOCO 3: Janela de Expedição & Tipo de Resolução */}
        <section className="bg-white rounded-[2.5rem] p-6 sm:p-8 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-surface-container-highest/60 flex flex-col gap-6 transition-all hover:shadow-[0_12px_36px_rgb(0,0,0,0.06)]">
          <div className="flex items-center justify-between border-b border-surface-container-low pb-4">
            <div className="flex items-center gap-3">
              <div className="font-mono tabular-nums w-9 h-9 rounded-2xl bg-emerald-100 text-primary font-bold text-sm flex items-center justify-center shadow-xs">
                3
              </div>
              <div>
                <h2 className="font-sans text-lg sm:text-xl font-bold text-on-surface">
                  Janela de Expedição &amp; Tipo de Resolução
                </h2>
                <p className="font-sans text-xs text-on-surface-variant font-medium">
                  Prazo de envio e preferência de devolução ou troca
                </p>
              </div>
            </div>
            <span className="font-sans inline-flex items-center gap-1 px-3 py-1 rounded-full bg-surface-container-low border border-surface-container-highest text-on-surface text-xs font-bold">
              {state.onlineDaysWindow === "UNDER_30"
                ? "Envio: há 14 dias"
                : "Envio: há 45 dias"}
            </span>
          </div>

          {/* Time Window Selection */}
          <div className="flex flex-col gap-2.5">
            <label className="font-sans text-xs font-extrabold uppercase tracking-wider text-on-surface-variant">
              Prazo decorrido desde a data de despacho (Tracking eletrónico):
            </label>
            <div role="radiogroup" aria-label="Prazo decorrido desde o despacho" className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
              {/* Option 1: <= 30 days */}
              <button
                type="button"
                role="radio"
                aria-checked={state.onlineDaysWindow === "UNDER_30"}
                onClick={() => {
                  setField("onlineDaysWindow", "UNDER_30");
                  setField("daysSincePurchase", 14);
                }}
                className={`relative rounded-2xl p-4 sm:p-5 flex items-start gap-3.5 text-left transition-all cursor-pointer focus-visible:outline-2 focus-visible:outline-primary ${
                  state.onlineDaysWindow === "UNDER_30"
                    ? "bg-emerald-50/70 border-2 border-primary shadow-sm"
                    : "bg-white border-2 border-surface-container-highest/80 hover:border-outline-variant opacity-70 hover:opacity-100"
                }`}
              >
                <div
                  className={`w-6 h-6 rounded-full flex items-center justify-center shrink-0 mt-0.5 ${
                    state.onlineDaysWindow === "UNDER_30"
                      ? "bg-primary text-white"
                      : "border-2 border-outline-variant bg-white"
                  }`}
                >
                  {state.onlineDaysWindow === "UNDER_30" && (
                    <span className="material-symbols-outlined text-[16px] font-bold">check</span>
                  )}
                </div>
                <div className="flex flex-col">
                  <span className="font-sans text-sm font-bold text-on-surface">
                    ≤ 30 dias desde o envio
                  </span>
                  <span className="font-sans text-xs text-on-surface-variant mt-0.5 leading-relaxed font-medium">
                    Elegível para estorno integral no método original de compra.
                  </span>
                </div>
              </button>

              {/* Option 2: > 30 days */}
              <button
                type="button"
                role="radio"
                aria-checked={state.onlineDaysWindow === "OVER_30"}
                onClick={() => {
                  setField("onlineDaysWindow", "OVER_30");
                  setField("daysSincePurchase", 45);
                }}
                className={`relative rounded-2xl p-4 sm:p-5 flex items-start gap-3.5 text-left transition-all cursor-pointer focus-visible:outline-2 focus-visible:outline-primary ${
                  state.onlineDaysWindow === "OVER_30"
                    ? "bg-amber-50/70 border-2 border-amber-500 shadow-sm"
                    : "bg-white border-2 border-surface-container-highest/80 hover:border-outline-variant opacity-70 hover:opacity-100"
                }`}
              >
                <div
                  className={`w-6 h-6 rounded-full flex items-center justify-center shrink-0 mt-0.5 ${
                    state.onlineDaysWindow === "OVER_30"
                      ? "bg-amber-600 text-white"
                      : "border-2 border-outline-variant bg-white"
                  }`}
                >
                  {state.onlineDaysWindow === "OVER_30" && (
                    <span className="material-symbols-outlined text-[16px] font-bold">check</span>
                  )}
                </div>
                <div className="flex flex-col">
                  <span className="font-sans text-sm font-bold text-on-surface">
                    &gt; 30 dias desde o envio
                  </span>
                  <span className="font-sans text-xs text-on-surface-variant mt-0.5 leading-relaxed font-medium">
                    Elegível para Cartão de Oferta / Vale de Loja Levi&apos;s.
                  </span>
                </div>
              </button>
            </div>
          </div>

          {/* Troca vs Devolução Pura */}
          <div className="bg-surface-container-low/60 rounded-2xl p-4 sm:p-5 border border-surface-container-highest/70 flex flex-col gap-3">
            <div className="flex items-center justify-between">
              <span className="font-sans text-xs font-extrabold uppercase tracking-wider text-on-surface">
                O cliente pretende trocar de artigo diretamente no balcão?
              </span>
              <span className="font-sans px-2.5 py-0.5 rounded-full bg-secondary-fixed text-on-secondary-fixed text-[11px] font-extrabold">
                Omnicanal
              </span>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => {
                  setField("onlineInStoreExchange", true);
                  setField("requestType", "TROCA");
                  setField("exchangeOption", "MESMO_MODELO");
                }}
                className={`font-sans font-semibold text-xs py-3 px-4 rounded-xl flex items-center justify-center gap-2 transition-all cursor-pointer ${
                  state.onlineInStoreExchange
                    ? "bg-blue-100/80 border-2 border-secondary text-secondary shadow-xs font-bold"
                    : "bg-white border-2 border-surface-container-highest hover:border-outline-variant text-on-surface-variant opacity-80 hover:opacity-100"
                }`}
              >
                <span className="material-symbols-outlined text-[18px]">cached</span>
                <span>Sim, trocar tamanho/cor no balcão</span>
              </button>

              <button
                type="button"
                onClick={() => {
                  setField("onlineInStoreExchange", false);
                  setField("requestType", "DEVOLUCAO");
                  setField("exchangeOption", "NENHUMA");
                }}
                className={`font-sans font-semibold text-xs py-3 px-4 rounded-xl flex items-center justify-center gap-2 transition-all cursor-pointer ${
                  !state.onlineInStoreExchange
                    ? "bg-emerald-100/70 border-2 border-primary text-primary shadow-xs font-bold"
                    : "bg-white border-2 border-surface-container-highest hover:border-outline-variant text-on-surface-variant opacity-80 hover:opacity-100"
                }`}
              >
                <span className="material-symbols-outlined text-[18px]">
                  assignment_returned
                </span>
                <span>Não, apenas devolução de artigo</span>
              </button>
            </div>
          </div>
        </section>

        {/* CARD 4: PRÉ-VISUALIZAÇÃO DA DECISÃO (XAI LIVE - ESTILO DUOLINGO MINT) */}
        <section className="bg-emerald-50/80 border-2 border-emerald-300 rounded-[2.5rem] p-6 sm:p-7 shadow-sm flex flex-col gap-4">
          <div className="flex items-center justify-between border-b border-emerald-200/80 pb-3 flex-wrap gap-2">
            <div className="flex items-center gap-2 text-primary font-sans font-bold text-sm">
              <span className="material-symbols-outlined text-[20px]">auto_awesome</span>
              <span>Previsão de Resolução Comercial</span>
            </div>
            <span
              className={`font-sans px-3 py-1 rounded-full text-xs font-extrabold border ${preview.badgeVariant}`}
            >
              {preview.badge}
            </span>
          </div>

          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex flex-col">
              <span className="font-sans text-base sm:text-lg text-on-surface font-bold">
                {preview.headline}
              </span>
              <p className="font-sans text-xs sm:text-sm text-on-surface-variant mt-1 leading-relaxed">
                {preview.detail}
              </p>
            </div>
            <div className="flex flex-col items-end shrink-0 bg-white px-4 py-2.5 rounded-2xl border border-emerald-200 shadow-xs">
              <span className="font-sans text-[10px] uppercase tracking-wider font-extrabold text-on-surface-variant">
                Valor Total Transação
              </span>
              <span className="font-sans tabular-nums text-xl font-extrabold text-primary">
                {(state.totalPrice ?? 89.9).toFixed(2)} {state.currency}
              </span>
            </div>
          </div>
        </section>
      </div>

      {/* Tactile Error Card with Retry Button */}
      {errorMessage && (
        <div
          role="alert"
          className="w-full p-5 sm:p-6 rounded-2xl bg-red-50/95 border-2 border-red-300 text-red-950 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 shadow-sm animate-in fade-in duration-200"
        >
          <div className="flex items-start gap-3.5">
            <div className="w-11 h-11 rounded-2xl bg-red-100 border border-red-200 text-red-600 flex items-center justify-center shrink-0">
              <span className="material-symbols-outlined text-[26px]">warning</span>
            </div>
            <div className="flex flex-col">
              <span className="font-sans text-sm font-bold text-red-900">
                Erro ao processar na BackPocket
              </span>
              <span className="font-sans text-xs sm:text-sm text-red-800 mt-0.5">
                {errorMessage}
              </span>
            </div>
          </div>

          <button
            type="button"
            onClick={handleProcessBackPocket}
            className="w-full sm:w-auto px-5 py-2.5 rounded-full bg-red-600 hover:bg-red-700 text-white font-sans text-xs sm:text-sm font-semibold flex items-center justify-center gap-2 shadow-[0_3px_0_#991b1b] hover:translate-y-0.5 active:translate-y-1 transition-all cursor-pointer shrink-0"
          >
            <span className="material-symbols-outlined text-[18px]">refresh</span>
            <span>Tentar novamente</span>
          </button>
        </div>
      )}

      {/* BOTTOM ACTION BAR (STICKY DUOLINGO-STYLE PILL TRAY) */}
      <div className="w-full bg-white/95 backdrop-blur-md border border-surface-container-highest/80 rounded-3xl p-4 sm:p-5 shadow-[0_12px_36px_rgba(19,27,46,0.08)] flex flex-col sm:flex-row items-center justify-between gap-4">
        {/* Back Button (Soft Pill) */}
        <button
          type="button"
          onClick={() => router.push("/novo-atendimento/passo/2")}
          className="w-full sm:w-auto px-6 py-3.5 rounded-2xl bg-surface-container-low hover:bg-surface-container text-on-surface font-sans font-semibold text-sm flex items-center justify-center gap-2 border border-surface-container-highest/70 transition-all active:scale-[0.98] cursor-pointer"
        >
          <span className="material-symbols-outlined text-[18px]">arrow_back</span>
          <span>Voltar ao Passo 2</span>
        </button>

        {/* Status Tag Indicator */}
        <div className="hidden md:flex items-center gap-2 text-xs text-on-surface-variant font-sans font-bold">
          <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
          <span>Sem impedimentos fiscais • Conexão BackPocket ativa</span>
        </div>

        {/* 3D Tactile Emerald Primary Button (Duolingo Style) */}
        <button
          type="button"
          onClick={handleProcessBackPocket}
          disabled={isProcessing}
          className="w-full sm:w-auto px-8 py-4 rounded-2xl bg-[#006c49] hover:bg-[#00573a] text-white font-sans font-semibold text-sm sm:text-base tracking-wide flex items-center justify-center gap-2.5 shadow-[0_5px_0_#00422b] hover:shadow-[0_2px_0_#00422b] active:shadow-[0_0_0_#00422b] active:translate-y-[4px] transition-all cursor-pointer disabled:opacity-50"
        >
          <span>{isProcessing ? "A Conectar..." : "Processar na BackPocket"}</span>
          <span className="text-lg">🚀</span>
        </button>
      </div>
    </div>
  );
}
