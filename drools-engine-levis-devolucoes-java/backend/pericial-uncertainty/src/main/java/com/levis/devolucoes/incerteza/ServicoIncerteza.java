package com.levis.devolucoes.incerteza;

import com.levis.devolucoes.incerteza.bayes.ModeloBayesiano;
import com.levis.devolucoes.incerteza.bayes.ModeloRazoesVerosimilhanca;
import com.levis.devolucoes.incerteza.certeza.CombinadorFatoresCerteza;
import com.levis.devolucoes.incerteza.fuzzy.MotorFuzzy;
import com.levis.devolucoes.incerteza.fuzzy.MotorFuzzyFcl;
import com.levis.devolucoes.incerteza.fuzzy.RegraAtivada;
import com.levis.devolucoes.incerteza.fuzzy.ResultadoFuzzy;
import com.levis.devolucoes.incerteza.parametros.CarregadorParametros;
import com.levis.devolucoes.incerteza.parametros.ParametrosIncerteza;
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
import com.levis.devolucoes.model.pedido.PedidoDevolucao;
import com.levis.devolucoes.model.produto.ArtigoDevolvido;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Fachada da camada de incerteza (docs/08), usada pelas regras (global {@code incerteza}) e pelo
 * serviço. Os cálculos e as classificações ficam aqui, testáveis sem Drools; as regras decidem
 * quando calcular e que efeito aplicar. Todos os números vêm do ficheiro de parâmetros.
 *
 * <p>Nos graus fuzzy, as contribuições são primeiro as pertenças das entradas (código {@code
 * variavel.termo}, peso = pertença, valor antes = valor da entrada) e depois as regras ativadas
 * (código RV/CR, peso = força).
 */
public class ServicoIncerteza {

  private static final Locale PT = Locale.forLanguageTag("pt-PT");

  private final ParametrosIncerteza parametros;
  private final MotorFuzzy motorFuzzy;
  private final ModeloBayesiano modeloBayesiano;
  private final CombinadorFatoresCerteza combinador = new CombinadorFatoresCerteza();

  public ServicoIncerteza(
      ParametrosIncerteza parametros, MotorFuzzy motorFuzzy, ModeloBayesiano modeloBayesiano) {
    this.parametros = parametros;
    this.motorFuzzy = motorFuzzy;
    this.modeloBayesiano = modeloBayesiano;
  }

  /** Serviço com o ficheiro de parâmetros da aplicação. */
  public static ServicoIncerteza padrao() {
    return comParametros(CarregadorParametros.RECURSO_PADRAO);
  }

  /** Serviço com o ficheiro de parâmetros indicado (ex.: o de teste). */
  public static ServicoIncerteza comParametros(String recurso) {
    return new ServicoIncerteza(
        CarregadorParametros.carregar(recurso),
        new MotorFuzzyFcl(),
        new ModeloRazoesVerosimilhanca());
  }

  public ParametrosIncerteza parametros() {
    return parametros;
  }

  public String versao() {
    return parametros.versao();
  }

  public boolean isDemonstrativo() {
    return parametros.demonstrativo();
  }

  // Parâmetros usados pelas regras que derivam evidências

  /** EF-03: diferença mínima de grau de uso entre artigos. */
  public int diferencaEstadosMinima() {
    return parametros.fatoresCerteza().fraude().diferencaEstadosMinima();
  }

  /** ED-03: dias desde a compra até aos quais a compra é recente. */
  public int diasCompraRecente() {
    return parametros.bayes().defeitoFabrico().diasCompraRecente();
  }

  /** Prazo a partir do qual se contam os dias da recomendação de crédito (PT-003). */
  public int prazoCreditoDias() {
    return parametros.fuzzy().creditoPt004().prazoDias();
  }

  /** Integridade das etiquetas, em [0, 1], para a revendibilidade. */
  public double integridadeEtiquetas(EstadoEtiquetas etiquetas) {
    return parametros.fuzzy().revendibilidade().integridadeEtiquetas().get(etiquetas);
  }

  // Evidências

  /** Evidência de fraude EF-xx, com o CF e a descrição dos parâmetros. */
  public Evidencia evidenciaFraude(
      String codigo, String pedidoId, Boolean presente, FonteEvidencia fonte) {
    var definicao = parametros.fatoresCerteza().fraude().evidencias().get(codigo);
    if (definicao == null) {
      throw new IllegalArgumentException("Evidência de fraude desconhecida: " + codigo);
    }
    Evidencia e = new Evidencia(codigo, Hipotese.FRAUDE, pedidoId, null, presente, fonte);
    e.setPeso(definicao.cf());
    e.setDescricao(definicao.descricao());
    return e;
  }

  /** Evidência de defeito de fabrico ED-xx, com o LR, o grupo e a descrição dos parâmetros. */
  public Evidencia evidenciaDefeito(
      String codigo, String pedidoId, String artigoId, Boolean presente, FonteEvidencia fonte) {
    var definicao = parametros.bayes().defeitoFabrico().evidencias().get(codigo);
    if (definicao == null) {
      throw new IllegalArgumentException("Evidência de defeito desconhecida: " + codigo);
    }
    Evidencia e =
        new Evidencia(codigo, Hipotese.DEFEITO_FABRICO, pedidoId, artigoId, presente, fonte);
    e.setPeso(definicao.lr());
    e.setGrupo(definicao.grupo());
    e.setDescricao(definicao.descricao());
    return e;
  }

  // Graus de crença

  /** Risco de fraude por fatores de certeza (docs/08 §2). */
  public GrauCrenca riscoFraude(String pedidoId, Collection<Evidencia> evidencias) {
    ResultadoCalculo r = combinador.calcular(evidencias);
    var limiares = parametros.fatoresCerteza().fraude().limiares();
    ClassificacaoIncerteza classe =
        r.valor() >= limiares.alto()
            ? ClassificacaoIncerteza.RISCO_ALTO
            : r.valor() >= limiares.medio()
                ? ClassificacaoIncerteza.RISCO_MEDIO
                : ClassificacaoIncerteza.RISCO_BAIXO;
    return grau(
        pedidoId,
        null,
        Hipotese.FRAUDE,
        MetodoIncerteza.FATOR_CERTEZA,
        r.valor(),
        classe,
        r.contribuicoes());
  }

  /** Probabilidade de defeito de fabrico de um artigo (docs/08 §3). */
  public GrauCrenca probabilidadeDefeito(
      String pedidoId, String artigoId, Collection<Evidencia> evidencias) {
    var defeito = parametros.bayes().defeitoFabrico();
    ResultadoCalculo r = modeloBayesiano.calcular(defeito.prior(), evidencias);
    ClassificacaoIncerteza classe =
        r.valor() >= defeito.limiares().proporPc006()
            ? ClassificacaoIncerteza.PROPOR_PC006
            : r.valor() >= defeito.limiares().rever()
                ? ClassificacaoIncerteza.REVER_DEFEITO
                : ClassificacaoIncerteza.DESGASTE;
    return grau(
        pedidoId,
        artigoId,
        Hipotese.DEFEITO_FABRICO,
        MetodoIncerteza.BAYES,
        r.valor(),
        classe,
        r.contribuicoes());
  }

  /** Revendibilidade de um artigo por lógica fuzzy (docs/08 §4.1). */
  public GrauCrenca revendibilidade(
      String pedidoId, String artigoId, int grauUso, EstadoEtiquetas etiquetas) {
    var revendibilidade = parametros.fuzzy().revendibilidade();
    Map<String, Double> entradas = new LinkedHashMap<>();
    entradas.put("grauUso", (double) grauUso);
    entradas.put("etiquetas", integridadeEtiquetas(etiquetas));
    ResultadoFuzzy r = motorFuzzy.avaliar(revendibilidade.fcl(), entradas);
    var limiares = revendibilidade.limiares();
    ClassificacaoIncerteza classe =
        r.valor() >= limiares.revendivel()
            ? ClassificacaoIncerteza.REVENDIVEL
            : r.valor() >= limiares.indeterminada()
                ? ClassificacaoIncerteza.REVENDIBILIDADE_INDETERMINADA
                : ClassificacaoIncerteza.NAO_REVENDIVEL;
    return grau(
        pedidoId,
        artigoId,
        Hipotese.REVENDIBILIDADE,
        MetodoIncerteza.FUZZY,
        r.valor(),
        classe,
        contribuicoesFuzzy(entradas, r));
  }

  /**
   * Recomendação de crédito de loja depois de PT-004 (docs/08 §4.2). É apenas uma recomendação para
   * a gestão: não altera a decisão.
   *
   * @param revendibilidade grau de revendibilidade; o valor por omissão se for nulo
   * @param risco CF de fraude (os negativos contam como zero); o valor por omissão se for nulo
   */
  public GrauCrenca recomendacaoCredito(
      String pedidoId,
      long diasDesdeCompra,
      Double revendibilidade,
      Double risco,
      BigDecimal valor) {
    var credito = parametros.fuzzy().creditoPt004();
    Map<String, Double> entradas = new LinkedHashMap<>();
    entradas.put(
        "diasAposPrazo",
        limitar(diasDesdeCompra - (double) credito.prazoDias(), credito.limites().diasAposPrazo()));
    entradas.put(
        "revendibilidade",
        revendibilidade != null ? revendibilidade : credito.porOmissao().revendibilidade());
    entradas.put("risco", risco != null ? Math.max(0, risco) : credito.porOmissao().risco());
    entradas.put(
        "valor", limitar(valor == null ? 0 : valor.doubleValue(), credito.limites().valor()));
    ResultadoFuzzy r = motorFuzzy.avaliar(credito.fcl(), entradas);
    ClassificacaoIncerteza classe =
        r.valor() >= credito.limiares().recomendado()
            ? ClassificacaoIncerteza.CREDITO_RECOMENDADO
            : r.valor() >= credito.limiares().aCriterio()
                ? ClassificacaoIncerteza.CREDITO_A_CRITERIO
                : ClassificacaoIncerteza.CREDITO_NAO_RECOMENDADO;
    return grau(
        pedidoId,
        null,
        Hipotese.RECOMENDACAO_CREDITO,
        MetodoIncerteza.FUZZY,
        r.valor(),
        classe,
        contribuicoesFuzzy(entradas, r));
  }

  /**
   * Recomendação de crédito de um pedido em REVER por PT-004 (IU-40): os dias desde a compra, a
   * menor revendibilidade calculada entre os artigos (a mais cautelosa), o risco de fraude e a soma
   * dos preços pagos.
   */
  public GrauCrenca recomendacaoCreditoPedido(
      PedidoDevolucao pedido, Collection<GrauCrenca> graus) {
    Double revendibilidade =
        graus.stream()
            .filter(g -> g.getHipotese() == Hipotese.REVENDIBILIDADE)
            .map(GrauCrenca::getValor)
            .min(Double::compare)
            .orElse(null);
    Double risco =
        graus.stream()
            .filter(g -> g.getHipotese() == Hipotese.FRAUDE)
            .map(GrauCrenca::getValor)
            .findFirst()
            .orElse(null);
    BigDecimal valor =
        pedido.getArtigos() == null
            ? BigDecimal.ZERO
            : pedido.getArtigos().stream()
                .map(ArtigoDevolvido::getPrecoPago)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    long dias = pedido.getDiasDesdeCompra() == null ? 0 : pedido.getDiasDesdeCompra();
    return recomendacaoCredito(pedido.getId(), dias, revendibilidade, risco, valor);
  }

  /**
   * Resumo legível de um grau, para o rasto das regras (ex.: "risco de fraude 0,84: RISCO_ALTO").
   */
  public String resumo(GrauCrenca grau) {
    String nome =
        switch (grau.getHipotese()) {
          case FRAUDE -> "risco de fraude (fator de certeza)";
          case DEFEITO_FABRICO -> "probabilidade de defeito de fabrico";
          case REVENDIBILIDADE -> "grau de revendibilidade";
          case RECOMENDACAO_CREDITO -> "recomendação de crédito de loja";
        };
    String formato =
        grau.getHipotese() == Hipotese.RECOMENDACAO_CREDITO ? "%s %.0f: %s" : "%s %.2f: %s";
    return String.format(PT, formato, nome, grau.getValor(), grau.getClassificacao())
        + (grau.isDemonstrativo() ? " (valores demonstrativos)" : "");
  }

  /**
   * Indício de fraude SIGNIFICATIVO a partir de um risco alto (IU-11); a descrição lista as
   * contribuições, para a gestão e para a comunicação de risco (EX-008).
   */
  public IndicadorFraude indicadorFraude(GrauCrenca risco) {
    String passos =
        risco.getContribuicoes().stream()
            .filter(Contribuicao::isAplicada)
            .map(c -> c.getCodigo() + " " + String.format(PT, "%+.2f", c.getPeso()))
            .collect(Collectors.joining(", "));
    String descricao =
        String.format(PT, "Risco de fraude %.2f por fatores de certeza", risco.getValor())
            + (risco.isDemonstrativo() ? " (valores demonstrativos)" : "")
            + ": "
            + passos;
    return new IndicadorFraude(risco.getPedidoId(), descricao, NivelRisco.SIGNIFICATIVO);
  }

  private GrauCrenca grau(
      String pedidoId,
      String artigoId,
      Hipotese hipotese,
      MetodoIncerteza metodo,
      double valor,
      ClassificacaoIncerteza classe,
      List<Contribuicao> contribuicoes) {
    GrauCrenca g = new GrauCrenca();
    g.setPedidoId(pedidoId);
    g.setArtigoId(artigoId);
    g.setHipotese(hipotese);
    g.setMetodo(metodo);
    g.setValor(valor);
    g.setClassificacao(classe);
    g.setContribuicoes(new ArrayList<>(contribuicoes));
    g.setVersaoParametros(parametros.versao());
    g.setDemonstrativo(parametros.demonstrativo());
    return g;
  }

  private static List<Contribuicao> contribuicoesFuzzy(
      Map<String, Double> entradas, ResultadoFuzzy r) {
    List<Contribuicao> contribuicoes = new ArrayList<>();
    entradas.forEach(
        (variavel, valor) ->
            r.pertencas()
                .getOrDefault(variavel, Map.of())
                .forEach(
                    (termo, pertenca) ->
                        contribuicoes.add(
                            Contribuicao.aplicada(
                                variavel + "." + termo,
                                variavel + " é " + termo,
                                pertenca,
                                valor,
                                pertenca))));
    for (RegraAtivada regra : r.regras()) {
      contribuicoes.add(
          Contribuicao.aplicada(
              regra.id(), regra.consequente(), regra.forca(), r.valor(), r.valor()));
    }
    return contribuicoes;
  }

  private static double limitar(double valor, double maximo) {
    return Math.max(0, Math.min(valor, maximo));
  }
}
