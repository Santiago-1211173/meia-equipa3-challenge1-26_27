"use client";

import React from "react";
import { useWizard } from "./WizardContext";

export default function Step1EngineSelect() {
  const { state, setField } = useWizard();

  const isDrools = state.engine === "returns";
  const isProlog = state.engine === "prolog";

  return (
    <div className="w-full flex flex-col gap-8">
      {/* Big Hero Interactive Cards Side-by-Side */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 w-full">
        {/* Card 1: Motor Drools */}
        <div
          role="radio"
          aria-checked={isDrools}
          tabIndex={0}
          onClick={() => setField("engine", "returns")}
          onKeyDown={(e) => {
            if (e.key === "Enter" || e.key === " ") {
              e.preventDefault();
              setField("engine", "returns");
            }
          }}
          className={`group relative rounded-2xl p-6 sm:p-7 cursor-pointer flex flex-col justify-between gap-7 transition-all duration-200 focus-visible:outline-2 focus-visible:outline-emerald-600 ${
            isDrools
              ? "bg-emerald-50/25 border-2 border-emerald-600 shadow-xs"
              : "bg-white border border-slate-200 hover:border-slate-300 hover:shadow-xs"
          }`}
        >
          {/* Header: Icon + Text aligned horizontally */}
          <div className="flex items-center gap-4">
            <div
              className={`w-12 h-12 rounded-xl flex items-center justify-center transition-transform group-hover:scale-105 shrink-0 ${
                isDrools
                  ? "bg-emerald-600 text-white shadow-xs"
                  : "bg-emerald-50 text-emerald-700 border border-emerald-200/60"
              }`}
            >
              <span className="material-symbols-outlined text-[26px]">
                bolt
              </span>
            </div>

            <div>
              <h3 className="font-sans text-xl sm:text-2xl font-bold text-slate-900 tracking-tight">
                Motor Drools
              </h3>
              <p className="font-sans text-xs font-semibold uppercase tracking-wider text-emerald-700 mt-0.5">
                Padrão de Balcão
              </p>
            </div>
          </div>

          {/* Action / Selection Pill */}
          <button
            type="button"
            tabIndex={-1}
            className={`font-sans w-full py-2.5 px-4 rounded-xl text-sm font-semibold flex items-center justify-center gap-2 transition-colors cursor-pointer ${
              isDrools
                ? "bg-emerald-600 hover:bg-emerald-700 text-white shadow-xs"
                : "bg-slate-50 hover:bg-slate-100 text-slate-700 border border-slate-200"
            }`}
          >
            <span className="material-symbols-outlined text-[18px]">
              {isDrools ? "check_circle" : "radio_button_unchecked"}
            </span>
            <span>
              {isDrools ? "Motor Drools Selecionado" : "Selecionar Motor Drools"}
            </span>
          </button>
        </div>

        {/* Card 2: Motor Prolog */}
        <div
          role="radio"
          aria-checked={isProlog}
          tabIndex={0}
          onClick={() => setField("engine", "prolog")}
          onKeyDown={(e) => {
            if (e.key === "Enter" || e.key === " ") {
              e.preventDefault();
              setField("engine", "prolog");
            }
          }}
          className={`group relative rounded-2xl p-6 sm:p-7 cursor-pointer flex flex-col justify-between gap-7 transition-all duration-200 focus-visible:outline-2 focus-visible:outline-indigo-600 ${
            isProlog
              ? "bg-indigo-50/25 border-2 border-indigo-600 shadow-xs"
              : "bg-white border border-slate-200 hover:border-slate-300 hover:shadow-xs"
          }`}
        >
          {/* Header: Icon + Text aligned horizontally */}
          <div className="flex items-center gap-4">
            <div
              className={`w-12 h-12 rounded-xl flex items-center justify-center transition-transform group-hover:scale-105 shrink-0 ${
                isProlog
                  ? "bg-indigo-600 text-white shadow-xs"
                  : "bg-indigo-50 text-indigo-700 border border-indigo-200/60"
              }`}
            >
              <span className="material-symbols-outlined text-[26px]">
                balance
              </span>
            </div>

            <div>
              <h3 className="font-sans text-xl sm:text-2xl font-bold text-slate-900 tracking-tight">
                Motor Prolog
              </h3>
              <p className="font-sans text-xs font-semibold uppercase tracking-wider text-indigo-700 mt-0.5">
                Dedução Lógica
              </p>
            </div>
          </div>

          {/* Action / Selection Pill */}
          <button
            type="button"
            tabIndex={-1}
            className={`font-sans w-full py-2.5 px-4 rounded-xl text-sm font-semibold flex items-center justify-center gap-2 transition-colors cursor-pointer ${
              isProlog
                ? "bg-indigo-600 hover:bg-indigo-700 text-white shadow-xs"
                : "bg-slate-50 hover:bg-slate-100 text-slate-700 border border-slate-200"
            }`}
          >
            <span className="material-symbols-outlined text-[18px]">
              {isProlog ? "check_circle" : "radio_button_unchecked"}
            </span>
            <span>
              {isProlog ? "Motor Prolog Selecionado" : "Selecionar Motor Prolog"}
            </span>
          </button>
        </div>
      </div>
    </div>
  );
}
