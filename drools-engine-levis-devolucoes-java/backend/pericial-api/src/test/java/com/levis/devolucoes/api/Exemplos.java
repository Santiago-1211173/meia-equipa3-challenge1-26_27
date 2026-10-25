package com.levis.devolucoes.api;

import com.levis.devolucoes.api.seguranca.EmissorTokens;
import com.levis.devolucoes.dto.comum.ColaboradorDto;
import com.levis.devolucoes.dto.decisao.DecisaoResponse;
import com.levis.devolucoes.dto.enums.Elegibilidade;
import com.levis.devolucoes.dto.enums.Funcao;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/** Tokens e respostas de exemplo para os testes da API. */
public final class Exemplos {

  public static final String PEDIDO_MINIMO =
      """
      {"id": "P-1", "artigos": [{"id": "A-1", "produto": {"sku": "501-ORIG-32"}}]}
      """;

  private Exemplos() {}

  public static ColaboradorDto colaborador(Funcao funcao, boolean aprovadoPeloDM) {
    return new ColaboradorDto("C-" + funcao.name(), "Teste", funcao, aprovadoPeloDM, "POS-1");
  }

  /** Cabeçalho Authorization com um token de um colaborador da função indicada. */
  public static String bearer(EmissorTokens emissor, Funcao funcao) {
    return bearer(emissor, colaborador(funcao, false));
  }

  public static String bearer(EmissorTokens emissor, ColaboradorDto colaborador) {
    return "Bearer " + emissor.emitir(colaborador).token();
  }

  public static DecisaoResponse decisao(UUID id) {
    return new DecisaoResponse(
        id,
        "P-1",
        LocalDateTime.of(2026, 3, 31, 10, 0),
        "com.levis.devolucoes:pericial-rules:0.1.0-SNAPSHOT",
        Elegibilidade.PERMITIR,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        false,
        false,
        null,
        List.of(),
        List.of(),
        List.of(),
        List.of());
  }
}
