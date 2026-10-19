import type { EngineStep } from "@/config/engines";

export default function StepIndicator({
  steps,
  current,
}: {
  steps: EngineStep[];
  /** Índice (a partir de 0) do passo em curso. */
  current: number;
}) {
  return (
    <ol className="step-indicator" aria-label="Passos do fluxo">
      {steps.map((step, index) => {
        const state = index < current ? "done" : index === current ? "current" : "todo";
        return (
          <li
            key={step.title}
            className={`step ${state}`}
            aria-current={state === "current" ? "step" : undefined}
          >
            <span className="step-number font-mono tabular-nums" aria-hidden="true">
              {state === "done" ? "✓" : index + 1}
            </span>
            <span className="step-text">
              <strong className="font-sans">{step.title}</strong>
              <small className="font-sans">{step.hint}</small>
            </span>
          </li>
        );
      })}
    </ol>
  );
}
