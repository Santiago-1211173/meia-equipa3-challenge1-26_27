"""Service coordinating unified inferences persistence, comparative reasoning, and multi-engine execution."""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone
from decimal import Decimal
import json
import logging
import math
import time
from typing import TYPE_CHECKING, Any, Dict, List, Optional, Set, Tuple
from uuid import UUID, uuid4

from fastapi import HTTPException, status
from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import HistoricoInferencia
from app.db.session import async_session_factory
from app.schemas.inference_record import (
    AvaliarAmbosResponse,
    ComparacaoMotoresResponse,
    InferenciaDetalheResponse,
    InferenciaItem,
    RegraItemDto,
)
from app.schemas.levis import DecisaoResponse, PaginaResponse

if TYPE_CHECKING:
    from app.services.levis_service import LevisService
    from app.services.retail_prolog_service import RetailPrologService

logger = logging.getLogger(__name__)


def _extract_product_info(pedido_data: Any) -> Tuple[str, Optional[str]]:
    """Extract (produto_nome, produto_ref) from input pedido payload."""
    data = pedido_data
    if hasattr(pedido_data, "model_dump"):
        data = pedido_data.model_dump()
    elif not isinstance(data, dict):
        return ("Artigo Levi's", None)

    if "pedido" in data and isinstance(data["pedido"], dict):
        data = data["pedido"]

    artigos = data.get("artigos")
    if isinstance(artigos, list) and len(artigos) > 0:
        first_art = artigos[0]
        if isinstance(first_art, dict):
            prod = first_art.get("produto") or {}
            sku = prod.get("sku") or first_art.get("sku") or first_art.get("id")
            marca = prod.get("marca") or "Levi's"
            cat = prod.get("categoria") or "Vestuário"
            nome = prod.get("nome") or prod.get("descricao")
            if not nome:
                if sku:
                    nome = f"{marca} {sku}"
                else:
                    nome = f"{marca} {cat}"
            return (str(nome), str(sku) if sku else None)

    return ("Artigo Levi's", None)


def _extract_pedido_id(decisao: Any, pedido_data: Any) -> str:
    """Extract canonical pedido_id string."""
    if hasattr(decisao, "pedidoId") and decisao.pedidoId:
        return str(decisao.pedidoId)
    if isinstance(decisao, dict) and decisao.get("pedidoId"):
        return str(decisao["pedidoId"])

    data = pedido_data
    if hasattr(pedido_data, "model_dump"):
        data = pedido_data.model_dump()
    if isinstance(data, dict):
        if "pedido" in data and isinstance(data["pedido"], dict):
            pid = data["pedido"].get("id") or data.get("id")
            if pid:
                return str(pid)
        if data.get("id"):
            return str(data["id"])
        if data.get("pedidoId"):
            return str(data["pedidoId"])

    return f"PED-{uuid4().hex[:6].upper()}"


def _extract_regras(decisao: Any) -> List[Dict[str, Any]]:
    """Extract unified rule trace items from a decision."""
    regras: List[Dict[str, Any]] = []
    raw_regras = getattr(decisao, "regras", []) if hasattr(decisao, "regras") else []
    if not raw_regras and isinstance(decisao, dict):
        raw_regras = decisao.get("regras") or []

    for r in raw_regras:
        if isinstance(r, dict):
            regras.append({
                "codigo": str(r.get("codigoRegra") or r.get("codigo") or "REGRA"),
                "nome": r.get("nomeRegra") or r.get("nome"),
                "modulo": r.get("modulo"),
                "mensagem": r.get("mensagem"),
                "resultado": str(r.get("resultado") or ""),
            })
        else:
            codigo = getattr(r, "codigoRegra", None) or getattr(r, "codigo", None) or "REGRA"
            nome = getattr(r, "nomeRegra", None) or getattr(r, "nome", None)
            modulo = getattr(r, "modulo", None)
            mensagem = getattr(r, "mensagem", None)
            res = getattr(r, "resultado", None)
            resultado_str = res.value if hasattr(res, "value") else str(res or "")
            regras.append({
                "codigo": str(codigo),
                "nome": str(nome) if nome else None,
                "modulo": str(modulo) if modulo else None,
                "mensagem": str(mensagem) if mensagem else None,
                "resultado": resultado_str if resultado_str else None,
            })
    return regras


def _to_item(rec: HistoricoInferencia, tem_outro_motor: bool = False) -> InferenciaItem:
    """Map SQLAlchemy HistoricoInferencia to Pydantic InferenciaItem."""
    regras = [
        RegraItemDto(
            codigo=r.get("codigo") or "REGRA",
            nome=r.get("nome"),
            modulo=r.get("modulo"),
            mensagem=r.get("mensagem"),
            resultado=r.get("resultado"),
        )
        if isinstance(r, dict)
        else RegraItemDto(codigo=str(r))
        for r in (rec.regras_disparadas or [])
    ]

    return InferenciaItem(
        id=rec.id,
        pedidoId=rec.pedido_id,
        motor=rec.motor,
        motorVersao=rec.motor_versao,
        produtoNome=rec.produto_nome,
        produtoRef=rec.produto_ref,
        valorDevolucao=float(rec.valor_devolucao or 0.0),
        elegibilidade=rec.elegibilidade,
        tipoTransacao=rec.tipo_transacao,
        meioReembolso=rec.meio_reembolso,
        nivelAprovacao=rec.nivel_aprovacao,
        executadoEm=rec.executado_em,
        duracaoMs=rec.duracao_ms,
        regrasDisparadas=regras,
        temOutroMotor=tem_outro_motor,
    )


class InferencesService:
    """Business service orchestrating inference persistence and multi-engine comparisons."""

    def __init__(
        self,
        levis_service: Optional[LevisService] = None,
        retail_service: Optional[RetailPrologService] = None,
    ) -> None:
        self.levis_service = levis_service
        self.retail_service = retail_service

    @staticmethod
    async def record_inference_safely(
        motor: str,
        decisao: Any,
        pedido_data: Any,
        duracao_ms: int = 0,
        session: Optional[AsyncSession] = None,
        motor_versao: Optional[str] = None,
        produto_nome: Optional[str] = None,
        produto_ref: Optional[str] = None,
    ) -> Optional[HistoricoInferencia]:
        """Safely persist an inference execution to PostgreSQL without raising exceptions on failure."""
        try:
            pedido_id = _extract_pedido_id(decisao, pedido_data)
            extracted_nome, extracted_ref = _extract_product_info(pedido_data)
            final_nome = produto_nome or extracted_nome
            final_ref = produto_ref or extracted_ref

            # Elegibilidade
            raw_eleg = getattr(decisao, "elegibilidade", None) if hasattr(decisao, "elegibilidade") else None
            if raw_eleg is None and isinstance(decisao, dict):
                raw_eleg = decisao.get("elegibilidade")
            eleg_str = raw_eleg.value if hasattr(raw_eleg, "value") else str(raw_eleg or "REVER")

            # Tipo transação
            raw_tipo = getattr(decisao, "tipoTransacao", None) if hasattr(decisao, "tipoTransacao") else None
            if raw_tipo is None and isinstance(decisao, dict):
                raw_tipo = decisao.get("tipoTransacao")
            tipo_str = raw_tipo.value if hasattr(raw_tipo, "value") else (str(raw_tipo) if raw_tipo else None)

            # Meio reembolso
            raw_meio = getattr(decisao, "meioReembolso", None) if hasattr(decisao, "meioReembolso") else None
            if raw_meio is None and isinstance(decisao, dict):
                raw_meio = decisao.get("meioReembolso")
            meio_str = raw_meio.value if hasattr(raw_meio, "value") else (str(raw_meio) if raw_meio else None)

            # Nível aprovação
            raw_aprov = getattr(decisao, "aprovacao", None) if hasattr(decisao, "aprovacao") else None
            if raw_aprov is None and isinstance(decisao, dict):
                raw_aprov = decisao.get("aprovacao")
            aprov_str = raw_aprov.value if hasattr(raw_aprov, "value") else (str(raw_aprov) if raw_aprov else None)

            # Valor devolução
            raw_val = getattr(decisao, "valorDevolucao", 0.0) if hasattr(decisao, "valorDevolucao") else 0.0
            if raw_val is None and isinstance(decisao, dict):
                raw_val = decisao.get("valorDevolucao", 0.0)
            try:
                val_dec = Decimal(str(round(float(raw_val or 0.0), 2)))
            except Exception:
                val_dec = Decimal("0.00")

            # JSON dumps
            if hasattr(pedido_data, "model_dump"):
                input_json = pedido_data.model_dump(mode="json")
            elif isinstance(pedido_data, dict):
                input_json = json.loads(json.dumps(pedido_data, default=str))
            else:
                input_json = {}

            if hasattr(decisao, "model_dump"):
                decisao_dict = decisao.model_dump(mode="json")
            elif isinstance(decisao, dict):
                decisao_dict = json.loads(json.dumps(decisao, default=str))
            else:
                decisao_dict = {}

            # UUID
            rec_id = None
            if hasattr(decisao, "avaliacaoId") and decisao.avaliacaoId:
                rec_id = decisao.avaliacaoId if isinstance(decisao.avaliacaoId, UUID) else UUID(str(decisao.avaliacaoId))
            elif isinstance(decisao, dict) and decisao.get("avaliacaoId"):
                rec_id = UUID(str(decisao["avaliacaoId"]))
            if not rec_id:
                rec_id = uuid4()

            # Version
            v_kjar = getattr(decisao, "versaoBaseConhecimento", None) if hasattr(decisao, "versaoBaseConhecimento") else None
            final_version = motor_versao or v_kjar or ("Drools 8.44.0" if motor.upper() == "DROOLS" else "SWI-Prolog 9.x")

            regras_list = _extract_regras(decisao)

            exec_time = getattr(decisao, "avaliadaEm", None) if hasattr(decisao, "avaliadaEm") else None
            if not exec_time and isinstance(decisao, dict):
                exec_time = decisao.get("avaliadaEm")
            if isinstance(exec_time, str):
                try:
                    exec_time = datetime.fromisoformat(exec_time)
                except Exception:
                    exec_time = datetime.now(timezone.utc)
            if not exec_time:
                exec_time = datetime.now(timezone.utc)

            record = HistoricoInferencia(
                id=rec_id,
                pedido_id=str(pedido_id),
                motor=motor.upper(),
                motor_versao=str(final_version),
                produto_nome=str(final_nome),
                produto_ref=str(final_ref) if final_ref else None,
                valor_devolucao=val_dec,
                elegibilidade=str(eleg_str),
                tipo_transacao=tipo_str,
                meio_reembolso=meio_str,
                nivel_aprovacao=aprov_str,
                regras_disparadas=regras_list,
                input_pedido_json=input_json,
                decisao_json=decisao_dict,
                duracao_ms=duracao_ms,
                executado_em=exec_time,
            )

            if session:
                session.add(record)
                await session.commit()
                await session.refresh(record)
                return record
            else:
                async with async_session_factory() as local_session:
                    local_session.add(record)
                    await local_session.commit()
                    await local_session.refresh(record)
                    return record

        except Exception as exc:
            logger.warning("[InferencesService] Could not persist inference for %s (%s): %s", pedido_data, motor, exc)
            return None

    async def list_inferences(
        self,
        session: AsyncSession,
        motor: Optional[str] = None,
        pedido_id: Optional[str] = None,
        elegibilidade: Optional[str] = None,
        tipo_transacao: Optional[str] = None,
        filtro_tipo: Optional[str] = None,
        busca: Optional[str] = None,
        pagina: int = 0,
        tamanho: int = 20,
    ) -> PaginaResponse[InferenciaItem]:
        """Query unified inference history with filtering and pagination."""
        # Base count statement
        stmt_count = select(func.count(HistoricoInferencia.id))
        stmt_data = select(HistoricoInferencia).order_by(HistoricoInferencia.executado_em.desc())

        # Filters
        if motor:
            m_clean = motor.strip().upper()
            stmt_count = stmt_count.where(HistoricoInferencia.motor == m_clean)
            stmt_data = stmt_data.where(HistoricoInferencia.motor == m_clean)

        if pedido_id:
            p_clean = pedido_id.strip()
            stmt_count = stmt_count.where(HistoricoInferencia.pedido_id == p_clean)
            stmt_data = stmt_data.where(HistoricoInferencia.pedido_id == p_clean)

        if elegibilidade:
            e_clean = elegibilidade.strip().upper()
            stmt_count = stmt_count.where(HistoricoInferencia.elegibilidade == e_clean)
            stmt_data = stmt_data.where(HistoricoInferencia.elegibilidade == e_clean)

        if tipo_transacao:
            t_clean = tipo_transacao.strip().upper()
            stmt_count = stmt_count.where(HistoricoInferencia.tipo_transacao == t_clean)
            stmt_data = stmt_data.where(HistoricoInferencia.tipo_transacao == t_clean)

        if filtro_tipo:
            ft = filtro_tipo.strip().upper()
            if ft == "TROCAS":
                cond = or_(
                    HistoricoInferencia.tipo_transacao == "TROCA",
                    HistoricoInferencia.elegibilidade == "TROCA",
                )
                stmt_count = stmt_count.where(cond)
                stmt_data = stmt_data.where(cond)
            elif ft == "DEVOLUCOES":
                cond = or_(
                    HistoricoInferencia.tipo_transacao.in_(["REEMBOLSO", "CREDITO_LOJA", "NENHUMA"]),
                    and_(HistoricoInferencia.tipo_transacao.is_(None), HistoricoInferencia.elegibilidade != "TROCA"),
                )
                stmt_count = stmt_count.where(cond)
                stmt_data = stmt_data.where(cond)

        if busca and busca.strip():
            q = f"%{busca.strip()}%"
            cond_busca = or_(
                HistoricoInferencia.pedido_id.ilike(q),
                HistoricoInferencia.produto_nome.ilike(q),
                HistoricoInferencia.produto_ref.ilike(q),
            )
            stmt_count = stmt_count.where(cond_busca)
            stmt_data = stmt_data.where(cond_busca)

        total_elementos = (await session.execute(stmt_count)).scalar() or 0

        # Pagination
        offset = max(0, pagina) * max(1, tamanho)
        stmt_data = stmt_data.offset(offset).limit(max(1, tamanho))
        records = (await session.execute(stmt_data)).scalars().all()

        # Compute temOutroMotor for items on this page
        distinct_pedidos = list({r.pedido_id for r in records})
        pedidos_motores: Dict[str, Set[str]] = {}
        if distinct_pedidos:
            stmt_other = (
                select(HistoricoInferencia.pedido_id, HistoricoInferencia.motor)
                .where(HistoricoInferencia.pedido_id.in_(distinct_pedidos))
                .distinct()
            )
            pairs = (await session.execute(stmt_other)).all()
            for pid, mot in pairs:
                if pid not in pedidos_motores:
                    pedidos_motores[pid] = set()
                pedidos_motores[pid].add(mot)

        items: List[InferenciaItem] = []
        for r in records:
            engines_for_pedido = pedidos_motores.get(r.pedido_id, set())
            tem_outro = len(engines_for_pedido - {r.motor}) > 0
            items.append(_to_item(r, tem_outro_motor=tem_outro))

        total_paginas = math.ceil(total_elementos / tamanho) if tamanho > 0 else 0

        return PaginaResponse[InferenciaItem](
            conteudo=items,
            pagina=pagina,
            tamanho=tamanho,
            totalElementos=total_elementos,
            totalPaginas=total_paginas,
        )

    async def get_inference_by_id(
        self,
        id: UUID,
        session: AsyncSession,
    ) -> Optional[InferenciaDetalheResponse]:
        """Retrieve full details of an inference by UUID."""
        record = await session.get(HistoricoInferencia, id)
        if not record:
            return None

        stmt_other = (
            select(HistoricoInferencia.motor)
            .where(HistoricoInferencia.pedido_id == record.pedido_id, HistoricoInferencia.motor != record.motor)
            .limit(1)
        )
        tem_outro = bool((await session.execute(stmt_other)).scalar())

        item = _to_item(record, tem_outro_motor=tem_outro)
        return InferenciaDetalheResponse(
            **item.model_dump(),
            inputPedidoJson=record.input_pedido_json or {},
            decisaoJson=record.decisao_json or {},
        )

    async def get_comparison_by_pedido_id(
        self,
        pedido_id: str,
        session: AsyncSession,
    ) -> Optional[ComparacaoMotoresResponse]:
        """Build comparative consensus matrix for a case evaluated by Drools and/or Prolog."""
        stmt_d = (
            select(HistoricoInferencia)
            .where(HistoricoInferencia.pedido_id == pedido_id, HistoricoInferencia.motor == "DROOLS")
            .order_by(HistoricoInferencia.executado_em.desc())
            .limit(1)
        )
        stmt_p = (
            select(HistoricoInferencia)
            .where(HistoricoInferencia.pedido_id == pedido_id, HistoricoInferencia.motor == "PROLOG")
            .order_by(HistoricoInferencia.executado_em.desc())
            .limit(1)
        )

        drools_rec = (await session.execute(stmt_d)).scalar_one_or_none()
        prolog_rec = (await session.execute(stmt_p)).scalar_one_or_none()

        if drools_rec is None and prolog_rec is None:
            return None

        instancia_drools = _to_item(drools_rec, tem_outro_motor=(prolog_rec is not None)) if drools_rec else None
        instancia_prolog = _to_item(prolog_rec, tem_outro_motor=(drools_rec is not None)) if prolog_rec else None

        divergencias: List[str] = []
        consenso = True
        resumo_consenso = ""
        razao_velocidade: Optional[str] = None

        if drools_rec and prolog_rec:
            d_eleg = drools_rec.elegibilidade.strip().upper()
            p_eleg = prolog_rec.elegibilidade.strip().upper()
            if d_eleg != p_eleg:
                divergencias.append(
                    f"Elegibilidade: Drools determinou '{d_eleg}' enquanto Prolog determinou '{p_eleg}'."
                )

            d_tipo = (drools_rec.tipo_transacao or "").strip().upper()
            p_tipo = (prolog_rec.tipo_transacao or "").strip().upper()
            if d_tipo and p_tipo and d_tipo != p_tipo:
                divergencias.append(
                    f"Tipo de transação: Drools autorizou '{d_tipo}' enquanto Prolog definiu '{p_tipo}'."
                )

            d_val = float(drools_rec.valor_devolucao or 0.0)
            p_val = float(prolog_rec.valor_devolucao or 0.0)
            if abs(d_val - p_val) > 0.01:
                divergencias.append(
                    f"Valor a reembolsar: Drools calculou {d_val:.2f}€ enquanto Prolog calculou {p_val:.2f}€."
                )

            d_meio = (drools_rec.meio_reembolso or "").strip().upper()
            p_meio = (prolog_rec.meio_reembolso or "").strip().upper()
            if d_meio and p_meio and d_meio != p_meio:
                divergencias.append(
                    f"Meio de reembolso: Drools indicou '{d_meio}' enquanto Prolog indicou '{p_meio}'."
                )

            consenso = len(divergencias) == 0
            if consenso:
                resumo_consenso = f"Ambos os motores deliberaram {d_eleg} em total consenso operacional."
            else:
                resumo_consenso = f"Divergência detetada: Drools deliberou {d_eleg} e Prolog deliberou {p_eleg}."

            d_ms = drools_rec.duracao_ms
            p_ms = prolog_rec.duracao_ms
            if d_ms > 0 and p_ms > 0:
                if p_ms < d_ms:
                    ratio = d_ms / max(p_ms, 1)
                    razao_velocidade = f"Prolog foi {ratio:.1f}x mais rápido que Drools ({p_ms}ms vs {d_ms}ms)"
                elif d_ms < p_ms:
                    ratio = p_ms / max(d_ms, 1)
                    razao_velocidade = f"Drools foi {ratio:.1f}x mais rápido que Prolog ({d_ms}ms vs {p_ms}ms)"
                else:
                    razao_velocidade = f"Ambos os motores apresentaram latência idêntica ({d_ms}ms)"
        elif drools_rec:
            consenso = True
            resumo_consenso = f"Apenas o motor Drools deliberou este caso ({drools_rec.elegibilidade}). Aguarda execução no motor Prolog para confronto."
        else:
            consenso = True
            resumo_consenso = f"Apenas o motor Prolog deliberou este caso ({prolog_rec.elegibilidade}). Aguarda execução no motor Drools para confronto."

        return ComparacaoMotoresResponse(
            pedidoId=pedido_id,
            consenso=consenso,
            resumoConsenso=resumo_consenso,
            razaoVelocidade=razao_velocidade,
            instanciaDrools=instancia_drools,
            instanciaProlog=instancia_prolog,
            divergencias=divergencias,
        )

    async def evaluate_both(
        self,
        payload: Dict[str, Any],
        session: Optional[AsyncSession] = None,
    ) -> AvaliarAmbosResponse:
        """Run parallel execution on Drools and Prolog resiliently using asyncio.gather."""
        if not self.levis_service or not self.retail_service:
            from app.clients.levis_client import LevisClient
            from app.clients.prolog_client import PrologClient
            from app.services.levis_service import LevisService
            from app.services.retail_prolog_service import RetailPrologService

            self.levis_service = self.levis_service or LevisService(levis_client=LevisClient())
            self.retail_service = self.retail_service or RetailPrologService(
                prolog_client=PrologClient(),
                levis_service=self.levis_service,
            )

        pedido_id = _extract_pedido_id(None, payload)

        async def run_drools():
            t0 = time.perf_counter()
            res = await self.levis_service.evaluate(payload)
            ms = max(1, int((time.perf_counter() - t0) * 1000))
            return res, ms

        async def run_prolog():
            t0 = time.perf_counter()
            res = await self.retail_service.evaluate_return(payload)
            ms = max(1, int((time.perf_counter() - t0) * 1000))
            return res, ms

        results = await asyncio.gather(run_drools(), run_prolog(), return_exceptions=True)
        drools_result, prolog_result = results

        drools_dec: Optional[DecisaoResponse] = None
        drools_err: Optional[str] = None
        drools_ms: int = 0
        if isinstance(drools_result, Exception):
            drools_err = str(drools_result)
            logger.error("[EvaluateBoth] Drools evaluation failed: %s", drools_err)
        else:
            drools_dec, drools_ms = drools_result

        prolog_dec: Optional[DecisaoResponse] = None
        prolog_err: Optional[str] = None
        prolog_ms: int = 0
        if isinstance(prolog_result, Exception):
            prolog_err = str(prolog_result)
            logger.error("[EvaluateBoth] Prolog evaluation failed: %s", prolog_err)
        else:
            prolog_dec, prolog_ms = prolog_result

        if drools_dec is None and prolog_dec is None:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Ambos os motores falharam na avaliação simultânea. Drools: {drools_err} | Prolog: {prolog_err}",
            )

        # Build comparison
        comp: Optional[ComparacaoMotoresResponse] = None
        if session:
            comp = await self.get_comparison_by_pedido_id(pedido_id=pedido_id, session=session)
        else:
            async with async_session_factory() as local_session:
                comp = await self.get_comparison_by_pedido_id(pedido_id=pedido_id, session=local_session)

        # Fallback comparison summary if not yet visible
        consenso = comp.consenso if comp else (drools_dec is not None and prolog_dec is not None)
        resumo = (
            comp.resumoConsenso
            if comp
            else ("Avaliação processada com sucesso." if not drools_err and not prolog_err else "Execução parcial.")
        )
        razao = comp.razaoVelocidade if comp else None

        return AvaliarAmbosResponse(
            pedidoId=pedido_id,
            consenso=consenso,
            resumoConsenso=resumo,
            razaoVelocidade=razao,
            drools=drools_dec,
            prolog=prolog_dec,
            droolsError=drools_err,
            prologError=prolog_err,
            comparacao=comp,
        )
