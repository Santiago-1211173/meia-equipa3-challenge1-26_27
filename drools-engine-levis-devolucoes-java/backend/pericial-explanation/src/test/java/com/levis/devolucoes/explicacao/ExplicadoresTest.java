package com.levis.devolucoes.explicacao;

import static com.levis.devolucoes.explicacao.SuporteExplicacoes.AVALIADOR;
import static com.levis.devolucoes.explicacao.SuporteExplicacoes.CATALOGO;
import static com.levis.devolucoes.explicacao.SuporteExplicacoes.TEXTO;
import static com.levis.devolucoes.explicacao.SuporteExplicacoes.cenario;
import static com.levis.devolucoes.model.teste.PedidoBuilder.umPedido;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.levis.devolucoes.explicacao.catalogo.CampoSaida;
import com.levis.devolucoes.explicacao.como.ExplicacaoComo;
import com.levis.devolucoes.explicacao.como.ExplicacaoConclusao;
import com.levis.devolucoes.explicacao.como.ExplicadorComo;
import com.levis.devolucoes.explicacao.emfalta.DetetorDadosEmFalta;
import com.levis.devolucoes.explicacao.motor.ResultadoExecucao;
import com.levis.devolucoes.explicacao.porque.DadoEntrada;
import com.levis.devolucoes.explicacao.porque.DependenciasDados;
import com.levis.devolucoes.explicacao.porque.ExplicacaoPorque;
import com.levis.devolucoes.explicacao.porque.ExplicadorPorque;
import com.levis.devolucoes.explicacao.porque.RegraEmEspera;
import com.levis.devolucoes.explicacao.porquenao.CausaNaoDisparo;
import com.levis.devolucoes.explicacao.porquenao.ExplicacaoPorqueNao;
import com.levis.devolucoes.explicacao.porquenao.ExplicacaoPorqueNaoConclusao;
import com.levis.devolucoes.explicacao.porquenao.ExplicadorPorqueNao;
import com.levis.devolucoes.explicacao.porquenao.ResultadoCondicao;
import com.levis.devolucoes.model.enums.DestinoProduto;
import com.levis.devolucoes.model.enums.Elegibilidade;
import com.levis.devolucoes.model.enums.Marca;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * As três explicações, segundo as definições aprovadas (ADR 0006): Como (caminho até uma
 * conclusão), Porque não (razão de uma conclusão não ter sido obtida) e Porquê (razão de uma
 * pergunta ao colaborador).
 */
class ExplicadoresTest {

  private final ExplicadorComo como = new ExplicadorComo(CATALOGO, AVALIADOR, TEXTO);
  private final ExplicadorPorqueNao porqueNao = new ExplicadorPorqueNao(CATALOGO, AVALIADOR, TEXTO);
  private final ExplicadorPorque porque =
      new ExplicadorPorque(CATALOGO, AVALIADOR, new DependenciasDados(), TEXTO);

  @Nested
  class Como {

    @Test
    @DisplayName("Cenário 5: caminho completo até à paragem obrigatória CH-008")
    void caminhoAteAParagem() {
      ExplicacaoComo explicacao = como.explicar(cenario(5));

      assertThat(explicacao.passos())
          .extracting(p -> p.codigoRegra())
          .containsExactly("CT-003", "CH-008", "EX-002", "OUT-007", "OUT-001");
      assertThat(explicacao.paragem()).isEqualTo("CH-008");
      assertThat(explicacao.modulosPercorridos()).containsExactly("M0", "M2", "M6", "M9");
      assertThat(explicacao.resumo()).contains("5 regras", "4 módulos", "CH-008", "M2");
    }

    @Test
    void passosComArtigoMensagemEAmbiguidade() {
      ExplicacaoComo explicacao = como.explicar(cenario(10));

      assertThat(explicacao.passos())
          .filteredOn(p -> p.codigoRegra().equals("CH-004"))
          .singleElement()
          .satisfies(
              p -> {
                assertThat(p.aValidar()).isTrue();
                assertThat(p.resultado()).isEqualTo(Elegibilidade.REVER);
                assertThat(p.mensagem()).contains("portal");
              });
      assertThat(explicacao.paragem()).isNull();
    }

    @Test
    @DisplayName("Cenário 7: como se concluiu OUT-001 = REVER (PT-003 e depois TN-011)")
    void caminhoDeUmaConclusao() {
      ExplicacaoConclusao explicacao = como.explicarConclusao(CampoSaida.OUT_001, null, cenario(7));

      assertThat(explicacao.regra()).isEqualTo("TN-011");
      assertThat(explicacao.valores()).containsEntry("elegibilidade", Elegibilidade.REVER);
      assertThat(explicacao.caminho()).hasSize(2);
      assertThat(explicacao.caminho().getFirst()).startsWith("PT-003");
      assertThat(explicacao.condicoes())
          .extracting(ResultadoCondicao::nome)
          .contains("mercadoCanada", "pagamentoInterac", "cartaoFisicoAusente");
      assertThat(explicacao.condicoes()).allMatch(c -> Boolean.TRUE.equals(c.cumprida()));
      assertThat(explicacao.resumo()).contains("OUT-001", "REVER", "TN-011");
    }

    @Test
    @DisplayName("Cenário 9: como se concluiu o destino do artigo (OUT-007)")
    void conclusaoDeUmArtigo() {
      ExplicacaoConclusao explicacao =
          como.explicarConclusao(CampoSaida.OUT_007, "A-1", cenario(9));

      assertThat(explicacao.valores()).containsEntry("destino", DestinoProduto.RISCO_BIOLOGICO);
      assertThat(explicacao.regra()).isEqualTo("PC-008");
    }

    @Test
    void documentacaoTemOCaminhoDosControlos() {
      ExplicacaoConclusao explicacao = como.explicarConclusao(CampoSaida.OUT_008, null, cenario(9));

      assertThat(explicacao.regra()).isEqualTo("CT-007");
      assertThat(explicacao.caminho())
          .anyMatch(h -> h.startsWith("CT-004"))
          .anyMatch(h -> h.startsWith("CT-005"));
    }

    @Test
    void conclusaoSemRegraEDestinoSemArtigo() {
      assertThat(como.explicarConclusao(CampoSaida.OUT_006, null, cenario(1)).regra()).isNull();
      assertThatThrownBy(() -> como.explicarConclusao(CampoSaida.OUT_007, null, cenario(9)))
          .isInstanceOf(IllegalArgumentException.class);
    }
  }

  @Nested
  class PorqueNaoConclusao {

    @Test
    @DisplayName("Cenário 1: porque não PERMITIR? PT-003 propôs, mas a revisão (PC-002) prevaleceu")
    void conclusaoPropostaMasSubstituida() {
      ExplicacaoPorqueNaoConclusao explicacao =
          porqueNao.explicarConclusao(CampoSaida.OUT_001, "PERMITIR", null, cenario(1));

      assertThat(explicacao.obtida()).isFalse();
      assertThat(explicacao.valorObtido()).isEqualTo(Elegibilidade.REVER);
      assertThat(explicacao.propostaPor()).contains("PT-003");
      assertThat(explicacao.definidoPor()).isEqualTo("OUT-001");
      assertThat(explicacao.resumo()).contains("PT-003", "REVER");
    }

    @Test
    @DisplayName(
        "Cenário 8: porque não ajuste de preço? Só PT-007 o produz, e falta o recibo original")
    void conclusaoNaoProduzida() {
      ExplicacaoPorqueNaoConclusao explicacao =
          porqueNao.explicarConclusao(CampoSaida.OUT_002, "AJUSTE_PRECO", null, cenario(8));

      assertThat(explicacao.obtida()).isFalse();
      assertThat(explicacao.propostaPor()).isEmpty();
      assertThat(explicacao.regras())
          .singleElement()
          .satisfies(
              r -> {
                assertThat(r.codigoRegra()).isEqualTo("PT-007");
                assertThat(r.causa()).isEqualTo(CausaNaoDisparo.CONDICOES_FALHADAS);
                assertThat(r.condicoesFalhadas())
                    .extracting(ResultadoCondicao::nome)
                    .contains("reciboOriginal");
              });
      assertThat(explicacao.resumo()).contains("PT-007");
    }

    @Test
    @DisplayName("Cenário 5: porque não reembolso? As regras que o produzem nunca foram alcançadas")
    void conclusaoComModulosNaoAlcancados() {
      ExplicacaoPorqueNaoConclusao explicacao =
          porqueNao.explicarConclusao(CampoSaida.OUT_002, "REEMBOLSO", null, cenario(5));

      assertThat(explicacao.regras())
          .extracting(ExplicacaoPorqueNao::codigoRegra)
          .contains("PT-003", "CH-002", "CH-005");
      assertThat(explicacao.regras())
          .allMatch(r -> r.causa() == CausaNaoDisparo.MODULO_NAO_ALCANCADO);
    }

    @Test
    @DisplayName("Cenário 9: porque não área de vendas? O artigo é isolado (PC-008 e BW-004)")
    void conclusaoDeUmArtigo() {
      ExplicacaoPorqueNaoConclusao explicacao =
          porqueNao.explicarConclusao(CampoSaida.OUT_007, "AREA_VENDAS", "A-1", cenario(9));

      assertThat(explicacao.valorObtido()).isEqualTo(DestinoProduto.RISCO_BIOLOGICO);
      assertThat(explicacao.regras())
          .extracting(ExplicacaoPorqueNao::codigoRegra)
          .contains("CT-008", "BW-001", "EP-005");
    }

    @Test
    void conclusaoObtida() {
      ExplicacaoPorqueNaoConclusao explicacao =
          porqueNao.explicarConclusao(CampoSaida.OUT_001, "RECUSAR", null, cenario(4));

      assertThat(explicacao.obtida()).isTrue();
      assertThat(explicacao.regras()).isEmpty();
    }
  }

  @Nested
  class PorqueNaoRegra {

    @Test
    @DisplayName("Cenário 5: HS-002 nunca foi avaliada, CH-008 terminou o fluxo em M2")
    void moduloNaoAlcancado() {
      ExplicacaoPorqueNao explicacao = porqueNao.explicar("HS-002", null, cenario(5));

      assertThat(explicacao.causa()).isEqualTo(CausaNaoDisparo.MODULO_NAO_ALCANCADO);
      assertThat(explicacao.regraResponsavel()).isEqualTo("CH-008");
      assertThat(explicacao.resumo()).contains("CH-008", "M2");
    }

    @Test
    @DisplayName("Cenário 6: o fluxo foi suspenso por EX-008")
    void suspensaoPorFraude() {
      ExplicacaoPorqueNao explicacao = porqueNao.explicar("PT-002", null, cenario(6));

      assertThat(explicacao.causa()).isEqualTo(CausaNaoDisparo.MODULO_NAO_ALCANCADO);
      assertThat(explicacao.regraResponsavel()).isEqualTo("EX-008");
    }

    @Test
    @DisplayName("PC-001 vencida por HS-002 (marca excluída), com mais salience no mesmo módulo")
    void precedencia() {
      ResultadoExecucao resultado =
          SuporteExplicacoes.executar(
              umPedido().artigo(a -> a.getProduto().setMarca(Marca.DOCKERS)).construir());

      ExplicacaoPorqueNao explicacao = porqueNao.explicar("PC-001", "A-1", resultado);

      assertThat(explicacao.causa()).isEqualTo(CausaNaoDisparo.CANCELADA_POR_PRECEDENCIA);
      assertThat(explicacao.regraResponsavel()).isEqualTo("HS-002");
    }

    @Test
    @DisplayName("Cenário 4: PC-006 falha porque o produto foi embainhado (HS-003 prevalece)")
    void condicoesFalhadas() {
      ExplicacaoPorqueNao explicacao = porqueNao.explicar("PC-006", "A-1", cenario(4));

      assertThat(explicacao.causa()).isEqualTo(CausaNaoDisparo.CONDICOES_FALHADAS);
      assertThat(explicacao.condicoesFalhadas())
          .extracting(ResultadoCondicao::nome)
          .contains("naoModificado");
      assertThat(explicacao.resumo()).contains("HS-003 prevalece");
    }

    @Test
    void regraQueDisparouERegraDesconhecida() {
      assertThat(porqueNao.explicar("PT-003", null, cenario(7)).causa())
          .isEqualTo(CausaNaoDisparo.DISPAROU);
      assertThatThrownBy(() -> porqueNao.explicar("XX-999", null, cenario(1)))
          .isInstanceOf(IllegalArgumentException.class);
    }
  }

  @Nested
  class Porque {

    @Test
    @DisplayName(
        "Cenário 1: porquê perguntar se o artigo pode ser revendido? PC-002 espera a resposta")
    void perguntaDeRevenda() {
      ExplicacaoPorque explicacao = porque.explicar(DadoEntrada.REVENDA, cenario(1));

      assertThat(explicacao.pergunta()).contains("reetiquetado e revendido");
      assertThat(explicacao.regrasQueDependem()).contains("PC-002", "PC-003", "PT-004", "BW-001");
      assertThat(explicacao.regrasEmEspera())
          .extracting(RegraEmEspera::nomeRegra)
          .containsExactlyInAnyOrder(
              "PC-002 Etiquetas soltas: aprovado, artigo revendível",
              "PC-002 Etiquetas soltas: recusado, artigo não revendível");
      assertThat(explicacao.regrasEmEspera())
          .allSatisfy(r -> assertThat(r.artigoId()).isEqualTo("A-1"))
          .flatExtracting(r -> r.conclusoes().stream().map(Object::toString).toList())
          .contains("OUT-001=PERMITIR", "OUT-001=RECUSAR");
      assertThat(explicacao.resumo()).contains("2 decisão(ões)", "PC-002");
    }

    @Test
    @DisplayName("Cenário 1: o dado em falta devolvido pelo \"O que falta?\" traz o seu porquê")
    void porqueDeUmDadoEmFalta() {
      var emFalta =
          new DetetorDadosEmFalta().detetar(SuporteExplicacoes.pedidoDoCenario(1)).getFirst();

      ExplicacaoPorque explicacao = porque.explicar(emFalta, cenario(1));

      assertThat(explicacao.dado()).isEqualTo(DadoEntrada.REVENDA);
      assertThat(explicacao.regrasEmEspera()).isNotEmpty();
    }

    @Test
    @DisplayName("Pedido de ajuste sem recibo original: porquê perguntar pelo comprovativo?")
    void perguntaDoComprovativo() {
      ResultadoExecucao resultado = cenario(8);

      ExplicacaoPorque explicacao = porque.explicar(DadoEntrada.COMPROVATIVO, resultado);

      assertThat(explicacao.regrasEmEspera())
          .extracting(RegraEmEspera::codigoRegra)
          .contains("PT-007");
      assertThat(explicacao.regrasEmEspera())
          .filteredOn(r -> r.nomeRegra().startsWith("PT-007 Ajuste de preço único"))
          .singleElement()
          .satisfies(
              r ->
                  assertThat(r.condicoesDoDado())
                      .extracting(ResultadoCondicao::nome)
                      .contains("reciboOriginal"));
    }

    @Test
    @DisplayName("Depois de uma paragem obrigatória nenhuma decisão espera pela resposta")
    void semDecisoesEmEspera() {
      ExplicacaoPorque explicacao = porque.explicar(DadoEntrada.PAGAMENTO, cenario(5));

      assertThat(explicacao.regrasEmEspera()).isEmpty();
      assertThat(explicacao.regrasQueDependem()).contains("TN-001", "TN-008");
      assertThat(explicacao.resumo())
          .contains("nenhuma decisão terminal está imediatamente dependente")
          .contains(DadoEntrada.PAGAMENTO.racional());
    }

    @Test
    @DisplayName("Todos os dados de entrada possuem racional de negócio estruturado")
    void todosOsDadosPossuemRacionalDeNegocio() {
      for (DadoEntrada dado : DadoEntrada.values()) {
        assertThat(dado.racional())
            .as("Racional de negócio para %s (%s)", dado.name(), dado.codigo())
            .isNotBlank()
            .endsWith(".");
        assertThat(dado.racionalNegocio()).isEqualTo(dado.racional());
      }
    }
  }
}

