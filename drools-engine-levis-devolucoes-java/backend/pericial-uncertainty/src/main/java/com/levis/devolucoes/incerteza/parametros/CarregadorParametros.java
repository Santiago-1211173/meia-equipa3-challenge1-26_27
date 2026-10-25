package com.levis.devolucoes.incerteza.parametros;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.levis.devolucoes.model.enums.EstadoEtiquetas;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * Lê e valida o ficheiro de parâmetros de incerteza. Falha se algum CF estiver fora de [−1, 1], se
 * algum LR não for positivo, se o prior não estiver em ]0, 1[, se os limiares não forem crescentes
 * ou se faltar um ficheiro FCL (docs/08 §5.2).
 */
public final class CarregadorParametros {

  /** Ficheiro de parâmetros usado pela aplicação. */
  public static final String RECURSO_PADRAO = "parametros/parametros-incerteza.yml";

  private static final ObjectMapper YAML =
      new ObjectMapper(new YAMLFactory())
          .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, true)
          .configure(DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES, true);

  private CarregadorParametros() {}

  /** Lê o ficheiro de parâmetros do classpath e valida-o. */
  public static ParametrosIncerteza carregar(String recurso) {
    ParametrosIncerteza parametros;
    try (InputStream entrada = abrir(recurso)) {
      if (entrada == null) {
        throw new ParametrosInvalidosException(recurso, List.of("ficheiro inexistente"));
      }
      parametros = YAML.readValue(entrada, ParametrosIncerteza.class);
    } catch (IOException e) {
      throw new ParametrosInvalidosException(recurso, List.of(e.getMessage()));
    }
    List<String> erros = validar(parametros);
    if (!erros.isEmpty()) {
      throw new ParametrosInvalidosException(recurso, erros);
    }
    return parametros;
  }

  /** Erros de validação dos parâmetros; vazio se forem válidos. */
  static List<String> validar(ParametrosIncerteza p) {
    List<String> erros = new ArrayList<>();
    if (p.versao() == null || p.versao().isBlank()) {
      erros.add("versao em falta");
    }
    if (incompleto(p)) {
      erros.add(
          "faltam secções obrigatórias (fatoresCerteza, bayes, fuzzy, evidências ou limiares)");
      return erros;
    }
    validarFraude(p.fatoresCerteza().fraude(), erros);
    validarDefeito(p.bayes().defeitoFabrico(), erros);
    validarRevendibilidade(p.fuzzy().revendibilidade(), erros);
    validarCredito(p.fuzzy().creditoPt004(), erros);
    return erros;
  }

  private static boolean incompleto(ParametrosIncerteza p) {
    if (p.fatoresCerteza() == null || p.bayes() == null || p.fuzzy() == null) {
      return true;
    }
    var fraude = p.fatoresCerteza().fraude();
    var defeito = p.bayes().defeitoFabrico();
    var revendibilidade = p.fuzzy().revendibilidade();
    var credito = p.fuzzy().creditoPt004();
    return fraude == null
        || fraude.evidencias() == null
        || fraude.limiares() == null
        || defeito == null
        || defeito.evidencias() == null
        || defeito.limiares() == null
        || revendibilidade == null
        || revendibilidade.limiares() == null
        || credito == null
        || credito.limites() == null
        || credito.porOmissao() == null
        || credito.limiares() == null;
  }

  private static void validarFraude(ParametrosIncerteza.Fraude fraude, List<String> erros) {
    fraude
        .evidencias()
        .forEach(
            (codigo, e) -> {
              if (e.cf() < -1 || e.cf() > 1) {
                erros.add("CF de " + codigo + " fora de [-1, 1]: " + e.cf());
              }
            });
    if (fraude.diferencaEstadosMinima() <= 0) {
      erros.add("diferencaEstadosMinima tem de ser positiva");
    }
    crescentes(erros, "limiares da fraude", fraude.limiares().medio(), fraude.limiares().alto());
  }

  private static void validarDefeito(
      ParametrosIncerteza.DefeitoFabrico defeito, List<String> erros) {
    if (defeito.prior() <= 0 || defeito.prior() >= 1) {
      erros.add("prior fora de ]0, 1[: " + defeito.prior());
    }
    defeito
        .evidencias()
        .forEach(
            (codigo, e) -> {
              if (e.lr() <= 0) {
                erros.add("LR de " + codigo + " tem de ser positivo: " + e.lr());
              }
            });
    if (defeito.diasCompraRecente() <= 0) {
      erros.add("diasCompraRecente tem de ser positivo");
    }
    crescentes(
        erros, "limiares do defeito", defeito.limiares().rever(), defeito.limiares().proporPc006());
  }

  private static void validarRevendibilidade(
      ParametrosIncerteza.Revendibilidade revendibilidade, List<String> erros) {
    fcl(erros, revendibilidade.fcl());
    crescentes(
        erros,
        "limiares da revendibilidade",
        revendibilidade.limiares().indeterminada(),
        revendibilidade.limiares().revendivel());
    var integridade = revendibilidade.integridadeEtiquetas();
    if (integridade == null || integridade.size() != EstadoEtiquetas.values().length) {
      erros.add("integridadeEtiquetas tem de ter um valor por estado das etiquetas");
      return;
    }
    integridade.forEach(
        (estado, valor) -> {
          if (valor < 0 || valor > 1) {
            erros.add("integridadeEtiquetas de " + estado + " fora de [0, 1]: " + valor);
          }
        });
  }

  private static void validarCredito(ParametrosIncerteza.CreditoPt004 credito, List<String> erros) {
    fcl(erros, credito.fcl());
    if (credito.prazoDias() <= 0) {
      erros.add("prazoDias tem de ser positivo");
    }
    if (credito.limites().diasAposPrazo() <= 0 || credito.limites().valor() <= 0) {
      erros.add("limites do crédito têm de ser positivos");
    }
    crescentes(
        erros,
        "limiares do crédito",
        credito.limiares().aCriterio(),
        credito.limiares().recomendado());
  }

  private static void crescentes(List<String> erros, String nome, double menor, double maior) {
    if (!(menor < maior)) {
      erros.add(nome + " não são crescentes: " + menor + " e " + maior);
    }
  }

  private static void fcl(List<String> erros, String recurso) {
    if (recurso == null
        || CarregadorParametros.class.getClassLoader().getResource(recurso) == null) {
      erros.add("ficheiro FCL inexistente: " + recurso);
    }
  }

  private static InputStream abrir(String recurso) {
    return CarregadorParametros.class.getClassLoader().getResourceAsStream(recurso);
  }
}
