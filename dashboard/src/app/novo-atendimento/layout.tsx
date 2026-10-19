"use client";

import React from "react";
import Navbar from "@/components/ui/Navbar";
import StatusFooter from "@/components/ui/StatusFooter";
import { WizardProvider, useWizard } from "@/components/wizard/WizardContext";
import ConfirmLeaveModal from "@/components/wizard/ConfirmLeaveModal";

function WizardLeaveModalGlobal() {
  const { showLeaveModal, confirmLeave, cancelLeave } = useWizard();
  return (
    <ConfirmLeaveModal
      isOpen={showLeaveModal}
      onConfirm={() => confirmLeave()}
      onCancel={() => cancelLeave()}
    />
  );
}

export default function NovoAtendimentoLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <WizardProvider>
      <div className="min-h-screen flex flex-col justify-between bg-surface text-on-surface">
        {/* Top Fixed Navbar */}
        <Navbar
          activeRoute="novo-atendimento"
          operatorName="Tiago Silva"
          operatorRole="Operador N2"
          streakCount={18}
        />

        {/* Central Content Area */}
        <main id="main-content" className="w-full flex-1 pt-20 pb-6 flex flex-col items-center">
          {children}
        </main>

        {/* Bottom Engine Health Footer */}
        <StatusFooter droolsStatus="online" prologStatus="online" />

        {/* Modal Global de Confirmação de Saída Tátil */}
        <WizardLeaveModalGlobal />
      </div>
    </WizardProvider>
  );
}
