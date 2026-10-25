package com.levis.devolucoes.regras;

import java.util.List;

/**
 * Ordem de avaliação dos agenda-groups (docs/03, ADR 0001). O grupo TRANSVERSAL (EX-008, PC-008) é
 * avaliado primeiro; seguem-se os módulos M0 a M9 pela ordem do fluxograma.
 */
public final class OrdemAgenda {

  public static final String TRANSVERSAL = "TRANSVERSAL";

  /** Grupos pela ordem em que são avaliados. */
  public static final List<String> GRUPOS =
      List.of(
          TRANSVERSAL,
          "M0",
          "M1",
          "M2",
          "EVIDENCIA",
          "INCERTEZA",
          "M3",
          "M4",
          "M5",
          "ONLINE",
          "M6",
          "M7",
          "M8",
          "M9");

  /** Nome da sessão stateful usada numa avaliação. */
  public static final String SESSAO = "sessaoPericial";

  /** Nome da sessão stateless usada nas simulações. */
  public static final String SESSAO_STATELESS = "sessaoPericialStateless";

  private OrdemAgenda() {}

  /**
   * Grupos pela ordem em que devem receber o foco: o foco é uma pilha, por isso o último a receber
   * o foco é o primeiro a ser avaliado.
   */
  public static List<String> ordemDeFoco() {
    return GRUPOS.reversed();
  }
}
