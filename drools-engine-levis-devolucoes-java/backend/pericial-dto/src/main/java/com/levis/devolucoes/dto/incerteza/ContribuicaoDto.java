package com.levis.devolucoes.dto.incerteza;

/**
 * Um passo do cálculo de um grau de crença: uma evidência (EF/ED) ou uma regra fuzzy (RV/CR); nas
 * pertenças fuzzy, o código é {@code variavel.termo}.
 *
 * @param peso CF, LR, pertença ou força da regra
 * @param aplicada falso para as evidências desconhecidas, ausentes ou de um grupo já contado
 */
public record ContribuicaoDto(
    String codigo,
    String descricao,
    double peso,
    double valorAntes,
    double valorDepois,
    boolean aplicada,
    String motivoNaoAplicada) {}
