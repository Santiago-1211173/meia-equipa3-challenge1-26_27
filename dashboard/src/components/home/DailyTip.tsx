"use client";

import React, { useState } from "react";

interface Tip {
  id: string;
  badge: string;
  category: string;
  title: string;
  text: string;
}

const tipsList: Tip[] = [
  {
    id: "tip-1",
    badge: "Dica do Dia",
    category: "Suporte & Boas Práticas Levi's",
    title: "Comprovativo Digital sem Papel Físico",
    text: "O Comprovativo Digital (levi.com ou BackPocket) pode ser consultado pelo e-mail sem precisar do papel físico! O motor valida a assinatura do recibo na nuvem de forma instantânea.",
  },
  {
    id: "tip-2",
    badge: "Atenção Higiénica",
    category: "Validação de Vestuário",
    title: "Peças Íntimas e Roupa Interior",
    text: "Por normas de higiene, boxers e roupa interior apenas podem ser aceites se a embalagem original selada estiver inviolada e com as etiquetas de fábrica.",
  },
  {
    id: "tip-3",
    badge: "Agilidade no Balcão",
    category: "Trocas Rápidas",
    title: "Trocas Diretas de Tamanho",
    text: "Quando o cliente pretende apenas trocar de tamanho da mesma peça (ex: 501® W32 para W34), o processo de aprovação é imediato dispensando estorno bancário.",
  },
];

export default function DailyTip() {
  const [currentTipIndex, setCurrentTipIndex] = useState(0);
  const [acknowledged, setAcknowledged] = useState(false);

  const tip = tipsList[currentTipIndex];

  const handleNextTip = () => {
    setAcknowledged(true);
    setTimeout(() => {
      setCurrentTipIndex((prev) => (prev + 1) % tipsList.length);
      setAcknowledged(false);
    }, 400);
  };

  return (
    <section
      aria-label="Dica pedagógica do turno"
      className="bg-gradient-to-r from-secondary-fixed/50 via-surface-container-low to-surface-container-lowest p-6 md:p-8 rounded-2xl shadow-sm border border-border-card flex flex-col md:flex-row items-center gap-6 relative overflow-hidden transition-all"
    >
      {/* Decorative Icon */}
      <div className="w-16 h-16 rounded-full bg-surface-container-lowest flex items-center justify-center text-secondary shadow-[0_4px_0_0_#adc6ff] flex-shrink-0 animate-pulse">
        <span
          className="material-symbols-outlined text-[36px]"
          style={{ fontVariationSettings: "'FILL' 1" }}
        >
          emoji_objects
        </span>
      </div>

      {/* Content */}
      <div className="flex flex-col gap-1.5 max-w-3xl flex-1 text-center md:text-left">
        <div className="flex flex-wrap items-center justify-center md:justify-start gap-2">
          <span className="px-3 py-0.5 rounded-full bg-secondary text-on-secondary font-label-md text-xs uppercase font-bold tracking-wider">
            {tip.badge}
          </span>
          <span className="text-on-surface-variant font-caption text-xs">
            {tip.category}
          </span>
        </div>

        <h4 className="font-sans font-headline-sm text-on-surface text-lg md:text-xl font-bold">
          {tip.title}
        </h4>

        <p className="font-sans font-body-md text-on-surface-variant text-sm md:text-base leading-relaxed">
          {tip.text}
        </p>
      </div>

      {/* Action Button */}
      <div className="md:ml-auto flex-shrink-0">
        <button
          type="button"
          onClick={handleNextTip}
          className={`font-sans px-5 py-2.5 rounded-full bg-surface-container-lowest text-secondary font-label-md text-xs md:text-sm font-semibold shadow-[0_3px_0_0_#adc6ff] hover:shadow-[0_1px_0_0_#adc6ff] hover:translate-y-[2px] active:shadow-none active:translate-y-[3px] transition-all cursor-pointer flex items-center gap-1.5 select-none ${
            acknowledged ? "scale-95 bg-emerald-50 text-emerald-700" : ""
          }`}
        >
          {acknowledged ? (
            <>
              <span className="material-symbols-outlined text-[18px] text-emerald-600">
                check_circle
              </span>
              <span>Perfeito! ✨</span>
            </>
          ) : (
            <>
              <span>Compreendido!</span>
              <span aria-hidden="true">👍</span>
            </>
          )}
        </button>
      </div>

      {/* Subtle background glow */}
      <div className="absolute right-0 top-0 w-32 h-32 bg-secondary-fixed/30 rounded-full blur-2xl pointer-events-none" />
    </section>
  );
}
