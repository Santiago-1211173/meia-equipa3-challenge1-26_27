package com.levis.devolucoes.api.controller;

import com.levis.devolucoes.dto.incerteza.ParametrosIncertezaResponse;
import com.levis.devolucoes.service.incerteza.ParametrosIncertezaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Camada de incerteza (docs/08): consulta dos parâmetros em vigor. */
@RestController
@RequestMapping("/api/v1/incerteza")
@Tag(name = "Incerteza")
public class IncertezaController {

  private final ParametrosIncertezaService parametros;

  public IncertezaController(ParametrosIncertezaService parametros) {
    this.parametros = parametros;
  }

  @GetMapping("/parametros")
  @Operation(
      operationId = "parametrosIncerteza",
      summary = "Parâmetros da camada de incerteza",
      description =
          "Versão, indicação de valores demonstrativos e valores em vigor (só leitura). Enquanto"
              + " demonstrativo for verdadeiro, os resultados não servem para decisões reais.")
  public ParametrosIncertezaResponse parametros() {
    return parametros.parametros();
  }
}
