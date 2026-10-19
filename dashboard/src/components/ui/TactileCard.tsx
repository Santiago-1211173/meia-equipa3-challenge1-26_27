"use client";

import React, { ReactNode } from "react";

export interface TactileCardProps {
  icon?: ReactNode;
  title: string;
  description?: string;
  selected?: boolean;
  onClick?: () => void;
  badge?: string;
  badgeVariant?: "primary" | "secondary" | "tertiary" | "neutral";
  disabled?: boolean;
  role?: "radio" | "option" | "button" | "checkbox";
  className?: string;
  children?: ReactNode;
}

export default function TactileCard({
  icon,
  title,
  description,
  selected = false,
  onClick,
  badge,
  badgeVariant = "primary",
  disabled = false,
  role = "radio",
  className = "",
  children,
}: TactileCardProps) {
  const getBadgeClasses = () => {
    switch (badgeVariant) {
      case "primary":
        return "bg-primary-fixed text-on-primary-fixed border border-primary-container/30";
      case "secondary":
        return "bg-secondary-fixed text-on-secondary-fixed border border-secondary-container/30";
      case "tertiary":
        return "bg-tertiary-fixed text-on-tertiary-fixed border border-tertiary-container/30";
      case "neutral":
      default:
        return "bg-surface-container text-on-surface-variant border border-border-card";
    }
  };

  return (
    <button
      type="button"
      role={role}
      aria-checked={role === "radio" || role === "checkbox" || role === "option" ? selected : undefined}
      aria-pressed={role === "button" ? selected : undefined}
      disabled={disabled}
      onClick={onClick}
      className={`card-tactile w-full p-6 text-left relative flex flex-col justify-between transition-all duration-150 cursor-pointer select-none focus-visible:outline-2 focus-visible:outline-primary ${
        selected ? "card-tactile-selected" : ""
      } ${disabled ? "opacity-50 cursor-not-allowed pointer-events-none" : ""} ${className}`}
    >
      <div className="flex items-start justify-between w-full gap-3">
        <div className="flex items-start gap-4 flex-1 min-w-0">
          {icon && (
            <div
              className={`w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 transition-colors ${
                selected
                  ? "bg-secondary-container/15 text-secondary"
                  : "bg-surface-container-low text-primary"
              }`}
            >
              {icon}
            </div>
          )}
          <div className="flex flex-col flex-1 min-w-0">
            <h3 className="font-sans font-bold text-on-surface leading-tight break-words">
              {title}
            </h3>
            {description && (
              <p className="font-sans font-body-md text-on-surface-variant text-sm mt-1 leading-snug">
                {description}
              </p>
            )}
          </div>
        </div>

        {/* Top-right badges and selected checkmark */}
        <div className="flex items-center gap-2 flex-shrink-0 pt-0.5">
          {badge && (
            <span
              className={`font-sans px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider ${getBadgeClasses()}`}
            >
              {badge}
            </span>
          )}
          {selected ? (
            <div
              aria-hidden="true"
              className="w-6 h-6 rounded-full bg-secondary flex items-center justify-center text-white shadow-sm animate-in fade-in zoom-in-75 duration-150"
            >
              <span
                className="material-symbols-outlined text-[16px]"
                style={{ fontVariationSettings: "'wght' 700" }}
              >
                check
              </span>
            </div>
          ) : (
            role === "radio" && (
              <div
                aria-hidden="true"
                className="w-6 h-6 rounded-full border-2 border-border-card-bottom bg-surface-container-lowest"
              />
            )
          )}
        </div>
      </div>

      {children && <div className="mt-4 w-full">{children}</div>}
    </button>
  );
}
