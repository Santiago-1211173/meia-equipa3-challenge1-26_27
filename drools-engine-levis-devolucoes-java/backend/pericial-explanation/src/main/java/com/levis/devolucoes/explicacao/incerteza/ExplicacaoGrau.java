package com.levis.devolucoes.explicacao.incerteza;

import com.levis.devolucoes.model.enums.ClassificacaoIncerteza;
import com.levis.devolucoes.model.enums.Hipotese;
import com.levis.devolucoes.model.enums.MetodoIncerteza;
import com.levis.devolucoes.model.incerteza.Contribuicao;
import java.util.List;

/**
 * "Como?" de um grau de crença (docs/08 §7.2): o valor, a classe e os passos do cálculo.
 *
 * @param hipotese hipótese avaliada
 * @param artigoId artigo, ou nulo para as hipóteses do pedido
 * @param calculado o grau foi calculado neste pedido
 * @param regra regra que o calculou (IU-10, IU-20, IU-30 ou IU-40), ou nula
 * @param metodo técnica usada, ou nula se não foi calculado
 * @param valor valor do grau, ou nulo
 * @param classificacao classe resultante dos limiares, ou nula
 * @param contribuicoes passos do cálculo, como foram guardados
 * @param passos os passos em texto, pela ordem do cálculo
 * @param versaoParametros versão do ficheiro de parâmetros
 * @param demonstrativo os parâmetros são demonstrativos
 * @param resumo texto para o colaborador, com o aviso quando os valores são demonstrativos
 */
public record ExplicacaoGrau(
    Hipotese hipotese,
    String artigoId,
    boolean calculado,
    String regra,
    MetodoIncerteza metodo,
    Double valor,
    ClassificacaoIncerteza classificacao,
    List<Contribuicao> contribuicoes,
    List<String> passos,
    String versaoParametros,
    boolean demonstrativo,
    String resumo) {}
