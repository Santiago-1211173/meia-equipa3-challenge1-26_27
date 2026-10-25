package com.levis.devolucoes.incerteza.bayes;

import com.levis.devolucoes.incerteza.Evidencias;
import com.levis.devolucoes.incerteza.ResultadoCalculo;
import com.levis.devolucoes.model.incerteza.Contribuicao;
import com.levis.devolucoes.model.incerteza.Evidencia;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Opção A do ADR 0011: forma odds–verosimilhança do teorema de Bayes, com evidência binária.
 *
 * <ul>
 *   <li>Só as evidências observadas como presentes contribuem com o seu LR.
 *   <li>Dentro de um grupo de correlação só se aplica a de maior |ln LR|; as restantes ficam
 *       registadas como "grupo X".
 * </ul>
 */
public class ModeloRazoesVerosimilhanca implements ModeloBayesiano {

  /** Força de uma evidência: |ln LR|; em empate, a de menor código. */
  private static final Comparator<Evidencia> FORCA =
      Comparator.<Evidencia>comparingDouble(e -> Math.abs(Math.log(e.getPeso())))
          .thenComparing(Evidencias.ORDEM.reversed());

  @Override
  public ResultadoCalculo calcular(double prior, Collection<Evidencia> evidencias) {
    Map<String, Evidencia> maisFortePorGrupo = new HashMap<>();
    for (Evidencia e : evidencias) {
      if (e.isObservada() && e.getGrupo() != null) {
        maisFortePorGrupo.merge(e.getGrupo(), e, (a, b) -> FORCA.compare(a, b) >= 0 ? a : b);
      }
    }

    double p = prior;
    List<Contribuicao> passos = new ArrayList<>();
    for (Evidencia e : Evidencias.ordenadas(evidencias)) {
      if (!e.isObservada()) {
        passos.add(naoAplicada(e, p, Evidencias.motivoNaoObservada(e)));
      } else if (e.getGrupo() != null && maisFortePorGrupo.get(e.getGrupo()) != e) {
        passos.add(naoAplicada(e, p, "grupo " + e.getGrupo()));
      } else {
        double odds = p / (1 - p) * e.getPeso();
        double depois = odds / (1 + odds);
        passos.add(Contribuicao.aplicada(e.getCodigo(), e.getDescricao(), e.getPeso(), p, depois));
        p = depois;
      }
    }
    return new ResultadoCalculo(p, passos);
  }

  private static Contribuicao naoAplicada(Evidencia e, double p, String motivo) {
    return Contribuicao.naoAplicada(e.getCodigo(), e.getDescricao(), e.getPeso(), p, motivo);
  }
}
