"use client";

import { useCallback, useEffect, useState } from "react";
import { ENGINES } from "@/config/engines";
import type { EngineId } from "@/config/gateway";
import { api } from "./api";

export type HealthState = "checking" | "online" | "offline";

interface HealthPayload {
  status?: string;
  prolog_engine?: string;
}

function isOnline(engine: EngineId, data: HealthPayload): boolean {
  if (data.status === "UP" || data.status === "healthy") {
    return true;
  }
  if (engine === "prolog") {
    return data.prolog_engine === "connected";
  }
  return false;
}

const INITIAL: Record<EngineId, HealthState> = {
  returns: "checking",
  prolog: "checking",
};

export function useEnginesHealth() {
  const [health, setHealth] = useState<Record<EngineId, HealthState>>(INITIAL);
  const [refreshing, setRefreshing] = useState(false);

  const refresh = useCallback(async () => {
    setRefreshing(true);
    const entries = await Promise.all(
      ENGINES.map(async (engine) => {
        try {
          const data = await api<HealthPayload>(engine.healthPath);
          return [engine.id, isOnline(engine.id, data) ? "online" : "offline"] as const;
        } catch {
          return [engine.id, "offline"] as const;
        }
      })
    );
    setHealth(Object.fromEntries(entries) as Record<EngineId, HealthState>);
    setRefreshing(false);
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- carga inicial do estado dos motores
    void refresh();
  }, [refresh]);

  return { health, refreshing, refresh };
}
