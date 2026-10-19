"""FastAPI endpoints exposing the Levi's Retail Returns Prolog expert engine.

Provides HTTP routes for batch evaluation, dialogic interactive interrogation,
counterfactual What-If simulation, multi-perspective explanations (How, Why Not),
and parity endpoints for dashboard integration (/avaliar, /cenarios-exemplo, etc.).
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional, Union
from uuid import UUID

from fastapi import APIRouter, Body, Depends, HTTPException, Path, Query, status

from app.api.deps import get_prolog_client, get_retail_prolog_service
from app.clients.prolog_client import PrologClient
from app.core.exceptions import (
    PrologConnectionError,
    PrologResponseError,
    PrologTimeoutError,
)
from app.schemas.levis import (
    CenarioExemploResponse,
    DadosEmFaltaResponse,
    DecisaoResponse,
    ExplicacaoComoResponse,
    ExplicacaoPorqueNaoConclusaoResponse,
    ExplicacaoPorqueResponse,
    SimulacaoResponse,
)
from app.services.retail_prolog_service import RetailPrologService

router = APIRouter(
    prefix="/retail",
    tags=["Levi's Retail Returns Expert Engine (Prolog)"],
)


def _handle_prolog_exception(exc: Exception) -> None:
    """Translate Prolog transport/runtime exceptions into standard FastAPI HTTPExceptions."""
    if isinstance(exc, (PrologConnectionError, PrologTimeoutError)):
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=exc.message,
        ) from exc
    if isinstance(exc, PrologResponseError):
        raise HTTPException(
            status_code=exc.status_code if 400 <= exc.status_code < 500 else status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=exc.message,
        ) from exc
    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail=str(exc),
    ) from exc


# ==============================================================================
# DASHBOARD PARITY ENDPOINTS (LEVI'S RETURNS)
# ==============================================================================


@router.get(
    "/cenarios-exemplo",
    response_model=List[CenarioExemploResponse],
    status_code=status.HTTP_200_OK,
    summary="Listar cenários de teste oficiais da Levi's para inferência Prolog",
)
async def listar_cenarios_exemplo(
    retail_service: RetailPrologService = Depends(get_retail_prolog_service),
) -> List[CenarioExemploResponse]:
    """Retrieve all 10 official reference scenarios."""
    return retail_service.get_example_scenarios()


@router.get(
    "/cenarios-exemplo/{id}",
    response_model=CenarioExemploResponse,
    status_code=status.HTTP_200_OK,
    summary="Obter cenário oficial da Levi's por ID",
)
async def obter_cenario_exemplo(
    id: int = Path(..., ge=1, le=10, description="Número ordinal do cenário (1 a 10)"),
    retail_service: RetailPrologService = Depends(get_retail_prolog_service),
) -> CenarioExemploResponse:
    """Retrieve an official Levi's scenario by ID."""
    sc = retail_service.get_example_scenario_by_id(id)
    if sc is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cenário oficial #{id} não foi encontrado.",
        )
    return sc


@router.post(
    "/avaliar",
    response_model=DecisaoResponse,
    status_code=status.HTTP_200_OK,
    summary="Avaliar pedido de devolução/troca no motor Prolog da Levi's",
    description="Submete o cenário/pedido ao motor declarativo SWI-Prolog e devolve o veredito tipado DecisaoResponse.",
)
async def avaliar_pedido(
    payload: Dict[str, Any] = Body(...),
    retail_service: RetailPrologService = Depends(get_retail_prolog_service),
) -> DecisaoResponse:
    """Evaluate return request and map to canonical DecisaoResponse."""
    try:
        return await retail_service.evaluate_return(payload)
    except Exception as exc:
        _handle_prolog_exception(exc)


@router.get(
    "/avaliacoes/{id}",
    response_model=DecisaoResponse,
    status_code=status.HTTP_200_OK,
    summary="Recuperar avaliação Prolog por UUID",
)
async def obter_avaliacao(
    id: UUID = Path(..., description="UUID da avaliação realizada"),
    retail_service: RetailPrologService = Depends(get_retail_prolog_service),
) -> DecisaoResponse:
    """Retrieve a cached evaluation by UUID."""
    ev = retail_service.get_evaluation(id)
    if ev is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Avaliação {id} não encontrada.",
        )
    return ev


@router.get(
    "/avaliacoes/{id}/explicacoes/como",
    response_model=ExplicacaoComoResponse,
    status_code=status.HTTP_200_OK,
    summary="Explicação causal Como? no motor Prolog",
)
async def explicacao_como(
    id: UUID = Path(..., description="UUID da avaliação"),
    retail_service: RetailPrologService = Depends(get_retail_prolog_service),
) -> ExplicacaoComoResponse:
    """Retrieve How explanation causal chain for an evaluation."""
    return await retail_service.explain_how(id)


@router.get(
    "/avaliacoes/{id}/explicacoes/porque-nao",
    response_model=ExplicacaoPorqueNaoConclusaoResponse,
    status_code=status.HTTP_200_OK,
    summary="Explicação contrafactual Porque Não? no motor Prolog",
)
async def explicacao_porque_nao(
    id: UUID = Path(..., description="UUID da avaliação"),
    conclusao: Optional[str] = Query(None, description="Conclusão alvo (ex.: OUT-001:PERMITIR)"),
    retail_service: RetailPrologService = Depends(get_retail_prolog_service),
) -> ExplicacaoPorqueNaoConclusaoResponse:
    """Retrieve Why Not explanation for unreached conclusions."""
    return await retail_service.explain_whynot(id, target=conclusao)


@router.post(
    "/avaliacoes/{id}/simulacoes",
    response_model=SimulacaoResponse,
    status_code=status.HTTP_200_OK,
    summary="Simulação contrafactual E Se? no motor Prolog",
)
async def simular_whatif(
    id: UUID = Path(..., description="UUID da avaliação de referência"),
    payload: Dict[str, Any] = Body(...),
    retail_service: RetailPrologService = Depends(get_retail_prolog_service),
) -> SimulacaoResponse:
    """Simulate variations on a scenario using Prolog sandbox."""
    alteracoes = payload.get("alteracoes") or payload
    return await retail_service.simulate_whatif(id, alteracoes=alteracoes)


@router.post(
    "/dados-em-falta",
    response_model=DadosEmFaltaResponse,
    status_code=status.HTTP_200_OK,
    summary="Análise de dados em falta via mecânica dialógica ACM Prolog",
)
async def dados_em_falta(
    payload: Dict[str, Any] = Body(...),
    retail_service: RetailPrologService = Depends(get_retail_prolog_service),
) -> DadosEmFaltaResponse:
    """Check for missing premises using Prolog interactive ACM mechanics."""
    return await retail_service.missing_data(payload)


@router.post(
    "/porque",
    response_model=ExplicacaoPorqueResponse,
    status_code=status.HTTP_200_OK,
    summary="Explicação Porquê da pergunta ao colaborador no motor Prolog",
)
async def explicar_porque_dado(
    dado: Optional[str] = Query(None, description="Código do dado em falta (ex.: IN-004)"),
    payload: Dict[str, Any] = Body(default_factory=dict),
    retail_service: RetailPrologService = Depends(get_retail_prolog_service),
) -> ExplicacaoPorqueResponse:
    """Explain why a specific premise is asked by the Prolog rule."""
    return await retail_service.explain_why(dado or "IN-004", payload)


@router.get(
    "/health",
    status_code=status.HTTP_200_OK,
    summary="Verificar estado de saúde do motor Prolog Levi's",
)
async def verificar_saude_prolog(
    prolog_client: PrologClient = Depends(get_prolog_client),
) -> Dict[str, Any]:
    """Check Prolog retail microservice health status."""
    is_healthy = await prolog_client.check_health()
    if not is_healthy:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="SWI-Prolog engine is unreachable.",
        )
    return {
        "status": "UP",
        "engine": "SWI-Prolog Levi's Retail Returns Engine (71 Regras)",
    }


# ==============================================================================
# EXISTING PROLOG RETAIL ROUTES (CORE API)
# ==============================================================================


@router.post(
    "/evaluate",
    status_code=status.HTTP_200_OK,
    summary="Evaluate retail return scenario against Levi's Prolog rules",
    description=(
        "Executes batch deduction across the 71 Levi's retail return rules and 9 policy families. "
        "Returns the final diagnostic verdict and justification chain."
    ),
)
async def evaluate_retail_scenario(
    payload: Dict[str, Any] = Body(...),
    prolog_client: PrologClient = Depends(get_prolog_client),
) -> Dict[str, Any]:
    """Execute batch evaluation on retail facts."""
    try:
        return await prolog_client.evaluate_retail(payload)
    except Exception as exc:
        _handle_prolog_exception(exc)


@router.post(
    "/interactive",
    status_code=status.HTTP_200_OK,
    summary="Step-by-step or simulated active dialogue interrogation",
    description=(
        "Coordinates interactive premise acquisition per Prof. ACM mechanics. "
        "Allows answering pending floor questions or evaluating with partial facts."
    ),
)
async def interactive_dialogue(
    payload: Dict[str, Any] = Body(default_factory=dict),
    prolog_client: PrologClient = Depends(get_prolog_client),
) -> Dict[str, Any]:
    """Execute dialogic step with the retail engine."""
    try:
        return await prolog_client.interactive_retail(payload)
    except Exception as exc:
        _handle_prolog_exception(exc)


@router.post(
    "/whatif",
    status_code=status.HTTP_200_OK,
    summary="Counterfactual simulation sandbox (What-If)",
    description=(
        "Hypothetically modifies premises and compares baseline outcome against simulated "
        "outcome without persisting changes or polluting session working memory."
    ),
)
async def whatif_simulation(
    payload: Dict[str, Any] = Body(...),
    prolog_client: PrologClient = Depends(get_prolog_client),
) -> Dict[str, Any]:
    """Execute counterfactual What-If sandbox simulation."""
    try:
        return await prolog_client.whatif_retail(payload)
    except Exception as exc:
        _handle_prolog_exception(exc)


@router.post(
    "/how",
    status_code=status.HTTP_200_OK,
    summary="Causal deductive trace for fact/decision (Via 1: How)",
    description="Explains how a fact or decision was concluded step-by-step.",
)
async def explain_how(
    payload: Dict[str, Any] = Body(...),
    prolog_client: PrologClient = Depends(get_prolog_client),
) -> Dict[str, Any]:
    """Generate deductive explanation for a fact."""
    try:
        return await prolog_client.how_retail(payload)
    except Exception as exc:
        _handle_prolog_exception(exc)


@router.post(
    "/whynot",
    status_code=status.HTTP_200_OK,
    summary="Failure tree analysis for unreached outcome (Via 4: Why Not)",
    description="Explains which candidate rule premises failed preventing a given outcome.",
)
async def explain_whynot(
    payload: Dict[str, Any] = Body(...),
    prolog_client: PrologClient = Depends(get_prolog_client),
) -> Dict[str, Any]:
    """Generate Why Not explanation detailing failed premises."""
    try:
        return await prolog_client.whynot_retail(payload)
    except Exception as exc:
        _handle_prolog_exception(exc)


@router.get(
    "/facts",
    status_code=status.HTTP_200_OK,
    summary="List all facts currently in retail working memory",
)
async def get_retail_facts(
    prolog_client: PrologClient = Depends(get_prolog_client),
) -> Dict[str, Any]:
    """Retrieve all asserted facts."""
    try:
        return await prolog_client.facts_retail()
    except Exception as exc:
        _handle_prolog_exception(exc)


@router.post(
    "/reset",
    status_code=status.HTTP_200_OK,
    summary="Reset retail engine session memory and interactive state",
)
async def reset_retail_session(
    prolog_client: PrologClient = Depends(get_prolog_client),
) -> Dict[str, Any]:
    """Reset session state."""
    try:
        return await prolog_client.reset_retail()
    except Exception as exc:
        _handle_prolog_exception(exc)
