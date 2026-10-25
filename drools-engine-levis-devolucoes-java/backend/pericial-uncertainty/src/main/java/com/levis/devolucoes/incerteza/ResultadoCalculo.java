package com.levis.devolucoes.incerteza;

import com.levis.devolucoes.model.incerteza.Contribuicao;
import java.util.List;

/** Valor de um cálculo de incerteza e os passos que o produziram. */
public record ResultadoCalculo(double valor, List<Contribuicao> contribuicoes) {

  public ResultadoCalculo {
    contribuicoes = List.copyOf(contribuicoes);
  }
}
