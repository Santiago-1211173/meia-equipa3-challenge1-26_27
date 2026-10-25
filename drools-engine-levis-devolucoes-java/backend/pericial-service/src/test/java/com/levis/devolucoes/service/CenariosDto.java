package com.levis.devolucoes.service;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.levis.devolucoes.dto.comum.ColaboradorDto;
import com.levis.devolucoes.dto.pedido.PedidoAvaliacaoRequest;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;

/**
 * Os cenários de docs/06 (JSON do test-jar do pericial-rules) como pedidos da API: o colaborador
 * passa a ser o utilizador autenticado e os indícios de fraude entram no pedido.
 */
public final class CenariosDto {

  private static final ObjectMapper JSON =
      new ObjectMapper()
          .registerModule(new JavaTimeModule())
          .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);

  private CenariosDto() {}

  /** Cenário em JSON (pedido, colaborador e esperado). */
  public record CenarioDto(
      int numero, PedidoAvaliacaoRequest pedido, ColaboradorDto colaborador, JsonNode esperado) {}

  public static CenarioDto ler(int numero) {
    String recurso = String.format("/cenarios/cenario-%02d.json", numero);
    try (InputStream entrada = CenariosDto.class.getResourceAsStream(recurso)) {
      JsonNode raiz = JSON.readTree(entrada);
      ObjectNode pedido = (ObjectNode) raiz.get("pedido").deepCopy();
      pedido.set("indicadoresFraude", raiz.get("indicadoresFraude"));
      ColaboradorDto colaborador =
          JSON.treeToValue(pedido.get("colaborador"), ColaboradorDto.class);
      pedido.remove("colaborador");
      respostasDoModeloParaODto(pedido);
      return new CenarioDto(
          numero,
          JSON.treeToValue(pedido, PedidoAvaliacaoRequest.class),
          colaborador,
          raiz.get("esperado"));
    } catch (IOException e) {
      throw new UncheckedIOException(recurso, e);
    }
  }

  /**
   * Os cenários usam o modelo (TRUE, FALSE ou null "Não sei"); a API recebe as respostas do
   * colaborador como SIM, NAO ou NAO_SEI (docs/08 §7.1).
   */
  private static void respostasDoModeloParaODto(ObjectNode pedido) {
    if (pedido.get("cliente") instanceof ObjectNode cliente && cliente.has("explicaOrigemCompra")) {
      cliente.put("explicaOrigemCompra", resposta(cliente.get("explicaOrigemCompra")));
    }
    if (pedido.get("artigos") != null) {
      for (JsonNode artigo : pedido.get("artigos")) {
        JsonNode estado = artigo.get("estado");
        if (estado != null && estado.get("inspecaoDefeito") instanceof ObjectNode inspecao) {
          inspecao.properties().forEach(e -> inspecao.put(e.getKey(), resposta(e.getValue())));
        }
      }
    }
  }

  private static String resposta(JsonNode valor) {
    if (valor == null || valor.isNull()) {
      return "NAO_SEI";
    }
    return valor.asBoolean() ? "SIM" : "NAO";
  }
}
