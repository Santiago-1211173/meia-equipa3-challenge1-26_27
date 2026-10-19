"""Database seeding module for official Levi's test scenarios (Drools and Prolog)."""

from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional, Set

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.clients.levis_client import LevisClient
from app.clients.prolog_client import PrologClient
from app.db.models import HistoricoInferencia
from app.db.session import async_session_factory
from app.schemas.inference_record import SeedCenarioItem, SeedResponse
from app.services.levis_service import LevisService
from app.services.retail_prolog_service import RetailPrologService

logger = logging.getLogger(__name__)


async def seed_scenarios(
    force: bool = False,
    session: Optional[AsyncSession] = None,
    levis_service: Optional[LevisService] = None,
    retail_service: Optional[RetailPrologService] = None,
) -> SeedResponse:
    """Idempotently seed evaluations for all 10 official Levi's scenarios in both engines.

    Args:
        force: If True, clears existing records for the scenarios and forces re-evaluation.
        session: Optional SQLAlchemy AsyncSession.
        levis_service: Optional LevisService instance.
        retail_service: Optional RetailPrologService instance.

    Returns:
        SeedResponse summary with execution statistics and scenario details.
    """
    logger.info("[DB Seed] Starting scenario seeding (force=%s)...", force)

    # Initialize services if not injected
    if not levis_service:
        levis_service = LevisService(levis_client=LevisClient())
    if not retail_service:
        retail_service = RetailPrologService(
            prolog_client=PrologClient(),
            levis_service=levis_service,
        )

    scenarios = levis_service.get_example_scenarios()
    if not scenarios:
        logger.warning("[DB Seed] No Levi's test scenarios found to seed.")
        return SeedResponse(
            status="sem_cenarios",
            totalCenarios=0,
            cenariosProcessados=0,
            cenariosSaltados=0,
            executadosDrools=0,
            executadosProlog=0,
            erros=["Nenhum ficheiro de cenário oficial encontrado para semear."],
            detalhes=[],
        )

    if session is not None:
        return await _execute_seed(
            scenarios=scenarios,
            force=force,
            session=session,
            levis_service=levis_service,
            retail_service=retail_service,
        )
    else:
        async with async_session_factory() as local_session:
            return await _execute_seed(
                scenarios=scenarios,
                force=force,
                session=local_session,
                levis_service=levis_service,
                retail_service=retail_service,
            )


async def _execute_seed(
    scenarios: List[Any],
    force: bool,
    session: AsyncSession,
    levis_service: LevisService,
    retail_service: RetailPrologService,
) -> SeedResponse:
    """Core seeding execution loop."""
    detalhes: List[SeedCenarioItem] = []
    erros: List[str] = []
    processados_count = 0
    saltados_count = 0
    executados_drools = 0
    executados_prolog = 0

    canonical_ids = [f"CENARIO-{sc.id:02d}" for sc in scenarios]
    alt_ids = [f"C{sc.id:02d}" for sc in scenarios]

    if force:
        logger.info("[DB Seed] Force mode enabled. Purging existing scenario records...")
        await session.execute(
            delete(HistoricoInferencia).where(
                HistoricoInferencia.pedido_id.in_(canonical_ids + alt_ids)
            )
        )
        await session.commit()
        existing_map: Dict[str, Set[str]] = {}
    else:
        stmt_existing = (
            select(HistoricoInferencia.pedido_id, HistoricoInferencia.motor)
            .where(HistoricoInferencia.pedido_id.in_(canonical_ids))
        )
        existing_rows = (await session.execute(stmt_existing)).all()
        existing_map: Dict[str, Set[str]] = {}
        for pid, mot in existing_rows:
            existing_map.setdefault(pid, set()).add(mot.upper())

    for sc in scenarios:
        pedido_id = f"CENARIO-{sc.id:02d}"
        existing_motors = existing_map.get(pedido_id, set())

        # Check idempotency: if both engines already exist and not force, skip
        if not force and "DROOLS" in existing_motors and "PROLOG" in existing_motors:
            saltados_count += 1
            detalhes.append(
                SeedCenarioItem(
                    cenarioId=sc.id,
                    pedidoId=pedido_id,
                    titulo=sc.titulo,
                    droolsStatus="saltado",
                    prologStatus="saltado",
                )
            )
            continue

        pedido_dict = sc.pedido.model_dump(mode="json")
        pedido_dict["id"] = pedido_id

        drools_status = "saltado" if "DROOLS" in existing_motors else "pendente"
        prolog_status = "saltado" if "PROLOG" in existing_motors else "pendente"
        drools_eleg = None
        prolog_eleg = None
        cenario_erro: Optional[str] = None
        ran_any = False

        # 1. Execute Drools
        if "DROOLS" not in existing_motors or force:
            try:
                logger.info("[DB Seed] Evaluating scenario %s on Drools...", pedido_id)
                drools_dec = await levis_service.evaluate(pedido_dict)
                raw_eleg = getattr(drools_dec, "elegibilidade", None)
                drools_eleg = raw_eleg.value if hasattr(raw_eleg, "value") else str(raw_eleg or "DESCONHECIDO")
                drools_status = "executado"
                executados_drools += 1
                ran_any = True
            except Exception as exc:
                drools_status = "erro"
                msg = f"{pedido_id} (Drools): {exc}"
                erros.append(msg)
                cenario_erro = msg
                logger.error("[DB Seed] Failed Drools evaluation for %s: %s", pedido_id, exc)

        # 2. Execute Prolog
        if "PROLOG" not in existing_motors or force:
            prolog_payload = {
                "id": sc.id,
                "pedido": pedido_dict,
                "pressupostos": sc.pressupostos,
            }
            try:
                logger.info("[DB Seed] Evaluating scenario %s on Prolog...", pedido_id)
                prolog_dec = await retail_service.evaluate_return(prolog_payload)
                raw_eleg = getattr(prolog_dec, "elegibilidade", None)
                prolog_eleg = raw_eleg.value if hasattr(raw_eleg, "value") else str(raw_eleg or "DESCONHECIDO")
                prolog_status = "executado"
                executados_prolog += 1
                ran_any = True
            except Exception as exc:
                prolog_status = "erro"
                msg = f"{pedido_id} (Prolog): {exc}"
                erros.append(msg)
                cenario_erro = f"{cenario_erro} | {msg}" if cenario_erro else msg
                logger.error("[DB Seed] Failed Prolog evaluation for %s: %s", pedido_id, exc)

        if ran_any:
            processados_count += 1

        detalhes.append(
            SeedCenarioItem(
                cenarioId=sc.id,
                pedidoId=pedido_id,
                titulo=sc.titulo,
                droolsStatus=drools_status,
                prologStatus=prolog_status,
                droolsElegibilidade=drools_eleg,
                prologElegibilidade=prolog_eleg,
                erro=cenario_erro,
            )
        )

    logger.info(
        "[DB Seed] Seeding finished. Processed: %d, Skipped: %d, Drools: %d, Prolog: %d, Errors: %d",
        processados_count,
        saltados_count,
        executados_drools,
        executados_prolog,
        len(erros),
    )

    return SeedResponse(
        status="concluido" if not erros else "concluido_com_avisos",
        totalCenarios=len(scenarios),
        cenariosProcessados=processados_count,
        cenariosSaltados=saltados_count,
        executadosDrools=executados_drools,
        executadosProlog=executados_prolog,
        erros=erros,
        detalhes=detalhes,
    )
