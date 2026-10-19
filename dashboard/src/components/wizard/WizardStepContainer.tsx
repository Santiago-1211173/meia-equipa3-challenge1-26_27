"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { useWizard, getFirstIncompleteStep } from "./WizardContext";
import Step1EngineSelect from "./Step1EngineSelect";
import Step2MarketStore from "./Step2MarketStore";
import Step3ProductEligibility from "./Step3ProductEligibility";
import Step4ReceiptTimeline from "./Step4ReceiptTimeline";
import Step5ExchangeExceptions from "./Step5ExchangeExceptions";
import Step6Refund from "./Step6Refund";
import VerdictScreen from "./VerdictScreen";
import StepHeader, { StepEyebrow } from "@/components/ui/StepHeader";
import ProgressBar from "@/components/ui/ProgressBar";
import NavigationFooter from "@/components/ui/NavigationFooter";
import WhyAskWidget from "./WhyAskWidget";
import { api, ApiClientError } from "@/client/api";
import type { DecisaoResponse } from "@/types/returns";

interface WizardStepContainerProps {
  stepNumber: number;
}

const STEP_META: Record<
  number,
  { title: string; subtitle: string; nextLabel: string; nextHint: string }
> = {
  1: {
    title: "Selecione o Motor de Avaliação",
    subtitle:
      "Escolha o motor de inferência para processar as regras de devolução e troca",
    nextLabel: "Continuar para Passo 2",
    nextHint: "Mercado e Tipo de Loja",
  },
  2: {
    title: "Mercado e Tipo de Loja",
    subtitle:
      "Configure o território fiscal, o formato da loja recetora e a proveniência original da compra",
    nextLabel: "Continuar para Passo 3",
    nextHint: "Elegibilidade do Produto",
  },
  3: {
    title: "Elegibilidade do Produto",
    subtitle:
      "Confirme os detalhes da peça e a sua condição física para validar a devolução",
    nextLabel: "Continuar para Passo 4",
    nextHint: "Comprovativo e Prazo",
  },
  4: {
    title: "Comprovativo e Prazo",
    subtitle:
      "Verifique o tipo de pedido, o documento apresentado e o tempo decorrido desde a compra",
    nextLabel: "Continuar para Passo 5",
    nextHint: "Troca ou Exceção de Balcão",
  },
  5: {
    title: "Troca ou Exceção de Balcão",
    subtitle:
      "Indique se o cliente pretende trocar a peça ou se há contestação a requerer exceção",
    nextLabel: "Continuar para Passo 6",
    nextHint: "Meio de Reembolso e Liquidação",
  },
  6: {
    title: "Meio de Reembolso e Liquidação",
    subtitle:
      "Confirme a forma como o valor será devolvido ao cliente de forma automática",
    nextLabel: "Calcular Veredito Final",
    nextHint: "Submeter para Avaliação",
  },
};

export default function WizardStepContainer({ stepNumber }: WizardStepContainerProps) {
  const router = useRouter();
  const {
    state,
    totalSteps,
    isHydrated,
    isDirty,
    isLeaving,
    setShowLeaveModal,
    setPendingNavigationUrl,
    goToStep,
    resetWizard,
    buildReturnRequest,
    evaluationResult,
    lastRequest,
    evaluationDurationMs,
    setEvaluationData,
    exitTo,
  } = useWizard();

  const [isEvaluating, setIsEvaluating] = useState<boolean>(false);
  const [evaluationError, setEvaluationError] = useState<string | null>(null);

  // Guarda Sequencial de Passos (Step Guard):
  // Impede que um utilizador aceda diretamente via URL sem ter completado os passos obrigatórios anteriores
  useEffect(() => {
    if (!isHydrated || isLeaving) return;
    const allowedStep = getFirstIncompleteStep(state);
    if (stepNumber > allowedStep) {
      router.replace(`/novo-atendimento/passo/${allowedStep}`);
    } else {
      goToStep(stepNumber);
    }
  }, [stepNumber, state, router, goToStep, isHydrated, isLeaving]);

  // Validações de obrigatoriedade por etapa (conforme especificações RPAC-Team3)
  const isStep1Valid = Boolean(state.engine);
  const isStep2Valid = Boolean(
    state.marketJurisdiction && state.storeType && state.purchaseChannel
  );
  const isResellRequired =
    state.physicalCondition === "NOVO_ETIQUETAS_SOLTAS" ||
    state.physicalCondition === "NOVO_SEM_ETIQUETAS";
  const isStep3Valid = Boolean(
    state.barcodeRecognized !== null &&
    state.brandAllowed !== null &&
    state.alteredOrHemmed !== null &&
    state.physicalCondition &&
    (!isResellRequired || state.readyToResell !== null)
  );
  const isStep4Valid = Boolean(
    state.requestType &&
    state.proofOfPurchase &&
    state.daysSincePurchase !== null
  );

  const isExchange = state.requestType === "TROCA";
  const isStep5Valid = Boolean(
    (!isExchange || (state.exchangeOption && state.exchangeOption !== "NENHUMA")) &&
    state.customerSituation &&
    state.managerException !== null
  );

  const isGift = state.requestType === "GIFT" || state.proofOfPurchase === "RECIBO_OFERTA";

  const isInteracValid = state.originalPaymentMethod !== "INTERAC" || state.physicalCardPresent !== null;
  const isPaypalValid = state.originalPaymentMethod !== "PAYPAL" || state.paymentAppAccessible !== null;
  const isEncerradaValid = state.accountState !== "ENCERRADA" || state.originalRefundRefused !== null;

  const isStep6Valid = isGift
    ? Boolean(state.totalPrice !== null && state.totalPrice > 0)
    : Boolean(
        state.totalPrice !== null &&
        state.totalPrice > 0 &&
        state.originalPaymentMethod &&
        state.accountState &&
        isInteracValid &&
        isPaypalValid &&
        isEncerradaValid
      );

  const isCurrentStepValid =
    stepNumber === 1 ? isStep1Valid :
    stepNumber === 2 ? isStep2Valid :
    stepNumber === 3 ? isStep3Valid :
    stepNumber === 4 ? isStep4Valid :
    stepNumber === 5 ? isStep5Valid :
    stepNumber === 6 ? isStep6Valid :
    true;

  const handleBack = () => {
    if (stepNumber <= 1) {
      if (isDirty) {
        setPendingNavigationUrl("/");
        setShowLeaveModal(true);
      } else {
        exitTo("/");
      }
    } else {
      router.push(`/novo-atendimento/passo/${stepNumber - 1}`);
    }
  };

  const handleLeave = () => {
    setPendingNavigationUrl("/");
    setShowLeaveModal(true);
  };

  const handleNext = async () => {
    // No passo 1, é obrigatório selecionar um motor antes de prosseguir
    if (stepNumber === 1 && !isStep1Valid) {
      return;
    }

    // No passo 2, é obrigatório definir jurisdição, formato e canal (IN-001, IN-002, IN-003)
    if (stepNumber === 2 && !isStep2Valid) {
      return;
    }

    // No passo 3, é obrigatório preencher a validação inicial e o estado físico
    if (stepNumber === 3 && !isStep3Valid) {
      return;
    }

    // No passo 4, é obrigatório preencher o tipo de pedido, comprovativo e prazo
    if (stepNumber === 4 && !isStep4Valid) {
      return;
    }

    // No passo 5, é obrigatório preencher a modalidade de troca (se for troca), situação de balcão e exceção
    if (stepNumber === 5 && !isStep5Valid) {
      return;
    }

    // No passo 6, é obrigatório preencher o valor, meio de pagamento original e estado da conta
    if (stepNumber === 6 && !isStep6Valid) {
      return;
    }

    if (stepNumber < totalSteps) {
      router.push(`/novo-atendimento/passo/${stepNumber + 1}`);
    } else {
      // Passo 6: Submeter para avaliação final no motor selecionado
      await handleEvaluate();
    }
  };

  const getStepHint = () => {
    if (stepNumber === 1) {
      return state.engine ? "Mercado e Tipo de Loja" : "Selecione um motor para prosseguir";
    }
    if (stepNumber === 2) {
      if (!isStep2Valid) {
        const missing = [];
        if (!state.marketJurisdiction) missing.push("Jurisdição");
        if (!state.storeType) missing.push("Formato");
        if (!state.purchaseChannel) missing.push("Canal");
        return `Obrigatório: selecionar ${missing.join(", ")}`;
      }
      return meta.nextHint;
    }
    if (stepNumber === 3) {
      if (!isStep3Valid) {
        const missing: string[] = [];
        if (state.barcodeRecognized === null) missing.push("Código de barras");
        if (state.brandAllowed === null) missing.push("Marca");
        if (state.alteredOrHemmed === null) missing.push("Bainhas");
        if (!state.physicalCondition) missing.push("Estado Físico");
        if (isResellRequired && state.readyToResell === null) missing.push("Revenda");
        return `Obrigatório: selecionar ${missing.slice(0, 2).join(", ")}${missing.length > 2 ? "..." : ""}`;
      }
      return meta.nextHint;
    }
    if (stepNumber === 4) {
      if (!isStep4Valid) {
        const missing: string[] = [];
        if (!state.requestType) missing.push("Tipo de Pedido");
        if (!state.proofOfPurchase) missing.push("Comprovativo");
        if (state.daysSincePurchase === null) missing.push("Prazo");
        return `Obrigatório: selecionar ${missing.slice(0, 2).join(", ")}${missing.length > 2 ? "..." : ""}`;
      }
      return isExchange ? "Modalidade de Troca e Exceção" : "Situação de Balcão e Exceção";
    }
    if (stepNumber === 5) {
      if (!isStep5Valid) {
        const missing: string[] = [];
        if (isExchange && (!state.exchangeOption || state.exchangeOption === "NENHUMA")) {
          missing.push("Modalidade");
        }
        if (!state.customerSituation) missing.push("Situação");
        if (state.managerException === null) missing.push("Exceção");
        return `Obrigatório: selecionar ${missing.join(", ")}`;
      }
      return meta.nextHint;
    }
    if (stepNumber === 6) {
      if (!isStep6Valid) {
        const missing: string[] = [];
        if (state.totalPrice === null || state.totalPrice <= 0) missing.push("Valor do Artigo");
        if (!isGift) {
          if (!state.originalPaymentMethod) missing.push("Meio de Pagamento");
          if (!state.accountState) missing.push("Estado da Conta");
          if (state.accountState === "ENCERRADA" && state.originalRefundRefused === null) {
            missing.push("Recusa no Terminal");
          }
          if (state.originalPaymentMethod === "INTERAC" && state.physicalCardPresent === null) {
            missing.push("Cartão Físico");
          }
          if (state.originalPaymentMethod === "PAYPAL" && state.paymentAppAccessible === null) {
            missing.push("Acesso App");
          }
        }
        return `Obrigatório: selecionar ${missing.slice(0, 2).join(", ")}${missing.length > 2 ? "..." : ""}`;
      }
      return meta.nextHint;
    }
    return meta.nextHint;
  };

  const handleEvaluate = async () => {
    setIsEvaluating(true);
    setEvaluationError(null);

    const requestPayload = buildReturnRequest();
    const endpoint =
      state.engine === "prolog"
        ? "/api/prolog/avaliar"
        : "/api/returns/avaliar";

    const startTime = performance.now();
    try {
      const response = await api<DecisaoResponse>(endpoint, {
        method: "POST",
        body: requestPayload,
      });
      const duration = Math.round(performance.now() - startTime);
      setEvaluationData(response, requestPayload, duration);
      router.push("/novo-atendimento/veredito");
    } catch (err: unknown) {
      let msg = "Não foi possível concluir a avaliação.";
      if (err instanceof ApiClientError) {
        msg = err.message;
      } else if (err instanceof Error) {
        msg = err.message;
      }
      setEvaluationError(msg);
    } finally {
      setIsEvaluating(false);
    }
  };

  const baseMeta = STEP_META[stepNumber] || STEP_META[1];
  const meta = {
    ...baseMeta,
    ...(stepNumber === 5
      ? {
          title: isExchange ? "Troca ou Exceção de Balcão" : "Situação de Balcão e Exceções",
          subtitle: isExchange
            ? "Indique a peça de substituição pretendida e se há contestação a requerer exceção"
            : "Indique se o cliente aceita a resolução padrão ou se há contestação a requerer exceção de gerência",
        }
      : {}),
  };



  // Se ainda estiver a carregar do sessionStorage ou a redirecionar por guarda de passos, mostrar loading discreto
  const allowedStep = getFirstIncompleteStep(state);
  const isGuarded = isHydrated && !isLeaving && stepNumber > allowedStep;

  if (!isHydrated || isGuarded) {
    return (
      <div className="w-full flex-1 flex items-center justify-center p-8 min-h-[300px]">
        <div className="w-8 h-8 border-2 border-emerald-600 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  // Caso tenhamos veredito final calculado
  if (evaluationResult) {
    return (
      <div className="w-full max-w-full sm:max-w-xl md:max-w-[680px] lg:max-w-5xl xl:max-w-6xl mx-auto px-4 sm:px-6 py-6">
        <VerdictScreen
          result={evaluationResult}
          request={lastRequest || buildReturnRequest()}
          engine={state.engine || "returns"}
          durationMs={evaluationDurationMs}
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

  return (
    <div className="w-full max-w-full sm:max-w-xl md:max-w-[680px] lg:max-w-5xl xl:max-w-5xl mx-auto px-4 sm:px-6 flex-1 flex flex-col justify-between pt-4 pb-2">
      {/* Modal Overlay de Loading com Animação Emerald */}
      {isEvaluating && (
        <div
          role="status"
          aria-live="polite"
          className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 animate-in fade-in duration-150"
        >
          <div className="card-tactile bg-white p-8 max-w-md w-full flex flex-col items-center gap-4 text-center shadow-2xl border-2 border-emerald-400">
            <div className="w-16 h-16 rounded-3xl bg-emerald-100 text-primary flex items-center justify-center shadow-[0_4px_0_#A7F3D0]">
              <span className="material-symbols-outlined text-[36px] animate-spin">
                refresh
              </span>
            </div>
            <div className="flex flex-col gap-1">
              <h3 className="font-sans text-on-surface text-xl font-bold">
                A Calcular Veredito Oficial...
              </h3>
              <p className="font-sans text-on-surface-variant text-xs sm:text-sm">
                A submeter pedido ao motor{" "}
                <span className="font-bold text-primary">
                  {state.engine === "prolog" ? "Prolog (Dedução Lógica)" : "Drools (Regras Rete-OO)"}
                </span>{" "}
                e a validar conformidade de balcão.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* 1. TOP ALIGNED: Step Indicator Eyebrow (circulado a vermelho) */}
      <div className="w-full flex justify-center pt-2 sm:pt-4 shrink-0">
        <StepEyebrow step={stepNumber} totalSteps={totalSteps} />
      </div>

      {/* 2. VERTICALLY CENTERED: Title + Subtitle + Content Cards (circulado a amarelo) */}
      <div className="w-full flex flex-col items-center my-auto py-4">
        {/* Screen Header (Title + Subtitle, without eyebrow) */}
        <StepHeader
          title={meta.title}
          subtitle={meta.subtitle}
          hideEyebrow={true}
        />

        {/* Step Content with smooth fade-in transition */}
        <div key={stepNumber} className="w-full animate-fade-in-step">
          {stepNumber === 1 && <Step1EngineSelect />}
          {stepNumber === 2 && <Step2MarketStore />}
          {stepNumber === 3 && <Step3ProductEligibility />}
          {stepNumber === 4 && <Step4ReceiptTimeline />}
          {stepNumber === 5 && <Step5ExchangeExceptions />}
          {stepNumber === 6 && <Step6Refund />}
        </div>

        {/* Tactile Error Card with Retry Button */}
        {evaluationError && (
          <div
            role="alert"
            className="w-full mt-6 p-5 sm:p-6 rounded-2xl bg-red-50/95 border-2 border-red-300 text-red-950 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 shadow-sm animate-in fade-in duration-200"
          >
            <div className="flex items-start gap-3.5">
              <div className="w-11 h-11 rounded-2xl bg-red-100 border border-red-200 text-red-600 flex items-center justify-center shrink-0">
                <span className="material-symbols-outlined text-[26px]">warning</span>
              </div>
              <div className="flex flex-col">
                <span className="font-sans text-sm font-bold text-red-900">
                  Não foi possível concluir a avaliação
                </span>
                <span className="font-sans text-xs sm:text-sm text-red-800 mt-0.5">
                  {evaluationError}
                </span>
              </div>
            </div>

            <button
              type="button"
              onClick={handleEvaluate}
              className="w-full sm:w-auto px-5 py-2.5 rounded-full bg-red-600 hover:bg-red-700 text-white font-sans text-xs sm:text-sm font-bold flex items-center justify-center gap-2 shadow-[0_3px_0_#991b1b] hover:translate-y-0.5 active:translate-y-1 transition-all cursor-pointer shrink-0"
            >
              <span className="material-symbols-outlined text-[18px]">refresh</span>
              <span>Tentar novamente</span>
            </button>
          </div>
        )}
      </div>

      {/* Bottom Progress & Navigation Group (aligned to the bottom of the page) */}
      <div className="w-full mt-auto pt-12 sm:pt-16 pb-1 flex flex-col gap-2">
        {/* Segmented Progress Bar */}
        <ProgressBar
          totalSteps={totalSteps}
          currentStep={stepNumber}
        />

        {/* Navigation Footer */}
        <NavigationFooter
          onBack={handleBack}
          onNext={handleNext}
          onLeave={stepNumber > 1 ? handleLeave : undefined}
          leaveLabel="Painel Inicial"
          nextLabel={meta.nextLabel}
          nextHint={getStepHint()}
          backLabel={stepNumber === 1 ? "Painel Inicial" : "Passo Anterior"}
          disabled={!isCurrentStepValid}
          isLoading={isEvaluating}
        />
      </div>

      {/* Widget de Explicabilidade Bidirecional "Porquê?" (ACM - Via 2) */}
      {stepNumber >= 2 && stepNumber <= 6 && (
        <WhyAskWidget
          stepNumber={stepNumber}
          engine={state.engine || "returns"}
          returnRequest={buildReturnRequest()}
          requestType={state.requestType || undefined}
          physicalCondition={state.physicalCondition || undefined}
        />
      )}
    </div>
  );
}
