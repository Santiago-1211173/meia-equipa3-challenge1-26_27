package com.levis.devolucoes.model.enums;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class ElegibilidadeTest {

  @Test
  void ordemDeSeveridade() {
    assertThat(Elegibilidade.RECUSAR.maisSeveroQue(Elegibilidade.ENCAMINHAR)).isTrue();
    assertThat(Elegibilidade.ENCAMINHAR.maisSeveroQue(Elegibilidade.REVER)).isTrue();
    assertThat(Elegibilidade.REVER.maisSeveroQue(Elegibilidade.PERMITIR)).isTrue();
    assertThat(Elegibilidade.PERMITIR.maisSeveroQue(null)).isTrue();
    assertThat(Elegibilidade.PERMITIR.maisSeveroQue(Elegibilidade.PERMITIR)).isFalse();
    assertThat(Elegibilidade.REVER.maisSeveroQue(Elegibilidade.RECUSAR)).isFalse();
  }

  @Test
  void modulosPelaOrdemDoFluxogramaComAIncertezaAntesDoM3() {
    assertThat(Modulo.values())
        .containsExactly(
            Modulo.M0,
            Modulo.M1,
            Modulo.M2,
            Modulo.EVIDENCIA,
            Modulo.INCERTEZA,
            Modulo.M3,
            Modulo.M4,
            Modulo.M5,
            Modulo.ONLINE,
            Modulo.M6,
            Modulo.M7,
            Modulo.M8,
            Modulo.M9);
  }
}
