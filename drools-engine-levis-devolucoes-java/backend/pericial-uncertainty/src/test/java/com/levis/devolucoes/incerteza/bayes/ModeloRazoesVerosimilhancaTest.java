package com.levis.devolucoes.incerteza.bayes;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.tuple;
import static org.assertj.core.api.Assertions.within;

import com.levis.devolucoes.incerteza.ResultadoCalculo;
import com.levis.devolucoes.model.enums.FonteEvidencia;
import com.levis.devolucoes.model.enums.Hipotese;
import com.levis.devolucoes.model.incerteza.Contribuicao;
import com.levis.devolucoes.model.incerteza.Evidencia;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Razões de verosimilhança (docs/08 §3.1 e §3.5); valores demonstrativos do ficheiro de teste. */
class ModeloRazoesVerosimilhancaTest {

  private static final double PRIOR = 0.30;
  private static final double TOLERANCIA = 0.00005;
  private final ModeloBayesiano modelo = new ModeloRazoesVerosimilhanca();

  private static Evidencia ev(String codigo, double lr, String grupo, Boolean presente) {
    Evidencia e =
        new Evidencia(
            codigo, Hipotese.DEFEITO_FABRICO, "P", "A-1", presente, FonteEvidencia.COLABORADOR);
    e.setPeso(lr);
    e.setGrupo(grupo);
    e.setDescricao(codigo);
    return e;
  }

  @Test
  void casoACosturaLocalizadaECompraRecente() {
    ResultadoCalculo r =
        modelo.calcular(
            PRIOR,
            List.of(
                ev("ED-01", 4.0, null, true),
                ev("ED-02", 2.5, null, true),
                ev("ED-03", 2.0, null, true)));

    assertThat(r.valor()).isCloseTo(0.8955, within(TOLERANCIA));
    assertThat(r.contribuicoes().getFirst().getValorAntes()).isCloseTo(PRIOR, within(TOLERANCIA));
  }

  @Test
  void casoBCosturaComSinaisDeUsoAplicaSoAEvidenciaMaisForteDoGrupo() {
    ResultadoCalculo r =
        modelo.calcular(
            PRIOR,
            List.of(
                ev("ED-01", 4.0, null, true),
                ev("ED-05", 0.25, "USO", true),
                ev("ED-06", 0.40, "USO", true)));

    assertThat(r.valor()).isCloseTo(0.3000, within(TOLERANCIA));
    assertThat(r.contribuicoes())
        .filteredOn(c -> !c.isAplicada())
        .extracting(Contribuicao::getCodigo, Contribuicao::getMotivoNaoAplicada)
        .containsExactly(tuple("ED-06", "grupo USO"));
  }

  @Test
  void semARegraDeGrupoADuplaContagemDariaOutroValor() {
    ResultadoCalculo r =
        modelo.calcular(
            PRIOR,
            List.of(
                ev("ED-01", 4.0, null, true),
                ev("ED-05", 0.25, "USO-A", true),
                ev("ED-06", 0.40, "USO-B", true)));

    assertThat(r.valor()).isCloseTo(0.1463, within(TOLERANCIA));
  }

  @Test
  void casoCCosturaEmCompraRecente() {
    ResultadoCalculo r =
        modelo.calcular(PRIOR, List.of(ev("ED-01", 4.0, null, true), ev("ED-03", 2.0, null, true)));

    assertThat(r.valor()).isCloseTo(0.7742, within(TOLERANCIA));
  }

  @Test
  void evidenciaAusenteOuDesconhecidaNaoEAplicada() {
    ResultadoCalculo r =
        modelo.calcular(
            PRIOR,
            List.of(
                ev("ED-01", 4.0, null, false),
                ev("ED-07", 0.10, null, null),
                ev("ED-02", 2.5, null, true)));

    double odds = PRIOR / (1 - PRIOR) * 2.5;
    assertThat(r.valor()).isCloseTo(odds / (1 + odds), within(TOLERANCIA));
    assertThat(r.contribuicoes())
        .filteredOn(c -> !c.isAplicada())
        .extracting(Contribuicao::getCodigo, Contribuicao::getMotivoNaoAplicada)
        .containsExactly(tuple("ED-01", "ausente"), tuple("ED-07", "desconhecida"));
  }

  @Test
  void semEvidenciasFicaOPrior() {
    assertThat(modelo.calcular(PRIOR, List.of()).valor()).isCloseTo(PRIOR, within(TOLERANCIA));
  }
}
