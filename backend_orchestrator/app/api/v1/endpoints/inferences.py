"""FastAPI endpoints for unified inferences history and multi-engine comparison."""

from __future__ import annotations

import logging
from typing import Any, Dict, Optional
from uuid import UUID

from fastapi import APIRouter, Body, Depends, HTTPException, Path, Query, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_inferences_service
from app.db.seed import seed_scenarios
from app.schemas.inference_record import (
    AvaliarAmbosResponse,
    ComparacaoMotoresResponse,
    InferenciaDetalheResponse,
    InferenciaItem,
    SeedResponse,
)
from app.schemas.levis import PaginaResponse
from app.services.inferences_service import InferencesService

logger = logging.getLogger(__name__)

router = APIRouter(
    tags=["Avaliações e Histórico Unificado de Inferências"],
)


@router.get(
    "/avaliacoes",
    response_model=PaginaResponse[InferenciaItem],
    status_code=status.HTTP_200_OK,
    summary="Listar histórico de avaliações periciais (Drools e Prolog)",
    description=(
        "Recupera o histórico persistido de inferências deliberadas por qualquer motor. "
        "Suporta paginação dinâmica, filtros por motor (DROOLS ou PROLOG), elegibilidade e ID do caso. "
        "Calcula o indicador 'temOutroMotor' para viabilizar a comparação de motores no dashboard."
    ),
    responses={
        200: {
            "description": "Página com registos de inferências.",
            "model": PaginaResponse[InferenciaItem],
        },
    },
)
async def listar_avaliacoes(
    motor: Optional[str] = Query(None, description="Filtrar por motor: 'DROOLS' ou 'PROLOG'"),
    pedido_id: Optional[str] = Query(None, description="Filtrar por identificador de pedido ou cenário"),
    elegibilidade: Optional[str] = Query(None, description="Filtrar por elegibilidade (PERMITIR, RECUSAR, etc.)"),
    tipo_transacao: Optional[str] = Query(None, description="Filtrar por tipo de transação (REEMBOLSO, TROCA, etc.)"),
    filtro_tipo: Optional[str] = Query(None, description="Filtro rápido do painel: TODOS, DEVOLUCOES ou TROCAS"),
    busca: Optional[str] = Query(None, description="Pesquisar por pedido, produto ou referência"),
    pagina: int = Query(0, ge=0, description="Índice da página (0-indexed)"),
    tamanho: int = Query(20, ge=1, le=100, description="Quantidade de registos por página"),
    session: AsyncSession = Depends(get_db),
    inferences_service: InferencesService = Depends(get_inferences_service),
) -> PaginaResponse[InferenciaItem]:
    """Return paginated list of unified inference records."""
    return await inferences_service.list_inferences(
        session=session,
        motor=motor,
        pedido_id=pedido_id,
        elegibilidade=elegibilidade,
        tipo_transacao=tipo_transacao,
        filtro_tipo=filtro_tipo,
        busca=busca,
        pagina=pagina,
        tamanho=tamanho,
    )


@router.get(
    "/avaliacoes/comparacao/{pedido_id}",
    response_model=ComparacaoMotoresResponse,
    status_code=status.HTTP_200_OK,
    summary="Matriz comparativa de motores para um caso específico (Drools vs Prolog)",
    description=(
        "Compara as deliberações mais recentes do Drools e do Prolog para o mesmo pedido/cenário. "
        "Avalia consenso sobre elegibilidade, tipo de transação, valor e meio de reembolso, "
        "e calcula o rácio de velocidade relativa entre motores."
    ),
    responses={
        200: {
            "description": "Matriz comparativa com consenso, divergências e latências.",
            "model": ComparacaoMotoresResponse,
        },
        404: {"description": "Nenhuma avaliação encontrada para o pedido especificado."},
    },
)
async def obter_comparacao_motores(
    pedido_id: str = Path(..., description="Identificador do pedido ou cenário (ex.: CENARIO-01 ou RF-8924)"),
    session: AsyncSession = Depends(get_db),
    inferences_service: InferencesService = Depends(get_inferences_service),
) -> ComparacaoMotoresResponse:
    """Retrieve side-by-side comparison matrix for a return case."""
    comp = await inferences_service.get_comparison_by_pedido_id(pedido_id=pedido_id, session=session)
    if not comp:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Nenhuma avaliação encontrada para o pedido '{pedido_id}'.",
        )
    return comp


@router.get(
    "/avaliacoes/{id}",
    response_model=InferenciaDetalheResponse,
    status_code=status.HTTP_200_OK,
    summary="Obter detalhe integral de uma avaliação por ID",
    description="Recupera o registo completo de uma inferência, incluindo factos de entrada e payload canónico de decisão.",
    responses={
        200: {
            "description": "Detalhe da inferência com rastreio de regras e dados completos.",
            "model": InferenciaDetalheResponse,
        },
        404: {"description": "Avaliação não encontrada."},
    },
)
async def obter_avaliacao_por_id(
    id: UUID = Path(..., description="UUID da inferência persistida"),
    session: AsyncSession = Depends(get_db),
    inferences_service: InferencesService = Depends(get_inferences_service),
) -> InferenciaDetalheResponse:
    """Retrieve full details of an inference record."""
    detalhe = await inferences_service.get_inference_by_id(id=id, session=session)
    if not detalhe:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Avaliação com ID '{id}' não foi encontrada.",
        )
    return detalhe


@router.post(
    "/avaliar-ambos",
    response_model=AvaliarAmbosResponse,
    status_code=status.HTTP_200_OK,
    summary="Avaliação simultânea e paralela em ambos os motores (Drools + Prolog)",
    description=(
        "Executa o pedido concorrentemente nos motores Drools e Prolog via asyncio.gather. "
        "Persiste ambos os vereditos de forma resiliente e retorna o confronto com análise de consenso."
    ),
    responses={
        200: {
            "description": "Avaliação simultânea concluída com ambas as deliberações.",
            "model": AvaliarAmbosResponse,
        },
        502: {"description": "Ambos os motores falharam na deliberação."},
    },
)
@router.post(
    "/avaliacoes/avaliar-ambos",
    response_model=AvaliarAmbosResponse,
    status_code=status.HTTP_200_OK,
    include_in_schema=False,
)
async def avaliar_ambos(
    payload: Dict[str, Any] = Body(..., description="Payload do pedido de devolução ou cenário de teste"),
    session: AsyncSession = Depends(get_db),
    inferences_service: InferencesService = Depends(get_inferences_service),
) -> AvaliarAmbosResponse:
    """Evaluate return scenario on Drools and Prolog simultaneously."""
    return await inferences_service.evaluate_both(payload=payload, session=session)


@router.post(
    "/avaliacoes/seed",
    response_model=SeedResponse,
    status_code=status.HTTP_200_OK,
    summary="Semear avaliações reais dos 10 cenários oficiais em ambos os motores",
    description=(
        "Executa e persiste de forma idempotente as avaliações dos 10 cenários de teste oficiais da Levi's "
        "no Drools e no Prolog. Se force=True, limpa os registos existentes e reavalia do início."
    ),
    responses={
        200: {
            "description": "Relatório de conclusão da semeadura.",
            "model": SeedResponse,
        },
    },
)
@router.post(
    "/inferences/seed",
    response_model=SeedResponse,
    status_code=status.HTTP_200_OK,
    include_in_schema=False,
)
async def semear_cenarios_oficiais(
    request: Request,
    force: bool = Query(False, description="Forçar nova execução e substituição dos registos existentes"),
    session: AsyncSession = Depends(get_db),
) -> SeedResponse:
    """Seed the database with real inference runs of the 10 Levi's reference scenarios."""
    levis_service = getattr(request.app.state, "levis_service", None)
    retail_service = getattr(request.app.state, "retail_prolog_service", None)
    return await seed_scenarios(
        force=force,
        session=session,
        levis_service=levis_service,
        retail_service=retail_service,
    )
