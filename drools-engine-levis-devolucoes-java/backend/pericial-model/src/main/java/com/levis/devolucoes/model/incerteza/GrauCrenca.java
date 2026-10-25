package com.levis.devolucoes.model.incerteza;

import com.levis.devolucoes.model.enums.ClassificacaoIncerteza;
import com.levis.devolucoes.model.enums.Hipotese;
import com.levis.devolucoes.model.enums.MetodoIncerteza;
import java.util.ArrayList;
import java.util.List;

/**
 * Grau calculado para uma hipótese: CF em [−1, 1], probabilidade em [0, 1], grau fuzzy em [0, 1] ou
 * recomendação em [0, 100], com a classe dos limiares e os passos do cálculo (auditoria e
 * explicações).
 */
public class GrauCrenca {

  private String pedidoId;
  private String artigoId;
  private Hipotese hipotese;
  private MetodoIncerteza metodo;
  private double valor;
  private ClassificacaoIncerteza classificacao;
  private List<Contribuicao> contribuicoes = new ArrayList<>();
  private String versaoParametros;
  private boolean demonstrativo;

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

  public Hipotese getHipotese() {
    return hipotese;
  }

  public void setHipotese(Hipotese hipotese) {
    this.hipotese = hipotese;
  }

  public MetodoIncerteza getMetodo() {
    return metodo;
  }

  public void setMetodo(MetodoIncerteza metodo) {
    this.metodo = metodo;
  }

  public double getValor() {
    return valor;
  }

  public void setValor(double valor) {
    this.valor = valor;
  }

  public ClassificacaoIncerteza getClassificacao() {
    return classificacao;
  }

  public void setClassificacao(ClassificacaoIncerteza classificacao) {
    this.classificacao = classificacao;
  }

  public List<Contribuicao> getContribuicoes() {
    return contribuicoes;
  }

  public void setContribuicoes(List<Contribuicao> contribuicoes) {
    this.contribuicoes = contribuicoes;
  }

  public String getVersaoParametros() {
    return versaoParametros;
  }

  public void setVersaoParametros(String versaoParametros) {
    this.versaoParametros = versaoParametros;
  }

  public boolean isDemonstrativo() {
    return demonstrativo;
  }

  public void setDemonstrativo(boolean demonstrativo) {
    this.demonstrativo = demonstrativo;
  }
}
