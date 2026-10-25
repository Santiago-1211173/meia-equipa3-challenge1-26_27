package com.levis.devolucoes.service.explicacao;

import com.levis.devolucoes.dto.explicacao.CondicaoDto;
import com.levis.devolucoes.dto.explicacao.ExplicacaoComoResponse;
import com.levis.devolucoes.dto.explicacao.ExplicacaoConclusaoResponse;
import com.levis.devolucoes.dto.explicacao.ExplicacaoPorqueNaoConclusaoResponse;
import com.levis.devolucoes.dto.explicacao.ExplicacaoPorqueNaoResponse;
import com.levis.devolucoes.explicacao.catalogo.CampoSaida;
import com.levis.devolucoes.explicacao.incerteza.ExplicacaoGrau;
import com.levis.devolucoes.explicacao.incerteza.ExplicacaoPorqueNaoGrau;
import com.levis.devolucoes.explicacao.motor.ResultadoExecucao;
import com.levis.devolucoes.model.enums.ClassificacaoIncerteza;
import com.levis.devolucoes.model.enums.Hipotese;
import com.levis.devolucoes.service.excecao.RecursoNaoEncontradoException;
import com.levis.devolucoes.service.mapeamento.ExplicacaoMapper;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;

/**
 * Explicações de uma avaliação gravada (ADR 0006): Como (caminho completo ou até uma conclusão) e
 * Porque não (de uma conclusão ou de uma regra).
 */
@Service
public class ExplicacaoService {

  /** Conclusões da camada de incerteza: INCERTEZA.FRAUDE, INCERTEZA.DEFEITO_FABRICO, ... */
  private static final String PREFIXO_INCERTEZA = "INCERTEZA.";

  private final ReavaliacaoService reavaliacao;
  private final Explicadores explicadores;
  private final ExplicacaoMapper mapper;

  public ExplicacaoService(
      ReavaliacaoService reavaliacao, Explicadores explicadores, ExplicacaoMapper mapper) {
    this.reavaliacao = reavaliacao;
    this.explicadores = explicadores;
    this.mapper = mapper;
  }

  public ExplicacaoComoResponse como(UUID avaliacaoId, Locale locale) {
    return mapper.como(explicadores.como(locale).explicar(resultado(avaliacaoId)));
  }

  /**
   * @param conclusao campo de saída (ex.: OUT-001)
   * @param artigoId artigo (obrigatório para OUT-007)
   */
  public ExplicacaoConclusaoResponse comoConclusao(
      UUID avaliacaoId, String conclusao, String artigoId, Locale locale) {
    ResultadoExecucao resultado = resultado(avaliacaoId);
    validarArtigo(resultado, artigoId);
    if (eIncerteza(conclusao)) {
      Hipotese hipotese = hipotese(conclusao);
      validarArtigoDaHipotese(hipotese, artigoId);
      return comoGrau(
          conclusao.trim(), explicadores.incerteza(locale).como(resultado, hipotese, artigoId));
    }
    return mapper.conclusao(
        explicadores.como(locale).explicarConclusao(CampoSaida.de(conclusao), artigoId, resultado));
  }

  /**
   * @param conclusao campo e valor (ex.: "OUT-001:PERMITIR" ou "OUT-001=PERMITIR")
   */
  public ExplicacaoPorqueNaoConclusaoResponse porqueNaoConclusao(
      UUID avaliacaoId, String conclusao, String artigoId, Locale locale) {
    String[] partes = conclusao.split("[:=]", 2);
    if (partes.length != 2 || partes[1].isBlank()) {
      throw new IllegalArgumentException(
          "Conclusão inválida: indique campo e valor, ex.: OUT-001:PERMITIR");
    }
    ResultadoExecucao resultado = resultado(avaliacaoId);
    validarArtigo(resultado, artigoId);
    if (eIncerteza(partes[0])) {
      Hipotese hipotese = hipotese(partes[0]);
      validarArtigoDaHipotese(hipotese, artigoId);
      ClassificacaoIncerteza classe = classe(partes[1]);
      return porqueNaoGrau(
          partes[0].trim(),
          explicadores.incerteza(locale).porqueNao(resultado, hipotese, classe, artigoId));
    }
    return mapper.porqueNaoConclusao(
        explicadores
            .porqueNao(locale)
            .explicarConclusao(
                CampoSaida.de(partes[0].trim()), partes[1].trim(), artigoId, resultado));
  }

  public ExplicacaoPorqueNaoResponse porqueNaoRegra(
      UUID avaliacaoId, String regra, String artigoId, Locale locale) {
    ResultadoExecucao resultado = resultado(avaliacaoId);
    validarArtigo(resultado, artigoId);
    return mapper.porqueNao(explicadores.porqueNao(locale).explicar(regra, artigoId, resultado));
  }

  // -------------------------------------------------------------------------------------------
  // Graus da camada de incerteza (docs/08 §7.2): conclusao=INCERTEZA.<HIPOTESE>
  // -------------------------------------------------------------------------------------------

  private static boolean eIncerteza(String conclusao) {
    return conclusao != null && conclusao.trim().toUpperCase().startsWith(PREFIXO_INCERTEZA);
  }

  private static Hipotese hipotese(String conclusao) {
    String nome = conclusao.trim().substring(PREFIXO_INCERTEZA.length()).toUpperCase();
    try {
      return Hipotese.valueOf(nome);
    } catch (IllegalArgumentException e) {
      throw new IllegalArgumentException(
          "Hipótese desconhecida: "
              + nome
              + " (FRAUDE, DEFEITO_FABRICO, REVENDIBILIDADE ou"
              + " RECOMENDACAO_CREDITO)");
    }
  }

  private static ClassificacaoIncerteza classe(String nome) {
    try {
      return ClassificacaoIncerteza.valueOf(nome.trim().toUpperCase());
    } catch (IllegalArgumentException e) {
      throw new IllegalArgumentException("Classificação desconhecida: " + nome);
    }
  }

  /** O defeito de fabrico e a revendibilidade são calculados por artigo. */
  private static void validarArtigoDaHipotese(Hipotese hipotese, String artigoId) {
    boolean porArtigo =
        hipotese == Hipotese.DEFEITO_FABRICO || hipotese == Hipotese.REVENDIBILIDADE;
    if (porArtigo && artigoId == null) {
      throw new IllegalArgumentException("Indique o artigo para " + hipotese);
    }
    if (!porArtigo && artigoId != null) {
      throw new IllegalArgumentException(hipotese + " é calculado para o pedido, sem artigo");
    }
  }

  private static ExplicacaoConclusaoResponse comoGrau(String conclusao, ExplicacaoGrau grau) {
    Map<String, String> valores = new LinkedHashMap<>();
    if (grau.calculado()) {
      valores.put("valor", String.valueOf(grau.valor()));
      valores.put("classificacao", grau.classificacao().name());
      valores.put("metodo", grau.metodo().name());
    }
    valores.put("versaoParametros", grau.versaoParametros());
    valores.put("demonstrativo", String.valueOf(grau.demonstrativo()));
    List<CondicaoDto> contribuicoes =
        grau.contribuicoes().stream()
            .map(
                c ->
                    new CondicaoDto(
                        c.getCodigo(),
                        c.getDescricao(),
                        c.isAplicada(),
                        c.isAplicada()
                            ? c.getValorAntes() + " → " + c.getValorDepois()
                            : c.getMotivoNaoAplicada(),
                        grau.artigoId()))
            .toList();
    return new ExplicacaoConclusaoResponse(
        conclusao.toUpperCase(),
        grau.artigoId(),
        valores,
        grau.regra(),
        null,
        contribuicoes,
        grau.passos(),
        grau.resumo());
  }

  private static ExplicacaoPorqueNaoConclusaoResponse porqueNaoGrau(
      String conclusao, ExplicacaoPorqueNaoGrau x) {
    return new ExplicacaoPorqueNaoConclusaoResponse(
        conclusao.toUpperCase(),
        x.perguntada().name(),
        x.artigoId(),
        x.obtida() == null ? null : x.obtida().name(),
        x.conseguida(),
        x.mudariam(),
        null,
        List.of(),
        x.resumo());
  }

  private ResultadoExecucao resultado(UUID avaliacaoId) {
    return reavaliacao.reavaliar(avaliacaoId).resultado();
  }

  private static void validarArtigo(ResultadoExecucao resultado, String artigoId) {
    if (artigoId != null && !resultado.artigos().containsKey(artigoId)) {
      throw new RecursoNaoEncontradoException("Artigo inexistente nesta avaliação: " + artigoId);
    }
  }
}
