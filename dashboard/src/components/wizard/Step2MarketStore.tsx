"use client";

import React from "react";
import { useWizard } from "./WizardContext";

// Bandeira dos EUA em SVG nítido e responsivo
function UsaFlag({ className = "w-9 h-6" }: { className?: string }) {
  return (
    <svg
      className={`rounded shadow-2xs shrink-0 border border-slate-200/80 object-cover ${className}`}
      viewBox="0 0 640 480"
      aria-hidden="true"
    >
      <g fillRule="evenodd">
        <path fill="#bd3d44" d="M0 0h640v480H0z" />
        <path
          fill="#fff"
          d="M0 37h640v37H0zm0 74h640v37H0zm0 74h640v37H0zm0 74h640v37H0zm0 73h640v37H0zm0 74h640v37H0z"
        />
        <path fill="#192f5d" d="M0 0h260v259H0z" />
        <g fill="#fff">
          <circle cx="26" cy="24" r="5" />
          <circle cx="78" cy="24" r="5" />
          <circle cx="130" cy="24" r="5" />
          <circle cx="182" cy="24" r="5" />
          <circle cx="234" cy="24" r="5" />
          <circle cx="52" cy="50" r="5" />
          <circle cx="104" cy="50" r="5" />
          <circle cx="156" cy="50" r="5" />
          <circle cx="208" cy="50" r="5" />
          <circle cx="26" cy="76" r="5" />
          <circle cx="78" cy="76" r="5" />
          <circle cx="130" cy="76" r="5" />
          <circle cx="182" cy="76" r="5" />
          <circle cx="234" cy="76" r="5" />
          <circle cx="52" cy="102" r="5" />
          <circle cx="104" cy="102" r="5" />
          <circle cx="156" cy="102" r="5" />
          <circle cx="208" cy="102" r="5" />
          <circle cx="26" cy="128" r="5" />
          <circle cx="78" cy="128" r="5" />
          <circle cx="130" cy="128" r="5" />
          <circle cx="182" cy="128" r="5" />
          <circle cx="234" cy="128" r="5" />
          <circle cx="52" cy="154" r="5" />
          <circle cx="104" cy="154" r="5" />
          <circle cx="156" cy="154" r="5" />
          <circle cx="208" cy="154" r="5" />
          <circle cx="26" cy="180" r="5" />
          <circle cx="78" cy="180" r="5" />
          <circle cx="130" cy="180" r="5" />
          <circle cx="182" cy="180" r="5" />
          <circle cx="234" cy="180" r="5" />
          <circle cx="52" cy="206" r="5" />
          <circle cx="104" cy="206" r="5" />
          <circle cx="156" cy="206" r="5" />
          <circle cx="208" cy="206" r="5" />
          <circle cx="26" cy="232" r="5" />
          <circle cx="78" cy="232" r="5" />
          <circle cx="130" cy="232" r="5" />
          <circle cx="182" cy="232" r="5" />
          <circle cx="234" cy="232" r="5" />
        </g>
      </g>
    </svg>
  );
}

// Bandeira do Canadá em SVG nítido e responsivo
function CanadaFlag({ className = "w-9 h-6" }: { className?: string }) {
  return (
    <svg
      className={`rounded shadow-2xs shrink-0 border border-slate-200/80 object-cover ${className}`}
      viewBox="0 0 640 480"
      aria-hidden="true"
    >
      <g fillRule="evenodd">
        <path fill="#d52b1e" d="M0 0h160v480H0zm480 0h160v480H480z" />
        <path fill="#fff" d="M160 0h320v480H160z" />
        <path
          fill="#d52b1e"
          d="m320 80 15 48 38-16-12 40 46 2-25 35 34 23-44 14 6 42-38-14-10 66h-20l-10-66-38 14 6-42-44-14 34-23-25-35 46-2-12-40 38 16z"
        />
      </g>
    </svg>
  );
}

interface ChannelItem {
  id: "FISICA" | "ONLINE_BACKPOCKET" | "FRANQUIA_CA" | "GROSSISTA" | "DESCONHECIDO";
  title: string;
  subtitle: string;
  icon: string;
  badge?: string;
}

const CHANNELS: ChannelItem[] = [
  {
    id: "FISICA",
    title: "Loja Física",
    subtitle: "Rede oficial de lojas físicas",
    icon: "store",
  },
  {
    id: "ONLINE_BACKPOCKET",
    title: "Online / BackPocket",
    subtitle: "levi.com, levi.ca ou app oficial",
    badge: "Web",
    icon: "shopping_bag",
  },
  {
    id: "FRANQUIA_CA",
    title: "Franquia Canadiana",
    subtitle: "Parceiro franqueado no Canadá",
    icon: "domain",
  },
  {
    id: "GROSSISTA",
    title: "Grossista / Externo",
    subtitle: "Grandes armazéns (ex: Macy's)",
    icon: "inventory_2",
  },
  {
    id: "DESCONHECIDO",
    title: "Desconhecido",
    subtitle: "Sem registo ou talão de venda",
    icon: "help_outline",
  },
];

export default function Step2MarketStore() {
  const { state, setField } = useWizard();

  const isUsa = state.marketJurisdiction === "EUA";
  const isCanada = state.marketJurisdiction === "CA";
  const isMainline = state.storeType === "MAINLINE";
  const isOutlet = state.storeType === "OUTLET";

  return (
    <div className="w-full flex flex-col gap-6">
      {/* 1. Jurisdição Territorial e Fiscal */}
      <div className="w-full flex flex-col gap-3">
        {/* Typographic Section Header */}
        <div className="flex items-center gap-2 px-1">
          <span className="font-mono tabular-nums text-xs font-bold text-slate-400 select-none">01</span>
          <span className="text-slate-300">/</span>
          <h3 className="font-sans text-sm sm:text-base font-bold text-slate-900 tracking-tight">
            Jurisdição Territorial
          </h3>
          {state.marketJurisdiction ? (
            <span className="font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200/60 select-none">
              <span className="material-symbols-outlined text-[13px] font-bold">check</span>
              Definido
            </span>
          ) : (
            <span className="font-sans inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200/80 select-none">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
              Obrigatório
            </span>
          )}
        </div>

        {/* Minimalist Flag Cards diretamente na página */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
          {/* Card: Estados Unidos */}
          <div
            role="radio"
            aria-checked={isUsa}
            tabIndex={0}
            onClick={() => setField("marketJurisdiction", "EUA")}
            onKeyDown={(e) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault();
                setField("marketJurisdiction", "EUA");
              }
            }}
            className={`group rounded-xl p-4 sm:p-5 cursor-pointer flex items-center justify-between gap-4 transition-all duration-150 focus-visible:outline-2 focus-visible:outline-emerald-600 ${
              isUsa
                ? "bg-white border-2 border-emerald-600 shadow-xs"
                : "bg-white border border-slate-200 hover:border-slate-300 hover:shadow-2xs"
            }`}
          >
            <div className="flex items-center gap-3.5 min-w-0">
              <UsaFlag className="w-10 h-7 rounded shadow-2xs shrink-0" />
              <div className="flex flex-col min-w-0 font-sans">
                <div className="flex items-center gap-2">
                  <h4 className="font-sans font-bold text-slate-900 text-sm sm:text-base tracking-tight truncate">
                    Estados Unidos
                  </h4>
                  <span className="font-mono tabular-nums text-[11px] font-semibold text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded">
                    USD ($)
                  </span>
                </div>
                <p className="font-sans text-xs text-slate-500 mt-0.5">
                  Mercado doméstico regular
                </p>
              </div>
            </div>

            <div
              aria-hidden="true"
              className={`w-5 h-5 rounded-full flex items-center justify-center shrink-0 transition-colors ${
                isUsa
                  ? "bg-emerald-600 text-white"
                  : "border-2 border-slate-300"
              }`}
            >
              {isUsa && (
                <span className="material-symbols-outlined text-[13px] font-bold">check</span>
              )}
            </div>
          </div>

          {/* Card: Canadá */}
          <div
            role="radio"
            aria-checked={isCanada}
            tabIndex={0}
            onClick={() => setField("marketJurisdiction", "CA")}
            onKeyDown={(e) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault();
                setField("marketJurisdiction", "CA");
              }
            }}
            className={`group rounded-xl p-4 sm:p-5 cursor-pointer flex items-center justify-between gap-4 transition-all duration-150 focus-visible:outline-2 focus-visible:outline-emerald-600 ${
              isCanada
                ? "bg-white border-2 border-emerald-600 shadow-xs"
                : "bg-white border border-slate-200 hover:border-slate-300 hover:shadow-2xs"
            }`}
          >
            <div className="flex items-center gap-3.5 min-w-0">
              <CanadaFlag className="w-10 h-7 rounded shadow-2xs shrink-0" />
              <div className="flex flex-col min-w-0 font-sans">
                <div className="flex items-center gap-2">
                  <h4 className="font-sans font-bold text-slate-900 text-sm sm:text-base tracking-tight truncate">
                    Canadá
                  </h4>
                  <span className="font-mono tabular-nums text-[11px] font-semibold text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded">
                    CAD ($)
                  </span>
                </div>
                <p className="font-sans text-xs text-slate-500 mt-0.5">
                  Regime transfronteiriço
                </p>
              </div>
            </div>

            <div
              aria-hidden="true"
              className={`w-5 h-5 rounded-full flex items-center justify-center shrink-0 transition-colors ${
                isCanada
                  ? "bg-emerald-600 text-white"
                  : "border-2 border-slate-300"
              }`}
            >
              {isCanada && (
                <span className="material-symbols-outlined text-[13px] font-bold">check</span>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* 2. Formato Comercial da Loja Recetora */}
      <div className="w-full flex flex-col gap-3">
        {/* Typographic Section Header */}
        <div className="flex items-center gap-2 px-1">
          <span className="font-mono tabular-nums text-xs font-bold text-slate-400 select-none">02</span>
          <span className="text-slate-300">/</span>
          <h3 className="font-sans text-sm sm:text-base font-bold text-slate-900 tracking-tight">
            Formato Comercial da Loja
          </h3>
          {state.storeType ? (
            <span className="font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200/60 select-none">
              <span className="material-symbols-outlined text-[13px] font-bold">check</span>
              Definido
            </span>
          ) : (
            <span className="font-sans inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200/80 select-none">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
              Obrigatório
            </span>
          )}
        </div>

        {/* Minimalist Cards diretamente na página */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
          {/* Card: Loja Mainline */}
          <div
            role="radio"
            aria-checked={isMainline}
            tabIndex={0}
            onClick={() => setField("storeType", "MAINLINE")}
            onKeyDown={(e) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault();
                setField("storeType", "MAINLINE");
              }
            }}
            className={`group rounded-xl p-4 sm:p-5 cursor-pointer flex items-center justify-between gap-4 transition-all duration-150 focus-visible:outline-2 focus-visible:outline-emerald-600 ${
              isMainline
                ? "bg-white border-2 border-emerald-600 shadow-xs"
                : "bg-white border border-slate-200 hover:border-slate-300 hover:shadow-2xs"
            }`}
          >
            <div className="flex items-center gap-3.5 min-w-0">
              <div
                className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-colors ${
                  isMainline
                    ? "bg-emerald-50 text-emerald-700"
                    : "bg-slate-100 text-slate-600"
                }`}
              >
                <span className="material-symbols-outlined text-[22px]">storefront</span>
              </div>
              <div className="flex flex-col min-w-0 font-sans">
                <div className="flex items-center gap-2">
                  <h4 className="font-sans font-bold text-slate-900 text-sm sm:text-base tracking-tight truncate">
                    Loja Mainline
                  </h4>
                  <span className="font-sans text-[11px] font-semibold text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded">
                    Regular
                  </span>
                </div>
                <p className="font-sans text-xs text-slate-500 mt-0.5">
                  Lojas conceito, flagships e coleções regulares
                </p>
              </div>
            </div>

            <div
              aria-hidden="true"
              className={`w-5 h-5 rounded-full flex items-center justify-center shrink-0 transition-colors ${
                isMainline
                  ? "bg-emerald-600 text-white"
                  : "border-2 border-slate-300"
              }`}
            >
              {isMainline && (
                <span className="material-symbols-outlined text-[13px] font-bold">check</span>
              )}
            </div>
          </div>

          {/* Card: Loja Outlet */}
          <div
            role="radio"
            aria-checked={isOutlet}
            tabIndex={0}
            onClick={() => setField("storeType", "OUTLET")}
            onKeyDown={(e) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault();
                setField("storeType", "OUTLET");
              }
            }}
            className={`group rounded-xl p-4 sm:p-5 cursor-pointer flex items-center justify-between gap-4 transition-all duration-150 focus-visible:outline-2 focus-visible:outline-emerald-600 ${
              isOutlet
                ? "bg-white border-2 border-emerald-600 shadow-xs"
                : "bg-white border border-slate-200 hover:border-slate-300 hover:shadow-2xs"
            }`}
          >
            <div className="flex items-center gap-3.5 min-w-0">
              <div
                className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-colors ${
                  isOutlet
                    ? "bg-emerald-50 text-emerald-700"
                    : "bg-slate-100 text-slate-600"
                }`}
              >
                <span className="material-symbols-outlined text-[22px]">sell</span>
              </div>
              <div className="flex flex-col min-w-0 font-sans">
                <div className="flex items-center gap-2">
                  <h4 className="font-sans font-bold text-slate-900 text-sm sm:text-base tracking-tight truncate">
                    Loja Outlet
                  </h4>
                  <span className="font-sans text-[11px] font-semibold text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded">
                    Factory
                  </span>
                </div>
                <p className="font-sans text-xs text-slate-500 mt-0.5">
                  Centros factory, promoções e pontas de stock
                </p>
              </div>
            </div>

            <div
              aria-hidden="true"
              className={`w-5 h-5 rounded-full flex items-center justify-center shrink-0 transition-colors ${
                isOutlet
                  ? "bg-emerald-600 text-white"
                  : "border-2 border-slate-300"
              }`}
            >
              {isOutlet && (
                <span className="material-symbols-outlined text-[13px] font-bold">check</span>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* 3. Canal de Compra Original */}
      <div className="w-full flex flex-col gap-3">
        {/* Typographic Section Header */}
        <div className="flex items-center gap-2 px-1">
          <span className="font-mono tabular-nums text-xs font-bold text-slate-400 select-none">03</span>
          <span className="text-slate-300">/</span>
          <h3 className="font-sans text-sm sm:text-base font-bold text-slate-900 tracking-tight">
            Canal de Compra Original
          </h3>
          {state.purchaseChannel ? (
            <span
              className={`font-sans inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold border select-none ${
                state.purchaseChannel === "GROSSISTA"
                  ? "bg-red-50 text-red-700 border-red-200/60"
                  : state.purchaseChannel === "FRANQUIA_CA"
                  ? "bg-amber-50 text-amber-700 border-amber-200/60"
                  : "bg-emerald-50 text-emerald-700 border-emerald-200/60"
              }`}
            >
              <span className="material-symbols-outlined text-[13px] font-bold">check</span>
              Definido
            </span>
          ) : (
            <span className="font-sans inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200/80 select-none">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
              Obrigatório
            </span>
          )}
        </div>

        {/* Minimalist Cards Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3.5">
          {CHANNELS.map((ch) => {
            const isSelected = state.purchaseChannel === ch.id;

            // Determinação de cores de seleção contextual conforme o canal
            let selectedBorderClass = "border-2 border-emerald-600 bg-white shadow-xs";
            let selectedIconClass = "bg-emerald-50 text-emerald-700";
            let selectedCircleClass = "bg-emerald-600 text-white";
            let focusOutlineClass = "focus-visible:outline-emerald-600";

            if (ch.id === "GROSSISTA") {
              // Estilo de paragem obrigatória / recusa direta
              selectedBorderClass = "border-2 border-red-500 bg-white shadow-xs";
              selectedIconClass = "bg-red-50 text-red-700";
              selectedCircleClass = "bg-red-500 text-white";
              focusOutlineClass = "focus-visible:outline-red-500";
            } else if (ch.id === "FRANQUIA_CA") {
              // Estilo de processo especial / encaminhamento
              selectedBorderClass = "border-2 border-amber-500 bg-white shadow-xs";
              selectedIconClass = "bg-amber-50 text-amber-700";
              selectedCircleClass = "bg-amber-500 text-white";
              focusOutlineClass = "focus-visible:outline-amber-500";
            }

            return (
              <div
                key={ch.id}
                role="radio"
                aria-checked={isSelected}
                tabIndex={0}
                onClick={() => setField("purchaseChannel", ch.id as any)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" || e.key === " ") {
                    e.preventDefault();
                    setField("purchaseChannel", ch.id as any);
                  }
                }}
                className={`group rounded-xl p-4 sm:p-4.5 cursor-pointer flex items-center justify-between gap-3.5 transition-all duration-150 focus-visible:outline-2 ${focusOutlineClass} ${
                  isSelected
                    ? selectedBorderClass
                    : "bg-white border border-slate-200 hover:border-slate-300 hover:shadow-2xs"
                }`}
              >
                <div className="flex items-center gap-3 min-w-0">
                  <div
                    className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-colors ${
                      isSelected
                        ? selectedIconClass
                        : "bg-slate-100 text-slate-600"
                    }`}
                  >
                    <span className="material-symbols-outlined text-[20px]">{ch.icon}</span>
                  </div>
                  <div className="flex flex-col min-w-0 font-sans">
                    <div className="flex items-center gap-1.5 flex-wrap">
                      <h4 className="font-sans font-bold text-slate-900 text-sm tracking-tight truncate">
                        {ch.title}
                      </h4>
                      {ch.badge && (
                        <span className="font-sans text-[10px] font-semibold text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded">
                          {ch.badge}
                        </span>
                      )}
                    </div>
                    <p className="font-sans text-xs text-slate-500 mt-0.5 truncate">
                      {ch.subtitle}
                    </p>
                  </div>
                </div>

                <div
                  aria-hidden="true"
                  className={`w-5 h-5 rounded-full flex items-center justify-center shrink-0 transition-colors ${
                    isSelected
                      ? selectedCircleClass
                      : "border-2 border-slate-300"
                  }`}
                >
                  {isSelected && (
                    <span className="material-symbols-outlined text-[13px] font-bold">check</span>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
