package com.levis.devolucoes.model.produto;

import com.levis.devolucoes.model.enums.CategoriaProduto;
import com.levis.devolucoes.model.enums.Marca;
import java.math.BigDecimal;

/** Dados de catálogo do artigo (IN-007). */
public class Produto {

  private String sku;
  private boolean skuReconhecidoPOS;
  private Marca marca;
  private CategoriaProduto categoria;
  private boolean grossista;
  private boolean vendidoNaLoja;
  private boolean produtoFranquia;
  private BigDecimal pvpOriginal;
  private BigDecimal precoAtual;
  private boolean emSaldo;

  /** Defeito de fabrico conhecido para o SKU, segundo o catálogo (docs/08, ED-04). */
  private boolean defeitoConhecido;

  /** PC-007: o produto é bodywear. */
  public boolean isBodywear() {
    return categoria == CategoriaProduto.BODYWEAR;
  }

  public String getSku() {
    return sku;
  }

  public void setSku(String sku) {
    this.sku = sku;
  }

  public boolean isSkuReconhecidoPOS() {
    return skuReconhecidoPOS;
  }

  public void setSkuReconhecidoPOS(boolean skuReconhecidoPOS) {
    this.skuReconhecidoPOS = skuReconhecidoPOS;
  }

  public Marca getMarca() {
    return marca;
  }

  public void setMarca(Marca marca) {
    this.marca = marca;
  }

  public CategoriaProduto getCategoria() {
    return categoria;
  }

  public void setCategoria(CategoriaProduto categoria) {
    this.categoria = categoria;
  }

  public boolean isGrossista() {
    return grossista;
  }

  public void setGrossista(boolean grossista) {
    this.grossista = grossista;
  }

  public boolean isVendidoNaLoja() {
    return vendidoNaLoja;
  }

  public void setVendidoNaLoja(boolean vendidoNaLoja) {
    this.vendidoNaLoja = vendidoNaLoja;
  }

  public boolean isProdutoFranquia() {
    return produtoFranquia;
  }

  public void setProdutoFranquia(boolean produtoFranquia) {
    this.produtoFranquia = produtoFranquia;
  }

  public BigDecimal getPvpOriginal() {
    return pvpOriginal;
  }

  public void setPvpOriginal(BigDecimal pvpOriginal) {
    this.pvpOriginal = pvpOriginal;
  }

  public BigDecimal getPrecoAtual() {
    return precoAtual;
  }

  public void setPrecoAtual(BigDecimal precoAtual) {
    this.precoAtual = precoAtual;
  }

  public boolean isEmSaldo() {
    return emSaldo;
  }

  public void setEmSaldo(boolean emSaldo) {
    this.emSaldo = emSaldo;
  }

  public boolean isDefeitoConhecido() {
    return defeitoConhecido;
  }

  public void setDefeitoConhecido(boolean defeitoConhecido) {
    this.defeitoConhecido = defeitoConhecido;
  }
}
