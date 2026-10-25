package com.levis.devolucoes.api.controller;

import static com.levis.devolucoes.api.Exemplos.bearer;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.levis.devolucoes.api.TesteController;
import com.levis.devolucoes.api.seguranca.EmissorTokens;
import com.levis.devolucoes.dto.enums.Funcao;
import com.levis.devolucoes.dto.incerteza.ParametrosIncertezaResponse;
import com.levis.devolucoes.service.incerteza.ParametrosIncertezaService;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@TesteController(IncertezaController.class)
class IncertezaControllerTest {

  @Autowired private MockMvc mvc;
  @Autowired private EmissorTokens emissor;
  @MockitoBean private ParametrosIncertezaService parametros;

  @Test
  void devolveOsParametrosComOAvisoDeValoresDemonstrativos() throws Exception {
    when(parametros.parametros())
        .thenReturn(
            new ParametrosIncertezaResponse(
                "0.1.0-demo",
                true,
                Map.of("EF-01", 0.3),
                Map.of("ED-01", 4.0),
                0.3,
                Map.of("fraude.alto", 0.7),
                Map.of("revendibilidade", "fcl/revendibilidade.fcl")));

    mvc.perform(
            get("/api/v1/incerteza/parametros")
                .header(HttpHeaders.AUTHORIZATION, bearer(emissor, Funcao.STYLIST)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.demonstrativo").value(true))
        .andExpect(jsonPath("$.fatoresCerteza['EF-01']").value(0.3));
  }

  @Test
  void exigeAutenticacao() throws Exception {
    mvc.perform(get("/api/v1/incerteza/parametros")).andExpect(status().isUnauthorized());
  }
}
