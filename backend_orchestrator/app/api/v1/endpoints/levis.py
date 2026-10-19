"""FastAPI endpoints for the Levi's Drools Expert reasoning engine.

Exposes REST routes for evaluation, multi-way explanations (Why, How, Why Not,
Missing Data, What If counterfactual simulation), knowledge base rule inspection,
and test scenarios under the unified /api/v1/levis/* namespace.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional, Union

from fastapi import APIRouter, Body, Depends, HTTPException, Path, Query, status

from app.api.deps import get_levis_service
from app.core.exceptions import (
    LevisConnectionError,
    LevisResponseError,
    LevisTimeoutError,
)
from app.schemas.levis import (
    AvaliacaoResumoResponse,
    CenarioExemploResponse,
    ColaboradorDto,
    DadosEmFaltaResponse,
    DecisaoResponse,
    ExplicacaoComoResponse,
    ExplicacaoConclusaoResponse,
    ExplicacaoPorqueNaoConclusaoResponse,
    ExplicacaoPorqueNaoResponse,
    ExplicacaoPorqueResponse,
    PaginaResponse,
    PedidoAvaliacaoRequest,
    RegraDetalheDto,
    RegraResumoDto,
    SimulacaoRequest,
    SimulacaoResponse,
)
from app.services.levis_service import LevisService

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/levis",
    tags=["Levi's Returns Expert Engine (Drools)"],
)


def _handle_levis_exception(exc: Exception) -> None:
    """Translate domain exceptions from LevisClient/Drools into standard FastAPI HTTPExceptions."""
    if isinstance(exc, (LevisConnectionError, LevisTimeoutError)):
        logger.error("Levi's engine communication failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=exc.message,
        ) from exc

    if isinstance(exc, LevisResponseError):
        logger.warning(
            "Levi's engine returned error status %s: %s",
            exc.status_code,
            exc.message,
        )
        detail: Any = exc.message
        if isinstance(exc.response_data, dict):
            detail = (
                exc.response_data.get("detail")
                or exc.response_data.get("message")
                or exc.response_data.get("title")
                or exc.message
            )
        status_code = (
            exc.status_code
            if 400 <= exc.status_code < 500
            else status.HTTP_502_BAD_GATEWAY
        )
        raise HTTPException(
            status_code=status_code,
            detail=detail,
        ) from exc

    if isinstance(exc, HTTPException):
        raise exc

    logger.exception("Unexpected error in Levi's endpoint handler: %s", exc)
    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail=f"Internal error processing Levi's request: {exc}",
    ) from exc


def _extract_pedido(
    payload: Union[PedidoAvaliacaoRequest, CenarioExemploResponse],
) -> PedidoAvaliacaoRequest:
    """Extract PedidoAvaliacaoRequest whether the client sent a raw pedido or wrapped scenario."""
    if isinstance(payload, CenarioExemploResponse):
        return payload.pedido
    return payload


# ==============================================================================
# 1. CORE EVALUATION
# ==============================================================================


@router.post(
    "/avaliar",
    response_model=DecisaoResponse,
    status_code=status.HTTP_200_OK,
    summary="Avaliar pedido de devolução, troca ou ajuste de preço (Drools)",
    description=(
        "Submete os factos de um pedido de devolução/troca ao motor pericial Drools Levi's. "
        "Aplica as 98 regras de produção DRL nos módulos M0-M9 e devolve a decisão completa "
        "(elegibilidade, valores a liquidar, destino físico de cada artigo e auditoria de regras disparadas). "
        "Aceita tanto o contrato PedidoAvaliacaoRequest direto como o JSON integral de um cenário de teste."
    ),
    responses={
        200: {
            "description": "Avaliação processada com sucesso e persistida no PostgreSQL.",
            "model": DecisaoResponse,
        },
        400: {"description": "Bad Request: Pedido com dados incompatíveis."},
        422: {"description": "Unprocessable Entity: Faltam campos obrigatórios do contrato."},
        503: {"description": "Service Unavailable: Motor Drools inacessível ou tempo limite excedido."},
    },
)
async def avaliar(
    payload: Union[PedidoAvaliacaoRequest, CenarioExemploResponse],
    levis_service: LevisService = Depends(get_levis_service),
) -> DecisaoResponse:
    """Process return/exchange facts and return comprehensive diagnosis."""
    try:
        pedido = _extract_pedido(payload)
        if not pedido.artigos or not pedido.tipoPedido:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="O pedido de avaliação exige 'tipoPedido' e pelo menos um artigo em 'artigos'.",
            )
        return await levis_service.evaluate(pedido)
    except Exception as exc:
        _handle_levis_exception(exc)


@router.get(
    "/avaliacoes/{id}",
    response_model=DecisaoResponse,
    status_code=status.HTTP_200_OK,
    summary="Consultar avaliação persistida por UUID",
    description="Recupera o histórico e veredito integral de uma avaliação previamente processada e gravada.",
    responses={
        200: {
            "description": "Avaliação encontrada.",
            "model": DecisaoResponse,
        },
        404: {"description": "Avaliação não encontrada com o UUID fornecido."},
        503: {"description": "Service Unavailable: Motor Drools ou PostgreSQL inacessível."},
    },
)
async def consultar_avaliacao(
    id: str = Path(
        ...,
        description="UUID identificador da avaliação",
        examples=["35e1fa88-5ba8-4cd4-a6dc-7ae0f52faf72"],
    ),
    levis_service: LevisService = Depends(get_levis_service),
) -> DecisaoResponse:
    """Retrieve an evaluation record by UUID."""
    try:
        return await levis_service.get_evaluation(id)
    except Exception as exc:
        _handle_levis_exception(exc)


@router.get(
    "/avaliacoes",
    response_model=PaginaResponse[AvaliacaoResumoResponse],
    status_code=status.HTTP_200_OK,
    summary="Listar histórico de avaliações (paginado)",
    description="Consulta o histórico paginado de avaliações guardadas na base de dados PostgreSQL.",
    responses={
        200: {
            "description": "Página com resumos de avaliações.",
            "model": PaginaResponse[AvaliacaoResumoResponse],
        },
        503: {"description": "Service Unavailable: Motor Drools ou PostgreSQL inacessível."},
    },
)
async def listar_avaliacoes(
    loja: Optional[str] = Query(None, description="Filtro opcional por código de loja"),
    pagina: int = Query(0, ge=0, description="Índice da página (inicia em 0)"),
    tamanho: int = Query(20, ge=1, le=100, description="Número de elementos por página"),
    levis_service: LevisService = Depends(get_levis_service),
) -> PaginaResponse[AvaliacaoResumoResponse]:
    """List evaluations with pagination and store filter."""
    try:
        return await levis_service.list_evaluations(loja=loja, pagina=pagina, tamanho=tamanho)
    except Exception as exc:
        _handle_levis_exception(exc)


# ==============================================================================
# 2. EXPLICABILIDADE: DADOS EM FALTA & PORQUÊ
# ==============================================================================


@router.post(
    "/dados-em-falta",
    response_model=DadosEmFaltaResponse,
    status_code=status.HTTP_200_OK,
    summary="Identificar dados em falta num pedido em preenchimento (O que falta?)",
    description=(
        "Analisa um pedido parcial em curso e indica a lista de perguntas/factos de entrada (IN-xxx) "
        "ainda necessários para alcançar uma decisão conclusiva, acompanhados da respetiva justificação."
    ),
    responses={
        200: {
            "description": "Lista de dados em falta identificada com sucesso.",
            "model": DadosEmFaltaResponse,
        },
        503: {"description": "Service Unavailable: Motor Drools inacessível."},
    },
)
async def dados_em_falta(
    payload: Union[PedidoAvaliacaoRequest, CenarioExemploResponse],
    locale: Optional[str] = Query(
        None, description="Tag de idioma para textos das perguntas (ex.: pt-PT, en-US)"
    ),
    levis_service: LevisService = Depends(get_levis_service),
) -> DadosEmFaltaResponse:
    """Analyze partially filled order facts and return required missing questions."""
    try:
        pedido = _extract_pedido(payload)
        return await levis_service.get_missing_data(pedido, locale=locale)
    except Exception as exc:
        _handle_levis_exception(exc)


@router.post(
    "/porque",
    response_model=ExplicacaoPorqueResponse,
    status_code=status.HTTP_200_OK,
    summary="Justificar a exigência de um dado de entrada específico (Porquê?)",
    description=(
        "Explica por que razão o sistema solicita um determinado dado (código IN-xxx), "
        "revelando quais as regras e conclusões pendentes que dependem deste facto."
    ),
    responses={
        200: {
            "description": "Justificação causal do requisito de entrada.",
            "model": ExplicacaoPorqueResponse,
        },
        503: {"description": "Service Unavailable: Motor Drools inacessível."},
    },
)
async def porque(
    payload: Union[PedidoAvaliacaoRequest, CenarioExemploResponse],
    dado: str = Query(
        ...,
        description="Código do dado de entrada analisado (ex.: IN-010)",
        examples=["IN-010"],
    ),
    locale: Optional[str] = Query(None, description="Tag de idioma para o texto explicativo"),
    levis_service: LevisService = Depends(get_levis_service),
) -> ExplicacaoPorqueResponse:
    """Explain why a specific question is asked for the current order state."""
    try:
        pedido = _extract_pedido(payload)
        return await levis_service.get_why(dado=dado, request=pedido, locale=locale)
    except Exception as exc:
        _handle_levis_exception(exc)


# ==============================================================================
# 3. EXPLICABILIDADE CAUSAL: COMO & PORQUE NÃO
# ==============================================================================


@router.get(
    "/avaliacoes/{id}/explicacoes/como",
    response_model=Union[ExplicacaoComoResponse, ExplicacaoConclusaoResponse],
    status_code=status.HTTP_200_OK,
    summary="Explicar como uma decisão ou conclusão foi deduzida (Como?)",
    description=(
        "Traça o percurso causal das regras disparadas (How). Sem parâmetros adicionais, "
        "devolve a sequência temporal de todas as deduções; com 'conclusao' (ex.: OUT-001), "
        "isola a árvore de derivação que culminou nesse valor específico."
    ),
    responses={
        200: {
            "description": "Explicação causal gerada com sucesso.",
        },
        404: {"description": "Avaliação não encontrada com o UUID fornecido."},
        503: {"description": "Service Unavailable: Motor Drools inacessível."},
    },
)
async def explicar_como(
    id: str = Path(..., description="UUID da avaliação pericial"),
    conclusao: Optional[str] = Query(
        None, description="Código da conclusão alvo (ex.: OUT-001)"
    ),
    artigo: Optional[str] = Query(
        None, description="Identificador do artigo alvo (ex.: A-1)"
    ),
    locale: Optional[str] = Query(None, description="Tag de idioma"),
    levis_service: LevisService = Depends(get_levis_service),
) -> Union[ExplicacaoComoResponse, ExplicacaoConclusaoResponse]:
    """Return causal trace of how a decision or specific output conclusion was reached."""
    try:
        return await levis_service.explain_how(
            evaluation_id=id, conclusao=conclusao, artigo=artigo, locale=locale
        )
    except Exception as exc:
        _handle_levis_exception(exc)


@router.get(
    "/avaliacoes/{id}/explicacoes/porque-nao",
    response_model=Union[ExplicacaoPorqueNaoConclusaoResponse, ExplicacaoPorqueNaoResponse],
    status_code=status.HTTP_200_OK,
    summary="Explicar por que razão uma conclusão não foi obtida ou regra não disparou (Porque não?)",
    description=(
        "Identifica os fatores impeditivos (Why Not). Com 'conclusao' (ex.: OUT-001:PERMITIR), "
        "mostra por que razão essa decisão não foi adotada; com 'regra' (ex.: PT-003), "
        "avalia detalhadamente cada premissa LHS que falhou."
    ),
    responses={
        200: {
            "description": "Explicação de não disparo gerada com sucesso.",
        },
        404: {"description": "Avaliação não encontrada com o UUID fornecido."},
        503: {"description": "Service Unavailable: Motor Drools inacessível."},
    },
)
async def explicar_porque_nao(
    id: str = Path(..., description="UUID da avaliação pericial"),
    conclusao: Optional[str] = Query(
        None,
        description="Conclusão pretendida que não se verificou (ex.: OUT-001:PERMITIR)",
        examples=["OUT-001:PERMITIR"],
    ),
    regra: Optional[str] = Query(
        None, description="Código da regra que não disparou (ex.: PT-003)", examples=["PT-003"]
    ),
    artigo: Optional[str] = Query(
        None, description="Identificador do artigo alvo (ex.: A-1)"
    ),
    locale: Optional[str] = Query(None, description="Tag de idioma"),
    levis_service: LevisService = Depends(get_levis_service),
) -> Union[ExplicacaoPorqueNaoConclusaoResponse, ExplicacaoPorqueNaoResponse]:
    """Explain why a conclusion was not reached or why a candidate rule did not trigger."""
    try:
        return await levis_service.explain_why_not(
            evaluation_id=id,
            conclusao=conclusao,
            regra=regra,
            artigo=artigo,
            locale=locale,
        )
    except Exception as exc:
        _handle_levis_exception(exc)


# ==============================================================================
# 4. SIMULAÇÃO CONTRAFACTUAL: E SE?
# ==============================================================================


@router.post(
    "/avaliacoes/{id}/simulacoes",
    response_model=SimulacaoResponse,
    status_code=status.HTTP_200_OK,
    summary="Simular variações no pedido original sem persistir alterações (E se?)",
    description=(
        "Executa uma análise contrafactual (What If) aplicando um mapa de alterações sobre "
        "os factos da avaliação original, devolvendo o delta de regras acionadas e a nova decisão."
    ),
    responses={
        200: {
            "description": "Simulação concluída com sucesso com o delta de alterações.",
            "model": SimulacaoResponse,
        },
        404: {"description": "Avaliação de base não encontrada."},
        503: {"description": "Service Unavailable: Motor Drools inacessível."},
    },
)
async def simular(
    id: str = Path(..., description="UUID da avaliação pericial base"),
    payload: SimulacaoRequest = Body(
        ...,
        examples=[{"alteracoes": {"portalOnlineDisponivel": True}}],
    ),
    locale: Optional[str] = Query(None, description="Tag de idioma"),
    levis_service: LevisService = Depends(get_levis_service),
) -> SimulacaoResponse:
    """Execute hypothetical simulation of modified order facts."""
    try:
        return await levis_service.simulate(
            evaluation_id=id, request=payload, locale=locale
        )
    except Exception as exc:
        _handle_levis_exception(exc)


# ==============================================================================
# 5. CATÁLOGO DE REGRAS DA BASE DE CONHECIMENTO
# ==============================================================================


@router.get(
    "/regras",
    response_model=List[RegraResumoDto],
    status_code=status.HTTP_200_OK,
    summary="Listar regras ativas na base de conhecimento",
    description="Devolve o catálogo com o resumo de todas as regras do perito carregadas no KieBase Drools.",
    responses={
        200: {
            "description": "Catálogo de regras obtido com sucesso.",
            "model": List[RegraResumoDto],
        },
        503: {"description": "Service Unavailable: Motor Drools inacessível."},
    },
)
async def listar_regras(
    levis_service: LevisService = Depends(get_levis_service),
) -> List[RegraResumoDto]:
    """List summary catalog of expert business rules."""
    try:
        return await levis_service.list_rules()
    except Exception as exc:
        _handle_levis_exception(exc)


@router.get(
    "/regras/{codigo}",
    response_model=RegraDetalheDto,
    status_code=status.HTTP_200_OK,
    summary="Consultar detalhe e variantes DRL de uma regra pericial",
    description=(
        "Devolve a especificação integral de uma regra por código (ex.: PT-003, PC-002), "
        "incluindo todas as variantes de produção DRL com premissas LHS e ações RHS."
    ),
    responses={
        200: {
            "description": "Detalhes da regra encontrados.",
            "model": RegraDetalheDto,
        },
        404: {"description": "Regra não encontrada com o código indicado."},
        503: {"description": "Service Unavailable: Motor Drools inacessível."},
    },
)
async def obter_regra(
    codigo: str = Path(
        ...,
        description="Código identificador da regra (ex.: PT-003, PC-002)",
        examples=["PT-003"],
    ),
    levis_service: LevisService = Depends(get_levis_service),
) -> RegraDetalheDto:
    """Get rule specifications and concrete DRL variants."""
    try:
        return await levis_service.get_rule_detail(codigo)
    except Exception as exc:
        _handle_levis_exception(exc)


# ==============================================================================
# 6. CENÁRIOS OFICIAIS DE TESTE DA LEVI'S
# ==============================================================================


@router.get(
    "/cenarios-exemplo",
    response_model=List[CenarioExemploResponse],
    status_code=status.HTTP_200_OK,
    summary="Listar os 10 cenários oficiais de teste da Levi's",
    description=(
        "Carrega os 10 cenários oficiais de validação do retalho Levi's, "
        "com premissas, justificações periciais e payload completo pronto para avaliação."
    ),
    responses={
        200: {
            "description": "Lista com os 10 cenários oficiais de teste.",
            "model": List[CenarioExemploResponse],
        },
    },
)
async def listar_cenarios_exemplo(
    levis_service: LevisService = Depends(get_levis_service),
) -> List[CenarioExemploResponse]:
    """Retrieve all 10 official Levi's test scenarios."""
    return levis_service.get_example_scenarios()


@router.get(
    "/cenarios-exemplo/{id}",
    response_model=CenarioExemploResponse,
    status_code=status.HTTP_200_OK,
    summary="Obter um cenário oficial de teste por ID (1 a 10)",
    description="Devolve o conteúdo e payload de um cenário específico da suíte oficial.",
    responses={
        200: {
            "description": "Cenário de teste encontrado.",
            "model": CenarioExemploResponse,
        },
        404: {"description": "Cenário não encontrado com o ID especificado."},
    },
)
async def obter_cenario_exemplo(
    id: int = Path(..., ge=1, le=10, description="Número ordinal do cenário (1 a 10)"),
    levis_service: LevisService = Depends(get_levis_service),
) -> CenarioExemploResponse:
    """Retrieve an official Levi's scenario by ID."""
    sc = levis_service.get_example_scenario_by_id(id)
    if sc is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cenário oficial #{id} não foi encontrado.",
        )
    return sc


# ==============================================================================
# 7. PERFIS DE DESENVOLVIMENTO & SAÚDE OPERACIONAL
# ==============================================================================


@router.get(
    "/colaboradores-dev",
    response_model=List[ColaboradorDto],
    status_code=status.HTTP_200_OK,
    summary="Listar perfis de colaboradores disponíveis no modo dev",
    description="Permite inspecionar os colaboradores pré-configurados de teste (ex.: Key Holder, Store Manager).",
    responses={
        200: {
            "description": "Lista de colaboradores para testes em modo dev.",
            "model": List[ColaboradorDto],
        },
        503: {"description": "Service Unavailable: Motor Drools inacessível."},
    },
)
async def listar_colaboradores_dev(
    levis_service: LevisService = Depends(get_levis_service),
) -> List[ColaboradorDto]:
    """List development collaborator test profiles."""
    try:
        return await levis_service.list_dev_collaborators()
    except Exception as exc:
        _handle_levis_exception(exc)


@router.get(
    "/health",
    status_code=status.HTTP_200_OK,
    summary="Verificar estado de saúde do motor Drools Levi's",
    description="Inspeciona a prontidão e disponibilidade operacional do microserviço Drools.",
    responses={
        200: {"description": "Motor Drools operacional (status: UP)."},
        503: {"description": "Motor Drools inacessível."},
    },
)
async def verificar_saude_levis(
    levis_service: LevisService = Depends(get_levis_service),
) -> Dict[str, Any]:
    """Check Drools microservice health status."""
    try:
        return await levis_service.get_health()
    except Exception as exc:
        _handle_levis_exception(exc)
