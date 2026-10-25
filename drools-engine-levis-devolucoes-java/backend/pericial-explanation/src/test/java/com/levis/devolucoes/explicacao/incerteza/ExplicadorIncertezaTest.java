package com.levis.devolucoes.explicacao.incerteza;

import static com.levis.devolucoes.model.teste.PedidoBuilder.umPedido;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.levis.devolucoes.explicacao.SuporteExplicacoes;
import com.levis.devolucoes.explicacao.motor.ResultadoExecucao;
import com.levis.devolucoes.explicacao.texto.GeradorTexto;
import com.levis.devolucoes.model.enums.ClassificacaoIncerteza;
import com.levis.devolucoes.model.enums.CondicaoUso;
import com.levis.devolucoes.model.enums.EstadoEtiquetas;
import com.levis.devolucoes.model.enums.Hipotese;
import com.levis.devolucoes.model.enums.MetodoIncerteza;
import com.levis.devolucoes.model.produto.ArtigoDevolvido;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.function.Consumer;
import org.junit.jupiter.api.Test;

/** Explicações dos graus de crença (docs/08 §7.2), com os parâmetros de teste. */
class ExplicadorIncertezaTest {

  private final ExplicadorIncerteza explicador =
      new ExplicadorIncerteza(SuporteExplicacoes.EXECUTOR.incerteza(), GeradorTexto.portugues());

  private static Consumer<ArtigoDevolvido> inspecao(Map<String, Boolean> respostas) {
    return a -> {
      a.getEstado().setCondicaoUso(CondicaoUso.USADO);
      a.getEstado().setAlegaDefeito(true);
      a.getEstado().setInspecaoDefeito(new LinkedHashMap<>(respostas));
    };
  }

  @Test
  void comoDoRiscoDeFraudeDoCenario6MostraOAcumuladoENaoFalaEmProbabilidade() {
    ResultadoExecucao r = SuporteExplicacoes.cenario(6);

    ExplicacaoGrau g = explicador.como(r, Hipotese.FRAUDE, null);

    assertThat(g.calculado()).isTrue();
    assertThat(g.regra()).isEqualTo("IU-10");
    assertThat(g.metodo()).isEqualTo(MetodoIncerteza.FATOR_CERTEZA);
    assertThat(g.passos())
        .containsExactly(
            "EF-01 +0,30 → 0,30",
            "EF-02 +0,20 → 0,44",
            "EF-03 +0,30 → 0,61",
            "EF-04 +0,40 → 0,76",
            "EF-05 +0,30 → 0,84");
    assertThat(g.resumo())
        .contains("risco de fraude é 0,84 (RISCO_ALTO)")
        .contains("não uma probabilidade")
        .contains("Valores demonstrativos — não usar para decisões reais.");
  }

  @Test
  void porqueNaoSuspendeuIndicaOLimiarEAsEvidenciasQueOLevariamAcima() {
    ResultadoExecucao r =
        SuporteExplicacoes.executar(
            umPedido()
                .semComprovativo()
                .artigo(a -> a.getEstado().setEtiquetas(EstadoEtiquetas.AUSENTES))
                .com(p -> p.getCliente().setExplicaOrigemCompra(true))
                .construir());

    ExplicacaoPorqueNaoGrau x =
        explicador.porqueNao(r, Hipotese.FRAUDE, ClassificacaoIncerteza.RISCO_ALTO, null);

    assertThat(x.conseguida()).isFalse();
    assertThat(x.obtida()).isEqualTo(ClassificacaoIncerteza.RISCO_MEDIO);
    assertThat(x.resumo())
        .startsWith("Não é RISCO_ALTO porque o valor 0,44 é inferior ao limiar 0,70.")
        .contains("EF-04 (Não explica onde nem quando comprou)");
  }

  @Test
  void comoDoDefeitoMostraOPriorEAsEvidenciasNaoAplicadas() {
    ResultadoExecucao r =
        SuporteExplicacoes.executar(
            umPedido()
                .diasDesdeCompra(40)
                .artigo(inspecao(Map.of("ED-01", true, "ED-05", true, "ED-06", true)))
                .construir());

    ExplicacaoGrau g = explicador.como(r, Hipotese.DEFEITO_FABRICO, "A-1");

    assertThat(g.passos().getFirst()).isEqualTo("probabilidade inicial 0,30");
    assertThat(g.passos())
        .contains(
            "ED-01 (LR 4,00) → 0,63",
            "ED-03 não aplicada (não observada)",
            "ED-06 não aplicada (já contada no grupo USO)");
    assertThat(g.classificacao()).isEqualTo(ClassificacaoIncerteza.DESGASTE);
  }

  @Test
  void porqueNaoPropos06DizQueEstaAbaixoDoLimiarEQueEvidenciasMudariam() {
    ResultadoExecucao r =
        SuporteExplicacoes.executar(
            umPedido().artigo(inspecao(Map.of("ED-01", true, "ED-02", false))).construir());

    ExplicacaoPorqueNaoGrau x =
        explicador.porqueNao(
            r, Hipotese.DEFEITO_FABRICO, ClassificacaoIncerteza.PROPOR_PC006, "A-1");

    assertThat(x.obtida()).isEqualTo(ClassificacaoIncerteza.REVER_DEFEITO);
    assertThat(x.resumo())
        .startsWith("Não é PROPOR_PC006 porque o valor 0,77 é inferior ao limiar 0,80.")
        .contains("ED-02 (Dano localizado num único ponto)")
        .doesNotContain("ED-07");
  }

  @Test
  void porqueNaoRevendivelMostraAsRegrasFuzzyAtivas() {
    ResultadoExecucao r =
        SuporteExplicacoes.executar(
            umPedido()
                .artigo(
                    a -> {
                      a.getEstado().setEtiquetas(EstadoEtiquetas.AUSENTES);
                      a.getEstado().setGrauUso(1);
                    })
                .construir());

    ExplicacaoPorqueNaoGrau x =
        explicador.porqueNao(
            r,
            Hipotese.REVENDIBILIDADE,
            ClassificacaoIncerteza.REVENDIBILIDADE_INDETERMINADA,
            "A-1");
    ExplicacaoGrau como = explicador.como(r, Hipotese.REVENDIBILIDADE, "A-1");

    assertThat(x.resumo())
        .startsWith(
            "Não é REVENDIBILIDADE_INDETERMINADA porque o valor 0,32 é inferior ao limiar 0,40.")
        .contains("Regras fuzzy ativas: RV3 0,50, RV5 0,50");
    assertThat(como.passos())
        .contains(
            "grauUso é nenhum com pertença 0,50",
            "regra RV3 (revendibilidade é media) com força 0,50");
  }

  @Test
  void classeObtidaEGrauNaoCalculado() {
    ResultadoExecucao r = SuporteExplicacoes.executar(umPedido().construir());

    assertThat(explicador.porqueNao(r, Hipotese.FRAUDE, ClassificacaoIncerteza.RISCO_BAIXO, null))
        .satisfies(x -> assertThat(x.conseguida()).isTrue());
    ExplicacaoGrau semDefeito = explicador.como(r, Hipotese.DEFEITO_FABRICO, "A-1");
    assertThat(semDefeito.calculado()).isFalse();
    assertThat(semDefeito.resumo()).contains("não foi calculado neste pedido no artigo A-1");
    assertThat(
            explicador
                .porqueNao(r, Hipotese.DEFEITO_FABRICO, ClassificacaoIncerteza.PROPOR_PC006, "A-1")
                .resumo())
        .startsWith("A classificação PROPOR_PC006 não pode ser obtida");
  }

  @Test
  void aClassificacaoTemDePertencerAHipotese() {
    ResultadoExecucao r = SuporteExplicacoes.executar(umPedido().construir());

    assertThatThrownBy(
            () -> explicador.porqueNao(r, Hipotese.FRAUDE, ClassificacaoIncerteza.REVENDIVEL, null))
        .isInstanceOf(IllegalArgumentException.class);
    assertThat(ExplicadorIncerteza.hipoteseDe(ClassificacaoIncerteza.CREDITO_A_CRITERIO))
        .isEqualTo(Hipotese.RECOMENDACAO_CREDITO);
  }

  @Test
  void emInglesOFatorDeCertezaTambemNaoEProbabilidade() {
    ExplicadorIncerteza ingles =
        new ExplicadorIncerteza(
            SuporteExplicacoes.EXECUTOR.incerteza(), new GeradorTexto(Locale.ENGLISH));

    ExplicacaoGrau g = ingles.como(SuporteExplicacoes.cenario(6), Hipotese.FRAUDE, null);

    assertThat(g.resumo())
        .contains("fraud risk is 0.84 (RISCO_ALTO)")
        .contains("not a probability")
        .contains("Demonstration values");
  }
}
