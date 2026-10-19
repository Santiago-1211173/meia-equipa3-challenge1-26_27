"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useOptionalWizard } from "@/components/wizard/WizardContext";

export interface NavbarProps {
  activeRoute?: "painel" | "novo-atendimento" | "decisoes" | string;
  operatorName?: string;
  operatorRole?: string;
  storeName?: string;
  streakCount?: number;
}

function getInitials(name: string): string {
  if (!name) return "OP";
  const parts = name.trim().split(/\s+/);
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

export default function Navbar({
  activeRoute = "painel",
  operatorName = "Tiago M.",
  operatorRole = "Operador N2",
}: NavbarProps) {
  const router = useRouter();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const wizard = useOptionalWizard();

  const handleNavClick = (e: React.MouseEvent<HTMLAnchorElement>, href: string) => {
    if (wizard && wizard.isDirty) {
      e.preventDefault();
      const target = href === "/novo-atendimento" ? "/novo-atendimento/passo/1" : href;
      wizard.setPendingNavigationUrl(target);
      wizard.setShowLeaveModal(true);
      if (mobileMenuOpen) setMobileMenuOpen(false);
    } else if (wizard && wizard.evaluationResult) {
      e.preventDefault();
      if (mobileMenuOpen) setMobileMenuOpen(false);
      const target = href === "/novo-atendimento" ? "/novo-atendimento/passo/1" : href;
      wizard.exitTo(target);
    }
  };

  const navLinks = [
    { href: "/", key: "painel", label: "Painel Principal" },
    { href: "/novo-atendimento", key: "novo-atendimento", label: "Novo Atendimento" },
    { href: "/decisoes", key: "decisoes", label: "Decisões & Histórico" },
  ];

  // Close mobile drawer on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && mobileMenuOpen) {
        setMobileMenuOpen(false);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [mobileMenuOpen]);

  const initials = getInitials(operatorName);

  return (
    <header
      role="banner"
      className="fixed top-0 left-0 w-full z-50 bg-white border-b border-slate-200"
    >
      <div className="h-16 w-full max-w-7xl mx-auto px-4 sm:px-6 md:px-8 flex items-center justify-between">
        {/* Brand */}
        <div className="flex items-center">
          <Link
            href="/"
            onClick={(e) => handleNavClick(e, "/")}
            aria-label="Ir para a página inicial do RetailFlow"
            className="flex items-center gap-2 select-none focus-visible:outline-2 focus-visible:outline-primary rounded"
          >
            <span className="font-display font-bold text-lg tracking-tight text-slate-900">
              RetailFlow
            </span>
          </Link>
        </div>

        {/* Minimalist Desktop Navigation (clean text tabs, no pills, no boxes) */}
        <nav
          aria-label="Navegação Principal"
          className="hidden md:flex items-center gap-8 h-16 font-sans"
        >
          {navLinks.map((item) => {
            const isActive = activeRoute === item.key;
            return (
              <Link
                key={item.key}
                href={item.href}
                onClick={(e) => handleNavClick(e, item.href)}
                aria-current={isActive ? "page" : undefined}
                className={`relative inline-flex items-center h-full text-sm transition-colors select-none focus-visible:outline-2 focus-visible:outline-primary ${
                  isActive
                    ? "font-semibold text-slate-900"
                    : "font-medium text-slate-500 hover:text-slate-900"
                }`}
              >
                <span>{item.label}</span>
                {isActive && (
                  <span
                    className="absolute bottom-0 inset-x-0 h-[2px] bg-primary -mb-px"
                    aria-hidden="true"
                  />
                )}
              </Link>
            );
          })}
        </nav>

        {/* Right side: Operator profile & mobile toggle */}
        <div className="flex items-center gap-3 font-sans">
          {/* Operator Profile */}
          <div className="flex items-center gap-2.5 select-none">
            <div className="relative">
              <div
                className="w-8 h-8 rounded-full bg-slate-100 border border-slate-200/80 text-slate-700 flex items-center justify-center text-xs font-semibold"
                aria-hidden="true"
              >
                {initials}
              </div>
              <span
                className="absolute -bottom-0.5 -right-0.5 w-2 h-2 rounded-full bg-emerald-500 ring-2 ring-white"
                title="Sessão ativa"
                aria-label="Sessão ativa"
              />
            </div>
            <div className="hidden sm:flex flex-col text-left leading-tight">
              <span className="text-xs font-semibold text-slate-900">
                {operatorName}
              </span>
              <span className="text-[11px] text-slate-500">
                {operatorRole}
              </span>
            </div>
          </div>

          {/* Mobile hamburger button */}
          <button
            type="button"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label={mobileMenuOpen ? "Fechar menu de navegação" : "Abrir menu de navegação"}
            aria-expanded={mobileMenuOpen}
            className="md:hidden p-1.5 rounded-md text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition-colors focus-visible:outline-2 focus-visible:outline-primary cursor-pointer"
          >
            <span className="material-symbols-outlined text-[22px]">
              {mobileMenuOpen ? "close" : "menu"}
            </span>
          </button>
        </div>
      </div>

      {/* Mobile navigation drawer */}
      {mobileMenuOpen && (
        <div className="md:hidden border-t border-slate-200 bg-white px-4 py-3 flex flex-col gap-1">
          {navLinks.map((item) => {
            const isActive = activeRoute === item.key;
            return (
              <Link
                key={item.key}
                href={item.href}
                onClick={(e) => {
                  setMobileMenuOpen(false);
                  handleNavClick(e, item.href);
                }}
                aria-current={isActive ? "page" : undefined}
                className={`px-3 py-2 rounded-md text-sm transition-colors focus-visible:outline-2 focus-visible:outline-primary ${
                  isActive
                    ? "font-semibold text-slate-900 bg-slate-100"
                    : "font-medium text-slate-600 hover:text-slate-900 hover:bg-slate-50"
                }`}
              >
                {item.label}
              </Link>
            );
          })}
        </div>
      )}
    </header>
  );
}
