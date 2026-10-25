package com.levis.devolucoes.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.levis.devolucoes.api.seguranca.EmissorTokens;
import com.levis.devolucoes.dto.decisao.DecisaoResponse;
import com.levis.devolucoes.dto.enums.ClassificacaoIncerteza;
import com.levis.devolucoes.dto.enums.Funcao;
import com.levis.devolucoes.dto.enums.Hipotese;
import com.levis.devolucoes.dto.incerteza.GrauCrencaDto;
import com.levis.devolucoes.service.CenariosDto;
import com.levis.devolucoes.service.CenariosDto.CenarioDto;
import com.levis.devolucoes.service.VerificadorCenario;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;
import java.util.stream.IntStream;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * A aplicação completa por HTTP, sobre PostgreSQL real: os 10 cenários de docs/06 com o colaborador
 * no token (mesmo resultado que o teste de aceitação das regras), explicações, "E se", "O que
 * falta?" e o documento OpenAPI (exportado para target/openapi.json, de onde o frontend gera o
 * cliente). Ignorado sem Docker.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
class CenariosApiIT {

  @Container @ServiceConnection
  static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

  @Autowired private TestRestTemplate http;
  @Autowired private EmissorTokens emissor;
  @Autowired private ObjectMapper json;

  static Stream<CenarioDto> cenarios() {
    return IntStream.rangeClosed(1, 10).mapToObj(CenariosDto::ler);
  }

  private ResponseEntity<String> pedir(
      HttpMethod metodo, String caminho, Object corpo, String autorizacao) {
    HttpHeaders cabecalhos = new HttpHeaders();
    cabecalhos.setContentType(MediaType.APPLICATION_JSON);
    cabecalhos.set(HttpHeaders.ACCEPT_LANGUAGE, "pt-PT");
    if (autorizacao != null) {
      cabecalhos.set(HttpHeaders.AUTHORIZATION, autorizacao);
    }
    return http.exchange(caminho, metodo, new HttpEntity<>(corpo, cabecalhos), String.class);
  }

  private DecisaoResponse avaliar(CenarioDto cenario) throws IOException {
    ResponseEntity<String> resposta =
        pedir(
            HttpMethod.POST,
            "/api/v1/avaliacoes",
            cenario.pedido(),
            Exemplos.bearer(emissor, cenario.colaborador()));
    assertThat(resposta.getStatusCode()).as(resposta.getBody()).isEqualTo(HttpStatus.CREATED);
    return json.readValue(resposta.getBody(), DecisaoResponse.class);
  }

  private JsonNode obter(String caminho) throws IOException {
    ResponseEntity<String> resposta =
        pedir(HttpMethod.GET, caminho, null, Exemplos.bearer(emissor, Funcao.STYLIST));
    assertThat(resposta.getStatusCode()).as(resposta.getBody()).isEqualTo(HttpStatus.OK);
    return json.readTree(resposta.getBody());
  }

  @ParameterizedTest(name = "cenário {0}")
  @MethodSource("cenarios")
  void osCenariosPorHttpDaoOResultadoEsperado(CenarioDto cenario) throws IOException {
    DecisaoResponse decisao = avaliar(cenario);

    VerificadorCenario.verificar(cenario.esperado(), decisao);
    DecisaoResponse consultada =
        json.treeToValue(
            obter("/api/v1/avaliacoes/" + decisao.avaliacaoId()), DecisaoResponse.class);
    assertThat(consultada)
        .usingRecursiveComparison()
        .withComparatorForType(BigDecimal::compareTo, BigDecimal.class)
        .isEqualTo(decisao);
  }

  @Test
  void incertezaDoCenario6ComExplicacoesEParametros() throws IOException {
    DecisaoResponse decisao = avaliar(CenariosDto.ler(6));
    String base = "/api/v1/avaliacoes/" + decisao.avaliacaoId() + "/explicacoes";

    GrauCrencaDto risco =
        decisao.incerteza().stream()
            .filter(g -> g.hipotese() == Hipotese.FRAUDE)
            .findFirst()
            .orElseThrow();
    assertThat(risco.valor()).isCloseTo(0.8354, within(0.00005));
    assertThat(risco.classificacao()).isEqualTo(ClassificacaoIncerteza.RISCO_ALTO);
    assertThat(risco.demonstrativo()).isTrue();
    assertThat(risco.contribuicoes()).hasSize(5);

    JsonNode como = obter(base + "/como?conclusao=INCERTEZA.FRAUDE");
    assertThat(como.get("regra").asText()).isEqualTo("IU-10");
    assertThat(como.get("resumo").asText()).contains("0,84").contains("Valores demonstrativos");
    JsonNode porqueNao = obter(base + "/porque-nao?conclusao=INCERTEZA.FRAUDE:RISCO_MEDIO");
    assertThat(porqueNao.get("obtida").asBoolean()).isFalse();
    assertThat(porqueNao.get("valorObtido").asText()).isEqualTo("RISCO_ALTO");

    ResponseEntity<String> semArtigo =
        pedir(
            HttpMethod.GET,
            base + "/como?conclusao=INCERTEZA.REVENDIBILIDADE",
            null,
            Exemplos.bearer(emissor, Funcao.STYLIST));
    assertThat(semArtigo.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

    JsonNode parametros = obter("/api/v1/incerteza/parametros");
    assertThat(parametros.get("demonstrativo").asBoolean()).isTrue();
    assertThat(parametros.get("fatoresCerteza").get("EF-01").asDouble()).isEqualTo(0.30);
  }

  @Test
  void explicacoesESimulacaoDeUmaAvaliacaoGravada() throws IOException {
    UUID id = avaliar(CenariosDto.ler(5)).avaliacaoId();
    String base = "/api/v1/avaliacoes/" + id + "/explicacoes";

    assertThat(obter(base + "/como").get("passos")).isNotEmpty();
    assertThat(obter(base + "/como?conclusao=OUT-001").get("regra").asText()).isEqualTo("CH-008");
    assertThat(obter(base + "/porque-nao?regra=HS-002").get("causa").asText())
        .isEqualTo("MODULO_NAO_ALCANCADO");
    assertThat(obter(base + "/porque-nao?conclusao=OUT-001:PERMITIR").get("obtida").asBoolean())
        .isFalse();

    ResponseEntity<String> simulacao =
        pedir(
            HttpMethod.POST,
            "/api/v1/avaliacoes/" + id + "/simulacoes",
            json.readTree("{\"alteracoes\": {\"portalOnlineDisponivel\": true}}"),
            Exemplos.bearer(emissor, Funcao.STYLIST));
    assertThat(simulacao.getStatusCode()).as(simulacao.getBody()).isEqualTo(HttpStatus.OK);
  }

  @Test
  void oQueFaltaEPorqueParaUmPedidoAindaVazio() throws IOException {
    String token = Exemplos.bearer(emissor, Funcao.KEY_HOLDER);

    ResponseEntity<String> emFalta =
        pedir(HttpMethod.POST, "/api/v1/avaliacoes/dados-em-falta", json.readTree("{}"), token);
    assertThat(emFalta.getStatusCode()).as(emFalta.getBody()).isEqualTo(HttpStatus.OK);
    JsonNode dados = json.readTree(emFalta.getBody());
    assertThat(dados.get("completo").asBoolean()).isFalse();
    assertThat(dados.get("terminal").asBoolean()).isFalse();
    assertThat(dados.get("dados")).isNotEmpty();

    // Um Stylist não está autorizado: HS-006 termina a inferência e não falta nada (ADR 0004)
    ResponseEntity<String> naoAutorizado =
        pedir(
            HttpMethod.POST,
            "/api/v1/avaliacoes/dados-em-falta",
            json.readTree("{}"),
            Exemplos.bearer(emissor, Funcao.STYLIST));
    JsonNode paragem = json.readTree(naoAutorizado.getBody());
    assertThat(paragem.get("terminal").asBoolean()).isTrue();
    assertThat(paragem.get("paragem").asText()).isEqualTo("HS-006");
    assertThat(paragem.get("dados")).isEmpty();

    // Como o assistente envia: artigo ainda sem SKU e artigo de troca por completar
    String emCurso =
        """
        {"artigos": [{"id": "A-1", "produto": {"sku": null}}],
         "artigosTroca": [{"produto": {"sku": "501-ORIG-34"}}]}
        """;
    ResponseEntity<String> parcial =
        pedir(HttpMethod.POST, "/api/v1/avaliacoes/dados-em-falta", json.readTree(emCurso), token);
    assertThat(parcial.getStatusCode()).as(parcial.getBody()).isEqualTo(HttpStatus.OK);

    ResponseEntity<String> porque =
        pedir(HttpMethod.POST, "/api/v1/avaliacoes/porque?dado=IN-010", json.readTree("{}"), token);
    assertThat(porque.getStatusCode()).as(porque.getBody()).isEqualTo(HttpStatus.OK);
  }

  @Test
  void naoAvaliaSemOsDadosObrigatorios() throws IOException {
    ResponseEntity<String> resposta =
        pedir(
            HttpMethod.POST,
            "/api/v1/avaliacoes",
            json.readTree(Exemplos.PEDIDO_MINIMO),
            Exemplos.bearer(emissor, Funcao.KEY_HOLDER));

    assertThat(resposta.getStatusCode()).isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
    assertThat(json.readTree(resposta.getBody()).get("erros")).isNotEmpty();
  }

  @Test
  void saudeSemAutenticacao() {
    assertThat(pedir(HttpMethod.GET, "/actuator/health", null, null).getStatusCode())
        .isEqualTo(HttpStatus.OK);
  }

  @Test
  void exportaODocumentoOpenApi() throws IOException {
    ResponseEntity<String> resposta = pedir(HttpMethod.GET, "/v3/api-docs", null, null);
    assertThat(resposta.getStatusCode()).isEqualTo(HttpStatus.OK);
    JsonNode documento = json.readTree(resposta.getBody());

    assertThat(documento.get("paths").fieldNames())
        .toIterable()
        .contains(
            "/api/v1/avaliacoes",
            "/api/v1/avaliacoes/{id}",
            "/api/v1/avaliacoes/dados-em-falta",
            "/api/v1/avaliacoes/porque",
            "/api/v1/avaliacoes/{id}/explicacoes/como",
            "/api/v1/avaliacoes/{id}/explicacoes/porque-nao",
            "/api/v1/avaliacoes/{id}/simulacoes",
            "/api/v1/regras",
            "/api/v1/regras/{codigo}")
        .doesNotContain("/api/v1/dev/tokens");
    JsonNode respostasAvaliar = documento.at("/paths/~1api~1v1~1avaliacoes/post/responses");
    assertThat(respostasAvaliar.has("201")).isTrue();
    assertThat(respostasAvaliar.at("/422/content").toString()).contains("ProblemDetail");
    assertThat(documento.at("/components/securitySchemes/bearer-jwt/scheme").asText())
        .isEqualTo("bearer");

    Path destino = Path.of("target", "openapi.json");
    Files.writeString(destino, json.writerWithDefaultPrettyPrinter().writeValueAsString(documento));
  }
}
