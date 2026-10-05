export interface OrchestratorHealthResponse {
  status: string;
  prolog_engine: string;
  drools_engine: string;
  timestamp: string;
}

export interface DroolsHealthResponse {
  status: string;
  service: string;
  version: string;
  activeKieBase: string;
  totalRules: number;
  timestamp?: string;
}

export type DecisionType = "approved" | "rejected" | "store_credit_only" | "manager_override" | "error";

export interface EvaluationResponse {
  status: string;
  decision: DecisionType;
  justification: string[];
  engine: string;
  timestamp: string;
  message?: string | null;
}

export interface ScenarioInput {
  scenario: string;
  value: number;
}

export interface DerivedFact {
  id: number;
  fact: string;
  rule_id: number;
  justified_by: number[];
}

export interface RunEngineResponse {
  status: string;
  initial_facts_count: number;
  derived_facts_count: number;
  total_facts: number;
  derived_facts: DerivedFact[];
}

export interface FactItem {
  id: number;
  fact: string;
}

export interface GetFactsResponse {
  status: string;
  facts_count: number;
  facts: FactItem[];
}

export interface DroolsEvaluationResponse {
  status: string;
  primaryDiagnosis: string;
  conclusions: string[];
  hypothesis?: string | null;
  firedRules: string[];
  timestamp?: string;
  evidencesEvaluated?: Record<string, string>;
}
