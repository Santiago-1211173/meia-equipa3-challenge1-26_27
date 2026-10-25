package com.levis.devolucoes.model.produto;

import com.levis.devolucoes.model.enums.CondicaoUso;
import com.levis.devolucoes.model.enums.EstadoEtiquetas;
import java.util.LinkedHashMap;
import java.util.Map;

/** Resultado da inspeção física do artigo (IN-008). */
public class EstadoProduto {

  private CondicaoUso condicaoUso;
  private EstadoEtiquetas etiquetas;
  private boolean personalizado;
  private boolean alterado;
  private boolean embainhado;
  private boolean defeitoFabricoConfirmado;
  private boolean sujoOuInseguro;
  private boolean danificado;
  private boolean etiquetaPrecoCorreta = true;
  private boolean rfidCorreto = true;
  private boolean embalagemIntacta;
  private boolean conjuntoCompleto = true;

  /**
   * Grau de uso observado pelo colaborador, 0 (nenhum) a 4 (intenso); null se desconhecido
   * (docs/08).
   */
  private Integer grauUso;

  /** O cliente alega um defeito do produto (docs/08 §3.2). */
  private boolean alegaDefeito;

  /**
   * Respostas da inspeção de defeito: ED-xx → presente (TRUE), ausente (FALSE) ou "Não sei" (null).
   */
  private Map<String, Boolean> inspecaoDefeito = new LinkedHashMap<>();

  /** HS-003: personalizado, alterado ou embainhado. */
  public boolean isModificado() {
    return personalizado || alterado || embainhado;
  }

  public CondicaoUso getCondicaoUso() {
    return condicaoUso;
  }

  public void setCondicaoUso(CondicaoUso condicaoUso) {
    this.condicaoUso = condicaoUso;
  }

  public EstadoEtiquetas getEtiquetas() {
    return etiquetas;
  }

  public void setEtiquetas(EstadoEtiquetas etiquetas) {
    this.etiquetas = etiquetas;
  }

  public boolean isPersonalizado() {
    return personalizado;
  }

  public void setPersonalizado(boolean personalizado) {
    this.personalizado = personalizado;
  }

  public boolean isAlterado() {
    return alterado;
  }

  public void setAlterado(boolean alterado) {
    this.alterado = alterado;
  }

  public boolean isEmbainhado() {
    return embainhado;
  }

  public void setEmbainhado(boolean embainhado) {
    this.embainhado = embainhado;
  }

  public boolean isDefeitoFabricoConfirmado() {
    return defeitoFabricoConfirmado;
  }

  public void setDefeitoFabricoConfirmado(boolean defeitoFabricoConfirmado) {
    this.defeitoFabricoConfirmado = defeitoFabricoConfirmado;
  }

  public boolean isSujoOuInseguro() {
    return sujoOuInseguro;
  }

  public void setSujoOuInseguro(boolean sujoOuInseguro) {
    this.sujoOuInseguro = sujoOuInseguro;
  }

  public boolean isDanificado() {
    return danificado;
  }

  public void setDanificado(boolean danificado) {
    this.danificado = danificado;
  }

  public boolean isEtiquetaPrecoCorreta() {
    return etiquetaPrecoCorreta;
  }

  public void setEtiquetaPrecoCorreta(boolean etiquetaPrecoCorreta) {
    this.etiquetaPrecoCorreta = etiquetaPrecoCorreta;
  }

  public boolean isRfidCorreto() {
    return rfidCorreto;
  }

  public void setRfidCorreto(boolean rfidCorreto) {
    this.rfidCorreto = rfidCorreto;
  }

  public boolean isEmbalagemIntacta() {
    return embalagemIntacta;
  }

  public void setEmbalagemIntacta(boolean embalagemIntacta) {
    this.embalagemIntacta = embalagemIntacta;
  }

  public boolean isConjuntoCompleto() {
    return conjuntoCompleto;
  }

  public void setConjuntoCompleto(boolean conjuntoCompleto) {
    this.conjuntoCompleto = conjuntoCompleto;
  }

  public Integer getGrauUso() {
    return grauUso;
  }

  public void setGrauUso(Integer grauUso) {
    this.grauUso = grauUso;
  }

  public boolean isAlegaDefeito() {
    return alegaDefeito;
  }

  public void setAlegaDefeito(boolean alegaDefeito) {
    this.alegaDefeito = alegaDefeito;
  }

  public Map<String, Boolean> getInspecaoDefeito() {
    return inspecaoDefeito;
  }

  public void setInspecaoDefeito(Map<String, Boolean> inspecaoDefeito) {
    this.inspecaoDefeito = inspecaoDefeito == null ? new LinkedHashMap<>() : inspecaoDefeito;
  }
}
