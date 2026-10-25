package com.levis.devolucoes.explicacao;

import static com.levis.devolucoes.explicacao.SuporteExplicacoes.EXECUTOR;
import static com.levis.devolucoes.explicacao.SuporteExplicacoes.TEXTO;
import static com.levis.devolucoes.explicacao.SuporteExplicacoes.pedidoDoCenario;
import static com.levis.devolucoes.model.teste.PedidoBuilder.umPedido;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.tuple;

import com.levis.devolucoes.explicacao.emfalta.DadoEmFalta;
import com.levis.devolucoes.explicacao.emfalta.DetetorDadosEmFalta;
import com.levis.devolucoes.explicacao.esenao.ClonadorFactos;
import com.levis.devolucoes.explicacao.esenao.DiferencaSaida;
import com.levis.devolucoes.explicacao.esenao.ResultadoSimulacao;
import com.levis.devolucoes.explicacao.esenao.SimuladorCenario;
import com.levis.devolucoes.explicacao.motor.ResultadoExecucao;
import com.levis.devolucoes.explicacao.texto.GeradorTexto;
import com.levis.devolucoes.model.enums.CondicaoUso;
import com.levis.devolucoes.model.enums.Elegibilidade;
import com.levis.devolucoes.model.enums.MeioPagamento;
import com.levis.devolucoes.model.enums.TipoTransacao;
import com.levis.devolucoes.model.pedido.PedidoDevolucao;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/** E se, O que falta, clonagem e textos. */
class SimulacaoEDadosEmFaltaTest {

  private final ClonadorFactos clonador = new ClonadorFactos();
  private final SimuladorCenario simulador = new SimuladorCenario(EXECUTOR, clonador, TEXTO);
  private final DetetorDadosEmFalta detetor = new DetetorDadosEmFalta();

  /** Avalia uma cópia do pedido e devolve-a com o pedido original intacto, para simular depois. */
  private ResultadoExecucao avaliarCopia(PedidoDevolucao pedido) {
    return EXECUTOR.executar(clonador.clonar(pedido), List.of());
  }

  @Nested
  class ESe {

    @Test
    @DisplayName("Cenário 10: e se o portal estivesse disponível? CH-002 em vez de CH-004")
    void portalDisponivel() {
      PedidoDevolucao pedido = pedidoDoCenario(10);
      ResultadoExecucao original = avaliarCopia(pedido);

      ResultadoSimulacao simulacao =
          simulador.simular(original, pedido, Map.of("portalOnlineDisponivel", true));

      assertThat(simulacao.regrasNovas()).contains("CH-002");
      assertThat(simulacao.regrasRemovidas()).contains("CH-004");
      assertThat(simulacao.diferencas()).isNotEmpty();
      assertThat(simulacao.resumo()).contains("campo(s)");
      assertThat(pedido.isPortalOnlineDisponivel()).isFalse();
    }

    @Test
    @DisplayName(
        "E se a inspeção mostrasse um dano localizado? Propor PC-006 em vez de inspeção adicional")
    void respostaDeInspecaoMudaAClasseDoDefeito() {
      PedidoDevolucao pedido =
          umPedido()
              .artigo(
                  a -> {
                    a.getEstado().setCondicaoUso(CondicaoUso.USADO);
                    a.getEstado().setAlegaDefeito(true);
                    a.getEstado().setInspecaoDefeito(new HashMap<>(Map.of("ED-01", true)));
                  })
              .construir();
      ResultadoExecucao original = avaliarCopia(pedido);

      ResultadoSimulacao simulacao =
          simulador.simular(
              original, pedido, Map.of("artigos[0].estado.inspecaoDefeito.ED-02", true));

      assertThat(simulacao.regrasNovas()).contains("IU-21");
      assertThat(simulacao.regrasRemovidas()).contains("IU-22");
      assertThat(pedido.getArtigos().getFirst().getEstado().getInspecaoDefeito())
          .doesNotContainKey("ED-02");
    }

    @Test
    @DisplayName("Cenário 1: e se o artigo estivesse moderadamente usado? Deixa de ser revendível")
    void grauDeUsoMudaARevendibilidade() {
      PedidoDevolucao pedido = pedidoDoCenario(1);
      ResultadoExecucao original = avaliarCopia(pedido);

      ResultadoSimulacao simulacao =
          simulador.simular(original, pedido, Map.of("artigos[0].estado.grauUso", 2));

      assertThat(simulacao.regrasNovas()).contains("IU-33");
      assertThat(simulacao.regrasRemovidas()).contains("IU-31");
    }

    @Test
    @DisplayName("Cenário 8: e se trouxesse o recibo original? PT-007 permite o ajuste")
    void reciboOriginal() {
      PedidoDevolucao pedido = pedidoDoCenario(8);
      ResultadoExecucao original = avaliarCopia(pedido);

      ResultadoSimulacao simulacao =
          simulador.simular(original, pedido, Map.of("comprovativo.reciboOriginal", true));

      assertThat(simulacao.simulado().decisao().getElegibilidade())
          .isEqualTo(Elegibilidade.PERMITIR);
      assertThat(simulacao.simulado().decisao().getTipoTransacao())
          .isEqualTo(TipoTransacao.AJUSTE_PRECO);
      assertThat(simulacao.diferencas())
          .contains(
              new DiferencaSaida(
                  "pedido", "elegibilidade", Elegibilidade.RECUSAR, Elegibilidade.PERMITIR));
      assertThat(simulacao.regrasNovas()).contains("PT-007");
      assertThat(simulacao.regrasRemovidas()).contains("PT-008");
    }

    @Test
    void alteracoesEmListasEEnums() {
      PedidoDevolucao pedido = umPedido().construir();
      ResultadoExecucao original = avaliarCopia(pedido);

      ResultadoSimulacao simulacao =
          simulador.simular(
              original,
              pedido,
              Map.of(
                  "artigos[0].estado.embainhado",
                  true,
                  "compraOriginal.pagamento.meio",
                  MeioPagamento.DEBITO));

      assertThat(simulacao.regrasNovas()).contains("HS-003");
      assertThat(simulacao.simulado().decisao().getElegibilidade())
          .isEqualTo(Elegibilidade.RECUSAR);
    }

    @Test
    void semDiferencas() {
      PedidoDevolucao pedido = umPedido().construir();
      ResultadoSimulacao simulacao =
          simulador.simular(avaliarCopia(pedido), pedido, Map.of("cliente.forneceDados", true));

      assertThat(simulacao.diferencas()).isEmpty();
      assertThat(simulacao.resumo()).contains("não muda");
    }

    @Test
    void valorNuloRemoveOComprovativo() {
      PedidoDevolucao pedido = umPedido().construir();
      Map<String, Object> alteracoes = new HashMap<>();
      alteracoes.put("comprovativo", null);

      ResultadoSimulacao simulacao = simulador.simular(avaliarCopia(pedido), pedido, alteracoes);

      assertThat(simulacao.regrasNovas()).contains("PT-002", "PT-005");
    }

    @Test
    void caminhoInvalido() {
      PedidoDevolucao pedido = umPedido().construir();
      ResultadoExecucao original = avaliarCopia(pedido);

      assertThatThrownBy(() -> simulador.simular(original, pedido, Map.of("naoExiste", 1)))
          .isInstanceOf(IllegalArgumentException.class);
      assertThatThrownBy(
              () -> simulador.simular(original, pedido, Map.of("artigos[5].revendivel", true)))
          .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void aCopiaEIndependente() {
      PedidoDevolucao pedido = umPedido().construir();
      PedidoDevolucao copia = clonador.clonar(pedido);

      copia.getArtigos().getFirst().setRevendivel(false);

      assertThat(pedido.getArtigos().getFirst().getRevendivel()).isNull();
      assertThat(copia.getCompraOriginal().getDataCompra())
          .isEqualTo(pedido.getCompraOriginal().getDataCompra());
    }
  }

  @Nested
  class OQueFalta {

    @Test
    @DisplayName("Cenário 1: falta avaliar a revenda (IN-010) para resolver PC-002")
    void cenario1FaltaARevenda() {
      List<DadoEmFalta> emFalta = detetor.detetar(pedidoDoCenario(1));

      assertThat(emFalta)
          .singleElement()
          .satisfies(
              d -> {
                assertThat(d.codigo()).isEqualTo("IN-010");
                assertThat(d.caminho()).isEqualTo("artigos[0].revendivel");
                assertThat(d.obrigatorio()).isFalse();
              });
    }

    @Test
    @DisplayName("Cenário 3: devolução às cegas sem dados obrigatórios em falta (A-16)")
    void cenario3SemDadosObrigatoriosEmFalta() {
      assertThat(detetor.obrigatorios(pedidoDoCenario(3))).isEmpty();
    }

    @Test
    void todosOsCenariosTemOsDadosObrigatorios() {
      for (int n = 1; n <= 10; n++) {
        assertThat(detetor.obrigatorios(pedidoDoCenario(n))).as("cenário %d", n).isEmpty();
      }
    }

    @Test
    void pedidoIncompleto() {
      PedidoDevolucao pedido =
          umPedido()
              .com(
                  p -> {
                    p.setLoja(null);
                    p.setTipoPedido(null);
                    p.getCompraOriginal().setPagamento(null);
                    p.getCompraOriginal().setDataCompra(null);
                    p.getArtigos().getFirst().getEstado().setEtiquetas(null);
                    p.getArtigos().getFirst().getProduto().setSku(null);
                  })
              .construir();

      assertThat(detetor.obrigatorios(pedido))
          .extracting(DadoEmFalta::codigo)
          .containsExactlyInAnyOrder(
              "IN-001", "IN-002", "IN-005", "IN-006", "IN-009", "IN-007", "IN-008");
    }

    @Test
    void verificadaAposTrintaDiasPrecisaDaRevenda() {
      assertThat(detetor.detetar(umPedido().diasDesdeCompra(40).construir()))
          .extracting(DadoEmFalta::codigo, DadoEmFalta::caminho)
          .containsExactly(
              tuple("IN-010", "artigos[0].revendivel"),
              tuple("IN-008", "artigos[0].estado.grauUso"));
    }

    @Test
    @DisplayName(
        "Alegação de defeito: sugere as perguntas de inspeção por responder (docs/08 §3.3)")
    void alegacaoDeDefeitoSugereAsPerguntasDeInspecao() {
      PedidoDevolucao pedido =
          umPedido()
              .artigo(
                  a -> {
                    a.getEstado().setAlegaDefeito(true);
                    a.getEstado().setInspecaoDefeito(new HashMap<>(Map.of("ED-01", true)));
                    a.getEstado().getInspecaoDefeito().put("ED-05", null);
                  })
              .construir();

      assertThat(detetor.detetar(pedido))
          .extracting(DadoEmFalta::caminho)
          .containsExactly(
              "artigos[0].estado.inspecaoDefeito.ED-02",
              "artigos[0].estado.inspecaoDefeito.ED-06",
              "artigos[0].estado.inspecaoDefeito.ED-07");
      assertThat(detetor.obrigatorios(pedido)).isEmpty();
    }
  }

  @Nested
  class Textos {

    @Test
    void portuguesEIngles() {
      GeradorTexto ingles = new GeradorTexto(Locale.ENGLISH);

      assertThat(TEXTO.formatar("porquenao.disparou", "PT-003"))
          .isEqualTo("A regra PT-003 disparou.");
      assertThat(ingles.formatar("porquenao.disparou", "PT-003")).isEqualTo("Rule PT-003 fired.");
      assertThat(ingles.formatar("emfalta.completo")).isEqualTo("All required data is present.");
    }
  }
}
