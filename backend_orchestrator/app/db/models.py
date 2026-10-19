"""SQLAlchemy declarative models for database persistence."""

import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Numeric, Integer, DateTime, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from app.db.session import Base


class HistoricoInferencia(Base):
    """Stores the execution trace and final decision of each inference run (Drools or Prolog)."""

    __tablename__ = "historico_inferencias"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    pedido_id = Column(String(64), nullable=False, index=True)
    motor = Column(String(20), nullable=False, index=True)  # 'DROOLS' ou 'PROLOG'
    motor_versao = Column(String(100), nullable=True)
    produto_nome = Column(String(200), nullable=False, default="Artigo")
    produto_ref = Column(String(64), nullable=True)
    valor_devolucao = Column(Numeric(12, 2), nullable=True, default=0.0)
    elegibilidade = Column(String(30), nullable=False)  # PERMITIR, RECUSAR, TROCA, REVER
    tipo_transacao = Column(String(30), nullable=True)
    meio_reembolso = Column(String(50), nullable=True)
    nivel_aprovacao = Column(String(50), nullable=True)
    regras_disparadas = Column(JSONB, nullable=False, default=list)
    input_pedido_json = Column(JSONB, nullable=False, default=dict)
    decisao_json = Column(JSONB, nullable=False, default=dict)
    duracao_ms = Column(Integer, nullable=False, default=0)
    executado_em = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        index=True,
    )

    __table_args__ = (
        Index("ix_historico_pedido_motor", "pedido_id", "motor"),
        Index("ix_historico_executado_em_desc", executado_em.desc()),
    )
