"use client";

import React, { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useWizard } from "@/components/wizard/WizardContext";
import VerdictScreen from "@/components/wizard/VerdictScreen";

export default function VereditoPage() {
  const router = useRouter();
  const {
    evaluationResult,
    lastRequest,
    evaluationDurationMs,
    state,
    buildReturnRequest,
    isHydrated,
    isLeaving,
    exitTo,
  } = useWizard();

  // Se o utilizador aceder diretamente a esta rota sem haver uma inferência concluída,
  // reencaminha de volta para o primeiro passo do atendimento (apenas se não estiver a sair).
  useEffect(() => {
    if (isHydrated && !isLeaving && !evaluationResult) {
      router.replace("/novo-atendimento/passo/1");
    }
  }, [isHydrated, isLeaving, evaluationResult, router]);

  if (!isHydrated || !evaluationResult) {
    return (
      <div className="w-full flex-1 flex items-center justify-center p-8 min-h-[300px]">
        <div className="w-8 h-8 border-2 border-emerald-600 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

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
