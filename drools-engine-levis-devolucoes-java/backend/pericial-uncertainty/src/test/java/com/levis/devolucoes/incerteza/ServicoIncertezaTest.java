package com.levis.devolucoes.incerteza;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

import com.levis.devolucoes.model.decisao.IndicadorFraude;
import com.levis.devolucoes.model.enums.ClassificacaoIncerteza;
import com.levis.devolucoes.model.enums.EstadoEtiquetas;
import com.levis.devolucoes.model.enums.FonteEvidencia;
import com.levis.devolucoes.model.enums.Hipotese;
import com.levis.devolucoes.model.enums.MetodoIncerteza;
import com.levis.devolucoes.model.enums.NivelRisco;
import com.levis.devolucoes.model.incerteza.Contribuicao;
import com.levis.devolucoes.model.incerteza.Evidencia;
import com.levis.devolucoes.model.incerteza.GrauCrenca;
import com.levis.devolucoes.model.pedido.CompraOriginal;
import com.levis.devolucoes.model.pedido.PedidoDevolucao;
import com.levis.devolucoes.model.produto.ArtigoDevolvido;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/** Fachada da camada de incerteza com os parâmetros de teste (docs/08 §2.4, §3.5, §4.1, §4.2). */
class ServicoIncertezaTest {

  static final ServicoIncerteza SERVICO =
      ServicoIncerteza.comParametros("parametros-incerteza-teste.yml");

  private static Evidencia fraude(String codigo) {
    return SERVICO.evidenciaFraude(codigo, "P", true, FonteEvidencia.SISTEMA);
  }

  private static Evidencia defeito(String codigo) {
    return SERVICO.evidenciaDefeito(codigo, "P", "A-1", true, FonteEvidencia.COLABORADOR);
  }

  @Test
  void riscoDoCenario6EAltoEDaUmIndicioSignificativo() {
    GrauCrenca g =
        SERVICO.riscoFraude(
            "P",
            List.of(
                fraude("EF-01"),
                fraude("EF-02"),
                fraude("EF-03"),
                fraude("EF-04"),
                fraude("EF-05")));

    assertThat(g.getValor()).isCloseTo(0.8354, within(0.00005));
    assertThat(g.getClassificacao()).isEqualTo(ClassificacaoIncerteza.RISCO_ALTO);
    assertThat(g.getHipotese()).isEqualTo(Hipotese.FRAUDE);
    assertThat(g.getMetodo()).isEqualTo(MetodoIncerteza.FATOR_CERTEZA);
    assertThat(g.getVersaoParametros()).isEqualTo("teste");
    assertThat(g.isDemonstrativo()).isTrue();
    assertThat(g.getArtigoId()).isNull();

    IndicadorFraude indicio = SERVICO.indicadorFraude(g);
    assertThat(indicio.getNivelRisco()).isEqualTo(NivelRisco.SIGNIFICATIVO);
    assertThat(indicio.getPedidoId()).isEqualTo("P");
    assertThat(indicio.getDescricao()).contains("0,84").contains("EF-01").contains("demonstrativ");
  }

  @Test
  void riscoDoCenario3EBaixo() {
    GrauCrenca g = SERVICO.riscoFraude("P", List.of(fraude("EF-01")));

    assertThat(g.getValor()).isCloseTo(0.30, within(0.00005));
    assertThat(g.getClassificacao()).isEqualTo(ClassificacaoIncerteza.RISCO_BAIXO);
  }

  @Test
  void riscoMedioEntreOsLimiares() {
    GrauCrenca g = SERVICO.riscoFraude("P", List.of(fraude("EF-01"), fraude("EF-02")));

    assertThat(g.getValor()).isCloseTo(0.44, within(0.00005));
    assertThat(g.getClassificacao()).isEqualTo(ClassificacaoIncerteza.RISCO_MEDIO);
  }

  @Test
  void osLimiaresIncluemOValorDoLimiar() {
    Evidencia alto = fraude("EF-01");
    alto.setPeso(SERVICO.parametros().fatoresCerteza().fraude().limiares().alto());
    Evidencia medio = fraude("EF-01");
    medio.setPeso(SERVICO.parametros().fatoresCerteza().fraude().limiares().medio());

    assertThat(SERVICO.riscoFraude("P", List.of(alto)).getClassificacao())
        .isEqualTo(ClassificacaoIncerteza.RISCO_ALTO);
    assertThat(SERVICO.riscoFraude("P", List.of(medio)).getClassificacao())
        .isEqualTo(ClassificacaoIncerteza.RISCO_MEDIO);
  }

  @Test
  void sinaisOpostosDaoRiscoBaixo() {
    GrauCrenca g = SERVICO.riscoFraude("P", List.of(fraude("EF-03"), fraude("EF-06")));

    assertThat(g.getValor()).isCloseTo(-0.4286, within(0.00005));
    assertThat(g.getClassificacao()).isEqualTo(ClassificacaoIncerteza.RISCO_BAIXO);
  }

  @Test
  void asEvidenciasLevamOPesoEOGrupoDosParametros() {
    assertThat(fraude("EF-06").getPeso()).isEqualTo(-0.60);
    assertThat(defeito("ED-05").getPeso()).isEqualTo(0.25);
    assertThat(defeito("ED-05").getGrupo()).isEqualTo("USO");
    assertThat(defeito("ED-01").getGrupo()).isNull();
    assertThat(defeito("ED-01").getDescricao()).isEqualTo("Dano numa costura ou ponto de união");
  }

  @Test
  void defeitoCasoAPropoePc006() {
    GrauCrenca g =
        SERVICO.probabilidadeDefeito(
            "P", "A-1", List.of(defeito("ED-01"), defeito("ED-02"), defeito("ED-03")));

    assertThat(g.getValor()).isCloseTo(0.8955, within(0.00005));
    assertThat(g.getClassificacao()).isEqualTo(ClassificacaoIncerteza.PROPOR_PC006);
    assertThat(g.getArtigoId()).isEqualTo("A-1");
    assertThat(g.getMetodo()).isEqualTo(MetodoIncerteza.BAYES);
  }

  @Test
  void defeitoCasoBEDesgaste() {
    GrauCrenca g =
        SERVICO.probabilidadeDefeito(
            "P", "A-1", List.of(defeito("ED-01"), defeito("ED-05"), defeito("ED-06")));

    assertThat(g.getValor()).isCloseTo(0.3000, within(0.00005));
    assertThat(g.getClassificacao()).isEqualTo(ClassificacaoIncerteza.DESGASTE);
  }

  @Test
  void defeitoCasoCPedeRevisao() {
    GrauCrenca g =
        SERVICO.probabilidadeDefeito("P", "A-1", List.of(defeito("ED-01"), defeito("ED-03")));

    assertThat(g.getValor()).isCloseTo(0.7742, within(0.00005));
    assertThat(g.getClassificacao()).isEqualTo(ClassificacaoIncerteza.REVER_DEFEITO);
  }

  @ParameterizedTest(name = "grauUso {0}, etiquetas {1} → {2} {3}")
  @CsvSource({
    "0, SOLTAS, 0.844, REVENDIVEL",
    "0, AUSENTES, 0.500, REVENDIBILIDADE_INDETERMINADA",
    "1, AUSENTES, 0.325, NAO_REVENDIVEL",
    "1, COLOCADAS, 0.675, REVENDIVEL"
  })
  void revendibilidade(
      int grauUso, EstadoEtiquetas etiquetas, double esperado, ClassificacaoIncerteza classe) {
    GrauCrenca g = SERVICO.revendibilidade("P", "A-1", grauUso, etiquetas);

    assertThat(g.getValor()).isCloseTo(esperado, within(0.02));
    assertThat(g.getClassificacao()).isEqualTo(classe);
    assertThat(g.getMetodo()).isEqualTo(MetodoIncerteza.FUZZY);
  }

  @Test
  void revendibilidadeGuardaPertencasERegrasAtivas() {
    GrauCrenca g = SERVICO.revendibilidade("P", "A-1", 1, EstadoEtiquetas.AUSENTES);

    assertThat(g.getContribuicoes())
        .extracting(Contribuicao::getCodigo)
        .contains("grauUso.nenhum", "grauUso.ligeiro", "etiquetas.ausentes", "RV3", "RV5");
    assertThat(g.getContribuicoes())
        .filteredOn(c -> c.getCodigo().equals("RV3"))
        .singleElement()
        .satisfies(c -> assertThat(c.getPeso()).isEqualTo(0.5));
  }

  @ParameterizedTest(name = "caso {0}")
  @CsvSource({
    "A, 35, 0.83, 0.10, 80, CREDITO_RECOMENDADO, 84.4",
    "B, 55, 0.83, 0.10, 80, CREDITO_A_CRITERIO, 50.0",
    "C, 55, 0.83, 0.10, 220, CREDITO_NAO_RECOMENDADO, 32.3",
    "D, 130, 0.83, 0.10, 80, CREDITO_NAO_RECOMENDADO, 15.6",
    "E, 35, 0.83, 0.55, 80, CREDITO_A_CRITERIO, 50.0"
  })
  void recomendacaoDeCredito(
      String caso,
      long dias,
      double revendibilidade,
      double risco,
      String valor,
      ClassificacaoIncerteza classe,
      double esperado) {
    GrauCrenca g =
        SERVICO.recomendacaoCredito("P", dias, revendibilidade, risco, new BigDecimal(valor));

    assertThat(g.getClassificacao()).as(caso).isEqualTo(classe);
    assertThat(g.getValor()).as(caso).isCloseTo(esperado, within(2.0));
    assertThat(g.getHipotese()).isEqualTo(Hipotese.RECOMENDACAO_CREDITO);
  }

  @Test
  void recomendacaoUsaOsValoresPorOmissaoELimitaAsEntradas() {
    GrauCrenca semGraus = SERVICO.recomendacaoCredito("P", 35, null, null, new BigDecimal("80"));
    GrauCrenca riscoNegativo =
        SERVICO.recomendacaoCredito("P", 35, 0.83, -0.6, new BigDecimal("80"));
    GrauCrenca baixo = SERVICO.recomendacaoCredito("P", 35, 0.83, 0.0, new BigDecimal("80"));
    GrauCrenca muitoTarde =
        SERVICO.recomendacaoCredito("P", 900, 0.83, 0.1, new BigDecimal("9000"));

    assertThat(semGraus.getContribuicoes())
        .extracting(Contribuicao::getCodigo)
        .contains("revendibilidade.media");
    assertThat(riscoNegativo.getValor()).isCloseTo(baixo.getValor(), within(0.0001));
    assertThat(muitoTarde.getClassificacao())
        .isEqualTo(ClassificacaoIncerteza.CREDITO_NAO_RECOMENDADO);
  }

  @Test
  void integridadeDasEtiquetasVemDosParametros() {
    assertThat(SERVICO.integridadeEtiquetas(EstadoEtiquetas.COLOCADAS)).isEqualTo(1.0);
    assertThat(SERVICO.integridadeEtiquetas(EstadoEtiquetas.SOLTAS)).isEqualTo(0.6);
    assertThat(SERVICO.integridadeEtiquetas(EstadoEtiquetas.AUSENTES)).isEqualTo(0.0);
  }

  @Test
  void expoeOsParametrosUsadosPelasRegras() {
    assertThat(SERVICO.versao()).isEqualTo("teste");
    assertThat(SERVICO.isDemonstrativo()).isTrue();
    assertThat(SERVICO.diferencaEstadosMinima()).isEqualTo(2);
    assertThat(SERVICO.diasCompraRecente()).isEqualTo(30);
    assertThat(SERVICO.prazoCreditoDias()).isEqualTo(30);
  }

  @Test
  void aConfiguracaoPadraoUsaOFicheiroDeProducao() {
    assertThat(ServicoIncerteza.padrao().isDemonstrativo()).isTrue();
  }

  @Test
  void recomendacaoDoPedidoUsaAMenorRevendibilidadeORiscoEASomaDosPrecos() {
    PedidoDevolucao pedido = new PedidoDevolucao();
    pedido.setId("P");
    CompraOriginal compra = new CompraOriginal();
    compra.setDataCompra(LocalDate.now().minusDays(35));
    pedido.setCompraOriginal(compra);
    pedido.setDataPedido(LocalDate.now());
    ArtigoDevolvido a1 = new ArtigoDevolvido();
    a1.setPrecoPago(new BigDecimal("50"));
    ArtigoDevolvido a2 = new ArtigoDevolvido();
    a2.setPrecoPago(new BigDecimal("30"));
    pedido.setArtigos(List.of(a1, a2));
    GrauCrenca alta = SERVICO.revendibilidade("P", "A-1", 0, EstadoEtiquetas.SOLTAS);
    GrauCrenca risco = SERVICO.riscoFraude("P", List.of(fraude("EF-06")));

    GrauCrenca g = SERVICO.recomendacaoCreditoPedido(pedido, List.of(alta, risco));
    GrauCrenca direto =
        SERVICO.recomendacaoCredito("P", 35, alta.getValor(), 0.0, new BigDecimal("80"));

    assertThat(g.getValor()).isCloseTo(direto.getValor(), within(0.0001));
    assertThat(SERVICO.resumo(g))
        .startsWith("recomendação de crédito de loja")
        .contains("demonstrativos");
    assertThat(SERVICO.resumo(risco)).contains("-0,60").contains("RISCO_BAIXO");
  }
}
