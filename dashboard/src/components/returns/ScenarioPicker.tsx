import ErrorBanner from "@/components/shared/ErrorBanner";
import type { CenarioExemploResponse } from "@/types/returns";

export default function ScenarioPicker({
  scenarios,
  selectedId,
  error,
  onSelect,
  onRetry,
}: {
  scenarios: CenarioExemploResponse[] | null;
  selectedId: number | null;
  error: string | null;
  onSelect: (scenario: CenarioExemploResponse) => void;
  onRetry: () => void;
}) {
  if (error) return <ErrorBanner message={error} onRetry={onRetry} />;
  if (!scenarios) return <p className="field-hint">A carregar cenários...</p>;

  return (
    <ul className="scenario-list">
      {scenarios.map((scenario) => (
        <li key={scenario.id}>
          <button
            type="button"
            className={`scenario-card ${scenario.id === selectedId ? "active" : ""}`}
            aria-pressed={scenario.id === selectedId}
            onClick={() => onSelect(scenario)}
          >
            <span className="scenario-number font-mono font-bold tabular-nums">{scenario.id}</span>
            <span className="scenario-title font-sans font-bold">{scenario.titulo}</span>
            {scenario.aValidar.length > 0 && <span className="tag-pending font-sans">a validar</span>}
          </button>
        </li>
      ))}
    </ul>
  );
}
