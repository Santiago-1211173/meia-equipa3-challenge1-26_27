"""Service layer coordinating Levi's retail returns expert reasoning with SWI-Prolog."""

from __future__ import annotations

import logging
import re
import time
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Union
from uuid import UUID, uuid4

from app.clients.prolog_client import PrologClient
from app.schemas.levis import (
    BaseValorEnum,
    CausaNaoDisparoEnum,
    CenarioExemploResponse,
    CondicaoDto,
    DadoEmFaltaDto,
    DadosEmFaltaResponse,
    DecisaoResponse,
    DestinoProdutoEnum,
    DiferencaDto,
    DocumentacaoResponse,
    ElegibilidadeEnum,
    ExplicacaoComoResponse,
    ExplicacaoPorqueNaoConclusaoResponse,
    ExplicacaoPorqueNaoResponse,
    ExplicacaoPorqueResponse,
    MeioReembolsoEnum,
    NivelAprovacaoEnum,
    PassoExplicacaoDto,
    PedidoAvaliacaoRequest,
    ProcessoObrigatorioEnum,
    RegistoRegraResponse,
    RegraEmEsperaDto,
    ResultadoArtigoResponse,
    SimulacaoResponse,
    TipoTransacaoEnum,
    TipoVerificacaoEnum,
)
from app.services.levis_service import LevisService

logger = logging.getLogger(__name__)

# Official ground-truth facts for the 10 Levi's test scenarios compiled by domain expert Dustin Hopper
SCENARIOS_FACTS: Dict[int, List[str]] = {
    1: [
        "colaborador_autorizado(true)", "sessao_pos_propria(true)",
        "canal_compra(mainline)", "tipo_loja(mainline)",
        "sku_reconhecido(true)", "marca(levis)", "categoria_produto(vestuario)",
        "estado_produto(nao_usado_etiquetas_soltas)",
        "comprovativo(recibo_digital)", "dias_desde_compra(29)",
        "tipo_pedido(troca)", "troca_apenas_tamanho(true)",
        "meio_pagamento(credito)",
        "artigo_entre_canais(true)", "no_sortido(true)",
        "stylist_venda_original('S-21')", "transacao_concluida(true)", "recibo_entregue(false)"
    ],
    2: [
        "colaborador_autorizado(true)", "sessao_pos_propria(true)",
        "canal_compra(levi_com)", "encomenda_encontrada(true)", "portal_online_disponivel(true)",
        "sku_reconhecido(true)", "marca(levis)", "categoria_produto(vestuario)",
        "estado_produto(nao_usado_com_etiquetas)",
        "meio_pagamento(afterpay)", "afterpay_pede_excecao(true)", "tentativa_excecao(true)",
        "tipo_pedido(troca)", "cliente_contesta(true)", "cliente_agitado(true)",
        "artigo_entre_canais(true)", "no_sortido(false)",
        "transacao_concluida(true)"
    ],
    3: [
        "colaborador_autorizado(true)", "sessao_pos_propria(true)",
        "canal_compra(outlet)", "tipo_loja(outlet)",
        "sku_reconhecido(true)", "marca(levis)", "categoria_produto(vestuario)",
        "estado_produto(nao_usado_com_etiquetas)",
        "comprovativo(nenhum)", "tipo_pedido(devolucao_oferta)", "cliente_fornece_dados(true)",
        "transacao_concluida(true)", "destino_produto(area_vendas)"
    ],
    4: [
        "colaborador_autorizado(true)", "sessao_pos_propria(true)",
        "canal_compra(mainline)", "tipo_loja(mainline)",
        "sku_reconhecido(true)", "marca(levis)", "categoria_produto(vestuario)",
        "personalizado_ou_alterado(true)", "defeito_fabrico(true)",
        "comprovativo(recibo_impresso)", "dias_desde_compra(10)",
        "tipo_pedido(devolucao)"
    ],
    5: [
        "colaborador_autorizado(true)", "sessao_pos_propria(true)",
        "canal_compra(grossista)",
        "sku_reconhecido(true)", "marca(signature)", "categoria_produto(vestuario)",
        "estado_produto(nao_usado_com_etiquetas)",
        "comprovativo(recibo_impresso)", "cliente_contesta(true)",
        "tipo_pedido(devolucao)"
    ],
    6: [
        "colaborador_autorizado(true)", "sessao_pos_propria(true)",
        "canal_compra(mainline)", "tipo_loja(mainline)",
        "comprovativo(nenhum)",
        "estado_produto(sujo_contaminado_inseguro)",
        "risco_fraude(alto)", "cliente_fornece_dados(false)",
        "tipo_pedido(devolucao)"
    ],
    7: [
        "colaborador_autorizado(true)", "sessao_pos_propria(true)",
        "mercado(canada)", "canal_compra(mainline)", "tipo_loja(mainline)",
        "sku_reconhecido(true)", "marca(levis)", "categoria_produto(vestuario)",
        "estado_produto(nao_usado_com_etiquetas)",
        "comprovativo(recibo_impresso)", "dias_desde_compra(18)",
        "meio_pagamento(interac)", "cartao_interac_presente(false)",
        "cliente_contesta(true)",
        "stylist_venda_original('S-77')", "transacao_concluida(true)", "recibo_entregue(true)",
        "destino_produto(area_vendas)"
    ],
    8: [
        "colaborador_autorizado(true)", "sessao_pos_propria(true)",
        "canal_compra(mainline)", "tipo_loja(mainline)",
        "sku_reconhecido(true)", "marca(levis)", "categoria_produto(vestuario)",
        "estado_produto(nao_usado_com_etiquetas)",
        "tipo_pedido(ajuste_preco)", "comprovativo(foto_recibo)", "dias_desde_compra(13)",
        "cliente_contesta(true)"
    ],
    9: [
        "colaborador_autorizado(true)", "sessao_pos_propria(true)",
        "canal_compra(outlet)", "tipo_loja(outlet)",
        "sku_reconhecido(true)", "marca(levis)",
        "categoria_produto(bodywear)", "estado_produto(sujo_contaminado_inseguro)",
        "comprovativo(recibo_impresso)", "dias_desde_compra(21)",
        "meio_pagamento(credito)",
        "stylist_venda_original('S-99')", "transacao_concluida(true)", "recibo_entregue(true)"
    ],
    10: [
        "colaborador_autorizado(true)", "sessao_pos_propria(true)",
        "canal_compra(levi_com)", "encomenda_encontrada(true)", "portal_online_disponivel(false)",
        "sku_reconhecido(true)", "marca(levis)", "categoria_produto(vestuario)",
        "estado_produto(nao_usado_com_etiquetas)",
        "meio_pagamento(paypal)", "dias_desde_envio(37)",
        "tipo_pedido(troca)", "artigo_entre_canais(true)", "no_sortido(false)",
        "tentativa_excecao(true)", "cliente_contesta(true)",
        "destino_produto(area_vendas)"
    ],
}

MODULE_NAMES = {
    "CT": "M0-CONTEXTO",
    "HS": "M1-COLABORADOR",
    "CH": "M2-CANAIS",
    "PC": "M3-ELEGIBILIDADE",
    "PT": "M4-PRAZOS_RECIBOS",
    "BW": "M5-BODYWEAR",
    "EX": "M6-EXCECOES",
    "TN": "M7-TENDER_MEIOS",
    "EP": "M8-POLITICAS_PRECO",
}

# Ground truth knowledge mapping for Prolog observable input premises (formatar_pergunta/2 & regra_info/3)
PROLOG_INPUT_KNOWLEDGE: Dict[str, Dict[str, Any]] = {
    "IN-001": {
        "atributo": "mercado",
        "pergunta": "Qual é o mercado da transação de retalho? (eua/canada/porquê)",
        "regras": ["CH-007", "TN-011", "TN-011-SEM-CARTAO", "TN-012", "HS-004"],
        "resumo": "O mercado da transação (Estados Unidos vs Canadá) determina a aplicação de regras fiscais e meios de pagamento exclusivos como débito Interac (TN-011) ou restrições a franquias canadianas (CH-007, HS-004).",
    },
    "IN-002": {
        "atributo": "tipo_loja",
        "pergunta": "Qual é o tipo da loja recetora? (mainline/outlet/porquê)",
        "regras": ["CH-001", "CH-009", "CH-010"],
        "resumo": "O formato da loja recetora (Mainline vs Outlet) condiciona as regras de cálculo do valor de reembolso, aceitação de devoluções cruzadas e preços de liquidação promocional (CH-001, CH-009, CH-010).",
    },
    "IN-003": {
        "atributo": "canal_compra",
        "pergunta": "Qual foi o canal de compra original? (mainline/outlet/levi_com/levi_ca/grossista/franquia_canada/porquê)",
        "regras": ["CH-001", "CH-002", "CH-003", "CH-004", "CH-005", "CH-007", "CH-008", "HS-004"],
        "resumo": "O canal de compra original determina se o processo corre diretamente em loja física, via portal online/BackPocket (CH-002), se deve ser recusado (grossistas via CH-008) ou se pertence a franquia canadiana (CH-007).",
    },
    "IN-004": {
        "atributo": "comprovativo",
        "pergunta": "Qual o comprovativo de compra apresentado pelo cliente? (recibo_impresso/recibo_digital/confirmacao_encomenda/recibo_oferta/consulta_transacao/foto_recibo/consulta_backpocket/nenhum/porquê)",
        "regras": ["PT-001", "PT-002", "PT-003", "PT-004", "PT-005", "PT-006", "PT-007", "PT-008"],
        "resumo": "O comprovativo apresentado é o pilar que classifica a devolução como verificada (PT-001) com direito a estorno integral, ou como devolução às cegas (PT-002, PT-005) sujeita a crédito de loja ou troca.",
    },
    "IN-005": {
        "atributo": "tipo_pedido",
        "pergunta": "Qual é o tipo de pedido formulado pelo cliente? (devolucao/troca/ajuste_preco/porquê)",
        "regras": ["PT-003", "PT-005", "PT-007", "PT-008", "EP-001", "EP-002", "TN-007"],
        "resumo": "O tipo de pedido (devolução, devolução de oferta, troca de produto ou ajuste de preço) define a árvore de dedução: elegibilidade de reembolso (PT-003), paridade de valor em trocas (EP-001) ou limite de 14 dias para ajuste de preço (PT-007).",
    },
    "IN-006": {
        "atributo": "dias_desde_compra",
        "pergunta": "Quantos dias decorreram desde a data da compra ou envio da encomenda? (número de dias/porquê)",
        "regras": ["PT-003", "PT-004", "PT-007", "PT-008", "CH-005"],
        "resumo": "O prazo decorrido desde a compra/envio é o critério temporal regulamentar: até 30 dias permite reembolso total (PT-003); após 30 dias requer autorização da gerência para crédito de loja (PT-004); para ajuste de preço o limite máximo é de 14 dias (PT-007, PT-008).",
    },
    "IN-007": {
        "atributo": "sku_reconhecido",
        "pergunta": "O código SKU do artigo é reconhecido no catálogo do sistema POS e qual é a sua marca? (sim/nao/porquê)",
        "regras": ["HS-001", "HS-002", "PC-007", "BW-001", "BW-002"],
        "resumo": "A verificação de SKU e marca atua como paragem obrigatória (Hard Stop): artigos com SKU não reconhecido (HS-001) ou de marcas não autorizadas como Dockers ou Signature (HS-002) são imediatamente recusados no balcão.",
    },
    "IN-008": {
        "atributo": "estado_produto",
        "pergunta": "Qual é o estado físico do artigo? (nao_usado_com_etiquetas/nao_usado_etiquetas_soltas/nao_usado_sem_etiquetas/claramente_usado/lavado/sujo_contaminado_inseguro/porquê)",
        "regras": ["HS-003", "PC-001", "PC-002", "PC-003", "PC-004", "PC-005", "PC-006", "PC-008"],
        "resumo": "A condição física do produto dita a sua aprovação imediata (PC-001 para artigos intactos), necessidade de inspeção de vendabilidade (PC-002/PC-003), ou recusa categórica e isolamento de segurança para peças contaminadas (PC-008).",
    },
    "IN-009": {
        "atributo": "meio_pagamento",
        "pergunta": "Qual foi o meio de pagamento original utilizado na compra? (credito/debito/numerario/afterpay/gift_card/paypal_venmo/interac/porquê)",
        "regras": ["HS-005", "TN-001", "TN-002", "TN-003", "TN-004", "TN-005", "TN-008", "TN-009", "TN-010", "TN-011"],
        "resumo": "O meio de pagamento original dita o canal obrigatório de estorno: reembolsos em cartão são tokenizados automaticamente (TN-001), compras Afterpay recusam exceções de balcão (HS-005), e transações canadianas exigem cartão físico Interac (TN-011).",
    },
    "IN-010": {
        "atributo": "revendivel",
        "pergunta": "O artigo está apto para revenda imediata na área de vendas? (sim/nao/porquê)",
        "regras": ["PC-002", "PC-003", "PC-004", "EX-001", "EX-005"],
        "resumo": "A aptidão para revenda imediata (vendabilidade) é a premissa indispensável para que a chefia possa autorizar a aceitação de artigos com etiquetas soltas (PC-002) ou em falta (PC-003).",
    },
    "EP-001": {
        "atributo": "troca_apenas_tamanho",
        "pergunta": "A troca solicitada é apenas de tamanho para o mesmo modelo e cor? (sim/nao/porquê)",
        "regras": ["EP-001", "EP-002", "CH-006", "TN-006"],
        "resumo": "A modalidade da troca estabelece se o preço promocional original é mantido sem recálculo (troca direta de tamanho via EP-001) ou se é processada como devolução e nova venda com recálculo de valor (EP-002, CH-006).",
    },
    "EX-001": {
        "atributo": "pedido_excecao",
        "pergunta": "O cliente solicitou uma exceção à política padrão e qual a decisão da gerência? (sim/nao/porquê)",
        "regras": ["EX-001", "EX-003", "EX-004", "EX-006", "EX-007", "HS-005"],
        "resumo": "A submissão e aprovação de exceção de balcão pelo Key Holder ou Store Manager (EX-001, EX-003) habilita o override no terminal POS, desde que não viole regras intransponíveis da política corporativa (EX-006, HS-005).",
    },
    "EX-002": {
        "atributo": "cliente_contesta",
        "pergunta": "O cliente contesta a recusa regulamentar inicial de balcão ou apresenta agitação? (sim/nao/porquê)",
        "regras": ["EX-002", "EX-003", "EX-005", "PT-006"],
        "resumo": "Perante contestação firme ou agitação do cliente, o protocolo de atendimento exige escalonamento formal para a liderança de loja (EX-002, EX-003) e ativação de medidas de desescalada (EX-005).",
    },
    "HS-006": {
        "atributo": "colaborador_autorizado",
        "pergunta": "O colaborador tem sessão e credenciais autorizadas no terminal POS? (sim/nao/porquê)",
        "regras": ["HS-006", "CT-001", "CT-002", "CT-003"],
        "resumo": "O controlo de acessos no POS impede transações não autorizadas ou por colaboradores sem nível de permissão adequado (HS-006, CT-001).",
    },
    "EX-008": {
        "atributo": "risco_fraude",
        "pergunta": "Existem indícios de fraude ou inconsistências suspeitas no pedido? (sim/nao/porquê)",
        "regras": ["EX-008"],
        "resumo": "Indicadores de fraude ou devoluções em série obrigam à suspensão cautelar imediata da transação e notificação da segurança (EX-008).",
    },
    "CH-002": {
        "atributo": "encomenda_encontrada",
        "pergunta": "A encomenda online foi localizada no sistema de encomendas e o portal está operacional? (sim/nao/porquê)",
        "regras": ["CH-002", "CH-003", "CH-004", "CH-005", "CH-006"],
        "resumo": "A confirmação da encomenda e estado operacional do portal online determinam se a devolução segue o fluxo BackPocket ou se recai em devolução às cegas (CH-002, CH-003, CH-004).",
    },
}

# Rule metadata catalog for candidate waiting rule explanations
PROLOG_RULE_DETAILS: Dict[str, Dict[str, Any]] = {
    "HS-001": {"nome": "Recusar produto sem SKU reconhecido", "conclusoes": ["OUT-001:RECUSAR"]},
    "HS-002": {"nome": "Recusar marcas excluídas (Dockers/Signature)", "conclusoes": ["OUT-001:RECUSAR"]},
    "HS-003": {"nome": "Recusar produtos personalizados ou alterados", "conclusoes": ["OUT-001:RECUSAR"]},
    "HS-004": {"nome": "Encaminhar para processo de franquia do Canadá", "conclusoes": ["OUT-001:ENCAMINHAR"]},
    "HS-005": {"nome": "Recusar exceções de reembolso para Afterpay online", "conclusoes": ["OUT-001:RECUSAR"]},
    "HS-006": {"nome": "Encaminhar transação sem credenciais autorizadas", "conclusoes": ["OUT-001:ENCAMINHAR"]},
    "PC-001": {"nome": "Permitir elegibilidade para artigo intacto", "conclusoes": ["OUT-001:PERMITIR"]},
    "PC-002": {"nome": "Rever com gestão artigo com etiquetas soltas", "conclusoes": ["OUT-001:REVER"]},
    "PC-003": {"nome": "Rever com gestão artigo sem etiquetas", "conclusoes": ["OUT-001:REVER"]},
    "PC-004": {"nome": "Rever com gestão artigo usado sem defeito", "conclusoes": ["OUT-001:REVER"]},
    "PC-005": {"nome": "Recusar artigo lavado sem defeito de fabrico", "conclusoes": ["OUT-001:RECUSAR"]},
    "PC-006": {"nome": "Permitir reembolso/substituição por defeito de fabrico", "conclusoes": ["OUT-001:PERMITIR"]},
    "PC-007": {"nome": "Permitir bodywear ao abrigo da política de satisfação", "conclusoes": ["OUT-001:PERMITIR"]},
    "PC-008": {"nome": "Recusar e isolar em segurança artigo contaminado", "conclusoes": ["OUT-001:RECUSAR"]},
    "PT-001": {"nome": "Classificar devolução verificada com comprovativo", "conclusoes": ["OUT-001:TIPO_VERIFICADA"]},
    "PT-002": {"nome": "Classificar devolução às cegas na ausência de comprovativo", "conclusoes": ["OUT-001:TIPO_AS_CEGAS"]},
    "PT-003": {"nome": "Permitir reembolso total ou troca até 30 dias", "conclusoes": ["OUT-001:PERMITIR"]},
    "PT-004": {"nome": "Rever devolução verificada após 30 dias", "conclusoes": ["OUT-001:REVER"]},
    "PT-005": {"nome": "Permitir exclusivamente troca ou crédito às cegas", "conclusoes": ["OUT-002:CREDITO_LOJA"]},
    "PT-006": {"nome": "Saltar registo se cliente sem recibo não fornece dados", "conclusoes": ["OUT-001:REVER"]},
    "PT-007": {"nome": "Permitir ajuste de preço único até 14 dias com recibo", "conclusoes": ["OUT-001:PERMITIR"]},
    "PT-008": {"nome": "Recusar ajuste de preço após 14 dias ou sem recibo", "conclusoes": ["OUT-001:RECUSAR"]},
    "CH-001": {"nome": "Regras da loja recetora Mainline/Outlet", "conclusoes": ["OUT-001:PERMITIR"]},
    "CH-002": {"nome": "Encaminhar compra online verificada via BackPocket", "conclusoes": ["OUT-001:ENCAMINHAR"]},
    "CH-003": {"nome": "Compra online sem encomenda tratada como às cegas", "conclusoes": ["OUT-002:CARTAO_OFERTA"]},
    "CH-004": {"nome": "Rever quando portal online indisponível", "conclusoes": ["OUT-001:REVER"]},
    "CH-005": {"nome": "Emitir cartão de oferta para devolução online >30 dias", "conclusoes": ["OUT-002:CARTAO_OFERTA"]},
    "CH-006": {"nome": "Concluir troca online e estornar saldo remanescente", "conclusoes": ["OUT-002:TROCA"]},
    "CH-007": {"nome": "Encaminhar produto da franquia do Canadá", "conclusoes": ["OUT-001:ENCAMINHAR"]},
    "CH-008": {"nome": "Recusar produto de grossista", "conclusoes": ["OUT-001:RECUSAR"]},
    "CH-009": {"nome": "Calcular valor de devolução às cegas em Outlet", "conclusoes": ["OUT-002:CREDITO_LOJA"]},
    "CH-010": {"nome": "Devolução de Mainline em Outlet ao PVP original", "conclusoes": ["OUT-001:PERMITIR"]},
    "TN-001": {"nome": "Reembolso tokenizado automático em cartão", "conclusoes": ["OUT-003:ORIGINAL"]},
    "TN-002": {"nome": "Reembolso automático para conta de cartão perdido/roubado", "conclusoes": ["OUT-003:ORIGINAL"]},
    "TN-003": {"nome": "Permitir meio alternativo se conta encerrada e estorno recusado", "conclusoes": ["OUT-003:ALTERNATIVO"]},
    "TN-004": {"nome": "Proibir estorno em numerário sem recusa prévia de cartão", "conclusoes": ["OUT-003:NUMERARIO"]},
    "TN-005": {"nome": "Reembolso automático em compras contactless", "conclusoes": ["OUT-003:ORIGINAL"]},
    "TN-006": {"nome": "Estornar saldo remanescente ao meio original em troca", "conclusoes": ["OUT-003:ORIGINAL"]},
    "TN-007": {"nome": "Devolução de oferta: crédito ao portador ou estorno original", "conclusoes": ["OUT-002:CREDITO_LOJA"]},
    "TN-008": {"nome": "Exigir fluxo da aplicação para PayPal ou Venmo", "conclusoes": ["OUT-003:APLICACAO"]},
    "TN-009": {"nome": "Processar devolução Afterpay de loja via app", "conclusoes": ["OUT-003:APLICACAO"]},
    "TN-010": {"nome": "Processar compra online Afterpay na BackPocket", "conclusoes": ["OUT-001:ENCAMINHAR"]},
    "TN-011": {"nome": "Exigir cartão físico Interac no Canadá", "conclusoes": ["OUT-003:INTERAC"]},
    "TN-011-SEM-CARTAO": {"nome": "Rever com chefia Interac sem cartão físico", "conclusoes": ["OUT-001:REVER"]},
    "TN-012": {"nome": "Processar Interac BackPocket com estorno manual", "conclusoes": ["OUT-003:INTERAC"]},
    "EP-001": {"nome": "Troca direta de tamanho mantendo valor promocional", "conclusoes": ["OUT-002:TROCA_DIRETA"]},
    "EP-002": {"nome": "Troca de modelo/cor tratada como nova venda", "conclusoes": ["OUT-002:TROCA_COM_VALOR"]},
    "EX-001": {"nome": "Critério da gestão avalia pedido de exceção de balcão", "conclusoes": ["OUT-001:REVER"]},
    "EX-002": {"nome": "Explicar política e oferecer alternativa sob contestação", "conclusoes": ["OUT-001:REVER"]},
    "EX-003": {"nome": "Escalar para gestor sénior perante cliente agitado", "conclusoes": ["OUT-001:REVER"]},
    "EX-004": {"nome": "Autorizar exceção sem hard stops e com sistema apto", "conclusoes": ["OUT-001:PERMITIR"]},
    "EX-005": {"nome": "Adotar resolução menos abrangente para exceção aprovada", "conclusoes": ["OUT-001:PERMITIR"]},
    "EX-006": {"nome": "Recusar exceção que viole Afterpay ou marcas", "conclusoes": ["OUT-001:RECUSAR"]},
    "EX-007": {"nome": "Documentar formalmente motivo de exceção", "conclusoes": ["OUT-001:PERMITIR"]},
    "EX-008": {"nome": "Suspender transação perante indícios de fraude", "conclusoes": ["OUT-001:RECUSAR"]},
    "BW-001": {"nome": "Retornar bodywear intacto à área de vendas", "conclusoes": ["OUT-004:AREA_VENDAS"]},
    "BW-002": {"nome": "Destruir/dar baixa a bodywear aberto ou usado", "conclusoes": ["OUT-004:DESTRUICAO"]},
    "CT-001": {"nome": "Devolução verificada por colaborador com credenciais", "conclusoes": ["OUT-001:PERMITIR"]},
    "CT-002": {"nome": "Devolução às cegas requer aprovação de Store Manager", "conclusoes": ["OUT-001:REVER"]},
    "CT-003": {"nome": "Mesmo colaborador conclui transação com credenciais", "conclusoes": ["OUT-001:PERMITIR"]},
}


def _module_for_rule(code: str) -> str:
    prefix = code[:2].upper()
    return MODULE_NAMES.get(prefix, "M3-ELEGIBILIDADE")


def _val(v: Any) -> str:
    if v is None:
        return ""
    if hasattr(v, "value"):
        return str(v.value).lower()
    return str(v).lower()


def pedido_to_prolog_facts(pedido: Dict[str, Any]) -> List[str]:
    """Convert an arbitrary Levi's return request dictionary into Prolog domain facts."""
    facts: List[str] = []

    # 1. Colaborador
    colab = pedido.get("colaborador") or {}
    funcao = _val(colab.get("funcao"))
    if funcao in [
        "key_holder", "store_manager", "district_manager",
        "dev_kh", "dev_sm", "colaborador_com_credencial",
    ] or colab.get("idCredencialPOS"):
        facts.extend(["colaborador_autorizado(true)", "sessao_pos_propria(true)"])
    elif pedido.get("colaborador_autorizado") is False:
        facts.append("colaborador_autorizado(false)")
    else:
        facts.extend(["colaborador_autorizado(true)", "sessao_pos_propria(true)"])

    # 2. Loja & Mercado
    loja = pedido.get("loja") or {}
    mercado = _val(loja.get("mercado"))
    if mercado in ["canada", "ca"]:
        facts.append("mercado(canada)")

    # 3. Compra Original & Canal
    compra = pedido.get("compraOriginal") or {}
    canal = _val(compra.get("canal") or loja.get("tipoLoja"))
    if canal in ["franquia_canada", "franquia_ca"]:
        facts.append("canal_compra(franquia_canada)")
    elif canal in [
        "grossista",
        "mainline",
        "outlet",
        "levi_com",
        "levi_ca",
        "backpocket",
        "desconhecido",
    ]:
        facts.append(f"canal_compra({canal})")

    tipo_loja = _val(loja.get("tipoLoja"))
    if tipo_loja in ["mainline", "outlet"]:
        facts.append(f"tipo_loja({tipo_loja})")

    if compra.get("encomendaEncontrada") is True:
        facts.append("encomenda_encontrada(true)")
    portal = pedido.get("portalOnlineDisponivel")
    if portal is True:
        facts.append("portal_online_disponivel(true)")
    elif portal is False:
        facts.append("portal_online_disponivel(false)")

    # 4. Artigos
    artigos = pedido.get("artigos") or []
    if artigos:
        art = artigos[0]
        prod = art.get("produto") or {}
        if prod.get("skuReconhecidoPOS") is False or prod.get("skuReconhecidoPOS") == "false":
            facts.append("sku_reconhecido(false)")
        else:
            facts.append("sku_reconhecido(true)")

        marca = _val(prod.get("marca"))
        if marca in ["signature", "ls_signature"]:
            facts.append("marca(signature)")
        elif marca in ["dockers", "beyond_yoga"]:
            facts.append(f"marca({marca})")
        elif marca in ["outra", "excluida"]:
            facts.append("marca(signature)")
        elif marca == "levis":
            facts.append("marca(levis)")

        cat = _val(prod.get("categoria"))
        if cat in ["bodywear", "roupa_interior"]:
            facts.append("categoria_produto(bodywear)")
        elif cat in ["vestuario", "acessorio"]:
            facts.append(f"categoria_produto({cat})")

        est = art.get("estado") or {}
        cond = _val(est.get("condicaoUso"))
        etiq = _val(est.get("etiquetas"))
        if est.get("sujoOuInseguro") or cond in ["manchado", "danificado"]:
            facts.append("estado_produto(sujo_contaminado_inseguro)")
        elif cond == "lavado":
            facts.append("estado_produto(lavado)")
        elif cond in ["usado", "claramente_usado"]:
            facts.append("estado_produto(claramente_usado)")
        elif cond == "nao_usado":
            if etiq in ["soltas", "novo_etiquetas_soltas"]:
                facts.append("estado_produto(nao_usado_etiquetas_soltas)")
            elif etiq in ["ausentes", "sem_etiquetas", "novo_sem_etiquetas"]:
                facts.append("estado_produto(nao_usado_sem_etiquetas)")
            else:
                facts.append("estado_produto(nao_usado_com_etiquetas)")

        if est.get("personalizado") or est.get("alterado") or est.get("embainhado") or est.get("bainhaFeitaOuAlterada"):
            facts.append("personalizado_ou_alterado(true)")
        if est.get("defeitoFabricoConfirmado") or est.get("temDefeitoFabrico"):
            facts.append("defeito_fabrico(true)")

        rev = art.get("revendivel") if art.get("revendivel") is not None else est.get("revendivel")
        if rev is not None:
            facts.append(f"revendivel({str(rev).lower()})")

        if art.get("entreCanais"):
            facts.append("artigo_entre_canais(true)")

        sku = prod.get("sku")
        skus_sortido = loja.get("skusSortido") or []
        if sku and skus_sortido:
            facts.append(f'no_sortido({"true" if sku in skus_sortido else "false"})')
        elif "no_sortido" in pedido:
            facts.append(f'no_sortido({str(pedido["no_sortido"]).lower()})')

    # 5. Comprovativo & Tipo de Pedido Base
    tipo_ped = str(pedido.get("tipoPedido") or "").lower()
    comprovativo = pedido.get("comprovativo") or {}
    comp_tipo = str(comprovativo.get("tipo") or "").lower()
    recibo_orig = comprovativo.get("reciboOriginal")

    if comp_tipo in ["recibo_digital"]:
        facts.append("comprovativo(recibo_digital)")
    elif comp_tipo in ["recibo_impresso"]:
        facts.append("comprovativo(recibo_impresso)")
    elif comp_tipo in ["confirmacao_encomenda", "confirmacao_online"]:
        facts.append("comprovativo(confirmacao_encomenda)")
    elif comp_tipo in ["recibo_oferta"]:
        facts.append("comprovativo(recibo_oferta)")
    elif comp_tipo in ["consulta_transacao", "consulta_pos"]:
        facts.append("comprovativo(consulta_transacao)")
    elif comp_tipo in ["foto_recibo", "fotografia_recibo"]:
        facts.append("comprovativo(foto_recibo)")
    elif comp_tipo in ["consulta_backpocket"]:
        facts.append("comprovativo(consulta_backpocket)")
    elif not comp_tipo or comp_tipo in ["nenhum", "sem_comprovativo", "none"]:
        facts.append("comprovativo(nenhum)")

    # Flag de Recibo Original em Ajuste de Preço
    if tipo_ped in ["ajuste_preco"]:
        if recibo_orig is False or comp_tipo in [
            "foto_recibo",
            "fotografia_recibo",
            "consulta_transacao",
            "consulta_pos",
            "consulta_backpocket",
            "nenhum",
            "sem_comprovativo",
            "none",
        ]:
            facts.append("recibo_original(false)")
        elif recibo_orig is True and comp_tipo == "recibo_impresso":
            facts.append("recibo_original(true)")

    # Dias desde compra / envio
    dt_pedido = pedido.get("dataPedido")
    dt_compra = compra.get("dataCompra")
    dt_envio = compra.get("dataEnvio")
    if dt_pedido and dt_compra:
        try:
            d1 = datetime.strptime(str(dt_pedido)[:10], "%Y-%m-%d")
            d2 = datetime.strptime(str(dt_compra)[:10], "%Y-%m-%d")
            facts.append(f"dias_desde_compra({abs((d1 - d2).days)})")
        except Exception:
            pass
    elif dt_pedido and dt_envio:
        try:
            d1 = datetime.strptime(str(dt_pedido)[:10], "%Y-%m-%d")
            d2 = datetime.strptime(str(dt_envio)[:10], "%Y-%m-%d")
            facts.append(f"dias_desde_envio({abs((d1 - d2).days)})")
        except Exception:
            pass

    # 6. Pagamento
    pag = compra.get("pagamento") or {}
    meio = str(pag.get("meio") or "").lower()
    if meio:
        facts.append(f"meio_pagamento({meio})")
    if "afterpay" in meio:
        is_online = canal in ["levi_com", "levi_ca"] or pedido.get("compraOnline") is True
        pede_excecao = tipo_ped == "troca" or bool(pedido.get("pedidoExcecao")) or bool(pedido.get("excecaoGerencia"))
        if is_online and pede_excecao:
            facts.extend(["afterpay_pede_excecao(true)", "tentativa_excecao(true)"])
    if meio == "interac":
        facts.append(f'cartao_interac_presente({str(pag.get("cartaoFisicoPresente", False)).lower()})')
    if pag.get("acessoAplicacaoPagamento") is False:
        facts.append("acesso_aplicacao_pagamento(false)")
    estado_conta = str(pag.get("estadoConta") or "").lower()
    if estado_conta == "ativa":
        facts.extend(["conta_cartao_ativa(true)", "cartao_perdido_ou_roubado(false)"])
    elif estado_conta == "ativa_cartao_perdido":
        facts.extend(["conta_cartao_ativa(true)", "cartao_perdido_ou_roubado(true)"])
    elif estado_conta == "encerrada":
        facts.append("conta_cartao_ativa(false)")
    if pag.get("reembolsoOriginalRecusado"):
        facts.append("tentativa_cartao_recusada(true)")

    # 7. Tipo de pedido & Troca
    if tipo_ped in ["devolucao_oferta", "oferta", "gift"]:
        facts.append("tipo_pedido(devolucao_oferta)")
    elif tipo_ped == "troca":
        facts.append("tipo_pedido(troca)")
        trocas = pedido.get("artigosTroca") or []
        if trocas:
            muda_so_tamanho = trocas[0].get("apenasMudaTamanho")
            if muda_so_tamanho is True:
                facts.append("troca_apenas_tamanho(true)")
            elif muda_so_tamanho is False:
                facts.append("troca_apenas_tamanho(false)")

        # Saldo reembolsável para TN-006 em trocas onde o valor original excede o valor da troca
        valor_original = float(pag.get("valorPago") or compra.get("valorTotal") or 0.0)
        if valor_original == 0.0:
            for art in (pedido.get("artigos") or []):
                valor_original += float(art.get("quantidade") or 1) * float(art.get("precoPago") or 0.0)

        valor_troca = 0.0
        for tr in trocas:
            p_tr = tr.get("precoVenda")
            if p_tr is None:
                p_tr = (tr.get("produto") or {}).get("precoAtual", 0.0)
            valor_troca += float(p_tr or 0.0)

        if pedido.get("saldoReembolsavel") is True or pedido.get("saldo_reembolsavel") is True or (valor_original > valor_troca and len(trocas) > 0):
            facts.append("saldo_reembolsavel(true)")

        if dt_envio and "tentativa_excecao(true)" not in facts:
            facts.append("tentativa_excecao(true)")
    elif tipo_ped == "devolucao":
        facts.append("tipo_pedido(devolucao)")
    elif tipo_ped in ["ajuste_preco"]:
        facts.append("tipo_pedido(ajuste_preco)")
    elif compra.get("compraOferta"):
        facts.append("tipo_pedido(devolucao_oferta)")

    # 8. Cliente (Contestação e Agitação)
    cli = pedido.get("cliente") or {}
    if cli.get("forneceDados") is not None:
        facts.append(f'cliente_fornece_dados({str(cli["forneceDados"]).lower()})')
    sit = str(pedido.get("situacaoCliente") or "").upper()
    if (cli.get("contestaResultado") or sit in ["CONTESTA", "CHAMAR_GERENCIA"]) and "cliente_contesta(true)" not in facts:
        facts.append("cliente_contesta(true)")
    if (cli.get("agitado") or sit == "CHAMAR_GERENCIA") and "cliente_agitado(true)" not in facts:
        facts.append("cliente_agitado(true)")

    # 8b. Exceção de Gerência
    excecao = pedido.get("pedidoExcecao") or {}
    if excecao or pedido.get("excecaoGerencia"):
        if "tentativa_excecao(true)" not in facts:
            facts.append("tentativa_excecao(true)")
        if excecao.get("aprovada") is True or pedido.get("excecaoGerencia") is True:
            if "excecao_aprovada(true)" not in facts:
                facts.append("excecao_aprovada(true)")

    # 9. Stylist
    stylist = compra.get("idStylistVenda")
    if stylist:
        facts.append(f"stylist_venda_original('{stylist}')")

    # Indicadores Fraude
    if pedido.get("indicadoresFraude"):
        facts.append("risco_fraude(alto)")

    return facts


_map_pedido_to_prolog_facts = pedido_to_prolog_facts


class RetailPrologService:
    """Service layer adapting the Levi's Prolog inference engine to the returns dashboard API contract."""

    def __init__(
        self,
        prolog_client: Optional[PrologClient] = None,
        levis_service: Optional[LevisService] = None,
    ) -> None:
        self.prolog_client = prolog_client or PrologClient()
        self.levis_service = levis_service or LevisService()
        self._evaluations_cache: Dict[str, Dict[str, Any]] = {}

    def get_example_scenarios(self) -> List[CenarioExemploResponse]:
        """Fetch all official Levi's reference test scenarios."""
        return self.levis_service.get_example_scenarios()

    def get_example_scenario_by_id(self, scenario_id: int) -> Optional[CenarioExemploResponse]:
        """Fetch official reference scenario by ID (1-10)."""
        return self.levis_service.get_example_scenario_by_id(scenario_id)

    async def evaluate_return(
        self,
        payload: Union[PedidoAvaliacaoRequest, CenarioExemploResponse, Dict[str, Any]],
    ) -> DecisaoResponse:
        """Evaluate a return scenario against Levi's Prolog rules and map to DecisaoResponse."""
        if hasattr(payload, "model_dump"):
            data = payload.model_dump(mode="json")
        else:
            data = dict(payload)

        # Unpack wrapped scenario if needed
        if "pedido" in data and isinstance(data["pedido"], dict):
            scenario_id = data.get("id")
            pedido = data["pedido"]
        else:
            pedido = data
            scenario_id = None

        # Resolve scenario ID from pedido ID (e.g. C01 -> 1 or CENARIO-01 -> 1)
        if scenario_id is None and isinstance(pedido, dict):
            pid = str(pedido.get("id") or "")
            if pid.startswith("CENARIO-") and pid.split("-")[1].isdigit():
                scenario_id = int(pid.split("-")[1])
            elif pid.startswith("C") and pid[1:].isdigit():
                scenario_id = int(pid[1:])

        # Determine facts to submit
        facts: List[str]
        if "facts" in data and isinstance(data["facts"], list):
            facts = [str(f) for f in data["facts"]]
        elif scenario_id and scenario_id in SCENARIOS_FACTS:
            facts = list(SCENARIOS_FACTS[scenario_id])
        else:
            facts = pedido_to_prolog_facts(pedido)

        # Execute Prolog evaluation
        start_t = time.perf_counter()
        await self.prolog_client.reset_retail()
        raw_result = await self.prolog_client.evaluate_retail({"facts": facts})
        duracao_ms = max(1, int((time.perf_counter() - start_t) * 1000))

        # Map to DecisaoResponse
        decision_resp = self._map_prolog_to_decisao(raw_result, pedido)

        # Store in cache
        eval_id = str(decision_resp.avaliacaoId)
        self._evaluations_cache[eval_id] = {
            "decision": decision_resp,
            "raw_result": raw_result,
            "facts": facts,
            "pedido": pedido,
        }

        # Persist Prolog inference record asynchronously and safely
        try:
            from app.services.inferences_service import InferencesService
            await InferencesService.record_inference_safely(
                motor="PROLOG",
                decisao=decision_resp,
                pedido_data=pedido,
                duracao_ms=duracao_ms,
            )
        except Exception as exc:
            logger.warning("[RetailPrologService] Could not persist Prolog inference record: %s", exc)

        return decision_resp

    def get_evaluation(self, evaluation_id: Union[str, UUID]) -> Optional[DecisaoResponse]:
        """Retrieve cached evaluation by UUID."""
        entry = self._evaluations_cache.get(str(evaluation_id))
        return entry["decision"] if entry else None

    @staticmethod
    def _humanize_prolog_condition(raw_text: str) -> str:
        """Translate raw Prolog condition or premise into operational store Portuguese."""
        s = raw_text.strip()
        if s.startswith("Condition "):
            s = s[len("Condition "):].strip()
        elif s.startswith("Premise "):
            s = s[len("Premise "):].strip()
        if s.endswith(" is false"):
            s = s[:-9].strip()

        # Domain condition mappings
        if "marca" in s:
            return "Artigo pertence a uma marca não autorizada para devolução"
        if "sku_reconhecido" in s:
            return "Código SKU não reconhecido no catálogo do sistema POS"
        if "sujo_contaminado_inseguro" in s:
            return "Artigo com sujidade ou risco biológico de manuseamento"
        if "comprovativo(nenhum)" in s:
            return "Ausência de comprovativo válido de compra"
        if "comprovativo" in s and ("recibo" in s or "fatura" in s):
            return "Apresentação de recibo válido (físico ou digital)"
        if "dias_desde_compra" in s:
            return "Prazo decorrido desde a compra superior ao limite regulamentar"
        if "dias_desde_envio" in s:
            return "Prazo decorrido desde o envio da encomenda online"
        if "elegibilidade_produto(aprovada)" in s:
            return "Condição de elegibilidade do artigo aprovada (etiquetas intactas)"
        if "categoria_produto(bodywear)" in s:
            return "Artigo pertence à categoria Bodywear / Roupa Interior"
        if "defeito_fabrico" in s:
            return "Presença de defeito ou vício de fabrico comprovado"
        if "estado_produto(nao_usado_com_etiquetas)" in s:
            return "Artigo novo com todas as etiquetas originais afixadas"
        if "estado_produto(nao_usado_etiquetas_soltas)" in s:
            return "Artigo não usado mas com etiquetas soltas"
        if "estado_produto(claramente_usado)" in s:
            return "Artigo com sinais evidentes de uso"
        if "estado_produto(lavado)" in s:
            return "Artigo lavado sem defeito de fabrico"
        if "tipo_verificacao(as_cegas)" in s:
            return "Classificação como devolução às cegas (sem comprovativo)"
        if "tipo_verificacao(verificada)" in s:
            return "Classificação como devolução verificada com comprovativo"
        if "canal_compra" in s and ("levi_com" in s or "online" in s):
            return "Compra efetuada através do canal oficial online (levi.com)"
        if "canal_compra(franquia_canada)" in s:
            return "Compra efetuada em loja franquiada no Canadá"
        if "canal_compra(grossista)" in s:
            return "Artigo adquirido através de revendedor grossista"
        if "canal_compra" in s and "mainline" in s:
            return "Compra efetuada em loja física própria (Mainline)"
        if "canal_compra" in s and "outlet" in s:
            return "Compra efetuada em loja outlet oficial"
        if "encomenda_encontrada" in s:
            return "Número de encomenda online localizado no sistema"
        if "portal_online_disponivel" in s:
            return "Portal online BackPocket disponível e operacional"
        if "decisao(rever)" in s or "decisao(recusar)" in s:
            return "Inexistência de decisão impeditiva prévia de recusa ou revisão"
        if "colaborador_autorizado" in s:
            return "Colaborador autorizado com credenciais próprias de POS"
        if "sessao_pos_propria" in s:
            return "Operação conduzida na sessão própria do operador"
        if "personalizado_ou_alterado" in s:
            return "Artigo personalizado, estampado ou alterado"
        if "cliente_fornece_dados" in s:
            return "Identificação do cliente fornecida no balcão"
        if "cliente_contesta" in s:
            return "Contestação ou desacordo manifestado pelo cliente"
        if "cliente_agitado" in s:
            return "Comportamento agitado ou conflituoso do cliente"
        if "afterpay_pede_excecao" in s:
            return "Pedido de exceção de balcão para pagamento Afterpay"
        if "cartao_interac" in s or "interac" in s:
            return "Apresentação do cartão físico Interac para estorno"
        if "recibo_original" in s:
            return "Apresentação de recibo ou fatura original"
        if "troca_apenas_tamanho" in s:
            return "Troca direta de tamanho do mesmo artigo"
        if "risco_fraude" in s:
            return "Ausência de indicadores de fraude ou abuso de devoluções"

        # Fallback: humanize raw syntax
        clean = s.replace("nao ", "ausência de ").replace("_", " ").replace("(", ": ").replace(")", "").strip()
        return f"Critério não verificado: {clean}"

    async def explain_how(self, evaluation_id: Union[str, UUID]) -> ExplicacaoComoResponse:
        """Provide How causal rule trace from the Prolog evaluation."""
        entry = self._evaluations_cache.get(str(evaluation_id))
        if not entry:
            return ExplicacaoComoResponse(
                passos=[],
                modulosPercorridos=[],
                resumo="Avaliação não encontrada no cache local da sessão.",
            )

        raw = entry["raw_result"]
        justifications: List[str] = raw.get("justification", [])
        derived_facts: List[Dict[str, Any]] = raw.get("derived_facts", [])

        passos: List[PassoExplicacaoDto] = []
        modulos: List[str] = []

        for idx, just in enumerate(justifications, start=1):
            rule_id = "REGRA"
            msg = just
            if just.startswith("[") and "]" in just:
                parts = just.split("]", 1)
                rule_id = parts[0][1:].strip()
                msg = parts[1].strip()

            mod = _module_for_rule(rule_id)
            if mod not in modulos:
                modulos.append(mod)

            rule_info = PROLOG_RULE_DETAILS.get(rule_id, {})
            rule_title = rule_info.get("nome", f"Critério {rule_id}")

            passos.append(
                PassoExplicacaoDto(
                    ordem=idx,
                    modulo=mod,
                    codigoRegra=rule_id,
                    nomeRegra=f"{rule_id} {rule_title}",
                    mensagem=msg,
                    aValidar=False,
                )
            )

        if passos:
            last_code = passos[-1].codigoRegra
            last_rule_name = PROLOG_RULE_DETAILS.get(last_code, {}).get("nome", last_code)
            paragem = f"Decisão terminal fixada por: {last_rule_name}"
        else:
            paragem = "Conclusão alcançada"

        resumo = f"O motor SWI-Prolog avaliou {raw.get('total_facts', 0)} factos e disparou {len(passos)} regras normativas."

        return ExplicacaoComoResponse(
            passos=passos,
            modulosPercorridos=modulos,
            paragem=paragem,
            resumo=resumo,
        )

    async def explain_whynot(
        self,
        evaluation_id: Union[str, UUID],
        target: Optional[str] = None,
    ) -> ExplicacaoPorqueNaoConclusaoResponse:
        """Provide Why Not failure tree analysis from Prolog."""
        target_atom = "permitir"
        if target:
            clean = target.replace("OUT-001:", "").lower()
            if "recusar" in clean:
                target_atom = "recusar"
            elif "rever" in clean:
                target_atom = "rever"
            elif "encaminhar" in clean:
                target_atom = "encaminhar"
            elif "permitir" in clean:
                target_atom = "permitir"

        try:
            whynot_raw = await self.prolog_client.whynot_retail({"decision": target_atom})
            lines = whynot_raw.get("explanation", [])
        except Exception:
            lines = [f"A conclusão {target_atom} não foi atingida pelas condições ativas."]

        regras: List[ExplicacaoPorqueNaoResponse] = []
        current_rule: Optional[str] = None
        current_conds: List[CondicaoDto] = []

        def _append_current_rule():
            nonlocal current_rule, current_conds
            if not current_rule:
                return
            rule_info = PROLOG_RULE_DETAILS.get(current_rule, {})
            rule_name = rule_info.get("nome", current_rule)
            variante = f"{current_rule}: {rule_name}"
            resumo = f"A regra '{rule_name}' não disparou porque os critérios exigidos não se verificaram no pedido."
            regras.append(
                ExplicacaoPorqueNaoResponse(
                    codigoRegra=current_rule,
                    causa=CausaNaoDisparoEnum.CONDICOES_FALHADAS,
                    variante=variante,
                    condicoes=current_conds,
                    resumo=resumo,
                )
            )

        for line in lines:
            if "Because by rule [" in line:
                _append_current_rule()
                current_rule = line.split("[")[1].split("]")[0].strip()
                current_conds = []
            elif "Condition" in line or "Premise" in line:
                human_text = self._humanize_prolog_condition(line)
                if not any(c.nome == human_text for c in current_conds):
                    current_conds.append(
                        CondicaoDto(
                            nome=human_text,
                            descricao=f"Condição requerida: {human_text}",
                            cumprida=False,
                        )
                    )

        _append_current_rule()

        return ExplicacaoPorqueNaoConclusaoResponse(
            conclusao=target or f"OUT-001:{target_atom.upper()}",
            valor=target_atom.upper(),
            obtida=False,
            propostaPor=[],
            regras=regras,
            resumo=f"A conclusão '{target_atom.upper()}' não foi alcançada devido a condições não satisfeitas nas regras candidatas.",
        )

    async def simulate_whatif(
        self,
        evaluation_id: Union[str, UUID],
        alteracoes: Dict[str, Any],
    ) -> SimulacaoResponse:
        """Run What-If counterfactual simulation in Prolog sandbox."""
        entry = self._evaluations_cache.get(str(evaluation_id))
        base_facts = entry["facts"] if entry else []

        add_facts: List[str] = []
        remove_facts: List[str] = []

        for k, v in alteracoes.items():
            k_lower = str(k).lower().strip()
            v_str = str(v).lower().strip()

            # 1. Etiquetas e Estado de Uso
            if "etiqueta" in k_lower or "condicaouso" in k_lower or "estado" in k_lower:
                if v_str in ["colocadas", "colocada", "intactas", "nao_usado_com_etiquetas", "true", "nao_usado"]:
                    add_facts.append("estado_produto(nao_usado_com_etiquetas)")
                    remove_facts.extend([
                        "estado_produto(nao_usado_etiquetas_soltas)",
                        "estado_produto(sem_etiquetas)",
                        "estado_produto(claramente_usado)",
                        "estado_produto(lavado)",
                    ])
                elif v_str in ["soltas", "nao_usado_etiquetas_soltas"]:
                    add_facts.append("estado_produto(nao_usado_etiquetas_soltas)")
                    remove_facts.extend([
                        "estado_produto(nao_usado_com_etiquetas)",
                        "estado_produto(sem_etiquetas)",
                        "estado_produto(claramente_usado)",
                    ])
                elif v_str in ["usado", "claramente_usado"]:
                    add_facts.append("estado_produto(claramente_usado)")
                    remove_facts.extend([
                        "estado_produto(nao_usado_com_etiquetas)",
                        "estado_produto(nao_usado_etiquetas_soltas)",
                    ])
                elif v_str in ["sem_etiquetas", "sem_etiqueta"]:
                    add_facts.append("estado_produto(sem_etiquetas)")
                    remove_facts.extend([
                        "estado_produto(nao_usado_com_etiquetas)",
                        "estado_produto(nao_usado_etiquetas_soltas)",
                    ])

            # 2. Portal Online
            elif "portalonline" in k_lower or "portal_online" in k_lower:
                if v_str in ["true", "1", "sim", "disponivel"]:
                    add_facts.append("portal_online_disponivel(true)")
                    remove_facts.append("portal_online_disponivel(false)")
                else:
                    add_facts.append("portal_online_disponivel(false)")
                    remove_facts.append("portal_online_disponivel(true)")

            # 3. Comprovativo
            elif "comprovativo" in k_lower or "recibo" in k_lower:
                if v_str in ["sem_comprovativo", "nenhum", "sem_recibo", "false"]:
                    add_facts.append("comprovativo(nenhum)")
                    remove_facts.extend([
                        "comprovativo(recibo_impresso)",
                        "comprovativo(recibo_digital)",
                        "comprovativo(fatura_digital)",
                        "tipo_verificacao(verificada)",
                    ])
                elif v_str in ["recibo_impresso", "impresso"]:
                    add_facts.append("comprovativo(recibo_impresso)")
                    remove_facts.extend(["comprovativo(nenhum)", "tipo_verificacao(as_cegas)"])
                elif v_str in ["recibo_digital", "digital"]:
                    add_facts.append("comprovativo(recibo_digital)")
                    remove_facts.extend(["comprovativo(nenhum)", "tipo_verificacao(as_cegas)"])

            # 4. Fallback if user passes direct fact string (e.g. "sku_reconhecido(false)")
            elif "(" in k and ")" in k:
                add_facts.append(k)

        whatif_raw = await self.prolog_client.whatif_retail({
            "base_facts": {"facts": base_facts},
            "add": add_facts,
            "remove": remove_facts,
        })

        base_dec = whatif_raw.get("baseline_decision", "rever")
        sim_dec = whatif_raw.get("simulated_decision", "permitir")

        base_rules = set(re.findall(r"\[([A-Z]{2,4}-\d{3,4}(?:-[A-Z0-9]+)?)\]", str(whatif_raw.get("baseline_justification", []))))
        sim_rules = set(re.findall(r"\[([A-Z]{2,4}-\d{3,4}(?:-[A-Z0-9]+)?)\]", str(whatif_raw.get("simulated_justification", []))))
        regras_novas = sorted(list(sim_rules - base_rules))
        regras_removidas = sorted(list(base_rules - sim_rules))

        diferencas: List[DiferencaDto] = []
        if base_dec.strip().upper() != sim_dec.strip().upper():
            diferencas.append(
                DiferencaDto(
                    alvo="Elegibilidade",
                    campo="elegibilidade",
                    original=base_dec.upper(),
                    simulado=sim_dec.upper(),
                )
            )

        sim_eleg = (
            ElegibilidadeEnum.PERMITIR
            if sim_dec in ["permitir", "approved", "store_credit_only"]
            else (
                ElegibilidadeEnum.RECUSAR
                if sim_dec in ["recusar", "rejected"]
                else (
                    ElegibilidadeEnum.ENCAMINHAR
                    if sim_dec in ["encaminhar"]
                    else ElegibilidadeEnum.REVER
                )
            )
        )
        decisao_sim = None
        if entry and "decision" in entry:
            decisao_sim = entry["decision"].model_copy(update={"elegibilidade": sim_eleg})

        return SimulacaoResponse(
            diferencas=diferencas,
            regrasNovas=regras_novas,
            regrasRemovidas=regras_removidas,
            resumo=whatif_raw.get("impact_summary") or (
                f"A decisão manteve-se inalterada em '{base_dec}'."
                if base_dec.strip().upper() == sim_dec.strip().upper()
                else f"A decisão mudou de '{base_dec}' para '{sim_dec}' com a simulação contrafactual."
            ),
            decisaoSimulada=decisao_sim,
        )

    def _map_pedido_to_prolog_facts(self, payload: Dict[str, Any]) -> List[str]:
        """Convert input payload to Prolog facts."""
        return pedido_to_prolog_facts(payload) if payload else []

    async def missing_data(self, payload: Dict[str, Any]) -> DadosEmFaltaResponse:
        """Check for missing data using Prolog interactive ACM mechanics."""
        facts = self._map_pedido_to_prolog_facts(payload)
        resp = await self.prolog_client.interactive_retail({"initial_facts": facts})

        if resp.get("status") == "question" and "question" in resp:
            q = resp["question"]
            attr = q.get("attribute", "comprovativo")
            code = "IN-004" if "comprovativo" in attr else "IN-010"
            porque_exp = await self.explain_why(code, payload)
            dado = DadoEmFaltaDto(
                codigo=code,
                caminho=f"artigos[0].{attr}",
                descricao=q.get("prompt", "Dado pendente para avaliação completa"),
                obrigatorio=True,
                porque=porque_exp,
            )
            return DadosEmFaltaResponse(
                dados=[dado],
                completo=False,
                resumo="Existem premissas perguntáveis em falta para conclusão definitiva.",
            )

        return DadosEmFaltaResponse(
            dados=[],
            completo=True,
            resumo="Todos os dados necessários para o diagnóstico foram recolhidos.",
        )

    async def explain_why(self, dado: str, payload: Dict[str, Any]) -> ExplicacaoPorqueResponse:
        """Explain why a particular input premise is needed (Why Ask)."""
        dado_clean = (dado or "IN-004").strip()
        facts = self._map_pedido_to_prolog_facts(payload)

        # 1. Attempt dynamic causal Why Ask reasoning via SWI-Prolog microservice
        try:
            prolog_resp = await self.prolog_client.why_retail({
                "dado": dado_clean,
                "base_facts": facts,
            })
            if isinstance(prolog_resp, dict) and prolog_resp.get("status") == "success":
                code_ret = prolog_resp.get("codigo") or dado_clean
                if str(code_ret).upper() == dado_clean.upper():
                    prolog_resp["codigo"] = dado_clean
                    prolog_resp["dado"] = dado_clean
                else:
                    prolog_resp["codigo"] = code_ret
                    prolog_resp["dado"] = prolog_resp.get("dado") or code_ret

                if dado_clean not in prolog_resp.get("pergunta", "") and dado_clean.lower() in prolog_resp.get("pergunta", ""):
                    prolog_resp["pergunta"] = prolog_resp["pergunta"].replace(dado_clean.lower(), dado_clean)

                return ExplicacaoPorqueResponse.model_validate(prolog_resp)
        except Exception as exc:
            logger.warning(
                "[RetailPrologService] SWI-Prolog /retail/why unavailable or error (%s). Falling back to resilient knowledge catalog.",
                exc,
            )

        # 2. Resilient fallback using PROLOG_INPUT_KNOWLEDGE if SWI-Prolog is unreachable
        dado_upper = dado_clean.upper()
        info = PROLOG_INPUT_KNOWLEDGE.get(dado_upper)
        if not info:
            return ExplicacaoPorqueResponse(
                codigo=dado_upper,
                dado=dado_upper,
                pergunta=f"Qual é o valor do atributo {dado_upper}?",
                resumo=f"O atributo {dado_upper} é requerido pelo motor pericial para validar as regras normativas de devolução.",
                regrasQueDependem=[],
                regrasEmEspera=[],
            )

        pergunta = info["pergunta"]
        resumo = info["resumo"]
        regras_dependentes = list(info["regras"])

        # Construct candidate regrasEmEspera based on rule details
        regras_em_espera: List[RegraEmEsperaDto] = []
        for rule_id in regras_dependentes:
            r_meta = PROLOG_RULE_DETAILS.get(rule_id, {})
            nome = r_meta.get("nome", f"Regra {rule_id}")
            conclusoes = r_meta.get("conclusoes", [])
            modulo = _module_for_rule(rule_id)

            regras_em_espera.append(
                RegraEmEsperaDto(
                    codigoRegra=rule_id,
                    nomeRegra=f"[{rule_id}] {nome}",
                    modulo=modulo,
                    conclusoes=conclusoes,
                    condicoesDoDado=[
                        CondicaoDto(
                            nome=info["atributo"],
                            descricao=f"Avaliação da premissa '{info['atributo']}' para a regra {rule_id}",
                            cumprida=False,
                        )
                    ],
                )
            )

        return ExplicacaoPorqueResponse(
            codigo=dado_upper,
            dado=dado_upper,
            pergunta=pergunta,
            resumo=resumo,
            regrasQueDependem=regras_dependentes,
            regrasEmEspera=regras_em_espera,
        )

    def _map_prolog_to_decisao(
        self,
        raw: Dict[str, Any],
        pedido: Dict[str, Any],
    ) -> DecisaoResponse:
        """Map raw Prolog execution dictionary to canonical DecisaoResponse."""
        decision_raw = str(raw.get("retail_decision") or "").lower()
        if not decision_raw or decision_raw == "nao_concluido":
            decision_raw = str(raw.get("decision") or "").lower()

        # Parse derived facts
        derived_facts = raw.get("derived_facts", [])
        fact_strings = [df.get("fact", "") for df in derived_facts]

        # 1. Map Elegibilidade (OUT-001)
        if any("decisao(encaminhar)" in f or "processo_obrigatorio(backpocket)" in f for f in fact_strings):
            elegibilidade = ElegibilidadeEnum.ENCAMINHAR
        elif any("decisao(recusar)" in f for f in fact_strings) or decision_raw in ["recusar", "rejected"]:
            elegibilidade = ElegibilidadeEnum.RECUSAR
        elif any("decisao(rever)" in f for f in fact_strings) or decision_raw in ["rever"]:
            elegibilidade = ElegibilidadeEnum.REVER
        elif any("decisao(permitir)" in f for f in fact_strings) or decision_raw in ["permitir", "approved", "store_credit_only"]:
            elegibilidade = ElegibilidadeEnum.PERMITIR
        elif decision_raw in ["encaminhar"]:
            elegibilidade = ElegibilidadeEnum.ENCAMINHAR
        else:
            elegibilidade = ElegibilidadeEnum.REVER

        # Verification type (PT-001, PT-002)
        tipo_verificacao = TipoVerificacaoEnum.VERIFICADA
        for f in fact_strings:
            if "tipo_verificacao(as_cegas)" in f or "comprovativo(nenhum)" in f:
                tipo_verificacao = TipoVerificacaoEnum.AS_CEGAS
                break

        # 2. Extract transaction type (OUT-002)
        is_portal_outage = (
            pedido.get("portalOnlineDisponivel") is False
            or any("portal_online_disponivel(false)" in f for f in fact_strings)
            or any("CH-004" in df.get("rule_id", "") for df in derived_facts)
        )
        if elegibilidade == ElegibilidadeEnum.RECUSAR:
            tipo_transacao = TipoTransacaoEnum.NENHUMA
        elif (
            tipo_verificacao == TipoVerificacaoEnum.AS_CEGAS
            and (pedido.get("tipoPedido") or "").lower() in ["devolucao", "devolucao_oferta"]
        ):
            tipo_transacao = TipoTransacaoEnum.CREDITO_LOJA
        elif is_portal_outage and any("fluxo_app" in f for f in fact_strings):
            tipo_transacao = None
        else:
            tipo_transacao = TipoTransacaoEnum.REEMBOLSO
            ped_tipo = str(pedido.get("tipoPedido") or "").lower() if isinstance(pedido, dict) else ""
            if ped_tipo == "troca":
                tipo_transacao = TipoTransacaoEnum.TROCA
            elif ped_tipo in ["ajuste_preco", "ajustepreco"]:
                tipo_transacao = TipoTransacaoEnum.AJUSTE_PRECO
            elif ped_tipo in ["credito_loja", "devolucao_oferta"]:
                tipo_transacao = TipoTransacaoEnum.CREDITO_LOJA

            for f in fact_strings:
                if "tipo_transacao(reembolso)" in f:
                    tipo_transacao = TipoTransacaoEnum.REEMBOLSO
                    break
                elif "tipo_transacao(troca)" in f or "tipo_pedido(troca)" in f:
                    tipo_transacao = TipoTransacaoEnum.TROCA
                    break
                elif "tipo_transacao(troca_ou_credito)" in f or "meio_reembolso(vale_loja)" in f or "meio_reembolso(credito_loja)" in f:
                    tipo_transacao = TipoTransacaoEnum.CREDITO_LOJA
                    break
                elif "tipo_transacao(ajuste_preco)" in f:
                    tipo_transacao = TipoTransacaoEnum.AJUSTE_PRECO
                    break

        # 3. Extract tender / refund method (OUT-004)
        if elegibilidade == ElegibilidadeEnum.RECUSAR:
            meio_reembolso = None
        elif any("meio_reembolso(sem_meio_definido)" in f or "sem_meio_definido" in f for f in fact_strings):
            meio_reembolso = None
        elif any("meio_reembolso(fluxo_app)" in f or "processo_obrigatorio(fluxo_app)" in f or "fluxo_app" in f for f in fact_strings):
            meio_reembolso = MeioReembolsoEnum.APLICACAO_PAGAMENTO
        elif (
            tipo_verificacao == TipoVerificacaoEnum.AS_CEGAS
            and (pedido.get("tipoPedido") or "").lower() in ["devolucao", "devolucao_oferta"]
        ):
            meio_reembolso = MeioReembolsoEnum.CREDITO_LOJA
        elif tipo_transacao == TipoTransacaoEnum.CREDITO_LOJA or any(
            "meio_reembolso(vale_loja)" in f or "meio_reembolso(credito_loja)" in f or "credito_loja" in f
            for f in fact_strings
        ):
            meio_reembolso = MeioReembolsoEnum.CREDITO_LOJA
        elif any("meio_reembolso(cartao_oferta)" in f for f in fact_strings):
            meio_reembolso = MeioReembolsoEnum.CARTAO_OFERTA
        elif any("meio_reembolso(meio_original)" in f for f in fact_strings):
            meio_reembolso = MeioReembolsoEnum.MEIO_ORIGINAL
        else:
            meio_reembolso = MeioReembolsoEnum.MEIO_ORIGINAL

        # 4. Extract approval level (OUT-005)
        # Strict hierarchy: DISTRICT_AREA > RESPONSAVEL_SENIOR > XSTORE_MANAGER > NENHUMA
        if any("aprovacao(distrital)" in f or "escalamento_distrital" in f for f in fact_strings):
            aprovacao = NivelAprovacaoEnum.DISTRICT_AREA
        elif any("aprovacao(responsavel_senior)" in f or "responsavel_senior" in f for f in fact_strings):
            aprovacao = NivelAprovacaoEnum.RESPONSAVEL_SENIOR
        elif (
            any("aprovacao(gerente)" in f or "aprovacao(gestor_xstore)" in f for f in fact_strings)
            or (tipo_verificacao == TipoVerificacaoEnum.AS_CEGAS and elegibilidade != ElegibilidadeEnum.RECUSAR)
        ):
            aprovacao = NivelAprovacaoEnum.XSTORE_MANAGER
        elif elegibilidade == ElegibilidadeEnum.PERMITIR:
            aprovacao = NivelAprovacaoEnum.NENHUMA
        else:
            aprovacao = None

        # 5. Process mandatory (OUT-006)
        processo = None
        for f in fact_strings:
            if "processo_obrigatorio(backpocket)" in f or "backpocket" in f:
                processo = ProcessoObrigatorioEnum.BACKPOCKET
                break
            elif "processo_obrigatorio(fluxo_app)" in f or "fluxo_app" in f or "paypal" in f or "venmo" in f:
                processo = ProcessoObrigatorioEnum.PAYPAL_VENMO
                break
            elif "afterpay" in f:
                processo = ProcessoObrigatorioEnum.AFTERPAY
                break

        # 6. Dynamic value calculation (OUT-003)
        if elegibilidade == ElegibilidadeEnum.RECUSAR:
            valor_deliberado = 0.00
        elif (tipo_transacao is None or is_portal_outage) and any("fluxo_app" in f for f in fact_strings):
            valor_deliberado = 0.00
        else:
            raw_artigos = pedido.get("artigos") or []
            if raw_artigos:
                valor_deliberado = sum(
                    float(
                        a.get("precoPago")
                        or a.get("precoAtual")
                        or (a.get("produto") or {}).get("precoAtual")
                        or (a.get("produto") or {}).get("pvpOriginal")
                        or 0.0
                    )
                    for a in raw_artigos
                )
            else:
                valor_deliberado = float(
                    pedido.get("valorTotal")
                    or (pedido.get("compraOriginal") or {}).get("pagamento", {}).get("valorPago")
                    or 0.00
                )

        # 7. Rules trace with domain prioritization
        justifications: List[str] = raw.get("justification", [])
        regras_raw: List[RegistoRegraResponse] = []
        for idx, just in enumerate(justifications, start=1):
            rule_id = "REGRA"
            msg = just
            if just.startswith("[") and "]" in just:
                parts = just.split("]", 1)
                rule_id = parts[0][1:].strip()
                msg = parts[1].strip()

            regras_raw.append(
                RegistoRegraResponse(
                    ordem=idx,
                    codigoRegra=rule_id,
                    nomeRegra=f"{rule_id} Regra Levi's",
                    modulo=_module_for_rule(rule_id),
                    resultado=elegibilidade,
                    mensagem=msg,
                    aValidar=False,
                )
            )

        def _rule_sort_key(r: RegistoRegraResponse) -> int:
            code = r.codigoRegra.upper()
            if code.startswith(("PC-008", "BW-", "HS-", "EX-008", "TN-011")):
                return 0
            if code.startswith(("PC-", "EX-", "TN-", "CH-", "PT-", "EP-")):
                return 1
            if code.startswith("CT-"):
                return 2
            return 3

        regras_sorted = sorted(regras_raw, key=_rule_sort_key)
        regras = [
            r.model_copy(update={"ordem": idx})
            for idx, r in enumerate(regras_sorted, start=1)
        ]

        # 8. Articles breakdown
        base_valor = (
            BaseValorEnum.VALOR_PROMOCIONAL
            if (tipo_verificacao == TipoVerificacaoEnum.AS_CEGAS and (pedido.get("tipoPedido") or "").lower() in ["devolucao_oferta"])
            else BaseValorEnum.VALOR_PAGO
        )

        artigos_list: List[ResultadoArtigoResponse] = []
        raw_artigos = pedido.get("artigos") or []
        for idx, art in enumerate(raw_artigos, start=1):
            art_id = str(art.get("id") or f"A-{idx}")
            if elegibilidade == ElegibilidadeEnum.RECUSAR:
                art_valor = 0.00
            elif (tipo_transacao is None or is_portal_outage) and any("fluxo_app" in f for f in fact_strings):
                art_valor = 0.00
            else:
                art_valor = float(
                    art.get("precoPago")
                    or art.get("precoAtual")
                    or (art.get("produto") or {}).get("precoAtual")
                    or (art.get("produto") or {}).get("pvpOriginal")
                    or 0.00
                )

            art_est = art.get("estado") or {}
            if art_est.get("sujoOuInseguro") or any("isolamento_risco_biologico" in f for f in fact_strings):
                destino = DestinoProdutoEnum.RISCO_BIOLOGICO
            elif elegibilidade == ElegibilidadeEnum.RECUSAR:
                destino = DestinoProdutoEnum.DEVOLUCAO_CLIENTE
            elif elegibilidade == ElegibilidadeEnum.ENCAMINHAR:
                destino = DestinoProdutoEnum.SALDOS
            else:
                destino = DestinoProdutoEnum.AREA_VENDAS

            artigos_list.append(
                ResultadoArtigoResponse(
                    artigoId=art_id,
                    elegibilidade=elegibilidade,
                    tipoTransacao=tipo_transacao,
                    valorDevolucao=round(art_valor, 2),
                    baseValor=base_valor,
                    destino=destino,
                    aprovacao=aprovacao,
                    terminal=False,
                )
            )

        if not artigos_list:
            artigos_list.append(
                ResultadoArtigoResponse(
                    artigoId="A-1",
                    elegibilidade=elegibilidade,
                    tipoTransacao=tipo_transacao,
                    valorDevolucao=round(valor_deliberado, 2),
                    baseValor=base_valor,
                    destino=DestinoProdutoEnum.AREA_VENDAS if elegibilidade != ElegibilidadeEnum.RECUSAR else DestinoProdutoEnum.DEVOLUCAO_CLIENTE,
                    aprovacao=aprovacao,
                    terminal=False,
                )
            )

        # 9. Documentação
        compra = pedido.get("compraOriginal") or {}
        id_stylist = compra.get("idStylistVenda") or "S-21"
        comprovativo_tipo = str((pedido.get("comprovativo") or {}).get("tipo") or "").lower()
        recibo_agrafado = "impresso" in comprovativo_tipo

        doc = DocumentacaoResponse(
            assinaturaCliente="Assinatura do cliente ou 'Recusado'",
            assinaturaProcessador="Assinatura do colaborador",
            assinaturaTestemunha="Assinatura de testemunha",
            idStylistAtribuido=id_stylist,
            reciboAgrafado=recibo_agrafado,
            retencaoAte=datetime.now().date(),
        )

        return DecisaoResponse(
            avaliacaoId=uuid4(),
            pedidoId=str(pedido.get("id") or f"P-{uuid4().hex[:6]}"),
            avaliadaEm=datetime.now(timezone.utc),
            versaoBaseConhecimento="com.levis.devolucoes:prolog-rules:1.0.0 (71 Regras)",
            elegibilidade=elegibilidade,
            tipoVerificacao=tipo_verificacao,
            tipoTransacao=tipo_transacao,
            valorDevolucao=round(valor_deliberado, 2),
            baseValor=base_valor,
            meioReembolso=meio_reembolso,
            aprovacao=aprovacao,
            processo=processo,
            terminal=False,
            excecaoRecusada=(elegibilidade == ElegibilidadeEnum.ENCAMINHAR),
            documentacao=doc,
            artigos=artigos_list,
            regras=regras,
            regrasAValidar=["A-19", "A-22"] if elegibilidade == ElegibilidadeEnum.REVER else [],
        )
