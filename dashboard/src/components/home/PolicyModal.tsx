"use client";

import React from "react";

export interface PolicyModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function PolicyModal({ isOpen, onClose }: PolicyModalProps) {
  if (!isOpen) return null;

  const policies = [
    {
      title: "Prazo de Devolução Standard (30 Dias)",
      tag: "Regra Fundamental",
      desc: "Devoluções completas ou trocas de artigos adquiridos em loja física ou online são aceites até 30 dias contados a partir da data de compra ou receção da encomenda.",
      icon: "calendar_month",
      badgeColor: "bg-primary-container text-white",
    },
    {
      title: "Estado Original e Etiquetas de Fábrica",
      tag: "Condição Física",
      desc: "Os artigos não podem ter sido usados, lavados ou alterados (ex: bainhas encurtadas). As etiquetas de fábrica e o código de barras de inventário devem estar intactos.",
      icon: "sell",
      badgeColor: "bg-surface-container-high text-on-surface",
    },
    {
      title: "Higiene em Vestuário Íntimo",
      tag: "Norma Sanitária",
      desc: "Boxers, roupa interior e fatos de banho só são elegíveis para devolução se a embalagem selada original se mantiver intacta e com o selo higiénico inviolado.",
      icon: "health_and_safety",
      badgeColor: "bg-tertiary-fixed text-on-tertiary-fixed",
    },
    {
      title: "Comprovativo Digital ou em Nuvem",
      tag: "Novidade Março 2025",
      desc: "Não é exigido talão em papel físico. Comprovativos obtidos via Levi's 247 App, BackPocket ou e-mail com QR code são validados de forma imediata no POS.",
      icon: "qr_code_scanner",
      badgeColor: "bg-secondary-fixed text-on-secondary-fixed",
    },
    {
      title: "Trocas entre Mainline e Outlet",
      tag: "Inter-loja",
      desc: "Artigos adquiridos em loja Mainline podem ser trocados em Outlet pelo valor atual de sistema. Artigos exclusivos de Outlet Factory Store mantêm políticas próprias de clearance.",
      icon: "storefront",
      badgeColor: "bg-surface-container-high text-on-surface",
    },
  ];

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="policy-modal-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs animate-fadeIn"
    >
      <div className="bg-white w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-3xl p-6 md:p-8 shadow-2xl border border-border-card flex flex-col gap-6">
        {/* Header */}
        <div className="flex items-start justify-between gap-4 border-b border-border-card pb-4">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-full bg-primary-container text-white flex items-center justify-center shadow-[0_2px_0_0_#059669]">
              <span className="material-symbols-outlined text-[24px]">menu_book</span>
            </div>
            <div>
              <span className="font-label-md text-xs font-bold text-primary uppercase tracking-wider">
                Políticas Vigentes • Edição Março 2025
              </span>
              <h3
                id="policy-modal-title"
                className="font-sans font-headline-sm text-on-surface text-xl md:text-2xl font-bold"
              >
                Manual Rápido de Balcão e Devoluções
              </h3>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            aria-label="Fechar modal de políticas"
            className="w-9 h-9 rounded-full bg-surface-container-low text-on-surface-variant hover:text-on-surface flex items-center justify-center cursor-pointer transition-colors"
          >
            <span className="material-symbols-outlined text-[20px]">close</span>
          </button>
        </div>

        {/* Policy list */}
        <div className="flex flex-col gap-3">
          {policies.map((p, idx) => (
            <div
              key={idx}
              className="p-4 rounded-2xl bg-surface-container-low/70 border border-border-card flex items-start gap-4 font-sans"
            >
              <div className="w-10 h-10 rounded-xl bg-white flex items-center justify-center text-primary shadow-xs border border-border-card flex-shrink-0">
                <span className="material-symbols-outlined text-[22px]">{p.icon}</span>
              </div>
              <div className="flex flex-col gap-1">
                <div className="flex flex-wrap items-center gap-2">
                  <h4 className="font-sans font-headline-sm text-sm text-on-surface font-bold">
                    {p.title}
                  </h4>
                  <span
                    className={`font-sans px-2.5 py-0.5 rounded-full font-label-md text-[11px] font-bold ${p.badgeColor}`}
                  >
                    {p.tag}
                  </span>
                </div>
                <p className="font-sans font-body-md text-on-surface-variant text-xs leading-relaxed">
                  {p.desc}
                </p>
              </div>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between gap-4 pt-3 border-t border-border-card font-sans">
          <span className="font-sans font-caption text-xs text-on-surface-variant flex items-center gap-1">
            <span className="material-symbols-outlined text-[16px] text-primary">verified</span>
            Regras sincronizadas com motores Drools 8 &amp; Prolog 9
          </span>

          <button
            type="button"
            onClick={onClose}
            className="font-sans px-6 py-2.5 rounded-full bg-primary-container text-white font-label-md text-xs font-semibold shadow-[0_3px_0_0_#059669] hover:translate-y-[1px] transition-all cursor-pointer"
          >
            Compreendido
          </button>
        </div>
      </div>
    </div>
  );
}
