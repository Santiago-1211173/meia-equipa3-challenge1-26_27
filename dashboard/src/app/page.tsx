"use client";

import React, { useState } from "react";
import Navbar from "@/components/ui/Navbar";
import StatusFooter from "@/components/ui/StatusFooter";
import {
  HeroSection,
  RecentCases,
  QuickActions,
  PolicyModal,
  SwitchOperatorModal,
  TrainingModal,
  availableOperators,
  OperatorOption,
} from "@/components/home";

export default function HomePage() {
  const [operator, setOperator] = useState<OperatorOption>(availableOperators[0]);
  const [policyModalOpen, setPolicyModalOpen] = useState(false);
  const [switchOperatorModalOpen, setSwitchOperatorModalOpen] = useState(false);
  const [trainingModalOpen, setTrainingModalOpen] = useState(false);

  return (
    <div className="min-h-screen flex flex-col bg-surface">
      {/* Fixed top navigation bar */}
      <Navbar
        activeRoute="painel"
        operatorName={operator.name}
        operatorRole={operator.role}
        streakCount={operator.streak}
      />

      {/* Main Content Area */}
      <main id="main-content" className="flex-1 w-full max-w-7xl mx-auto px-4 md:px-8 pt-24 pb-12 flex flex-col gap-8">
        {/* 1. Hero & Quick Actions Banner */}
        <HeroSection
          operatorName={operator.name.split(" ")[0]}
          onQuickPolicy={() => setPolicyModalOpen(true)}
        />

        {/* 2. Últimos Casos Resolvidos (Tactile Cards & Audit) */}
        <RecentCases />

        {/* 3. Atalhos Rápidos de Balcão */}
        <QuickActions
          onSwitchOperator={() => setSwitchOperatorModalOpen(true)}
          onSimulateTraining={() => setTrainingModalOpen(true)}
          onViewPolicies={() => setPolicyModalOpen(true)}
        />
      </main>

      {/* Bottom Engine Health & SLA Status */}
      <StatusFooter droolsStatus="online" prologStatus="online" />

      {/* Interactive Modals */}
      <PolicyModal
        isOpen={policyModalOpen}
        onClose={() => setPolicyModalOpen(false)}
      />

      <SwitchOperatorModal
        isOpen={switchOperatorModalOpen}
        currentOperator={operator.name}
        onSelectOperator={(newOp) => setOperator(newOp)}
        onClose={() => setSwitchOperatorModalOpen(false)}
      />

      <TrainingModal
        isOpen={trainingModalOpen}
        onClose={() => setTrainingModalOpen(false)}
      />
    </div>
  );
}
