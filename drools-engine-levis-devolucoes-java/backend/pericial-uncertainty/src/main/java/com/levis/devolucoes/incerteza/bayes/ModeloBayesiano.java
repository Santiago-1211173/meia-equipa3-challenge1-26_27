package com.levis.devolucoes.incerteza.bayes;

import com.levis.devolucoes.incerteza.ResultadoCalculo;
import com.levis.devolucoes.model.incerteza.Evidencia;
import java.util.Collection;

/**
 * Cálculo da probabilidade de uma hipótese a partir de um prior e de evidências. Isola a escolha da
 * metodologia (ADR 0011): mudar de opção não altera as regras IU-20 a IU-23.
 */
public interface ModeloBayesiano {

  /** Probabilidade final e os passos do cálculo, começando no prior. */
  ResultadoCalculo calcular(double prior, Collection<Evidencia> evidencias);
}
