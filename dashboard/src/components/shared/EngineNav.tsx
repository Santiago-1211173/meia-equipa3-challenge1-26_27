"use client";

import Link from "next/link";
import { ENGINES } from "@/config/engines";
import type { EngineId } from "@/config/gateway";
import { useEnginesHealth, type HealthState } from "@/client/useEnginesHealth";

const HEALTH_LABEL: Record<HealthState, string> = {
  checking: "a verificar",
  online: "online",
  offline: "offline",
};

export default function EngineNav({ active }: { active: EngineId }) {
  const { health, refreshing, refresh } = useEnginesHealth();

  return (
    <div className="engine-nav">
      <nav className="tabs-nav" aria-label="Motores de inferência">
        {ENGINES.map((engine) => (
          <Link
            key={engine.id}
            href={`/?motor=${engine.id}`}
            className={`tab-btn font-sans ${engine.id === active ? "active" : ""}`}
            aria-current={engine.id === active ? "page" : undefined}
            scroll={false}
          >
            <span className={`health-dot ${health[engine.id]}`} aria-hidden="true" />
            {engine.label}
            <span className="sr-only"> ({HEALTH_LABEL[health[engine.id]]})</span>
          </Link>
        ))}
      </nav>
      <button className="btn-refresh font-sans" onClick={refresh} disabled={refreshing}>
        {refreshing ? "A verificar..." : "↻ Atualizar estado"}
      </button>
    </div>
  );
}
