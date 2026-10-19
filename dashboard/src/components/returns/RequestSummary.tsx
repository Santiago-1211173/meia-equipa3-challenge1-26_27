import { label, money } from "@/config/returnsLabels";
import type { CenarioExemploResponse, ReturnRequest } from "@/types/returns";

function pick(source: unknown, path: string): unknown {
  return path.split(".").reduce<unknown>((current, key) => {
    return current && typeof current === "object" ? (current as Record<string, unknown>)[key] : undefined;
  }, source);
}

const text = (value: unknown) => (value === null || value === undefined || value === "" ? "—" : String(value));

export default function RequestSummary({
  request,
  scenario,
}: {
  request: ReturnRequest;
  scenario: CenarioExemploResponse | null;
}) {
  const items = Array.isArray(request.artigos) ? (request.artigos as unknown[]) : [];
  const rows: [string, string][] = [
    ["Tipo de pedido", label(request.tipoPedido)],
    ["Data do pedido", text(request.dataPedido)],
    ["Loja", `${text(pick(request, "loja.nome"))} · ${label(pick(request, "loja.tipoLoja"))}`],
    ["Colaborador", label(pick(request, "colaborador.funcao"))],
    ["Canal da compra", label(pick(request, "compraOriginal.canal"))],
    ["Data da compra", text(pick(request, "compraOriginal.dataCompra"))],
    ["Pagamento", label(pick(request, "compraOriginal.pagamento.meio"))],
    ["Comprovativo", label(pick(request, "comprovativo.tipo"))],
  ];

  return (
    <div className="request-summary font-sans">
      <dl className="facts-grid">
        {rows.map(([name, value]) => (
          <div key={name}>
            <dt>{name}</dt>
            <dd className="font-sans font-bold tabular-nums">{value}</dd>
          </div>
        ))}
      </dl>

      {items.length > 0 && (
        <div className="table-container">
          <table className="plain-table font-sans tabular-nums">
            <caption className="sr-only">Artigos do pedido</caption>
            <thead>
              <tr>
                <th scope="col">Artigo</th>
                <th scope="col">Estado de uso</th>
                <th scope="col">Etiquetas</th>
                <th scope="col">Preço pago</th>
              </tr>
            </thead>
            <tbody>
              {items.map((item, index) => (
                <tr key={text(pick(item, "id")) + index}>
                  <td className="font-mono font-bold tabular-nums">{text(pick(item, "id"))}</td>
                  <td>{label(pick(item, "estado.condicaoUso"))}</td>
                  <td>{label(pick(item, "estado.etiquetas"))}</td>
                  <td className="font-sans font-bold tabular-nums">{money(pick(item, "precoPago"))}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {scenario && (
        <details className="scenario-notes">
          <summary>Pressupostos e raciocínio esperado do cenário</summary>
          {scenario.pressupostos.length > 0 && (
            <>
              <div className="presets-label">Pressupostos</div>
              <ul>
                {scenario.pressupostos.map((line) => (
                  <li key={line}>{line}</li>
                ))}
              </ul>
            </>
          )}
          {scenario.justificacao.length > 0 && (
            <>
              <div className="presets-label">Raciocínio esperado</div>
              <ol>
                {scenario.justificacao.map((line) => (
                  <li key={line}>{line}</li>
                ))}
              </ol>
            </>
          )}
        </details>
      )}
    </div>
  );
}
