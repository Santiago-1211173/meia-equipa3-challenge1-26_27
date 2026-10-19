"""Pydantic v2 schemas for the Levi's Returns Expert Engine (Drools).

Maps all domain enums, request entities, evaluation decisions,
explanations (5-way: How, Why, Why Not, What If, Missing Data),
and knowledge catalog contracts.
"""

from __future__ import annotations

import re
from datetime import date, datetime
from decimal import Decimal
from enum import Enum
from typing import Any, Dict, Generic, List, Optional, Set, TypeVar, Union
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator


def _to_camel_case(s: str) -> str:
    """Converts snake_case string to camelCase."""
    return re.sub(r"_([a-z0-9])", lambda m: m.group(1).upper(), s)


class LevisBaseModel(BaseModel):
    """Base model supporting both camelCase and snake_case attributes seamlessly."""

    model_config = ConfigDict(
        populate_by_name=True,
        extra="ignore",
    )

    @model_validator(mode="before")
    @classmethod
    def _normalize_keys(cls, data: Any) -> Any:
        if isinstance(data, dict):
            new_data: Dict[str, Any] = {}
            for k, v in data.items():
                new_data[k] = v
                if isinstance(k, str) and "_" in k:
                    camel = _to_camel_case(k)
                    if camel not in new_data:
                        new_data[camel] = v
            return new_data
        return data

    def __getattr__(self, name: str) -> Any:
        if "_" in name:
            camel = _to_camel_case(name)
            if camel in self.__dict__:
                return self.__dict__[camel]
        raise AttributeError(f"'{self.__class__.__name__}' object has no attribute '{name}'")


# ==============================================================================
# 1. ENUMS DE DOMÍNIO
# ==============================================================================


class BaseValorEnum(str, Enum):
    """Base usada para o cálculo do valor da devolução (OUT-003)."""

    VALOR_PAGO = "VALOR_PAGO"
    PRECO_ATUAL = "PRECO_ATUAL"
    VALOR_PROMOCIONAL = "VALOR_PROMOCIONAL"
    VALOR_ESCALAO = "VALOR_ESCALAO"
    VALOR_POS = "VALOR_POS"
    PVP_ORIGINAL = "PVP_ORIGINAL"


BaseValor = BaseValorEnum


class CanalCompraEnum(str, Enum):
    """Canal da compra original (IN-003)."""

    MAINLINE = "MAINLINE"
    OUTLET = "OUTLET"
    LEVI_COM = "LEVI_COM"
    LEVI_CA = "LEVI_CA"
    BACKPOCKET = "BACKPOCKET"
    FRANQUIA_CANADA = "FRANQUIA_CANADA"
    GROSSISTA = "GROSSISTA"
    DESCONHECIDO = "DESCONHECIDO"


CanalCompra = CanalCompraEnum


class CategoriaProdutoEnum(str, Enum):
    """Categoria do produto; distingue vestuário, acessórios e bodywear (IN-007)."""

    VESTUARIO = "VESTUARIO"
    ACESSORIO = "ACESSORIO"
    BODYWEAR = "BODYWEAR"


CategoriaProduto = CategoriaProdutoEnum


class CondicaoUsoEnum(str, Enum):
    """Condição física de uso do artigo inspecionado (IN-008)."""

    NAO_USADO = "NAO_USADO"
    USADO = "USADO"
    LAVADO = "LAVADO"


CondicaoUso = CondicaoUsoEnum


class DestinoProdutoEnum(str, Enum):
    """Destino físico ou operacional do produto devolvido (OUT-007)."""

    AREA_VENDAS = "AREA_VENDAS"
    SALDOS = "SALDOS"
    REETIQUETAR = "REETIQUETAR"
    BAIXA_DANO = "BAIXA_DANO"
    RISCO_BIOLOGICO = "RISCO_BIOLOGICO"
    DEVOLUCAO_CLIENTE = "DEVOLUCAO_CLIENTE"


DestinoProduto = DestinoProdutoEnum


class ElegibilidadeEnum(str, Enum):
    """Classificação primária de elegibilidade (OUT-001)."""

    PERMITIR = "PERMITIR"
    REVER = "REVER"
    ENCAMINHAR = "ENCAMINHAR"
    RECUSAR = "RECUSAR"


Elegibilidade = ElegibilidadeEnum


class EstadoContaEnum(str, Enum):
    """Estado da conta associada ao cartão de pagamento original (TN-002, TN-003)."""

    ATIVA = "ATIVA"
    ATIVA_CARTAO_PERDIDO = "ATIVA_CARTAO_PERDIDO"
    ENCERRADA = "ENCERRADA"


EstadoConta = EstadoContaEnum


class EstadoEtiquetasEnum(str, Enum):
    """Estado de fixação das etiquetas originais do artigo (IN-008)."""

    COLOCADAS = "COLOCADAS"
    SOLTAS = "SOLTAS"
    AUSENTES = "AUSENTES"


EstadoEtiquetas = EstadoEtiquetasEnum
EtiquetasEnum = EstadoEtiquetasEnum


class FuncaoEnum(str, Enum):
    """Função do colaborador na hierarquia da loja (HS-006, CT-002)."""

    STYLIST = "STYLIST"
    ELEVATED_STYLIST = "ELEVATED_STYLIST"
    LEAD_CASHIER = "LEAD_CASHIER"
    KEY_HOLDER = "KEY_HOLDER"
    GESTAO_LOJA = "GESTAO_LOJA"
    XSTORE_MANAGER = "XSTORE_MANAGER"


Funcao = FuncaoEnum


class MarcaEnum(str, Enum):
    """Marca do produto (IN-007)."""

    LEVIS = "LEVIS"
    DOCKERS = "DOCKERS"
    LS_SIGNATURE = "LS_SIGNATURE"
    BEYOND_YOGA = "BEYOND_YOGA"
    OUTRA = "OUTRA"


Marca = MarcaEnum


class MeioPagamentoEnum(str, Enum):
    """Meio de pagamento original utilizado na compra (IN-009)."""

    CREDITO = "CREDITO"
    DEBITO = "DEBITO"
    APPLE_PAY = "APPLE_PAY"
    GOOGLE_PAY = "GOOGLE_PAY"
    PAYPAL = "PAYPAL"
    VENMO = "VENMO"
    AFTERPAY = "AFTERPAY"
    INTERAC = "INTERAC"
    NUMERARIO = "NUMERARIO"
    CARTAO_OFERTA = "CARTAO_OFERTA"


MeioPagamento = MeioPagamentoEnum


class MeioReembolsoEnum(str, Enum):
    """Meio estipulado para liquidação ou reembolso (OUT-004)."""

    MEIO_ORIGINAL = "MEIO_ORIGINAL"
    CARTAO_OFERTA = "CARTAO_OFERTA"
    CARTAO_OFERTA_ELETRONICO = "CARTAO_OFERTA_ELETRONICO"
    MEIO_ALTERNATIVO = "MEIO_ALTERNATIVO"
    APLICACAO_PAGAMENTO = "APLICACAO_PAGAMENTO"
    CREDITO_LOJA = "CREDITO_LOJA"


MeioReembolso = MeioReembolsoEnum


class MercadoEnum(str, Enum):
    """Mercado geográfico da loja recetora (IN-001)."""

    EUA = "EUA"
    CANADA = "CANADA"


Mercado = MercadoEnum


class NivelAprovacaoEnum(str, Enum):
    """Nível hierárquico mínimo de aprovação exigido (OUT-005)."""

    NENHUMA = "NENHUMA"
    XSTORE_MANAGER = "XSTORE_MANAGER"
    RESPONSAVEL_SENIOR = "RESPONSAVEL_SENIOR"
    DISTRICT_AREA = "DISTRICT_AREA"


NivelAprovacao = NivelAprovacaoEnum


class NivelRiscoEnum(str, Enum):
    """Nível de risco de indícios de fraude (EX-004, EX-008)."""

    BAIXO = "BAIXO"
    SIGNIFICATIVO = "SIGNIFICATIVO"
    CONFIRMADO = "CONFIRMADO"


NivelRisco = NivelRiscoEnum


class ProcessoObrigatorioEnum(str, Enum):
    """Processo operacional obrigatório a seguir na transação (OUT-006)."""

    POS = "POS"
    BACKPOCKET = "BACKPOCKET"
    AFTERPAY = "AFTERPAY"
    PAYPAL_VENMO = "PAYPAL_VENMO"
    VERIFONE_INTERAC = "VERIFONE_INTERAC"
    FRANQUIA_CANADA = "FRANQUIA_CANADA"
    DANO = "DANO"
    RISCO_BIOLOGICO = "RISCO_BIOLOGICO"


ProcessoObrigatorio = ProcessoObrigatorioEnum


class TipoComprovativoEnum(str, Enum):
    """Tipo de comprovativo de compra apresentado pelo cliente (IN-004)."""

    RECIBO_IMPRESSO = "RECIBO_IMPRESSO"
    RECIBO_DIGITAL = "RECIBO_DIGITAL"
    CONFIRMACAO_ENCOMENDA = "CONFIRMACAO_ENCOMENDA"
    RECIBO_OFERTA = "RECIBO_OFERTA"
    CONSULTA_TRANSACAO = "CONSULTA_TRANSACAO"
    FOTOGRAFIA_RECIBO = "FOTOGRAFIA_RECIBO"
    CONSULTA_BACKPOCKET = "CONSULTA_BACKPOCKET"


TipoComprovativo = TipoComprovativoEnum


class TipoLojaEnum(str, Enum):
    """Formato comercial da loja recetora (IN-002)."""

    MAINLINE = "MAINLINE"
    OUTLET = "OUTLET"


TipoLoja = TipoLojaEnum


class TipoPedidoEnum(str, Enum):
    """Intenção inicial solicitada pelo cliente na loja (IN-005)."""

    DEVOLUCAO = "DEVOLUCAO"
    TROCA = "TROCA"
    AJUSTE_PRECO = "AJUSTE_PRECO"
    DEVOLUCAO_OFERTA = "DEVOLUCAO_OFERTA"


TipoPedido = TipoPedidoEnum


class TipoTransacaoEnum(str, Enum):
    """Veredito final do tipo de transação autorizada (OUT-002)."""

    REEMBOLSO = "REEMBOLSO"
    TROCA = "TROCA"
    TROCA_MESMO_ARTIGO = "TROCA_MESMO_ARTIGO"
    CREDITO_LOJA = "CREDITO_LOJA"
    AJUSTE_PRECO = "AJUSTE_PRECO"
    NENHUMA = "NENHUMA"


TipoTransacao = TipoTransacaoEnum


class TipoVerificacaoEnum(str, Enum):
    """Classificação da verificação do comprovativo (PT-001, PT-002)."""

    NAO_DETERMINADA = "NAO_DETERMINADA"
    VERIFICADA = "VERIFICADA"
    AS_CEGAS = "AS_CEGAS"


TipoVerificacao = TipoVerificacaoEnum


class CausaNaoDisparoEnum(str, Enum):
    """Causa que impediu uma regra de disparar ou produzir conclusão."""

    DISPAROU = "DISPAROU"
    MODULO_NAO_ALCANCADO = "MODULO_NAO_ALCANCADO"
    CANCELADA_POR_PRECEDENCIA = "CANCELADA_POR_PRECEDENCIA"
    CONDICOES_FALHADAS = "CONDICOES_FALHADAS"


CausaNaoDisparo = CausaNaoDisparoEnum


# ==============================================================================
# 2. ENTIDADES DO PEDIDO (REQUESTS)
# ==============================================================================


class ColaboradorDto(LevisBaseModel):
    """Colaborador de loja (autenticado via JWT ou aprovador de exceção)."""

    id: str = Field(..., description="Identificador único do colaborador (ex.: DEV-KH).")
    nome: Optional[str] = Field(default=None, description="Nome do colaborador.")
    funcao: FuncaoEnum = Field(..., description="Função na loja.")
    aprovadoPeloDM: bool = Field(default=False, description="Se tem aprovação do District Manager.")
    idCredencialPOS: Optional[str] = Field(default=None, description="Identificador no POS.")


class LojaRequest(LevisBaseModel):
    """Loja recetora onde a devolução/troca é solicitada (IN-001, IN-002)."""

    codigo: str = Field(..., description="Código da loja recetora (ex.: US-ML-010).")
    nome: Optional[str] = Field(default=None, description="Nome da loja.")
    mercado: Optional[MercadoEnum] = Field(default=MercadoEnum.EUA, description="Mercado geográfico.")
    tipoLoja: Optional[TipoLojaEnum] = Field(default=TipoLojaEnum.MAINLINE, description="Formato da loja.")
    lojaBackPocket: bool = Field(default=False, description="Indica se tem integração BackPocket.")
    coberturaLojaUnica: bool = Field(default=False, description="Indica cobertura de loja única.")
    skusSortido: Optional[Union[Set[str], List[str]]] = Field(
        default=None, description="Conjunto de SKUs presentes no sortido local."
    )

    @model_validator(mode="before")
    @classmethod
    def _normalize_mercado(cls, data: Any) -> Any:
        if isinstance(data, dict):
            mercado = data.get("mercado")
            if isinstance(mercado, str):
                m_upper = mercado.strip().upper()
                if m_upper in ["CA", "CANADA"]:
                    data["mercado"] = MercadoEnum.CANADA
                elif m_upper in ["EUA", "US", "USA"]:
                    data["mercado"] = MercadoEnum.EUA
        return data


class ClienteRequest(LevisBaseModel):
    """Comportamento e dados do cliente no momento da solicitação (PT-006, EX-002, EX-003)."""

    id: Optional[str] = Field(default=None, description="Identificador do cliente no sistema de fidelização.")
    forneceDados: Optional[bool] = Field(default=True, description="Aceita fornecer dados pessoais (vazio = sim).")
    barreiraLinguistica: bool = Field(default=False, description="Presença de barreira linguística.")
    contestaResultado: bool = Field(default=False, description="Cliente contesta ativamente a decisão inicial.")
    agitado: bool = Field(default=False, description="Cliente apresenta comportamento alterado ou agitado.")


class PagamentoRequest(LevisBaseModel):
    """Meio de pagamento da transação original (IN-009)."""

    meio: Optional[MeioPagamentoEnum] = Field(default=None, description="Meio de pagamento original.")
    valorPago: Optional[Union[Decimal, float]] = Field(default=None, description="Valor pago na compra original.")
    estadoConta: Optional[EstadoContaEnum] = Field(default=None, description="Estado da conta associada.")
    cartaoFisicoPresente: bool = Field(default=False, description="Cartão físico está presente na loja.")
    reembolsoOriginalRecusado: bool = Field(default=False, description="Tentativa de reembolso original falhou.")
    acessoAplicacaoPagamento: Optional[bool] = Field(default=None, description="Cliente acede à app (PayPal/Venmo).")


class CompraRequest(LevisBaseModel):
    """Detalhes da compra original apresentada (IN-003, IN-006, IN-009)."""

    idTransacao: Optional[str] = Field(default=None, description="Número do talão ou transação original.")
    canal: Optional[CanalCompraEnum] = Field(default=None, description="Canal onde o artigo foi adquirido.")
    dataCompra: Optional[date] = Field(default=None, description="Data de realização da compra.")
    dataEnvio: Optional[date] = Field(default=None, description="Data de expedição (para compras online).")
    pagamento: Optional[PagamentoRequest] = Field(default=None, description="Detalhes de pagamento original.")
    idStylistVenda: Optional[str] = Field(default=None, description="Identificador do stylist que efetuou a venda.")
    quantidadeComprada: int = Field(default=1, description="Quantidade total de artigos na transação.")
    promocaoEscaloes: bool = Field(default=False, description="Compra beneficiou de promoção por escalões.")
    encomendaEncontrada: Optional[bool] = Field(default=None, description="Encomenda online localizada em sistema.")
    ajustePrecoAplicado: bool = Field(default=False, description="Indica se já beneficiou de ajuste de preço prévio.")
    compraOferta: bool = Field(default=False, description="Indica se se tratou de compra de oferta.")

    @model_validator(mode="before")
    @classmethod
    def _normalize_canal(cls, data: Any) -> Any:
        if isinstance(data, dict):
            canal = data.get("canal")
            if isinstance(canal, str):
                c_upper = canal.strip().upper()
                if c_upper in ["FRANQUIA_CA", "FRANQUIA_CANADA"]:
                    data["canal"] = CanalCompraEnum.FRANQUIA_CANADA
        return data


CompraOriginalRequest = CompraRequest


class ComprovativoRequest(LevisBaseModel):
    """Comprovativo de compra apresentado (IN-004)."""

    tipo: Optional[TipoComprovativoEnum] = Field(default=None, description="Tipo de comprovativo apresentado.")
    confirmaCompra: bool = Field(default=False, description="Comprovativo confirma inequivocamente a compra.")
    reciboOriginal: bool = Field(default=False, description="Recibo original está presente.")
    clienteMantemRecibo: bool = Field(default=False, description="Cliente retém o recibo após a transação.")
    incluiOutrosArtigos: bool = Field(default=False, description="Recibo inclui outros artigos além dos devolvidos.")


class ProdutoRequest(LevisBaseModel):
    """Ficha do produto cadastrado (IN-007)."""

    sku: str = Field(..., description="Código SKU do produto (ex.: 501-ORIG-32).")
    skuReconhecidoPOS: Optional[bool] = Field(default=True, description="SKU reconhecido pelo POS.")
    marca: Optional[MarcaEnum] = Field(default=MarcaEnum.LEVIS, description="Marca do produto.")
    categoria: Optional[CategoriaProdutoEnum] = Field(default=CategoriaProdutoEnum.VESTUARIO, description="Categoria.")
    grossista: Optional[bool] = Field(default=False, description="Artigo proveniente de canal grossista.")
    vendidoNaLoja: Optional[bool] = Field(default=True, description="Artigo vendido na loja recetora.")
    produtoFranquia: Optional[bool] = Field(default=False, description="Produto exclusivo de franquia.")
    pvpOriginal: Optional[Union[Decimal, float]] = Field(default=None, description="Preço de venda ao público original.")
    precoAtual: Optional[Union[Decimal, float]] = Field(default=None, description="Preço de venda atual na loja.")
    emSaldo: Optional[bool] = Field(default=False, description="Produto em saldo atualmente.")


class EstadoProdutoRequest(LevisBaseModel):
    """Inspeção física do artigo devolvido (IN-008)."""

    condicaoUso: Optional[CondicaoUsoEnum] = Field(default=CondicaoUsoEnum.NAO_USADO, description="Condição de uso.")
    etiquetas: Optional[EstadoEtiquetasEnum] = Field(default=EstadoEtiquetasEnum.COLOCADAS, description="Etiquetas.")
    personalizado: bool = Field(default=False, description="Artigo recebeu personalização no Tailor Shop.")
    alterado: bool = Field(default=False, description="Artigo foi alterado por alfaiate externo.")
    embainhado: bool = Field(default=False, description="Artigo foi embainhado.")
    defeitoFabricoConfirmado: bool = Field(default=False, description="Defeito de fabrico confirmado pelo colaborador.")
    sujoOuInseguro: bool = Field(default=False, description="Artigo sujo, contaminado ou inseguro.")
    danificado: bool = Field(default=False, description="Artigo com danos físicos não de fabrico.")
    etiquetaPrecoCorreta: Optional[bool] = Field(default=True, description="Etiqueta de preço correta.")
    rfidCorreto: Optional[bool] = Field(default=True, description="Etiqueta RFID corresponde ao produto.")
    embalagemIntacta: bool = Field(default=True, description="Embalagem original intacta (ex.: bodywear).")
    conjuntoCompleto: Optional[bool] = Field(default=True, description="Conjunto ou pack completo.")


class ArtigoRequest(LevisBaseModel):
    """Artigo devolvido pelo cliente (IN-007, IN-008, IN-010)."""

    id: str = Field(..., description="Identificador local do artigo (ex.: A-1).")
    produto: ProdutoRequest = Field(..., description="Dados do produto.")
    quantidade: Optional[int] = Field(default=1, description="Quantidade devolvida.")
    precoPago: Optional[Union[Decimal, float]] = Field(default=None, description="Preço efetivamente pago.")
    estado: Optional[EstadoProdutoRequest] = Field(default=None, description="Estado de conservação.")
    entreCanais: bool = Field(default=False, description="Devolução entre canais diferentes.")
    revendivel: Optional[bool] = Field(
        default=None, description="IN-010: Verificável, reetiquetável e revendível (vazio = por inspecionar)."
    )
    valorCalculadoPos: Optional[Union[Decimal, float]] = Field(
        default=None, description="Valor calculado pelo POS (ajustes/escalões)."
    )


class ArtigoTrocaRequest(LevisBaseModel):
    """Artigo pretendido pelo cliente numa troca (EP-001, EP-002, TN-006)."""

    produto: ProdutoRequest = Field(..., description="Produto que o cliente pretende levar.")
    apenasMudaTamanho: bool = Field(default=False, description="Troca apenas de tamanho do mesmo artigo.")
    precoVenda: Optional[Union[Decimal, float]] = Field(default=None, description="Preço de venda atual do novo artigo.")


class PedidoExcecaoRequest(LevisBaseModel):
    """Pedido de exceção solicitado pelo cliente e decisão de gestão (EX-001 a EX-007, HS-005)."""

    motivo: Optional[str] = Field(default=None, description="Motivo invocado para a exceção.")
    resolucaoPedida: Optional[TipoTransacaoEnum] = Field(default=None, description="Tipo de resolução pretendida.")
    exigeMeioProibido: bool = Field(default=False, description="Exige meio de reembolso proibido pela política.")
    exigeSkuIncorreto: bool = Field(default=False, description="Exige troca por SKU inválido/incorreto.")
    envolveProdutoExcluido: bool = Field(default=False, description="Envolve produto excluído de devoluções.")
    contornaProcessoObrigatorio: bool = Field(default=False, description="Contorna processo operacional obrigatório.")
    concluivelNoSistema: Optional[bool] = Field(default=True, description="Pode ser concluído tecnicamente no POS.")
    aprovada: Optional[bool] = Field(default=None, description="Decisão da gestão (vazio = pendente).")
    aprovador: Optional[ColaboradorDto] = Field(default=None, description="Colaborador responsável pela aprovação.")
    preocupacaoCliente: Optional[str] = Field(default=None, description="Registo do descontentamento do cliente.")


class IndicadorFraudeRequest(LevisBaseModel):
    """Indício de fraude ou abuso de devoluções registado pelo colaborador (EX-008)."""

    descricao: str = Field(..., description="Descrição detalhada da suspeita ou comportamento.")
    nivelRisco: NivelRiscoEnum = Field(..., description="Gravidade do risco de fraude.")


class PedidoAvaliacaoRequest(LevisBaseModel):
    """Contrato completo de pedido submetido para avaliação pericial pelas regras Drools."""

    id: Optional[str] = Field(default=None, description="Identificador do pedido (gerado se não fornecido).")
    dataPedido: Optional[date] = Field(default=None, description="Data da apresentação na loja (IN-006).")
    tipoPedido: Optional[TipoPedidoEnum] = Field(default=None, description="Tipo de pedido do cliente (IN-005).")
    loja: Optional[LojaRequest] = Field(default=None, description="Loja recetora.")
    colaborador: Optional[ColaboradorDto] = Field(
        default=None, description="Colaborador autenticado (usado nos cenários de teste e dev token)."
    )
    cliente: Optional[ClienteRequest] = Field(default=None, description="Dados do cliente.")
    compraOriginal: Optional[CompraRequest] = Field(default=None, description="Dados da compra original.")
    comprovativo: Optional[ComprovativoRequest] = Field(default=None, description="Comprovativo de compra apresentado.")
    artigos: List[ArtigoRequest] = Field(default_factory=list, description="Lista de artigos a devolver/trocar.")
    artigosTroca: Optional[List[ArtigoTrocaRequest]] = Field(
        default=None, description="Artigos pretendidos em troca."
    )
    portalOnlineDisponivel: Optional[bool] = Field(
        default=None, description="Portal online disponível (consultado via BackPocket se vazio)."
    )
    politicaPermiteAsCegasOnline: Optional[bool] = Field(
        default=None, description="Política autoriza devolução online às cegas (CH-003)."
    )
    pedidoExcecao: Optional[PedidoExcecaoRequest] = Field(
        default=None, description="Pedido de exceção ou contestação."
    )
    indicadoresFraude: Optional[List[IndicadorFraudeRequest]] = Field(
        default=None, description="Indicadores de risco de fraude."
    )

    @model_validator(mode="after")
    def _align_franquia_artigos(self) -> "PedidoAvaliacaoRequest":
        if self.compraOriginal and self.compraOriginal.canal == CanalCompraEnum.FRANQUIA_CANADA:
            for artigo in self.artigos:
                if artigo.produto:
                    artigo.produto.produtoFranquia = True
        return self


# ==============================================================================
# 3. DECISÃO E RESPOSTA (RESPONSES)
# ==============================================================================


class DocumentacaoResponse(LevisBaseModel):
    """Requisitos de documentação e retenção documental exigidos (OUT-008)."""

    assinaturaCliente: Optional[str] = Field(default=None, description="Exigência de assinatura do cliente.")
    assinaturaProcessador: Optional[str] = Field(default=None, description="Assinatura do colaborador.")
    assinaturaTestemunha: Optional[str] = Field(default=None, description="Assinatura de testemunha.")
    idStylistAtribuido: Optional[str] = Field(default=None, description="Stylist a quem atribuir a transação.")
    reciboAgrafado: bool = Field(default=False, description="Exige agrafar recibo físico.")
    notaRecibo: Optional[str] = Field(default=None, description="Anotação manuscrita obrigatória no recibo.")
    retencaoAte: Optional[date] = Field(default=None, description="Data limite de arquivo físico.")
    registoExcecao: Optional[str] = Field(default=None, description="Formulário ou registo de exceção gerencial.")


class RegistoRegraResponse(LevisBaseModel):
    """Registo de disparo de uma regra DRL (rasto de auditoria da inferência)."""

    ordem: int = Field(default=0, description="Ordem cronológica de ativação.")
    codigoRegra: Optional[str] = Field(default=None, description="Código de negócio da regra (ex.: PC-002).")
    nomeRegra: Optional[str] = Field(default=None, description="Nome técnico da regra no ficheiro DRL.")
    modulo: Optional[str] = Field(default=None, description="Módulo da regra (M0 a M9).")
    artigoId: Optional[str] = Field(default=None, description="Artigo a que a regra se aplicou.")
    resultado: Optional[ElegibilidadeEnum] = Field(default=None, description="Resultado determinado.")
    mensagem: Optional[str] = Field(default=None, description="Mensagem de justificação operacional.")
    aValidar: bool = Field(default=False, description="Regra com ambiguidades para validação futura.")


class ResultadoArtigoResponse(LevisBaseModel):
    """Resultado individual de diagnóstico por artigo avaliado (ADR 0002, OUT-007)."""

    artigoId: str = Field(..., description="Identificador do artigo avaliado.")
    elegibilidade: Optional[ElegibilidadeEnum] = Field(default=None, description="Elegibilidade para este artigo.")
    tipoTransacao: Optional[TipoTransacaoEnum] = Field(default=None, description="Tipo de transação autorizada.")
    valorDevolucao: Optional[Union[Decimal, float]] = Field(default=None, description="Valor monetário a creditar.")
    baseValor: Optional[BaseValorEnum] = Field(default=None, description="Base de preço adotada.")
    destino: Optional[DestinoProdutoEnum] = Field(default=None, description="Destino físico do artigo (OUT-007).")
    descontoSaldo: int = Field(default=0, description="Desconto percentual aplicado se destinado a saldos.")
    aprovacao: Optional[NivelAprovacaoEnum] = Field(default=None, description="Nível de aprovação necessário.")
    terminal: bool = Field(default=False, description="Avaliação para este artigo foi terminal.")


class DecisaoResponse(LevisBaseModel):
    """Decisão final consolidada emitida pelo motor de regras Drools Levi's (OUT-001 a OUT-008)."""

    avaliacaoId: Optional[UUID] = Field(default=None, description="UUID da avaliação persistida em PostgreSQL.")
    pedidoId: Optional[str] = Field(default=None, description="Identificador do pedido avaliado.")
    avaliadaEm: Optional[datetime] = Field(default=None, description="Timestamp da avaliação pericial.")
    versaoBaseConhecimento: Optional[str] = Field(default=None, description="Versão de auditoria do kjar.")
    elegibilidade: Optional[ElegibilidadeEnum] = Field(default=None, description="OUT-001: Elegibilidade global.")
    tipoVerificacao: Optional[TipoVerificacaoEnum] = Field(default=None, description="Verificação de comprovativo.")
    tipoTransacao: Optional[TipoTransacaoEnum] = Field(default=None, description="OUT-002: Tipo de transação.")
    valorDevolucao: Optional[Union[Decimal, float]] = Field(default=None, description="OUT-003: Valor total a reembolsar.")
    baseValor: Optional[BaseValorEnum] = Field(default=None, description="Base de valor aplicada.")
    meioReembolso: Optional[MeioReembolsoEnum] = Field(default=None, description="OUT-004: Meio de reembolso.")
    aprovacao: Optional[NivelAprovacaoEnum] = Field(default=None, description="OUT-005: Nível de aprovação exigido.")
    processo: Optional[ProcessoObrigatorioEnum] = Field(default=None, description="OUT-006: Processo obrigatório.")
    terminal: bool = Field(default=False, description="Indica se a avaliação foi terminada prematuramente.")
    excecaoRecusada: bool = Field(default=False, description="Indica se houve exceção solicitada e recusada.")
    documentacao: Optional[DocumentacaoResponse] = Field(
        default=None, description="OUT-008: Documentação e arquivo."
    )
    artigos: List[ResultadoArtigoResponse] = Field(
        default_factory=list, description="OUT-007: Vereditos por artigo."
    )
    regras: List[RegistoRegraResponse] = Field(default_factory=list, description="Rasto cronológico de regras DRL.")
    regrasAValidar: List[str] = Field(
        default_factory=list, description="Regras ativadas que exigem validação posterior."
    )


class AvaliacaoResumoResponse(LevisBaseModel):
    """Linha de sumário para consulta histórica de avaliações."""

    avaliacaoId: UUID = Field(..., description="UUID da avaliação.")
    pedidoId: Optional[str] = Field(default=None, description="Identificador do pedido.")
    avaliadaEm: Optional[datetime] = Field(default=None, description="Data/hora da avaliação.")
    lojaCodigo: Optional[str] = Field(default=None, description="Código da loja onde ocorreu.")
    elegibilidade: Optional[ElegibilidadeEnum] = Field(default=None, description="Elegibilidade decidida.")
    tipoTransacao: Optional[TipoTransacaoEnum] = Field(default=None, description="Tipo de transação.")
    valorDevolucao: Optional[Union[Decimal, float]] = Field(default=None, description="Valor total da devolução.")


T = TypeVar("T")


class PaginaResponse(LevisBaseModel, Generic[T]):
    """Estrutura paginada para listas de resultados."""

    conteudo: List[T] = Field(default_factory=list, description="Elementos da página atual.")
    pagina: int = Field(default=0, description="Índice da página (0-indexed).")
    tamanho: int = Field(default=20, description="Tamanho de página configurado.")
    totalElementos: int = Field(default=0, description="Total geral de registos.")
    totalPaginas: int = Field(default=0, description="Total de páginas disponíveis.")


PaginaDto = PaginaResponse


# ==============================================================================
# 4. MODELOS DE EXPLICABILIDADE (5 VIAS)
# ==============================================================================


class CondicaoDto(LevisBaseModel):
    """Condição individual avaliada no antecedente de uma regra."""

    nome: Optional[str] = Field(default=None, description="Identificador da condição.")
    descricao: Optional[str] = Field(default=None, description="Descrição em linguagem natural.")
    cumprida: Optional[bool] = Field(default=None, description="Indica se a condição foi satisfeita.")
    valor: Optional[str] = Field(default=None, description="Valores concretos dos factos avaliados.")
    artigoId: Optional[str] = Field(default=None, description="Artigo associado à condição.")


class RegraEmEsperaDto(LevisBaseModel):
    """Regra que só aguarda pela resposta a um dado em falta para disparar."""

    codigoRegra: Optional[str] = Field(default=None, description="Código da regra.")
    nomeRegra: Optional[str] = Field(default=None, description="Nome da regra DRL.")
    modulo: Optional[str] = Field(default=None, description="Módulo pertencente.")
    artigoId: Optional[str] = Field(default=None, description="Artigo visado.")
    conclusoes: List[str] = Field(default_factory=list, description="Conclusões que produziria.")
    condicoesDoDado: List[CondicaoDto] = Field(
        default_factory=list, description="Condições que leem a pergunta em causa."
    )


class ExplicacaoPorqueResponse(LevisBaseModel):
    """Explicação causal da razão pela qual uma pergunta é feita ao colaborador (Porquê?)."""

    dado: Optional[str] = Field(default=None, description="Código do dado requerido (ex.: IN-010).")
    codigo: Optional[str] = Field(default=None, description="Alias para código do dado requerido (ex.: IN-010).")
    pergunta: Optional[str] = Field(default=None, description="Texto da pergunta a formular ao colaborador.")
    regrasQueDependem: List[str] = Field(
        default_factory=list, description="Regras cujas condições leem este dado."
    )
    regrasEmEspera: List[RegraEmEsperaDto] = Field(
        default_factory=list, description="Regras que dependem apenas deste dado para disparar."
    )
    resumo: Optional[str] = Field(default=None, description="Resumo em linguagem natural.")

    @model_validator(mode="after")
    def _sync_dado_and_codigo(self) -> ExplicacaoPorqueResponse:
        if self.dado and not self.codigo:
            self.codigo = self.dado
        elif self.codigo and not self.dado:
            self.dado = self.codigo
        return self


class DadoEmFaltaDto(LevisBaseModel):
    """Dado em falta no preenchimento do pedido, com o respetivo 'Porquê?'."""

    codigo: str = Field(..., description="Código do dado (IN-001 a IN-010).")
    caminho: str = Field(..., description="Caminho JSON no pedido (ex.: artigos[0].revendivel).")
    descricao: Optional[str] = Field(default=None, description="Descrição do dado em falta.")
    obrigatorio: bool = Field(default=False, description="Indica se é estritamente obrigatório para decidir.")
    porque: Optional[ExplicacaoPorqueResponse] = Field(default=None, description="Justificação da necessidade.")


class DadosEmFaltaResponse(LevisBaseModel):
    """Resposta do assistente a 'O que falta?': perguntas pendentes e justificação causal."""

    dados: List[DadoEmFaltaDto] = Field(default_factory=list, description="Lista de dados em falta.")
    completo: bool = Field(default=False, description="Indica se o pedido tem dados suficientes para decidir.")
    resumo: Optional[str] = Field(default=None, description="Resumo explicativo.")


class PassoExplicacaoDto(LevisBaseModel):
    """Passo individual na cadeia causal de inferência (Como?)."""

    ordem: int = Field(default=0, description="Posição na sequência de raciocínio.")
    modulo: Optional[str] = Field(default=None, description="Módulo da regra.")
    codigoRegra: Optional[str] = Field(default=None, description="Código da regra.")
    nomeRegra: Optional[str] = Field(default=None, description="Nome técnico da regra.")
    artigoId: Optional[str] = Field(default=None, description="Artigo afetado.")
    resultado: Optional[ElegibilidadeEnum] = Field(default=None, description="Resultado estipulado.")
    mensagem: Optional[str] = Field(default=None, description="Mensagem de diagnóstico.")
    aValidar: bool = Field(default=False, description="Requer validação.")


class ExplicacaoComoResponse(LevisBaseModel):
    """Explicação global do caminho de raciocínio seguido pelo motor (Como?)."""

    passos: List[PassoExplicacaoDto] = Field(default_factory=list, description="Sequência de regras acionadas.")
    modulosPercorridos: List[str] = Field(default_factory=list, description="Módulos M0 a M9 visitados.")
    paragem: Optional[str] = Field(default=None, description="Critério ou regra que causou a paragem da inferência.")
    resumo: Optional[str] = Field(default=None, description="Resumo em linguagem natural.")


class ExplicacaoConclusaoResponse(LevisBaseModel):
    """Explicação focalizada em como uma conclusão específica foi deduzida (Como?)."""

    conclusao: Optional[str] = Field(default=None, description="Campo de saída analisado (ex.: OUT-001).")
    artigoId: Optional[str] = Field(default=None, description="Artigo correspondente.")
    valores: Dict[str, str] = Field(default_factory=dict, description="Valores finais dos campos envolvidos.")
    regra: Optional[str] = Field(default=None, description="Regra decisiva que produziu o valor.")
    mensagem: Optional[str] = Field(default=None, description="Mensagem da regra.")
    condicoes: List[CondicaoDto] = Field(default_factory=list, description="Condições que se cumpriram.")
    caminho: List[str] = Field(default_factory=list, description="Sequência de regras até à conclusão.")
    resumo: Optional[str] = Field(default=None, description="Resumo explicativo.")


class ExplicacaoPorqueNaoResponse(LevisBaseModel):
    """Explicação de por que razão uma regra particular não disparou (Porque não?)."""

    codigoRegra: Optional[str] = Field(default=None, description="Código da regra analisada (ex.: PT-003).")
    artigoId: Optional[str] = Field(default=None, description="Artigo correspondente.")
    causa: Optional[CausaNaoDisparoEnum] = Field(default=None, description="Causa determinante do não disparo.")
    regraResponsavel: Optional[str] = Field(default=None, description="Regra de paragem ou precedente impeditiva.")
    variante: Optional[str] = Field(default=None, description="Variante DRL mais próxima de ter disparado.")
    condicoes: List[CondicaoDto] = Field(default_factory=list, description="Avaliação booleana das condições.")
    resumo: Optional[str] = Field(default=None, description="Explicação em linguagem natural.")


class ExplicacaoPorqueNaoConclusaoResponse(LevisBaseModel):
    """Explicação de por que razão um determinado valor de conclusão não foi obtido (Porque não?)."""

    conclusao: Optional[str] = Field(default=None, description="Conclusão analisada (ex.: OUT-001).")
    valor: Optional[str] = Field(default=None, description="Valor pretendido que não foi obtido (ex.: PERMITIR).")
    artigoId: Optional[str] = Field(default=None, description="Artigo correspondente.")
    valorObtido: Optional[str] = Field(default=None, description="Valor efetivamente obtido no veredito.")
    obtida: bool = Field(default=False, description="Indica se o valor pretendido acabou por ser obtido.")
    propostaPor: List[str] = Field(default_factory=list, description="Regras que chegaram a propor o valor.")
    definidoPor: Optional[str] = Field(default=None, description="Regra que fixou o valor final concorrente.")
    regras: List[ExplicacaoPorqueNaoResponse] = Field(
        default_factory=list, description="Explicações detalhadas para as regras que poderiam produzir o valor."
    )
    resumo: Optional[str] = Field(default=None, description="Resumo em linguagem natural.")


class DiferencaDto(LevisBaseModel):
    """Diferença de saída entre a avaliação original e a simulação."""

    alvo: Optional[str] = Field(default=None, description="Entidade afetada ('pedido' ou ID do artigo).")
    campo: Optional[str] = Field(default=None, description="Nome do campo alterado.")
    original: Optional[str] = Field(default=None, description="Valor antes da simulação.")
    simulado: Optional[str] = Field(default=None, description="Valor resultante da simulação.")


class SimulacaoRequest(LevisBaseModel):
    """Pedido de simulação 'E se?' contendo o mapa de alterações hipotéticas."""

    alteracoes: Dict[str, Any] = Field(
        default_factory=dict,
        description="Mapa de caminhos e novos valores (ex.: {'portalOnlineDisponivel': True}).",
    )


class SimulacaoResponse(LevisBaseModel):
    """Resultado da simulação 'E se?' sobre uma avaliação persistida."""

    diferencas: List[DiferencaDto] = Field(default_factory=list, description="Lista de campos com saídas alteradas.")
    regrasNovas: List[str] = Field(default_factory=list, description="Regras adicionais acionadas pela simulação.")
    regrasRemovidas: List[str] = Field(default_factory=list, description="Regras que deixaram de acionar.")
    resumo: Optional[str] = Field(default=None, description="Resumo comparativo em linguagem natural.")
    decisaoSimulada: Optional[DecisaoResponse] = Field(
        default=None, description="Decisão completa produzida na simulação."
    )


# ==============================================================================
# 5. CATÁLOGO DA BASE DE CONHECIMENTO
# ==============================================================================


class VarianteRegraDto(LevisBaseModel):
    """Variante DRL concreta de uma regra pericial."""

    nome: str = Field(..., description="Nome técnico da regra no ficheiro DRL.")
    modulo: Optional[str] = Field(default=None, description="Módulo pertencente.")
    descricao: Optional[str] = Field(default=None, description="Descrição da lógica de negócio.")
    condicoes: List[str] = Field(default_factory=list, description="Cláusulas LHS da regra.")
    conclusoes: List[str] = Field(default_factory=list, description="Conclusões RHS geradas.")
    aValidar: bool = Field(default=False, description="Requer validação operacional.")


class RegraResumoDto(LevisBaseModel):
    """Entrada sumária de uma regra no catálogo do motor."""

    id: str = Field(..., description="Identificador da regra (ex.: PC-002).")
    modulos: List[str] = Field(default_factory=list, description="Módulos onde se aplica.")
    descricao: Optional[str] = Field(default=None, description="Descrição resumida.")
    variantes: int = Field(default=0, description="Número de variantes DRL associadas.")
    aValidar: bool = Field(default=False, description="Contém variantes para validação.")


class RegraDetalheDto(LevisBaseModel):
    """Detalhes completos de uma regra pericial e respetivas variantes DRL."""

    id: str = Field(..., description="Identificador da regra.")
    variantes: List[VarianteRegraDto] = Field(default_factory=list, description="Lista de variantes DRL.")


# ==============================================================================
# 6. AUTENTICAÇÃO E DESENVOLVIMENTO
# ==============================================================================


class DevTokenRequest(LevisBaseModel):
    """Pedido de emissão de token JWT dev para colaborador."""

    id: str = Field(default="DEV-KH", description="Identificador do colaborador.")
    nome: Optional[str] = Field(default="Key Holder", description="Nome do colaborador.")
    funcao: FuncaoEnum = Field(default=FuncaoEnum.KEY_HOLDER, description="Função na loja.")
    aprovadoPeloDM: bool = Field(default=False, description="Aprovado pelo District Manager.")
    idCredencialPOS: Optional[str] = Field(default="POS-KH", description="Credencial do terminal POS.")


ColaboradorDevTokenRequest = DevTokenRequest


class TokenResponse(LevisBaseModel):
    """Token JWT emitido para autenticação Bearer no motor Drools."""

    token: str = Field(..., description="JWT Bearer token assinado.")
    expiraEm: Optional[datetime] = Field(default=None, description="Timestamp de expiração do token.")

    @property
    def tokenAcesso(self) -> str:
        """Alias para compatibilidade de token de acesso."""
        return self.token


# ==============================================================================
# 7. CENÁRIOS DE DEMONSTRAÇÃO
# ==============================================================================


class CenarioExemploResponse(LevisBaseModel):
    """Metadados e payload de um dos 10 cenários oficiais de teste da Levi's."""

    id: int = Field(..., description="Número ordinal do cenário (1 a 10).")
    titulo: str = Field(..., description="Título descritivo do caso de devolução/troca.")
    estado: Optional[str] = Field(default=None, description="Estado de validação do cenário.")
    aValidar: List[str] = Field(default_factory=list, description="Itens para validação.")
    pressupostos: List[str] = Field(default_factory=list, description="Premissas do caso.")
    justificacao: List[str] = Field(default_factory=list, description="Raciocínio esperado por módulos.")
    pedido: PedidoAvaliacaoRequest = Field(..., description="Payload completo pronto para avaliação.")
    esperado: Optional[Dict[str, Any]] = Field(default=None, description="Resultado esperado da decisão.")
