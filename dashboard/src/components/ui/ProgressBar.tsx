"use client";

import React from "react";

export interface ProgressBarProps {
  totalSteps: number;
  currentStep: number;
  nextLabel?: string;
  className?: string;
}

export default function ProgressBar({
  totalSteps = 6,
  currentStep = 1,
  nextLabel,
  className = "",
}: ProgressBarProps) {
  const steps = Array.from({ length: totalSteps }, (_, i) => i + 1);

  return (
    <div
      role="progressbar"
      aria-label={`Progresso do atendimento: Passo ${currentStep} de ${totalSteps}`}
      aria-valuenow={currentStep}
      aria-valuemin={1}
      aria-valuemax={totalSteps}
      aria-valuetext={`Passo ${currentStep} de ${totalSteps}${nextLabel ? ` - A seguir: ${nextLabel}` : ""}`}
      className={`w-full flex flex-col gap-2 ${className}`}
    >
      {/* Sleek Modern Segmented Progress Track */}
      <div className="w-full flex items-center gap-1.5">
        {steps.map((step) => {
          const isCompleted = step < currentStep;
          const isCurrent = step === currentStep;

          return (
            <div
              key={step}
              className={`flex-1 h-1.5 rounded-full transition-all duration-300 ease-out ${
                isCompleted || isCurrent
                  ? "bg-emerald-600"
                  : "bg-slate-200/70"
              }`}
            />
          );
        })}
      </div>

      {/* Step info text */}
      <div className="flex justify-between items-center text-xs text-slate-500 font-sans font-medium px-0.5 select-none">
        <span className="tabular-nums">
          Passo {currentStep} de {totalSteps}
        </span>
        {nextLabel && (
          <span className="font-sans text-slate-700 font-semibold">
            {nextLabel}
          </span>
        )}
      </div>
    </div>
  );
}
