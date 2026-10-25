package com.levis.devolucoes.explicacao.incerteza;

import com.levis.devolucoes.explicacao.motor.ResultadoExecucao;
import com.levis.devolucoes.explicacao.texto.GeradorTexto;
import com.levis.devolucoes.incerteza.ServicoIncerteza;
import com.levis.devolucoes.incerteza.parametros.ParametrosIncerteza;
import com.levis.devolucoes.model.enums.ClassificacaoIncerteza;
import com.levis.devolucoes.model.enums.Hipotese;
import com.levis.devolucoes.model.enums.MetodoIncerteza;
import com.levis.devolucoes.model.incerteza.Contribuicao;
import com.levis.devolucoes.model.incerteza.GrauCrenca;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

/**
 * Explicações dos graus de crença (docs/08 §7.2): "Como?" com os passos do cálculo e "Porque não?"
 * com a distância aos limiares. Um fator de certeza nunca é apresentado como probabilidade, e o
 * aviso dos valores demonstrativos acompanha sempre o texto enquanto os parâmetros o forem.
 */
public class ExplicadorIncerteza {

  /** Regra que calcula cada hipótese. */
  private static final Map<Hipotese, String> REGRA =
      Map.of(
          Hipotese.FRAUDE, "IU-10",
          Hipotese.DEFEITO_FABRICO, "IU-20",
          Hipotese.REVENDIBILIDADE, "IU-30",
          Hipotese.RECOMENDACAO_CREDITO, "IU-40");

  private final ServicoIncerteza incerteza;
  private final GeradorTexto texto;

  public ExplicadorIncerteza(ServicoIncerteza incerteza, GeradorTexto texto) {
    this.incerteza = incerteza;
    this.texto = texto;
  }

  /**
   * "Como?" do grau da hipótese, no artigo indicado (obrigatório para defeito e revendibilidade).
   */
  public ExplicacaoGrau como(ResultadoExecucao resultado, Hipotese hipotese, String artigoId) {
    Optional<GrauCrenca> encontrado = grau(resultado, hipotese, artigoId);
    String nome = nome(hipotese);
    if (encontrado.isEmpty()) {
      return new ExplicacaoGrau(
          hipotese,
          artigoId,
          false,
          null,
          null,
          null,
          null,
          List.of(),
          List.of(),
          incerteza.versao(),
          incerteza.isDemonstrativo(),
          texto.formatar("incerteza.como.nao_calculado", nome, sufixoArtigo(artigoId)));
    }
    GrauCrenca g = encontrado.get();
    List<String> passos = passos(g);
    String chave =
        switch (g.getMetodo()) {
          case FATOR_CERTEZA -> "incerteza.como.cf";
          case BAYES -> "incerteza.como.bayes";
          case FUZZY -> "incerteza.como.fuzzy";
        };
    String resumo =
        texto.formatar(chave, nome, g.getValor(), g.getClassificacao(), String.join("; ", passos))
            + aviso(g.isDemonstrativo());
    return new ExplicacaoGrau(
        hipotese,
        artigoId,
        true,
        REGRA.get(hipotese),
        g.getMetodo(),
        g.getValor(),
        g.getClassificacao(),
        List.copyOf(g.getContribuicoes()),
        passos,
        g.getVersaoParametros(),
        g.isDemonstrativo(),
        resumo);
  }

  /** "Porque não?" da classe perguntada para o grau da hipótese. */
  public ExplicacaoPorqueNaoGrau porqueNao(
      ResultadoExecucao resultado,
      Hipotese hipotese,
      ClassificacaoIncerteza perguntada,
      String artigoId) {
    Intervalo intervalo = intervalo(hipotese, perguntada);
    Optional<GrauCrenca> encontrado = grau(resultado, hipotese, artigoId);
    if (encontrado.isEmpty()) {
      return new ExplicacaoPorqueNaoGrau(
          hipotese,
          artigoId,
          perguntada,
          null,
          null,
          false,
          List.of(),
          texto.formatar("incerteza.porquenao.nao_calculado", perguntada, nome(hipotese))
              + aviso(incerteza.isDemonstrativo()));
    }
    GrauCrenca g = encontrado.get();
    double valor = g.getValor();
    if (g.getClassificacao() == perguntada) {
      return new ExplicacaoPorqueNaoGrau(
          hipotese,
          artigoId,
          perguntada,
          g.getClassificacao(),
          valor,
          true,
          List.of(),
          texto.formatar("incerteza.porquenao.obtida", perguntada, nome(hipotese), valor)
              + aviso(g.isDemonstrativo()));
    }
    boolean subir = intervalo.minimo() != null && valor < intervalo.minimo();
    String motivo =
        subir
            ? texto.formatar("incerteza.porquenao.abaixo", perguntada, valor, intervalo.minimo())
            : texto.formatar("incerteza.porquenao.acima", perguntada, valor, intervalo.maximo());
    List<String> mudariam = mudariam(g, subir);
    String complemento = "";
    if (g.getMetodo() == MetodoIncerteza.FUZZY) {
      complemento = texto.formatar("incerteza.porquenao.regras", String.join(", ", mudariam));
    } else if (!mudariam.isEmpty()) {
      complemento = texto.formatar("incerteza.porquenao.mudariam", String.join(", ", mudariam));
    }
    return new ExplicacaoPorqueNaoGrau(
        hipotese,
        artigoId,
        perguntada,
        g.getClassificacao(),
        valor,
        false,
        mudariam,
        motivo + complemento + aviso(g.isDemonstrativo()));
  }

  // -------------------------------------------------------------------------------------------

  private static Optional<GrauCrenca> grau(
      ResultadoExecucao resultado, Hipotese hipotese, String artigoId) {
    return resultado.decisao().getGrausCrenca().stream()
        .filter(g -> g.getHipotese() == hipotese && Objects.equals(g.getArtigoId(), artigoId))
        .findFirst();
  }

  private List<String> passos(GrauCrenca g) {
    List<String> passos = new ArrayList<>();
    if (g.getMetodo() == MetodoIncerteza.BAYES && !g.getContribuicoes().isEmpty()) {
      passos.add(
          texto.formatar("incerteza.passo.prior", g.getContribuicoes().getFirst().getValorAntes()));
    }
    for (Contribuicao c : g.getContribuicoes()) {
      if (!c.isAplicada()) {
        passos.add(texto.formatar("incerteza.passo.nao_aplicada", c.getCodigo(), motivo(c)));
        continue;
      }
      String chave =
          switch (g.getMetodo()) {
            case FATOR_CERTEZA -> "incerteza.passo.cf";
            case BAYES -> "incerteza.passo.lr";
            case FUZZY ->
                c.getCodigo().contains(".") ? "incerteza.passo.pertenca" : "incerteza.passo.regra";
          };
      passos.add(
          texto.formatar(chave, c.getCodigo(), c.getPeso(), c.getValorDepois(), c.getDescricao()));
    }
    return passos;
  }

  /**
   * Evidências não aplicadas que levariam o grau na direção da classe, ou as regras fuzzy ativas.
   */
  private List<String> mudariam(GrauCrenca g, boolean subir) {
    List<String> lista = new ArrayList<>();
    for (Contribuicao c : g.getContribuicoes()) {
      if (g.getMetodo() == MetodoIncerteza.FUZZY) {
        if (!c.getCodigo().contains(".")) {
          lista.add(texto.formatar("incerteza.passo.forca", c.getCodigo(), c.getPeso()));
        }
        continue;
      }
      double neutro = g.getMetodo() == MetodoIncerteza.BAYES ? 1 : 0;
      boolean nessaDirecao = subir ? c.getPeso() > neutro : c.getPeso() < neutro;
      if (!c.isAplicada() && nessaDirecao) {
        lista.add(c.getCodigo() + " (" + c.getDescricao() + ")");
      }
    }
    return lista;
  }

  private String motivo(Contribuicao c) {
    String motivo = c.getMotivoNaoAplicada() == null ? "" : c.getMotivoNaoAplicada();
    if (motivo.startsWith("grupo ")) {
      return texto.formatar("incerteza.motivo.grupo", motivo.substring("grupo ".length()));
    }
    return switch (motivo) {
      case "desconhecida" -> texto.formatar("incerteza.motivo.desconhecida");
      case "ausente" -> texto.formatar("incerteza.motivo.ausente");
      default -> motivo;
    };
  }

  private String nome(Hipotese hipotese) {
    return texto.formatar("incerteza.hipotese." + hipotese.name());
  }

  private String sufixoArtigo(String artigoId) {
    return artigoId == null ? "" : texto.formatar("incerteza.artigo", artigoId);
  }

  private String aviso(boolean demonstrativo) {
    return demonstrativo ? " " + texto.formatar("incerteza.demonstrativo") : "";
  }

  /** Intervalo [mínimo, máximo[ do valor para a classe; os extremos abertos ficam nulos. */
  private record Intervalo(Double minimo, Double maximo) {}

  private Intervalo intervalo(Hipotese hipotese, ClassificacaoIncerteza classe) {
    ParametrosIncerteza p = incerteza.parametros();
    var fraude = p.fatoresCerteza().fraude().limiares();
    var defeito = p.bayes().defeitoFabrico().limiares();
    var revenda = p.fuzzy().revendibilidade().limiares();
    var credito = p.fuzzy().creditoPt004().limiares();
    Intervalo intervalo =
        switch (classe) {
          case RISCO_ALTO -> new Intervalo(fraude.alto(), null);
          case RISCO_MEDIO -> new Intervalo(fraude.medio(), fraude.alto());
          case RISCO_BAIXO -> new Intervalo(null, fraude.medio());
          case PROPOR_PC006 -> new Intervalo(defeito.proporPc006(), null);
          case REVER_DEFEITO -> new Intervalo(defeito.rever(), defeito.proporPc006());
          case DESGASTE -> new Intervalo(null, defeito.rever());
          case REVENDIVEL -> new Intervalo(revenda.revendivel(), null);
          case REVENDIBILIDADE_INDETERMINADA ->
              new Intervalo(revenda.indeterminada(), revenda.revendivel());
          case NAO_REVENDIVEL -> new Intervalo(null, revenda.indeterminada());
          case CREDITO_RECOMENDADO -> new Intervalo(credito.recomendado(), null);
          case CREDITO_A_CRITERIO -> new Intervalo(credito.aCriterio(), credito.recomendado());
          case CREDITO_NAO_RECOMENDADO -> new Intervalo(null, credito.aCriterio());
        };
    if (hipoteseDe(classe) != hipotese) {
      throw new IllegalArgumentException(
          "A classificação " + classe + " não pertence à hipótese " + hipotese);
    }
    return intervalo;
  }

  /** Hipótese a que pertence uma classificação. */
  public static Hipotese hipoteseDe(ClassificacaoIncerteza classe) {
    return switch (classe) {
      case RISCO_ALTO, RISCO_MEDIO, RISCO_BAIXO -> Hipotese.FRAUDE;
      case PROPOR_PC006, REVER_DEFEITO, DESGASTE -> Hipotese.DEFEITO_FABRICO;
      case REVENDIVEL, REVENDIBILIDADE_INDETERMINADA, NAO_REVENDIVEL -> Hipotese.REVENDIBILIDADE;
      case CREDITO_RECOMENDADO, CREDITO_A_CRITERIO, CREDITO_NAO_RECOMENDADO ->
          Hipotese.RECOMENDACAO_CREDITO;
    };
  }
}
