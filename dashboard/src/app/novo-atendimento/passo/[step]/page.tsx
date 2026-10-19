import React from "react";
import WizardStepContainer from "@/components/wizard/WizardStepContainer";

interface StepPageProps {
  params: Promise<{ step: string }>;
}

export default async function StepPage({ params }: StepPageProps) {
  const { step } = await params;
  const parsed = parseInt(step, 10);
  const stepNumber = Math.max(1, Math.min(6, isNaN(parsed) ? 1 : parsed));

  return <WizardStepContainer stepNumber={stepNumber} />;
}
