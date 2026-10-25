package com.levis.devolucoes.model.incerteza;

/** Um passo do cálculo de um grau de crença: uma evidência (EF/ED) ou uma regra fuzzy (RV/CR). */
public class Contribuicao {

  private String codigo;
  private String descricao;
  private double peso;
  private double valorAntes;
  private double valorDepois;
  private boolean aplicada;
  private String motivoNaoAplicada;

  public Contribuicao() {}

  /** Contribuição aplicada ao cálculo. */
  public static Contribuicao aplicada(
      String codigo, String descricao, double peso, double antes, double depois) {
    Contribuicao c = new Contribuicao();
    c.codigo = codigo;
    c.descricao = descricao;
    c.peso = peso;
    c.valorAntes = antes;
    c.valorDepois = depois;
    c.aplicada = true;
    return c;
  }

  /** Contribuição registada mas não aplicada (desconhecida, ausente ou de um grupo já usado). */
  public static Contribuicao naoAplicada(
      String codigo, String descricao, double peso, double valor, String motivo) {
    Contribuicao c = new Contribuicao();
    c.codigo = codigo;
    c.descricao = descricao;
    c.peso = peso;
    c.valorAntes = valor;
    c.valorDepois = valor;
    c.motivoNaoAplicada = motivo;
    return c;
  }

  public String getCodigo() {
    return codigo;
  }

  public void setCodigo(String codigo) {
    this.codigo = codigo;
  }

  public String getDescricao() {
    return descricao;
  }

  public void setDescricao(String descricao) {
    this.descricao = descricao;
  }

  public double getPeso() {
    return peso;
  }

  public void setPeso(double peso) {
    this.peso = peso;
  }

  public double getValorAntes() {
    return valorAntes;
  }

  public void setValorAntes(double valorAntes) {
    this.valorAntes = valorAntes;
  }

  public double getValorDepois() {
    return valorDepois;
  }

  public void setValorDepois(double valorDepois) {
    this.valorDepois = valorDepois;
  }

  public boolean isAplicada() {
    return aplicada;
  }

  public void setAplicada(boolean aplicada) {
    this.aplicada = aplicada;
  }

  public String getMotivoNaoAplicada() {
    return motivoNaoAplicada;
  }

  public void setMotivoNaoAplicada(String motivoNaoAplicada) {
    this.motivoNaoAplicada = motivoNaoAplicada;
  }
}
