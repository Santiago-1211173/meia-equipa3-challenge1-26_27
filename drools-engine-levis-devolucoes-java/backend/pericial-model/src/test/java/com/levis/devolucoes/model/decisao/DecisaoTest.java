package com.levis.devolucoes.model.decisao;

import static org.assertj.core.api.Assertions.assertThat;

import com.levis.devolucoes.model.enums.Elegibilidade;
import com.levis.devolucoes.model.enums.Modulo;
import com.levis.devolucoes.model.enums.NivelAprovacao;
import com.levis.devolucoes.model.enums.TipoTransacao;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/** Semântica de aplicar(), terminal e suspender() (ADR 0004). */
class DecisaoTest {

  private final Decisao decisao = new Decisao("P-1");

  @Test
  void registaCadaRegraNoRasto() {
    Clock relogio = Clock.fixed(Instant.parse("2026-03-31T10:15:00Z"), ZoneOffset.UTC);
    decisao.usarRelogio(relogio);

    decisao.aplicar("PT-003", Modulo.M5, Elegibilidade.PERMITIR, "Reembolso total.");

    assertThat(decisao.getRegistos())
        .singleElement()
        .satisfies(
            r -> {
              assertThat(r.getCodigoRegra()).isEqualTo("PT-003");
              assertThat(r.getModulo()).isEqualTo(Modulo.M5);
              assertThat(r.getResultado()).isEqualTo(Elegibilidade.PERMITIR);
              assertThat(r.getMensagem()).isEqualTo("Reembolso total.");
              assertThat(r.getInstante()).isEqualTo(LocalDateTime.of(2026, 3, 31, 10, 15));
            });
    assertThat(decisao.getElegibilidade()).isEqualTo(Elegibilidade.PERMITIR);
    assertThat(decisao.disparou("PT-003")).isTrue();
    assertThat(decisao.disparou("PT-004")).isFalse();
  }

  @Test
  void nuncaBaixaASeveridade() {
    decisao.aplicar("PT-004", Modulo.M5, Elegibilidade.REVER, "Após 30 dias.");
    decisao.aplicar("PC-001", Modulo.M3, Elegibilidade.PERMITIR, "Estado elegível.");

    assertThat(decisao.getElegibilidade()).isEqualTo(Elegibilidade.REVER);
    assertThat(decisao.getRegistos()).hasSize(2);
  }

  @Test
  void sobeASeveridade() {
    decisao.aplicar("PC-001", Modulo.M3, Elegibilidade.PERMITIR, "Estado elegível.");
    decisao.aplicar("PT-008", Modulo.M5, Elegibilidade.RECUSAR, "Ajuste recusado.");

    assertThat(decisao.getElegibilidade()).isEqualTo(Elegibilidade.RECUSAR);
  }

  @ParameterizedTest
  @ValueSource(strings = {"HS-001", "HS-002", "HS-003", "HS-004", "HS-006", "CH-007", "CH-008"})
  void paragemObrigatoriaTerminaOFluxo(String regra) {
    decisao.aplicar(regra, Modulo.M3, Elegibilidade.RECUSAR, "Paragem.");
    assertThat(decisao.isTerminal()).isTrue();
  }

  @Test
  void ch002EncaminhaSemTerminar() {
    decisao.aplicar("CH-002", Modulo.ONLINE, Elegibilidade.ENCAMINHAR, "BackPocket.");

    assertThat(decisao.getElegibilidade()).isEqualTo(Elegibilidade.ENCAMINHAR);
    assertThat(decisao.isTerminal()).isFalse();
  }

  @Test
  void hs005NaoTerminaOFluxo() {
    decisao.aplicar("HS-005", Modulo.ONLINE, Elegibilidade.RECUSAR, "Exceção Afterpay recusada.");
    assertThat(decisao.isTerminal()).isFalse();
  }

  @Test
  void paragemQuePermiteNaoTermina() {
    decisao.aplicar("HS-006", Modulo.M0, Elegibilidade.PERMITIR, "Autorizado.");
    assertThat(decisao.isTerminal()).isFalse();
  }

  @Test
  void resolverRevisaoPassaDeReverAPermitir() {
    decisao.aplicar("PC-002", Modulo.M3, Elegibilidade.REVER, "Etiquetas soltas.");
    decisao.resolverRevisao("PC-002", Modulo.M3, "Revendível: aprovado.");

    assertThat(decisao.getElegibilidade()).isEqualTo(Elegibilidade.PERMITIR);
    assertThat(decisao.getRegistos()).hasSize(2);
  }

  @Test
  void resolverRevisaoNaoAlteraUmaRecusa() {
    decisao.aplicar("PC-005", Modulo.M3, Elegibilidade.RECUSAR, "Lavado.");
    decisao.resolverRevisao("PC-002", Modulo.M3, "Revendível.");

    assertThat(decisao.getElegibilidade()).isEqualTo(Elegibilidade.RECUSAR);
  }

  @Test
  void registarNaoAlteraAElegibilidade() {
    decisao.registar("CT-005", Modulo.M8, "Assinaturas.");

    assertThat(decisao.getElegibilidade()).isNull();
    assertThat(decisao.getRegistos().getFirst().getResultado()).isNull();
  }

  @Test
  void suspenderPorFraudeTerminaEmReverComEscalonamento() {
    decisao.aplicar("PC-001", Modulo.M3, Elegibilidade.PERMITIR, "Estado elegível.");
    decisao.suspender("EX-008", Modulo.M3, "Transação suspensa.");

    assertThat(decisao.getElegibilidade()).isEqualTo(Elegibilidade.REVER);
    assertThat(decisao.getAprovacao()).isEqualTo(NivelAprovacao.DISTRICT_AREA);
    assertThat(decisao.isTerminal()).isTrue();
    assertThat(decisao.getRegistos().getLast().getResultado()).isEqualTo(Elegibilidade.REVER);
  }

  @Test
  void suspenderSobrepoeUmaRecusaAnterior() {
    decisao.aplicar("PT-008", Modulo.M5, Elegibilidade.RECUSAR, "Ajuste recusado.");
    decisao.suspender("EX-008", Modulo.M5, "Transação suspensa.");

    assertThat(decisao.getElegibilidade()).isEqualTo(Elegibilidade.REVER);
  }

  @Test
  void recusarExcecaoNaoAlteraAElegibilidade() {
    decisao.aplicar("CH-002", Modulo.ONLINE, Elegibilidade.ENCAMINHAR, "BackPocket.");
    decisao.recusarExcecao("HS-005", Modulo.ONLINE, "Exceção Afterpay recusada.");

    assertThat(decisao.getElegibilidade()).isEqualTo(Elegibilidade.ENCAMINHAR);
    assertThat(decisao.isExcecaoRecusada()).isTrue();
    assertThat(decisao.isTerminal()).isFalse();
    assertThat(decisao.getRegistos().getLast().getResultado()).isEqualTo(Elegibilidade.RECUSAR);
  }

  private static DecisaoArtigo artigo(String id, Elegibilidade elegibilidade) {
    DecisaoArtigo artigo = new DecisaoArtigo("P-1", id);
    if (elegibilidade != null) {
      artigo.aplicar("TESTE", Modulo.M3, elegibilidade, "teste");
    }
    return artigo;
  }

  @Test
  void agregacaoUsaOResultadoMaisSeveroDosArtigos() {
    decisao.aplicar("PT-003", Modulo.M5, Elegibilidade.PERMITIR, "Reembolso.");
    decisao.agregarArtigos(
        "OUT-001",
        Modulo.M9,
        List.of(artigo("A-2", Elegibilidade.REVER), artigo("A-1", Elegibilidade.PERMITIR)));

    assertThat(decisao.getElegibilidade()).isEqualTo(Elegibilidade.REVER);
    assertThat(decisao.getResultadosArtigos())
        .extracting(DecisaoArtigo::getArtigoId)
        .containsExactly("A-1", "A-2");
    assertThat(decisao.getRegistos().getLast().getMensagem())
        .contains("2 artigo(s): 1 permitido(s), 1 em revisão, 0 recusado(s)");
  }

  @Test
  void agregacaoNaoBaixaAElegibilidadeDoPedido() {
    decisao.aplicar("PT-008", Modulo.M5, Elegibilidade.RECUSAR, "Ajuste recusado.");
    decisao.agregarArtigos("OUT-001", Modulo.M9, List.of(artigo("A-1", Elegibilidade.PERMITIR)));

    assertThat(decisao.getElegibilidade()).isEqualTo(Elegibilidade.RECUSAR);
  }

  @Test
  void todosOsArtigosRecusadosNaoHaTransacao() {
    decisao.agregarArtigos(
        "OUT-001",
        Modulo.M9,
        List.of(artigo("A-1", Elegibilidade.RECUSAR), artigo("A-2", Elegibilidade.RECUSAR)));

    assertThat(decisao.getElegibilidade()).isEqualTo(Elegibilidade.RECUSAR);
    assertThat(decisao.getTipoTransacao()).isEqualTo(TipoTransacao.NENHUMA);
  }

  @Test
  void artigosSemResultadoNaoContam() {
    decisao.agregarArtigos(
        "OUT-001",
        Modulo.M9,
        List.of(artigo("A-1", null), artigo("A-2", Elegibilidade.ENCAMINHAR)));

    assertThat(decisao.getElegibilidade()).isEqualTo(Elegibilidade.ENCAMINHAR);
    assertThat(decisao.getTipoTransacao()).isNull();
  }

  @Test
  void decisaoArtigoTemOMesmoComportamento() {
    DecisaoArtigo artigo = new DecisaoArtigo("P-1", "A-1");
    artigo.aplicar("HS-003", Modulo.M3, Elegibilidade.RECUSAR, "Embainhado.");

    assertThat(artigo.isTerminal()).isTrue();
    assertThat(artigo.getAprovacao()).isEqualTo(NivelAprovacao.NENHUMA);
  }

  @Test
  void valoresIniciais() {
    assertThat(decisao.getPedidoId()).isEqualTo("P-1");
    assertThat(decisao.getAprovacao()).isEqualTo(NivelAprovacao.NENHUMA);
    assertThat(decisao.getDocumentacao()).isNotNull();
    assertThat(decisao.getResultadosArtigos()).isEmpty();
    assertThat(decisao.isTerminal()).isFalse();
  }

  @Test
  void aAprovacaoExigidaNuncaDesce() {
    Decisao decisao = new Decisao("P");
    decisao.exigirAprovacao(NivelAprovacao.DISTRICT_AREA);
    decisao.exigirAprovacao(NivelAprovacao.RESPONSAVEL_SENIOR);
    DecisaoArtigo artigo = new DecisaoArtigo("P", "A-1");
    artigo.exigirAprovacao(NivelAprovacao.RESPONSAVEL_SENIOR);
    artigo.exigirAprovacao(NivelAprovacao.XSTORE_MANAGER);

    assertThat(decisao.getAprovacao()).isEqualTo(NivelAprovacao.DISTRICT_AREA);
    assertThat(artigo.getAprovacao()).isEqualTo(NivelAprovacao.RESPONSAVEL_SENIOR);
  }

  @Test
  void guardaOsGrausDeCrencaEAVersaoDosParametros() {
    Decisao decisao = new Decisao("P");
    com.levis.devolucoes.model.incerteza.GrauCrenca grau =
        new com.levis.devolucoes.model.incerteza.GrauCrenca();
    grau.setVersaoParametros("0.1.0-demo");

    decisao.acrescentarGrau(grau);

    assertThat(decisao.getGrausCrenca()).containsExactly(grau);
    assertThat(decisao.getVersaoParametrosIncerteza()).isEqualTo("0.1.0-demo");
  }

  @Test
  void sabeComQueResultadoUmaRegraDisparou() {
    Decisao decisao = new Decisao("P");
    decisao.aplicar("PT-004", Modulo.M5, Elegibilidade.REVER, "rever");

    assertThat(decisao.disparouCom("PT-004", Elegibilidade.REVER)).isTrue();
    assertThat(decisao.disparouCom("PT-004", Elegibilidade.PERMITIR)).isFalse();
    assertThat(decisao.disparouCom("PT-003", Elegibilidade.REVER)).isFalse();
  }
}
