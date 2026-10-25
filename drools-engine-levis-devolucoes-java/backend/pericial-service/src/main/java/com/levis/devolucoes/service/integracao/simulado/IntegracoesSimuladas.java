package com.levis.devolucoes.service.integracao.simulado;

import com.levis.devolucoes.dto.enums.CategoriaProduto;
import com.levis.devolucoes.dto.enums.EstadoConta;
import com.levis.devolucoes.dto.enums.Marca;
import com.levis.devolucoes.service.integracao.porta.BackPocketGateway;
import com.levis.devolucoes.service.integracao.porta.CatalogoProdutoGateway;
import com.levis.devolucoes.service.integracao.porta.PagamentoGateway;
import com.levis.devolucoes.service.integracao.porta.PosGateway;
import java.math.BigDecimal;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

/**
 * Adaptadores simulados, em memória, do POS, do catálogo, da BackPocket e dos pagamentos, para dev
 * e testes (ADR 0007). Não há adaptadores reais: os documentos não especificam as APIs externas.
 */
@Component
public class IntegracoesSimuladas
    implements PosGateway, CatalogoProdutoGateway, BackPocketGateway, PagamentoGateway {

  private final Map<String, ProdutoCatalogo> produtos = new ConcurrentHashMap<>();
  private final Map<String, Boolean> encomendas = new ConcurrentHashMap<>();
  private final Map<String, EstadoConta> contas = new ConcurrentHashMap<>();
  private volatile boolean portalDisponivel = true;

  public IntegracoesSimuladas() {
    registarProduto(
        produto("501-ORIG-32", Marca.LEVIS, CategoriaProduto.VESTUARIO, "98.00", "98.00"));
    registarProduto(
        produto("501-ORIG-34", Marca.LEVIS, CategoriaProduto.VESTUARIO, "98.00", "98.00"));
    // Defeito de fabrico conhecido para o SKU (ED-04, docs/08): dado demonstrativo do catálogo
    // simulado
    registarProduto(
        comDefeitoConhecido(
            produto(
                "TRUCKER-AZUL-M", Marca.LEVIS, CategoriaProduto.VESTUARIO, "128.00", "128.00")));
    registarProduto(
        produto("BW-BOXER-3PK-M", Marca.LEVIS, CategoriaProduto.BODYWEAR, "29.99", "29.99"));
    registarProduto(
        new ProdutoCatalogo(
            "DOCKERS-ALPHA-32",
            Marca.DOCKERS,
            CategoriaProduto.VESTUARIO,
            false,
            false,
            false,
            new BigDecimal("69.50"),
            new BigDecimal("69.50"),
            false,
            false));
    encomendas.put("LCOM-0202", true);
  }

  private static ProdutoCatalogo produto(
      String sku, Marca marca, CategoriaProduto categoria, String pvp, String atual) {
    return new ProdutoCatalogo(
        sku,
        marca,
        categoria,
        false,
        true,
        false,
        new BigDecimal(pvp),
        new BigDecimal(atual),
        false,
        false);
  }

  private static ProdutoCatalogo comDefeitoConhecido(ProdutoCatalogo p) {
    return new ProdutoCatalogo(
        p.sku(),
        p.marca(),
        p.categoria(),
        p.grossista(),
        p.vendidoNaLoja(),
        p.produtoFranquia(),
        p.pvpOriginal(),
        p.precoAtual(),
        p.emSaldo(),
        true);
  }

  // Configuração (dev e testes)

  public void registarProduto(ProdutoCatalogo produto) {
    produtos.put(produto.sku(), produto);
  }

  public void registarEncomenda(String idEncomenda, boolean encontrada) {
    encomendas.put(idEncomenda, encontrada);
  }

  public void registarConta(String idTransacao, EstadoConta estado) {
    contas.put(idTransacao, estado);
  }

  public void definirPortalDisponivel(boolean disponivel) {
    this.portalDisponivel = disponivel;
  }

  // Portas

  @Override
  public boolean skuReconhecido(String sku) {
    return sku != null && produtos.containsKey(sku);
  }

  @Override
  public Optional<ProdutoCatalogo> produto(String sku) {
    return sku == null ? Optional.empty() : Optional.ofNullable(produtos.get(sku));
  }

  @Override
  public Optional<Boolean> encomendaEncontrada(String idEncomenda) {
    return idEncomenda == null
        ? Optional.empty()
        : Optional.of(encomendas.getOrDefault(idEncomenda, false));
  }

  @Override
  public boolean portalDisponivel() {
    return portalDisponivel;
  }

  @Override
  public Optional<EstadoConta> estadoConta(String idTransacao) {
    return idTransacao == null ? Optional.empty() : Optional.ofNullable(contas.get(idTransacao));
  }
}
