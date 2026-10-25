package com.levis.devolucoes.explicacao.incerteza;

import com.levis.devolucoes.model.enums.ClassificacaoIncerteza;
import com.levis.devolucoes.model.enums.Hipotese;
import java.util.List;

/**
 * "Porque não?" de uma classe de um grau de crença (docs/08 §7.2): a distância aos limiares e o que
 * mudaria a classe.
 *
 * @param hipotese hipótese avaliada
 * @param artigoId artigo, ou nulo para as hipóteses do pedido
 * @param perguntada classe perguntada (ex.: RISCO_ALTO)
 * @param obtida classe obtida, ou nula se o grau não foi calculado
 * @param valor valor do grau, ou nulo
 * @param conseguida a classe perguntada foi obtida
 * @param mudariam evidências não aplicadas que aproximariam o grau da classe perguntada, ou as
 *     regras fuzzy ativas
 * @param resumo texto para o colaborador
 */
public record ExplicacaoPorqueNaoGrau(
    Hipotese hipotese,
    String artigoId,
    ClassificacaoIncerteza perguntada,
    ClassificacaoIncerteza obtida,
    Double valor,
    boolean conseguida,
    List<String> mudariam,
    String resumo) {}
