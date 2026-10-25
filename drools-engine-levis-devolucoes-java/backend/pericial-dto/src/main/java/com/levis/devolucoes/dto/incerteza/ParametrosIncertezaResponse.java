package com.levis.devolucoes.dto.incerteza;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.Map;

/**
 * Parâmetros da camada de incerteza em vigor, só para leitura (docs/08 §7.1).
 *
 * @param demonstrativo os valores são demonstrativos: a interface mostra o aviso
 * @param fatoresCerteza CF de cada evidência de fraude (EF-xx)
 * @param razoesVerosimilhanca LR de cada evidência de defeito (ED-xx)
 * @param priorDefeito probabilidade inicial de defeito de fabrico
 * @param limiares limiares de cada classificação (ex.: {@code fraude.alto})
 * @param ficheirosFcl ficheiros FCL das funções de pertença e das regras fuzzy
 */
@Schema(description = "Parâmetros da camada de incerteza (valores demonstrativos)")
public record ParametrosIncertezaResponse(
    String versao,
    boolean demonstrativo,
    Map<String, Double> fatoresCerteza,
    Map<String, Double> razoesVerosimilhanca,
    double priorDefeito,
    Map<String, Double> limiares,
    Map<String, String> ficheirosFcl) {}
