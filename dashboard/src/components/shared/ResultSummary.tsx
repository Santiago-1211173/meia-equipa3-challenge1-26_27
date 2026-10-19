import type { ReactNode } from "react";

type Tone = "approved" | "rejected" | "info";

/** Decisão em destaque, seguida do conteúdo de justificação passado como children. */
export default function ResultSummary({
  eyebrow,
  headline,
  tone = "approved",
  meta,
  children,
}: {
  eyebrow: string;
  headline: string;
  tone?: Tone;
  meta?: string;
  children?: ReactNode;
}) {
  const toneBg =
    tone === "approved"
      ? "bg-emerald-100 text-emerald-800 border-emerald-300"
      : tone === "rejected"
      ? "bg-rose-100 text-rose-800 border-rose-300"
      : "bg-amber-100 text-amber-800 border-amber-300";

  return (
    <div className="card-tactile p-6 bg-white border border-border-card rounded-2xl shadow-sm flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <span className="font-sans text-xs font-bold uppercase tracking-wider text-on-surface-variant">
          {eyebrow}
        </span>
        {meta && (
          <span className="font-sans font-caption text-xs text-on-surface-variant bg-surface-container px-2.5 py-1 rounded-full font-medium">
            {meta}
          </span>
        )}
      </div>
      <div className="flex items-center gap-3">
        <span className={`font-sans px-4 py-1.5 rounded-full text-sm font-extrabold border ${toneBg}`}>
          {headline}
        </span>
      </div>
      {children}
    </div>
  );
}

