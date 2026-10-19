"use client";

import React from "react";

export interface StatusFooterProps {
  droolsStatus?: "online" | "offline";
  prologStatus?: "online" | "offline";
  droolsLatency?: string;
  prologLatency?: string;
  systemVersion?: string;
  className?: string;
}

export default function StatusFooter({
  droolsStatus = "online",
  prologStatus = "online",
  droolsLatency = "Operacional",
  prologLatency = "7.4ms SLA",
  systemVersion = "RetailFlow Frontline AI POS Engine v2.4",
  className = "",
}: StatusFooterProps) {
  const isDroolsOnline = droolsStatus === "online";
  const isPrologOnline = prologStatus === "online";

  return (
    <footer
      role="contentinfo"
      className={`w-full border-t border-border-card bg-surface-container-low/80 py-4 px-6 mt-16 select-none ${className}`}
    >
      <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-3 text-xs text-on-surface-variant font-sans font-medium">
        {/* Engine status indicators */}
        <div className="flex flex-wrap items-center justify-center md:justify-start gap-5">
          <div className="flex items-center gap-2">
            <span
              className={`w-2.5 h-2.5 rounded-full ${
                isDroolsOnline
                  ? "bg-primary-container shadow-[0_0_8px_rgba(16,185,129,0.6)] animate-pulse"
                  : "bg-error"
              }`}
            />
            <span className="font-mono tabular-nums">
              Drools v8.44:{" "}
              <strong className="text-on-surface font-semibold">
                {isDroolsOnline ? droolsLatency : "Offline"}
              </strong>
            </span>
          </div>

          <div className="flex items-center gap-2">
            <span
              className={`w-2.5 h-2.5 rounded-full ${
                isPrologOnline
                  ? "bg-primary-container shadow-[0_0_8px_rgba(16,185,129,0.6)] animate-pulse"
                  : "bg-error"
              }`}
            />
            <span className="font-mono tabular-nums">
              Prolog Core:{" "}
              <strong className="text-on-surface font-semibold">
                {isPrologOnline ? prologLatency : "Offline"}
              </strong>
            </span>
          </div>
        </div>

        {/* System & Team identity */}
        <div className="flex items-center gap-2 text-on-surface-variant">
          <span className="font-mono tabular-nums">{systemVersion}</span>
          <span>•</span>
          <span className="font-sans font-semibold text-on-surface">MEIA Equipa 3</span>
        </div>
      </div>
    </footer>
  );
}
