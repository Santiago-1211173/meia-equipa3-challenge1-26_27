package com.levis.devolucoes.incerteza.fuzzy;

import java.util.Map;

/**
 * Motor de inferência fuzzy Mamdani (docs/08 §4.3). Devolve, além do valor desfuzzificado, os graus
 * de pertença das entradas e a força de cada regra ativada, para as explicações.
 */
public interface MotorFuzzy {

  /**
   * Avalia o bloco de um ficheiro FCL do classpath.
   *
   * @param fcl recurso do ficheiro FCL (ex.: {@code fcl/revendibilidade.fcl})
   * @param entradas valor de cada variável de entrada, pelo nome usado no FCL
   * @throws IllegalArgumentException se o ficheiro não existir ou faltar uma entrada
   */
  ResultadoFuzzy avaliar(String fcl, Map<String, Double> entradas);
}
