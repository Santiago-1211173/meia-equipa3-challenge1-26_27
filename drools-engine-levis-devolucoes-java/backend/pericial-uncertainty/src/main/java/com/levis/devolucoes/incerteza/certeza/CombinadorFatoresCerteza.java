package com.levis.devolucoes.incerteza.certeza;

import com.levis.devolucoes.incerteza.Evidencias;
import com.levis.devolucoes.incerteza.ResultadoCalculo;
import com.levis.devolucoes.model.incerteza.Contribuicao;
import com.levis.devolucoes.model.incerteza.Evidencia;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

/**
 * Combinação de fatores de certeza do modelo MYCIN (docs/08 §2.1). A operação é comutativa e
 * associativa: a ordem das evidências não altera o resultado. Sem evidências, o CF é 0.
 */
public class CombinadorFatoresCerteza {

  /** Combina dois fatores de certeza em [−1, 1]. */
  public static double combinar(double cf1, double cf2) {
    if (cf1 >= 0 && cf2 >= 0) {
      return cf1 + cf2 * (1 - cf1);
    }
    if (cf1 < 0 && cf2 < 0) {
      return cf1 + cf2 * (1 + cf1);
    }
    return (cf1 + cf2) / (1 - Math.min(Math.abs(cf1), Math.abs(cf2)));
  }

  /**
   * CF das evidências observadas como presentes, com um passo por evidência (as ausentes e as
   * desconhecidas ficam registadas como não aplicadas).
   */
  public ResultadoCalculo calcular(Collection<Evidencia> evidencias) {
    double cf = 0;
    List<Contribuicao> passos = new ArrayList<>();
    for (Evidencia e : Evidencias.ordenadas(evidencias)) {
      if (e.isObservada()) {
        double depois = combinar(cf, e.getPeso());
        passos.add(Contribuicao.aplicada(e.getCodigo(), e.getDescricao(), e.getPeso(), cf, depois));
        cf = depois;
      } else {
        passos.add(
            Contribuicao.naoAplicada(
                e.getCodigo(),
                e.getDescricao(),
                e.getPeso(),
                cf,
                Evidencias.motivoNaoObservada(e)));
      }
    }
    return new ResultadoCalculo(cf, passos);
  }
}
