package com.levis.devolucoes.incerteza.fuzzy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.tuple;
import static org.assertj.core.api.Assertions.within;

import java.util.Map;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/** Motor fuzzy com os ficheiros FCL (docs/08 §4.1 e §4.2). */
class MotorFuzzyFclTest {

  private final MotorFuzzy motor = new MotorFuzzyFcl();

  @ParameterizedTest(name = "grauUso {0}, etiquetas {1} → {2}")
  @CsvSource({"0, 0.6, 0.844", "0, 0.0, 0.500", "1, 0.0, 0.325", "1, 1.0, 0.675"})
  void exemplosDaRevendibilidade(double grauUso, double etiquetas, double esperado) {
    ResultadoFuzzy r =
        motor.avaliar(
            "fcl/revendibilidade.fcl", Map.of("grauUso", grauUso, "etiquetas", etiquetas));

    assertThat(r.valor()).isCloseTo(esperado, within(0.02));
  }

  @Test
  void devolveAsRegrasAtivasComAForcaEAsPertencas() {
    ResultadoFuzzy r =
        motor.avaliar("fcl/revendibilidade.fcl", Map.of("grauUso", 1.0, "etiquetas", 0.0));

    assertThat(r.regras())
        .extracting(RegraAtivada::id, RegraAtivada::forca, RegraAtivada::consequente)
        .containsExactly(
            tuple("RV3", 0.5, "revendibilidade é media"),
            tuple("RV5", 0.5, "revendibilidade é baixa"));
    assertThat(r.pertencas().get("grauUso"))
        .containsEntry("nenhum", 0.5)
        .containsEntry("ligeiro", 0.5)
        .doesNotContainKey("moderado");
    assertThat(r.pertencas().get("etiquetas")).containsEntry("ausentes", 1.0);
  }

  @ParameterizedTest(name = "caso {0} → {5}")
  @CsvSource({
    "A, 5, 0.83, 0.10, 80, 84.4, CR1",
    "B, 25, 0.83, 0.10, 80, 50.0, CR2",
    "C, 25, 0.83, 0.10, 220, 32.3, CR2",
    "D, 100, 0.83, 0.10, 80, 15.6, CR5",
    "E, 5, 0.83, 0.55, 80, 50.0, CR4"
  })
  void exemplosDaRecomendacaoDeCredito(
      String caso,
      double dias,
      double revendibilidade,
      double risco,
      double valor,
      double esperado,
      String primeiraRegra) {
    ResultadoFuzzy r =
        motor.avaliar(
            "fcl/credito-pt004.fcl",
            Map.of(
                "diasAposPrazo", dias,
                "revendibilidade", revendibilidade,
                "risco", risco,
                "valor", valor));

    assertThat(r.valor()).as(caso).isCloseTo(esperado, within(2.0));
    assertThat(r.regras().getFirst().id()).isEqualTo(primeiraRegra);
  }

  @Test
  void casoCAtivaCR2ECR8ComAMesmaForca() {
    ResultadoFuzzy r =
        motor.avaliar(
            "fcl/credito-pt004.fcl",
            Map.of("diasAposPrazo", 25.0, "revendibilidade", 0.83, "risco", 0.10, "valor", 220.0));

    assertThat(r.regras()).extracting(RegraAtivada::id).containsExactly("CR2", "CR8");
    assertThat(r.regras().get(0).forca()).isCloseTo(0.524, within(0.001));
    assertThat(r.regras().get(1).forca()).isCloseTo(0.524, within(0.001));
  }

  @Test
  void entradaEmFaltaOuFclInexistenteSaoErros() {
    assertThatThrownBy(() -> motor.avaliar("fcl/revendibilidade.fcl", Map.of("grauUso", 0.0)))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("etiquetas");
    assertThatThrownBy(() -> motor.avaliar("fcl/inexistente.fcl", Map.of()))
        .isInstanceOf(IllegalArgumentException.class);
  }
}
