package com.levis.devolucoes.incerteza.certeza;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

import com.levis.devolucoes.incerteza.ResultadoCalculo;
import com.levis.devolucoes.model.enums.FonteEvidencia;
import com.levis.devolucoes.model.enums.Hipotese;
import com.levis.devolucoes.model.incerteza.Contribuicao;
import com.levis.devolucoes.model.incerteza.Evidencia;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Fatores de certeza (docs/08 §2.1 e §2.4); valores demonstrativos do ficheiro de teste. */
class CombinadorFatoresCertezaTest {

  private static final double TOLERANCIA = 0.00005;

  private static Evidencia ev(String codigo, double cf, Boolean presente) {
    Evidencia e =
        new Evidencia(codigo, Hipotese.FRAUDE, "P", null, presente, FonteEvidencia.SISTEMA);
    e.setPeso(cf);
    e.setDescricao(codigo);
    return e;
  }

  private static List<Evidencia> cenario6() {
    return List.of(
        ev("EF-01", 0.30, true),
        ev("EF-02", 0.20, true),
        ev("EF-03", 0.30, true),
        ev("EF-04", 0.40, true),
        ev("EF-05", 0.30, true));
  }

  @Test
  void ambosPositivos() {
    assertThat(CombinadorFatoresCerteza.combinar(0.3, 0.2)).isCloseTo(0.44, within(TOLERANCIA));
  }

  @Test
  void ambosNegativos() {
    assertThat(CombinadorFatoresCerteza.combinar(-0.3, -0.2)).isCloseTo(-0.44, within(TOLERANCIA));
  }

  @Test
  void sinaisOpostos() {
    assertThat(CombinadorFatoresCerteza.combinar(0.30, -0.60))
        .isCloseTo(-0.4286, within(TOLERANCIA));
  }

  @Test
  void cadeiaDoCenario6() {
    ResultadoCalculo r = new CombinadorFatoresCerteza().calcular(cenario6());

    assertThat(r.valor()).isCloseTo(0.8354, within(TOLERANCIA));
    assertThat(r.contribuicoes())
        .extracting(Contribuicao::getValorDepois)
        .satisfiesExactly(
            v -> assertThat(v).isCloseTo(0.3000, within(TOLERANCIA)),
            v -> assertThat(v).isCloseTo(0.4400, within(TOLERANCIA)),
            v -> assertThat(v).isCloseTo(0.6080, within(TOLERANCIA)),
            v -> assertThat(v).isCloseTo(0.7648, within(TOLERANCIA)),
            v -> assertThat(v).isCloseTo(0.8354, within(TOLERANCIA)));
  }

  @Test
  void aOrdemDasEvidenciasNaoAlteraOResultado() {
    List<Evidencia> baralhadas = new ArrayList<>(cenario6());
    Collections.reverse(baralhadas);
    baralhadas.add(ev("EF-06", -0.60, true));
    List<Evidencia> ordenadas = new ArrayList<>(cenario6());
    ordenadas.add(0, ev("EF-06", -0.60, true));

    double a = new CombinadorFatoresCerteza().calcular(baralhadas).valor();
    double b = new CombinadorFatoresCerteza().calcular(ordenadas).valor();

    assertThat(a).isCloseTo(b, within(TOLERANCIA));
    assertThat(CombinadorFatoresCerteza.combinar(0.4, -0.6))
        .isCloseTo(CombinadorFatoresCerteza.combinar(-0.6, 0.4), within(TOLERANCIA));
  }

  @Test
  void semEvidenciasOCertezaEZero() {
    assertThat(new CombinadorFatoresCerteza().calcular(List.of()).valor()).isZero();
  }

  @Test
  void soAsEvidenciasPresentesContam() {
    ResultadoCalculo r =
        new CombinadorFatoresCerteza()
            .calcular(
                List.of(ev("EF-01", 0.30, true), ev("EF-04", 0.40, null), ev("EF-05", 0.3, false)));

    assertThat(r.valor()).isCloseTo(0.30, within(TOLERANCIA));
    assertThat(r.contribuicoes())
        .filteredOn(c -> !c.isAplicada())
        .extracting(Contribuicao::getCodigo, Contribuicao::getMotivoNaoAplicada)
        .containsExactly(
            org.assertj.core.groups.Tuple.tuple("EF-04", "desconhecida"),
            org.assertj.core.groups.Tuple.tuple("EF-05", "ausente"));
  }
}
