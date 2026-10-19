"""Tests for Retail Prolog parity endpoints (/retail/avaliar, /retail/cenarios-exemplo, etc.)."""

from __future__ import annotations

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app





@pytest.mark.asyncio
async def test_listar_cenarios_exemplo(async_client: AsyncClient):
    """Ensure /api/v1/retail/cenarios-exemplo returns all 10 scenarios."""
    resp = await async_client.get("/api/v1/retail/cenarios-exemplo")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 10
    assert data[0]["id"] == 1
    assert "pedido" in data[0]


@pytest.mark.asyncio
async def test_obter_cenario_exemplo_id(async_client: AsyncClient):
    """Ensure /api/v1/retail/cenarios-exemplo/1 returns Scenario 1."""
    resp = await async_client.get("/api/v1/retail/cenarios-exemplo/1")
    assert resp.status_code == 200
    data = resp.json()
    assert data["id"] == 1
    assert "As etiquetas soltas" in data["titulo"]


@pytest.mark.asyncio
async def test_avaliar_cenario_1(async_client: AsyncClient):
    """Ensure /api/v1/retail/avaliar evaluates Scenario 1 and returns DecisaoResponse."""
    sc_resp = await async_client.get("/api/v1/retail/cenarios-exemplo/1")
    sc_data = sc_resp.json()

    resp = await async_client.post("/api/v1/retail/avaliar", json=sc_data["pedido"])
    assert resp.status_code == 200
    dec = resp.json()

    assert dec["elegibilidade"] == "REVER"
    assert dec["tipoTransacao"] == "TROCA"
    assert "avaliacaoId" in dec
    assert len(dec["regras"]) > 0

    # Test explain how
    eval_id = dec["avaliacaoId"]
    how_resp = await async_client.get(f"/api/v1/retail/avaliacoes/{eval_id}/explicacoes/como")
    assert how_resp.status_code == 200
    how_data = how_resp.json()
    assert len(how_data["passos"]) > 0

    # Test explain why not
    wn_resp = await async_client.get(
        f"/api/v1/retail/avaliacoes/{eval_id}/explicacoes/porque-nao?conclusao=OUT-001:PERMITIR"
    )
    assert wn_resp.status_code == 200
    wn_data = wn_resp.json()
    assert wn_data["valor"] == "PERMITIR"


@pytest.mark.asyncio
async def test_retail_health(async_client: AsyncClient):
    """Ensure /api/v1/retail/health reports UP."""
    resp = await async_client.get("/api/v1/retail/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "UP"


@pytest.mark.asyncio
async def test_retail_porque_empty_payload(async_client: AsyncClient):
    """Ensure /api/v1/retail/porque returns dependent rules and empty waiting rules on empty payload."""
    resp = await async_client.post("/api/v1/retail/porque?dado=IN-001", json={})
    assert resp.status_code == 200
    data = resp.json()
    assert data["codigo"] == "IN-001"
    assert data["dado"] == "IN-001"
    assert "TN-011" in data["regrasQueDependem"]
    assert len(data["regrasEmEspera"]) == 0
    assert "TN-011" in data["resumo"]


@pytest.mark.asyncio
async def test_retail_porque_dynamic_waiting_rules(async_client: AsyncClient):
    """Ensure /api/v1/retail/porque dynamically deduces rules waiting on IN-001 with Interac facts."""
    payload = {
        "compraOriginal": {
            "pagamento": {
                "meio": "interac",
                "cartaoFisicoPresente": True,
            }
        }
    }
    resp = await async_client.post("/api/v1/retail/porque?dado=IN-001", json=payload)
    assert resp.status_code == 200
    data = resp.json()
    assert data["codigo"] == "IN-001"
    assert "TN-011" in data["regrasQueDependem"]
    assert len(data["regrasEmEspera"]) >= 1

    waiting_codes = [r["codigoRegra"] for r in data["regrasEmEspera"]]
    assert "TN-011" in waiting_codes
    assert "TN-011" in data["resumo"]

    first_wait = data["regrasEmEspera"][0]
    assert "TN-011" in first_wait["nomeRegra"]
    assert first_wait["modulo"] == "tn"
    assert len(first_wait["condicoesDoDado"]) > 0
    assert first_wait["condicoesDoDado"][0]["nome"] == "mercado"


@pytest.mark.asyncio
async def test_retail_porque_in008_product_condition(async_client: AsyncClient):
    """Ensure /api/v1/retail/porque for IN-008 queries product condition policy rules."""
    resp = await async_client.post("/api/v1/retail/porque?dado=IN-008", json={})
    assert resp.status_code == 200
    data = resp.json()
    assert data["codigo"] == "IN-008"
    assert len(data["regrasQueDependem"]) > 0
    assert any(r.startswith("PC-") for r in data["regrasQueDependem"])

