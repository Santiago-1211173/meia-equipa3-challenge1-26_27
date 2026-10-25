package com.levis.devolucoes.api.controller;

import com.levis.devolucoes.dto.explicacao.ExplicacaoComoResponse;
import com.levis.devolucoes.dto.explicacao.ExplicacaoConclusaoResponse;
import com.levis.devolucoes.dto.explicacao.ExplicacaoPorqueNaoConclusaoResponse;
import com.levis.devolucoes.dto.explicacao.ExplicacaoPorqueNaoResponse;
import com.levis.devolucoes.service.explicacao.ExplicacaoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.Locale;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Explicações de uma avaliação gravada (Como e Porque não; ADR 0006). */
@RestController
@RequestMapping("/api/v1/avaliacoes/{id}/explicacoes")
@Tag(name = "Explicações")
public class ExplicacaoController {

  private final ExplicacaoService explicacoes;

  public ExplicacaoController(ExplicacaoService explicacoes) {
    this.explicacoes = explicacoes;
  }

  @GetMapping("/como")
  @Operation(
      operationId = "como",
      summary = "Como?",
      description =
          "Sem conclusão: o caminho completo percorrido (ExplicacaoComoResponse). Com conclusão"
              + " (ex.: OUT-001): o caminho até essa conclusão (ExplicacaoConclusaoResponse).")
  @ApiResponse(
      responseCode = "200",
      content =
          @Content(
              schema =
                  @Schema(
                      oneOf = {ExplicacaoComoResponse.class, ExplicacaoConclusaoResponse.class})))
  public Object como(
      @PathVariable UUID id,
      @Parameter(
              description =
                  "Campo de saída (ex.: OUT-001) ou grau da camada de incerteza (ex.: INCERTEZA.FRAUDE)")
          @RequestParam(required = false)
          String conclusao,
      @Parameter(description = "Artigo, para as conclusões por artigo")
          @RequestParam(required = false)
          String artigo,
      Locale locale) {
    if (conclusao == null) {
      return explicacoes.como(id, locale);
    }
    return explicacoes.comoConclusao(id, conclusao, artigo, locale);
  }

  @GetMapping("/porque-nao")
  @Operation(
      operationId = "porqueNao",
      summary = "Porque não?",
      description =
          "Indicar exatamente um de: conclusão (ex.: OUT-001:PERMITIR), a razão de não ter sido"
              + " obtida (ExplicacaoPorqueNaoConclusaoResponse); ou regra (ex.: PT-003), a razão"
              + " de não ter disparado (ExplicacaoPorqueNaoResponse).")
  @ApiResponse(
      responseCode = "200",
      content =
          @Content(
              schema =
                  @Schema(
                      oneOf = {
                        ExplicacaoPorqueNaoConclusaoResponse.class,
                        ExplicacaoPorqueNaoResponse.class
                      })))
  public Object porqueNao(
      @PathVariable UUID id,
      @Parameter(
              description =
                  "Conclusão no formato OUT-00n:VALOR ou INCERTEZA.<HIPOTESE>:<CLASSIFICACAO>")
          @RequestParam(required = false)
          String conclusao,
      @Parameter(description = "ID da regra, ex.: PT-003") @RequestParam(required = false)
          String regra,
      @Parameter(description = "Artigo, para as conclusões e regras por artigo")
          @RequestParam(required = false)
          String artigo,
      Locale locale) {
    if ((conclusao == null) == (regra == null)) {
      throw new IllegalArgumentException(
          "Indique exatamente um dos parâmetros: conclusao ou regra.");
    }
    if (conclusao != null) {
      return explicacoes.porqueNaoConclusao(id, conclusao, artigo, locale);
    }
    return explicacoes.porqueNaoRegra(id, regra, artigo, locale);
  }
}
