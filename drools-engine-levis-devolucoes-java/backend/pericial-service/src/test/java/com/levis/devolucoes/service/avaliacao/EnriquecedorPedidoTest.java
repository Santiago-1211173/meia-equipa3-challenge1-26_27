package com.levis.devolucoes.service.avaliacao;

import static org.assertj.core.api.Assertions.assertThat;

import com.levis.devolucoes.dto.enums.CanalCompra;
import com.levis.devolucoes.dto.enums.CategoriaProduto;
import com.levis.devolucoes.dto.enums.EstadoConta;
import com.levis.devolucoes.dto.enums.Marca;
import com.levis.devolucoes.dto.enums.MeioPagamento;
import com.levis.devolucoes.dto.pedido.ArtigoRequest;
import com.levis.devolucoes.dto.pedido.ArtigoTrocaRequest;
import com.levis.devolucoes.dto.pedido.CompraRequest;
import com.levis.devolucoes.dto.pedido.PagamentoRequest;
import com.levis.devolucoes.dto.pedido.PedidoAvaliacaoRequest;
import com.levis.devolucoes.dto.pedido.ProdutoRequest;
import com.levis.devolucoes.service.integracao.simulado.IntegracoesSimuladas;
import java.util.List;
import org.junit.jupiter.api.Test;

class EnriquecedorPedidoTest {

  private final IntegracoesSimuladas integracoes = new IntegracoesSimuladas();
  private final EnriquecedorPedido enriquecedor =
      new EnriquecedorPedido(integracoes, integracoes, integracoes, integracoes);

  private static ProdutoRequest so(String sku) {
    return new ProdutoRequest(sku, null, null, null, null, null, null, null, null, null, null);
  }

  private static PedidoAvaliacaoRequest pedido(
      ProdutoRequest produto, CompraRequest compra, Boolean portal) {
    return new PedidoAvaliacaoRequest(
        "P-1",
        null,
        null,
        null,
        null,
        compra,
        null,
        List.of(new ArtigoRequest("A-1", produto, null, null, null, false, null, null)),
        null,
        portal,
        null,
        null,
        null);
  }

  private static CompraRequest compra(CanalCompra canal, Boolean encontrada) {
    return new CompraRequest(
        "LCOM-0202",
        canal,
        null,
        null,
        new PagamentoRequest(MeioPagamento.CREDITO, null, null, false, false, null),
        null,
        1,
        false,
        encontrada,
        false,
        false);
  }

  @Test
  void completaOProdutoComOPosEOCatalogo() {
    PedidoAvaliacaoRequest enriquecido =
        enriquecedor.enriquecer(pedido(so("BW-BOXER-3PK-M"), null, null));

    ProdutoRequest produto = enriquecido.artigos().getFirst().produto();
    assertThat(produto.skuReconhecidoPOS()).isTrue();
    assertThat(produto.marca()).isEqualTo(Marca.LEVIS);
    assertThat(produto.categoria()).isEqualTo(CategoriaProduto.BODYWEAR);
    assertThat(produto.precoAtual()).isEqualByComparingTo("29.99");
    assertThat(enriquecido.portalOnlineDisponivel()).isTrue();
  }

  @Test
  void skuDesconhecidoNaoEReconhecidoEFicaSemDadosDeCatalogo() {
    ProdutoRequest produto =
        enriquecedor.enriquecer(pedido(so("XPTO"), null, null)).artigos().getFirst().produto();

    assertThat(produto.skuReconhecidoPOS()).isFalse();
    assertThat(produto.marca()).isNull();
  }

  @Test
  void nuncaSobrepoeOQueOColaboradorIndicou() {
    ProdutoRequest indicado =
        new ProdutoRequest(
            "BW-BOXER-3PK-M",
            false,
            Marca.OUTRA,
            CategoriaProduto.VESTUARIO,
            null,
            null,
            null,
            null,
            null,
            null,
            null);
    integracoes.definirPortalDisponivel(true);

    PedidoAvaliacaoRequest enriquecido = enriquecedor.enriquecer(pedido(indicado, null, false));

    ProdutoRequest produto = enriquecido.artigos().getFirst().produto();
    assertThat(produto.skuReconhecidoPOS()).isFalse();
    assertThat(produto.marca()).isEqualTo(Marca.OUTRA);
    assertThat(produto.categoria()).isEqualTo(CategoriaProduto.VESTUARIO);
    assertThat(produto.precoAtual()).isEqualByComparingTo("29.99");
    assertThat(enriquecido.portalOnlineDisponivel()).isFalse();
  }

  /** Pedido em preenchimento: artigo de troca sem "reconhecido pelo POS" e artigo ainda sem SKU. */
  @Test
  void aceitaProdutosPorCompletar() {
    PedidoAvaliacaoRequest emCurso =
        new PedidoAvaliacaoRequest(
            "P-1",
            null,
            null,
            null,
            null,
            null,
            null,
            List.of(new ArtigoRequest("A-1", so(null), null, null, null, false, null, null)),
            List.of(new ArtigoTrocaRequest(so("501-ORIG-34"), false, null)),
            null,
            null,
            null,
            null);

    PedidoAvaliacaoRequest enriquecido = enriquecedor.enriquecer(emCurso);

    assertThat(enriquecido.artigos().getFirst().produto().skuReconhecidoPOS()).isNull();
    assertThat(enriquecido.artigosTroca().getFirst().produto().skuReconhecidoPOS()).isNull();
    assertThat(enriquecido.artigosTroca().getFirst().produto().marca()).isEqualTo(Marca.LEVIS);
  }

  @Test
  void encomendaOnlineEContaDoPagamento() {
    integracoes.registarConta("LCOM-0202", EstadoConta.ENCERRADA);

    CompraRequest online =
        enriquecedor
            .enriquecer(pedido(so("501-ORIG-32"), compra(CanalCompra.LEVI_COM, null), null))
            .compraOriginal();
    CompraRequest loja =
        enriquecedor
            .enriquecer(pedido(so("501-ORIG-32"), compra(CanalCompra.MAINLINE, null), null))
            .compraOriginal();

    assertThat(online.encomendaEncontrada()).isTrue();
    assertThat(online.pagamento().estadoConta()).isEqualTo(EstadoConta.ENCERRADA);
    assertThat(loja.encomendaEncontrada()).isNull();
  }
}
