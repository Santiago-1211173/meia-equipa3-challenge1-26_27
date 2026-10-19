export interface StepInputItem {
  code: string; // ex: 'IN-001'
  label: string; // ex: '01 / Jurisdição Territorial'
}

export const STEP_INPUT_MAPPING: Record<number, StepInputItem[]> = {
  2: [
    { code: "IN-001", label: "01 / Jurisdição Territorial" },
    { code: "IN-002", label: "02 / Formato Comercial da Loja" },
    { code: "IN-003", label: "03 / Canal de Compra Original" },
  ],
  3: [
    { code: "IN-007", label: "01 / Identificação & Marca" },
    { code: "IN-008", label: "02 / Estado Físico do Artigo" },
    { code: "IN-010", label: "03 / Possibilidade de Revenda" },
  ],
  4: [
    { code: "IN-005", label: "01 / Tipo de Pedido Formulado" },
    { code: "IN-004", label: "02 / Comprovativo Apresentado" },
    { code: "IN-006", label: "03 / Prazo Decorrido da Compra" },
  ],
  5: [
    { code: "EP-001", label: "01 / Modalidade de Troca" },
    { code: "EX-002", label: "02 / Situação do Cliente no Balcão" },
    { code: "EX-001", label: "03 / Exceção da Gerência" },
  ],
  6: [
    { code: "IN-009", label: "02 / Meio de Pagamento Original" },
  ],
};

export function getInputsForStep(
  stepNumber: number,
  requestType?: string,
  physicalCondition?: string | null
): StepInputItem[] {
  if (stepNumber === 3) {
    const isResellApplicable =
      !physicalCondition ||
      physicalCondition === "NOVO_ETIQUETAS_SOLTAS" ||
      physicalCondition === "NOVO_SEM_ETIQUETAS";
    if (isResellApplicable) {
      return [
        { code: "IN-007", label: "01 / Identificação & Marca" },
        { code: "IN-008", label: "02 / Estado Físico do Artigo" },
        { code: "IN-010", label: "03 / Possibilidade de Revenda" },
      ];
    }
    return [
      { code: "IN-007", label: "01 / Identificação & Marca" },
      { code: "IN-008", label: "02 / Estado Físico do Artigo" },
    ];
  }
  if (stepNumber === 5) {
    if (requestType === "TROCA") {
      return [
        { code: "EP-001", label: "01 / Modalidade de Troca" },
        { code: "EX-002", label: "02 / Situação do Cliente no Balcão" },
        { code: "EX-001", label: "03 / Exceção da Gerência" },
      ];
    }
    return [
      { code: "EX-002", label: "01 / Situação do Cliente no Balcão" },
      { code: "EX-001", label: "02 / Exceção da Gerência" },
    ];
  }
  return STEP_INPUT_MAPPING[stepNumber] || [];
}
