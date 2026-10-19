"use client";

import React, { useState, useEffect, useRef, useCallback } from "react";
import { getInputsForStep, type StepInputItem } from "@/config/stepInputMapping";
import { api, ApiClientError } from "@/client/api";
import type { ExplicacaoPorqueResponse, RegraEmEsperaDto } from "@/types/returns";
import { moduleLabel, label } from "@/config/returnsLabels";

export interface WhyAskWidgetProps {
  stepNumber: number;
  engine: "returns" | "prolog" | string;
  returnRequest?: Record<string, unknown>;
  requestType?: string;
  physicalCondition?: string | null;
}

// Mapeamento semântico de módulos de regras para áreas de política de loja
const POLICY_NAMES: Record<string, string> = {
  CH: "Canais e Formatos de Loja",
  PC: "Elegibilidade e Estado da Peça",
  PT: "Comprovativo e Prazos",
  EX: "Exceções e Autorizações",
  TN: "Liquidação e Pagamento",
  EP: "Políticas de Troca e Ajuste",
  HS: "Procedimentos de Balcão",
  CT: "Contexto e Jurisdição",
  BW: "Vestuário e Higiene",
};

// Dicionário de humanização e estilos visuais minimalistas de desfechos
interface OutcomeInfo {
  label: string;
  icon: string;
  badgeClass: string;
}

const OUTCOME_DEFINITIONS: Record<string, OutcomeInfo> = {
  PERMITIR: {
    label: "Devolução Permitida",
    icon: "check_circle",
    badgeClass: "text-emerald-700 bg-emerald-50 border border-emerald-200/60",
  },
  RECUSAR: {
    label: "Devolução Recusada",
    icon: "cancel",
    badgeClass: "text-rose-700 bg-rose-50 border border-rose-200/60",
  },
  REVER: {
    label: "Requer Aprovação de Chefia",
    icon: "shield",
    badgeClass: "text-amber-700 bg-amber-50 border border-amber-200/60",
  },
  ENCAMINHAR: {
    label: "Encaminhar Pedido",
    icon: "forward",
    badgeClass: "text-sky-700 bg-sky-50 border border-sky-200/60",
  },
  ENCAMINHAR_PEDIDO: {
    label: "Encaminhar Pedido",
    icon: "forward",
    badgeClass: "text-sky-700 bg-sky-50 border border-sky-200/60",
  },
  REEMBOLSO: {
    label: "Reembolso Monetário",
    icon: "payments",
    badgeClass: "text-emerald-700 bg-emerald-50 border border-emerald-200/60",
  },
  CREDITO_LOJA: {
    label: "Emissão de Crédito de Loja",
    icon: "store",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  TROCA: {
    label: "Troca Direta de Artigo",
    icon: "swap_horiz",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  TROCA_DIRETA: {
    label: "Troca Direta de Tamanho",
    icon: "swap_horiz",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  TROCA_COM_VALOR: {
    label: "Troca com Recálculo de Valor",
    icon: "swap_horiz",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  CARTAO_OFERTA: {
    label: "Emissão de Cartão-Oferta",
    icon: "card_giftcard",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  CARTAO_OFERTA_ELETRONICO: {
    label: "Cartão-Oferta Eletrónico",
    icon: "card_giftcard",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  MEIO_ORIGINAL: {
    label: "Estorno pelo Meio Original",
    icon: "undo",
    badgeClass: "text-emerald-700 bg-emerald-50 border border-emerald-200/60",
  },
  ORIGINAL: {
    label: "Estorno no Meio Original",
    icon: "undo",
    badgeClass: "text-emerald-700 bg-emerald-50 border border-emerald-200/60",
  },
  ALTERNATIVO: {
    label: "Meio de Pagamento Alternativo",
    icon: "payments",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  MEIO_ALTERNATIVO: {
    label: "Meio de Pagamento Alternativo",
    icon: "payments",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  NUMERARIO: {
    label: "Estorno em Numerário",
    icon: "payments",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  APLICACAO: {
    label: "Aplicação de Pagamento",
    icon: "smartphone",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  APLICACAO_PAGAMENTO: {
    label: "Aplicação de Pagamento",
    icon: "smartphone",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  INTERAC: {
    label: "Terminal Interac (Canadá)",
    icon: "credit_card",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  AJUSTE_PRECO: {
    label: "Ajuste de Preço Comercial",
    icon: "price_change",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  TIPO_VERIFICADA: {
    label: "Devolução Verificada",
    icon: "verified",
    badgeClass: "text-emerald-700 bg-emerald-50 border border-emerald-200/60",
  },
  TIPO_AS_CEGAS: {
    label: "Devolução às Cegas",
    icon: "visibility_off",
    badgeClass: "text-amber-700 bg-amber-50 border border-amber-200/60",
  },
  OUT_003: {
    label: "Cálculo do Valor da Devolução",
    icon: "calculate",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  AREA_VENDAS: {
    label: "Retorno à Área de Vendas",
    icon: "check_circle",
    badgeClass: "text-emerald-700 bg-emerald-50 border border-emerald-200/60",
  },
  SALDOS: {
    label: "Encaminhar para Saldos",
    icon: "sell",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  BAIXA_DANO: {
    label: "Baixa por Artigo Danificado",
    icon: "report_problem",
    badgeClass: "text-rose-700 bg-rose-50 border border-rose-200/60",
  },
  REETIQUETAR: {
    label: "Reetiquetar Peça de Roupa",
    icon: "label",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  RISCO_BIOLOGICO: {
    label: "Isolamento por Risco Biológico",
    icon: "warning",
    badgeClass: "text-rose-700 bg-rose-50 border border-rose-200/60",
  },
  DEVOLUCAO_CLIENTE: {
    label: "Devolver Artigo ao Cliente",
    icon: "undo",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  },
  XSTORE_MANAGER: {
    label: "Aprovação Gestor de Loja",
    icon: "admin_panel_settings",
    badgeClass: "text-amber-700 bg-amber-50 border border-amber-200/60",
  },
  RESPONSAVEL_SENIOR: {
    label: "Aprovação Responsável Sénior",
    icon: "admin_panel_settings",
    badgeClass: "text-amber-700 bg-amber-50 border border-amber-200/60",
  },
  DISTRICT_AREA: {
    label: "Aprovação District Manager",
    icon: "admin_panel_settings",
    badgeClass: "text-amber-700 bg-amber-50 border border-amber-200/60",
  },
};

/** Analisa a conclusão técnica e converte-a num desfecho claro com ícone e estilo minimalista */
function parseOutcome(raw: string): OutcomeInfo | null {
  if (!raw) return null;

  // Remove qualquer prefixo OUT-001:, OUT-001=, etc. e remove : ou = residuais no início
  const withoutPrefix = raw
    .replace(/^[A-Z]{2,4}-\d{3,4}\s*[:=]\s*/i, "")
    .replace(/^[:=]\s*/, "")
    .trim();

  const cleaned = withoutPrefix.toUpperCase();

  // Filtrar conclusões neutras ou sem impacto operacional imediato
  if (!cleaned || cleaned === "NENHUMA" || cleaned === "NENHUM") {
    return null;
  }

  // Tratamento específico de cálculo OUT-003
  if (/^OUT[-_]?003$/i.test(raw.trim()) || cleaned === "OUT-003") {
    return OUTCOME_DEFINITIONS.OUT_003;
  }

  if (OUTCOME_DEFINITIONS[cleaned]) {
    return OUTCOME_DEFINITIONS[cleaned];
  }

  const humanLabel = label(withoutPrefix).replace(/^[:=]\s*/, "").trim();
  if (!humanLabel || humanLabel.toLowerCase() === "nenhuma" || humanLabel.toLowerCase() === "nenhum") {
    return null;
  }

  return {
    label: humanLabel,
    icon: "check_circle",
    badgeClass: "text-slate-700 bg-slate-100 border border-slate-200/70",
  };
}

/** Extrai áreas de política de loja a partir das regras dependentes sem exibir códigos XX-YYY */
function getPolicyCategories(regras?: string[] | null): string[] {
  if (!regras || regras.length === 0) return [];
  const set = new Set<string>();
  for (const r of regras) {
    const prefix = r.split("-")[0]?.toUpperCase();
    if (prefix && POLICY_NAMES[prefix]) {
      set.add(POLICY_NAMES[prefix]);
    }
  }
  return Array.from(set);
}

/** Filtra e limpa condições do dado descartando jargão técnico redundante */
function parseCondition(c: { descricao?: string | null; nome?: string | null }): string | null {
  const text = (c.descricao || c.nome || "").trim();
  if (!text) return null;

  // Filtrar jargão de depuração interno do motor
  if (
    /avaliação da premissa/i.test(text) ||
    /premissa/i.test(text) ||
    /\b(?:atributo|regra|regras)\s+[A-Z]{2,4}-\d{3,4}/i.test(text)
  ) {
    return null;
  }

  // Filtrar expressões lógicas de código
  if (/!=|==|null|<|>|<=|>=/i.test(text)) {
    return null;
  }

  const sanitized = cleanCounterText(text);
  if (
    sanitized.length < 5 ||
    /\b(?:para|para a|de|do|com|em|para a regra)\s*$/i.test(sanitized) ||
    /^[A-Z]{2,4}-\d{3,4}/i.test(sanitized)
  ) {
    return null;
  }

  return sanitized;
}

/** Remove códigos do nome da regra (ex: "CH-010 Compra Mainline..." -> "Compra Mainline...") */
function humanizeRuleName(nomeRegra?: string | null): string {
  if (!nomeRegra) return "Norma de conformidade de balcão";
  const cleaned = nomeRegra
    .replace(/^\[?[A-Z]{2,4}-\d{3,4}(?:-[A-Z0-9]+)?\]?\s*[:–—-]?\s*/g, "")
    .replace(/\b[A-Z]{2,4}-\d{3,4}(?:-[A-Z0-9]+)?\b/g, "")
    .trim();
  return cleaned || "Norma de conformidade de balcão";
}

/** Sanitiza texto pericial garantindo que nenhum código XX-YYY surge no balcão */
function cleanCounterText(text?: string | null): string {
  if (!text) return "";
  let s = text;

  // 1. Remove sufixos de debug de perguntas (ex: "(eua/canada/porquê)")
  s = s.replace(/\s*\([a-z_/]+porquê\)/gi, "");

  // 2. Remove listas de códigos de regra entre parênteses: (CH-007, HS-004), (TN-011), etc.
  s = s.replace(/\s*\(\s*[A-Z]{2,4}-\d{3,4}(?:-[A-Z0-9]+)?(?:\s*,\s*[A-Z]{2,4}-\d{3,4}(?:-[A-Z0-9]+)?)*\s*\)/g, "");

  // 3. Remove "via CH-008", "regra CH-001", etc.
  s = s.replace(/\b(?:via|regra|regras)\s+[A-Z]{2,4}-\d{3,4}(?:-[A-Z0-9]+)?\b/gi, "");

  // 4. Limpeza geral de quaisquer códigos residuais XX-YYY
  s = s.replace(/\b[A-Z]{2,4}-\d{3,4}(?:-[A-Z0-9]+)?\b/g, "");

  // 5. Humanizar conclusões técnicas em colchetes se presentes (ex: "→ [REEMBOLSO_DEBITO_INTERAC]" -> ": Reembolso debito interac")
  s = s.replace(/:\s*→\s*\[([A-Z0-9_]+)\]/g, (_, code) => `: ${label(code)}`);
  s = s.replace(/→\s*\[([A-Z0-9_]+)\]/g, (_, code) => `(${label(code)})`);

  // 6. Normalizar pontuação e espaços residuais
  s = s
    .replace(/:\s*→/g, ":")
    .replace(/\(\s*\)/g, "")
    .replace(/\s+([,.;:])/g, "$1")
    .replace(/,\s*,/g, ",")
    .replace(/\s{2,}/g, " ")
    .trim();

  return s;
}

export default function WhyAskWidget({
  stepNumber,
  engine,
  returnRequest,
  requestType,
  physicalCondition,
}: WhyAskWidgetProps) {
  const effectiveRequestType =
    requestType || (returnRequest?.tipoPedido as string) || undefined;
  const effectivePhysicalCondition =
    physicalCondition ||
    (returnRequest?.artigos as Array<Record<string, any>>)?.[0]?.estado?.condicaoUso ||
    undefined;
  const inputs: StepInputItem[] = getInputsForStep(
    stepNumber,
    effectiveRequestType,
    effectivePhysicalCondition
  );

  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [isRendered, setIsRendered] = useState<boolean>(false);

  useEffect(() => {
    if (isOpen) {
      setIsRendered(true);
    } else if (isRendered) {
      // Fallback de segurança para garantir desmontagem limpa caso animationend não dispare
      const timer = setTimeout(() => {
        setIsRendered(false);
      }, 200);
      return () => clearTimeout(timer);
    }
  }, [isOpen, isRendered]);

  const handleAnimationEnd = (e: React.AnimationEvent<HTMLDivElement>) => {
    // Apenas responde a animações do próprio contentor do popup
    if (e.target !== e.currentTarget) return;
    if (!isOpen) {
      setIsRendered(false);
    }
  };

  const [selectedCodeOverride, setSelectedCodeOverride] = useState<string | null>(null);

  useEffect(() => {
    setSelectedCodeOverride(null);
  }, [stepNumber, effectiveRequestType, effectivePhysicalCondition]);
  const [data, setData] = useState<ExplicacaoPorqueResponse | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Deriva o código ativo garantindo sempre que pertence aos inputs do passo em curso
  const selectedCode =
    selectedCodeOverride && inputs.some((item) => item.code === selectedCodeOverride)
      ? selectedCodeOverride
      : inputs[0]?.code || "";

  // Cache para transições instantâneas entre chips/perguntas
  const cacheRef = useRef<Record<string, ExplicacaoPorqueResponse>>({});
  const popoverRef = useRef<HTMLDivElement>(null);
  const triggerButtonRef = useRef<HTMLButtonElement>(null);
  const tabsContainerRef = useRef<HTMLDivElement>(null);

  // Estados de rolagem horizontal das abas de perguntas
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const isMouseDownRef = useRef(false);
  const startXRef = useRef(0);
  const scrollLeftRef = useRef(0);
  const hasDraggedRef = useRef(false);

  // Verificação de limites de scroll horizontal
  const checkScroll = useCallback(() => {
    const el = tabsContainerRef.current;
    if (!el) return;
    const left = el.scrollLeft > 2;
    const right = el.scrollLeft < el.scrollWidth - el.clientWidth - 2;
    setCanScrollLeft(left);
    setCanScrollRight(right);
  }, []);

  // Monitorização de scroll e redimensionamento da janela
  useEffect(() => {
    if (!isOpen) return;
    const el = tabsContainerRef.current;
    if (!el) return;

    checkScroll();
    el.addEventListener("scroll", checkScroll, { passive: true });
    window.addEventListener("resize", checkScroll);

    return () => {
      el.removeEventListener("scroll", checkScroll);
      window.removeEventListener("resize", checkScroll);
    };
  }, [isOpen, checkScroll, inputs]);

  // Conversão de scroll vertical do rato (deltaY) para scroll horizontal instantâneo
  useEffect(() => {
    if (!isOpen) return;
    const el = tabsContainerRef.current;
    if (!el) return;

    const onWheel = (e: WheelEvent) => {
      if (e.deltaY !== 0) {
        e.preventDefault();
        el.scrollLeft += e.deltaY;
        checkScroll();
      }
    };

    el.addEventListener("wheel", onWheel, { passive: false });
    return () => {
      el.removeEventListener("wheel", onWheel);
    };
  }, [isOpen, checkScroll]);

  // Centrar automaticamente a pergunta selecionada ao alterar
  useEffect(() => {
    if (!isOpen || !selectedCode || !tabsContainerRef.current) return;
    const timer = setTimeout(() => {
      const el = tabsContainerRef.current;
      if (!el) return;
      const btn = el.querySelector<HTMLButtonElement>(`[data-code="${selectedCode}"]`);
      if (btn) {
        const containerWidth = el.clientWidth;
        const btnLeft = btn.offsetLeft;
        const btnWidth = btn.clientWidth;
        const targetScroll = btnLeft - containerWidth / 2 + btnWidth / 2;
        el.scrollTo({ left: targetScroll, behavior: "smooth" });
      }
      checkScroll();
    }, 60);

    return () => clearTimeout(timer);
  }, [isOpen, selectedCode, checkScroll]);

  // Drag-to-scroll com o cursor do rato
  const handleMouseDown = (e: React.MouseEvent<HTMLDivElement>) => {
    const el = tabsContainerRef.current;
    if (!el) return;
    isMouseDownRef.current = true;
    hasDraggedRef.current = false;
    startXRef.current = e.pageX - el.offsetLeft;
    scrollLeftRef.current = el.scrollLeft;
  };

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!isMouseDownRef.current) return;
    const el = tabsContainerRef.current;
    if (!el) return;
    const x = e.pageX - el.offsetLeft;
    const walk = x - startXRef.current;
    if (Math.abs(walk) > 4) {
      hasDraggedRef.current = true;
      setIsDragging(true);
      el.scrollLeft = scrollLeftRef.current - walk;
      checkScroll();
    }
  };

  const handleMouseUp = () => {
    isMouseDownRef.current = false;
    setIsDragging(false);
  };

  const handleScrollTabs = (direction: "left" | "right") => {
    const el = tabsContainerRef.current;
    if (!el) return;
    const scrollAmount = 140;
    el.scrollBy({
      left: direction === "left" ? -scrollAmount : scrollAmount,
      behavior: "smooth",
    });
    setTimeout(checkScroll, 200);
  };

  // Função para carregar a explicação da pergunta selecionada
  const fetchExplanation = useCallback(
    async (codeToFetch: string, force = false) => {
      if (!codeToFetch) return;

      const cacheKey = `${engine}:${codeToFetch}`;
      if (!force && cacheRef.current[cacheKey]) {
        setData(cacheRef.current[cacheKey]);
        setError(null);
        return;
      }

      setIsLoading(true);
      setError(null);

      const endpoint =
        engine === "prolog"
          ? `/api/prolog/porque?dado=${encodeURIComponent(codeToFetch)}`
          : `/api/returns/porque?dado=${encodeURIComponent(codeToFetch)}`;

      try {
        const response = await api<ExplicacaoPorqueResponse>(endpoint, {
          method: "POST",
          body: returnRequest || {},
        });
        cacheRef.current[cacheKey] = response;
        setData(response);
      } catch (err: unknown) {
        let msg = "Não foi possível carregar a justificação da pergunta.";
        if (err instanceof ApiClientError) {
          msg = err.message;
        } else if (err instanceof Error) {
          msg = err.message;
        }
        setError(msg);
      } finally {
        setIsLoading(false);
      }
    },
    [engine, returnRequest]
  );

  // Disparar busca ao abrir ou alternar código selecionado
  useEffect(() => {
    if (isOpen && selectedCode) {
      fetchExplanation(selectedCode);
    }
  }, [isOpen, selectedCode, fetchExplanation]);

  // Limpar cache e revalidar se o payload da transação for alterado
  const prevPayloadRef = useRef<string>("");
  useEffect(() => {
    const serialized = JSON.stringify(returnRequest || {});
    if (prevPayloadRef.current && prevPayloadRef.current !== serialized) {
      cacheRef.current = {};
      if (isOpen && selectedCode) {
        fetchExplanation(selectedCode, true);
      }
    }
    prevPayloadRef.current = serialized;
  }, [returnRequest, isOpen, selectedCode, fetchExplanation]);

  // Fecho por clique exterior
  useEffect(() => {
    if (!isOpen) return;

    const handleClickOutside = (e: MouseEvent) => {
      const target = e.target as Node;
      if (
        popoverRef.current &&
        !popoverRef.current.contains(target) &&
        triggerButtonRef.current &&
        !triggerButtonRef.current.contains(target)
      ) {
        setIsOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [isOpen]);

  // Fecho por tecla Escape
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setIsOpen(false);
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isOpen]);

  // Se o passo não tem perguntas mapeadas (ex: Passo 1), não renderiza o widget
  if (inputs.length === 0) {
    return null;
  }

  const activeItem = inputs.find((item) => item.code === selectedCode) || inputs[0];
  const policies = getPolicyCategories(data?.regrasQueDependem);

  return (
    <aside
      aria-label="Explicabilidade da Pergunta"
      className="fixed bottom-6 right-6 z-40"
    >
      {/* 1. Popover Flutuante Minimalista */}
      {isRendered && (
        <div
          ref={popoverRef}
          role="dialog"
          aria-labelledby="why-ask-title"
          aria-modal="false"
          onAnimationEnd={handleAnimationEnd}
          className={`fixed bottom-18 right-4 sm:bottom-20 sm:right-6 z-50 w-[420px] max-w-[calc(100vw-2rem)] max-h-[75vh] flex flex-col rounded-xl bg-white border border-slate-200 shadow-lg overflow-hidden ${
            isOpen ? "animate-why-ask-in" : "animate-why-ask-out"
          }`}
        >
          {/* Header Minimalista e Profissional */}
          <header className="px-4 py-3.5 border-b border-slate-100 flex items-center justify-between gap-3 bg-white shrink-0">
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="w-8 h-8 rounded-lg bg-slate-100 text-slate-600 flex items-center justify-center shrink-0">
                <span className="material-symbols-outlined text-[18px]">
                  help_outline
                </span>
              </div>
              <div className="flex flex-col min-w-0">
                <h3
                  id="why-ask-title"
                  className="font-sans font-bold text-sm text-slate-900 tracking-tight"
                >
                  Porquê esta pergunta?
                </h3>
                <p className="font-sans text-[11px] text-slate-400 truncate">
                  Racional de negócio &middot; {engine === "prolog" ? "Prolog" : "Drools"}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-1 shrink-0">
              <button
                type="button"
                onClick={() => fetchExplanation(selectedCode, true)}
                title="Atualizar racional"
                aria-label="Atualizar racional"
                className="w-7 h-7 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 flex items-center justify-center transition-colors cursor-pointer"
              >
                <span
                  className={`material-symbols-outlined text-[16px] ${
                    isLoading ? "animate-spin text-slate-900" : ""
                  }`}
                >
                  refresh
                </span>
              </button>
              <button
                type="button"
                onClick={() => setIsOpen(false)}
                aria-label="Fechar"
                className="w-7 h-7 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 flex items-center justify-center transition-colors cursor-pointer"
              >
                <span className="material-symbols-outlined text-[16px]">close</span>
              </button>
            </div>
          </header>

          {/* Seletor de Perguntas do Passo Ativo com Scroll Horizontal Completo e Setas */}
          <div className="relative bg-slate-50/80 border-b border-slate-100 flex items-center shrink-0">
            {/* Seta Esquerda (surge quando há scroll à esquerda) */}
            {canScrollLeft && (
              <div className="absolute left-0 top-0 bottom-0 z-10 flex items-center pl-1.5 bg-gradient-to-r from-slate-50 via-slate-50/90 to-transparent pr-4 pointer-events-none">
                <button
                  type="button"
                  onClick={() => handleScrollTabs("left")}
                  aria-label="Rolar perguntas para a esquerda"
                  className="w-6 h-6 rounded-md bg-white border border-slate-200 shadow-2xs hover:bg-slate-100 flex items-center justify-center text-slate-600 transition-colors pointer-events-auto cursor-pointer"
                >
                  <span className="material-symbols-outlined text-[16px]">chevron_left</span>
                </button>
              </div>
            )}

            {/* Pista de Perguntas com Suporte a Roda do Rato, Arrastar e Toque */}
            <div
              ref={tabsContainerRef}
              onMouseDown={handleMouseDown}
              onMouseMove={handleMouseMove}
              onMouseUp={handleMouseUp}
              onMouseLeave={handleMouseUp}
              className={`px-4 py-2 flex items-center gap-1.5 overflow-x-auto no-scrollbar select-none w-full ${
                isDragging ? "cursor-grabbing" : "cursor-grab"
              }`}
            >
              {inputs.map((item) => {
                const isSelected = item.code === selectedCode;
                const cleanLabel = item.label.replace(/^\d+\s*\/\s*/, "");
                return (
                  <button
                    key={item.code}
                    data-code={item.code}
                    type="button"
                    onClick={() => {
                      if (!hasDraggedRef.current) {
                        setSelectedCodeOverride(item.code);
                      }
                    }}
                    className={`px-3 py-1.5 rounded-lg text-xs font-medium whitespace-nowrap transition-all duration-150 cursor-pointer shrink-0 ${
                      isSelected
                        ? "bg-white text-slate-900 font-semibold border border-slate-200 shadow-2xs"
                        : "text-slate-500 hover:text-slate-800 hover:bg-white/60"
                    }`}
                  >
                    <span>{cleanLabel}</span>
                  </button>
                );
              })}
            </div>

            {/* Seta Direita (surge quando há mais perguntas à direita) */}
            {canScrollRight && (
              <div className="absolute right-0 top-0 bottom-0 z-10 flex items-center pr-1.5 bg-gradient-to-l from-slate-50 via-slate-50/90 to-transparent pl-4 pointer-events-none">
                <button
                  type="button"
                  onClick={() => handleScrollTabs("right")}
                  aria-label="Rolar perguntas para a direita"
                  className="w-6 h-6 rounded-md bg-white border border-slate-200 shadow-2xs hover:bg-slate-100 flex items-center justify-center text-slate-600 transition-colors pointer-events-auto cursor-pointer"
                >
                  <span className="material-symbols-outlined text-[16px]">chevron_right</span>
                </button>
              </div>
            )}
          </div>

          {/* Conteúdo com Scroll */}
          <div className="p-4 overflow-y-auto flex-1 flex flex-col gap-4 text-left">
            {isLoading && (
              <div
                role="status"
                aria-live="polite"
                className="py-12 flex flex-col items-center justify-center gap-2.5 text-center"
              >
                <div className="w-6 h-6 border-2 border-slate-200 border-t-slate-800 rounded-full animate-spin" />
                <span className="text-xs text-slate-500 font-medium">
                  A consultar racional pericial...
                </span>
              </div>
            )}

            {error && !isLoading && (
              <div
                role="alert"
                className="p-3.5 rounded-xl bg-red-50/60 border border-red-200/80 text-red-950 flex flex-col gap-2"
              >
                <div className="flex items-center gap-1.5 text-red-800 font-semibold text-xs">
                  <span className="material-symbols-outlined text-[16px]">error</span>
                  <span>Erro ao carregar justificação</span>
                </div>
                <p className="text-xs text-red-800 leading-relaxed">{error}</p>
                <button
                  type="button"
                  onClick={() => fetchExplanation(selectedCode, true)}
                  className="self-start text-xs font-semibold text-red-700 hover:text-red-900 underline cursor-pointer"
                >
                  Tentar novamente
                </button>
              </div>
            )}

            {!isLoading && !error && data && (
              <>
                {/* 1. Pergunta Formulada e Racional de Negócio (100% Livre de Códigos) */}
                <div className="p-3.5 rounded-xl bg-slate-50/70 border border-slate-200/80 flex flex-col gap-2.5">
                  <div className="flex flex-col gap-0.5">
                    <span className="font-sans text-[10px] font-bold uppercase tracking-wider text-slate-400">
                      Pergunta ao Operador
                    </span>
                    <p className="font-sans text-xs sm:text-sm font-bold text-slate-900 leading-snug">
                      {cleanCounterText(data.pergunta) || "Qual é a informação solicitada neste campo?"}
                    </p>
                  </div>

                  <div className="pt-2 border-t border-slate-200/60 flex flex-col gap-0.5">
                    <span className="font-sans text-[10px] font-bold uppercase tracking-wider text-slate-400">
                      Racional de Negócio
                    </span>
                    <p className="font-sans text-xs text-slate-600 leading-relaxed">
                      {cleanCounterText(data.resumo) ||
                        "Esta premissa é necessária para determinar as normas e políticas comerciais aplicáveis ao caso."}
                    </p>
                  </div>
                </div>

                {/* 2. Políticas de Loja Abrangidas (Substitui os códigos XX-YYY por Categorias Legíveis) */}
                <div className="flex flex-col gap-2">
                  <div className="flex items-center justify-between">
                    <span className="font-sans text-[11px] font-bold uppercase tracking-wider text-slate-400">
                      Políticas de Loja Envolvidas
                    </span>
                    <span className="font-sans text-[11px] text-slate-400">
                      {data.regrasQueDependem?.length || 0} {data.regrasQueDependem?.length === 1 ? "norma" : "normas"}
                    </span>
                  </div>

                  {policies.length > 0 ? (
                    <div className="flex flex-wrap gap-1.5">
                      {policies.map((policy) => (
                        <span
                          key={policy}
                          className="font-sans px-2.5 py-1 rounded-md bg-white border border-slate-200 text-slate-700 text-xs font-medium shadow-2xs"
                        >
                          {policy}
                        </span>
                      ))}
                    </div>
                  ) : (
                    <p className="font-sans text-xs text-slate-400 italic">
                      Conformidade geral de atendimento.
                    </p>
                  )}
                </div>

                {/* 3. Regras em Decisão Imediata no Pedido Atual */}
                {data.regrasEmEspera && data.regrasEmEspera.length > 0 && (
                  <div className="flex flex-col gap-2.5 pt-3 border-t border-slate-100">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <span className="font-sans text-[11px] font-bold uppercase tracking-wider text-slate-400">
                          Regras em decisão no pedido atual
                        </span>
                        <span className="font-sans inline-flex items-center justify-center px-1.5 py-0.5 rounded-md text-[10px] font-bold bg-slate-100 text-slate-600">
                          {data.regrasEmEspera.length}
                        </span>
                      </div>
                      <span className="font-sans text-[11px] text-slate-400">
                        {data.regrasEmEspera.length === 1 ? "norma pendente" : "normas pendentes"}
                      </span>
                    </div>

                    <div className="flex flex-col gap-2">
                      {data.regrasEmEspera.map((regra: RegraEmEsperaDto, idx: number) => {
                        const ruleTitle = humanizeRuleName(regra.nomeRegra);
                        const category = moduleLabel(regra.modulo);
                        const outcomes = (regra.conclusoes || [])
                          .map(parseOutcome)
                          .filter((o): o is OutcomeInfo => o !== null);
                        const validConditions = (regra.condicoesDoDado || [])
                          .map(parseCondition)
                          .filter((cond): cond is string => Boolean(cond));

                        const primaryOutcome = outcomes[0];
                        const additionalOutcomes = outcomes.slice(1);

                        return (
                          <div
                            key={regra.codigoRegra || idx}
                            className="p-3.5 rounded-xl bg-white border border-slate-200/90 hover:border-slate-300 transition-all flex flex-col gap-2 shadow-2xs group"
                          >
                            {/* Linha de Topo: Categoria de Loja (Eyebrow) e Badge de Desfecho Principal */}
                            <div className="flex items-center justify-between gap-2">
                              <span className="font-sans text-[10px] font-bold uppercase tracking-wider text-slate-400">
                                {category || "Norma Comercial"}
                              </span>

                              {primaryOutcome && (
                                <span
                                  className={`font-sans inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-semibold shrink-0 ${primaryOutcome.badgeClass}`}
                                >
                                  <span className="material-symbols-outlined text-[13px]">
                                    {primaryOutcome.icon}
                                  </span>
                                  <span>{primaryOutcome.label}</span>
                                </span>
                              )}
                            </div>

                            {/* Título da Regra: Sem truncagem, tipografia nítida e profissional */}
                            <h4 className="font-sans font-bold text-xs sm:text-sm text-slate-900 leading-snug">
                              {ruleTitle}
                            </h4>

                            {/* Desfechos Secundários / Conclusões Adicionais (se existirem) */}
                            {additionalOutcomes.length > 0 && (
                              <div className="flex flex-wrap items-center gap-1.5 pt-0.5">
                                <span className="text-[10px] font-medium text-slate-400">
                                  Condições adicionais:
                                </span>
                                {additionalOutcomes.map((sec, sIdx) => (
                                  <span
                                    key={sIdx}
                                    className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold ${sec.badgeClass}`}
                                  >
                                    <span className="material-symbols-outlined text-[12px]">
                                      {sec.icon}
                                    </span>
                                    <span>{sec.label}</span>
                                  </span>
                                ))}
                              </div>
                            )}

                            {/* Requisitos / Condições de Negócio Verificadas (Apenas se reais e legíveis) */}
                            {validConditions.length > 0 && (
                              <div className="pt-2 border-t border-slate-100 flex flex-col gap-1">
                                {validConditions.map((cond, condIdx) => (
                                  <div
                                    key={condIdx}
                                    className="flex items-center gap-1.5 text-[11px] text-slate-500"
                                  >
                                    <span className="material-symbols-outlined text-[13px] text-emerald-600 shrink-0">
                                      check
                                    </span>
                                    <span className="leading-tight">{cond}</span>
                                  </div>
                                ))}
                              </div>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  </div>
                )}
              </>
            )}
          </div>

          {/* Rodapé Minimalista (Sem Código IN-xxx) */}
          <footer className="px-4 py-2.5 bg-slate-50 border-t border-slate-100 flex items-center justify-between text-[11px] text-slate-400 shrink-0 select-none">
            <span className="font-medium">Explicabilidade de balcão</span>
            <span className="text-slate-500 font-medium truncate max-w-[200px]">
              {activeItem.label.replace(/^\d+\s*\/\s*/, "")}
            </span>
          </footer>
        </div>
      )}

      {/* 2. Botão Flutuante Minimalista (Sem Glow, Sem Sombra Colorida) */}
      <button
        ref={triggerButtonRef}
        type="button"
        onClick={() => setIsOpen((prev) => !prev)}
        aria-expanded={isOpen}
        aria-haspopup="dialog"
        aria-label={
          isOpen
            ? "Fechar justificação pericial da pergunta"
            : "Porquê esta pergunta? (Racional de negócio)"
        }
        title="Porquê esta pergunta? (Racional de negócio)"
        className={`w-10 h-10 rounded-full flex items-center justify-center transition-all duration-150 cursor-pointer select-none border focus-visible:outline-2 focus-visible:outline-emerald-600 ${
          isOpen
            ? "bg-slate-900 text-white border-slate-900 shadow-sm"
            : "bg-white text-slate-600 hover:text-slate-900 border-slate-200 hover:border-slate-300 hover:bg-slate-50 shadow-xs"
        }`}
      >
        <span className="material-symbols-outlined text-[20px]">
          {isOpen ? "close" : "help_outline"}
        </span>
      </button>
    </aside>
  );
}
