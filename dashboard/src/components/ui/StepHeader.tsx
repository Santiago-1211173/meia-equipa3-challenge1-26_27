"use client";

import React from "react";

export interface StepHeaderProps {
  step?: number;
  totalSteps?: number;
  title: string;
  subtitle?: string;
  className?: string;
  hideEyebrow?: boolean;
}

export function StepEyebrow({
  step,
  totalSteps,
  className = "",
}: {
  step: number;
  totalSteps: number;
  className?: string;
}) {
  return (
    <div className={`inline-flex items-center gap-2 text-xs select-none ${className}`}>
      <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
      <span className="font-sans tabular-nums text-[11px] font-bold uppercase tracking-widest text-slate-400">
        Passo {step} de {totalSteps}
      </span>
    </div>
  );
}

export default function StepHeader({
  step,
  totalSteps,
  title,
  subtitle,
  className = "",
  hideEyebrow = false,
}: StepHeaderProps) {
  return (
    <div className={`w-full text-center flex flex-col items-center gap-2 mb-8 ${className}`}>
      {/* Modern Minimalist Eyebrow */}
      {!hideEyebrow && step !== undefined && totalSteps !== undefined && (
        <StepEyebrow step={step} totalSteps={totalSteps} className="mb-1" />
      )}

      {/* Main Title (H2 uses font-sans per typographic rules) */}
      <h2 className="font-sans font-headline-lg text-on-surface tracking-tight max-w-2xl px-2">
        {title}
      </h2>

      {/* Optional Subtitle */}
      {subtitle && (
        <p className="font-sans font-body-lg text-on-surface-variant max-w-xl px-4 text-center leading-relaxed">
          {subtitle}
        </p>
      )}
    </div>
  );
}
