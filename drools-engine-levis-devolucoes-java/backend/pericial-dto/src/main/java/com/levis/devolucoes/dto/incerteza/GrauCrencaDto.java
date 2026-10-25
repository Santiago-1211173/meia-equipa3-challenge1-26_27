package com.levis.devolucoes.dto.incerteza;

import com.levis.devolucoes.dto.enums.ClassificacaoIncerteza;
import com.levis.devolucoes.dto.enums.Hipotese;
import com.levis.devolucoes.dto.enums.MetodoIncerteza;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

/**
 * Grau calculado pela camada de incerteza (docs/08 §7.1). Enquanto {@code demonstrativo} for
 * verdadeiro, os valores não servem para decisões reais.
 *
 * @param artigoId artigo, ou nulo para o risco de fraude e a recomendação de crédito
 * @param valor CF em [−1, 1] (não é uma probabilidade), probabilidade ou grau em [0, 1], ou
 *     recomendação em [0, 100]
 */
@Schema(description = "Grau de crença da camada de incerteza (valores demonstrativos)")
public record GrauCrencaDto(
    Hipotese hipotese,
    MetodoIncerteza metodo,
    String artigoId,
    double valor,
    ClassificacaoIncerteza classificacao,
    List<ContribuicaoDto> contribuicoes,
    boolean demonstrativo,
    String versaoParametros) {}
