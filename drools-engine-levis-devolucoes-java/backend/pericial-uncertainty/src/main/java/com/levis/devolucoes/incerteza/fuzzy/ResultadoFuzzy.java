package com.levis.devolucoes.incerteza.fuzzy;

import java.util.List;
import java.util.Map;

/**
 * Resultado de uma inferência fuzzy.
 *
 * @param valor valor desfuzzificado (centroide) da variável de saída
 * @param pertencas por variável de entrada, os termos com pertença maior que zero
 * @param regras as regras ativadas (força maior que zero), pela ordem do ficheiro FCL
 */
public record ResultadoFuzzy(
    double valor, Map<String, Map<String, Double>> pertencas, List<RegraAtivada> regras) {

  public ResultadoFuzzy {
    pertencas = Map.copyOf(pertencas);
    regras = List.copyOf(regras);
  }
}
