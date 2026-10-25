"""Tests for the uncertainty layer contract of the Levi's Drools engine (docs/08 of the Drools engine).

Covers the request fields that feed the uncertainty layer (they must reach Drools untouched),
the belief degrees returned in DecisaoResponse.incerteza and the parameters endpoint.
"""

from __future__ import annotations

from typing import Any, Dict
from unittest.mock import AsyncMock

import pytest
from httpx import AsyncClient
from pydantic import ValidationError

from app.clients.levis_client import LevisClient
from app.core.exceptions import LevisConnectionError
from app.schemas.levis import (
    ClassificacaoIncertezaEnum,
    DecisaoResponse,
    EstadoProdutoRequest,
    HipoteseEnum,
    MetodoIncertezaEnum,
    PedidoAvaliacaoRequest,
    RespostaEnum,
)


def _pedido_com_incerteza() -> Dict[str, Any]:
    return {
        "id": "INC-01",
        "dataPedido": "2026-10-20",
        "tipoPedido": "DEVOLUCAO",
        "loja": {"codigo": "US-ML-010", "mercado": "EUA", "tipoLoja": "MAINLINE"},
        "cliente": {"id": "CLI-1", "explicaOrigemCompra": "NAO", "pedeNumerario": True},
        "artigos": [
            {
                "id": "A-1",
                "produto": {"sku": "501-ORIG-32", "defeitoConhecido": True},
                "revendivel": None,
                "estado": {
                    "condicaoUso": "NAO_USADO",
                    "etiquetas": "SOLTAS",
                    "grauUso": 0,
                    "alegaDefeito": True,
                    "inspecaoDefeito": {"ED-01": "SIM", "ED-05": "NAO", "ED-07": "NAO_SEI"},
                },
            }
        ],
    }


def _grau_fraude() -> Dict[str, Any]:
    return {
        "hipotese": "FRAUDE",
        "metodo": "FATOR_CERTEZA",
        "artigoId": None,
        "valor": 0.58,
        "classificacao": "RISCO_MEDIO",
        "contribuicoes": [
            {
                "codigo": "EF-04",
                "descricao": "Não explica onde nem quando comprou",
                "peso": 0.4,
                "valorAntes": 0.0,
                "valorDepois": 0.4,
                "aplicada": True,
                "motivoNaoAplicada": None,
            },
            {
                "codigo": "EF-06",
                "descricao": "Comprovativo verificado",
                "peso": -0.6,
                "valorAntes": 0.4,
                "valorDepois": 0.4,
                "aplicada": False,
                "motivoNaoAplicada": "Não observada neste pedido",
            },
        ],
        "demonstrativo": True,
        "versaoParametros": "0.1-demonstrativo",
    }


class TestPedidoComDadosDeIncerteza:
    """The uncertainty inputs are validated and forwarded to Drools."""

    def test_campos_de_incerteza_sao_lidos(self) -> None:
        pedido = PedidoAvaliacaoRequest.model_validate(_pedido_com_incerteza())

        assert pedido.cliente is not None
        assert pedido.cliente.explicaOrigemCompra == RespostaEnum.NAO
        assert pedido.cliente.pedeNumerario is True
        artigo = pedido.artigos[0]
        assert artigo.produto.defeitoConhecido is True
        assert artigo.estado is not None
        assert artigo.estado.grauUso == 0
        assert artigo.estado.alegaDefeito is True
        assert artigo.estado.inspecaoDefeito == {
            "ED-01": RespostaEnum.SIM,
            "ED-05": RespostaEnum.NAO,
            "ED-07": RespostaEnum.NAO_SEI,
        }

    def test_campos_de_incerteza_chegam_ao_drools(self) -> None:
        pedido = PedidoAvaliacaoRequest.model_validate(_pedido_com_incerteza())

        corpo = LevisClient(base_url="http://drools.test")._clean_payload(pedido)

        assert corpo["cliente"]["explicaOrigemCompra"] == "NAO"
        assert corpo["cliente"]["pedeNumerario"] is True
        artigo = corpo["artigos"][0]
        assert artigo["produto"]["defeitoConhecido"] is True
        # Grau de uso 0 ("nenhum") é um valor, não pode desaparecer com exclude_none
        assert artigo["estado"]["grauUso"] == 0
        assert artigo["estado"]["alegaDefeito"] is True
        assert artigo["estado"]["inspecaoDefeito"] == {"ED-01": "SIM", "ED-05": "NAO", "ED-07": "NAO_SEI"}

    def test_sem_dados_de_incerteza_nao_envia_campos_vazios(self) -> None:
        dados = _pedido_com_incerteza()
        dados["cliente"] = {"id": "CLI-1"}
        dados["artigos"][0]["produto"] = {"sku": "501-ORIG-32"}
        dados["artigos"][0]["estado"] = {"condicaoUso": "NAO_USADO", "etiquetas": "COLOCADAS"}

        corpo = LevisClient(base_url="http://drools.test")._clean_payload(
            PedidoAvaliacaoRequest.model_validate(dados)
        )

        assert "explicaOrigemCompra" not in corpo["cliente"]
        assert "defeitoConhecido" not in corpo["artigos"][0]["produto"]
        assert "grauUso" not in corpo["artigos"][0]["estado"]
        assert "inspecaoDefeito" not in corpo["artigos"][0]["estado"]

    @pytest.mark.parametrize(("valor", "esperado"), [(True, RespostaEnum.SIM), (False, RespostaEnum.NAO)])
    def test_explica_origem_aceita_o_booleano_dos_cenarios(self, valor: bool, esperado: RespostaEnum) -> None:
        # Os cenários de teste do Drools (ex.: cenário 6) usam o booleano do modelo
        dados = _pedido_com_incerteza()
        dados["cliente"]["explicaOrigemCompra"] = valor

        pedido = PedidoAvaliacaoRequest.model_validate(dados)

        assert pedido.cliente is not None
        assert pedido.cliente.explicaOrigemCompra == esperado

    @pytest.mark.parametrize("grau", [-1, 5])
    def test_grau_de_uso_fora_da_escala_e_recusado(self, grau: int) -> None:
        with pytest.raises(ValidationError):
            EstadoProdutoRequest.model_validate({"grauUso": grau})

    def test_pergunta_de_inspecao_desconhecida_e_recusada(self) -> None:
        # ED-03 e ED-04 não são perguntas ao colaborador: vêm da data da compra e do catálogo
        with pytest.raises(ValidationError, match="ED-03"):
            EstadoProdutoRequest.model_validate({"alegaDefeito": True, "inspecaoDefeito": {"ED-03": "SIM"}})


class TestDecisaoComIncerteza:
    """The belief degrees returned by Drools are kept in DecisaoResponse."""

    def test_graus_de_crenca_sao_lidos(self) -> None:
        decisao = DecisaoResponse.model_validate(
            {"pedidoId": "INC-01", "elegibilidade": "REVER", "incerteza": [_grau_fraude()]}
        )

        assert len(decisao.incerteza) == 1
        grau = decisao.incerteza[0]
        assert grau.hipotese == HipoteseEnum.FRAUDE
        assert grau.metodo == MetodoIncertezaEnum.FATOR_CERTEZA
        assert grau.classificacao == ClassificacaoIncertezaEnum.RISCO_MEDIO
        assert grau.valor == pytest.approx(0.58)
        assert grau.demonstrativo is True
        assert [c.codigo for c in grau.contribuicoes] == ["EF-04", "EF-06"]
        assert grau.contribuicoes[1].aplicada is False

    def test_decisao_sem_incerteza_tem_lista_vazia(self) -> None:
        decisao = DecisaoResponse.model_validate({"pedidoId": "C01", "elegibilidade": "PERMITIR"})

        assert decisao.incerteza == []


class TestEndpointsDeIncerteza:
    """REST contract of /api/v1/levis/* for the uncertainty layer."""

    @pytest.mark.asyncio
    async def test_avaliar_devolve_os_graus_de_crenca(
        self,
        async_client: AsyncClient,
        mock_levis_client: AsyncMock,
    ) -> None:
        mock_levis_client.evaluate.return_value = {
            "avaliacaoId": "00000000-0000-0000-0000-000000000009",
            "pedidoId": "INC-01",
            "elegibilidade": "REVER",
            "artigos": [],
            "regras": [],
            "incerteza": [_grau_fraude()],
        }

        resp = await async_client.post("/api/v1/levis/avaliar", json=_pedido_com_incerteza())

        assert resp.status_code == 200
        graus = resp.json()["incerteza"]
        assert len(graus) == 1
        assert graus[0]["hipotese"] == "FRAUDE"
        assert graus[0]["classificacao"] == "RISCO_MEDIO"
        assert graus[0]["contribuicoes"][0]["codigo"] == "EF-04"
        enviado = mock_levis_client.evaluate.call_args.args[0]
        assert enviado.artigos[0].estado.alegaDefeito is True

    @pytest.mark.asyncio
    async def test_como_de_um_grau_mantem_o_calculo(
        self,
        async_client: AsyncClient,
        mock_levis_client: AsyncMock,
    ) -> None:
        mock_levis_client.explain_how.return_value = {
            "conclusao": "INCERTEZA.DEFEITO_FABRICO",
            "artigoId": "A-1",
            "valores": {"valor": "0.71", "classificacao": "PROPOR_PC006", "metodo": "BAYES"},
            "regra": "IU-20",
            "condicoes": [
                {"nome": "ED-01", "descricao": "Dano numa costura", "cumprida": True, "valor": "0.05 → 0.17"}
            ],
            "caminho": ["Probabilidade a priori 0,05", "ED-01 presente: 0,05 → 0,17"],
            "resumo": "Defeito de fabrico provável.",
        }

        resp = await async_client.get(
            "/api/v1/levis/avaliacoes/00000000-0000-0000-0000-000000000009/explicacoes/como",
            params={"conclusao": "INCERTEZA.DEFEITO_FABRICO", "artigo": "A-1"},
        )

        assert resp.status_code == 200
        corpo = resp.json()
        assert corpo["regra"] == "IU-20"
        assert corpo["valores"]["classificacao"] == "PROPOR_PC006"
        assert corpo["caminho"][1].startswith("ED-01")
        assert corpo["condicoes"][0]["valor"] == "0.05 → 0.17"
        mock_levis_client.explain_how.assert_awaited_once_with(
            evaluation_id="00000000-0000-0000-0000-000000000009",
            conclusao="INCERTEZA.DEFEITO_FABRICO",
            artigo="A-1",
            locale=None,
        )

    @pytest.mark.asyncio
    async def test_porque_nao_de_uma_classificacao_mantem_o_que_mudaria(
        self,
        async_client: AsyncClient,
        mock_levis_client: AsyncMock,
    ) -> None:
        mock_levis_client.explain_why_not.return_value = {
            "conclusao": "INCERTEZA.FRAUDE",
            "valor": "RISCO_BAIXO",
            "valorObtido": "RISCO_MEDIO",
            "obtida": False,
            "propostaPor": ["EF-06 Comprovativo verificado"],
            "regras": [],
            "resumo": "O risco de fraude é médio (0,58).",
        }

        resp = await async_client.get(
            "/api/v1/levis/avaliacoes/00000000-0000-0000-0000-000000000009/explicacoes/porque-nao",
            params={"conclusao": "INCERTEZA.FRAUDE:RISCO_BAIXO"},
        )

        assert resp.status_code == 200
        corpo = resp.json()
        assert corpo["valorObtido"] == "RISCO_MEDIO"
        assert corpo["obtida"] is False
        assert corpo["propostaPor"] == ["EF-06 Comprovativo verificado"]

    @pytest.mark.asyncio
    async def test_parametros_de_incerteza(
        self,
        async_client: AsyncClient,
        mock_levis_client: AsyncMock,
    ) -> None:
        resp = await async_client.get("/api/v1/levis/incerteza/parametros")

        assert resp.status_code == 200
        parametros = resp.json()
        assert parametros["versao"] == "0.1-demonstrativo"
        assert parametros["demonstrativo"] is True
        assert parametros["razoesVerosimilhanca"]["ED-01"] == pytest.approx(4.0)
        mock_levis_client.get_uncertainty_parameters.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_parametros_de_incerteza_com_motor_indisponivel(
        self,
        async_client: AsyncClient,
        mock_levis_client: AsyncMock,
    ) -> None:
        mock_levis_client.get_uncertainty_parameters.side_effect = LevisConnectionError(
            message="Connection refused to Drools engine",
            url="http://localhost:8082",
        )

        resp = await async_client.get("/api/v1/levis/incerteza/parametros")

        assert resp.status_code == 503
        assert "Connection refused" in resp.json()["detail"]
