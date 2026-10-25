package com.levis.devolucoes.persistencia;

import static org.assertj.core.api.Assertions.assertThat;

import com.levis.devolucoes.persistencia.entidade.AvaliacaoEntity;
import com.levis.devolucoes.persistencia.entidade.ExcecaoAprovadaEntity;
import com.levis.devolucoes.persistencia.entidade.RegistoRegraEntity;
import com.levis.devolucoes.persistencia.repositorio.AvaliacaoRepository;
import com.levis.devolucoes.persistencia.repositorio.ExcecaoAprovadaRepository;
import com.levis.devolucoes.persistencia.repositorio.RegistoRegraRepository;
import jakarta.persistence.EntityManager;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.data.domain.PageRequest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.TestPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Persistência em PostgreSQL real (Testcontainers): o Flyway cria o esquema, o Hibernate valida as
 * entidades contra ele e as avaliações são gravadas e lidas com o rasto. Ignorado sem Docker.
 */
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@TestPropertySource(properties = "spring.jpa.hibernate.ddl-auto=validate")
@Testcontainers(disabledWithoutDocker = true)
class PersistenciaAvaliacaoIT {

  @Container @ServiceConnection
  static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

  private static final LocalDateTime AGORA = LocalDateTime.of(2026, 3, 31, 10, 0);

  @Autowired private AvaliacaoRepository avaliacoes;
  @Autowired private RegistoRegraRepository registos;
  @Autowired private ExcecaoAprovadaRepository excecoes;
  @Autowired private EntityManager entityManager;
  @Autowired private JdbcTemplate jdbc;

  private static AvaliacaoEntity avaliacao(String pedidoId, String loja) {
    AvaliacaoEntity avaliacao = new AvaliacaoEntity();
    avaliacao.setId(UUID.randomUUID());
    avaliacao.setPedidoId(pedidoId);
    avaliacao.setCriadaEm(AGORA);
    avaliacao.setLojaCodigo(loja);
    avaliacao.setColaboradorId("C-1");
    avaliacao.setVersaoBaseConhecimento("com.levis.devolucoes:pericial-rules:0.1.0-SNAPSHOT");
    avaliacao.setVersaoParametrosIncerteza("0.1.0-demo");
    avaliacao.setElegibilidade("REVER");
    avaliacao.setTipoTransacao("TROCA");
    avaliacao.setValorDevolucao(new BigDecimal("69.50"));
    avaliacao.setPedidoJson("{\"id\": \"" + pedidoId + "\", \"tipoPedido\": \"TROCA\"}");
    avaliacao.setDecisaoJson("{\"elegibilidade\": \"REVER\"}");
    avaliacao.acrescentarRegisto(
        new RegistoRegraEntity(
            1,
            "PC-002",
            "PC-002 Etiquetas soltas",
            "M3",
            "A-1",
            "REVER",
            "Etiquetas soltas.",
            AGORA));
    avaliacao.acrescentarRegisto(
        new RegistoRegraEntity(
            2,
            "PT-003",
            "PT-003 Devolução verificada até 30 dias",
            "M5",
            null,
            "PERMITIR",
            "Troca.",
            AGORA));
    return avaliacao;
  }

  @Test
  void flywayCriaOEsquema() {
    Integer versoes =
        jdbc.queryForObject(
            "select count(*) from flyway_schema_history where success", Integer.class);
    assertThat(versoes).as("V1 e V2 (versão dos parâmetros de incerteza)").isEqualTo(2);
  }

  @Test
  void gravaELeUmaAvaliacaoComORasto() {
    AvaliacaoEntity gravada = avaliacoes.saveAndFlush(avaliacao("C01", "US-ML-010"));
    entityManager.clear();

    AvaliacaoEntity lida = avaliacoes.findComRegistosById(gravada.getId()).orElseThrow();

    assertThat(lida.getVersaoBaseConhecimento()).endsWith("pericial-rules:0.1.0-SNAPSHOT");
    assertThat(lida.getVersaoParametrosIncerteza()).isEqualTo("0.1.0-demo");
    assertThat(lida.getValorDevolucao()).isEqualByComparingTo("69.50");
    assertThat(lida.getPedidoJson()).contains("\"tipoPedido\"");
    assertThat(lida.getRegistos())
        .extracting(RegistoRegraEntity::getCodigoRegra)
        .containsExactly("PC-002", "PT-003");
    assertThat(registos.findByAvaliacaoIdOrderByOrdem(gravada.getId())).hasSize(2);
  }

  @Test
  void osDocumentosJsonFicamComoJsonb() {
    AvaliacaoEntity gravada = avaliacoes.saveAndFlush(avaliacao("C02", "US-ML-010"));

    String tipo =
        jdbc.queryForObject(
            "select pedido_json ->> 'tipoPedido' from avaliacao where id = ?",
            String.class,
            gravada.getId());
    assertThat(tipo).isEqualTo("TROCA");
  }

  @Test
  void consultasDoHistorico() {
    avaliacoes.saveAndFlush(avaliacao("C03", "US-ML-010"));
    avaliacoes.saveAndFlush(avaliacao("C03", "US-ML-010"));
    avaliacoes.saveAndFlush(avaliacao("C04", "CA-ML-070"));

    assertThat(avaliacoes.findByPedidoIdOrderByCriadaEmDesc("C03")).hasSize(2);
    assertThat(avaliacoes.findByLojaCodigo("CA-ML-070", PageRequest.of(0, 10)).getTotalElements())
        .isEqualTo(1);
    assertThat(registos.contarAvaliacoesPorRegra())
        .filteredOn(c -> c.getCodigo().equals("PC-002"))
        .singleElement()
        .satisfies(c -> assertThat(c.getTotal()).isEqualTo(3));
  }

  @Test
  void registoDeExcecaoAprovada() {
    AvaliacaoEntity avaliacao = avaliacao("C05", "US-ML-010");
    ExcecaoAprovadaEntity excecao = new ExcecaoAprovadaEntity();
    excecao.setId(UUID.randomUUID());
    excecao.setRegistadaEm(AGORA);
    excecao.setMotivo("Cliente de longa data");
    excecao.setAprovador("Ana Gestora (GESTAO_LOJA)");
    excecao.setValor(new BigDecimal("98.00"));
    excecao.setResultado("REEMBOLSO");
    excecao.setRegisto("Motivo: Cliente de longa data; aprovador: Ana Gestora");
    avaliacao.acrescentarExcecao(excecao);
    avaliacoes.saveAndFlush(avaliacao);

    assertThat(
            excecoes.findByRegistadaEmBetweenOrderByRegistadaEm(
                AGORA.minusDays(1), AGORA.plusDays(1)))
        .singleElement()
        .satisfies(e -> assertThat(e.getAprovador()).contains("Ana Gestora"));
  }

  @Test
  void apagarUmaAvaliacaoApagaORasto() {
    AvaliacaoEntity gravada = avaliacoes.saveAndFlush(avaliacao("C06", "US-ML-010"));

    avaliacoes.deleteById(gravada.getId());
    avaliacoes.flush();

    assertThat(registos.findByAvaliacaoIdOrderByOrdem(gravada.getId())).isEmpty();
  }
}
