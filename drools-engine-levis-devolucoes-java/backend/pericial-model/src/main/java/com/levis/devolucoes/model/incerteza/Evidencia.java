package com.levis.devolucoes.model.incerteza;

import com.levis.devolucoes.model.enums.FonteEvidencia;
import com.levis.devolucoes.model.enums.Hipotese;

/**
 * Evidência a favor ou contra uma hipótese (EF-xx para a fraude, ED-xx para o defeito de fabrico).
 * O peso (CF ou LR) vem do ficheiro de parâmetros, nunca do código.
 */
public class Evidencia {

  private String codigo;
  private Hipotese hipotese;
  private String pedidoId;
  private String artigoId;
  private Boolean presente;
  private FonteEvidencia fonte;
  private double peso;
  private String grupo;
  private String descricao;

  public Evidencia() {}

  public Evidencia(
      String codigo,
      Hipotese hipotese,
      String pedidoId,
      String artigoId,
      Boolean presente,
      FonteEvidencia fonte) {
    this.codigo = codigo;
    this.hipotese = hipotese;
    this.pedidoId = pedidoId;
    this.artigoId = artigoId;
    this.presente = presente;
    this.fonte = fonte;
  }

  /** Observada como presente; falso para ausente ou desconhecida ("Não sei"). */
  public boolean isObservada() {
    return Boolean.TRUE.equals(presente);
  }

  public String getCodigo() {
    return codigo;
  }

  public void setCodigo(String codigo) {
    this.codigo = codigo;
  }

  public Hipotese getHipotese() {
    return hipotese;
  }

  public void setHipotese(Hipotese hipotese) {
    this.hipotese = hipotese;
  }

  public String getPedidoId() {
    return pedidoId;
  }

  public void setPedidoId(String pedidoId) {
    this.pedidoId = pedidoId;
  }

  public String getArtigoId() {
    return artigoId;
  }

  public void setArtigoId(String artigoId) {
    this.artigoId = artigoId;
  }

  public Boolean getPresente() {
    return presente;
  }

  public void setPresente(Boolean presente) {
    this.presente = presente;
  }

  public FonteEvidencia getFonte() {
    return fonte;
  }

  public void setFonte(FonteEvidencia fonte) {
    this.fonte = fonte;
  }

  public double getPeso() {
    return peso;
  }

  public void setPeso(double peso) {
    this.peso = peso;
  }

  public String getGrupo() {
    return grupo;
  }

  public void setGrupo(String grupo) {
    this.grupo = grupo;
  }

  public String getDescricao() {
    return descricao;
  }

  public void setDescricao(String descricao) {
    this.descricao = descricao;
  }
}
