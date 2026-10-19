"use client";

import React from "react";

export interface ToggleOption {
  label: string;
  value: string;
  badge?: string;
}

export interface ToggleButtonProps {
  options: ToggleOption[];
  selected: string | null;
  onChange: (value: string) => void;
  disabled?: boolean;
  ariaLabel?: string;
  className?: string;
}

export default function ToggleButton({
  options,
  selected,
  onChange,
  disabled = false,
  ariaLabel = "Opções",
  className = "",
}: ToggleButtonProps) {
  return (
    <div
      role="radiogroup"
      aria-label={ariaLabel}
      className={`inline-flex rounded-full p-1 bg-surface-container border border-border-card select-none ${className}`}
    >
      {options.map((opt) => {
        const isSelected = selected === opt.value;
        return (
          <button
            key={opt.value}
            type="button"
            role="radio"
            aria-checked={isSelected}
            disabled={disabled}
            onClick={() => onChange(opt.value)}
            className={`font-sans px-4 py-1.5 rounded-full text-xs font-bold transition-all duration-150 flex items-center gap-1.5 cursor-pointer focus-visible:outline-2 focus-visible:outline-primary ${
              isSelected
                ? "bg-primary-container text-on-primary-container shadow-sm font-extrabold"
                : "text-on-surface-variant hover:text-on-surface hover:bg-surface-container-high/60"
            } ${disabled ? "opacity-50 cursor-not-allowed pointer-events-none" : "active:scale-[0.98]"}`}
          >
            {isSelected && (
              <span
                className="material-symbols-outlined text-[15px] animate-in fade-in zoom-in duration-100"
                style={{ fontVariationSettings: "'wght' 700" }}
              >
                check
              </span>
            )}
            <span>{opt.label}</span>
            {opt.badge && (
              <span className="font-sans text-[10px] px-1.5 py-0.5 rounded-full bg-surface-container-highest font-normal">
                {opt.badge}
              </span>
            )}
          </button>
        );
      })}
    </div>
  );
}
