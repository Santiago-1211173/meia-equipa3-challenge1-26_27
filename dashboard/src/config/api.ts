export const DEFAULT_API_BASE_URL = "/api/backend";

export const ENDPOINTS = {
  HEALTH: "/health",
  API_V1_HEALTH: "/api/v1/health",
  EVALUATE: "/api/v1/evaluate",
  INFERENCE_LOAD: "/api/v1/inference/load",
  INFERENCE_RUN: "/api/v1/inference/run",
  INFERENCE_FACTS: "/api/v1/inference/facts",
  INFERENCE_RESET: "/api/v1/inference/reset",
  DROOLS_EVALUATE: "/api/v1/drools/evaluate",
  DROOLS_HEALTH: "/api/v1/drools/health",
};

export interface PocPreset {
  id: string;
  name: string;
  expected: "approved" | "rejected";
  payload: {
    scenario: string;
    value: number;
  };
}

export const POC_PRESETS: PocPreset[] = [
  {
    id: "approved-42",
    name: "🟢 POC Aprovado (Valor = 42)",
    expected: "approved",
    payload: {
      scenario: "test",
      value: 42,
    },
  },
  {
    id: "rejected-15",
    name: "🔴 POC Rejeitado (Valor = 15)",
    expected: "rejected",
    payload: {
      scenario: "test",
      value: 15,
    },
  },
];

export interface DroolsPreset {
  id: string;
  name: string;
  expectedDiagnosis: string;
  payload: Record<string, string>;
}

export const DROOLS_PRESETS: DroolsPreset[] = [
  {
    id: "otorrhagia",
    name: "👂 Otorragia (Sangue + Dor no Ouvido)",
    expectedDiagnosis: "Otorrhagia",
    payload: {
      bloodEar: "yes",
      earAche: "yes",
    },
  },
  {
    id: "skull-fracture",
    name: "💀 Fratura Craniana (Sangue + LCR)",
    expectedDiagnosis: "Skull fracture",
    payload: {
      bloodEar: "yes",
      cerebrospinal: "yes",
    },
  },
  {
    id: "epistaxe",
    name: "👃 Epistaxe (Hemorragia Nasal)",
    expectedDiagnosis: "Epistaxe",
    payload: {
      bloodNose: "yes",
    },
  },
  {
    id: "coffee-ground",
    name: "☕ Hematémese (Borra de Café)",
    expectedDiagnosis: "Coffee ground emesis",
    payload: {
      vomiting: "yes",
      bloodCoffee: "yes",
    },
  },
  {
    id: "anorectal",
    name: "🩸 Hemorragia Anorretal",
    expectedDiagnosis: "Anorectal hemorrhage",
    payload: {
      bloodAnus: "yes",
    },
  },
  {
    id: "hematuria",
    name: "🚻 Hematúria (Trato Urinário)",
    expectedDiagnosis: "Hematuria",
    payload: {
      bloodPenis: "yes",
    },
  },
];
