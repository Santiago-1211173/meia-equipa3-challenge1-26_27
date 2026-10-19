"""Pydantic schemas for unified inferences history and multi-engine comparison."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Literal, Optional
from uuid import UUID

from pydantic import Field

from app.schemas.levis import DecisaoResponse, LevisBaseModel, PaginaResponse

MotorTipo = Literal["DROOLS", "PROLOG"]
ElegibilidadeTipo = Literal["PERMITIR", "RECUSAR", "TROCA", "REVER", "ENCAMINHAR"]


class RegraItemDto(LevisBaseModel):
    """Summarized rule execution item."""

    codigo: str = Field(..., description="Código ou identificador da regra disparada")
    nome: Optional[str] = Field(default=None, description="Nome descritivo da regra")
    modulo: Optional[str] = Field(default=None, description="Módulo funcional da regra (ex.: M0-M9)")
    mensagem: Optional[str] = Field(default=None, description="Mensagem ou justificação operacional")
    resultado: Optional[str] = Field(default=None, description="Resultado ou efeito determinado")


class InferenciaItem(LevisBaseModel):
    """Canonical model for a persisted inference in list or overview."""

    id: UUID = Field(..., description="Identificador único da inferência")
    pedidoId: str = Field(..., description="Identificador do pedido / caso")
    motor: str = Field(..., description="Motor que executou a deliberação (DROOLS ou PROLOG)")
    motorVersao: Optional[str] = Field(default=None, description="Versão de auditoria do motor")
    produtoNome: str = Field(default="Artigo", description="Nome do produto em avaliação")
    produtoRef: Optional[str] = Field(default=None, description="Referência SKU ou identificador do produto")
    valorDevolucao: float = Field(default=0.0, description="Valor monetário calculado para a devolução")
    elegibilidade: str = Field(..., description="Elegibilidade decidida (PERMITIR, RECUSAR, TROCA, REVER, etc.)")
    tipoTransacao: Optional[str] = Field(default=None, description="Tipo de transação autorizada")
    meioReembolso: Optional[str] = Field(default=None, description="Meio de reembolso determinado")
    nivelAprovacao: Optional[str] = Field(default=None, description="Nível de aprovação requerido")
    executadoEm: datetime = Field(..., description="Timestamp da execução")
    duracaoMs: int = Field(default=0, description="Duração do processamento no motor em milissegundos")
    regrasDisparadas: List[RegraItemDto] = Field(default_factory=list, description="Lista de regras ativadas")
    temOutroMotor: bool = Field(
        default=False,
        description="Indica se existe outra inferência deste mesmo caso resolvida por motor distinto",
    )


class InferenciaDetalheResponse(InferenciaItem):
    """Complete detail view of an inference record including input and full decision JSON."""

    inputPedidoJson: Dict[str, Any] = Field(default_factory=dict, description="Payload de entrada do pedido")
    decisaoJson: Dict[str, Any] = Field(default_factory=dict, description="Payload completo da decisão canónica")


class ComparacaoMotoresResponse(LevisBaseModel):
    """Side-by-side comparison matrix for a return case resolved by multiple engines."""

    pedidoId: str = Field(..., description="Identificador do caso em análise")
    consenso: bool = Field(..., description="Verdadeiro se ambos os motores convergiram na elegibilidade e desfecho")
    resumoConsenso: str = Field(..., description="Resumo executivo do alinhamento ou divergência entre motores")
    razaoVelocidade: Optional[str] = Field(default=None, description="Rácio de desempenho de latência entre motores")
    instanciaDrools: Optional[InferenciaItem] = Field(default=None, description="Registo mais recente do Drools")
    instanciaProlog: Optional[InferenciaItem] = Field(default=None, description="Registo mais recente do Prolog")
    divergencias: List[str] = Field(default_factory=list, description="Lista detalhada de discrepâncias encontradas")


class AvaliarAmbosResponse(LevisBaseModel):
    """Response returned when evaluating a case simultaneously against Drools and Prolog."""

    pedidoId: str = Field(..., description="Identificador do pedido avaliado")
    consenso: bool = Field(..., description="Se ambos convergiram no resultado")
    resumoConsenso: str = Field(..., description="Resumo do resultado combinado")
    razaoVelocidade: Optional[str] = Field(default=None, description="Comparação de latência")
    drools: Optional[DecisaoResponse] = Field(default=None, description="Decisão completa do motor Drools")
    prolog: Optional[DecisaoResponse] = Field(default=None, description="Decisão completa do motor Prolog")
    droolsError: Optional[str] = Field(default=None, description="Erro ocorrido no Drools se tiver falhado")
    comparacao: Optional[ComparacaoMotoresResponse] = Field(default=None, description="Matriz comparativa")


class SeedCenarioItem(LevisBaseModel):
    """Execution status for a single scenario during seeding."""

    cenarioId: int = Field(..., description="Número ordinal do cenário (1-10)")
    pedidoId: str = Field(..., description="Identificador do caso semeado (ex.: CENARIO-01)")
    titulo: str = Field(..., description="Título do cenário")
    droolsStatus: str = Field(..., description="Estado no motor Drools: 'executado', 'saltado', 'erro'")
    prologStatus: str = Field(..., description="Estado no motor Prolog: 'executado', 'saltado', 'erro'")
    droolsElegibilidade: Optional[str] = Field(default=None, description="Elegibilidade decidida pelo Drools")
    prologElegibilidade: Optional[str] = Field(default=None, description="Elegibilidade decidida pelo Prolog")
    erro: Optional[str] = Field(default=None, description="Mensagem de erro em caso de falha")


class SeedResponse(LevisBaseModel):
    """Summary of the scenario seeding operation."""

    status: str = Field(default="concluido", description="Estado geral da operação de semeadura")
    totalCenarios: int = Field(..., description="Total de cenários de teste oficiais avaliados")
    cenariosProcessados: int = Field(default=0, description="Total de cenários processados")
    cenariosSaltados: int = Field(default=0, description="Total de cenários saltados por já existirem")
    executadosDrools: int = Field(default=0, description="Total de avaliações persistidas pelo Drools")
    executadosProlog: int = Field(default=0, description="Total de avaliações persistidas pelo Prolog")
    erros: List[str] = Field(default_factory=list, description="Erros registados durante o processo")
    detalhes: List[SeedCenarioItem] = Field(default_factory=list, description="Detalhe por cenário")
