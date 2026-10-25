package com.levis.devolucoes.incerteza;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.tuple;

import com.levis.devolucoes.model.enums.FonteEvidencia;
import com.levis.devolucoes.model.enums.Hipotese;
import com.levis.devolucoes.model.incerteza.Evidencia;
import com.levis.devolucoes.model.pedido.Cliente;
import com.levis.devolucoes.model.pedido.PedidoDevolucao;
import com.levis.devolucoes.model.produto.ArtigoDevolvido;
import com.levis.devolucoes.model.produto.EstadoProduto;
import com.levis.devolucoes.model.produto.Produto;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Evidências que vêm das respostas do colaborador e do catálogo (docs/08 §5.4). */
class FabricaEvidenciasTest {

  private final FabricaEvidencias fabrica = new FabricaEvidencias(ServicoIncertezaTest.SERVICO);

  private static PedidoDevolucao pedido(Boolean explicaOrigem, ArtigoDevolvido... artigos) {
    PedidoDevolucao p = new PedidoDevolucao();
    p.setId("P");
    Cliente c = new Cliente();
    c.setExplicaOrigemCompra(explicaOrigem);
    c.setAgitado(true);
    c.setContestaResultado(true);
    p.setCliente(c);
    p.setArtigos(List.of(artigos));
    return p;
  }

  private static ArtigoDevolvido artigo(
      String id, boolean alegaDefeito, boolean defeitoConhecido, Map<String, Boolean> inspecao) {
    ArtigoDevolvido a = new ArtigoDevolvido();
    a.setId(id);
    Produto produto = new Produto();
    produto.setDefeitoConhecido(defeitoConhecido);
    a.setProduto(produto);
    EstadoProduto estado = new EstadoProduto();
    estado.setAlegaDefeito(alegaDefeito);
    estado.setInspecaoDefeito(inspecao);
    a.setEstado(estado);
    return a;
  }

  @Test
  void naoExplicarAOrigemEEvidenciaPresenteDeFraude() {
    List<Evidencia> evidencias = fabrica.evidencias(pedido(false));

    assertThat(evidencias)
        .extracting(
            Evidencia::getCodigo,
            Evidencia::getPresente,
            Evidencia::getHipotese,
            Evidencia::getFonte)
        .containsExactly(tuple("EF-04", true, Hipotese.FRAUDE, FonteEvidencia.COLABORADOR));
    assertThat(evidencias.getFirst().getPeso()).isEqualTo(0.40);
  }

  @Test
  void explicarAOrigemEEvidenciaAusenteENaoSeiNaoGeraEvidencia() {
    assertThat(fabrica.evidencias(pedido(true)))
        .extracting(Evidencia::getCodigo, Evidencia::getPresente)
        .containsExactly(tuple("EF-04", false));
    assertThat(fabrica.evidencias(pedido(null))).isEmpty();
  }

  @Test
  void oComportamentoDoClienteNuncaEEvidencia() {
    assertThat(fabrica.evidencias(pedido(null))).noneMatch(e -> e.getHipotese() == Hipotese.FRAUDE);
  }

  @Test
  void inspecaoDeDefeitoSoQuandoOClienteAlegaDefeito() {
    Map<String, Boolean> inspecao = new LinkedHashMap<>();
    inspecao.put("ED-01", true);
    inspecao.put("ED-05", null);
    inspecao.put("ED-07", false);
    inspecao.put("ED-03", true);
    inspecao.put("XX-99", true);

    List<Evidencia> evidencias =
        fabrica.evidencias(
            pedido(
                null, artigo("A-1", true, true, inspecao), artigo("A-2", false, true, inspecao)));

    assertThat(evidencias)
        .extracting(
            Evidencia::getCodigo,
            Evidencia::getArtigoId,
            Evidencia::getPresente,
            Evidencia::getFonte)
        .containsExactly(
            tuple("ED-01", "A-1", true, FonteEvidencia.COLABORADOR),
            tuple("ED-05", "A-1", null, FonteEvidencia.COLABORADOR),
            tuple("ED-07", "A-1", false, FonteEvidencia.COLABORADOR),
            tuple("ED-04", "A-1", true, FonteEvidencia.CATALOGO));
    assertThat(evidencias).allMatch(e -> e.getHipotese() == Hipotese.DEFEITO_FABRICO);
    assertThat(evidencias.get(1).getGrupo()).isEqualTo("USO");
  }

  @Test
  void semDefeitoConhecidoNoCatalogoAEvidenciaFicaAusente() {
    List<Evidencia> evidencias =
        fabrica.evidencias(pedido(null, artigo("A-1", true, false, Map.of())));

    assertThat(evidencias)
        .extracting(Evidencia::getCodigo, Evidencia::getPresente)
        .containsExactly(tuple("ED-04", false));
  }

  @Test
  void pedidoSemClienteNemArtigosNaoTemEvidencias() {
    PedidoDevolucao p = new PedidoDevolucao();
    p.setId("P");
    assertThat(fabrica.evidencias(p)).isEmpty();
  }
}
