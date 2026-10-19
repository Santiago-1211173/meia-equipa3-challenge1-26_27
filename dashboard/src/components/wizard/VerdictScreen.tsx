"use client";

import React, { useState } from "react";
import ResultCard from "@/components/ui/ResultCard";
import ExplainTabs from "@/components/returns/ExplainTabs";
import {
  ELIGIBILITY,
  cleanRuleCodes,
  formatDocumentationDetails,
  formatOperationalAction,
  formatResolutionSubtext,
  formatTenderSubtext,
  label,
} from "@/config/returnsLabels";
import type {
  DecisaoResponse,
  ReturnRequest,
} from "@/types/returns";
import type { EngineId } from "@/config/gateway";
import { useRouter } from "next/navigation";

export interface VerdictScreenProps {
  result: DecisaoResponse;
  request?: ReturnRequest;
  engine?: EngineId;
  durationMs?: number;
  currency?: string;
  onReset: () => void;
  onHome?: () => void;
}

export default function VerdictScreen({
  result,
  request = {},
  engine = "returns",
  durationMs = 0,
  currency = "USD",
  onReset,
  onHome,
}: VerdictScreenProps) {
  const router = useRouter();
  const [copied, setCopied] = useState<boolean>(false);

  const baseEndpoint = engine === "prolog" ? "/api/prolog" : "/api/returns";

  // Extrair valor numérico
  const refundVal =
    typeof result.valorDevolucao === "number"
      ? result.valorDevolucao
      : typeof result.valorDevolucao === "string"
      ? parseFloat(result.valorDevolucao)
      : undefined;

  // Encontrar a melhor explicação em linguagem natural, sem códigos técnicos
  const getHumanExplanation = (): string => {
    // 1. Priorizar regras substantivas de decisão (PT-, TN-, PC-, EX-, HS-) com resultado coincidente
    const substantiveRule = result.regras?.find(
      (r) =>
        r.resultado === result.elegibilidade &&
        r.mensagem &&
        (r.codigoRegra?.startsWith("PT-") ||
          r.codigoRegra?.startsWith("TN-") ||
          r.codigoRegra?.startsWith("PC-") ||
          r.codigoRegra?.startsWith("EX-") ||
          r.codigoRegra?.startsWith("HS-") ||
          r.nomeRegra?.startsWith("PT-") ||
          r.nomeRegra?.startsWith("TN-") ||
          r.nomeRegra?.startsWith("PC-") ||
          r.nomeRegra?.startsWith("EX-") ||
          r.nomeRegra?.startsWith("HS-"))
    );
    if (substantiveRule?.mensagem) {
      const cleaned = cleanRuleCodes(substantiveRule.mensagem);
      if (cleaned.length > 10) return cleaned;
    }

    // 2. Procurar regra com resultado coincidente
    const matchingRule = result.regras?.find(
      (r) => r.resultado === result.elegibilidade && r.mensagem
    );
    if (matchingRule?.mensagem) {
      const cleaned = cleanRuleCodes(matchingRule.mensagem);
      if (cleaned.length > 10) return cleaned;
    }

    // 2. Procurar qualquer regra com mensagem relevante
    const anyMessageRule = result.regras
      ?.slice()
      .reverse()
      .find((r) => r.mensagem && !r.mensagem.includes("conclui a transação"));
    if (anyMessageRule?.mensagem) {
      const cleaned = cleanRuleCodes(anyMessageRule.mensagem);
      if (cleaned.length > 10) return cleaned;
    }

    // 3. Fallbacks padronizados por elegibilidade
    if (result.elegibilidade === "PERMITIR") {
      return "Devolução aprovada. O artigo cumpre todos os requisitos de condição física, comprovativo de compra e janela temporal permitida.";
    }
    if (result.elegibilidade === "RECUSAR") {
      return "Devolução não permitida. O pedido não cumpre os critérios da política comercial para o canal e condições apresentadas.";
    }
    if (result.elegibilidade === "REVER") {
      return "O atendimento requer aprovação ou confirmação presencial do responsável de loja antes da liquidação.";
    }
    if (result.elegibilidade === "ENCAMINHAR") {
      return "O pedido requer processamento através de canal ou aplicação específica dedicada.";
    }
    return "Avaliação concluída de acordo com as diretrizes de balcão.";
  };

  const explanation = getHumanExplanation();

  // 1. Destino do Artigo (OUT-007) sem fallback cego para Área de Vendas
  const firstArticle = result.artigos?.[0];
  const resolvedDestino = firstArticle?.destino
    ? label(firstArticle.destino)
    : result.elegibilidade === "RECUSAR"
    ? "Devolver ao cliente"
    : "Área de Vendas";

  const resolvedDestinoSubtext = firstArticle?.descontoSaldo
    ? `Desconto de ${firstArticle.descontoSaldo}% em saldos`
    : result.elegibilidade === "RECUSAR"
    ? "Sem reintegração em inventário"
    : "Reintegração em stock de loja";

  // 2. Ação Imediata Operacional (OUT-006 & OUT-005)
  const opAction = formatOperationalAction(
    result.processo,
    result.aprovacao,
    result.elegibilidade
  );

  // 3. Documentação & Controlo (OUT-008)
  const docDetails = formatDocumentationDetails(result.documentacao);

  // Meio de pagamento original para contextualização pericial
  const originalTender = (request as any)?.compraOriginal?.pagamento?.meio as string | undefined;

  // Copiar resumo para a área de transferência
  const handleCopySummary = async () => {
    const text = [
      `=== RESUMO DE ATENDIMENTO RETAILFLOW ===`,
      `Veredito: ${result.elegibilidade ?? "REVER"}`,
      `Transação: ${label(result.tipoTransacao)}`,
      `Valor: ${refundVal !== undefined ? refundVal.toFixed(2) : "0.00"} ${currency}`,
      `Meio de Reembolso: ${label(result.meioReembolso)}`,
      `Destino: ${resolvedDestino}`,
      `Aprovação: ${label(result.aprovacao)}`,
      `Processo: ${label(result.processo)}`,
      `Ação Imediata: ${opAction.action} (${opAction.hint})`,
      `Documentação: ${docDetails.label} - ${docDetails.subtext}`,
      `Justificação: ${explanation}`,
      `Motor: ${engine === "prolog" ? "SWI-Prolog" : "Drools (DRL)"} (${durationMs} ms)`,
      `Versão BC: ${result.versaoBaseConhecimento ?? "1.0.0"}`,
      `ID Avaliação: ${result.avaliacaoId ?? "N/A"}`,
    ].join("\n");

    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    } catch {
      // Ignorar caso clipboard não esteja disponível
    }
  };

  // Mapeamento dos 8 campos oficiais do sistema pericial (RPAC-Team3 OUT-001 a OUT-008)
  const outFields = [
    {
      code: "OUT-001",
      name: "Elegibilidade",
      icon: "verified",
      value: result.elegibilidade ? (ELIGIBILITY[result.elegibilidade]?.label ?? result.elegibilidade) : "—",
      subtext: "Decisão do núcleo pericial",
      highlight:
        result.elegibilidade === "PERMITIR"
          ? "text-emerald-700 bg-emerald-50 border-emerald-200"
          : result.elegibilidade === "RECUSAR"
          ? "text-rose-700 bg-rose-50 border-rose-200"
          : "text-amber-700 bg-amber-50 border-amber-200",
    },
    {
      code: "OUT-002",
      name: "Tipo de Transação",
      icon: "swap_horiz",
      value: label(result.tipoTransacao),
      subtext: formatResolutionSubtext(result.tipoTransacao, result.meioReembolso, result.elegibilidade, originalTender),
      highlight: "text-slate-800 bg-slate-50 border-slate-200",
    },
    {
      code: "OUT-003",
      name: "Valor da Devolução",
      icon: "payments",
      value: refundVal !== undefined ? `${refundVal.toFixed(2)} ${currency === "CAD" ? "CAD $" : currency === "EUR" ? "€" : "$"}` : "0.00",
      subtext: label(result.baseValor) || "Valor autorizado",
      highlight: "text-slate-900 bg-slate-50 border-slate-200 font-bold",
    },
    {
      code: "OUT-004",
      name: "Meio de Reembolso",
      icon: "credit_card",
      value: label(result.meioReembolso),
      subtext: formatTenderSubtext(result.meioReembolso, result.tipoTransacao, result.elegibilidade, originalTender),
      highlight: "text-slate-800 bg-slate-50 border-slate-200",
    },
    {
      code: "OUT-005",
      name: "Aprovação Necessária",
      icon: "shield",
      value: label(result.aprovacao),
      subtext: result.aprovacao && result.aprovacao !== "NENHUMA" ? "Autorização mandatória" : "Sem escalamento de chefia",
      highlight: result.aprovacao && result.aprovacao !== "NENHUMA" ? "text-amber-800 bg-amber-50 border-amber-200" : "text-slate-700 bg-slate-50 border-slate-200",
    },
    {
      code: "OUT-006",
      name: "Processo Obrigatório",
      icon: "point_of_sale",
      value: label(result.processo),
      subtext: opAction.hint || "Terminal de execução",
      highlight: "text-slate-800 bg-slate-50 border-slate-200",
    },
    {
      code: "OUT-007",
      name: "Destino do Artigo",
      icon: "inventory_2",
      value: resolvedDestino,
      subtext: resolvedDestinoSubtext,
      highlight: "text-slate-800 bg-slate-50 border-slate-200",
    },
    {
      code: "OUT-008",
      name: "Documentação & Controlo",
      icon: "assignment",
      value: docDetails.label,
      subtext: docDetails.subtext,
      highlight: "text-slate-800 bg-slate-50 border-slate-200",
    },
  ];

  return (
    <div className="w-full flex flex-col gap-8 animate-in fade-in duration-200 text-left">
      {/* 1. Header Alinhado com o Design Minimalista do Sistema */}
      <div className="w-full flex flex-col items-center text-center gap-2.5">
        {/* Pill de Telemetria e Identificação do Motor Pericial */}
        <div className="inline-flex items-center flex-wrap justify-center gap-2 px-3 py-1.5 rounded-full bg-slate-50 border border-slate-200 shadow-2xs">
          {engine === "prolog" ? (
            <span className="inline-flex items-center gap-1.5 text-xs font-bold text-indigo-700 bg-indigo-50 border border-indigo-200/80 px-2.5 py-0.5 rounded-full">
              <span className="material-symbols-outlined text-[15px] text-indigo-600">psychology</span>
              <span>Motor SWI-Prolog &bull; Regras Declarativas</span>
            </span>
          ) : (
            <span className="inline-flex items-center gap-1.5 text-xs font-bold text-emerald-800 bg-emerald-50 border border-emerald-200/80 px-2.5 py-0.5 rounded-full">
              <span className="material-symbols-outlined text-[15px] text-emerald-600">bolt</span>
              <span>Motor Drools (DRL) &bull; Regras M0-M9</span>
            </span>
          )}

        </div>

        <h1 className="font-display text-2xl sm:text-3xl font-bold text-slate-900 tracking-tight">
          Veredito e Resolução de Balcão
        </h1>

        <p className="font-sans text-xs sm:text-sm text-slate-500 max-w-2xl leading-relaxed">
          Decisão oficial calculada pelo motor de inferência em conformidade rigorosa com a política comercial Levi Strauss &amp; Co.
        </p>
      </div>

      {/* 2. Secção 01: Veredito e Resolução Imediata (ResultCard Minimalista) */}
      <div className="w-full flex flex-col gap-3">
        <div className="flex items-center gap-2 px-1">
          <span className="font-mono tabular-nums text-xs font-bold text-slate-400 select-none">01</span>
          <span className="text-slate-300">/</span>
          <h3 className="font-sans text-sm sm:text-base font-bold text-slate-900 tracking-tight">
            Resolução Imediata de Balcão
          </h3>
        </div>

        <ResultCard
          eligibility={result.elegibilidade ?? "REVER"}
          refundValue={refundVal}
          explanation={explanation}
          remedy={result.tipoTransacao ? label(result.tipoTransacao) : undefined}
          paymentMethod={label(result.meioReembolso)}
          storeCredit={result.meioReembolso === "CARTAO_OFERTA" || result.meioReembolso === "CREDITO_LOJA"}
          currency={currency}
          operationalAction={opAction.action}
          operationalHint={opAction.hint}
          rawTransactionType={result.tipoTransacao}
          rawRefundMethod={result.meioReembolso}
          rawOriginalPaymentMethod={originalTender}
          rawProcess={result.processo}
          rawApproval={result.aprovacao}
          actions={
            <div className="w-full flex flex-wrap items-center justify-between gap-3 pt-4 border-t border-slate-100">
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={handleCopySummary}
                  className="font-sans px-4 py-2 rounded-xl bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 text-xs sm:text-sm font-semibold flex items-center gap-2 shadow-2xs transition-colors cursor-pointer"
                >
                  <span className="material-symbols-outlined text-[16px] text-slate-500">
                    {copied ? "check" : "content_copy"}
                  </span>
                  <span>{copied ? "Copiado!" : "Copiar Resumo"}</span>
                </button>

                <button
                  type="button"
                  onClick={() => window.print()}
                  className="font-sans px-4 py-2 rounded-xl bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 text-xs sm:text-sm font-semibold flex items-center gap-2 shadow-2xs transition-colors cursor-pointer"
                >
                  <span className="material-symbols-outlined text-[16px] text-slate-500">print</span>
                  <span>Imprimir Recibo</span>
                </button>
              </div>

              <button
                type="button"
                onClick={onReset}
                className="font-sans px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs sm:text-sm font-semibold flex items-center gap-2 shadow-xs transition-colors cursor-pointer"
              >
                <span className="material-symbols-outlined text-[18px]">add</span>
                <span>Novo Atendimento</span>
              </button>
            </div>
          }
        />
      </div>

      {/* 3. Secção 02: Especificações Oficiais da Decisão (RPAC-Team3 OUT-001 a OUT-008) */}
      <div className="w-full flex flex-col gap-3">
        <div className="flex items-center justify-between px-1 flex-wrap gap-2">
          <div className="flex items-center gap-2">
            <span className="font-mono tabular-nums text-xs font-bold text-slate-400 select-none">02</span>
            <span className="text-slate-300">/</span>
            <h3 className="font-sans text-sm sm:text-base font-bold text-slate-900 tracking-tight">
              Especificações Oficiais da Decisão
            </h3>
          </div>

          <span className="font-sans text-xs text-slate-400">
            Saídas normalizadas do sistema pericial
          </span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
          {outFields.map((field) => (
            <div
              key={field.code}
              className="p-3.5 bg-white border border-slate-200 rounded-xl shadow-2xs hover:border-slate-300 transition-all flex flex-col justify-between"
            >
              <div className="flex items-center justify-between gap-2 mb-1.5">
                <span className="text-[10px] font-bold font-mono tabular-nums text-slate-400 uppercase tracking-wider">
                  {field.code}
                </span>
                <span className="material-symbols-outlined text-[16px] text-slate-400">
                  {field.icon}
                </span>
              </div>

              <span className="font-sans text-xs font-semibold text-slate-500">
                {field.name}
              </span>

              <div className="my-1.5">
                <span className={`font-sans tabular-nums inline-flex px-2 py-0.5 rounded-md text-xs font-bold border truncate max-w-full ${field.highlight}`} title={field.value}>
                  {field.value}
                </span>
              </div>

              <span className="font-sans text-[11px] text-slate-400 truncate">
                {field.subtext}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* 4. Secção 03: Módulo de Explicações do Motor (ACM) */}
      <div className="w-full flex flex-col gap-3">
        <div className="flex items-center justify-between px-1 flex-wrap gap-2">
          <div className="flex items-center gap-2">
            <span className="font-mono tabular-nums text-xs font-bold text-slate-400 select-none">03</span>
            <span className="text-slate-300">/</span>
            <h3 className="font-sans text-sm sm:text-base font-bold text-slate-900 tracking-tight">
              Explicações do Motor de Inferência (ACM)
            </h3>
          </div>

          <span className="font-sans text-xs text-slate-400">
            Como &middot; Porque Não &middot; E Se &middot; Factos e Validações
          </span>
        </div>

        <div className="p-5 sm:p-6 bg-white border border-slate-200 rounded-2xl shadow-xs">
          <ExplainTabs
            evaluationId={result.avaliacaoId || ""}
            request={request}
            obtained={result.elegibilidade ?? null}
            base={baseEndpoint}
          />
        </div>
      </div>

      {/* 5. Rodapé de Conclusão e Navegação Rápida */}
      <div className="w-full pt-4 pb-2 flex items-center justify-between gap-4 flex-wrap border-t border-slate-200">
        <button
          type="button"
          onClick={() => {
            if (onHome) {
              onHome();
            } else {
              router.push("/");
            }
          }}
          className="font-sans px-4 py-2.5 rounded-xl bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 text-xs sm:text-sm font-semibold flex items-center gap-2 shadow-2xs transition-colors cursor-pointer"
        >
          <span className="material-symbols-outlined text-[18px]">home</span>
          <span>Voltar ao Painel Principal</span>
        </button>

        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => window.print()}
            className="font-sans px-4 py-2.5 rounded-xl bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 text-xs sm:text-sm font-semibold flex items-center gap-2 shadow-2xs transition-colors cursor-pointer"
          >
            <span className="material-symbols-outlined text-[18px]">print</span>
            <span>Imprimir Recibo</span>
          </button>

          <button
            type="button"
            onClick={onReset}
            className="font-sans px-6 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs sm:text-sm font-semibold flex items-center gap-2 shadow-xs transition-colors cursor-pointer"
          >
            <span className="material-symbols-outlined text-[18px]">add</span>
            <span>Iniciar Novo Atendimento</span>
          </button>
        </div>
      </div>
    </div>
  );
}
