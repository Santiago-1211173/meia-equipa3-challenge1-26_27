package com.levis.devolucoes.model.pedido;

/** Cliente que apresenta o pedido e o seu comportamento (PT-006, EX-002, EX-003). */
public class Cliente {

  private String id;
  private boolean forneceDados = true;
  private boolean barreiraLinguistica;
  private boolean contestaResultado;
  private boolean agitado;

  /** O cliente explica onde e quando comprou; null se o colaborador não sabe (docs/08, EF-04). */
  private Boolean explicaOrigemCompra;

  /** O cliente pede o reembolso em numerário (docs/08, EF-05). */
  private boolean pedeNumerario;

  public String getId() {
    return id;
  }

  public void setId(String id) {
    this.id = id;
  }

  public boolean isForneceDados() {
    return forneceDados;
  }

  public void setForneceDados(boolean forneceDados) {
    this.forneceDados = forneceDados;
  }

  public boolean isBarreiraLinguistica() {
    return barreiraLinguistica;
  }

  public void setBarreiraLinguistica(boolean barreiraLinguistica) {
    this.barreiraLinguistica = barreiraLinguistica;
  }

  public boolean isContestaResultado() {
    return contestaResultado;
  }

  public void setContestaResultado(boolean contestaResultado) {
    this.contestaResultado = contestaResultado;
  }

  public boolean isAgitado() {
    return agitado;
  }

  public void setAgitado(boolean agitado) {
    this.agitado = agitado;
  }

  public Boolean getExplicaOrigemCompra() {
    return explicaOrigemCompra;
  }

  public void setExplicaOrigemCompra(Boolean explicaOrigemCompra) {
    this.explicaOrigemCompra = explicaOrigemCompra;
  }

  public boolean isPedeNumerario() {
    return pedeNumerario;
  }

  public void setPedeNumerario(boolean pedeNumerario) {
    this.pedeNumerario = pedeNumerario;
  }
}
