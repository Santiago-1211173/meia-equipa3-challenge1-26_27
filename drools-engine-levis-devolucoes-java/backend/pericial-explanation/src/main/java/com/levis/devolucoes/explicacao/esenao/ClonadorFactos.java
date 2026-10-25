package com.levis.devolucoes.explicacao.esenao;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JavaType;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.levis.devolucoes.model.decisao.IndicadorFraude;
import com.levis.devolucoes.model.pedido.PedidoDevolucao;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Cópia profunda do pedido (via JSON) com alterações por caminho, por exemplo {@code
 * portalOnlineDisponivel}, {@code compraOriginal.pagamento.meio} ou {@code artigos[0].revendivel}.
 */
public class ClonadorFactos {

  private static final Pattern SEGMENTO = Pattern.compile("([A-Za-z][\\w-]*)(?:\\[(\\d+)])?");

  /** Campos do modelo que são mapas: as alterações podem acrescentar chaves (ex.: ED-02). */
  private static final Set<String> MAPAS = Set.of("inspecaoDefeito");

  private final ObjectMapper json =
      new ObjectMapper()
          .registerModule(new JavaTimeModule())
          .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
          // os getters calculados (diasDesdeCompra, compraOnline, ...) não são propriedades de
          // entrada
          .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);

  public PedidoDevolucao clonar(PedidoDevolucao pedido) {
    return alterar(pedido, Map.of());
  }

  /** JSON de um facto (pedido ou lista de indícios), para gravar a avaliação. */
  public String paraJson(Object facto) {
    try {
      return json.writeValueAsString(facto);
    } catch (JsonProcessingException e) {
      throw new IllegalStateException("Não foi possível converter para JSON", e);
    }
  }

  /** Pedido a partir do JSON gravado. */
  public PedidoDevolucao pedidoDeJson(String texto) {
    return deJson(texto, json.getTypeFactory().constructType(PedidoDevolucao.class));
  }

  /** Indícios de fraude a partir do JSON gravado. */
  public List<IndicadorFraude> fraudesDeJson(String texto) {
    return deJson(
        texto, json.getTypeFactory().constructCollectionType(List.class, IndicadorFraude.class));
  }

  private <T> T deJson(String texto, JavaType tipo) {
    try {
      return json.readValue(texto, tipo);
    } catch (JsonProcessingException e) {
      throw new IllegalArgumentException("JSON de factos inválido", e);
    }
  }

  /** Cópia do pedido com as alterações aplicadas; o pedido original não muda. */
  public PedidoDevolucao alterar(PedidoDevolucao pedido, Map<String, Object> alteracoes) {
    ObjectNode raiz = json.valueToTree(pedido);
    alteracoes.forEach((caminho, valor) -> definir(raiz, caminho, valor));
    try {
      return json.treeToValue(raiz, PedidoDevolucao.class);
    } catch (JsonProcessingException e) {
      throw new IllegalArgumentException("Alterações inválidas: " + alteracoes, e);
    }
  }

  private void definir(ObjectNode raiz, String caminho, Object valor) {
    String[] partes = caminho.split("\\.");
    JsonNode atual = raiz;
    String anterior = null;
    for (int i = 0; i < partes.length; i++) {
      Matcher m = SEGMENTO.matcher(partes[i]);
      if (!m.matches()) {
        throw new IllegalArgumentException("Caminho inválido: " + caminho);
      }
      String nome = m.group(1);
      boolean ultimo = i == partes.length - 1;
      if (!(atual instanceof ObjectNode objeto)) {
        throw new IllegalArgumentException("Caminho inválido: " + caminho + " (" + nome + ")");
      }
      if (m.group(2) == null) {
        if (ultimo) {
          if (!objeto.has(nome) && (anterior == null || !MAPAS.contains(anterior))) {
            throw new IllegalArgumentException("Campo inexistente: " + caminho);
          }
          objeto.set(nome, json.valueToTree(valor));
          return;
        }
        atual = objeto.get(nome);
        anterior = nome;
      } else {
        JsonNode lista = objeto.get(nome);
        int indice = Integer.parseInt(m.group(2));
        if (!(lista instanceof ArrayNode array) || indice >= array.size()) {
          throw new IllegalArgumentException("Índice inválido: " + caminho);
        }
        if (ultimo) {
          array.set(indice, json.valueToTree(valor));
          return;
        }
        atual = array.get(indice);
        anterior = nome;
      }
      if (atual == null || atual.isNull()) {
        throw new IllegalArgumentException("Caminho inexistente: " + caminho);
      }
    }
  }
}
