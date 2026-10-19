"use client";

import React from "react";
import Link from "next/link";

export interface TrainingModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function TrainingModal({ isOpen, onClose }: TrainingModalProps) {
  if (!isOpen) return null;

  const scenarios = [
    {
      title: "Devolução Standard 501® (Aprovação)",
      desc: "Cliente apresenta jeans com 14 dias de compra, etiqueta afixada e recibo em papel perfeitamente legível.",
      icon: "check_circle",
      color: "text-primary",
      badge: "Iniciação N1",
    },
    {
      title: "Peça com Bainha Feita (Recusa Justificada)",
      desc: "Cliente solicitou alteração de comprimento de perna e pretende agora devolver por ter mudado de ideias.",
      icon: "content_cut",
      color: "text-error",
      badge: "Exceções",
    },
    {
      title: "Encomenda Web Levi.com com Troca no Balcão",
      desc: "Compra online sem papel físico. Cliente apresenta apenas o e-mail de expedição e quer trocar tamanho.",
      icon: "devices",
      color: "text-secondary",
      badge: "Omnicanal",
    },
  ];

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="training-modal-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs animate-fadeIn"
    >
      <div className="bg-white w-full max-w-lg rounded-3xl p-6 md:p-8 shadow-2xl border border-border-card flex flex-col gap-6">
        {/* Header */}
        <div className="flex items-start justify-between gap-4 border-b border-border-card pb-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-tertiary-fixed text-on-tertiary-fixed flex items-center justify-center shadow-xs">
              <span className="material-symbols-outlined text-[22px]">school</span>
            </div>
            <div>
              <span className="font-label-md text-xs font-bold text-tertiary uppercase tracking-wider">
                Ambiente Pedagógico
              </span>
              <h3
                id="training-modal-title"
                className="font-sans font-headline-sm text-on-surface text-lg md:text-xl font-bold"
              >
                Simular Cenário de Treino
              </h3>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            aria-label="Fechar modal"
            className="w-8 h-8 rounded-full bg-surface-container-low text-on-surface-variant hover:text-on-surface flex items-center justify-center cursor-pointer transition-colors"
          >
            <span className="material-symbols-outlined text-[20px]">close</span>
          </button>
        </div>

        <p className="font-sans font-body-md text-on-surface-variant text-xs md:text-sm">
          O modo de treino permite exercitar os fluxos de balcão e os motores de decisão formal
          sem registar movimentos na caixa real ou alterar o inventário físico.
        </p>

        {/* Scenarios */}
        <div className="flex flex-col gap-2.5">
          {scenarios.map((sc, i) => (
            <div
              key={i}
              className="p-3.5 rounded-2xl bg-surface-container-low border border-border-card flex items-start gap-3 font-sans"
            >
              <div className="w-9 h-9 rounded-xl bg-white flex items-center justify-center shadow-xs border border-border-card flex-shrink-0">
                <span className={`material-symbols-outlined text-[20px] ${sc.color}`}>
                  {sc.icon}
                </span>
              </div>
              <div className="flex flex-col gap-0.5">
                <div className="flex items-center gap-2">
                  <h4 className="font-sans font-label-lg text-xs font-bold text-on-surface">
                    {sc.title}
                  </h4>
                  <span className="font-sans px-2 py-0.2 rounded-full bg-surface-container-highest text-on-surface font-caption text-[10px] font-bold">
                    {sc.badge}
                  </span>
                </div>
                <p className="font-sans font-caption text-xs text-on-surface-variant">
                  {sc.desc}
                </p>
              </div>
            </div>
          ))}
        </div>

        {/* Action Button */}
        <div className="flex items-center justify-between gap-3 pt-3 border-t border-border-card font-sans">
          <button
            type="button"
            onClick={onClose}
            className="font-sans px-4 py-2 rounded-full bg-surface-container text-on-surface font-label-md text-xs font-semibold cursor-pointer"
          >
            Voltar
          </button>

          <Link
            href="/novo-atendimento"
            onClick={onClose}
            className="font-sans px-6 py-2.5 rounded-full bg-primary-container text-white font-label-md text-xs font-semibold shadow-[0_3px_0_0_#059669] hover:translate-y-[1px] transition-all flex items-center gap-2 cursor-pointer"
          >
            <span className="material-symbols-outlined text-[18px]">play_circle</span>
            <span>Iniciar no Wizard</span>
          </Link>
        </div>
      </div>
    </div>
  );
}
