package com.levis.devolucoes.incerteza.parametros;

import com.levis.devolucoes.model.enums.EstadoEtiquetas;
import java.util.Map;

/**
 * Parâmetros da camada de incerteza, lidos de {@code parametros-incerteza.yml} (docs/08 §6). Os
 * valores são demonstrativos enquanto {@link #demonstrativo()} for verdadeiro.
 *
 * @param versao versão do ficheiro, gravada em cada grau de crença (auditoria)
 * @param demonstrativo os valores não foram validados pela operação; a interface mostra o aviso
 */
public record ParametrosIncerteza(
    String versao, boolean demonstrativo, FatoresCerteza fatoresCerteza, Bayes bayes, Fuzzy fuzzy) {

  /** Fatores de certeza (docs/08 §2). */
  public record FatoresCerteza(Fraude fraude) {}

  /** Risco de fraude: CF por evidência EF-xx e limiares. */
  public record Fraude(
      Map<String, EvidenciaCf> evidencias, int diferencaEstadosMinima, LimiaresRisco limiares) {}

  /** Fator de certeza de uma evidência, em [−1, 1]. */
  public record EvidenciaCf(double cf, String descricao) {}

  /** Limiares do risco: médio e alto. */
  public record LimiaresRisco(double medio, double alto) {}

  /** Probabilidade bayesiana (docs/08 §3). */
  public record Bayes(DefeitoFabrico defeitoFabrico) {}

  /** Defeito de fabrico ou desgaste: prior, LR por evidência ED-xx e limiares. */
  public record DefeitoFabrico(
      double prior,
      Map<String, EvidenciaLr> evidencias,
      int diasCompraRecente,
      LimiaresDefeito limiares) {}

  /** Razão de verosimilhança de uma evidência (maior que 0) e o seu grupo de correlação. */
  public record EvidenciaLr(double lr, String descricao, String grupo) {}

  /** Limiares da probabilidade de defeito: rever e propor PC-006. */
  public record LimiaresDefeito(double rever, double proporPc006) {}

  /** Lógica fuzzy (docs/08 §4). */
  public record Fuzzy(Revendibilidade revendibilidade, CreditoPt004 creditoPt004) {}

  /** Revendibilidade (IN-010). */
  public record Revendibilidade(
      String fcl,
      Map<EstadoEtiquetas, Double> integridadeEtiquetas,
      LimiaresRevendibilidade limiares) {}

  /** Limiares da revendibilidade: indeterminada e revendível. */
  public record LimiaresRevendibilidade(double indeterminada, double revendivel) {}

  /** Recomendação de crédito de loja depois de PT-004. */
  public record CreditoPt004(
      String fcl,
      int prazoDias,
      LimitesCredito limites,
      PorOmissaoCredito porOmissao,
      LimiaresCredito limiares) {}

  /** Limites superiores das entradas. */
  public record LimitesCredito(double diasAposPrazo, double valor) {}

  /** Valores das entradas que não foram calculadas. */
  public record PorOmissaoCredito(double revendibilidade, double risco) {}

  /** Limiares da recomendação: a critério e recomendado. */
  public record LimiaresCredito(double aCriterio, double recomendado) {}
}
