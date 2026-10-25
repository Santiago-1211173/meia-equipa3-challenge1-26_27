package com.levis.devolucoes.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.levis.devolucoes.dto.comum.PaginaDto;
import com.levis.devolucoes.dto.decisao.AvaliacaoResumoResponse;
import com.levis.devolucoes.dto.decisao.DecisaoResponse;
import com.levis.devolucoes.dto.explicacao.CausaNaoDisparo;
import com.levis.devolucoes.dto.explicacao.DadosEmFaltaResponse;
import com.levis.devolucoes.dto.explicacao.ExplicacaoComoResponse;
import com.levis.devolucoes.dto.explicacao.ExplicacaoConclusaoResponse;
import com.levis.devolucoes.dto.explicacao.ExplicacaoPorqueNaoConclusaoResponse;
import com.levis.devolucoes.dto.explicacao.ExplicacaoPorqueResponse;
import com.levis.devolucoes.dto.pedido.PedidoAvaliacaoRequest;
import com.levis.devolucoes.dto.simulacao.SimulacaoRequest;
import com.levis.devolucoes.dto.simulacao.SimulacaoResponse;
import com.levis.devolucoes.persistencia.repositorio.AvaliacaoRepository;
import com.levis.devolucoes.persistencia.repositorio.RegistoRegraRepository;
import com.levis.devolucoes.service.CenariosDto.CenarioDto;
import com.levis.devolucoes.service.avaliacao.AvaliacaoService;
import com.levis.devolucoes.service.excecao.PedidoInvalidoException;
import com.levis.devolucoes.service.excecao.RecursoNaoEncontradoException;
import com.levis.devolucoes.service.excecao.VersaoBaseConhecimentoDiferenteException;
import com.levis.devolucoes.service.explicacao.ExplicacaoService;
import com.levis.devolucoes.service.regra.CatalogoRegrasService;
import com.levis.devolucoes.service.simulacao.SimulacaoService;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.stream.IntStream;
import java.util.stream.Stream;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Serviço completo sobre PostgreSQL real: os 10 cenários de docs/06 pelos DTO (mesmo resultado que
 * o teste de aceitação das regras), auditoria, explicações sobre avaliações gravadas, simulação, "O
 * que falta?" e "Porquê?". Ignorado sem Docker.
 */
@SpringBootTest(classes = AplicacaoServicoTeste.class)
@Testcontainers(disabledWithoutDocker = true)
class ServicoPericialIT {

  @Container @ServiceConnection
  static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

  private static final Locale PT = Locale.forLanguageTag("pt-PT");

  @Autowired private AvaliacaoService avaliacoes;
  @Autowired private ExplicacaoService explicacoes;
  @Autowired private SimulacaoService simulacoes;
  @Autowired private CatalogoRegrasService catalogo;
  @Autowired private AvaliacaoRepository repositorio;
  @Autowired private RegistoRegraRepository registos;
  @Autowired private TransactionTemplate transacao;

  static Stream<CenarioDto> cenarios() {
    return IntStream.rangeClosed(1, 10).mapToObj(CenariosDto::ler);
  }

  private DecisaoResponse avaliar(int numero) {
    CenarioDto cenario = CenariosDto.ler(numero);
    return avaliacoes.avaliar(cenario.pedido(), cenario.colaborador());
  }

  @ParameterizedTest(name = "cenário {0}")
  @MethodSource("cenarios")
  void osCenariosPeloServicoDaoOResultadoEsperado(CenarioDto cenario) {
    DecisaoResponse decisao = avaliacoes.avaliar(cenario.pedido(), cenario.colaborador());
    VerificadorCenario.verificar(cenario.esperado(), decisao);

    assertThat(decisao.avaliacaoId()).isNotNull();
    assertThat(decisao.versaoBaseConhecimento()).startsWith("com.levis.devolucoes:pericial-rules:");
  }

  @Nested
  class Auditoria {

    @Test
    void gravaAVersaoORastoEAsRegrasAValidar() {
      DecisaoResponse decisao = avaliar(10);

      assertThat(avaliacoes.consultar(decisao.avaliacaoId())).isEqualTo(decisao);
      assertThat(registos.findByAvaliacaoIdOrderByOrdem(decisao.avaliacaoId()))
          .hasSize(decisao.regras().size());
      assertThat(decisao.regrasAValidar()).contains("CH-004", "TN-008");
      transacao.executeWithoutResult(
          t ->
              assertThat(repositorio.findById(decisao.avaliacaoId()).orElseThrow().getPedidoJson())
                  .containsPattern("\"portalOnlineDisponivel\":\\s*false"));
    }

    @Test
    void historicoPorLoja() {
      avaliar(7);

      PaginaDto<AvaliacaoResumoResponse> pagina = avaliacoes.listar("CA-ML-070", 0, 10);

      assertThat(pagina.conteudo()).isNotEmpty().allMatch(a -> a.lojaCodigo().equals("CA-ML-070"));
    }

    @Test
    void avaliacaoInexistente() {
      assertThatThrownBy(() -> avaliacoes.consultar(UUID.randomUUID()))
          .isInstanceOf(RecursoNaoEncontradoException.class);
    }
  }

  @Nested
  class Validacao {

    @Test
    void pedidoSemDadosObrigatoriosNaoEAvaliado() {
      CenarioDto cenario = CenariosDto.ler(1);
      PedidoAvaliacaoRequest semLoja =
          new PedidoAvaliacaoRequest(
              cenario.pedido().id(),
              cenario.pedido().dataPedido(),
              null,
              null,
              cenario.pedido().cliente(),
              cenario.pedido().compraOriginal(),
              cenario.pedido().comprovativo(),
              cenario.pedido().artigos(),
              cenario.pedido().artigosTroca(),
              null,
              null,
              null,
              null);

      assertThatThrownBy(() -> avaliacoes.avaliar(semLoja, cenario.colaborador()))
          .isInstanceOf(PedidoInvalidoException.class)
          .satisfies(
              e ->
                  assertThat(((PedidoInvalidoException) e).erros())
                      .anyMatch(m -> m.startsWith("IN-001"))
                      .anyMatch(m -> m.startsWith("IN-005")));
    }

    @Test
    void oQueFaltaEOPorqueDeCadaPergunta() {
      CenarioDto cenario = CenariosDto.ler(1);

      DadosEmFaltaResponse emFalta =
          avaliacoes.dadosEmFalta(cenario.pedido(), cenario.colaborador(), PT);

      assertThat(emFalta.completo()).isTrue();
      assertThat(emFalta.dados())
          .singleElement()
          .satisfies(
              d -> {
                assertThat(d.codigo()).isEqualTo("IN-010");
                assertThat(d.porque().regrasEmEspera()).isNotEmpty();
                assertThat(d.porque().resumo()).contains("PC-002");
              });

      ExplicacaoPorqueResponse porque =
          avaliacoes.porque(cenario.pedido(), cenario.colaborador(), "IN-010", Locale.ENGLISH);
      assertThat(porque.resumo()).startsWith("I ask");
    }

    @Test
    void depoisDeUmaParagemNaoFaltaNadaEOPedidoEAvaliado() {
      // Cenário 5 (grossista, CH-008) sem tipo de pedido nem loja: dados obrigatórios em falta
      CenarioDto cenario = CenariosDto.ler(5);
      PedidoAvaliacaoRequest incompleto =
          new PedidoAvaliacaoRequest(
              cenario.pedido().id(),
              cenario.pedido().dataPedido(),
              null,
              null,
              cenario.pedido().cliente(),
              cenario.pedido().compraOriginal(),
              cenario.pedido().comprovativo(),
              cenario.pedido().artigos(),
              cenario.pedido().artigosTroca(),
              null,
              null,
              cenario.pedido().pedidoExcecao(),
              null);

      DadosEmFaltaResponse emFalta = avaliacoes.dadosEmFalta(incompleto, cenario.colaborador(), PT);
      assertThat(emFalta.terminal()).isTrue();
      assertThat(emFalta.paragem()).isEqualTo("CH-008");
      assertThat(emFalta.completo()).isTrue();
      assertThat(emFalta.dados()).isEmpty();

      DecisaoResponse decisao = avaliacoes.avaliar(incompleto, cenario.colaborador());
      assertThat(decisao.terminal()).isTrue();
    }
  }

  @Nested
  class Explicacoes {

    @Test
    void comoECaminhoDeUmaConclusao() {
      DecisaoResponse decisao = avaliar(7);

      ExplicacaoComoResponse como = explicacoes.como(decisao.avaliacaoId(), PT);
      ExplicacaoConclusaoResponse conclusao =
          explicacoes.comoConclusao(decisao.avaliacaoId(), "OUT-001", null, PT);

      assertThat(como.passos()).hasSize(decisao.regras().size());
      assertThat(conclusao.regra()).isEqualTo("TN-011");
      assertThat(conclusao.valores()).containsEntry("elegibilidade", "REVER");
    }

    @Test
    void porqueNaoDeUmaConclusaoEDeUmaRegra() {
      DecisaoResponse decisao = avaliar(8);

      ExplicacaoPorqueNaoConclusaoResponse conclusao =
          explicacoes.porqueNaoConclusao(decisao.avaliacaoId(), "OUT-002:AJUSTE_PRECO", null, PT);

      assertThat(conclusao.obtida()).isFalse();
      assertThat(conclusao.regras())
          .singleElement()
          .satisfies(
              r -> {
                assertThat(r.codigoRegra()).isEqualTo("PT-007");
                assertThat(r.causa()).isEqualTo(CausaNaoDisparo.CONDICOES_FALHADAS);
              });
      assertThat(explicacoes.porqueNaoRegra(decisao.avaliacaoId(), "PT-008", null, PT).causa())
          .isEqualTo(CausaNaoDisparo.DISPAROU);
    }

    @Test
    void artigoInexistente() {
      DecisaoResponse decisao = avaliar(9);

      assertThatThrownBy(
              () -> explicacoes.comoConclusao(decisao.avaliacaoId(), "OUT-007", "A-99", PT))
          .isInstanceOf(RecursoNaoEncontradoException.class);
    }

    @Test
    void versaoDiferenteDaBaseDeConhecimentoNaoEExplicada() {
      DecisaoResponse decisao = avaliar(3);
      transacao.executeWithoutResult(
          t ->
              repositorio
                  .findById(decisao.avaliacaoId())
                  .orElseThrow()
                  .setVersaoBaseConhecimento("com.levis.devolucoes:pericial-rules:0.0.1"));

      assertThatThrownBy(() -> explicacoes.como(decisao.avaliacaoId(), PT))
          .isInstanceOf(VersaoBaseConhecimentoDiferenteException.class);
    }
  }

  @Nested
  class Simulacao {

    @Test
    void eSeOPortalEstivesseDisponivel() {
      DecisaoResponse decisao = avaliar(10);

      SimulacaoResponse simulacao =
          simulacoes.simular(
              decisao.avaliacaoId(),
              new SimulacaoRequest(Map.of("portalOnlineDisponivel", true)),
              PT);

      assertThat(simulacao.regrasNovas()).contains("CH-002");
      assertThat(simulacao.regrasRemovidas()).contains("CH-004");
      assertThat(simulacao.decisaoSimulada().avaliacaoId()).isNull();
      assertThat(avaliacoes.consultar(decisao.avaliacaoId())).isEqualTo(decisao);
    }
  }

  @Test
  void catalogoDaBaseDeConhecimento() {
    assertThat(catalogo.listar())
        .as("76 regras da base de conhecimento e 19 da camada de incerteza")
        .hasSize(95);
    assertThat(catalogo.detalhe("PC-002").variantes()).hasSize(3);
    assertThatThrownBy(() -> catalogo.detalhe("XX-1"))
        .isInstanceOf(RecursoNaoEncontradoException.class);
  }
}
