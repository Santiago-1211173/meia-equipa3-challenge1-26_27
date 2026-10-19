"use client";

import React from "react";

export interface OperatorOption {
  id: string;
  name: string;
  role: string;
  streak: number;
  avatarColor: string;
}

export const availableOperators: OperatorOption[] = [
  {
    id: "op-1",
    name: "Tiago M.",
    role: "Operador N2",
    streak: 18,
    avatarColor: "bg-primary",
  },
  {
    id: "op-2",
    name: "Marta S.",
    role: "Supervisora de Balcão",
    streak: 34,
    avatarColor: "bg-secondary",
  },
  {
    id: "op-3",
    name: "Pedro F.",
    role: "Operador N1",
    streak: 9,
    avatarColor: "bg-tertiary",
  },
  {
    id: "op-4",
    name: "Sofia R.",
    role: "Assistente de Loja",
    streak: 12,
    avatarColor: "bg-emerald-700",
  },
];

export interface SwitchOperatorModalProps {
  isOpen: boolean;
  currentOperator: string;
  onSelectOperator: (operator: OperatorOption) => void;
  onClose: () => void;
}

export default function SwitchOperatorModal({
  isOpen,
  currentOperator,
  onSelectOperator,
  onClose,
}: SwitchOperatorModalProps) {
  if (!isOpen) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="switch-op-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs animate-fadeIn"
    >
      <div className="bg-white w-full max-w-md rounded-3xl p-6 md:p-8 shadow-2xl border border-border-card flex flex-col gap-6">
        {/* Header */}
        <div className="flex items-start justify-between gap-4 border-b border-border-card pb-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center text-on-surface shadow-xs">
              <span className="material-symbols-outlined text-[22px]">switch_account</span>
            </div>
            <div>
              <span className="font-label-md text-xs font-bold text-on-surface-variant uppercase tracking-wider">
                Sessão de Caixa
              </span>
              <h3 id="switch-op-title" className="font-sans font-headline-sm text-on-surface text-lg font-bold">
                Trocar de Operador
              </h3>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            aria-label="Fechar"
            className="w-8 h-8 rounded-full bg-surface-container-low text-on-surface-variant hover:text-on-surface flex items-center justify-center cursor-pointer transition-colors"
          >
            <span className="material-symbols-outlined text-[20px]">close</span>
          </button>
        </div>

        {/* Operator selection list */}
        <div className="flex flex-col gap-2.5 font-sans">
          {availableOperators.map((op) => {
            const isCurrent = currentOperator.startsWith(op.name.split(" ")[0]);

            return (
              <button
                key={op.id}
                type="button"
                onClick={() => {
                  onSelectOperator(op);
                  onClose();
                }}
                className={`p-3.5 rounded-2xl border flex items-center justify-between gap-3 text-left transition-all cursor-pointer select-none ${
                  isCurrent
                    ? "bg-blue-50/80 border-blue-500 shadow-sm"
                    : "bg-surface-container-low hover:bg-surface-container border-border-card"
                }`}
              >
                <div className="flex items-center gap-3">
                  <div
                    className={`w-10 h-10 rounded-full ${op.avatarColor} text-white flex items-center justify-center font-bold text-sm shadow-xs`}
                  >
                    {op.name.charAt(0)}
                  </div>
                  <div className="flex flex-col">
                    <span className="font-sans font-label-lg text-sm text-on-surface font-bold">
                      {op.name}
                    </span>
                    <span className="font-sans font-caption text-xs text-on-surface-variant">
                      {op.role}
                    </span>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <span className="font-sans tabular-nums px-2 py-0.5 rounded-full bg-tertiary-fixed text-on-tertiary-fixed font-label-md text-[10px] font-bold">
                    🔥 {op.streak}
                  </span>
                  {isCurrent && (
                    <span className="material-symbols-outlined text-blue-600 text-[20px]">
                      check_circle
                    </span>
                  )}
                </div>
              </button>
            );
          })}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end pt-2 border-t border-border-card font-sans">
          <button
            type="button"
            onClick={onClose}
            className="font-sans px-5 py-2 rounded-full bg-surface-container text-on-surface font-label-md text-xs font-semibold shadow-xs hover:translate-y-[1px] transition-all cursor-pointer"
          >
            Cancelar
          </button>
        </div>
      </div>
    </div>
  );
}
