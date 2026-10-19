"use client";

import React from "react";

export interface QuickActionsProps {
  onSwitchOperator?: () => void;
  onSimulateTraining?: () => void;
  onViewPolicies?: () => void;
}

export default function QuickActions({
  onSwitchOperator,
  onSimulateTraining,
  onViewPolicies,
}: QuickActionsProps) {
  return (
    <section
      aria-label="Atalhos rápidos de balcão"
      className="grid grid-cols-1 md:grid-cols-3 gap-4 w-full"
    >
      {/* 1. Trocar de Operador */}
      <button
        type="button"
        onClick={onSwitchOperator}
        className="p-4 bg-white rounded-xl border border-slate-200 hover:border-slate-300 hover:bg-slate-50/70 transition-all flex items-center justify-between group cursor-pointer text-left shadow-xs focus-visible:outline-2 focus-visible:outline-primary select-none"
      >
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-slate-100 flex items-center justify-center text-slate-700">
            <span className="material-symbols-outlined text-[19px]">switch_account</span>
          </div>
          <div className="flex flex-col">
            <span className="font-sans text-sm font-bold text-slate-900">
              Trocar de Operador
            </span>
            <span className="font-sans text-xs text-slate-500">
              Passar caixa ao colega
            </span>
          </div>
        </div>
        <span className="material-symbols-outlined text-slate-400 group-hover:text-slate-700 group-hover:translate-x-0.5 text-[18px] transition-all">
          chevron_right
        </span>
      </button>

      {/* 2. Simular Cenário de Treino */}
      <button
        type="button"
        onClick={onSimulateTraining}
        className="p-4 bg-white rounded-xl border border-slate-200 hover:border-slate-300 hover:bg-slate-50/70 transition-all flex items-center justify-between group cursor-pointer text-left shadow-xs focus-visible:outline-2 focus-visible:outline-primary select-none"
      >
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-amber-50 text-amber-700 border border-amber-200/60 flex items-center justify-center">
            <span className="material-symbols-outlined text-[19px]">school</span>
          </div>
          <div className="flex flex-col">
            <span className="font-sans text-sm font-bold text-slate-900">
              Simular Cenário de Treino
            </span>
            <span className="font-sans text-xs text-slate-500">
              Modo Sandbox seguro
            </span>
          </div>
        </div>
        <span className="material-symbols-outlined text-slate-400 group-hover:text-slate-700 group-hover:translate-x-0.5 text-[18px] transition-all">
          chevron_right
        </span>
      </button>

      {/* 3. Políticas Março 2025 */}
      <button
        type="button"
        onClick={onViewPolicies}
        className="p-4 bg-white rounded-xl border border-slate-200 hover:border-slate-300 hover:bg-slate-50/70 transition-all flex items-center justify-between group cursor-pointer text-left shadow-xs focus-visible:outline-2 focus-visible:outline-primary select-none"
      >
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-200/60 flex items-center justify-center">
            <span className="material-symbols-outlined text-[19px]">verified</span>
          </div>
          <div className="flex flex-col">
            <span className="font-sans text-sm font-bold text-slate-900">
              Políticas Atualizadas
            </span>
            <span className="font-sans text-xs text-slate-500">
              Regras em vigor no balcão
            </span>
          </div>
        </div>
        <span className="material-symbols-outlined text-slate-400 group-hover:text-slate-700 group-hover:translate-x-0.5 text-[18px] transition-all">
          chevron_right
        </span>
      </button>
    </section>
  );
}
