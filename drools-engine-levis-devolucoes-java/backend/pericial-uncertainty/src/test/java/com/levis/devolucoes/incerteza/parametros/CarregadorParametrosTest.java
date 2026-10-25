package com.levis.devolucoes.incerteza.parametros;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.levis.devolucoes.incerteza.parametros.ParametrosIncerteza.Bayes;
import com.levis.devolucoes.incerteza.parametros.ParametrosIncerteza.CreditoPt004;
import com.levis.devolucoes.incerteza.parametros.ParametrosIncerteza.DefeitoFabrico;
import com.levis.devolucoes.incerteza.parametros.ParametrosIncerteza.EvidenciaCf;
import com.levis.devolucoes.incerteza.parametros.ParametrosIncerteza.EvidenciaLr;
import com.levis.devolucoes.incerteza.parametros.ParametrosIncerteza.FatoresCerteza;
import com.levis.devolucoes.incerteza.parametros.ParametrosIncerteza.Fraude;
import com.levis.devolucoes.incerteza.parametros.ParametrosIncerteza.Fuzzy;
import com.levis.devolucoes.incerteza.parametros.ParametrosIncerteza.LimiaresDefeito;
import com.levis.devolucoes.incerteza.parametros.ParametrosIncerteza.LimiaresRisco;
import com.levis.devolucoes.incerteza.parametros.ParametrosIncerteza.Revendibilidade;
import com.levis.devolucoes.model.enums.EstadoEtiquetas;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.function.UnaryOperator;
import org.junit.jupiter.api.Test;

class CarregadorParametrosTest {

  private static final ParametrosIncerteza VALIDOS =
      CarregadorParametros.carregar("parametros-incerteza-teste.yml");

  @Test
  void leOFicheiroDeProducaoEODeTeste() {
    ParametrosIncerteza producao =
        CarregadorParametros.carregar(CarregadorParametros.RECURSO_PADRAO);

    assertThat(producao.demonstrativo()).isTrue();
    assertThat(producao.versao()).isNotBlank();
    assertThat(VALIDOS.versao()).isEqualTo("teste");
    assertThat(VALIDOS.fatoresCerteza().fraude().evidencias()).containsKeys("EF-01", "EF-06");
    assertThat(VALIDOS.bayes().defeitoFabrico().evidencias().get("ED-05").grupo()).isEqualTo("USO");
    assertThat(VALIDOS.fuzzy().revendibilidade().integridadeEtiquetas())
        .containsOnlyKeys(EstadoEtiquetas.values());
  }

  @Test
  void rejeitaCfForaDoIntervalo() {
    assertThat(erros(p -> comFraude(p, "EF-01", 1.5))).anyMatch(e -> e.contains("CF de EF-01"));
  }

  @Test
  void rejeitaLrNaoPositivo() {
    assertThat(erros(p -> comLr(p, "ED-01", 0))).anyMatch(e -> e.contains("LR de ED-01"));
  }

  @Test
  void rejeitaPriorForaDeZeroEUm() {
    assertThat(erros(p -> comPrior(p, 1))).anyMatch(e -> e.contains("prior"));
    assertThat(erros(p -> comPrior(p, 0))).anyMatch(e -> e.contains("prior"));
  }

  @Test
  void rejeitaLimiaresNaoCrescentes() {
    assertThat(
            erros(
                p ->
                    new ParametrosIncerteza(
                        p.versao(),
                        p.demonstrativo(),
                        new FatoresCerteza(
                            new Fraude(
                                p.fatoresCerteza().fraude().evidencias(),
                                p.fatoresCerteza().fraude().diferencaEstadosMinima(),
                                new LimiaresRisco(0.7, 0.4))),
                        p.bayes(),
                        p.fuzzy())))
        .anyMatch(e -> e.contains("limiares da fraude"));
  }

  @Test
  void rejeitaFclInexistente() {
    var r = VALIDOS.fuzzy().revendibilidade();
    assertThat(
            erros(
                p ->
                    new ParametrosIncerteza(
                        p.versao(),
                        p.demonstrativo(),
                        p.fatoresCerteza(),
                        p.bayes(),
                        new Fuzzy(
                            new Revendibilidade(
                                "fcl/nao-existe.fcl", r.integridadeEtiquetas(), r.limiares()),
                            p.fuzzy().creditoPt004()))))
        .anyMatch(e -> e.contains("FCL inexistente"));
  }

  @Test
  void rejeitaCreditoSemPrazo() {
    CreditoPt004 c = VALIDOS.fuzzy().creditoPt004();
    assertThat(
            erros(
                p ->
                    new ParametrosIncerteza(
                        p.versao(),
                        p.demonstrativo(),
                        p.fatoresCerteza(),
                        p.bayes(),
                        new Fuzzy(
                            p.fuzzy().revendibilidade(),
                            new CreditoPt004(
                                c.fcl(), 0, c.limites(), c.porOmissao(), c.limiares())))))
        .anyMatch(e -> e.contains("prazoDias"));
  }

  @Test
  void rejeitaSeccoesEmFalta() {
    assertThat(
            erros(
                p ->
                    new ParametrosIncerteza(
                        p.versao(), p.demonstrativo(), null, p.bayes(), p.fuzzy())))
        .anyMatch(e -> e.contains("secções obrigatórias"));
  }

  @Test
  void ficheiroInexistenteFalhaNoArranque() {
    assertThatThrownBy(() -> CarregadorParametros.carregar("parametros/nao-existe.yml"))
        .isInstanceOf(ParametrosInvalidosException.class)
        .hasMessageContaining("ficheiro inexistente");
  }

  @Test
  void ficheiroComErrosFalhaComAListaDeErros() {
    assertThatThrownBy(() -> CarregadorParametros.carregar("parametros-invalidos.yml"))
        .isInstanceOfSatisfying(
            ParametrosInvalidosException.class,
            e -> assertThat(e.erros()).hasSizeGreaterThanOrEqualTo(2));
  }

  private static java.util.List<String> erros(UnaryOperator<ParametrosIncerteza> alteracao) {
    return CarregadorParametros.validar(alteracao.apply(VALIDOS));
  }

  private static ParametrosIncerteza comFraude(ParametrosIncerteza p, String codigo, double cf) {
    Map<String, EvidenciaCf> evidencias =
        new LinkedHashMap<>(p.fatoresCerteza().fraude().evidencias());
    evidencias.put(codigo, new EvidenciaCf(cf, "alterada"));
    Fraude f = p.fatoresCerteza().fraude();
    return new ParametrosIncerteza(
        p.versao(),
        p.demonstrativo(),
        new FatoresCerteza(new Fraude(evidencias, f.diferencaEstadosMinima(), f.limiares())),
        p.bayes(),
        p.fuzzy());
  }

  private static ParametrosIncerteza comLr(ParametrosIncerteza p, String codigo, double lr) {
    DefeitoFabrico d = p.bayes().defeitoFabrico();
    Map<String, EvidenciaLr> evidencias = new LinkedHashMap<>(d.evidencias());
    evidencias.put(codigo, new EvidenciaLr(lr, "alterada", null));
    return new ParametrosIncerteza(
        p.versao(),
        p.demonstrativo(),
        p.fatoresCerteza(),
        new Bayes(new DefeitoFabrico(d.prior(), evidencias, d.diasCompraRecente(), d.limiares())),
        p.fuzzy());
  }

  private static ParametrosIncerteza comPrior(ParametrosIncerteza p, double prior) {
    DefeitoFabrico d = p.bayes().defeitoFabrico();
    return new ParametrosIncerteza(
        p.versao(),
        p.demonstrativo(),
        p.fatoresCerteza(),
        new Bayes(
            new DefeitoFabrico(
                prior,
                d.evidencias(),
                d.diasCompraRecente(),
                new LimiaresDefeito(d.limiares().rever(), d.limiares().proporPc006()))),
        p.fuzzy());
  }
}
