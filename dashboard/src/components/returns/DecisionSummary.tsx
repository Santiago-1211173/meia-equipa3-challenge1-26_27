import ResultSummary from "@/components/shared/ResultSummary";
import { ELIGIBILITY, label, money } from "@/config/returnsLabels";
import type { DecisaoResponse } from "@/types/returns";

export default function DecisionSummary({
  decision,
  durationMs,
}: {
  decision: DecisaoResponse;
  durationMs: number;
}) {
  const eligibility = decision.elegibilidade ? ELIGIBILITY[decision.elegibilidade] : undefined;
  const details: [string, string][] = [
    ["Transação autorizada", label(decision.tipoTransacao)],
    ["Valor a devolver", decision.valorDevolucao != null ? money(decision.valorDevolucao) : "—"],
    ["Base do valor", label(decision.baseValor)],
    ["Meio de reembolso", label(decision.meioReembolso)],
    ["Aprovação necessária", label(decision.aprovacao)],
    ["Processo a seguir", label(decision.processo)],
    ["Comprovativo", label(decision.tipoVerificacao)],
  ];
  const docs = decision.documentacao;
  const docNotes = [
    docs?.assinaturaCliente && `Assinatura do cliente: ${docs.assinaturaCliente}`,
    docs?.assinaturaProcessador && `Assinatura do colaborador: ${docs.assinaturaProcessador}`,
    docs?.assinaturaTestemunha && `Assinatura de testemunha: ${docs.assinaturaTestemunha}`,
    docs?.reciboAgrafado && "Agrafar o recibo ao registo de caixa",
    docs?.notaRecibo && `Nota no recibo: ${docs.notaRecibo}`,
    docs?.registoExcecao && `Registo de exceção: ${docs.registoExcecao}`,
  ].filter(Boolean) as string[];

  return (
    <ResultSummary
      eyebrow="Resumo da Decisão"
      tone={eligibility?.tone ?? "info"}
      headline={eligibility?.label ?? label(decision.elegibilidade)}
      meta={`${durationMs} ms`}
    >
      {eligibility && (
        <p className="font-sans font-body-md text-on-surface-variant text-sm">
          {eligibility.hint}
        </p>
      )}

      {/* Grid de Factos Principais */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3 pt-2">
        {details.map(([name, value]) => (
          <div
            key={name}
            className="p-3 rounded-xl bg-surface-container-low border border-border-card flex flex-col justify-between"
          >
            <span className="font-sans font-caption text-[11px] text-on-surface-variant font-bold uppercase tracking-wider">
              {name}
            </span>
            <span className="font-sans font-headline-sm text-sm font-extrabold text-on-surface mt-1 truncate tabular-nums" title={value}>
              {value}
            </span>
          </div>
        ))}
      </div>

      {decision.excecaoRecusada && (
        <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-900 text-xs font-sans font-medium flex items-center gap-2">
          <span className="material-symbols-outlined text-rose-600 text-[18px]">gpp_bad</span>
          <span>O pedido de exceção de balcão foi analisado e recusado pela política comercial.</span>
        </div>
      )}

      {/* Tabela de Artigos */}
      {decision.artigos.length > 0 && (
        <div className="flex flex-col gap-2 mt-2">
          <span className="font-sans font-label-md text-xs font-bold uppercase tracking-wider text-on-surface-variant">
            Decisão por Artigo
          </span>
          <div className="w-full overflow-x-auto rounded-xl border border-border-card shadow-xs">
            <table className="w-full text-left border-collapse text-xs font-sans tabular-nums">
              <thead className="bg-surface-container-low text-on-surface-variant font-bold border-b border-border-card">
                <tr>
                  <th scope="col" className="p-3">Artigo</th>
                  <th scope="col" className="p-3">Resultado</th>
                  <th scope="col" className="p-3">Valor</th>
                  <th scope="col" className="p-3">Destino do Artigo</th>
                  <th scope="col" className="p-3">Aprovação</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-card/50 bg-white">
                {decision.artigos.map((item) => (
                  <tr key={item.artigoId} className="hover:bg-surface-container-lowest">
                    <td className="p-3 font-mono font-bold text-on-surface tabular-nums">{item.artigoId}</td>
                    <td className="p-3">
                      <span
                        className={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-extrabold ${
                          item.elegibilidade === "PERMITIR"
                            ? "bg-emerald-100 text-emerald-800"
                            : item.elegibilidade === "RECUSAR"
                            ? "bg-rose-100 text-rose-800"
                            : "bg-amber-100 text-amber-800"
                        }`}
                      >
                        {item.elegibilidade ? (ELIGIBILITY[item.elegibilidade]?.label ?? item.elegibilidade) : "—"}
                      </span>
                    </td>
                    <td className="p-3 font-sans font-bold text-on-surface tabular-nums">
                      {item.valorDevolucao != null ? money(item.valorDevolucao) : "—"}
                    </td>
                    <td className="p-3 text-on-surface-variant">
                      {label(item.destino)}
                      {item.descontoSaldo ? ` (−${item.descontoSaldo}%)` : ""}
                    </td>
                    <td className="p-3 text-on-surface-variant">{label(item.aprovacao)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Documentação */}
      {docNotes.length > 0 && (
        <div className="flex flex-col gap-2 mt-2">
          <span className="font-sans font-label-md text-xs font-bold uppercase tracking-wider text-on-surface-variant">
            Procedimentos e Documentação
          </span>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
            {docNotes.map((note, index) => (
              <div
                key={index}
                className="flex items-center gap-2 p-2.5 rounded-xl bg-surface-container-low border border-border-card text-xs text-on-surface font-sans"
              >
                <span className="material-symbols-outlined text-primary text-[18px]">task_alt</span>
                <span>{note}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {decision.regrasAValidar.length > 0 && (
        <div className="p-3 rounded-xl bg-amber-50 border border-amber-200 text-amber-900 text-xs font-sans flex items-center gap-2">
          <span className="material-symbols-outlined text-amber-600 text-[18px]">pending_actions</span>
          <span>Existem procedimentos pendentes de confirmação do fecho de turno no terminal POS.</span>
        </div>
      )}
    </ResultSummary>
  );
}

