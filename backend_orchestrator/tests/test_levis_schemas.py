"""Unit tests for Levi's Returns Expert Pydantic v2 schemas."""

import glob
import json
from pathlib import Path

import pytest
from pydantic import ValidationError

from app.schemas.levis import (
    ArtigoRequest,
    CausaNaoDisparoEnum,
    DecisaoResponse,
    ElegibilidadeEnum,
    EstadoEtiquetasEnum,
    ExplicacaoComoResponse,
    ExplicacaoPorqueNaoResponse,
    ExplicacaoPorqueResponse,
    FuncaoEnum,
    LojaRequest,
    PedidoAvaliacaoRequest,
    ProdutoRequest,
    RegraDetalheDto,
    RegraResumoDto,
    SimulacaoRequest,
    SimulacaoResponse,
    TipoPedidoEnum,
    TipoTransacaoEnum,
)

LOCAL_CENARIOS_DIR = Path(__file__).parent.parent / "data" / "cenarios"
REPO_CENARIOS_DIR = (
    Path(__file__).parent.parent.parent
    / "drools-engine-levis-devolucoes-java"
    / "backend"
    / "pericial-rules"
    / "src"
    / "test"
    / "resources"
    / "cenarios"
)
CENARIOS_DIR = LOCAL_CENARIOS_DIR if LOCAL_CENARIOS_DIR.exists() and any(LOCAL_CENARIOS_DIR.glob("cenario-*.json")) else REPO_CENARIOS_DIR


def test_cenario_01_validation():
    """Valida que o payload do cenario-01.json é perfeitamente validado por PedidoAvaliacaoRequest."""
    cenario_file = CENARIOS_DIR / "cenario-01.json"
    assert cenario_file.exists(), f"Ficheiro de cenário não encontrado: {cenario_file}"

    with open(cenario_file, encoding="utf-8") as f:
        data = json.load(f)

    pedido = PedidoAvaliacaoRequest.model_validate(data["pedido"])

    assert pedido.id == "C01"
    assert pedido.tipoPedido == TipoPedidoEnum.TROCA
    assert pedido.loja is not None
    assert pedido.loja.codigo == "US-ML-010"
    assert len(pedido.artigos) == 1
    assert pedido.artigos[0].produto.sku == "501-ORIG-32"
    assert pedido.artigos[0].precoPago == 69.50
    assert pedido.artigos[0].estado is not None
    assert pedido.artigos[0].estado.etiquetas == EstadoEtiquetasEnum.SOLTAS
    assert pedido.artigosTroca is not None
    assert len(pedido.artigosTroca) == 1


def test_all_10_cenarios_validation():
    """Garante que todos os 10 cenários oficiais de retalho da Levi's passam na validação Pydantic."""
    scenario_files = sorted(glob.glob(str(CENARIOS_DIR / "cenario-*.json")))
    assert len(scenario_files) == 10, f"Esperados 10 cenários, encontrados {len(scenario_files)}"

    for path in scenario_files:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)

        pedido = PedidoAvaliacaoRequest.model_validate(data["pedido"])
        assert pedido.id is not None
        assert len(pedido.artigos) >= 1
        for artigo in pedido.artigos:
            assert artigo.produto.sku is not None


def test_invalid_payload_raises_validation_error():
    """Garante que payloads inválidos disparam pydantic.ValidationError com detalhes claros."""
    # Falta 'id' e 'produto' no artigo
    with pytest.raises(ValidationError) as exc_info:
        PedidoAvaliacaoRequest.model_validate({"artigos": [{"quantidade": 1}]})

    errors = exc_info.value.errors()
    assert len(errors) >= 2
    field_names = [e["loc"][-1] for e in errors]
    assert "id" in field_names
    assert "produto" in field_names


def test_camel_and_snake_case_flexibility():
    """Testa que os modelos suportam tanto camelCase como snake_case."""
    # Teste de input em snake_case
    payload_snake = {
        "id": "TEST-1",
        "data_pedido": "2026-03-31",
        "tipo_pedido": "DEVOLUCAO",
        "artigos": [
            {
                "id": "A-1",
                "produto": {"sku": "501-ORIG-32"},
                "preco_pago": 98.0,
            }
        ],
    }
    pedido = PedidoAvaliacaoRequest.model_validate(payload_snake)
    assert pedido.id == "TEST-1"
    assert str(pedido.dataPedido) == "2026-03-31"
    assert pedido.data_pedido == pedido.dataPedido
    assert pedido.artigos[0].preco_pago == 98.0
    assert pedido.artigos[0].precoPago == 98.0


def test_decisao_and_explanations_schemas():
    """Valida schemas de decisão e explicabilidade."""
    decisao_dict = {
        "avaliacaoId": "a568a9f1-c783-4cef-ae2f-380ca337e91b",
        "pedidoId": "C01",
        "elegibilidade": "REVER",
        "tipoTransacao": "TROCA",
        "valorDevolucao": 69.50,
        "baseValor": "VALOR_PAGO",
        "meioReembolso": "MEIO_ORIGINAL",
        "aprovacao": "RESPONSAVEL_SENIOR",
        "terminal": False,
        "excecaoRecusada": False,
        "documentacao": {
            "reciboAgrafado": False,
            "idStylistAtribuido": "S-21",
        },
        "artigos": [
            {
                "artigoId": "A-1",
                "elegibilidade": "REVER",
                "tipoTransacao": "TROCA",
                "valorDevolucao": 69.50,
                "destino": "AREA_VENDAS",
            }
        ],
        "regras": [
            {
                "ordem": 1,
                "codigoRegra": "CT-003",
                "nomeRegra": "m0_colaborador_autorizado",
                "modulo": "M0",
                "resultado": "PERMITIR",
            }
        ],
    }

    decisao = DecisaoResponse.model_validate(decisao_dict)
    assert decisao.elegibilidade == ElegibilidadeEnum.REVER
    assert decisao.tipoTransacao == TipoTransacaoEnum.TROCA
    assert len(decisao.artigos) == 1
    assert decisao.artigos[0].destino.value == "AREA_VENDAS"

    como_dict = {
        "passos": [
            {
                "ordem": 1,
                "modulo": "M0",
                "codigoRegra": "CT-003",
                "nomeRegra": "m0_colaborador_autorizado",
                "mensagem": "Colaborador autorizado",
            }
        ],
        "modulosPercorridos": ["M0", "M2"],
        "resumo": "Caminho percorrido com sucesso.",
    }
    como = ExplicacaoComoResponse.model_validate(como_dict)
    assert len(como.passos) == 1
    assert como.modulosPercorridos == ["M0", "M2"]

    porque_nao_dict = {
        "codigoRegra": "PT-004",
        "causa": "CONDICOES_FALHADAS",
        "resumo": "Condições não satisfeitas.",
    }
    pn = ExplicacaoPorqueNaoResponse.model_validate(porque_nao_dict)
    assert pn.codigoRegra == "PT-004"
    assert pn.causa == CausaNaoDisparoEnum.CONDICOES_FALHADAS
