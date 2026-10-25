"use client";

import React from "react";

export interface SegmentedOption<T extends string | number> {
  label: string;
  value: T;
  tone?: "success" | "danger" | "warning" | "info" | "neutral";
}

export interface SegmentedChoiceProps<T extends string | number> {
  options: SegmentedOption<T>[];
  value: T | null | undefined;
  onChange: (value: T) => void;
  ariaLabel: string;
  disabled?: boolean;
  className?: string;
  width?: string;
}

const TONE_CLASSES: Record<NonNullable<SegmentedOption<string>["tone"]>, string> = {
  success: "bg-white text-emerald-800 border-slate-200/90",
  danger: "bg-white text-rose-700 border-rose-300",
  warning: "bg-white text-amber-800 border-amber-300",
  info: "bg-white text-indigo-700 border-indigo-300",
  neutral: "bg-white text-slate-800 border-slate-300",
};

/**
 * Escolha segmentada com o mesmo aspeto do SlickSlider, para perguntas com mais de duas
 * respostas (ex.: Sim / Não / Não sei, ou o grau de uso de 0 a 4). Setas mudam de opção.
 */
export default function SegmentedChoice<T extends string | number>({
  options,
  value,
  onChange,
  ariaLabel,
  disabled = false,
  className = "",
  width = "w-full sm:w-auto",
}: SegmentedChoiceProps<T>) {
  const selectedIndex = options.findIndex((opt) => opt.value === value);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (disabled) return;
    const step = e.key === "ArrowRight" ? 1 : e.key === "ArrowLeft" ? -1 : 0;
    if (step === 0) return;
    e.preventDefault();
    const from = selectedIndex < 0 ? (step > 0 ? -1 : options.length) : selectedIndex;
    const next = Math.min(options.length - 1, Math.max(0, from + step));
    onChange(options[next].value);
  };

  return (
    <div
      role="radiogroup"
      aria-label={ariaLabel}
      tabIndex={disabled ? -1 : 0}
      onKeyDown={handleKeyDown}
      className={`grid gap-1 p-1 bg-slate-100 border border-slate-200/90 rounded-xl select-none shrink-0 transition-colors duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 focus-visible:ring-offset-2 ${width} ${
        disabled ? "opacity-50 pointer-events-none" : ""
      } ${className}`}
      style={{ gridTemplateColumns: `repeat(${options.length}, minmax(0, 1fr))` }}
    >
      {options.map((opt, idx) => {
        const isSelected = idx === selectedIndex;
        return (
          <button
            key={String(opt.value)}
            type="button"
            role="radio"
            aria-checked={isSelected}
            tabIndex={-1}
            disabled={disabled}
            onClick={() => onChange(opt.value)}
            className={`font-sans h-[30px] sm:h-8 px-2.5 rounded-lg text-xs font-bold whitespace-nowrap border transition-colors duration-150 cursor-pointer focus:outline-none ${
              isSelected
                ? `${TONE_CLASSES[opt.tone ?? "success"]} shadow-[0_1px_3px_rgba(15,23,42,0.08),0_1px_2px_rgba(15,23,42,0.06)]`
                : "border-transparent text-slate-500 hover:text-slate-700"
            }`}
          >
            {opt.label}
          </button>
        );
      })}
    </div>
  );
}
