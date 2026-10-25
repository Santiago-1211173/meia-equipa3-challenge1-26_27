package com.levis.devolucoes.regras;

import static com.levis.devolucoes.model.teste.PedidoBuilder.umPedido;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

import com.levis.devolucoes.model.decisao.DecisaoArtigo;
import com.levis.devolucoes.model.enums.CategoriaProduto;
import com.levis.devolucoes.model.enums.ClassificacaoIncerteza;
import com.levis.devolucoes.model.enums.CondicaoUso;
import com.levis.devolucoes.model.enums.Elegibilidade;
import com.levis.devolucoes.model.enums.EstadoEtiquetas;
import com.levis.devolucoes.model.enums.Hipotese;
import com.levis.devolucoes.model.enums.NivelAprovacao;
import com.levis.devolucoes.model.incerteza.Contribuicao;
import com.levis.devolucoes.model.incerteza.GrauCrenca;
import com.levis.devolucoes.model.pedido.PedidoDevolucao;
import com.levis.devolucoes.model.produto.ArtigoDevolvido;
import com.levis.devolucoes.model.teste.PedidoBuilder;
import com.levis.devolucoes.regras.cenarios.CarregadorCenarios;
import com.levis.devolucoes.regras.cenarios.Cenario;
import com.levis.devolucoes.regras.suporte.MotorTeste;
import com.levis.devolucoes.regras.suporte.Regra;
import com.levis.devolucoes.regras.suporte.ResultadoAvaliacao;
import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.function.Consumer;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * Camada de incerteza (docs/08 §5.4 e §8), com os parâmetros fixos de teste. Os valores esperados
 * são os do docs/08 e são demonstrativos.
 */
class IncertezaTest {

  private static final double CF = 0.00005;

  private static ResultadoAvaliacao avaliar(PedidoBuilder pedido) {
    return MotorTeste.avaliar(pedido.construir());
  }

  private static GrauCrenca grau(ResultadoAvaliacao r, Hipotese hipotese, String artigo) {
    return r.grau(hipotese, artigo)
        .orElseThrow(() -> new AssertionError("Sem grau " + hipotese + " em " + artigo));
  }

  private static boolean aplicada(GrauCrenca g, String codigo) {
    return g.getContribuicoes().stream()
        .anyMatch(c -> c.getCodigo().equals(codigo) && c.isAplicada());
  }

  /** Artigo usado em que o cliente alega defeito, com as respostas de inspeção indicadas. */
  private static Consumer<ArtigoDevolvido> alegaDefeito(String... presentes) {
    return a -> {
      a.getEstado().setCondicaoUso(CondicaoUso.USADO);
      a.getEstado().setAlegaDefeito(true);
      Map<String, Boolean> inspecao = new LinkedHashMap<>();
      for (String codigo : presentes) {
        inspecao.put(codigo, true);
      }
      a.getEstado().setInspecaoDefeito(inspecao);
    };
  }

  private static Consumer<ArtigoDevolvido> estado(
      CondicaoUso uso, EstadoEtiquetas etiquetas, Integer grauUso) {
    return a -> {
      a.getEstado().setCondicaoUso(uso);
      a.getEstado().setEtiquetas(etiquetas);
      a.getEstado().setGrauUso(grauUso);
    };
  }

  private static Cenario lerCenario6(boolean comportamentoDificil) {
    Cenario c = CarregadorCenarios.ler(6);
    c.pedido().getCliente().setAgitado(comportamentoDificil);
    c.pedido().getCliente().setContestaResultado(comportamentoDificil);
    return c;
  }

  // -------------------------------------------------------------------------------------------

  @Nested
  class Evidencias {

    @Test
    @Regra("IU-01")
    void semComprovativoDaEF01() {
      ResultadoAvaliacao r = avaliar(umPedido().semComprovativo());

      assertThat(r.disparou("IU-01")).isTrue();
      assertThat(aplicada(grau(r, Hipotese.FRAUDE, null), "EF-01")).isTrue();
    }

    @Test
    @Regra("IU-02")
    void todosOsArtigosSemEtiquetasDaoAEF02() {
      ResultadoAvaliacao r =
          avaliar(
              umPedido()
                  .artigo(estado(CondicaoUso.NAO_USADO, EstadoEtiquetas.AUSENTES, null))
                  .maisUmArtigo(
                      "A-2", estado(CondicaoUso.NAO_USADO, EstadoEtiquetas.AUSENTES, null)));
      ResultadoAvaliacao umComEtiquetas =
          avaliar(
              umPedido()
                  .artigo(estado(CondicaoUso.NAO_USADO, EstadoEtiquetas.AUSENTES, null))
                  .maisUmArtigo("A-2", a -> {}));

      assertThat(r.disparou("IU-02")).isTrue();
      assertThat(umComEtiquetas.disparou("IU-02")).isFalse();
    }

    @Test
    @Regra("IU-03")
    void estadosMuitoDiferentesDaoAEF03() {
      ResultadoAvaliacao diferentes =
          avaliar(
              umPedido()
                  .artigo(a -> a.getEstado().setGrauUso(0))
                  .maisUmArtigo("A-2", a -> a.getEstado().setGrauUso(2)));
      ResultadoAvaliacao parecidos =
          avaliar(
              umPedido()
                  .artigo(a -> a.getEstado().setGrauUso(0))
                  .maisUmArtigo("A-2", a -> a.getEstado().setGrauUso(1)));
      ResultadoAvaliacao umSo = avaliar(umPedido().artigo(a -> a.getEstado().setGrauUso(4)));

      assertThat(diferentes.disparou("IU-03")).isTrue();
      assertThat(parecidos.disparou("IU-03")).isFalse();
      assertThat(umSo.disparou("IU-03")).isFalse();
    }

    @Test
    @Regra("IU-05")
    void pedirNumerarioAsCegasDaAEF05() {
      ResultadoAvaliacao asCegas =
          avaliar(umPedido().semComprovativo().com(p -> p.getCliente().setPedeNumerario(true)));
      ResultadoAvaliacao comRecibo =
          avaliar(umPedido().com(p -> p.getCliente().setPedeNumerario(true)));

      assertThat(asCegas.disparou("IU-05")).isTrue();
      assertThat(comRecibo.disparou("IU-05")).isFalse();
    }

    @Test
    @Regra({"IU-06", "IU-10"})
    void comprovativoVerificadoDaAEF06EUmRiscoNegativo() {
      ResultadoAvaliacao r = avaliar(umPedido());

      GrauCrenca risco = grau(r, Hipotese.FRAUDE, null);
      assertThat(r.disparou("IU-06")).isTrue();
      assertThat(risco.getValor()).isCloseTo(-0.60, within(CF));
      assertThat(risco.getClassificacao()).isEqualTo(ClassificacaoIncerteza.RISCO_BAIXO);
      assertThat(risco.isDemonstrativo()).isTrue();
      assertThat(r.decisao().getVersaoParametrosIncerteza()).isEqualTo("teste");
    }

    @Test
    @Regra("IU-07")
    void compraRecenteDaAEvidenciaED03PresenteOuAusente() {
      ResultadoAvaliacao recente = avaliar(umPedido().artigo(alegaDefeito()));
      ResultadoAvaliacao antiga = avaliar(umPedido().diasDesdeCompra(40).artigo(alegaDefeito()));

      assertThat(recente.disparou("IU-07")).isTrue();
      assertThat(aplicada(grau(recente, Hipotese.DEFEITO_FABRICO, "A-1"), "ED-03")).isTrue();
      assertThat(grau(antiga, Hipotese.DEFEITO_FABRICO, "A-1").getContribuicoes())
          .filteredOn(c -> c.getCodigo().equals("ED-03"))
          .extracting(Contribuicao::getMotivoNaoAplicada)
          .containsExactly("ausente");
    }
  }

  // -------------------------------------------------------------------------------------------

  @Nested
  class RiscoDeFraude {

    @Test
    @Regra({"IU-10", "IU-11"})
    @DisplayName("Cenário 6: risco 0,8354 alto, indício registado e EX-008 suspende")
    void cenario6() {
      Cenario c = lerCenario6(true);
      ResultadoAvaliacao r = MotorTeste.avaliar(c.pedido(), c.indicadoresFraude());

      GrauCrenca risco = grau(r, Hipotese.FRAUDE, null);
      assertThat(risco.getValor()).isCloseTo(0.8354, within(CF));
      assertThat(risco.getClassificacao()).isEqualTo(ClassificacaoIncerteza.RISCO_ALTO);
      assertThat(r.disparou("IU-11")).isTrue();
      assertThat(r.disparou("EX-008")).isTrue();
      assertThat(r.decisao().isTerminal()).isTrue();
      assertThat(r.disparos())
          .as("depois da suspensão nada mais é avaliado")
          .doesNotContain("IU-30", "IU-33", "PT-002");
      assertThat(r.decisao().getElegibilidade()).isEqualTo(Elegibilidade.REVER);
    }

    @Test
    @DisplayName("Não enviesamento: o comportamento do cliente não muda o risco (docs/08 §1.2.3)")
    @Regra("IU-10")
    void comportamentoDoClienteNaoEEvidencia() {
      Cenario dificil = lerCenario6(true);
      Cenario calmo = lerCenario6(false);

      double comportamentoDificil =
          grau(
                  MotorTeste.avaliar(dificil.pedido(), dificil.indicadoresFraude()),
                  Hipotese.FRAUDE,
                  null)
              .getValor();
      double comportamentoCalmo =
          grau(MotorTeste.avaliar(calmo.pedido(), calmo.indicadoresFraude()), Hipotese.FRAUDE, null)
              .getValor();

      assertThat(comportamentoDificil).isEqualTo(comportamentoCalmo);
    }

    @Test
    @Regra("IU-10")
    @DisplayName("Cenário 3: um indício fraco isolado não escala")
    void cenario3() {
      Cenario c = CarregadorCenarios.ler(3);
      ResultadoAvaliacao r = MotorTeste.avaliar(c.pedido(), c.indicadoresFraude());

      GrauCrenca risco = grau(r, Hipotese.FRAUDE, null);
      assertThat(risco.getValor()).isCloseTo(0.30, within(CF));
      assertThat(risco.getClassificacao()).isEqualTo(ClassificacaoIncerteza.RISCO_BAIXO);
      assertThat(r.disparos()).doesNotContain("IU-11", "IU-12", "IU-50");
      assertThat(r.decisao().getElegibilidade()).isEqualTo(Elegibilidade.PERMITIR);
    }

    @Test
    @Regra({"IU-12", "IU-50"})
    void riscoMedioExigeAprovacaoEPoeOsArtigosPermitidosEmRevisao() {
      ResultadoAvaliacao r =
          avaliar(
              umPedido()
                  .semComprovativo()
                  .artigo(
                      a -> {
                        a.getEstado().setEtiquetas(EstadoEtiquetas.AUSENTES);
                        a.setRevendivel(true);
                      }));

      assertThat(grau(r, Hipotese.FRAUDE, null).getClassificacao())
          .isEqualTo(ClassificacaoIncerteza.RISCO_MEDIO);
      assertThat(r.disparou("IU-12")).isTrue();
      assertThat(r.decisao().getAprovacao()).isEqualTo(NivelAprovacao.RESPONSAVEL_SENIOR);
      assertThat(r.artigo("A-1").getElegibilidade()).isEqualTo(Elegibilidade.REVER);
      assertThat(r.registo("IU-50").getMensagem()).contains("Risco de fraude médio");
      assertThat(r.decisao().getElegibilidade()).isEqualTo(Elegibilidade.REVER);
    }

    @Test
    @Regra("IU-50")
    @DisplayName("Princípio 1: uma paragem HS continua a recusar, mesmo com risco médio")
    void aIncertezaNuncaTransformaUmRecusarEmPermitir() {
      ResultadoAvaliacao r =
          avaliar(
              umPedido()
                  .semComprovativo()
                  .artigo(
                      a -> {
                        a.getEstado().setEtiquetas(EstadoEtiquetas.AUSENTES);
                        a.getProduto().setSkuReconhecidoPOS(false);
                      }));

      assertThat(r.disparou("HS-001")).isTrue();
      assertThat(r.artigo("A-1").getElegibilidade()).isEqualTo(Elegibilidade.RECUSAR);
      assertThat(r.disparou("IU-50")).isFalse();
      assertThat(r.decisao().getElegibilidade()).isEqualTo(Elegibilidade.RECUSAR);
    }
  }

  // -------------------------------------------------------------------------------------------

  @Nested
  class DefeitoDeFabrico {

    @Test
    @Regra("IU-20")
    @DisplayName("Cenário 4 com alegação de defeito: HS-003 recusa e o Bayes não corre")
    void hs003ImpedeOCalculo() {
      ResultadoAvaliacao r =
          avaliar(
              umPedido()
                  .artigo(
                      alegaDefeito("ED-01", "ED-02")
                          .andThen(a -> a.getEstado().setEmbainhado(true))));

      assertThat(r.disparou("HS-003")).isTrue();
      assertThat(r.grau(Hipotese.DEFEITO_FABRICO, "A-1")).isEmpty();
    }

    @Test
    @Regra({"IU-20", "IU-21"})
    @DisplayName(
        "Caso A: P = 0,8955, propor PC-006; PC-004 não se aplica; PT-003 permite mas o artigo fica em REVER")
    void casoAProporPc006() {
      ResultadoAvaliacao r = avaliar(umPedido().artigo(alegaDefeito("ED-01", "ED-02")));

      GrauCrenca defeito = grau(r, Hipotese.DEFEITO_FABRICO, "A-1");
      assertThat(defeito.getValor()).isCloseTo(0.8955, within(CF));
      assertThat(defeito.getClassificacao()).isEqualTo(ClassificacaoIncerteza.PROPOR_PC006);
      assertThat(r.disparou("IU-21")).isTrue();
      assertThat(r.disparou("PC-004")).isFalse();
      assertThat(r.disparou("PT-003")).isTrue();
      DecisaoArtigo artigo = r.artigo("A-1");
      assertThat(artigo.getElegibilidade()).isEqualTo(Elegibilidade.REVER);
      assertThat(artigo.getAprovacao()).isEqualTo(NivelAprovacao.RESPONSAVEL_SENIOR);
      assertThat(r.decisao().getElegibilidade()).isEqualTo(Elegibilidade.REVER);
    }

    @Test
    @Regra("PC-006")
    @DisplayName(
        "Caso A com o defeito confirmado pela gestão: PC-006 aplica-se e o Bayes não corre")
    void defeitoConfirmadoAplicaPc006() {
      ResultadoAvaliacao r =
          avaliar(
              umPedido()
                  .artigo(
                      alegaDefeito("ED-01", "ED-02")
                          .andThen(a -> a.getEstado().setDefeitoFabricoConfirmado(true))));

      assertThat(r.disparou("PC-006")).isTrue();
      assertThat(r.grau(Hipotese.DEFEITO_FABRICO, "A-1")).isEmpty();
    }

    @Test
    @Regra({"IU-20", "IU-23"})
    @DisplayName(
        "Caso B: desgaste (0,30); só a evidência mais forte do grupo USO; PC-004 aplica-se")
    void casoBDesgaste() {
      ResultadoAvaliacao r =
          avaliar(umPedido().diasDesdeCompra(40).artigo(alegaDefeito("ED-01", "ED-05", "ED-06")));

      GrauCrenca defeito = grau(r, Hipotese.DEFEITO_FABRICO, "A-1");
      assertThat(defeito.getValor()).isCloseTo(0.3000, within(CF));
      assertThat(defeito.getClassificacao()).isEqualTo(ClassificacaoIncerteza.DESGASTE);
      assertThat(defeito.getContribuicoes())
          .filteredOn(c -> c.getCodigo().equals("ED-06"))
          .extracting(Contribuicao::getMotivoNaoAplicada)
          .containsExactly("grupo USO");
      assertThat(r.disparou("IU-23")).isTrue();
      assertThat(r.disparou("PC-004")).isTrue();
    }

    @Test
    @Regra({"IU-20", "IU-22"})
    @DisplayName("Caso C: P = 0,7742, inspeção adicional; o resultado fica em REVER")
    void casoCInspecaoAdicional() {
      ResultadoAvaliacao r = avaliar(umPedido().artigo(alegaDefeito("ED-01")));

      GrauCrenca defeito = grau(r, Hipotese.DEFEITO_FABRICO, "A-1");
      assertThat(defeito.getValor()).isCloseTo(0.7742, within(CF));
      assertThat(defeito.getClassificacao()).isEqualTo(ClassificacaoIncerteza.REVER_DEFEITO);
      assertThat(r.disparou("IU-22")).isTrue();
      assertThat(r.disparou("PC-004")).isFalse();
      assertThat(r.artigo("A-1").getElegibilidade()).isEqualTo(Elegibilidade.REVER);
    }

    @Test
    @Regra({"PC-005", "IU-21"})
    @DisplayName("Lavado com defeito provável: a PC-005 não recusa e o artigo fica em REVER")
    void lavadoComDefeitoProvavelFicaEmRevisao() {
      ResultadoAvaliacao r =
          avaliar(
              umPedido()
                  .artigo(
                      alegaDefeito("ED-01", "ED-02")
                          .andThen(a -> a.getEstado().setCondicaoUso(CondicaoUso.LAVADO))));

      assertThat(r.disparou("PC-005")).isFalse();
      assertThat(r.artigo("A-1").getElegibilidade()).isEqualTo(Elegibilidade.REVER);
    }

    @Test
    @Regra("IU-20")
    void bodywearNaoTemCalculo() {
      ResultadoAvaliacao r =
          avaliar(
              umPedido()
                  .artigo(
                      alegaDefeito("ED-01")
                          .andThen(a -> a.getProduto().setCategoria(CategoriaProduto.BODYWEAR))));

      assertThat(r.grau(Hipotese.DEFEITO_FABRICO, "A-1")).isEmpty();
    }
  }

  // -------------------------------------------------------------------------------------------

  @Nested
  class Revendibilidade {

    @Test
    @Regra({"IU-30", "IU-31"})
    @DisplayName("Cenário 1 (não usado, etiquetas soltas): revendível 0,844, mas a gestão decide")
    void cenario1SoRecomenda() {
      ResultadoAvaliacao r =
          avaliar(umPedido().artigo(estado(CondicaoUso.NAO_USADO, EstadoEtiquetas.SOLTAS, 0)));

      GrauCrenca revendibilidade = grau(r, Hipotese.REVENDIBILIDADE, "A-1");
      assertThat(revendibilidade.getValor()).isCloseTo(0.844, within(0.02));
      assertThat(revendibilidade.getClassificacao()).isEqualTo(ClassificacaoIncerteza.REVENDIVEL);
      assertThat(r.disparou("IU-31")).isTrue();
      assertThat(r.disparou("PC-002")).isTrue();
      assertThat(r.artigo("A-1").getElegibilidade()).isEqualTo(Elegibilidade.REVER);
    }

    @Test
    @Regra({"IU-30", "IU-32"})
    void naoUsadoSemEtiquetasFicaIndeterminado() {
      ResultadoAvaliacao r =
          avaliar(umPedido().artigo(estado(CondicaoUso.NAO_USADO, EstadoEtiquetas.AUSENTES, 0)));

      assertThat(grau(r, Hipotese.REVENDIBILIDADE, "A-1").getClassificacao())
          .isEqualTo(ClassificacaoIncerteza.REVENDIBILIDADE_INDETERMINADA);
      assertThat(r.disparou("IU-32")).isTrue();
      assertThat(r.artigo("A-1").getElegibilidade()).isEqualTo(Elegibilidade.REVER);
    }

    @Test
    @Regra({"IU-30", "IU-33"})
    void ligeiramenteUsadoSemEtiquetasNaoERevendivelERecusa() {
      ResultadoAvaliacao r =
          avaliar(umPedido().artigo(estado(CondicaoUso.NAO_USADO, EstadoEtiquetas.AUSENTES, 1)));

      GrauCrenca revendibilidade = grau(r, Hipotese.REVENDIBILIDADE, "A-1");
      assertThat(revendibilidade.getValor()).isCloseTo(0.325, within(0.02));
      assertThat(revendibilidade.getClassificacao())
          .isEqualTo(ClassificacaoIncerteza.NAO_REVENDIVEL);
      assertThat(r.disparou("IU-33")).isTrue();
      assertThat(r.artigo("A-1").getElegibilidade()).isEqualTo(Elegibilidade.RECUSAR);
    }

    @Test
    @Regra("IU-30")
    void naoSobrepoeADecisaoDaGestaoNemSeAplicaABodywear() {
      ResultadoAvaliacao decidido =
          avaliar(
              umPedido()
                  .artigo(
                      estado(CondicaoUso.NAO_USADO, EstadoEtiquetas.AUSENTES, 1)
                          .andThen(a -> a.setRevendivel(true))));
      ResultadoAvaliacao bodywear =
          avaliar(
              umPedido()
                  .artigo(
                      estado(CondicaoUso.NAO_USADO, EstadoEtiquetas.SOLTAS, 0)
                          .andThen(a -> a.getProduto().setCategoria(CategoriaProduto.BODYWEAR))));
      ResultadoAvaliacao semGrauUso = avaliar(umPedido());

      assertThat(decidido.grau(Hipotese.REVENDIBILIDADE, "A-1")).isEmpty();
      assertThat(bodywear.grau(Hipotese.REVENDIBILIDADE, "A-1")).isEmpty();
      assertThat(semGrauUso.grau(Hipotese.REVENDIBILIDADE, "A-1")).isEmpty();
    }
  }

  // -------------------------------------------------------------------------------------------

  @Nested
  class RecomendacaoDeCredito {

    private static PedidoDevolucao pt004(long dias, String precoPago) {
      return umPedido()
          .diasDesdeCompra(dias)
          .artigo(
              estado(CondicaoUso.NAO_USADO, EstadoEtiquetas.COLOCADAS, 0)
                  .andThen(a -> a.setPrecoPago(new BigDecimal(precoPago))))
          .construir();
    }

    @ParameterizedTest(name = "caso {0}: {1} dias, {2} → {3}")
    @CsvSource({
      "A, 35, 80, CREDITO_RECOMENDADO",
      "B, 55, 80, CREDITO_A_CRITERIO",
      "C, 55, 220, CREDITO_NAO_RECOMENDADO",
      "D, 130, 80, CREDITO_NAO_RECOMENDADO"
    })
    @Regra("IU-40")
    void recomendaSemAlterarADecisao(
        String caso, long dias, String preco, ClassificacaoIncerteza esperada) {
      ResultadoAvaliacao r = MotorTeste.avaliar(pt004(dias, preco));

      assertThat(r.disparou("PT-004")).isTrue();
      assertThat(r.disparou("IU-40")).isTrue();
      assertThat(grau(r, Hipotese.RECOMENDACAO_CREDITO, null).getClassificacao())
          .as(caso)
          .isEqualTo(esperada);
      assertThat(r.decisao().getElegibilidade()).isEqualTo(Elegibilidade.REVER);
    }

    @Test
    @Regra("IU-40")
    void recomendaTambemComOArtigoJaRevendivel() {
      // A PT-004 nunca aprova o crédito sozinha: deixa sempre em REVER e a gestão decide,
      // por isso a IU-40 recomenda também quando a revenda já foi confirmada
      ResultadoAvaliacao r =
          MotorTeste.avaliar(
              umPedido().diasDesdeCompra(35).artigo(a -> a.setRevendivel(true)).construir());

      assertThat(r.decisao().disparouCom("PT-004", Elegibilidade.REVER)).isTrue();
      assertThat(r.disparou("IU-40")).isTrue();
      assertThat(grau(r, Hipotese.RECOMENDACAO_CREDITO, null)).isNotNull();
      assertThat(r.decisao().getElegibilidade()).isEqualTo(Elegibilidade.REVER);
    }
  }
}
