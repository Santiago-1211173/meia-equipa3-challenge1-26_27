"use client";

import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  ReactNode,
} from "react";
import { useRouter } from "next/navigation";
import type { EngineId } from "@/config/gateway";
import type { ReturnRequest, DecisaoResponse, Resposta } from "@/types/returns";

export interface WizardState {
  engine: EngineId | null;
  marketJurisdiction: "EUA" | "CA" | null;
  storeType: "MAINLINE" | "OUTLET" | null;
  purchaseChannel:
    | "FISICA"
    | "ONLINE_BACKPOCKET"
    | "FRANQUIA_CA"
    | "GROSSISTA"
    | "DESCONHECIDO"
    | null;
  barcodeRecognized: boolean | null;
  brandAllowed: boolean | null;
  alteredOrHemmed: boolean | null;
  intimateUnderwear: boolean | null;
  manufacturingDefect: boolean | null;
  physicalCondition:
    | "NOVO_ETIQUETAS"
    | "NOVO_ETIQUETAS_SOLTAS"
    | "NOVO_SEM_ETIQUETAS"
    | "USADO"
    | "LAVADO"
    | "MANCHADO"
    | null;
  readyToResell: boolean | null;
  // Camada de incerteza (só o motor Drools a calcula)
  /** O colaborador não consegue decidir a revenda: a revendibilidade é estimada pelo grau de uso. */
  resaleUndecided: boolean;
  /** Grau de uso observado, de 0 (nenhum) a 4 (intenso). */
  wearLevel: number | null;
  /** O cliente alega defeito de fabrico que o colaborador não confirmou. */
  defectClaimed: boolean | null;
  /** Respostas às perguntas da inspeção do defeito alegado (ED-01, ED-02, ED-05, ED-06, ED-07). */
  defectInspection: Partial<Record<string, Resposta>>;
  /** O cliente explica onde e quando comprou (EF-04). */
  purchaseOriginExplained: Resposta | null;
  /** O cliente pede o reembolso em numerário (EF-05). */
  asksForCash: boolean | null;
  requestType: "DEVOLUCAO" | "TROCA" | "GIFT" | "AJUSTE_PRECO" | null;
  proofOfPurchase:
    | "RECIBO_ORIGINAL"
    | "CONFIRMACAO_ONLINE"
    | "RECIBO_OFERTA"
    | "CONSULTA_POS"
    | "SEM_COMPROVATIVO"
    | null;
  daysSincePurchase: number | null;
  exchangeOption: "NENHUMA" | "MESMO_MODELO" | "OUTRO_ARTIGO" | null;
  customerSituation: "CONFORME" | "CONTESTA" | "CHAMAR_GERENCIA" | null;
  managerException: boolean | null;
  refundMethod: "CONTA_ORIGINAL" | "VALE_LOJA" | "CARTAO_ENCERRADO";
  // Campos de Pagamento Original IN-009 e Família TN
  originalPaymentMethod:
    | "CREDITO"
    | "DEBITO"
    | "NUMERARIO"
    | "CARTAO_OFERTA"
    | "APPLE_PAY"
    | "PAYPAL"
    | "AFTERPAY"
    | "INTERAC"
    | null;
  accountState: "ATIVA" | "ATIVA_CARTAO_PERDIDO" | "ENCERRADA" | null;
  originalRefundRefused: boolean | null;
  physicalCardPresent: boolean | null;
  paymentAppAccessible: boolean | null;
  totalPrice: number | null;
  precoAtualProduto?: number;
  currency: "USD" | "CAD";
  operatorName: string;
  storeName: string;
  // Campos específicos de compras online
  onlineOrderFound: boolean;
  onlinePaymentMethod: "CC" | "BNPL" | "PAYPAL" | "WALLETS";
  onlineDaysWindow: "UNDER_30" | "OVER_30";
  onlineInStoreExchange: boolean;
  onlineOrderNumber: string;
}

export const defaultWizardState: WizardState = {
  engine: null,
  marketJurisdiction: null,
  storeType: null,
  purchaseChannel: null,
  barcodeRecognized: null,
  brandAllowed: null,
  alteredOrHemmed: null,
  intimateUnderwear: null,
  manufacturingDefect: null,
  physicalCondition: null,
  readyToResell: null,
  resaleUndecided: false,
  wearLevel: null,
  defectClaimed: null,
  defectInspection: {},
  purchaseOriginExplained: null,
  asksForCash: null,
  requestType: null,
  proofOfPurchase: null,
  daysSincePurchase: null,
  exchangeOption: null,
  customerSituation: null,
  managerException: null,
  refundMethod: "CONTA_ORIGINAL",
  originalPaymentMethod: null,
  accountState: null,
  originalRefundRefused: null,
  physicalCardPresent: null,
  paymentAppAccessible: null,
  totalPrice: null,
  precoAtualProduto: undefined,
  currency: "USD",
  operatorName: "Tiago Silva",
  storeName: "Loja Central • Caixa Aberto",
  onlineOrderFound: true,
  onlinePaymentMethod: "CC",
  onlineDaysWindow: "UNDER_30",
  onlineInStoreExchange: false,
  onlineOrderNumber: "WEB-84920-PT",
};

/**
 * O estado da conta e do cartão só é relevante para pagamentos com cartão de crédito ou débito:
 * é o que as regras TN-002 e TN-003 avaliam nos dois motores. Nos outros meios não se pergunta.
 */
export function exigeEstadoDaConta(meio: WizardState["originalPaymentMethod"]): boolean {
  return meio === "CREDITO" || meio === "DEBITO";
}

/** A camada de incerteza só existe no motor Drools: só nele se fazem as perguntas que a alimentam. */
export function usaCamadaIncerteza(state: Pick<WizardState, "engine">): boolean {
  return state.engine === "returns";
}

/** A revenda (IN-010) só se pergunta para artigos não usados sem etiquetas colocadas. */
export function exigeDecisaoDeRevenda(state: Pick<WizardState, "physicalCondition">): boolean {
  return (
    state.physicalCondition === "NOVO_ETIQUETAS_SOLTAS" ||
    state.physicalCondition === "NOVO_SEM_ETIQUETAS"
  );
}

/**
 * A revenda fica respondida com Sim/Não ou, no Drools, com "ainda não sei" e o grau de uso,
 * a partir do qual a camada de incerteza estima a revendibilidade para a gestão.
 */
export function revendaRespondida(state: WizardState): boolean {
  if (!exigeDecisaoDeRevenda(state)) return true;
  if (state.readyToResell !== null) return true;
  return usaCamadaIncerteza(state) && state.resaleUndecided && state.wearLevel !== null;
}

/** O defeito alegado só se avalia quando não está confirmado e o artigo não é bodywear (IU-20). */
export function podeAlegarDefeito(state: WizardState): boolean {
  return (
    usaCamadaIncerteza(state) &&
    state.manufacturingDefect === false &&
    state.intimateUnderwear !== true
  );
}

export function getFirstIncompleteStep(state: WizardState): number {
  // Passo 1: Motor de inferência é obrigatório
  if (!state.engine) return 1;

  // Passo 2: Jurisdição, formato e canal são obrigatórios
  if (!state.marketJurisdiction || !state.storeType || !state.purchaseChannel) {
    return 2;
  }

  // Passo 3: Condição física e elegibilidade
  if (
    state.barcodeRecognized === null ||
    state.brandAllowed === null ||
    state.alteredOrHemmed === null ||
    !state.physicalCondition ||
    !revendaRespondida(state)
  ) {
    return 3;
  }

  // Passo 4: Tipo de pedido, comprovativo e prazo são obrigatórios
  if (!state.requestType || !state.proofOfPurchase || state.daysSincePurchase === null) return 4;

  // Passo 5: Modalidade de troca (se for troca), situação do cliente e exceção de gerência
  if (state.requestType === "TROCA" && (!state.exchangeOption || state.exchangeOption === "NENHUMA")) {
    return 5;
  }
  if (!state.customerSituation || state.managerException === null) {
    return 5;
  }

  // Passo 6: Valor, meio de pagamento original e, só para cartão, estado da conta
  const isGift = state.requestType === "GIFT" || state.proofOfPurchase === "RECIBO_OFERTA";
  if (isGift) {
    if (state.totalPrice === null || state.totalPrice <= 0) {
      return 6;
    }
  } else {
    const comCartao = exigeEstadoDaConta(state.originalPaymentMethod);
    if (
      state.totalPrice === null ||
      state.totalPrice <= 0 ||
      !state.originalPaymentMethod ||
      (comCartao && !state.accountState) ||
      (comCartao && state.accountState === "ENCERRADA" && state.originalRefundRefused === null) ||
      (state.originalPaymentMethod === "INTERAC" && state.physicalCardPresent === null) ||
      (state.originalPaymentMethod === "PAYPAL" && state.paymentAppAccessible === null)
    ) {
      return 6;
    }
  }

  return 6;
}

const STORAGE_KEY = "retailflow_wizard_state_v7";
const EVAL_STORAGE_KEY = "retailflow_wizard_eval_v7";

interface WizardContextType {
  state: WizardState;
  currentStep: number;
  totalSteps: number;
  isHydrated: boolean;
  isDirty: boolean;
  isLeaving: boolean;
  showLeaveModal: boolean;
  pendingNavigationUrl: string | null;
  evaluationResult: DecisaoResponse | null;
  lastRequest: ReturnRequest | null;
  evaluationDurationMs: number;
  setShowLeaveModal: (show: boolean) => void;
  setPendingNavigationUrl: (url: string | null) => void;
  setIsLeaving: (leaving: boolean) => void;
  confirmLeave: (targetUrl?: string) => void;
  cancelLeave: () => void;
  setField: <K extends keyof WizardState>(field: K, value: WizardState[K]) => void;
  goToStep: (step: number) => void;
  nextStep: () => void;
  prevStep: () => void;
  buildReturnRequest: () => ReturnRequest;
  resetWizard: () => void;
  saveDraft: () => boolean;
  setEvaluationData: (
    result: DecisaoResponse,
    request?: ReturnRequest,
    durationMs?: number
  ) => void;
  clearEvaluation: () => void;
  exitTo: (targetUrl?: string) => void;
}

const WizardContext = createContext<WizardContextType | undefined>(undefined);

export function WizardProvider({ children }: { children: ReactNode }) {
  const router = useRouter();
  const [state, setState] = useState<WizardState>(defaultWizardState);
  const [currentStep, setCurrentStep] = useState<number>(1);
  const [isHydrated, setIsHydrated] = useState<boolean>(false);
  const [isLeaving, setIsLeaving] = useState<boolean>(false);
  const [showLeaveModal, setShowLeaveModal] = useState<boolean>(false);
  const [pendingNavigationUrl, setPendingNavigationUrl] = useState<string | null>(null);
  const [evaluationResult, setEvaluationResult] = useState<DecisaoResponse | null>(null);
  const [lastRequest, setLastRequest] = useState<ReturnRequest | null>(null);
  const [evaluationDurationMs, setEvaluationDurationMs] = useState<number>(0);
  const totalSteps = 6;

  // O wizard só é considerado "dirty" enquanto o utilizador está a preencher o formulário.
  // Assim que a inferência é concluída e o veredito é gerado, a sessão está finalizada
  // e não deve despoletar guardas nem alertas de saída com perda de dados.
  const isDirty = Boolean(state.engine || state.marketJurisdiction) && !evaluationResult;

  // Carregar rascunho anterior e avaliação concluída de sessionStorage caso existam
  useEffect(() => {
    try {
      const saved = sessionStorage.getItem(STORAGE_KEY);
      if (saved) {
        const parsed = JSON.parse(saved);
        setState((prev) => ({ ...prev, ...parsed }));
      }
      const savedEval = sessionStorage.getItem(EVAL_STORAGE_KEY);
      if (savedEval) {
        const parsedEval = JSON.parse(savedEval);
        if (parsedEval.result) setEvaluationResult(parsedEval.result);
        if (parsedEval.request) setLastRequest(parsedEval.request);
        if (typeof parsedEval.durationMs === "number") {
          setEvaluationDurationMs(parsedEval.durationMs);
        }
      }
    } catch {
      // Ignorar erros de storage
    } finally {
      setIsHydrated(true);
    }
  }, []);

  // Guardar alterações de estado automaticamente
  useEffect(() => {
    try {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch {
      // Ignorar erros de storage
    }
  }, [state]);

  // Sincronizar veredito avaliado com sessionStorage
  useEffect(() => {
    try {
      if (evaluationResult) {
        sessionStorage.setItem(
          EVAL_STORAGE_KEY,
          JSON.stringify({
            result: evaluationResult,
            request: lastRequest,
            durationMs: evaluationDurationMs,
          })
        );
      } else {
        sessionStorage.removeItem(EVAL_STORAGE_KEY);
      }
    } catch {
      // Ignorar erros de storage
    }
  }, [evaluationResult, lastRequest, evaluationDurationMs]);

  // Interceção de atalhos de reload do teclado (F5, Ctrl+R, Cmd+R) para exibir o modal customizado
  useEffect(() => {
    if (!isDirty || isLeaving) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      const isF5 = e.key === "F5";
      const isReloadShortcut =
        (e.ctrlKey || e.metaKey) && (e.key === "r" || e.key === "R");

      if (isF5 || isReloadShortcut) {
        e.preventDefault();
        e.stopPropagation();
        setPendingNavigationUrl("__RELOAD__");
        setShowLeaveModal(true);
      }
    };

    window.addEventListener("keydown", handleKeyDown, { capture: true });
    return () => window.removeEventListener("keydown", handleKeyDown, { capture: true });
  }, [isDirty, isLeaving]);

  const setField = <K extends keyof WizardState>(field: K, value: WizardState[K]) => {
    if (evaluationResult) {
      setEvaluationResult(null);
      setLastRequest(null);
      setEvaluationDurationMs(0);
      try {
        sessionStorage.removeItem(EVAL_STORAGE_KEY);
      } catch {
        // Ignorar
      }
    }
    setState((prev) => {
      const updated = { ...prev, [field]: value };
      // Ajustar automaticamente moeda se jurisdição mudar
      if (field === "marketJurisdiction") {
        updated.currency = value === "CA" ? "CAD" : "USD";
      }
      // Camada de incerteza: as respostas que deixam de se aplicar são limpas
      if (field === "manufacturingDefect" && value !== false) {
        updated.defectClaimed = null;
        updated.defectInspection = {};
      }
      if (field === "defectClaimed" && value !== true) {
        updated.defectInspection = {};
      }
      if (field === "readyToResell" && value !== null) {
        updated.resaleUndecided = false;
        updated.wearLevel = null;
      }
      if (field === "resaleUndecided" && value === true) {
        updated.readyToResell = null;
      }
      if (field === "resaleUndecided" && value === false) {
        updated.wearLevel = null;
      }
      if (field === "physicalCondition" && !exigeDecisaoDeRevenda(updated)) {
        updated.resaleUndecided = false;
        updated.wearLevel = null;
      }
      // Sincronização reativa de modalidade de troca com o tipo de pedido (IN-005 / M6)
      if (field === "requestType") {
        if (value === "TROCA") {
          if (prev.exchangeOption === "NENHUMA" || prev.exchangeOption === null) {
            updated.exchangeOption = null;
          }
        } else {
          updated.exchangeOption = "NENHUMA";
        }
      }
      return updated;
    });
  };

  const goToStep = (step: number) => {
    if (step >= 1 && step <= totalSteps) {
      setCurrentStep(step);
    }
  };

  const nextStep = () => {
    if (currentStep < totalSteps) {
      setCurrentStep((prev) => prev + 1);
    }
  };

  const prevStep = () => {
    if (currentStep > 1) {
      setCurrentStep((prev) => prev - 1);
    }
  };

  const saveDraft = (): boolean => {
    try {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(state));
      return true;
    } catch {
      return false;
    }
  };

  const resetWizard = () => {
    setState(defaultWizardState);
    setCurrentStep(1);
    setEvaluationResult(null);
    setLastRequest(null);
    setEvaluationDurationMs(0);
    try {
      sessionStorage.removeItem(STORAGE_KEY);
      sessionStorage.removeItem(EVAL_STORAGE_KEY);
    } catch {
      // Ignorar
    }
  };

  const setEvaluationData = (
    result: DecisaoResponse,
    request?: ReturnRequest,
    durationMs?: number
  ) => {
    setEvaluationResult(result);
    if (request) setLastRequest(request);
    if (typeof durationMs === "number") setEvaluationDurationMs(durationMs);
  };

  const clearEvaluation = () => {
    setEvaluationResult(null);
    setLastRequest(null);
    setEvaluationDurationMs(0);
    try {
      sessionStorage.removeItem(EVAL_STORAGE_KEY);
    } catch {
      // Ignorar
    }
  };

  const exitTo = (targetUrl: string = "/") => {
    setIsLeaving(true);
    setShowLeaveModal(false);
    setPendingNavigationUrl(null);
    resetWizard();

    // Desarmar qualquer listener residual no objeto window
    if (typeof window !== "undefined") {
      window.onbeforeunload = null;
    }

    if (targetUrl === "__RELOAD__") {
      if (typeof window !== "undefined") {
        window.location.reload();
      }
      return;
    }

    // Navegação SPA suave com Next.js Router (sem provocar o alerta nativo do browser)
    router.push(targetUrl);
  };

  const confirmLeave = (targetUrl?: unknown) => {
    const validTarget =
      typeof targetUrl === "string" && targetUrl.trim().length > 0
        ? targetUrl
        : (typeof pendingNavigationUrl === "string" && pendingNavigationUrl.trim().length > 0
            ? pendingNavigationUrl
            : "/");

    exitTo(validTarget);
  };

  const cancelLeave = () => {
    setShowLeaveModal(false);
    setPendingNavigationUrl(null);
  };

function mapTipoPedidoToResolucaoPedida(
  requestType: WizardState["requestType"],
  exchangeOption: WizardState["exchangeOption"]
): "REEMBOLSO" | "TROCA" | "TROCA_MESMO_ARTIGO" | "CREDITO_LOJA" | "AJUSTE_PRECO" {
  switch (requestType) {
    case "DEVOLUCAO":
      return "REEMBOLSO";
    case "GIFT":
      return "CREDITO_LOJA";
    case "AJUSTE_PRECO":
      return "AJUSTE_PRECO";
    case "TROCA":
      return exchangeOption === "MESMO_MODELO" ? "TROCA_MESMO_ARTIGO" : "TROCA";
    default:
      return "REEMBOLSO";
  }
}

  const buildReturnRequest = (): ReturnRequest => {
    const today = new Date();
    const purchaseDate = new Date(today);
    const effectiveDays = state.daysSincePurchase ?? 14;
    purchaseDate.setDate(today.getDate() - effectiveDays);

    const formattedToday = today.toISOString().split("T")[0];
    const formattedPurchaseDate = purchaseDate.toISOString().split("T")[0];

    // Mapeamento normalizado compatível com Drools e Prolog
    const isOnline = state.purchaseChannel === "ONLINE_BACKPOCKET";
    const mercadoEfetivo = state.marketJurisdiction === "CA" ? "CANADA" : "EUA";
    const canalEfetivo = isOnline
      ? state.marketJurisdiction === "CA"
        ? "LEVI_CA"
        : "LEVI_COM"
      : state.purchaseChannel === "FRANQUIA_CA"
      ? "FRANQUIA_CANADA"
      : state.purchaseChannel === "GROSSISTA"
      ? "GROSSISTA"
      : state.purchaseChannel === "DESCONHECIDO"
      ? "DESCONHECIDO"
      : state.storeType === "OUTLET"
      ? "OUTLET"
      : "MAINLINE";

    const condicaoUso =
      state.physicalCondition === "USADO" || state.physicalCondition === "MANCHADO"
        ? "USADO"
        : state.physicalCondition === "LAVADO"
        ? "LAVADO"
        : "NAO_USADO";

    const etiquetas =
      state.physicalCondition === "NOVO_ETIQUETAS"
        ? "COLOCADAS"
        : state.physicalCondition === "NOVO_ETIQUETAS_SOLTAS"
        ? "SOLTAS"
        : "AUSENTES";

    const isBlind = !isOnline && state.proofOfPurchase === "SEM_COMPROVATIVO";

    const comprovativoTipo = isOnline
      ? state.onlineOrderFound
        ? "CONFIRMACAO_ENCOMENDA"
        : null
      : state.proofOfPurchase === "RECIBO_ORIGINAL"
      ? "RECIBO_IMPRESSO"
      : state.proofOfPurchase === "CONFIRMACAO_ONLINE"
      ? "CONFIRMACAO_ENCOMENDA"
      : state.proofOfPurchase === "RECIBO_OFERTA"
      ? "RECIBO_OFERTA"
      : state.proofOfPurchase === "CONSULTA_POS"
      ? "CONSULTA_TRANSACAO"
      : isBlind
      ? null
      : "RECIBO_IMPRESSO"; // fallback seguro

    const isGift = state.requestType === "GIFT" || state.proofOfPurchase === "RECIBO_OFERTA";

    const effectiveTipoPedido = isOnline
      ? state.requestType === "TROCA" || state.onlineInStoreExchange
        ? "TROCA"
        : "DEVOLUCAO"
      : isGift
      ? "DEVOLUCAO_OFERTA"
      : state.requestType ?? "DEVOLUCAO";

    const effectiveResolucaoPedida = isGift
      ? "CREDITO_LOJA"
      : mapTipoPedidoToResolucaoPedida(
          isOnline && state.onlineInStoreExchange ? "TROCA" : state.requestType,
          state.exchangeOption
        );

    const meioPagamentoOnline =
      state.onlinePaymentMethod === "BNPL"
        ? "AFTERPAY"
        : state.onlinePaymentMethod === "PAYPAL"
        ? "PAYPAL"
        : state.onlinePaymentMethod === "WALLETS"
        ? "APPLE_PAY"
        : "CREDITO";

    const isAfterpayOnlineExchange =
      (state.originalPaymentMethod === "AFTERPAY" || (isOnline && state.onlinePaymentMethod === "BNPL")) &&
      isOnline &&
      (effectiveTipoPedido === "TROCA" || state.requestType === "TROCA");

    const isPaypalNoAccess =
      (state.originalPaymentMethod === "PAYPAL" || (isOnline && state.onlinePaymentMethod === "PAYPAL")) &&
      state.paymentAppAccessible === false;

    const shouldContornarObrigatorio = isAfterpayOnlineExchange || isPaypalNoAccess;

    const effectivePrice = state.totalPrice ?? 89.9;

    // Camada de incerteza (Drools): só se envia o que o colaborador respondeu
    const usaIncerteza = usaCamadaIncerteza(state);
    const alegaDefeito = podeAlegarDefeito(state) && state.defectClaimed === true;
    const inspecaoDefeito = Object.fromEntries(
      Object.entries(state.defectInspection).filter(([, resposta]) => resposta !== undefined)
    );
    const grauUso =
      usaIncerteza && state.resaleUndecided && state.wearLevel !== null ? state.wearLevel : undefined;

    return {
      id: "REQ-" + Date.now(),
      dataPedido: formattedToday,
      tipoPedido: effectiveTipoPedido,
      portalOnlineDisponivel: true,
      politicaPermiteAsCegasOnline: false,
      loja: {
        codigo: state.marketJurisdiction === "CA" ? "CA-STORE-01" : "US-STORE-01",
        nome: `Loja ${state.storeType === "OUTLET" ? "Outlet" : "Mainline"} (${mercadoEfetivo})`,
        mercado: mercadoEfetivo,
        tipoLoja: state.storeType || "MAINLINE",
        skusSortido: ["501-ORIGINAL-FIT", "721-HIGH-RISE", "TRUCKER-JACKET"],
      },
      colaborador: {
        id: "OP-042",
        nome: state.operatorName,
        funcao: "KEY_HOLDER",
        idCredencialPOS: "POS-042",
      },
      cliente: {
        id: "CLI-DEFAULT",
        idCliente: "CLI-DEFAULT",
        forneceDados: true,
        paisResidencia: mercadoEfetivo,
        contestaResultado:
          state.customerSituation === "CONTESTA" ||
          state.customerSituation === "CHAMAR_GERENCIA",
        agitado: state.customerSituation === "CHAMAR_GERENCIA",
        explicaOrigemCompra: usaIncerteza ? state.purchaseOriginExplained ?? undefined : undefined,
        pedeNumerario: usaIncerteza && state.asksForCash === true,
      },
      compraOriginal: {
        idTransacao: isOnline
          ? state.onlineOrderNumber || "WEB-84920-PT"
          : isBlind
          ? null
          : "TX-ORIG-" + Math.floor(100000 + Math.random() * 900000),
        canal: canalEfetivo,
        dataCompra: isBlind ? null : formattedPurchaseDate,
        dataEnvio: isOnline ? formattedPurchaseDate : null,
        encomendaEncontrada: isOnline ? state.onlineOrderFound : true,
        compraOferta: isGift || effectiveTipoPedido === "DEVOLUCAO_OFERTA",
        moeda: state.currency,
        valorTotal: effectivePrice,
        pagamento: {
          meio:
            state.originalPaymentMethod ||
            (isGift
              ? "CREDITO"
              : state.refundMethod === "VALE_LOJA"
              ? "CARTAO_OFERTA"
              : isOnline
              ? meioPagamentoOnline
              : "CREDITO"),
          valorPago: effectivePrice,
          estadoConta: isGift ? "ATIVA" : (state.accountState || (state.refundMethod === "CARTAO_ENCERRADO" ? "ENCERRADA" : "ATIVA")),
          cartaoFisicoPresente: isGift ? false : (state.physicalCardPresent ?? true),
          reembolsoOriginalRecusado: state.originalRefundRefused ?? false,
          acessoAplicacaoPagamento: state.paymentAppAccessible ?? true,
        },
        idStylistVenda: "S-18",
        quantidadeComprada: 1,
      },
      comprovativo: isBlind
        ? null
        : {
            tipo: comprovativoTipo,
            idComprovativo: isOnline
              ? state.onlineOrderNumber || "RCP-ONLINE-84920"
              : "RCP-" + Math.floor(100000 + Math.random() * 900000),
            confirmaCompra: isOnline
              ? state.onlineOrderFound
              : state.proofOfPurchase !== "SEM_COMPROVATIVO",
            reciboOriginal: isOnline
              ? state.onlineOrderFound
              : state.proofOfPurchase === "RECIBO_ORIGINAL" ||
                state.proofOfPurchase === "CONFIRMACAO_ONLINE" ||
                state.proofOfPurchase === "RECIBO_OFERTA",
          },
      artigos: [
        {
          id: "A-01",
          produto: {
            sku: "501-ORIGINAL-FIT",
            skuReconhecidoPOS: state.barcodeRecognized ?? true,
            marca: state.brandAllowed === false ? "OUTRA" : "LEVIS",
            categoria: state.intimateUnderwear ? "BODYWEAR" : "VESTUARIO",
            vendidoNaLoja: true,
            produtoFranquia: state.purchaseChannel === "FRANQUIA_CA",
            pvpOriginal: effectivePrice,
            precoAtual: state.precoAtualProduto ?? effectivePrice,
          },
          quantidade: 1,
          precoPago: effectivePrice,
          revendivel:
            state.physicalCondition === "NOVO_ETIQUETAS_SOLTAS" ||
            state.physicalCondition === "NOVO_SEM_ETIQUETAS"
              ? state.readyToResell
              : state.physicalCondition === "NOVO_ETIQUETAS",
          estado: {
            condicaoUso,
            etiquetas,
            embainhado: Boolean(state.alteredOrHemmed),
            alterado: Boolean(state.alteredOrHemmed),
            personalizado: false,
            defeitoFabricoConfirmado: Boolean(state.manufacturingDefect),
            sujoOuInseguro: state.physicalCondition === "MANCHADO",
            danificado: state.physicalCondition === "MANCHADO",
            grauUso,
            alegaDefeito,
            inspecaoDefeito: alegaDefeito && Object.keys(inspecaoDefeito).length > 0 ? inspecaoDefeito : undefined,
            bainhaFeitaOuAlterada: Boolean(state.alteredOrHemmed),
            temDefeitoFabrico: Boolean(state.manufacturingDefect),
            revendivel:
              state.physicalCondition === "NOVO_ETIQUETAS_SOLTAS" ||
              state.physicalCondition === "NOVO_SEM_ETIQUETAS"
                ? state.readyToResell
                : state.physicalCondition === "NOVO_ETIQUETAS",
          },
          entreCanais: state.purchaseChannel !== "FISICA",
        },
      ],
      artigosTroca:
        (state.requestType === "TROCA" ||
          effectiveTipoPedido === "TROCA" ||
          (isOnline && state.onlineInStoreExchange)) &&
        state.exchangeOption !== "NENHUMA" &&
        state.exchangeOption !== null
          ? [
              {
                produto: {
                  sku:
                    state.exchangeOption === "OUTRO_ARTIGO"
                      ? "721-HIGH-RISE-30"
                      : "501-ORIGINAL-FIT-32",
                  skuReconhecidoPOS: true,
                  marca: "LEVIS",
                  categoria: "VESTUARIO",
                  vendidoNaLoja: true,
                  pvpOriginal: effectivePrice,
                  precoAtual: state.precoAtualProduto ?? effectivePrice,
                },
                apenasMudaTamanho:
                  state.exchangeOption === "OUTRO_ARTIGO"
                    ? false
                    : state.exchangeOption === "MESMO_MODELO" || isOnline,
                precoVenda: state.precoAtualProduto ?? effectivePrice,
              },
            ]
          : [],
      excecaoGerencia: Boolean(state.managerException),
      situacaoCliente: state.customerSituation ?? "CONFORME",
      pedidoExcecao: state.managerException
        ? {
            aprovada: true,
            motivo: "Exceção autorizada pelo responsável sénior presente",
            concluivelNoSistema: true,
            contornaProcessoObrigatorio: shouldContornarObrigatorio,
            resolucaoPedida: effectiveResolucaoPedida,
          }
        : isGift
        ? {
            motivo: "Devolução de oferta com recibo: cliente optou por crédito de loja",
            resolucaoPedida: "CREDITO_LOJA",
            concluivelNoSistema: true,
            aprovada: true,
            contornaProcessoObrigatorio: false,
          }
        : isAfterpayOnlineExchange
        ? {
            motivo: "Exige troca em loja para compra online paga com Afterpay e contorna o processo obrigatório",
            resolucaoPedida: "TROCA",
            contornaProcessoObrigatorio: true,
            preocupacaoCliente: "Quer a troca em loja e contorna o processo obrigatório Afterpay",
            aprovada: null,
            concluivelNoSistema: true,
          }
        : state.customerSituation !== "CONFORME" && state.customerSituation !== null
        ? {
            aprovada: null, // Pendente de avaliação
            concluivelNoSistema: true,
            contornaProcessoObrigatorio: shouldContornarObrigatorio,
            resolucaoPedida: effectiveResolucaoPedida,
          }
        : shouldContornarObrigatorio
        ? {
            motivo: "Pedido exige contornar o processo operacional obrigatório",
            resolucaoPedida: effectiveResolucaoPedida,
            contornaProcessoObrigatorio: true,
            concluivelNoSistema: true,
          }
        : null,
    };
  };

  return (
    <WizardContext.Provider
      value={{
        state,
        currentStep,
        totalSteps,
        isHydrated,
        isDirty,
        isLeaving,
        showLeaveModal,
        pendingNavigationUrl,
        setShowLeaveModal,
        setPendingNavigationUrl,
        setIsLeaving,
        confirmLeave,
        cancelLeave,
        setField,
        goToStep,
        nextStep,
        prevStep,
        buildReturnRequest,
        resetWizard,
        saveDraft,
        evaluationResult,
        lastRequest,
        evaluationDurationMs,
        setEvaluationData,
        clearEvaluation,
        exitTo,
      }}
    >
      {children}
    </WizardContext.Provider>
  );
}

export function useWizard() {
  const context = useContext(WizardContext);
  if (!context) {
    throw new Error("useWizard deve ser usado dentro de um WizardProvider");
  }
  return context;
}

export function useOptionalWizard() {
  return useContext(WizardContext);
}
