import type { ReactNode } from "react";
import type { EngineMeta, EngineStep } from "@/config/engines";
import StepIndicator from "./StepIndicator";

/** Esqueleto comum às três abas: cabeçalho, passos e duas colunas (entrada / resultado). */
export default function EngineWorkspace({
  engine,
  currentStep,
  input,
  result,
  steps,
  toolbar,
}: {
  engine: EngineMeta;
  currentStep: number;
  input: ReactNode;
  result: ReactNode;
  /** Passos específicos do modo ativo; por omissão usa os do motor. */
  steps?: EngineStep[];
  /** Controlo opcional acima dos passos (ex.: escolha de modo). */
  toolbar?: ReactNode;
}) {
  return (
    <section aria-labelledby="engine-title" className="workspace">
      <div className="workspace-head">
        <h2 id="engine-title" className="font-sans">{engine.label}</h2>
        <p className="font-sans">{engine.tagline}</p>
      </div>
      {toolbar}
      <StepIndicator steps={steps ?? engine.steps} current={currentStep} />
      <div className="grid-2">
        <div className="card">{input}</div>
        <div className="card" aria-live="polite">
          {result}
        </div>
      </div>
    </section>
  );
}
